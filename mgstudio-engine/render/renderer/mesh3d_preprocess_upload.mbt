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
const MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 : Int = 2

///|
const MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 : Int = 3

///|
const MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 : Int = 2

///|
const MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES : UInt64 = 20UL

///|
const MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES : UInt64 = 16UL

///|
const MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES : UInt64 = 32UL

///|
const MESH3D_PREPROCESS_WORKGROUP_SIZE : Int = 64

///|
const MESH3D_DRAW_INDIRECT_KIND_NONE : Int = 0

///|
const MESH3D_DRAW_INDIRECT_KIND_INDEXED : Int = 1

///|
const MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED : Int = 2

///|
const MESH3D_PREPROCESS_INPUT_FLAG_SIGN_DETERMINANT_MODEL_3X3 : UInt = 1U << 31

///|
fn mesh3d_preprocess_camera_upload_state_new(
  key_hi : Int,
  key_lo : Int,
) -> GpuMesh3dPreprocessCameraUploadState {
  GpuMesh3dPreprocessCameraUploadState::{
    key_hi,
    key_lo,
    mesh_input_buffer: None,
    mesh_input_capacity: 0UL,
    previous_mesh_input_buffer: None,
    previous_mesh_input_capacity: 0UL,
    output_buffer: None,
    output_capacity: 0UL,
    output_count: 0,
    motion_vector_mesh_bind_group: None,
    motion_vector_mesh_bind_group_skin_revision: -1,
    preprocess_main_direct_bind_group: None,
    preprocess_main_indexed_bind_group: None,
    preprocess_main_non_indexed_bind_group: None,
    preprocess_early_indexed_bind_group: None,
    preprocess_early_non_indexed_bind_group: None,
    preprocess_late_indexed_bind_group: None,
    preprocess_late_non_indexed_bind_group: None,
    build_indirect_reset_indexed_bind_group: None,
    build_indirect_reset_non_indexed_bind_group: None,
    build_indirect_indexed_bind_group: None,
    build_indirect_non_indexed_bind_group: None,
    preprocess_view_buffer: None,
    preprocess_view_capacity: 0UL,
    previous_view_buffer: None,
    previous_view_capacity: 0UL,
    mesh_culling_data_buffer: None,
    mesh_culling_data_capacity: 0UL,
    direct_work_item_buffer: None,
    direct_work_item_capacity: 0UL,
    direct_work_item_count: 0,
    indexed_work_item_buffer: None,
    indexed_work_item_capacity: 0UL,
    indexed_work_item_count: 0,
    non_indexed_work_item_buffer: None,
    non_indexed_work_item_capacity: 0UL,
    non_indexed_work_item_count: 0,
    late_indexed_work_item_buffer: None,
    late_indexed_work_item_capacity: 0UL,
    late_indexed_work_item_count: 0,
    late_non_indexed_work_item_buffer: None,
    late_non_indexed_work_item_capacity: 0UL,
    late_non_indexed_work_item_count: 0,
    late_indexed_dispatch_indirect_buffer: None,
    late_indexed_dispatch_indirect_capacity: 0UL,
    late_non_indexed_dispatch_indirect_buffer: None,
    late_non_indexed_dispatch_indirect_capacity: 0UL,
    indexed_cpu_metadata_buffer: None,
    indexed_cpu_metadata_capacity: 0UL,
    indexed_gpu_metadata_buffer: None,
    indexed_gpu_metadata_capacity: 0UL,
    indexed_gpu_metadata_count: 0,
    indexed_batch_set_buffer: None,
    indexed_batch_set_capacity: 0UL,
    indexed_batch_set_count: 0,
    indexed_indirect_parameters_buffer: None,
    indexed_indirect_parameters_capacity: 0UL,
    non_indexed_cpu_metadata_buffer: None,
    non_indexed_cpu_metadata_capacity: 0UL,
    non_indexed_gpu_metadata_buffer: None,
    non_indexed_gpu_metadata_capacity: 0UL,
    non_indexed_gpu_metadata_count: 0,
    non_indexed_batch_set_buffer: None,
    non_indexed_batch_set_capacity: 0UL,
    non_indexed_batch_set_count: 0,
    non_indexed_indirect_parameters_buffer: None,
    non_indexed_indirect_parameters_capacity: 0UL,
    dispatch_metadata_buffer: None,
    dispatch_metadata_capacity: 0UL,
    direct_workgroup_count: 0,
    indexed_workgroup_count: 0,
    non_indexed_workgroup_count: 0,
    depth_pyramid_texture: None,
    depth_pyramid_all_mips_view: None,
    depth_pyramid_mips: [],
    depth_pyramid_width: 0,
    depth_pyramid_height: 0,
    depth_pyramid_mip_count: 0,
  }
}

///|
fn mesh3d_preprocess_camera_upload_state_key(
  key_hi : Int,
  key_lo : Int,
) -> UInt64 {
  let hi = key_hi.reinterpret_as_uint().to_uint64()
  let lo = key_lo.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn mesh3d_preprocess_camera_upload_state_index(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> Int? {
  let key = mesh3d_preprocess_camera_upload_state_key(key_hi, key_lo)
  if backend.mesh3d_preprocess_camera_upload_state_indices.get(key)
    is Some(index) &&
    index >= 0 &&
    index < backend.mesh3d_preprocess_camera_upload_states.length() {
    let state = backend.mesh3d_preprocess_camera_upload_states[index]
    if state.key_hi == key_hi && state.key_lo == key_lo {
      return Some(index)
    }
  }
  for i in 0..<backend.mesh3d_preprocess_camera_upload_states.length() {
    let state = backend.mesh3d_preprocess_camera_upload_states[i]
    if state.key_hi == key_hi && state.key_lo == key_lo {
      backend.mesh3d_preprocess_camera_upload_state_indices.set(key, i)
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
  let key = mesh3d_preprocess_camera_upload_state_key(key_hi, key_lo)
  backend.mesh3d_preprocess_camera_upload_states.push(
    mesh3d_preprocess_camera_upload_state_new(key_hi, key_lo),
  )
  let state_index = backend.mesh3d_preprocess_camera_upload_states.length() - 1
  backend.mesh3d_preprocess_camera_upload_state_indices.set(key, state_index)
  state_index
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
fn mesh3d_preprocess_ensure_uniform_buffer(
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
  let buffer = backend.device.create_buffer(
    size=next_capacity,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
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
fn mesh3d_preprocess_upload_uniform_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  let required_size = bytes.length().to_uint64()
  let (buffer_opt, next_capacity) = mesh3d_preprocess_ensure_uniform_buffer(
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
  let bytes = Array::make(items.length() * 8, b'\x00')
  let mut byte_offset = 0
  for item in items {
    u32le_write_into(bytes, byte_offset, item.input_index.reinterpret_as_uint())
    u32le_write_into(
      bytes,
      byte_offset + 4,
      item.output_or_indirect_parameters_index.reinterpret_as_uint(),
    )
    byte_offset = byte_offset + 8
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_mesh_input_sign_determinant(
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> UInt {
  if scale_x * scale_y * scale_z >= 0.0F {
    MESH3D_PREPROCESS_INPUT_FLAG_SIGN_DETERMINANT_MODEL_3X3
  } else {
    0U
  }
}

///|
fn mesh3d_preprocess_mesh_input_words(
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
  flags : UInt,
  previous_input_index : UInt,
  first_vertex_index : Int,
  first_index_index : Int,
  index_count : Int,
  tag : Int,
  frame_count : UInt,
) -> Array[UInt] {
  let words : Array[UInt] = []
  for
    word in mesh3d_world_from_local_words(
      translation_x, translation_y, translation_z, rotation_x, rotation_y, rotation_z,
      rotation_w, scale_x, scale_y, scale_z,
    ) {
    words.push(word)
  }
  words.push(0U)
  words.push(0U)
  words.push(flags)
  words.push(previous_input_index)
  words.push(first_vertex_index.reinterpret_as_uint())
  words.push(first_index_index.reinterpret_as_uint())
  words.push(index_count.reinterpret_as_uint())
  words.push(0xffffffffU)
  words.push(0U)
  words.push(frame_count)
  words.push(tag.reinterpret_as_uint())
  words.push(0U)
  words
}

///|
fn mesh3d_preprocess_mesh_inputs_bytes(
  frame_count : UInt,
  inputs : Array[HostMesh3dPreprocessMeshInput],
) -> (Bytes, Bytes) {
  let words : Array[UInt] = []
  let previous_words : Array[UInt] = []
  let input_len = inputs.length()
  for input in inputs {
    let runtime_flags = input.flags |
      mesh3d_preprocess_mesh_input_sign_determinant(
        input.scale_x,
        input.scale_y,
        input.scale_z,
      )
    for
      word in mesh3d_preprocess_mesh_input_words(
        input.translation_x,
        input.translation_y,
        input.translation_z,
        input.rotation_x,
        input.rotation_y,
        input.rotation_z,
        input.rotation_w,
        input.scale_x,
        input.scale_y,
        input.scale_z,
        runtime_flags,
        if input_len > 0 {
          (words.length() / 24).reinterpret_as_uint()
        } else {
          0xffffffffU
        },
        input.first_vertex_index,
        input.first_index_index,
        input.index_count,
        input.tag,
        frame_count,
      ) {
      words.push(word)
    }
    let previous_flags = input.flags |
      mesh3d_preprocess_mesh_input_sign_determinant(
        input.previous_scale_x,
        input.previous_scale_y,
        input.previous_scale_z,
      )
    for
      word in mesh3d_preprocess_mesh_input_words(
        input.previous_translation_x,
        input.previous_translation_y,
        input.previous_translation_z,
        input.previous_rotation_x,
        input.previous_rotation_y,
        input.previous_rotation_z,
        input.previous_rotation_w,
        input.previous_scale_x,
        input.previous_scale_y,
        input.previous_scale_z,
        previous_flags,
        0xffffffffU,
        input.first_vertex_index,
        input.first_index_index,
        input.index_count,
        input.tag,
        0U,
      ) {
      previous_words.push(word)
    }
  }
  (u32le_pack(words), u32le_pack(previous_words))
}

///|
fn mesh3d_preprocess_cpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersCpuMetadata],
) -> Bytes {
  let bytes = Array::make(metadata.length() * 8, b'\x00')
  let mut byte_offset = 0
  for entry in metadata {
    u32le_write_into(
      bytes,
      byte_offset,
      entry.base_output_index.reinterpret_as_uint(),
    )
    u32le_write_into(
      bytes,
      byte_offset + 4,
      entry.batch_set_index.reinterpret_as_uint(),
    )
    byte_offset = byte_offset + 8
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_gpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersGpuMetadata],
) -> Bytes {
  let bytes = Array::make(metadata.length() * 12, b'\x00')
  let mut byte_offset = 0
  for entry in metadata {
    u32le_write_into(bytes, byte_offset, entry.mesh_index.reinterpret_as_uint())
    u32le_write_into(
      bytes,
      byte_offset + 4,
      entry.early_instance_count.reinterpret_as_uint(),
    )
    u32le_write_into(
      bytes,
      byte_offset + 8,
      entry.late_instance_count.reinterpret_as_uint(),
    )
    byte_offset = byte_offset + 12
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_batch_set_bytes(
  batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet],
) -> Bytes {
  let bytes = Array::make(batch_sets.length() * 8, b'\x00')
  let mut byte_offset = 0
  for batch_set in batch_sets {
    u32le_write_into(
      bytes,
      byte_offset,
      batch_set.indirect_parameters_count.reinterpret_as_uint(),
    )
    u32le_write_into(
      bytes,
      byte_offset + 4,
      batch_set.indirect_parameters_base.reinterpret_as_uint(),
    )
    byte_offset = byte_offset + 8
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_dispatch_metadata_bytes(
  metadata : HostMesh3dPreprocessDispatchMetadata,
) -> Bytes {
  let bytes = Array::make(20, b'\x00')
  u32le_write_into(
    bytes,
    0,
    metadata.direct_workgroup_count.reinterpret_as_uint(),
  )
  u32le_write_into(
    bytes,
    4,
    metadata.indexed_workgroup_count.reinterpret_as_uint(),
  )
  u32le_write_into(
    bytes,
    8,
    metadata.non_indexed_workgroup_count.reinterpret_as_uint(),
  )
  u32le_write_into(
    bytes,
    12,
    metadata.late_indexed_workgroup_count.reinterpret_as_uint(),
  )
  u32le_write_into(
    bytes,
    16,
    metadata.late_non_indexed_workgroup_count.reinterpret_as_uint(),
  )
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_frustum_plane_words(
  plane : HostMesh3dPreprocessFrustumPlane,
) -> Array[UInt] {
  [
    f32_bits(plane.normal_x),
    f32_bits(plane.normal_y),
    f32_bits(plane.normal_z),
    f32_bits(plane.distance),
  ]
}

///|
fn mesh3d_preprocess_mesh_culling_data_bytes(
  culling_data : Array[HostMesh3dPreprocessMeshCullingData],
) -> Bytes {
  let bytes = Array::make(culling_data.length() * 32, b'\x00')
  let mut byte_offset = 0
  for entry in culling_data {
    u32le_write_into(bytes, byte_offset, f32_bits(entry.aabb_center_x))
    u32le_write_into(bytes, byte_offset + 4, f32_bits(entry.aabb_center_y))
    u32le_write_into(bytes, byte_offset + 8, f32_bits(entry.aabb_center_z))
    u32le_write_into(bytes, byte_offset + 12, 0U)
    u32le_write_into(
      bytes,
      byte_offset + 16,
      f32_bits(entry.aabb_half_extents_x),
    )
    u32le_write_into(
      bytes,
      byte_offset + 20,
      f32_bits(entry.aabb_half_extents_y),
    )
    u32le_write_into(
      bytes,
      byte_offset + 24,
      f32_bits(entry.aabb_half_extents_z),
    )
    u32le_write_into(bytes, byte_offset + 28, 0U)
    byte_offset = byte_offset + 32
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_preprocess_append_clip_matrix_words(
  words : Array[UInt],
  matrix : GpuClipMatrix,
) -> Unit {
  words.push(f32_bits(matrix.x_axis_x))
  words.push(f32_bits(matrix.x_axis_y))
  words.push(f32_bits(matrix.x_axis_z))
  words.push(f32_bits(matrix.x_axis_w))
  words.push(f32_bits(matrix.y_axis_x))
  words.push(f32_bits(matrix.y_axis_y))
  words.push(f32_bits(matrix.y_axis_z))
  words.push(f32_bits(matrix.y_axis_w))
  words.push(f32_bits(matrix.z_axis_x))
  words.push(f32_bits(matrix.z_axis_y))
  words.push(f32_bits(matrix.z_axis_z))
  words.push(f32_bits(matrix.z_axis_w))
  words.push(f32_bits(matrix.w_axis_x))
  words.push(f32_bits(matrix.w_axis_y))
  words.push(f32_bits(matrix.w_axis_z))
  words.push(f32_bits(matrix.w_axis_w))
}

///|
fn mesh3d_preprocess_view_uniform_bytes(
  view : HostMesh3dPreprocessView,
  frame_count : UInt,
) -> Bytes {
  let words : Array[UInt] = []
  mesh3d_preprocess_append_clip_matrix_words(words, view.clip_from_world)
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    view.unjittered_clip_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(words, view.world_from_clip)
  mesh3d_preprocess_append_clip_matrix_words(words, view.world_from_view)
  mesh3d_preprocess_append_clip_matrix_words(words, view.view_from_world)
  mesh3d_preprocess_append_clip_matrix_words(words, view.clip_from_view)
  mesh3d_preprocess_append_clip_matrix_words(words, view.view_from_clip)
  words.push(f32_bits(view.world_position_x))
  words.push(f32_bits(view.world_position_y))
  words.push(f32_bits(view.world_position_z))
  words.push(f32_bits(view.exposure))
  words.push(f32_bits(view.viewport_x))
  words.push(f32_bits(view.viewport_y))
  words.push(f32_bits(view.viewport_width))
  words.push(f32_bits(view.viewport_height))
  words.push(f32_bits(view.main_pass_viewport_x))
  words.push(f32_bits(view.main_pass_viewport_y))
  words.push(f32_bits(view.main_pass_viewport_width))
  words.push(f32_bits(view.main_pass_viewport_height))
  for i in 0..<6 {
    let plane = if i < view.frustum_planes.length() {
      view.frustum_planes[i]
    } else {
      HostMesh3dPreprocessFrustumPlane::{
        normal_x: 0.0F,
        normal_y: 0.0F,
        normal_z: 0.0F,
        distance: 0.0F,
      }
    }
    for word in mesh3d_preprocess_frustum_plane_words(plane) {
      words.push(word)
    }
  }
  for _ in 0..<40 {
    words.push(0U)
  }
  words.push(f32_bits(view.mip_bias))
  words.push(frame_count)
  words.push(0U)
  words.push(0U)
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_previous_view_uniform_bytes(
  previous_view : HostMesh3dPreprocessPreviousView,
) -> Bytes {
  let words : Array[UInt] = []
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.view_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.clip_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.clip_from_view,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.world_from_clip,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.view_from_clip,
  )
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_late_dispatch_parameters_default_bytes() -> Bytes {
  u32le_pack([0U, 1U, 1U, 0U, 0U, 0U, 0U, 0U])
}

///|
fn mesh3d_preprocess_previous_power_of_two(value : Int) -> Int {
  let safe_value = if value <= 1 { 1 } else { value }
  let mut power = 1
  while power * 2 > 0 && power * 2 <= safe_value {
    power = power * 2
  }
  power
}

///|
fn mesh3d_preprocess_next_power_of_two(value : Int) -> Int {
  let safe_value = if value <= 1 { 1 } else { value }
  let mut power = 1
  while power < safe_value {
    power = power * 2
  }
  power
}

///|
fn mesh3d_preprocess_depth_pyramid_mip_count(width : Int, height : Int) -> Int {
  let mut max_dim = if width > height { width } else { height }
  if max_dim <= 0 {
    return 1
  }
  let mut mip_count = 0
  while max_dim > 0 && mip_count < 12 {
    mip_count = mip_count + 1
    max_dim = max_dim / 2
  }
  if mip_count <= 0 {
    1
  } else {
    mip_count
  }
}

///|
fn mesh3d_preprocess_depth_pyramid_dispatch_size(size : Int) -> UInt {
  mesh3d_preprocess_next_power_of_two(size + 1).reinterpret_as_uint()
}
