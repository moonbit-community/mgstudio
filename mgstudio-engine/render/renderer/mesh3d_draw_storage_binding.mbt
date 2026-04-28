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
fn GpuBackend::create_mesh3d_draw_bind_group(
  self : GpuBackend,
  bgl : @wgpu.BindGroupLayout,
  draw_buf : @wgpu.Buffer,
  draw_size : UInt64,
  label : String,
) -> @wgpu.BindGroup? {
  guard ensure_mesh3d_skin_buffers(self, MESH3D_SKINNING_STORAGE_STRIDE_BYTES) else {
    return None
  }
  guard self.mesh3d_skin_current_buf is Some(current_skin_buf) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok = builder.add_buffer(0U, draw_buf, size=draw_size) &&
    builder.add_buffer(1U, current_skin_buf, size=self.mesh3d_skin_capacity)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(self.device, bgl, label~))
}

///|
pub fn GpuBackend::ensure_mesh3d_draw_slot(
  self : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard self.mesh3d_bgl_draw is Some(bgl) else { return None }
  if slot_index < self.mesh3d_draw_slots.length() &&
    slot_index < self.mesh3d_draw_slot_skin_revisions.length() &&
    self.mesh3d_draw_slot_skin_revisions[slot_index] ==
    self.mesh3d_skin_revision {
    return Some(self.mesh3d_draw_slots[slot_index])
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while self.mesh3d_draw_slots.length() <= slot_index {
    let draw_buf = self.device.create_buffer(
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      usage~,
    )
    guard self.create_mesh3d_draw_bind_group(
        bgl,
        draw_buf,
        MESH3D_DRAW_STORAGE_STRIDE_BYTES,
        "mgstudio_mesh3d_draw_slot_bg",
      )
      is Some(draw_bg) else {
      return None
    }
    self.mesh3d_draw_slots.push(GpuStorageSlot::{
      buffer: draw_buf,
      bind_group: draw_bg,
    })
    self.mesh3d_draw_slot_skin_revisions.push(self.mesh3d_skin_revision)
  }
  if self.mesh3d_draw_slot_skin_revisions[slot_index] !=
    self.mesh3d_skin_revision {
    let slot = self.mesh3d_draw_slots[slot_index]
    guard self.create_mesh3d_draw_bind_group(
        bgl,
        slot.buffer,
        MESH3D_DRAW_STORAGE_STRIDE_BYTES,
        "mgstudio_mesh3d_draw_slot_bg",
      )
      is Some(draw_bg) else {
      return None
    }
    self.mesh3d_draw_slots[slot_index] = GpuStorageSlot::{
      buffer: slot.buffer,
      bind_group: draw_bg,
    }
    self.mesh3d_draw_slot_skin_revisions[slot_index] = self.mesh3d_skin_revision
  }
  Some(self.mesh3d_draw_slots[slot_index])
}

///|
pub fn GpuBackend::ensure_mesh3d_instance_draw_binding(
  self : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard self.mesh3d_bgl_draw is Some(bgl) else { return None }
  if self.mesh3d_instance_draw_buf is Some(draw_buf) &&
    self.mesh3d_instance_draw_bg is Some(draw_bg) &&
    self.mesh3d_instance_draw_capacity >= required_size &&
    self.mesh3d_instance_draw_skin_revision == self.mesh3d_skin_revision {
    return Some((draw_buf, draw_bg))
  }
  let mut next_capacity = if self.mesh3d_instance_draw_capacity > 0UL {
    self.mesh3d_instance_draw_capacity
  } else {
    MESH3D_DRAW_STORAGE_STRIDE_BYTES * 16384UL
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let draw_buf = match self.mesh3d_instance_draw_buf {
    Some(existing) if self.mesh3d_instance_draw_capacity >= required_size =>
      existing
    _ => self.device.create_buffer(size=next_capacity, usage~)
  }
  guard self.create_mesh3d_draw_bind_group(
      bgl, draw_buf, next_capacity, "mgstudio_mesh3d_instance_draw_bg",
    )
    is Some(draw_bg) else {
    return None
  }
  // Keep old buffer/bind group alive: commands recorded earlier in this frame
  // may still reference them when capacity grows mid-frame.
  self.mesh3d_instance_draw_buf = Some(draw_buf)
  self.mesh3d_instance_draw_bg = Some(draw_bg)
  self.mesh3d_instance_draw_capacity = next_capacity
  self.mesh3d_instance_draw_skin_revision = self.mesh3d_skin_revision
  Some((draw_buf, draw_bg))
}
