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
pub let ecs_key_scene_root : @ecs.ComponentKey[SceneRoot] = @ecs.register_component(
  debug_name="scene.scene_root",
)

///|
pub let ecs_key_scene_instance : @ecs.ComponentKey[SceneInstance] = @ecs.register_component(
  debug_name="scene.scene_instance",
)

///|
pub let ecs_key_scene_instance_ready : @ecs.ComponentKey[SceneInstanceReady] = @ecs.register_component(
  debug_name="scene.scene_instance_ready",
)

///|
pub impl @ecs.Component for SceneRoot with component() {
  ecs_key_scene_root
}

///|
pub impl @ecs.Component for SceneInstance with component() {
  ecs_key_scene_instance
}

///|
pub impl @ecs.Component for SceneInstanceReady with component() {
  ecs_key_scene_instance_ready
}
