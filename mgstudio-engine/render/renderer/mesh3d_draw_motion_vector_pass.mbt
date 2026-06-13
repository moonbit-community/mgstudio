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
fn mesh3d_motion_vector_descriptor_view_bind_groups_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  layout_entry : Mesh3dMaterialPipelineLayoutCacheEntry,
) -> (@wgpu.BindGroup, @wgpu.BindGroup, @wgpu.BindGroup)? {
  guard backend.frame is Some(frame) else { return None }
  for entry in backend.mesh3d_motion_vector_view_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.frame_count == backend.frame_count {
      return Some(
        (
          entry.view_bind_group,
          entry.empty_bind_group,
          entry.empty_material_bind_group,
        ),
      )
    }
  }
  guard backend.mesh3d_motion_vector_view_buf is Some(view_buf) else {
    return None
  }
  guard backend.mesh3d_motion_vector_globals_buf is Some(globals_buf) else {
    return None
  }
  guard backend.mesh3d_motion_vector_previous_view_buf
    is Some(previous_view_buf) else {
    return None
  }
  guard backend.mesh3d_motion_vector_visibility_ranges_buf
    is Some(visibility_ranges_buf) else {
    return None
  }
  let view_entries = layout_entry.view_bind_group_layout_descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=view_entries.length().to_uint64(),
  )
  for entry in view_entries {
    let ok = match entry.binding() {
      0 => builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE)
      1 =>
        builder.add_buffer(
          1U,
          globals_buf,
          size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
        )
      2 =>
        builder.add_buffer(
          2U,
          previous_view_buf,
          size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
        )
      14 =>
        builder.add_buffer(
          14U,
          visibility_ranges_buf,
          size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
        )
      _ => false
    }
    if !ok {
      builder.free()
      return None
    }
  }
  let view_bg = builder.finish(
    backend.device,
    layout_entry.view_bind_group_layout,
    label="mgstudio_motion_vector_descriptor_view_bg",
  )
  let empty_bg = mesh3d_create_empty_bind_group(
    backend,
    layout_entry.binding_arrays_bind_group_layout,
    "mgstudio_motion_vector_descriptor_empty_bg",
  )
  let empty_material_bg = mesh3d_create_empty_bind_group(
    backend,
    layout_entry.material_bind_group_layout,
    "mgstudio_motion_vector_descriptor_empty_material_bg",
  )
  frame.transient_bind_groups.push(view_bg)
  frame.transient_bind_groups.push(empty_bg)
  frame.transient_bind_groups.push(empty_material_bg)
  backend.mesh3d_motion_vector_view_bg_cache.push(Mesh3dMotionVectorViewBindGroupCacheEntry::{
    material_pipeline_id,
    frame_count: backend.frame_count,
    view_bind_group: view_bg,
    empty_bind_group: empty_bg,
    empty_material_bind_group: empty_material_bg,
  })
  Some((view_bg, empty_bg, empty_material_bg))
}

///|
pub fn GpuBackend::draw_mesh3d_motion_vector_pass(
  self : GpuBackend,
  pass : @wgpu.RenderPass,
  ps : GpuPassState,
  mesh : GpuMeshInfo,
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
  previous_x : Float,
  previous_y : Float,
  previous_z : Float,
  previous_rotation_x : Float,
  previous_rotation_y : Float,
  previous_rotation_z : Float,
  previous_rotation_w : Float,
  previous_scale_x : Float,
  previous_scale_y : Float,
  previous_scale_z : Float,
  world_from_local : Array[Float]?,
  previous_world_from_local : Array[Float]?,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  morph_weights_index : Int,
  previous_morph_weights_index : Int,
  morph_target_texture_id : Int,
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
  cull_mode : Int,
  material_pipeline_id : UInt64,
  transparent : Bool,
  material_extension_bind_group_data : @render_resource.MaterialBindGroupResolvedData,
) -> Unit raise GpuBackendError {
  if mesh.primitive_topology != MESH3D_TOPOLOGY_TRIANGLE_LIST {
    return
  }
  if transparent {
    return
  }
  let is_skinned = skinning_key_hi >= 0
  let has_previous_skin = is_skinned && skinning_key_lo > 0
  let is_morphed = morph_weights_index >= 0 && morph_target_texture_id >= 0
  let has_previous_morph = is_morphed && previous_morph_weights_index >= 0
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    self, material_pipeline_id,
  )
  let material_layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    self, material_pipeline_id, material_descriptor,
  )
  guard mesh3d_motion_vector_pipeline_entry_get_or_create(
      self,
      mesh.primitive_topology,
      ps.msaa_sample_count,
      material_pipeline_id,
      material_descriptor,
      cull_mode,
      is_skinned,
      has_previous_skin,
      is_morphed,
      has_previous_morph,
    )
    is Some(pipeline_entry) else {
    return
  }
  let pipeline = pipeline_entry.pipeline
  let mesh_bgl = pipeline_entry.mesh_bind_group_layout
  let mesh_layout_descriptor = pipeline_entry.mesh_bind_group_layout_descriptor
  let mesh_layout_mask = mesh3d_motion_vector_mesh_layout_mask(
    is_skinned, has_previous_skin, is_morphed, has_previous_morph,
  )
  guard self.mesh3d_motion_vector_view_buf is Some(view_buf) else { return }
  guard self.mesh3d_motion_vector_previous_view_buf is Some(previous_view_buf) else {
    return
  }
  let (view_bg, empty_bg, empty_material_bg) = match material_descriptor {
    Some(_) =>
      match
        mesh3d_motion_vector_descriptor_view_bind_groups_get_or_create(
          self, material_pipeline_id, material_layout_entry,
        ) {
        Some(groups) => groups
        None => return
      }
    None => {
      guard self.mesh3d_motion_vector_view_bg is Some(view_bg) else { return }
      guard self.mesh3d_motion_vector_empty_bg is Some(empty_bg) else { return }
      (view_bg, empty_bg, empty_bg)
    }
  }
  let preprocess_state_index = mesh3d_preprocess_camera_upload_state_index(
    self, preprocess_camera_key_hi, preprocess_camera_key_lo,
  )
  let preprocess_state = if preprocess_state_index is Some(state_index) {
    Some(self.mesh3d_preprocess_camera_upload_states[state_index])
  } else {
    None
  }
  let indirect_first_instance_supported = self.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  let use_indirect = indirect_first_instance_supported &&
    indirect_parameters_index >= 0 &&
    indirect_kind != MESH3D_DRAW_INDIRECT_KIND_NONE
  let mut mesh_buffer : @wgpu.Buffer? = None
  let mut mesh_bind_group : @wgpu.BindGroup? = None
  let mut mesh_write_offset = 0UL
  let mut mesh_index = 0U
  let mut morph_descriptor_index = 0U
  let mut writes_motion_vector_mesh = true
  if (use_indirect || draw_storage_index >= 0) &&
    preprocess_state is Some(preprocess_state) &&
    preprocess_state.output_count > 0 &&
    preprocess_state_index is Some(state_index) &&
    mesh3d_preprocess_motion_vector_mesh_bind_group_get_or_create(
      self, state_index, mesh_bgl, mesh_layout_descriptor, mesh_layout_mask, morph_target_texture_id,
    )
    is Some(preprocess_mesh_bg) {
    mesh_bind_group = Some(preprocess_mesh_bg)
    mesh_index = if use_indirect {
      0U
    } else {
      draw_storage_index.reinterpret_as_uint()
    }
    morph_descriptor_index = mesh_index
    writes_motion_vector_mesh = false
  } else if self.mesh3d_gpu_instance_builder_enabled || use_indirect {
    let desired_mesh_index = if draw_storage_index >= 0 {
      draw_storage_index
    } else {
      self.mesh3d_motion_vector_instance_mesh_used /
      MESH3D_PREPASS_MESH_BUFFER_SIZE.to_int()
    }
    let next_used_int = (desired_mesh_index + 1) *
      MESH3D_PREPASS_MESH_BUFFER_SIZE.to_int()
    if next_used_int < 0 {
      return
    }
    let required_size = next_used_int.to_uint64()
    guard ensure_mesh3d_motion_vector_instance_mesh_binding(
        self,
        mesh_bgl,
        mesh_layout_descriptor,
        mesh_layout_mask,
        required_size,
        morph_target_texture_id,
        desired_mesh_index.reinterpret_as_uint(),
        morph_weights_index,
        previous_morph_weights_index,
      )
      is Some((instance_mesh_buf, instance_mesh_bg)) else {
      return
    }
    mesh_index = desired_mesh_index.reinterpret_as_uint()
    morph_descriptor_index = desired_mesh_index.reinterpret_as_uint()
    mesh_buffer = Some(instance_mesh_buf)
    mesh_bind_group = Some(instance_mesh_bg)
    mesh_write_offset = desired_mesh_index.to_uint64() *
      MESH3D_PREPASS_MESH_BUFFER_SIZE
    if self.mesh3d_motion_vector_instance_mesh_used < next_used_int {
      self.mesh3d_motion_vector_instance_mesh_used = next_used_int
    }
  } else {
    let mesh_slot_index = self.mesh3d_motion_vector_mesh_slot_used
    guard ensure_mesh3d_motion_vector_mesh_slot(
        self,
        mesh_slot_index,
        mesh_bgl,
        mesh_layout_descriptor,
        mesh_layout_mask,
        morph_target_texture_id,
        mesh_slot_index.reinterpret_as_uint(),
        morph_weights_index,
        previous_morph_weights_index,
      )
      is Some(mesh_slot) else {
      return
    }
    self.mesh3d_motion_vector_mesh_slot_used = mesh_slot_index + 1
    mesh_buffer = Some(mesh_slot.buffer)
    mesh_bind_group = Some(mesh_slot.bind_group)
    mesh_write_offset = 0UL
    mesh_index = 0U
    morph_descriptor_index = mesh_slot_index.reinterpret_as_uint()
  }
  guard mesh_bind_group is Some(active_mesh_bg) else { return }
  let motion_view_bytes = mesh3d_motion_vector_view_uniform_bytes(ps)
  let motion_view_needs_upload = match
    self.mesh3d_motion_vector_pass_view_uniform_bytes {
    Some(cached) => cached != motion_view_bytes
    None => true
  }
  if motion_view_needs_upload {
    self.queue.write_buffer(view_buf, 0UL, motion_view_bytes)
    self.mesh3d_motion_vector_pass_view_uniform_bytes = Some(motion_view_bytes)
  }
  let motion_previous_view_bytes = mesh3d_motion_vector_previous_view_uniform_bytes(
    ps,
  )
  let motion_previous_view_needs_upload = match
    self.mesh3d_motion_vector_pass_previous_view_uniform_bytes {
    Some(cached) => cached != motion_previous_view_bytes
    None => true
  }
  if motion_previous_view_needs_upload {
    self.queue.write_buffer(previous_view_buf, 0UL, motion_previous_view_bytes)
    self.mesh3d_motion_vector_pass_previous_view_uniform_bytes = Some(
      motion_previous_view_bytes,
    )
  }
  if writes_motion_vector_mesh {
    guard mesh_buffer is Some(active_mesh_buffer) else { return }
    self.queue.write_buffer(
      active_mesh_buffer,
      mesh_write_offset,
      mesh3d_motion_vector_mesh_bytes(
        world_from_local, previous_world_from_local, x, y, z, rotation_x, rotation_y,
        rotation_z, rotation_w, scale_x, scale_y, scale_z, previous_x, previous_y,
        previous_z, previous_rotation_x, previous_rotation_y, previous_rotation_z,
        previous_rotation_w, previous_scale_x, previous_scale_y, previous_scale_z,
        skinning_key_hi, morph_descriptor_index,
      ),
    )
  }
  let material_bg = if mesh3d_descriptor_material_layout(material_descriptor)
    is Some(_) {
    let default_texture = ensure_default_texture(self)
    guard resolve_mesh3d_texture(self, texture_id) is Some(base_color_texture) else {
      return
    }
    let normal_texture = ensure_normal_map_fallback_texture(self)
    mesh3d_material_cache_get_or_create(
      self,
      material_pipeline_id,
      material_descriptor,
      base_color_texture,
      normal_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      default_texture,
      normal_texture,
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
      material_extension_bind_group_data~,
    )
  } else {
    empty_material_bg
  }
  pass.set_pipeline(pipeline)
  pass.set_bind_group(
    0U,
    view_bg,
    mesh3d_descriptor_bind_group_dynamic_offsets(material_descriptor, 0),
  )
  pass.set_bind_group(1U, empty_bg, [])
  pass.set_bind_group(
    2U,
    active_mesh_bg,
    mesh3d_draw_bind_group_dynamic_offsets(
      mesh_layout_descriptor, morph_weights_index, previous_morph_weights_index,
    ),
  )
  if material_descriptor is Some(_) {
    pass.set_bind_group(3U, material_bg, [])
  }
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
  if use_indirect && preprocess_state is Some(preprocess_state) {
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_INDEXED &&
      preprocess_state.indexed_indirect_parameters_buffer
      is Some(indexed_indirect_parameters_buffer) {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed_indirect(
        indexed_indirect_parameters_buffer,
        mesh3d_indexed_indirect_offset(indirect_parameters_index),
      )
    } else if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED &&
      preprocess_state.non_indexed_indirect_parameters_buffer
      is Some(non_indexed_indirect_parameters_buffer) {
      pass.draw_indirect(
        non_indexed_indirect_parameters_buffer,
        mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
      )
    } else if mesh.index_count == 0U {
      pass.draw(mesh.vertex_count, 1U, mesh.vertex_start, mesh_index)
    } else {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed(
        mesh.index_count,
        1U,
        mesh.index_start,
        mesh.vertex_start.reinterpret_as_int(),
        mesh_index,
      )
    }
  } else if mesh.index_count == 0U {
    pass.draw(mesh.vertex_count, 1U, mesh.vertex_start, mesh_index)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      1U,
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      mesh_index,
    )
  }
}
