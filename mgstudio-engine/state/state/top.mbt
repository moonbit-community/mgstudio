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
// Bevy source: `bevy/crates/bevy_state/src/state/mod.rs`.

///|
pub type State[S] = @state_root.State[S]

///|
pub type NextState[S] = @state_root.NextState[S]

///|
pub type StateTransitionEvent[S] = @state_root.StateTransitionEvent[S]

///|
pub type StateTransitionSystems = @state_root.StateTransitionSystems

///|
pub type OnEnter[S] = @state_root.OnEnter[S]

///|
pub type OnExit[S] = @state_root.OnExit[S]

///|
pub type OnTransition[S] = @state_root.OnTransition[S]

///|
pub type OnReenter[S] = @state_root.OnReenter[S]

///|
pub type OnReexit[S] = @state_root.OnReexit[S]

///|
pub type DespawnOnExit = @state_root.DespawnOnExit

///|
pub type DespawnOnEnter = @state_root.DespawnOnEnter

///|
pub type OptionalStateSource[S] = @state_root.OptionalStateSource[S]

///|
pub type StatesPlugin = @state_root.StatesPlugin

///|
pub fn states_plugin(plugin : StatesPlugin) -> @app.Plugin[@ecs.World] {
  @state_root.states_plugin(plugin)
}

///|
pub fn[S : @app.States] insert_state_app(
  app : @app.App[@ecs.World],
  state : S,
) -> @app.App[@ecs.World] {
  @state_root.insert_state_app(app, state)
}

///|
pub fn[S : @app.States] in_state(state : S) -> (@ecs.World) -> Bool {
  @state_root.in_state(state)
}

///|
pub fn[S] optional_state(state : S) -> @state_root.OptionalStateSource[S] {
  @state_root.optional_state(state)
}

///|
pub fn[S : @app.States] state_changed(state : S) -> (@ecs.World) -> Bool {
  @state_root.state_changed(state)
}

///|
pub fn[S : @app.States] state_exists(state : S) -> (@ecs.World) -> Bool {
  @state_root.state_exists(state)
}

///|
pub fn[S : @app.States] state_resource_key(
  state : S,
) -> @ecs.ResourceKey[State[S]] {
  @state_root.state_resource_key(state)
}

///|
pub fn[S : @app.States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  @state_root.state_transition_event_resource_key(state)
}

///|
pub fn[S : @app.States] state_set_dependency_depth(state : S) -> Int {
  @state_root.state_set_dependency_depth(state)
}
