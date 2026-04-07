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
const RENDER3D_PASS_KIND_BASE_SCENE : Int = @pbr_render.RENDER3D_PASS_KIND_BASE_SCENE

///|
const RENDER3D_PASS_KIND_BASE_MOTION_VECTOR : Int = @pbr_render.RENDER3D_PASS_KIND_BASE_MOTION_VECTOR

///|
const RENDER3D_PASS_KIND_BASE_POINT_SHADOW : Int = @pbr_render.RENDER3D_PASS_KIND_BASE_POINT_SHADOW

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
fn render3d_pass_kind_encode(
  base_kind : Int,
  postprocess_enabled : Bool,
  fog_enabled : Bool,
  decal_enabled : Bool,
) -> Int {
  @pbr_render.render3d_pass_kind_encode(
    base_kind, postprocess_enabled, fog_enabled, decal_enabled,
  )
}

///|
fn render3d_mesh_draw_flags(mesh : ExtractedMesh3d) -> Int {
  let mut flags = 0
  if mesh.payload.is_forward_decal || mesh.payload.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_standard_material_alpha_cutoff(alpha_mode : AlphaMode3d) -> Float {
  @pbr_render.render3d_standard_material_alpha_cutoff(alpha_mode)
}

///|
fn render3d_standard_material_flags(
  material : StandardMaterial,
  base_color_texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
) -> UInt {
  @pbr_render.render3d_standard_material_flags(
    material, base_color_texture_id, normal_texture_id, emissive_texture_id, metallic_roughness_texture_id,
    occlusion_texture_id, depth_texture_id, anisotropy_texture_id, specular_tint_texture_id,
  )
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  if !deferred_lighting_enabled {
    return OpaqueRendererMethod::Forward
  }
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_apply_extended_material_metadata(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
) -> StandardMaterial {
  @pbr_render.render3d_apply_extended_material_metadata(material, extension)
}
