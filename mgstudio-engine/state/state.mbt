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
/// State API boundary aligned with Bevy-style state responsibilities.
/// Runtime implementation is owned by `Milky2018/mgstudio/state/state`.

///|
pub type State[S] = @state_state.State[S]

///|
pub type NextState[S] = @state_state.NextState[S]

///|
pub type StateTransitionEvent[S] = @state_state.StateTransitionEvent[S]

///|
pub type StateTransitionSystems = @state_state.StateTransitionSystems

///|
pub type OnEnter[S] = @state_state.OnEnter[S]

///|
pub type OnExit[S] = @state_state.OnExit[S]

///|
pub type OnTransition[S] = @state_state.OnTransition[S]

///|
pub type OnReenter[S] = @state_state.OnReenter[S]

///|
pub type OnReexit[S] = @state_state.OnReexit[S]

///|
pub type DespawnOnExit = @state_state.DespawnOnExit

///|
pub type DespawnOnEnter = @state_state.DespawnOnEnter

///|
pub type OptionalStateSource[S] = @state_state.OptionalStateSource[S]

///|
pub type StatesPlugin = @state_state.StatesPlugin

///|
pub fn states_plugin(plugin : StatesPlugin) -> @app.Plugin[@ecs.World] {
  @state_state.states_plugin(plugin)
}

///|
pub fn[S : @app.States] insert_state_app(
  app : @app.App[@ecs.World],
  state : S,
) -> @app.App[@ecs.World] {
  @state_state.insert_state_app(app, state)
}

///|
pub fn[S : @app.States] in_state(state : S) -> (@ecs.World) -> Bool {
  @state_state.in_state(state)
}

///|
pub fn[S] optional_state(state : S) -> @app.OptionalStateSource[S] {
  @state_state.optional_state(state)
}

///|
pub fn[S : @app.States] state_changed(state : S) -> (@ecs.World) -> Bool {
  @state_state.state_changed(state)
}

///|
pub fn[S : @app.States] state_exists(state : S) -> (@ecs.World) -> Bool {
  @state_state.state_exists(state)
}

///|
pub fn[S : @app.States] state_resource_key(
  state : S,
) -> @ecs.ResourceKey[State[S]] {
  @state_state.state_resource_key(state)
}

///|
pub fn[S : @app.States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  @state_state.state_transition_event_resource_key(state)
}

///|
pub fn[S : @app.States] state_set_dependency_depth(state : S) -> Int {
  @state_state.state_set_dependency_depth(state)
}
