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
  mut pending : (@core.Entity, ComponentMut[A])?
}

///|
pub struct Query1FilteredParallelMut[A, F] {
  query : Query1Filtered[A, F]
}

///|
pub struct Query2RefMutFiltered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  filter : F
  system : @core.SystemTicks
}

///|
pub struct Query2RefMutFilteredMany[A, B, F] {
  query : Query2RefMutFiltered[A, B, F]
  entities : Array[@core.Entity]
  mut index : Int
  mut pending : (@core.Entity, ComponentRef[A], ComponentMut[B])?
}

///|
pub struct Query2RefMutFilteredParallel[A, B, F] {
  query : Query2RefMutFiltered[A, B, F]
}

///|
fn[A : ToJson] query_component_mut_has_writeback(
  component_mut : ComponentMut[A],
) -> Bool {
  component_mut.value_ref.val.to_json() != component_mut.original_payload
}

///|
fn[A : ToJson] query_component_mut_writeback(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  component_mut : ComponentMut[A],
) -> Unit {
  if !query_component_mut_has_writeback(component_mut) {
    return
  }
  let store_ref = world.ensure_component_store(key.id())
  let tick = component_write_change_tick(world)
  store_ref.val.set(entity, component_mut.value_ref.val.to_json(), tick)
  |> ignore
}

///|
fn[A : @json.FromJson] query_component_mut(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  system : @core.SystemTicks,
) -> ComponentMut[A]? raise EcsError {
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  Some(query_component_mut_from_payload(world, key, entity, payload, system))
}

///|
fn[A : @json.FromJson] query_component_mut_from_payload(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  payload : Json,
  system : @core.SystemTicks,
) -> ComponentMut[A] raise EcsError {
  let value : A = world.decode_component_payload(key, entity, payload)
  let ticks = world.component(key).get_ticks(entity).unwrap()
  ComponentMut::{
    value_ref: Ref::new(value),
    ticks,
    system,
    original_payload: payload,
  }
}

///|
pub fn[A, F] Query1Filtered::iter_many_mut(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> Query1FilteredManyMut[A, F] {
  { query: self, entities, index: 0, pending: None }
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::get_mut(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> ComponentMut[A]? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  query_component_mut(self.world, self.key_a, entity, self.system)
}

///|
pub fn[A : ToJson + @json.FromJson, F : QueryFilter] Query1Filtered::view_mut(
  self : Query1Filtered[A, F],
  f : (@core.Entity, ComponentMut[A]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_a,
        entry.0,
        entry.1,
        self.system,
      )
      f(entry.0, component_mut)
      query_component_mut_writeback(
        self.world,
        self.key_a,
        entry.0,
        component_mut,
      )
    }
  }
}

///|
pub fn[A, F] Query1Filtered::par_iter_mut(
  self : Query1Filtered[A, F],
) -> Query1FilteredParallelMut[A, F] {
  { query: self }
}

///|
pub fn[A : ToJson + @json.FromJson, F : QueryFilter] Query1FilteredParallelMut::for_each(
  self : Query1FilteredParallelMut[A, F],
  f : (@core.Entity, ComponentMut[A]) -> Unit,
) -> Unit raise EcsError {
  self.query.view_mut(f)
}

///|
pub fn[A : ToJson, F] Query1FilteredManyMut::flush(
  self : Query1FilteredManyMut[A, F],
) -> Unit {
  if self.pending is Some((entity, component_mut)) {
    query_component_mut_writeback(
      self.query.world,
      self.query.key_a,
      entity,
      component_mut,
    )
    self.pending = None
  }
}

///|
pub fn[A : ToJson + @json.FromJson, F : QueryFilter] Query1FilteredManyMut::fetch_next(
  self : Query1FilteredManyMut[A, F],
) -> (@core.Entity, ComponentMut[A])? raise EcsError {
  self.flush()
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get_mut(entity) is Some(component_mut) {
      self.pending = Some((entity, component_mut))
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
  Query2RefMutFiltered::{
    world: self,
    key_a,
    key_b,
    filter,
    system: self.get_system_context().ticks(),
  }
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, F : QueryFilter] Query2RefMutFiltered::get(
  self : Query2RefMutFiltered[A, B, F],
  entity : @core.Entity,
) -> (ComponentRef[A], ComponentMut[B])? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  guard query_component_ref(self.world, self.key_a, entity, self.system)
    is Some(component_ref) else {
    return None
  }
  guard query_component_mut(self.world, self.key_b, entity, self.system)
    is Some(component_mut) else {
    return None
  }
  Some((component_ref, component_mut))
}

///|
pub fn[A : @json.FromJson, B : ToJson + @json.FromJson, F : QueryFilter] Query2RefMutFiltered::view_mut(
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

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, Json)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
        let component_ref = query_component_ref_from_payload(
          self.world,
          self.key_a,
          entry.0,
          entry.1,
          self.system,
        )
        let component_mut = query_component_mut_from_payload(
          self.world,
          self.key_b,
          entry.0,
          payload_b,
          self.system,
        )
        f(entry.0, component_ref, component_mut)
        query_component_mut_writeback(
          self.world,
          self.key_b,
          entry.0,
          component_mut,
        )
      }
    }
    return
  }

  let entries : Array[(@core.Entity, Json)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
      let component_ref = query_component_ref_from_payload(
        self.world,
        self.key_a,
        entry.0,
        payload_a,
        self.system,
      )
      let component_mut = query_component_mut_from_payload(
        self.world,
        self.key_b,
        entry.0,
        entry.1,
        self.system,
      )
      f(entry.0, component_ref, component_mut)
      query_component_mut_writeback(
        self.world,
        self.key_b,
        entry.0,
        component_mut,
      )
    }
  }
}

///|
pub fn[A, B, F : QueryFilter] Query2RefMutFiltered::count(
  self : Query2RefMutFiltered[A, B, F],
) -> Int {
  query2_count_filtered(
    self.world,
    self.key_a,
    self.key_b,
    self.filter,
    self.system,
  )
}

///|
pub fn[A, B, F] Query2RefMutFiltered::iter_many_mut(
  self : Query2RefMutFiltered[A, B, F],
  entities : Array[@core.Entity],
) -> Query2RefMutFilteredMany[A, B, F] {
  { query: self, entities, index: 0, pending: None }
}

///|
pub fn[A, B, F] Query2RefMutFiltered::par_iter_mut(
  self : Query2RefMutFiltered[A, B, F],
) -> Query2RefMutFilteredParallel[A, B, F] {
  { query: self }
}

///|
pub fn[A : @json.FromJson, B : ToJson + @json.FromJson, F : QueryFilter] Query2RefMutFilteredParallel::for_each(
  self : Query2RefMutFilteredParallel[A, B, F],
  f : (@core.Entity, ComponentRef[A], ComponentMut[B]) -> Unit,
) -> Unit raise EcsError {
  self.query.view_mut(f)
}

///|
pub fn[A, B : ToJson, F] Query2RefMutFilteredMany::flush(
  self : Query2RefMutFilteredMany[A, B, F],
) -> Unit {
  if self.pending is Some((entity, _component_ref, component_mut)) {
    query_component_mut_writeback(
      self.query.world,
      self.query.key_b,
      entity,
      component_mut,
    )
    self.pending = None
  }
}

///|
pub fn[A : @json.FromJson, B : ToJson + @json.FromJson, F : QueryFilter] Query2RefMutFilteredMany::fetch_next(
  self : Query2RefMutFilteredMany[A, B, F],
) -> (@core.Entity, ComponentRef[A], ComponentMut[B])? raise EcsError {
  self.flush()
  while self.index < self.entities.length() {
    let entity = self.entities[self.index]
    self.index = self.index + 1
    if self.query.get(entity) is Some((component_ref, component_mut)) {
      self.pending = Some((entity, component_ref, component_mut))
      return Some((entity, component_ref, component_mut))
    }
  }
  None
}
