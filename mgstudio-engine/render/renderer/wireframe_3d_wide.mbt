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
// Bevy source: `bevy/crates/bevy_pbr/src/wireframe.rs::WireframeWideBindGroups`.
const WIREFRAME_3D_VERTEX_PULL_PARAMS_SIZE : UInt64 = 16UL

///|
pub(all) struct Wireframe3dWidePreparedBindGroup {
  mesh_id : Int
  bind_group : @wgpu.BindGroup
}

///|
fn wireframe_3d_align_up(value : UInt64, alignment : UInt64) -> UInt64 {
  if alignment == 0UL {
    value
  } else {
    (value + alignment - 1UL) / alignment * alignment
  }
}

///|
fn GpuBackend::prepare_wireframe_3d_wide_params(
  self : GpuBackend,
  params_words : Array[UInt],
) -> Bool {
  if params_words.length() % 3 != 0 {
    return false
  }
  let count = params_words.length() / 3
  if count == 0 {
    self.wireframe_3d_wide_params_count = 0
    return true
  }
  let alignment = self.device
    .limits_min_uniform_buffer_offset_alignment_u32()
    .to_uint64()
  let stride = wireframe_3d_align_up(
    WIREFRAME_3D_VERTEX_PULL_PARAMS_SIZE,
    alignment,
  )
  let required_size = stride * count.to_uint64()
  if self.wireframe_3d_wide_params_buf is None ||
    self.wireframe_3d_wide_params_capacity < required_size ||
    self.wireframe_3d_wide_params_stride != stride {
    let next_capacity = if required_size > stride {
      required_size
    } else {
      stride
    }
    let next_buffer = self.device.create_buffer(
      size=next_capacity,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    next_buffer.set_label("wireframe_3d_wide_params")
    match self.wireframe_3d_wide_params_buf {
      Some(old_buffer) => self.frame_retired_buffers.push(old_buffer)
      None => ()
    }
    self.wireframe_3d_wide_params_buf = Some(next_buffer)
    self.wireframe_3d_wide_params_capacity = next_capacity
    self.wireframe_3d_wide_params_stride = stride
  }
  let bytes = Array::make(required_size.to_int(), b'\x00')
  for index in 0..<count {
    let encoded = u32le_pack([
      params_words[index * 3],
      params_words[index * 3 + 1],
      params_words[index * 3 + 2],
      0U,
    ])
    let byte_offset = (index.to_uint64() * stride).to_int()
    for byte_index in 0..<encoded.length() {
      bytes[byte_offset + byte_index] = encoded[byte_index]
    }
  }
  guard self.wireframe_3d_wide_params_buf is Some(params_buffer) else {
    return false
  }
  self.queue.write_buffer(params_buffer, 0UL, Bytes::from_array(bytes))
  self.wireframe_3d_wide_params_count = count
  true
}

///|
fn GpuBackend::wireframe_3d_wide_bind_group_layout(
  self : GpuBackend,
) -> @wgpu.BindGroupLayout? {
  match self.wireframe_3d_wide_bgl {
    Some(layout) => Some(layout)
    None => {
      let vertex = ss(@wgpu.SHADER_STAGE_VERTEX)
      let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
      let ok = builder.add_buffer(
          0U,
          vertex,
          @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        ) &&
        builder.add_buffer(
          1U,
          vertex,
          @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        ) &&
        builder.add_buffer(
          2U,
          vertex,
          @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
          has_dynamic_offset=true,
          min_binding_size=WIREFRAME_3D_VERTEX_PULL_PARAMS_SIZE,
        )
      if !ok {
        builder.free()
        return None
      }
      let layout = builder.finish(
        self.device,
        label="wireframe_wide_bind_group_layout",
      )
      self.wireframe_3d_wide_bgl = Some(layout)
      Some(layout)
    }
  }
}

///|
fn GpuBackend::prepare_wireframe_3d_wide_bind_groups(
  self : GpuBackend,
  mesh_ids : Array[Int],
  params_words : Array[UInt],
) -> Bool {
  guard mesh_ids.length() == params_words.length() / 3 else { return false }
  guard self.prepare_wireframe_3d_wide_params(params_words) else {
    return false
  }
  for entry in self.wireframe_3d_wide_bind_groups {
    self.frame_retired_bind_groups.push(entry.bind_group)
  }
  self.wireframe_3d_wide_bind_groups.clear()
  if mesh_ids.length() == 0 {
    return true
  }
  guard self.wireframe_3d_wide_params_buf is Some(params_buffer) else {
    return false
  }
  guard self.wireframe_3d_wide_bind_group_layout() is Some(layout) else {
    return false
  }
  for mesh_id in mesh_ids {
    guard mesh_id >= 0 else { continue }
    guard find_mesh(self, mesh_id) is Some(mesh) else { continue }
    let storage_usage = @wgpu.BUFFER_USAGE_STORAGE
    if (mesh.vertex_buf.usage_u64().raw & storage_usage) == 0UL ||
      (mesh.index_buf.usage_u64().raw & storage_usage) == 0UL {
      return false
    }
    let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
    let ok = builder.add_buffer(0U, mesh.vertex_buf) &&
      builder.add_buffer(1U, mesh.index_buf) &&
      builder.add_buffer(
        2U,
        params_buffer,
        size=WIREFRAME_3D_VERTEX_PULL_PARAMS_SIZE,
      )
    if !ok {
      builder.free()
      return false
    }
    let bind_group = builder.finish(
      self.device,
      layout,
      label="wireframe_3d_wide_bind_group",
    )
    self.wireframe_3d_wide_bind_groups.push({ mesh_id, bind_group })
  }
  true
}

///|
pub fn prepare_wireframe_3d_wide_bind_groups(
  mesh_ids : Array[Int],
  params_words : Array[UInt],
) -> Bool {
  guard ensure_backend() is Some(backend) else { return false }
  backend.prepare_wireframe_3d_wide_bind_groups(mesh_ids, params_words)
}

///|
fn GpuBackend::wireframe_3d_wide_bind_group(
  self : GpuBackend,
  mesh : GpuMeshInfo,
) -> @wgpu.BindGroup? {
  for entry in self.wireframe_3d_wide_bind_groups {
    if entry.mesh_id == mesh.id {
      return Some(entry.bind_group)
    }
  }
  None
}

///|
fn GpuBackend::wireframe_3d_wide_dynamic_offset(
  self : GpuBackend,
  params_index : Int,
) -> UInt? {
  if params_index < 0 || params_index >= self.wireframe_3d_wide_params_count {
    return None
  }
  let offset = params_index.to_uint64() * self.wireframe_3d_wide_params_stride
  if offset > 0xffffffffUL {
    return None
  }
  Some(offset.to_uint())
}
