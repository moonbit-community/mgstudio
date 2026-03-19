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
fn ensure_mesh3d_uniform_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuUniformSlot? {
  guard backend.mesh3d_bgl_uniform is Some(bgl) else { return None }
  let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_uniform_slots.length() <= slot_index {
    let uniform_buf = backend.device.create_buffer(
      size=MESH3D_UNIFORM_BUFFER_SIZE,
      usage=ubo_usage,
    )
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh3d_uniform_slots.push(GpuUniformSlot::{
      buffer: uniform_buf,
      bind_group: uniform_bg,
    })
  }
  Some(backend.mesh3d_uniform_slots[slot_index])
}

///|
fn ensure_mesh3d_instance_uniform_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh3d_bgl_uniform is Some(bgl) else { return None }
  if backend.mesh3d_instance_uniform_buf is Some(uniform_buf) &&
    backend.mesh3d_instance_uniform_bg is Some(uniform_bg) &&
    backend.mesh3d_instance_uniform_capacity >= required_size {
    return Some((uniform_buf, uniform_bg))
  }
  let mut next_capacity = if backend.mesh3d_instance_uniform_capacity > 0UL {
    backend.mesh3d_instance_uniform_capacity
  } else {
    MESH3D_UNIFORM_BUFFER_SIZE * 16384UL
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  let uniform_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, uniform_buf, size=MESH3D_UNIFORM_BUFFER_SIZE)
  if !ok {
    builder.free()
    return None
  }
  let uniform_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh3d_instance_uniform_bg",
  )
  // Keep old buffer/bind group alive: commands recorded earlier in this frame
  // may still reference them when capacity grows mid-frame.
  backend.mesh3d_instance_uniform_buf = Some(uniform_buf)
  backend.mesh3d_instance_uniform_bg = Some(uniform_bg)
  backend.mesh3d_instance_uniform_capacity = next_capacity
  Some((uniform_buf, uniform_bg))
}

///|
fn mesh3d_motion_vector_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  tonemapping_view_uniform_bytes_full(
    pass_state, 1.0F, 0U, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
  )
}

///|
fn mesh3d_motion_vector_previous_view_uniform_bytes(
  pass_state : GpuPassState,
) -> Bytes {
  let identity = gpu_clip_matrix_identity()
  let words : Array[UInt] = []
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.previous_clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  u32le_pack(words)
}

///|
fn mesh3d_motion_vector_globals_uniform_bytes() -> Bytes {
  u32le_pack([0U, 0U, 0U, 0U])
}

///|
fn mesh3d_motion_vector_visibility_ranges_bytes() -> Bytes {
  u32le_pack([0U, 0U, 0U, 0U])
}

///|
fn load_wgsl_required_mesh3d_motion_vector_prepass(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_FRAGMENT", true)
  defines.set("MOTION_VECTOR_PREPASS", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/prepass/prepass.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn mesh3d_normalize_quat(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float) {
  let len_sq = x * x + y * y + z * z + w * w
  if len_sq <= 1.0e-8F {
    (0.0F, 0.0F, 0.0F, 1.0F)
  } else {
    let inv_len = 1.0F / Float::sqrt(len_sq)
    (x * inv_len, y * inv_len, z * inv_len, w * inv_len)
  }
}

///|
fn mesh3d_quat_rotation_matrix(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float, Float, Float, Float, Float, Float) {
  let (safe_x, safe_y, safe_z, safe_w) = mesh3d_normalize_quat(x, y, z, w)
  let xx = safe_x * safe_x
  let yy = safe_y * safe_y
  let zz = safe_z * safe_z
  let xy = safe_x * safe_y
  let xz = safe_x * safe_z
  let yz = safe_y * safe_z
  let wx = safe_w * safe_x
  let wy = safe_w * safe_y
  let wz = safe_w * safe_z
  (
    1.0F - 2.0F * (yy + zz),
    2.0F * (xy - wz),
    2.0F * (xz + wy),
    2.0F * (xy + wz),
    1.0F - 2.0F * (xx + zz),
    2.0F * (yz - wx),
    2.0F * (xz - wy),
    2.0F * (yz + wx),
    1.0F - 2.0F * (xx + yy),
  )
}

///|
fn mesh3d_world_from_local_words(
  translation_x : Float,
  translation_y : Float,
  translation_z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> Array[UInt] {
  let (m00, m01, m02, m10, m11, m12, m20, m21, m22) = mesh3d_quat_rotation_matrix(
    rotation_x, rotation_y, rotation_z, rotation_w,
  )
  let world_x_axis_x = m00 * scale_x
  let world_x_axis_y = m10 * scale_x
  let world_x_axis_z = m20 * scale_x
  let world_y_axis_x = m01 * scale_y
  let world_y_axis_y = m11 * scale_y
  let world_y_axis_z = m21 * scale_y
  let world_z_axis_x = m02 * scale_z
  let world_z_axis_y = m12 * scale_z
  let world_z_axis_z = m22 * scale_z
  [
    f32_bits(world_x_axis_x),
    f32_bits(world_y_axis_x),
    f32_bits(world_z_axis_x),
    f32_bits(translation_x),
    f32_bits(world_x_axis_y),
    f32_bits(world_y_axis_y),
    f32_bits(world_z_axis_y),
    f32_bits(translation_y),
    f32_bits(world_x_axis_z),
    f32_bits(world_y_axis_z),
    f32_bits(world_z_axis_z),
    f32_bits(translation_z),
  ]
}

///|
fn mesh3d_inverse_transpose_words(
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> Array[UInt] {
  let safe_scale_x = if scale_x == 0.0F { 1.0F } else { scale_x }
  let safe_scale_y = if scale_y == 0.0F { 1.0F } else { scale_y }
  let safe_scale_z = if scale_z == 0.0F { 1.0F } else { scale_z }
  let (m00, m01, m02, m10, m11, m12, m20, m21, m22) = mesh3d_quat_rotation_matrix(
    rotation_x, rotation_y, rotation_z, rotation_w,
  )
  [
    f32_bits(m00 / safe_scale_x),
    f32_bits(m10 / safe_scale_x),
    f32_bits(m20 / safe_scale_x),
    f32_bits(m01 / safe_scale_y),
    f32_bits(m11 / safe_scale_y),
    f32_bits(m21 / safe_scale_y),
    f32_bits(m02 / safe_scale_z),
    f32_bits(m12 / safe_scale_z),
    f32_bits(m22 / safe_scale_z),
  ]
}

///|
fn mesh3d_motion_vector_mesh_uniform_bytes(
  translation_x : Float,
  translation_y : Float,
  translation_z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  previous_translation_x : Float,
  previous_translation_y : Float,
  previous_translation_z : Float,
  previous_rotation_x : Float,
  previous_rotation_y : Float,
  previous_rotation_z : Float,
  previous_rotation_w : Float,
  previous_scale_x : Float,
  previous_scale_y : Float,
  previous_scale_z : Float,
) -> Bytes {
  let determinant = scale_x * scale_y * scale_z
  let mut flags = 0xFFFFU
  if determinant >= 0.0F {
    flags = flags | (1U << 31)
  }
  let inverse_transpose = mesh3d_inverse_transpose_words(
    rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
  )
  let words : Array[UInt] = []
  for
    word in mesh3d_world_from_local_words(
      translation_x, translation_y, translation_z, rotation_x, rotation_y, rotation_z,
      rotation_w, scale_x, scale_y, scale_z,
    ) {
    words.push(word)
  }
  for
    word in mesh3d_world_from_local_words(
      previous_translation_x, previous_translation_y, previous_translation_z, previous_rotation_x,
      previous_rotation_y, previous_rotation_z, previous_rotation_w, previous_scale_x,
      previous_scale_y, previous_scale_z,
    ) {
    words.push(word)
  }
  for i in 0..<8 {
    words.push(inverse_transpose[i])
  }
  words.push(inverse_transpose[8])
  words.push(flags)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  words.push(0xFFFFFFFFU)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  for _ in 0..<3 {
    words.push(0U)
  }
  u32le_pack(words)
}

///|
const MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 : Int = 2

///|
const MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 : Int = 3

///|
const MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 : Int = 2

///|
fn mesh3d_preprocess_camera_upload_state_new(
  key_hi : Int,
  key_lo : Int,
) -> GpuMesh3dPreprocessCameraUploadState {
  GpuMesh3dPreprocessCameraUploadState::{
    key_hi,
    key_lo,
    direct_work_item_buffer: None,
    direct_work_item_capacity: 0UL,
    indexed_work_item_buffer: None,
    indexed_work_item_capacity: 0UL,
    non_indexed_work_item_buffer: None,
    non_indexed_work_item_capacity: 0UL,
    late_indexed_work_item_buffer: None,
    late_indexed_work_item_capacity: 0UL,
    late_non_indexed_work_item_buffer: None,
    late_non_indexed_work_item_capacity: 0UL,
    indexed_cpu_metadata_buffer: None,
    indexed_cpu_metadata_capacity: 0UL,
    indexed_gpu_metadata_buffer: None,
    indexed_gpu_metadata_capacity: 0UL,
    indexed_batch_set_buffer: None,
    indexed_batch_set_capacity: 0UL,
    non_indexed_cpu_metadata_buffer: None,
    non_indexed_cpu_metadata_capacity: 0UL,
    non_indexed_gpu_metadata_buffer: None,
    non_indexed_gpu_metadata_capacity: 0UL,
    non_indexed_batch_set_buffer: None,
    non_indexed_batch_set_capacity: 0UL,
    dispatch_metadata_buffer: None,
    dispatch_metadata_capacity: 0UL,
  }
}

///|
fn mesh3d_preprocess_camera_upload_state_index(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> Int? {
  for i in 0..<backend.mesh3d_preprocess_camera_upload_states.length() {
    let state = backend.mesh3d_preprocess_camera_upload_states[i]
    if state.key_hi == key_hi && state.key_lo == key_lo {
      return Some(i)
    }
  }
  None
}

///|
fn mesh3d_preprocess_camera_upload_state_get_or_create(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> Int {
  if mesh3d_preprocess_camera_upload_state_index(backend, key_hi, key_lo)
    is Some(index) {
    return index
  }
  backend.mesh3d_preprocess_camera_upload_states.push(
    mesh3d_preprocess_camera_upload_state_new(key_hi, key_lo),
  )
  backend.mesh3d_preprocess_camera_upload_states.length() - 1
}

///|
fn mesh3d_preprocess_ensure_storage_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  required_size : UInt64,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  if required_size == 0UL {
    return (existing_buffer, existing_capacity)
  }
  if existing_buffer is Some(buffer) && existing_capacity >= required_size {
    return (Some(buffer), existing_capacity)
  }
  let mut next_capacity = if existing_capacity > 0UL {
    existing_capacity
  } else {
    required_size
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE |
    @wgpu.BUFFER_USAGE_COPY_DST |
    @wgpu.BUFFER_USAGE_INDIRECT,
  )
  let buffer = backend.device.create_buffer(size=next_capacity, usage~)
  buffer.set_label(label)
  (Some(buffer), next_capacity)
}

///|
fn mesh3d_preprocess_upload_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  let required_size = bytes.length().to_uint64()
  let (buffer_opt, next_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    backend, existing_buffer, existing_capacity, required_size, label,
  )
  if required_size > 0UL && buffer_opt is Some(buffer) {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  (buffer_opt, next_capacity)
}

///|
fn mesh3d_preprocess_work_items_bytes(
  items : Array[HostMesh3dPreprocessShaderWorkItem],
) -> Bytes {
  let words : Array[UInt] = []
  for item in items {
    words.push(item.input_index.reinterpret_as_uint())
    words.push(item.output_or_indirect_parameters_index.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_cpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersCpuMetadata],
) -> Bytes {
  let words : Array[UInt] = []
  for entry in metadata {
    words.push(entry.base_output_index.reinterpret_as_uint())
    words.push(entry.batch_set_index.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_gpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersGpuMetadata],
) -> Bytes {
  let words : Array[UInt] = []
  for entry in metadata {
    words.push(entry.mesh_index.reinterpret_as_uint())
    words.push(entry.early_instance_count.reinterpret_as_uint())
    words.push(entry.late_instance_count.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_batch_set_bytes(
  batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet],
) -> Bytes {
  let words : Array[UInt] = []
  for batch_set in batch_sets {
    words.push(batch_set.indirect_parameters_count.reinterpret_as_uint())
    words.push(batch_set.indirect_parameters_base.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_dispatch_metadata_bytes(
  metadata : HostMesh3dPreprocessDispatchMetadata,
) -> Bytes {
  u32le_pack([
    metadata.direct_workgroup_count.reinterpret_as_uint(),
    metadata.indexed_workgroup_count.reinterpret_as_uint(),
    metadata.non_indexed_workgroup_count.reinterpret_as_uint(),
    metadata.late_indexed_workgroup_count.reinterpret_as_uint(),
    metadata.late_non_indexed_workgroup_count.reinterpret_as_uint(),
  ])
}

///|
fn mesh3d_pipeline_get_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent
    } else {
      backend.mesh3d_pipeline_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent
  } else {
    backend.mesh3d_pipeline
  }
}

///|
fn mesh3d_pipeline_set_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent = pipeline
  } else {
    backend.mesh3d_pipeline = pipeline
  }
}

///|
fn mesh3d_rgba8_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline = None
  backend.mesh3d_pipeline_transparent = None
  backend.mesh3d_pipeline_line_list = None
  backend.mesh3d_pipeline_line_list_transparent = None
  backend.mesh3d_pipeline_line_strip = None
  backend.mesh3d_pipeline_line_strip_transparent = None
  backend.mesh3d_pipeline_rgba8_cull_mode = -1
}

///|
fn mesh3d_pipeline_get_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent
  } else {
    backend.mesh3d_pipeline_surface
  }
}

///|
fn mesh3d_pipeline_set_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent = pipeline
  } else {
    backend.mesh3d_pipeline_surface = pipeline
  }
}

///|
fn mesh3d_surface_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline_surface is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline_surface = None
  backend.mesh3d_pipeline_surface_transparent = None
  backend.mesh3d_pipeline_surface_line_list = None
  backend.mesh3d_pipeline_surface_line_list_transparent = None
  backend.mesh3d_pipeline_surface_line_strip = None
  backend.mesh3d_pipeline_surface_line_strip_transparent = None
  backend.mesh3d_pipeline_surface_cull_mode = -1
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_rgba8_cull_mode != safe_cull_mode {
    mesh3d_rgba8_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_rgba8_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_layout is None {
    let bgl = create_uniform_bind_group_layout_vertex_fragment(
      backend,
      "mgstudio_mesh3d_uniform_bgl",
      has_dynamic_offset=true,
    )
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
    let material_ok = material_builder.add_sampler(
        0U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        2U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        4U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        5U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        6U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        7U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        8U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        9U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        10U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      material_builder.add_sampler(
        11U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh3d material bind group layout")
    }
    let material_bgl = material_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_material_bgl",
    )
    let pl = backend.device.create_pipeline_layout_2(bgl, material_bgl)
    backend.mesh3d_bgl_uniform = Some(bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_pipeline_layout = Some(pl)
    mesh3d_material_cache_clear(backend)
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_rgba8_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_rgba8_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, true, Some(pipeline_transparent))
  sm.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh3d pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) && prev != format {
    mesh3d_surface_pipeline_cache_clear(backend)
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_surface_cull_mode != safe_cull_mode {
    mesh3d_surface_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_surface_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) &&
    prev == format &&
    mesh3d_pipeline_get_surface(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_surface(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_surface(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_surface(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_surface_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_surface_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(
    backend,
    topology,
    true,
    Some(pipeline_transparent),
  )
  backend.mesh3d_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  topology : UInt,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(backend, format, topology, cull_mode)
      return mesh3d_pipeline_get_surface(backend, topology, transparent)
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  mesh3d_pipeline_get_rgba8(backend, topology, transparent)
}

///|
fn ensure_mesh3d_motion_vector_pipeline(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.mesh3d_motion_vector_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(2U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(
        14U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_STORAGE,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_view_bgl",
    )
    let empty_bgl = backend.device.create_bind_group_layout_empty()
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX),
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector mesh bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_mesh_bgl",
    )
    let pl = create_pipeline_layout_3(
      backend.device,
      view_bgl,
      empty_bgl,
      mesh_bgl,
    )
    backend.mesh3d_motion_vector_bgl_view = Some(view_bgl)
    backend.mesh3d_motion_vector_bgl_empty = Some(empty_bgl)
    backend.mesh3d_motion_vector_bgl_mesh = Some(mesh_bgl)
    backend.mesh3d_motion_vector_pipeline_layout = Some(pl)
  }
  if backend.mesh3d_motion_vector_view_buf is None ||
    backend.mesh3d_motion_vector_globals_buf is None ||
    backend.mesh3d_motion_vector_previous_view_buf is None ||
    backend.mesh3d_motion_vector_visibility_ranges_buf is None ||
    backend.mesh3d_motion_vector_view_bg is None {
    guard backend.mesh3d_motion_vector_bgl_view is Some(view_bgl) else {
      return
    }
    let uniform_usage = bu(
      @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let storage_usage = bu(
      @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let view_buf = backend.device.create_buffer(
      size=MESH2D_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let previous_view_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let visibility_ranges_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      usage=storage_usage,
    )
    backend.queue.write_buffer(
      globals_buf,
      0UL,
      mesh3d_motion_vector_globals_uniform_bytes(),
    )
    backend.queue.write_buffer(
      visibility_ranges_buf,
      0UL,
      mesh3d_motion_vector_visibility_ranges_bytes(),
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE) &&
      builder.add_buffer(
        1U,
        globals_buf,
        size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        previous_view_buf,
        size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        14U,
        visibility_ranges_buf,
        size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    if !ok {
      builder.free()
      return
    }
    let view_bg = builder.finish(
      backend.device,
      view_bgl,
      label="mgstudio_motion_vector_view_bg",
    )
    backend.mesh3d_motion_vector_view_buf = Some(view_buf)
    backend.mesh3d_motion_vector_globals_buf = Some(globals_buf)
    backend.mesh3d_motion_vector_previous_view_buf = Some(previous_view_buf)
    backend.mesh3d_motion_vector_visibility_ranges_buf = Some(
      visibility_ranges_buf,
    )
    backend.mesh3d_motion_vector_view_bg = Some(view_bg)
  }
  if backend.mesh3d_motion_vector_mesh_buf is None ||
    backend.mesh3d_motion_vector_mesh_bg is None {
    guard backend.mesh3d_motion_vector_bgl_mesh is Some(mesh_bgl) else {
      return
    }
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    let mesh_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_MESH_BUFFER_SIZE,
      usage~,
    )
    let mesh_bg = backend.device.create_bind_group_uniform_buffer(
      mesh_bgl, mesh_buf,
    )
    backend.mesh3d_motion_vector_mesh_buf = Some(mesh_buf)
    backend.mesh3d_motion_vector_mesh_bg = Some(mesh_bg)
  }
  if backend.mesh3d_motion_vector_pipeline is Some(_) {
    return
  }
  guard backend.mesh3d_motion_vector_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_required_mesh3d_motion_vector_prepass(
    backend.assets_base,
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout=pl)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_count(2U)
    builder.set_color_target_format_at(
      0U,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    )
    builder.set_color_target_format_at(1U, tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT))
    builder.set_color_target_write_mask_at(0U, @wgpu.COLOR_WRITE_MASK_NONE)
    builder.set_color_target_write_mask_at(1U, @wgpu.COLOR_WRITE_MASK_ALL)
    builder.disable_blend()
    builder.set_vertex_buffer_layout(
      MESH3D_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 3U)
    builder.set_topology_u32(@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=true,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal(
        "wgpu: failed to build canonical mesh3d motion vector prepass pipeline",
      )
    }
  }
  pipeline.set_label("mgstudio_motion_vector_prepass")
  backend.mesh3d_motion_vector_pipeline = Some(pipeline)
  sm.release()
}

///|
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_material_bg_cache {
    entry.bind_group.release()
  }
  backend.mesh3d_material_bg_cache.clear()
}

///|
fn ensure_mesh3d_point_shadow_compare_sampler(
  backend : GpuBackend,
) -> @wgpu.Sampler {
  match backend.mesh3d_point_shadow_compare_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.MIPMAP_FILTER_MODE_NEAREST,
        compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      )
      backend.mesh3d_point_shadow_compare_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
  base_texture : GpuTextureInfo,
  normal_texture : GpuTextureInfo,
  emissive_texture : GpuTextureInfo,
  metallic_roughness_texture : GpuTextureInfo,
  occlusion_texture : GpuTextureInfo,
  depth_texture : GpuTextureInfo,
  anisotropy_texture : GpuTextureInfo,
  specular_tint_texture : GpuTextureInfo,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  for entry in backend.mesh3d_material_bg_cache {
    if entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id &&
      entry.depth_texture_id == depth_texture.id &&
      entry.anisotropy_texture_id == anisotropy_texture.id &&
      entry.specular_tint_texture_id == specular_tint_texture.id &&
      entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id {
      return entry.bind_group
    }
  }
  let layout = match backend.mesh3d_bgl_material {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d material bind group layout")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_sampler(0U, base_texture.sampler) &&
    builder.add_texture_view(1U, base_texture.view) &&
    builder.add_texture_view(2U, normal_texture.view) &&
    builder.add_texture_view(3U, emissive_texture.view) &&
    builder.add_texture_view(4U, metallic_roughness_texture.view) &&
    builder.add_texture_view(5U, occlusion_texture.view) &&
    builder.add_texture_view(6U, depth_texture.view) &&
    builder.add_texture_view(7U, anisotropy_texture.view) &&
    builder.add_texture_view(8U, specular_tint_texture.view) &&
    builder.add_texture_view(9U, transmission_source_texture.view) &&
    builder.add_texture_view(10U, point_shadow_sample_view) &&
    builder.add_sampler(11U, point_shadow_compare_sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d material bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_material_bg",
  )
  backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
    base_texture_id: base_texture.id,
    normal_texture_id: normal_texture.id,
    emissive_texture_id: emissive_texture.id,
    metallic_roughness_texture_id: metallic_roughness_texture.id,
    occlusion_texture_id: occlusion_texture.id,
    depth_texture_id: depth_texture.id,
    anisotropy_texture_id: anisotropy_texture.id,
    specular_tint_texture_id: specular_tint_texture.id,
    transmission_source_texture_id: transmission_source_texture.id,
    point_shadow_texture_id: point_shadow_texture.id,
    bind_group,
  })
  bind_group
}

///|
fn resolve_mesh3d_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  if id < 0 {
    return Some(ensure_default_texture(backend))
  }
  match find_texture(backend, id) {
    Some(texture) => Some(texture)
    None => Some(ensure_default_texture(backend))
  }
}

///|
fn ensure_point_shadow_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.point_shadow_fallback_texture_id >= 0 {
    if find_texture(backend, backend.point_shadow_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let created_id = backend.create_point_light_shadow_target(1)
  backend.point_shadow_fallback_texture_id = created_id
  guard find_texture(backend, created_id) is Some(texture) else {
    fatal("wgpu: failed to initialize point shadow fallback texture")
  }
  texture
}

///|
pub fn GpuBackend::create_mesh3d_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Int {
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = vertices.length() / 12
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
    vertices
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 12) {
      out.push(vertices[i])
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
pub fn GpuBackend::upload_mesh3d_preprocess_camera_payload(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  payload : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  let state_index = mesh3d_preprocess_camera_upload_state_get_or_create(
    self, camera_key_hi, camera_key_lo,
  )
  let direct_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.direct_work_items,
  )
  let (direct_work_item_buffer, direct_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity,
    direct_work_item_bytes,
    "mgstudio_mesh3d_preprocess_direct_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer
  = direct_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  = direct_work_item_capacity
  let indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.indexed_work_items,
  )
  let (indexed_work_item_buffer, indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity,
    indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
  = indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  = indexed_work_item_capacity
  let non_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.non_indexed_work_items,
  )
  let (non_indexed_work_item_buffer, non_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity,
    non_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
  = non_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  = non_indexed_work_item_capacity
  let late_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.late_indexed_work_items,
  )
  let (late_indexed_work_item_buffer, late_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity,
    late_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_late_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
  = late_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  = late_indexed_work_item_capacity
  let late_non_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.late_non_indexed_work_items,
  )
  let (late_non_indexed_work_item_buffer, late_non_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity,
    late_non_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_late_non_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
  = late_non_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  = late_non_indexed_work_item_capacity

  let indexed_cpu_metadata_bytes = mesh3d_preprocess_cpu_metadata_bytes(
    payload.indexed_cpu_metadata,
  )
  let indexed_cpu_metadata_bytes_len_u32 = indexed_cpu_metadata_bytes.length() /
    4
  if indexed_cpu_metadata_bytes_len_u32 !=
    payload.indexed_cpu_metadata.length() *
    MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 {
    return
  }
  let (indexed_cpu_metadata_buffer, indexed_cpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity,
    indexed_cpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_indexed_cpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
  = indexed_cpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  = indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_bytes = mesh3d_preprocess_gpu_metadata_bytes(
    payload.indexed_gpu_metadata,
  )
  let indexed_gpu_metadata_bytes_len_u32 = indexed_gpu_metadata_bytes.length() /
    4
  if indexed_gpu_metadata_bytes_len_u32 !=
    payload.indexed_gpu_metadata.length() *
    MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 {
    return
  }
  let (indexed_gpu_metadata_buffer, indexed_gpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity,
    indexed_gpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_indexed_gpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
  = indexed_gpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  = indexed_gpu_metadata_capacity
  let indexed_batch_set_bytes = mesh3d_preprocess_batch_set_bytes(
    payload.indexed_batch_sets,
  )
  let indexed_batch_set_bytes_len_u32 = indexed_batch_set_bytes.length() / 4
  if indexed_batch_set_bytes_len_u32 !=
    payload.indexed_batch_sets.length() * MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 {
    return
  }
  let (indexed_batch_set_buffer, indexed_batch_set_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity,
    indexed_batch_set_bytes,
    "mgstudio_mesh3d_preprocess_indexed_batch_sets",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
  = indexed_batch_set_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  = indexed_batch_set_capacity

  let non_indexed_cpu_metadata_bytes = mesh3d_preprocess_cpu_metadata_bytes(
    payload.non_indexed_cpu_metadata,
  )
  let non_indexed_cpu_metadata_bytes_len_u32 = non_indexed_cpu_metadata_bytes.length() /
    4
  if non_indexed_cpu_metadata_bytes_len_u32 !=
    payload.non_indexed_cpu_metadata.length() *
    MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 {
    return
  }
  let (non_indexed_cpu_metadata_buffer, non_indexed_cpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity,
    non_indexed_cpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_cpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
  = non_indexed_cpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  = non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_bytes = mesh3d_preprocess_gpu_metadata_bytes(
    payload.non_indexed_gpu_metadata,
  )
  let non_indexed_gpu_metadata_bytes_len_u32 = non_indexed_gpu_metadata_bytes.length() /
    4
  if non_indexed_gpu_metadata_bytes_len_u32 !=
    payload.non_indexed_gpu_metadata.length() *
    MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 {
    return
  }
  let (non_indexed_gpu_metadata_buffer, non_indexed_gpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity,
    non_indexed_gpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_gpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
  = non_indexed_gpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  = non_indexed_gpu_metadata_capacity
  let non_indexed_batch_set_bytes = mesh3d_preprocess_batch_set_bytes(
    payload.non_indexed_batch_sets,
  )
  let non_indexed_batch_set_bytes_len_u32 = non_indexed_batch_set_bytes.length() /
    4
  if non_indexed_batch_set_bytes_len_u32 !=
    payload.non_indexed_batch_sets.length() *
    MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 {
    return
  }
  let (non_indexed_batch_set_buffer, non_indexed_batch_set_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity,
    non_indexed_batch_set_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_batch_sets",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
  = non_indexed_batch_set_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  = non_indexed_batch_set_capacity

  let dispatch_metadata_bytes = mesh3d_preprocess_dispatch_metadata_bytes(
    payload.dispatch_metadata,
  )
  let (dispatch_metadata_buffer, dispatch_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_capacity,
    dispatch_metadata_bytes,
    "mgstudio_mesh3d_preprocess_dispatch_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_buffer
  = dispatch_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_capacity
  = dispatch_metadata_capacity
}

///|
pub fn GpuBackend::draw_mesh3d(
  self : GpuBackend,
  mesh_id : Int,
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
  unlit : Float,
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
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
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
    guard self.mesh3d_motion_vector_mesh_buf is Some(mesh_buf) else { return }
    guard self.mesh3d_motion_vector_mesh_bg is Some(mesh_bg) else { return }
    self.queue.write_buffer(
      view_buf,
      0UL,
      mesh3d_motion_vector_view_uniform_bytes(ps),
    )
    self.queue.write_buffer(
      previous_view_buf,
      0UL,
      mesh3d_motion_vector_previous_view_uniform_bytes(ps),
    )
    self.queue.write_buffer(
      mesh_buf,
      0UL,
      mesh3d_motion_vector_mesh_uniform_bytes(
        x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
        scale_z, previous_x, previous_y, previous_z, previous_rotation_x, previous_rotation_y,
        previous_rotation_z, previous_rotation_w, previous_scale_x, previous_scale_y,
        previous_scale_z,
      ),
    )
    pass.set_pipeline(pipeline)
    pass.set_bind_group(0U, view_bg, [])
    pass.set_bind_group(2U, mesh_bg, [])
    let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
      mesh.vertex_stride_bytes
    pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
    return
  }
  guard mesh3d_pipeline_for_current_pass(
      self,
      transparent,
      mesh.primitive_topology,
      cull_mode,
    )
    is Some(pipeline) else {
    return
  }
  let mut uniform_buffer : @wgpu.Buffer? = None
  let mut uniform_bind_group : @wgpu.BindGroup? = None
  let mut uniform_write_offset = 0UL
  let mut uniform_dynamic_offsets : Array[UInt] = []
  if self.mesh3d_gpu_instance_builder_enabled {
    let next_used_int = self.mesh3d_instance_uniform_used + 512
    if next_used_int < 0 {
      return
    }
    let required_size = next_used_int.to_uint64()
    guard ensure_mesh3d_instance_uniform_binding(self, required_size)
      is Some((instance_uniform_buf, instance_uniform_bg)) else {
      return
    }
    let dynamic_offset = self.mesh3d_instance_uniform_used.reinterpret_as_uint()
    uniform_buffer = Some(instance_uniform_buf)
    uniform_bind_group = Some(instance_uniform_bg)
    uniform_write_offset = self.mesh3d_instance_uniform_used.to_uint64()
    uniform_dynamic_offsets = [dynamic_offset]
    self.mesh3d_instance_uniform_used = next_used_int
  } else {
    let mesh3d_uniform_slot_index = self.mesh3d_uniform_slot_used
    guard ensure_mesh3d_uniform_slot(self, mesh3d_uniform_slot_index)
      is Some(uniform_slot) else {
      return
    }
    self.mesh3d_uniform_slot_used = mesh3d_uniform_slot_index + 1
    uniform_buffer = Some(uniform_slot.buffer)
    uniform_bind_group = Some(uniform_slot.bind_group)
    uniform_write_offset = 0UL
    uniform_dynamic_offsets = [0U]
  }
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    -1
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
  let resolved_transmission_source_texture_id = if transmission_source_texture_id <
    0 {
    -1
  } else {
    transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    point_shadow_texture_id
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
  let textured = texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let emissive_textured = emissive_texture_id >= 0
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let occlusion_textured = occlusion_texture_id >= 0
  let depth_textured = depth_texture_id >= 0
  let anisotropy_textured = anisotropy_texture_id >= 0
  let specular_tint_textured = specular_tint_texture_id >= 0
  let transmission_source_textured = transmission_source_texture_id >= 0
  let point_shadow_textured = point_shadow_texture_id >= 0
  let uv_transform_a_value = uv_transform_a
  let uv_transform_b_value = uv_transform_b
  let uv_transform_c_value = uv_transform_c
  let uv_transform_d_value = uv_transform_d
  let uv_transform_tx_value = uv_transform_tx
  let uv_transform_ty_value = uv_transform_ty
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
  let bytes = f32le_pack([
    x,
    y,
    z,
    1.0F,
    rotation_x,
    rotation_y,
    rotation_z,
    rotation_w,
    scale_x,
    scale_y,
    scale_z,
    1.0F,
    ps.camera_x,
    ps.camera_y,
    ps.camera_z,
    1.0F,
    ps.clip_from_world.x_axis_x,
    ps.clip_from_world.x_axis_y,
    ps.clip_from_world.x_axis_z,
    ps.clip_from_world.x_axis_w,
    ps.clip_from_world.y_axis_x,
    ps.clip_from_world.y_axis_y,
    ps.clip_from_world.y_axis_z,
    ps.clip_from_world.y_axis_w,
    ps.clip_from_world.z_axis_x,
    ps.clip_from_world.z_axis_y,
    ps.clip_from_world.z_axis_z,
    ps.clip_from_world.z_axis_w,
    ps.clip_from_world.w_axis_x,
    ps.clip_from_world.w_axis_y,
    ps.clip_from_world.w_axis_z,
    ps.clip_from_world.w_axis_w,
    color_r,
    color_g,
    color_b,
    color_a,
    uv_transform_a_value,
    uv_transform_b_value,
    uv_transform_c_value,
    uv_transform_tx_value,
    uv_transform_d_value,
    uv_transform_ty_value,
    uv_transform_mode_value,
    0.0F,
    ps.ambient_r,
    ps.ambient_g,
    ps.ambient_b,
    ps.ambient_brightness,
    ps.directional_dir_x,
    ps.directional_dir_y,
    ps.directional_dir_z,
    ps.directional_illuminance,
    ps.directional_color_r,
    ps.directional_color_g,
    ps.directional_color_b,
    1.0F,
    ps.point_pos_x,
    ps.point_pos_y,
    ps.point_pos_z,
    ps.point_range,
    ps.point_color_r,
    ps.point_color_g,
    ps.point_color_b,
    ps.point_intensity,
    ps.spot_pos_x,
    ps.spot_pos_y,
    ps.spot_pos_z,
    ps.spot_range,
    ps.spot_dir_x,
    ps.spot_dir_y,
    ps.spot_dir_z,
    ps.spot_inner_angle,
    ps.spot_color_r,
    ps.spot_color_g,
    ps.spot_color_b,
    ps.spot_intensity,
    ps.spot_outer_angle,
    if transmission_source_textured {
      transmission_blur_taps
    } else {
      0.0F
    },
    if transmission_source_textured {
      transmission_steps
    } else {
      0.0F
    },
    0.0F,
    emissive_r,
    emissive_g,
    emissive_b,
    unlit,
    metallic,
    roughness,
    reflectance,
    if normal_textured {
      1.0F
    } else {
      0.0F
    },
    if textured {
      1.0F
    } else {
      0.0F
    },
    if emissive_textured {
      1.0F
    } else {
      0.0F
    },
    if metallic_roughness_textured {
      1.0F
    } else {
      0.0F
    },
    if occlusion_textured {
      1.0F
    } else {
      0.0F
    },
    parallax_depth_scale,
    max_parallax_layer_count,
    max_relief_mapping_search_steps,
    if depth_textured {
      1.0F
    } else {
      0.0F
    },
    anisotropy_strength,
    cosf(anisotropy_rotation),
    sinf(anisotropy_rotation),
    if anisotropy_textured {
      1.0F
    } else {
      0.0F
    },
    specular_tint_r,
    specular_tint_g,
    specular_tint_b,
    if specular_tint_textured {
      1.0F
    } else {
      0.0F
    },
    diffuse_transmission,
    specular_transmission,
    thickness,
    ior,
    if point_shadow_textured {
      point_shadow_enabled
    } else {
      0.0F
    },
    if point_shadow_textured {
      point_shadow_depth_bias
    } else {
      0.0F
    },
    if point_shadow_textured {
      ps.point_shadow_near
    } else {
      0.1F
    },
    ps.camera_exposure,
  ])
  guard uniform_buffer is Some(active_uniform_buffer) else { return }
  guard uniform_bind_group is Some(active_uniform_bg) else { return }
  self.queue.write_buffer(active_uniform_buffer, uniform_write_offset, bytes)
  let material_bg = mesh3d_material_cache_get_or_create(
    self, base_texture, normal_texture, emissive_texture, metallic_roughness_texture,
    occlusion_texture, depth_texture, anisotropy_texture, specular_tint_texture,
    transmission_source_texture, point_shadow_texture,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, active_uniform_bg, uniform_dynamic_offsets)
  pass.set_bind_group(1U, material_bg, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  debug_mesh3d_executed_draw_calls_ref.val = debug_mesh3d_executed_draw_calls_ref.val +
    1
  current_frame_mesh3d_executed_draw_calls_ref.val = current_frame_mesh3d_executed_draw_calls_ref.val +
    1
  if mesh.primitive_topology == MESH3D_TOPOLOGY_LINE_STRIP {
    pass.draw(mesh.vertex_count, 1U, 0U, 0U)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
  }
}

///|
