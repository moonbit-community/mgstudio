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
pub struct Query1[A] {
  world : World
  key_a : ComponentKey[A]
}

///|
pub struct Query2[A, B] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
}

///|
pub struct Query3[A, B, C] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  key_c : ComponentKey[C]
}

///|
pub struct Has[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Has::new(key : ComponentKey[T]) -> Has[T] {
  Has::{ key, }
}

///|
pub fn[T] Has::key(self : Has[T]) -> ComponentKey[T] {
  self.key
}

///|
pub struct Optional[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Optional::new(key : ComponentKey[T]) -> Optional[T] {
  Optional::{ key, }
}

///|
pub fn[T] Optional::key(self : Optional[T]) -> ComponentKey[T] {
  self.key
}

///|
pub struct Query2Has[A, B] {
  world : World
  key_a : ComponentKey[A]
  has_b : Has[B]
}

///|
pub struct Query2HasFiltered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  has_b : Has[B]
  filter : F
}

///|
pub struct Query2Optional[A, B] {
  world : World
  key_a : ComponentKey[A]
  optional_b : Optional[B]
}

///|
pub struct Query2OptionalFiltered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  optional_b : Optional[B]
  filter : F
}

///|
pub struct EntityQuery[F] {
  world : World
  filter : F
}

///|
pub struct Query1Filtered[A, F] {
  world : World
  key_a : ComponentKey[A]
  filter : F
}

///|
pub struct Query1FilteredMany[A, F] {
  query : Query1Filtered[A, F]
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct Query1FilteredManyRef[A, F] {
  query : Query1Filtered[A, F]
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct Query2Filtered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  filter : F
}

///|
pub struct Query3Filtered[A, B, C, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  key_c : ComponentKey[C]
  filter : F
}

///|
pub fn[A] World::query1(self : World, key_a : ComponentKey[A]) -> Query1[A] {
  Query1::{ world: self, key_a }
}

///|
pub fn[A, B] World::query2(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
) -> Query2[A, B] {
  Query2::{ world: self, key_a, key_b }
}

///|
pub fn[A, B, C] World::query3(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
) -> Query3[A, B, C] {
  Query3::{ world: self, key_a, key_b, key_c }
}

///|
pub fn[A, B] World::query2_has(
  self : World,
  key_a : ComponentKey[A],
  has_b : Has[B],
) -> Query2Has[A, B] {
  Query2Has::{ world: self, key_a, has_b }
}

///|
pub fn[A, B, F] World::query2_has_filtered(
  self : World,
  key_a : ComponentKey[A],
  has_b : Has[B],
  filter : F,
) -> Query2HasFiltered[A, B, F] {
  Query2HasFiltered::{ world: self, key_a, has_b, filter }
}

///|
pub fn[A, B] World::query2_optional(
  self : World,
  key_a : ComponentKey[A],
  optional_b : Optional[B],
) -> Query2Optional[A, B] {
  Query2Optional::{ world: self, key_a, optional_b }
}

///|
pub fn[A, B, F] World::query2_optional_filtered(
  self : World,
  key_a : ComponentKey[A],
  optional_b : Optional[B],
  filter : F,
) -> Query2OptionalFiltered[A, B, F] {
  Query2OptionalFiltered::{ world: self, key_a, optional_b, filter }
}

///|
pub fn[F] World::query_entities_filtered(
  self : World,
  filter : F,
) -> EntityQuery[F] {
  EntityQuery::{ world: self, filter }
}

///|
pub fn[A, F] World::query1_filtered(
  self : World,
  key_a : ComponentKey[A],
  filter : F,
) -> Query1Filtered[A, F] {
  Query1Filtered::{ world: self, key_a, filter }
}

///|
pub fn[A, B, F] World::query2_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Query2Filtered[A, B, F] {
  Query2Filtered::{ world: self, key_a, key_b, filter }
}

///|
pub fn[A, B, C, F] World::query3_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  filter : F,
) -> Query3Filtered[A, B, C, F] {
  Query3Filtered::{ world: self, key_a, key_b, key_c, filter }
}

///|
pub fn[A] Query1::for_each(
  self : Query1[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_for_each(self.world, self.key_a, f)
}

///|
pub fn[A] Query1::get(
  self : Query1[A],
  entity : @core.Entity,
) -> A? raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).get(entity)
}

///|
pub fn[A] Query1::single(self : Query1[A]) -> A? raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).single()
}

///|
pub fn[A] Query1::require_single(self : Query1[A]) -> A raise {
  self.world.query1_filtered(self.key_a, All::new()).require_single()
}

///|
pub fn[A] Query1::count(self : Query1[A]) -> Int {
  self.world.query1_filtered(self.key_a, All::new()).count()
}

///|
pub fn[F : QueryFilter] EntityQuery::count(self : EntityQuery[F]) -> Int {
  let counter = Ref::new(0)
  self.view(fn(_entity) { counter.val = counter.val + 1 })
  counter.val
}

///|
pub fn[F : QueryFilter] EntityQuery::require_single(
  self : EntityQuery[F],
) -> @core.Entity raise {
  let count_ref : Ref[Int] = Ref::new(0)
  let entity_ref : Ref[@core.Entity?] = Ref::new(None)
  self.view(fn(entity) {
    count_ref.val = count_ref.val + 1
    if count_ref.val == 1 {
      entity_ref.val = Some(entity)
    } else {
      entity_ref.val = None
    }
  })
  if count_ref.val == 1 {
    match entity_ref.val {
      Some(entity) => entity
      None => raise Skipped("Expected exactly one matching entity")
    }
  } else {
    raise Skipped("Expected exactly one matching entity")
  }
}

///|
pub fn[F : QueryFilter] EntityQuery::view(
  self : EntityQuery[F],
  f : (@core.Entity) -> Unit,
) -> Unit {
  let query_component_ids : Array[Int] = []
  for entity in query_all_alive_entities(self.world) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      f(entity)
    }
  }
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::get(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> A? raise EcsError {
  let query_component_ids = [self.key_a.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  self.world.get(entity, self.key_a)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::get_ref(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> ComponentRef[A]? raise EcsError {
  let query_component_ids = [self.key_a.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  query_component_ref(self.world, self.key_a, entity)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::view(
  self : Query1Filtered[A, F],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let query_component_ids = [self.key_a.id()]
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value : A = self.world.component_value(self.key_a, entry.0, entry.1)
      f(entry.0, value)
    }
  }
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::view_ref(
  self : Query1Filtered[A, F],
  f : (@core.Entity, ComponentRef[A]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let query_component_ids = [self.key_a.id()]
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let component_ref = query_component_ref_from_payload(
        self.world,
        self.key_a,
        entry.0,
        entry.1,
      )
      f(entry.0, component_ref)
    }
  }
}

///|
pub fn[A, F] Query1Filtered::iter_many(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredMany[A, F] {
  { query: self, entities, index: 0 }
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredMany[A, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_unsafe(entities)
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique_unsafe(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredMany[A, F] {
  self.iter_many(entities)
}

///|
pub fn[A, F] Query1Filtered::iter_many_ref(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyRef[A, F] {
  { query: self, entities, index: 0 }
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique_ref(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyRef[A, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_ref_unsafe(entities)
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique_ref_unsafe(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyRef[A, F] {
  self.iter_many_ref(entities)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::for_each(
  self : Query1Filtered[A, F],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let query_component_ids = [self.key_a.id()]
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value : A = self.world.component_value(self.key_a, entry.0, entry.1)
      f(entry.0, value)
    }
  }
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::single(
  self : Query1Filtered[A, F],
) -> A? raise EcsError {
  let count_ref : Ref[Int] = Ref::new(0)
  let value_ref : Ref[A?] = Ref::new(None)
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
pub fn[A, F : QueryFilter] Query1Filtered::require_single(
  self : Query1Filtered[A, F],
) -> A raise {
  let single = self.single()
  match single {
    Some(value) => value
    None => raise Skipped("Expected exactly one matching entity")
  }
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::count(
  self : Query1Filtered[A, F],
) -> Int {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return 0
  }
  let query_component_ids = [self.key_a.id()]
  let counter = Ref::new(0)
  store_ref.val.for_each(fn(entity, _payload) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
pub fn[A] Query1::view(
  self : Query1[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_view(self.world, self.key_a, f)
}

///|
pub fn[A] Query1::iter_many_unique(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredMany[A, All] raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).iter_many_unique(entities)
}

///|
pub fn[A] Query1::iter_many_unique_unsafe(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredMany[A, All] {
  self.world
  .query1_filtered(self.key_a, All::new())
  .iter_many_unique_unsafe(entities)
}

///|
pub fn[A] Query1::iter_many_unique_ref(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredManyRef[A, All] raise EcsError {
  self.world
  .query1_filtered(self.key_a, All::new())
  .iter_many_unique_ref(entities)
}

///|
pub fn[A] Query1::iter_many_unique_ref_unsafe(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredManyRef[A, All] {
  self.world
  .query1_filtered(self.key_a, All::new())
  .iter_many_unique_ref_unsafe(entities)
}

///|
pub fn[A, B] Query2::for_each(
  self : Query2[A, B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each(self.world, self.key_a, self.key_b, f)
}

///|
pub fn[A, B] Query2::get(
  self : Query2[A, B],
  entity : @core.Entity,
) -> (A, B)? raise EcsError {
  self.world.query2_filtered(self.key_a, self.key_b, All::new()).get(entity)
}

///|
pub fn[A, B] Query2::view(
  self : Query2[A, B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_view(self.world, self.key_a, self.key_b, f)
}

///|
pub fn[A, B] Query2::count(self : Query2[A, B]) -> Int {
  query2_count_filtered(self.world, self.key_a, self.key_b, All::new())
}

///|
pub fn[A, B, F : QueryFilter] Query2Filtered::get(
  self : Query2Filtered[A, B, F],
  entity : @core.Entity,
) -> (A, B)? raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  Some((value_a, value_b))
}

///|
pub fn[A, B, F : QueryFilter] Query2Filtered::view(
  self : Query2Filtered[A, B, F],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id()]
  query2_for_each_intersection(self.world, self.key_a, self.key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      f(entity, value_a, value_b)
    }
  })
}

///|
pub fn[A, B, F : QueryFilter] Query2Filtered::for_each(
  self : Query2Filtered[A, B, F],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id()]
  query2_for_each_intersection(self.world, self.key_a, self.key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      f(entity, value_a, value_b)
    }
  })
}

///|
pub fn[A, B, F : QueryFilter] Query2Filtered::count(
  self : Query2Filtered[A, B, F],
) -> Int {
  query2_count_filtered(self.world, self.key_a, self.key_b, self.filter)
}

///|
pub fn[A, B] Query2Has::get(
  self : Query2Has[A, B],
  entity : @core.Entity,
) -> (A, Bool)? raise EcsError {
  self.world.query2_has_filtered(self.key_a, self.has_b, All::new()).get(entity)
}

///|
pub fn[A, B] Query2Has::view(
  self : Query2Has[A, B],
  f : (@core.Entity, A, Bool) -> Unit,
) -> Unit raise EcsError {
  try! self.world
  .query2_has_filtered(self.key_a, self.has_b, All::new())
  .view(f)
}

///|
pub fn[A, B] Query2Has::for_each(
  self : Query2Has[A, B],
  f : (@core.Entity, A, Bool) -> Unit,
) -> Unit raise EcsError {
  try! self.world
  .query2_has_filtered(self.key_a, self.has_b, All::new())
  .for_each(f)
}

///|
pub fn[A, B] Query2Has::count(self : Query2Has[A, B]) -> Int {
  self.world.query2_has_filtered(self.key_a, self.has_b, All::new()).count()
}

///|
pub fn[A, B, F : QueryFilter] Query2HasFiltered::get(
  self : Query2HasFiltered[A, B, F],
  entity : @core.Entity,
) -> (A, Bool)? raise EcsError {
  let query_component_ids = [self.key_a.id(), self.has_b.key().id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  Some(
    (
      value_a,
      entity_has_component_id(self.world, self.has_b.key().id(), entity),
    ),
  )
}

///|
pub fn[A, B, F : QueryFilter] Query2HasFiltered::view(
  self : Query2HasFiltered[A, B, F],
  f : (@core.Entity, A, Bool) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let query_component_ids = [self.key_a.id(), self.has_b.key().id()]
  let has_b_key = self.has_b.key()
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value_a : A = self.world.component_value(self.key_a, entry.0, entry.1)
      f(
        entry.0,
        value_a,
        entity_has_component_id(self.world, has_b_key.id(), entry.0),
      )
    }
  }
}

///|
pub fn[A, B, F : QueryFilter] Query2HasFiltered::for_each(
  self : Query2HasFiltered[A, B, F],
  f : (@core.Entity, A, Bool) -> Unit,
) -> Unit raise EcsError {
  try! self.view(f)
}

///|
pub fn[A, B, F : QueryFilter] Query2HasFiltered::count(
  self : Query2HasFiltered[A, B, F],
) -> Int {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return 0
  }
  let query_component_ids = [self.key_a.id(), self.has_b.key().id()]
  let counter = Ref::new(0)
  store_ref.val.for_each(fn(entity, _payload) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
pub fn[A, B] Query2Optional::get(
  self : Query2Optional[A, B],
  entity : @core.Entity,
) -> (A, B?)? raise EcsError {
  self.world
  .query2_optional_filtered(self.key_a, self.optional_b, All::new())
  .get(entity)
}

///|
pub fn[A, B] Query2Optional::view(
  self : Query2Optional[A, B],
  f : (@core.Entity, A, B?) -> Unit,
) -> Unit raise EcsError {
  try! self.world
  .query2_optional_filtered(self.key_a, self.optional_b, All::new())
  .view(f)
}

///|
pub fn[A, B] Query2Optional::for_each(
  self : Query2Optional[A, B],
  f : (@core.Entity, A, B?) -> Unit,
) -> Unit raise EcsError {
  try! self.world
  .query2_optional_filtered(self.key_a, self.optional_b, All::new())
  .for_each(f)
}

///|
pub fn[A, B] Query2Optional::count(self : Query2Optional[A, B]) -> Int {
  self.world
  .query2_optional_filtered(self.key_a, self.optional_b, All::new())
  .count()
}

///|
pub fn[A, B, F : QueryFilter] Query2OptionalFiltered::get(
  self : Query2OptionalFiltered[A, B, F],
  entity : @core.Entity,
) -> (A, B?)? raise EcsError {
  let query_component_ids = [self.key_a.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  Some((value_a, try! self.world.get(entity, self.optional_b.key())))
}

///|
pub fn[A, B, F : QueryFilter] Query2OptionalFiltered::view(
  self : Query2OptionalFiltered[A, B, F],
  f : (@core.Entity, A, B?) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let query_component_ids = [self.key_a.id()]
  let optional_b_key = self.optional_b.key()
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value_a : A = self.world.component_value(self.key_a, entry.0, entry.1)
      f(entry.0, value_a, try! self.world.get(entry.0, optional_b_key))
    }
  }
}

///|
pub fn[A, B, F : QueryFilter] Query2OptionalFiltered::for_each(
  self : Query2OptionalFiltered[A, B, F],
  f : (@core.Entity, A, B?) -> Unit,
) -> Unit raise EcsError {
  try! self.view(f)
}

///|
pub fn[A, B, F : QueryFilter] Query2OptionalFiltered::count(
  self : Query2OptionalFiltered[A, B, F],
) -> Int {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return 0
  }
  let query_component_ids = [self.key_a.id()]
  let counter = Ref::new(0)
  store_ref.val.for_each(fn(entity, _payload) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
pub fn[A, B, C] Query3::for_each(
  self : Query3[A, B, C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each(self.world, self.key_a, self.key_b, self.key_c, f)
}

///|
pub fn[A, B, C] Query3::get(
  self : Query3[A, B, C],
  entity : @core.Entity,
) -> (A, B, C)? raise EcsError {
  self.world
  .query3_filtered(self.key_a, self.key_b, self.key_c, All::new())
  .get(entity)
}

///|
pub fn[A, B, C] Query3::view(
  self : Query3[A, B, C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_view(self.world, self.key_a, self.key_b, self.key_c, f)
}

///|
pub fn[A, B, C] Query3::count(self : Query3[A, B, C]) -> Int {
  query3_count_filtered(
    self.world,
    self.key_a,
    self.key_b,
    self.key_c,
    All::new(),
  )
}

///|
pub fn[A, B, C, F : QueryFilter] Query3Filtered::get(
  self : Query3Filtered[A, B, C, F],
  entity : @core.Entity,
) -> (A, B, C)? raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id(), self.key_c.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  guard self.world.get(entity, self.key_c) is Some(value_c) else { return None }
  Some((value_a, value_b, value_c))
}

///|
pub fn[A, B, C, F : QueryFilter] Query3Filtered::view(
  self : Query3Filtered[A, B, C, F],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id(), self.key_c.id()]
  query3_for_each_intersection(self.world, self.key_a, self.key_b, self.key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      f(entity, value_a, value_b, value_c)
    }
  })
}

///|
pub fn[A, B, C, F : QueryFilter] Query3Filtered::for_each(
  self : Query3Filtered[A, B, C, F],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id(), self.key_c.id()]
  query3_for_each_intersection(self.world, self.key_a, self.key_b, self.key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    if query_matches_with_default_filters(
        self.world,
        entity,
        self.filter,
        query_component_ids,
      ) {
      f(entity, value_a, value_b, value_c)
    }
  })
}

///|
pub fn[A, B, C, F : QueryFilter] Query3Filtered::count(
  self : Query3Filtered[A, B, C, F],
) -> Int {
  query3_count_filtered(
    self.world,
    self.key_a,
    self.key_b,
    self.key_c,
    self.filter,
  )
}

///|
pub fn[A, F : QueryFilter] Query1FilteredMany::fetch_next(
  self : Query1FilteredMany[A, F],
) -> (@core.Entity, A)? raise EcsError {
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
pub fn[A, F : QueryFilter] Query1FilteredManyRef::fetch_next(
  self : Query1FilteredManyRef[A, F],
) -> (@core.Entity, ComponentRef[A])? raise EcsError {
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get_ref(entity) is Some(component_ref) {
      return Some((entity, component_ref))
    }
  }
  None
}

///|
pub fn[A] query1(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_for_each(world, key_a, f)
}

///|
pub fn[A] query1_view(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_ref) else { return }
  let query_component_ids = [key_a.id()]
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        world,
        entry.0,
        All::new(),
        query_component_ids,
      ) {
      let value : A = world.component_value(key_a, entry.0, entry.1)
      f(entry.0, value)
    }
  }
}

///|
pub fn[A] query1_for_each(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_ref) else { return }
  let query_component_ids = [key_a.id()]
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if query_matches_with_default_filters(
        world,
        entry.0,
        All::new(),
        query_component_ids,
      ) {
      let value : A = world.component_value(key_a, entry.0, entry.1)
      f(entry.0, value)
    }
  }
}

///|
pub fn[A, B] query2(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each(world, key_a, key_b, f)
}

///|
pub fn[A, B] query2_view(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each_intersection(world, key_a, key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    f(entity, value_a, value_b)
  })
}

///|
pub fn[A, B] query2_for_each(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each_intersection(world, key_a, key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    f(entity, value_a, value_b)
  })
}

///|
pub fn[A, B, C] query3(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each(world, key_a, key_b, key_c, f)
}

///|
pub fn[A, B, C] query3_view(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each_intersection(world, key_a, key_b, key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    f(entity, value_a, value_b, value_c)
  })
}

///|
pub fn[A, B, C] query3_for_each(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each_intersection(world, key_a, key_b, key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    f(entity, value_a, value_b, value_c)
  })
}

///|
fn[A, B] query2_for_each_intersection(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [key_a.id(), key_b.id()]

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        query_matches_with_default_filters(
          world,
          entry.0,
          All::new(),
          query_component_ids,
        ) {
        let value_a : A = world.component_value(key_a, entry.0, entry.1)
        let value_b : B = world.component_value(key_b, entry.0, payload_b)
        f(entry.0, value_a, value_b)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      query_matches_with_default_filters(
        world,
        entry.0,
        All::new(),
        query_component_ids,
      ) {
      let value_a : A = world.component_value(key_a, entry.0, payload_a)
      let value_b : B = world.component_value(key_b, entry.0, entry.1)
      f(entry.0, value_a, value_b)
    }
  }
}

///|
fn[A, B, C] query3_for_each_intersection(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return }
  guard world.component_store(key_c.id()) is Some(store_c_ref) else { return }

  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let store_c = store_c_ref.val
  let len_a = store_a.len()
  let len_b = store_b.len()
  let len_c = store_c.len()
  let query_component_ids = [key_a.id(), key_b.id(), key_c.id()]

  if len_a <= len_b && len_a <= len_c {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        store_c.get(entry.0) is Some(payload_c) &&
        query_matches_with_default_filters(
          world,
          entry.0,
          All::new(),
          query_component_ids,
        ) {
        let value_a : A = world.component_value(key_a, entry.0, entry.1)
        let value_b : B = world.component_value(key_b, entry.0, payload_b)
        let value_c : C = world.component_value(key_c, entry.0, payload_c)
        f(entry.0, value_a, value_b, value_c)
      }
    }
    return
  }

  if len_b <= len_a && len_b <= len_c {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_a.get(entry.0) is Some(payload_a) &&
        store_c.get(entry.0) is Some(payload_c) &&
        query_matches_with_default_filters(
          world,
          entry.0,
          All::new(),
          query_component_ids,
        ) {
        let value_a : A = world.component_value(key_a, entry.0, payload_a)
        let value_b : B = world.component_value(key_b, entry.0, entry.1)
        let value_c : C = world.component_value(key_c, entry.0, payload_c)
        f(entry.0, value_a, value_b, value_c)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_c.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      store_b.get(entry.0) is Some(payload_b) &&
      query_matches_with_default_filters(
        world,
        entry.0,
        All::new(),
        query_component_ids,
      ) {
      let value_a : A = world.component_value(key_a, entry.0, payload_a)
      let value_b : B = world.component_value(key_b, entry.0, payload_b)
      let value_c : C = world.component_value(key_c, entry.0, entry.1)
      f(entry.0, value_a, value_b, value_c)
    }
  }
}

///|
fn[A, B, F : QueryFilter] query2_count_filtered(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Int {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return 0 }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return 0 }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [key_a.id(), key_b.id()]
  let counter = Ref::new(0)

  if store_a.len() <= store_b.len() {
    store_a.for_each(fn(entity, _payload) {
      if store_b.contains(entity) &&
        query_matches_with_default_filters(
          world, entity, filter, query_component_ids,
        ) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  store_b.for_each(fn(entity, _payload) {
    if store_a.contains(entity) &&
      query_matches_with_default_filters(
        world, entity, filter, query_component_ids,
      ) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
fn[A, B, C, F : QueryFilter] query3_count_filtered(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  filter : F,
) -> Int {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return 0 }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return 0 }
  guard world.component_store(key_c.id()) is Some(store_c_ref) else { return 0 }

  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let store_c = store_c_ref.val
  let query_component_ids = [key_a.id(), key_b.id(), key_c.id()]
  let counter = Ref::new(0)

  if store_a.len() <= store_b.len() && store_a.len() <= store_c.len() {
    store_a.for_each(fn(entity, _payload) {
      if store_b.contains(entity) &&
        store_c.contains(entity) &&
        query_matches_with_default_filters(
          world, entity, filter, query_component_ids,
        ) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  if store_b.len() <= store_a.len() && store_b.len() <= store_c.len() {
    store_b.for_each(fn(entity, _payload) {
      if store_a.contains(entity) &&
        store_c.contains(entity) &&
        query_matches_with_default_filters(
          world, entity, filter, query_component_ids,
        ) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  store_c.for_each(fn(entity, _payload) {
    if store_a.contains(entity) &&
      store_b.contains(entity) &&
      query_matches_with_default_filters(
        world, entity, filter, query_component_ids,
      ) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
fn query_all_alive_entities(world : World) -> Array[@core.Entity] {
  world.entities.alive_entities()
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
fn[A] query_component_ref(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
) -> ComponentRef[A]? raise EcsError {
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  Some(query_component_ref_from_payload(world, key, entity, payload))
}

///|
fn[A] query_component_ref_from_payload(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  payload : ErasedValue,
) -> ComponentRef[A] raise EcsError {
  let value : A = world.component_value(key, entity, payload)
  ComponentRef::{ value, }
}
