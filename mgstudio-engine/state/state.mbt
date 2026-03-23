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
/// Runtime implementation currently lives in `Milky2018/mgstudio/app`.

///|
pub type State[S] = @app.State[S]

///|
pub type NextState[S] = @app.NextState[S]

///|
pub type StateTransitionEvent[S] = @app.StateTransitionEvent[S]

///|
pub type StateTransitionSystems = @app.StateTransitionSystems

///|
pub type OnEnter[S] = @app.OnEnter[S]

///|
pub type OnExit[S] = @app.OnExit[S]

///|
pub type OnTransition[S] = @app.OnTransition[S]

///|
pub type OnReenter[S] = @app.OnReenter[S]

///|
pub type OnReexit[S] = @app.OnReexit[S]

///|
pub type DespawnOnExit = @app.DespawnOnExit

///|
pub type DespawnOnEnter = @app.DespawnOnEnter

///|
pub type OptionalStateSource[S] = @app.OptionalStateSource[S]

///|
pub type StatesPlugin = @app.StatesPlugin

///|
pub fn states_plugin(plugin : StatesPlugin) -> @app.Plugin[@ecs.World] {
  @app.states_plugin(plugin)
}

///|
pub fn[S : @app.States] insert_state_app(
  app : @app.App[@ecs.World],
  state : S,
) -> @app.App[@ecs.World] {
  @app.insert_state_app(app, state)
}

///|
pub fn[S : @app.States] in_state(state : S) -> (@ecs.World) -> Bool {
  @app.in_state(state)
}

///|
pub fn[S : @app.States] optional_state(
  state : S,
) -> @app.OptionalStateSource[S] {
  @app.optional_state(state)
}

///|
pub fn[S : @app.States] state_changed(state : S) -> (@ecs.World) -> Bool {
  @app.state_changed(state)
}

///|
pub fn[S : @app.States] state_exists(state : S) -> (@ecs.World) -> Bool {
  @app.state_exists(state)
}

///|
pub fn[S : @app.States] state_resource_key(
  state : S,
) -> @ecs.ResourceKey[State[S]] {
  @app.state_resource_key(state)
}

///|
pub fn[S : @app.States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  @app.state_transition_event_resource_key(state)
}

///|
pub fn[S : @app.States] state_set_dependency_depth(state : S) -> Int {
  @app.state_set_dependency_depth(state)
}
