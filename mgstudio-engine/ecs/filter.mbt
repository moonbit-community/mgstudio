// Copyright 2025 International Digital Economy Academy
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
pub(open) trait QueryFilter {
  fn matches(self : Self, world : World, entity : @core.Entity) -> Bool
  fn matches_table_row(
    self : Self,
    world : World,
    entity : @core.Entity,
    table_id : Int,
    row_index : Int,
  ) -> Bool = _
  fn bind_table_row_matcher(self : Self, world : World, table_id : Int) -> (
    @core.Entity,
    Int,
  ) -> Bool = _
  fn mentions_component(self : Self, component_id : Int) -> Bool
  fn matches_component_set(self : Self, set_contains_id : (Int) -> Bool) -> Bool
  fn collect_access(self : Self, access : QueryFilterAccess) -> Unit = _
  fn requires_entity_check(self : Self) -> Bool
  fn requires_entity_check_for_world(self : Self, world : World) -> Bool = _
  fn is_dense(self : Self, world : World) -> Bool = _
  fn iteration_anchor_component(self : Self) -> Int?
  fn iteration_anchor_components(self : Self) -> Array[Int] = _
  fn depends_on_ticks(self : Self) -> Bool
}

///|
pub(open) trait QueryFilterDisjunction {
  fn matches_any(self : Self, world : World, entity : @core.Entity) -> Bool
  fn matches_table_row_any(
    self : Self,
    world : World,
    entity : @core.Entity,
    table_id : Int,
    row_index : Int,
  ) -> Bool = _
  fn bind_table_row_matcher_any(self : Self, world : World, table_id : Int) -> (
    @core.Entity,
    Int,
  ) -> Bool = _
  fn mentions_component_any(self : Self, component_id : Int) -> Bool
  fn matches_component_set_any(self : Self, set_contains_id : (Int) -> Bool) -> Bool
  fn collect_access_any(self : Self, access : QueryFilterAccess) -> Unit = _
  fn requires_entity_check_any(self : Self) -> Bool
  fn requires_entity_check_any_for_world(self : Self, world : World) -> Bool = _
  fn is_dense_any(self : Self, world : World) -> Bool = _
  fn depends_on_ticks_any(self : Self) -> Bool
}

///|
impl QueryFilter with fn matches_table_row(
  self,
  world,
  entity,
  _table_id,
  _row_index,
) {
  QueryFilter::matches(self, world, entity)
}

///|
impl QueryFilter with fn bind_table_row_matcher(self, world, table_id) {
  fn(entity, row_index) {
    QueryFilter::matches_table_row(self, world, entity, table_id, row_index)
  }
}

///|
impl QueryFilter with fn collect_access(_self, _access) {
  ()
}

///|
impl QueryFilter with fn requires_entity_check_for_world(self, _world) {
  QueryFilter::requires_entity_check(self)
}

///|
impl QueryFilter with fn is_dense(_self, _world) {
  false
}

///|
impl QueryFilter with fn iteration_anchor_components(self) {
  match QueryFilter::iteration_anchor_component(self) {
    Some(component_id) => [component_id]
    None => []
  }
}

///|
impl QueryFilterDisjunction with fn matches_table_row_any(
  self,
  world,
  entity,
  _table_id,
  _row_index,
) {
  QueryFilterDisjunction::matches_any(self, world, entity)
}

///|
impl QueryFilterDisjunction with fn bind_table_row_matcher_any(
  self,
  world,
  table_id,
) {
  fn(entity, row_index) {
    QueryFilterDisjunction::matches_table_row_any(
      self, world, entity, table_id, row_index,
    )
  }
}

///|
impl QueryFilterDisjunction with fn collect_access_any(_self, _access) {
  ()
}

///|
impl QueryFilterDisjunction with fn requires_entity_check_any_for_world(
  self,
  _world,
) {
  QueryFilterDisjunction::requires_entity_check_any(self)
}

///|
impl QueryFilterDisjunction with fn is_dense_any(_self, _world) {
  false
}

///|
pub struct QueryFilterAccess {
  priv read_components : Array[Int]
  priv with_components : Array[Int]
  priv without_components : Array[Int]
  priv read_component_set : @utils.IntBitSet
  priv with_component_set : @utils.IntBitSet
  priv without_component_set : @utils.IntBitSet
}

///|
pub fn QueryFilterAccess::new() -> QueryFilterAccess {
  {
    read_components: [],
    with_components: [],
    without_components: [],
    read_component_set: @utils.IntBitSet::new(),
    with_component_set: @utils.IntBitSet::new(),
    without_component_set: @utils.IntBitSet::new(),
  }
}

///|
pub fn QueryFilterAccess::add_read_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.read_component_set.contains(component_id) {
    self.read_component_set.insert(component_id)
    self.read_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::add_with_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.with_component_set.contains(component_id) {
    self.with_component_set.insert(component_id)
    self.with_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::add_without_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.without_component_set.contains(component_id) {
    self.without_component_set.insert(component_id)
    self.without_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::read_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.read_components
}

///|
pub fn QueryFilterAccess::with_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.with_components
}

///|
pub fn QueryFilterAccess::without_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.without_components
}

///|
fn query_filter_component_is_dense(world : World, component_id : Int) -> Bool {
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return true
  }
  match world.local_component_storage_type(local_component_id) {
    Some(Table) => true
    Some(SparseSet) => false
    None => true
  }
}

///|
fn query_filter_component_requires_entity_check_for_world(
  world : World,
  component_id : Int,
) -> Bool {
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return true
  }
  match world.local_component_storage_type(local_component_id) {
    Some(Table) => false
    Some(SparseSet) => true
    None => true
  }
}

///|
fn query_filter_table_added_matches(
  world : World,
  component_id : Int,
  table_id : Int,
  row_index : Int,
) -> Bool {
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return false
  }
  guard world.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard world.table_storage(table_id) is Some(table_ref) else { return false }
  match table_ref.added_tick_at_row(row, local_component_id) {
    Some(tick) => world.get_tick_context().ticks().contains(tick)
    None => false
  }
}

///|
fn query_filter_table_changed_matches(
  world : World,
  component_id : Int,
  table_id : Int,
  row_index : Int,
) -> Bool {
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return false
  }
  guard world.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard world.table_storage(table_id) is Some(table_ref) else { return false }
  match table_ref.changed_tick_at_row(row, local_component_id) {
    Some(tick) => world.get_tick_context().ticks().contains(tick)
    None => false
  }
}

///|
fn query_filter_bind_table_added_matcher(
  world : World,
  component_id : Int,
  table_id : Int,
) -> (@core.Entity, Int) -> Bool {
  let ticks = world.get_tick_context().ticks()
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return fn(_entity, _row_index) { false }
  }
  guard world.local_component_storage_type(local_component_id) == Some(Table) else {
    return fn(_entity, _row_index) { false }
  }
  guard world.table_storage(table_id) is Some(table_ref) else {
    return fn(_entity, _row_index) { false }
  }
  guard table_ref.column(local_component_id) is Some(column) else {
    return fn(_entity, _row_index) { false }
  }
  fn(_entity, row_index) { column.added_tick_is_in(row_index, ticks) }
}

///|
fn query_filter_bind_table_changed_matcher(
  world : World,
  component_id : Int,
  table_id : Int,
) -> (@core.Entity, Int) -> Bool {
  let ticks = world.get_tick_context().ticks()
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return fn(_entity, _row_index) { false }
  }
  guard world.local_component_storage_type(local_component_id) == Some(Table) else {
    return fn(_entity, _row_index) { false }
  }
  guard world.table_storage(table_id) is Some(table_ref) else {
    return fn(_entity, _row_index) { false }
  }
  guard table_ref.column(local_component_id) is Some(column) else {
    return fn(_entity, _row_index) { false }
  }
  fn(_entity, row_index) { column.changed_tick_is_in(row_index, ticks) }
}

///|
fn query_filter_append_unique_anchor_components(
  out : Array[Int],
  component_ids : Array[Int],
) -> Unit {
  for component_id in component_ids {
    if !out.contains(component_id) {
      out.push(component_id)
    }
  }
}

///|
pub struct All {}

///|
pub fn All::new() -> All {
  All::{  }
}

///|
pub impl QueryFilter for All with fn matches(self, _world, _entity) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with fn bind_table_row_matcher(
  self,
  _world,
  _table_id,
) {
  ignore(self)
  fn(_entity, _row_index) { true }
}

///|
pub impl QueryFilter for All with fn mentions_component(self, _component_id) {
  ignore(self)
  false
}

///|
pub impl QueryFilter for All with fn matches_component_set(
  self,
  _set_contains_id,
) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with fn collect_access(self, _access) {
  ignore(self)
}

///|
pub impl QueryFilter for All with fn requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl QueryFilter for All with fn is_dense(self, _world) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with fn iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl QueryFilter for All with fn depends_on_ticks(self) {
  ignore(self)
  false
}

///|
pub struct With[T] {
  priv key : ComponentKey[T]
}

///|
pub fn[T] With::new(key : ComponentKey[T]) -> With[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for With[T] with fn matches(self, world, entity) {
  entity_has_component_id(world, self.key.id(), entity)
}

///|
pub impl[T] QueryFilter for With[T] with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  let matches = match world.local_component_id(self.key.id()) {
    Some(local_component_id) =>
      world.table_has_component_local_id(table_id, local_component_id)
    None => false
  }
  fn(_entity, _row_index) { matches }
}

///|
pub impl[T] QueryFilter for With[T] with fn mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for With[T] with fn matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with fn collect_access(self, access) {
  access.add_with_component(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with fn requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for With[T] with fn is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with fn iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with fn depends_on_ticks(self) {
  ignore(self)
  false
}

///|
pub struct Without[T] {
  priv key : ComponentKey[T]
}

///|
pub fn[T] Without::new(key : ComponentKey[T]) -> Without[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Without[T] with fn matches(self, world, entity) {
  !entity_has_component_id(world, self.key.id(), entity)
}

///|
pub impl[T] QueryFilter for Without[T] with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  let matches = match world.local_component_id(self.key.id()) {
    Some(local_component_id) =>
      !world.table_has_component_local_id(table_id, local_component_id)
    None => true
  }
  fn(_entity, _row_index) { matches }
}

///|
pub impl[T] QueryFilter for Without[T] with fn mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Without[T] with fn matches_component_set(
  self,
  set_contains_id,
) {
  !set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with fn collect_access(self, access) {
  access.add_without_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with fn requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Without[T] with fn is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with fn iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl[T] QueryFilter for Without[T] with fn depends_on_ticks(self) {
  ignore(self)
  false
}

///|
pub struct Allow[T] {
  priv key : ComponentKey[T]
}

///|
pub fn[T] Allow::new(key : ComponentKey[T]) -> Allow[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Allow[T] with fn matches(self, _world, _entity) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with fn bind_table_row_matcher(
  self,
  _world,
  _table_id,
) {
  ignore(self)
  fn(_entity, _row_index) { true }
}

///|
pub impl[T] QueryFilter for Allow[T] with fn mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Allow[T] with fn matches_component_set(
  self,
  _set_contains_id,
) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with fn collect_access(self, _access) {
  ignore(self)
}

///|
pub impl[T] QueryFilter for Allow[T] with fn requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Allow[T] with fn is_dense(self, _world) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with fn iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl[T] QueryFilter for Allow[T] with fn depends_on_ticks(self) {
  ignore(self)
  false
}

///|
pub struct Added[T] {
  priv key : ComponentKey[T]
}

///|
pub fn[T] Added::new(key : ComponentKey[T]) -> Added[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Added[T] with fn matches(self, world, entity) {
  world.is_added_by_key(entity, self.key, world.get_tick_context().ticks())
}

///|
pub impl[T] QueryFilter for Added[T] with fn mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Added[T] with fn matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with fn collect_access(self, access) {
  access.add_with_component(self.key.id())
  access.add_read_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with fn requires_entity_check(self) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Added[T] with fn requires_entity_check_for_world(
  self,
  world,
) {
  query_filter_component_requires_entity_check_for_world(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with fn matches_table_row(
  self,
  world,
  _entity,
  table_id,
  row_index,
) {
  query_filter_table_added_matches(world, self.key.id(), table_id, row_index)
}

///|
pub impl[T] QueryFilter for Added[T] with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  query_filter_bind_table_added_matcher(world, self.key.id(), table_id)
}

///|
pub impl[T] QueryFilter for Added[T] with fn is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with fn iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with fn depends_on_ticks(self) {
  ignore(self)
  true
}

///|
pub struct Changed[T] {
  priv key : ComponentKey[T]
}

///|
pub fn[T] Changed::new(key : ComponentKey[T]) -> Changed[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Changed[T] with fn matches(self, world, entity) {
  world.is_changed_by_key(entity, self.key, world.get_tick_context().ticks())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Changed[T] with fn matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn collect_access(self, access) {
  access.add_with_component(self.key.id())
  access.add_read_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn requires_entity_check(self) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Changed[T] with fn requires_entity_check_for_world(
  self,
  world,
) {
  query_filter_component_requires_entity_check_for_world(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn matches_table_row(
  self,
  world,
  _entity,
  table_id,
  row_index,
) {
  query_filter_table_changed_matches(world, self.key.id(), table_id, row_index)
}

///|
pub impl[T] QueryFilter for Changed[T] with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  query_filter_bind_table_changed_matcher(world, self.key.id(), table_id)
}

///|
pub impl[T] QueryFilter for Changed[T] with fn is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with fn depends_on_ticks(self) {
  ignore(self)
  true
}

///|
pub struct Or[F] {
  priv filters : F
}

///|
pub fn[F] Or::new(filters : F) -> Or[F] {
  { filters, }
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn matches(
  self,
  world,
  entity,
) {
  QueryFilterDisjunction::matches_any(self.filters, world, entity)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilterDisjunction::matches_table_row_any(
    self.filters,
    world,
    entity,
    table_id,
    row_index,
  )
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  QueryFilterDisjunction::bind_table_row_matcher_any(
    self.filters,
    world,
    table_id,
  )
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn mentions_component(
  self,
  component_id,
) {
  QueryFilterDisjunction::mentions_component_any(self.filters, component_id)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilterDisjunction::matches_component_set_any(
    self.filters,
    set_contains_id,
  )
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn collect_access(
  self,
  access,
) {
  QueryFilterDisjunction::collect_access_any(self.filters, access)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn requires_entity_check(
  self,
) {
  QueryFilterDisjunction::requires_entity_check_any(self.filters)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilterDisjunction::requires_entity_check_any_for_world(
    self.filters,
    world,
  )
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn is_dense(
  self,
  world,
) {
  QueryFilterDisjunction::is_dense_any(self.filters, world)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn iteration_anchor_component(
  self,
) {
  ignore(self)
  None
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with fn depends_on_ticks(
  self,
) {
  QueryFilterDisjunction::depends_on_ticks_any(self.filters)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn matches(
  self,
  world,
  entity,
) {
  QueryFilter::matches(self.0, world, entity) &&
  QueryFilter::matches(self.1, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(self.0, world, entity, table_id, row_index) &&
  QueryFilter::matches_table_row(self.1, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn bind_table_row_matcher(
  self,
  world,
  table_id,
) {
  let matches_a = QueryFilter::bind_table_row_matcher(self.0, world, table_id)
  let matches_b = QueryFilter::bind_table_row_matcher(self.1, world, table_id)
  fn(entity, row_index) {
    matches_a(entity, row_index) && matches_b(entity, row_index)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn mentions_component(
  self,
  component_id,
) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(self.0, set_contains_id) &&
  QueryFilter::matches_component_set(self.1, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn collect_access(
  self,
  access,
) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn requires_entity_check(
  self,
) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(self.0, world) ||
  QueryFilter::requires_entity_check_for_world(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn is_dense(
  self,
  world,
) {
  QueryFilter::is_dense(self.0, world) && QueryFilter::is_dense(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn iteration_anchor_component(
  self,
) {
  match QueryFilter::iteration_anchor_component(self.0) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.1)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn iteration_anchor_components(
  self,
) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.0),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.1),
  )
  component_ids
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with fn depends_on_ticks(
  self,
) {
  QueryFilter::depends_on_ticks(self.0) || QueryFilter::depends_on_ticks(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn matches(self, world, entity) {
  QueryFilter::matches(self.0, world, entity) &&
  QueryFilter::matches(self.1, world, entity) &&
  QueryFilter::matches(self.2, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn matches_table_row(self, world, entity, table_id, row_index) {
  QueryFilter::matches_table_row(self.0, world, entity, table_id, row_index) &&
  QueryFilter::matches_table_row(self.1, world, entity, table_id, row_index) &&
  QueryFilter::matches_table_row(self.2, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn bind_table_row_matcher(self, world, table_id) {
  let matches_a = QueryFilter::bind_table_row_matcher(self.0, world, table_id)
  let matches_b = QueryFilter::bind_table_row_matcher(self.1, world, table_id)
  let matches_c = QueryFilter::bind_table_row_matcher(self.2, world, table_id)
  fn(entity, row_index) {
    matches_a(entity, row_index) &&
    matches_b(entity, row_index) &&
    matches_c(entity, row_index)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn mentions_component(self, component_id) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id) ||
  QueryFilter::mentions_component(self.2, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn matches_component_set(self, set_contains_id) {
  QueryFilter::matches_component_set(self.0, set_contains_id) &&
  QueryFilter::matches_component_set(self.1, set_contains_id) &&
  QueryFilter::matches_component_set(self.2, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn collect_access(self, access) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
  QueryFilter::collect_access(self.2, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1) ||
  QueryFilter::requires_entity_check(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn requires_entity_check_for_world(self, world) {
  QueryFilter::requires_entity_check_for_world(self.0, world) ||
  QueryFilter::requires_entity_check_for_world(self.1, world) ||
  QueryFilter::requires_entity_check_for_world(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn is_dense(self, world) {
  QueryFilter::is_dense(self.0, world) &&
  QueryFilter::is_dense(self.1, world) &&
  QueryFilter::is_dense(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn iteration_anchor_component(self) {
  match QueryFilter::iteration_anchor_component(self.0) {
    Some(component_id) => Some(component_id)
    None =>
      match QueryFilter::iteration_anchor_component(self.1) {
        Some(component_id) => Some(component_id)
        None => QueryFilter::iteration_anchor_component(self.2)
      }
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn iteration_anchor_components(self) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.0),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.1),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.2),
  )
  component_ids
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks(self.0) ||
  QueryFilter::depends_on_ticks(self.1) ||
  QueryFilter::depends_on_ticks(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn matches(self, world, entity) {
  QueryFilter::matches((self.0, self.1, self.2), world, entity) &&
  QueryFilter::matches(self.3, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn matches_table_row(self, world, entity, table_id, row_index) {
  QueryFilter::matches_table_row(
    (self.0, self.1, self.2),
    world,
    entity,
    table_id,
    row_index,
  ) &&
  QueryFilter::matches_table_row(self.3, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn mentions_component(self, component_id) {
  QueryFilter::mentions_component((self.0, self.1, self.2), component_id) ||
  QueryFilter::mentions_component(self.3, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn matches_component_set(self, set_contains_id) {
  QueryFilter::matches_component_set((self.0, self.1, self.2), set_contains_id) &&
  QueryFilter::matches_component_set(self.3, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn collect_access(self, access) {
  QueryFilter::collect_access((self.0, self.1, self.2), access)
  QueryFilter::collect_access(self.3, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check((self.0, self.1, self.2)) ||
  QueryFilter::requires_entity_check(self.3)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn requires_entity_check_for_world(self, world) {
  QueryFilter::requires_entity_check_for_world((self.0, self.1, self.2), world) ||
  QueryFilter::requires_entity_check_for_world(self.3, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn is_dense(self, world) {
  QueryFilter::is_dense((self.0, self.1, self.2), world) &&
  QueryFilter::is_dense(self.3, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn iteration_anchor_component(self) {
  match QueryFilter::iteration_anchor_component((self.0, self.1, self.2)) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.3)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn iteration_anchor_components(self) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components((self.0, self.1, self.2)),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.3),
  )
  component_ids
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilter for (
  A,
  B,
  C,
  D,
) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks((self.0, self.1, self.2)) ||
  QueryFilter::depends_on_ticks(self.3)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn matches(self, world, entity) {
  QueryFilter::matches((self.0, self.1, self.2, self.3), world, entity) &&
  QueryFilter::matches(self.4, world, entity)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(
    (self.0, self.1, self.2, self.3),
    world,
    entity,
    table_id,
    row_index,
  ) &&
  QueryFilter::matches_table_row(self.4, world, entity, table_id, row_index)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn mentions_component(self, component_id) {
  QueryFilter::mentions_component(
    (self.0, self.1, self.2, self.3),
    component_id,
  ) ||
  QueryFilter::mentions_component(self.4, component_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(
    (self.0, self.1, self.2, self.3),
    set_contains_id,
  ) &&
  QueryFilter::matches_component_set(self.4, set_contains_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn collect_access(self, access) {
  QueryFilter::collect_access((self.0, self.1, self.2, self.3), access)
  QueryFilter::collect_access(self.4, access)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check((self.0, self.1, self.2, self.3)) ||
  QueryFilter::requires_entity_check(self.4)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(
    (self.0, self.1, self.2, self.3),
    world,
  ) ||
  QueryFilter::requires_entity_check_for_world(self.4, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn is_dense(self, world) {
  QueryFilter::is_dense((self.0, self.1, self.2, self.3), world) &&
  QueryFilter::is_dense(self.4, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn iteration_anchor_component(self) {
  match
    QueryFilter::iteration_anchor_component((self.0, self.1, self.2, self.3)) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.4)
  }
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn iteration_anchor_components(self) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components((self.0, self.1, self.2, self.3)),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.4),
  )
  component_ids
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
] QueryFilter for (A, B, C, D, E) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks((self.0, self.1, self.2, self.3)) ||
  QueryFilter::depends_on_ticks(self.4)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn matches(self, world, entity) {
  QueryFilter::matches((self.0, self.1, self.2, self.3, self.4), world, entity) &&
  QueryFilter::matches(self.5, world, entity)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(
    (self.0, self.1, self.2, self.3, self.4),
    world,
    entity,
    table_id,
    row_index,
  ) &&
  QueryFilter::matches_table_row(self.5, world, entity, table_id, row_index)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn mentions_component(
  self,
  component_id,
) {
  QueryFilter::mentions_component(
    (self.0, self.1, self.2, self.3, self.4),
    component_id,
  ) ||
  QueryFilter::mentions_component(self.5, component_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(
    (self.0, self.1, self.2, self.3, self.4),
    set_contains_id,
  ) &&
  QueryFilter::matches_component_set(self.5, set_contains_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn collect_access(self, access) {
  QueryFilter::collect_access((self.0, self.1, self.2, self.3, self.4), access)
  QueryFilter::collect_access(self.5, access)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check((self.0, self.1, self.2, self.3, self.4)) ||
  QueryFilter::requires_entity_check(self.5)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(
    (self.0, self.1, self.2, self.3, self.4),
    world,
  ) ||
  QueryFilter::requires_entity_check_for_world(self.5, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn is_dense(self, world) {
  QueryFilter::is_dense((self.0, self.1, self.2, self.3, self.4), world) &&
  QueryFilter::is_dense(self.5, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn iteration_anchor_component(self) {
  match
    QueryFilter::iteration_anchor_component(
      (self.0, self.1, self.2, self.3, self.4),
    ) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.5)
  }
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn iteration_anchor_components(self) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(
      (self.0, self.1, self.2, self.3, self.4),
    ),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.5),
  )
  component_ids
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
] QueryFilter for (A, B, C, D, E, F) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks((self.0, self.1, self.2, self.3, self.4)) ||
  QueryFilter::depends_on_ticks(self.5)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn matches(self, world, entity) {
  QueryFilter::matches(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    world,
    entity,
  ) &&
  QueryFilter::matches(self.6, world, entity)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    world,
    entity,
    table_id,
    row_index,
  ) &&
  QueryFilter::matches_table_row(self.6, world, entity, table_id, row_index)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn mentions_component(
  self,
  component_id,
) {
  QueryFilter::mentions_component(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    component_id,
  ) ||
  QueryFilter::mentions_component(self.6, component_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    set_contains_id,
  ) &&
  QueryFilter::matches_component_set(self.6, set_contains_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn collect_access(self, access) {
  QueryFilter::collect_access(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    access,
  )
  QueryFilter::collect_access(self.6, access)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check(
    (self.0, self.1, self.2, self.3, self.4, self.5),
  ) ||
  QueryFilter::requires_entity_check(self.6)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(
    (self.0, self.1, self.2, self.3, self.4, self.5),
    world,
  ) ||
  QueryFilter::requires_entity_check_for_world(self.6, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn is_dense(self, world) {
  QueryFilter::is_dense((self.0, self.1, self.2, self.3, self.4, self.5), world) &&
  QueryFilter::is_dense(self.6, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn iteration_anchor_component(self) {
  match
    QueryFilter::iteration_anchor_component(
      (self.0, self.1, self.2, self.3, self.4, self.5),
    ) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.6)
  }
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn iteration_anchor_components(
  self,
) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(
      (self.0, self.1, self.2, self.3, self.4, self.5),
    ),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.6),
  )
  component_ids
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks(
    (self.0, self.1, self.2, self.3, self.4, self.5),
  ) ||
  QueryFilter::depends_on_ticks(self.6)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn matches(self, world, entity) {
  QueryFilter::matches(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    world,
    entity,
  ) &&
  QueryFilter::matches(self.7, world, entity)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn matches_table_row(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    world,
    entity,
    table_id,
    row_index,
  ) &&
  QueryFilter::matches_table_row(self.7, world, entity, table_id, row_index)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn mentions_component(
  self,
  component_id,
) {
  QueryFilter::mentions_component(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    component_id,
  ) ||
  QueryFilter::mentions_component(self.7, component_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    set_contains_id,
  ) &&
  QueryFilter::matches_component_set(self.7, set_contains_id)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn collect_access(self, access) {
  QueryFilter::collect_access(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    access,
  )
  QueryFilter::collect_access(self.7, access)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn requires_entity_check(self) {
  QueryFilter::requires_entity_check(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
  ) ||
  QueryFilter::requires_entity_check(self.7)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn requires_entity_check_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    world,
  ) ||
  QueryFilter::requires_entity_check_for_world(self.7, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn is_dense(self, world) {
  QueryFilter::is_dense(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    world,
  ) &&
  QueryFilter::is_dense(self.7, world)
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn iteration_anchor_component(
  self,
) {
  match
    QueryFilter::iteration_anchor_component(
      (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    ) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.7)
  }
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn iteration_anchor_components(
  self,
) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(
      (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
    ),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.7),
  )
  component_ids
}

///|
pub impl[
  A : QueryFilter,
  B : QueryFilter,
  C : QueryFilter,
  D : QueryFilter,
  E : QueryFilter,
  F : QueryFilter,
  G : QueryFilter,
  H : QueryFilter,
] QueryFilter for (A, B, C, D, E, F, G, H) with fn depends_on_ticks(self) {
  QueryFilter::depends_on_ticks(
    (self.0, self.1, self.2, self.3, self.4, self.5, self.6),
  ) ||
  QueryFilter::depends_on_ticks(self.7)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn matches_any(
  self,
  world,
  entity,
) {
  QueryFilter::matches(self.0, world, entity) ||
  QueryFilter::matches(self.1, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn matches_table_row_any(
  self,
  world,
  entity,
  table_id,
  row_index,
) {
  QueryFilter::matches_table_row(self.0, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.1, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn bind_table_row_matcher_any(
  self,
  world,
  table_id,
) {
  let matches_a = QueryFilter::bind_table_row_matcher(self.0, world, table_id)
  let matches_b = QueryFilter::bind_table_row_matcher(self.1, world, table_id)
  fn(entity, row_index) {
    matches_a(entity, row_index) || matches_b(entity, row_index)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn mentions_component_any(
  self,
  component_id,
) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn matches_component_set_any(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(self.0, set_contains_id) ||
  QueryFilter::matches_component_set(self.1, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn collect_access_any(
  self,
  access,
) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn requires_entity_check_any(
  self,
) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn requires_entity_check_any_for_world(
  self,
  world,
) {
  QueryFilter::requires_entity_check_for_world(self.0, world) ||
  QueryFilter::requires_entity_check_for_world(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn is_dense_any(
  self,
  world,
) {
  QueryFilter::is_dense(self.0, world) && QueryFilter::is_dense(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with fn depends_on_ticks_any(
  self,
) {
  QueryFilter::depends_on_ticks(self.0) || QueryFilter::depends_on_ticks(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn matches_any(self, world, entity) {
  QueryFilter::matches(self.0, world, entity) ||
  QueryFilter::matches(self.1, world, entity) ||
  QueryFilter::matches(self.2, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn matches_table_row_any(self, world, entity, table_id, row_index) {
  QueryFilter::matches_table_row(self.0, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.1, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.2, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn bind_table_row_matcher_any(self, world, table_id) {
  let matches_a = QueryFilter::bind_table_row_matcher(self.0, world, table_id)
  let matches_b = QueryFilter::bind_table_row_matcher(self.1, world, table_id)
  let matches_c = QueryFilter::bind_table_row_matcher(self.2, world, table_id)
  fn(entity, row_index) {
    matches_a(entity, row_index) ||
    matches_b(entity, row_index) ||
    matches_c(entity, row_index)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn mentions_component_any(self, component_id) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id) ||
  QueryFilter::mentions_component(self.2, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn matches_component_set_any(self, set_contains_id) {
  QueryFilter::matches_component_set(self.0, set_contains_id) ||
  QueryFilter::matches_component_set(self.1, set_contains_id) ||
  QueryFilter::matches_component_set(self.2, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn collect_access_any(self, access) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
  QueryFilter::collect_access(self.2, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn requires_entity_check_any(self) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1) ||
  QueryFilter::requires_entity_check(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn requires_entity_check_any_for_world(self, world) {
  QueryFilter::requires_entity_check_for_world(self.0, world) ||
  QueryFilter::requires_entity_check_for_world(self.1, world) ||
  QueryFilter::requires_entity_check_for_world(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn is_dense_any(self, world) {
  QueryFilter::is_dense(self.0, world) &&
  QueryFilter::is_dense(self.1, world) &&
  QueryFilter::is_dense(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with fn depends_on_ticks_any(self) {
  QueryFilter::depends_on_ticks(self.0) ||
  QueryFilter::depends_on_ticks(self.1) ||
  QueryFilter::depends_on_ticks(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn matches_any(self, world, entity) {
  QueryFilter::matches(self.0, world, entity) ||
  QueryFilter::matches(self.1, world, entity) ||
  QueryFilter::matches(self.2, world, entity) ||
  QueryFilter::matches(self.3, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn matches_table_row_any(self, world, entity, table_id, row_index) {
  QueryFilter::matches_table_row(self.0, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.1, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.2, world, entity, table_id, row_index) ||
  QueryFilter::matches_table_row(self.3, world, entity, table_id, row_index)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn bind_table_row_matcher_any(self, world, table_id) {
  let matches_a = QueryFilter::bind_table_row_matcher(self.0, world, table_id)
  let matches_b = QueryFilter::bind_table_row_matcher(self.1, world, table_id)
  let matches_c = QueryFilter::bind_table_row_matcher(self.2, world, table_id)
  let matches_d = QueryFilter::bind_table_row_matcher(self.3, world, table_id)
  fn(entity, row_index) {
    matches_a(entity, row_index) ||
    matches_b(entity, row_index) ||
    matches_c(entity, row_index) ||
    matches_d(entity, row_index)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn mentions_component_any(self, component_id) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id) ||
  QueryFilter::mentions_component(self.2, component_id) ||
  QueryFilter::mentions_component(self.3, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn matches_component_set_any(self, set_contains_id) {
  QueryFilter::matches_component_set(self.0, set_contains_id) ||
  QueryFilter::matches_component_set(self.1, set_contains_id) ||
  QueryFilter::matches_component_set(self.2, set_contains_id) ||
  QueryFilter::matches_component_set(self.3, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn collect_access_any(self, access) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
  QueryFilter::collect_access(self.2, access)
  QueryFilter::collect_access(self.3, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn requires_entity_check_any(self) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1) ||
  QueryFilter::requires_entity_check(self.2) ||
  QueryFilter::requires_entity_check(self.3)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn requires_entity_check_any_for_world(self, world) {
  QueryFilter::requires_entity_check_for_world(self.0, world) ||
  QueryFilter::requires_entity_check_for_world(self.1, world) ||
  QueryFilter::requires_entity_check_for_world(self.2, world) ||
  QueryFilter::requires_entity_check_for_world(self.3, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn is_dense_any(self, world) {
  QueryFilter::is_dense(self.0, world) &&
  QueryFilter::is_dense(self.1, world) &&
  QueryFilter::is_dense(self.2, world) &&
  QueryFilter::is_dense(self.3, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter, D : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
  D,
) with fn depends_on_ticks_any(self) {
  QueryFilter::depends_on_ticks(self.0) ||
  QueryFilter::depends_on_ticks(self.1) ||
  QueryFilter::depends_on_ticks(self.2) ||
  QueryFilter::depends_on_ticks(self.3)
}
