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
// Bevy source: `bevy/crates/bevy_pbr/src/extended_material.rs`.

///|
pub type ExtendedMaterialMetadata3d = @material.ExtendedMaterialMetadata3d

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
pub fn pbr_extended_material_metadata_default() -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::default()
}

///|
pub fn pbr_extended_material_metadata_new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::new(extension_tag)
}

///|
pub fn pbr_forward_decal_material_ext_default() -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::default()
}

///|
pub fn pbr_forward_decal_material_ext_new(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::new(depth_fade_factor)
}
