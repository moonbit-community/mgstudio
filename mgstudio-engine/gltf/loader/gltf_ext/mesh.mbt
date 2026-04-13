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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/gltf_ext/mesh.rs`.
pub fn gltf_mesh_extras(value : String) -> GltfMeshExtras {
  GltfMeshExtras::new(value)
}

///|
pub fn gltf_mesh_index(mesh_index : Int) -> GltfMeshIndex {
  GltfMeshIndex::new(mesh_index)
}

///|
pub fn gltf_primitive_index(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfPrimitiveIndex {
  GltfPrimitiveIndex::new(mesh_index, primitive_index)
}

///|
pub fn gltf_skin_index(skin_index : Int) -> GltfSkinIndex {
  GltfSkinIndex::new(skin_index)
}

///|
pub fn gltf_mesh_asset_label(mesh_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Mesh(mesh_index)
}

///|
pub fn gltf_primitive_asset_label(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfAssetLabel {
  GltfAssetLabel::Primitive(mesh_index, primitive_index)
}

///|
pub fn gltf_skin_asset_label(skin_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Skin(skin_index)
}
