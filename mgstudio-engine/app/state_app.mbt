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
#warnings("-unnecessary_annotation")
pub fn StatesPlugin::StatesPlugin() -> StatesPlugin {
  StatesPlugin::{  }
}

///|
priv struct StatesPluginMarker {}

///|
let states_plugin_marker_key : @ecs.ResourceKey[StatesPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_state::StatesPlugin",
)

///|
fn states_plugin_installed(world : @ecs.World) -> Bool {
  world.get_resource(states_plugin_marker_key) is Some(_)
}

///|
fn require_states_plugin_installed(world : @ecs.World) -> Unit {
  if !states_plugin_installed(world) {
    abort(
      "StatesPlugin is not installed. Add .add_plugins(@app.StatesPlugin::StatesPlugin()) before installing states.",
    )
  }
}

///|
pub impl Plugin for StatesPlugin with fn name(_self) {
  "mgstudio.app.StatesPlugin"
}

///|
#warnings("-unnecessary_annotation")
pub impl Plugin for StatesPlugin with fn build(_self, app) {
  main_schedule_insert_after_unique(app.world(), PreUpdate, StateTransition)
  main_schedule_insert_startup_before_unique(
    app.world(),
    PreStartup,
    StateTransition,
  )
  app
  .world()
  .insert_resource(states_plugin_marker_key, StatesPluginMarker::{  })
  app
}

///|
pub fn[S : States] insert_state_app(
  app : App[@ecs.World],
  state : S,
) -> App[@ecs.World] {
  require_states_plugin_installed(app.world())
  register_state_transition(state)
  app.world().insert_resource(state_resource_key(state), State::new(state))
  app.world().insert_resource(next_state_resource_key(state), Unchanged)
  enqueue_transition_event(app.world(), state, {
    exited: None,
    entered: Some(state),
    allow_same_state_transitions: true,
  })
  ignore(app.world().drop_resource(previous_state_resource_key(state)))
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
pub fn[S : States, P : SystemParam] App::add_on_enter_system_param(
  self : App[@ecs.World],
  state : S,
  system_fn : (P) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam] App::add_on_enter_system_param2(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param2(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_on_enter_system_param3(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param3(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_on_enter_system_param4(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param4(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] App::add_on_enter_system_param5(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4, P5) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param5(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] App::add_on_enter_system_param6(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4, P5, P6) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param6(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] App::add_on_enter_system_param7(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4, P5, P6, P7) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param7(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] App::add_on_enter_system_param8(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit,
) -> App[@ecs.World] {
  self.add_on_enter_system_config(state, system_config_param8(system_fn))
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
pub fn[S : States, P : SystemParam] App::add_on_exit_system_param(
  self : App[@ecs.World],
  state : S,
  system_fn : (P) -> Unit,
) -> App[@ecs.World] {
  self.add_on_exit_system_config(state, system_config_param(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam] App::add_on_exit_system_param2(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2) -> Unit,
) -> App[@ecs.World] {
  self.add_on_exit_system_config(state, system_config_param2(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_on_exit_system_param3(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.add_on_exit_system_config(state, system_config_param3(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_on_exit_system_param4(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.add_on_exit_system_config(state, system_config_param4(system_fn))
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

///|
pub fn[S : States, P : SystemParam] App::add_on_transition_system_param(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  system_fn : (P) -> Unit,
) -> App[@ecs.World] {
  self.add_on_transition_system_config(
    exited,
    entered,
    system_config_param(system_fn),
  )
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam] App::add_on_transition_system_param2(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  system_fn : (P1, P2) -> Unit,
) -> App[@ecs.World] {
  self.add_on_transition_system_config(
    exited,
    entered,
    system_config_param2(system_fn),
  )
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_on_transition_system_param3(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  system_fn : (P1, P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.add_on_transition_system_config(
    exited,
    entered,
    system_config_param3(system_fn),
  )
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_on_transition_system_param4(
  self : App[@ecs.World],
  exited : S,
  entered : S,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.add_on_transition_system_config(
    exited,
    entered,
    system_config_param4(system_fn),
  )
}

///|
pub fn[S : States] App::add_on_reenter_system_config(
  self : App[@ecs.World],
  state : S,
  config : SystemConfig[@ecs.World],
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_state_transition(state)
  register_on_reenter_system(state, config)
  self
}

///|
pub fn[S : States] App::add_on_reenter_system(
  self : App[@ecs.World],
  state : S,
  system_fn : SystemFn[@ecs.World],
) -> App[@ecs.World] {
  self.add_on_reenter_system_config(state, system(system_fn))
}

///|
pub fn[S : States, P : SystemParam] App::add_on_reenter_system_param(
  self : App[@ecs.World],
  state : S,
  system_fn : (P) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reenter_system_config(state, system_config_param(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam] App::add_on_reenter_system_param2(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reenter_system_config(state, system_config_param2(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_on_reenter_system_param3(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reenter_system_config(state, system_config_param3(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_on_reenter_system_param4(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reenter_system_config(state, system_config_param4(system_fn))
}

///|
pub fn[S : States] App::add_on_reexit_system_config(
  self : App[@ecs.World],
  state : S,
  config : SystemConfig[@ecs.World],
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_state_transition(state)
  register_on_reexit_system(state, config)
  self
}

///|
pub fn[S : States] App::add_on_reexit_system(
  self : App[@ecs.World],
  state : S,
  system_fn : SystemFn[@ecs.World],
) -> App[@ecs.World] {
  self.add_on_reexit_system_config(state, system(system_fn))
}

///|
pub fn[S : States, P : SystemParam] App::add_on_reexit_system_param(
  self : App[@ecs.World],
  state : S,
  system_fn : (P) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reexit_system_config(state, system_config_param(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam] App::add_on_reexit_system_param2(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reexit_system_config(state, system_config_param2(system_fn))
}

///|
pub fn[S : States, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_on_reexit_system_param3(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reexit_system_config(state, system_config_param3(system_fn))
}

///|
pub fn[
  S : States,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_on_reexit_system_param4(
  self : App[@ecs.World],
  state : S,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.add_on_reexit_system_config(state, system_config_param4(system_fn))
}
