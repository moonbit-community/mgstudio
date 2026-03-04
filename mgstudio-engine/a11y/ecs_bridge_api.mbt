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
/// ECS component bridge types.
pub let ecs_components : Array[String] = []

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = ["A11yState"]

///|
pub let ecs_res_key_a11y_state : @ecs.ResourceKey[A11yState] = @ecs.register_resource(
  debug_name="a11y.a11y_state",
)

///|
pub fn get_a11y_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[A11yState] {
  world.resource(ecs_res_key_a11y_state)
}
