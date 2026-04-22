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
test "component_store: insert/set/remove" {
  let entities = Entities::new()
  let e = entities.spawn()
  let store : ComponentStore[Int] = ComponentStore::new()
  store.insert(e, 1)
  debug_inspect(store.get(e).unwrap() == 1, content="true")
  debug_inspect(store.set(e, 2), content="true")
  debug_inspect(store.get(e).unwrap() == 2, content="true")
  debug_inspect(store.remove(e).unwrap() == 2, content="true")
  debug_inspect(store.contains(e), content="false")
}

///|
test "component_store: swap-remove keeps other entity accessible" {
  let entities = Entities::new()
  let e1 = entities.spawn()
  let e2 = entities.spawn()
  let store : ComponentStore[Int] = ComponentStore::new()
  store.insert(e1, 1)
  store.insert(e2, 2)
  store.remove(e1) |> ignore
  debug_inspect(store.get(e2).unwrap() == 2, content="true")
  debug_inspect(store.len() == 1, content="true")
}

///|
test "component_store: update and upsert" {
  let entities = Entities::new()
  let e = entities.spawn()
  let store : ComponentStore[Int] = ComponentStore::new()
  debug_inspect(!store.update(e, fn(v) { v + 1 }), content="true")
  store.upsert(e, 10)
  assert_true(store.get(e) is Some(10))
  debug_inspect(store.update(e, fn(v) { v + 5 }), content="true")
  assert_true(store.get(e) is Some(15))
}

///|
test "component_store: dense index access follows sparse-set order" {
  let entities = Entities::new()
  let e0 = entities.spawn()
  let e1 = entities.spawn()
  let store : ComponentStore[Int] = ComponentStore::new()
  store.insert(e0, 10)
  store.insert(e1, 20)
  debug_inspect(store.entity_at(0) == e0, content="true")
  debug_inspect(store.value_at(0) == 10, content="true")
  debug_inspect(store.entity_at(1) == e1, content="true")
  debug_inspect(store.value_at(1) == 20, content="true")
}
