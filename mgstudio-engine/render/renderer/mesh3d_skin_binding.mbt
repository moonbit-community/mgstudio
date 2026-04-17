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
fn mesh3d_skin_default_rows() -> Array[Float] {
  mesh3d_identity_rows((MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 64UL).to_int())
}

///|
fn mesh3d_skin_bytes(
  backend : GpuBackend,
  skinning_rows : Array[Float],
) -> Bytes {
  let byte_len = skinning_rows.length() * 4
  if backend.mesh3d_skin_staging_bytes.length() != byte_len {
    backend.mesh3d_skin_staging_bytes = bytes_fixed_staging_make(byte_len)
    backend.mesh3d_skin_staging_view = backend.mesh3d_skin_staging_bytes.unsafe_reinterpret_as_bytes()
  }
  f32le_pack_into_fixed(backend.mesh3d_skin_staging_bytes, 0, skinning_rows)
  backend.mesh3d_skin_staging_view
}

///|
fn create_mesh3d_skin_bind_group(
  backend : GpuBackend,
  bgl : @wgpu.BindGroupLayout,
  buffer : @wgpu.Buffer,
  size : UInt64,
  label : String,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, buffer, size~)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(backend.device, bgl, label~))
}

///|
fn ensure_mesh3d_skin_buffers(
  backend : GpuBackend,
  required_size : UInt64,
) -> Bool {
  guard backend.mesh3d_bgl_skin is Some(bgl) else { return false }
  if backend.mesh3d_skin_capacity >= required_size &&
    backend.mesh3d_skin_current_buf is Some(_) &&
    backend.mesh3d_skin_current_bg is Some(_) &&
    backend.mesh3d_skin_prev_buf is Some(_) &&
    backend.mesh3d_skin_prev_bg is Some(_) {
    return true
  }
  let mut next_capacity = if backend.mesh3d_skin_capacity >=
    MESH3D_SKINNING_STORAGE_STRIDE_BYTES {
    backend.mesh3d_skin_capacity
  } else {
    MESH3D_SKINNING_STORAGE_STRIDE_BYTES
  }
  while next_capacity < required_size {
    next_capacity = next_capacity + next_capacity / 2UL
    let remainder = next_capacity % MESH3D_SKINNING_STORAGE_STRIDE_BYTES
    if remainder != 0UL {
      next_capacity = next_capacity +
        (MESH3D_SKINNING_STORAGE_STRIDE_BYTES - remainder)
    }
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let current_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let prev_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let initial_rows = mesh3d_skin_default_rows()
  let initial_bytes = mesh3d_skin_bytes(backend, initial_rows)
  backend.queue.write_buffer(current_buf, 0UL, initial_bytes)
  backend.queue.write_buffer(prev_buf, 0UL, initial_bytes)
  guard create_mesh3d_skin_bind_group(
      backend, bgl, current_buf, next_capacity, "mgstudio_mesh3d_skin_current_bg",
    )
    is Some(current_bg) else {
    return false
  }
  guard create_mesh3d_skin_bind_group(
      backend, bgl, prev_buf, next_capacity, "mgstudio_mesh3d_skin_prev_bg",
    )
    is Some(prev_bg) else {
    return false
  }
  backend.mesh3d_skin_current_buf = Some(current_buf)
  backend.mesh3d_skin_current_bg = Some(current_bg)
  backend.mesh3d_skin_prev_buf = Some(prev_buf)
  backend.mesh3d_skin_prev_bg = Some(prev_bg)
  backend.mesh3d_skin_capacity = next_capacity
  backend.mesh3d_skin_revision = backend.mesh3d_skin_revision + 1
  true
}

///|
fn ensure_mesh3d_skin_current_binding(backend : GpuBackend) -> @wgpu.BindGroup? {
  ensure_mesh3d_skin_binding(backend, 0)
}

///|
fn ensure_mesh3d_skin_binding(
  backend : GpuBackend,
  skinning_key_lo : Int,
) -> @wgpu.BindGroup? {
  if !ensure_mesh3d_skin_buffers(backend, MESH3D_SKINNING_STORAGE_STRIDE_BYTES) {
    return None
  }
  if skinning_key_lo > 0 {
    backend.mesh3d_skin_prev_bg
  } else {
    backend.mesh3d_skin_current_bg
  }
}

///|
pub fn GpuBackend::prepare_mesh3d_skin_bindings(
  self : GpuBackend,
  skinning_rows : Array[Float],
) -> Unit {
  if skinning_rows.length() < 16 {
    return
  }
  let required_size = skinning_rows.length().to_uint64() * 4UL
  if !ensure_mesh3d_skin_buffers(
      self,
      if required_size < MESH3D_SKINNING_STORAGE_STRIDE_BYTES {
        MESH3D_SKINNING_STORAGE_STRIDE_BYTES
      } else {
        required_size
      },
    ) {
    return
  }
  guard self.mesh3d_skin_current_buf is Some(current_buf) else { return }
  guard self.mesh3d_skin_prev_buf is Some(prev_buf) else { return }
  self.mesh3d_skin_current_buf = Some(prev_buf)
  self.mesh3d_skin_prev_buf = Some(current_buf)
  let current_bg = self.mesh3d_skin_current_bg
  let prev_bg = self.mesh3d_skin_prev_bg
  self.mesh3d_skin_current_bg = prev_bg
  self.mesh3d_skin_prev_bg = current_bg
  guard self.mesh3d_skin_current_buf is Some(active_current_buf) else { return }
  self.queue.write_buffer(
    active_current_buf,
    0UL,
    mesh3d_skin_bytes(self, skinning_rows),
  )
  self.mesh3d_skin_revision = self.mesh3d_skin_revision + 1
}
