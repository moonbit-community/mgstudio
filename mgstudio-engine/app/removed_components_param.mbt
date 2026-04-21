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
pub impl[T : @ecs.Component] SystemParam for @ecs.RemovedComponents[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @ecs.Component] SystemParam for @ecs.RemovedComponents[T] with get(
  _state,
) {
  let world = system_param_abort_missing_world()
  let key : @ecs.ComponentKey[T] = @ecs.Component::component()
  world.removed_components(key, current_system_sequence())
}

///|
pub impl[T : @ecs.Component] SystemParam for @ecs.RemovedComponents[T] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : @ecs.Component] SystemParam for @ecs.RemovedComponents[T] with access(
  _world,
) {
  SystemAccess::new()
}
