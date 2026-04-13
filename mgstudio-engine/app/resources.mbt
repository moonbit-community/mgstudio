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
let state_type_debug_name_registry : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let state_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let previous_state_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let next_state_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let state_transition_event_resource_registry : Ref[
  @hashmap.HashMap[String, @any.Any],
] = Ref::new(@hashmap.HashMap::new())

///|
let pending_state_transition_event_resource_registry : Ref[
  @hashmap.HashMap[String, @any.Any],
] = Ref::new(@hashmap.HashMap::new())

///|
fn[S] state_type_registry_key(probe : NextState[S]) -> String {
  @any.of(probe).type_name()
}

///|
fn[S : States] state_type_debug_name(_state : S) -> String {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  let debug_name = States::debug_name(_state)
  state_type_debug_name_registry.val.set(type_key, debug_name)
  debug_name
}

///|
fn[S] registered_state_type_debug_name(probe : NextState[S]) -> String {
  let type_key = state_type_registry_key(probe)
  match state_type_debug_name_registry.val.get(type_key) {
    Some(debug_name) => debug_name
    None => type_key
  }
}

///|
fn[S] registered_state_resource_key() -> @ecs.ResourceKey[State[S]] {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  match state_resource_registry.val.get(type_key) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "state resource registry contained a mismatched key for \{type_key}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[State[S]] = @ecs.register_resource(
        debug_name="mgstudio_state::State<\{registered_state_type_debug_name(probe)}>",
      )
      state_resource_registry.val.set(type_key, @any.of(key))
      key
    }
  }
}

///|
fn[S] registered_previous_state_resource_key() -> @ecs.ResourceKey[
  PreviousState[S],
] {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  match previous_state_resource_registry.val.get(type_key) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "previous state resource registry contained a mismatched key for \{type_key}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[PreviousState[S]] = @ecs.register_resource(
        debug_name="mgstudio_state::PreviousState<\{registered_state_type_debug_name(probe)}>",
      )
      previous_state_resource_registry.val.set(type_key, @any.of(key))
      key
    }
  }
}

///|
fn[S] registered_next_state_resource_key() -> @ecs.ResourceKey[NextState[S]] {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  match next_state_resource_registry.val.get(type_key) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "next state resource registry contained a mismatched key for \{type_key}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[NextState[S]] = @ecs.register_resource(
        debug_name="mgstudio_state::NextState<\{registered_state_type_debug_name(probe)}>",
      )
      next_state_resource_registry.val.set(type_key, @any.of(key))
      key
    }
  }
}

///|
fn[S] registered_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  match state_transition_event_resource_registry.val.get(type_key) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "state transition event resource registry contained a mismatched key for \{type_key}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[StateTransitionEvent[S]] = @ecs.register_resource(
        debug_name="mgstudio_state::StateTransitionEvent<\{registered_state_type_debug_name(probe)}>",
      )
      state_transition_event_resource_registry.val.set(type_key, @any.of(key))
      key
    }
  }
}

///|
fn[S] registered_pending_state_transition_event_resource_key() -> @ecs.ResourceKey[
  StateTransitionEvent[S],
] {
  let probe : NextState[S] = NextState::Unchanged
  let type_key = state_type_registry_key(probe)
  match pending_state_transition_event_resource_registry.val.get(type_key) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "pending state transition event resource registry contained a mismatched key for \{type_key}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[StateTransitionEvent[S]] = @ecs.register_resource(
        debug_name="mgstudio_state::PendingStateTransitionEvent<\{registered_state_type_debug_name(probe)}>",
      )
      pending_state_transition_event_resource_registry.val.set(
        type_key,
        @any.of(key),
      )
      key
    }
  }
}

///|
pub fn[S : States] state_resource_key(state : S) -> @ecs.ResourceKey[State[S]] {
  ignore(state_type_debug_name(state))
  registered_state_resource_key()
}

///|
pub fn[S : States] previous_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[PreviousState[S]] {
  ignore(state_type_debug_name(state))
  registered_previous_state_resource_key()
}

///|
pub fn[S : States] next_state_resource_key(
  state : S,
) -> @ecs.ResourceKey[NextState[S]] {
  ignore(state_type_debug_name(state))
  registered_next_state_resource_key()
}

///|
pub fn[S : States] state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  ignore(state_type_debug_name(state))
  registered_state_transition_event_resource_key()
}

///|
fn[S : States] pending_state_transition_event_resource_key(
  state : S,
) -> @ecs.ResourceKey[StateTransitionEvent[S]] {
  ignore(state_type_debug_name(state))
  registered_pending_state_transition_event_resource_key()
}

///|
pub impl[S] Resource for State[S] with resource() {
  registered_state_resource_key()
}

///|
pub impl[S] Resource for PreviousState[S] with resource() {
  registered_previous_state_resource_key()
}

///|
pub impl[S] Resource for NextState[S] with resource() {
  registered_next_state_resource_key()
}

///|
pub impl[S] Resource for StateTransitionEvent[S] with resource() {
  registered_state_transition_event_resource_key()
}

///|
fn[T] read_world_resource(world : @ecs.World, key : @ecs.ResourceKey[T]) -> T? {
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
