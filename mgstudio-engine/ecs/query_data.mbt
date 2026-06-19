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
  priv local_component_is_table : Array[Bool]
  priv table_column_caches : Array[Array[RawTableColumn?]]
  priv table_column_cache_ready : Array[@utils.IntBitSet]
}

///|
pub(all) struct QueryDataTableRowFetch {
  priv world : World
  priv entity : @core.Entity
  priv table_id : Int
  priv row_index : Int
}

///|
pub(all) struct QueryDataPlannedFetch {
  priv row : QueryDataTableRowFetch
  priv plan : QueryDataFetchPlan
  priv offset : Int
}

///|
pub(all) struct QueryDataSparseAnchorFetch {
  priv row : QueryDataTableRowFetch
  priv anchor_local_component_id : Int
  priv plan : QueryDataFetchPlan
  priv offset : Int
}

///|
fn query_data_table_row_fetch(
  world : World,
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> QueryDataTableRowFetch {
  { world, entity, table_id, row_index }
}

///|
fn QueryDataTableRowFetch::planned(
  self : QueryDataTableRowFetch,
  plan : QueryDataFetchPlan,
  offset : Int,
) -> QueryDataPlannedFetch {
  { row: self, plan, offset }
}

///|
fn QueryDataTableRowFetch::sparse_anchor(
  self : QueryDataTableRowFetch,
  anchor_local_component_id : Int,
  plan : QueryDataFetchPlan,
  offset : Int,
) -> QueryDataSparseAnchorFetch {
  { row: self, anchor_local_component_id, plan, offset }
}

///|
fn QueryDataPlannedFetch::with_offset(
  self : QueryDataPlannedFetch,
  offset : Int,
) -> QueryDataPlannedFetch {
  { row: self.row, plan: self.plan, offset }
}

///|
fn QueryDataSparseAnchorFetch::with_offset(
  self : QueryDataSparseAnchorFetch,
  offset : Int,
) -> QueryDataSparseAnchorFetch {
  {
    row: self.row,
    anchor_local_component_id: self.anchor_local_component_id,
    plan: self.plan,
    offset,
  }
}

///|
fn QueryDataFetchPlan::new() -> QueryDataFetchPlan {
  {
    local_component_ids: [],
    local_component_is_table: [],
    table_column_caches: [],
    table_column_cache_ready: [],
  }
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
  self.local_component_is_table.push(
    local_component_id >= 0 &&
    world.local_component_storage_type(local_component_id) == Some(Table),
  )
  self.table_column_caches.push([])
  self.table_column_cache_ready.push(@utils.IntBitSet::new())
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
fn QueryDataFetchPlan::component_is_table_at_offset(
  self : QueryDataFetchPlan,
  offset : Int,
) -> Bool {
  offset >= 0 &&
  offset < self.local_component_is_table.length() &&
  self.local_component_is_table[offset]
}

///|
fn QueryDataFetchPlan::cached_table_column(
  self : QueryDataFetchPlan,
  world : World,
  offset : Int,
  table_id : Int,
) -> RawTableColumn? {
  guard table_id >= 0 &&
    offset >= 0 &&
    offset < self.local_component_ids.length() &&
    offset < self.table_column_caches.length() &&
    offset < self.table_column_cache_ready.length() &&
    self.component_is_table_at_offset(offset) else {
    return None
  }
  let local_component_id = self.local_component_ids[offset]
  guard local_component_id >= 0 else { return None }
  let cache = self.table_column_caches[offset]
  let ready = self.table_column_cache_ready[offset]
  while cache.length() <= table_id {
    cache.push(None)
  }
  if ready.contains(table_id) {
    return cache[table_id]
  }
  ready.insert(table_id)
  let column_ref = match world.table_storage(table_id) {
    Some(table_ref) => table_ref.column(local_component_id)
    None => None
  }
  cache[table_id] = column_ref
  column_ref
}

///|
fn[T] QueryDataFetchPlan::value_at_table_row(
  self : QueryDataFetchPlan,
  world : World,
  key : ComponentKey[T],
  offset : Int,
  table_id : Int,
  row_index : Int,
) -> T? {
  match self.cached_table_column(world, offset, table_id) {
    Some(column_ref) => {
      guard row_index >= 0 &&
        row_index < raw_table_column_kernel_len(column_ref.storage) else {
        return None
      }
      guard offset >= 0 && offset < self.local_component_ids.length() else {
        return None
      }
      guard world.table_storage(table_id) is Some(table_ref) else {
        return None
      }
      guard TableRow::from_index(row_index) is Some(row) else { return None }
      guard table_ref.entity_at_row(row) is Some(_) else { return None }
      key.component_get_table_row(world, table_id, row_index)
    }
    None => None
  }
}

///|
pub(open) trait QueryData {
  fn matches(World, @core.Entity) -> Bool
  fn fetch(World, @core.Entity) -> Self raise EcsError
  fn prepare_fetch_plan(World) -> QueryDataFetchPlan = _
  fn append_fetch_plan(World, QueryDataFetchPlan) -> Unit = _
  fn fetch_plan_size() -> Int = _
  fn fetch_table_row(QueryDataTableRowFetch) -> Self raise EcsError = _
  fn fetch_table_row_with_plan_offset(QueryDataPlannedFetch) -> Self raise EcsError = _
  fn fetch_sparse_anchor_with_plan_offset(QueryDataSparseAnchorFetch) -> Self raise EcsError = _
  fn mentions_component(Int) -> Bool
  fn matches_component_set((Int) -> Bool) -> Bool
  fn collect_access(QueryDataAccess) -> Unit = _
  fn collect_required_components(QueryDataAccess) -> Unit = _
  fn requires_entity_check() -> Bool
  fn is_dense(World) -> Bool = _
  fn iteration_anchor_component() -> Int?
  fn iteration_anchor_components() -> Array[Int] = _
  fn contiguous_compatible() -> Bool
}

///|
impl QueryData with fn collect_access(_access) {
  ()
}

///|
impl QueryData with fn collect_required_components(_access) {
  ()
}

///|
impl QueryData with fn is_dense(_world) {
  false
}

///|
impl QueryData with fn prepare_fetch_plan(world) {
  let plan = QueryDataFetchPlan::new()
  Self::append_fetch_plan(world, plan)
  plan
}

///|
impl QueryData with fn append_fetch_plan(_world, _plan) {
  ()
}

///|
impl QueryData with fn fetch_plan_size() {
  0
}

///|
impl QueryData with fn fetch_table_row(fetch) {
  Self::fetch(fetch.world, fetch.entity)
}

///|
impl QueryData with fn fetch_table_row_with_plan_offset(fetch) {
  Self::fetch_table_row(fetch.row)
}

///|
impl QueryData with fn fetch_sparse_anchor_with_plan_offset(fetch) {
  Self::fetch_table_row_with_plan_offset({
    row: fetch.row,
    plan: fetch.plan,
    offset: fetch.offset,
  })
}

///|
impl QueryData with fn iteration_anchor_components() {
  []
}

///|
pub struct Read[T] {
  priv key : ComponentKey[T]
  priv value : T
  priv added_tick : @core.Tick
  priv changed_tick : @core.Tick
  priv changed_by : String?
  priv is_added : Bool
  priv is_changed : Bool
}

///|
priv struct QueryComponentTickSnapshot {
  added_tick : @core.Tick
  changed_tick : @core.Tick
  changed_by : String?
  is_added : Bool
  is_changed : Bool
}

///|
pub struct QueryDataAccess {
  priv read_components : Array[Int]
  priv write_components : Array[Int]
  priv required_components : Array[Int]
  priv read_component_set : @utils.IntBitSet
  priv write_component_set : @utils.IntBitSet
  priv required_component_set : @utils.IntBitSet
  priv mut has_read_write_conflict : Bool
  priv mut has_duplicate_write : Bool
}

///|
pub fn QueryDataAccess::new() -> QueryDataAccess {
  {
    read_components: [],
    write_components: [],
    required_components: [],
    read_component_set: @utils.IntBitSet::new(),
    write_component_set: @utils.IntBitSet::new(),
    required_component_set: @utils.IntBitSet::new(),
    has_read_write_conflict: false,
    has_duplicate_write: false,
  }
}

///|
pub fn[T] Read::key(self : Read[T]) -> ComponentKey[T] {
  self.key
}

///|
/// Returns the queried component value for read-only use.
///
/// `Read[T]` is a read query item. If `T` contains mutable fields, mutating the
/// returned value directly bypasses ECS change detection. Use `Write[T]` in the
/// query data and mutate through `Write::modify` or `Write::set` when the query
/// intends to write the component.
pub fn[T] Read::value(self : Read[T]) -> T {
  self.value
}

///|
pub fn[T] Read::is_added(self : Read[T]) -> Bool {
  self.is_added
}

///|
pub fn[T] Read::is_changed(self : Read[T]) -> Bool {
  self.is_changed
}

///|
pub fn[T] Read::added(self : Read[T]) -> @core.Tick {
  self.added_tick
}

///|
pub fn[T] Read::last_changed(self : Read[T]) -> @core.Tick {
  self.changed_tick
}

///|
pub fn[T] Read::changed_by(self : Read[T]) -> String? {
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
pub fn QueryDataAccess::add_required_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if !self.required_component_set.contains(component_id) {
    self.required_component_set.insert(component_id)
    self.required_components.push(component_id)
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
pub fn QueryDataAccess::required_components(
  self : QueryDataAccess,
) -> Array[Int] {
  self.required_components
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
fn[T] query_data_require_component(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T {
  match world.component_value_by_key(entity, key) {
    Some(value) => value
    None =>
      abort("QueryData::fetch expected component value to exist after matches")
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
fn query_data_component_local_id_or_abort(local_component_id : Int?) -> Int {
  match local_component_id {
    Some(local_component_id) => local_component_id
    None => abort("QueryData::fetch expected component local id to exist")
  }
}

///|
fn query_data_component_storage_type_or_abort(
  world : World,
  local_component_id : Int,
) -> ComponentStorageType {
  match world.local_component_storage_type(local_component_id) {
    Some(storage_type) => storage_type
    None => abort("QueryData::fetch expected component storage type to exist")
  }
}

///|
fn query_data_tick_or_abort(tick : @core.Tick?, label : String) -> @core.Tick {
  match tick {
    Some(tick) => tick
    None => abort("QueryData::fetch expected component \{label} tick metadata")
  }
}

///|
fn query_data_tick_snapshot_from_ticks(
  world : World,
  added_tick : @core.Tick?,
  changed_tick : @core.Tick?,
  changed_by : String?,
) -> QueryComponentTickSnapshot {
  let system_ticks = world.get_tick_context().ticks()
  let added_tick_value = query_data_tick_or_abort(added_tick, "added")
  let changed_tick_value = query_data_tick_or_abort(changed_tick, "changed")
  {
    added_tick: added_tick_value,
    changed_tick: changed_tick_value,
    changed_by,
    is_added: system_ticks.contains(added_tick_value),
    is_changed: system_ticks.contains(changed_tick_value),
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
          table_ref.added_tick_at_row(row, local_component_id),
          table_ref.changed_tick_at_row(row, local_component_id),
          table_ref.changed_caller_at_row(row, local_component_id),
        )
      _ => ()
    }
  }
  query_data_tick_snapshot_for_entity(world, entity, local_component_id)
}

///|
fn[T] query_data_comp_from_value(
  fetch : QueryDataTableRowFetch,
  key : ComponentKey[T],
  local_component_id : Int,
  value : T,
) -> Read[T] {
  let snapshot = query_data_tick_snapshot_at_table_row(
    fetch.world,
    fetch.entity,
    local_component_id,
    fetch.table_id,
    fetch.row_index,
  )
  {
    key,
    value,
    added_tick: snapshot.added_tick,
    changed_tick: snapshot.changed_tick,
    changed_by: snapshot.changed_by,
    is_added: snapshot.is_added,
    is_changed: snapshot.is_changed,
  }
}

///|
fn[T] query_data_component_value_at_fetch_location(
  fetch : QueryDataTableRowFetch,
  key : ComponentKey[T],
  local_component_id : Int,
) -> T {
  match
    query_data_component_storage_type_or_abort(fetch.world, local_component_id) {
    Table =>
      match
        fetch.world.component_value_by_table_row_fast(
          key,
          local_component_id,
          fetch.table_id,
          fetch.row_index,
        ) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch expected table component value at query table row",
          )
      }
    SparseSet => query_data_require_component(fetch.world, fetch.entity, key)
  }
}

///|
fn[T] query_data_component_value_at_planned_fetch_location(
  fetch : QueryDataPlannedFetch,
  key : ComponentKey[T],
  local_component_id : Int,
) -> T {
  match
    query_data_component_storage_type_or_abort(
      fetch.row.world,
      local_component_id,
    ) {
    Table =>
      match
        fetch.plan.value_at_table_row(
          fetch.row.world,
          key,
          fetch.offset,
          fetch.row.table_id,
          fetch.row.row_index,
        ) {
        Some(value) => value
        None =>
          abort(
            "QueryData::fetch expected planned table component value at query table row",
          )
      }
    SparseSet =>
      query_data_require_component(fetch.row.world, fetch.row.entity, key)
  }
}

///|
fn[T] query_data_optional_component_value_by_entity(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? {
  guard entity_has_component_id(world, key.id(), entity) else { return None }
  match world.component_value_by_key(entity, key) {
    Some(value) => Some(value)
    None =>
      abort(
        "QueryData::fetch expected present optional component value to exist",
      )
  }
}

///|
fn[T] query_data_optional_component_value_at_fetch_location(
  fetch : QueryDataTableRowFetch,
  key : ComponentKey[T],
) -> T? {
  match fetch.world.local_component_id(key.id()) {
    Some(local_component_id) =>
      match
        query_data_component_storage_type_or_abort(
          fetch.world,
          local_component_id,
        ) {
        Table =>
          if fetch.world.table_has_component_local_id(
              fetch.table_id,
              local_component_id,
            ) {
            match
              fetch.world.component_value_by_table_row_fast(
                key,
                local_component_id,
                fetch.table_id,
                fetch.row_index,
              ) {
              Some(value) => Some(value)
              None =>
                abort(
                  "QueryData::fetch expected optional table component value at query table row",
                )
            }
          } else {
            None
          }
        SparseSet =>
          query_data_optional_component_value_by_entity(
            fetch.world,
            fetch.entity,
            key,
          )
      }
    None => None
  }
}

///|
fn[T] query_data_optional_component_value_at_planned_fetch_location(
  fetch : QueryDataPlannedFetch,
  key : ComponentKey[T],
) -> T? {
  match query_data_local_component_id_from_plan(fetch.plan, fetch.offset) {
    Some(local_component_id) =>
      match
        query_data_component_storage_type_or_abort(
          fetch.row.world,
          local_component_id,
        ) {
        Table =>
          match
            fetch.plan.cached_table_column(
              fetch.row.world,
              fetch.offset,
              fetch.row.table_id,
            ) {
            Some(_) =>
              match
                fetch.plan.value_at_table_row(
                  fetch.row.world,
                  key,
                  fetch.offset,
                  fetch.row.table_id,
                  fetch.row.row_index,
                ) {
                Some(value) => Some(value)
                None =>
                  abort(
                    "QueryData::fetch expected planned optional table component value at query table row",
                  )
              }
            None => None
          }
        SparseSet =>
          query_data_optional_component_value_by_entity(
            fetch.row.world,
            fetch.row.entity,
            key,
          )
      }
    None => None
  }
}

///|
pub fn[T] query_data_component_fetch(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T {
  query_data_require_component(world, entity, key)
}

///|
pub fn[T] query_data_component_optional(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? {
  world.component_value_by_key(entity, key)
}

///|
fn[T] query_data_require_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Write[T] {
  guard world.component_present(key.id(), entity) else {
    abort("QueryData::fetch expected component value to exist after matches")
  }
  let local_component_id = match world.local_component_id(key.id()) {
    Some(local_component_id) => local_component_id
    None => abort("QueryData::fetch expected component local id to exist")
  }
  let (table_id, row_index) = match world.entity_table_location(entity) {
    Some(location) => location
    None => (-1, -1)
  }
  mut_from_component_location(
    world, entity, key, local_component_id, table_id, row_index,
  )
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
pub impl QueryData for @core.Entity with fn matches(_world, _entity) {
  true
}

///|
pub impl QueryData for @core.Entity with fn fetch(_world, entity) {
  entity
}

///|
pub impl QueryData for @core.Entity with fn fetch_table_row(fetch) {
  fetch.entity
}

///|
pub impl QueryData for @core.Entity with fn mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for @core.Entity with fn matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl QueryData for @core.Entity with fn collect_access(_access) {
  ()
}

///|
pub impl QueryData for @core.Entity with fn requires_entity_check() {
  false
}

///|
pub impl QueryData for @core.Entity with fn is_dense(_world) {
  true
}

///|
pub impl QueryData for @core.Entity with fn iteration_anchor_component() {
  None
}

///|
pub impl QueryData for @core.Entity with fn contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Read[T] with fn matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn fetch(world, entity) {
  let key = T::component()
  query_data_comp_from_value(
    query_data_table_row_fetch(world, entity, -1, -1),
    key,
    query_data_component_local_id_or_abort(world.local_component_id(key.id())),
    query_data_require_component(world, entity, key),
  )
}

///|
pub impl[T : Component] QueryData for Read[T] with fn append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Read[T] with fn fetch_table_row(fetch) {
  let key = T::component()
  let local_component_id = query_data_component_local_id_or_abort(
    fetch.world.local_component_id(key.id()),
  )
  let value = query_data_component_value_at_fetch_location(
    fetch, key, local_component_id,
  )
  query_data_comp_from_value(fetch, key, local_component_id, value)
}

///|
pub impl[T : Component] QueryData for Read[T] with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let key = T::component()
  let local_component_id = query_data_component_local_id_or_abort(
    query_data_local_component_id_from_plan(fetch.plan, fetch.offset),
  )
  let value = query_data_component_value_at_planned_fetch_location(
    fetch, key, local_component_id,
  )
  query_data_comp_from_value(fetch.row, key, local_component_id, value)
}

///|
pub impl[T : Component] QueryData for Read[T] with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let key = T::component()
  match query_data_local_component_id_from_plan(fetch.plan, fetch.offset) {
    Some(local_component_id) if local_component_id ==
      fetch.anchor_local_component_id => {
      let value = query_data_require_component(
        fetch.row.world,
        fetch.row.entity,
        key,
      )
      query_data_comp_from_value(fetch.row, key, local_component_id, value)
    }
    _ =>
      Read::fetch_table_row_with_plan_offset({
        row: fetch.row,
        plan: fetch.plan,
        offset: fetch.offset,
      })
  }
}

///|
pub impl[T : Component] QueryData for Read[T] with fn mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Read[T] with fn matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn collect_required_components(
  access,
) {
  access.add_required_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Read[T] with fn is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Read[T] with fn iteration_anchor_components() {
  [T::component().id()]
}

///|
pub impl[T : Component] QueryData for Read[T] with fn contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Write[T] with fn matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn fetch(world, entity) {
  query_data_require_component_mut(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Write[T] with fn fetch_table_row(fetch) {
  let key = T::component()
  mut_from_component_location(
    fetch.world,
    fetch.entity,
    key,
    query_data_component_local_id_or_abort(
      fetch.world.local_component_id(key.id()),
    ),
    fetch.table_id,
    fetch.row_index,
  )
}

///|
pub impl[T : Component] QueryData for Write[T] with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let key = T::component()
  mut_from_component_location(
    fetch.row.world,
    fetch.row.entity,
    key,
    query_data_component_local_id_or_abort(
      query_data_local_component_id_from_plan(fetch.plan, fetch.offset),
    ),
    fetch.row.table_id,
    fetch.row.row_index,
  )
}

///|
pub impl[T : Component] QueryData for Write[T] with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  Write::fetch_table_row_with_plan_offset({
    row: fetch.row,
    plan: fetch.plan,
    offset: fetch.offset,
  })
}

///|
pub impl[T : Component] QueryData for Write[T] with fn mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Write[T] with fn matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn collect_access(access) {
  access.add_write_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn collect_required_components(
  access,
) {
  access.add_required_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Write[T] with fn is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Write[T] with fn iteration_anchor_components() {
  [T::component().id()]
}

///|
pub impl[T : Component] QueryData for Write[T] with fn contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityRef with fn matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityRef with fn fetch(world, entity) {
  try! world.entity(entity)
}

///|
pub impl QueryData for EntityRef with fn fetch_table_row(fetch) {
  EntityRef::{ world: fetch.world, entity: fetch.entity }
}

///|
pub impl QueryData for EntityRef with fn mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityRef with fn matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityRef with fn collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityRef with fn requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityRef with fn is_dense(_world) {
  true
}

///|
pub impl QueryData for EntityRef with fn iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityRef with fn contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityMut with fn matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityMut with fn fetch(world, entity) {
  try! world.entity_mut(entity)
}

///|
pub impl QueryData for EntityMut with fn fetch_table_row(fetch) {
  EntityMut::{ world: fetch.world, entity: fetch.entity }
}

///|
pub impl QueryData for EntityMut with fn mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityMut with fn matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityMut with fn collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityMut with fn requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityMut with fn is_dense(_world) {
  true
}

///|
pub impl QueryData for EntityMut with fn iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityMut with fn contiguous_compatible() {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with fn matches(_world, _entity) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with fn fetch(world, entity) {
  if T::matches(world, entity) {
    Some(T::fetch(world, entity))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fn append_fetch_plan(world, plan) {
  T::append_fetch_plan(world, plan)
}

///|
pub impl[T : QueryData] QueryData for T? with fn fetch_plan_size() {
  T::fetch_plan_size()
}

///|
pub impl[T : QueryData] QueryData for T? with fn fetch_table_row(fetch) {
  if T::matches(fetch.world, fetch.entity) {
    Some(T::fetch_table_row(fetch))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  if T::matches(fetch.row.world, fetch.row.entity) {
    Some(T::fetch_table_row_with_plan_offset(fetch))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  if T::matches(fetch.row.world, fetch.row.entity) {
    Some(T::fetch_sparse_anchor_with_plan_offset(fetch))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with fn mentions_component(
  component_id,
) {
  T::mentions_component(component_id)
}

///|
pub impl[T : QueryData] QueryData for T? with fn matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with fn collect_access(access) {
  T::collect_access(access)
}

///|
pub impl[T : QueryData] QueryData for T? with fn requires_entity_check() {
  false
}

///|
pub impl[T : QueryData] QueryData for T? with fn is_dense(world) {
  T::is_dense(world)
}

///|
pub impl[T : QueryData] QueryData for T? with fn iteration_anchor_component() {
  None
}

///|
pub impl[T : QueryData] QueryData for T? with fn contiguous_compatible() {
  T::contiguous_compatible()
}

///|
pub impl[T : Component] QueryData for Has[T] with fn matches(_world, _entity) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with fn fetch(world, entity) {
  { present: entity_has_component_id(world, T::component().id(), entity) }
}

///|
pub impl[T : Component] QueryData for Has[T] with fn append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Has[T] with fn fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Has[T] with fn fetch_table_row(fetch) {
  let present = match fetch.world.local_component_id(T::component().id()) {
    Some(local_component_id) =>
      if fetch.world.local_component_storage_type(local_component_id) ==
        Some(Table) {
        fetch.world.table_has_component_local_id(
          fetch.table_id,
          local_component_id,
        )
      } else {
        entity_has_component_id(fetch.world, T::component().id(), fetch.entity)
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let present = match
    query_data_local_component_id_from_plan(fetch.plan, fetch.offset) {
    Some(local_component_id) =>
      if fetch.row.world.local_component_storage_type(local_component_id) ==
        Some(Table) {
        fetch.row.world.table_has_component_local_id(
          fetch.row.table_id,
          local_component_id,
        )
      } else {
        entity_has_component_id(
          fetch.row.world,
          T::component().id(),
          fetch.row.entity,
        )
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let present = match
    query_data_local_component_id_from_plan(fetch.plan, fetch.offset) {
    Some(local_component_id) if local_component_id ==
      fetch.anchor_local_component_id => true
    Some(_local_component_id) =>
      if fetch.plan.component_is_table_at_offset(fetch.offset) {
        fetch.plan.cached_table_column(
          fetch.row.world,
          fetch.offset,
          fetch.row.table_id,
        )
        is Some(_)
      } else {
        entity_has_component_id(
          fetch.row.world,
          T::component().id(),
          fetch.row.entity,
        )
      }
    None => false
  }
  { present, }
}

///|
pub impl[T : Component] QueryData for Has[T] with fn mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Has[T] with fn matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with fn collect_access(_access) {
  ()
}

///|
pub impl[T : Component] QueryData for Has[T] with fn requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Has[T] with fn is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Has[T] with fn iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Has[T] with fn contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn matches(
  _world,
  _entity,
) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn fetch(world, entity) {
  {
    value: query_data_optional_component_value_by_entity(
      world,
      entity,
      T::component(),
    ),
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn append_fetch_plan(
  world,
  plan,
) {
  plan.push_component_id(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn fetch_plan_size() {
  1
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn fetch_table_row(fetch) {
  let key = T::component()
  { value: query_data_optional_component_value_at_fetch_location(fetch, key) }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let key = T::component()
  {
    value: query_data_optional_component_value_at_planned_fetch_location(
      fetch, key,
    ),
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let key = T::component()
  match query_data_local_component_id_from_plan(fetch.plan, fetch.offset) {
    Some(local_component_id) if local_component_id ==
      fetch.anchor_local_component_id => {
      ignore(local_component_id)
      {
        value: query_data_optional_component_value_by_entity(
          fetch.row.world,
          fetch.row.entity,
          key,
        ),
      }
    }
    _ =>
      Optional::fetch_table_row_with_plan_offset({
        row: fetch.row,
        plan: fetch.plan,
        offset: fetch.offset,
      })
  }
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn mentions_component(
  _component_id,
) {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Optional[T] with fn contiguous_compatible() {
  true
}

///|
pub impl QueryData for Unit with fn matches(_world, _entity) {
  true
}

///|
pub impl QueryData for Unit with fn fetch(_world, _entity) {
  ()
}

///|
pub impl QueryData for Unit with fn fetch_table_row(_fetch) {
  ()
}

///|
pub impl QueryData for Unit with fn mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for Unit with fn matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for Unit with fn collect_access(_access) {
  ()
}

///|
pub impl QueryData for Unit with fn requires_entity_check() {
  false
}

///|
pub impl QueryData for Unit with fn is_dense(_world) {
  true
}

///|
pub impl QueryData for Unit with fn iteration_anchor_component() {
  None
}

///|
pub impl QueryData for Unit with fn contiguous_compatible() {
  true
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn matches(
  world,
  entity,
) {
  A::matches(world, entity) && B::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn append_fetch_plan(
  world,
  plan,
) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn fetch_plan_size() {
  A::fetch_plan_size() + B::fetch_plan_size()
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn fetch_table_row(
  fetch,
) {
  (A::fetch_table_row(fetch), B::fetch_table_row(fetch))
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn mentions_component(
  component_id,
) {
  A::mentions_component(component_id) || B::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn collect_required_components(
  access,
) {
  A::collect_required_components(access)
  B::collect_required_components(access)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn requires_entity_check() {
  A::requires_entity_check() || B::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn is_dense(
  world,
) {
  A::is_dense(world) && B::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None => B::iteration_anchor_component()
  }
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn iteration_anchor_components() {
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
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fn contiguous_compatible() {
  A::contiguous_compatible() && B::contiguous_compatible()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn matches(
  world,
  entity,
) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity), C::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn append_fetch_plan(
  world,
  plan,
) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn fetch_plan_size() {
  A::fetch_plan_size() + B::fetch_plan_size() + C::fetch_plan_size()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn fetch_table_row(
  fetch,
) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn mentions_component(
  component_id,
) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn collect_required_components(
  access,
) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn is_dense(
  world,
) {
  A::is_dense(world) && B::is_dense(world) && C::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn iteration_anchor_component() {
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
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn iteration_anchor_components() {
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
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fn contiguous_compatible() {
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
) with fn matches(world, entity) {
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
) with fn fetch(world, entity) {
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
) with fn append_fetch_plan(world, plan) {
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
) with fn fetch_plan_size() {
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
) with fn fetch_table_row(fetch) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
    D::fetch_table_row(fetch),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fn fetch_table_row_with_plan_offset(fetch) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_table_row_with_plan_offset(fetch.with_offset(d_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fn fetch_sparse_anchor_with_plan_offset(fetch) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(d_offset)),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fn mentions_component(component_id) {
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
) with fn matches_component_set(set_contains_id) {
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
) with fn collect_access(access) {
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
) with fn collect_required_components(access) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
  D::collect_required_components(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fn requires_entity_check() {
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
) with fn is_dense(world) {
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
) with fn iteration_anchor_component() {
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
) with fn iteration_anchor_components() {
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
) with fn contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity) &&
  E::matches(world, entity)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
    E::fetch(world, entity),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn append_fetch_plan(world, plan) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
  D::append_fetch_plan(world, plan)
  E::append_fetch_plan(world, plan)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn fetch_plan_size() {
  A::fetch_plan_size() +
  B::fetch_plan_size() +
  C::fetch_plan_size() +
  D::fetch_plan_size() +
  E::fetch_plan_size()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn fetch_table_row(fetch) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
    D::fetch_table_row(fetch),
    E::fetch_table_row(fetch),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn fetch_table_row_with_plan_offset(fetch) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_table_row_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_table_row_with_plan_offset(fetch.with_offset(e_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(e_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn mentions_component(component_id) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id) ||
  E::mentions_component(component_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn matches_component_set(set_contains_id) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id) &&
  E::matches_component_set(set_contains_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
  E::collect_access(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn collect_required_components(access) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
  D::collect_required_components(access)
  E::collect_required_components(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check() ||
  E::requires_entity_check()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world) &&
  E::is_dense(world)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None =>
              match D::iteration_anchor_component() {
                Some(component_id) => Some(component_id)
                None => E::iteration_anchor_component()
              }
          }
      }
  }
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn iteration_anchor_components() {
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
  query_data_append_unique_anchor_components(
    component_ids,
    E::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
] QueryData for (A, B, C, D, E) with fn contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible() &&
  E::contiguous_compatible()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity) &&
  E::matches(world, entity) &&
  F::matches(world, entity)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
    E::fetch(world, entity),
    F::fetch(world, entity),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn append_fetch_plan(world, plan) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
  D::append_fetch_plan(world, plan)
  E::append_fetch_plan(world, plan)
  F::append_fetch_plan(world, plan)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn fetch_plan_size() {
  A::fetch_plan_size() +
  B::fetch_plan_size() +
  C::fetch_plan_size() +
  D::fetch_plan_size() +
  E::fetch_plan_size() +
  F::fetch_plan_size()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn fetch_table_row(fetch) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
    D::fetch_table_row(fetch),
    E::fetch_table_row(fetch),
    F::fetch_table_row(fetch),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_table_row_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_table_row_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_table_row_with_plan_offset(fetch.with_offset(f_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(f_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn mentions_component(component_id) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id) ||
  E::mentions_component(component_id) ||
  F::mentions_component(component_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id) &&
  E::matches_component_set(set_contains_id) &&
  F::matches_component_set(set_contains_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
  E::collect_access(access)
  F::collect_access(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn collect_required_components(access) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
  D::collect_required_components(access)
  E::collect_required_components(access)
  F::collect_required_components(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check() ||
  E::requires_entity_check() ||
  F::requires_entity_check()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world) &&
  E::is_dense(world) &&
  F::is_dense(world)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None =>
              match D::iteration_anchor_component() {
                Some(component_id) => Some(component_id)
                None =>
                  match E::iteration_anchor_component() {
                    Some(component_id) => Some(component_id)
                    None => F::iteration_anchor_component()
                  }
              }
          }
      }
  }
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn iteration_anchor_components() {
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
  query_data_append_unique_anchor_components(
    component_ids,
    E::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    F::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
] QueryData for (A, B, C, D, E, F) with fn contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible() &&
  E::contiguous_compatible() &&
  F::contiguous_compatible()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity) &&
  E::matches(world, entity) &&
  F::matches(world, entity) &&
  G::matches(world, entity)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
    E::fetch(world, entity),
    F::fetch(world, entity),
    G::fetch(world, entity),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn append_fetch_plan(world, plan) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
  D::append_fetch_plan(world, plan)
  E::append_fetch_plan(world, plan)
  F::append_fetch_plan(world, plan)
  G::append_fetch_plan(world, plan)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn fetch_plan_size() {
  A::fetch_plan_size() +
  B::fetch_plan_size() +
  C::fetch_plan_size() +
  D::fetch_plan_size() +
  E::fetch_plan_size() +
  F::fetch_plan_size() +
  G::fetch_plan_size()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn fetch_table_row(fetch) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
    D::fetch_table_row(fetch),
    E::fetch_table_row(fetch),
    F::fetch_table_row(fetch),
    G::fetch_table_row(fetch),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  let g_offset = f_offset + F::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_table_row_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_table_row_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_table_row_with_plan_offset(fetch.with_offset(f_offset)),
    G::fetch_table_row_with_plan_offset(fetch.with_offset(g_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  let g_offset = f_offset + F::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(f_offset)),
    G::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(g_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn mentions_component(component_id) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id) ||
  E::mentions_component(component_id) ||
  F::mentions_component(component_id) ||
  G::mentions_component(component_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id) &&
  E::matches_component_set(set_contains_id) &&
  F::matches_component_set(set_contains_id) &&
  G::matches_component_set(set_contains_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
  E::collect_access(access)
  F::collect_access(access)
  G::collect_access(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn collect_required_components(
  access,
) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
  D::collect_required_components(access)
  E::collect_required_components(access)
  F::collect_required_components(access)
  G::collect_required_components(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check() ||
  E::requires_entity_check() ||
  F::requires_entity_check() ||
  G::requires_entity_check()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world) &&
  E::is_dense(world) &&
  F::is_dense(world) &&
  G::is_dense(world)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None =>
              match D::iteration_anchor_component() {
                Some(component_id) => Some(component_id)
                None =>
                  match E::iteration_anchor_component() {
                    Some(component_id) => Some(component_id)
                    None =>
                      match F::iteration_anchor_component() {
                        Some(component_id) => Some(component_id)
                        None => G::iteration_anchor_component()
                      }
                  }
              }
          }
      }
  }
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn iteration_anchor_components() {
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
  query_data_append_unique_anchor_components(
    component_ids,
    E::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    F::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    G::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
] QueryData for (A, B, C, D, E, F, G) with fn contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible() &&
  E::contiguous_compatible() &&
  F::contiguous_compatible() &&
  G::contiguous_compatible()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity) &&
  E::matches(world, entity) &&
  F::matches(world, entity) &&
  G::matches(world, entity) &&
  H::matches(world, entity)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
    E::fetch(world, entity),
    F::fetch(world, entity),
    G::fetch(world, entity),
    H::fetch(world, entity),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn append_fetch_plan(world, plan) {
  A::append_fetch_plan(world, plan)
  B::append_fetch_plan(world, plan)
  C::append_fetch_plan(world, plan)
  D::append_fetch_plan(world, plan)
  E::append_fetch_plan(world, plan)
  F::append_fetch_plan(world, plan)
  G::append_fetch_plan(world, plan)
  H::append_fetch_plan(world, plan)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn fetch_plan_size() {
  A::fetch_plan_size() +
  B::fetch_plan_size() +
  C::fetch_plan_size() +
  D::fetch_plan_size() +
  E::fetch_plan_size() +
  F::fetch_plan_size() +
  G::fetch_plan_size() +
  H::fetch_plan_size()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn fetch_table_row(fetch) {
  (
    A::fetch_table_row(fetch),
    B::fetch_table_row(fetch),
    C::fetch_table_row(fetch),
    D::fetch_table_row(fetch),
    E::fetch_table_row(fetch),
    F::fetch_table_row(fetch),
    G::fetch_table_row(fetch),
    H::fetch_table_row(fetch),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn fetch_table_row_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  let g_offset = f_offset + F::fetch_plan_size()
  let h_offset = g_offset + G::fetch_plan_size()
  (
    A::fetch_table_row_with_plan_offset(fetch),
    B::fetch_table_row_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_table_row_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_table_row_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_table_row_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_table_row_with_plan_offset(fetch.with_offset(f_offset)),
    G::fetch_table_row_with_plan_offset(fetch.with_offset(g_offset)),
    H::fetch_table_row_with_plan_offset(fetch.with_offset(h_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn fetch_sparse_anchor_with_plan_offset(
  fetch,
) {
  let b_offset = fetch.offset + A::fetch_plan_size()
  let c_offset = b_offset + B::fetch_plan_size()
  let d_offset = c_offset + C::fetch_plan_size()
  let e_offset = d_offset + D::fetch_plan_size()
  let f_offset = e_offset + E::fetch_plan_size()
  let g_offset = f_offset + F::fetch_plan_size()
  let h_offset = g_offset + G::fetch_plan_size()
  (
    A::fetch_sparse_anchor_with_plan_offset(fetch),
    B::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(b_offset)),
    C::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(c_offset)),
    D::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(d_offset)),
    E::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(e_offset)),
    F::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(f_offset)),
    G::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(g_offset)),
    H::fetch_sparse_anchor_with_plan_offset(fetch.with_offset(h_offset)),
  )
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn mentions_component(
  component_id,
) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id) ||
  E::mentions_component(component_id) ||
  F::mentions_component(component_id) ||
  G::mentions_component(component_id) ||
  H::mentions_component(component_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id) &&
  E::matches_component_set(set_contains_id) &&
  F::matches_component_set(set_contains_id) &&
  G::matches_component_set(set_contains_id) &&
  H::matches_component_set(set_contains_id)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
  E::collect_access(access)
  F::collect_access(access)
  G::collect_access(access)
  H::collect_access(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn collect_required_components(
  access,
) {
  A::collect_required_components(access)
  B::collect_required_components(access)
  C::collect_required_components(access)
  D::collect_required_components(access)
  E::collect_required_components(access)
  F::collect_required_components(access)
  G::collect_required_components(access)
  H::collect_required_components(access)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check() ||
  E::requires_entity_check() ||
  F::requires_entity_check() ||
  G::requires_entity_check() ||
  H::requires_entity_check()
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world) &&
  E::is_dense(world) &&
  F::is_dense(world) &&
  G::is_dense(world) &&
  H::is_dense(world)
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None =>
              match D::iteration_anchor_component() {
                Some(component_id) => Some(component_id)
                None =>
                  match E::iteration_anchor_component() {
                    Some(component_id) => Some(component_id)
                    None =>
                      match F::iteration_anchor_component() {
                        Some(component_id) => Some(component_id)
                        None =>
                          match G::iteration_anchor_component() {
                            Some(component_id) => Some(component_id)
                            None => H::iteration_anchor_component()
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn iteration_anchor_components() {
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
  query_data_append_unique_anchor_components(
    component_ids,
    E::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    F::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    G::iteration_anchor_components(),
  )
  query_data_append_unique_anchor_components(
    component_ids,
    H::iteration_anchor_components(),
  )
  component_ids
}

///|
pub impl[
  A : QueryData,
  B : QueryData,
  C : QueryData,
  D : QueryData,
  E : QueryData,
  F : QueryData,
  G : QueryData,
  H : QueryData,
] QueryData for (A, B, C, D, E, F, G, H) with fn contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible() &&
  E::contiguous_compatible() &&
  F::contiguous_compatible() &&
  G::contiguous_compatible() &&
  H::contiguous_compatible()
}
