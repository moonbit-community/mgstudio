// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
priv struct QueryTableBatchScope {
  lease : WorldLease
  table_id : Int
  mut entities : Array[@core.Entity]?
  whole_table : Bool
  mut authorized_row : Int
}

///|
priv struct QueryTableBatchColumnBinding[T] {
  mut values : Array[T]?
  mut column : RawTableColumn?
}

///|
/// One matching dense ECS table.
///
/// The query data and filter used to create this batch remain the authority for
/// component access and table selection. Bind only columns declared by the
/// query. A batch is valid only for the duration of its `Query::for_each_table`
/// callback.
pub struct QueryTableBatch {
  priv scope : QueryTableBatchScope
  priv data_access : QueryDataAccess
  priv data_mentions_component : (Int) -> Bool
  priv filter_mentions_component : (Int) -> Bool
  priv cleanups : Array[() -> Unit]
}

///|
/// Exact matching rows for one dense query table.
///
/// The row matcher is bound once for the table and retains the query's full
/// per-row filter semantics, including `Changed`, `Added`, and `Or`. Row
/// indices are physical indices into the accompanying `QueryTableBatch`.
pub struct QueryTableRows {
  priv scope : QueryTableBatchScope
  priv matches : (@core.Entity, Int) -> Bool
}

///|
/// A read-only typed column bound once for a query table.
pub struct TableBatchRead[T] {
  priv scope : QueryTableBatchScope
  priv binding : QueryTableBatchColumnBinding[T]
  priv key : ComponentKey[T]
}

///|
/// A writable typed column bound once for a query table.
///
/// Use the mutation methods on this type so component change ticks and changed
/// messages remain synchronized. Direct mutable array access is intentionally
/// not exposed.
pub struct TableBatchWrite[T] {
  priv scope : QueryTableBatchScope
  priv binding : QueryTableBatchColumnBinding[T]
  priv key : ComponentKey[T]
  priv local_component_id : Int
}

///|
/// A revocable mutable view of one complete table component column.
///
/// Values can be read and replaced with indexed syntax during the callback
/// that receives this view. Every operation aborts after that callback returns;
/// retaining the view never retains usable write access to the ECS column.
pub struct TableBatchMutValues[T] {
  priv mut active : Bool
  priv values : MutArrayView[T]
}

///|
fn[T] TableBatchMutValues::invalidate(self : TableBatchMutValues[T]) -> Unit {
  self.active = false
}

///|
fn[T] TableBatchMutValues::ensure_active(self : TableBatchMutValues[T]) -> Unit {
  if !self.active {
    abort("table batch mutable values used outside its callback")
  }
}

///|
pub fn[T] TableBatchMutValues::length(self : TableBatchMutValues[T]) -> Int {
  self.ensure_active()
  self.values.length()
}

///|
pub fn[T] TableBatchMutValues::op_get(
  self : TableBatchMutValues[T],
  row_index : Int,
) -> T {
  self.ensure_active()
  self.values[row_index]
}

///|
pub fn[T] TableBatchMutValues::op_set(
  self : TableBatchMutValues[T],
  row_index : Int,
  value : T,
) -> Unit {
  self.ensure_active()
  self.values[row_index] = value
}

///|
/// Callback-scoped change metadata writer for one bound table column.
///
/// The table column, change tick, and optional caller location are resolved
/// once when the writer is created. Use this when reference-typed component
/// values are mutated in place and only selected rows should be marked changed.
/// The writer becomes invalid when its callback returns.
pub struct TableBatchChangeWriter {
  priv mut active : Bool
  priv row_count : Int
  priv scope : QueryTableBatchScope
  priv column : RawTableColumn
  priv tick : @core.Tick
  priv caller_id : Int
}

///|
fn TableBatchChangeWriter::invalidate(self : TableBatchChangeWriter) -> Unit {
  self.active = false
}

///|
pub fn TableBatchChangeWriter::set_changed(
  self : TableBatchChangeWriter,
  row_index : Int,
) -> Unit {
  if !self.active {
    abort("table batch change writer used outside its callback")
  }
  if row_index < 0 || row_index >= self.row_count {
    abort("table batch change writer row is out of bounds")
  }
  ignore(self.scope.entity_or_abort(row_index))
  if !self.column.record_changed_id_at_row(row_index, self.tick, self.caller_id) {
    abort("table batch change writer expected change tick metadata")
  }
}

///|
fn QueryTableBatchScope::world_or_abort(self : QueryTableBatchScope) -> World {
  self.lease.world_or_abort()
}

///|
fn QueryTableBatchScope::entities_or_abort(
  self : QueryTableBatchScope,
) -> Array[@core.Entity] {
  ignore(self.world_or_abort())
  match self.entities {
    Some(entities) => entities
    None => abort("table batch used outside its callback")
  }
}

///|
fn QueryTableBatchScope::entity_or_abort(
  self : QueryTableBatchScope,
  row_index : Int,
) -> @core.Entity {
  let entities = self.entities_or_abort()
  if row_index < 0 || row_index >= entities.length() {
    abort("table batch row is out of bounds")
  }
  if !self.whole_table && self.authorized_row != row_index {
    abort(
      "filtered table row access requires the matching QueryTableRows::for_each callback",
    )
  }
  entities[row_index]
}

///|
fn QueryTableBatchScope::with_authorized_row(
  self : QueryTableBatchScope,
  row_index : Int,
  visit : (Int) -> Unit raise EcsError,
) -> Unit raise EcsError {
  let previous_row = self.authorized_row
  self.authorized_row = row_index
  defer {
    self.authorized_row = previous_row
  }
  visit(row_index)
}

///|
fn[T] QueryTableBatchColumnBinding::values_or_abort(
  self : QueryTableBatchColumnBinding[T],
) -> Array[T] {
  match self.values {
    Some(values) => values
    None => abort("table batch column used outside its callback")
  }
}

///|
fn[T] QueryTableBatchColumnBinding::column_or_abort(
  self : QueryTableBatchColumnBinding[T],
) -> RawTableColumn {
  match self.column {
    Some(column) => column
    None => abort("table batch column used outside its callback")
  }
}

///|
fn[T] QueryTableBatchColumnBinding::invalidate(
  self : QueryTableBatchColumnBinding[T],
) -> Unit {
  self.values = None
  self.column = None
}

///|
fn QueryTableBatch::invalidate(self : QueryTableBatch) -> Unit {
  for cleanup in self.cleanups {
    cleanup()
  }
  self.cleanups.clear()
  self.scope.entities = None
  self.scope.lease.invalidate()
}

///|
fn QueryTableBatch::allows_read(
  self : QueryTableBatch,
  component_id : Int,
) -> Bool {
  self.data_access.read_component_set.contains(component_id) ||
  self.data_access.write_component_set.contains(component_id)
}

///|
fn QueryTableBatch::allows_write(
  self : QueryTableBatch,
  component_id : Int,
) -> Bool {
  self.data_access.write_component_set.contains(component_id)
}

///|
fn QueryTableBatch::mentions_component(
  self : QueryTableBatch,
  component_id : Int,
) -> Bool {
  (self.data_mentions_component)(component_id) ||
  (self.filter_mentions_component)(component_id)
}

///|
pub fn QueryTableBatch::length(self : QueryTableBatch) -> Int {
  self.scope.entities_or_abort().length()
}

///|
pub fn QueryTableBatch::entity(
  self : QueryTableBatch,
  row_index : Int,
) -> @core.Entity {
  self.scope.entity_or_abort(row_index)
}

///|
/// Provides one callback-scoped view of this complete table's entity column.
///
/// The view covers only live entity rows and is valid only during `read`.
/// Retaining it after the callback is invalid. This operation is available
/// only from `Query::for_each_table`; filtered row batches must preserve their
/// exact row matcher and use `QueryTableBatch::entity`.
pub fn QueryTableBatch::with_entities(
  self : QueryTableBatch,
  read : (ArrayView[@core.Entity]) -> Unit,
) -> Unit {
  if !self.scope.whole_table {
    abort("QueryTableBatch::with_entities requires Query::for_each_table")
  }
  let entities = self.scope.entities_or_abort()
  read(entities[:])
}

///|
/// Visits the physical table rows that satisfy the query filter.
///
/// This row set is valid only for the duration of its
/// `Query::try_for_each_filtered_table` callback.
pub fn QueryTableRows::for_each(
  self : QueryTableRows,
  visit : (Int) -> Unit raise EcsError,
) -> Unit raise EcsError {
  let entities = self.scope.entities_or_abort()
  for row_index in 0..<entities.length() {
    if (self.matches)(entities[row_index], row_index) {
      self.scope.with_authorized_row(row_index, visit)
    }
  }
}

///|
/// Provides a callback-scoped read view bound to this filtered row set.
///
/// The callback still must iterate with `QueryTableRows::for_each`; the view is
/// the complete physical table column so matching row indices can be resolved
/// without repeating batch lease and entity validation. The column and rows
/// must originate from the same batch callback.
pub fn[T] QueryTableRows::with_read_values(
  self : QueryTableRows,
  column : TableBatchRead[T],
  read : (ArrayView[T]) -> Unit,
) -> Unit {
  if !physical_equal(self.scope, column.scope) {
    abort("filtered table rows and read column must belong to the same batch")
  }
  let row_count = self.scope.entities_or_abort().length()
  read(column.binding.values_or_abort()[:row_count])
}

///|
/// Provides a callback-scoped read view of a writable column bound to this
/// filtered row set.
///
/// The returned `ArrayView` cannot replace values. Mutations must still use
/// `TableBatchWrite` so change ticks, callers, messages, and finalizers remain
/// synchronized. The callback must iterate with `QueryTableRows::for_each`.
pub fn[T] QueryTableRows::with_write_values(
  self : QueryTableRows,
  column : TableBatchWrite[T],
  read : (ArrayView[T]) -> Unit,
) -> Unit {
  if !physical_equal(self.scope, column.scope) {
    abort("filtered table rows and write column must belong to the same batch")
  }
  let row_count = self.scope.entities_or_abort().length()
  read(column.binding.values_or_abort()[:row_count])
}

///|
pub fn[T] QueryTableBatch::read(
  self : QueryTableBatch,
  key : ComponentKey[T],
) -> TableBatchRead[T]? {
  let component_id = key.id()
  if !self.allows_read(component_id) {
    abort(
      "table batch read requires the component to be declared as Read or Write in the Query data",
    )
  }
  let world = self.scope.world_or_abort()
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return None
  }
  if world.local_component_storage_type(local_component_id) != Some(Table) {
    abort("table batch read requires table component storage")
  }
  guard world.table_storage(self.scope.table_id) is Some(table_ref) else {
    abort("table batch expected a live table")
  }
  guard table_ref.column(local_component_id) is Some(column) else {
    return None
  }
  guard key.component_bind_table_values(world, self.scope.table_id)
    is Some(values) else {
    abort("table batch expected a typed table column")
  }
  if values.length() < self.length() {
    abort("table batch typed read column is shorter than its entity column")
  }
  let binding = QueryTableBatchColumnBinding::{
    values: Some(values),
    column: Some(column),
  }
  self.cleanups.push(fn() { binding.invalidate() })
  Some({ scope: self.scope, binding, key })
}

///|
pub fn[T] QueryTableBatch::write(
  self : QueryTableBatch,
  key : ComponentKey[T],
) -> TableBatchWrite[T]? {
  let component_id = key.id()
  if !self.allows_write(component_id) {
    abort(
      "table batch write requires the component to be declared as Write in the Query data",
    )
  }
  let world = self.scope.world_or_abort()
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return None
  }
  if world.local_component_storage_type(local_component_id) != Some(Table) {
    abort("table batch write requires table component storage")
  }
  guard world.table_storage(self.scope.table_id) is Some(table_ref) else {
    abort("table batch expected a live table")
  }
  guard table_ref.column(local_component_id) is Some(column) else {
    return None
  }
  guard key.component_bind_table_values(world, self.scope.table_id)
    is Some(values) else {
    abort("table batch expected a typed table column")
  }
  if values.length() < self.length() {
    abort("table batch typed write column is shorter than its entity column")
  }
  let binding = QueryTableBatchColumnBinding::{
    values: Some(values),
    column: Some(column),
  }
  self.cleanups.push(fn() { binding.invalidate() })
  Some({ scope: self.scope, binding, key, local_component_id })
}

///|
pub fn[T] QueryTableBatch::has(
  self : QueryTableBatch,
  key : ComponentKey[T],
) -> Bool {
  let component_id = key.id()
  if !self.mentions_component(component_id) {
    abort(
      "table batch presence access requires the component to be declared by the Query data or filter",
    )
  }
  let world = self.scope.world_or_abort()
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return false
  }
  if world.local_component_storage_type(local_component_id) != Some(Table) {
    abort("table batch presence access requires table component storage")
  }
  world.table_has_component_local_id(self.scope.table_id, local_component_id)
}

///|
pub fn[T] TableBatchRead::value(self : TableBatchRead[T], row_index : Int) -> T {
  ignore(self.scope.entity_or_abort(row_index))
  self.binding.values_or_abort()[row_index]
}

///|
/// Provides one callback-scoped read-only view of this complete table column.
///
/// The view covers only live entity rows and is valid only during `read`.
/// Retaining it after the callback is invalid. This operation is available
/// only from `Query::for_each_table`; filtered row batches must preserve their
/// exact row matcher and use `TableBatchRead::value`.
pub fn[T] TableBatchRead::with_values(
  self : TableBatchRead[T],
  read : (ArrayView[T]) -> Unit,
) -> Unit {
  if !self.scope.whole_table {
    abort("TableBatchRead::with_values requires Query::for_each_table")
  }
  let row_count = self.scope.entities_or_abort().length()
  read(self.binding.values_or_abort()[:row_count])
}

///|
pub fn[T] TableBatchRead::key(self : TableBatchRead[T]) -> ComponentKey[T] {
  self.key
}

///|
pub fn[T] TableBatchRead::is_added(
  self : TableBatchRead[T],
  row_index : Int,
) -> Bool {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().added_tick_at_row(row_index) {
    Some(tick) =>
      self.scope.world_or_abort().get_tick_context().ticks().contains(tick)
    None => abort("table batch read expected added tick metadata")
  }
}

///|
pub fn[T] TableBatchRead::is_changed(
  self : TableBatchRead[T],
  row_index : Int,
) -> Bool {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().changed_tick_at_row(row_index) {
    Some(tick) =>
      self.scope.world_or_abort().get_tick_context().ticks().contains(tick)
    None => abort("table batch read expected changed tick metadata")
  }
}

///|
pub fn[T] TableBatchRead::added(
  self : TableBatchRead[T],
  row_index : Int,
) -> @core.Tick {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().added_tick_at_row(row_index) {
    Some(tick) => tick
    None => abort("table batch read expected added tick metadata")
  }
}

///|
pub fn[T] TableBatchRead::last_changed(
  self : TableBatchRead[T],
  row_index : Int,
) -> @core.Tick {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().changed_tick_at_row(row_index) {
    Some(tick) => tick
    None => abort("table batch read expected changed tick metadata")
  }
}

///|
pub fn[T] TableBatchRead::changed_by(
  self : TableBatchRead[T],
  row_index : Int,
) -> String? {
  ignore(self.scope.entity_or_abort(row_index))
  self.binding.column_or_abort().changed_caller_at_row(row_index)
}

///|
pub fn[T] TableBatchWrite::peek(
  self : TableBatchWrite[T],
  row_index : Int,
) -> T {
  ignore(self.scope.entity_or_abort(row_index))
  self.binding.values_or_abort()[row_index]
}

///|
pub fn[T] TableBatchWrite::key(self : TableBatchWrite[T]) -> ComponentKey[T] {
  self.key
}

///|
pub fn[T] TableBatchWrite::value(
  self : TableBatchWrite[T],
  row_index : Int,
) -> T {
  self.peek(row_index)
}

///|
pub fn[T] TableBatchWrite::is_added(
  self : TableBatchWrite[T],
  row_index : Int,
) -> Bool {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().added_tick_at_row(row_index) {
    Some(tick) =>
      self.scope.world_or_abort().get_tick_context().ticks().contains(tick)
    None => abort("table batch write expected added tick metadata")
  }
}

///|
pub fn[T] TableBatchWrite::is_changed(
  self : TableBatchWrite[T],
  row_index : Int,
) -> Bool {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().changed_tick_at_row(row_index) {
    Some(tick) =>
      self.scope.world_or_abort().get_tick_context().ticks().contains(tick)
    None => abort("table batch write expected changed tick metadata")
  }
}

///|
pub fn[T] TableBatchWrite::added(
  self : TableBatchWrite[T],
  row_index : Int,
) -> @core.Tick {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().added_tick_at_row(row_index) {
    Some(tick) => tick
    None => abort("table batch write expected added tick metadata")
  }
}

///|
pub fn[T] TableBatchWrite::last_changed(
  self : TableBatchWrite[T],
  row_index : Int,
) -> @core.Tick {
  ignore(self.scope.entity_or_abort(row_index))
  match self.binding.column_or_abort().changed_tick_at_row(row_index) {
    Some(tick) => tick
    None => abort("table batch write expected changed tick metadata")
  }
}

///|
pub fn[T] TableBatchWrite::changed_by(
  self : TableBatchWrite[T],
  row_index : Int,
) -> String? {
  ignore(self.scope.entity_or_abort(row_index))
  self.binding.column_or_abort().changed_caller_at_row(row_index)
}

///|
fn[T] TableBatchWrite::mark_changed(
  self : TableBatchWrite[T],
  row_index : Int,
  caller : String?,
) -> Unit {
  ignore(self.scope.entity_or_abort(row_index))
  let world = self.scope.world_or_abort()
  let tick = component_write_tick(world)
  if !self.binding
    .column_or_abort()
    .record_changed_at_row(row_index, tick, caller) {
    abort("table batch write expected change tick metadata")
  }
}

///|
fn[T] TableBatchWrite::assign(
  self : TableBatchWrite[T],
  row_index : Int,
  value : T,
) -> Unit {
  ignore(self.scope.entity_or_abort(row_index))
  let world = self.scope.world_or_abort()
  if !world.replace_component_value_at_table_row(
      self.key,
      self.local_component_id,
      self.scope.table_id,
      row_index,
      value,
    ) {
    abort("table batch write expected a writable table component row")
  }
}

///|
#callsite(autofill(loc))
pub fn[T : Component] TableBatchWrite::set_changed(
  self : TableBatchWrite[T],
  row_index : Int,
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  self.mark_changed(
    row_index,
    hook_caller_from_loc(self.scope.world_or_abort(), loc),
  )
}

///|
/// Binds change metadata once for selected in-place row mutations.
///
/// This preserves ordinary component change detection. It only removes the
/// repeated table, world-tick, and call-site resolution otherwise performed by
/// one `set_changed` call per row.
#callsite(autofill(loc))
pub fn[T : Component] TableBatchWrite::with_change_writer(
  self : TableBatchWrite[T],
  write : (TableBatchChangeWriter) -> Unit,
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  let row_count = self.scope.entities_or_abort().length()
  let world = self.scope.world_or_abort()
  let writer = TableBatchChangeWriter::{
    active: true,
    row_count,
    scope: self.scope,
    column: self.binding.column_or_abort(),
    tick: component_write_tick(world),
    caller_id: raw_table_store_changed_caller(hook_caller_from_loc(world, loc)),
  }
  defer writer.invalidate()
  write(writer)
}

///|
#callsite(autofill(loc))
pub fn[T : Component] TableBatchWrite::set_added(
  self : TableBatchWrite[T],
  row_index : Int,
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  let entity = self.scope.entity_or_abort(row_index)
  let world = self.scope.world_or_abort()
  let caller = hook_caller_from_loc(world, loc)
  world.record_component_added_with_caller(entity, self.key.id(), caller)
  world
  .ensure_added_component_messages(self.key.id())
  .send(component_write_tick(world), entity)
  world.record_component_changed_with_caller(entity, self.key.id(), caller)
}

///|
#callsite(autofill(loc))
pub fn[T, R] TableBatchWrite::modify(
  self : TableBatchWrite[T],
  row_index : Int,
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let result = f(self.peek(row_index))
  self.mark_changed(
    row_index,
    hook_caller_from_loc(self.scope.world_or_abort(), loc),
  )
  result
}

///|
/// Updates every row in this writable table column through one mutable view.
///
/// The view covers only the live entity rows and is valid only during
/// `update`. Retaining it after the callback does not retain access: all
/// subsequent operations abort. Every row is marked changed after the callback
/// returns. This operation is available only from `Query::for_each_table`; a
/// filtered row batch cannot safely update its whole physical column.
/// Components with custom finalizers must use `set` so replaced values are
/// finalized.
#callsite(autofill(loc))
pub fn[T] TableBatchWrite::update_inplace(
  self : TableBatchWrite[T],
  update : (TableBatchMutValues[T]) -> Unit,
  loc~ : SourceLoc,
) -> Unit {
  if !self.scope.whole_table {
    abort("TableBatchWrite::update_inplace requires Query::for_each_table")
  }
  if self.key.component_has_custom_finalizer() {
    abort(
      "TableBatchWrite::update_inplace does not support components with custom finalizers",
    )
  }
  let row_count = self.scope.entities_or_abort().length()
  let values = self.binding.values_or_abort()
  let mut_values = TableBatchMutValues::{
    active: true,
    values: values.mut_view(end=row_count),
  }
  defer mut_values.invalidate()
  update(mut_values)
  let world = self.scope.world_or_abort()
  let tick = component_write_tick(world)
  let caller = hook_caller_from_loc(world, loc)
  let column = self.binding.column_or_abort()
  for row_index in 0..<row_count {
    if !column.record_changed_at_row(row_index, tick, caller) {
      abort("table batch write expected change tick metadata")
    }
  }
}

///|
/// Updates every row in this writable table column without recording change
/// ticks, matching Bevy's `bypass_change_detection` semantics for bulk state.
///
/// Like `update_inplace`, this is valid only for a complete table column and
/// rejects components with custom finalizers.
pub fn[T] TableBatchWrite::update_inplace_bypass_change_detection(
  self : TableBatchWrite[T],
  update : (TableBatchMutValues[T]) -> Unit,
) -> Unit {
  if !self.scope.whole_table {
    abort(
      "TableBatchWrite::update_inplace_bypass_change_detection requires Query::for_each_table",
    )
  }
  if self.key.component_has_custom_finalizer() {
    abort(
      "TableBatchWrite::update_inplace_bypass_change_detection does not support components with custom finalizers",
    )
  }
  let row_count = self.scope.entities_or_abort().length()
  let mut_values = TableBatchMutValues::{
    active: true,
    values: self.binding.values_or_abort().mut_view(end=row_count),
  }
  defer mut_values.invalidate()
  update(mut_values)
}

///|
/// Updates one row without marking it changed.
///
/// Returning the same reference preserves its ownership; returning a different
/// value replaces and finalizes the displaced component normally.
pub fn[T] TableBatchWrite::bypass_change_detection(
  self : TableBatchWrite[T],
  row_index : Int,
  update : (T) -> T,
) -> Unit {
  let value = self.peek(row_index)
  let replacement = update(value)
  if !physical_equal(value, replacement) {
    self.assign(row_index, replacement)
  }
}

///|
#callsite(autofill(loc))
pub fn[T : Eq] TableBatchWrite::set_if_neq(
  self : TableBatchWrite[T],
  row_index : Int,
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  if self.peek(row_index) != value {
    self.set(row_index, value, loc~)
    true
  } else {
    false
  }
}

///|
#callsite(autofill(loc))
pub fn[T] TableBatchWrite::set(
  self : TableBatchWrite[T],
  row_index : Int,
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  self.mark_changed(
    row_index,
    hook_caller_from_loc(self.scope.world_or_abort(), loc),
  )
  self.assign(row_index, value)
}

///|
fn query_visit_table_batch(
  batch : QueryTableBatch,
  visit : (QueryTableBatch) -> Unit raise EcsError,
) -> Unit raise EcsError {
  defer batch.invalidate()
  visit(batch)
}

///|
fn query_visit_filtered_table_batch(
  batch : QueryTableBatch,
  rows : QueryTableRows,
  visit : (QueryTableBatch, QueryTableRows) -> Unit raise EcsError,
) -> Unit raise EcsError {
  defer batch.invalidate()
  visit(batch, rows)
}

///|
/// Visits each matching dense table once.
///
/// This is the MoonBit batch counterpart of Bevy's table-bound contiguous
/// query fetch. It preserves the original query's component access and
/// archetypal filter semantics, but rejects sparse data and filters that need
/// per-row evaluation.
pub fn[D : QueryData, F : QueryFilter] Query::for_each_table(
  self : Query[D, F],
  visit : (QueryTableBatch) -> Unit raise EcsError,
) -> Unit raise EcsError {
  let world = self.world_or_abort()
  let plan = self.iteration_plan(self.default_filter_component_ids())
  if !plan.dense_driven {
    raise TableBatchUnavailable(
      "Query::for_each_table requires conflict-free dense query data and an archetypal dense filter",
    )
  }
  if plan.table_row_filter_required {
    raise TableBatchUnavailable(
      "Query::for_each_table does not support filters that require per-row evaluation",
    )
  }
  let data_access = QueryDataAccess::new()
  D::collect_access(data_access)
  D::collect_required_components(data_access)
  world.begin_query_iteration()
  defer world.end_query_iteration()
  for table_id in plan.dense_tables {
    guard world.table_entities_view(table_id) is Some(entities) else {
      continue
    }
    if entities.length() == 0 {
      continue
    }
    let filter = self.filter
    let batch = QueryTableBatch::{
      scope: {
        lease: WorldLease::new(world),
        table_id,
        entities: Some(entities),
        whole_table: true,
        authorized_row: -1,
      },
      data_access,
      data_mentions_component: fn(component_id) {
        D::mentions_component(component_id)
      },
      filter_mentions_component: fn(component_id) {
        QueryFilter::mentions_component(filter, component_id)
      },
      cleanups: [],
    }
    query_visit_table_batch(batch, visit)
  }
}

///|
/// Visits each matching dense table once with an exact per-row filter view.
///
/// Unlike `Query::for_each_table`, this API accepts dense filters that require
/// row evaluation. The filter binds its table-local state once, and callers
/// must traverse `QueryTableRows` to preserve `Changed`, `Added`, `Or`, and
/// custom row-filter semantics.
pub fn[D : QueryData, F : QueryFilter] Query::try_for_each_filtered_table(
  self : Query[D, F],
  visit : (QueryTableBatch, QueryTableRows) -> Unit raise EcsError,
) -> Bool raise EcsError {
  let world = self.world_or_abort()
  let plan = self.iteration_plan(self.default_filter_component_ids())
  if !plan.dense_driven {
    return false
  }
  let data_access = QueryDataAccess::new()
  D::collect_access(data_access)
  D::collect_required_components(data_access)
  world.begin_query_iteration()
  defer world.end_query_iteration()
  for table_id in plan.dense_tables {
    guard world.table_entities_view(table_id) is Some(entities) else {
      continue
    }
    if entities.length() == 0 {
      continue
    }
    let filter = self.filter
    let scope = QueryTableBatchScope::{
      lease: WorldLease::new(world),
      table_id,
      entities: Some(entities),
      whole_table: false,
      authorized_row: -1,
    }
    let batch = QueryTableBatch::{
      scope,
      data_access,
      data_mentions_component: fn(component_id) {
        D::mentions_component(component_id)
      },
      filter_mentions_component: fn(component_id) {
        QueryFilter::mentions_component(filter, component_id)
      },
      cleanups: [],
    }
    let rows = QueryTableRows::{
      scope,
      matches: QueryFilter::bind_table_row_matcher(filter, world, table_id),
    }
    query_visit_filtered_table_batch(batch, rows, visit)
  }
  true
}
