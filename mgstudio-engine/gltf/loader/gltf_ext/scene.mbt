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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/gltf_ext/scene.rs`.
// Bridge surface for scene and node metadata extracted from glTF.
pub fn gltf_scene_extras(value : String) -> GltfSceneExtras {
  GltfSceneExtras::new(value)
}

///|
pub fn gltf_scene_index(scene_index : Int) -> GltfSceneIndex {
  GltfSceneIndex::new(scene_index)
}

///|
pub fn gltf_node_index(node_index : Int) -> GltfNodeIndex {
  GltfNodeIndex::new(node_index)
}

///|
pub fn gltf_scene_asset_label(scene_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Scene(scene_index)
}

///|
pub fn gltf_node_asset_label(node_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Node(node_index)
}
