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
// Bevy source: `bevy/crates/bevy_scene/src/scene_spawner.rs`.
// Bridge aliases for scene spawning runtime handles.

///|
pub type SceneSpawnerRoot = SceneRoot

///|
pub type SceneSpawnerInstance = SceneInstance

///|
pub type SceneSpawnerInstanceReady = SceneInstanceReady

///|
pub const SCENE_SPAWNER_MODULE_TAG : String = "bevy_scene::scene_spawner"

///|
pub struct SceneSpawnerBridge {
  module_tag : String
}

///|
pub fn SceneSpawnerBridge::default() -> SceneSpawnerBridge {
  SceneSpawnerBridge::{ module_tag: SCENE_SPAWNER_MODULE_TAG }
}

///|
pub fn scene_spawner_bridge_enabled(bridge : SceneSpawnerBridge) -> Bool {
  bridge.module_tag == SCENE_SPAWNER_MODULE_TAG
}

///|
pub fn scene_spawner_bridge_module_tag(bridge : SceneSpawnerBridge) -> String {
  bridge.module_tag
}
