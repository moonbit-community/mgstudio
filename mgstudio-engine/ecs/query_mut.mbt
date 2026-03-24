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
pub struct Query1FilteredManyMut[A, F] {
  query : Query1Filtered[A, F]
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct Query1FilteredParallelMut[A, F] {
  query : Query1Filtered[A, F]
  batching_strategy : BatchingStrategy
}

///|
pub struct Query2RefMutFiltered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  filter : F
}

///|
pub struct Query2RefMutFilteredMany[A, B, F] {
  query : Query2RefMutFiltered[A, B, F]
  entities : Array[@core.Entity]
  mut index : Int
}

///|
pub struct Query2RefMutFilteredParallel[A, B, F] {
  query : Query2RefMutFiltered[A, B, F]
  batching_strategy : BatchingStrategy
}

///|
pub struct Query2ValueMutFiltered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  filter : F
}

///|
pub struct Query2ValueMutFilteredParallel[A, B, F] {
  query : Query2ValueMutFiltered[A, B, F]
  batching_strategy : BatchingStrategy
}

///|
pub struct Query2RefMutFilteredContiguousMut[A, B, F] {
  query : Query2RefMutFiltered[A, B, F]
  chunks : Array[Array[@core.Entity]]
  mut index : Int
}

///|
pub struct Query2ValueMutFilteredContiguousMut[A, B, F] {
  query : Query2ValueMutFiltered[A, B, F]
  chunks : Array[Array[@core.Entity]]
  mut index : Int
}

///|
pub struct Query3ValueRefMutFiltered[A, B, C, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  key_c : ComponentKey[C]
  filter : F
}

///|
pub struct Query3ValueRefMutFilteredParallel[A, B, C, F] {
  query : Query3ValueRefMutFiltered[A, B, C, F]
  batching_strategy : BatchingStrategy
}

///|
pub struct Query3RefMutOptionalFiltered[A, B, C, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  key_c : ComponentKey[C]
  filter : F
}

///|
fn[A] query_component_mut(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  Some(query_component_mut_from_payload(world, key, entity, payload))
}

///|
fn[A] query_component_mut_from_payload(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  payload : ErasedValue,
) -> ComponentMut[A] raise EcsError {
  let value_ref : Ref[A] = world.component_ref(key, entity, payload)
  ignore(key)
  ignore(entity)
  ComponentMut::{ value_ref, }
}

///|
fn[A, B, F : QueryFilter] query2_contiguous_chunks(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Array[Array[@core.Entity]] {
  let chunks : Array[Array[@core.Entity]] = []
  guard world.component_store(key_a.id()) is Some(store_a_ref) else {
    return chunks
  }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else {
    return chunks
  }

  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [key_a.id(), key_b.id()]
  let mut current_chunk : Array[@core.Entity] = []
  let mut previous_dense_index = -2
  let dense_index_ref = Ref::new(0)
  store_b.for_each(fn(entity, _payload) {
    let dense_i = dense_index_ref.val
    dense_index_ref.val = dense_index_ref.val + 1
    if store_a.contains(entity) &&
      query_matches_with_default_filters(
        world, entity, filter, query_component_ids,
      ) {
      if dense_i != previous_dense_index + 1 && current_chunk.length() > 0 {
        chunks.push(current_chunk)
        current_chunk = []
      }
      current_chunk.push(entity)
      previous_dense_index = dense_i
    }
  })

  if current_chunk.length() > 0 {
    chunks.push(current_chunk)
  }
  chunks
}

///|
pub fn[A] Query1::get_mut(
  self : Query1[A],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).get_mut(entity)
}

///|
pub fn[A] Query1::get_unchecked(
  self : Query1[A],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).get_unchecked(entity)
}

///|
pub fn[A] Query1::with_mut(
  self : Query1[A],
  entity : @core.Entity,
  f : (ComponentMut[A]) -> Unit,
) -> Bool raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).with_mut(entity, f)
}

///|
pub fn[A] Query1::view_mut(
  self : Query1[A],
  f : (@core.Entity, ComponentMut[A]) -> Unit,
) -> Unit raise EcsError {
  self.world.query1_filtered(self.key_a, All::new()).view_mut(f)
}

///|
pub fn[A] Query1::iter_many_mut(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, All] {
  self.world.query1_filtered(self.key_a, All::new()).iter_many_mut(entities)
}

///|
pub fn[A] Query1::iter_many_unique_mut(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, All] raise EcsError {
  self.world
  .query1_filtered(self.key_a, All::new())
  .iter_many_unique_mut(entities)
}

///|
pub fn[A] Query1::iter_many_unique_mut_unsafe(
  self : Query1[A],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, All] {
  self.world
  .query1_filtered(self.key_a, All::new())
  .iter_many_unique_mut_unsafe(entities)
}

///|
pub fn[A] Query1::par_iter_mut(
  self : Query1[A],
) -> Query1FilteredParallelMut[A, All] {
  self.world.query1_filtered(self.key_a, All::new()).par_iter_mut()
}

///|
pub fn[A, F] Query1Filtered::iter_many_mut(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, F] {
  { query: self, entities, index: 0 }
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique_mut(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_mut_unsafe(entities)
}

///|
pub fn[A, F] Query1Filtered::iter_many_unique_mut_unsafe(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, F] {
  self.iter_many_mut(entities)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::get_mut(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  let query_component_ids = [self.key_a.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  query_component_mut(self.world, self.key_a, entity)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::get_unchecked(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  self.get_mut(entity)
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::with_mut(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
  f : (ComponentMut[A]) -> Unit,
) -> Bool raise EcsError {
  if self.get_mut(entity) is Some(component_mut) {
    f(component_mut)
    return true
  }
  false
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::view_mut(
  self : Query1Filtered[A, F],
  f : (@core.Entity, ComponentMut[A]) -> Unit,
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
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_a,
        entry.0,
        entry.1,
      )
      f(entry.0, component_mut)
    }
  }
}

///|
pub fn[A, F] Query1Filtered::par_iter_mut(
  self : Query1Filtered[A, F],
) -> Query1FilteredParallelMut[A, F] {
  { query: self, batching_strategy: BatchingStrategy::new() }
}

///|
pub fn[A, F] Query1FilteredParallelMut::batching_strategy(
  self : Query1FilteredParallelMut[A, F],
  strategy : BatchingStrategy,
) -> Query1FilteredParallelMut[A, F] {
  { query: self.query, batching_strategy: strategy }
}

///|
pub fn[A, F : QueryFilter] Query1FilteredParallelMut::for_each(
  self : Query1FilteredParallelMut[A, F],
  f : (@core.Entity, ComponentMut[A]) -> Unit,
) -> Unit raise EcsError {
  ignore(self.batching_strategy)
  self.query.view_mut(f)
}

///|
pub fn[A, F : QueryFilter] Query1FilteredManyMut::fetch_next(
  self : Query1FilteredManyMut[A, F],
) -> (@core.Entity, ComponentMut[A])? raise EcsError {
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get_mut(entity) is Some(component_mut) {
      return Some((entity, component_mut))
    }
  }
  None
}

///|
pub fn[A, B, F] World::query2_ref_mut_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Query2RefMutFiltered[A, B, F] {
  Query2RefMutFiltered::{ world: self, key_a, key_b, filter }
}

///|
pub fn[A, B, F] World::query2_value_mut_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Query2ValueMutFiltered[A, B, F] {
  Query2ValueMutFiltered::{ world: self, key_a, key_b, filter }
}

///|
pub fn[A, B, C, F] World::query3_value_ref_mut_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  filter : F,
) -> Query3ValueRefMutFiltered[A, B, C, F] {
  Query3ValueRefMutFiltered::{ world: self, key_a, key_b, key_c, filter }
}

///|
pub fn[A, B, C, F] World::query3_ref_mut_optional_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  filter : F,
) -> Query3RefMutOptionalFiltered[A, B, C, F] {
  Query3RefMutOptionalFiltered::{ world: self, key_a, key_b, key_c, filter }
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::get(
  self : Query2RefMutFiltered[A, B, F],
  entity : @core.Entity,
) -> (ComponentRef[A], ComponentMut[B])? raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard query_component_ref(self.world, self.key_a, entity)
    is Some(component_ref) else {
    return None
  }
  guard query_component_mut(self.world, self.key_b, entity)
    is Some(component_mut) else {
    return None
  }
  Some((component_ref, component_mut))
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::get_unchecked(
  self : Query2RefMutFiltered[A, B, F],
  entity : @core.Entity,
) -> (ComponentRef[A], ComponentMut[B])? raise EcsError {
  self.get(entity)
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::with_mut(
  self : Query2RefMutFiltered[A, B, F],
  entity : @core.Entity,
  f : (ComponentRef[A], ComponentMut[B]) -> Unit,
) -> Bool raise EcsError {
  if self.get(entity) is Some((component_ref, component_mut)) {
    f(component_ref, component_mut)
    return true
  }
  false
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::get(
  self : Query2ValueMutFiltered[A, B, F],
  entity : @core.Entity,
) -> (A, ComponentMut[B])? raise EcsError {
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
  guard query_component_mut(self.world, self.key_b, entity)
    is Some(component_mut) else {
    return None
  }
  Some((value_a, component_mut))
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::get_unchecked(
  self : Query2ValueMutFiltered[A, B, F],
  entity : @core.Entity,
) -> (A, ComponentMut[B])? raise EcsError {
  self.get(entity)
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::contiguous_iter_mut(
  self : Query2ValueMutFiltered[A, B, F],
) -> Query2ValueMutFilteredContiguousMut[A, B, F]? {
  Some({
    query: self,
    chunks: query2_contiguous_chunks(
      self.world,
      self.key_a,
      self.key_b,
      self.filter,
    ),
    index: 0,
  })
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::with_mut(
  self : Query2ValueMutFiltered[A, B, F],
  entity : @core.Entity,
  f : (A, ComponentMut[B]) -> Unit,
) -> Bool raise EcsError {
  if self.get(entity) is Some((value_a, component_mut)) {
    f(value_a, component_mut)
    return true
  }
  false
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::view_mut(
  self : Query2ValueMutFiltered[A, B, F],
  f : (@core.Entity, A, ComponentMut[B]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_a_ref) else {
    return
  }
  guard self.world.component_store(self.key_b.id()) is Some(store_b_ref) else {
    return
  }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [self.key_a.id(), self.key_b.id()]

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        query_matches_with_default_filters(
          self.world,
          entry.0,
          self.filter,
          query_component_ids,
        ) {
        let value_a : A = self.world.component_value(
          self.key_a,
          entry.0,
          entry.1,
        )
        let component_mut = query_component_mut_from_payload(
          self.world,
          self.key_b,
          entry.0,
          payload_b,
        )
        f(entry.0, value_a, component_mut)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value_a : A = self.world.component_value(
        self.key_a,
        entry.0,
        payload_a,
      )
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_b,
        entry.0,
        entry.1,
      )
      f(entry.0, value_a, component_mut)
    }
  }
}

///|
pub fn[A, B, F] Query2ValueMutFiltered::par_iter_mut(
  self : Query2ValueMutFiltered[A, B, F],
) -> Query2ValueMutFilteredParallel[A, B, F] {
  { query: self, batching_strategy: BatchingStrategy::new() }
}

///|
pub fn[A, B, F] Query2ValueMutFilteredParallel::batching_strategy(
  self : Query2ValueMutFilteredParallel[A, B, F],
  strategy : BatchingStrategy,
) -> Query2ValueMutFilteredParallel[A, B, F] {
  { query: self.query, batching_strategy: strategy }
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFiltered::count(
  self : Query2ValueMutFiltered[A, B, F],
) -> Int {
  query2_count_filtered(self.world, self.key_a, self.key_b, self.filter)
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFilteredParallel::for_each(
  self : Query2ValueMutFilteredParallel[A, B, F],
  f : (@core.Entity, A, ComponentMut[B]) -> Unit,
) -> Unit raise EcsError {
  ignore(self.batching_strategy)
  self.query.view_mut(f)
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::view_mut(
  self : Query2RefMutFiltered[A, B, F],
  f : (@core.Entity, ComponentRef[A], ComponentMut[B]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_a_ref) else {
    return
  }
  guard self.world.component_store(self.key_b.id()) is Some(store_b_ref) else {
    return
  }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [self.key_a.id(), self.key_b.id()]

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        query_matches_with_default_filters(
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
        let component_mut = query_component_mut_from_payload(
          self.world,
          self.key_b,
          entry.0,
          payload_b,
        )
        f(entry.0, component_ref, component_mut)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let component_ref = query_component_ref_from_payload(
        self.world,
        self.key_a,
        entry.0,
        payload_a,
      )
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_b,
        entry.0,
        entry.1,
      )
      f(entry.0, component_ref, component_mut)
    }
  }
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::contiguous_iter_mut(
  self : Query2RefMutFiltered[A, B, F],
) -> Query2RefMutFilteredContiguousMut[A, B, F]? {
  Some({
    query: self,
    chunks: query2_contiguous_chunks(
      self.world,
      self.key_a,
      self.key_b,
      self.filter,
    ),
    index: 0,
  })
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFilteredContiguousMut::fetch_next(
  self : Query2RefMutFilteredContiguousMut[A, B, F],
) -> (Array[ComponentRef[A]], Array[ComponentMut[B]])? {
  guard self.chunks.get(self.index) is Some(chunk_entities) else { return None }
  self.index = self.index + 1

  let refs : Array[ComponentRef[A]] = []
  let muts : Array[ComponentMut[B]] = []
  for entity in chunk_entities {
    if (try? self.query.get_unchecked(entity))
      is Ok(Some((component_ref, component_mut))) {
      refs.push(component_ref)
      muts.push(component_mut)
    }
  }
  Some((refs, muts))
}

///|
pub fn[A, B, F : QueryFilter] Query2ValueMutFilteredContiguousMut::fetch_next(
  self : Query2ValueMutFilteredContiguousMut[A, B, F],
) -> (Array[A], Array[ComponentMut[B]])? {
  guard self.chunks.get(self.index) is Some(chunk_entities) else { return None }
  self.index = self.index + 1

  let values_a : Array[A] = []
  let muts : Array[ComponentMut[B]] = []
  for entity in chunk_entities {
    if (try? self.query.get_unchecked(entity))
      is Ok(Some((value_a, component_mut))) {
      values_a.push(value_a)
      muts.push(component_mut)
    }
  }
  Some((values_a, muts))
}

///|
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFiltered::get(
  self : Query3ValueRefMutFiltered[A, B, C, F],
  entity : @core.Entity,
) -> (A, ComponentRef[B], ComponentMut[C])? raise EcsError {
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
  guard query_component_ref(self.world, self.key_b, entity)
    is Some(component_ref) else {
    return None
  }
  guard query_component_mut(self.world, self.key_c, entity)
    is Some(component_mut) else {
    return None
  }
  Some((value_a, component_ref, component_mut))
}

///|
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFiltered::get_unchecked(
  self : Query3ValueRefMutFiltered[A, B, C, F],
  entity : @core.Entity,
) -> (A, ComponentRef[B], ComponentMut[C])? raise EcsError {
  self.get(entity)
}

///|
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFiltered::with_mut(
  self : Query3ValueRefMutFiltered[A, B, C, F],
  entity : @core.Entity,
  f : (A, ComponentRef[B], ComponentMut[C]) -> Unit,
) -> Bool raise EcsError {
  if self.get(entity) is Some((value_a, component_ref, component_mut)) {
    f(value_a, component_ref, component_mut)
    return true
  }
  false
}

///|
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFiltered::view_mut(
  self : Query3ValueRefMutFiltered[A, B, C, F],
  f : (@core.Entity, A, ComponentRef[B], ComponentMut[C]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_a_ref) else {
    return
  }
  guard self.world.component_store(self.key_b.id()) is Some(store_b_ref) else {
    return
  }
  guard self.world.component_store(self.key_c.id()) is Some(store_c_ref) else {
    return
  }

  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let store_c = store_c_ref.val
  let query_component_ids = [self.key_a.id(), self.key_b.id(), self.key_c.id()]

  if store_a.len() <= store_b.len() && store_a.len() <= store_c.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        store_c.get(entry.0) is Some(payload_c) &&
        query_matches_with_default_filters(
          self.world,
          entry.0,
          self.filter,
          query_component_ids,
        ) {
        let value_a : A = self.world.component_value(
          self.key_a,
          entry.0,
          entry.1,
        )
        let component_ref = query_component_ref_from_payload(
          self.world,
          self.key_b,
          entry.0,
          payload_b,
        )
        let component_mut = query_component_mut_from_payload(
          self.world,
          self.key_c,
          entry.0,
          payload_c,
        )
        f(entry.0, value_a, component_ref, component_mut)
      }
    }
    return
  }

  if store_b.len() <= store_a.len() && store_b.len() <= store_c.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_a.get(entry.0) is Some(payload_a) &&
        store_c.get(entry.0) is Some(payload_c) &&
        query_matches_with_default_filters(
          self.world,
          entry.0,
          self.filter,
          query_component_ids,
        ) {
        let value_a : A = self.world.component_value(
          self.key_a,
          entry.0,
          payload_a,
        )
        let component_ref = query_component_ref_from_payload(
          self.world,
          self.key_b,
          entry.0,
          entry.1,
        )
        let component_mut = query_component_mut_from_payload(
          self.world,
          self.key_c,
          entry.0,
          payload_c,
        )
        f(entry.0, value_a, component_ref, component_mut)
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
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let value_a : A = self.world.component_value(
        self.key_a,
        entry.0,
        payload_a,
      )
      let component_ref = query_component_ref_from_payload(
        self.world,
        self.key_b,
        entry.0,
        payload_b,
      )
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_c,
        entry.0,
        entry.1,
      )
      f(entry.0, value_a, component_ref, component_mut)
    }
  }
}

///|
pub fn[A, B, C, F] Query3ValueRefMutFiltered::par_iter_mut(
  self : Query3ValueRefMutFiltered[A, B, C, F],
) -> Query3ValueRefMutFilteredParallel[A, B, C, F] {
  { query: self, batching_strategy: BatchingStrategy::new() }
}

///|
pub fn[A, B, C, F] Query3ValueRefMutFilteredParallel::batching_strategy(
  self : Query3ValueRefMutFilteredParallel[A, B, C, F],
  strategy : BatchingStrategy,
) -> Query3ValueRefMutFilteredParallel[A, B, C, F] {
  { query: self.query, batching_strategy: strategy }
}

///|
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFiltered::count(
  self : Query3ValueRefMutFiltered[A, B, C, F],
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
pub fn[A, B, C, F : QueryFilter] Query3ValueRefMutFilteredParallel::for_each(
  self : Query3ValueRefMutFilteredParallel[A, B, C, F],
  f : (@core.Entity, A, ComponentRef[B], ComponentMut[C]) -> Unit,
) -> Unit raise EcsError {
  ignore(self.batching_strategy)
  self.query.view_mut(f)
}

///|
pub fn[A, B, C, F : QueryFilter] Query3RefMutOptionalFiltered::get(
  self : Query3RefMutOptionalFiltered[A, B, C, F],
  entity : @core.Entity,
) -> (ComponentRef[A], ComponentMut[B], ComponentRef[C]?)? raise EcsError {
  let query_component_ids = [self.key_a.id(), self.key_b.id()]
  guard query_matches_with_default_filters(
    self.world,
    entity,
    self.filter,
    query_component_ids,
  ) else {
    return None
  }
  guard query_component_ref(self.world, self.key_a, entity)
    is Some(component_ref_a) else {
    return None
  }
  guard query_component_mut(self.world, self.key_b, entity)
    is Some(component_mut_b) else {
    return None
  }
  let component_ref_c = query_component_ref(self.world, self.key_c, entity)
  Some((component_ref_a, component_mut_b, component_ref_c))
}

///|
pub fn[A, B, C, F : QueryFilter] Query3RefMutOptionalFiltered::get_unchecked(
  self : Query3RefMutOptionalFiltered[A, B, C, F],
  entity : @core.Entity,
) -> (ComponentRef[A], ComponentMut[B], ComponentRef[C]?)? raise EcsError {
  self.get(entity)
}

///|
pub fn[A, B, C, F : QueryFilter] Query3RefMutOptionalFiltered::with_mut(
  self : Query3RefMutOptionalFiltered[A, B, C, F],
  entity : @core.Entity,
  f : (ComponentRef[A], ComponentMut[B], ComponentRef[C]?) -> Unit,
) -> Bool raise EcsError {
  if self.get(entity)
    is Some((component_ref_a, component_mut_b, component_ref_c)) {
    f(component_ref_a, component_mut_b, component_ref_c)
    return true
  }
  false
}

///|
pub fn[A, B, C, F : QueryFilter] Query3RefMutOptionalFiltered::view_mut(
  self : Query3RefMutOptionalFiltered[A, B, C, F],
  f : (@core.Entity, ComponentRef[A], ComponentMut[B], ComponentRef[C]?) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_a_ref) else {
    return
  }
  guard self.world.component_store(self.key_b.id()) is Some(store_b_ref) else {
    return
  }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let query_component_ids = [self.key_a.id(), self.key_b.id()]

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, ErasedValue)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        query_matches_with_default_filters(
          self.world,
          entry.0,
          self.filter,
          query_component_ids,
        ) {
        let component_ref_a = query_component_ref_from_payload(
          self.world,
          self.key_a,
          entry.0,
          entry.1,
        )
        let component_mut_b = query_component_mut_from_payload(
          self.world,
          self.key_b,
          entry.0,
          payload_b,
        )
        let component_ref_c = match
          self.world.component_store(self.key_c.id()) {
          Some(store_c_ref) =>
            match store_c_ref.val.get(entry.0) {
              Some(payload_c) =>
                Some(
                  query_component_ref_from_payload(
                    self.world,
                    self.key_c,
                    entry.0,
                    payload_c,
                  ),
                )
              None => None
            }
          None => None
        }
        f(entry.0, component_ref_a, component_mut_b, component_ref_c)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      query_matches_with_default_filters(
        self.world,
        entry.0,
        self.filter,
        query_component_ids,
      ) {
      let component_ref_a = query_component_ref_from_payload(
        self.world,
        self.key_a,
        entry.0,
        payload_a,
      )
      let component_mut_b = query_component_mut_from_payload(
        self.world,
        self.key_b,
        entry.0,
        entry.1,
      )
      let component_ref_c = match self.world.component_store(self.key_c.id()) {
        Some(store_c_ref) =>
          match store_c_ref.val.get(entry.0) {
            Some(payload_c) =>
              Some(
                query_component_ref_from_payload(
                  self.world,
                  self.key_c,
                  entry.0,
                  payload_c,
                ),
              )
            None => None
          }
        None => None
      }
      f(entry.0, component_ref_a, component_mut_b, component_ref_c)
    }
  }
}

///|
pub fn[A, B, C, F : QueryFilter] Query3RefMutOptionalFiltered::count(
  self : Query3RefMutOptionalFiltered[A, B, C, F],
) -> Int {
  query2_count_filtered(self.world, self.key_a, self.key_b, self.filter)
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::count(
  self : Query2RefMutFiltered[A, B, F],
) -> Int {
  query2_count_filtered(self.world, self.key_a, self.key_b, self.filter)
}

///|
pub fn[A, B, F] Query2RefMutFiltered::iter_many_mut(
  self : Query2RefMutFiltered[A, B, F],
  entities : Array[@core.Entity],
) -> Query2RefMutFilteredMany[A, B, F] {
  { query: self, entities, index: 0 }
}

///|
pub fn[A, B, F] Query2RefMutFiltered::iter_many_unique_mut(
  self : Query2RefMutFiltered[A, B, F],
  entities : Array[@core.Entity],
) -> Query2RefMutFilteredMany[A, B, F] raise EcsError {
  query_require_unique_entities(entities)
  self.iter_many_unique_mut_unsafe(entities)
}

///|
pub fn[A, B, F] Query2RefMutFiltered::iter_many_unique_mut_unsafe(
  self : Query2RefMutFiltered[A, B, F],
  entities : Array[@core.Entity],
) -> Query2RefMutFilteredMany[A, B, F] {
  self.iter_many_mut(entities)
}

///|
pub fn[A, B, F] Query2RefMutFiltered::par_iter_mut(
  self : Query2RefMutFiltered[A, B, F],
) -> Query2RefMutFilteredParallel[A, B, F] {
  { query: self, batching_strategy: BatchingStrategy::new() }
}

///|
pub fn[A, B, F] Query2RefMutFilteredParallel::batching_strategy(
  self : Query2RefMutFilteredParallel[A, B, F],
  strategy : BatchingStrategy,
) -> Query2RefMutFilteredParallel[A, B, F] {
  { query: self.query, batching_strategy: strategy }
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFilteredParallel::for_each(
  self : Query2RefMutFilteredParallel[A, B, F],
  f : (@core.Entity, ComponentRef[A], ComponentMut[B]) -> Unit,
) -> Unit raise EcsError {
  ignore(self.batching_strategy)
  self.query.view_mut(f)
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFilteredMany::fetch_next(
  self : Query2RefMutFilteredMany[A, B, F],
) -> (@core.Entity, ComponentRef[A], ComponentMut[B])? raise EcsError {
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get(entity) is Some((component_ref, component_mut)) {
      return Some((entity, component_ref, component_mut))
    }
  }
  None
}
