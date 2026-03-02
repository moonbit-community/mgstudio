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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = []

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = ["A11yState"]

///|
pub(open) trait HasRes_A11yState {
  get_a11y_state_resource(self : Self) -> @core.Resource[A11yState]
}

///|
pub fn[W : HasRes_A11yState] query_get_a11y_state_resource(
  world : W,
) -> @core.Resource[A11yState] {
  world.get_a11y_state_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_a11y_state_resource_by_world : Map[
  Int,
  @core.Resource[A11yState],
] = {}

///|
pub impl HasRes_A11yState for @ecs.World with get_a11y_state_resource(self) {
  bridge_get_a11y_state_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
