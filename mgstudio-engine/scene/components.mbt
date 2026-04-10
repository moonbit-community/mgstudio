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
// Bevy source: `bevy/crates/bevy_scene/src/components.rs`.
// Bridge aliases for scene-facing ECS component surface.

///|
pub type SceneComponentNode3d = SceneNode3d

///|
pub type SceneComponentRoot = SceneRoot

///|
pub type SceneComponentInstance = SceneInstance

///|
pub const SCENE_COMPONENTS_MODULE_TAG : String = "bevy_scene::components"

///|
pub struct SceneComponentsBridge {
  module_tag : String
}

///|
pub fn SceneComponentsBridge::default() -> SceneComponentsBridge {
  SceneComponentsBridge::{ module_tag: SCENE_COMPONENTS_MODULE_TAG }
}

///|
pub fn scene_components_bridge_enabled(bridge : SceneComponentsBridge) -> Bool {
  bridge.module_tag == SCENE_COMPONENTS_MODULE_TAG
}

///|
pub fn scene_components_bridge_module_tag(
  bridge : SceneComponentsBridge,
) -> String {
  bridge.module_tag
}
