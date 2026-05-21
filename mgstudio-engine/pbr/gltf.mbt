// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_pbr/src/gltf.rs`.

///|
pub struct GltfExtensionHandlerPbrState {
  default_material_label : String
  material_suffix : String
} derive(Eq, Debug)

///|
pub fn GltfExtensionHandlerPbrState::default() -> GltfExtensionHandlerPbrState {
  GltfExtensionHandlerPbrState::{
    default_material_label: "DefaultMaterial/std",
    material_suffix: "/std",
  }
}

///|
pub fn GltfExtensionHandlerPbrState::default_material_label(
  self : GltfExtensionHandlerPbrState,
) -> String {
  self.default_material_label
}

///|
pub fn GltfExtensionHandlerPbrState::standard_material_label(
  self : GltfExtensionHandlerPbrState,
  material_label : String,
) -> String {
  "\{material_label}\{self.material_suffix}"
}

///|
pub fn standard_material_from_gltf_material(
  material : @material.StandardMaterial,
) -> @material.StandardMaterial {
  material
}

///|
pub fn gltf_pbr_mesh_material(
  standard_material_handle : @asset.Handle[@material.StandardMaterial],
) -> @material.MeshMaterial3d {
  @material.MeshMaterial3d::new(standard_material_handle)
}
