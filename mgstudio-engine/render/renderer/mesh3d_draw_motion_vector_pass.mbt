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
  transparent : Bool,
) -> Unit raise GpuBackendError {
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
    guard ensure_mesh3d_motion_vector_instance_mesh_binding(self, required_size)
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
}
