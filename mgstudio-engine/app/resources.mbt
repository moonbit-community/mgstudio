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
} derive(Eq, Show, ToJson, FromJson)

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
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn[S] PreviousState::get(self : PreviousState[S]) -> S {
  self.value
}

///|
pub(all) enum NextState[S] {
  Unchanged
  Pending(S)
  PendingIfNeq(S)
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct StateTransitionEvent[S] {
  exited : S?
  entered : S?
  allow_same_state_transitions : Bool
} derive(Eq, Show, ToJson, FromJson)

///|
fn[S : States] state_type_debug_name(_state : S) -> String {
  States::debug_name(_state)
}

///|
fn[S : States] state_resource_debug_name(state : S) -> String {
  "bevy_state::State<" + state_type_debug_name(state) + ">"
}

///|
fn[S : States] previous_state_resource_debug_name(state : S) -> String {
  "bevy_state::PreviousState<" + state_type_debug_name(state) + ">"
}

///|
fn[S : States] next_state_resource_debug_name(state : S) -> String {
  "bevy_state::NextState<" + state_type_debug_name(state) + ">"
}

///|
fn[S : States] state_transition_event_resource_debug_name(state : S) -> String {
  "bevy_state::StateTransitionEvent<" + state_type_debug_name(state) + ">"
}

///|
fn[S : States] pending_state_transition_event_resource_debug_name(
  state : S,
) -> String {
  "bevy_state::PendingStateTransitionEvent<" +
  state_type_debug_name(state) +
  ">"
}

///|
pub fn[S : States] state_resource_key(state : S) -> @ecs.ResourceKey[State[S]] {
  @ecs.register_resource(debug_name=state_resource_debug_name(state))
}

///|
pub fn[S : States] previous_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[PreviousState[S]] {
  @ecs.register_resource(debug_name=previous_state_resource_debug_name(state))
}

///|
pub fn[S : States] next_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[NextState[S]] {
  @ecs.register_resource(debug_name=next_state_resource_debug_name(state))
}

///|
pub fn[S : States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  @ecs.register_resource(
    debug_name=state_transition_event_resource_debug_name(state),
  )
}

///|
fn[S : States] pending_state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  @ecs.register_resource(
    debug_name=pending_state_transition_event_resource_debug_name(state),
  )
}

///|
fn[T : @json.FromJson] read_world_resource(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
) -> T? {
  try world.get_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
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
