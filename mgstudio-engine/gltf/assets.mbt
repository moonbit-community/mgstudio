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
// Bevy source: `bevy/crates/bevy_gltf/src/assets.rs`.
pub fn gltf_scene_asset_label(scene : GltfSceneIndex) -> GltfAssetLabel {
  GltfAssetLabel::Scene(scene.index())
}

///|
pub fn gltf_node_asset_label(node : GltfNodeIndex) -> GltfAssetLabel {
  GltfAssetLabel::Node(node.index())
}

///|
pub fn gltf_mesh_asset_label(mesh : GltfMeshIndex) -> GltfAssetLabel {
  GltfAssetLabel::Mesh(mesh.index())
}

///|
pub fn gltf_primitive_asset_label(
  primitive : GltfPrimitiveIndex,
) -> GltfAssetLabel {
  GltfAssetLabel::Primitive(primitive.mesh_index(), primitive.primitive_index())
}

///|
pub fn gltf_skin_asset_label(skin : GltfSkinIndex) -> GltfAssetLabel {
  GltfAssetLabel::Skin(skin.index())
}
