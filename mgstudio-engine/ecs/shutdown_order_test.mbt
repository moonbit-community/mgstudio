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
test "ecs: shutdown hooks run after resource and component finalizers" {
  let order : Array[Int] = []
  let resource_key = register_resource(
    debug_name="tests.ecs.shutdown_order_resource",
    finalizer=fn(_value : Unit) { order.push(1) },
  )
  let component_key = register_component(
    debug_name="tests.ecs.shutdown_order_component",
    finalizer=fn(_value : Unit) { order.push(2) },
  )
  let world = World::new()
  world.insert_resource(resource_key, ())
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, component_key, ())
  world.add_shutdown_hook(fn(_world) { order.push(3) })

  world.close()
  debug_inspect(order, content="[1, 2, 3]")
}
