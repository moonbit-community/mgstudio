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
// Bevy source: `bevy/crates/bevy_scene/src/scene_filter.rs`.
// Scene filter API is gated by dynamic-scene reflection support.

///|
pub const SCENE_FILTER_MODULE_TAG : String = "bevy_scene::scene_filter"

///|
pub struct SceneFilterBridge {
  supported : Bool
}

///|
pub fn SceneFilterBridge::default() -> SceneFilterBridge {
  SceneFilterBridge::{ supported: DYNAMIC_SCENE_SUPPORTED }
}

///|
pub fn scene_filter_supported() -> Bool {
  DYNAMIC_SCENE_SUPPORTED
}

///|
pub fn scene_filter_bridge_supported(bridge : SceneFilterBridge) -> Bool {
  bridge.supported
}
