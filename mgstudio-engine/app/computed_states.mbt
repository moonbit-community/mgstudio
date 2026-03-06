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
