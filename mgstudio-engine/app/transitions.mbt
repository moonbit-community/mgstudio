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
  dependency_depth : Int
  apply : (@ecs.World) -> Unit
  run_exit : (@ecs.World) -> Unit
  run_transition : (@ecs.World) -> Unit
  run_enter : (@ecs.World) -> Unit
  clear_pending : (@ecs.World) -> Unit
}

///|
let state_transition_registrations : Array[StateTransitionRegistration] = []

///|
let state_transition_registration_indices : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()

///|
priv struct StateTransitionHookRegistration {
  key : String
  config_ref : Ref[SystemConfig[@ecs.World]]
  matches : (@ecs.World) -> Bool
}

///|
let on_enter_registrations : Array[StateTransitionHookRegistration] = []

///|
let on_exit_registrations : Array[StateTransitionHookRegistration] = []

///|
let on_transition_registrations : Array[StateTransitionHookRegistration] = []

///|
pub struct OnEnter[S] {
  state : S
} derive(Eq, Show)

///|
pub fn[S] OnEnter::new(state : S) -> OnEnter[S] {
  OnEnter::{ state, }
}

///|
pub fn[S] OnEnter::state(self : OnEnter[S]) -> S {
  self.state
}

///|
pub struct OnExit[S] {
  state : S
} derive(Eq, Show)

///|
pub fn[S] OnExit::new(state : S) -> OnExit[S] {
  OnExit::{ state, }
}

///|
pub fn[S] OnExit::state(self : OnExit[S]) -> S {
  self.state
}

///|
pub struct OnTransition[S] {
  exited : S
  entered : S
} derive(Eq, Show)

///|
pub fn[S] OnTransition::new(exited : S, entered : S) -> OnTransition[S] {
  OnTransition::{ exited, entered }
}

///|
pub fn[S] OnTransition::exited(self : OnTransition[S]) -> S {
  self.exited
}

///|
pub fn[S] OnTransition::entered(self : OnTransition[S]) -> S {
  self.entered
}

///|
pub(all) enum StateTransitionSystems {
  DependentTransitions
  ExitSchedules
  TransitionSchedules
  EnterSchedules
} derive(Eq, Show)

///|
fn[S : States] state_transition_registration_key(state : S) -> String {
  "bevy_state::transition<" + state_type_debug_name(state) + ">"
}

///|
fn register_state_transition_registration(
  key : String,
  dependency_depth : Int,
  apply : (@ecs.World) -> Unit,
  run_exit : (@ecs.World) -> Unit,
  run_transition : (@ecs.World) -> Unit,
  run_enter : (@ecs.World) -> Unit,
  clear_pending : (@ecs.World) -> Unit,
  replace_existing? : Bool = false,
) -> Unit {
  let registration = StateTransitionRegistration::{
    dependency_depth,
    apply,
    run_exit,
    run_transition,
    run_enter,
    clear_pending,
  }
  if state_transition_registration_indices.get(key) is Some(index) {
    if replace_existing {
      state_transition_registrations[index] = registration
    }
    return
  }
  state_transition_registration_indices.set(
    key,
    state_transition_registrations.length(),
  )
  state_transition_registrations.push(registration)
}

///|
fn[S : States] register_state_transition(state : S) -> Unit {
  let key = state_transition_registration_key(state)
  register_state_transition_registration(
    key,
    state.dependency_depth(),
    fn(world : @ecs.World) { apply_state_transition(world, state) },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
  )
}

///|
fn sorted_state_transition_registration_indices(ascending : Bool) -> Array[Int] {
  let indices : Array[Int] = []
  for i in 0..<state_transition_registrations.length() {
    indices.push(i)
  }
  indices.sort_by(fn(left : Int, right : Int) -> Int {
    let left_depth = state_transition_registrations[left].dependency_depth
    let right_depth = state_transition_registrations[right].dependency_depth
    if ascending {
      left_depth - right_depth
    } else {
      right_depth - left_depth
    }
  })
  indices
}

///|
fn run_registered_state_transitions(world : @ecs.World) -> Unit {
  if !states_plugin_installed(world) {
    return
  }
  let root_to_leaf = sorted_state_transition_registration_indices(true)
  let leaf_to_root = sorted_state_transition_registration_indices(false)
  let prev_stage = current_schedule_stage_ref.val
  current_schedule_stage_ref.val = Some(StateTransition)
  for index in root_to_leaf {
    (state_transition_registrations[index].apply)(world)
  }
  for index in leaf_to_root {
    (state_transition_registrations[index].run_exit)(world)
  }
  for index in root_to_leaf {
    (state_transition_registrations[index].run_transition)(world)
  }
  for index in root_to_leaf {
    (state_transition_registrations[index].run_enter)(world)
  }
  for index in root_to_leaf {
    (state_transition_registrations[index].clear_pending)(world)
  }
  current_schedule_stage_ref.val = prev_stage
}

///|
fn register_state_transition_hook(
  hooks : Array[StateTransitionHookRegistration],
  key : String,
  config : SystemConfig[@ecs.World],
  matches : (@ecs.World) -> Bool,
) -> Unit {
  hooks.push({ key, config_ref: Ref::new(config), matches })
}

///|
fn run_state_transition_hooks(
  world : @ecs.World,
  hooks : Array[StateTransitionHookRegistration],
  key : String,
) -> Unit {
  let matched_refs : Array[Ref[SystemConfig[@ecs.World]]] = []
  for hook in hooks {
    if hook.key == key && (hook.matches)(world) {
      matched_refs.push(hook.config_ref)
    }
  }
  guard matched_refs.length() > 0 else { return }
  let matched_configs : Array[SystemConfig[@ecs.World]] = []
  for config_ref in matched_refs {
    matched_configs.push(config_ref.val)
  }
  run_systems(world, matched_configs, [])
  for i in 0..<matched_refs.length() {
    matched_refs[i].val = matched_configs[i]
  }
}

///|
fn[S : States] enqueue_transition_event(
  world : @ecs.World,
  state : S,
  event : StateTransitionEvent[S],
) -> Unit {
  world.insert_resource(state_transition_event_resource_key(state), event)
  world.insert_resource(
    pending_state_transition_event_resource_key(state),
    event,
  )
}

///|
fn[S : States] run_pending_exit(world : @ecs.World, state : S) -> Unit {
  guard pending_transition(world, state) is Some(event) else { return }
  ignore(event)
  let key = state_transition_registration_key(state)
  run_state_transition_hooks(world, on_exit_registrations, key)
}

///|
fn[S : States] run_pending_transition(world : @ecs.World, state : S) -> Unit {
  guard pending_transition(world, state) is Some(event) else { return }
  ignore(event)
  let key = state_transition_registration_key(state)
  run_state_transition_hooks(world, on_transition_registrations, key)
}

///|
fn[S : States] run_pending_enter(world : @ecs.World, state : S) -> Unit {
  guard pending_transition(world, state) is Some(event) else { return }
  ignore(event)
  let key = state_transition_registration_key(state)
  run_state_transition_hooks(world, on_enter_registrations, key)
}

///|
fn[S : States] clear_pending_event(world : @ecs.World, state : S) -> Unit {
  let key = pending_state_transition_event_resource_key(state)
  let _ : Result[StateTransitionEvent[S]?, @ecs.EcsError] = try? world.remove_resource(
    key,
  )
}

///|
fn[S : States] register_on_enter_system(
  state : S,
  config : SystemConfig[@ecs.World],
) -> Unit {
  let key = state_transition_registration_key(state)
  register_state_transition_hook(on_enter_registrations, key, config, fn(
    world : @ecs.World,
  ) {
    match pending_transition(world, state) {
      Some(event) =>
        if event.entered == event.exited && !event.allow_same_state_transitions {
          false
        } else {
          match event.entered {
            Some(entered) => entered == state
            None => false
          }
        }
      None => false
    }
  })
}

///|
fn[S : States] register_on_exit_system(
  state : S,
  config : SystemConfig[@ecs.World],
) -> Unit {
  let key = state_transition_registration_key(state)
  register_state_transition_hook(on_exit_registrations, key, config, fn(
    world : @ecs.World,
  ) {
    match pending_transition(world, state) {
      Some(event) =>
        if event.entered == event.exited && !event.allow_same_state_transitions {
          false
        } else {
          match event.exited {
            Some(exited) => exited == state
            None => false
          }
        }
      None => false
    }
  })
}

///|
fn[S : States] register_on_transition_system(
  exited : S,
  entered : S,
  config : SystemConfig[@ecs.World],
) -> Unit {
  let key = state_transition_registration_key(exited)
  register_state_transition_hook(on_transition_registrations, key, config, fn(
    world : @ecs.World,
  ) {
    match pending_transition(world, exited) {
      Some(event) =>
        event.exited == Some(exited) && event.entered == Some(entered)
      None => false
    }
  })
}

///|
fn[S : States] internal_apply_state_transition(
  world : @ecs.World,
  state : S,
  current_state : State[S]?,
  new_state : S?,
  allow_same_state_transitions : Bool,
) -> Unit {
  let current_key = state_resource_key(state)
  let previous_key = previous_state_resource_key(state)
  match new_state {
    Some(entered) =>
      match current_state {
        Some(current) => {
          let exited = current.get()
          if !allow_same_state_transitions && exited == entered {
            return
          }
          world.insert_resource(current_key, State::new(entered))
          world.insert_resource(previous_key, PreviousState::{ value: exited })
          let event = StateTransitionEvent::{
            exited: Some(exited),
            entered: Some(entered),
            allow_same_state_transitions,
          }
          enqueue_transition_event(world, state, event)
        }
        None => {
          world.insert_resource(current_key, State::new(entered))
          let _ : Result[PreviousState[S]?, @ecs.EcsError] = try? world.remove_resource(
            previous_key,
          )
          let event = StateTransitionEvent::{
            exited: None,
            entered: Some(entered),
            allow_same_state_transitions,
          }
          enqueue_transition_event(world, state, event)
        }
      }
    None =>
      match current_state {
        Some(current) => {
          let exited = current.get()
          let _ : Result[State[S]?, @ecs.EcsError] = try? world.remove_resource(
            current_key,
          )
          world.insert_resource(previous_key, PreviousState::{ value: exited })
          let event = StateTransitionEvent::{
            exited: Some(exited),
            entered: None,
            allow_same_state_transitions,
          }
          enqueue_transition_event(world, state, event)
        }
        None => ()
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
    world,
    state,
    current_state,
    Some(queued_state),
    allow_same_state_transitions,
  )
}
