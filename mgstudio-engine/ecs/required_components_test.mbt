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
struct RequiredA {} derive(Eq, Show, ToJson, FromJson)

///|
struct RequiredB {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct RequiredC {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct RequiredCounter {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
pub impl Default for RequiredB with default() {
  RequiredB::{ value: 10 }
}

///|
pub impl Default for RequiredC with default() {
  RequiredC::{ value: 20 }
}

///|
pub impl Default for RequiredCounter with default() {
  RequiredCounter::{ value: 0 }
}

///|
let required_a_key : ComponentKey[RequiredA] = register_component(
  debug_name="tests.required.a",
)

///|
let required_b_key : ComponentKey[RequiredB] = register_component(
  debug_name="tests.required.b",
)

///|
let required_c_key : ComponentKey[RequiredC] = register_component(
  debug_name="tests.required.c",
)

///|
let required_counter_key : ComponentKey[RequiredCounter] = register_component(
  debug_name="tests.required.counter",
)

///|
pub impl Component for RequiredA with component() {
  required_a_key
}

///|
pub impl Component for RequiredB with component() {
  required_b_key
}

///|
pub impl Component for RequiredC with component() {
  required_c_key
}

///|
pub impl Component for RequiredCounter with component() {
  required_counter_key
}

///|
test "ecs: required components insert recursively on set_component" {
  let world = World::new()
  let entity = world.spawn()

  try! world.register_required_components(required_a_key, required_b_key)
  try! world.register_required_components(required_b_key, required_c_key)
  try! world.set_component(entity, RequiredA::{  })

  inspect(try! world.get(entity, required_b_key), content="Some({value: 10})")
  inspect(try! world.get(entity, required_c_key), content="Some({value: 20})")
}

///|
test "ecs: direct required constructor overrides indirect constructor" {
  let world = World::new()
  let entity = world.spawn()

  try! world.register_required_components(required_a_key, required_b_key)
  try! world.register_required_components_with(
    required_b_key,
    required_counter_key,
    fn() { RequiredCounter::{ value: 1 } },
  )
  try! world.register_required_components_with(
    required_a_key,
    required_counter_key,
    fn() { RequiredCounter::{ value: 2 } },
  )
  try! world.set_component(entity, RequiredA::{  })

  inspect(
    try! world.get(entity, required_counter_key),
    content="Some({value: 2})",
  )
}

///|
test "ecs: explicit component value beats required insertion" {
  let world = World::new()
  let entity = world.spawn()

  try! world.register_required_components(required_a_key, required_b_key)
  try! world.set_component(entity, RequiredB::{ value: 99 })
  try! world.set_component(entity, RequiredA::{  })

  inspect(try! world.get(entity, required_b_key), content="Some({value: 99})")
}

///|
test "ecs: get_required_components returns recursive ids" {
  let world = World::new()

  try! world.register_required_components(required_a_key, required_b_key)
  try! world.register_required_components(required_b_key, required_c_key)

  let required = world.get_required_components(required_a_key).unwrap()
  inspect(required.len(), content="2")
  inspect(required.contains(required_b_key.id()), content="true")
  inspect(required.contains(required_c_key.id()), content="true")
}

///|
test "ecs: try register required components reports duplicate cycle and archetype usage" {
  let duplicate_world = World::new()
  try! duplicate_world.register_required_components(
    required_a_key, required_b_key,
  )
  let duplicate_result = duplicate_world.try_register_required_components(
    required_a_key, required_b_key,
  )
  guard duplicate_result is Err(DuplicateRegistration(a0, b0)) else {
    fail("expected duplicate registration error")
  }
  inspect(
    a0 == required_a_key.id() && b0 == required_b_key.id(),
    content="true",
  )

  let cycle_world = World::new()
  try! cycle_world.register_required_components(required_a_key, required_b_key)
  let cycle_result = cycle_world.try_register_required_components_with(
    required_b_key,
    required_a_key,
    fn() { RequiredA::{  } },
  )
  guard cycle_result is Err(CyclicRequirement(a1, b1)) else {
    fail("expected cyclic requirement error")
  }
  inspect(
    a1 == required_b_key.id() && b1 == required_a_key.id(),
    content="true",
  )

  let archetype_world = World::new()
  let entity = archetype_world.spawn()
  try! archetype_world.set_component(entity, RequiredA::{  })
  let archetype_result = archetype_world.try_register_required_components(
    required_a_key, required_b_key,
  )
  guard archetype_result is Err(ArchetypeExists(component_id)) else {
    fail("expected archetype exists error")
  }
  inspect(component_id == required_a_key.id(), content="true")
}
