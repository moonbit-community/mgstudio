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
struct Counter {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct BrokenCounter {
  value : String
} derive(Eq, Show, ToJson, FromJson)

///|
struct GlobalConfig {
  fps : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct TickEvent {
  frame : Int
} derive(Eq, Show, ToJson, FromJson)

///|
test "ecs: register key ids are monotonic" {
  let comp_a : ComponentKey[Counter] = register_component(debug_name="counter")
  let comp_b : ComponentKey[Counter] = register_component(
    debug_name="counter_b",
  )
  inspect(comp_b.id() > comp_a.id(), content="true")

  let res_a : ResourceKey[GlobalConfig] = register_resource(debug_name="cfg")
  let res_b : ResourceKey[GlobalConfig] = register_resource(debug_name="cfg_b")
  inspect(res_b.id() > res_a.id(), content="true")

  let event_a : EventKey[TickEvent] = register_event(debug_name="tick")
  let event_b : EventKey[TickEvent] = register_event(debug_name="tick_b")
  inspect(event_b.id() > event_a.id(), content="true")
}

///|
test "ecs: spawn set get update and despawn cleanup" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter",
  )
  let entity = world.spawn()

  try! world.set(entity, comp_counter, Counter::{ value: 3 })
  inspect(try! world.get(entity, comp_counter), content="Some({value: 3})")

  inspect(
    try! world.update(entity, comp_counter, fn(counter) {
      Counter::{ value: counter.value + 9 }
    }),
    content="true",
  )
  inspect(try! world.get(entity, comp_counter), content="Some({value: 12})")

  try! world.despawn(entity)
  inspect(world.is_alive(entity), content="false")
}

///|
test "ecs: decode failure includes context" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter_decode",
  )
  let comp_broken : ComponentKey[BrokenCounter] = comp_counter.cast()
  let entity = world.spawn()

  try! world.set(entity, comp_counter, Counter::{ value: 7 })

  let result : Result[BrokenCounter?, EcsError] = try? world.get(
    entity, comp_broken,
  )
  guard result is Err(ComponentDecodeFailed(key_id, _name, _entity, _)) else {
    fail("expected decode failure")
  }
  inspect(key_id == comp_counter.id(), content="true")
}

///|
test "ecs: dead entity fails fast" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter_dead",
  )
  let entity = world.spawn()
  try! world.despawn(entity)

  let set_result : Result[Unit, EcsError] = try? world.set(
    entity,
    comp_counter,
    Counter::{ value: 1 },
  )
  guard set_result is Err(EntityNotAlive(_)) else {
    fail("expected EntityNotAlive for set")
  }
}
