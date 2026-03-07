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
struct LocalCounter {
  mut value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
impl FromWorld for LocalCounter with from_world(_world) {
  { value: 0 }
}

///|
struct RemovedMarker {} derive(Eq, Show)

///|
let removed_marker_key : @ecs.ComponentKey[RemovedMarker] = @ecs.register_component(
  debug_name="tests.app.removed_marker",
)

///|
pub impl @ecs.Component for RemovedMarker with component() {
  removed_marker_key
}

///|
test "app: Local persists independently per system instance" {
  let seen_first : Array[Int] = []
  let seen_second : Array[Int] = []

  let mut app = App::new(@ecs.World::new())
    .add_system_param(fn(local_state : Local[LocalCounter]) {
      let state_ref = local_state.get_ref()
      state_ref.val.value = state_ref.val.value + 1
      seen_first.push(state_ref.val.value)
    })
    .add_system_param(fn(local_state : Local[LocalCounter]) {
      let state_ref = local_state.get_ref()
      state_ref.val.value = state_ref.val.value + 10
      seen_second.push(state_ref.val.value)
    })

  app = app.run_once()
  app = app.run_once()

  inspect(seen_first, content="[1, 2]")
  inspect(seen_second, content="[10, 20]")
}

///|
test "app: Local Array FromWorld starts empty and persists" {
  let lengths : Array[Int] = []

  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    local_state : Local[Array[Int]],
  ) {
    let state_ref = local_state.get_ref()
    state_ref.val.push(state_ref.val.length())
    lengths.push(state_ref.val.length())
  })

  app = app.run_once()
  app = app.run_once()

  inspect(lengths, content="[1, 2]")
}

///|
test "app: ParamSet2 keeps each nested SystemParam state independently" {
  let seen : Array[(Int, Int)] = []

  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    params : ParamSet2[Local[LocalCounter], Local[LocalCounter]],
  ) {
    let first = params.p0().get_ref()
    let second = params.p1().get_ref()
    first.val.value = first.val.value + 1
    second.val.value = second.val.value + 10
    seen.push((first.val.value, second.val.value))
  })

  app = app.run_once()
  app = app.run_once()

  inspect(seen, content="[(1, 10), (2, 20)]")
}

///|
test "app: RemovedComponents typed system param observes fresh removals" {
  let entity_ref : Ref[@core.Entity] = Ref::new(@core.Entity::placeholder())
  let observed_lengths : Array[Int] = []
  let observed_entities : Array[Bool] = []

  let mut app = App::new(@ecs.World::new())
    .add_startup_system(fn(world) {
      let entity = world.spawn()
      entity_ref.val = entity
      try! world.set(entity, removed_marker_key, RemovedMarker::{  })
    })
    .add_system(fn(world) {
      if !entity_ref.val.is_placeholder() {
        try! (world.remove(entity_ref.val, removed_marker_key) |> ignore)
      }
    })
    .add_system_param(fn(removed : @ecs.RemovedComponents[RemovedMarker]) {
      let entities = removed.read()
      observed_lengths.push(entities.length())
      if entities.length() > 0 {
        observed_entities.push(entities[0] == entity_ref.val)
      }
    })

  app = app.run_startup()
  app = app.run_once()
  app = app.run_once()

  inspect(observed_lengths, content="[1, 0]")
  inspect(observed_entities, content="[true]")
}
