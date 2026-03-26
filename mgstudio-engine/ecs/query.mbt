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
}

///|
pub struct Query[_, F] {
  world : World
  filter : F
}

///|
pub struct QueryMany[D, F] {
  query : Query[D, F]
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct QueryCombinations[D, F] {
  query : Query[D, F]
  entities : Array[@core.Entity]
  mut left_index : Int
  mut right_index : Int
}

///|
pub struct QueryContiguousIter[D, F] {
  query : Query[D, F]
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
  Query::{ world: self, filter }
}

///|
pub fn[D] World::query(self : World) -> QueryState[D, All] {
  ignore(self)
  { filter: All::new() }
}

///|
pub fn[D, F] World::query_filtered(
  self : World,
  filter : F,
) -> QueryState[D, F] {
  ignore(self)
  { filter, }
}

///|
pub fn[D] query(world : World) -> Query[D, All] {
  Query::{ world, filter: All::new() }
}

///|
pub fn[D, F] query_filtered(world : World, filter : F) -> Query[D, F] {
  Query::{ world, filter }
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::get(
  self : Query[D, F],
  entity : @core.Entity,
) -> D? raise EcsError {
  guard self.world.is_alive(entity) else { raise EntityNotAlive(entity) }
  guard query_matches_with_query_data_default_filters(
    self.world,
    entity,
    self.filter,
    D::mentions_component,
  ) else {
    return None
  }
  guard D::matches(self.world, entity) else { return None }
  Some(D::fetch(self.world, entity))
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::view(
  self : Query[D, F],
  f : (@core.Entity, D) -> Unit,
) -> Unit raise EcsError {
  for
    entity in query_candidate_entities(
      self.world,
      D::iteration_anchor_component(),
    ) {
    if query_matches_with_query_data_default_filters(
        self.world,
        entity,
        self.filter,
        D::mentions_component,
      ) &&
      D::matches(self.world, entity) {
      f(entity, D::fetch(self.world, entity))
    }
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
  let count_ref : Ref[Int] = Ref::new(0)
  for
    entity in query_candidate_entities(
      self.world,
      D::iteration_anchor_component(),
    ) {
    if query_matches_with_query_data_default_filters(
        self.world,
        entity,
        self.filter,
        D::mentions_component,
      ) &&
      D::matches(self.world, entity) {
      count_ref.val = count_ref.val + 1
    }
  }
  count_ref.val
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::single(
  self : Query[D, F],
) -> D? raise EcsError {
  let count_ref : Ref[Int] = Ref::new(0)
  let value_ref : Ref[D?] = Ref::new(None)
  self.view(fn(_entity, value) {
    count_ref.val = count_ref.val + 1
    if count_ref.val == 1 {
      value_ref.val = Some(value)
    } else {
      value_ref.val = None
    }
  })
  if count_ref.val == 1 {
    value_ref.val
  } else {
    None
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
pub fn[D, F] Query::iter_many(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  { query: self, entities, index: 0 }
}

///|
pub fn[D, F] Query::iter_many_unique(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_unsafe(entities)
}

///|
pub fn[D, F] Query::iter_many_unique_unsafe(
  self : Query[D, F],
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  self.iter_many(entities)
}

///|
pub fn[D : QueryData, F : QueryFilter] Query::iter_combinations(
  self : Query[D, F],
) -> QueryCombinations[D, F] {
  let entities : Array[@core.Entity] = []
  for
    entity in query_candidate_entities(
      self.world,
      D::iteration_anchor_component(),
    ) {
    if query_matches_with_query_data_default_filters(
        self.world,
        entity,
        self.filter,
        D::mentions_component,
      ) &&
      D::matches(self.world, entity) {
      entities.push(entity)
    }
  }
  { query: self, entities, left_index: 0, right_index: 1 }
}

///|
pub fn[D : QueryData, F] Query::contiguous_iter(
  self : Query[D, F],
) -> QueryContiguousIter[D, F]? {
  guard D::contiguous_compatible() else { return None }
  guard D::iteration_anchor_component() is Some(anchor_component_id) else {
    return None
  }
  let entities = query_entities_for_component_id(
    self.world,
    anchor_component_id,
  )
  Some({ query: self, entities, index: 0 })
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
pub fn[D : QueryData, F : QueryFilter] QueryState::get(
  self : QueryState[D, F],
  world : World,
  entity : @core.Entity,
) -> D? raise EcsError {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.get(entity)
}

///|
pub fn[D, F] QueryState::iter(
  self : QueryState[D, F],
  world : World,
) -> QueryMany[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.iter_many(query_all_alive_entities(world))
}

///|
pub fn[D, F] QueryState::iter_many(
  self : QueryState[D, F],
  world : World,
  entities : Array[@core.Entity],
) -> QueryMany[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.iter_many(entities)
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::iter_combinations(
  self : QueryState[D, F],
  world : World,
) -> QueryCombinations[D, F] {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.iter_combinations()
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryState::single(
  self : QueryState[D, F],
  world : World,
) -> D? raise EcsError {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.single()
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
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.count()
}

///|
pub fn[D : QueryData, F] QueryState::contiguous_iter(
  self : QueryState[D, F],
  world : World,
) -> QueryContiguousIter[D, F]? {
  let query : Query[D, F] = query_filtered(world, self.filter)
  query.contiguous_iter()
}

///|
pub fn[D : QueryData, F : QueryFilter] QueryMany::fetch_next(
  self : QueryMany[D, F],
) -> (@core.Entity, D)? raise EcsError {
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get(entity) is Some(value) {
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
    guard self.query.get(left_entity) is Some(left_value) else { continue }
    guard self.query.get(right_entity) is Some(right_value) else { continue }
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
    if self.query.get(entity) is Some(value) {
      return Some(value)
    }
  }
  None
}

///|
fn query_all_alive_entities(world : World) -> Array[@core.Entity] {
  world.entities.alive_entities()
}

///|
fn query_candidate_entities(
  world : World,
  anchor_component_id : Int?,
) -> Array[@core.Entity] {
  match anchor_component_id {
    Some(component_id) => query_entities_for_component_id(world, component_id)
    None => query_all_alive_entities(world)
  }
}

///|
fn query_entities_for_component_id(
  world : World,
  component_id : Int,
) -> Array[@core.Entity] {
  guard world.component_store(component_id) is Some(store_ref) else {
    return []
  }
  let entities : Array[@core.Entity] = []
  store_ref.val.for_each(fn(entity, _payload) { entities.push(entity) })
  entities
}

///|
fn[F : QueryFilter] query_matches_with_query_data_default_filters(
  world : World,
  entity : @core.Entity,
  filter : F,
  data_mentions_component : (Int) -> Bool,
) -> Bool {
  guard QueryFilter::matches(filter, world, entity) else { return false }
  try world.get_resource(ecs_key_default_query_filters) catch {
    _ => true
  } noraise {
    Some(default_query_filters) =>
      query_data_default_filters_allow_entity(
        default_query_filters, world, entity, filter, data_mentions_component,
      )
    None => true
  }
}

///|
fn[F : QueryFilter] query_data_default_filters_allow_entity(
  default_query_filters : DefaultQueryFilters,
  world : World,
  entity : @core.Entity,
  filter : F,
  data_mentions_component : (Int) -> Bool,
) -> Bool {
  for component_id in default_query_filters.disabling_component_ids() {
    if entity_has_component_id(world, component_id, entity) &&
      !data_mentions_component(component_id) &&
      !QueryFilter::mentions_component(filter, component_id) {
      return false
    }
  }
  true
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
