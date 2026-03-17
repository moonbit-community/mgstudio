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
struct HookTestComponent {
  value : Int
} derive(Eq, Show)

///|
let hook_test_component_key : ComponentKey[HookTestComponent] = register_component(
  debug_name="tests.ecs.component_hooks.component",
)

///|
pub impl Component for HookTestComponent with component() {
  hook_test_component_key
}

///|
struct DuplicateHookTestComponent {} derive(Eq, Show)

///|
let duplicate_hook_test_component_key : ComponentKey[DuplicateHookTestComponent] = register_component(
  debug_name="tests.ecs.component_hooks.duplicate",
)

///|
pub impl Component for DuplicateHookTestComponent with component() {
  duplicate_hook_test_component_key
}

///|
struct LateRegistrationHookTestComponent {} derive(Eq, Show)

///|
let late_registration_hook_test_component_key : ComponentKey[
  LateRegistrationHookTestComponent,
] = register_component(debug_name="tests.ecs.component_hooks.late_registration")

///|
pub impl Component for LateRegistrationHookTestComponent with component() {
  late_registration_hook_test_component_key
}

///|
let hook_event_log_ref : Ref[Array[String]] = Ref::new([])

///|
let hook_entity_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let hook_component_id_matches_ref : Ref[Bool] = Ref::new(true)

///|
let hook_callers_present_ref : Ref[Bool] = Ref::new(true)

///|
let hook_callers_match_test_file_ref : Ref[Bool] = Ref::new(true)

///|
fn hook_test_reset() -> Unit {
  hook_event_log_ref.val.clear()
  hook_entity_ids_ref.val.clear()
  hook_component_id_matches_ref.val = true
  hook_callers_present_ref.val = true
  hook_callers_match_test_file_ref.val = true
}

///|
fn hook_test_value_text(world : World, entity : @core.Entity) -> String {
  let result : Result[HookTestComponent?, EcsError] = try? world.get(
    entity, hook_test_component_key,
  )
  match result {
    Ok(Some(component)) => component.value.to_string()
    Ok(None) => "none"
    Err(EntityNotAlive(_)) => "dead"
    Err(_) => "error"
  }
}

///|
fn hook_test_record(
  kind : String,
  world : World,
  context : HookContext,
) -> Unit {
  hook_event_log_ref.val.push(
    "\{kind}:\{hook_test_value_text(world, context.entity)}",
  )
  hook_entity_ids_ref.val.push(context.entity.id)
  if context.component_id != hook_test_component_key.id() {
    hook_component_id_matches_ref.val = false
  }
  match context.caller {
    Some(caller) =>
      if !caller.contains("component_hooks_test.mbt") {
        hook_callers_match_test_file_ref.val = false
      }
    None => {
      hook_callers_present_ref.val = false
      hook_callers_match_test_file_ref.val = false
    }
  }
}

///|
fn hook_test_install_hooks() -> Unit {
  let hooks = register_component_hooks_for_key(hook_test_component_key)
  ignore(
    try! hooks
    .on_add(fn(world, context) { hook_test_record("add", world, context) })
    .on_insert(fn(world, context) { hook_test_record("insert", world, context) })
    .on_replace(fn(world, context) {
      hook_test_record("replace", world, context)
    })
    .on_remove(fn(world, context) { hook_test_record("remove", world, context) })
    .on_despawn(fn(world, context) {
      hook_test_record("despawn", world, context)
    }),
  )
}

///|
fn init {
  hook_test_install_hooks()
}

///|
test "ecs component hooks: first insert fires add then insert with readable payload" {
  hook_test_reset()
  let world = World::new()
  let entity = world.spawn()

  try! world.set(entity, hook_test_component_key, HookTestComponent::{
    value: 1,
  })

  inspect(hook_event_log_ref.val, content="[\"add:1\", \"insert:1\"]")
  inspect(hook_entity_ids_ref.val, content="[0, 0]")
  inspect(hook_component_id_matches_ref.val, content="true")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
test "ecs component hooks: replace fires replace then insert around the new payload" {
  hook_test_reset()
  let world = World::new()
  let entity = world.spawn()

  try! world.set(entity, hook_test_component_key, HookTestComponent::{
    value: 1,
  })
  hook_test_reset()

  try! world.set(entity, hook_test_component_key, HookTestComponent::{
    value: 2,
  })

  inspect(hook_event_log_ref.val, content="[\"replace:1\", \"insert:2\"]")
  inspect(hook_entity_ids_ref.val, content="[0, 0]")
  inspect(hook_component_id_matches_ref.val, content="true")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
test "ecs component hooks: remove keeps the old payload visible through replace and remove" {
  hook_test_reset()
  let world = World::new()
  let entity = world.spawn()

  try! world.set(entity, hook_test_component_key, HookTestComponent::{
    value: 7,
  })
  hook_test_reset()

  inspect(try! world.remove(entity, hook_test_component_key), content="true")
  inspect(hook_event_log_ref.val, content="[\"replace:7\", \"remove:7\"]")
  inspect(hook_entity_ids_ref.val, content="[0, 0]")
  inspect(hook_component_id_matches_ref.val, content="true")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")
  inspect(try! world.get(entity, hook_test_component_key), content="None")
}

///|
test "ecs component hooks: despawn fires despawn replace remove before entity teardown" {
  hook_test_reset()
  let world = World::new()
  let entity = world.spawn()

  try! world.set(entity, hook_test_component_key, HookTestComponent::{
    value: 9,
  })
  hook_test_reset()

  try! world.despawn(entity)

  inspect(
    hook_event_log_ref.val,
    content="[\"despawn:9\", \"replace:9\", \"remove:9\"]",
  )
  inspect(hook_entity_ids_ref.val, content="[0, 0, 0]")
  inspect(hook_component_id_matches_ref.val, content="true")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")
  inspect(world.is_alive(entity), content="false")
}

///|
test "ecs component hooks: component access mutation paths preserve caller provenance" {
  hook_test_reset()
  let world = World::new()
  let entity = world.spawn()
  let access = world.component(hook_test_component_key)

  access.insert(
    entity,
    HookTestComponent::{ value: 3 },
    world.read_change_tick(),
  )

  inspect(hook_event_log_ref.val, content="[\"add:3\", \"insert:3\"]")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")

  hook_test_reset()
  ignore(access.remove(entity))
  inspect(hook_event_log_ref.val, content="[\"replace:3\", \"remove:3\"]")
  inspect(hook_callers_present_ref.val, content="true")
  inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
test "ecs component hooks: duplicate builder registration fails per hook kind" {
  ignore(DuplicateHookTestComponent::{  })
  let builder = register_component_hooks_for_key(
    duplicate_hook_test_component_key,
  )
  ignore(try! builder.on_add(fn(_world, _context) { () }))

  let duplicate_result : Result[
    ComponentHooksBuilder[DuplicateHookTestComponent],
    ComponentHooksError,
  ] = try? register_component_hooks_for_key(duplicate_hook_test_component_key).on_add(fn(
      _world,
      _context,
    ) {
      ()
    },
  )

  guard duplicate_result is Err(DuplicateHookRegistration(component_id, OnAdd)) else {
    fail("expected duplicate on_add registration failure")
  }
  inspect(
    component_id == duplicate_hook_test_component_key.id(),
    content="true",
  )
}

///|
test "ecs component hooks: world-scoped registration rejects components already in use" {
  ignore(LateRegistrationHookTestComponent::{  })
  let world0 = World::new()
  let world1 = World::new()
  let entity = world0.spawn()

  try! world0.set(entity, late_registration_hook_test_component_key, LateRegistrationHookTestComponent::{

  })

  let late_result : Result[
    ComponentHooksBuilder[LateRegistrationHookTestComponent],
    ComponentHooksError,
  ] = try? World::register_component_hooks_for_key(
    world0, late_registration_hook_test_component_key,
  )
  guard late_result is Err(ComponentAlreadyInUse(component_id)) else {
    fail("expected late component hook registration to be rejected")
  }
  inspect(
    component_id == late_registration_hook_test_component_key.id(),
    content="true",
  )

  let fresh_result : Result[
    ComponentHooksBuilder[LateRegistrationHookTestComponent],
    ComponentHooksError,
  ] = try? World::register_component_hooks_for_key(
    world1, late_registration_hook_test_component_key,
  )
  inspect(fresh_result is Ok(_), content="true")
}
