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
fn mesh3d_lightmap_texture_id_at(
  lightmap_texture_id : Int,
  lightmap_slab_texture_ids : Array[Int],
  index : Int,
) -> Int {
  if index >= 0 &&
    index < lightmap_slab_texture_ids.length() &&
    lightmap_slab_texture_ids[index] >= 0 {
    lightmap_slab_texture_ids[index]
  } else if index == 0 {
    lightmap_texture_id
  } else {
    -1
  }
}

///|
fn mesh3d_lightmap_texture_views(
  backend : GpuBackend,
  lightmap_texture_id : Int,
  lightmap_slab_texture_ids : Array[Int],
  entry : @render_resource.BindGroupLayoutEntry,
) -> Array[@wgpu.TextureView] {
  let views : Array[@wgpu.TextureView] = []
  let count = mesh3d_layout_binding_count(entry)
  for index in 0..<count {
    let texture_id = mesh3d_lightmap_texture_id_at(
      lightmap_texture_id, lightmap_slab_texture_ids, index,
    )
    match (resolve_mesh3d_texture(backend, texture_id) catch { _ => None }) {
      Some(texture) => views.push(texture.view)
      None => ()
    }
  }
  views
}

///|
fn mesh3d_lightmap_samplers(
  backend : GpuBackend,
  lightmap_texture_id : Int,
  lightmap_slab_texture_ids : Array[Int],
  entry : @render_resource.BindGroupLayoutEntry,
) -> Array[@wgpu.Sampler] {
  let samplers : Array[@wgpu.Sampler] = []
  let count = mesh3d_layout_binding_count(entry)
  for index in 0..<count {
    let texture_id = mesh3d_lightmap_texture_id_at(
      lightmap_texture_id, lightmap_slab_texture_ids, index,
    )
    match (resolve_mesh3d_texture(backend, texture_id) catch { _ => None }) {
      Some(texture) => samplers.push(texture.sampler)
      None => ()
    }
  }
  samplers
}

///|
fn mesh3d_add_samplers_for_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  binding : UInt,
  samplers : Array[@wgpu.Sampler],
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  if samplers.length() == 0 {
    return false
  }
  if entry.count() > 1 {
    let sampler_array : Array[@wgpu.Sampler] = []
    for i in 0..<entry.count() {
      if i < samplers.length() {
        sampler_array.push(samplers[i])
      } else {
        sampler_array.push(samplers[samplers.length() - 1])
      }
    }
    builder.add_sampler_array(binding, sampler_array)
  } else {
    builder.add_sampler(binding, samplers[0])
  }
}

///|
fn GpuBackend::create_mesh3d_draw_bind_group(
  self : GpuBackend,
  bgl : @wgpu.BindGroupLayout,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  draw_buf : @wgpu.Buffer,
  draw_size : UInt64,
  lightmap_texture_id : Int,
  lightmap_slab_texture_ids : Array[Int],
  morph_target_texture_id : Int,
  morph_descriptor_index : UInt,
  current_morph_weights_byte_offset : Int,
  previous_morph_weights_byte_offset : Int,
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
      2 => {
        guard ensure_mesh3d_morph_buffers(
          self,
          MESH3D_MORPH_WEIGHT_STRIDE_BYTES,
        ) else {
          false
        }
        guard self.mesh3d_morph_current_buf is Some(current_morph_buf) else {
          false
        }
        builder.add_buffer(
          2U,
          current_morph_buf,
          size=self.mesh3d_morph_capacity,
        )
      }
      3 => {
        guard find_mesh3d_morph_target_buffer(self, morph_target_texture_id)
          is Some(morph_target_buffer) else {
          false
        }
        builder.add_buffer(
          3U,
          morph_target_buffer.buffer,
          size=morph_target_buffer.byte_size,
        )
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
      7 => {
        guard ensure_mesh3d_morph_buffers(
          self,
          MESH3D_MORPH_WEIGHT_STRIDE_BYTES,
        ) else {
          false
        }
        guard self.mesh3d_morph_prev_buf is Some(prev_morph_buf) else { false }
        builder.add_buffer(7U, prev_morph_buf, size=self.mesh3d_morph_capacity)
      }
      8 => {
        guard self.write_mesh3d_morph_descriptor(
          morph_descriptor_index, current_morph_weights_byte_offset, previous_morph_weights_byte_offset,
          morph_target_texture_id,
        ) else {
          false
        }
        guard self.mesh3d_morph_descriptor_buf is Some(descriptor_buf) else {
          false
        }
        builder.add_buffer(
          8U,
          descriptor_buf,
          size=self.mesh3d_morph_descriptor_capacity,
        )
      }
      4 => {
        guard lightmap_texture_id >= 0 else { false }
        mesh3d_add_texture_views_for_layout_entry(
          builder,
          4U,
          mesh3d_lightmap_texture_views(
            self, lightmap_texture_id, lightmap_slab_texture_ids, entry,
          ),
          entry,
        )
      }
      5 => {
        guard lightmap_texture_id >= 0 else { false }
        mesh3d_add_samplers_for_layout_entry(
          builder,
          5U,
          mesh3d_lightmap_samplers(
            self, lightmap_texture_id, lightmap_slab_texture_ids, entry,
          ),
          entry,
        )
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
fn mesh3d_draw_layout_has_binding(
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  binding : Int,
) -> Bool {
  for entry in layout_descriptor.entries() {
    if entry.binding() == binding {
      return true
    }
  }
  false
}

///|
fn mesh3d_draw_layout_morph_revision(
  backend : GpuBackend,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
) -> Int {
  if mesh3d_draw_layout_has_binding(layout_descriptor, 2) ||
    mesh3d_draw_layout_has_binding(layout_descriptor, 7) ||
    mesh3d_draw_layout_has_binding(layout_descriptor, 8) {
    backend.mesh3d_morph_revision
  } else {
    -1
  }
}

///|
fn mesh3d_draw_layout_morph_target_texture_id(
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  morph_target_texture_id : Int,
) -> Int {
  if mesh3d_draw_layout_has_binding(layout_descriptor, 3) {
    morph_target_texture_id
  } else {
    -1
  }
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
  lightmap_texture_id : Int,
  lightmap_slab_index : Int,
  lightmap_slab_texture_ids : Array[Int],
  morph_target_texture_id : Int,
  morph_descriptor_index : UInt,
  current_morph_weights_byte_offset : Int,
  previous_morph_weights_byte_offset : Int,
) -> GpuStorageSlot? {
  let morph_revision = mesh3d_draw_layout_morph_revision(
    self, layout_descriptor,
  )
  let resolved_morph_target_texture_id = mesh3d_draw_layout_morph_target_texture_id(
    layout_descriptor, morph_target_texture_id,
  )
  if slot_index < self.mesh3d_draw_slots.length() &&
    slot_index < self.mesh3d_draw_slot_skin_revisions.length() &&
    slot_index < self.mesh3d_draw_slot_morph_revisions.length() &&
    slot_index < self.mesh3d_draw_slot_material_pipeline_ids.length() &&
    slot_index < self.mesh3d_draw_slot_lightmap_slab_indices.length() &&
    slot_index < self.mesh3d_draw_slot_morph_target_texture_ids.length() &&
    self.mesh3d_draw_slot_skin_revisions[slot_index] ==
    self.mesh3d_skin_revision &&
    self.mesh3d_draw_slot_morph_revisions[slot_index] == morph_revision &&
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] ==
    material_pipeline_id &&
    self.mesh3d_draw_slot_lightmap_slab_indices[slot_index] ==
    lightmap_slab_index &&
    self.mesh3d_draw_slot_morph_target_texture_ids[slot_index] ==
    resolved_morph_target_texture_id {
    if mesh3d_draw_layout_has_binding(layout_descriptor, 8) {
      guard self.write_mesh3d_morph_descriptor(
        morph_descriptor_index, current_morph_weights_byte_offset, previous_morph_weights_byte_offset,
        morph_target_texture_id,
      ) else {
        return None
      }
    }
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
        lightmap_texture_id,
        lightmap_slab_texture_ids,
        morph_target_texture_id,
        morph_descriptor_index,
        current_morph_weights_byte_offset,
        previous_morph_weights_byte_offset,
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
    self.mesh3d_draw_slot_morph_revisions.push(morph_revision)
    self.mesh3d_draw_slot_material_pipeline_ids.push(material_pipeline_id)
    self.mesh3d_draw_slot_lightmap_slab_indices.push(lightmap_slab_index)
    self.mesh3d_draw_slot_morph_target_texture_ids.push(
      resolved_morph_target_texture_id,
    )
  }
  if self.mesh3d_draw_slot_skin_revisions[slot_index] !=
    self.mesh3d_skin_revision ||
    self.mesh3d_draw_slot_morph_revisions[slot_index] != morph_revision ||
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] !=
    material_pipeline_id ||
    self.mesh3d_draw_slot_lightmap_slab_indices[slot_index] !=
    lightmap_slab_index ||
    self.mesh3d_draw_slot_morph_target_texture_ids[slot_index] !=
    resolved_morph_target_texture_id {
    let slot = self.mesh3d_draw_slots[slot_index]
    guard self.create_mesh3d_draw_bind_group(
        bgl,
        layout_descriptor,
        slot.buffer,
        MESH3D_DRAW_STORAGE_STRIDE_BYTES,
        lightmap_texture_id,
        lightmap_slab_texture_ids,
        morph_target_texture_id,
        morph_descriptor_index,
        current_morph_weights_byte_offset,
        previous_morph_weights_byte_offset,
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
    self.mesh3d_draw_slot_morph_revisions[slot_index] = morph_revision
    self.mesh3d_draw_slot_material_pipeline_ids[slot_index] = material_pipeline_id
    self.mesh3d_draw_slot_lightmap_slab_indices[slot_index] = lightmap_slab_index
    self.mesh3d_draw_slot_morph_target_texture_ids[slot_index] = resolved_morph_target_texture_id
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
    -1,
    -1,
    [],
    -1,
    0U,
    -1,
    -1,
  )
}

///|
fn GpuBackend::ensure_mesh3d_instance_draw_binding_with_layout(
  self : GpuBackend,
  material_pipeline_id : UInt64,
  bgl : @wgpu.BindGroupLayout,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  required_size : UInt64,
  lightmap_texture_id : Int,
  lightmap_slab_index : Int,
  lightmap_slab_texture_ids : Array[Int],
  morph_target_texture_id : Int,
  morph_descriptor_index : UInt,
  current_morph_weights_byte_offset : Int,
  previous_morph_weights_byte_offset : Int,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  let morph_revision = mesh3d_draw_layout_morph_revision(
    self, layout_descriptor,
  )
  let resolved_morph_target_texture_id = mesh3d_draw_layout_morph_target_texture_id(
    layout_descriptor, morph_target_texture_id,
  )
  if self.mesh3d_instance_draw_buf is Some(draw_buf) &&
    self.mesh3d_instance_draw_bg is Some(draw_bg) &&
    self.mesh3d_instance_draw_capacity >= required_size &&
    self.mesh3d_instance_draw_skin_revision == self.mesh3d_skin_revision &&
    self.mesh3d_instance_draw_morph_revision == morph_revision &&
    self.mesh3d_instance_draw_material_pipeline_id == material_pipeline_id &&
    self.mesh3d_instance_draw_lightmap_slab_index == lightmap_slab_index &&
    self.mesh3d_instance_draw_morph_target_texture_id ==
    resolved_morph_target_texture_id {
    if mesh3d_draw_layout_has_binding(layout_descriptor, 8) {
      guard self.write_mesh3d_morph_descriptor(
        morph_descriptor_index, current_morph_weights_byte_offset, previous_morph_weights_byte_offset,
        morph_target_texture_id,
      ) else {
        return None
      }
    }
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
      bgl, layout_descriptor, draw_buf, next_capacity, lightmap_texture_id, lightmap_slab_texture_ids,
      morph_target_texture_id, morph_descriptor_index, current_morph_weights_byte_offset,
      previous_morph_weights_byte_offset, "mgstudio_mesh3d_instance_draw_bg",
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
  self.mesh3d_instance_draw_morph_revision = morph_revision
  self.mesh3d_instance_draw_material_pipeline_id = material_pipeline_id
  self.mesh3d_instance_draw_lightmap_slab_index = lightmap_slab_index
  self.mesh3d_instance_draw_morph_target_texture_id = resolved_morph_target_texture_id
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
    -1,
    -1,
    [],
    -1,
    0U,
    -1,
    -1,
  )
}

///|
fn GpuBackend::clear_mesh3d_preprocess_phase_draw_bind_groups(
  self : GpuBackend,
  state_index : Int,
) -> Unit {
  for
    entry in self.mesh3d_preprocess_camera_upload_states[state_index].phase_draw_bind_groups {
    self.retire_mesh3d_draw_bind_group(entry.bind_group)
  }
  self.mesh3d_preprocess_camera_upload_states[state_index].phase_draw_bind_groups.clear()
}

///|
// Bevy source: `bevy_pbr/src/render/mesh.rs::prepare_mesh_bind_groups` creates
// a distinct `MeshPhaseBindGroups` entry for every render phase output buffer.
fn GpuBackend::mesh3d_preprocess_phase_draw_bind_group_get_or_create(
  self : GpuBackend,
  state_index : Int,
  material_pipeline_id : UInt64,
  bgl : @wgpu.BindGroupLayout,
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  lightmap_texture_id : Int,
  lightmap_slab_index : Int,
  lightmap_slab_texture_ids : Array[Int],
  morph_target_texture_id : Int,
  morph_descriptor_index : UInt,
  current_morph_weights_byte_offset : Int,
  previous_morph_weights_byte_offset : Int,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard self.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  let output_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  if output_capacity == 0UL {
    return None
  }
  let morph_revision = mesh3d_draw_layout_morph_revision(
    self, layout_descriptor,
  )
  let resolved_morph_target_texture_id = mesh3d_draw_layout_morph_target_texture_id(
    layout_descriptor, morph_target_texture_id,
  )
  for
    entry in self.mesh3d_preprocess_camera_upload_states[state_index].phase_draw_bind_groups {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.skin_revision == self.mesh3d_skin_revision &&
      entry.morph_revision == morph_revision &&
      entry.lightmap_slab_index == lightmap_slab_index &&
      entry.morph_target_texture_id == resolved_morph_target_texture_id {
      if mesh3d_draw_layout_has_binding(layout_descriptor, 8) {
        guard self.write_mesh3d_morph_descriptor(
          morph_descriptor_index, current_morph_weights_byte_offset, previous_morph_weights_byte_offset,
          morph_target_texture_id,
        ) else {
          return None
        }
      }
      return Some((output_buffer, entry.bind_group))
    }
  }
  guard self.create_mesh3d_draw_bind_group(
      bgl, layout_descriptor, output_buffer, output_capacity, lightmap_texture_id,
      lightmap_slab_texture_ids, morph_target_texture_id, morph_descriptor_index,
      current_morph_weights_byte_offset, previous_morph_weights_byte_offset, "mgstudio_mesh3d_preprocess_phase_draw_bg",
    )
    is Some(bind_group) else {
    return None
  }
  self.mesh3d_preprocess_camera_upload_states[state_index].phase_draw_bind_groups.push(GpuMesh3dPhaseDrawBindGroupEntry::{
      material_pipeline_id,
      skin_revision: self.mesh3d_skin_revision,
      morph_revision,
      lightmap_slab_index,
      morph_target_texture_id: resolved_morph_target_texture_id,
      bind_group,
    },
  )
  Some((output_buffer, bind_group))
}

///|
fn mesh3d_draw_bind_group_dynamic_offsets(
  layout_descriptor : @render_resource.BindGroupLayoutDescriptor,
  current_morph_weights_index : Int,
  previous_morph_weights_index : Int,
) -> Array[UInt] {
  let offsets : Array[UInt] = []
  for entry in layout_descriptor.entries() {
    match entry.kind() {
      BufferBinding(_, has_dynamic_offset, _) =>
        if has_dynamic_offset {
          match entry.binding() {
            2 =>
              offsets.push(
                if current_morph_weights_index >= 0 {
                  current_morph_weights_index.reinterpret_as_uint()
                } else {
                  0U
                },
              )
            7 =>
              offsets.push(
                if previous_morph_weights_index >= 0 {
                  previous_morph_weights_index.reinterpret_as_uint()
                } else {
                  0U
                },
              )
            _ => offsets.push(0U)
          }
        }
      _ => ()
    }
  }
  offsets
}
