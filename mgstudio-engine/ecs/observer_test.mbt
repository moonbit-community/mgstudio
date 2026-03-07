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
struct ObserverMarker {
  value : Int
} derive(Eq, Show)

///|
let observer_marker_key : ComponentKey[ObserverMarker] = register_component(
  debug_name="tests.ecs.observer.marker",
)

///|
pub impl Component for ObserverMarker with component() {
  observer_marker_key
}

///|
test "ecs observer: world add_observer is world-scoped and fires on replace" {
  let world0 = World::new()
  let world1 = World::new()
  let seen_entities : Array[Int] = []
  let first_hits : Ref[Int] = Ref::new(0)
  let second_hits : Ref[Int] = Ref::new(0)
  let captured_world_id : Ref[Int] = Ref::new(-1)

  let first_handle = world0.add_observer(fn(
    event : On[Insert, ObserverMarker],
  ) {
    first_hits.val = first_hits.val + 1
    seen_entities.push(event.entity.id)
    captured_world_id.val = current_observer_world_abort_missing().world_id()
  })
  ignore(
    world0.add_observer(fn(_event : On[Insert, ObserverMarker]) {
      second_hits.val = second_hits.val + 1
    }),
  )

  let entity0 = world0.spawn()
  let entity1 = world1.spawn()

  try! world0.set(entity0, observer_marker_key, ObserverMarker::{ value: 1 })
  try! world0.set(entity0, observer_marker_key, ObserverMarker::{ value: 2 })
  try! world1.set(entity1, observer_marker_key, ObserverMarker::{ value: 3 })

  inspect(first_handle.world_id() == world0.world_id(), content="true")
  inspect(first_handle.id() > 0, content="true")
  inspect(first_hits.val, content="2")
  inspect(second_hits.val, content="2")
  inspect(seen_entities, content="[0, 0]")
  inspect(captured_world_id.val == world0.world_id(), content="true")
}
