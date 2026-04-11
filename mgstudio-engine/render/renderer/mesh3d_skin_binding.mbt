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
