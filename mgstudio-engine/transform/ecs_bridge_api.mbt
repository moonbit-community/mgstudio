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
pub let ecs_components : Array[String] = ["GlobalTransform"]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_GlobalTransform {
  get_global_transform_store(self : Self) -> @ecs.ComponentAccess[
    GlobalTransform,
  ]
}

///|
pub fn[W : Has_GlobalTransform] get_global_transform_store(
  world : W,
) -> @ecs.ComponentAccess[GlobalTransform] {
  world.get_global_transform_store()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_GlobalTransform for @ecs.World with get_global_transform_store(
  self,
) {
  self.component(ecs_key_global_transform)
}

///|
/// End ECS bridge impls.
