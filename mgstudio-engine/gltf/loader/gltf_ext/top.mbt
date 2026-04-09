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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/gltf_ext/mod.rs`.
// Bridge surface for shared glTF extras and asset labels.
pub using @root_gltf {type GltfAssetLabel}

///|
pub using @root_gltf {type GltfExtras}

///|
pub using @root_gltf {type GltfMaterialExtras}

///|
pub using @root_gltf {type GltfMaterialName}

///|
pub using @root_gltf {type GltfMeshExtras}

///|
pub using @root_gltf {type GltfMeshIndex}

///|
pub using @root_gltf {type GltfNodeIndex}

///|
pub using @root_gltf {type GltfPrimitiveIndex}

///|
pub using @root_gltf {type GltfSceneExtras}

///|
pub using @root_gltf {type GltfSceneIndex}

///|
pub using @root_gltf {type GltfSkinIndex}

///|
pub fn gltf_extras(value : String) -> GltfExtras {
  GltfExtras::new(value)
}

///|
pub fn gltf_animation_asset_label(animation_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Animation(animation_index)
}

///|
pub fn gltf_inverse_bind_matrices_asset_label(
  skin_index : Int,
) -> GltfAssetLabel {
  GltfAssetLabel::InverseBindMatrices(skin_index)
}
