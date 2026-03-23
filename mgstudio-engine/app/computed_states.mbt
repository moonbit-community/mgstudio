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
pub struct OptionalStateSource[S] {
  state : S
}

///|
pub fn[S] optional_state(state : S) -> OptionalStateSource[S] {
  { state, }
}

///|
pub fn[S] OptionalStateSource::state(self : OptionalStateSource[S]) -> S {
  self.state
}

///|
fn[Source : States, Derived : States] apply_computed_state_transition(
  world : @ecs.World,
  source_state : Source,
  state : Derived,
  compute : (Source) -> Derived?,
  allow_same_state_transitions : Bool,
) -> Unit {
  guard pending_transition(world, source_state) is Some(_) else { return }
  let current_state = world_state(world, state)
  let next_state = match world_state(world, source_state) {
    Some(source) => compute(source.get())
    None => None
  }
  internal_apply_state_transition(
    world, state, current_state, next_state, allow_same_state_transitions,
  )
}

///|
fn[A : States, B : States, Derived : States] apply_computed_state_transition2(
  world : @ecs.World,
  source_a : A,
  source_b : B,
  state : Derived,
  compute : ((A, B)) -> Derived?,
  allow_same_state_transitions : Bool,
) -> Unit {
  guard pending_transition(world, source_a) is Some(_) ||
    pending_transition(world, source_b) is Some(_) else {
    return
  }
  let current_state = world_state(world, state)
  let next_state = match world_state(world, source_a) {
    Some(left) =>
      match world_state(world, source_b) {
        Some(right) => compute((left.get(), right.get()))
        None => None
      }
    None => None
  }
  internal_apply_state_transition(
    world, state, current_state, next_state, allow_same_state_transitions,
  )
}

///|
fn[A : States, B : States, C : States, Derived : States] apply_computed_state_transition3(
  world : @ecs.World,
  source_a : A,
  source_b : B,
  source_c : C,
  state : Derived,
  compute : ((A, B, C)) -> Derived?,
  allow_same_state_transitions : Bool,
) -> Unit {
  guard pending_transition(world, source_a) is Some(_) ||
    pending_transition(world, source_b) is Some(_) ||
    pending_transition(world, source_c) is Some(_) else {
    return
  }
  let current_state = world_state(world, state)
  let next_state = match world_state(world, source_a) {
    Some(first) =>
      match world_state(world, source_b) {
        Some(second) =>
          match world_state(world, source_c) {
            Some(third) => compute((first.get(), second.get(), third.get()))
            None => None
          }
        None => None
      }
    None => None
  }
  internal_apply_state_transition(
    world, state, current_state, next_state, allow_same_state_transitions,
  )
}

///|
fn[A : States, B : States, C : States, Derived : States] apply_computed_state_transition3_optional(
  world : @ecs.World,
  source_a : A,
  source_b : B,
  source_c : OptionalStateSource[C],
  state : Derived,
  compute : ((A, B, C?)) -> Derived?,
  allow_same_state_transitions : Bool,
) -> Unit {
  guard pending_transition(world, source_a) is Some(_) ||
    pending_transition(world, source_b) is Some(_) ||
    pending_transition(world, source_c.state()) is Some(_) else {
    return
  }
  let current_state = world_state(world, state)
  let next_state = match world_state(world, source_a) {
    Some(first) =>
      match world_state(world, source_b) {
        Some(second) => {
          let optional_third = match world_state(world, source_c.state()) {
            Some(third) => Some(third.get())
            None => None
          }
          compute((first.get(), second.get(), optional_third))
        }
        None => None
      }
    None => None
  }
  internal_apply_state_transition(
    world, state, current_state, next_state, allow_same_state_transitions,
  )
}

///|
fn[A : States, B : States] computed_state_source_depth2(
  source_a : A,
  source_b : B,
) -> Int {
  let depth_a = state_set_dependency_depth(source_a)
  let depth_b = state_set_dependency_depth(source_b)
  if depth_a > depth_b {
    depth_a + 1
  } else {
    depth_b + 1
  }
}

///|
fn[A : States, B : States, C : States] computed_state_source_depth3(
  source_a : A,
  source_b : B,
  source_c : C,
) -> Int {
  let depth_ab = computed_state_source_depth2(source_a, source_b) - 1
  let depth_c = state_set_dependency_depth(source_c)
  if depth_ab > depth_c {
    depth_ab + 1
  } else {
    depth_c + 1
  }
}

///|
fn[A : States, B : States, C : States] computed_state_source_depth3_optional(
  source_a : A,
  source_b : B,
  source_c : OptionalStateSource[C],
) -> Int {
  computed_state_source_depth3(source_a, source_b, source_c.state())
}

///|
pub fn[Source : States, Derived : States] register_computed_state(
  source_state : Source,
  state : Derived,
  compute : (Source) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> Unit {
  register_state_transition(source_state)
  register_state_transition_registration(
    state_transition_registration_key(state),
    dependent_state_dependency_depth(source_state),
    fn(world : @ecs.World) {
      apply_computed_state_transition(
        world, source_state, state, compute, allow_same_state_transitions,
      )
    },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
    replace_existing=true,
  )
}

///|
pub fn[A : States, B : States, Derived : States] register_computed_state2(
  source_a : A,
  source_b : B,
  state : Derived,
  compute : ((A, B)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> Unit {
  register_state_transition(source_a)
  register_state_transition(source_b)
  register_state_transition_registration(
    state_transition_registration_key(state),
    computed_state_source_depth2(source_a, source_b),
    fn(world : @ecs.World) {
      apply_computed_state_transition2(
        world, source_a, source_b, state, compute, allow_same_state_transitions,
      )
    },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
    replace_existing=true,
  )
}

///|
pub fn[A : States, B : States, C : States, Derived : States] register_computed_state3(
  source_a : A,
  source_b : B,
  source_c : C,
  state : Derived,
  compute : ((A, B, C)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> Unit {
  register_state_transition(source_a)
  register_state_transition(source_b)
  register_state_transition(source_c)
  register_state_transition_registration(
    state_transition_registration_key(state),
    computed_state_source_depth3(source_a, source_b, source_c),
    fn(world : @ecs.World) {
      apply_computed_state_transition3(
        world, source_a, source_b, source_c, state, compute, allow_same_state_transitions,
      )
    },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
    replace_existing=true,
  )
}

///|
pub fn[A : States, B : States, C : States, Derived : States] register_computed_state3_optional(
  source_a : A,
  source_b : B,
  source_c : OptionalStateSource[C],
  state : Derived,
  compute : ((A, B, C?)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> Unit {
  register_state_transition(source_a)
  register_state_transition(source_b)
  register_state_transition(source_c.state())
  register_state_transition_registration(
    state_transition_registration_key(state),
    computed_state_source_depth3_optional(source_a, source_b, source_c),
    fn(world : @ecs.World) {
      apply_computed_state_transition3_optional(
        world, source_a, source_b, source_c, state, compute, allow_same_state_transitions,
      )
    },
    fn(world : @ecs.World) { run_pending_exit(world, state) },
    fn(world : @ecs.World) { run_pending_transition(world, state) },
    fn(world : @ecs.World) { run_pending_enter(world, state) },
    fn(world : @ecs.World) { clear_pending_event(world, state) },
    replace_existing=true,
  )
}

///|
pub fn[Source : States, Derived : States] App::add_computed_state(
  self : App[@ecs.World],
  source_state : Source,
  state : Derived,
  compute : (Source) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_computed_state(
    source_state,
    state,
    compute,
    allow_same_state_transitions~,
  )
  self
}

///|
pub fn[A : States, B : States, Derived : States] App::add_computed_state2(
  self : App[@ecs.World],
  source_a : A,
  source_b : B,
  state : Derived,
  compute : ((A, B)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_computed_state2(
    source_a,
    source_b,
    state,
    compute,
    allow_same_state_transitions~,
  )
  self
}

///|
pub fn[A : States, B : States, C : States, Derived : States] App::add_computed_state3(
  self : App[@ecs.World],
  source_a : A,
  source_b : B,
  source_c : C,
  state : Derived,
  compute : ((A, B, C)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_computed_state3(
    source_a,
    source_b,
    source_c,
    state,
    compute,
    allow_same_state_transitions~,
  )
  self
}

///|
pub fn[A : States, B : States, C : States, Derived : States] App::add_computed_state3_optional(
  self : App[@ecs.World],
  source_a : A,
  source_b : B,
  source_c : OptionalStateSource[C],
  state : Derived,
  compute : ((A, B, C?)) -> Derived?,
  allow_same_state_transitions? : Bool = true,
) -> App[@ecs.World] {
  require_states_plugin_installed(self.world())
  register_computed_state3_optional(
    source_a,
    source_b,
    source_c,
    state,
    compute,
    allow_same_state_transitions~,
  )
  self
}
