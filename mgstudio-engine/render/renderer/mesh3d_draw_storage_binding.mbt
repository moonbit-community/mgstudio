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
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  draw_buf : @wgpu.Buffer,
  draw_size : UInt64,
  label : String,
) -> @wgpu.BindGroup? {
  let entries = layout_descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=entries.length().to_uint64(),
  )
  for entry in entries {
    let ok = match entry.binding() {
      0 => builder.add_buffer(0U, draw_buf, size=draw_size)
      1 => {
        guard ensure_mesh3d_skin_buffers(
          self,
          MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
        ) else {
          false
        }
        guard self.mesh3d_skin_current_buf is Some(current_skin_buf) else {
          false
        }
        builder.add_buffer(1U, current_skin_buf, size=self.mesh3d_skin_capacity)
      }
      6 => {
        guard ensure_mesh3d_skin_buffers(
          self,
          MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
        ) else {
          false
        }
        guard self.mesh3d_skin_prev_buf is Some(prev_skin_buf) else { false }
        builder.add_buffer(6U, prev_skin_buf, size=self.mesh3d_skin_capacity)
      }
      _ => false
    }
    if !ok {
      builder.free()
      return None
    }
  }
  Some(builder.finish(self.device, bgl, label~))
}

///|
fn GpuBackend::retire_mesh3d_draw_bind_group(
  self : GpuBackend,
  bind_group : @wgpu.BindGroup,
) -> Unit {
  if self.frame is Some(frame) {
    frame.transient_bind_groups.push(bind_group)
  } else {
    bind_group.release()
  }
}

///|
fn GpuBackend::ensure_mesh3d_draw_slot_with_layout(
  self : GpuBackend,
  slot_index : Int,
  material_pipeline_id : UInt64,
  bgl : @wgpu.BindGroupLayout,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
) -> GpuStorageSlot? {
  if slot_index < self.mesh3d_draw_slots.length() &&
    slot_index < self.mesh3d_draw_slot_skin_revisions.length() &&
    slot_index < self.mesh3d_draw_slot_material_pipeline_ids.length() &&
    self.mesh3d_draw_slot_skin_revisions[slot_index] ==
    self.mesh3d_skin_revision &&
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] ==
    material_pipeline_id {
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
        layout_descriptor,
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
    self.mesh3d_draw_slot_material_pipeline_ids.push(material_pipeline_id)
  }
  if self.mesh3d_draw_slot_skin_revisions[slot_index] !=
    self.mesh3d_skin_revision ||
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] !=
    material_pipeline_id {
    let slot = self.mesh3d_draw_slots[slot_index]
    guard self.create_mesh3d_draw_bind_group(
        bgl,
        layout_descriptor,
        slot.buffer,
        MESH3D_DRAW_STORAGE_STRIDE_BYTES,
        "mgstudio_mesh3d_draw_slot_bg",
      )
      is Some(draw_bg) else {
      return None
    }
    self.retire_mesh3d_draw_bind_group(slot.bind_group)
    self.mesh3d_draw_slots[slot_index] = GpuStorageSlot::{
      buffer: slot.buffer,
      bind_group: draw_bg,
    }
    self.mesh3d_draw_slot_skin_revisions[slot_index] = self.mesh3d_skin_revision
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] = material_pipeline_id
  }
  Some(self.mesh3d_draw_slots[slot_index])
}

///|
pub fn GpuBackend::ensure_mesh3d_draw_slot(
  self : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard self.mesh3d_bgl_draw is Some(bgl) else { return None }
  self.ensure_mesh3d_draw_slot_with_layout(
    slot_index,
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    bgl,
    mesh3d_default_draw_bind_group_layout_descriptor(),
  )
}

///|
fn GpuBackend::ensure_mesh3d_instance_draw_binding_with_layout(
  self : GpuBackend,
  material_pipeline_id : UInt64,
  bgl : @wgpu.BindGroupLayout,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  if self.mesh3d_instance_draw_buf is Some(draw_buf) &&
    self.mesh3d_instance_draw_bg is Some(draw_bg) &&
    self.mesh3d_instance_draw_capacity >= required_size &&
    self.mesh3d_instance_draw_skin_revision == self.mesh3d_skin_revision &&
    self.mesh3d_instance_draw_material_pipeline_id == material_pipeline_id {
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
      bgl, layout_descriptor, draw_buf, next_capacity, "mgstudio_mesh3d_instance_draw_bg",
    )
    is Some(draw_bg) else {
    return None
  }
  if self.mesh3d_instance_draw_bg is Some(old_bg) {
    self.retire_mesh3d_draw_bind_group(old_bg)
  }
  // Keep old buffer alive: commands recorded earlier in this frame may still
  // reference it when capacity grows mid-frame.
  self.mesh3d_instance_draw_buf = Some(draw_buf)
  self.mesh3d_instance_draw_bg = Some(draw_bg)
  self.mesh3d_instance_draw_capacity = next_capacity
  self.mesh3d_instance_draw_skin_revision = self.mesh3d_skin_revision
  self.mesh3d_instance_draw_material_pipeline_id = material_pipeline_id
  Some((draw_buf, draw_bg))
}

///|
pub fn GpuBackend::ensure_mesh3d_instance_draw_binding(
  self : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard self.mesh3d_bgl_draw is Some(bgl) else { return None }
  self.ensure_mesh3d_instance_draw_binding_with_layout(
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    bgl,
    mesh3d_default_draw_bind_group_layout_descriptor(),
    required_size,
  )
}
