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

// Bevy-aligned `pbr/render/mesh` container.

///|
pub fn render3d_upload_mesh_handle_cached(
  phase_state_ref : Ref[Render3dPhaseState],
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int {
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return -1
  }
  match phase_state_ref.val.mesh_upload_cache.get(mesh_handle_id) {
    Some(mesh_id) =>
      if mesh_id > 0 {
        mesh_id
      } else {
        let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
          mesh_handle,
        )
        phase_state_ref.val.mesh_upload_cache.set(
          mesh_handle_id, uploaded_mesh_id,
        )
        uploaded_mesh_id
      }
    None => {
      let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
        mesh_handle,
      )
      phase_state_ref.val.mesh_upload_cache.set(
        mesh_handle_id, uploaded_mesh_id,
      )
      uploaded_mesh_id
    }
  }
}

///|
pub struct Render3dMeshUploadCacheState {
  clear_count : Int
}

///|
pub fn Render3dMeshUploadCacheState::default() -> Render3dMeshUploadCacheState {
  Render3dMeshUploadCacheState::{ clear_count: 0 }
}

///|
pub fn render3d_mesh_upload_cache_state_after_clear(
  state : Render3dMeshUploadCacheState,
) -> Render3dMeshUploadCacheState {
  Render3dMeshUploadCacheState::{ clear_count: state.clear_count + 1 }
}

///|
pub fn render3d_clear_mesh_upload_cache(
  phase_state_ref : Ref[Render3dPhaseState],
) -> Unit {
  phase_state_ref.val.mesh_upload_cache.clear()
}

///|
pub(all) struct MeshGpuDrawPayload3d {
  mesh_id : Int
  preprocess_camera_key_hi : Int
  preprocess_camera_key_lo : Int
  draw_storage_index : Int
  indirect_kind : Int
  indirect_parameters_index : Int
  transform : @transform.Transform
  previous_transform : @transform.Transform
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
  texture_id : Int
  uv_transform : @transform.Affine2
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  emissive : @sprite.Color
  metallic : Float
  anisotropy_texture_id : Int
  anisotropy_rotation : Float
  specular_tint_texture_id : Int
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  surface_roughness : Float
  reflectance : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  alpha_cutoff : Float
  material_flags : UInt
  transmission_source_texture_id : Int
  transmission_blur_taps : Float
  transmission_steps : Float
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  environment_map_intensity : Float
  environment_map_rotation : @math.Quat
  specular_tint : @sprite.Color
  anisotropy_strength : Float
  max_relief_mapping_search_steps : Float
  cull_mode : Int
  shader_path : String?
  skinning_key_hi : Int
  skinning_key_lo : Int
}

///|
pub fn render3d_build_mesh_gpu_draw_payload(
  mesh_id : Int,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
  material : @material.StandardMaterial,
  transform : @transform.Transform,
  previous_transform : @transform.Transform,
  draw_color_r : Float,
  draw_color_g : Float,
  draw_color_b : Float,
  draw_alpha : Float,
  texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
  draw_surface_roughness : Float,
  draw_reflectance : Float,
  draw_diffuse_transmission : Float,
  draw_specular_transmission : Float,
  draw_thickness : Float,
  draw_ior : Float,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  environment_map_intensity : Float,
  environment_map_rotation : @math.Quat,
  specular_tint : @sprite.Color,
  anisotropy_strength : Float,
  max_relief_mapping_search_steps : Float,
  draw_flags : Int,
  forward_decal? : Bool = false,
  shader_path? : String? = None,
  skinning_key_hi? : Int = -1,
  skinning_key_lo? : Int = -1,
) -> MeshGpuDrawPayload3d {
  let material_flags = render3d_standard_material_flags(
    material,
    texture_id,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    anisotropy_texture_id,
    specular_tint_texture_id,
    forward_decal~,
  )
  MeshGpuDrawPayload3d::{
    mesh_id,
    preprocess_camera_key_hi,
    preprocess_camera_key_lo,
    draw_storage_index,
    indirect_kind,
    indirect_parameters_index,
    transform,
    previous_transform,
    color_r: draw_color_r,
    color_g: draw_color_g,
    color_b: draw_color_b,
    color_a: draw_alpha,
    texture_id,
    uv_transform: material.uv_transform,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    emissive: material.emissive,
    metallic: material.metallic,
    anisotropy_texture_id,
    anisotropy_rotation: material.anisotropy_rotation,
    specular_tint_texture_id,
    parallax_depth_scale: material.parallax_depth_scale,
    max_parallax_layer_count: material.max_parallax_layer_count,
    surface_roughness: draw_surface_roughness,
    reflectance: draw_reflectance,
    diffuse_transmission: draw_diffuse_transmission,
    specular_transmission: draw_specular_transmission,
    thickness: draw_thickness,
    ior: draw_ior,
    alpha_cutoff: render3d_standard_material_alpha_cutoff(material.alpha_mode),
    material_flags,
    transmission_source_texture_id,
    transmission_blur_taps,
    transmission_steps,
    point_shadow_texture_id,
    point_shadow_enabled,
    point_shadow_depth_bias,
    environment_diffuse_texture_id,
    environment_specular_texture_id,
    environment_map_intensity,
    environment_map_rotation,
    specular_tint,
    anisotropy_strength,
    max_relief_mapping_search_steps,
    cull_mode: render3d_cull_mode_value(material, draw_flags),
    shader_path,
    skinning_key_hi,
    skinning_key_lo,
  }
}

///|
pub fn render3d_draw_mesh_gpu_payload(payload : MeshGpuDrawPayload3d) -> Unit {
  @render_gpu.host_gpu_draw_mesh3d(
    mesh_id=payload.mesh_id,
    preprocess_camera_key_hi=payload.preprocess_camera_key_hi,
    preprocess_camera_key_lo=payload.preprocess_camera_key_lo,
    draw_storage_index=payload.draw_storage_index,
    indirect_kind=payload.indirect_kind,
    indirect_parameters_index=payload.indirect_parameters_index,
    x=payload.transform.translation.x,
    y=payload.transform.translation.y,
    z=payload.transform.translation.z,
    rotation_x=payload.transform.rotation.x,
    rotation_y=payload.transform.rotation.y,
    rotation_z=payload.transform.rotation.z,
    rotation_w=payload.transform.rotation.w,
    scale_x=payload.transform.scale.x,
    scale_y=payload.transform.scale.y,
    scale_z=payload.transform.scale.z,
    previous_x=payload.previous_transform.translation.x,
    previous_y=payload.previous_transform.translation.y,
    previous_z=payload.previous_transform.translation.z,
    previous_rotation_x=payload.previous_transform.rotation.x,
    previous_rotation_y=payload.previous_transform.rotation.y,
    previous_rotation_z=payload.previous_transform.rotation.z,
    previous_rotation_w=payload.previous_transform.rotation.w,
    previous_scale_x=payload.previous_transform.scale.x,
    previous_scale_y=payload.previous_transform.scale.y,
    previous_scale_z=payload.previous_transform.scale.z,
    color_r=payload.color_r,
    color_g=payload.color_g,
    color_b=payload.color_b,
    color_a=payload.color_a,
    texture_id=payload.texture_id,
    uv_transform_a=payload.uv_transform.a,
    uv_transform_b=payload.uv_transform.b,
    uv_transform_c=payload.uv_transform.c,
    uv_transform_d=payload.uv_transform.d,
    uv_transform_tx=payload.uv_transform.tx,
    uv_transform_ty=payload.uv_transform.ty,
    uv_transform_mode=1.0F,
    normal_texture_id=payload.normal_texture_id,
    emissive_texture_id=payload.emissive_texture_id,
    metallic_roughness_texture_id=payload.metallic_roughness_texture_id,
    occlusion_texture_id=payload.occlusion_texture_id,
    depth_texture_id=payload.depth_texture_id,
    emissive_r=payload.emissive.r,
    emissive_g=payload.emissive.g,
    emissive_b=payload.emissive.b,
    metallic=payload.metallic,
    roughness=payload.surface_roughness,
    reflectance=payload.reflectance,
    parallax_depth_scale=payload.parallax_depth_scale,
    max_parallax_layer_count=payload.max_parallax_layer_count,
    max_relief_mapping_search_steps=payload.max_relief_mapping_search_steps,
    anisotropy_texture_id=payload.anisotropy_texture_id,
    anisotropy_strength=payload.anisotropy_strength,
    anisotropy_rotation=payload.anisotropy_rotation,
    specular_tint_texture_id=payload.specular_tint_texture_id,
    specular_tint_r=payload.specular_tint.r,
    specular_tint_g=payload.specular_tint.g,
    specular_tint_b=payload.specular_tint.b,
    diffuse_transmission=payload.diffuse_transmission,
    specular_transmission=payload.specular_transmission,
    thickness=payload.thickness,
    ior=payload.ior,
    alpha_cutoff=payload.alpha_cutoff,
    material_flags=payload.material_flags,
    transmission_source_texture_id=payload.transmission_source_texture_id,
    transmission_blur_taps=payload.transmission_blur_taps,
    transmission_steps=payload.transmission_steps,
    point_shadow_texture_id=payload.point_shadow_texture_id,
    point_shadow_enabled=payload.point_shadow_enabled,
    point_shadow_depth_bias=payload.point_shadow_depth_bias,
    environment_diffuse_texture_id=payload.environment_diffuse_texture_id,
    environment_specular_texture_id=payload.environment_specular_texture_id,
    environment_map_intensity=payload.environment_map_intensity,
    environment_map_rotation_x=payload.environment_map_rotation.x,
    environment_map_rotation_y=payload.environment_map_rotation.y,
    environment_map_rotation_z=payload.environment_map_rotation.z,
    environment_map_rotation_w=payload.environment_map_rotation.w,
    cull_mode=payload.cull_mode,
    shader_path=payload.shader_path,
    skinning_key_hi=payload.skinning_key_hi,
    skinning_key_lo=payload.skinning_key_lo,
  )
}
