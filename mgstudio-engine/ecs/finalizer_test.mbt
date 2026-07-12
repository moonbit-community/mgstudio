// Copyright 2026 International Digital Economy Academy
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
struct FinalizerProbe {
  id : Int
}

///|
test "ecs: registered finalizers run exactly once on replacement removal and close" {
  let resource_finalized : Array[Int] = []
  let component_finalized : Array[Int] = []
  let resource_key = register_resource(
    debug_name="tests.ecs.finalizer_resource",
    finalizer=fn(value : FinalizerProbe) { resource_finalized.push(value.id) },
  )
  let component_key = register_component(
    debug_name="tests.ecs.finalizer_component",
    finalizer=fn(value : FinalizerProbe) { component_finalized.push(value.id) },
  )
  let world = World::new()

  world.insert_resource(resource_key, { id: 1 })
  world.insert_resource(resource_key, { id: 2 })
  ignore(world.remove_resource(resource_key))
  let first = world.spawn_empty()
  try! world.set_by_key(first, component_key, { id: 3 })
  try! world.set_by_key(first, component_key, { id: 4 })
  try! world.despawn(first)
  debug_inspect(resource_finalized, content="[1, 2]")
  debug_inspect(component_finalized, content="[3, 4]")

  world.insert_resource(resource_key, { id: 5 })
  let second = world.spawn_empty()
  try! world.set_by_key(second, component_key, { id: 6 })
  world.close()
  world.close()
  debug_inspect(resource_finalized, content="[1, 2, 5]")
  debug_inspect(component_finalized, content="[3, 4, 6]")
}
