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
// Bevy source: `bevy/crates/bevy_gltf/src/material.rs`.
pub fn gltf_material_asset_label(
  material_index : Int,
  is_scale_inverted : Bool,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_material_asset_label(material_index, is_scale_inverted)
}

///|
pub fn gltf_default_material_asset_label() -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_default_material_asset_label()
}

///|
pub fn gltf_material_name(name : String) -> GltfMaterialName {
  @gltf_gltf_ext.gltf_material_name(name)
}

///|
pub fn gltf_material_extras(value : String) -> GltfMaterialExtras {
  @gltf_gltf_ext.gltf_material_extras(value)
}
