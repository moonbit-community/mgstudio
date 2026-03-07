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
pub struct StatesPlugin {}

///|
pub fn StatesPlugin::default() -> StatesPlugin {
  StatesPlugin::{  }
}

///|
priv struct StatesPluginMarker {}

///|
fn states_plugin_marker_key() -> @ecs.ResourceKey[StatesPluginMarker] {
  @ecs.register_resource(debug_name="bevy_state::StatesPlugin")
}

///|
fn states_plugin_installed(world : @ecs.World) -> Bool {
  try world.get_resource(states_plugin_marker_key()) catch {
    _ => false
  } noraise {
    value => value is Some(_)
  }
}

///|
fn require_states_plugin_installed(world : @ecs.World) -> Unit {
  if !states_plugin_installed(world) {
    abort(
      "StatesPlugin is not installed. Add @app.states_plugin(@app.StatesPlugin::default()) before installing states.",
    )
  }
}

///|
fn state_insert_change_tick(world : @ecs.World) -> @core.Tick {
  world.read_change_tick() + 1
}

///|
pub fn states_plugin(plugin : StatesPlugin) -> Plugin[@ecs.World] {
  ignore(plugin)
  fn(app : App[@ecs.World]) {
    let change_tick = state_insert_change_tick(app.world())
    main_schedule_insert_after_unique(
      app.world(),
      PreUpdate,
      StateTransition,
      change_tick,
    )
    main_schedule_insert_startup_before_unique(
      app.world(),
      PreStartup,
      StateTransition,
      change_tick,
    )
    app
    .world()
    .insert_resource(states_plugin_marker_key(), StatesPluginMarker::{  })
    app
  }
}

///|
pub fn[S : States] insert_state_app(
  app : App[@ecs.World],
  state : S,
) -> App[@ecs.World] {
  require_states_plugin_installed(app.world())
  register_state_transition(state)
  let change_tick = state_insert_change_tick(app.world())
  app
  .world()
  .insert_resource_with_change_tick(
    state_resource_key(state),
    State::new(state),
    change_tick,
  )
  app
  .world()
  .insert_resource_with_change_tick(
    next_state_resource_key(state),
    NextState::Unchanged,
    change_tick,
  )
  enqueue_transition_event(app.world(), state, StateTransitionEvent::{
    exited: None,
    entered: Some(state),
    allow_same_state_transitions: true,
  })
  let _ : Result[PreviousState[S]?, @ecs.EcsError] = try? app
    .world()
    .remove_resource(previous_state_resource_key(state))
  app
}

///|
pub fn[S : States] App::insert_state(
  self : App[@ecs.World],
  state : S,
) -> App[@ecs.World] {
  insert_state_app(self, state)
}

///|
pub fn[S : States] App::add_on_enter_system_config(
  self : App[@ecs.World],
  state : S,
  config : SystemConfig[@ecs.World],
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_state_transition(state)
  register_on_enter_system(state, config)
  self
}

///|
pub fn[S : States] App::add_on_enter_system(
  self : App[@ecs.World],
  state : S,
  system_fn : SystemFn[@ecs.World],
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system(system_fn))
}

///|
pub fn[S : States] App::add_on_exit_system_config(
  self : App[@ecs.World],
  state : S,
  config : SystemConfig[@ecs.World],
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_state_transition(state)
  register_on_exit_system(state, config)
  self
}

///|
pub fn[S : States] App::add_on_exit_system(
  self : App[@ecs.World],
  state : S,
  system_fn : SystemFn[@ecs.World],
) -> App[@ecs.World] {
  self.add_on_exit_system_config(state, system(system_fn))
}

///|
pub fn[S : States] App::add_on_transition_system_config(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  config : SystemConfig[@ecs.World],
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_state_transition(exited)
  register_on_transition_system(exited, entered, config)
  self
}

///|
pub fn[S : States] App::add_on_transition_system(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  system_fn : SystemFn[@ecs.World],
) -> App[@ecs.World] {
  self.add_on_transition_system_config(exited, entered, system(system_fn))
}
