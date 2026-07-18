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
struct BypassFinalizerProbe {
  id : Int
}

///|
let bypass_finalized_values : Array[Int] = []

///|
let bypass_finalizer_probe_key : ComponentKey[BypassFinalizerProbe] = register_component(
  debug_name="tests.ecs.bypass_finalizer_component",
  finalizer=fn(value) { bypass_finalized_values.push(value.id) },
)

///|
pub impl Component for BypassFinalizerProbe with fn component() {
  bypass_finalizer_probe_key
}

///|
test "ecs: bypass change detection preserves same-reference ownership" {
  bypass_finalized_values.clear()
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, bypass_finalizer_probe_key, { id: 1 })
  let component = (try! world.get_mut(entity, key=bypass_finalizer_probe_key)).unwrap()

  component.bypass_change_detection(fn(value) { value })
  let finalized_before_close = bypass_finalized_values.length()
  world.close()

  debug_inspect(
    (finalized_before_close, bypass_finalized_values),
    content="(0, [1])",
  )
}

///|
test "ecs: bypass change detection finalizes a distinct replacement" {
  bypass_finalized_values.clear()
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, bypass_finalizer_probe_key, { id: 1 })
  let component = (try! world.get_mut(entity, key=bypass_finalizer_probe_key)).unwrap()

  component.bypass_change_detection(fn(_value) {
    BypassFinalizerProbe::{ id: 2 }
  })
  let finalized_before_close = bypass_finalized_values.copy()
  world.close()

  debug_inspect(
    (finalized_before_close, bypass_finalized_values),
    content="([1], [1, 2])",
  )
}

///|
test "ecs: finalizers distinguish value transfer from destruction" {
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
  defer world.close()

  world.insert_resource(resource_key, { id: 1 })
  world.insert_resource(resource_key, { id: 2 })
  let removed_resource = world.remove_resource(resource_key)
  debug_inspect(removed_resource.map(fn(value) { value.id }), content="Some(2)")
  let first = world.spawn_empty()
  try! world.set_by_key(first, component_key, { id: 3 })
  try! world.set_by_key(first, component_key, { id: 4 })
  try! world.despawn(first)
  let rejected = world.spawn_empty()
  try! world.despawn(rejected)
  try world.set_by_key(rejected, component_key, { id: 8 }) catch {
    EntityNotAlive(_) => ()
    _ => fail("expected stale entity insertion to be rejected")
  } noraise {
    _ => fail("expected stale entity insertion to fail")
  }
  debug_inspect(resource_finalized, content="[1]")
  debug_inspect(component_finalized, content="[3, 4, 8]")

  world.insert_resource(resource_key, { id: 5 })
  debug_inspect(world.drop_resource(resource_key), content="true")
  debug_inspect(resource_finalized, content="[1, 5]")
  world.insert_resource(resource_key, { id: 7 })
  let second = world.spawn_empty()
  try! world.set_by_key(second, component_key, { id: 6 })
  let transferred = world.spawn_empty()
  try! world.set_by_key(transferred, component_key, { id: 9 })
  debug_inspect(
    (try! world.take(transferred, component_key)).map(fn(value) { value.id }),
    content="Some(9)",
  )
  debug_inspect(component_finalized, content="[3, 4, 8]")
  world.close()
  world.close()
  debug_inspect(resource_finalized, content="[1, 5, 7]")
  debug_inspect(component_finalized, content="[3, 4, 8, 6]")
}
