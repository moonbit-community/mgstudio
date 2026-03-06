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
pub(open) trait SubStates: States + FreelyMutableState {}

///|
fn[Source : States, Derived : SubStates] apply_sub_state_transition(
  world : @ecs.World,
  source_state : Source,
  state : Derived,
  should_exist : (Source) -> Derived?,
) -> Unit {
  let parent_changed = pending_transition(world, source_state) is Some(_)
  let next_key = next_state_resource_key(state)
  let queued_next_state = match world_next_state(world, state) {
    Some(next_state) =>
      match take_next_state(next_state) {
        Some(queued) => {
          world.insert_resource(next_key, NextState::Unchanged)
          Some(queued)
        }
        None => None
      }
    None => None
  }
  if !parent_changed && queued_next_state is None {
    return
  }

  let current_state = world_state(world, state)
  let current_value = match current_state {
    Some(current) => Some(current.get())
    None => None
  }
  let initial_state = if parent_changed {
    match world_state(world, source_state) {
      Some(source) => should_exist(source.get())
      None => None
    }
  } else {
    current_value
  }
  let allow_same_state_transitions = match queued_next_state {
    Some((_queued, allow_same)) => allow_same
    None => false
  }
  let new_state = match initial_state {
    Some(initial) =>
      match queued_next_state {
        Some((queued, _allow_same)) => Some(queued)
        None =>
          match current_value {
            Some(current) => Some(current)
            None => Some(initial)
          }
      }
    None => None
  }

  internal_apply_state_transition(
    world, state, current_state, new_state, allow_same_state_transitions,
  )
}

///|
pub fn[Source : States, Derived : SubStates] register_sub_state(
  source_state : Source,
  state : Derived,
  should_exist : (Source) -> Derived?,
) -> Unit {
  register_state_transition(source_state)
  register_state_transition_registration(
    state_transition_registration_key(state),
    dependent_state_dependency_depth(source_state),
    fn(world : @ecs.World) {
      apply_sub_state_transition(world, source_state, state, should_exist)
    },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
    replace_existing=true,
  )
}

///|
pub fn[Source : States, Derived : SubStates] App::add_sub_state(
  self : App[@ecs.World],
  source_state : Source,
  state : Derived,
  should_exist : (Source) -> Derived?,
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_sub_state(source_state, state, should_exist)
  if world_next_state(self.world(), state) is None {
    self
    .world()
    .insert_resource(next_state_resource_key(state), NextState::Unchanged)
  }
  if world_state(self.world(), state) is Some(current_state) {
    enqueue_transition_event(self.world(), state, StateTransitionEvent::{
      exited: None,
      entered: Some(current_state.get()),
      allow_same_state_transitions: true,
    })
  }
  self
}
