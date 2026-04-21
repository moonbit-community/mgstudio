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
struct OneShotCounterResource {
  mut value : Int
} derive(Eq, Debug)

///|
let one_shot_counter_resource_key : @ecs.ResourceKey[OneShotCounterResource] = @ecs.register_resource(
  debug_name="tests.app.one_shot_counter_resource",
)

///|
pub impl Resource for OneShotCounterResource with resource() {
  one_shot_counter_resource_key
}

///|
test "app: world run_system_once supports system params" {
  let world = @ecs.World::new()
  world.insert_resource(one_shot_counter_resource_key, { value: 0 })

  try! run_system_once_param(world, fn(
    counter : ResMut[OneShotCounterResource],
  ) {
    counter.modify(fn(value) { value.value = value.value + 1 })
  })

  debug_inspect(
    try! world.get_resource(one_shot_counter_resource_key),
    content="Some({ value: 1 })",
  )
}

///|
test "app: registered systems preserve local state across runs" {
  let world = @ecs.World::new()
  world.insert_resource(one_shot_counter_resource_key, { value: 0 })

  let system_id = register_system_param2(world, fn(
    local_counter : Local[Int],
    counter : ResMut[OneShotCounterResource],
  ) {
    let next = local_counter.get() + 1
    local_counter.set(next)
    counter.modify(fn(value) { value.value = value.value + next })
  })

  try! run_system(world, system_id)
  try! run_system(world, system_id)

  debug_inspect(
    try! world.get_resource(one_shot_counter_resource_key),
    content="Some({ value: 3 })",
  )
}

///|
test "app: commands can register and run one-shot systems" {
  let world = @ecs.World::new()
  world.insert_resource(one_shot_counter_resource_key, { value: 0 })

  let mut app = App::new(world).add_system_param(fn(commands : Commands) {
    let system_id = commands.register_system_param(fn(
      counter : ResMut[OneShotCounterResource],
    ) {
      counter.modify(fn(value) { value.value = value.value + 1 })
    })
    commands.run_system(system_id)
  })

  app = app.run_once()

  debug_inspect(
    try! app.world().get_resource(one_shot_counter_resource_key),
    content="Some({ value: 1 })",
  )
}
