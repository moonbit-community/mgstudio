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
pub struct QueryState[_, F] {
  priv filter : F
  priv mut cached_candidate_archetypes : Array[Int]
  priv mut cached_anchor_component_id : Int?
  priv mut cached_filter_anchor_component_id : Int?
  priv mut cached_candidate_anchor_component_id : Int?
  priv mut cached_candidate_archetype_generation : Int
  priv mut cached_matching_entities : Array[@core.Entity]
  priv mut cached_matching_archetypes : Array[Int]
  priv mut cached_matching_archetype_bits : @utils.IntBitSet
  priv mut cached_matching_archetype_generation : Int
  priv mut cached_matching_entities_generation : Int
  priv mut cached_matching_entities_tick : Int
  priv mut cached_matching_anchor_component_id : Int?
  priv mut cached_matching_filter_anchor_component_id : Int?
  priv mut cached_matching_candidate_anchor_component_id : Int?
  priv mut cached_matching_generation : Int
  priv mut cached_matching_tick : Int
  priv mut cached_matching_entities_valid : Bool
  priv mut cached_matching_tables : Array[Int]
  priv mut cached_matching_table_bits : @utils.IntBitSet
  priv mut cached_matching_tables_generation : Int
  priv mut cached_matching_tables_valid : Bool
  priv mut cached_is_dense : Bool
  priv mut cached_default_filter_component_ids : Array[Int]
  priv mut cached_default_filter_local_component_ids : Array[Int]
  priv mut cached_default_filters_world_id : Int
  priv mut cached_dependency_component_ids : Array[Int]
  priv mut cached_dependency_world_id : Int
  priv mut cached_dependency_component_registration_generation : Int
  priv mut cached_data_fetch_plan : QueryDataFetchPlan
  priv mut cached_data_fetch_plan_world_id : Int
  priv mut cached_data_fetch_plan_component_registration_generation : Int
}

///|
pub struct QueryCache {
  priv mut cached_candidate_archetypes : Array[Int]
  priv mut cached_anchor_component_id : Int?
  priv mut cached_filter_anchor_component_id : Int?
  priv mut cached_candidate_anchor_component_id : Int?
  priv mut cached_candidate_archetype_generation : Int
  priv mut cached_matching_entities : Array[@core.Entity]
  priv mut cached_matching_archetypes : Array[Int]
  priv mut cached_matching_archetype_bits : @utils.IntBitSet
  priv mut cached_matching_archetype_generation : Int
  priv mut cached_matching_entities_generation : Int
  priv mut cached_matching_entities_tick : Int
  priv mut cached_matching_anchor_component_id : Int?
  priv mut cached_matching_filter_anchor_component_id : Int?
  priv mut cached_matching_candidate_anchor_component_id : Int?
  priv mut cached_matching_generation : Int
  priv mut cached_matching_tick : Int
  priv mut cached_matching_entities_valid : Bool
  priv mut cached_matching_tables : Array[Int]
  priv mut cached_matching_table_bits : @utils.IntBitSet
  priv mut cached_matching_tables_generation : Int
  priv mut cached_matching_tables_valid : Bool
  priv mut cached_is_dense : Bool
  priv mut cached_default_filter_component_ids : Array[Int]
  priv mut cached_default_filter_local_component_ids : Array[Int]
  priv mut cached_default_filters_world_id : Int
  priv mut cached_dependency_component_ids : Array[Int]
  priv mut cached_dependency_world_id : Int
  priv mut cached_dependency_component_registration_generation : Int
} derive(ToJson, FromJson)

///|
pub struct QueryCacheSnapshot {
  priv cached_candidate_archetypes : Array[Int]
  priv cached_anchor_component_id : Int?
  priv cached_filter_anchor_component_id : Int?
  priv cached_candidate_anchor_component_id : Int?
  priv cached_candidate_archetype_generation : Int
  priv cached_matching_entities : Array[@core.Entity]
  priv cached_matching_archetypes : Array[Int]
  priv cached_matching_archetype_bits : @utils.IntBitSet
  priv cached_matching_archetype_generation : Int
  priv cached_matching_entities_generation : Int
  priv cached_matching_entities_tick : Int
  priv cached_matching_anchor_component_id : Int?
  priv cached_matching_filter_anchor_component_id : Int?
  priv cached_matching_candidate_anchor_component_id : Int?
  priv cached_matching_generation : Int
  priv cached_matching_tick : Int
  priv cached_matching_entities_valid : Bool
  priv cached_matching_tables : Array[Int]
  priv cached_matching_table_bits : @utils.IntBitSet
  priv cached_matching_tables_generation : Int
  priv cached_matching_tables_valid : Bool
  priv cached_is_dense : Bool
  priv cached_default_filter_component_ids : Array[Int]
  priv cached_default_filter_local_component_ids : Array[Int]
  priv cached_default_filters_world_id : Int
  priv cached_dependency_component_ids : Array[Int]
  priv cached_dependency_world_id : Int
  priv cached_dependency_component_registration_generation : Int
} derive(ToJson, FromJson)

///|
pub fn QueryCacheSnapshot::cached_candidate_archetype_generation(
  self : QueryCacheSnapshot,
) -> Int {
  self.cached_candidate_archetype_generation
}

///|
pub fn QueryCacheSnapshot::cached_candidate_archetypes(
  self : QueryCacheSnapshot,
) -> Array[Int] {
  self.cached_candidate_archetypes
}

///|
pub fn QueryCacheSnapshot::cached_anchor_component_id(
  self : QueryCacheSnapshot,
) -> Int? {
  self.cached_anchor_component_id
}

///|
pub fn QueryCacheSnapshot::cached_filter_anchor_component_id(
  self : QueryCacheSnapshot,
) -> Int? {
  self.cached_filter_anchor_component_id
}

///|
pub fn QueryCacheSnapshot::cached_candidate_anchor_component_id(
  self : QueryCacheSnapshot,
) -> Int? {
  self.cached_candidate_anchor_component_id
}

///|
pub fn QueryCacheSnapshot::cached_matching_archetype_generation(
  self : QueryCacheSnapshot,
) -> Int {
  self.cached_matching_archetype_generation
}

///|
pub fn QueryCacheSnapshot::cached_matching_entities_generation(
  self : QueryCacheSnapshot,
) -> Int {
  self.cached_matching_entities_generation
}

///|
pub fn QueryCacheSnapshot::cached_matching_entities_tick(
  self : QueryCacheSnapshot,
) -> Int {
  self.cached_matching_entities_tick
}

///|
pub fn QueryCacheSnapshot::cached_matching_entities_valid(
  self : QueryCacheSnapshot,
) -> Bool {
  self.cached_matching_entities_valid
}

///|
pub fn QueryCacheSnapshot::cached_matching_archetypes(
  self : QueryCacheSnapshot,
) -> Array[Int] {
  self.cached_matching_archetypes
}

///|
pub fn QueryCacheSnapshot::cached_is_dense(self : QueryCacheSnapshot) -> Bool {
  self.cached_is_dense
}

///|
pub fn QueryCacheSnapshot::cached_matching_tables(
  self : QueryCacheSnapshot,
) -> Array[Int] {
  self.cached_matching_tables
}

///|
pub fn QueryCacheSnapshot::cached_matching_tables_generation(
  self : QueryCacheSnapshot,
) -> Int {
  self.cached_matching_tables_generation
}

///|
pub fn QueryCacheSnapshot::cached_matching_table_bits(
  self : QueryCacheSnapshot,
) -> @utils.IntBitSet {
  self.cached_matching_table_bits
}

///|
fn QueryCache::snapshot(self : QueryCache) -> QueryCacheSnapshot {
  {
    cached_candidate_archetypes: self.cached_candidate_archetypes,
    cached_anchor_component_id: self.cached_anchor_component_id,
    cached_filter_anchor_component_id: self.cached_filter_anchor_component_id,
    cached_candidate_anchor_component_id: self.cached_candidate_anchor_component_id,
    cached_candidate_archetype_generation: self.cached_candidate_archetype_generation,
    cached_matching_entities: self.cached_matching_entities,
    cached_matching_archetypes: self.cached_matching_archetypes,
    cached_matching_archetype_bits: self.cached_matching_archetype_bits,
    cached_matching_archetype_generation: self.cached_matching_archetype_generation,
    cached_matching_entities_generation: self.cached_matching_entities_generation,
    cached_matching_entities_tick: self.cached_matching_entities_tick,
    cached_matching_anchor_component_id: self.cached_matching_anchor_component_id,
    cached_matching_filter_anchor_component_id: self.cached_matching_filter_anchor_component_id,
    cached_matching_candidate_anchor_component_id: self.cached_matching_candidate_anchor_component_id,
    cached_matching_generation: self.cached_matching_generation,
    cached_matching_tick: self.cached_matching_tick,
    cached_matching_entities_valid: self.cached_matching_entities_valid,
    cached_matching_tables: self.cached_matching_tables,
    cached_matching_table_bits: self.cached_matching_table_bits,
    cached_matching_tables_generation: self.cached_matching_tables_generation,
    cached_matching_tables_valid: self.cached_matching_tables_valid,
    cached_is_dense: self.cached_is_dense,
    cached_default_filter_component_ids: self.cached_default_filter_component_ids,
    cached_default_filter_local_component_ids: self.cached_default_filter_local_component_ids,
    cached_default_filters_world_id: self.cached_default_filters_world_id,
    cached_dependency_component_ids: self.cached_dependency_component_ids,
    cached_dependency_world_id: self.cached_dependency_world_id,
    cached_dependency_component_registration_generation: self.cached_dependency_component_registration_generation,
  }
}

///|
pub struct Query[_, F] {
  priv world : World
  priv filter : F
  priv mut cache : QueryCache?
}

///|
priv struct QueryIterationPlan {
  data_fetch_plan : QueryDataFetchPlan
  default_filter_component_ids : Array[Int]
  entities_pre_matched : Bool
  archetype_driven : Bool
  dense_driven : Bool
  table_row_filter_required : Bool
  archetypes : Array[Int]
  dense_tables : Array[Int]
  sparse_anchor_info : QuerySparseAnchorInfo?
  sparse_anchor_archetype_bits : @utils.IntBitSet
  entities : Array[@core.Entity]
}

///|
pub struct QueryMany[D, F] {
  priv query : Query[D, F]
  priv data_fetch_plan : QueryDataFetchPlan
  priv default_filter_component_ids : Array[Int]
  priv entities_pre_matched : Bool
  priv archetype_driven : Bool
  priv dense_driven : Bool
  priv table_row_filter_required : Bool
  priv archetypes : Array[Int]
  priv mut archetype_index : Int
  priv mut archetype_entities : Array[@core.Entity]
  priv mut archetype_entity_index : Int
  priv mut current_table_id : Int
  priv dense_tables : Array[Int]
  priv mut dense_table_index : Int
  priv mut dense_table_entities : Array[@core.Entity]
  priv mut dense_table_row_count : Int
  priv mut dense_table_row_index : Int
  priv sparse_anchor_info : QuerySparseAnchorInfo?
  priv sparse_anchor_entities : Array[@core.Entity]
  priv mut sparse_anchor_index : Int
  priv entities : Array[@core.Entity]
  priv mut index : Int
}

///|
pub struct QueryCombinations[D, F] {
  priv query : Query[D, F]
  priv default_filter_component_ids : Array[Int]
  priv entities_pre_matched : Bool
  priv entities : Array[@core.Entity]
  priv mut left_index : Int
  priv mut right_index : Int
}

///|
pub struct QueryContiguousIter[D, F] {
  priv query : Query[D, F]
  priv default_filter_component_ids : Array[Int]
  priv entities_pre_matched : Bool
  priv entities : Array[@core.Entity]
  priv mut index : Int
}

///|
pub struct QueryParallel[D, F] {
  priv query : Query[D, F]
  priv batching_strategy : BatchingStrategy
}

///|
priv struct QuerySparseAnchorInfo {
  local_component_id : Int
  component_definition_id : Int
}

///|
pub struct Has[_] {
  priv present : Bool
}

///|
pub fn[T] Has::new(key : ComponentKey[T]) -> Has[T] {
  ignore(key)
  Has::{ present: false }
}

///|
pub fn[T : Component] Has::key(self : Has[T]) -> ComponentKey[T] {
  ignore(self)
  T::component()
}

///|
pub fn[T] Has::present(self : Has[T]) -> Bool {
  self.present
}

///|
pub struct Optional[T] {
  priv value : T?
}

///|
pub fn[T] Optional::new(key : ComponentKey[T]) -> Optional[T] {
  ignore(key)
  Optional::{ value: None }
}

///|
pub fn[T : Component] Optional::key(self : Optional[T]) -> ComponentKey[T] {
  ignore(self)
  T::component()
}

///|
pub fn[T] Optional::value(self : Optional[T]) -> T? {
  self.value
}

///|
pub fn[F] World::query_entities_filtered(
  self : World,
  filter : F,
) -> Query[@core.Entity, F] {
  Query::{ world: self, filter, cache: None }
}

///|
pub fn[D] World::query(self : World) -> QueryState[D, All] {
  ignore(self)
  query_state_new(All::new())
}

///|
pub fn[D, F] World::query_filtered(
  self : World,
  filter : F,
) -> QueryState[D, F] {
  ignore(self)
  query_state_new(filter)
}

///|
pub fn QueryCache::new() -> QueryCache {
  {
    cached_candidate_archetypes: [],
    cached_anchor_component_id: None,
    cached_filter_anchor_component_id: None,
    cached_candidate_anchor_component_id: None,
    cached_candidate_archetype_generation: -1,
    cached_matching_entities: [],
    cached_matching_archetypes: [],
    cached_matching_archetype_bits: @utils.IntBitSet::new(),
    cached_matching_archetype_generation: -1,
    cached_matching_entities_generation: -1,
    cached_matching_entities_tick: -1,
    cached_matching_anchor_component_id: None,
    cached_matching_filter_anchor_component_id: None,
    cached_matching_candidate_anchor_component_id: None,
    cached_matching_generation: -1,
    cached_matching_tick: -1,
    cached_matching_entities_valid: false,
    cached_matching_tables: [],
    cached_matching_table_bits: @utils.IntBitSet::new(),
    cached_matching_tables_generation: -1,
    cached_matching_tables_valid: false,
    cached_is_dense: false,
    cached_default_filter_component_ids: [],
    cached_default_filter_local_component_ids: [],
    cached_default_filters_world_id: -1,
    cached_dependency_component_ids: [],
    cached_dependency_world_id: -1,
    cached_dependency_component_registration_generation: -1,
  }
}

///|
pub fn[D] query(world : World) -> Query[D, All] {
  Query::{ world, filter: All::new(), cache: None }
}

///|
pub fn[D, F] query_filtered(world : World, filter : F) -> Query[D, F] {
  Query::{ world, filter, cache: None }
}

///|
pub fn[D, F] query_filtered_with_cache(
  world : World,
  filter : F,
  cache : QueryCache,
) -> Query[D, F] {
  Query::{ world, filter, cache: Some(cache) }
}

///|
pub fn[D, F] Query::cache_snapshot(self : Query[D, F]) -> QueryCacheSnapshot {
  match self.cache {
    Some(cache) => cache.snapshot()
    None => QueryCache::new().snapshot()
  }
}

///|
pub fn[D, F] Query::cache_state(self : Query[D, F]) -> QueryCache {
  match self.cache {
    Some(cache) => cache
    None => QueryCache::new()
  }
}

///|
fn[D, F] query_state_new(filter : F) -> QueryState[D, F] {
  {
    filter,
    cached_candidate_archetypes: [],
    cached_anchor_component_id: None,
    cached_filter_anchor_component_id: None,
    cached_candidate_anchor_component_id: None,
    cached_candidate_archetype_generation: -1,
    cached_matching_entities: [],
    cached_matching_archetypes: [],
    cached_matching_archetype_bits: @utils.IntBitSet::new(),
    cached_matching_archetype_generation: -1,
    cached_matching_entities_generation: -1,
    cached_matching_entities_tick: -1,
    cached_matching_anchor_component_id: None,
    cached_matching_filter_anchor_component_id: None,
    cached_matching_candidate_anchor_component_id: None,
    cached_matching_generation: -1,
    cached_matching_tick: -1,
    cached_matching_entities_valid: false,
    cached_matching_tables: [],
    cached_matching_table_bits: @utils.IntBitSet::new(),
    cached_matching_tables_generation: -1,
    cached_matching_tables_valid: false,
    cached_is_dense: false,
    cached_default_filter_component_ids: [],
    cached_default_filter_local_component_ids: [],
    cached_default_filters_world_id: -1,
    cached_dependency_component_ids: [],
    cached_dependency_world_id: -1,
    cached_dependency_component_registration_generation: -1,
    cached_data_fetch_plan: QueryDataFetchPlan::new(),
    cached_data_fetch_plan_world_id: -1,
    cached_data_fetch_plan_component_registration_generation: -1,
  }
}

///|
pub fn[D, F] QueryState::cache_snapshot(
  self : QueryState[D, F],
) -> QueryCacheSnapshot {
  {
    cached_candidate_archetypes: self.cached_candidate_archetypes,
    cached_anchor_component_id: self.cached_anchor_component_id,
    cached_filter_anchor_component_id: self.cached_filter_anchor_component_id,
    cached_candidate_anchor_component_id: self.cached_candidate_anchor_component_id,
    cached_candidate_archetype_generation: self.cached_candidate_archetype_generation,
    cached_matching_entities: self.cached_matching_entities,
    cached_matching_archetypes: self.cached_matching_archetypes,
    cached_matching_archetype_bits: self.cached_matching_archetype_bits,
    cached_matching_archetype_generation: self.cached_matching_archetype_generation,
    cached_matching_entities_generation: self.cached_matching_entities_generation,
    cached_matching_entities_tick: self.cached_matching_entities_tick,
    cached_matching_anchor_component_id: self.cached_matching_anchor_component_id,
    cached_matching_filter_anchor_component_id: self.cached_matching_filter_anchor_component_id,
    cached_matching_candidate_anchor_component_id: self.cached_matching_candidate_anchor_component_id,
    cached_matching_generation: self.cached_matching_generation,
    cached_matching_tick: self.cached_matching_tick,
    cached_matching_entities_valid: self.cached_matching_entities_valid,
    cached_matching_tables: self.cached_matching_tables,
    cached_matching_table_bits: self.cached_matching_table_bits,
    cached_matching_tables_generation: self.cached_matching_tables_generation,
    cached_matching_tables_valid: self.cached_matching_tables_valid,
    cached_is_dense: self.cached_is_dense,
    cached_default_filter_component_ids: self.cached_default_filter_component_ids,
    cached_default_filter_local_component_ids: self.cached_default_filter_local_component_ids,
    cached_default_filters_world_id: self.cached_default_filters_world_id,
    cached_dependency_component_ids: self.cached_dependency_component_ids,
    cached_dependency_world_id: self.cached_dependency_world_id,
    cached_dependency_component_registration_generation: self.cached_dependency_component_registration_generation,
  }
}

///|
fn[D, F] Query::ensure_cache(self : Query[D, F]) -> QueryCache {
  match self.cache {
    Some(cache) => cache
    None => {
      let cache = QueryCache::new()
      self.cache = Some(cache)
      cache
    }
  }
}

///|
fn[D : QueryData, F] QueryState::data_fetch_plan(
  self : QueryState[D, F],
  world : World,
) -> QueryDataFetchPlan {
  let world_id = world.world_id()
  let component_registration_generation = world.component_registration_generation()
  if self.cached_data_fetch_plan_world_id != world_id ||
    self.cached_data_fetch_plan_component_registration_generation !=
    component_registration_generation {
    self.cached_data_fetch_plan = D::prepare_fetch_plan(world)
    self.cached_data_fetch_plan_world_id = world_id
    self.cached_data_fetch_plan_component_registration_generation = component_registration_generation
  }
  self.cached_data_fetch_plan
}

///|
fn[D, F] query_many_from_plan(
  query : Query[D, F],
  plan : QueryIterationPlan,
) -> QueryMany[D, F] {
  {
    query,
    data_fetch_plan: plan.data_fetch_plan,
    default_filter_component_ids: plan.default_filter_component_ids,
    entities_pre_matched: plan.entities_pre_matched,
    archetype_driven: plan.archetype_driven,
    dense_driven: plan.dense_driven,
    table_row_filter_required: plan.table_row_filter_required,
    archetypes: plan.archetypes,
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    current_table_id: -1,
    dense_tables: plan.dense_tables,
    dense_table_index: 0,
    dense_table_entities: [],
    dense_table_row_count: 0,
    dense_table_row_index: 0,
    sparse_anchor_info: plan.sparse_anchor_info,
    sparse_anchor_entities: match plan.sparse_anchor_info {
      Some(anchor_info) =>
        query_sparse_anchor_entities(
          query.world,
          anchor_info,
          plan.sparse_anchor_archetype_bits,
        )
      None => []
    },
    sparse_anchor_index: 0,
    entities: plan.entities,
    index: 0,
  }
}

///|
fn[D : QueryData, F : QueryFilter] Query::iteration_plan(
  self : Query[D, F],
  default_filter_component_ids : Array[Int],
) -> QueryIterationPlan {
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    self.world,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  let archetype_driven = access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check
  let archetypes = if archetype_driven {
    self.matching_archetypes()
  } else {
    []
  }
  let entities = if archetype_driven { [] } else { self.matching_entities() }
  let dense_driven = archetype_driven &&
    query_is_dense_mode(
      self.world,
      self.filter,
      default_filter_component_ids,
      D::is_dense,
      D::collect_access,
    )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    self.world,
  )
  let sparse_anchor_info = if archetype_driven &&
    !dense_driven &&
    !table_row_filter_required {
    query_sparse_anchor_info(
      self.world,
      D::iteration_anchor_components(),
      QueryFilter::iteration_anchor_components(self.filter),
    )
  } else {
    None
  }
  {
    data_fetch_plan: D::prepare_fetch_plan(self.world),
    default_filter_component_ids,
    entities_pre_matched: true,
    archetype_driven,
    dense_driven,
    table_row_filter_required,
    archetypes,
    dense_tables: if dense_driven {
      self.matching_dense_tables()
    } else {
      []
    },
    sparse_anchor_info,
    sparse_anchor_archetype_bits: match sparse_anchor_info {
      Some(_) => self.ensure_cache().cached_matching_archetype_bits
      None => @utils.IntBitSet::new()
    },
    entities,
  }
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::iteration_plan(
  self : QueryState[D, F],
  world : World,
  default_filter_component_ids : Array[Int],
) -> QueryIterationPlan {
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    world,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  let archetype_driven = access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check
  let archetypes = if archetype_driven {
    self.query_matching_archetypes(world)
  } else {
    []
  }
  let entities = if archetype_driven {
    []
  } else {
    self.query_matching_entities(world)
  }
  let dense_driven = archetype_driven &&
    query_is_dense_mode(
      world,
      self.filter,
      default_filter_component_ids,
      D::is_dense,
      D::collect_access,
    )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    world,
  )
  let sparse_anchor_info = if archetype_driven &&
    !dense_driven &&
    !table_row_filter_required {
    query_sparse_anchor_info(
      world,
      D::iteration_anchor_components(),
      QueryFilter::iteration_anchor_components(self.filter),
    )
  } else {
    None
  }
  {
    data_fetch_plan: self.data_fetch_plan(world),
    default_filter_component_ids,
    entities_pre_matched: true,
    archetype_driven,
    dense_driven,
    table_row_filter_required,
    archetypes,
    dense_tables: if dense_driven {
      self.query_matching_tables(world)
    } else {
      []
    },
    sparse_anchor_info,
    sparse_anchor_archetype_bits: match sparse_anchor_info {
      Some(_) => self.cached_matching_archetype_bits
      None => @utils.IntBitSet::new()
    },
    entities,
  }
}

///|
fn query_sparse_anchor_info(
  world : World,
  data_anchor_component_ids : Array[Int],
  filter_anchor_component_ids : Array[Int],
) -> QuerySparseAnchorInfo? {
  let data_anchor_component_id = query_min_anchor_component_id(
    world, data_anchor_component_ids,
  )
  let filter_anchor_component_id = query_min_anchor_component_id(
    world, filter_anchor_component_ids,
  )
  guard query_candidate_anchor_component_id(
      world, data_anchor_component_id, filter_anchor_component_id,
    )
    is Some(component_id) else {
    return None
  }
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return None
  }
  guard world.local_component_storage_type(local_component_id) ==
    Some(SparseSet) else {
    return None
  }
  Some({ local_component_id, component_definition_id: component_id })
}

///|
fn query_sparse_anchor_entities(
  world : World,
  anchor_info : QuerySparseAnchorInfo,
  matched_archetype_bits : @utils.IntBitSet,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let ops = component_ops(anchor_info.component_definition_id)
  (ops.for_each_entity)(world, fn(entity) {
    guard world.entity_has_component_local_id(
      entity,
      anchor_info.local_component_id,
    ) else {
      return
    }
    guard world.entity_archetype_id(entity) is Some(archetype_id) else {
      return
    }
    if matched_archetype_bits.contains(archetype_id) {
      entities.push(entity)
    }
  })
  entities
}

///|
fn[D : QueryData] query_fetch_with_sparse_anchor(
  world : World,
  entity : @core.Entity,
  anchor_info : QuerySparseAnchorInfo,
  plan : QueryDataFetchPlan,
) -> D raise EcsError {
  match world.entity_table_location(entity) {
    Some((table_id, row_index)) =>
      D::fetch_sparse_anchor_with_plan_offset(
        query_data_table_row_fetch(world, entity, table_id, row_index).sparse_anchor(
          anchor_info.local_component_id,
          plan,
          0,
        ),
      )
    None => D::fetch(world, entity)
  }
}

///|
fn[D : QueryData] query_fetch_entity_table_row(
  world : World,
  entity : @core.Entity,
) -> D raise EcsError {
  match world.entity_table_location(entity) {
    Some((table_id, row_index)) =>
      D::fetch_table_row(
        query_data_table_row_fetch(world, entity, table_id, row_index),
      )
    None => D::fetch(world, entity)
  }
}

///|
fn[D : QueryData] query_fetch_entity_table_row_with_plan(
  world : World,
  entity : @core.Entity,
  plan : QueryDataFetchPlan,
) -> D raise EcsError {
  match world.entity_table_location(entity) {
    Some((table_id, row_index)) =>
      D::fetch_table_row_with_plan_offset(
        query_data_table_row_fetch(world, entity, table_id, row_index).planned(
          plan, 0,
        ),
      )
    None => D::fetch(world, entity)
  }
}

///|
fn[D : QueryData] query_fetch_known_table_row_with_plan(
  world : World,
  entity : @core.Entity,
  table_id : Int,
  plan : QueryDataFetchPlan,
) -> D raise EcsError {
  match world.entity_table_location(entity) {
    Some((actual_table_id, row_index)) if actual_table_id == table_id =>
      D::fetch_table_row_with_plan_offset(
        query_data_table_row_fetch(world, entity, table_id, row_index).planned(
          plan, 0,
        ),
      )
    _ => query_fetch_entity_table_row_with_plan(world, entity, plan)
  }
}

///|
fn[D : QueryData, F : QueryFilter] query_dense_tables_single(
  world : World,
  dense_tables : Array[Int],
  filter : F,
  table_row_filter_required : Bool,
  plan : QueryDataFetchPlan,
) -> D? raise EcsError {
  let mut found : @core.Entity? = None
  let mut found_table_id = -1
  let mut found_row_index = -1
  for table_id in dense_tables {
    guard world.table_entities_view(table_id) is Some(entities) else {
      continue
    }
    let row_count = entities.length()
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard query_filter_matches_table_row_if_needed(
        world, filter, table_row_filter_required, entity, table_id, row_index,
      ) else {
        continue
      }
      if found is Some(_) {
        return None
      }
      found = Some(entity)
      found_table_id = table_id
      found_row_index = row_index
    }
  }
  match found {
    Some(entity) =>
      Some(
        D::fetch_table_row_with_plan_offset(
          query_data_table_row_fetch(
            world, entity, found_table_id, found_row_index,
          ).planned(plan, 0),
        ),
      )
    None => None
  }
}

///|
fn[F : QueryFilter] query_dense_tables_count(
  world : World,
  dense_tables : Array[Int],
  filter : F,
  table_row_filter_required : Bool,
) -> Int {
  if !table_row_filter_required {
    let mut count = 0
    for table_id in dense_tables {
      match world.table_entities_view(table_id) {
        Some(entities) => count = count + entities.length()
        None => ()
      }
    }
    return count
  }
  let mut count = 0
  for table_id in dense_tables {
    guard world.table_entities_view(table_id) is Some(entities) else {
      continue
    }
    let row_count = entities.length()
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      if QueryFilter::matches_table_row(
          filter, world, entity, table_id, row_index,
        ) {
        count = count + 1
      }
    }
  }
  count
}

///|
fn query_sparse_anchor_count_matching(
  world : World,
  anchor_info : QuerySparseAnchorInfo,
  matched_archetype_bits : @utils.IntBitSet,
) -> Int {
  query_sparse_anchor_entities(world, anchor_info, matched_archetype_bits).length()
}

///|
fn[D : QueryData] query_sparse_anchor_single_matching(
  world : World,
  anchor_info : QuerySparseAnchorInfo,
  matched_archetype_bits : @utils.IntBitSet,
) -> D? raise EcsError {
  let entities = query_sparse_anchor_entities(
    world, anchor_info, matched_archetype_bits,
  )
  guard entities.length() == 1 else { return None }
  let plan = D::prepare_fetch_plan(world)
  let entity = entities[0]
  guard world.component_present_by_local_id(
    entity,
    anchor_info.local_component_id,
  ) else {
    return None
  }
  Some(query_fetch_with_sparse_anchor(world, entity, anchor_info, plan))
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::get(
  self : Query[D, F],
  entity : @core.Entity,
) -> D? raise EcsError {
  let default_filter_component_ids = self.default_filter_component_ids()
  query_get_with_default_filter_component_ids(
    self, entity, default_filter_component_ids,
  )
}

///|
fn[D : QueryData, F : QueryFilter] query_get_with_default_filter_component_ids(
  query : Query[D, F],
  entity : @core.Entity,
  default_filter_component_ids : Array[Int],
) -> D? raise EcsError {
  guard query.world.is_alive(entity) else { raise EntityNotAlive(entity) }
  guard query_matches_with_default_filter_component_ids(
    query.world,
    entity,
    query.filter,
    default_filter_component_ids,
  ) else {
    return None
  }
  guard D::matches(query.world, entity) else { return None }
  Some(query_fetch_entity_table_row(query.world, entity))
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::view(
  self : Query[D, F],
  f : (@core.Entity, D) -> Unit,
) -> Unit raise EcsError {
  self.world.begin_query_iteration()
  let result : Result[Unit, EcsError] = try? ({
    let iter = self.iter()
    while iter.fetch_next() is Some((entity, item)) {
      f(entity, item)
    }
  })
  self.world.end_query_iteration()
  match result {
    Ok(_) => ()
    Err(err) => raise err
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::for_each(
  self : Query[D, F],
  f : (@core.Entity, D) -> Unit,
) -> Unit raise EcsError {
  self.view(f)
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter(
  self : Query[D, F],
) -> QueryMany[D, F] {
  query_many_from_plan(
    self,
    self.iteration_plan(self.default_filter_component_ids()),
  )
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::count(self : Query[D, F]) -> Int {
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    self.world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    self.world,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_tables = self.matching_dense_tables()
    if dense_tables.length() > 0 {
      return query_dense_tables_count(
        self.world,
        dense_tables,
        self.filter,
        table_row_filter_required,
      )
    }
    let matched_archetypes = self.matching_archetypes()
    let cache = self.ensure_cache()
    match
      query_sparse_anchor_info(
        self.world,
        data_anchor_component_ids,
        filter_anchor_component_ids,
      ) {
      Some(anchor_info) if !cache.cached_is_dense =>
        if !table_row_filter_required {
          return query_sparse_anchor_count_matching(
            self.world,
            anchor_info,
            cache.cached_matching_archetype_bits,
          )
        }
      _ => ()
    }
    let mut count = 0
    for archetype_id in matched_archetypes {
      if table_row_filter_required {
        match self.world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              if query_filter_matches_entity_table_row(
                  self.world,
                  self.filter,
                  entity,
                ) {
                count = count + 1
              }
            }
          None => ()
        }
      } else {
        count = count + self.world.archetype_entity_count(archetype_id)
      }
    }
    return count
  }
  self.matching_entities().length()
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::single(
  self : Query[D, F],
) -> D? raise EcsError {
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    self.world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    self.world,
  )
  let data_fetch_plan = D::prepare_fetch_plan(self.world)
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_tables = self.matching_dense_tables()
    if dense_tables.length() > 0 {
      query_dense_tables_single(
        self.world,
        dense_tables,
        self.filter,
        table_row_filter_required,
        data_fetch_plan,
      )
    } else {
      let matched_archetypes = self.matching_archetypes()
      let cache = self.ensure_cache()
      match
        query_sparse_anchor_info(
          self.world,
          data_anchor_component_ids,
          filter_anchor_component_ids,
        ) {
        Some(anchor_info) if !cache.cached_is_dense =>
          if !table_row_filter_required {
            return query_sparse_anchor_single_matching(
              self.world,
              anchor_info,
              cache.cached_matching_archetype_bits,
            )
          }
        _ => ()
      }
      let mut found : @core.Entity? = None
      for archetype_id in matched_archetypes {
        match self.world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              guard !table_row_filter_required ||
                query_filter_matches_entity_table_row(
                  self.world,
                  self.filter,
                  entity,
                ) else {
                continue
              }
              if found is Some(_) {
                return None
              }
              found = Some(entity)
            }
          None => ()
        }
      }
      match found {
        Some(entity) =>
          Some(
            query_fetch_entity_table_row_with_plan(
              self.world,
              entity,
              data_fetch_plan,
            ),
          )
        None => None
      }
    }
  } else {
    let entities = self.matching_entities()
    if entities.length() != 1 {
      return None
    }
    Some(
      query_fetch_entity_table_row_with_plan(
        self.world,
        entities[0],
        data_fetch_plan,
      ),
    )
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::require_single(
  self : Query[D, F],
) -> D raise {
  match self.single() {
    Some(value) => value
    None => raise Skipped("Expected exactly one matching entity")
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter_many(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  {
    query: self,
    data_fetch_plan: D::prepare_fetch_plan(self.world),
    default_filter_component_ids: self.default_filter_component_ids(),
    entities_pre_matched: false,
    archetype_driven: false,
    dense_driven: false,
    table_row_filter_required: false,
    archetypes: [],
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    current_table_id: -1,
    dense_tables: [],
    dense_table_index: 0,
    dense_table_entities: [],
    dense_table_row_count: 0,
    dense_table_row_index: 0,
    sparse_anchor_info: None,
    sparse_anchor_entities: [],
    sparse_anchor_index: 0,
    entities,
    index: 0,
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter_many_unique(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_unsafe(entities)
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter_many_unique_unsafe(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  self.iter_many(entities)
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter_combinations(
  self : Query[D, F],
) -> QueryCombinations[D, F] {
  let entities = self.matching_entities()
  {
    query: self,
    default_filter_component_ids: [],
    entities_pre_matched: true,
    entities,
    left_index: 0,
    right_index: 1,
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::contiguous_iter(
  self : Query[D, F],
) -> QueryContiguousIter[D, F]? {
  guard D::contiguous_compatible() else { return None }
  guard D::iteration_anchor_component() is Some(anchor_component_id) else {
    return None
  }
  guard self.world.local_component_id(anchor_component_id)
    is Some(anchor_local_component_id) else {
    return None
  }
  guard self.world.local_component_storage_type(anchor_local_component_id)
    is Some(anchor_storage_type) else {
    return None
  }
  guard anchor_storage_type == Table else { return None }
  let entities = self.matching_entities()
  Some({
    query: self,
    default_filter_component_ids: [],
    entities_pre_matched: true,
    entities,
    index: 0,
  })
}

///|
pub fn[D, F] Query::par_iter(self : Query[D, F]) -> QueryParallel[D, F] {
  { query: self, batching_strategy: BatchingStrategy::new() }
}

///|
pub fn[D, F] QueryParallel::batching_strategy(
  self : QueryParallel[D, F],
  strategy : BatchingStrategy,
) -> QueryParallel[D, F] {
  { query: self.query, batching_strategy: strategy }
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryParallel::for_each(
  self : QueryParallel[D, F],
  f : (@core.Entity, D) -> Unit,
) -> Unit raise EcsError {
  ignore(self.batching_strategy)
  self.query.view(f)
}

///|
fn[D : QueryData, F : QueryFilter] Query::default_filter_component_ids(
  self : Query[D, F],
) -> Array[Int] {
  let cache = self.ensure_cache()
  ignore(
    cache.refresh_default_filter_component_ids(
      self.world,
      self.filter,
      D::mentions_component,
    ),
  )
  cache.cached_default_filter_component_ids
}

///|
fn[D : QueryData, F : QueryFilter] Query::matching_entities(
  self : Query[D, F],
) -> Array[@core.Entity] {
  let cache = self.ensure_cache()
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  cache.query_matching_entities(
    self.world,
    self.filter,
    data_anchor_component_ids,
    filter_anchor_component_ids,
    D::matches,
    D::mentions_component,
    D::matches_component_set,
    D::requires_entity_check(),
    D::is_dense,
    D::collect_access,
  )
}

///|
fn[D : QueryData, F : QueryFilter] Query::matching_archetypes(
  self : Query[D, F],
) -> Array[Int] {
  let cache = self.ensure_cache()
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  cache.query_matching_archetypes(
    self.world,
    self.filter,
    data_anchor_component_ids,
    filter_anchor_component_ids,
    D::mentions_component,
    D::matches_component_set,
    D::is_dense,
    D::collect_access,
  )
}

///|
fn[D : QueryData, F : QueryFilter] Query::matching_dense_tables(
  self : Query[D, F],
) -> Array[Int] {
  let cache = self.ensure_cache()
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  ignore(
    cache.query_matching_archetypes(
      self.world,
      self.filter,
      data_anchor_component_ids,
      filter_anchor_component_ids,
      D::mentions_component,
      D::matches_component_set,
      D::is_dense,
      D::collect_access,
    ),
  )
  if cache.cached_is_dense {
    cache.cached_matching_tables
  } else {
    []
  }
}

///|
fn[F : QueryFilter] QueryCache::refresh_default_filter_component_ids(
  self : QueryCache,
  world : World,
  filter : F,
  data_mentions_component : (Int) -> Bool,
) -> Bool {
  let world_id = world.world_id()
  let next_default_filter_component_ids = query_default_filter_component_ids_for_query(
    query_default_filters_for_world(world),
    filter,
    data_mentions_component,
  )
  if self.cached_default_filters_world_id != world_id ||
    !query_int_array_equals(
      self.cached_default_filter_component_ids,
      next_default_filter_component_ids,
    ) {
    let next_default_filter_local_component_ids : Array[Int] = []
    for component_id in next_default_filter_component_ids {
      guard world.local_component_id(component_id) is Some(local_component_id) else {
        continue
      }
      next_default_filter_local_component_ids.push(local_component_id)
    }
    self.cached_default_filter_component_ids = next_default_filter_component_ids
    self.cached_default_filter_local_component_ids = next_default_filter_local_component_ids
    self.cached_default_filters_world_id = world_id
    return true
  }
  false
}

///|
fn[F : QueryFilter] QueryCache::dependency_component_ids(
  self : QueryCache,
  world : World,
  filter : F,
  data_mentions_component : (Int) -> Bool,
  data_collect_access : (QueryDataAccess) -> Unit,
  default_filters_stale : Bool,
) -> Array[Int] {
  let world_id = world.world_id()
  let component_registration_generation = world.component_registration_generation()
  if self.cached_dependency_world_id != world_id ||
    self.cached_dependency_component_registration_generation !=
    component_registration_generation ||
    default_filters_stale {
    self.cached_dependency_component_ids = query_dependency_component_ids_from_access(
      world,
      filter,
      self.cached_default_filter_component_ids,
      data_collect_access,
      data_mentions_component,
    )
    self.cached_dependency_world_id = world_id
    self.cached_dependency_component_registration_generation = component_registration_generation
  }
  self.cached_dependency_component_ids
}

///|
fn QueryCache::query_candidate_archetypes(
  self : QueryCache,
  world : World,
  data_anchor_component_ids : Array[Int],
  filter_anchor_component_ids : Array[Int],
) -> Array[Int] {
  let data_anchor_component_id = query_min_anchor_component_id(
    world, data_anchor_component_ids,
  )
  let filter_anchor_component_id = query_min_anchor_component_id(
    world, filter_anchor_component_ids,
  )
  let candidate_anchor_component_id = query_candidate_anchor_component_id(
    world, data_anchor_component_id, filter_anchor_component_id,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  if self.cached_candidate_archetype_generation !=
    candidate_archetype_generation ||
    self.cached_candidate_anchor_component_id != candidate_anchor_component_id ||
    self.cached_anchor_component_id != data_anchor_component_id ||
    self.cached_filter_anchor_component_id != filter_anchor_component_id {
    self.cached_candidate_archetypes = query_candidate_archetypes(
      world, data_anchor_component_id, filter_anchor_component_id,
    )
    self.cached_anchor_component_id = data_anchor_component_id
    self.cached_filter_anchor_component_id = filter_anchor_component_id
    self.cached_candidate_anchor_component_id = candidate_anchor_component_id
    self.cached_candidate_archetype_generation = candidate_archetype_generation
  }
  self.cached_candidate_archetypes
}

///|
fn[F : QueryFilter] QueryCache::query_matching_entities(
  self : QueryCache,
  world : World,
  filter : F,
  data_anchor_component_ids : Array[Int],
  filter_anchor_component_ids : Array[Int],
  data_matches : (World, @core.Entity) -> Bool,
  data_mentions_component : (Int) -> Bool,
  data_matches_component_set : ((Int) -> Bool) -> Bool,
  data_requires_entity_check : Bool,
  data_is_dense : (World) -> Bool,
  data_collect_access : (QueryDataAccess) -> Unit,
) -> Array[@core.Entity] {
  let matched_archetypes = self.query_matching_archetypes(
    world, filter, data_anchor_component_ids, filter_anchor_component_ids, data_mentions_component,
    data_matches_component_set, data_is_dense, data_collect_access,
  )
  let filter_requires_entity_check = query_filter_requires_entity_check(
    filter, world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    filter, world,
  )
  let dependency_component_ids = self.dependency_component_ids(
    world, filter, data_mentions_component, data_collect_access, true,
  )
  let matching_entities_generation = query_dependency_generation(
    world, dependency_component_ids,
  )
  let depends_on_ticks = QueryFilter::depends_on_ticks(filter)
  let tick_marker = if depends_on_ticks { query_tick_marker(world) } else { -1 }
  let entity_cache_reusable = !data_requires_entity_check &&
    self.cached_matching_entities_valid &&
    self.cached_matching_entities_generation == matching_entities_generation &&
    self.cached_matching_generation == matching_entities_generation &&
    self.cached_matching_tick == tick_marker &&
    (!depends_on_ticks || self.cached_matching_entities_tick == tick_marker)
  if entity_cache_reusable {
    return self.cached_matching_entities
  }
  let matched_entities : Array[@core.Entity] = []
  if !data_requires_entity_check &&
    !filter_requires_entity_check &&
    !table_row_filter_required {
    query_collect_archetype_entities(
      world, matched_archetypes, matched_entities,
    )
  } else {
    for archetype_id in matched_archetypes {
      match world.archetype_entities_view(archetype_id) {
        Some(entities) =>
          for entity in entities {
            if (!data_requires_entity_check || data_matches(world, entity)) &&
              (
                !filter_requires_entity_check ||
                QueryFilter::matches(filter, world, entity)
              ) &&
              (
                !table_row_filter_required ||
                query_filter_matches_entity_table_row(world, filter, entity)
              ) {
              matched_entities.push(entity)
            }
          }
        None => ()
      }
    }
  }
  self.cached_matching_entities = matched_entities
  self.cached_matching_entities_valid = true
  self.cached_matching_entities_generation = matching_entities_generation
  self.cached_matching_entities_tick = tick_marker
  self.cached_matching_generation = matching_entities_generation
  self.cached_matching_tick = tick_marker
  self.cached_matching_entities
}

///|
fn[F : QueryFilter] QueryCache::query_matching_archetypes(
  self : QueryCache,
  world : World,
  filter : F,
  data_anchor_component_ids : Array[Int],
  filter_anchor_component_ids : Array[Int],
  data_mentions_component : (Int) -> Bool,
  data_matches_component_set : ((Int) -> Bool) -> Bool,
  data_is_dense : (World) -> Bool,
  data_collect_access : (QueryDataAccess) -> Unit,
) -> Array[Int] {
  let data_anchor_component_id = query_min_anchor_component_id(
    world, data_anchor_component_ids,
  )
  let filter_anchor_component_id = query_min_anchor_component_id(
    world, filter_anchor_component_ids,
  )
  let candidate_anchor_component_id = query_candidate_anchor_component_id(
    world, data_anchor_component_id, filter_anchor_component_id,
  )
  let default_filters_stale = self.refresh_default_filter_component_ids(
    world, filter, data_mentions_component,
  )
  let matching_metadata_changed = self.cached_matching_anchor_component_id !=
    data_anchor_component_id ||
    self.cached_matching_filter_anchor_component_id !=
    filter_anchor_component_id ||
    self.cached_matching_candidate_anchor_component_id !=
    candidate_anchor_component_id ||
    default_filters_stale
  let previous_candidate_archetypes = self.cached_candidate_archetypes
  let candidate_archetypes = self.query_candidate_archetypes(
    world, data_anchor_component_ids, filter_anchor_component_ids,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  let matched_archetypes_added : Array[Int] = []
  let mut matched_archetypes_reset = false
  if matching_metadata_changed {
    let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
    let (matched_archetypes, matched_archetype_bits) = query_collect_matching_archetypes(
      world, candidate_archetypes, filter, default_filter_local_component_ids, data_matches_component_set,
    )
    self.cached_matching_archetypes = matched_archetypes
    self.cached_matching_archetype_bits = matched_archetype_bits
    self.cached_matching_archetype_generation = candidate_archetype_generation
    self.cached_matching_entities_valid = false
    self.cached_matching_tables_valid = false
    matched_archetypes_reset = true
  } else if self.cached_matching_archetype_generation !=
    candidate_archetype_generation {
    let added_candidate_archetypes : Array[Int] = []
    let candidate_removed = query_archetype_delta(
      previous_candidate_archetypes, candidate_archetypes, added_candidate_archetypes,
    )
    if candidate_removed {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      let (matched_archetypes, matched_archetype_bits) = query_collect_matching_archetypes(
        world, candidate_archetypes, filter, default_filter_local_component_ids,
        data_matches_component_set,
      )
      self.cached_matching_archetypes = matched_archetypes
      self.cached_matching_archetype_bits = matched_archetype_bits
      self.cached_matching_entities_valid = false
      self.cached_matching_tables_valid = false
      matched_archetypes_reset = true
    } else {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      for archetype_id in added_candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world, archetype_id, filter, default_filter_local_component_ids, data_matches_component_set,
          ) &&
          !self.cached_matching_archetype_bits.contains(archetype_id) {
          self.cached_matching_archetype_bits.insert(archetype_id)
          self.cached_matching_archetypes.push(archetype_id)
          matched_archetypes_added.push(archetype_id)
        }
      }
      if matched_archetypes_added.length() > 0 {
        self.cached_matching_entities_valid = false
      }
    }
    self.cached_matching_archetype_generation = candidate_archetype_generation
  }
  self.cached_matching_anchor_component_id = data_anchor_component_id
  self.cached_matching_filter_anchor_component_id = filter_anchor_component_id
  self.cached_matching_candidate_anchor_component_id = candidate_anchor_component_id
  let is_dense = query_is_dense_mode(
    world,
    filter,
    self.cached_default_filter_component_ids,
    data_is_dense,
    data_collect_access,
  )
  let was_dense = self.cached_is_dense
  self.cached_is_dense = is_dense
  if is_dense {
    if !self.cached_matching_tables_valid ||
      matched_archetypes_reset ||
      !was_dense {
      let (matching_tables, matching_table_bits) = query_matching_table_cache(
        world,
        self.cached_matching_archetypes,
      )
      self.cached_matching_tables = matching_tables
      self.cached_matching_table_bits = matching_table_bits
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    } else if matched_archetypes_added.length() > 0 {
      for archetype_id in matched_archetypes_added {
        query_matching_table_cache_add_archetype(
          world,
          archetype_id,
          self.cached_matching_tables,
          self.cached_matching_table_bits,
        )
      }
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    } else {
      self.cached_matching_tables_generation = candidate_archetype_generation
    }
  } else {
    self.cached_matching_tables = []
    self.cached_matching_table_bits = @utils.IntBitSet::new()
    self.cached_matching_tables_generation = candidate_archetype_generation
    self.cached_matching_tables_valid = true
  }
  self.cached_matching_archetypes
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::default_filter_component_ids(
  self : QueryState[D, F],
  world : World,
) -> Array[Int] {
  ignore(self.refresh_default_filter_component_ids(world))
  self.cached_default_filter_component_ids
}

///|
fn query_int_array_equals(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|

///|
fn[F : QueryFilter] query_collect_matching_archetypes(
  world : World,
  candidate_archetypes : Array[Int],
  filter : F,
  default_filter_local_component_ids : Array[Int],
  data_matches_component_set : ((Int) -> Bool) -> Bool,
) -> (Array[Int], @utils.IntBitSet) {
  let matched_archetypes : Array[Int] = []
  let matched_archetype_bits = @utils.IntBitSet::new()
  for archetype_id in candidate_archetypes {
    if query_archetype_matches_with_default_filter_component_ids(
        world, archetype_id, filter, default_filter_local_component_ids, data_matches_component_set,
      ) &&
      !matched_archetype_bits.contains(archetype_id) {
      matched_archetype_bits.insert(archetype_id)
      matched_archetypes.push(archetype_id)
    }
  }
  (matched_archetypes, matched_archetype_bits)
}

///|
fn query_archetype_delta(
  previous : Array[Int],
  current : Array[Int],
  added : Array[Int],
) -> Bool {
  let mut previous_index = 0
  let mut current_index = 0
  let mut removed = false
  while previous_index < previous.length() && current_index < current.length() {
    let previous_id = previous[previous_index]
    let current_id = current[current_index]
    if previous_id == current_id {
      previous_index = previous_index + 1
      current_index = current_index + 1
    } else if previous_id < current_id {
      removed = true
      previous_index = previous_index + 1
    } else {
      added.push(current_id)
      current_index = current_index + 1
    }
  }
  if previous_index < previous.length() {
    removed = true
  }
  while current_index < current.length() {
    added.push(current[current_index])
    current_index = current_index + 1
  }
  removed
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::refresh_default_filter_component_ids(
  self : QueryState[D, F],
  world : World,
) -> Bool {
  let world_id = world.world_id()
  let next_default_filter_component_ids = query_default_filter_component_ids_for_query(
    query_default_filters_for_world(world),
    self.filter,
    D::mentions_component,
  )
  if self.cached_default_filters_world_id != world_id ||
    !query_int_array_equals(
      self.cached_default_filter_component_ids,
      next_default_filter_component_ids,
    ) {
    let next_default_filter_local_component_ids : Array[Int] = []
    for component_id in next_default_filter_component_ids {
      guard world.local_component_id(component_id) is Some(local_component_id) else {
        continue
      }
      next_default_filter_local_component_ids.push(local_component_id)
    }
    self.cached_default_filter_component_ids = next_default_filter_component_ids
    self.cached_default_filter_local_component_ids = next_default_filter_local_component_ids
    self.cached_default_filters_world_id = world_id
    return true
  }
  false
}

///|
fn query_push_unique_component_id(
  component_ids : Array[Int],
  component_id : Int,
) -> Unit {
  if !component_ids.contains(component_id) {
    component_ids.push(component_id)
  }
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::dependency_component_ids(
  self : QueryState[D, F],
  world : World,
  default_filters_stale : Bool,
) -> Array[Int] {
  let world_id = world.world_id()
  let component_registration_generation = world.component_registration_generation()
  if self.cached_dependency_world_id != world_id ||
    self.cached_dependency_component_registration_generation !=
    component_registration_generation ||
    default_filters_stale {
    self.cached_dependency_component_ids = query_dependency_component_ids_from_access(
      world,
      self.filter,
      self.cached_default_filter_component_ids,
      D::collect_access,
      D::mentions_component,
    )
    self.cached_dependency_world_id = world_id
    self.cached_dependency_component_registration_generation = component_registration_generation
  }
  self.cached_dependency_component_ids
}

///|
fn query_dependency_generation(
  world : World,
  component_ids : Array[Int],
) -> Int {
  if component_ids.length() == 0 {
    return world.entity_lifecycle_generation()
  }
  let mut generation = world.entity_lifecycle_generation() * 1_000_003 +
    component_ids.length()
  for component_id in component_ids {
    let component_generation = world.component_membership_generation_for_definition(
      component_id,
    )
    generation = generation * 1_000_003 +
      component_id * 97 +
      component_generation
  }
  generation
}

///|
fn query_tick_marker(world : World) -> Int {
  let ticks = world.get_tick_context().ticks()
  (ticks.last_run * 1_000_003 + ticks.this_run).to_int()
}

///|
fn[F : QueryFilter] query_filter_requires_entity_check(
  filter : F,
  world : World,
) -> Bool {
  QueryFilter::requires_entity_check_for_world(filter, world)
}

///|
fn[F : QueryFilter] query_filter_requires_table_row_check(
  filter : F,
  world : World,
) -> Bool {
  QueryFilter::depends_on_ticks(filter) &&
  !query_filter_requires_entity_check(filter, world)
}

///|
fn[F : QueryFilter] query_filter_matches_entity_table_row(
  world : World,
  filter : F,
  entity : @core.Entity,
) -> Bool {
  match world.entity_table_location(entity) {
    Some((table_id, row_index)) =>
      QueryFilter::matches_table_row(filter, world, entity, table_id, row_index)
    None => QueryFilter::matches(filter, world, entity)
  }
}

///|
fn[F : QueryFilter] query_filter_matches_table_row_if_needed(
  world : World,
  filter : F,
  table_row_filter_required : Bool,
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> Bool {
  !table_row_filter_required ||
  QueryFilter::matches_table_row(filter, world, entity, table_id, row_index)
}

///|
fn query_component_is_dense(world : World, component_id : Int) -> Bool {
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
fn[F : QueryFilter] query_data_filter_access(
  filter : F,
  collect_data_access : (QueryDataAccess) -> Unit,
) -> (QueryDataAccess, QueryFilterAccess) {
  let data_access = QueryDataAccess::new()
  let filter_access = QueryFilterAccess::new()
  collect_data_access(data_access)
  QueryFilter::collect_access(filter, filter_access)
  (data_access, filter_access)
}

///|
pub fn[F : QueryFilter] query_access_descriptor(
  filter : F,
  collect_data_access : (QueryDataAccess) -> Unit,
) -> (QueryDataAccess, QueryFilterAccess) {
  query_data_filter_access(filter, collect_data_access)
}

///|
fn[F : QueryFilter] query_access_validation(
  filter : F,
  collect_data_access : (QueryDataAccess) -> Unit,
) -> SystemParamValidationError? {
  let (data_access, filter_access) = query_data_filter_access(
    filter, collect_data_access,
  )
  query_validate_data_filter_access(data_access, filter_access)
}

///|
fn[F : QueryFilter] query_access_valid(
  filter : F,
  collect_data_access : (QueryDataAccess) -> Unit,
) -> Bool {
  query_access_validation(filter, collect_data_access) is None
}

///|
fn[F : QueryFilter] query_is_dense_mode(
  world : World,
  filter : F,
  default_filter_component_ids : Array[Int],
  data_is_dense : (World) -> Bool,
  collect_data_access : (QueryDataAccess) -> Unit,
) -> Bool {
  guard query_access_valid(filter, collect_data_access) else { return false }
  guard data_is_dense(world) else { return false }
  guard QueryFilter::is_dense(filter, world) else { return false }
  for component_id in default_filter_component_ids {
    if !query_component_is_dense(world, component_id) {
      return false
    }
  }
  true
}

///|
fn[F : QueryFilter] query_dependency_component_ids_from_access(
  world : World,
  filter : F,
  default_filter_component_ids : Array[Int],
  collect_data_access : (QueryDataAccess) -> Unit,
  data_mentions_component : (Int) -> Bool,
) -> Array[Int] {
  let component_ids : Array[Int] = []
  let (data_access, filter_access) = query_data_filter_access(
    filter, collect_data_access,
  )
  for component_id in data_access.read_components() {
    query_push_unique_component_id(component_ids, component_id)
  }
  for component_id in data_access.write_components() {
    query_push_unique_component_id(component_ids, component_id)
  }
  for component_id in filter_access.read_components() {
    query_push_unique_component_id(component_ids, component_id)
  }
  for component_id in filter_access.with_components() {
    query_push_unique_component_id(component_ids, component_id)
  }
  for component_id in filter_access.without_components() {
    query_push_unique_component_id(component_ids, component_id)
  }
  for component_id in world.registered_definition_component_ids() {
    if data_mentions_component(component_id) ||
      QueryFilter::mentions_component(filter, component_id) {
      query_push_unique_component_id(component_ids, component_id)
    }
  }
  for component_id in default_filter_component_ids {
    query_push_unique_component_id(component_ids, component_id)
  }
  component_ids
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::get(
  self : QueryState[D, F],
  world : World,
  entity : @core.Entity,
) -> D? raise EcsError {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query_get_with_default_filter_component_ids(
    query,
    entity,
    self.default_filter_component_ids(world),
  )
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::iter(
  self : QueryState[D, F],
  world : World,
) -> QueryMany[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  let default_filter_component_ids = self.default_filter_component_ids(world)
  query_many_from_plan(
    query,
    self.iteration_plan(world, default_filter_component_ids),
  )
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::iter_many(
  self : QueryState[D, F],
  world : World,
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  {
    query,
    data_fetch_plan: self.data_fetch_plan(world),
    default_filter_component_ids: self.default_filter_component_ids(world),
    entities_pre_matched: false,
    archetype_driven: false,
    dense_driven: false,
    table_row_filter_required: false,
    archetypes: [],
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    current_table_id: -1,
    dense_tables: [],
    dense_table_index: 0,
    dense_table_entities: [],
    dense_table_row_count: 0,
    dense_table_row_index: 0,
    sparse_anchor_info: None,
    sparse_anchor_entities: [],
    sparse_anchor_index: 0,
    entities,
    index: 0,
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::iter_combinations(
  self : QueryState[D, F],
  world : World,
) -> QueryCombinations[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  let entities = self.query_matching_entities(world)
  {
    query,
    default_filter_component_ids: self.default_filter_component_ids(world),
    entities_pre_matched: true,
    entities,
    left_index: 0,
    right_index: 1,
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::single(
  self : QueryState[D, F],
  world : World,
) -> D? raise EcsError {
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    world,
  )
  let data_fetch_plan = self.data_fetch_plan(world)
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_tables = self.query_matching_tables(world)
    if dense_tables.length() > 0 {
      query_dense_tables_single(
        world,
        dense_tables,
        self.filter,
        table_row_filter_required,
        data_fetch_plan,
      )
    } else {
      let matched_archetypes = self.query_matching_archetypes(world)
      match
        query_sparse_anchor_info(
          world, data_anchor_component_ids, filter_anchor_component_ids,
        ) {
        Some(anchor_info) if !self.cached_is_dense =>
          if !table_row_filter_required {
            return query_sparse_anchor_single_matching(
              world,
              anchor_info,
              self.cached_matching_archetype_bits,
            )
          }
        _ => ()
      }
      let mut found : @core.Entity? = None
      for archetype_id in matched_archetypes {
        match world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              guard !table_row_filter_required ||
                query_filter_matches_entity_table_row(
                  world,
                  self.filter,
                  entity,
                ) else {
                continue
              }
              if found is Some(_) {
                return None
              }
              found = Some(entity)
            }
          None => ()
        }
      }
      match found {
        Some(entity) =>
          Some(
            query_fetch_entity_table_row_with_plan(
              world, entity, data_fetch_plan,
            ),
          )
        None => None
      }
    }
  } else {
    let entities = self.query_matching_entities(world)
    if entities.length() != 1 {
      return None
    }
    Some(
      query_fetch_entity_table_row_with_plan(
        world,
        entities[0],
        data_fetch_plan,
      ),
    )
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::require_single(
  self : QueryState[D, F],
  world : World,
) -> D raise {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.require_single()
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::count(
  self : QueryState[D, F],
  world : World,
) -> Int {
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    world,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_tables = self.query_matching_tables(world)
    if dense_tables.length() > 0 {
      return query_dense_tables_count(
        world,
        dense_tables,
        self.filter,
        table_row_filter_required,
      )
    }
    let matched_archetypes = self.query_matching_archetypes(world)
    match
      query_sparse_anchor_info(
        world, data_anchor_component_ids, filter_anchor_component_ids,
      ) {
      Some(anchor_info) if !self.cached_is_dense =>
        if !table_row_filter_required {
          return query_sparse_anchor_count_matching(
            world,
            anchor_info,
            self.cached_matching_archetype_bits,
          )
        }
      _ => ()
    }
    let mut count = 0
    for archetype_id in matched_archetypes {
      if table_row_filter_required {
        match world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              if query_filter_matches_entity_table_row(
                  world,
                  self.filter,
                  entity,
                ) {
                count = count + 1
              }
            }
          None => ()
        }
      } else {
        count = count + world.archetype_entity_count(archetype_id)
      }
    }
    return count
  }
  self.query_matching_entities(world).length()
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::contiguous_iter(
  self : QueryState[D, F],
  world : World,
) -> QueryContiguousIter[D, F]? {
  let query : Query[D, F] = query_filtered(world, self.filter)
  guard D::contiguous_compatible() else { return None }
  guard D::iteration_anchor_component() is Some(anchor_component_id) else {
    return None
  }
  guard world.local_component_id(anchor_component_id)
    is Some(anchor_local_component_id) else {
    return None
  }
  guard world.local_component_storage_type(anchor_local_component_id)
    is Some(anchor_storage_type) else {
    return None
  }
  guard anchor_storage_type == Table else { return None }
  Some({
    query,
    default_filter_component_ids: self.default_filter_component_ids(world),
    entities_pre_matched: true,
    entities: self.query_matching_entities(world),
    index: 0,
  })
}

///|
fn[D, F] QueryState::query_candidate_archetypes(
  self : QueryState[D, F],
  world : World,
  data_anchor_component_ids : Array[Int],
  filter_anchor_component_ids : Array[Int],
) -> Array[Int] {
  let data_anchor_component_id = query_min_anchor_component_id(
    world, data_anchor_component_ids,
  )
  let filter_anchor_component_id = query_min_anchor_component_id(
    world, filter_anchor_component_ids,
  )
  let candidate_anchor_component_id = query_candidate_anchor_component_id(
    world, data_anchor_component_id, filter_anchor_component_id,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  if self.cached_candidate_archetype_generation !=
    candidate_archetype_generation ||
    self.cached_candidate_anchor_component_id != candidate_anchor_component_id ||
    self.cached_anchor_component_id != data_anchor_component_id ||
    self.cached_filter_anchor_component_id != filter_anchor_component_id {
    self.cached_candidate_archetypes = query_candidate_archetypes(
      world, data_anchor_component_id, filter_anchor_component_id,
    )
    self.cached_anchor_component_id = data_anchor_component_id
    self.cached_filter_anchor_component_id = filter_anchor_component_id
    self.cached_candidate_anchor_component_id = candidate_anchor_component_id
    self.cached_candidate_archetype_generation = candidate_archetype_generation
  }
  self.cached_candidate_archetypes
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::query_matching_entities(
  self : QueryState[D, F],
  world : World,
) -> Array[@core.Entity] {
  let matched_archetypes = self.query_matching_archetypes(world)
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = query_filter_requires_entity_check(
    self.filter,
    world,
  )
  let table_row_filter_required = query_filter_requires_table_row_check(
    self.filter,
    world,
  )
  let dependency_component_ids = self.dependency_component_ids(world, true)
  let matching_entities_generation = query_dependency_generation(
    world, dependency_component_ids,
  )
  let depends_on_ticks = QueryFilter::depends_on_ticks(self.filter)
  let tick_marker = if depends_on_ticks { query_tick_marker(world) } else { -1 }
  let entity_cache_reusable = !data_requires_entity_check &&
    self.cached_matching_entities_valid &&
    self.cached_matching_entities_generation == matching_entities_generation &&
    self.cached_matching_generation == matching_entities_generation &&
    self.cached_matching_tick == tick_marker &&
    (!depends_on_ticks || self.cached_matching_entities_tick == tick_marker)
  if entity_cache_reusable {
    return self.cached_matching_entities
  }
  let matched_entities : Array[@core.Entity] = []
  if !data_requires_entity_check &&
    !filter_requires_entity_check &&
    !table_row_filter_required {
    query_collect_archetype_entities(
      world, matched_archetypes, matched_entities,
    )
  } else {
    for archetype_id in matched_archetypes {
      match world.archetype_entities_view(archetype_id) {
        Some(entities) =>
          for entity in entities {
            if (!data_requires_entity_check || D::matches(world, entity)) &&
              (
                !filter_requires_entity_check ||
                QueryFilter::matches(self.filter, world, entity)
              ) &&
              (
                !table_row_filter_required ||
                query_filter_matches_entity_table_row(
                  world,
                  self.filter,
                  entity,
                )
              ) {
              matched_entities.push(entity)
            }
          }
        None => ()
      }
    }
  }
  self.cached_matching_entities = matched_entities
  self.cached_matching_entities_valid = true
  self.cached_matching_entities_generation = matching_entities_generation
  self.cached_matching_entities_tick = tick_marker
  self.cached_matching_generation = matching_entities_generation
  self.cached_matching_tick = tick_marker
  self.cached_matching_entities
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::query_matching_archetypes(
  self : QueryState[D, F],
  world : World,
) -> Array[Int] {
  let data_anchor_component_ids = D::iteration_anchor_components()
  let filter_anchor_component_ids = QueryFilter::iteration_anchor_components(
    self.filter,
  )
  let data_anchor_component_id = query_min_anchor_component_id(
    world, data_anchor_component_ids,
  )
  let filter_anchor_component_id = query_min_anchor_component_id(
    world, filter_anchor_component_ids,
  )
  let candidate_anchor_component_id = query_candidate_anchor_component_id(
    world, data_anchor_component_id, filter_anchor_component_id,
  )
  let default_filters_stale = self.refresh_default_filter_component_ids(world)
  let matching_metadata_changed = self.cached_matching_anchor_component_id !=
    data_anchor_component_id ||
    self.cached_matching_filter_anchor_component_id !=
    filter_anchor_component_id ||
    self.cached_matching_candidate_anchor_component_id !=
    candidate_anchor_component_id ||
    default_filters_stale
  let previous_candidate_archetypes = self.cached_candidate_archetypes
  let candidate_archetypes = self.query_candidate_archetypes(
    world, data_anchor_component_ids, filter_anchor_component_ids,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  let matched_archetypes_added : Array[Int] = []
  let mut matched_archetypes_reset = false
  if matching_metadata_changed {
    let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
    let (matched_archetypes, matched_archetype_bits) = query_collect_matching_archetypes(
      world,
      candidate_archetypes,
      self.filter,
      default_filter_local_component_ids,
      D::matches_component_set,
    )
    self.cached_matching_archetypes = matched_archetypes
    self.cached_matching_archetype_bits = matched_archetype_bits
    self.cached_matching_archetype_generation = candidate_archetype_generation
    self.cached_matching_entities_valid = false
    self.cached_matching_tables_valid = false
    matched_archetypes_reset = true
  } else if self.cached_matching_archetype_generation !=
    candidate_archetype_generation {
    let added_candidate_archetypes : Array[Int] = []
    let candidate_removed = query_archetype_delta(
      previous_candidate_archetypes, candidate_archetypes, added_candidate_archetypes,
    )
    if candidate_removed {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      let (matched_archetypes, matched_archetype_bits) = query_collect_matching_archetypes(
        world,
        candidate_archetypes,
        self.filter,
        default_filter_local_component_ids,
        D::matches_component_set,
      )
      self.cached_matching_archetypes = matched_archetypes
      self.cached_matching_archetype_bits = matched_archetype_bits
      self.cached_matching_entities_valid = false
      self.cached_matching_tables_valid = false
      matched_archetypes_reset = true
    } else {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      for archetype_id in added_candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world,
            archetype_id,
            self.filter,
            default_filter_local_component_ids,
            D::matches_component_set,
          ) &&
          !self.cached_matching_archetype_bits.contains(archetype_id) {
          self.cached_matching_archetype_bits.insert(archetype_id)
          self.cached_matching_archetypes.push(archetype_id)
          matched_archetypes_added.push(archetype_id)
        }
      }
      if matched_archetypes_added.length() > 0 {
        self.cached_matching_entities_valid = false
      }
    }
    self.cached_matching_archetype_generation = candidate_archetype_generation
  }
  self.cached_matching_anchor_component_id = data_anchor_component_id
  self.cached_matching_filter_anchor_component_id = filter_anchor_component_id
  self.cached_matching_candidate_anchor_component_id = candidate_anchor_component_id
  let is_dense = query_is_dense_mode(
    world,
    self.filter,
    self.cached_default_filter_component_ids,
    D::is_dense,
    D::collect_access,
  )
  let was_dense = self.cached_is_dense
  self.cached_is_dense = is_dense
  if is_dense {
    if !self.cached_matching_tables_valid ||
      matched_archetypes_reset ||
      !was_dense {
      let (matching_tables, matching_table_bits) = query_matching_table_cache(
        world,
        self.cached_matching_archetypes,
      )
      self.cached_matching_tables = matching_tables
      self.cached_matching_table_bits = matching_table_bits
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    } else if matched_archetypes_added.length() > 0 {
      for archetype_id in matched_archetypes_added {
        query_matching_table_cache_add_archetype(
          world,
          archetype_id,
          self.cached_matching_tables,
          self.cached_matching_table_bits,
        )
      }
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    } else {
      self.cached_matching_tables_generation = candidate_archetype_generation
    }
  } else {
    self.cached_matching_tables = []
    self.cached_matching_table_bits = @utils.IntBitSet::new()
    self.cached_matching_tables_generation = candidate_archetype_generation
    self.cached_matching_tables_valid = true
  }
  self.cached_matching_archetypes
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::query_matching_tables(
  self : QueryState[D, F],
  world : World,
) -> Array[Int] {
  ignore(self.query_matching_archetypes(world))
  if self.cached_is_dense {
    self.cached_matching_tables
  } else {
    []
  }
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryMany::fetch_next(
  self : QueryMany[D, F],
) -> (@core.Entity, D)? raise EcsError {
  if self.dense_driven {
    while true {
      if self.current_table_id >= 0 {
        while self.dense_table_row_index < self.dense_table_row_count {
          let row_index = self.dense_table_row_index
          self.dense_table_row_index = self.dense_table_row_index + 1
          let entity = self.dense_table_entities[row_index]
          if query_filter_matches_table_row_if_needed(
              self.query.world,
              self.query.filter,
              self.table_row_filter_required,
              entity,
              self.current_table_id,
              row_index,
            ) {
            return Some(
              (
                entity,
                D::fetch_table_row_with_plan_offset(
                  query_data_table_row_fetch(
                    self.query.world,
                    entity,
                    self.current_table_id,
                    row_index,
                  ).planned(self.data_fetch_plan, 0),
                ),
              ),
            )
          }
        }
      }
      if self.dense_table_index >= self.dense_tables.length() {
        return None
      }
      self.current_table_id = self.dense_tables[self.dense_table_index]
      self.dense_table_index = self.dense_table_index + 1
      self.dense_table_entities = match
        self.query.world.table_entities_view(self.current_table_id) {
        Some(entities) => entities
        None => []
      }
      self.dense_table_row_count = self.dense_table_entities.length()
      self.dense_table_row_index = 0
    }
  }
  match self.sparse_anchor_info {
    Some(anchor_info) => {
      while self.sparse_anchor_index < self.sparse_anchor_entities.length() {
        let index = self.sparse_anchor_index
        self.sparse_anchor_index = self.sparse_anchor_index + 1
        let entity = self.sparse_anchor_entities[index]
        guard self.query.world.component_present_by_local_id(
          entity,
          anchor_info.local_component_id,
        ) else {
          continue
        }
        return Some(
          (
            entity,
            query_fetch_with_sparse_anchor(
              self.query.world,
              entity,
              anchor_info,
              self.data_fetch_plan,
            ),
          ),
        )
      }
      return None
    }
    None => ()
  }
  if self.archetype_driven {
    while true {
      if self.archetype_entity_index < self.archetype_entities.length() {
        let entity = self.archetype_entities[self.archetype_entity_index]
        self.archetype_entity_index = self.archetype_entity_index + 1
        guard !self.table_row_filter_required ||
          query_filter_matches_entity_table_row(
            self.query.world,
            self.query.filter,
            entity,
          ) else {
          continue
        }
        return Some(
          (
            entity,
            query_fetch_known_table_row_with_plan(
              self.query.world,
              entity,
              self.current_table_id,
              self.data_fetch_plan,
            ),
          ),
        )
      }
      if self.archetype_index >= self.archetypes.length() {
        return None
      }
      let archetype_id = self.archetypes[self.archetype_index]
      self.archetype_index = self.archetype_index + 1
      self.current_table_id = match
        self.query.world.archetype_table_id(archetype_id) {
        Some(table_id) => table_id
        None => -1
      }
      self.archetype_entities = match
        self.query.world.archetype_entities_view(archetype_id) {
        Some(entities) => entities
        None => []
      }
      self.archetype_entity_index = 0
    }
  }
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.entities_pre_matched {
      return Some(
        (
          entity,
          query_fetch_entity_table_row_with_plan(
            self.query.world,
            entity,
            self.data_fetch_plan,
          ),
        ),
      )
    }
    if query_get_with_default_filter_component_ids(
        self.query,
        entity,
        self.default_filter_component_ids,
      )
      is Some(value) {
      return Some((entity, value))
    }
  }
  None
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryCombinations::fetch_next(
  self : QueryCombinations[D, F],
) -> (D, D)? raise EcsError {
  while self.left_index < self.entities.length() {
    if self.right_index >= self.entities.length() {
      self.left_index = self.left_index + 1
      self.right_index = self.left_index + 1
      continue
    }
    let left_entity = self.entities[self.left_index]
    let right_entity = self.entities[self.right_index]
    self.right_index = self.right_index + 1
    if self.entities_pre_matched {
      return Some(
        (
          query_fetch_entity_table_row(self.query.world, left_entity),
          query_fetch_entity_table_row(self.query.world, right_entity),
        ),
      )
    }
    guard query_get_with_default_filter_component_ids(
        self.query,
        left_entity,
        self.default_filter_component_ids,
      )
      is Some(left_value) else {
      continue
    }
    guard query_get_with_default_filter_component_ids(
        self.query,
        right_entity,
        self.default_filter_component_ids,
      )
      is Some(right_value) else {
      continue
    }
    return Some((left_value, right_value))
  }
  None
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryContiguousIter::fetch_next(
  self : QueryContiguousIter[D, F],
) -> D? raise EcsError {
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.entities_pre_matched {
      return Some(query_fetch_entity_table_row(self.query.world, entity))
    }
    if query_get_with_default_filter_component_ids(
        self.query,
        entity,
        self.default_filter_component_ids,
      )
      is Some(value) {
      return Some(value)
    }
  }
  None
}

///|
fn query_all_archetype_ids(world : World) -> Array[Int] {
  let archetype_ids : Array[Int] = []
  for archetype_id in 0..<world.archetype_generation() {
    archetype_ids.push(archetype_id)
  }
  archetype_ids
}

///|
fn query_min_anchor_component_id(
  world : World,
  anchor_component_ids : Array[Int],
) -> Int? {
  if anchor_component_ids.length() == 0 {
    return None
  }
  let mut best_component_id : Int? = None
  let mut best_count = 0
  for component_id in anchor_component_ids {
    let count = world.component_membership_count_for_definition(component_id)
    match best_component_id {
      Some(_) =>
        if count < best_count {
          best_component_id = Some(component_id)
          best_count = count
        }
      None => {
        best_component_id = Some(component_id)
        best_count = count
      }
    }
  }
  best_component_id
}

///|
fn query_candidate_archetypes(
  world : World,
  anchor_component_id : Int?,
  filter_anchor_component_id : Int?,
) -> Array[Int] {
  match
    query_candidate_anchor_component_id(
      world, anchor_component_id, filter_anchor_component_id,
    ) {
    Some(component_id) => query_archetypes_for_component_id(world, component_id)
    None => query_all_archetype_ids(world)
  }
}

///|
fn query_candidate_anchor_component_id(
  world : World,
  anchor_component_id : Int?,
  filter_anchor_component_id : Int?,
) -> Int? {
  match (anchor_component_id, filter_anchor_component_id) {
    (Some(data_anchor_component_id), Some(filter_anchor_component_id)) => {
      let data_anchor_count = world.component_membership_count_for_definition(
        data_anchor_component_id,
      )
      let filter_anchor_count = world.component_membership_count_for_definition(
        filter_anchor_component_id,
      )
      if data_anchor_count <= filter_anchor_count {
        Some(data_anchor_component_id)
      } else {
        Some(filter_anchor_component_id)
      }
    }
    (Some(component_id), None) => Some(component_id)
    (None, Some(component_id)) => Some(component_id)
    (None, None) => None
  }
}

///|
fn query_candidate_archetype_generation(world : World) -> Int {
  world.archetype_generation()
}

///|
fn query_archetypes_for_component_id(
  world : World,
  component_id : Int,
) -> Array[Int] {
  guard world.local_component_id(component_id) is Some(component_local_id) else {
    return []
  }
  world.archetype_ids_for_component_local_id(component_local_id)
}

///|
fn[F : QueryFilter] query_archetype_matches_with_default_filter_component_ids(
  world : World,
  archetype_id : Int,
  filter : F,
  default_filter_local_component_ids : Array[Int],
  data_matches_component_set : ((Int) -> Bool) -> Bool,
) -> Bool {
  guard world.archetype_definition_component_presence_view(archetype_id)
    is Some(definition_presence) else {
    return false
  }
  guard world.archetype_local_component_presence_view(archetype_id)
    is Some(local_presence) else {
    return false
  }
  let set_contains_id = fn(component_id : Int) {
    definition_presence.contains(component_id)
  }
  guard data_matches_component_set(set_contains_id) else { return false }
  guard QueryFilter::matches_component_set(filter, set_contains_id) else {
    return false
  }
  for local_component_id in default_filter_local_component_ids {
    if local_presence.contains(local_component_id) {
      return false
    }
  }
  true
}

///|
fn query_default_filters_for_world(world : World) -> DefaultQueryFilters? {
  world.get_resource(ecs_key_default_query_filters)
}

///|
fn[F : QueryFilter] query_matches_with_default_filter_component_ids(
  world : World,
  entity : @core.Entity,
  filter : F,
  default_filter_component_ids : Array[Int],
) -> Bool {
  guard QueryFilter::matches(filter, world, entity) else { return false }
  for component_id in default_filter_component_ids {
    if entity_has_component_id(world, component_id, entity) {
      return false
    }
  }
  true
}

///|
fn[F : QueryFilter] query_default_filter_component_ids_for_query(
  default_query_filters : DefaultQueryFilters?,
  filter : F,
  data_mentions_component : (Int) -> Bool,
) -> Array[Int] {
  let component_ids : Array[Int] = []
  match default_query_filters {
    Some(default_query_filters) =>
      for component_id in default_query_filters.disabling_component_ids() {
        if !data_mentions_component(component_id) &&
          !QueryFilter::mentions_component(filter, component_id) {
          component_ids.push(component_id)
        }
      }
    None => ()
  }
  component_ids
}

///|
fn query_require_unique_entities(
  entities : Array[@core.Entity],
) -> Unit raise EcsError {
  let seen : @hashset.HashSet[UInt64] = @hashset.HashSet([])
  for entity in entities {
    let key_hi = entity.id.reinterpret_as_uint().to_uint64()
    let key_lo = entity.generation.reinterpret_as_uint().to_uint64() &
      0xFFFF_FFFFUL
    let key = (key_hi << 32) | key_lo
    if !seen.add_and_check(key) {
      raise NonUniqueEntityList(entity)
    }
  }
}

///|
fn query_collect_archetype_entities(
  world : World,
  archetype_ids : Array[Int],
  out : Array[@core.Entity],
) -> Unit {
  for archetype_id in archetype_ids {
    match world.archetype_entities_view(archetype_id) {
      Some(entities) =>
        for entity in entities {
          out.push(entity)
        }
      None => ()
    }
  }
}

///|
fn query_matching_table_cache(
  world : World,
  matched_archetypes : Array[Int],
) -> (Array[Int], @utils.IntBitSet) {
  let matching_tables : Array[Int] = []
  let table_bits = @utils.IntBitSet::new()
  for archetype_id in matched_archetypes {
    query_matching_table_cache_add_archetype(
      world, archetype_id, matching_tables, table_bits,
    )
  }
  (matching_tables, table_bits)
}

///|
fn query_matching_table_cache_add_archetype(
  world : World,
  archetype_id : Int,
  matching_tables : Array[Int],
  table_bits : @utils.IntBitSet,
) -> Unit {
  guard world.archetype_table_id(archetype_id) is Some(table_id) else { return }
  if !table_bits.contains(table_id) {
    table_bits.insert(table_id)
    matching_tables.push(table_id)
  }
}
