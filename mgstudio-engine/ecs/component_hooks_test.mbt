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
} derive(Eq, Debug)

///|
let hook_test_component_key : ComponentKey[HookTestComponent] = register_component(
  debug_name="tests.ecs.component_hooks.component",
)

///|
pub impl Component for HookTestComponent with fn component() {
  hook_test_component_key
}

///|
struct DuplicateHookTestComponent {} derive(Eq, Debug)

///|
let duplicate_hook_test_component_key : ComponentKey[DuplicateHookTestComponent] = register_component(
  debug_name="tests.ecs.component_hooks.duplicate",
)

///|
pub impl Component for DuplicateHookTestComponent with fn component() {
  duplicate_hook_test_component_key
}

///|
struct LateRegistrationHookTestComponent {} derive(Eq, Debug)

///|
let late_registration_hook_test_component_key : ComponentKey[
  LateRegistrationHookTestComponent,
] = register_component(debug_name="tests.ecs.component_hooks.late_registration")

///|
pub impl Component for LateRegistrationHookTestComponent with fn component() {
  late_registration_hook_test_component_key
}

///|
struct HookCommandsTestComponent {} derive(Eq, Debug)

///|
let hook_commands_test_component_key : ComponentKey[HookCommandsTestComponent] = register_component(
  debug_name="tests.ecs.component_hooks.deferred_commands",
)

///|
pub impl Component for HookCommandsTestComponent with fn component() {
  hook_commands_test_component_key
}

///|
struct HookRemoveCommandsTestComponent {} derive(Eq, Debug)

///|
let hook_remove_commands_test_component_key : ComponentKey[
  HookRemoveCommandsTestComponent,
] = register_component(
  debug_name="tests.ecs.component_hooks.deferred_remove_commands",
)

///|
pub impl Component for HookRemoveCommandsTestComponent with fn component() {
  hook_remove_commands_test_component_key
}

///|
struct HooksWithRegistrationTestComponent {} derive(Eq, Debug)

///|
let hooks_with_registration_test_component_key : ComponentKey[
  HooksWithRegistrationTestComponent,
] = register_component(debug_name="tests.ecs.component_hooks.with_registration")

///|
pub impl Component for HooksWithRegistrationTestComponent with fn component() {
  hooks_with_registration_test_component_key
}

///|
struct HooksWithLateRegistrationTestComponent {} derive(Eq, Debug)

///|
let hooks_with_late_registration_test_component_key : ComponentKey[
  HooksWithLateRegistrationTestComponent,
] = register_component(
  debug_name="tests.ecs.component_hooks.with_late_registration",
)

///|
pub impl Component for HooksWithLateRegistrationTestComponent with fn component() {
  hooks_with_late_registration_test_component_key
}

///|
let hook_event_log : Array[String] = []

///|
let hook_entity_ids : Array[Int] = []

///|
let hook_component_id_matches_ref : Ref[Bool] = Ref(true)

///|
let hook_callers_present_ref : Ref[Bool] = Ref(true)

///|
let hook_callers_match_test_file_ref : Ref[Bool] = Ref(true)

///|
fn hook_test_reset() -> Unit {
  hook_event_log.clear()
  hook_entity_ids.clear()
  hook_component_id_matches_ref.val = true
  hook_callers_present_ref.val = true
  hook_callers_match_test_file_ref.val = true
}

///|
fn hook_test_value_text(world : World, entity : @core.Entity) -> String {
  match
    (world.get_by_key(entity, hook_test_component_key) catch {
      EntityNotAlive(_) => return "dead"
      _ => return "error"
    }) {
    Some(component) => component.value.to_string()
    None => "none"
  }
}

///|
fn hook_test_record(
  kind : String,
  world : DeferredWorld,
  context : HookContext,
) -> Unit {
  hook_event_log.push(
    "\{kind}:\{hook_test_value_text(world.world(), context.entity())}",
  )
  hook_entity_ids.push(context.entity().id)
  let expected_component_id = world
    .world()
    .component_id_by_key(hook_test_component_key)
    .unwrap_or(-1)
  if context.component_id() != expected_component_id {
    hook_component_id_matches_ref.val = false
  }
  match context.caller() {
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
fn hook_test_install_hooks(world : World) -> Unit {
  let hooks = world.register_component_hooks_for_key(hook_test_component_key)
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
fn hook_commands_test_install_hooks(world : World) -> Unit {
  let hooks = world.register_component_hooks_for_key(
    hook_commands_test_component_key,
  )
  ignore(
    try! hooks.on_remove(fn(world, context) {
      world.commands().entity(context.entity()).despawn()
    }),
  )
}

///|
fn hook_remove_commands_test_install_hooks(world : World) -> Unit {
  let hooks = world.register_component_hooks_for_key(
    hook_remove_commands_test_component_key,
  )
  ignore(
    try! hooks.on_remove(fn(world, context) {
      world
      .commands()
      .entity(context.entity())
      .remove_by_key(hook_test_component_key)
    }),
  )
}

///|
test "ecs component hooks: first insert fires add then insert with readable payload" {
  hook_test_reset()
  let world = World::new(track_change_locations=true)
  defer world.close()
  hook_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 1 })

  debug_inspect(hook_event_log, content="[\"add:1\", \"insert:1\"]")
  debug_inspect(hook_entity_ids, content="[0, 0]")
  debug_inspect(hook_component_id_matches_ref.val, content="true")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
test "ecs component hooks: replace fires replace then insert around the new payload" {
  hook_test_reset()
  let world = World::new(track_change_locations=true)
  defer world.close()
  hook_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 1 })
  hook_test_reset()

  try! world.set_by_key(entity, hook_test_component_key, { value: 2 })

  debug_inspect(hook_event_log, content="[\"replace:1\", \"insert:2\"]")
  debug_inspect(hook_entity_ids, content="[0, 0]")
  debug_inspect(hook_component_id_matches_ref.val, content="true")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
test "ecs component hooks: remove keeps the old payload visible through replace and remove" {
  hook_test_reset()
  let world = World::new(track_change_locations=true)
  defer world.close()
  hook_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 7 })
  hook_test_reset()

  debug_inspect(
    try! world.remove_by_key(entity, hook_test_component_key),
    content="true",
  )
  debug_inspect(hook_event_log, content="[\"replace:7\", \"remove:7\"]")
  debug_inspect(hook_entity_ids, content="[0, 0]")
  debug_inspect(hook_component_id_matches_ref.val, content="true")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")
  debug_inspect(
    try! world.get_by_key(entity, hook_test_component_key),
    content="None",
  )
}

///|
test "ecs component hooks: despawn fires despawn replace remove before entity teardown" {
  hook_test_reset()
  let world = World::new(track_change_locations=true)
  defer world.close()
  hook_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 9 })
  hook_test_reset()

  try! world.despawn(entity)

  debug_inspect(
    hook_event_log,
    content="[\"despawn:9\", \"replace:9\", \"remove:9\"]",
  )
  debug_inspect(hook_entity_ids, content="[0, 0, 0]")
  debug_inspect(hook_component_id_matches_ref.val, content="true")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")
  debug_inspect(world.is_alive(entity), content="false")
}

///|
test "ecs component hooks: component access mutation paths preserve caller provenance" {
  hook_test_reset()
  let world = World::new(track_change_locations=true)
  defer world.close()
  hook_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 3 })

  debug_inspect(hook_event_log, content="[\"add:3\", \"insert:3\"]")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")

  hook_test_reset()
  ignore(try! world.take(entity, hook_test_component_key))
  debug_inspect(hook_event_log, content="[\"replace:3\", \"remove:3\"]")
  debug_inspect(hook_callers_present_ref.val, content="true")
  debug_inspect(hook_callers_match_test_file_ref.val, content="true")
}

///|
#warnings("-unnecessary_annotation")
test "ecs component hooks: deferred hook commands flush after callback" {
  let world = World::new()
  defer world.close()
  hook_commands_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_commands_test_component_key, HookCommandsTestComponent::{

  })
  debug_inspect(world.is_alive(entity), content="true")

  ignore(try! world.remove_by_key(entity, hook_commands_test_component_key))
  debug_inspect(world.is_alive(entity), content="false")
}

///|
#warnings("-unnecessary_annotation")
test "ecs component hooks: deferred remove commands flush after callback" {
  let world = World::new()
  defer world.close()
  hook_remove_commands_test_install_hooks(world)
  let entity = world.spawn()

  try! world.set_by_key(entity, hook_test_component_key, { value: 1 })
  try! world.set_by_key(entity, hook_remove_commands_test_component_key, HookRemoveCommandsTestComponent::{

  })
  debug_inspect(
    try! world.contains_by_key(entity, hook_test_component_key),
    content="true",
  )

  ignore(
    try! world.remove_by_key(entity, hook_remove_commands_test_component_key),
  )
  debug_inspect(
    try! world.contains_by_key(entity, hook_test_component_key),
    content="false",
  )
}

///|
test "ecs component hooks: duplicate builder registration fails per hook kind" {
  ignore(DuplicateHookTestComponent::{  })
  let world = World::new()
  defer world.close()
  let builder = world.register_component_hooks_for_key(
    duplicate_hook_test_component_key,
  )
  ignore(try! builder.on_add(fn(_world, _context) { () }))

  let duplicate_component_id = try {
    ignore(
      world
      .register_component_hooks_for_key(duplicate_hook_test_component_key)
      .on_add(fn(_world, _context) { () }),
    )
    -1
  } catch {
    DuplicateHookRegistration(component_id, OnAdd) => component_id
    _ => fail("expected duplicate on_add registration failure")
  }
  let expected_component_id = world
    .component_id_by_key(duplicate_hook_test_component_key)
    .unwrap_or(-1)
  debug_inspect(duplicate_component_id == expected_component_id, content="true")
}

///|
#warnings("-unnecessary_annotation")
test "ecs component hooks: world-scoped registration rejects late hooks and keeps worlds isolated" {
  ignore(LateRegistrationHookTestComponent::{  })
  let world0 = World::new()
  defer world0.close()
  let world1 = World::new()
  defer world1.close()
  let entity = world0.spawn()

  try! world0.set_by_key(entity, late_registration_hook_test_component_key, LateRegistrationHookTestComponent::{

  })

  let late_component_id = try {
    ignore(
      World::register_component_hooks_for_key(
        world0, late_registration_hook_test_component_key,
      ).on_add(fn(_world, _context) { () }),
    )
    -1
  } catch {
    ComponentAlreadyInUse(component_id) => component_id
    _ => fail("expected late hook registration in same world to fail")
  }
  let world0_component_id = world0
    .component_id_by_key(late_registration_hook_test_component_key)
    .unwrap_or(-1)
  debug_inspect(late_component_id == world0_component_id, content="true")

  let duplicate_component_id = try {
    ignore(
      World::register_component_hooks_for_key(
        world0, late_registration_hook_test_component_key,
      ).on_add(fn(_world, _context) { () }),
    )
    -1
  } catch {
    ComponentAlreadyInUse(component_id) => component_id
    _ => fail("expected repeated late hook registration in same world to fail")
  }
  debug_inspect(duplicate_component_id == world0_component_id, content="true")

  ignore(
    try! World::register_component_hooks_for_key(
      world1, late_registration_hook_test_component_key,
    ).on_add(fn(_world, _context) { () }),
  )
}

///|
test "ecs component hooks: register_component_hooks_with merges disjoint hooks and rejects duplicate kinds" {
  ignore(HooksWithRegistrationTestComponent::{  })
  let world = World::new()
  defer world.close()

  try! world.register_component_hooks_with(
    hooks_with_registration_test_component_key,
    ComponentHooks::new(on_add=Some(fn(_world, _context) { () })),
  )

  try! world.register_component_hooks_with(
    hooks_with_registration_test_component_key,
    ComponentHooks::new(on_remove=Some(fn(_world, _context) { () })),
  )

  let mut duplicate_component_id = -1
  world.register_component_hooks_with(
    hooks_with_registration_test_component_key,
    ComponentHooks::new(on_add=Some(fn(_world, _context) { () })),
  ) catch {
    DuplicateHookRegistration(component_id, OnAdd) =>
      duplicate_component_id = component_id
    _ => fail("expected duplicate hook kind registration to fail")
  }
  let expected_component_id = world
    .component_id_by_key(hooks_with_registration_test_component_key)
    .unwrap_or(-1)
  debug_inspect(duplicate_component_id == expected_component_id, content="true")
}

///|
#warnings("-unnecessary_annotation")
test "ecs component hooks: register_component_hooks_with enforces pre-use-only per world" {
  ignore(HooksWithLateRegistrationTestComponent::{  })
  let world0 = World::new()
  defer world0.close()
  let world1 = World::new()
  defer world1.close()
  let entity = world0.spawn()
  try! world0.set_by_key(
    entity,
    hooks_with_late_registration_test_component_key,
    HooksWithLateRegistrationTestComponent::{  },
  )

  let mut late_component_id = -1
  world0.register_component_hooks_with(
    hooks_with_late_registration_test_component_key,
    ComponentHooks::new(on_insert=Some(fn(_world, _context) { () })),
  ) catch {
    ComponentAlreadyInUse(component_id) => late_component_id = component_id
    _ => fail("expected late hook-with registration in same world to fail")
  }
  let world0_component_id = world0
    .component_id_by_key(hooks_with_late_registration_test_component_key)
    .unwrap_or(-1)
  debug_inspect(late_component_id == world0_component_id, content="true")

  try! world1.register_component_hooks_with(
    hooks_with_late_registration_test_component_key,
    ComponentHooks::new(on_insert=Some(fn(_world, _context) { () })),
  )
}
