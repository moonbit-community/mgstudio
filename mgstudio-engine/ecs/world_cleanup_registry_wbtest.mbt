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
test "ecs: World close releases every typed per-world storage" {
  let component_key : ComponentKey[Int] = register_component(
    debug_name="tests.ecs.cleanup.component",
  )
  let resource_key : ResourceKey[Int] = register_resource(
    debug_name="tests.ecs.cleanup.resource",
  )
  let event_key : EventKey[Int] = register_event(
    debug_name="tests.ecs.cleanup.event",
  )
  let world = World::new()
  let bootstrap_cleanup_count = world.cleanup_registry.entries.length()
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, component_key, 1)
  world.insert_resource(resource_key, 2)
  world.send_event(event_key, 3)
  debug_inspect(
    world.cleanup_registry.entries.length() - bootstrap_cleanup_count,
    content="3",
  )

  world.close()
  debug_inspect(world.cleanup_registry.entries.length(), content="0")
}
