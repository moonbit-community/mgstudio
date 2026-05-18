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
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
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
pub fn GpuBackend::create_mesh3d_morph_target_texture(
  self : GpuBackend,
  width : Int,
  height : Int,
  depth : Int,
  components : Array[Float],
) -> Int raise GpuBackendError {
  self.create_texture_3d_with_format(
    width,
    height,
    depth,
    @wgpu.TEXTURE_FORMAT_R32_FLOAT,
    [mesh3d_morph_bytes(components)],
  )
}
