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
priv struct MeshGpuBatchSetKey3d {
  indirect_kind : Int
  preprocess_camera_key_hi : Int
  preprocess_camera_key_lo : Int
  texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  anisotropy_texture_id : Int
  specular_texture_id : Int
  specular_tint_texture_id : Int
  material_flags : UInt
  material_bind_group_index : Int
  cull_mode : Int
  vertex_shader_path : String?
  fragment_shader_path : String?
  material_pipeline_id : UInt64
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  environment_map_intensity : Float
  environment_map_rotation : @math.Quat
  mesh_flags : UInt
  skinned : Bool
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
  uv_transform : @transform.Affine2
  emissive : @color.Color
  emissive_exposure_weight : Float
  metallic : Float
  surface_roughness : Float
  reflectance : Float
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  max_relief_mapping_search_steps : Float
  anisotropy_strength : Float
  anisotropy_rotation : Float
  specular_tint : @color.Color
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  attenuation_color : @color.Color
  attenuation_distance : Float
  clearcoat : Float
  clearcoat_perceptual_roughness : Float
  alpha_cutoff : Float
  lightmap_exposure : Float
  lightmap_slab_index : Int
  deferred_lighting_pass_id : Int
  transmission_source_texture_id : Int
  transmission_blur_taps : Float
  transmission_steps : Float
}

///|
priv struct MeshGpuBinKey3d {
  mesh_id : Int
}

///|
priv struct MeshGpuBinnedRenderPhaseBatch3d {
  batch_set_key : MeshGpuBatchSetKey3d
  bin_key : MeshGpuBinKey3d
  representative_payload_index : Int
  instance_count : Int
}

///|
priv struct MeshGpuBinnedRenderPhase3d {
  payloads : Array[@pbr_render.MeshGpuDrawPayload3d]
  entries : Array[@render.HostMesh3dMainPassDrawEntry]
  batches : Array[MeshGpuBinnedRenderPhaseBatch3d]
}

///|
fn render3d_mesh_gpu_binned_phase_new() -> MeshGpuBinnedRenderPhase3d {
  { payloads: [], entries: [], batches: [] }
}

///|
fn render3d_mesh_gpu_batch_set_key(
  payload : @pbr_render.MeshGpuDrawPayload3d,
) -> MeshGpuBatchSetKey3d {
  {
    indirect_kind: payload.indirect_kind,
    preprocess_camera_key_hi: payload.preprocess_camera_key_hi,
    preprocess_camera_key_lo: payload.preprocess_camera_key_lo,
    texture_id: payload.texture_id,
    normal_texture_id: payload.normal_texture_id,
    emissive_texture_id: payload.emissive_texture_id,
    metallic_roughness_texture_id: payload.metallic_roughness_texture_id,
    occlusion_texture_id: payload.occlusion_texture_id,
    depth_texture_id: payload.depth_texture_id,
    anisotropy_texture_id: payload.anisotropy_texture_id,
    specular_texture_id: payload.specular_texture_id,
    specular_tint_texture_id: payload.specular_tint_texture_id,
    material_flags: payload.material_flags,
    material_bind_group_index: payload.material_bind_group_index,
    cull_mode: payload.cull_mode,
    vertex_shader_path: payload.vertex_shader_path,
    fragment_shader_path: payload.fragment_shader_path,
    material_pipeline_id: payload.material_pipeline_id.id(),
    point_shadow_texture_id: payload.point_shadow_texture_id,
    point_shadow_enabled: payload.point_shadow_enabled,
    point_shadow_depth_bias: payload.point_shadow_depth_bias,
    environment_diffuse_texture_id: payload.environment_diffuse_texture_id,
    environment_specular_texture_id: payload.environment_specular_texture_id,
    environment_map_intensity: payload.environment_map_intensity,
    environment_map_rotation: payload.environment_map_rotation,
    mesh_flags: payload.mesh_flags,
    skinned: payload.skinning_key_hi >= 0,
    color_r: payload.color_r,
    color_g: payload.color_g,
    color_b: payload.color_b,
    color_a: payload.color_a,
    uv_transform: payload.uv_transform,
    emissive: payload.emissive,
    emissive_exposure_weight: payload.emissive_exposure_weight,
    metallic: payload.metallic,
    surface_roughness: payload.surface_roughness,
    reflectance: payload.reflectance,
    parallax_depth_scale: payload.parallax_depth_scale,
    max_parallax_layer_count: payload.max_parallax_layer_count,
    max_relief_mapping_search_steps: payload.max_relief_mapping_search_steps,
    anisotropy_strength: payload.anisotropy_strength,
    anisotropy_rotation: payload.anisotropy_rotation,
    specular_tint: payload.specular_tint,
    diffuse_transmission: payload.diffuse_transmission,
    specular_transmission: payload.specular_transmission,
    thickness: payload.thickness,
    ior: payload.ior,
    attenuation_color: payload.attenuation_color,
    attenuation_distance: payload.attenuation_distance,
    clearcoat: payload.clearcoat,
    clearcoat_perceptual_roughness: payload.clearcoat_perceptual_roughness,
    alpha_cutoff: payload.alpha_cutoff,
    lightmap_exposure: payload.lightmap_exposure,
    lightmap_slab_index: payload.lightmap_slab_index,
    deferred_lighting_pass_id: payload.deferred_lighting_pass_id,
    transmission_source_texture_id: payload.transmission_source_texture_id,
    transmission_blur_taps: payload.transmission_blur_taps,
    transmission_steps: payload.transmission_steps,
  }
}

///|
fn render3d_mesh_gpu_bin_key(
  payload : @pbr_render.MeshGpuDrawPayload3d,
) -> MeshGpuBinKey3d {
  { mesh_id: payload.mesh_id }
}

///|
fn render3d_mesh_gpu_batch_set_key_eq(
  lhs : MeshGpuBatchSetKey3d,
  rhs : MeshGpuBatchSetKey3d,
) -> Bool {
  lhs.indirect_kind == rhs.indirect_kind &&
  lhs.preprocess_camera_key_hi == rhs.preprocess_camera_key_hi &&
  lhs.preprocess_camera_key_lo == rhs.preprocess_camera_key_lo &&
  lhs.texture_id == rhs.texture_id &&
  lhs.normal_texture_id == rhs.normal_texture_id &&
  lhs.emissive_texture_id == rhs.emissive_texture_id &&
  lhs.metallic_roughness_texture_id == rhs.metallic_roughness_texture_id &&
  lhs.occlusion_texture_id == rhs.occlusion_texture_id &&
  lhs.depth_texture_id == rhs.depth_texture_id &&
  lhs.anisotropy_texture_id == rhs.anisotropy_texture_id &&
  lhs.specular_texture_id == rhs.specular_texture_id &&
  lhs.specular_tint_texture_id == rhs.specular_tint_texture_id &&
  lhs.material_flags == rhs.material_flags &&
  lhs.material_bind_group_index == rhs.material_bind_group_index &&
  lhs.cull_mode == rhs.cull_mode &&
  lhs.vertex_shader_path == rhs.vertex_shader_path &&
  lhs.fragment_shader_path == rhs.fragment_shader_path &&
  lhs.material_pipeline_id == rhs.material_pipeline_id &&
  lhs.point_shadow_texture_id == rhs.point_shadow_texture_id &&
  lhs.point_shadow_enabled == rhs.point_shadow_enabled &&
  lhs.point_shadow_depth_bias == rhs.point_shadow_depth_bias &&
  lhs.environment_diffuse_texture_id == rhs.environment_diffuse_texture_id &&
  lhs.environment_specular_texture_id == rhs.environment_specular_texture_id &&
  lhs.environment_map_intensity == rhs.environment_map_intensity &&
  lhs.environment_map_rotation.x == rhs.environment_map_rotation.x &&
  lhs.environment_map_rotation.y == rhs.environment_map_rotation.y &&
  lhs.environment_map_rotation.z == rhs.environment_map_rotation.z &&
  lhs.environment_map_rotation.w == rhs.environment_map_rotation.w &&
  lhs.mesh_flags == rhs.mesh_flags &&
  lhs.skinned == rhs.skinned &&
  lhs.color_r == rhs.color_r &&
  lhs.color_g == rhs.color_g &&
  lhs.color_b == rhs.color_b &&
  lhs.color_a == rhs.color_a &&
  lhs.uv_transform.a == rhs.uv_transform.a &&
  lhs.uv_transform.b == rhs.uv_transform.b &&
  lhs.uv_transform.c == rhs.uv_transform.c &&
  lhs.uv_transform.d == rhs.uv_transform.d &&
  lhs.uv_transform.tx == rhs.uv_transform.tx &&
  lhs.uv_transform.ty == rhs.uv_transform.ty &&
  lhs.emissive.r == rhs.emissive.r &&
  lhs.emissive.g == rhs.emissive.g &&
  lhs.emissive.b == rhs.emissive.b &&
  lhs.emissive_exposure_weight == rhs.emissive_exposure_weight &&
  lhs.metallic == rhs.metallic &&
  lhs.surface_roughness == rhs.surface_roughness &&
  lhs.reflectance == rhs.reflectance &&
  lhs.parallax_depth_scale == rhs.parallax_depth_scale &&
  lhs.max_parallax_layer_count == rhs.max_parallax_layer_count &&
  lhs.max_relief_mapping_search_steps == rhs.max_relief_mapping_search_steps &&
  lhs.anisotropy_strength == rhs.anisotropy_strength &&
  lhs.anisotropy_rotation == rhs.anisotropy_rotation &&
  lhs.specular_tint.r == rhs.specular_tint.r &&
  lhs.specular_tint.g == rhs.specular_tint.g &&
  lhs.specular_tint.b == rhs.specular_tint.b &&
  lhs.diffuse_transmission == rhs.diffuse_transmission &&
  lhs.specular_transmission == rhs.specular_transmission &&
  lhs.thickness == rhs.thickness &&
  lhs.ior == rhs.ior &&
  lhs.attenuation_color.r == rhs.attenuation_color.r &&
  lhs.attenuation_color.g == rhs.attenuation_color.g &&
  lhs.attenuation_color.b == rhs.attenuation_color.b &&
  lhs.attenuation_distance == rhs.attenuation_distance &&
  lhs.clearcoat == rhs.clearcoat &&
  lhs.clearcoat_perceptual_roughness == rhs.clearcoat_perceptual_roughness &&
  lhs.alpha_cutoff == rhs.alpha_cutoff &&
  lhs.lightmap_exposure == rhs.lightmap_exposure &&
  lhs.lightmap_slab_index == rhs.lightmap_slab_index &&
  lhs.deferred_lighting_pass_id == rhs.deferred_lighting_pass_id &&
  lhs.transmission_source_texture_id == rhs.transmission_source_texture_id &&
  lhs.transmission_blur_taps == rhs.transmission_blur_taps &&
  lhs.transmission_steps == rhs.transmission_steps
}

///|
fn render3d_mesh_gpu_bin_key_eq(
  lhs : MeshGpuBinKey3d,
  rhs : MeshGpuBinKey3d,
) -> Bool {
  lhs.mesh_id == rhs.mesh_id
}

///|
fn render3d_mesh_gpu_payload_follows_batch(
  previous : @pbr_render.MeshGpuDrawPayload3d,
  next : @pbr_render.MeshGpuDrawPayload3d,
) -> Bool {
  if previous.draw_storage_index + 1 != next.draw_storage_index {
    return false
  }
  if previous.indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NONE {
    return true
  }
  previous.indirect_parameters_index + 1 == next.indirect_parameters_index
}

///|
fn render3d_mesh_gpu_binned_phase_push(
  phase : MeshGpuBinnedRenderPhase3d,
  payload : @pbr_render.MeshGpuDrawPayload3d,
) -> Unit {
  let batch_set_key = render3d_mesh_gpu_batch_set_key(payload)
  let bin_key = render3d_mesh_gpu_bin_key(payload)
  let payload_index = phase.payloads.length()
  let can_extend = if payload_index == 0 || phase.batches.length() == 0 {
    false
  } else {
    let previous_payload = phase.payloads[payload_index - 1]
    let previous_batch = phase.batches[phase.batches.length() - 1]
    render3d_mesh_gpu_batch_set_key_eq(
      previous_batch.batch_set_key,
      batch_set_key,
    ) &&
    render3d_mesh_gpu_bin_key_eq(previous_batch.bin_key, bin_key) &&
    render3d_mesh_gpu_payload_follows_batch(previous_payload, payload)
  }
  phase.payloads.push(payload)
  phase.entries.push(@pbr_render.render3d_host_main_pass_draw_entry(payload))
  if can_extend {
    let batch_index = phase.batches.length() - 1
    let batch = phase.batches[batch_index]
    phase.batches[batch_index] = MeshGpuBinnedRenderPhaseBatch3d::{
      ..batch,
      instance_count: batch.instance_count + 1,
    }
  } else {
    phase.batches.push({
      batch_set_key,
      bin_key,
      representative_payload_index: payload_index,
      instance_count: 1,
    })
  }
}

///|
fn render3d_mesh_gpu_binned_phase_entries(
  phase : MeshGpuBinnedRenderPhase3d,
) -> Array[@render.HostMesh3dMainPassDrawEntry] {
  phase.entries
}

///|
fn render3d_mesh_gpu_binned_phase_batch_count(
  phase : MeshGpuBinnedRenderPhase3d,
) -> Int {
  phase.batches.length()
}

///|
fn render3d_draw_mesh_gpu_binned_phase(
  phase : MeshGpuBinnedRenderPhase3d,
) -> Unit {
  @app.timeline_trace_emit_counter_int(
    "render_3d_binned_phase_draw_commands",
    phase.batches.length(),
  )
  for batch in phase.batches {
    ignore(batch.batch_set_key)
    ignore(batch.bin_key)
    let representative_payload = phase.payloads[batch.representative_payload_index]
    @pbr_render.render3d_draw_mesh_gpu_payload(@pbr_render.MeshGpuDrawPayload3d::{
      ..representative_payload,
      indirect_draw_count: batch.instance_count,
    })
  }
}
