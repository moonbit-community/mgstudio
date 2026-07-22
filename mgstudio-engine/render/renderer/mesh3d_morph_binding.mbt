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
const MESH3D_MORPH_WEIGHT_STRIDE_BYTES : UInt64 = 256UL

///|
const MESH3D_MAX_MORPH_WEIGHT_FLOATS : Int = 64

///|
const MESH3D_MORPH_ATTRIBUTE_STRIDE_BYTES : UInt64 = 48UL

///|
const MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES : UInt64 = 20UL

///|
fn mesh3d_morph_default_weights() -> Array[Float] {
  let weights : Array[Float] = []
  for _ in 0..<MESH3D_MAX_MORPH_WEIGHT_FLOATS {
    weights.push(0.0F)
  }
  weights
}

///|
fn mesh3d_morph_bytes(weights : Array[Float]) -> Bytes {
  u32le_pack(weights.map(f32_bits))
}

///|
fn mesh3d_align_storage_size(size : UInt64) -> UInt64 {
  let remainder = size % 4UL
  if remainder == 0UL {
    size
  } else {
    size + (4UL - remainder)
  }
}

///|
fn mesh3d_morph_required_size(weights : Array[Float]) -> UInt64 {
  let raw_size = weights.length().to_uint64() * 4UL
  if raw_size < MESH3D_MORPH_WEIGHT_STRIDE_BYTES {
    return MESH3D_MORPH_WEIGHT_STRIDE_BYTES
  }
  let remainder = raw_size % MESH3D_MORPH_WEIGHT_STRIDE_BYTES
  if remainder == 0UL {
    raw_size
  } else {
    raw_size + (MESH3D_MORPH_WEIGHT_STRIDE_BYTES - remainder)
  }
}

///|
fn ensure_mesh3d_morph_buffers(
  backend : GpuBackend,
  required_size : UInt64,
) -> Bool {
  if backend.mesh3d_morph_capacity >= required_size &&
    backend.mesh3d_morph_current_buf is Some(_) &&
    backend.mesh3d_morph_prev_buf is Some(_) {
    return true
  }
  let mut next_capacity = if backend.mesh3d_morph_capacity >=
    MESH3D_MORPH_WEIGHT_STRIDE_BYTES {
    backend.mesh3d_morph_capacity
  } else {
    MESH3D_MORPH_WEIGHT_STRIDE_BYTES
  }
  while next_capacity < required_size {
    next_capacity = next_capacity + next_capacity / 2UL
    let remainder = next_capacity % MESH3D_MORPH_WEIGHT_STRIDE_BYTES
    if remainder != 0UL {
      next_capacity = next_capacity +
        (MESH3D_MORPH_WEIGHT_STRIDE_BYTES - remainder)
    }
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let current_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let prev_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let initial_bytes = mesh3d_morph_bytes(mesh3d_morph_default_weights())
  backend.queue.write_buffer(current_buf, 0UL, initial_bytes)
  backend.queue.write_buffer(prev_buf, 0UL, initial_bytes)
  backend.mesh3d_morph_current_buf = Some(current_buf)
  backend.mesh3d_morph_prev_buf = Some(prev_buf)
  backend.mesh3d_morph_capacity = next_capacity
  backend.mesh3d_morph_revision = backend.mesh3d_morph_revision + 1
  true
}

///|
pub fn GpuBackend::prepare_mesh3d_morph_bindings(
  self : GpuBackend,
  morph_weights : Array[Float],
) -> Unit {
  if morph_weights.length() == 0 {
    return
  }
  let required_size = mesh3d_morph_required_size(morph_weights)
  if !ensure_mesh3d_morph_buffers(self, required_size) {
    return
  }
  guard self.mesh3d_morph_current_buf is Some(current_buf) else { return }
  guard self.mesh3d_morph_prev_buf is Some(prev_buf) else { return }
  self.mesh3d_morph_current_buf = Some(prev_buf)
  self.mesh3d_morph_prev_buf = Some(current_buf)
  guard self.mesh3d_morph_current_buf is Some(active_current_buf) else {
    return
  }
  self.queue.write_buffer(
    active_current_buf,
    0UL,
    mesh3d_morph_bytes(morph_weights),
  )
  self.mesh3d_morph_revision = self.mesh3d_morph_revision + 1
}

///|
pub fn GpuBackend::create_mesh3d_morph_target_buffer(
  self : GpuBackend,
  width : Int,
  height : Int,
  depth : Int,
  components : Array[Float],
) -> Int {
  ignore(depth)
  if width <= 0 || height <= 0 || components.length() == 0 {
    return -1
  }
  let packed = mesh3d_morph_bytes(components)
  let byte_size = mesh3d_align_storage_size(packed.length().to_uint64())
  let buffer = self.device.create_buffer(
    size=byte_size,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  self.queue.write_buffer(buffer, 0UL, packed)
  let id = alloc_id(self)
  self.mesh3d_morph_target_buffers.push({
    id,
    buffer,
    byte_size,
    vertex_count: width,
    weight_count: height,
  })
  id
}

///|
fn find_mesh3d_morph_target_buffer(
  backend : GpuBackend,
  id : Int,
) -> GpuMesh3dMorphTargetBufferInfo? {
  for info in backend.mesh3d_morph_target_buffers {
    if info.id == id {
      return Some(info)
    }
  }
  None
}

///|
fn ensure_mesh3d_morph_descriptor_buffer(
  backend : GpuBackend,
  descriptor_index : UInt,
) -> @wgpu.Buffer? {
  let required_size = (descriptor_index.to_uint64() + 1UL) *
    MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES
  if backend.mesh3d_morph_descriptor_capacity >= required_size &&
    backend.mesh3d_morph_descriptor_buf is Some(buf) {
    return Some(buf)
  }
  let mut next_capacity = if backend.mesh3d_morph_descriptor_capacity >=
    MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES {
    backend.mesh3d_morph_descriptor_capacity
  } else {
    MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES
  }
  while next_capacity < required_size {
    next_capacity = next_capacity + next_capacity / 2UL
    let remainder = next_capacity % MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES
    if remainder != 0UL {
      next_capacity = next_capacity +
        (MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES - remainder)
    }
  }
  let buffer = backend.device.create_buffer(
    size=next_capacity,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  backend.mesh3d_morph_descriptor_buf = Some(buffer)
  backend.mesh3d_morph_descriptor_capacity = next_capacity
  backend.mesh3d_morph_revision = backend.mesh3d_morph_revision + 1
  Some(buffer)
}

///|
fn mesh3d_morph_descriptor_bytes(
  current_weights_offset : UInt,
  prev_weights_offset : UInt,
  targets_offset : UInt,
  vertex_count : UInt,
  weight_count : UInt,
) -> Bytes {
  u32le_pack([
    current_weights_offset, prev_weights_offset, targets_offset, vertex_count, weight_count,
  ])
}

///|
fn GpuBackend::write_mesh3d_morph_descriptor(
  self : GpuBackend,
  descriptor_index : UInt,
  current_morph_weights_byte_offset : Int,
  previous_morph_weights_byte_offset : Int,
  morph_target_buffer_id : Int,
) -> Bool {
  guard current_morph_weights_byte_offset >= 0 && morph_target_buffer_id >= 0 else {
    return false
  }
  guard find_mesh3d_morph_target_buffer(self, morph_target_buffer_id)
    is Some(targets) else {
    return false
  }
  guard ensure_mesh3d_morph_descriptor_buffer(self, descriptor_index)
    is Some(descriptor_buf) else {
    return false
  }
  let current_offset = (current_morph_weights_byte_offset / 4).reinterpret_as_uint()
  let previous_offset = if previous_morph_weights_byte_offset >= 0 {
    (previous_morph_weights_byte_offset / 4).reinterpret_as_uint()
  } else {
    0xFFFF_FFFFU
  }
  self.queue.write_buffer(
    descriptor_buf,
    descriptor_index.to_uint64() * MESH3D_MORPH_DESCRIPTOR_STRIDE_BYTES,
    mesh3d_morph_descriptor_bytes(
      current_offset,
      previous_offset,
      0U,
      targets.vertex_count.reinterpret_as_uint(),
      targets.weight_count.reinterpret_as_uint(),
    ),
  )
  true
}
