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
pub fn[A : @json.FromJson] Query1::for_each(
  self : Query1[A],
  f : (@core.Entity, A) -> Unit,
) -> Unit raise EcsError {
  query1(self.world, self.key_a, f)
}

///|
pub fn[A : ToJson + @json.FromJson] Query1::update(
  self : Query1[A],
  update : (@core.Entity, A) -> A,
) -> Unit raise EcsError {
  query1_update(self.world, self.key_a, update)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson] Query2::for_each(
  self : Query2[A, B],
  f : (@core.Entity, A, B) -> Unit,
) -> Unit raise EcsError {
  query2(self.world, self.key_a, self.key_b, f)
}

///|
pub fn[A : ToJson + @json.FromJson, B : ToJson + @json.FromJson] Query2::update(
  self : Query2[A, B],
  update : (@core.Entity, A, B) -> (A, B),
) -> Unit raise EcsError {
  query2_update(self.world, self.key_a, self.key_b, update)
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] Query3::for_each(
  self : Query3[A, B, C],
  f : (@core.Entity, A, B, C) -> Unit,
) -> Unit raise EcsError {
  query3(self.world, self.key_a, self.key_b, self.key_c, f)
}

///|
pub fn[
  A : ToJson + @json.FromJson,
  B : ToJson + @json.FromJson,
  C : ToJson + @json.FromJson,
] Query3::update(
  self : Query3[A, B, C],
  update : (@core.Entity, A, B, C) -> (A, B, C),
) -> Unit raise EcsError {
  query3_update(self.world, self.key_a, self.key_b, self.key_c, update)
}

///|
pub fn[A : @json.FromJson] query1(
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
pub fn[A : ToJson + @json.FromJson] query1_update(
  world : World,
  key_a : ComponentKey[A],
  update : (@core.Entity, A) -> A,
) -> Unit raise EcsError {
  guard world.component_store(key_a.id()) is Some(store_ref) else { return }
  let entries : Array[(@core.Entity, Json)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  let writes : Array[(@core.Entity, Json)] = []
  for entry in entries {
    let value : A = world.decode_component_payload(key_a, entry.0, entry.1)
    let next = update(entry.0, value)
    writes.push((entry.0, next.to_json()))
  }
  for write in writes {
    store_ref.val.set(write.0, write.1, world.read_change_tick()) |> ignore
  }
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson] query2(
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
pub fn[A : ToJson + @json.FromJson, B : ToJson + @json.FromJson] query2_update(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  update : (@core.Entity, A, B) -> (A, B),
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json)] = []
  query2_for_each_intersection(world, key_a, key_b, fn(
    entity,
    value_a,
    value_b,
  ) {
    let next = update(entity, value_a, value_b)
    writes.push((entity, next.0.to_json(), next.1.to_json()))
  })
  let store_a_ref = world.ensure_component_store(key_a.id())
  let store_b_ref = world.ensure_component_store(key_b.id())
  for write in writes {
    store_a_ref.val.set(write.0, write.1, world.read_change_tick()) |> ignore
    store_b_ref.val.set(write.0, write.2, world.read_change_tick()) |> ignore
  }
}

///|
pub fn[A : @json.FromJson, B : @json.FromJson, C : @json.FromJson] query3(
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
] query3_update(
  world : World,
  key_a : ComponentKey[A],
  key_b : ComponentKey[B],
  key_c : ComponentKey[C],
  update : (@core.Entity, A, B, C) -> (A, B, C),
) -> Unit raise EcsError {
  let writes : Array[(@core.Entity, Json, Json, Json)] = []
  query3_for_each_intersection(world, key_a, key_b, key_c, fn(
    entity,
    value_a,
    value_b,
    value_c,
  ) {
    let next = update(entity, value_a, value_b, value_c)
    writes.push((entity, next.0.to_json(), next.1.to_json(), next.2.to_json()))
  })
  let store_a_ref = world.ensure_component_store(key_a.id())
  let store_b_ref = world.ensure_component_store(key_b.id())
  let store_c_ref = world.ensure_component_store(key_c.id())
  for write in writes {
    store_a_ref.val.set(write.0, write.1, world.read_change_tick()) |> ignore
    store_b_ref.val.set(write.0, write.2, world.read_change_tick()) |> ignore
    store_c_ref.val.set(write.0, write.3, world.read_change_tick()) |> ignore
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
