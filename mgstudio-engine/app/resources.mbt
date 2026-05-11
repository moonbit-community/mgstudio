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
let state_resource_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
let previous_state_resource_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
let next_state_resource_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
let state_transition_event_resource_registry : Ref[
  @hashmap.HashMap[String, Int],
] = Ref(@hashmap.HashMap([]))

///|
let pending_state_transition_event_resource_registry : Ref[
  @hashmap.HashMap[String, Int],
] = Ref(@hashmap.HashMap([]))

///|
fn[S : States] state_type_debug_name(state : S) -> String {
  ignore(state)
  S::type_debug_name()
}

///|
fn[T] registered_typed_resource_key(
  registry : Ref[@hashmap.HashMap[String, Int]],
  debug_name : String,
) -> @ecs.ResourceKey[T] {
  match registry.val.get(debug_name) {
    Some(id) => @ecs.resource_key_from_id(id, debug_name~)
    None => {
      let key : @ecs.ResourceKey[T] = @ecs.register_resource(debug_name~)
      registry.val.set(debug_name, key.id())
      key
    }
  }
}

///|
fn[S : States] registered_state_resource_key() -> @ecs.ResourceKey[State[S]] {
  let debug_name = "mgstudio_state::State<\{S::type_debug_name()}>"
  registered_typed_resource_key(state_resource_registry, debug_name)
}

///|
fn[S : States] registered_previous_state_resource_key() -> @ecs.ResourceKey[
  PreviousState[S],
] {
  let debug_name = "mgstudio_state::PreviousState<\{S::type_debug_name()}>"
  registered_typed_resource_key(previous_state_resource_registry, debug_name)
}

///|
fn[S : States] registered_next_state_resource_key() -> @ecs.ResourceKey[
  NextState[S],
] {
  let debug_name = "mgstudio_state::NextState<\{S::type_debug_name()}>"
  registered_typed_resource_key(next_state_resource_registry, debug_name)
}

///|
fn[S : States] registered_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  let debug_name = "mgstudio_state::StateTransitionEvent<\{S::type_debug_name()}>"
  registered_typed_resource_key(
    state_transition_event_resource_registry, debug_name,
  )
}

///|
fn[S : States] registered_pending_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  let debug_name = "mgstudio_state::PendingStateTransitionEvent<\{S::type_debug_name()}>"
  registered_typed_resource_key(
    pending_state_transition_event_resource_registry, debug_name,
  )
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
pub impl[S : States] Resource for State[S] with resource() {
  registered_state_resource_key()
}

///|
pub impl[S : States] Resource for PreviousState[S] with resource() {
  registered_previous_state_resource_key()
}

///|
pub impl[S : States] Resource for NextState[S] with resource() {
  registered_next_state_resource_key()
}

///|
pub impl[S : States] Resource for StateTransitionEvent[S] with resource() {
  registered_state_transition_event_resource_key()
}

///|
fn[T : @ecs.EcsPayloadCodec] read_world_resource(
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
