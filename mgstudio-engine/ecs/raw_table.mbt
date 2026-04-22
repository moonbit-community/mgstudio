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
pub(all) struct RawTableColumnOps {
  payload_at_row : (@any.Any, Int) -> ErasedValue?
  replace_payload_at_row : (@any.Any, Int, ErasedValue) -> Bool
  append_payload : (@any.Any, ErasedValue) -> Bool
  swap_remove_row : (@any.Any, Int) -> Bool
}

///|
pub(all) struct RawTableColumnDescriptor {
  new_values : () -> @any.Any
  ops : RawTableColumnOps
}

///|
let component_table_column_descriptors : @hashmap.HashMap[
  Int,
  RawTableColumnDescriptor,
] = @hashmap.HashMap::new()

///|
fn raw_table_invalid_sequence() -> @core.Sequence {
  -1
}

///|
fn raw_table_store_sequence(sequence : @core.Sequence?) -> @core.Sequence {
  match sequence {
    Some(sequence) => sequence
    None => raw_table_invalid_sequence()
  }
}

///|
fn raw_table_load_sequence(sequence : @core.Sequence) -> @core.Sequence? {
  if sequence < 0 {
    None
  } else {
    Some(sequence)
  }
}

///|
fn[T] raw_table_column_descriptor_for_key(
  _key : ComponentKey[T],
) -> RawTableColumnDescriptor {
  let ops : RawTableColumnOps = {
    payload_at_row: fn(values_any, row_index) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return None
      }
      Some(erased_value(values[row_index]))
    },
    replace_payload_at_row: fn(values_any, row_index, payload) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return false
      }
      values[row_index] = payload.unsafe_to_value()
      true
    },
    append_payload: fn(values_any, payload) {
      let values : Array[T] = values_any.unsafe_coerce()
      values.push(payload.unsafe_to_value())
      true
    },
    swap_remove_row: fn(values_any, row_index) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return false
      }
      let last_index = values.length() - 1
      if row_index != last_index {
        values[row_index] = values[last_index]
      }
      ignore(values.pop())
      true
    },
  }
  {
    new_values: fn() {
      let values : Array[T] = []
      @any.of(values)
    },
    ops,
  }
}

///|
fn[T] register_component_table_column_descriptor(
  component_id : Int,
  key : ComponentKey[T],
) -> Unit {
  if component_table_column_descriptors.get(component_id) is Some(_) {
    return
  }
  let descriptor = raw_table_column_descriptor_for_key(key)
  component_table_column_descriptors.set(component_id, descriptor)
}

///|
fn component_table_column_descriptor(
  component_id : Int,
) -> RawTableColumnDescriptor {
  match component_table_column_descriptors.get(component_id) {
    Some(descriptor) => descriptor
    None =>
      abort(
        "Missing raw table column descriptor for component definition \{component_id.to_string()}",
      )
  }
}

///|
priv struct RawTableColumn {
  values : @any.Any
  ops : RawTableColumnOps
  mut added_sequences : Array[@core.Sequence]
  mut changed_sequences : Array[@core.Sequence]
  mut changed_callers : Array[String?]
}

///|
struct RawTable {
  component_local_ids : Array[Int]
  component_indices : Map[Int, Int]
  rows : RawTableRowKernel
  columns : Array[Ref[RawTableColumn]]
}

///|
priv struct RawTableSwapRemoveResult {
  removed_entity : @core.Entity
  swapped_entity : @core.Entity?
  swapped_row : TableRow?
}

///|
fn raw_table_column_new(
  descriptor : RawTableColumnDescriptor,
) -> RawTableColumn {
  {
    values: (descriptor.new_values)(),
    ops: descriptor.ops,
    added_sequences: [],
    changed_sequences: [],
    changed_callers: [],
  }
}

///|
fn RawTableColumn::payload_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> ErasedValue? {
  (self.ops.payload_at_row)(self.values, row_index)
}

///|
fn RawTableColumn::replace_payload_at_row(
  self : RawTableColumn,
  row_index : Int,
  payload : ErasedValue,
) -> Bool {
  (self.ops.replace_payload_at_row)(self.values, row_index, payload)
}

///|
fn RawTableColumn::append_payload(
  self : RawTableColumn,
  payload : ErasedValue,
) -> Bool {
  (self.ops.append_payload)(self.values, payload)
}

///|
fn RawTableColumn::append_metadata(self : RawTableColumn) -> Unit {
  self.added_sequences.push(raw_table_invalid_sequence())
  self.changed_sequences.push(raw_table_invalid_sequence())
  self.changed_callers.push(None)
}

///|
fn RawTableColumn::set_metadata_at_row(
  self : RawTableColumn,
  row_index : Int,
  added_sequence : @core.Sequence?,
  changed_sequence : @core.Sequence?,
  changed_caller : String?,
) -> Bool {
  if row_index < 0 || row_index >= self.added_sequences.length() {
    return false
  }
  self.added_sequences[row_index] = raw_table_store_sequence(added_sequence)
  self.changed_sequences[row_index] = raw_table_store_sequence(
    changed_sequence,
  )
  self.changed_callers[row_index] = changed_caller
  true
}

///|
fn RawTableColumn::added_sequence_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Sequence? {
  if row_index < 0 || row_index >= self.added_sequences.length() {
    return None
  }
  raw_table_load_sequence(self.added_sequences[row_index])
}

///|
fn RawTableColumn::changed_sequence_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Sequence? {
  if row_index < 0 || row_index >= self.changed_sequences.length() {
    return None
  }
  raw_table_load_sequence(self.changed_sequences[row_index])
}

///|
fn RawTableColumn::changed_caller_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> String? {
  if row_index < 0 || row_index >= self.changed_callers.length() {
    return None
  }
  self.changed_callers[row_index]
}

///|
fn RawTableColumn::record_added_at_row(
  self : RawTableColumn,
  row_index : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  self.set_metadata_at_row(
    row_index,
    Some(sequence),
    self.changed_sequence_at_row(row_index),
    caller,
  )
}

///|
fn RawTableColumn::record_changed_at_row(
  self : RawTableColumn,
  row_index : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  self.set_metadata_at_row(
    row_index,
    self.added_sequence_at_row(row_index),
    Some(sequence),
    caller,
  )
}

///|
fn[T] RawTableColumn::value_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> T? raise @any.TypeMismatch {
  let values : Array[T] = self.values.to()
  if row_index < 0 || row_index >= values.length() {
    return None
  }
  Some(values[row_index])
}

///|
fn[T] RawTableColumn::replace_value_at_row(
  self : RawTableColumn,
  row_index : Int,
  value : T,
) -> Bool raise @any.TypeMismatch {
  let values : Array[T] = self.values.to()
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  values[row_index] = value
  true
}

///|
fn RawTableColumn::type_name(self : RawTableColumn) -> String {
  self.values.type_name()
}

///|
fn raw_table_column_swap_remove(
  column_ref : Ref[RawTableColumn],
  row_index : Int,
) -> Bool {
  let column = column_ref.val
  if !(column.ops.swap_remove_row)(column.values, row_index) {
    return false
  }
  let last_index = column.added_sequences.length() - 1
  if row_index < 0 || row_index > last_index {
    return false
  }
  if row_index != last_index {
    column.added_sequences[row_index] = column.added_sequences[last_index]
    column.changed_sequences[row_index] = column.changed_sequences[last_index]
    column.changed_callers[row_index] = column.changed_callers[last_index]
  }
  ignore(column.added_sequences.pop())
  ignore(column.changed_sequences.pop())
  ignore(column.changed_callers.pop())
  true
}

///|
fn raw_table_new(world : World, component_local_ids : Array[Int]) -> RawTable {
  let component_indices : Map[Int, Int] = {}
  let columns : Array[Ref[RawTableColumn]] = []
  for index in 0..<component_local_ids.length() {
    let component_local_id = component_local_ids[index]
    component_indices.set(component_local_id, index)
    let definition_id = match world.definition_component_id(component_local_id) {
      Some(definition_id) => definition_id
      None =>
        abort(
          "Missing component definition id for local component \{component_local_id.to_string()}",
        )
    }
    let descriptor = component_table_column_descriptor(definition_id)
    columns.push(Ref::new(raw_table_column_new(descriptor)))
  }
  {
    component_local_ids: component_local_ids.copy(),
    component_indices,
    rows: raw_table_row_kernel_new(),
    columns,
  }
}

///|
fn RawTable::row_count(self : RawTable) -> Int {
  raw_table_row_kernel_len(self.rows)
}

///|
fn RawTable::component_index(self : RawTable, component_local_id : Int) -> Int? {
  self.component_indices.get(component_local_id)
}

///|
fn RawTable::column(
  self : RawTable,
  component_local_id : Int,
) -> Ref[RawTableColumn]? {
  guard self.component_index(component_local_id) is Some(component_index) else {
    return None
  }
  Some(self.columns[component_index])
}

///|
fn RawTable::column_type_name(
  self : RawTable,
  component_local_id : Int,
) -> String? {
  match self.column(component_local_id) {
    Some(column_ref) => Some(column_ref.val.type_name())
    None => None
  }
}

///|
fn RawTable::entity_at_row(self : RawTable, row : TableRow) -> @core.Entity? {
  raw_table_row_kernel_entity_at(self.rows, row.index())
}

///|
fn RawTable::payload_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> ErasedValue? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.payload_at_row(row.index())
}

///|
fn[T] RawTable::value_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> T? raise @any.TypeMismatch {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.value_at_row(row.index())
}

///|
fn RawTable::replace_payload_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  payload : ErasedValue,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.replace_payload_at_row(row.index(), payload)
}

///|
fn[T] RawTable::replace_value_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  value : T,
) -> Bool raise @any.TypeMismatch {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.replace_value_at_row(row.index(), value)
}

///|
fn RawTable::set_metadata_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  added_sequence : @core.Sequence?,
  changed_sequence : @core.Sequence?,
  changed_caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.set_metadata_at_row(
    row.index(),
    added_sequence,
    changed_sequence,
    changed_caller,
  )
}

///|
fn RawTable::added_sequence_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Sequence? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.added_sequence_at_row(row.index())
}

///|
fn RawTable::changed_sequence_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Sequence? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.changed_sequence_at_row(row.index())
}

///|
fn RawTable::changed_caller_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> String? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.changed_caller_at_row(row.index())
}

///|
fn RawTable::record_added_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.record_added_at_row(row.index(), sequence, caller)
}

///|
fn RawTable::record_changed_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.record_changed_at_row(row.index(), sequence, caller)
}

///|
fn RawTable::append_row(
  self : RawTable,
  entity : @core.Entity,
  ordered_payloads : Array[ErasedValue],
) -> TableRow? {
  if ordered_payloads.length() != self.columns.length() {
    return None
  }
  let row = raw_table_row_kernel_push(self.rows, entity)
  for column_index in 0..<self.columns.length() {
    let column = self.columns[column_index].val
    if !column.append_payload(ordered_payloads[column_index]) {
      return None
    }
    column.append_metadata()
  }
  TableRow::from_index(row)
}

///|
fn RawTable::swap_remove_row(
  self : RawTable,
  row : TableRow,
) -> RawTableSwapRemoveResult? {
  let row_index = row.index()
  let len = self.row_count()
  if row_index < 0 || row_index >= len {
    return None
  }
  let removed_entity = match self.entity_at_row(row) {
    Some(entity) => entity
    None => return None
  }
  let last_row_index = len - 1
  let swapped_entity = if row_index == last_row_index {
    None
  } else {
    raw_table_row_kernel_entity_at(self.rows, last_row_index)
  }
  for column_ref in self.columns {
    ignore(raw_table_column_swap_remove(column_ref, row_index))
  }
  guard raw_table_row_kernel_swap_remove(self.rows, row_index) else {
    return None
  }
  Some({
    removed_entity,
    swapped_entity,
    swapped_row: if row_index == last_row_index {
      None
    } else {
      TableRow::from_index(row_index)
    },
  })
}

///|
fn World::ensure_table_storage(self : World, table_id : Int) -> Ref[RawTable] {
  let component_local_ids = self.table_component_local_ids
    .get(table_id)
    .unwrap_or([])
  self.tables.get_or_init(table_id, fn() {
    Ref::new(raw_table_new(self, component_local_ids))
  })
}

///|
fn World::table_storage(self : World, table_id : Int) -> Ref[RawTable]? {
  self.tables.get(table_id)
}

///|
fn World::pending_component_payload(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id {
        context.payloads.get(local_component_id)
      } else {
        None
      }
    None => None
  }
}

///|
fn World::push_pending_component_payload_context(
  self : World,
  entity : @core.Entity,
  payloads : Map[Int, ErasedValue],
) -> PendingComponentPayloadContext? {
  let previous = self.pending_component_payload_context
  self.pending_component_payload_context = Some({
    entity_id: entity.id,
    payloads,
  })
  previous
}

///|
fn World::restore_pending_component_payload_context(
  self : World,
  previous : PendingComponentPayloadContext?,
) -> Unit {
  self.pending_component_payload_context = previous
}

///|
fn World::table_id_for_entity(self : World, entity : @core.Entity) -> Int? {
  self.table_id_for_entity_id(entity.id)
}

///|
fn World::table_id_for_entity_id(self : World, entity_id : Int) -> Int? {
  guard entity_id >= 0 && entity_id < self.entity_archetype_ids.length() else {
    return None
  }
  let archetype_id = self.entity_archetype_ids[entity_id]
  if archetype_id < 0 {
    return None
  }
  self.archetype_table_ids.get(archetype_id)
}

///|
fn World::entity_table_row(self : World, entity : @core.Entity) -> TableRow? {
  self.entity_table_row_by_id(entity.id)
}

///|
fn World::entity_table_row_by_id(self : World, entity_id : Int) -> TableRow? {
  guard entity_id >= 0 && entity_id < self.entity_table_rows.length() else {
    return None
  }
  TableRow::from_index(self.entity_table_rows[entity_id])
}

///|
fn[T] World::component_value_by_local_id(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  local_component_id : Int,
) -> T? raise EcsError {
  if self.pending_component_payload(entity, local_component_id) is Some(payload) {
    return Some(self.component_value(key, entity, payload))
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) =>
      match self.sparse_component_columns.get(local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => Some(self.component_value(key, entity, payload))
            None => None
          }
        None => None
      }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return None
      }
      guard self.table_storage(table_id) is Some(table_ref) else { return None }
      guard self.entity_table_row(entity) is Some(row) else { return None }
      let result : Result[T?, @any.TypeMismatch] = try? table_ref.val.value_at_row(
        row,
        local_component_id,
      )
      match result {
        Ok(value) => value
        Err(_) =>
          raise ComponentTypeMismatch(
            key.id(),
            key.debug_name(),
            entity,
            table_ref.val.column_type_name(local_component_id).unwrap_or(
              "unknown",
            ),
          )
      }
    }
    None => None
  }
}

///|
fn[T] World::component_value_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  match self.local_component_id(key.id()) {
    Some(local_component_id) =>
      self.component_value_by_local_id(entity, key, local_component_id)
    None => None
  }
}

///|
fn[T] World::replace_component_value_by_local_id(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  local_component_id : Int,
  value : T,
) -> Bool raise EcsError {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.payloads.set(local_component_id, erased_value(value))
        return true
      }
    None => ()
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) => {
      let store_ref = self.ensure_component_store_for_local_id(
        local_component_id,
        SparseSet,
      )
      store_ref.val.set(entity, erased_value(value))
    }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      guard self.entity_table_row(entity) is Some(row) else { return false }
      let result : Result[Bool, @any.TypeMismatch] = try? table_ref.val
        .replace_value_at_row(row, local_component_id, value)
      match result {
        Ok(ok) => ok
        Err(_) =>
          raise ComponentTypeMismatch(
            key.id(),
            key.debug_name(),
            entity,
            table_ref.val.column_type_name(local_component_id).unwrap_or(
              "unknown",
            ),
          )
      }
    }
    None => false
  }
}

///|
fn[T] World::replace_component_value_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
) -> Bool raise EcsError {
  match self.local_component_id(key.id()) {
    Some(local_component_id) =>
      self.replace_component_value_by_local_id(
        entity,
        key,
        local_component_id,
        value,
      )
    None => false
  }
}

///|
fn World::table_component_added_sequence_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Sequence? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.added_sequence_at_row(row, local_component_id)
}

///|
fn World::table_component_changed_sequence_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Sequence? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.changed_sequence_at_row(row, local_component_id)
}

///|
fn World::table_component_changed_caller_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> String? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.changed_caller_at_row(row, local_component_id)
}

///|
fn World::record_table_component_added_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Unit {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return }
  guard self.table_storage(table_id) is Some(table_ref) else { return }
  guard self.entity_table_row(entity) is Some(row) else { return }
  ignore(
    table_ref.val.record_added_at_row(row, local_component_id, sequence, caller),
  )
}

///|
fn World::record_table_component_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Unit {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return }
  guard self.table_storage(table_id) is Some(table_ref) else { return }
  guard self.entity_table_row(entity) is Some(row) else { return }
  ignore(
    table_ref.val.record_changed_at_row(
      row,
      local_component_id,
      sequence,
      caller,
    ),
  )
}

///|
fn World::sync_table_component_metadata_for_entity(
  self : World,
  entity : @core.Entity,
  table_id : Int,
  row : TableRow,
  component_local_ids : Array[Int],
) -> Unit {
  guard self.table_storage(table_id) is Some(table_ref) else { return }
  for local_component_id in component_local_ids {
    let added_sequence = match self.added_component_sequences.get(
      local_component_id,
    ) {
      Some(sequence_by_entity) => sequence_by_entity.get(entity.id)
      None => None
    }
    let changed_sequence = match self.changed_component_sequences.get(
      local_component_id,
    ) {
      Some(sequence_by_entity) => sequence_by_entity.get(entity.id)
      None => None
    }
    let changed_caller = match self.changed_component_callers.get(
      local_component_id,
    ) {
      Some(caller_by_entity) => caller_by_entity.get(entity.id)
      None => None
    }
    ignore(
      table_ref.val.set_metadata_at_row(
        row,
        local_component_id,
        added_sequence,
        changed_sequence,
        changed_caller,
      ),
    )
  }
}

///|
fn World::component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  if self.pending_component_payload(entity, local_component_id) is Some(payload) {
    return Some(payload)
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) =>
      match self.sparse_component_columns.get(local_component_id) {
        Some(store_ref) => store_ref.val.get(entity)
        None => None
      }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return None
      }
      guard self.table_storage(table_id) is Some(table_ref) else { return None }
      guard self.entity_table_row(entity) is Some(row) else { return None }
      table_ref.val.payload_at_row(row, local_component_id)
    }
    None => None
  }
}

///|
fn World::component_payload(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
) -> ErasedValue? {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.component_payload_by_local_id(entity, local_component_id)
    None => None
  }
}

///|
fn World::replace_component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  payload : ErasedValue,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.payloads.set(local_component_id, payload)
        return true
      }
    None => ()
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) => {
      let store_ref = self.ensure_component_store_for_local_id(
        local_component_id,
        SparseSet,
      )
      store_ref.val.set(entity, payload)
    }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      guard self.entity_table_row(entity) is Some(row) else { return false }
      table_ref.val.replace_payload_at_row(row, local_component_id, payload)
    }
    None => false
  }
}

///|
fn World::replace_component_payload(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
  payload : ErasedValue,
) -> Bool {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.replace_component_payload_by_local_id(
        entity,
        local_component_id,
        payload,
      )
    None => false
  }
}

///|
fn World::remove_sparse_component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return None
  }
  match self.sparse_component_columns.get(local_component_id) {
    Some(store_ref) => store_ref.val.remove(entity)
    None => None
  }
}

///|
fn World::write_pending_sparse_component_payloads(
  self : World,
  entity : @core.Entity,
  pending_payloads : Map[Int, ErasedValue],
) -> Unit {
  for entry in pending_payloads.iter() {
    let component_local_id = entry.0
    let payload = entry.1
    if self.local_component_storage_type(component_local_id) == Some(SparseSet) {
      let store_ref = self.ensure_component_store_for_local_id(
        component_local_id,
        SparseSet,
      )
      store_ref.val.insert(entity, payload)
    }
  }
}
