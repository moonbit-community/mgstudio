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
  indirect_draw_count : Int,
  instance_vertex_buffer_id : Int,
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
  world_from_local : Array[Float]?,
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
  emissive_exposure_weight : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_texture_id : Int,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_texture_id : Int,
  specular_tint_texture_id : Int,
  clearcoat_texture_id : Int,
  clearcoat_roughness_texture_id : Int,
  clearcoat_normal_texture_id : Int,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  attenuation_color_r : Float,
  attenuation_color_g : Float,
  attenuation_color_b : Float,
  attenuation_distance : Float,
  clearcoat : Float,
  clearcoat_perceptual_roughness : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  forward_decal_inv_depth_fade_factor : Float,
  lightmap_exposure : Float,
  lightmap_texture_id : Int,
  lightmap_slab_index : Int,
  lightmap_slot_index : Int,
  lightmap_slab_texture_ids : Array[Int],
  lightmap_uv_min_x : Float,
  lightmap_uv_min_y : Float,
  lightmap_uv_max_x : Float,
  lightmap_uv_max_y : Float,
  deferred_lighting_pass_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  mesh_flags : UInt,
  cull_mode : Int,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  morph_weights_index : Int,
  previous_morph_weights_index : Int,
  morph_targets_texture_id : Int,
  material_pipeline_id : UInt64,
  transparent : Bool,
  material_extension_bind_group_data : @render_resource.MaterialBindGroupResolvedData,
) -> Unit raise GpuBackendError {
  let draw_vertex_shader_path = if pass_kind == 0 {
    vertex_shader_path
  } else {
    None
  }
  let draw_fragment_shader_path = if pass_kind == 0 {
    fragment_shader_path
  } else {
    None
  }
  let forward_decal = (material_flags & (1U << 20)) != 0U
  let lightmapped = lightmap_texture_id >= 0
  guard mesh3d_pipeline_for_current_pass(
      self,
      transparent,
      material_flags,
      material_pipeline_id,
      forward_decal,
      mesh.primitive_topology,
      cull_mode,
      draw_vertex_shader_path,
      draw_fragment_shader_path,
      skinning_key_hi >= 0,
      ps.tonemap_in_shader,
      ps.tonemapping_mode,
      ps.deband_dither_enabled,
      pass_kind_shadow_filter_method(ps.pass_kind),
      lightmapped~,
    )
    is Some(pipeline) else {
    return
  }
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    self, material_pipeline_id,
  )
  let material_layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    self,
    material_pipeline_id,
    material_descriptor,
    default_lightmapped=lightmapped,
  )
  let instance_vertex_buffer = if instance_vertex_buffer_id >= 0 {
    guard self.mesh3d_instance_vertex_buffer(instance_vertex_buffer_id)
      is Some(buffer) else {
      return
    }
    Some(buffer)
  } else {
    None
  }
  let indirect_first_instance_supported = self.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  let use_indirect = indirect_first_instance_supported &&
    instance_vertex_buffer is None &&
    indirect_parameters_index >= 0 &&
    indirect_kind != MESH3D_DRAW_INDIRECT_KIND_NONE
  let mut draw_buffer : @wgpu.Buffer? = None
  let mut draw_bind_group : @wgpu.BindGroup? = None
  let mut draw_write_offset = 0UL
  let mut draw_index = 0U
  let mut morph_descriptor_index = 0U
  if draw_storage_index >= 0 ||
    self.mesh3d_gpu_instance_builder_enabled ||
    use_indirect {
    let desired_draw_index = if draw_storage_index >= 0 {
      draw_storage_index
    } else {
      self.mesh3d_instance_draw_used / MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    }
    let draw_count = if indirect_draw_count <= 0 {
      1
    } else {
      indirect_draw_count
    }
    let next_used_int = (desired_draw_index + draw_count) *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    if next_used_int < 0 {
      return
    }
    let required_size = next_used_int.to_uint64()
    guard self.ensure_mesh3d_instance_draw_binding_with_layout(
        material_pipeline_id,
        material_layout_entry.draw_bind_group_layout,
        material_layout_entry.draw_bind_group_layout_descriptor,
        required_size,
        lightmap_texture_id,
        lightmap_slab_index,
        lightmap_slab_texture_ids,
        morph_targets_texture_id,
        desired_draw_index.reinterpret_as_uint(),
        morph_weights_index,
        previous_morph_weights_index,
      )
      is Some((instance_draw_buf, instance_draw_bg)) else {
      return
    }
    draw_index = desired_draw_index.reinterpret_as_uint()
    morph_descriptor_index = desired_draw_index.reinterpret_as_uint()
    draw_buffer = Some(instance_draw_buf)
    draw_bind_group = Some(instance_draw_bg)
    draw_write_offset = desired_draw_index.to_uint64() *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES
    if self.mesh3d_instance_draw_used < next_used_int {
      self.mesh3d_instance_draw_used = next_used_int
    }
  } else {
    let mesh3d_draw_slot_index = self.mesh3d_draw_slot_used
    guard self.ensure_mesh3d_draw_slot_with_layout(
        mesh3d_draw_slot_index,
        material_pipeline_id,
        material_layout_entry.draw_bind_group_layout,
        material_layout_entry.draw_bind_group_layout_descriptor,
        lightmap_texture_id,
        lightmap_slab_index,
        lightmap_slab_texture_ids,
        morph_targets_texture_id,
        mesh3d_draw_slot_index.reinterpret_as_uint(),
        morph_weights_index,
        previous_morph_weights_index,
      )
      is Some(draw_slot) else {
      return
    }
    self.mesh3d_draw_slot_used = mesh3d_draw_slot_index + 1
    draw_buffer = Some(draw_slot.buffer)
    draw_bind_group = Some(draw_slot.bind_group)
    draw_write_offset = 0UL
    draw_index = 0U
    morph_descriptor_index = mesh3d_draw_slot_index.reinterpret_as_uint()
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
  let resolved_specular_texture_id = if specular_texture_id < 0 {
    -1
  } else {
    specular_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  let resolved_clearcoat_texture_id = if clearcoat_texture_id < 0 {
    -1
  } else {
    clearcoat_texture_id
  }
  let resolved_clearcoat_roughness_texture_id = if clearcoat_roughness_texture_id <
    0 {
    -1
  } else {
    clearcoat_roughness_texture_id
  }
  let resolved_clearcoat_normal_texture_id = if clearcoat_normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
  } else {
    clearcoat_normal_texture_id
  }
  let resolved_transmission_source_texture_id = if ps.transmission_source_texture_id <
    0 {
    ensure_transmission_source_fallback_texture(self).id
  } else {
    ps.transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if ps.point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    ps.point_shadow_texture_id
  }
  let resolved_directional_shadow_texture_id = if ps.directional_shadow_texture_id <
    0 {
    ensure_directional_shadow_fallback_texture(self).id
  } else {
    ps.directional_shadow_texture_id
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
  guard resolve_mesh3d_texture(self, resolved_specular_texture_id)
    is Some(specular_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_texture_id)
    is Some(clearcoat_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_roughness_texture_id)
    is Some(clearcoat_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_normal_texture_id)
    is Some(clearcoat_normal_texture) else {
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
  guard resolve_mesh3d_texture(self, resolved_directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
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
  let specular_textured = specular_texture_id >= 0
  let specular_tint_textured = specular_tint_texture_id >= 0
  let clearcoat_textured = clearcoat_texture_id >= 0
  let clearcoat_roughness_textured = clearcoat_roughness_texture_id >= 0
  let clearcoat_normal_textured = clearcoat_normal_texture_id >= 0
  let point_shadow_textured = ps.point_shadow_texture_id >= 0
  ignore(point_shadow_enabled)
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
    specular_textured ||
    specular_tint_textured ||
    clearcoat_textured ||
    clearcoat_roughness_textured ||
    clearcoat_normal_textured {
    1.0F
  } else {
    0.0F
  }
  guard mesh3d_pass_uniform_state_get_or_create(
      self, ps, preprocess_camera_key_hi, preprocess_camera_key_lo, pass_kind,
    )
    is Some(pass_uniforms) else {
    return
  }
  guard draw_buffer is Some(active_draw_buffer) else { return }
  guard draw_bind_group is Some(active_draw_bg) else { return }
  ignore(skinning_key_lo)
  let draw_preuploaded = draw_storage_index >= 0 &&
    self.mesh3d_prepared_draw_pass_kind == ps.pass_kind &&
    self.mesh3d_prepared_draw_camera_key_hi == preprocess_camera_key_hi &&
    self.mesh3d_prepared_draw_camera_key_lo == preprocess_camera_key_lo &&
    draw_storage_index < self.mesh3d_prepared_draw_count
  if !use_indirect &&
    draw_storage_index >= 0 &&
    indirect_draw_count > 1 &&
    !draw_preuploaded {
    return
  }
  if !draw_preuploaded {
    let draw_bytes = mesh3d_draw_uniform_bytes(
      world_from_local,
      x,
      y,
      z,
      rotation_x,
      rotation_y,
      rotation_z,
      rotation_w,
      scale_x,
      scale_y,
      scale_z,
      color_r,
      color_g,
      color_b,
      color_a,
      uv_transform_a_value,
      uv_transform_b_value,
      uv_transform_c_value,
      uv_transform_d_value,
      uv_transform_tx_value,
      uv_transform_ty_value,
      uv_transform_mode_value,
      emissive_r,
      emissive_g,
      emissive_b,
      metallic,
      roughness,
      reflectance,
      parallax_depth_scale,
      max_parallax_layer_count,
      max_relief_mapping_search_steps,
      anisotropy_strength,
      anisotropy_rotation,
      specular_tint_r,
      specular_tint_g,
      specular_tint_b,
      diffuse_transmission,
      specular_transmission,
      thickness,
      ior,
      alpha_cutoff,
      runtime_material_flags,
      if skinning_key_hi >= 0 {
        skinning_key_hi.reinterpret_as_uint()
      } else {
        0xFFFFFFFFU
      },
      mesh_flags,
      draw_point_shadow_depth_bias,
      lightmap_texture_id,
      lightmap_slot_index,
      lightmap_uv_min_x,
      lightmap_uv_min_y,
      lightmap_uv_max_x,
      lightmap_uv_max_y,
      mesh.vertex_start,
      morph_descriptor_index,
    )
    self.queue.write_buffer(active_draw_buffer, draw_write_offset, draw_bytes)
  }
  let (view_bg, binding_arrays_bg) = mesh3d_frame_view_bg_cache_get_or_create(
    self,
    material_pipeline_id,
    material_descriptor,
    ps.tonemap_in_shader,
    pass_uniforms,
    transmission_source_texture,
    point_shadow_texture,
    directional_shadow_texture,
    environment_diffuse_texture,
    environment_specular_texture,
    ps.prepass_depth_texture_id,
    ps.prepass_normal_texture_id,
    ps.prepass_motion_vector_texture_id,
    ps.prepass_deferred_texture_id,
    ps.tonemapping_mode,
    ps.tonemapping_agx_lut_texture_id,
    ps.tonemapping_tony_lut_texture_id,
    ps.tonemapping_blender_lut_texture_id,
    pbr_blue_noise_texture_id=ps.pbr_blue_noise_texture_id,
    pbr_area_light_luts_texture_id=ps.pbr_area_light_luts_texture_id,
    pbr_dfg_lut_texture_id=ps.pbr_dfg_lut_texture_id,
  )
  let material_bg = if material_descriptor is Some(_) &&
    mesh3d_descriptor_material_layout(material_descriptor) is None {
    None
  } else {
    Some(
      mesh3d_material_cache_get_or_create(
        self,
        material_pipeline_id,
        material_descriptor,
        base_texture,
        normal_texture,
        emissive_texture,
        metallic_roughness_texture,
        occlusion_texture,
        depth_texture,
        anisotropy_texture,
        specular_texture,
        specular_tint_texture,
        clearcoat_texture,
        clearcoat_roughness_texture,
        clearcoat_normal_texture,
        mesh3d_standard_material_uniform_bytes(
          color_r, color_g, color_b, color_a, uv_transform_a_value, uv_transform_b_value,
          uv_transform_c_value, uv_transform_d_value, uv_transform_tx_value, uv_transform_ty_value,
          emissive_r, emissive_g, emissive_b, emissive_exposure_weight, metallic,
          roughness, reflectance, attenuation_color_r, attenuation_color_g, attenuation_color_b,
          attenuation_distance, clearcoat, clearcoat_perceptual_roughness, parallax_depth_scale,
          max_parallax_layer_count, max_relief_mapping_search_steps, anisotropy_strength,
          anisotropy_rotation, specular_tint_r, specular_tint_g, specular_tint_b,
          diffuse_transmission, specular_transmission, thickness, ior, alpha_cutoff,
          runtime_material_flags, lightmap_exposure, deferred_lighting_pass_id,
        ),
        forward_decal_inv_depth_fade_factor~,
        material_extension_bind_group_data~,
      ),
    )
  }
  pass.set_pipeline(pipeline)
  pass.set_bind_group(
    0U,
    view_bg,
    mesh3d_descriptor_view_bind_group_dynamic_offsets(
      material_descriptor,
      0,
      light_probes_uniform_offset=ps.light_probes_uniform_offset,
    ),
  )
  pass.set_bind_group(1U, binding_arrays_bg, [])
  pass.set_bind_group(
    2U,
    active_draw_bg,
    mesh3d_draw_bind_group_dynamic_offsets(
      material_layout_entry.draw_bind_group_layout_descriptor,
      morph_weights_index,
      previous_morph_weights_index,
    ),
  )
  if material_bg is Some(bind_group) {
    pass.set_bind_group(3U, bind_group, [])
  }
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
  let direct_instance_count = match instance_vertex_buffer {
    Some(buffer) => {
      pass.set_vertex_buffer(1U, buffer.buffer, 0UL, buffer.byte_size)
      buffer.length.reinterpret_as_uint()
    }
    None => indirect_draw_count.reinterpret_as_uint()
  }
  render_diagnostics_record_mesh3d_executed_draw()
  if use_indirect &&
    mesh3d_preprocess_camera_upload_state(
      self, preprocess_camera_key_hi, preprocess_camera_key_lo,
    )
    is Some(preprocess_state) {
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED &&
      preprocess_state.non_indexed_indirect_parameters_buffer
      is Some(non_indexed_indirect_parameters_buffer) {
      if indirect_draw_count > 1 {
        pass.multi_draw_indirect(
          non_indexed_indirect_parameters_buffer,
          mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
          indirect_draw_count.reinterpret_as_uint(),
        )
      } else {
        pass.draw_indirect(
          non_indexed_indirect_parameters_buffer,
          mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
        )
      }
      return
    }
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_INDEXED &&
      preprocess_state.indexed_indirect_parameters_buffer
      is Some(indexed_indirect_parameters_buffer) {
      gpu_mesh_bind_index_buffer(pass, mesh)
      if indirect_draw_count > 1 {
        pass.multi_draw_indexed_indirect(
          indexed_indirect_parameters_buffer,
          mesh3d_indexed_indirect_offset(indirect_parameters_index),
          indirect_draw_count.reinterpret_as_uint(),
        )
      } else {
        pass.draw_indexed_indirect(
          indexed_indirect_parameters_buffer,
          mesh3d_indexed_indirect_offset(indirect_parameters_index),
        )
      }
      return
    }
  }
  if mesh.index_count == 0U {
    pass.draw(
      mesh.vertex_count,
      direct_instance_count,
      mesh.vertex_start,
      draw_index,
    )
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      direct_instance_count,
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      draw_index,
    )
  }
}
