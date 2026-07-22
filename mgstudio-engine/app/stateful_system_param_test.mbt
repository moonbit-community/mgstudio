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
} derive(Eq, Debug, ToJson, FromJson)

///|
impl FromWorld for LocalCounter with fn from_world(_world) {
  { value: 0 }
}

///|
struct RemovedMarker {} derive(Eq, Debug)

///|
let removed_marker_key : @ecs.ComponentKey[RemovedMarker] = @ecs.register_component(
  debug_name="tests.app.removed_marker",
)

///|
pub impl @ecs.Component for RemovedMarker with fn component() {
  removed_marker_key
}

///|
test "app: Local persists independently per system instance" {
  let seen_first : Array[Int] = []
  let seen_second : Array[Int] = []

  let lifecycle_world_38_0 = @ecs.World::new()
  defer lifecycle_world_38_0.close()
  let mut app = App::new(lifecycle_world_38_0)
    .add_system_param(fn(local_state : Local[LocalCounter]) {
      let state = local_state.get()
      state.value = state.value + 1
      local_state.set(state)
      seen_first.push(state.value)
    })
    .add_system_param(fn(local_state : Local[LocalCounter]) {
      let state = local_state.get()
      state.value = state.value + 10
      local_state.set(state)
      seen_second.push(state.value)
    })

  app = app.run_once()
  app = app.run_once()

  debug_inspect(seen_first, content="[1, 2]")
  debug_inspect(seen_second, content="[10, 20]")
}

///|
test "app: Local Array FromWorld starts empty and persists" {
  let lengths : Array[Int] = []

  let lifecycle_world_64_0 = @ecs.World::new()
  defer lifecycle_world_64_0.close()
  let mut app = App::new(lifecycle_world_64_0).add_system_param(fn(
    local_state : Local[Array[Int]],
  ) {
    let state = local_state.get()
    state.push(state.length())
    local_state.set(state)
    lengths.push(state.length())
  })

  app = app.run_once()
  app = app.run_once()

  debug_inspect(lengths, content="[1, 2]")
}

///|
test "app: Local primitive FromWorld defaults are available" {
  let seen_counters : Array[Int] = []
  let seen_elapsed_ok : Array[Bool] = []
  let seen_labels : Array[String] = []

  let lifecycle_world_83_0 = @ecs.World::new()
  defer lifecycle_world_83_0.close()
  let mut app = App::new(lifecycle_world_83_0).add_system_param3(fn(
    counter : Local[Int],
    elapsed : Local[Float],
    label : Local[String],
  ) {
    let next_counter = counter.get() + 1
    let next_elapsed = elapsed.get() + 0.5F
    let next_label = if label.get() == "" { "tick" } else { label.get() }
    counter.set(next_counter)
    elapsed.set(next_elapsed)
    label.set(next_label)
    seen_counters.push(next_counter)
    seen_elapsed_ok.push(next_elapsed == 0.5F || next_elapsed == 1.0F)
    seen_labels.push(next_label)
  })

  app = app.run_once()
  app = app.run_once()

  debug_inspect(seen_counters, content="[1, 2]")
  debug_inspect(seen_elapsed_ok, content="[true, true]")
  debug_inspect(seen_labels, content="[\"tick\", \"tick\"]")
}

///|
test "app: ParamSet2 keeps each nested SystemParam state independently" {
  let seen : Array[(Int, Int)] = []

  let lifecycle_world_113_0 = @ecs.World::new()
  defer lifecycle_world_113_0.close()
  let mut app = App::new(lifecycle_world_113_0).add_system_param(fn(
    params : ParamSet2[Local[LocalCounter], Local[LocalCounter]],
  ) {
    let first = params.p0()
    let second = params.p1()
    let first_state = first.get()
    let second_state = second.get()
    first_state.value = first_state.value + 1
    second_state.value = second_state.value + 10
    first.set(first_state)
    second.set(second_state)
    seen.push((first_state.value, second_state.value))
  })

  app = app.run_once()
  app = app.run_once()

  debug_inspect(seen, content="[(1, 10), (2, 20)]")
}

///|
#warnings("-unnecessary_annotation")
test "app: RemovedComponents typed system param observes fresh removals" {
  let entity_ref : Ref[@core.Entity] = Ref(@core.Entity::placeholder())
  let observed_lengths : Array[Int] = []
  let observed_entities : Array[Bool] = []

  let lifecycle_world_137_0 = @ecs.World::new()
  defer lifecycle_world_137_0.close()
  let mut app = App::new(lifecycle_world_137_0)
    .add_startup_system(fn(world) {
      let entity = world.spawn()
      entity_ref.val = entity
      try! world.set_by_key(entity, removed_marker_key, RemovedMarker::{  })
    })
    .add_system(fn(world) {
      if !entity_ref.val.is_placeholder() {
        try! (world.remove_by_key(entity_ref.val, removed_marker_key) |> ignore)
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

  debug_inspect(observed_lengths, content="[1, 0]")
  debug_inspect(observed_entities, content="[true]")
}
