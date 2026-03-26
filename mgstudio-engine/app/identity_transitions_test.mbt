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
struct TriggerIdentityOnce {
  mut done : Bool
}

///|
struct DespawnMarker {}

///|
let trigger_identity_once_resource_key : @ecs.ResourceKey[TriggerIdentityOnce] = @ecs.register_resource(
  debug_name="app::identity_transitions_test::TriggerIdentityOnce",
)

///|
let despawn_marker_key : @ecs.ComponentKey[DespawnMarker] = @ecs.register_component(
  debug_name="app::identity_transitions_test::DespawnMarker",
)

///|
impl Resource for TriggerIdentityOnce with resource() {
  trigger_identity_once_resource_key
}

///|
let transition_entries : Array[String] = []

///|
fn push_transition_entry(entry : String) -> Unit {
  transition_entries.push(entry)
}

///|
fn on_enter_a(_world : @ecs.World) -> Unit {
  push_transition_entry("enter")
}

///|
fn on_exit_a(_world : @ecs.World) -> Unit {
  push_transition_entry("exit")
}

///|
fn on_reenter_a(_world : @ecs.World) -> Unit {
  push_transition_entry("reenter")
}

///|
fn on_reexit_a(_world : @ecs.World) -> Unit {
  push_transition_entry("reexit")
}

///|
fn trigger_identity_transition_once(step : ResMut[TriggerIdentityOnce]) -> Unit {
  let step_ref = step.get_ref()
  guard !step_ref.val.done else { return }
  step_ref.val.done = true
  set_state(TestState::A)
}

///|
test "app identity transition: default enter and exit ignore same-state transitions" {
  transition_entries.clear()
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_resource(TriggerIdentityOnce::{ done: false })
    .insert_state(TestState::A)
    .add_on_enter_system(TestState::A, on_enter_a)
    .add_on_exit_system(TestState::A, on_exit_a)
    .add_on_reenter_system(TestState::A, on_reenter_a)
    .add_on_reexit_system(TestState::A, on_reexit_a)
    .add_systems(Update, system(system_param(trigger_identity_transition_once)))

  app.run_startup() |> ignore
  inspect(transition_entries, content="[\"enter\"]")
  transition_entries.clear()

  app.run_once() |> ignore
  app.run_once() |> ignore

  inspect(transition_entries, content="[\"reexit\", \"reenter\"]")
}

///|
test "app identity transition: DespawnOnExit removes scoped entities" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_resource(TriggerIdentityOnce::{ done: false })
    .insert_state(TestState::A)
    .add_systems(Update, system(system_param(trigger_identity_transition_once)))

  let entity = app.world().spawn_empty()
  app
  .world()
  .set_by_key(entity, ecs_key_despawn_on_exit, DespawnOnExit::new(TestState::A))
  app.world().set_by_key(entity, despawn_marker_key, DespawnMarker::{  })

  app.run_startup() |> ignore
  app.run_once() |> ignore
  app.run_once() |> ignore

  let result : Result[DespawnMarker?, @ecs.EcsError] = try? app
    .world()
    .get_by_key(entity, despawn_marker_key)
  inspect(result is Err(_), content="true")
}

///|
test "app identity transition: DespawnOnEnter removes scoped entities" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(TestState::B) }).run_if(
        in_state(TestState::A),
      ),
    )

  let entity = app.world().spawn_empty()
  app
  .world()
  .set_by_key(
    entity,
    ecs_key_despawn_on_enter,
    DespawnOnEnter::new(TestState::B),
  )
  app.world().set_by_key(entity, despawn_marker_key, DespawnMarker::{  })

  app.run_startup() |> ignore
  app.run_once() |> ignore
  app.run_once() |> ignore

  let result : Result[DespawnMarker?, @ecs.EcsError] = try? app
    .world()
    .get_by_key(entity, despawn_marker_key)
  inspect(result is Err(_), content="true")
}
