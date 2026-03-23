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
let typed_counter_key : ComponentKey[TypedCounter] = register_component(
  debug_name="typed_counter",
)

///|
let typed_marker_key : ComponentKey[TypedMarker] = register_component(
  debug_name="typed_marker",
)

///|
struct TypedCounter {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct TypedMarker {
  enabled : Bool
} derive(Eq, Show, ToJson, FromJson)

///|
pub impl Component for TypedCounter with component() {
  typed_counter_key
}

///|
pub impl Component for TypedMarker with component() {
  typed_marker_key
}

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
test "ecs: register_resource reuses stable id for repeated debug_name" {
  let res_a : ResourceKey[GlobalConfig] = register_resource(
    debug_name="stable_cfg",
  )
  let res_b : ResourceKey[GlobalConfig] = register_resource(
    debug_name="stable_cfg",
  )
  inspect(res_a.id() == res_b.id(), content="true")
}

///|
test "ecs: register_message reuses stable id for repeated debug_name" {
  let message_a : MessageKey[TickEvent] = register_message(
    debug_name="stable_tick_message",
  )
  let message_b : MessageKey[TickEvent] = register_message(
    debug_name="stable_tick_message",
  )
  inspect(message_a.id() == message_b.id(), content="true")
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
test "ecs: type mismatch includes context" {
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
  guard result is Err(ComponentTypeMismatch(key_id, _name, _entity, _actual)) else {
    fail("expected component type mismatch")
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

///|
test "ecs: typed component api uses component ownership" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let counter_key : ComponentKey[TypedCounter] = Component::component()
  let marker_key : ComponentKey[TypedMarker] = Component::component()

  inspect(counter_key.id() == typed_counter_key.id(), content="true")
  inspect(marker_key.id() == typed_marker_key.id(), content="true")

  try! world.set_component(e0, TypedCounter::{ value: 10 })
  try! world.set_component(e1, TypedCounter::{ value: 20 })
  try! world.set_component(e1, TypedMarker::{ enabled: true })

  let initial_counter : TypedCounter? = try! World::get_component(world, e0)
  inspect(initial_counter, content="Some({value: 10})")
  inspect(
    try! World::update_component(world, e0, fn(counter : TypedCounter) {
      TypedCounter::{ value: counter.value + 5 }
    }),
    content="true",
  )
  let updated_counter : TypedCounter? = try! World::get_component(world, e0)
  inspect(updated_counter, content="Some({value: 15})")

  let without_marker : Without[TypedMarker] = Without::new(marker_key)
  let filtered : Query1Filtered[TypedCounter, Without[TypedMarker]] = World::query1_typed_filtered(
    world, without_marker,
  )
  inspect(filtered.count(), content="1")
  inspect(try! filtered.get(e0), content="Some({value: 15})")
  inspect(try! filtered.get(e1), content="None")

  let tick = world.advance_sequence()
  ignore(tick)
  inspect(tick == 1, content="true")
  inspect(try! world.remove(e0, counter_key), content="true")
  let removed : Array[@core.Entity] = world
    .removed_components(counter_key, @core.SystemSequence::new(0, 1))
    .read()
  json_inspect(removed, content=[{ "id": 0, "generation": 1 }])
}
