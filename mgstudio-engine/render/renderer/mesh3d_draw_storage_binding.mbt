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
pub fn GpuBackend::ensure_mesh3d_draw_slot(
  self : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard self.mesh3d_bgl_draw is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while self.mesh3d_draw_slots.length() <= slot_index {
    let draw_buf = self.device.create_buffer(
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      usage~,
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      draw_buf,
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    )
    if !ok {
      builder.free()
      return None
    }
    let draw_bg = builder.finish(
      self.device,
      bgl,
      label="mgstudio_mesh3d_draw_slot_bg",
    )
    self.mesh3d_draw_slots.push(GpuStorageSlot::{
      buffer: draw_buf,
      bind_group: draw_bg,
    })
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
    self.mesh3d_instance_draw_capacity >= required_size {
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
  let draw_buf = self.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, draw_buf, size=next_capacity)
  if !ok {
    builder.free()
    return None
  }
  let draw_bg = builder.finish(
    self.device,
    bgl,
    label="mgstudio_mesh3d_instance_draw_bg",
  )
  // Keep old buffer/bind group alive: commands recorded earlier in this frame
  // may still reference them when capacity grows mid-frame.
  self.mesh3d_instance_draw_buf = Some(draw_buf)
  self.mesh3d_instance_draw_bg = Some(draw_bg)
  self.mesh3d_instance_draw_capacity = next_capacity
  Some((draw_buf, draw_bg))
}
