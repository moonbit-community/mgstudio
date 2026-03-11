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
pub let ecs_components : Array[String] = [
  "SceneRoot", "SceneInstance", "SceneInstanceReady",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = []

///|
pub fn get_scene_root_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SceneRoot] {
  world.component(ecs_key_scene_root)
}

///|
pub fn get_scene_instance_ready_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SceneInstanceReady] {
  world.component(ecs_key_scene_instance_ready)
}

///|
pub fn get_scene_instance_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SceneInstance] {
  world.component(ecs_key_scene_instance)
}
