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
  filter : F
  mut cached_candidate_archetypes : Array[Int]
  mut cached_anchor_component_id : Int?
  mut cached_filter_anchor_component_id : Int?
  mut cached_candidate_anchor_component_id : Int?
  mut cached_candidate_archetype_generation : Int
  mut cached_candidate_generation : Int
  mut cached_matching_entities : Array[@core.Entity]
  mut cached_matching_archetypes : Array[Int]
  mut cached_matching_archetype_generation : Int
  mut cached_matching_entities_generation : Int
  mut cached_matching_entities_sequence : Int
  mut cached_matching_anchor_component_id : Int?
  mut cached_matching_filter_anchor_component_id : Int?
  mut cached_matching_candidate_anchor_component_id : Int?
  mut cached_matching_candidate_generation : Int
  mut cached_matching_generation : Int
  mut cached_matching_sequence : Int
  mut cached_matching_entities_valid : Bool
  mut cached_matching_tables : Array[Int]
  mut cached_matching_table_archetype_groups : Array[Array[Int]]
  mut cached_matching_tables_generation : Int
  mut cached_matching_tables_valid : Bool
  mut cached_is_dense : Bool
  mut cached_default_filter_component_ids : Array[Int]
  mut cached_default_filter_local_component_ids : Array[Int]
  mut cached_default_filters_world_id : Int
  mut cached_dependency_component_ids : Array[Int]
  mut cached_dependency_world_id : Int
  mut cached_dependency_component_registration_generation : Int
}

///|
pub struct QueryCache {
  mut cached_candidate_archetypes : Array[Int]
  mut cached_anchor_component_id : Int?
  mut cached_filter_anchor_component_id : Int?
  mut cached_candidate_anchor_component_id : Int?
  mut cached_candidate_archetype_generation : Int
  mut cached_candidate_generation : Int
  mut cached_matching_entities : Array[@core.Entity]
  mut cached_matching_archetypes : Array[Int]
  mut cached_matching_archetype_generation : Int
  mut cached_matching_entities_generation : Int
  mut cached_matching_entities_sequence : Int
  mut cached_matching_anchor_component_id : Int?
  mut cached_matching_filter_anchor_component_id : Int?
  mut cached_matching_candidate_anchor_component_id : Int?
  mut cached_matching_candidate_generation : Int
  mut cached_matching_generation : Int
  mut cached_matching_sequence : Int
  mut cached_matching_entities_valid : Bool
  mut cached_matching_tables : Array[Int]
  mut cached_matching_table_archetype_groups : Array[Array[Int]]
  mut cached_matching_tables_generation : Int
  mut cached_matching_tables_valid : Bool
  mut cached_is_dense : Bool
  mut cached_default_filter_component_ids : Array[Int]
  mut cached_default_filter_local_component_ids : Array[Int]
  mut cached_default_filters_world_id : Int
  mut cached_dependency_component_ids : Array[Int]
  mut cached_dependency_world_id : Int
  mut cached_dependency_component_registration_generation : Int
} derive(ToJson, FromJson)

///|
pub struct Query[_, F] {
  world : World
  filter : F
  mut cache : QueryCache?
}

///|
pub struct QueryMany[D, F] {
  query : Query[D, F]
  default_filter_component_ids : Array[Int]
  entities_pre_matched : Bool
  archetype_driven : Bool
  dense_driven : Bool
  archetypes : Array[Int]
  mut archetype_index : Int
  mut archetype_entities : Array[@core.Entity]
  mut archetype_entity_index : Int
  dense_table_groups : Array[Array[Int]]
  mut dense_table_group_index : Int
  mut dense_table_group_archetype_index : Int
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct QueryCombinations[D, F] {
  query : Query[D, F]
  default_filter_component_ids : Array[Int]
  entities_pre_matched : Bool
  entities : Array[@core.Entity]
  mut left_index : Int
  mut right_index : Int
}

///|
pub struct QueryContiguousIter[D, F] {
  query : Query[D, F]
  default_filter_component_ids : Array[Int]
  entities_pre_matched : Bool
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct QueryParallel[D, F] {
  query : Query[D, F]
  batching_strategy : BatchingStrategy
}

///|
pub struct Has[_] {
  present : Bool
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
  value : T?
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
    cached_candidate_generation: -1,
    cached_matching_entities: [],
    cached_matching_archetypes: [],
    cached_matching_archetype_generation: -1,
    cached_matching_entities_generation: -1,
    cached_matching_entities_sequence: -1,
    cached_matching_anchor_component_id: None,
    cached_matching_filter_anchor_component_id: None,
    cached_matching_candidate_anchor_component_id: None,
    cached_matching_candidate_generation: -1,
    cached_matching_generation: -1,
    cached_matching_sequence: -1,
    cached_matching_entities_valid: false,
    cached_matching_tables: [],
    cached_matching_table_archetype_groups: [],
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
pub fn[D, F] Query::cache_snapshot(self : Query[D, F]) -> QueryCache {
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
    cached_candidate_generation: -1,
    cached_matching_entities: [],
    cached_matching_archetypes: [],
    cached_matching_archetype_generation: -1,
    cached_matching_entities_generation: -1,
    cached_matching_entities_sequence: -1,
    cached_matching_anchor_component_id: None,
    cached_matching_filter_anchor_component_id: None,
    cached_matching_candidate_anchor_component_id: None,
    cached_matching_candidate_generation: -1,
    cached_matching_generation: -1,
    cached_matching_sequence: -1,
    cached_matching_entities_valid: false,
    cached_matching_tables: [],
    cached_matching_table_archetype_groups: [],
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
  Some(D::fetch(query.world, entity))
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::view(
  self : Query[D, F],
  f : (@core.Entity, D) -> Unit,
) -> Unit raise EcsError {
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_table_groups = self.matching_dense_table_groups()
    if dense_table_groups.length() > 0 {
      for table_group in dense_table_groups {
        for archetype_id in table_group {
          match self.world.archetype_entities_view(archetype_id) {
            Some(entities) =>
              for entity in entities {
                f(entity, D::fetch(self.world, entity))
              }
            None => ()
          }
        }
      }
      return
    }
    for archetype_id in self.matching_archetypes() {
      match self.world.archetype_entities_view(archetype_id) {
        Some(entities) =>
          for entity in entities {
            f(entity, D::fetch(self.world, entity))
          }
        None => ()
      }
    }
    return
  }
  for entity in self.matching_entities() {
    f(entity, D::fetch(self.world, entity))
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
pub fn[D : QueryData, F : QueryFilter] Query::count(self : Query[D, F]) -> Int {
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_table_groups = self.matching_dense_table_groups()
    if dense_table_groups.length() > 0 {
      let count = Ref::new(0)
      for table_group in dense_table_groups {
        for archetype_id in table_group {
          count.val = count.val +
            self.world.archetype_entity_count(archetype_id)
        }
      }
      return count.val
    }
    let count = Ref::new(0)
    for archetype_id in self.matching_archetypes() {
      count.val = count.val + self.world.archetype_entity_count(archetype_id)
    }
    return count.val
  }
  self.matching_entities().length()
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::single(
  self : Query[D, F],
) -> D? raise EcsError {
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_table_groups = self.matching_dense_table_groups()
    if dense_table_groups.length() > 0 {
      let found : Ref[@core.Entity?] = Ref::new(None)
      for table_group in dense_table_groups {
        for archetype_id in table_group {
          match self.world.archetype_entities_view(archetype_id) {
            Some(entities) =>
              for entity in entities {
                if found.val is Some(_) {
                  return None
                }
                found.val = Some(entity)
              }
            None => ()
          }
        }
      }
      match found.val {
        Some(entity) => Some(D::fetch(self.world, entity))
        None => None
      }
    } else {
      let found : Ref[@core.Entity?] = Ref::new(None)
      for archetype_id in self.matching_archetypes() {
        match self.world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              if found.val is Some(_) {
                return None
              }
              found.val = Some(entity)
            }
          None => ()
        }
      }
      match found.val {
        Some(entity) => Some(D::fetch(self.world, entity))
        None => None
      }
    }
  } else {
    let entities = self.matching_entities()
    if entities.length() != 1 {
      return None
    }
    Some(D::fetch(self.world, entities[0]))
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
    default_filter_component_ids: self.default_filter_component_ids(),
    entities_pre_matched: false,
    archetype_driven: false,
    dense_driven: false,
    archetypes: [],
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    dense_table_groups: [],
    dense_table_group_index: 0,
    dense_table_group_archetype_index: 0,
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
  cache.query_matching_entities(
    self.world,
    self.filter,
    D::iteration_anchor_component(),
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
  cache.query_matching_archetypes(
    self.world,
    self.filter,
    D::iteration_anchor_component(),
    D::mentions_component,
    D::matches_component_set,
    D::is_dense,
    D::collect_access,
  )
}

///|
fn[D : QueryData, F : QueryFilter] Query::matching_dense_table_groups(
  self : Query[D, F],
) -> Array[Array[Int]] {
  let cache = self.ensure_cache()
  ignore(
    cache.query_matching_archetypes(
      self.world,
      self.filter,
      D::iteration_anchor_component(),
      D::mentions_component,
      D::matches_component_set,
      D::is_dense,
      D::collect_access,
    ),
  )
  if cache.cached_is_dense {
    cache.cached_matching_table_archetype_groups
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
fn[F : QueryFilter] QueryCache::query_candidate_archetypes(
  self : QueryCache,
  world : World,
  filter : F,
  data_anchor_component_id : Int?,
) -> Array[Int] {
  let filter_anchor_component_id = QueryFilter::iteration_anchor_component(
    filter,
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
    self.cached_candidate_generation = candidate_archetype_generation
  }
  self.cached_candidate_archetypes
}

///|
fn[F : QueryFilter] QueryCache::query_matching_entities(
  self : QueryCache,
  world : World,
  filter : F,
  data_anchor_component_id : Int?,
  data_matches : (World, @core.Entity) -> Bool,
  data_mentions_component : (Int) -> Bool,
  data_matches_component_set : ((Int) -> Bool) -> Bool,
  data_requires_entity_check : Bool,
  data_is_dense : (World) -> Bool,
  data_collect_access : (QueryDataAccess) -> Unit,
) -> Array[@core.Entity] {
  let matched_archetypes = self.query_matching_archetypes(
    world, filter, data_anchor_component_id, data_mentions_component, data_matches_component_set,
    data_is_dense, data_collect_access,
  )
  let filter_requires_entity_check = QueryFilter::requires_entity_check(filter)
  let dependency_component_ids = self.dependency_component_ids(
    world, filter, data_mentions_component, data_collect_access, true,
  )
  let matching_entities_generation = query_dependency_generation(
    world, dependency_component_ids,
  )
  let depends_on_sequence = QueryFilter::depends_on_sequence(filter)
  let sequence_marker = if depends_on_sequence {
    query_sequence_marker(world)
  } else {
    -1
  }
  let entity_cache_reusable = !data_requires_entity_check &&
    self.cached_matching_entities_valid &&
    self.cached_matching_entities_generation == matching_entities_generation &&
    (
      !depends_on_sequence ||
      self.cached_matching_entities_sequence == sequence_marker
    )
  if entity_cache_reusable {
    return self.cached_matching_entities
  }
  let matched_entities : Array[@core.Entity] = []
  if !data_requires_entity_check && !filter_requires_entity_check {
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
  self.cached_matching_entities_sequence = sequence_marker
  self.cached_matching_entities
}

///|
fn[F : QueryFilter] QueryCache::query_matching_archetypes(
  self : QueryCache,
  world : World,
  filter : F,
  data_anchor_component_id : Int?,
  data_mentions_component : (Int) -> Bool,
  data_matches_component_set : ((Int) -> Bool) -> Bool,
  data_is_dense : (World) -> Bool,
  data_collect_access : (QueryDataAccess) -> Unit,
) -> Array[Int] {
  let filter_anchor_component_id = QueryFilter::iteration_anchor_component(
    filter,
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
    world, filter, data_anchor_component_id,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  if matching_metadata_changed {
    let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
    let matched_archetypes : Array[Int] = []
    for archetype_id in candidate_archetypes {
      if query_archetype_matches_with_default_filter_component_ids(
          world, archetype_id, filter, default_filter_local_component_ids, data_matches_component_set,
        ) {
        matched_archetypes.push(archetype_id)
      }
    }
    self.cached_matching_archetypes = matched_archetypes
    self.cached_matching_archetype_generation = candidate_archetype_generation
    self.cached_matching_entities_valid = false
    self.cached_matching_tables_valid = false
  } else if self.cached_matching_archetype_generation !=
    candidate_archetype_generation {
    let added_candidate_archetypes : Array[Int] = []
    let candidate_removed = query_archetype_delta(
      previous_candidate_archetypes, candidate_archetypes, added_candidate_archetypes,
    )
    if candidate_removed {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      let matched_archetypes : Array[Int] = []
      for archetype_id in candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world, archetype_id, filter, default_filter_local_component_ids, data_matches_component_set,
          ) {
          matched_archetypes.push(archetype_id)
        }
      }
      self.cached_matching_archetypes = matched_archetypes
      self.cached_matching_entities_valid = false
      self.cached_matching_tables_valid = false
    } else {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      for archetype_id in added_candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world, archetype_id, filter, default_filter_local_component_ids, data_matches_component_set,
          ) {
          self.cached_matching_archetypes.push(archetype_id)
        }
      }
      if added_candidate_archetypes.length() > 0 {
        self.cached_matching_entities_valid = false
        self.cached_matching_tables_valid = false
      }
    }
    self.cached_matching_archetype_generation = candidate_archetype_generation
  }
  self.cached_matching_anchor_component_id = data_anchor_component_id
  self.cached_matching_filter_anchor_component_id = filter_anchor_component_id
  self.cached_matching_candidate_anchor_component_id = candidate_anchor_component_id
  self.cached_matching_candidate_generation = candidate_archetype_generation
  self.cached_matching_generation = candidate_archetype_generation
  self.cached_matching_sequence = -1
  let is_dense = query_is_dense_mode(
    world,
    filter,
    self.cached_default_filter_component_ids,
    data_is_dense,
    data_collect_access,
  )
  self.cached_is_dense = is_dense
  if is_dense {
    if !self.cached_matching_tables_valid ||
      self.cached_matching_tables_generation != candidate_archetype_generation {
      let (matching_tables, matching_table_archetype_groups) = query_matching_table_cache(
        world,
        self.cached_matching_archetypes,
      )
      self.cached_matching_tables = matching_tables
      self.cached_matching_table_archetype_groups = matching_table_archetype_groups
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    }
  } else {
    self.cached_matching_tables = []
    self.cached_matching_table_archetype_groups = []
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
fn query_archetype_delta(
  previous : Array[Int],
  current : Array[Int],
  added : Array[Int],
) -> Bool {
  let previous_index = Ref::new(0)
  let current_index = Ref::new(0)
  let removed = Ref::new(false)
  while previous_index.val < previous.length() &&
        current_index.val < current.length() {
    let previous_id = previous[previous_index.val]
    let current_id = current[current_index.val]
    if previous_id == current_id {
      previous_index.val = previous_index.val + 1
      current_index.val = current_index.val + 1
    } else if previous_id < current_id {
      removed.val = true
      previous_index.val = previous_index.val + 1
    } else {
      added.push(current_id)
      current_index.val = current_index.val + 1
    }
  }
  if previous_index.val < previous.length() {
    removed.val = true
  }
  while current_index.val < current.length() {
    added.push(current[current_index.val])
    current_index.val = current_index.val + 1
  }
  removed.val
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
  let mut generation = -1
  for component_id in component_ids {
    let component_generation = world.component_membership_generation_for_definition(
      component_id,
    )
    if component_generation > generation {
      generation = component_generation
    }
  }
  generation
}

///|
fn query_sequence_marker(world : World) -> Int {
  let sequence = world.get_sequence_context().sequence()
  sequence.last_run * 1_000_003 + sequence.this_run
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
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  let archetype_driven = access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check
  let default_filter_component_ids = self.default_filter_component_ids(world)
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
  {
    query,
    default_filter_component_ids,
    entities_pre_matched: true,
    archetype_driven,
    dense_driven,
    archetypes,
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    dense_table_groups: if dense_driven {
      self.query_matching_table_groups(world)
    } else {
      []
    },
    dense_table_group_index: 0,
    dense_table_group_archetype_index: 0,
    entities,
    index: 0,
  }
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
    default_filter_component_ids: self.default_filter_component_ids(world),
    entities_pre_matched: false,
    archetype_driven: false,
    dense_driven: false,
    archetypes: [],
    archetype_index: 0,
    archetype_entities: [],
    archetype_entity_index: 0,
    dense_table_groups: [],
    dense_table_group_index: 0,
    dense_table_group_archetype_index: 0,
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
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_table_groups = self.query_matching_table_groups(world)
    if dense_table_groups.length() > 0 {
      let found : Ref[@core.Entity?] = Ref::new(None)
      for table_group in dense_table_groups {
        for archetype_id in table_group {
          match world.archetype_entities_view(archetype_id) {
            Some(entities) =>
              for entity in entities {
                if found.val is Some(_) {
                  return None
                }
                found.val = Some(entity)
              }
            None => ()
          }
        }
      }
      match found.val {
        Some(entity) => Some(D::fetch(world, entity))
        None => None
      }
    } else {
      let found : Ref[@core.Entity?] = Ref::new(None)
      for archetype_id in self.query_matching_archetypes(world) {
        match world.archetype_entities_view(archetype_id) {
          Some(entities) =>
            for entity in entities {
              if found.val is Some(_) {
                return None
              }
              found.val = Some(entity)
            }
          None => ()
        }
      }
      match found.val {
        Some(entity) => Some(D::fetch(world, entity))
        None => None
      }
    }
  } else {
    let entities = self.query_matching_entities(world)
    if entities.length() != 1 {
      return None
    }
    Some(D::fetch(world, entities[0]))
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
  let data_requires_entity_check = D::requires_entity_check()
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let access_valid = query_access_valid(self.filter, D::collect_access)
  if access_valid &&
    !data_requires_entity_check &&
    !filter_requires_entity_check {
    let dense_table_groups = self.query_matching_table_groups(world)
    if dense_table_groups.length() > 0 {
      let count = Ref::new(0)
      for table_group in dense_table_groups {
        for archetype_id in table_group {
          count.val = count.val + world.archetype_entity_count(archetype_id)
        }
      }
      return count.val
    }
    let count = Ref::new(0)
    for archetype_id in self.query_matching_archetypes(world) {
      count.val = count.val + world.archetype_entity_count(archetype_id)
    }
    return count.val
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
fn[D, F : QueryFilter] QueryState::query_candidate_archetypes(
  self : QueryState[D, F],
  world : World,
  data_anchor_component_id : Int?,
) -> Array[Int] {
  let filter_anchor_component_id = QueryFilter::iteration_anchor_component(
    self.filter,
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
    self.cached_candidate_generation = candidate_archetype_generation
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
  let filter_requires_entity_check = QueryFilter::requires_entity_check(
    self.filter,
  )
  let dependency_component_ids = self.dependency_component_ids(world, true)
  let matching_entities_generation = query_dependency_generation(
    world, dependency_component_ids,
  )
  let depends_on_sequence = QueryFilter::depends_on_sequence(self.filter)
  let sequence_marker = if depends_on_sequence {
    query_sequence_marker(world)
  } else {
    -1
  }
  let entity_cache_reusable = !data_requires_entity_check &&
    self.cached_matching_entities_valid &&
    self.cached_matching_entities_generation == matching_entities_generation &&
    (
      !depends_on_sequence ||
      self.cached_matching_entities_sequence == sequence_marker
    )
  if entity_cache_reusable {
    return self.cached_matching_entities
  }
  let matched_entities : Array[@core.Entity] = []
  if !data_requires_entity_check && !filter_requires_entity_check {
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
  self.cached_matching_entities_sequence = sequence_marker
  self.cached_matching_entities
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::query_matching_archetypes(
  self : QueryState[D, F],
  world : World,
) -> Array[Int] {
  let data_anchor_component_id = D::iteration_anchor_component()
  let filter_anchor_component_id = QueryFilter::iteration_anchor_component(
    self.filter,
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
    world, data_anchor_component_id,
  )
  let candidate_archetype_generation = query_candidate_archetype_generation(
    world,
  )
  if matching_metadata_changed {
    let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
    let matched_archetypes : Array[Int] = []
    for archetype_id in candidate_archetypes {
      if query_archetype_matches_with_default_filter_component_ids(
          world,
          archetype_id,
          self.filter,
          default_filter_local_component_ids,
          D::matches_component_set,
        ) {
        matched_archetypes.push(archetype_id)
      }
    }
    self.cached_matching_archetypes = matched_archetypes
    self.cached_matching_archetype_generation = candidate_archetype_generation
    self.cached_matching_entities_valid = false
    self.cached_matching_tables_valid = false
  } else if self.cached_matching_archetype_generation !=
    candidate_archetype_generation {
    let added_candidate_archetypes : Array[Int] = []
    let candidate_removed = query_archetype_delta(
      previous_candidate_archetypes, candidate_archetypes, added_candidate_archetypes,
    )
    if candidate_removed {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      let matched_archetypes : Array[Int] = []
      for archetype_id in candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world,
            archetype_id,
            self.filter,
            default_filter_local_component_ids,
            D::matches_component_set,
          ) {
          matched_archetypes.push(archetype_id)
        }
      }
      self.cached_matching_archetypes = matched_archetypes
      self.cached_matching_entities_valid = false
      self.cached_matching_tables_valid = false
    } else {
      let default_filter_local_component_ids = self.cached_default_filter_local_component_ids
      for archetype_id in added_candidate_archetypes {
        if query_archetype_matches_with_default_filter_component_ids(
            world,
            archetype_id,
            self.filter,
            default_filter_local_component_ids,
            D::matches_component_set,
          ) {
          self.cached_matching_archetypes.push(archetype_id)
        }
      }
      if added_candidate_archetypes.length() > 0 {
        self.cached_matching_entities_valid = false
        self.cached_matching_tables_valid = false
      }
    }
    self.cached_matching_archetype_generation = candidate_archetype_generation
  }
  self.cached_matching_anchor_component_id = data_anchor_component_id
  self.cached_matching_filter_anchor_component_id = filter_anchor_component_id
  self.cached_matching_candidate_anchor_component_id = candidate_anchor_component_id
  self.cached_matching_candidate_generation = candidate_archetype_generation
  self.cached_matching_generation = candidate_archetype_generation
  self.cached_matching_sequence = -1
  let is_dense = query_is_dense_mode(
    world,
    self.filter,
    self.cached_default_filter_component_ids,
    D::is_dense,
    D::collect_access,
  )
  self.cached_is_dense = is_dense
  if is_dense {
    if !self.cached_matching_tables_valid ||
      self.cached_matching_tables_generation != candidate_archetype_generation {
      let (matching_tables, matching_table_archetype_groups) = query_matching_table_cache(
        world,
        self.cached_matching_archetypes,
      )
      self.cached_matching_tables = matching_tables
      self.cached_matching_table_archetype_groups = matching_table_archetype_groups
      self.cached_matching_tables_generation = candidate_archetype_generation
      self.cached_matching_tables_valid = true
    }
  } else {
    self.cached_matching_tables = []
    self.cached_matching_table_archetype_groups = []
    self.cached_matching_tables_generation = candidate_archetype_generation
    self.cached_matching_tables_valid = true
  }
  self.cached_matching_archetypes
}

///|
fn[D : QueryData, F : QueryFilter] QueryState::query_matching_table_groups(
  self : QueryState[D, F],
  world : World,
) -> Array[Array[Int]] {
  ignore(self.query_matching_archetypes(world))
  if self.cached_is_dense {
    self.cached_matching_table_archetype_groups
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
      if self.archetype_entity_index < self.archetype_entities.length() {
        let entity = self.archetype_entities[self.archetype_entity_index]
        self.archetype_entity_index = self.archetype_entity_index + 1
        return Some((entity, D::fetch(self.query.world, entity)))
      }
      if self.dense_table_group_index >= self.dense_table_groups.length() {
        return None
      }
      let table_group = self.dense_table_groups[self.dense_table_group_index]
      if self.dense_table_group_archetype_index >= table_group.length() {
        self.dense_table_group_index = self.dense_table_group_index + 1
        self.dense_table_group_archetype_index = 0
        continue
      }
      let archetype_id = table_group[self.dense_table_group_archetype_index]
      self.dense_table_group_archetype_index = self.dense_table_group_archetype_index +
        1
      self.archetype_entities = match
        self.query.world.archetype_entities_view(archetype_id) {
        Some(entities) => entities
        None => []
      }
      self.archetype_entity_index = 0
    }
  }
  if self.archetype_driven {
    while true {
      if self.archetype_entity_index < self.archetype_entities.length() {
        let entity = self.archetype_entities[self.archetype_entity_index]
        self.archetype_entity_index = self.archetype_entity_index + 1
        return Some((entity, D::fetch(self.query.world, entity)))
      }
      if self.archetype_index >= self.archetypes.length() {
        return None
      }
      let archetype_id = self.archetypes[self.archetype_index]
      self.archetype_index = self.archetype_index + 1
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
      return Some((entity, D::fetch(self.query.world, entity)))
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
          D::fetch(self.query.world, left_entity),
          D::fetch(self.query.world, right_entity),
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
      return Some(D::fetch(self.query.world, entity))
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
  world.non_empty_archetype_ids_snapshot()
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
  world.archetype_generation() * 1_000_003 +
  world.non_empty_archetype_generation()
}

///|
fn query_archetypes_for_component_id(
  world : World,
  component_id : Int,
) -> Array[Int] {
  guard world.local_component_id(component_id) is Some(component_local_id) else {
    return []
  }
  world.non_empty_archetype_ids_for_component_local_id(component_local_id)
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
  try world.get_resource(ecs_key_default_query_filters) catch {
    _ => None
  } noraise {
    Some(default_query_filters) => Some(default_query_filters)
    None => None
  }
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
  let seen : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  for entity in entities {
    let key = (entity.id, entity.generation)
    if seen.contains(key) {
      raise NonUniqueEntityList(entity)
    }
    seen.set(key, true)
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
fn query_find_string_index(values : Array[String], target : String) -> Int? {
  for index in 0..<values.length() {
    if values[index] == target {
      return Some(index)
    }
  }
  None
}

///|
fn query_table_signature_for_archetype(
  world : World,
  archetype_id : Int,
) -> String {
  guard world.archetype_local_component_presence_view(archetype_id)
    is Some(local_presence) else {
    return "table:"
  }
  let table_local_component_ids : Array[Int] = []
  for entry in local_presence.iter() {
    let local_component_id = entry.0
    if world.local_component_storage_type(local_component_id) == Some(Table) {
      table_local_component_ids.push(local_component_id)
    }
  }
  table_local_component_ids.sort()
  if table_local_component_ids.length() == 0 {
    return "table:"
  }
  let mut signature = "table:"
  for index in 0..<table_local_component_ids.length() {
    if index > 0 {
      signature = signature + ","
    }
    signature = signature + table_local_component_ids[index].to_string()
  }
  signature
}

///|
fn query_matching_table_cache(
  world : World,
  matched_archetypes : Array[Int],
) -> (Array[Int], Array[Array[Int]]) {
  let table_signatures : Array[String] = []
  let table_representative_archetypes : Array[Int] = []
  let table_archetype_groups : Array[Array[Int]] = []
  for archetype_id in matched_archetypes {
    let table_signature = query_table_signature_for_archetype(
      world, archetype_id,
    )
    match query_find_string_index(table_signatures, table_signature) {
      Some(index) => table_archetype_groups[index].push(archetype_id)
      None => {
        table_signatures.push(table_signature)
        table_representative_archetypes.push(archetype_id)
        table_archetype_groups.push([archetype_id])
      }
    }
  }
  (table_representative_archetypes, table_archetype_groups)
}
