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
struct AddedMarker {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
let added_marker_key : ComponentKey[AddedMarker] = register_component(
  debug_name="added_components_marker",
)

///|
pub impl Component for AddedMarker with component() {
  added_marker_key
}

///|
test "ecs added components: insert emits entity in tick range" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, added_marker_key, AddedMarker::{ value: 1 })

  let added = world
    .added_components(added_marker_key, @core.SystemSequence::new(0, 1))
    .read()
  debug_inspect(added.length(), content="1")
  debug_inspect(added[0] == entity, content="true")
}

///|
test "ecs added components: replace and update do not emit new add events" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, added_marker_key, AddedMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  debug_inspect(
    try! world.replace(entity, added_marker_key, AddedMarker::{ value: 2 }),
    content="true",
  )
  debug_inspect(
    try! world.update_by_key(entity, added_marker_key, fn(marker) {
      AddedMarker::{ value: marker.value + 1 }
    }),
    content="true",
  )

  let added = world
    .added_components(added_marker_key, @core.SystemSequence::new(1, 2))
    .read()
  debug_inspect(added.length(), content="0")
}

///|
test "ecs added components: remove then reinsert emits a fresh add event" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, added_marker_key, AddedMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  debug_inspect(
    try! world.remove_by_key(entity, added_marker_key),
    content="true",
  )
  world.advance_sequence() |> ignore
  try! world.set_by_key(entity, added_marker_key, AddedMarker::{ value: 3 })

  let added = world
    .added_components(added_marker_key, @core.SystemSequence::new(1, 2))
    .read()
  debug_inspect(added.length(), content="1")
  debug_inspect(added[0] == entity, content="true")
}
