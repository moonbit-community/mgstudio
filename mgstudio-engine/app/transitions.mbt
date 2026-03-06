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
priv struct StateTransitionRegistration {
  apply : (@ecs.World) -> Unit
}

///|
let state_transition_registrations : Array[StateTransitionRegistration] = []

///|
let state_transition_registration_seen : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()

///|
fn[S : States] state_transition_registration_key(state : S) -> String {
  "bevy_state::transition<" + state_type_debug_name(state) + ">"
}

///|
fn[S : States] register_state_transition(state : S) -> Unit {
  let key = state_transition_registration_key(state)
  if state_transition_registration_seen.contains(key) {
    return
  }
  state_transition_registration_seen.set(key, true)
  state_transition_registrations.push({
    apply: fn(world : @ecs.World) { apply_state_transition(world, state) },
  })
}

///|
fn run_registered_state_transitions(world : @ecs.World) -> Unit {
  for registration in state_transition_registrations {
    (registration.apply)(world)
  }
}

///|
fn[S : States] internal_apply_state_transition(
  world : @ecs.World,
  state : S,
  current_state : State[S]?,
  new_state : S,
  allow_same_state_transitions : Bool,
) -> Unit {
  let current_key = state_resource_key(state)
  let previous_key = previous_state_resource_key(state)
  match current_state {
    Some(current) => {
      let exited = current.get()
      if !allow_same_state_transitions && exited == new_state {
        return
      }
      world.insert_resource(current_key, State::new(new_state))
      world.insert_resource(previous_key, PreviousState::{ value: exited })
    }
    None => {
      world.insert_resource(current_key, State::new(new_state))
      let _ : Result[PreviousState[S]?, @ecs.EcsError] = try? world.remove_resource(
        previous_key,
      )
    }
  }
}

///|
fn[S : States] apply_state_transition(world : @ecs.World, state : S) -> Unit {
  let next_key = next_state_resource_key(state)
  let current_key = state_resource_key(state)
  guard world_next_state(world, state) is Some(next_state) else { return }
  guard take_next_state(next_state)
    is Some((queued_state, allow_same_state_transitions)) else {
    return
  }
  world.insert_resource(next_key, NextState::Unchanged)
  let current_state : State[S]? = read_world_resource(world, current_key)
  internal_apply_state_transition(
    world, state, current_state, queued_state, allow_same_state_transitions,
  )
}
