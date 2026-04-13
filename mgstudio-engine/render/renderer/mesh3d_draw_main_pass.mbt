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
pub fn GpuBackend::draw_mesh3d_main_pass(
  self : GpuBackend,
  pass : @wgpu.RenderPass,
  ps : GpuPassState,
  mesh : GpuMeshInfo,
  pass_kind : Int,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  uv_transform_mode : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_texture_id : Int,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_texture_id : Int,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  cull_mode : Int,
  shader_path : String?,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  transparent : Bool,
) -> Unit raise GpuBackendError {
  let draw_shader_path = if pass_kind == 0 { shader_path } else { None }
  let forward_decal = (material_flags & (1U << 20)) != 0U
  guard mesh3d_pipeline_for_current_pass(
      self,
      transparent,
      forward_decal,
      mesh.primitive_topology,
      cull_mode,
      draw_shader_path,
    )
    is Some(pipeline) else {
    return
  }
  let indirect_first_instance_supported = self.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  let use_indirect = indirect_first_instance_supported &&
    indirect_parameters_index >= 0 &&
    indirect_kind != MESH3D_DRAW_INDIRECT_KIND_NONE
  let mut draw_buffer : @wgpu.Buffer? = None
  let mut draw_bind_group : @wgpu.BindGroup? = None
  let mut draw_write_offset = 0UL
  let mut draw_index = 0U
  if self.mesh3d_gpu_instance_builder_enabled || use_indirect {
    let desired_draw_index = if draw_storage_index >= 0 {
      draw_storage_index
    } else {
      self.mesh3d_instance_draw_used / MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    }
    let next_used_int = (desired_draw_index + 1) *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    if next_used_int < 0 {
      return
    }
    let required_size = next_used_int.to_uint64()
    guard self.ensure_mesh3d_instance_draw_binding(required_size)
      is Some((instance_draw_buf, instance_draw_bg)) else {
      return
    }
    draw_index = desired_draw_index.reinterpret_as_uint()
    draw_buffer = Some(instance_draw_buf)
    draw_bind_group = Some(instance_draw_bg)
    draw_write_offset = desired_draw_index.to_uint64() *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES
    if self.mesh3d_instance_draw_used < next_used_int {
      self.mesh3d_instance_draw_used = next_used_int
    }
  } else {
    let mesh3d_draw_slot_index = self.mesh3d_draw_slot_used
    guard self.ensure_mesh3d_draw_slot(mesh3d_draw_slot_index)
      is Some(draw_slot) else {
      return
    }
    self.mesh3d_draw_slot_used = mesh3d_draw_slot_index + 1
    draw_buffer = Some(draw_slot.buffer)
    draw_bind_group = Some(draw_slot.bind_group)
    draw_write_offset = 0UL
    draw_index = 0U
  }
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
  } else {
    normal_texture_id
  }
  let resolved_emissive_texture_id = if emissive_texture_id < 0 {
    -1
  } else {
    emissive_texture_id
  }
  let resolved_metallic_roughness_texture_id = if metallic_roughness_texture_id <
    0 {
    -1
  } else {
    metallic_roughness_texture_id
  }
  let resolved_occlusion_texture_id = if occlusion_texture_id < 0 {
    -1
  } else {
    occlusion_texture_id
  }
  let resolved_depth_texture_id = if depth_texture_id < 0 {
    -1
  } else {
    depth_texture_id
  }
  let resolved_anisotropy_texture_id = if anisotropy_texture_id < 0 {
    -1
  } else {
    anisotropy_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  let resolved_transmission_source_texture_id = if ps.transmission_source_texture_id <
    0 {
    -1
  } else {
    ps.transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if ps.point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    ps.point_shadow_texture_id
  }
  let environment_map_enabled = ps.environment_map_intensity > 0.0F
  let resolved_environment_diffuse_texture_id = if environment_map_enabled {
    if ps.environment_diffuse_texture_id >= 0 {
      ps.environment_diffuse_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  let resolved_environment_specular_texture_id = if environment_map_enabled {
    if ps.environment_specular_texture_id >= 0 {
      ps.environment_specular_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  guard resolve_mesh3d_texture(self, resolved_base_texture_id)
    is Some(base_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_emissive_texture_id)
    is Some(emissive_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_metallic_roughness_texture_id)
    is Some(metallic_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_occlusion_texture_id)
    is Some(occlusion_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_depth_texture_id)
    is Some(depth_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_anisotropy_texture_id)
    is Some(anisotropy_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_specular_texture_id)
    is Some(environment_specular_texture) else {
    return
  }
  let textured = texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let emissive_textured = emissive_texture_id >= 0
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let occlusion_textured = occlusion_texture_id >= 0
  let depth_textured = depth_texture_id >= 0
  let anisotropy_textured = anisotropy_texture_id >= 0
  let specular_tint_textured = specular_tint_texture_id >= 0
  let point_shadow_textured = ps.point_shadow_texture_id >= 0
  let draw_point_shadow_enabled = if point_shadow_textured &&
    point_shadow_enabled > 0.5F {
    1.0F
  } else {
    0.0F
  }
  let draw_point_shadow_depth_bias = if point_shadow_textured {
    point_shadow_depth_bias
  } else {
    0.0F
  }
  let uv_transform_a_value = uv_transform_a
  let uv_transform_b_value = uv_transform_b
  let uv_transform_c_value = uv_transform_c
  let uv_transform_d_value = uv_transform_d
  let uv_transform_tx_value = uv_transform_tx
  let uv_transform_ty_value = uv_transform_ty
  let runtime_material_flags = mesh3d_runtime_material_flags(
    material_flags, normal_texture_id, normal_texture,
  )
  let uv_transform_mode_value = if uv_transform_mode < 0.0F {
    -1.0F
  } else if textured ||
    normal_textured ||
    emissive_textured ||
    metallic_roughness_textured ||
    occlusion_textured ||
    depth_textured ||
    anisotropy_textured ||
    specular_tint_textured {
    1.0F
  } else {
    0.0F
  }
  let view_bytes = mesh3d_view_uniform_bytes(ps)
  let draw_bytes = mesh3d_draw_uniform_bytes(
    x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
    color_r, color_g, color_b, color_a, uv_transform_a_value, uv_transform_b_value,
    uv_transform_c_value, uv_transform_d_value, uv_transform_tx_value, uv_transform_ty_value,
    uv_transform_mode_value, emissive_r, emissive_g, emissive_b, metallic, roughness,
    reflectance, parallax_depth_scale, max_parallax_layer_count, max_relief_mapping_search_steps,
    anisotropy_strength, anisotropy_rotation, specular_tint_r, specular_tint_g, specular_tint_b,
    diffuse_transmission, specular_transmission, thickness, ior, alpha_cutoff, runtime_material_flags,
    draw_point_shadow_enabled, draw_point_shadow_depth_bias,
  )
  guard self.mesh3d_view_buf is Some(active_view_buffer) else { return }
  guard draw_buffer is Some(active_draw_buffer) else { return }
  guard draw_bind_group is Some(active_draw_bg) else { return }
  // Bevy-aligned path: skin buffers are prepared before draw.
  let resolved_skin_bg = if skinning_key_hi >= 0 && skinning_key_lo >= 0 {
    match
      mesh3d_skin_bind_group_for_key(self, skinning_key_hi, skinning_key_lo) {
      Some(bind_group) => Some(bind_group)
      None => ensure_mesh3d_skin_default_binding(self)
    }
  } else {
    ensure_mesh3d_skin_default_binding(self)
  }
  guard resolved_skin_bg is Some(active_skin_bg) else { return }
  let view_needs_upload = match self.mesh3d_pass_view_uniform_bytes {
    Some(cached) => cached != view_bytes
    None => true
  }
  if view_needs_upload {
    self.queue.write_buffer(active_view_buffer, 0UL, view_bytes)
    self.mesh3d_pass_view_uniform_bytes = Some(view_bytes)
  }
  self.queue.write_buffer(active_draw_buffer, draw_write_offset, draw_bytes)
  let view_bg = mesh3d_view_bg_cache_get_or_create(
    self, transmission_source_texture, point_shadow_texture, environment_diffuse_texture,
    environment_specular_texture,
  )
  let material_bg = mesh3d_material_cache_get_or_create(
    self, base_texture, normal_texture, emissive_texture, metallic_roughness_texture,
    occlusion_texture, depth_texture, anisotropy_texture, specular_tint_texture,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [])
  pass.set_bind_group(1U, material_bg, [])
  pass.set_bind_group(2U, active_draw_bg, [])
  pass.set_bind_group(3U, active_skin_bg, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  debug_mesh3d_executed_draw_calls_ref.val = debug_mesh3d_executed_draw_calls_ref.val +
    1
  current_frame_mesh3d_executed_draw_calls_ref.val = current_frame_mesh3d_executed_draw_calls_ref.val +
    1
  if use_indirect &&
    mesh3d_preprocess_camera_upload_state(
      self, preprocess_camera_key_hi, preprocess_camera_key_lo,
    )
    is Some(preprocess_state) {
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED &&
      preprocess_state.non_indexed_indirect_parameters_buffer
      is Some(non_indexed_indirect_parameters_buffer) {
      pass.draw_indirect(
        non_indexed_indirect_parameters_buffer,
        mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
      )
      return
    }
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_INDEXED &&
      preprocess_state.indexed_indirect_parameters_buffer
      is Some(indexed_indirect_parameters_buffer) {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed_indirect(
        indexed_indirect_parameters_buffer,
        mesh3d_indexed_indirect_offset(indirect_parameters_index),
      )
      return
    }
  }
  if mesh.primitive_topology == MESH3D_TOPOLOGY_LINE_STRIP {
    pass.draw(mesh.vertex_count, 1U, 0U, draw_index)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, draw_index)
  }
}
