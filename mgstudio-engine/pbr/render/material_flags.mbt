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
pub const RENDER3D_PASS_KIND_BASE_SCENE : Int = 0

///|
pub const RENDER3D_PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
pub const RENDER3D_PASS_KIND_BASE_POINT_SHADOW : Int = 2

///|
pub const RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
pub const RENDER3D_PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
pub const RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
pub const STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT : UInt = 1U << 0

///|
pub const STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT : UInt = 1U << 1

///|
pub const STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT : UInt = 1U <<
  2

///|
pub const STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT : UInt = 1U << 3

///|
pub const STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT : UInt = 1U << 4

///|
pub const STANDARD_MATERIAL_FLAGS_UNLIT_BIT : UInt = 1U << 5

///|
pub const STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y : UInt = 1U << 7

///|
pub const STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT : UInt = 1U << 9

///|
pub const STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT : UInt = 1U << 17

///|
pub const STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT : UInt = 1U << 19

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE : UInt = 0U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK : UInt = 1U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND : UInt = 2U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED : UInt = 3U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD : UInt = 4U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY : UInt = 5U << 29

///|
pub const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE : UInt = 6U << 29

///|
pub fn render3d_pass_kind_encode(
  base_kind : Int,
  postprocess_enabled : Bool,
  fog_enabled : Bool,
  decal_enabled : Bool,
) -> Int {
  let mut value = base_kind
  if !postprocess_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG
  }
  if !fog_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_FOG_FLAG
  }
  if !decal_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG
  }
  value
}

///|
fn render3d_standard_material_alpha_mode_flags(
  alpha_mode : @material.AlphaMode3d,
) -> UInt {
  match alpha_mode {
    Opaque => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE
    Mask(_) => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
    Blend => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND
    Premultiplied => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED
    Add => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD
    Multiply => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY
    AlphaToCoverage => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE
  }
}

///|
pub fn render3d_standard_material_alpha_cutoff(
  alpha_mode : @material.AlphaMode3d,
) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
pub fn render3d_standard_material_flags(
  material : @material.StandardMaterial,
  base_color_texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
) -> UInt {
  let mut flags = render3d_standard_material_alpha_mode_flags(
    material.alpha_mode,
  )
  if base_color_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT
  }
  if emissive_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT
  }
  if metallic_roughness_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT
  }
  if occlusion_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT
  }
  if material.cull_mode is None {
    flags = flags | STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT
  }
  if material.unlit {
    flags = flags | STANDARD_MATERIAL_FLAGS_UNLIT_BIT
  }
  if normal_texture_id >= 0 && material.flip_normal_map_y {
    flags = flags | STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y
  }
  if depth_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT
  }
  if anisotropy_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT
  }
  if specular_tint_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT
  }
  flags
}

///|
pub fn render3d_cull_mode_value(
  material : @material.StandardMaterial,
  draw_flags : Int,
) -> Int {
  let draw_cull_mode_base = match material.cull_mode {
    None => 0
    Some(face) =>
      match face {
        @material.Face3d::Front => 1
        @material.Face3d::Back => 2
      }
  }
  draw_cull_mode_base | draw_flags
}

///|
pub fn render3d_apply_extended_material_metadata(
  material : @material.StandardMaterial,
  extension : @material.ExtendedMaterialMetadata3d?,
) -> @material.StandardMaterial {
  guard extension is Some(extension_value) else { return material }
  let mut out = material
  if extension_value.alpha_mode_override is Some(alpha_mode_override) {
    out = out.with_alpha_mode(alpha_mode_override)
  }
  if extension_value.opaque_render_method_override
    is Some(opaque_render_method_override) {
    out = out.with_opaque_render_method(opaque_render_method_override)
  }
  out
}
