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
struct ChangedMarker {
  mut value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
let changed_marker_key : ComponentKey[ChangedMarker] = register_component(
  debug_name="changed_components_marker",
)

///|
pub impl Component for ChangedMarker with component() {
  changed_marker_key
}

///|
test "ecs changed components: insert emits entity in tick range" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, changed_marker_key, ChangedMarker::{ value: 1 })

  let changed = world
    .changed_components(changed_marker_key, @core.SystemSequence::new(0, 1))
    .read()
  inspect(changed.length(), content="1")
  inspect(changed[0] == entity, content="true")
}

///|
test "ecs changed components: replace and update emit changed events" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, changed_marker_key, ChangedMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  inspect(
    try! world.replace(entity, changed_marker_key, ChangedMarker::{ value: 2 }),
    content="true",
  )
  inspect(
    try! world.update_by_key(entity, changed_marker_key, fn(marker) {
      ChangedMarker::{ value: marker.value + 1 }
    }),
    content="true",
  )

  let changed = world
    .changed_components(changed_marker_key, @core.SystemSequence::new(1, 2))
    .read()
  inspect(changed.contains(entity), content="true")
}

///|
test "ecs changed components: Mut::set emits changed event" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, changed_marker_key, ChangedMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  let maybe_mut = try! world.get_mut(entity, key=changed_marker_key)
  let item = match maybe_mut {
    Some(item) => item
    None => abort("expected mutable component")
  }
  item.set(ChangedMarker::{ value: 9 })

  let changed = world
    .changed_components(changed_marker_key, @core.SystemSequence::new(1, 2))
    .read()
  inspect(changed.contains(entity), content="true")
}

///|
test "ecs changed components: Mut::get_ref marks changed on mutable borrow" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, changed_marker_key, ChangedMarker::{ value: 1 })
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  let maybe_mut = try! world.get_mut(entity, key=changed_marker_key)
  let item = match maybe_mut {
    Some(item) => item
    None => abort("expected mutable component")
  }
  item.get_ref().val.value = 11

  let changed = world
    .changed_components(changed_marker_key, @core.SystemSequence::new(1, 2))
    .read()
  inspect(changed.contains(entity), content="true")
}
