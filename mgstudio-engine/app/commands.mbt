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
fn current_world_or_abort() -> @ecs.World {
  match current_world() {
    Some(world) => world
    None =>
      abort("state mutation requires an active world during system execution")
  }
}

///|
pub fn[S : States] set_state(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for " + state_type_debug_name(state))
  }
  world.insert_resource(next_key, current.set(state))
}

///|
pub fn[S : States] set_state_if_neq(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for " + state_type_debug_name(state))
  }
  world.insert_resource(next_key, current.set_if_neq(state))
}
