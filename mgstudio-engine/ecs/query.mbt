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
pub struct EntityQuery[F] {
  world : World
  filter : F
  system : @core.SystemTicks
}

///|
pub struct Query1Filtered[A, F] {
  world : World
  key_a : ComponentKey[A]
  filter : F
  system : @core.SystemTicks
}

///|
pub struct Query2Filtered[A, B, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  filter : F
  system : @core.SystemTicks
}

///|
pub struct Query3Filtered[A, B, C, F] {
  world : World
  key_a : ComponentKey[A]
  key_b : ComponentKey[B]
  key_c : ComponentKey[C]
  filter : F
  system : @core.SystemTicks
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
pub fn[F] World::query_entities_filtered(
  self : World,
  filter : F,
) -> EntityQuery[F] {
  EntityQuery::{
    world: self,
    filter,
    system: self.get_system_context().ticks(),
  }
}

///|
pub fn[A, F] World::query1_filtered(
  self : World,
  key_a : ComponentKey[A],
  filter : F,
) -> Query1Filtered[A, F] {
  Query1Filtered::{
    world: self,
    key_a,
    filter,
    system: self.get_system_context().ticks(),
  }
}

///|
pub fn[A, B, F] World::query2_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  filter : F,
) -> Query2Filtered[A, B, F] {
  Query2Filtered::{
    world: self,
    key_a,
    key_b,
    filter,
    system: self.get_system_context().ticks(),
  }
}

///|
pub fn[A, B, C, F] World::query3_filtered(
  self : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  filter : F,
) -> Query3Filtered[A, B, C, F] {
  Query3Filtered::{
    world: self,
    key_a,
    key_b,
    key_c,
    filter,
    system: self.get_system_context().ticks(),
  }
}

///|
pub fn[A : ToJson + @json.FromJson] Query1::for_each(
  self : Query1[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_for_each(self.world, self.key_a, f)
}

///|
pub fn[A : @json.FromJson] Query1::get(
  self : Query1[A],
  entity : @core.Entity,
) -> A? raise EcsError {
  self.world.get(entity, self.key_a)
}

///|
pub fn[F : QueryFilter] EntityQuery::count(self : EntityQuery[F]) -> Int {
  let counter = Ref::new(0)
  self.view(fn(_entity) { counter.val = counter.val + 1 })
  counter.val
}

///|
pub fn[F : QueryFilter] EntityQuery::view(
  self : EntityQuery[F],
  f : (@core.Entity) -> Unit,
) -> Unit {
  for entity in query_all_alive_entities(self.world) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      f(entity)
    }
  }
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::get(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> A? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  self.world.get(entity, self.key_a)
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::get_ref(
  self : Query1Filtered[A, F],
  entity : @core.Entity,
) -> ComponentRef[A]? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  query_component_ref(self.world, self.key_a, entity, self.system)
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::view(
  self : Query1Filtered[A, F],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
      let value : A = self.world.decode_component_payload(
        self.key_a,
        entry.0,
        entry.1,
      )
      f(entry.0, value)
    }
  }
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::view_ref(
  self : Query1Filtered[A, F],
  f : (@core.Entity, ComponentRef[A]) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
      let component_ref = query_component_ref_from_payload(
        self.world,
        self.key_a,
        entry.0,
        entry.1,
        self.system,
      )
      f(entry.0, component_ref)
    }
  }
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::iter_many(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  for entity in entities {
    if self.get(entity) is Some(value) {
      f(entity, value)
    }
  }
}

///|
pub fn[A : @json.FromJson, F : QueryFilter] Query1Filtered::iter_many_ref(
  self : Query1Filtered[A, F],
  entities : Array[@core.Entity],
  f : (@core.Entity, ComponentRef[A]) -> Unit,
) -> Unit raise EcsError {
  for entity in entities {
    if self.get_ref(entity) is Some(component_ref) {
      f(entity, component_ref)
    }
  }
}

///|
pub fn[A : ToJson + @json.FromJson, F : QueryFilter] Query1Filtered::for_each(
  self : Query1Filtered[A, F],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return
  }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  let writes : Array[(@core.Entity, Json)] = []
  for entry in entries {
    if QueryFilter::matches(self.filter, self.world, entry.0, self.system) {
      let value : A = self.world.decode_component_payload(
        self.key_a,
        entry.0,
        entry.1,
      )
      f(entry.0, value)
      writes.push((entry.0, value.to_json()))
    }
  }
  let tick = component_write_change_tick(self.world)
  for write in writes {
    store_ref.val.set(write.0, write.1, tick) |> ignore
  }
}

///|
pub fn[A, F : QueryFilter] Query1Filtered::count(
  self : Query1Filtered[A, F],
) -> Int {
  guard self.world.component_store(self.key_a.id()) is Some(store_ref) else {
    return 0
  }
  let counter = Ref::new(0)
  store_ref.val.for_each(fn(entity, _payload) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      counter.val = counter.val + 1
    }
  })
  counter.val
}

///|
pub fn[A : @json.FromJson] Query1::view(
  self : Query1[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_view(self.world, self.key_a, f)
}

///|
pub fn[A : ToJson + @json.FromJson, B : ToJson + @json.FromJson] Query2::for_each(
  self : Query2[A, B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each(self.world, self.key_a, self.key_b, f)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson] Query2::get(
  self : Query2[A, B],
  entity : @core.Entity,
) -> (A, B)? raise EcsError {
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  Some((value_a, value_b))
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson] Query2::view(
  self : Query2[A, B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_view(self.world, self.key_a, self.key_b, f)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, F : QueryFilter] Query2Filtered::get(
  self : Query2Filtered[A, B, F],
  entity : @core.Entity,
) -> (A, B)? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  Some((value_a, value_b))
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, F : QueryFilter] Query2Filtered::view(
  self : Query2Filtered[A, B, F],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each_intersection(self.world, self.key_a, self.key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      f(entity, value_a, value_b)
    }
  })
}

///|
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  F : QueryFilter,
] Query2Filtered::for_each(
  self : Query2Filtered[A, B, F],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json)] = []
  query2_for_each_intersection(self.world, self.key_a, self.key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      f(entity, value_a, value_b)
      writes.push((entity, value_a.to_json(), value_b.to_json()))
    }
  })
  let store_a_ref = self.world.ensure_component_store(self.key_a.id())
  let store_b_ref = self.world.ensure_component_store(self.key_b.id())
  let tick = component_write_change_tick(self.world)
  for write in writes {
    store_a_ref.val.set(write.0, write.1, tick) |> ignore
    store_b_ref.val.set(write.0, write.2, tick) |> ignore
  }
}

///|
pub fn[A, B, F : QueryFilter] Query2Filtered::count(
  self : Query2Filtered[A, B, F],
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
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  C : ToJson + @json.FromJson,
] Query3::for_each(
  self : Query3[A, B, C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each(self.world, self.key_a, self.key_b, self.key_c, f)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] Query3::get(
  self : Query3[A, B, C],
  entity : @core.Entity,
) -> (A, B, C)? raise EcsError {
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  guard self.world.get(entity, self.key_c) is Some(value_c) else { return None }
  Some((value_a, value_b, value_c))
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] Query3::view(
  self : Query3[A, B, C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_view(self.world, self.key_a, self.key_b, self.key_c, f)
}

///|
pub fn[
  A : @json.FromJson,
  B : @json.FromJson,
  C : @json.FromJson,
  F : QueryFilter,
] Query3Filtered::get(
  self : Query3Filtered[A, B, C, F],
  entity : @core.Entity,
) -> (A, B, C)? raise EcsError {
  guard QueryFilter::matches(self.filter, self.world, entity, self.system) else {
    return None
  }
  guard self.world.get(entity, self.key_a) is Some(value_a) else { return None }
  guard self.world.get(entity, self.key_b) is Some(value_b) else { return None }
  guard self.world.get(entity, self.key_c) is Some(value_c) else { return None }
  Some((value_a, value_b, value_c))
}

///|
pub fn[
  A : @json.FromJson,
  B : @json.FromJson,
  C : @json.FromJson,
  F : QueryFilter,
] Query3Filtered::view(
  self : Query3Filtered[A, B, C, F],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each_intersection(self.world, self.key_a, self.key_b, self.key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      f(entity, value_a, value_b, value_c)
    }
  })
}

///|
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  C : ToJson + @json.FromJson,
  F : QueryFilter,
] Query3Filtered::for_each(
  self : Query3Filtered[A, B, C, F],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json, Json)] = []
  query3_for_each_intersection(self.world, self.key_a, self.key_b, self.key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    if QueryFilter::matches(self.filter, self.world, entity, self.system) {
      f(entity, value_a, value_b, value_c)
      writes.push(
        (entity, value_a.to_json(), value_b.to_json(), value_c.to_json()),
      )
    }
  })
  let store_a_ref = self.world.ensure_component_store(self.key_a.id())
  let store_b_ref = self.world.ensure_component_store(self.key_b.id())
  let store_c_ref = self.world.ensure_component_store(self.key_c.id())
  let tick = component_write_change_tick(self.world)
  for write in writes {
    store_a_ref.val.set(write.0, write.1, tick) |> ignore
    store_b_ref.val.set(write.0, write.2, tick) |> ignore
    store_c_ref.val.set(write.0, write.3, tick) |> ignore
  }
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
    self.system,
  )
}

///|
pub fn[A : ToJson + @json.FromJson] query1(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1_for_each(world, key_a, f)
}

///|
pub fn[A : @json.FromJson] query1_view(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_ref) else { return }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    let value : A = world.decode_component_payload(key_a, entry.0, entry.1)
    f(entry.0, value)
  }
}

///|
pub fn[A : ToJson + @json.FromJson] query1_for_each(
  world : World,
  key_a : ComponentKey[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_ref) else { return }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  let writes : Array[(@core.Entity, Json)] = []
  for entry in entries {
    let value : A = world.decode_component_payload(key_a, entry.0, entry.1)
    f(entry.0, value)
    writes.push((entry.0, value.to_json()))
  }
  let tick = world.read_change_tick()
  for write in writes {
    store_ref.val.set(write.0, write.1, tick) |> ignore
  }
}

///|
pub fn[A : ToJson + @json.FromJson, B : ToJson + @json.FromJson] query2(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2_for_each(world, key_a, key_b, f)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson] query2_view(
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
pub fn[A : ToJson + @json.FromJson, B : ToJson + @json.FromJson] query2_for_each(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json)] = []
  query2_for_each_intersection(world, key_a, key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    f(entity, value_a, value_b)
    writes.push((entity, value_a.to_json(), value_b.to_json()))
  })
  let store_a_ref = world.ensure_component_store(key_a.id())
  let store_b_ref = world.ensure_component_store(key_b.id())
  let tick = world.read_change_tick()
  for write in writes {
    store_a_ref.val.set(write.0, write.1, tick) |> ignore
    store_b_ref.val.set(write.0, write.2, tick) |> ignore
  }
}

///|
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  C : ToJson + @json.FromJson,
] query3(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3_for_each(world, key_a, key_b, key_c, f)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] query3_view(
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
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  C : ToJson + @json.FromJson,
] query3_for_each(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json, Json)] = []
  query3_for_each_intersection(world, key_a, key_b, key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    f(entity, value_a, value_b, value_c)
    writes.push(
      (entity, value_a.to_json(), value_b.to_json(), value_c.to_json()),
    )
  })
  let store_a_ref = world.ensure_component_store(key_a.id())
  let store_b_ref = world.ensure_component_store(key_b.id())
  let store_c_ref = world.ensure_component_store(key_c.id())
  let tick = world.read_change_tick()
  for write in writes {
    store_a_ref.val.set(write.0, write.1, tick) |> ignore
    store_b_ref.val.set(write.0, write.2, tick) |> ignore
    store_c_ref.val.set(write.0, write.3, tick) |> ignore
  }
}

///|
fn[A : @json.FromJson, B : @json.FromJson] query2_for_each_intersection(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val

  if store_a.len() <= store_b.len() {
    let entries : Array[(@core.Entity, Json)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) {
        let value_a : A = world.decode_component_payload(
          key_a,
          entry.0,
          entry.1,
        )
        let value_b : B = world.decode_component_payload(
          key_b,
          entry.0,
          payload_b,
        )
        f(entry.0, value_a, value_b)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, Json)] = []
  store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) {
      let value_a : A = world.decode_component_payload(
        key_a,
        entry.0,
        payload_a,
      )
      let value_b : B = world.decode_component_payload(key_b, entry.0, entry.1)
      f(entry.0, value_a, value_b)
    }
  }
}

///|
fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] query3_for_each_intersection(
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

  if len_a <= len_b && len_a <= len_c {
    let entries : Array[(@core.Entity, Json)] = []
    store_a.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_b.get(entry.0) is Some(payload_b) &&
        store_c.get(entry.0) is Some(payload_c) {
        let value_a : A = world.decode_component_payload(
          key_a,
          entry.0,
          entry.1,
        )
        let value_b : B = world.decode_component_payload(
          key_b,
          entry.0,
          payload_b,
        )
        let value_c : C = world.decode_component_payload(
          key_c,
          entry.0,
          payload_c,
        )
        f(entry.0, value_a, value_b, value_c)
      }
    }
    return
  }

  if len_b <= len_a && len_b <= len_c {
    let entries : Array[(@core.Entity, Json)] = []
    store_b.for_each(fn(entity, payload) { entries.push((entity, payload)) })
    for entry in entries {
      if store_a.get(entry.0) is Some(payload_a) &&
        store_c.get(entry.0) is Some(payload_c) {
        let value_a : A = world.decode_component_payload(
          key_a,
          entry.0,
          payload_a,
        )
        let value_b : B = world.decode_component_payload(
          key_b,
          entry.0,
          entry.1,
        )
        let value_c : C = world.decode_component_payload(
          key_c,
          entry.0,
          payload_c,
        )
        f(entry.0, value_a, value_b, value_c)
      }
    }
    return
  }

  let entries : Array[(@core.Entity, Json)] = []
  store_c.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    if store_a.get(entry.0) is Some(payload_a) &&
      store_b.get(entry.0) is Some(payload_b) {
      let value_a : A = world.decode_component_payload(
        key_a,
        entry.0,
        payload_a,
      )
      let value_b : B = world.decode_component_payload(
        key_b,
        entry.0,
        payload_b,
      )
      let value_c : C = world.decode_component_payload(key_c, entry.0, entry.1)
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
  system : @core.SystemTicks,
) -> Int {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return 0 }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return 0 }
  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let counter = Ref::new(0)

  if store_a.len() <= store_b.len() {
    store_a.for_each(fn(entity, _payload) {
      if store_b.contains(entity) &&
        QueryFilter::matches(filter, world, entity, system) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  store_b.for_each(fn(entity, _payload) {
    if store_a.contains(entity) &&
      QueryFilter::matches(filter, world, entity, system) {
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
  system : @core.SystemTicks,
) -> Int {
  guard world.component_store(key_a.id()) is Some(store_a_ref) else { return 0 }
  guard world.component_store(key_b.id()) is Some(store_b_ref) else { return 0 }
  guard world.component_store(key_c.id()) is Some(store_c_ref) else { return 0 }

  let store_a = store_a_ref.val
  let store_b = store_b_ref.val
  let store_c = store_c_ref.val
  let counter = Ref::new(0)

  if store_a.len() <= store_b.len() && store_a.len() <= store_c.len() {
    store_a.for_each(fn(entity, _payload) {
      if store_b.contains(entity) &&
        store_c.contains(entity) &&
        QueryFilter::matches(filter, world, entity, system) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  if store_b.len() <= store_a.len() && store_b.len() <= store_c.len() {
    store_b.for_each(fn(entity, _payload) {
      if store_a.contains(entity) &&
        store_c.contains(entity) &&
        QueryFilter::matches(filter, world, entity, system) {
        counter.val = counter.val + 1
      }
    })
    return counter.val
  }

  store_c.for_each(fn(entity, _payload) {
    if store_a.contains(entity) &&
      store_b.contains(entity) &&
      QueryFilter::matches(filter, world, entity, system) {
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
fn[A : @json.FromJson] query_component_ref(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  system : @core.SystemTicks,
) -> ComponentRef[A]? raise EcsError {
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  Some(query_component_ref_from_payload(world, key, entity, payload, system))
}

///|
fn[A : @json.FromJson] query_component_ref_from_payload(
  world : World,
  key : ComponentKey[A],
  entity : @core.Entity,
  payload : Json,
  system : @core.SystemTicks,
) -> ComponentRef[A] raise EcsError {
  let value : A = world.decode_component_payload(key, entity, payload)
  let ticks = world.component(key).get_ticks(entity).unwrap()
  ComponentRef::{ value, ticks, system }
}
