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

pub fn GpuBackend::upload_mesh3d_preprocess_camera_payload(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  payload : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  let state_index = mesh3d_preprocess_camera_upload_state_get_or_create(
    self, camera_key_hi, camera_key_lo,
  )
  let old_preprocess_view_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let old_previous_view_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let old_mesh_input_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let old_previous_mesh_input_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let old_output_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let old_mesh_culling_data_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let old_direct_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  let old_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let old_non_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let old_late_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  let old_late_non_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  let old_late_indexed_dispatch_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity
  let old_late_non_indexed_dispatch_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity
  let old_indexed_cpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let old_indexed_gpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let old_indexed_batch_set_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  let old_indexed_indirect_parameters_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  let old_non_indexed_cpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let old_non_indexed_gpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let old_non_indexed_batch_set_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  let old_non_indexed_indirect_parameters_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  let (mesh_input_bytes, previous_mesh_input_bytes) = mesh3d_preprocess_mesh_inputs_bytes(
    self.frame_count,
    payload.mesh_inputs,
  )
  let preprocess_view_bytes = mesh3d_preprocess_view_uniform_bytes(
    payload.view,
    self.frame_count,
  )
  let previous_view_bytes = mesh3d_preprocess_previous_view_uniform_bytes(
    payload.previous_view,
  )
  let mesh_culling_data_bytes = mesh3d_preprocess_mesh_culling_data_bytes(
    payload.mesh_culling_data,
  )
  let late_dispatch_default_bytes = mesh3d_preprocess_late_dispatch_parameters_default_bytes()
  let (mesh_input_buffer, mesh_input_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity,
    mesh_input_bytes,
    "mgstudio_mesh3d_preprocess_mesh_inputs",
  )
  let (previous_mesh_input_buffer, previous_mesh_input_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity,
    previous_mesh_input_bytes,
    "mgstudio_mesh3d_preprocess_previous_mesh_inputs",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer = mesh_input_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity = mesh_input_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
  = previous_mesh_input_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  = previous_mesh_input_capacity
  let output_required_size = payload.mesh_inputs.length().to_uint64() *
    MESH3D_PREPASS_MESH_BUFFER_SIZE
  let (output_buffer, output_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].output_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity,
    output_required_size,
    "mgstudio_mesh3d_preprocess_output",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].output_buffer = output_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity = output_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].output_count = payload.mesh_inputs.length()
  let (preprocess_view_buffer, preprocess_view_capacity) = mesh3d_preprocess_upload_uniform_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity,
    preprocess_view_bytes,
    "mgstudio_mesh3d_preprocess_view",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
  = preprocess_view_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  = preprocess_view_capacity
  let (previous_view_buffer, previous_view_capacity) = mesh3d_preprocess_upload_uniform_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity,
    previous_view_bytes,
    "mgstudio_mesh3d_preprocess_previous_view",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
  = previous_view_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  = previous_view_capacity
  let (mesh_culling_data_buffer, mesh_culling_data_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity,
    mesh_culling_data_bytes,
    "mgstudio_mesh3d_preprocess_mesh_culling_data",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
  = mesh_culling_data_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  = mesh_culling_data_capacity
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
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_count
  = payload.direct_work_items.length()
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
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_count
  = payload.indexed_work_items.length()
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
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_count
  = payload.non_indexed_work_items.length()
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
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_count
  = payload.late_indexed_work_items.length()
  if self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is None {
    let (buffer, capacity) = mesh3d_preprocess_ensure_storage_buffer(
      self,
      None,
      0UL,
      8UL,
      "mgstudio_mesh3d_preprocess_late_indexed_work_items",
    )
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    = buffer
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
    = capacity
  }
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
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_count
  = payload.late_non_indexed_work_items.length()
  if self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is None {
    let (buffer, capacity) = mesh3d_preprocess_ensure_storage_buffer(
      self,
      None,
      0UL,
      8UL,
      "mgstudio_mesh3d_preprocess_late_non_indexed_work_items",
    )
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    = buffer
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
    = capacity
  }
  let (
    late_indexed_dispatch_indirect_buffer,
    late_indexed_dispatch_indirect_capacity,
  ) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity,
    late_dispatch_default_bytes,
    "mgstudio_mesh3d_preprocess_late_indexed_dispatch_indirect",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
  = late_indexed_dispatch_indirect_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity
  = late_indexed_dispatch_indirect_capacity
  let (
    late_non_indexed_dispatch_indirect_buffer,
    late_non_indexed_dispatch_indirect_capacity,
  ) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity,
    late_dispatch_default_bytes,
    "mgstudio_mesh3d_preprocess_late_non_indexed_dispatch_indirect",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
  = late_non_indexed_dispatch_indirect_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity
  = late_non_indexed_dispatch_indirect_capacity

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
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_count
  = payload.indexed_gpu_metadata.length()
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
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_count
  = payload.indexed_batch_sets.length()
  let indexed_indirect_parameters_required_size = payload.indexed_gpu_metadata
    .length()
    .to_uint64() *
    MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
  let (indexed_indirect_parameters_buffer, indexed_indirect_parameters_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity,
    indexed_indirect_parameters_required_size,
    "mgstudio_mesh3d_preprocess_indexed_indirect_parameters",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer
  = indexed_indirect_parameters_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  = indexed_indirect_parameters_capacity

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
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_count
  = payload.non_indexed_gpu_metadata.length()
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
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_count
  = payload.non_indexed_batch_sets.length()
  let non_indexed_indirect_parameters_required_size = payload.non_indexed_gpu_metadata
    .length()
    .to_uint64() *
    MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
  let (
    non_indexed_indirect_parameters_buffer,
    non_indexed_indirect_parameters_capacity,
  ) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity,
    non_indexed_indirect_parameters_required_size,
    "mgstudio_mesh3d_preprocess_non_indexed_indirect_parameters",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer
  = non_indexed_indirect_parameters_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  = non_indexed_indirect_parameters_capacity

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
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_workgroup_count
  = payload.dispatch_metadata.direct_workgroup_count
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_workgroup_count
  = payload.dispatch_metadata.indexed_workgroup_count
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_workgroup_count
  = payload.dispatch_metadata.non_indexed_workgroup_count
  let requested_depth_pyramid_width = mesh3d_preprocess_previous_power_of_two(
    if payload.view.main_pass_viewport_width <= 1.0F {
      1
    } else {
      payload.view.main_pass_viewport_width.to_int()
    },
  )
  let requested_depth_pyramid_height = mesh3d_preprocess_previous_power_of_two(
    if payload.view.main_pass_viewport_height <= 1.0F {
      1
    } else {
      payload.view.main_pass_viewport_height.to_int()
    },
  )
  let requested_depth_pyramid_mip_count = mesh3d_preprocess_depth_pyramid_mip_count(
    requested_depth_pyramid_width, requested_depth_pyramid_height,
  )
  let current_state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let depth_pyramid_needs_resize = current_state.depth_pyramid_texture is None ||
    current_state.depth_pyramid_width != requested_depth_pyramid_width ||
    current_state.depth_pyramid_height != requested_depth_pyramid_height ||
    current_state.depth_pyramid_mip_count != requested_depth_pyramid_mip_count
  if depth_pyramid_needs_resize {
    for view in current_state.depth_pyramid_mips {
      view.release()
    }
    current_state.depth_pyramid_mips.clear()
    if current_state.depth_pyramid_all_mips_view is Some(view) {
      view.release()
    }
    if current_state.depth_pyramid_texture is Some(texture) {
      texture.release()
    }
    let usage = @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
    )
    let texture = self.device.create_texture_u32(
      requested_depth_pyramid_width.reinterpret_as_uint(),
      requested_depth_pyramid_height.reinterpret_as_uint(),
      1U,
      usage,
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      mip_level_count=requested_depth_pyramid_mip_count.reinterpret_as_uint(),
    )
    let all_mips_view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      requested_depth_pyramid_mip_count.reinterpret_as_uint(),
    )
    let mip_views : Array[@wgpu.TextureView] = []
    for mip_level in 0..<requested_depth_pyramid_mip_count {
      mip_views.push(
        texture.create_view_u32(
          tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
          @wgpu.TEXTURE_VIEW_DIMENSION_2D,
          @wgpu.TEXTURE_ASPECT_ALL,
          0U,
          1U,
          mip_level.reinterpret_as_uint(),
          1U,
        ),
      )
    }
    current_state.depth_pyramid_texture = Some(texture)
    current_state.depth_pyramid_all_mips_view = Some(all_mips_view)
    current_state.depth_pyramid_mips = mip_views
    current_state.depth_pyramid_width = requested_depth_pyramid_width
    current_state.depth_pyramid_height = requested_depth_pyramid_height
    current_state.depth_pyramid_mip_count = requested_depth_pyramid_mip_count
  }
  let direct_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_direct_work_item_capacity != direct_work_item_capacity ||
    old_output_capacity != output_capacity
  if direct_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
    = None
  }
  let indexed_main_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_indexed_work_item_capacity != indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity
  if indexed_main_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
    = None
  }
  let non_indexed_main_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_non_indexed_work_item_capacity != non_indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity
  if non_indexed_main_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
    = None
  }
  let indexed_early_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_indexed_work_item_capacity != indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_indexed_work_item_capacity != late_indexed_work_item_capacity ||
    old_late_indexed_dispatch_capacity !=
    late_indexed_dispatch_indirect_capacity
  if indexed_early_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
    = None
  }
  let indexed_late_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_indexed_work_item_capacity != late_indexed_work_item_capacity ||
    old_late_indexed_dispatch_capacity !=
    late_indexed_dispatch_indirect_capacity
  if indexed_late_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
    = None
  }
  let non_indexed_early_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_non_indexed_work_item_capacity != non_indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_non_indexed_work_item_capacity !=
    late_non_indexed_work_item_capacity ||
    old_late_non_indexed_dispatch_capacity !=
    late_non_indexed_dispatch_indirect_capacity
  if non_indexed_early_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
    = None
  }
  let non_indexed_late_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_non_indexed_work_item_capacity !=
    late_non_indexed_work_item_capacity ||
    old_late_non_indexed_dispatch_capacity !=
    late_non_indexed_dispatch_indirect_capacity
  if non_indexed_late_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
    = None
  }
  let indexed_reset_bind_group_dirty = old_indexed_batch_set_capacity !=
    indexed_batch_set_capacity
  if indexed_reset_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
    = None
  }
  let non_indexed_reset_bind_group_dirty = old_non_indexed_batch_set_capacity !=
    non_indexed_batch_set_capacity
  if non_indexed_reset_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
    = None
  }
  let indexed_build_bind_group_dirty = old_mesh_input_capacity !=
    mesh_input_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_indexed_batch_set_capacity != indexed_batch_set_capacity ||
    old_indexed_indirect_parameters_capacity !=
    indexed_indirect_parameters_capacity
  if indexed_build_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    = None
  }
  let non_indexed_build_bind_group_dirty = old_mesh_input_capacity !=
    mesh_input_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_non_indexed_batch_set_capacity != non_indexed_batch_set_capacity ||
    old_non_indexed_indirect_parameters_capacity !=
    non_indexed_indirect_parameters_capacity
  if non_indexed_build_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    = None
  }
  mesh3d_preprocess_main_direct_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_main_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_main_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_early_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_early_non_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_preprocess_late_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_late_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_build_indirect_reset_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_build_indirect_reset_non_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_build_indirect_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_build_indirect_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
}

///|
pub fn GpuBackend::preprocess_mesh3d(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  phase_kind : Int,
) -> Unit raise GpuBackendError {
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard self.frame is Some(frame) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let compute_pass = frame.encoder.begin_compute_pass()
  if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN {
    if state.direct_workgroup_count > 0 &&
      state.direct_work_item_count > 0 &&
      self.mesh3d_preprocess_direct_pipeline is Some(preprocess_direct_pipeline) &&
      state.preprocess_main_direct_bind_group is Some(bind_group) {
      compute_pass.set_pipeline(preprocess_direct_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.direct_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    }
  }
  let indexed_work_item_buffer = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_indexed_work_item_buffer
  } else {
    state.indexed_work_item_buffer
  }
  let indexed_work_item_count = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_indexed_work_item_count
  } else {
    state.indexed_work_item_count
  }
  let non_indexed_work_item_buffer = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_non_indexed_work_item_buffer
  } else {
    state.non_indexed_work_item_buffer
  }
  let non_indexed_work_item_count = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_non_indexed_work_item_count
  } else {
    state.non_indexed_work_item_count
  }
  if indexed_work_item_count > 0 && indexed_work_item_buffer is Some(_) {
    if phase_kind == MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
      is Some(bind_group) &&
      self.mesh3d_preprocess_indirect_early_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.indexed_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
      is Some(bind_group) &&
      state.late_indexed_dispatch_indirect_buffer is Some(late_dispatch_buffer) &&
      self.mesh3d_preprocess_indirect_late_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups_indirect(late_dispatch_buffer, 0UL)
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN &&
      self.mesh3d_preprocess_indirect_pipeline is Some(preprocess_pipeline) {
      if self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
        is Some(bind_group) {
        compute_pass.set_pipeline(preprocess_pipeline)
        compute_pass.set_bind_group(0U, bind_group, [])
        compute_pass.dispatch_workgroups(
          state.indexed_workgroup_count.reinterpret_as_uint(),
          1U,
          1U,
        )
      }
    }
  }
  if non_indexed_work_item_count > 0 && non_indexed_work_item_buffer is Some(_) {
    if phase_kind == MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
      is Some(bind_group) &&
      self.mesh3d_preprocess_indirect_early_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.non_indexed_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
      is Some(bind_group) &&
      state.late_non_indexed_dispatch_indirect_buffer
      is Some(late_dispatch_buffer) &&
      self.mesh3d_preprocess_indirect_late_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups_indirect(late_dispatch_buffer, 0UL)
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN &&
      self.mesh3d_preprocess_indirect_pipeline is Some(preprocess_pipeline) {
      if self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
        is Some(bind_group) {
        compute_pass.set_pipeline(preprocess_pipeline)
        compute_pass.set_bind_group(0U, bind_group, [])
        compute_pass.dispatch_workgroups(
          state.non_indexed_workgroup_count.reinterpret_as_uint(),
          1U,
          1U,
        )
      }
    }
  }
  compute_pass.end()
  compute_pass.release()
}

///|
pub fn GpuBackend::build_mesh3d_indirect_parameters(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  phase_kind : Int,
) -> Unit raise GpuBackendError {
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard self.frame is Some(frame) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let compute_pass = frame.encoder.begin_compute_pass()
  if state.indexed_batch_set_count > 0 &&
    self.mesh3d_preprocess_reset_batch_sets_pipeline is Some(reset_pipeline) {
    if self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
      is Some(bind_group) {
      compute_pass.set_pipeline(reset_pipeline)
      compute_pass.set_bind_group0(bind_group)
      let workgroup_count = ((
        state.indexed_batch_set_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
      ) /
      MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
      compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
    }
  }
  if state.indexed_gpu_metadata_count > 0 &&
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    is Some(bind_group) {
    let indexed_pipeline = if phase_kind == MESH3D_BUILD_INDIRECT_PHASE_EARLY {
      self.mesh3d_preprocess_build_indexed_indirect_early_pipeline
    } else {
      self.mesh3d_preprocess_build_indexed_indirect_pipeline
    }
    guard indexed_pipeline is Some(indexed_pipeline) else {
      compute_pass.end()
      compute_pass.release()
      return
    }
    compute_pass.set_pipeline(indexed_pipeline)
    compute_pass.set_bind_group0(bind_group)
    let workgroup_count = ((
      state.indexed_gpu_metadata_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
    ) /
    MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
    compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
  }
  if state.non_indexed_batch_set_count > 0 &&
    self.mesh3d_preprocess_reset_batch_sets_pipeline is Some(reset_pipeline) {
    if self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
      is Some(bind_group) {
      compute_pass.set_pipeline(reset_pipeline)
      compute_pass.set_bind_group0(bind_group)
      let workgroup_count = ((
        state.non_indexed_batch_set_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
      ) /
      MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
      compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
    }
  }
  if state.non_indexed_gpu_metadata_count > 0 &&
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    is Some(bind_group) {
    let non_indexed_pipeline = if phase_kind ==
      MESH3D_BUILD_INDIRECT_PHASE_EARLY {
      self.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline
    } else {
      self.mesh3d_preprocess_build_non_indexed_indirect_pipeline
    }
    guard non_indexed_pipeline is Some(non_indexed_pipeline) else {
      compute_pass.end()
      compute_pass.release()
      return
    }
    compute_pass.set_pipeline(non_indexed_pipeline)
    compute_pass.set_bind_group0(bind_group)
    let workgroup_count = ((
      state.non_indexed_gpu_metadata_count +
      MESH3D_PREPROCESS_WORKGROUP_SIZE -
      1
    ) /
    MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
    compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
  }
  compute_pass.end()
  compute_pass.release()
}

///|
pub fn GpuBackend::downsample_mesh3d_depth_pyramid(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.depth_view is Some(depth_view) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  guard state.depth_pyramid_mip_count > 1 else { return }
  guard self.mesh3d_preprocess_depth_pyramid_dummy_view is Some(dummy_view) else {
    return
  }
  guard self.mesh3d_preprocess_depth_pyramid_sampler is Some(sampler) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_bgl is Some(downsample_bgl) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_first_pipeline
    is Some(first_pipeline) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_second_pipeline
    is Some(second_pipeline) else {
    return
  }
  let mip_views = state.depth_pyramid_mips
  let mip_or_dummy = fn(index : Int) -> @wgpu.TextureView {
    if index >= 0 && index < mip_views.length() {
      mip_views[index]
    } else {
      dummy_view
    }
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let ok = builder.add_texture_view(0U, depth_view) &&
    builder.add_texture_view(1U, mip_or_dummy(1)) &&
    builder.add_texture_view(2U, mip_or_dummy(2)) &&
    builder.add_texture_view(3U, mip_or_dummy(3)) &&
    builder.add_texture_view(4U, mip_or_dummy(4)) &&
    builder.add_texture_view(5U, mip_or_dummy(5)) &&
    builder.add_texture_view(6U, mip_or_dummy(6)) &&
    builder.add_texture_view(7U, mip_or_dummy(7)) &&
    builder.add_texture_view(8U, mip_or_dummy(8)) &&
    builder.add_texture_view(9U, mip_or_dummy(9)) &&
    builder.add_texture_view(10U, mip_or_dummy(10)) &&
    builder.add_texture_view(11U, mip_or_dummy(11)) &&
    builder.add_texture_view(12U, mip_or_dummy(12)) &&
    builder.add_sampler(13U, sampler)
  if !ok {
    builder.free()
    return
  }
  let bind_group = builder.finish(
    self.device,
    downsample_bgl,
    label="mgstudio_mesh3d_preprocess_downsample_depth_bg",
  )
  let dispatch_x = (
      mesh3d_preprocess_depth_pyramid_dispatch_size(state.depth_pyramid_width) +
      63U
    ) /
    64U
  let dispatch_y = (
      mesh3d_preprocess_depth_pyramid_dispatch_size(state.depth_pyramid_height) +
      63U
    ) /
    64U
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_bind_group0(bind_group)
  compute_pass.set_pipeline(first_pipeline)
  compute_pass.dispatch_workgroups(dispatch_x, dispatch_y, 1U)
  if state.depth_pyramid_mip_count >= 7 {
    compute_pass.set_pipeline(second_pipeline)
    compute_pass.dispatch_workgroups(1U, 1U, 1U)
  }
  compute_pass.end()
  compute_pass.release()
  bind_group.release()
}

///|
fn mesh3d_preprocess_camera_upload_state(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> GpuMesh3dPreprocessCameraUploadState? {
  guard mesh3d_preprocess_camera_upload_state_index(backend, key_hi, key_lo)
    is Some(state_index) else {
    return None
  }
  Some(backend.mesh3d_preprocess_camera_upload_states[state_index])
}

///|
fn mesh3d_preprocess_motion_vector_mesh_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].motion_vector_mesh_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_motion_vector_bgl_mesh is Some(mesh_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  let output_count = backend.mesh3d_preprocess_camera_upload_states[state_index].output_count
  if output_count <= 0 {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      output_buffer,
      size=output_count.to_uint64() * MESH3D_PREPASS_MESH_BUFFER_SIZE,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    mesh_bgl,
    label="mgstudio_motion_vector_preprocess_mesh_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].motion_vector_mesh_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_direct_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_direct_bgl is Some(preprocess_direct_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer
    is Some(direct_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let direct_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    direct_work_item_capacity == 0UL ||
    output_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      direct_work_item_buffer,
      size=direct_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_direct_bgl,
    label="mgstudio_mesh3d_preprocess_direct_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_bgl is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
    is Some(indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      indexed_work_item_buffer,
      size=indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_bgl is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
    is Some(non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      non_indexed_work_item_buffer,
      size=non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_early_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_early_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
    is Some(indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is Some(late_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
    is Some(late_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let late_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL ||
    late_indexed_work_item_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      indexed_work_item_buffer,
      size=indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      11U,
      late_indexed_work_item_buffer,
      size=late_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(
      12U,
      late_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_early_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_late_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_late_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is Some(late_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
    is Some(late_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let late_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    late_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      late_indexed_work_item_buffer,
      size=late_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      12U,
      late_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_late_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_early_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_early_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
    is Some(non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is Some(late_non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
    is Some(late_non_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let late_non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL ||
    late_non_indexed_work_item_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      non_indexed_work_item_buffer,
      size=non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      11U,
      late_non_indexed_work_item_buffer,
      size=late_non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(
      12U,
      late_non_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_early_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_late_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_late_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is Some(late_non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
    is Some(late_non_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let late_non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    late_non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      late_non_indexed_work_item_buffer,
      size=late_non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      12U,
      late_non_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_late_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_reset_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_reset_batch_sets_bgl is Some(reset_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
    is Some(indexed_batch_set_buffer) else {
    return None
  }
  let indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  if indexed_batch_set_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      indexed_batch_set_buffer,
      size=indexed_batch_set_capacity,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    reset_bgl,
    label="mgstudio_mesh3d_preprocess_reset_indexed_batch_sets_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_reset_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_reset_batch_sets_bgl is Some(reset_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
    is Some(non_indexed_batch_set_buffer) else {
    return None
  }
  let non_indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  if non_indexed_batch_set_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      non_indexed_batch_set_buffer,
      size=non_indexed_batch_set_capacity,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    reset_bgl,
    label="mgstudio_mesh3d_preprocess_reset_non_indexed_batch_sets_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_build_indexed_indirect_bgl
    is Some(indexed_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
    is Some(indexed_batch_set_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer
    is Some(indexed_indirect_parameters_buffer) else {
    return None
  }
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  let indexed_indirect_parameters_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  if mesh_input_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    indexed_batch_set_capacity == 0UL ||
    indexed_indirect_parameters_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(0U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      1U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      2U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      3U,
      indexed_batch_set_buffer,
      size=indexed_batch_set_capacity,
    ) &&
    builder.add_buffer(
      4U,
      indexed_indirect_parameters_buffer,
      size=indexed_indirect_parameters_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    indexed_bgl,
    label="mgstudio_mesh3d_preprocess_build_indexed_indirect_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_build_non_indexed_indirect_bgl
    is Some(non_indexed_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
    is Some(non_indexed_batch_set_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer
    is Some(non_indexed_indirect_parameters_buffer) else {
    return None
  }
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let non_indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  let non_indexed_indirect_parameters_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  if mesh_input_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    non_indexed_batch_set_capacity == 0UL ||
    non_indexed_indirect_parameters_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(0U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      1U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      2U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      3U,
      non_indexed_batch_set_buffer,
      size=non_indexed_batch_set_capacity,
    ) &&
    builder.add_buffer(
      4U,
      non_indexed_indirect_parameters_buffer,
      size=non_indexed_indirect_parameters_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    non_indexed_bgl,
    label="mgstudio_mesh3d_preprocess_build_non_indexed_indirect_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_indexed_indirect_offset(indirect_parameters_index : Int) -> UInt64 {
  indirect_parameters_index.to_uint64() *
  MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
}

///|
fn mesh3d_non_indexed_indirect_offset(
  indirect_parameters_index : Int,
) -> UInt64 {
  indirect_parameters_index.to_uint64() *
  MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
}

///|
