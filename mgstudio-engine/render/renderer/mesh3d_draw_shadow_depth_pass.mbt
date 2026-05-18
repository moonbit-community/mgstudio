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
const MESH3D_SHADOW_ALPHA_MODE_RESERVED_BITS : UInt = 7U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_MASK : UInt = 1U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_BLEND : UInt = 2U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_PREMULTIPLIED : UInt = 3U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_ADD : UInt = 4U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_MULTIPLY : UInt = 5U << 29

///|
const MESH3D_SHADOW_ALPHA_MODE_ALPHA_TO_COVERAGE : UInt = 6U << 29

///|
fn mesh3d_shadow_material_path_from_flags(material_flags : UInt) -> Bool {
  let alpha_mode = material_flags & MESH3D_SHADOW_ALPHA_MODE_RESERVED_BITS
  alpha_mode == MESH3D_SHADOW_ALPHA_MODE_MASK ||
  alpha_mode == MESH3D_SHADOW_ALPHA_MODE_BLEND ||
  alpha_mode == MESH3D_SHADOW_ALPHA_MODE_PREMULTIPLIED ||
  alpha_mode == MESH3D_SHADOW_ALPHA_MODE_ADD ||
  alpha_mode == MESH3D_SHADOW_ALPHA_MODE_ALPHA_TO_COVERAGE
}

///|
pub fn GpuBackend::draw_mesh3d_shadow_depth_pass(
  self : GpuBackend,
  pass : @wgpu.RenderPass,
  ps : GpuPassState,
  mesh : GpuMeshInfo,
  pass_kind : Int,
  directional_light : Bool,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
  indirect_draw_count : Int,
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
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  emissive_exposure_weight : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  attenuation_color_r : Float,
  attenuation_color_g : Float,
  attenuation_color_b : Float,
  attenuation_distance : Float,
  clearcoat : Float,
  clearcoat_perceptual_roughness : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  lightmap_exposure : Float,
  deferred_lighting_pass_id : Int,
  mesh_flags : UInt,
  cull_mode : Int,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  morph_weights_index : Int,
  previous_morph_weights_index : Int,
  morph_target_texture_id : Int,
  material_pipeline_id : UInt64,
) -> Unit raise GpuBackendError {
  let material_path = mesh3d_shadow_material_path_from_flags(material_flags)
  let skinned = skinning_key_hi >= 0
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    self, material_pipeline_id,
  )
  let material_layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    self, material_pipeline_id, material_descriptor,
  )
  let emulate_unclipped_depth = mesh3d_shadow_depth_should_emulate_unclipped_depth(
    self, directional_light,
  )
  guard mesh3d_shadow_depth_pipeline_for_current_pass(
      self,
      mesh.primitive_topology,
      material_pipeline_id,
      cull_mode,
      material_path,
      skinned,
      directional_light,
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
        -1,
        morph_target_texture_id,
      )
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
    guard self.ensure_mesh3d_draw_slot_with_layout(
        mesh3d_draw_slot_index,
        material_pipeline_id,
        material_layout_entry.draw_bind_group_layout,
        material_layout_entry.draw_bind_group_layout_descriptor,
        -1,
        morph_target_texture_id,
      )
      is Some(draw_slot) else {
      return
    }
    self.mesh3d_draw_slot_used = mesh3d_draw_slot_index + 1
    draw_buffer = Some(draw_slot.buffer)
    draw_bind_group = Some(draw_slot.bind_group)
    draw_write_offset = 0UL
    draw_index = 0U
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
      uv_transform_a,
      uv_transform_b,
      uv_transform_c,
      uv_transform_d,
      uv_transform_tx,
      uv_transform_ty,
      uv_transform_mode,
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
      material_flags,
      if skinning_key_hi >= 0 {
        skinning_key_hi.reinterpret_as_uint()
      } else {
        0xFFFFFFFFU
      },
      mesh_flags,
      0.0F,
      -1,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      mesh.vertex_start,
    )
    self.queue.write_buffer(active_draw_buffer, draw_write_offset, draw_bytes)
  }
  guard mesh3d_shadow_view_bind_group_for_pass_uniforms(self, pass_uniforms)
    is Some(view_bg) else {
    return
  }
  guard self.mesh3d_shadow_empty_bg is Some(empty_bg) else { return }
  let material_bg = if material_path || emulate_unclipped_depth {
    let default_texture = ensure_default_texture(self)
    guard resolve_mesh3d_texture(self, texture_id) is Some(base_color_texture) else {
      return
    }
    let normal_texture = ensure_normal_map_fallback_texture(self)
    mesh3d_material_cache_get_or_create(
      self,
      material_pipeline_id,
      mesh3d_material_pipeline_descriptor_find(self, material_pipeline_id),
      base_color_texture,
      normal_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      mesh3d_standard_material_uniform_bytes(
        color_r, color_g, color_b, color_a, uv_transform_a, uv_transform_b, uv_transform_c,
        uv_transform_d, uv_transform_tx, uv_transform_ty, emissive_r, emissive_g,
        emissive_b, emissive_exposure_weight, metallic, roughness, reflectance, attenuation_color_r,
        attenuation_color_g, attenuation_color_b, attenuation_distance, clearcoat,
        clearcoat_perceptual_roughness, parallax_depth_scale, max_parallax_layer_count,
        max_relief_mapping_search_steps, anisotropy_strength, anisotropy_rotation,
        specular_tint_r, specular_tint_g, specular_tint_b, diffuse_transmission,
        specular_transmission, thickness, ior, alpha_cutoff, material_flags, lightmap_exposure,
        deferred_lighting_pass_id,
      ),
    )
  } else {
    empty_bg
  }
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [])
  pass.set_bind_group(1U, empty_bg, [])
  pass.set_bind_group(
    2U,
    active_draw_bg,
    mesh3d_draw_bind_group_dynamic_offsets(
      material_layout_entry.draw_bind_group_layout_descriptor,
      morph_weights_index,
      previous_morph_weights_index,
    ),
  )
  pass.set_bind_group(3U, material_bg, [])
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
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
      indirect_draw_count.reinterpret_as_uint(),
      mesh.vertex_start,
      draw_index,
    )
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      indirect_draw_count.reinterpret_as_uint(),
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      draw_index,
    )
  }
}
