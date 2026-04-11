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
fn ensure_mesh3d_draw_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard backend.mesh3d_bgl_draw is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_draw_slots.length() <= slot_index {
    let draw_buf = backend.device.create_buffer(
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      usage~,
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      draw_buf,
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    )
    if !ok {
      builder.free()
      return None
    }
    let draw_bg = builder.finish(
      backend.device,
      bgl,
      label="mgstudio_mesh3d_draw_slot_bg",
    )
    backend.mesh3d_draw_slots.push(GpuStorageSlot::{
      buffer: draw_buf,
      bind_group: draw_bg,
    })
  }
  Some(backend.mesh3d_draw_slots[slot_index])
}

///|
fn ensure_mesh3d_instance_draw_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh3d_bgl_draw is Some(bgl) else { return None }
  if backend.mesh3d_instance_draw_buf is Some(draw_buf) &&
    backend.mesh3d_instance_draw_bg is Some(draw_bg) &&
    backend.mesh3d_instance_draw_capacity >= required_size {
    return Some((draw_buf, draw_bg))
  }
  let mut next_capacity = if backend.mesh3d_instance_draw_capacity > 0UL {
    backend.mesh3d_instance_draw_capacity
  } else {
    MESH3D_DRAW_STORAGE_STRIDE_BYTES * 16384UL
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let draw_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, draw_buf, size=next_capacity)
  if !ok {
    builder.free()
    return None
  }
  let draw_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh3d_instance_draw_bg",
  )
  // Keep old buffer/bind group alive: commands recorded earlier in this frame
  // may still reference them when capacity grows mid-frame.
  backend.mesh3d_instance_draw_buf = Some(draw_buf)
  backend.mesh3d_instance_draw_bg = Some(draw_bg)
  backend.mesh3d_instance_draw_capacity = next_capacity
  Some((draw_buf, draw_bg))
}

///|
fn mesh3d_identity_rows(matrix_count : Int) -> Array[Float] {
  let identity_rows : Array[Float] = []
  for _ in 0..<matrix_count {
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
  }
  identity_rows
}

///|
fn ensure_mesh3d_skin_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard backend.mesh3d_bgl_skin is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_skin_slots.length() <= slot_index {
    let skin_buf = backend.device.create_buffer(
      size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
      usage~,
    )
    let matrix_count = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 64UL).to_int()
    backend.queue.write_buffer(
      skin_buf,
      0UL,
      f32le_pack(mesh3d_identity_rows(matrix_count)),
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      skin_buf,
      size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
    )
    if !ok {
      builder.free()
      return None
    }
    let skin_bg = builder.finish(
      backend.device,
      bgl,
      label="mgstudio_mesh3d_skin_slot_bg",
    )
    backend.mesh3d_skin_slots.push(GpuStorageSlot::{
      buffer: skin_buf,
      bind_group: skin_bg,
    })
  }
  Some(backend.mesh3d_skin_slots[slot_index])
}

///|
fn ensure_mesh3d_skin_default_binding(backend : GpuBackend) -> @wgpu.BindGroup? {
  guard backend.mesh3d_bgl_skin is Some(bgl) else { return None }
  if backend.mesh3d_skin_default_bg is Some(bg) {
    return Some(bg)
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let skin_buf = backend.device.create_buffer(
    size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
    usage~,
  )
  let matrix_count = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 64UL).to_int()
  backend.queue.write_buffer(
    skin_buf,
    0UL,
    f32le_pack(mesh3d_identity_rows(matrix_count)),
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    skin_buf,
    size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
  )
  if !ok {
    builder.free()
    return None
  }
  let skin_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh3d_skin_default_bg",
  )
  backend.mesh3d_skin_default_buf = Some(skin_buf)
  backend.mesh3d_skin_default_bg = Some(skin_bg)
  Some(skin_bg)
}

///|
fn mesh3d_skin_slot_cache_key(key_hi : Int, key_lo : Int) -> UInt64 {
  let hi = key_hi.reinterpret_as_uint().to_uint64()
  let lo = key_lo.reinterpret_as_uint().to_uint64() & 0xffffffffUL
  (hi << 32) | lo
}

///|
fn mesh3d_skin_bind_group_for_key(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> @wgpu.BindGroup? {
  let key = mesh3d_skin_slot_cache_key(key_hi, key_lo)
  guard backend.mesh3d_skin_slot_indices_by_key.get(key) is Some(slot_index) else {
    return None
  }
  guard slot_index >= 0 && slot_index < backend.mesh3d_skin_slots.length() else {
    return None
  }
  Some(backend.mesh3d_skin_slots[slot_index].bind_group)
}

///|
fn mesh3d_upload_skinning_matrices(
  backend : GpuBackend,
  target_buffer : @wgpu.Buffer,
  skinning_matrices : Array[Float],
) -> Unit {
  let max_values = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 4UL).to_int()
  let upload_len = if skinning_matrices.length() < max_values {
    skinning_matrices.length()
  } else {
    max_values
  }
  if upload_len <= 0 {
    return
  }
  let upload_values = if upload_len == skinning_matrices.length() {
    skinning_matrices
  } else {
    let clipped : Array[Float] = []
    for i in 0..<upload_len {
      clipped.push(skinning_matrices[i])
    }
    clipped
  }
  backend.queue.write_buffer(target_buffer, 0UL, f32le_pack(upload_values))
}

///|
pub fn GpuBackend::prepare_mesh3d_skin_binding(
  self : GpuBackend,
  key_hi : Int,
  key_lo : Int,
  skinning_matrices : Array[Float],
) -> Unit {
  if key_hi < 0 || key_lo < 0 {
    return
  }
  if skinning_matrices.length() < 16 || skinning_matrices.length() % 16 != 0 {
    return
  }
  let key = mesh3d_skin_slot_cache_key(key_hi, key_lo)
  if self.mesh3d_skin_slot_indices_by_key.get(key) is Some(existing_slot_index) {
    if existing_slot_index >= 0 &&
      existing_slot_index < self.mesh3d_skin_slots.length() {
      mesh3d_upload_skinning_matrices(
        self,
        self.mesh3d_skin_slots[existing_slot_index].buffer,
        skinning_matrices,
      )
      return
    }
  }
  let slot_index = self.mesh3d_skin_slot_used
  guard ensure_mesh3d_skin_slot(self, slot_index) is Some(skin_slot) else {
    return
  }
  self.mesh3d_skin_slot_used = slot_index + 1
  mesh3d_upload_skinning_matrices(self, skin_slot.buffer, skinning_matrices)
  self.mesh3d_skin_slot_indices_by_key.set(key, slot_index)
}

///|
fn mesh3d_expand_vertices_with_skinning_defaults(
  vertices : Array[Float],
) -> Array[Float]? {
  if vertices.length() % MESH3D_VERTEX_SKINNED_FLOAT_STRIDE == 0 {
    return Some(vertices)
  }
  if vertices.length() % MESH3D_VERTEX_BASE_FLOAT_STRIDE != 0 {
    return None
  }
  let vertex_count = vertices.length() / MESH3D_VERTEX_BASE_FLOAT_STRIDE
  let expanded : Array[Float] = []
  for vertex_index in 0..<vertex_count {
    let base = vertex_index * MESH3D_VERTEX_BASE_FLOAT_STRIDE
    for i in 0..<MESH3D_VERTEX_BASE_FLOAT_STRIDE {
      expanded.push(vertices[base + i])
    }
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
  }
  Some(expanded)
}

///|
pub fn GpuBackend::create_mesh3d_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Int {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return 0
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return 0
  }
  let uses_u32_indices = usable_vcount > 65535
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = if uses_u32_indices {
    let indices_u32 : Array[UInt] = []
    for i in 0..<usable_vcount {
      indices_u32.push(i.reinterpret_as_uint())
    }
    self.device.create_buffer_init(usage=ib_usage, u32le_pack(indices_u32))
  } else {
    let indices_u16 : Array[Int] = []
    for i in 0..<usable_vcount {
      indices_u16.push(i)
    }
    self.device.create_buffer_init(usage=ib_usage, u16le_pack(indices_u16))
  }
  let info = GpuMeshInfo::{
    id,
    index_count: usable_vcount.reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology,
    vertex_stride_bytes: MESH3D_VERTEX_STRIDE_BYTES,
    index_stride_bytes: if uses_u32_indices {
      4UL
    } else {
      2UL
    },
    uses_u32_indices,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  self.create_mesh3d_xyznuvrgba(vertices, 0)
}

///|
pub fn GpuBackend::update_mesh3d_xyznuvrgba(
  self : GpuBackend,
  mesh_id : Int,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Bool {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return false
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return false
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return false
  }
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES ||
    mesh.primitive_topology != primitive_topology ||
    mesh.vertex_count.reinterpret_as_int() != usable_vcount {
    return false
  }
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  self.queue.write_buffer(mesh.vertex_buf, 0UL, f32le_pack(trimmed_vertices))
  true
}

///|
pub fn GpuBackend::draw_mesh3d(
  self : GpuBackend,
  mesh_id : Int,
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
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  environment_map_intensity : Float,
  environment_map_rotation_x : Float,
  environment_map_rotation_y : Float,
  environment_map_rotation_z : Float,
  environment_map_rotation_w : Float,
  cull_mode : Int,
  shader_path : String?,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  skinning_matrices? : Array[Float]? = None,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  transmission_source_texture_id |> ignore
  transmission_blur_taps |> ignore
  transmission_steps |> ignore
  point_shadow_texture_id |> ignore
  environment_diffuse_texture_id |> ignore
  environment_specular_texture_id |> ignore
  environment_map_intensity |> ignore
  environment_map_rotation_x |> ignore
  environment_map_rotation_y |> ignore
  environment_map_rotation_z |> ignore
  environment_map_rotation_w |> ignore
  skinning_matrices |> ignore
  if !ps.is_3d {
    return
  }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES {
    return
  }
  let transparent = color_a < 0.999F
  let pass_kind_raw = ps.pass_kind
  if !pass_kind_decal_enabled(pass_kind_raw) && mesh3d_draw_is_decal(cull_mode) {
    return
  }
  if !pass_kind_fog_enabled(pass_kind_raw) && mesh3d_draw_is_fog(cull_mode) {
    return
  }
  if !pass_kind_postprocess_enabled(pass_kind_raw) &&
    mesh3d_draw_is_postprocess_proxy(cull_mode) {
    return
  }
  let pass_kind = pass_kind_base_kind(pass_kind_raw)
  if pass_kind == PASS_KIND_BASE_MOTION_VECTOR {
    if mesh.primitive_topology != MESH3D_TOPOLOGY_TRIANGLE_LIST {
      return
    }
    if transparent {
      return
    }
    ensure_mesh3d_motion_vector_pipeline(self)
    guard self.mesh3d_motion_vector_pipeline is Some(pipeline) else { return }
    guard self.mesh3d_motion_vector_view_buf is Some(view_buf) else { return }
    guard self.mesh3d_motion_vector_previous_view_buf is Some(previous_view_buf) else {
      return
    }
    guard self.mesh3d_motion_vector_view_bg is Some(view_bg) else { return }
    guard self.mesh3d_motion_vector_empty_bg is Some(empty_bg) else { return }
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
    let mut writes_motion_vector_mesh = true
    if preprocess_state_index is Some(state_index) &&
      (use_indirect || draw_storage_index >= 0) &&
      mesh3d_preprocess_motion_vector_mesh_bind_group_get_or_create(
        self, state_index,
      )
      is Some(preprocess_mesh_bg) {
      mesh_bind_group = Some(preprocess_mesh_bg)
      mesh_index = if use_indirect {
        0U
      } else {
        draw_storage_index.reinterpret_as_uint()
      }
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
          self, required_size,
        )
        is Some((instance_mesh_buf, instance_mesh_bg)) else {
        return
      }
      mesh_index = desired_mesh_index.reinterpret_as_uint()
      mesh_buffer = Some(instance_mesh_buf)
      mesh_bind_group = Some(instance_mesh_bg)
      mesh_write_offset = desired_mesh_index.to_uint64() *
        MESH3D_PREPASS_MESH_BUFFER_SIZE
      if self.mesh3d_motion_vector_instance_mesh_used < next_used_int {
        self.mesh3d_motion_vector_instance_mesh_used = next_used_int
      }
    } else {
      let mesh_slot_index = self.mesh3d_motion_vector_mesh_slot_used
      guard ensure_mesh3d_motion_vector_mesh_slot(self, mesh_slot_index)
        is Some(mesh_slot) else {
        return
      }
      self.mesh3d_motion_vector_mesh_slot_used = mesh_slot_index + 1
      mesh_buffer = Some(mesh_slot.buffer)
      mesh_bind_group = Some(mesh_slot.bind_group)
      mesh_write_offset = 0UL
      mesh_index = 0U
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
      self.mesh3d_motion_vector_pass_view_uniform_bytes = Some(
        motion_view_bytes,
      )
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
      self.queue.write_buffer(
        previous_view_buf, 0UL, motion_previous_view_bytes,
      )
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
          x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
          scale_z, previous_x, previous_y, previous_z, previous_rotation_x, previous_rotation_y,
          previous_rotation_z, previous_rotation_w, previous_scale_x, previous_scale_y,
          previous_scale_z,
        ),
      )
    }
    pass.set_pipeline(pipeline)
    pass.set_bind_group(0U, view_bg, [])
    pass.set_bind_group(1U, empty_bg, [])
    pass.set_bind_group(2U, active_mesh_bg, [])
    let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
      mesh.vertex_stride_bytes
    pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
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
      } else {
        gpu_mesh_bind_index_buffer(pass, mesh)
        pass.draw_indexed(mesh.index_count, 1U, 0U, 0, mesh_index)
      }
    } else {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed(mesh.index_count, 1U, 0U, 0, mesh_index)
    }
    return
  }
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
    guard ensure_mesh3d_instance_draw_binding(self, required_size)
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
    guard ensure_mesh3d_draw_slot(self, mesh3d_draw_slot_index)
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
