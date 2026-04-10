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
pub struct DespawnOnExit {
  transition_key : String
  state_debug : String
}

///|
pub struct DespawnOnEnter {
  transition_key : String
  state_debug : String
}

///|
pub fn DespawnOnExit::transition_key(self : DespawnOnExit) -> String {
  self.transition_key
}

///|
pub fn DespawnOnEnter::transition_key(self : DespawnOnEnter) -> String {
  self.transition_key
}

///|
pub fn DespawnOnExit::state_debug(self : DespawnOnExit) -> String {
  self.state_debug
}

///|
pub fn DespawnOnEnter::state_debug(self : DespawnOnEnter) -> String {
  self.state_debug
}

///|
let despawn_on_exit_registration_registry : Ref[@hashmap.HashMap[String, Bool]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let despawn_on_enter_registration_registry : Ref[@hashmap.HashMap[String, Bool]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
pub let ecs_key_despawn_on_exit : @ecs.ComponentKey[DespawnOnExit] = @ecs.register_component(
  debug_name="mgstudio_state::DespawnOnExit",
)

///|
pub let ecs_key_despawn_on_enter : @ecs.ComponentKey[DespawnOnEnter] = @ecs.register_component(
  debug_name="mgstudio_state::DespawnOnEnter",
)

///|
pub impl @ecs.Component for DespawnOnExit with component() {
  ecs_key_despawn_on_exit
}

///|
pub impl @ecs.Component for DespawnOnEnter with component() {
  ecs_key_despawn_on_enter
}

///|
fn[S : States] despawn_on_exit_entities(world : @ecs.World, state : S) -> Unit {
  guard pending_transition(world, state) is Some(event) else { return }
  guard event.exited is Some(exited) else { return }
  let transition_key = state_transition_registration_key(state)
  let exited_debug = to_repr(exited).to_string()
  let entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_despawn_on_exit, fn(entity, marker) {
    if marker.transition_key() == transition_key &&
      marker.state_debug() == exited_debug {
      entities.push(entity)
    }
  })
  for entity in entities {
    ignore(world.despawn(entity) catch { _ => () })
  }
}

///|
fn[S : States] despawn_on_enter_entities(world : @ecs.World, state : S) -> Unit {
  guard pending_transition(world, state) is Some(event) else { return }
  guard event.entered is Some(entered) else { return }
  let transition_key = state_transition_registration_key(state)
  let entered_debug = to_repr(entered).to_string()
  let entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_despawn_on_enter, fn(entity, marker) {
    if marker.transition_key() == transition_key &&
      marker.state_debug() == entered_debug {
      entities.push(entity)
    }
  })
  for entity in entities {
    ignore(world.despawn(entity) catch { _ => () })
  }
}

///|
fn[S : States] ensure_despawn_on_exit_registered(state : S) -> Unit {
  let transition_key = state_transition_registration_key(state)
  if despawn_on_exit_registration_registry.val.contains(transition_key) {
    return
  }
  register_state_transition(state)
  register_state_transition_hook(
    on_exit_registrations,
    transition_key,
    system(fn(world : @ecs.World) { despawn_on_exit_entities(world, state) }),
    fn(world : @ecs.World) {
      match pending_transition(world, state) {
        Some(event) => event.exited is Some(_)
        None => false
      }
    },
  )
  despawn_on_exit_registration_registry.val.set(transition_key, true)
}

///|
fn[S : States] ensure_despawn_on_enter_registered(state : S) -> Unit {
  let transition_key = state_transition_registration_key(state)
  if despawn_on_enter_registration_registry.val.contains(transition_key) {
    return
  }
  register_state_transition(state)
  register_state_transition_hook(
    on_enter_registrations,
    transition_key,
    system(fn(world : @ecs.World) { despawn_on_enter_entities(world, state) }),
    fn(world : @ecs.World) {
      match pending_transition(world, state) {
        Some(event) => event.entered is Some(_)
        None => false
      }
    },
  )
  despawn_on_enter_registration_registry.val.set(transition_key, true)
}

///|
pub fn[S : States] DespawnOnExit::new(state : S) -> DespawnOnExit {
  ensure_despawn_on_exit_registered(state)
  {
    transition_key: state_transition_registration_key(state),
    state_debug: to_repr(state).to_string(),
  }
}

///|
pub fn[S : States] DespawnOnEnter::new(state : S) -> DespawnOnEnter {
  ensure_despawn_on_enter_registered(state)
  {
    transition_key: state_transition_registration_key(state),
    state_debug: to_repr(state).to_string(),
  }
}
