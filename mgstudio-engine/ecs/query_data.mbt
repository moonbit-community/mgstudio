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
pub(all) struct QueryDataFetchPlan {
  priv local_component_ids : Array[Int]
}

///|
fn QueryDataFetchPlan::new() -> QueryDataFetchPlan {
  { local_component_ids: [] }
}

///|
fn QueryDataFetchPlan::push_component_id(
  self : QueryDataFetchPlan,
  world : World,
  component_id : Int,
) -> Unit {
  let local_component_id = match world.local_component_id(component_id) {
    Some(local_component_id) => local_component_id
    None => -1
  }
  self.local_component_ids.push(local_component_id)
}

///|
fn QueryDataFetchPlan::local_component_id(
  self : QueryDataFetchPlan,
  offset : Int,
) -> Int? {
  guard offset >= 0 && offset < self.local_component_ids.length() else {
    return None
  }
  let local_component_id = self.local_component_ids[offset]
  if local_component_id >= 0 {
    Some(local_component_id)
  } else {
    None
  }
}

///|
pub(open) trait QueryData {
  matches(World, @core.Entity) -> Bool
  fetch(World, @core.Entity) -> Self raise EcsError
  prepare_fetch_plan(World) -> QueryDataFetchPlan = _
  append_fetch_plan(World, QueryDataFetchPlan) -> Unit = _
  fetch_plan_size() -> Int = _
  fetch_table_row(World, @core.Entity, Int, Int) -> Self raise EcsError = _
  fetch_table_row_with_plan(World, @core.Entity, Int, Int, QueryDataFetchPlan) -> Self raise EcsError = _
  fetch_table_row_with_plan_offset(
    World,
    @core.Entity,
    Int,
    Int,
    QueryDataFetchPlan,
    Int,
  ) -> Self raise EcsError = _
  fetch_sparse_anchor(World, @core.Entity, Int, EcsPayload, Int, Int) -> Self raise EcsError = _
  fetch_sparse_anchor_with_plan(
    World,
    @core.Entity,
    Int,
    EcsPayload,
    Int,
    Int,
    QueryDataFetchPlan,
  ) -> Self raise EcsError = _
  fetch_sparse_anchor_with_plan_offset(
    World,
    @core.Entity,
    Int,
    EcsPayload,
    Int,
    Int,
    QueryDataFetchPlan,
    Int,
  ) -> Self raise EcsError = _
  mentions_component(Int) -> Bool
  matches_component_set((Int) -> Bool) -> Bool
  collect_access(QueryDataAccess) -> Unit = _
  requires_entity_check() -> Bool
  is_dense(World) -> Bool = _
  iteration_anchor_component() -> Int?
  iteration_anchor_components() -> Array[Int] = _
  contiguous_compatible() -> Bool
}

///|
impl QueryData with collect_access(_access) {
  ()
}

///|
impl QueryData with is_dense(_world) {
  false
}

///|
impl QueryData with prepare_fetch_plan(world) {
  let plan = QueryDataFetchPlan::new()
  Self::append_fetch_plan(world, plan)
  plan
}

///|
impl QueryData with append_fetch_plan(_world, _plan) {
  ()
}

///|
impl QueryData with fetch_plan_size() {
  0
}

///|
impl QueryData with fetch_table_row(world, entity, _table_id, _row_index) {
  Self::fetch(world, entity)
}

///|
impl QueryData with fetch_table_row_with_plan(
  world,
  entity,
  table_id,
  row_index,
  plan,
) {
  Self::fetch_table_row_with_plan_offset(
    world, entity, table_id, row_index, plan, 0,
  )
}

///|
impl QueryData with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  _plan,
  _offset,
) {
  Self::fetch_table_row(world, entity, table_id, row_index)
}

///|
impl QueryData with fetch_sparse_anchor(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
) {
  Self::fetch_table_row(world, entity, table_id, row_index)
}

///|
impl QueryData with fetch_sparse_anchor_with_plan(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
  plan,
) {
  Self::fetch_sparse_anchor_with_plan_offset(
    world, entity, _anchor_local_component_id, _anchor_payload, table_id, row_index,
    plan, 0,
  )
}

///|
impl QueryData with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  Self::fetch_table_row_with_plan_offset(
    world, entity, table_id, row_index, plan, offset,
  )
}

///|
impl QueryData with iteration_anchor_components() {
  []
}

///|
pub struct Comp[T] {
  priv value : T?
  priv added_tick : @core.Tick?
  priv changed_tick : @core.Tick?
  priv changed_by : String?
  priv is_added : Bool
  priv is_changed : Bool
}

///|
priv struct QueryComponentTickSnapshot {
  added_tick : @core.Tick?
  changed_tick : @core.Tick?
  changed_by : String?
  is_added : Bool
  is_changed : Bool
}

///|
pub struct QueryDataAccess {
  priv read_components : Array[Int]
  priv write_components : Array[Int]
  priv read_component_set : @utils.IntBitSet
  priv write_component_set : @utils.IntBitSet
  priv mut has_read_write_conflict : Bool
  priv mut has_duplicate_write : Bool
}

///|
pub fn QueryDataAccess::new() -> QueryDataAccess {
  {
    read_components: [],
    write_components: [],
    read_component_set: @utils.IntBitSet::new(),
    write_component_set: @utils.IntBitSet::new(),
    has_read_write_conflict: false,
    has_duplicate_write: false,
  }
}

///|
pub fn[T] Comp::new(key : ComponentKey[T]) -> Comp[T] {
  ignore(key)
  {
    value: None,
    added_tick: None,
    changed_tick: None,
    changed_by: None,
    is_added: false,
    is_changed: false,
  }
}

///|
pub fn[T : Component] Comp::key(self : Comp[T]) -> ComponentKey[T] {
  ignore(self)
  Component::component()
}

///|
pub fn[T] Comp::value(self : Comp[T]) -> T {
  match self.value {
    Some(value) => value
    None => abort("Comp::value expected a fetched query item")
  }
}

///|
pub fn[T] Comp::is_added(self : Comp[T]) -> Bool {
  self.is_added
}

///|
pub fn[T] Comp::is_changed(self : Comp[T]) -> Bool {
  self.is_changed
}

///|
pub fn[T] Comp::added(self : Comp[T]) -> @core.Tick {
  match self.added_tick {
    Some(tick) => tick
    None => abort("Comp::added expected component tick metadata")
  }
}

///|
pub fn[T] Comp::last_changed(self : Comp[T]) -> @core.Tick {
  match self.changed_tick {
    Some(tick) => tick
    None => abort("Comp::last_changed expected component tick metadata")
  }
}

///|
pub fn[T] Comp::changed_by(self : Comp[T]) -> String? {
  self.changed_by
}

///|
pub fn QueryDataAccess::add_read_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if self.write_component_set.contains(component_id) {
    self.has_read_write_conflict = true
  }
  if !self.read_component_set.contains(component_id) {
    self.read_component_set.insert(component_id)
    self.read_components.push(component_id)
  }
}

///|
pub fn QueryDataAccess::add_write_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if self.write_component_set.contains(component_id) {
    self.has_duplicate_write = true
  }
  if self.read_component_set.contains(component_id) {
    self.has_read_write_conflict = true
  }
  if !self.write_component_set.contains(component_id) {
    self.write_component_set.insert(component_id)
    self.write_components.push(component_id)
  }
}

///|
pub fn QueryDataAccess::read_components(self : QueryDataAccess) -> Array[Int] {
  self.read_components
}

///|
pub fn QueryDataAccess::write_components(self : QueryDataAccess) -> Array[Int] {
  self.write_components
}

///|
pub fn QueryDataAccess::accesses_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Bool {
  self.read_component_set.contains(component_id) ||
  self.write_component_set.contains(component_id)
}

///|
pub fn QueryDataAccess::has_conflict(self : QueryDataAccess) -> Bool {
  self.has_read_write_conflict || self.has_duplicate_write
}

///|
fn query_data_component_is_dense(world : World, component_id : Int) -> Bool {
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
fn query_data_append_unique_anchor_components(
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
pub fn[T] query_data_component_matches(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  entity_has_component_id(world, key.id(), entity)
}

///|
fn[T : EcsPayloadCodec] query_data_require_component(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T raise EcsError {
  match world.component_value_by_key(entity, key) {
    Some(value) => value
    None =>
      abort(
        "QueryData::fetch expected component payload to exist after matches",
      )
  }
}

///|
fn query_data_local_component_id_from_plan(
  plan : QueryDataFetchPlan,
  offset : Int,
) -> Int? {
  plan.local_component_id(offset)
}

///|
fn query_data_tick_snapshot_from_ticks(
  world : World,
  added_tick : @core.Tick?,
  changed_tick : @core.Tick?,
  changed_by : String?,
) -> QueryComponentTickSnapshot {
  let system_ticks = world.get_tick_context().ticks()
  {
    added_tick,
    changed_tick,
    changed_by,
    is_added: match added_tick {
      Some(tick) => system_ticks.contains(tick)
      None => false
    },
    is_changed: match changed_tick {
      Some(tick) => system_ticks.contains(tick)
      None => false
    },
  }
}

///|
fn query_data_tick_snapshot_for_entity(
  world : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> QueryComponentTickSnapshot {
  query_data_tick_snapshot_from_ticks(
    world,
    world.added_component_tick_by_local_id(local_component_id, entity.id),
    world.changed_component_tick_by_local_id(local_component_id, entity.id),
    world.changed_component_caller_by_local_id(local_component_id, entity.id),
  )
}

///|
fn query_data_tick_snapshot_at_table_row(
  world : World,
  entity : @core.Entity,
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
) -> QueryComponentTickSnapshot {
  if table_id >= 0 &&
    row_index >= 0 &&
    world.local_component_storage_type(local_component_id) == Some(Table) {
    match (world.table_storage(table_id), TableRow::from_index(row_index)) {
      (Some(table_ref), Some(row)) =>
        return query_data_tick_snapshot_from_ticks(
          world,
          table_ref.val.added_tick_at_row(row, local_component_id),
          table_ref.val.changed_tick_at_row(row, local_component_id),
          table_ref.val.changed_caller_at_row(row, local_component_id),
        )
      _ => ()
    }
  }
  query_data_tick_snapshot_for_entity(world, entity, local_component_id)
}

///|
fn[T] query_data_comp_from_value(
  world : World,
  entity : @core.Entity,
  local_component_id : Int?,
  table_id : Int,
  row_index : Int,
  value : T,
) -> Comp[T] {
  let snapshot = match local_component_id {
    Some(local_component_id) =>
      query_data_tick_snapshot_at_table_row(
        world, entity, local_component_id, table_id, row_index,
      )
    None => query_data_tick_snapshot_from_ticks(world, None, None, None)
  }
  {
    value: Some(value),
    added_tick: snapshot.added_tick,
    changed_tick: snapshot.changed_tick,
    changed_by: snapshot.changed_by,
    is_added: snapshot.is_added,
    is_changed: snapshot.is_changed,
  }
}

///|
pub fn[T : EcsPayloadCodec] query_data_component_fetch(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T raise EcsError {
  query_data_require_component(world, entity, key)
}

///|
pub fn[T : EcsPayloadCodec] query_data_component_optional(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  world.component_value_by_key(entity, key)
}

///|
fn[T] query_data_require_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T] {
  guard world.component_payload(key.id(), entity) is Some(_) else {
    abort("QueryData::fetch expected component payload to exist after matches")
  }
  let local_component_id = world.local_component_id(key.id())
  let table_id = world.table_id_for_entity(entity)
  let row_index = match world.entity_table_row(entity) {
    Some(row) => Some(row.index())
    None => None
  }
  {
    world: Some(world),
    entity: Some(entity),
    key: Some(key),
    table_id,
    row_index,
    local_component_id,
  }
}

///|
pub fn[T] query_data_component_has(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  entity_has_component_id(world, key.id(), entity)
}

///|
pub impl QueryData for @core.Entity with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for @core.Entity with fetch(_world, entity) {
  entity
}

///|
pub impl QueryData for @core.Entity with fetch_table_row(
  _world,
  entity,
  _table_id,
  _row_index,
) {
  entity
}

///|
pub impl QueryData for @core.Entity with fetch_sparse_anchor(
  _world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  _table_id,
  _row_index,
) {
  entity
}

///|
pub impl QueryData for @core.Entity with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for @core.Entity with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for @core.Entity with collect_access(_access) {
  ()
}

///|
pub impl QueryData for @core.Entity with requires_entity_check() {
  false
}

///|
pub impl QueryData for @core.Entity with is_dense(_world) {
  true
}

///|
pub impl QueryData for @core.Entity with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for @core.Entity with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Comp[T] with matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch(world, entity) {
  let key = T::component()
  query_data_comp_from_value(
    world,
    entity,
    world.local_component_id(key.id()),
    -1,
    -1,
    query_data_require_component(world, entity, key),
  )
}

///|
pub impl[T : Component] QueryData for Comp[T] with append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  let key = T::component()
  let local_component_id = world.local_component_id(key.id())
  let value_at_row = match local_component_id {
    Some(local_component_id) =>
      try! world.component_value_by_local_id_at_table_row(
        key, local_component_id, table_id, row_index,
      )
    None => None
  }
  match value_at_row {
    Some(value) =>
      query_data_comp_from_value(
        world, entity, local_component_id, table_id, row_index, value,
      )
    None =>
      query_data_comp_from_value(
        world,
        entity,
        world.local_component_id(key.id()),
        table_id,
        row_index,
        query_data_require_component(world, entity, key),
      )
  }
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let key = T::component()
  let local_component_id = query_data_local_component_id_from_plan(plan, offset)
  let value_at_row = match local_component_id {
    Some(local_component_id) =>
      try! world.component_value_by_local_id_at_table_row(
        key, local_component_id, table_id, row_index,
      )
    None => None
  }
  match value_at_row {
    Some(value) =>
      query_data_comp_from_value(
        world, entity, local_component_id, table_id, row_index, value,
      )
    None =>
      query_data_comp_from_value(
        world,
        entity,
        world.local_component_id(key.id()),
        table_id,
        row_index,
        query_data_require_component(world, entity, key),
      )
  }
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  let key = T::component()
  match world.local_component_id(key.id()) {
    Some(local_component_id) if local_component_id == anchor_local_component_id => {
      let value = match T::from_ecs_payload(anchor_payload) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch_sparse_anchor expected anchor payload type to match component",
          )
      }
      query_data_comp_from_value(
        world,
        entity,
        Some(local_component_id),
        table_id,
        row_index,
        value,
      )
    }
    _ => Comp::fetch_table_row(world, entity, table_id, row_index)
  }
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  match query_data_local_component_id_from_plan(plan, offset) {
    Some(local_component_id) if local_component_id == anchor_local_component_id => {
      let value = match T::from_ecs_payload(anchor_payload) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch_sparse_anchor expected anchor payload type to match component",
          )
      }
      query_data_comp_from_value(
        world,
        entity,
        Some(local_component_id),
        table_id,
        row_index,
        value,
      )
    }
    _ =>
      Comp::fetch_table_row_with_plan_offset(
        world, entity, table_id, row_index, plan, offset,
      )
  }
}

///|
pub impl[T : Component] QueryData for Comp[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Comp[T] with matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Comp[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with iteration_anchor_components() {
  [T::component().id()]
}

///|
pub impl[T : Component] QueryData for Comp[T] with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Mut[T] with matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch(world, entity) {
  query_data_require_component_mut(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Mut[T] with append_fetch_plan(world, plan) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  let key = T::component()
  {
    world: Some(world),
    entity: Some(entity),
    key: Some(key),
    table_id: Some(table_id),
    row_index: Some(row_index),
    local_component_id: world.local_component_id(key.id()),
  }
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let key = T::component()
  {
    world: Some(world),
    entity: Some(entity),
    key: Some(key),
    table_id: Some(table_id),
    row_index: Some(row_index),
    local_component_id: query_data_local_component_id_from_plan(plan, offset),
  }
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch_sparse_anchor(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
) {
  let key = T::component()
  {
    world: Some(world),
    entity: Some(entity),
    key: Some(key),
    table_id: Some(table_id),
    row_index: Some(row_index),
    local_component_id: world.local_component_id(key.id()),
  }
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  Mut::fetch_table_row_with_plan_offset(
    world, entity, table_id, row_index, plan, offset,
  )
}

///|
pub impl[T : Component] QueryData for Mut[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Mut[T] with matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with collect_access(access) {
  access.add_write_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Mut[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with iteration_anchor_components() {
  [T::component().id()]
}

///|
pub impl[T : Component] QueryData for Mut[T] with contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityRef with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityRef with fetch(world, entity) {
  try! world.entity(entity)
}

///|
pub impl QueryData for EntityRef with fetch_table_row(
  world,
  entity,
  _table_id,
  _row_index,
) {
  EntityRef::{ world, entity }
}

///|
pub impl QueryData for EntityRef with fetch_sparse_anchor(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  _table_id,
  _row_index,
) {
  EntityRef::{ world, entity }
}

///|
pub impl QueryData for EntityRef with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityRef with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityRef with collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityRef with requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityRef with is_dense(_world) {
  true
}

///|
pub impl QueryData for EntityRef with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityRef with contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityMut with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityMut with fetch(world, entity) {
  try! world.entity_mut(entity)
}

///|
pub impl QueryData for EntityMut with fetch_table_row(
  world,
  entity,
  _table_id,
  _row_index,
) {
  EntityMut::{ world, entity }
}

///|
pub impl QueryData for EntityMut with fetch_sparse_anchor(
  world,
  entity,
  _anchor_local_component_id,
  _anchor_payload,
  _table_id,
  _row_index,
) {
  EntityMut::{ world, entity }
}

///|
pub impl QueryData for EntityMut with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityMut with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityMut with collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityMut with requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityMut with is_dense(_world) {
  true
}

///|
pub impl QueryData for EntityMut with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityMut with contiguous_compatible() {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with matches(_world, _entity) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with fetch(world, entity) {
  if T::matches(world, entity) {
    Some(T::fetch(world, entity))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with append_fetch_plan(world, plan) {
  T::append_fetch_plan(world, plan)
}

///|
pub impl[T : QueryData] QueryData for T? with fetch_plan_size() {
  T::fetch_plan_size()
}

///|
pub impl[T : QueryData] QueryData for T? with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  if T::matches(world, entity) {
    Some(T::fetch_table_row(world, entity, table_id, row_index))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  if T::matches(world, entity) {
    Some(
      T::fetch_table_row_with_plan_offset(
        world, entity, table_id, row_index, plan, offset,
      ),
    )
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  if T::matches(world, entity) {
    Some(
      T::fetch_sparse_anchor(
        world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      ),
    )
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  if T::matches(world, entity) {
    Some(
      T::fetch_sparse_anchor_with_plan_offset(
        world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
        plan, offset,
      ),
    )
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with mentions_component(component_id) {
  T::mentions_component(component_id)
}

///|
pub impl[T : QueryData] QueryData for T? with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with collect_access(access) {
  T::collect_access(access)
}

///|
pub impl[T : QueryData] QueryData for T? with requires_entity_check() {
  false
}

///|
pub impl[T : QueryData] QueryData for T? with is_dense(world) {
  T::is_dense(world)
}

///|
pub impl[T : QueryData] QueryData for T? with iteration_anchor_component() {
  None
}

///|
pub impl[T : QueryData] QueryData for T? with contiguous_compatible() {
  T::contiguous_compatible()
}

///|
pub impl[T : Component] QueryData for Has[T] with matches(_world, _entity) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch(world, entity) {
  { present: entity_has_component_id(world, T::component().id(), entity) }
}

///|
pub impl[T : Component] QueryData for Has[T] with append_fetch_plan(world, plan) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch_table_row(
  world,
  entity,
  table_id,
  _row_index,
) {
  let present = match world.local_component_id(T::component().id()) {
    Some(local_component_id) =>
      if world.local_component_storage_type(local_component_id) == Some(Table) {
        world.table_has_component_local_id(table_id, local_component_id)
      } else {
        entity_has_component_id(world, T::component().id(), entity)
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  _row_index,
  plan,
  offset,
) {
  let present = match query_data_local_component_id_from_plan(plan, offset) {
    Some(local_component_id) =>
      if world.local_component_storage_type(local_component_id) == Some(Table) {
        world.table_has_component_local_id(table_id, local_component_id)
      } else {
        entity_has_component_id(world, T::component().id(), entity)
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
) {
  ignore(row_index)
  let present = match world.local_component_id(T::component().id()) {
    Some(local_component_id) if local_component_id == anchor_local_component_id =>
      true
    Some(local_component_id) =>
      if world.local_component_storage_type(local_component_id) == Some(Table) {
        world.table_has_component_local_id(table_id, local_component_id)
      } else {
        entity_has_component_id(world, T::component().id(), entity)
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  _anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  ignore(row_index)
  let present = match query_data_local_component_id_from_plan(plan, offset) {
    Some(local_component_id) if local_component_id == anchor_local_component_id =>
      true
    Some(local_component_id) =>
      if world.local_component_storage_type(local_component_id) == Some(Table) {
        world.table_has_component_local_id(table_id, local_component_id)
      } else {
        entity_has_component_id(world, T::component().id(), entity)
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Has[T] with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with collect_access(_access) {
  ()
}

///|
pub impl[T : Component] QueryData for Has[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Has[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Has[T] with iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Has[T] with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with matches(_world, _entity) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch(world, entity) {
  { value: world.get_by_key(entity, T::component()) }
}

///|
pub impl[T : Component] QueryData for Optional[T] with append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  let key = T::component()
  let value_at_row = match world.local_component_id(key.id()) {
    Some(local_component_id) =>
      try! world.component_value_by_local_id_at_table_row(
        key, local_component_id, table_id, row_index,
      )
    None => None
  }
  match value_at_row {
    Some(value) => { value: Some(value) }
    None => { value: world.get_by_key(entity, key) }
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let key = T::component()
  let value_at_row = match
    query_data_local_component_id_from_plan(plan, offset) {
    Some(local_component_id) =>
      try! world.component_value_by_local_id_at_table_row(
        key, local_component_id, table_id, row_index,
      )
    None => None
  }
  match value_at_row {
    Some(value) => { value: Some(value) }
    None => { value: world.get_by_key(entity, key) }
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  match world.local_component_id(T::component().id()) {
    Some(local_component_id) if local_component_id == anchor_local_component_id => {
      let value = match T::from_ecs_payload(anchor_payload) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch_sparse_anchor expected anchor payload type to match component",
          )
      }
      { value: Some(value) }
    }
    _ => Optional::fetch_table_row(world, entity, table_id, row_index)
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  match query_data_local_component_id_from_plan(plan, offset) {
    Some(local_component_id) if local_component_id == anchor_local_component_id => {
      let value = match T::from_ecs_payload(anchor_payload) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch_sparse_anchor expected anchor payload type to match component",
          )
      }
      { value: Some(value) }
    }
    _ =>
      Optional::fetch_table_row_with_plan_offset(
        world, entity, table_id, row_index, plan, offset,
      )
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with mentions_component(
  _component_id,
) {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Optional[T] with contiguous_compatible() {
  true
}

///|
pub impl QueryData for Unit with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for Unit with fetch(_world, _entity) {
  ()
}

///|
pub impl QueryData for Unit with fetch_table_row(
  _world,
  _entity,
  _table_id,
  _row_index,
) {
  ()
}

///|
pub impl QueryData for Unit with fetch_sparse_anchor(
  _world,
  _entity,
  _anchor_local_component_id,
  _anchor_payload,
  _table_id,
  _row_index,
) {
  ()
}

///|
pub impl QueryData for Unit with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for Unit with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for Unit with collect_access(_access) {
  ()
}

///|
pub impl QueryData for Unit with requires_entity_check() {
  false
}

///|
pub impl QueryData for Unit with is_dense(_world) {
  true
}

///|
pub impl QueryData for Unit with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for Unit with contiguous_compatible() {
  true
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with matches(
  world,
  entity,
) {
  A::matches(world, entity) && B::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with append_fetch_plan(
  world,
  plan,
) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch_plan_size() {
  A::fetch_plan_size() + B::fetch_plan_size()
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  (
    A::fetch_table_row(world, entity, table_id, row_index),
    B::fetch_table_row(world, entity, table_id, row_index),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, offset,
    ),
    B::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, b_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  (
    A::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    B::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, offset,
    ),
    B::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, b_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with mentions_component(
  component_id,
) {
  A::mentions_component(component_id) || B::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with requires_entity_check() {
  A::requires_entity_check() || B::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with is_dense(world) {
  A::is_dense(world) && B::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None => B::iteration_anchor_component()
  }
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with iteration_anchor_components() {
  let component_ids : Array[Int] = []
  query_data_append_unique_anchor_components(
    component_ids,
    A::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    B::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with contiguous_compatible() {
  A::contiguous_compatible() && B::contiguous_compatible()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with matches(
  world,
  entity,
) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity), C::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with append_fetch_plan(
  world,
  plan,
) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch_plan_size() {
  A::fetch_plan_size() + B::fetch_plan_size() + C::fetch_plan_size()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch_table_row(
  world,
  entity,
  table_id,
  row_index,
) {
  (
    A::fetch_table_row(world, entity, table_id, row_index),
    B::fetch_table_row(world, entity, table_id, row_index),
    C::fetch_table_row(world, entity, table_id, row_index),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, offset,
    ),
    B::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, b_offset,
    ),
    C::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, c_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  (
    A::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    B::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    C::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, offset,
    ),
    B::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, b_offset,
    ),
    C::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, c_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with mentions_component(
  component_id,
) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with is_dense(
  world,
) {
  A::is_dense(world) && B::is_dense(world) && C::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None => C::iteration_anchor_component()
      }
  }
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with iteration_anchor_components() {
  let component_ids : Array[Int] = []
  query_data_append_unique_anchor_components(
    component_ids,
    A::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    B::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    C::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with append_fetch_plan(world, plan) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
  D::append_fetch_plan(world, plan)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch_plan_size() {
  A::fetch_plan_size() +
  B::fetch_plan_size() +
  C::fetch_plan_size() +
  D::fetch_plan_size()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch_table_row(world, entity, table_id, row_index) {
  (
    A::fetch_table_row(world, entity, table_id, row_index),
    B::fetch_table_row(world, entity, table_id, row_index),
    C::fetch_table_row(world, entity, table_id, row_index),
    D::fetch_table_row(world, entity, table_id, row_index),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch_table_row_with_plan_offset(
  world,
  entity,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, offset,
    ),
    B::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, b_offset,
    ),
    C::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, c_offset,
    ),
    D::fetch_table_row_with_plan_offset(
      world, entity, table_id, row_index, plan, d_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch_sparse_anchor(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
) {
  (
    A::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    B::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    C::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
    D::fetch_sparse_anchor(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch_sparse_anchor_with_plan_offset(
  world,
  entity,
  anchor_local_component_id,
  anchor_payload,
  table_id,
  row_index,
  plan,
  offset,
) {
  let b_offset = offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, offset,
    ),
    B::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, b_offset,
    ),
    C::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, c_offset,
    ),
    D::fetch_sparse_anchor_with_plan_offset(
      world, entity, anchor_local_component_id, anchor_payload, table_id, row_index,
      plan, d_offset,
    ),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with mentions_component(component_id) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with matches_component_set(set_contains_id) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None => D::iteration_anchor_component()
          }
      }
  }
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with iteration_anchor_components() {
  let component_ids : Array[Int] = []
  query_data_append_unique_anchor_components(
    component_ids,
    A::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    B::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    C::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    D::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible()
}
