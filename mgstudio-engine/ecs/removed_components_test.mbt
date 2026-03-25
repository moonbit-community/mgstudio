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
struct TestMarker {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
test "ecs removed components: remove emits entity in tick range" {
  let world = World::new()
  let key : ComponentKey[TestMarker] = register_component(
    debug_name="removed_components_remove",
  )
  let entity = world.spawn()

  try! world.set_by_key(entity, key, TestMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  inspect(try! world.remove_by_key(entity, key), content="true")

  let removed = world
    .removed_components(key, @core.SystemSequence::new(0, 1))
    .read()
  inspect(removed.length(), content="1")
  inspect(removed[0] == entity, content="true")
}

///|
test "ecs removed components: despawn emits removed entity for attached component" {
  let world = World::new()
  let key : ComponentKey[TestMarker] = register_component(
    debug_name="removed_components_despawn",
  )
  let entity = world.spawn()

  try! world.set_by_key(entity, key, TestMarker::{ value: 7 })
  world.advance_sequence() |> ignore
  try! world.despawn(entity)

  let removed = world
    .removed_components(key, @core.SystemSequence::new(0, 1))
    .read()
  inspect(removed.length(), content="1")
  inspect(removed[0] == entity, content="true")
}

///|
test "ecs removed components: len, is_empty and clear match unread messages" {
  let world = World::new()
  let key : ComponentKey[TestMarker] = register_component(
    debug_name="removed_components_len_clear",
  )
  let entity0 = world.spawn()
  let entity1 = world.spawn()

  try! world.set_by_key(entity0, key, TestMarker::{ value: 1 })
  try! world.set_by_key(entity1, key, TestMarker::{ value: 2 })
  world.advance_sequence() |> ignore
  inspect(try! world.remove_by_key(entity0, key), content="true")
  inspect(try! world.remove_by_key(entity1, key), content="true")

  let removed = world.removed_components(key, @core.SystemSequence::new(0, 1))
  inspect(removed.len(), content="2")
  inspect(removed.is_empty(), content="false")
  removed.clear()
  inspect(removed.len(), content="0")
  inspect(removed.is_empty(), content="true")
  inspect(removed.read().length(), content="0")
}
