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
pub struct State[S] {
  value : S
} derive(Eq, Debug)

///|
pub fn[S] State::new(state : S) -> State[S] {
  { value: state }
}

///|
pub fn[S] State::get(self : State[S]) -> S {
  self.value
}

///|
pub struct PreviousState[S] {
  value : S
} derive(Eq, Debug)

///|
pub fn[S] PreviousState::get(self : PreviousState[S]) -> S {
  self.value
}

///|
pub(all) enum NextState[S] {
  Unchanged
  Pending(S)
  PendingIfNeq(S)
} derive(Eq, Debug)

///|
pub struct StateTransitionEvent[S] {
  exited : S?
  entered : S?
  allow_same_state_transitions : Bool
} derive(Eq, Debug)

///|
pub struct StateResourceKeys[S] {
  state : @ecs.ResourceKey[State[S]]
  previous_state : @ecs.ResourceKey[PreviousState[S]]
  next_state : @ecs.ResourceKey[NextState[S]]
  state_transition_event : @ecs.ResourceKey[StateTransitionEvent[S]]
  pending_state_transition_event : @ecs.ResourceKey[StateTransitionEvent[S]]
}

///|
fn[S : States] state_type_debug_name(state : S) -> String {
  ignore(state)
  S::type_debug_name()
}

///|
pub fn[S] register_state_resource_keys(
  type_debug_name : String,
) -> StateResourceKeys[S] {
  {
    state: @ecs.register_resource(
      debug_name="mgstudio_state::State<\{type_debug_name}>",
    ),
    previous_state: @ecs.register_resource(
      debug_name="mgstudio_state::PreviousState<\{type_debug_name}>",
    ),
    next_state: @ecs.register_resource(
      debug_name="mgstudio_state::NextState<\{type_debug_name}>",
    ),
    state_transition_event: @ecs.register_resource(
      debug_name="mgstudio_state::StateTransitionEvent<\{type_debug_name}>",
    ),
    pending_state_transition_event: @ecs.register_resource(
      debug_name="mgstudio_state::PendingStateTransitionEvent<\{type_debug_name}>",
    ),
  }
}

///|
fn[S : States] registered_state_resource_key() -> @ecs.ResourceKey[State[S]] {
  S::state_resource_keys().state
}

///|
fn[S : States] registered_previous_state_resource_key() -> @ecs.ResourceKey[
  PreviousState[S],
] {
  S::state_resource_keys().previous_state
}

///|
fn[S : States] registered_next_state_resource_key() -> @ecs.ResourceKey[
  NextState[S],
] {
  S::state_resource_keys().next_state
}

///|
fn[S : States] registered_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  S::state_resource_keys().state_transition_event
}

///|
fn[S : States] registered_pending_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  S::state_resource_keys().pending_state_transition_event
}

///|
pub fn[S : States] state_resource_key(state : S) -> @ecs.ResourceKey[State[S]] {
  ignore(state)
  registered_state_resource_key()
}

///|
pub fn[S : States] previous_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[PreviousState[S]] {
  ignore(state)
  registered_previous_state_resource_key()
}

///|
pub fn[S : States] next_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[NextState[S]] {
  ignore(state)
  registered_next_state_resource_key()
}

///|
pub fn[S : States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  ignore(state)
  registered_state_transition_event_resource_key()
}

///|
fn[S : States] pending_state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  ignore(state)
  registered_pending_state_transition_event_resource_key()
}

///|
pub impl[S : States] Resource for State[S] with fn resource() {
  registered_state_resource_key()
}

///|
pub impl[S : States] Resource for PreviousState[S] with fn resource() {
  registered_previous_state_resource_key()
}

///|
pub impl[S : States] Resource for NextState[S] with fn resource() {
  registered_next_state_resource_key()
}

///|
pub impl[S : States] Resource for StateTransitionEvent[S] with fn resource() {
  registered_state_transition_event_resource_key()
}

///|
fn[T] read_world_resource(world : @ecs.World, key : @ecs.ResourceKey[T]) -> T? {
  world.get_resource(key)
}

///|
pub fn[S : States] world_state(world : @ecs.World, state : S) -> State[S]? {
  read_world_resource(world, state_resource_key(state))
}

///|
pub fn[S : States] world_previous_state(
  world : @ecs.World,
  state : S,
) -> PreviousState[S]? {
  read_world_resource(world, previous_state_resource_key(state))
}

///|
pub fn[S : States] world_next_state(
  world : @ecs.World,
  state : S,
) -> NextState[S]? {
  read_world_resource(world, next_state_resource_key(state))
}

///|
pub fn[S : States] last_transition(
  world : @ecs.World,
  state : S,
) -> StateTransitionEvent[S]? {
  read_world_resource(world, state_transition_event_resource_key(state))
}

///|
fn[S : States] pending_transition(
  world : @ecs.World,
  state : S,
) -> StateTransitionEvent[S]? {
  read_world_resource(world, pending_state_transition_event_resource_key(state))
}
