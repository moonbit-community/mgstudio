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
fn meshlet_buffer_size_for_bytes(bytes : Bytes) -> UInt64 {
  let byte_len = bytes.length()
  if byte_len <= 0 {
    4UL
  } else {
    byte_len.to_uint64()
  }
}

///|
fn meshlet_storage_buffer_update(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer, UInt64) {
  let required_size = meshlet_buffer_size_for_bytes(bytes)
  let (buffer, capacity) = match current_buffer {
    Some(existing) if current_capacity >= required_size =>
      (existing, current_capacity)
    Some(existing) => {
      existing.release()
      let next = backend.device.create_buffer(
        size=required_size,
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      )
      next.set_label(label)
      (next, required_size)
    }
    None => {
      let next = backend.device.create_buffer(
        size=required_size,
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      )
      next.set_label(label)
      (next, required_size)
    }
  }
  if bytes.length() > 0 {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  (buffer, capacity)
}

///|
fn meshlet_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
pub struct HostMeshletMaterialShadeDrawEntry {
  material_id : Int
  material_pipeline_id : UInt64
  draw_entry : HostMesh3dMainPassDrawEntry
}

///|
pub fn host_meshlet_material_shade_draw_entry(
  material_id~ : Int,
  material_pipeline_id~ : UInt64,
  draw_entry~ : HostMesh3dMainPassDrawEntry,
) -> HostMeshletMaterialShadeDrawEntry {
  HostMeshletMaterialShadeDrawEntry::{
    material_id,
    material_pipeline_id,
    draw_entry,
  }
}

///|
fn meshlet_reuse_or_create_buffer(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
) -> (@wgpu.Buffer, UInt64) {
  let safe_size = meshlet_non_zero_u64(required_size)
  match current_buffer {
    Some(existing) if current_capacity >= safe_size =>
      (existing, current_capacity)
    Some(existing) => {
      existing.release()
      let next = backend.device.create_buffer(
        size=safe_size,
        usage=bu(usage_bits),
      )
      next.set_label(label)
      (next, safe_size)
    }
    None => {
      let next = backend.device.create_buffer(
        size=safe_size,
        usage=bu(usage_bits),
      )
      next.set_label(label)
      (next, safe_size)
    }
  }
}

///|
fn meshlet_fixed_buffer_write(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
  bytes : Bytes,
) -> @wgpu.Buffer {
  let buffer = match current_buffer {
    Some(existing) => existing
    None => {
      let next = backend.device.create_buffer(
        size=meshlet_non_zero_u64(required_size),
        usage=bu(usage_bits),
      )
      next.set_label(label)
      next
    }
  }
  if bytes.length() > 0 {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  buffer
}

///|
fn meshlet_cull_queue_size(cluster_buffer_slots : Int) -> UInt64 {
  let slots = if cluster_buffer_slots <= 0 { 1 } else { cluster_buffer_slots }
  2UL * slots.to_uint64() * 4UL
}

///|
fn meshlet_second_pass_candidate_size(scene_instance_count : Int) -> UInt64 {
  let count = if scene_instance_count <= 0 { 1 } else { scene_instance_count }
  4UL * count.to_uint64()
}

///|
pub(all) struct MeshletViewVisibilityBuffer {
  buffer : @wgpu.Buffer
  capacity : UInt64
  view_width : Int
  view_height : Int
  not_shadow_view : Bool
  dummy_render_target_texture : @wgpu.Texture
  dummy_render_target_view : @wgpu.TextureView
  material_depth_texture : @wgpu.Texture?
  material_depth_view : @wgpu.TextureView?
  depth_pyramid_texture : @wgpu.Texture
  depth_pyramid_view : @wgpu.TextureView
  depth_pyramid_mip_views : Array[@wgpu.TextureView]
  depth_pyramid_mip_count : Int
  depth_pyramid_width : Int
  depth_pyramid_height : Int
  mut instance_visibility_buf : @wgpu.Buffer
  mut instance_visibility_capacity : UInt64
  second_pass_count_buf : @wgpu.Buffer
  second_pass_dispatch_buf : @wgpu.Buffer
  first_bvh_cull_count_front_buf : @wgpu.Buffer
  first_bvh_cull_dispatch_front_buf : @wgpu.Buffer
  first_bvh_cull_count_back_buf : @wgpu.Buffer
  first_bvh_cull_dispatch_back_buf : @wgpu.Buffer
  front_meshlet_cull_count_buf : @wgpu.Buffer
  front_meshlet_cull_dispatch_buf : @wgpu.Buffer
  back_meshlet_cull_count_buf : @wgpu.Buffer
  back_meshlet_cull_dispatch_buf : @wgpu.Buffer
  second_bvh_cull_count_front_buf : @wgpu.Buffer
  second_bvh_cull_dispatch_front_buf : @wgpu.Buffer
  second_bvh_cull_count_back_buf : @wgpu.Buffer
  second_bvh_cull_dispatch_back_buf : @wgpu.Buffer
  visibility_buffer_software_raster_indirect_args_buf : @wgpu.Buffer
  visibility_buffer_hardware_raster_indirect_args_buf : @wgpu.Buffer
}

///|
fn meshlet_visibility_buffer_pixel_count(
  view_width : Int,
  view_height : Int,
) -> UInt64 {
  let width = if view_width <= 0 { 1 } else { view_width }
  let height = if view_height <= 0 { 1 } else { view_height }
  width.to_uint64() * height.to_uint64()
}

///|
fn meshlet_visibility_buffer_size(
  view_width : Int,
  view_height : Int,
) -> UInt64 {
  meshlet_visibility_buffer_pixel_count(view_width, view_height) * 4UL
}

///|
fn meshlet_create_visibility_buffer(
  backend : GpuBackend,
  required_size : UInt64,
  label : String,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=meshlet_non_zero_u64(required_size),
    usage=bu(
      @wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_COPY_DST |
      @wgpu.BUFFER_USAGE_COPY_SRC,
    ),
  )
  buffer.set_label(label)
  buffer
}

///|
fn meshlet_create_dummy_render_target(
  backend : GpuBackend,
  view_width : Int,
  view_height : Int,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let width = if view_width <= 0 {
    1U
  } else {
    view_width.reinterpret_as_uint()
  }
  let height = if view_height <= 0 {
    1U
  } else {
    view_height.reinterpret_as_uint()
  }
  let texture = backend.device.create_texture_u32(
    width,
    height,
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_R8_UINT),
  )
  let view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_R8_UINT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  (texture, view)
}

///|
fn meshlet_create_material_depth_target(
  backend : GpuBackend,
  view_width : Int,
  view_height : Int,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let width = if view_width <= 0 {
    1U
  } else {
    view_width.reinterpret_as_uint()
  }
  let height = if view_height <= 0 {
    1U
  } else {
    view_height.reinterpret_as_uint()
  }
  let texture = backend.device.create_texture_u32(
    width,
    height,
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
  )
  let view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    1U,
    0U,
    1U,
  )
  (texture, view)
}

///|
fn meshlet_create_r32float_depth_pyramid_dummy(
  backend : GpuBackend,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_STORAGE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let texture = backend.device.create_texture_u32(
    1U,
    1U,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
  )
  let view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  let zero = f32le_pack([0.0F])
  let tex_info = @wgpu_c.texel_copy_texture_info_new(
    texture.raw_handle(),
    0U,
    0U,
    0U,
    0U,
  )
  let layout = @wgpu_c.texel_copy_buffer_layout_new(0UL, 4U, 1U)
  let extent = @wgpu_c.extent3d_new(1U, 1U, 1U)
  backend.queue.write_texture_ptr(tex_info, zero, layout, extent, data_size=4UL)
  @wgpu_c.extent3d_free(extent)
  @wgpu_c.texel_copy_buffer_layout_free(layout)
  @wgpu_c.texel_copy_texture_info_free(tex_info)
  (texture, view)
}

///|
fn meshlet_previous_power_of_two(value : Int) -> Int {
  let safe_value = if value <= 1 { 1 } else { value }
  let mut power = 1
  while power * 2 > 0 && power * 2 <= safe_value {
    power = power * 2
  }
  power
}

///|
fn meshlet_depth_pyramid_mip_count(width : Int, height : Int) -> Int {
  let mut max_dim = if width > height { width } else { height }
  if max_dim <= 0 {
    return 1
  }
  let mut mip_count = 0
  while max_dim > 0 && mip_count < 12 {
    mip_count = mip_count + 1
    max_dim = max_dim / 2
  }
  if mip_count <= 0 {
    1
  } else {
    mip_count
  }
}

///|
fn meshlet_depth_pyramid_dispatch_size(size : Int) -> UInt {
  let safe_value = if size <= 0 { 1 } else { size + 1 }
  let mut power = 1
  while power < safe_value {
    power = power * 2
  }
  power.reinterpret_as_uint()
}

///|
fn meshlet_create_depth_pyramid(
  backend : GpuBackend,
  view_width : Int,
  view_height : Int,
) -> (@wgpu.Texture, @wgpu.TextureView, Array[@wgpu.TextureView], Int, Int, Int) {
  let width = meshlet_previous_power_of_two(view_width)
  let height = meshlet_previous_power_of_two(view_height)
  let mip_count = meshlet_depth_pyramid_mip_count(width, height)
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
  )
  let texture = backend.device.create_texture_u32(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    mip_level_count=mip_count.reinterpret_as_uint(),
  )
  let all_mips_view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    mip_count.reinterpret_as_uint(),
  )
  let mip_views : Array[@wgpu.TextureView] = []
  for mip_level in 0..<mip_count {
    mip_views.push(
      texture.create_view_u32(
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        @wgpu.TEXTURE_ASPECT_ALL,
        0U,
        1U,
        mip_level.reinterpret_as_uint(),
        1U,
      ),
    )
  }
  (texture, all_mips_view, mip_views, mip_count, width, height)
}

///|
fn meshlet_create_storage_buffer_with_bytes(
  backend : GpuBackend,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
  bytes : Bytes,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=meshlet_non_zero_u64(required_size),
    usage=bu(usage_bits),
  )
  buffer.set_label(label)
  if bytes.length() > 0 {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  buffer
}

///|
fn meshlet_dispatch_indirect_initial_bytes() -> Bytes {
  u32le_pack([0U, 1U, 1U])
}

///|
fn meshlet_create_view_visibility_resources(
  backend : GpuBackend,
  required_size : UInt64,
  view_width : Int,
  view_height : Int,
  not_shadow_view : Bool,
  label : String,
) -> MeshletViewVisibilityBuffer {
  let (dummy_render_target_texture, dummy_render_target_view) = meshlet_create_dummy_render_target(
    backend, view_width, view_height,
  )
  let (material_depth_texture, material_depth_view) = if not_shadow_view {
    let (texture, view) = meshlet_create_material_depth_target(
      backend, view_width, view_height,
    )
    (Some(texture), Some(view))
  } else {
    (None, None)
  }
  let (
    depth_pyramid_texture,
    depth_pyramid_view,
    depth_pyramid_mip_views,
    depth_pyramid_mip_count,
    depth_pyramid_width,
    depth_pyramid_height,
  ) = meshlet_create_depth_pyramid(backend, view_width, view_height)
  let storage_copy = @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
  let storage_copy_indirect = storage_copy | @wgpu.BUFFER_USAGE_INDIRECT
  MeshletViewVisibilityBuffer::{
    buffer: meshlet_create_visibility_buffer(backend, required_size, label),
    capacity: required_size,
    view_width,
    view_height,
    not_shadow_view,
    dummy_render_target_texture,
    dummy_render_target_view,
    material_depth_texture,
    material_depth_view,
    depth_pyramid_texture,
    depth_pyramid_view,
    depth_pyramid_mip_views,
    depth_pyramid_mip_count,
    depth_pyramid_width,
    depth_pyramid_height,
    instance_visibility_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_view_instance_visibility",
      u32le_pack([0U]),
    ),
    instance_visibility_capacity: 4UL,
    second_pass_count_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_second_pass_count",
      u32le_pack([0U]),
    ),
    second_pass_dispatch_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_second_pass_dispatch",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    first_bvh_cull_count_front_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_first_bvh_cull_count_front",
      u32le_pack([0U]),
    ),
    first_bvh_cull_dispatch_front_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_first_bvh_cull_dispatch_front",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    first_bvh_cull_count_back_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_first_bvh_cull_count_back",
      u32le_pack([0U]),
    ),
    first_bvh_cull_dispatch_back_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_first_bvh_cull_dispatch_back",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    front_meshlet_cull_count_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_front_meshlet_cull_count",
      u32le_pack([0U]),
    ),
    front_meshlet_cull_dispatch_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_front_meshlet_cull_dispatch",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    back_meshlet_cull_count_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_back_meshlet_cull_count",
      u32le_pack([0U]),
    ),
    back_meshlet_cull_dispatch_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_back_meshlet_cull_dispatch",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    second_bvh_cull_count_front_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_second_bvh_cull_count_front",
      u32le_pack([0U]),
    ),
    second_bvh_cull_dispatch_front_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_second_bvh_cull_dispatch_front",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    second_bvh_cull_count_back_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      4UL,
      storage_copy,
      "mgstudio_meshlet_second_bvh_cull_count_back",
      u32le_pack([0U]),
    ),
    second_bvh_cull_dispatch_back_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_second_bvh_cull_dispatch_back",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    visibility_buffer_software_raster_indirect_args_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      12UL,
      storage_copy_indirect,
      "mgstudio_meshlet_visibility_buffer_software_raster_indirect_args",
      meshlet_dispatch_indirect_initial_bytes(),
    ),
    visibility_buffer_hardware_raster_indirect_args_buf: meshlet_create_storage_buffer_with_bytes(
      backend,
      16UL,
      storage_copy_indirect,
      "mgstudio_meshlet_visibility_buffer_hardware_raster_indirect_args",
      u32le_pack([384U, 0U, 0U, 0U]),
    ),
  }
}

///|
fn meshlet_release_view_visibility_resources(
  resources : MeshletViewVisibilityBuffer,
) -> Unit {
  resources.buffer.release()
  resources.dummy_render_target_view.release()
  resources.dummy_render_target_texture.release()
  match resources.material_depth_view {
    Some(view) => view.release()
    None => ()
  }
  match resources.material_depth_texture {
    Some(texture) => texture.release()
    None => ()
  }
  for view in resources.depth_pyramid_mip_views {
    view.release()
  }
  resources.depth_pyramid_view.release()
  resources.depth_pyramid_texture.release()
  resources.instance_visibility_buf.release()
  resources.second_pass_count_buf.release()
  resources.second_pass_dispatch_buf.release()
  resources.first_bvh_cull_count_front_buf.release()
  resources.first_bvh_cull_dispatch_front_buf.release()
  resources.first_bvh_cull_count_back_buf.release()
  resources.first_bvh_cull_dispatch_back_buf.release()
  resources.front_meshlet_cull_count_buf.release()
  resources.front_meshlet_cull_dispatch_buf.release()
  resources.back_meshlet_cull_count_buf.release()
  resources.back_meshlet_cull_dispatch_buf.release()
  resources.second_bvh_cull_count_front_buf.release()
  resources.second_bvh_cull_dispatch_front_buf.release()
  resources.second_bvh_cull_count_back_buf.release()
  resources.second_bvh_cull_dispatch_back_buf.release()
  resources.visibility_buffer_software_raster_indirect_args_buf.release()
  resources.visibility_buffer_hardware_raster_indirect_args_buf.release()
}

///|
pub fn GpuBackend::prepare_meshlet_view_visibility_buffer(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  view_width~ : Int,
  view_height~ : Int,
  not_shadow_view~ : Bool,
) -> Unit {
  let required_size = meshlet_visibility_buffer_size(view_width, view_height)
  let label = if not_shadow_view {
    "mgstudio_meshlet_visibility_buffer"
  } else {
    "mgstudio_meshlet_shadow_visibility_buffer"
  }
  let next = match self.meshlet_view_visibility_buffers.get(view_entity_bits) {
    Some(existing) if existing.capacity >= required_size &&
      existing.view_width == view_width &&
      existing.view_height == view_height &&
      existing.not_shadow_view == not_shadow_view =>
      MeshletViewVisibilityBuffer::{
        buffer: existing.buffer,
        capacity: existing.capacity,
        view_width,
        view_height,
        not_shadow_view,
        dummy_render_target_texture: existing.dummy_render_target_texture,
        dummy_render_target_view: existing.dummy_render_target_view,
        material_depth_texture: existing.material_depth_texture,
        material_depth_view: existing.material_depth_view,
        depth_pyramid_texture: existing.depth_pyramid_texture,
        depth_pyramid_view: existing.depth_pyramid_view,
        depth_pyramid_mip_views: existing.depth_pyramid_mip_views,
        depth_pyramid_mip_count: existing.depth_pyramid_mip_count,
        depth_pyramid_width: existing.depth_pyramid_width,
        depth_pyramid_height: existing.depth_pyramid_height,
        instance_visibility_buf: existing.instance_visibility_buf,
        instance_visibility_capacity: existing.instance_visibility_capacity,
        second_pass_count_buf: existing.second_pass_count_buf,
        second_pass_dispatch_buf: existing.second_pass_dispatch_buf,
        first_bvh_cull_count_front_buf: existing.first_bvh_cull_count_front_buf,
        first_bvh_cull_dispatch_front_buf: existing.first_bvh_cull_dispatch_front_buf,
        first_bvh_cull_count_back_buf: existing.first_bvh_cull_count_back_buf,
        first_bvh_cull_dispatch_back_buf: existing.first_bvh_cull_dispatch_back_buf,
        front_meshlet_cull_count_buf: existing.front_meshlet_cull_count_buf,
        front_meshlet_cull_dispatch_buf: existing.front_meshlet_cull_dispatch_buf,
        back_meshlet_cull_count_buf: existing.back_meshlet_cull_count_buf,
        back_meshlet_cull_dispatch_buf: existing.back_meshlet_cull_dispatch_buf,
        second_bvh_cull_count_front_buf: existing.second_bvh_cull_count_front_buf,
        second_bvh_cull_dispatch_front_buf: existing.second_bvh_cull_dispatch_front_buf,
        second_bvh_cull_count_back_buf: existing.second_bvh_cull_count_back_buf,
        second_bvh_cull_dispatch_back_buf: existing.second_bvh_cull_dispatch_back_buf,
        visibility_buffer_software_raster_indirect_args_buf: existing.visibility_buffer_software_raster_indirect_args_buf,
        visibility_buffer_hardware_raster_indirect_args_buf: existing.visibility_buffer_hardware_raster_indirect_args_buf,
      }
    Some(existing) => {
      meshlet_release_view_visibility_resources(existing)
      meshlet_create_view_visibility_resources(
        self, required_size, view_width, view_height, not_shadow_view, label,
      )
    }
    None =>
      meshlet_create_view_visibility_resources(
        self, required_size, view_width, view_height, not_shadow_view, label,
      )
  }
  self.meshlet_view_visibility_buffers.set(view_entity_bits, next)
  self.meshlet_view_visibility_buffer_revision = self.meshlet_view_visibility_buffer_revision +
    1
}

///|
pub fn prepare_meshlet_view_visibility_buffer(
  view_entity_bits~ : UInt64,
  view_width~ : Int,
  view_height~ : Int,
  not_shadow_view~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_view_visibility_buffer(
      view_entity_bits~,
      view_width~,
      view_height~,
      not_shadow_view~,
    )
  }
}

///|
pub fn GpuBackend::clear_stale_meshlet_view_visibility_buffers(
  self : GpuBackend,
  active_view_bits : Array[UInt64],
) -> Unit {
  let active : Map[UInt64, Bool] = {}
  for view_bits in active_view_bits {
    active.set(view_bits, true)
  }
  let stale : Array[UInt64] = []
  for view_bits in self.meshlet_view_visibility_buffers.keys() {
    if active.get(view_bits) is None {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    match self.meshlet_view_visibility_buffers.get(view_bits) {
      Some(resources) => meshlet_release_view_visibility_resources(resources)
      None => ()
    }
    self.meshlet_view_visibility_buffers.remove(view_bits)
  }
}

///|
pub fn clear_stale_meshlet_view_visibility_buffers(
  active_view_bits : Array[UInt64],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.clear_stale_meshlet_view_visibility_buffers(active_view_bits)
  }
}

///|
pub fn GpuBackend::prepare_meshlet_view_instance_visibility_buffer(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  instance_visibility~ : Bytes,
) -> Unit {
  match self.meshlet_view_visibility_buffers.get(view_entity_bits) {
    Some(resources) => {
      let (buffer, capacity) = meshlet_storage_buffer_update(
        self,
        Some(resources.instance_visibility_buf),
        resources.instance_visibility_capacity,
        instance_visibility,
        "mgstudio_meshlet_view_instance_visibility",
      )
      resources.instance_visibility_buf = buffer
      resources.instance_visibility_capacity = capacity
    }
    None => ()
  }
}

///|
pub fn prepare_meshlet_view_instance_visibility_buffer(
  view_entity_bits~ : UInt64,
  instance_visibility~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_view_instance_visibility_buffer(
      view_entity_bits~,
      instance_visibility~,
    )
  }
}

///|
pub fn meshlet_view_visibility_buffer_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_view_visibility_buffer_revision
    None => 0
  }
}

///|
pub fn meshlet_view_visibility_buffer_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_view_visibility_buffers.length()
    None => 0
  }
}

///|
fn meshlet_dispatch_group_count_16(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    ((value + 15) / 16).reinterpret_as_uint()
  }
}

///|
fn meshlet_positive_u32(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn meshlet_clear_visibility_buffer_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT", true)
  defines
}

///|
fn meshlet_first_instance_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_INSTANCE_CULLING_PASS", true)
  defines.set("MESHLET_FIRST_CULLING_PASS", true)
  defines
}

///|
fn meshlet_first_bvh_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_BVH_CULLING_PASS", true)
  defines.set("MESHLET_FIRST_CULLING_PASS", true)
  defines
}

///|
fn meshlet_first_meshlet_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_CLUSTER_CULLING_PASS", true)
  defines.set("MESHLET_FIRST_CULLING_PASS", true)
  defines
}

///|
fn meshlet_second_instance_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_INSTANCE_CULLING_PASS", true)
  defines
}

///|
fn meshlet_second_bvh_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_BVH_CULLING_PASS", true)
  defines
}

///|
fn meshlet_second_meshlet_cull_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_CLUSTER_CULLING_PASS", true)
  defines
}

///|
fn meshlet_visibility_buffer_raster_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_VISIBILITY_BUFFER_RASTER_PASS", true)
  defines
}

///|
fn meshlet_fill_counts_defines() -> @hashmap.HashMap[String, Bool] {
  @hashmap.HashMap([])
}

///|
fn meshlet_downsample_depth_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET", true)
  defines.set("MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT", true)
  defines
}

///|
fn meshlet_create_clear_visibility_buffer_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok = builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_COMPUTE),
      @wgpu.BUFFER_BINDING_TYPE_STORAGE,
    ) &&
    builder.add_buffer(
      1U,
      ss(@wgpu.SHADER_STAGE_COMPUTE),
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet clear visibility buffer layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_clear_visibility_buffer_bind_group_layout",
  )
}

///|
fn meshlet_create_clear_visibility_buffer_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_clear_visibility_buffer_constants")
  buffer
}

///|
fn meshlet_create_first_instance_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(10U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(13U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet first instance cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_first_instance_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_first_instance_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_first_instance_cull_constants")
  buffer
}

///|
fn meshlet_create_first_bvh_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=18UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(10U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(13U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(14U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(15U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(16U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(17U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet first BVH cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_first_bvh_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_first_bvh_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_first_bvh_cull_constants")
  buffer
}

///|
fn meshlet_create_first_meshlet_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(10U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(13U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet first meshlet cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_first_meshlet_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_first_meshlet_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_first_meshlet_cull_constants")
  buffer
}

///|
fn meshlet_create_second_instance_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=13UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(
      10U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      11U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet second instance cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_second_instance_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_second_instance_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_second_instance_cull_constants")
  buffer
}

///|
fn meshlet_create_second_bvh_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=15UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(10U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(13U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(14U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet second BVH cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_second_bvh_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_second_bvh_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_second_bvh_cull_constants")
  buffer
}

///|
fn meshlet_create_second_meshlet_cull_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(9U, compute, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE) &&
    builder.add_buffer(
      10U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet second meshlet cull layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_second_meshlet_cull_bind_group_layout",
  )
}

///|
fn meshlet_create_second_meshlet_cull_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_second_meshlet_cull_constants")
  buffer
}

///|
fn meshlet_create_visibility_buffer_raster_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let all_stages = ss(
    @wgpu.SHADER_STAGE_COMPUTE |
    @wgpu.SHADER_STAGE_VERTEX |
    @wgpu.SHADER_STAGE_FRAGMENT,
  )
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=10UL)
  let ok = builder.add_buffer(
      0U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      1U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      2U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      3U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      4U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      5U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      6U,
      all_stages,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(7U, all_stages, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(8U, all_stages, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(9U, all_stages, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet visibility buffer raster layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_visibility_buffer_raster_bind_group_layout",
  )
}

///|
fn meshlet_create_visibility_buffer_raster_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_visibility_buffer_raster_constants")
  buffer
}

///|
fn meshlet_create_resolve_render_targets_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let fragment = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
  let ok = builder.add_buffer(
      0U,
      fragment,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      1U,
      fragment,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(
      2U,
      fragment,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
    ) &&
    builder.add_buffer(3U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet resolve render-target layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_resolve_render_targets_bind_group_layout",
  )
}

///|
fn meshlet_create_resolve_render_targets_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_resolve_render_targets_constants")
  buffer
}

///|
fn meshlet_create_resolve_pipeline(
  backend : GpuBackend,
  pipeline_layout : @wgpu.PipelineLayout,
  fragment_entry : String,
  depth_format : UInt,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let vertex_wgsl = load_wgsl_from_assets_required(
    backend, "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
  let fragment_wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/resolve_render_targets.wgsl",
    meshlet_clear_visibility_buffer_defines(),
    default_wgsl_value_defines(),
  )
  let vertex_sm = backend.device.create_shader_module_wgsl(vertex_wgsl)
  let fragment_sm = backend.device.create_shader_module_wgsl(fragment_wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      vertex_sm,
      layout=pipeline_layout,
    )
    builder.set_entry_points("fullscreen_vertex_shader", fragment_entry)
    builder.set_fragment_module(fragment_sm)
    builder.set_color_target_count(0U)
    builder.set_depth_stencil(
      tf(depth_format),
      depth_write_enabled=true,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_ALWAYS,
    )
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_NONE)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build meshlet \{label} pipeline: \{err.message()}")
    }
  }
  pipeline.set_label(label)
  vertex_sm.release()
  fragment_sm.release()
  pipeline
}

///|
fn meshlet_create_downsample_depth_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
  let mut ok = builder.add_buffer(
    0U,
    compute,
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  for binding_i in 1..<13 {
    let binding = binding_i.reinterpret_as_uint()
    let access = if binding == 6U {
      @wgpu.STORAGE_TEXTURE_ACCESS_READ_WRITE
    } else {
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY
    }
    ok = ok &&
      builder.add_storage_texture(
        binding,
        compute,
        access,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
  }
  ok = ok &&
    builder.add_sampler(13U, compute, @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet downsample depth layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_downsample_depth_bind_group_layout",
  )
}

///|
fn meshlet_create_fill_counts_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet fill counts layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_fill_counts_bind_group_layout",
  )
}

///|
fn meshlet_create_visibility_buffer_hardware_raster_pipeline(
  backend : GpuBackend,
  pipeline_layout : @wgpu.PipelineLayout,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/visibility_buffer_hardware_raster.wgsl",
    meshlet_visibility_buffer_raster_defines(),
    default_wgsl_value_defines(),
  )
  let shader = create_postprocess_shader_module(
    backend, wgsl, "meshlet visibility buffer hardware raster",
  )
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      shader,
      layout=pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(tf(@wgpu.TEXTURE_FORMAT_R8_UINT))
    builder.disable_blend()
    builder.set_topology_u32(@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_NONE)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      shader.release()
      fatal(
        "wgpu: failed to build meshlet visibility buffer hardware raster pipeline",
      )
    }
  }
  pipeline.set_label(
    "mgstudio_meshlet_visibility_buffer_hardware_raster_pipeline",
  )
  shader.release()
  pipeline
}

///|
fn ensure_meshlet_clear_visibility_buffer_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_clear_visibility_buffer_bgl is Some(_) &&
    backend.meshlet_clear_visibility_buffer_pipeline_layout is Some(_) &&
    backend.meshlet_clear_visibility_buffer_pipeline is Some(_) &&
    backend.meshlet_clear_visibility_buffer_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_clear_visibility_buffer_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/clear_visibility_buffer.wgsl",
    meshlet_clear_visibility_buffer_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "clear_visibility_buffer",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet clear visibility buffer pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_clear_visibility_buffer_constants_buf(
    backend,
  )
  backend.meshlet_clear_visibility_buffer_bgl = Some(bgl)
  backend.meshlet_clear_visibility_buffer_pipeline_layout = Some(
    pipeline_layout,
  )
  backend.meshlet_clear_visibility_buffer_pipeline = Some(pipeline)
  backend.meshlet_clear_visibility_buffer_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_first_instance_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_first_instance_cull_bgl is Some(_) &&
    backend.meshlet_first_instance_cull_pipeline_layout is Some(_) &&
    backend.meshlet_first_instance_cull_pipeline is Some(_) &&
    backend.meshlet_first_instance_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_first_instance_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_instances.wgsl",
    meshlet_first_instance_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_instances",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet first instance cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_first_instance_cull_constants_buf(backend)
  backend.meshlet_first_instance_cull_bgl = Some(bgl)
  backend.meshlet_first_instance_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_first_instance_cull_pipeline = Some(pipeline)
  backend.meshlet_first_instance_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_first_bvh_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_first_bvh_cull_bgl is Some(_) &&
    backend.meshlet_first_bvh_cull_pipeline_layout is Some(_) &&
    backend.meshlet_first_bvh_cull_pipeline is Some(_) &&
    backend.meshlet_first_bvh_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_first_bvh_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_bvh.wgsl",
    meshlet_first_bvh_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_bvh",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet first BVH cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_first_bvh_cull_constants_buf(backend)
  backend.meshlet_first_bvh_cull_bgl = Some(bgl)
  backend.meshlet_first_bvh_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_first_bvh_cull_pipeline = Some(pipeline)
  backend.meshlet_first_bvh_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_first_meshlet_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_first_meshlet_cull_bgl is Some(_) &&
    backend.meshlet_first_meshlet_cull_pipeline_layout is Some(_) &&
    backend.meshlet_first_meshlet_cull_pipeline is Some(_) &&
    backend.meshlet_first_meshlet_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_first_meshlet_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_clusters.wgsl",
    meshlet_first_meshlet_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_clusters",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet first meshlet cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_first_meshlet_cull_constants_buf(backend)
  backend.meshlet_first_meshlet_cull_bgl = Some(bgl)
  backend.meshlet_first_meshlet_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_first_meshlet_cull_pipeline = Some(pipeline)
  backend.meshlet_first_meshlet_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_second_instance_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_second_instance_cull_bgl is Some(_) &&
    backend.meshlet_second_instance_cull_pipeline_layout is Some(_) &&
    backend.meshlet_second_instance_cull_pipeline is Some(_) &&
    backend.meshlet_second_instance_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_second_instance_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_instances.wgsl",
    meshlet_second_instance_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_instances",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet second instance cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_second_instance_cull_constants_buf(backend)
  backend.meshlet_second_instance_cull_bgl = Some(bgl)
  backend.meshlet_second_instance_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_second_instance_cull_pipeline = Some(pipeline)
  backend.meshlet_second_instance_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_second_bvh_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_second_bvh_cull_bgl is Some(_) &&
    backend.meshlet_second_bvh_cull_pipeline_layout is Some(_) &&
    backend.meshlet_second_bvh_cull_pipeline is Some(_) &&
    backend.meshlet_second_bvh_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_second_bvh_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_bvh.wgsl",
    meshlet_second_bvh_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_bvh",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet second BVH cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_second_bvh_cull_constants_buf(backend)
  backend.meshlet_second_bvh_cull_bgl = Some(bgl)
  backend.meshlet_second_bvh_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_second_bvh_cull_pipeline = Some(pipeline)
  backend.meshlet_second_bvh_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_second_meshlet_cull_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_second_meshlet_cull_bgl is Some(_) &&
    backend.meshlet_second_meshlet_cull_pipeline_layout is Some(_) &&
    backend.meshlet_second_meshlet_cull_pipeline is Some(_) &&
    backend.meshlet_second_meshlet_cull_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_second_meshlet_cull_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/cull_clusters.wgsl",
    meshlet_second_meshlet_cull_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "cull_clusters",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet second meshlet cull pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_second_meshlet_cull_constants_buf(backend)
  backend.meshlet_second_meshlet_cull_bgl = Some(bgl)
  backend.meshlet_second_meshlet_cull_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_second_meshlet_cull_pipeline = Some(pipeline)
  backend.meshlet_second_meshlet_cull_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_visibility_buffer_raster_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_visibility_buffer_raster_bgl is Some(_) &&
    backend.meshlet_visibility_buffer_raster_pipeline_layout is Some(_) &&
    backend.meshlet_visibility_buffer_software_raster_pipeline is Some(_) &&
    backend.meshlet_visibility_buffer_hardware_raster_pipeline is Some(_) &&
    backend.meshlet_visibility_buffer_raster_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_visibility_buffer_raster_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/visibility_buffer_software_raster.wgsl",
    meshlet_visibility_buffer_raster_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "rasterize_cluster",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet visibility buffer software raster pipeline: \{err.message()}",
      )
  }
  shader.release()
  let hardware_pipeline = meshlet_create_visibility_buffer_hardware_raster_pipeline(
    backend, pipeline_layout,
  )
  let constants_buf = meshlet_create_visibility_buffer_raster_constants_buf(
    backend,
  )
  backend.meshlet_visibility_buffer_raster_bgl = Some(bgl)
  backend.meshlet_visibility_buffer_raster_pipeline_layout = Some(
    pipeline_layout,
  )
  backend.meshlet_visibility_buffer_software_raster_pipeline = Some(pipeline)
  backend.meshlet_visibility_buffer_hardware_raster_pipeline = Some(
    hardware_pipeline,
  )
  backend.meshlet_visibility_buffer_raster_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_resolve_render_targets_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_resolve_render_targets_bgl is Some(_) &&
    backend.meshlet_resolve_render_targets_pipeline_layout is Some(_) &&
    backend.meshlet_resolve_depth_pipeline is Some(_) &&
    backend.meshlet_resolve_material_depth_pipeline is Some(_) &&
    backend.meshlet_resolve_render_targets_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_resolve_render_targets_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let resolve_depth_pipeline = meshlet_create_resolve_pipeline(
    backend,
    pipeline_layout,
    "resolve_depth",
    @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    "mgstudio_meshlet_resolve_depth_pipeline",
  )
  let resolve_material_depth_pipeline = meshlet_create_resolve_pipeline(
    backend,
    pipeline_layout,
    "resolve_material_depth",
    @wgpu.TEXTURE_FORMAT_DEPTH16_UNORM,
    "mgstudio_meshlet_resolve_material_depth_pipeline",
  )
  let constants_buf = meshlet_create_resolve_render_targets_constants_buf(
    backend,
  )
  backend.meshlet_resolve_render_targets_bgl = Some(bgl)
  backend.meshlet_resolve_render_targets_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_resolve_depth_pipeline = Some(resolve_depth_pipeline)
  backend.meshlet_resolve_material_depth_pipeline = Some(
    resolve_material_depth_pipeline,
  )
  backend.meshlet_resolve_render_targets_constants_buf = Some(constants_buf)
  true
}

///|
fn ensure_meshlet_downsample_depth_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_downsample_depth_bgl is Some(_) &&
    backend.meshlet_downsample_depth_pipeline_layout is Some(_) &&
    backend.meshlet_downsample_depth_first_pipeline is Some(_) &&
    backend.meshlet_downsample_depth_second_pipeline is Some(_) &&
    backend.meshlet_downsample_depth_sampler is Some(_) &&
    backend.meshlet_downsample_depth_dummy_view is Some(_) {
    return true
  }
  let bgl = meshlet_create_downsample_depth_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_with_immediates(
    [bgl],
    [(ss(@wgpu.SHADER_STAGE_COMPUTE), 0U, 4U)],
  )
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
    meshlet_downsample_depth_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let first_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "downsample_depth_first",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet downsample depth first pipeline: \{err.message()}",
      )
  }
  let second_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "downsample_depth_second",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet downsample depth second pipeline: \{err.message()}",
      )
  }
  shader.release()
  let (dummy_texture, dummy_view) = meshlet_create_r32float_depth_pyramid_dummy(
    backend,
  )
  let sampler = backend.device.create_sampler_nearest_clamp()
  backend.meshlet_downsample_depth_bgl = Some(bgl)
  backend.meshlet_downsample_depth_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_downsample_depth_first_pipeline = Some(first_pipeline)
  backend.meshlet_downsample_depth_second_pipeline = Some(second_pipeline)
  backend.meshlet_downsample_depth_sampler = Some(sampler)
  backend.meshlet_downsample_depth_dummy_texture = Some(dummy_texture)
  backend.meshlet_downsample_depth_dummy_view = Some(dummy_view)
  true
}

///|
fn ensure_meshlet_fill_counts_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_fill_counts_bgl is Some(_) &&
    backend.meshlet_fill_counts_pipeline_layout is Some(_) &&
    backend.meshlet_fill_counts_pipeline is Some(_) {
    return true
  }
  let bgl = meshlet_create_fill_counts_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/fill_counts.wgsl",
    meshlet_fill_counts_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "fill_counts",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet fill counts pipeline: \{err.message()}",
      )
  }
  shader.release()
  backend.meshlet_fill_counts_bgl = Some(bgl)
  backend.meshlet_fill_counts_pipeline_layout = Some(pipeline_layout)
  backend.meshlet_fill_counts_pipeline = Some(pipeline)
  true
}

///|
fn meshlet_create_clear_visibility_buffer_bind_group(
  backend : GpuBackend,
  visibility_buffer : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok = builder.add_buffer(0U, visibility_buffer) &&
    builder.add_buffer(1U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  Some(
    builder.finish(
      backend.device,
      bgl,
      label="mgstudio_meshlet_clear_visibility_buffer_bind_group",
    ),
  )
}

///|
fn meshlet_previous_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  let identity = gpu_clip_matrix_identity()
  let words : Array[UInt] = []
  for word in gpu_clip_matrix_words(pass_state.view_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.previous_clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.clip_from_view) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  u32le_pack(words)
}

///|
fn meshlet_transient_uniform_buffer(
  backend : GpuBackend,
  frame : GpuFrameState,
  size : UInt64,
  label : String,
  bytes : Bytes,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=meshlet_non_zero_u64(size),
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label(label)
  backend.queue.write_buffer(buffer, 0UL, bytes)
  frame.transient_buffers.push(buffer)
  buffer
}

///|
fn meshlet_create_first_instance_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_instance_aabbs_buf is Some(instance_aabbs) else {
    return None
  }
  guard backend.meshlet_instance_bvh_root_nodes_buf
    is Some(instance_bvh_root_nodes) else {
    return None
  }
  guard backend.meshlet_bvh_traversal_queue_0_buf is Some(first_bvh_queue) else {
    return None
  }
  guard backend.meshlet_second_pass_candidates_buf
    is Some(second_pass_candidates) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, instance_uniforms) &&
    builder.add_buffer(4U, view_resources.instance_visibility_buf) &&
    builder.add_buffer(5U, instance_aabbs) &&
    builder.add_buffer(6U, instance_bvh_root_nodes) &&
    builder.add_buffer(7U, view_resources.first_bvh_cull_count_front_buf) &&
    builder.add_buffer(8U, view_resources.first_bvh_cull_dispatch_front_buf) &&
    builder.add_buffer(9U, first_bvh_queue) &&
    builder.add_buffer(10U, view_resources.second_pass_count_buf) &&
    builder.add_buffer(11U, view_resources.second_pass_dispatch_buf) &&
    builder.add_buffer(12U, second_pass_candidates) &&
    builder.add_buffer(13U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_first_instance_cull_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_first_bvh_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
  ping : Bool,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_bvh_nodes_buf is Some(bvh_nodes) else { return None }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_bvh_traversal_queue_0_buf is Some(first_bvh_queue) else {
    return None
  }
  guard backend.meshlet_bvh_traversal_queue_1_buf is Some(second_bvh_queue) else {
    return None
  }
  guard backend.meshlet_cluster_cull_candidate_queue_buf
    is Some(meshlet_cull_queue) else {
    return None
  }
  let (read_count, write_count, write_dispatch) = if ping {
    (
      view_resources.first_bvh_cull_count_front_buf,
      view_resources.first_bvh_cull_count_back_buf,
      view_resources.first_bvh_cull_dispatch_back_buf,
    )
  } else {
    (
      view_resources.first_bvh_cull_count_back_buf,
      view_resources.first_bvh_cull_count_front_buf,
      view_resources.first_bvh_cull_dispatch_front_buf,
    )
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=18UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, bvh_nodes) &&
    builder.add_buffer(4U, instance_uniforms) &&
    builder.add_buffer(5U, read_count) &&
    builder.add_buffer(6U, write_count) &&
    builder.add_buffer(7U, write_dispatch) &&
    builder.add_buffer(8U, first_bvh_queue) &&
    builder.add_buffer(9U, view_resources.front_meshlet_cull_count_buf) &&
    builder.add_buffer(10U, view_resources.back_meshlet_cull_count_buf) &&
    builder.add_buffer(11U, view_resources.front_meshlet_cull_dispatch_buf) &&
    builder.add_buffer(12U, view_resources.back_meshlet_cull_dispatch_buf) &&
    builder.add_buffer(13U, meshlet_cull_queue) &&
    builder.add_buffer(14U, view_resources.second_bvh_cull_count_front_buf) &&
    builder.add_buffer(15U, view_resources.second_bvh_cull_dispatch_front_buf) &&
    builder.add_buffer(16U, second_bvh_queue) &&
    builder.add_buffer(17U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let label = if ping {
    "mgstudio_meshlet_first_bvh_cull_ping_bind_group"
  } else {
    "mgstudio_meshlet_first_bvh_cull_pong_bind_group"
  }
  let bind_group = builder.finish(backend.device, bgl, label~)
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_first_meshlet_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_cull_data_buf is Some(cull_data) else { return None }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_visibility_buffer_raster_cluster_prev_counts_buf
    is Some(previous_raster_counts) else {
    return None
  }
  guard backend.meshlet_visibility_buffer_raster_clusters_buf
    is Some(raster_clusters) else {
    return None
  }
  guard backend.meshlet_cluster_cull_candidate_queue_buf
    is Some(meshlet_cull_queue) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, cull_data) &&
    builder.add_buffer(4U, instance_uniforms) &&
    builder.add_buffer(
      5U,
      view_resources.visibility_buffer_software_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(
      6U,
      view_resources.visibility_buffer_hardware_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(7U, previous_raster_counts) &&
    builder.add_buffer(8U, raster_clusters) &&
    builder.add_buffer(9U, view_resources.front_meshlet_cull_count_buf) &&
    builder.add_buffer(10U, view_resources.back_meshlet_cull_count_buf) &&
    builder.add_buffer(11U, view_resources.back_meshlet_cull_dispatch_buf) &&
    builder.add_buffer(12U, meshlet_cull_queue) &&
    builder.add_buffer(13U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_first_meshlet_cull_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_second_instance_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_instance_aabbs_buf is Some(instance_aabbs) else {
    return None
  }
  guard backend.meshlet_instance_bvh_root_nodes_buf
    is Some(instance_bvh_root_nodes) else {
    return None
  }
  guard backend.meshlet_bvh_traversal_queue_1_buf is Some(second_bvh_queue) else {
    return None
  }
  guard backend.meshlet_second_pass_candidates_buf
    is Some(second_pass_candidates) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=13UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, instance_uniforms) &&
    builder.add_buffer(4U, view_resources.instance_visibility_buf) &&
    builder.add_buffer(5U, instance_aabbs) &&
    builder.add_buffer(6U, instance_bvh_root_nodes) &&
    builder.add_buffer(7U, view_resources.second_bvh_cull_count_front_buf) &&
    builder.add_buffer(8U, view_resources.second_bvh_cull_dispatch_front_buf) &&
    builder.add_buffer(9U, second_bvh_queue) &&
    builder.add_buffer(10U, view_resources.second_pass_count_buf) &&
    builder.add_buffer(11U, second_pass_candidates) &&
    builder.add_buffer(12U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_second_instance_cull_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_second_bvh_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
  ping : Bool,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_bvh_nodes_buf is Some(bvh_nodes) else { return None }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_bvh_traversal_queue_1_buf is Some(second_bvh_queue) else {
    return None
  }
  guard backend.meshlet_cluster_cull_candidate_queue_buf
    is Some(meshlet_cull_queue) else {
    return None
  }
  let (read_count, write_count, write_dispatch) = if ping {
    (
      view_resources.second_bvh_cull_count_front_buf,
      view_resources.second_bvh_cull_count_back_buf,
      view_resources.second_bvh_cull_dispatch_back_buf,
    )
  } else {
    (
      view_resources.second_bvh_cull_count_back_buf,
      view_resources.second_bvh_cull_count_front_buf,
      view_resources.second_bvh_cull_dispatch_front_buf,
    )
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=15UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, bvh_nodes) &&
    builder.add_buffer(4U, instance_uniforms) &&
    builder.add_buffer(5U, read_count) &&
    builder.add_buffer(6U, write_count) &&
    builder.add_buffer(7U, write_dispatch) &&
    builder.add_buffer(8U, second_bvh_queue) &&
    builder.add_buffer(9U, view_resources.front_meshlet_cull_count_buf) &&
    builder.add_buffer(10U, view_resources.back_meshlet_cull_count_buf) &&
    builder.add_buffer(11U, view_resources.front_meshlet_cull_dispatch_buf) &&
    builder.add_buffer(12U, view_resources.back_meshlet_cull_dispatch_buf) &&
    builder.add_buffer(13U, meshlet_cull_queue) &&
    builder.add_buffer(14U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let label = if ping {
    "mgstudio_meshlet_second_bvh_cull_ping_bind_group"
  } else {
    "mgstudio_meshlet_second_bvh_cull_pong_bind_group"
  }
  let bind_group = builder.finish(backend.device, bgl, label~)
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_second_meshlet_cull_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  previous_view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_cull_data_buf is Some(cull_data) else { return None }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_visibility_buffer_raster_cluster_prev_counts_buf
    is Some(previous_raster_counts) else {
    return None
  }
  guard backend.meshlet_visibility_buffer_raster_clusters_buf
    is Some(raster_clusters) else {
    return None
  }
  guard backend.meshlet_cluster_cull_candidate_queue_buf
    is Some(meshlet_cull_queue) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_texture_view(0U, view_resources.depth_pyramid_view) &&
    builder.add_buffer(1U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(2U, previous_view_buf) &&
    builder.add_buffer(3U, cull_data) &&
    builder.add_buffer(4U, instance_uniforms) &&
    builder.add_buffer(
      5U,
      view_resources.visibility_buffer_software_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(
      6U,
      view_resources.visibility_buffer_hardware_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(7U, previous_raster_counts) &&
    builder.add_buffer(8U, raster_clusters) &&
    builder.add_buffer(9U, view_resources.back_meshlet_cull_count_buf) &&
    builder.add_buffer(10U, meshlet_cull_queue) &&
    builder.add_buffer(11U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_second_meshlet_cull_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_visibility_buffer_raster_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  view_buf : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_visibility_buffer_raster_clusters_buf
    is Some(raster_clusters) else {
    return None
  }
  guard backend.meshlet_meshlets_buf is Some(meshlets) else { return None }
  guard backend.meshlet_indices_buf is Some(indices) else { return None }
  guard backend.meshlet_vertex_positions_buf is Some(vertex_positions) else {
    return None
  }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  guard backend.meshlet_visibility_buffer_raster_cluster_prev_counts_buf
    is Some(previous_raster_counts) else {
    return None
  }
  guard backend.meshlet_software_raster_cluster_count_buf
    is Some(software_raster_cluster_count) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=10UL)
  let ok = builder.add_buffer(0U, raster_clusters) &&
    builder.add_buffer(1U, meshlets) &&
    builder.add_buffer(2U, indices) &&
    builder.add_buffer(3U, vertex_positions) &&
    builder.add_buffer(4U, instance_uniforms) &&
    builder.add_buffer(5U, previous_raster_counts) &&
    builder.add_buffer(6U, software_raster_cluster_count) &&
    builder.add_buffer(7U, view_resources.buffer) &&
    builder.add_buffer(8U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(9U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_visibility_buffer_raster_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_resolve_render_targets_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_visibility_buffer_raster_clusters_buf
    is Some(raster_clusters) else {
    return None
  }
  guard backend.meshlet_instance_material_ids_buf is Some(instance_material_ids) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
  let ok = builder.add_buffer(0U, view_resources.buffer) &&
    builder.add_buffer(1U, raster_clusters) &&
    builder.add_buffer(2U, instance_material_ids) &&
    builder.add_buffer(3U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_resolve_render_targets_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_downsample_depth_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  sampler : @wgpu.Sampler,
  dummy_view : @wgpu.TextureView,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  let mip_or_dummy = fn(index : Int) -> @wgpu.TextureView {
    if index >= 0 && index < view_resources.depth_pyramid_mip_views.length() {
      view_resources.depth_pyramid_mip_views[index]
    } else {
      dummy_view
    }
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let mut ok = builder.add_buffer(0U, view_resources.buffer)
  for mip_index in 0..<12 {
    ok = ok &&
      builder.add_texture_view(
        (mip_index + 1).reinterpret_as_uint(),
        mip_or_dummy(mip_index),
      )
  }
  ok = ok && builder.add_sampler(13U, sampler)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_downsample_depth_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_fill_counts_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_visibility_buffer_raster_cluster_prev_counts_buf
    is Some(previous_raster_counts) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let ok = builder.add_buffer(
      0U,
      view_resources.visibility_buffer_software_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(
      1U,
      view_resources.visibility_buffer_hardware_raster_indirect_args_buf,
    ) &&
    builder.add_buffer(2U, previous_raster_counts)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_fill_counts_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_create_material_shade_bind_group(
  backend : GpuBackend,
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  guard backend.meshlet_visibility_buffer_raster_clusters_buf
    is Some(raster_clusters) else {
    return None
  }
  guard backend.meshlet_meshlets_buf is Some(meshlets) else { return None }
  guard backend.meshlet_indices_buf is Some(indices) else { return None }
  guard backend.meshlet_vertex_positions_buf is Some(vertex_positions) else {
    return None
  }
  guard backend.meshlet_vertex_normals_buf is Some(vertex_normals) else {
    return None
  }
  guard backend.meshlet_vertex_uvs_buf is Some(vertex_uvs) else { return None }
  guard backend.meshlet_instance_uniforms_buf is Some(instance_uniforms) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(0U, view_resources.buffer) &&
    builder.add_buffer(1U, raster_clusters) &&
    builder.add_buffer(2U, meshlets) &&
    builder.add_buffer(3U, indices) &&
    builder.add_buffer(4U, vertex_positions) &&
    builder.add_buffer(5U, vertex_normals) &&
    builder.add_buffer(6U, vertex_uvs) &&
    builder.add_buffer(7U, instance_uniforms)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_meshlet_material_shade_bind_group",
  )
  frame.transient_bind_groups.push(bind_group)
  Some(bind_group)
}

///|
fn meshlet_material_shade_pipeline_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  pass_state : GpuPassState,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  guard material_descriptor is Some(_) else { return None }
  let color_format = match current_pass_color_format(backend) {
    Some(format) => format.to_u32()
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32()
  }
  let topology = @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
  let cull_mode = 0
  let blend_kind = MESH3D_PIPELINE_BLEND_OPAQUE
  let skinned = false
  let forward_decal = false
  let tonemap_in_shader = pass_state.tonemap_in_shader
  let tonemapping_mode = pass_state.tonemapping_mode
  let deband_dither_enabled = pass_state.deband_dither_enabled
  let shadow_filter_method = pass_kind_shadow_filter_method(
    pass_state.pass_kind,
  )
  if mesh3d_pipeline_get(
      backend, color_format, topology, material_pipeline_id, cull_mode, blend_kind,
      skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  if mesh3d_pipeline_failed(
      backend, color_format, topology, material_pipeline_id, cull_mode, blend_kind,
      skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method,
    ) {
    return None
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend, material_pipeline_id, material_descriptor,
  )
  let vertex_shader_path = mesh3d_vertex_shader_path_or_default(
    mesh3d_descriptor_vertex_shader_path(material_descriptor),
  )
  let fragment_shader_path = mesh3d_fragment_shader_path_or_default(
    mesh3d_descriptor_fragment_shader_path(material_descriptor),
  )
  let vertex_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    vertex_shader_path,
  )
  let fragment_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    fragment_shader_path,
  )
  let vertex_sm = mesh3d_create_forward_shader_module(
    backend, vertex_wgsl, "wgpu: failed to create meshlet material shade vertex shader module",
  )
  let fragment_sm = mesh3d_create_forward_shader_module(
    backend, fragment_wgsl, "wgpu: failed to create meshlet material shade fragment shader module",
  ) catch {
    err => {
      vertex_sm.release()
      raise err
    }
  }
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      vertex_sm,
      layout=layout_entry.pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_fragment_module(fragment_sm)
    builder.set_color_target_format(tf(color_format))
    builder.disable_blend()
    builder.set_topology_u32(topology)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
      depth_write_enabled=false,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_EQUAL,
    )
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_NONE)
    backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
    let created = builder.create_pipeline(backend.device)
    let result = backend.device.pop_error_scope_sync_result(backend.instance)
    if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
      let message = mesh3d_error_scope_message(
        result, "wgpu: failed to create meshlet material shade pipeline",
      )
      created.release()
      builder.free()
      mesh3d_pipeline_set_failed(
        backend, color_format, topology, material_pipeline_id, cull_mode, blend_kind,
        skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
        shadow_filter_method, message,
      )
      debug("[renderer] meshlet material shade pipeline failed: \{message}")
      vertex_sm.release()
      fragment_sm.release()
      return None
    }
    builder.free()
    created
  } catch {
    err => {
      let message = "wgpu: failed to build meshlet material shade pipeline: \{err.message()}"
      mesh3d_pipeline_set_failed(
        backend, color_format, topology, material_pipeline_id, cull_mode, blend_kind,
        skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
        shadow_filter_method, message,
      )
      debug("[renderer] meshlet material shade pipeline failed: \{message}")
      vertex_sm.release()
      fragment_sm.release()
      return None
    }
  }
  pipeline.set_label("mgstudio_meshlet_material_shade_pipeline")
  mesh3d_pipeline_set(
    backend, color_format, topology, material_pipeline_id, cull_mode, blend_kind,
    skinned, forward_decal, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
    shadow_filter_method, pipeline,
  )
  vertex_sm.release()
  fragment_sm.release()
  Some(pipeline)
}

///|
fn meshlet_bind_material_shade_draw(
  backend : GpuBackend,
  pass : @wgpu.RenderPass,
  pass_state : GpuPassState,
  material_shade_bind_group : @wgpu.BindGroup,
  entry : HostMeshletMaterialShadeDrawEntry,
) -> Bool raise GpuBackendError {
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    backend,
    entry.material_pipeline_id,
  )
  guard meshlet_material_shade_pipeline_get_or_create(
      backend,
      entry.material_pipeline_id,
      material_descriptor,
      pass_state,
    )
    is Some(pipeline) else {
    return false
  }
  let draw = entry.draw_entry
  let resolved_base_texture_id = if draw.texture_id < 0 {
    -1
  } else {
    draw.texture_id
  }
  let resolved_normal_texture_id = if draw.normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(backend).id
  } else {
    draw.normal_texture_id
  }
  let resolved_emissive_texture_id = if draw.emissive_texture_id < 0 {
    -1
  } else {
    draw.emissive_texture_id
  }
  let resolved_metallic_roughness_texture_id = if draw.metallic_roughness_texture_id <
    0 {
    -1
  } else {
    draw.metallic_roughness_texture_id
  }
  let resolved_occlusion_texture_id = if draw.occlusion_texture_id < 0 {
    -1
  } else {
    draw.occlusion_texture_id
  }
  let resolved_depth_texture_id = if draw.depth_texture_id < 0 {
    -1
  } else {
    draw.depth_texture_id
  }
  let resolved_anisotropy_texture_id = if draw.anisotropy_texture_id < 0 {
    -1
  } else {
    draw.anisotropy_texture_id
  }
  let resolved_specular_tint_texture_id = if draw.specular_tint_texture_id < 0 {
    -1
  } else {
    draw.specular_tint_texture_id
  }
  let resolved_transmission_source_texture_id = if pass_state.transmission_source_texture_id <
    0 {
    -1
  } else {
    pass_state.transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if pass_state.point_shadow_texture_id <
    0 {
    ensure_point_shadow_fallback_texture(backend).id
  } else {
    pass_state.point_shadow_texture_id
  }
  let resolved_directional_shadow_texture_id = if pass_state.directional_shadow_texture_id <
    0 {
    ensure_directional_shadow_fallback_texture(backend).id
  } else {
    pass_state.directional_shadow_texture_id
  }
  let environment_map_enabled = pass_state.environment_map_intensity > 0.0F
  let resolved_environment_diffuse_texture_id = if environment_map_enabled {
    if pass_state.environment_diffuse_texture_id >= 0 {
      pass_state.environment_diffuse_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  let resolved_environment_specular_texture_id = if environment_map_enabled {
    if pass_state.environment_specular_texture_id >= 0 {
      pass_state.environment_specular_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  guard resolve_mesh3d_texture(backend, resolved_base_texture_id)
    is Some(base_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_emissive_texture_id)
    is Some(emissive_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_metallic_roughness_texture_id)
    is Some(metallic_roughness_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_occlusion_texture_id)
    is Some(occlusion_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_depth_texture_id)
    is Some(depth_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_anisotropy_texture_id)
    is Some(anisotropy_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(backend, resolved_environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    return false
  }
  guard resolve_mesh3d_texture(
      backend, resolved_environment_specular_texture_id,
    )
    is Some(environment_specular_texture) else {
    return false
  }
  let runtime_material_flags = mesh3d_runtime_material_flags(
    draw.material_flags,
    draw.normal_texture_id,
    normal_texture,
  )
  guard mesh3d_pass_uniform_state_get_or_create(
      backend,
      pass_state,
      0,
      0,
      pass_state.pass_kind,
    )
    is Some(pass_uniforms) else {
    return false
  }
  let (view_bg, binding_arrays_bg) = mesh3d_frame_view_bg_cache_get_or_create(
    backend,
    entry.material_pipeline_id,
    material_descriptor,
    pass_uniforms,
    transmission_source_texture,
    point_shadow_texture,
    directional_shadow_texture,
    environment_diffuse_texture,
    environment_specular_texture,
    pass_state.tonemapping_mode,
    pass_state.tonemapping_agx_lut_texture_id,
    pass_state.tonemapping_tony_lut_texture_id,
    pass_state.tonemapping_blender_lut_texture_id,
  )
  let material_bg = mesh3d_material_cache_get_or_create(
    backend,
    entry.material_pipeline_id,
    material_descriptor,
    base_texture,
    normal_texture,
    emissive_texture,
    metallic_roughness_texture,
    occlusion_texture,
    depth_texture,
    anisotropy_texture,
    specular_tint_texture,
    mesh3d_standard_material_uniform_bytes(
      draw.color_r,
      draw.color_g,
      draw.color_b,
      draw.color_a,
      draw.uv_transform_a,
      draw.uv_transform_b,
      draw.uv_transform_c,
      draw.uv_transform_d,
      draw.uv_transform_tx,
      draw.uv_transform_ty,
      draw.emissive_r,
      draw.emissive_g,
      draw.emissive_b,
      draw.emissive_exposure_weight,
      draw.metallic,
      draw.roughness,
      draw.reflectance,
      draw.attenuation_color_r,
      draw.attenuation_color_g,
      draw.attenuation_color_b,
      draw.attenuation_distance,
      draw.clearcoat,
      draw.clearcoat_perceptual_roughness,
      draw.parallax_depth_scale,
      draw.max_parallax_layer_count,
      draw.max_relief_mapping_search_steps,
      draw.anisotropy_strength,
      draw.anisotropy_rotation,
      draw.specular_tint_r,
      draw.specular_tint_g,
      draw.specular_tint_b,
      draw.diffuse_transmission,
      draw.specular_transmission,
      draw.thickness,
      draw.ior,
      draw.alpha_cutoff,
      runtime_material_flags,
      draw.lightmap_exposure,
      draw.deferred_lighting_pass_id,
    ),
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(
    0U,
    view_bg,
    mesh3d_descriptor_bind_group_dynamic_offsets(material_descriptor, 0),
  )
  pass.set_bind_group(1U, binding_arrays_bg, [])
  pass.set_bind_group(2U, material_shade_bind_group, [])
  pass.set_bind_group(3U, material_bg, [])
  let first_vertex = if entry.material_id < 0 {
    0U
  } else {
    (entry.material_id * 3).reinterpret_as_uint()
  }
  pass.draw(3U, 1U, first_vertex, 0U)
  render_diagnostics_record_mesh3d_executed_draw()
  true
}

///|
fn meshlet_end_active_render_pass_for_compute(backend : GpuBackend) -> Bool {
  guard backend.frame is Some(frame) else { return false }
  if frame.pass is Some(pass) {
    render_pass_timing_end_active_pass()
    pass.end()
    pass.release()
    frame.pass = None
  }
  true
}

///|
pub fn GpuBackend::execute_meshlet_clear_visibility_buffer(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_clear_visibility_buffer_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.meshlet_clear_visibility_buffer_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_clear_visibility_buffer_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_clear_visibility_buffer_constants_buf
    is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([
      meshlet_positive_u32(view_resources.view_width),
      meshlet_positive_u32(view_resources.view_height),
      0U,
      0U,
    ]),
  )
  guard meshlet_create_clear_visibility_buffer_bind_group(
      self,
      view_resources.buffer,
      constants_buf,
      bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups(
    meshlet_dispatch_group_count_16(view_resources.view_width),
    meshlet_dispatch_group_count_16(view_resources.view_height),
    1U,
  )
  compute_pass.end()
  compute_pass.release()
  bind_group.release()
  self.meshlet_clear_visibility_buffer_dispatch_count = self.meshlet_clear_visibility_buffer_dispatch_count +
    1
  true
}

///|
fn meshlet_workgroup_count_128(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    ((value + 127) / 128).reinterpret_as_uint()
  }
}

///|
fn meshlet_clear_first_instance_cull_outputs(
  frame : GpuFrameState,
  view_resources : MeshletViewVisibilityBuffer,
) -> Unit {
  frame.encoder.clear_buffer(
    view_resources.first_bvh_cull_count_front_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.first_bvh_cull_dispatch_front_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(view_resources.second_pass_count_buf, 0UL, 4UL)
  frame.encoder.clear_buffer(view_resources.second_pass_dispatch_buf, 0UL, 4UL)
  frame.encoder.clear_buffer(
    view_resources.first_bvh_cull_count_back_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.first_bvh_cull_dispatch_back_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.front_meshlet_cull_count_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.front_meshlet_cull_dispatch_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.back_meshlet_cull_count_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.back_meshlet_cull_dispatch_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.second_bvh_cull_count_front_buf,
    0UL,
    4UL,
  )
  frame.encoder.clear_buffer(
    view_resources.second_bvh_cull_dispatch_front_buf,
    0UL,
    4UL,
  )
}

///|
pub fn GpuBackend::execute_meshlet_first_instance_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  scene_instance_count~ : Int,
) -> Bool raise GpuBackendError {
  guard scene_instance_count > 0 else { return false }
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_first_instance_cull_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_first_instance_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_first_instance_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_first_instance_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([meshlet_positive_u32(scene_instance_count), 0U, 0U, 0U]),
  )
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_first_instance_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_first_instance_cull_previous_view",
    previous_view_bytes,
  )
  guard meshlet_create_first_instance_cull_bind_group(
      self, frame, view_resources, view_buf, previous_view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  meshlet_clear_first_instance_cull_outputs(frame, view_resources)
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups(
    meshlet_workgroup_count_128(scene_instance_count),
    1U,
    1U,
  )
  compute_pass.end()
  compute_pass.release()
  self.meshlet_first_instance_cull_dispatch_count = self.meshlet_first_instance_cull_dispatch_count +
    1
  true
}

///|
fn meshlet_first_bvh_read_buffers(
  view_resources : MeshletViewVisibilityBuffer,
  ping : Bool,
) -> (@wgpu.Buffer, @wgpu.Buffer) {
  if ping {
    (
      view_resources.first_bvh_cull_count_front_buf,
      view_resources.first_bvh_cull_dispatch_front_buf,
    )
  } else {
    (
      view_resources.first_bvh_cull_count_back_buf,
      view_resources.first_bvh_cull_dispatch_back_buf,
    )
  }
}

///|
pub fn GpuBackend::execute_meshlet_first_bvh_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  max_bvh_depth~ : Int,
  rightmost_slot~ : Int,
) -> Bool raise GpuBackendError {
  guard max_bvh_depth > 0 else { return false }
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_first_bvh_cull_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_first_bvh_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_first_bvh_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_first_bvh_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_first_bvh_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_first_bvh_cull_previous_view",
    previous_view_bytes,
  )
  let safe_rightmost_slot = if rightmost_slot < 0 {
    0U
  } else {
    rightmost_slot.reinterpret_as_uint()
  }
  let mut ping = true
  let mut dispatched = false
  for _ in 0..<max_bvh_depth {
    let (read_count, read_dispatch) = meshlet_first_bvh_read_buffers(
      view_resources, ping,
    )
    self.queue.write_buffer(
      constants_buf,
      0UL,
      u32le_pack([if ping { 1U } else { 0U }, safe_rightmost_slot, 0U, 0U]),
    )
    guard meshlet_create_first_bvh_cull_bind_group(
        self, frame, view_resources, view_buf, previous_view_buf, constants_buf,
        bgl, ping,
      )
      is Some(bind_group) else {
      return dispatched
    }
    let compute_pass = frame.encoder.begin_compute_pass()
    compute_pass.set_pipeline(pipeline)
    compute_pass.set_bind_group(0U, bind_group, [])
    compute_pass.dispatch_workgroups_indirect(read_dispatch, 0UL)
    compute_pass.end()
    compute_pass.release()
    frame.encoder.clear_buffer(read_count, 0UL, 4UL)
    frame.encoder.clear_buffer(read_dispatch, 0UL, 4UL)
    ping = !ping
    dispatched = true
    self.meshlet_first_bvh_cull_dispatch_count = self.meshlet_first_bvh_cull_dispatch_count +
      1
  }
  dispatched
}

///|
fn meshlet_reset_first_raster_indirect_args(
  backend : GpuBackend,
  view_resources : MeshletViewVisibilityBuffer,
) -> Unit {
  backend.queue.write_buffer(
    view_resources.visibility_buffer_software_raster_indirect_args_buf,
    0UL,
    meshlet_dispatch_indirect_initial_bytes(),
  )
  backend.queue.write_buffer(
    view_resources.visibility_buffer_hardware_raster_indirect_args_buf,
    0UL,
    u32le_pack([384U, 0U, 0U, 0U]),
  )
}

///|
pub fn GpuBackend::execute_meshlet_first_meshlet_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_first_meshlet_cull_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_first_meshlet_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_first_meshlet_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_first_meshlet_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_first_meshlet_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_first_meshlet_cull_previous_view",
    previous_view_bytes,
  )
  let safe_rightmost_slot = if rightmost_slot < 0 {
    0U
  } else {
    rightmost_slot.reinterpret_as_uint()
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([safe_rightmost_slot, 0U, 0U, 0U]),
  )
  meshlet_reset_first_raster_indirect_args(self, view_resources)
  guard meshlet_create_first_meshlet_cull_bind_group(
      self, frame, view_resources, view_buf, previous_view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups_indirect(
    view_resources.front_meshlet_cull_dispatch_buf,
    0UL,
  )
  compute_pass.end()
  compute_pass.release()
  self.meshlet_first_meshlet_cull_dispatch_count = self.meshlet_first_meshlet_cull_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_second_instance_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  scene_instance_count~ : Int,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_second_instance_cull_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_second_instance_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_second_instance_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_second_instance_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([meshlet_positive_u32(scene_instance_count), 0U, 0U, 0U]),
  )
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_second_instance_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_second_instance_cull_previous_view",
    previous_view_bytes,
  )
  guard meshlet_create_second_instance_cull_bind_group(
      self, frame, view_resources, view_buf, previous_view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups_indirect(
    view_resources.second_pass_dispatch_buf,
    0UL,
  )
  compute_pass.end()
  compute_pass.release()
  self.meshlet_second_instance_cull_dispatch_count = self.meshlet_second_instance_cull_dispatch_count +
    1
  true
}

///|
fn meshlet_second_bvh_read_dispatch(
  view_resources : MeshletViewVisibilityBuffer,
  ping : Bool,
) -> @wgpu.Buffer {
  if ping {
    view_resources.second_bvh_cull_dispatch_front_buf
  } else {
    view_resources.second_bvh_cull_dispatch_back_buf
  }
}

///|
pub fn GpuBackend::execute_meshlet_second_bvh_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  max_bvh_depth~ : Int,
  rightmost_slot~ : Int,
) -> Bool raise GpuBackendError {
  guard max_bvh_depth > 0 else { return false }
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_second_bvh_cull_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_second_bvh_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_second_bvh_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_second_bvh_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_second_bvh_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_second_bvh_cull_previous_view",
    previous_view_bytes,
  )
  let safe_rightmost_slot = if rightmost_slot < 0 {
    0U
  } else {
    rightmost_slot.reinterpret_as_uint()
  }
  let mut ping = true
  let mut dispatched = false
  for _ in 0..<max_bvh_depth {
    self.queue.write_buffer(
      constants_buf,
      0UL,
      u32le_pack([if ping { 1U } else { 0U }, safe_rightmost_slot, 0U, 0U]),
    )
    guard meshlet_create_second_bvh_cull_bind_group(
        self, frame, view_resources, view_buf, previous_view_buf, constants_buf,
        bgl, ping,
      )
      is Some(bind_group) else {
      return dispatched
    }
    let compute_pass = frame.encoder.begin_compute_pass()
    compute_pass.set_pipeline(pipeline)
    compute_pass.set_bind_group(0U, bind_group, [])
    compute_pass.dispatch_workgroups_indirect(
      meshlet_second_bvh_read_dispatch(view_resources, ping),
      0UL,
    )
    compute_pass.end()
    compute_pass.release()
    ping = !ping
    dispatched = true
    self.meshlet_second_bvh_cull_dispatch_count = self.meshlet_second_bvh_cull_dispatch_count +
      1
  }
  dispatched
}

///|
pub fn GpuBackend::execute_meshlet_second_meshlet_cull(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_second_meshlet_cull_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_second_meshlet_cull_bgl is Some(bgl) else { return false }
  guard self.meshlet_second_meshlet_cull_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_second_meshlet_cull_constants_buf is Some(constants_buf) else {
    return false
  }
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_second_meshlet_cull_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  let previous_view_bytes = meshlet_previous_view_uniform_bytes(pass_state)
  let previous_view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    previous_view_bytes.length().to_uint64(),
    "mgstudio_meshlet_second_meshlet_cull_previous_view",
    previous_view_bytes,
  )
  let safe_rightmost_slot = if rightmost_slot < 0 {
    0U
  } else {
    rightmost_slot.reinterpret_as_uint()
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([safe_rightmost_slot, 0U, 0U, 0U]),
  )
  guard meshlet_create_second_meshlet_cull_bind_group(
      self, frame, view_resources, view_buf, previous_view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups_indirect(
    view_resources.back_meshlet_cull_dispatch_buf,
    0UL,
  )
  compute_pass.end()
  compute_pass.release()
  self.meshlet_second_meshlet_cull_dispatch_count = self.meshlet_second_meshlet_cull_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_visibility_buffer_software_raster(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_visibility_buffer_raster_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_visibility_buffer_raster_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_visibility_buffer_software_raster_pipeline
    is Some(pipeline) else {
    return false
  }
  guard self.meshlet_visibility_buffer_raster_constants_buf
    is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(constants_buf, 0UL, u32le_pack([0U, 0U, 0U, 0U]))
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_visibility_buffer_raster_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  guard meshlet_create_visibility_buffer_raster_bind_group(
      self, frame, view_resources, view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups_indirect(
    view_resources.visibility_buffer_software_raster_indirect_args_buf,
    0UL,
  )
  compute_pass.end()
  compute_pass.release()
  self.meshlet_visibility_buffer_software_raster_dispatch_count = self.meshlet_visibility_buffer_software_raster_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_visibility_buffer_hardware_raster(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_visibility_buffer_raster_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_visibility_buffer_raster_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_visibility_buffer_hardware_raster_pipeline
    is Some(pipeline) else {
    return false
  }
  guard self.meshlet_visibility_buffer_raster_constants_buf
    is Some(constants_buf) else {
    return false
  }
  let safe_rightmost_slot = if rightmost_slot < 0 {
    0U
  } else {
    rightmost_slot.reinterpret_as_uint()
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([safe_rightmost_slot, 0U, 0U, 0U]),
  )
  let view_buf = meshlet_transient_uniform_buffer(
    self,
    frame,
    MESH3D_VIEW_BUFFER_SIZE,
    "mgstudio_meshlet_visibility_buffer_hardware_raster_view",
    mesh3d_view_uniform_bytes(pass_state),
  )
  guard meshlet_create_visibility_buffer_raster_bind_group(
      self, frame, view_resources, view_buf, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let pass = frame.encoder.begin_render_pass_color_clear(
    view_resources.dummy_render_target_view,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  )
  pass.set_viewport(
    Float::from_double(pass_state.viewport_x.to_double()),
    Float::from_double(pass_state.viewport_y.to_double()),
    Float::from_double(pass_state.viewport_w.to_double()),
    Float::from_double(pass_state.viewport_h.to_double()),
    pass_state.viewport_depth_min,
    pass_state.viewport_depth_max,
  )
  pass.set_scissor_rect(
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.draw_indirect(
    view_resources.visibility_buffer_hardware_raster_indirect_args_buf,
    0UL,
  )
  pass.end()
  pass.release()
  self.meshlet_visibility_buffer_hardware_raster_dispatch_count = self.meshlet_visibility_buffer_hardware_raster_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_fill_counts(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_fill_counts_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.meshlet_fill_counts_bgl is Some(bgl) else { return false }
  guard self.meshlet_fill_counts_pipeline is Some(pipeline) else {
    return false
  }
  guard meshlet_create_fill_counts_bind_group(self, frame, view_resources, bgl)
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups(1U, 1U, 1U)
  compute_pass.end()
  compute_pass.release()
  self.meshlet_fill_counts_dispatch_count = self.meshlet_fill_counts_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_downsample_depth(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  guard view_resources.depth_pyramid_mip_count > 1 else { return false }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_downsample_depth_resources(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.meshlet_downsample_depth_bgl is Some(bgl) else { return false }
  guard self.meshlet_downsample_depth_first_pipeline is Some(first_pipeline) else {
    return false
  }
  guard self.meshlet_downsample_depth_second_pipeline is Some(second_pipeline) else {
    return false
  }
  guard self.meshlet_downsample_depth_sampler is Some(sampler) else {
    return false
  }
  guard self.meshlet_downsample_depth_dummy_view is Some(dummy_view) else {
    return false
  }
  guard meshlet_create_downsample_depth_bind_group(
      self, frame, view_resources, sampler, dummy_view, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let dispatch_x = (
      meshlet_depth_pyramid_dispatch_size(view_resources.view_width) + 63U
    ) /
    64U
  let dispatch_y = (
      meshlet_depth_pyramid_dispatch_size(view_resources.view_height) + 63U
    ) /
    64U
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(first_pipeline)
  compute_pass.set_immediates(
    0U,
    u32le_pack([meshlet_positive_u32(view_resources.depth_pyramid_mip_count)]),
  )
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups(dispatch_x, dispatch_y, 1U)
  if view_resources.depth_pyramid_mip_count >= 7 {
    compute_pass.set_pipeline(second_pipeline)
    compute_pass.dispatch_workgroups(1U, 1U, 1U)
  }
  compute_pass.end()
  compute_pass.release()
  self.meshlet_downsample_depth_dispatch_count = self.meshlet_downsample_depth_dispatch_count +
    1
  true
}

///|
fn meshlet_set_resolve_render_targets_viewport(
  pass : @wgpu.RenderPass,
  pass_state : GpuPassState,
) -> Unit {
  pass.set_viewport(
    Float::from_double(pass_state.viewport_x.to_double()),
    Float::from_double(pass_state.viewport_y.to_double()),
    Float::from_double(pass_state.viewport_w.to_double()),
    Float::from_double(pass_state.viewport_h.to_double()),
    pass_state.viewport_depth_min,
    pass_state.viewport_depth_max,
  )
  pass.set_scissor_rect(
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
}

///|
pub fn GpuBackend::execute_meshlet_resolve_depth(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_resolve_render_targets_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard ensure_depth_view_for_target(self, pass_state.target_id)
    is Some(depth_view) else {
    return false
  }
  guard self.meshlet_resolve_render_targets_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_resolve_depth_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_resolve_render_targets_constants_buf is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([
      meshlet_positive_u32(view_resources.view_width),
      meshlet_positive_u32(view_resources.view_height),
      0U,
      0U,
    ]),
  )
  guard meshlet_create_resolve_render_targets_bind_group(
      self, frame, view_resources, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let pass = command_encoder_begin_render_pass_depth_u32(
    frame.encoder,
    depth_view,
    depth_load_op_u32=@wgpu.LOAD_OP_LOAD,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    depth_read_only=false,
    stencil_read_only=true,
  )
  meshlet_set_resolve_render_targets_viewport(pass, pass_state)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  self.meshlet_resolve_depth_dispatch_count = self.meshlet_resolve_depth_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_resolve_material_depth(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  guard view_resources.material_depth_view is Some(material_depth_view) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_resolve_render_targets_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard self.meshlet_resolve_render_targets_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_resolve_material_depth_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_resolve_render_targets_constants_buf is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([
      meshlet_positive_u32(view_resources.view_width),
      meshlet_positive_u32(view_resources.view_height),
      0U,
      0U,
    ]),
  )
  guard meshlet_create_resolve_render_targets_bind_group(
      self, frame, view_resources, constants_buf, bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let pass = command_encoder_begin_render_pass_depth_u32(
    frame.encoder,
    material_depth_view,
    depth_load_op_u32=@wgpu.LOAD_OP_CLEAR,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    depth_read_only=false,
    stencil_read_only=true,
  )
  meshlet_set_resolve_render_targets_viewport(pass, pass_state)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  self.meshlet_resolve_material_depth_dispatch_count = self.meshlet_resolve_material_depth_dispatch_count +
    1
  true
}

///|
pub fn GpuBackend::execute_meshlet_main_opaque_material_shade(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  draws~ : Array[HostMeshletMaterialShadeDrawEntry],
) -> Bool raise GpuBackendError {
  guard draws.length() > 0 else { return false }
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  guard view_resources.material_depth_view is Some(material_depth_view) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard self.frame is Some(frame) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(color_view) else {
    return false
  }
  let first_descriptor = mesh3d_material_pipeline_descriptor_find(
    self,
    draws[0].material_pipeline_id,
  )
  let first_layout = mesh3d_material_pipeline_layout_get_or_create(
    self,
    draws[0].material_pipeline_id,
    first_descriptor,
  )
  guard meshlet_create_material_shade_bind_group(
      self,
      frame,
      view_resources,
      first_layout.draw_bind_group_layout,
    )
    is Some(material_shade_bind_group) else {
    return false
  }
  let pass = frame.encoder.begin_render_pass_color_depth_u32(
    color_view,
    material_depth_view,
    color_load_op_u32=@wgpu.LOAD_OP_LOAD,
    color_store_op_u32=@wgpu.STORE_OP_STORE,
    color_clear_r_f32=0.0F,
    color_clear_g_f32=0.0F,
    color_clear_b_f32=0.0F,
    color_clear_a_f32=1.0F,
    depth_load_op_u32=@wgpu.LOAD_OP_LOAD,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    depth_read_only=false,
    stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    stencil_read_only=true,
  )
  meshlet_set_resolve_render_targets_viewport(pass, pass_state)
  let mut executed = false
  for entry in draws {
    if meshlet_bind_material_shade_draw(
        self, pass, pass_state, material_shade_bind_group, entry,
      ) {
      executed = true
    }
  }
  pass.end()
  pass.release()
  executed
}

///|
pub fn execute_meshlet_clear_visibility_buffer(
  view_entity_bits~ : UInt64,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_clear_visibility_buffer(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_clear_visibility_buffer", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_clear_visibility_buffer_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_clear_visibility_buffer_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_first_instance_cull(
  view_entity_bits~ : UInt64,
  scene_instance_count~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_first_instance_cull(
        view_entity_bits~,
        scene_instance_count~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_first_instance_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_first_instance_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_first_instance_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_first_bvh_cull(
  view_entity_bits~ : UInt64,
  max_bvh_depth~ : Int,
  rightmost_slot~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_first_bvh_cull(
        view_entity_bits~,
        max_bvh_depth~,
        rightmost_slot~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_first_bvh_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_first_bvh_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_first_bvh_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_first_meshlet_cull(
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_first_meshlet_cull(
        view_entity_bits~,
        rightmost_slot~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_first_meshlet_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_first_meshlet_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_first_meshlet_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_second_instance_cull(
  view_entity_bits~ : UInt64,
  scene_instance_count~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_second_instance_cull(
        view_entity_bits~,
        scene_instance_count~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_second_instance_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_second_instance_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_second_instance_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_second_bvh_cull(
  view_entity_bits~ : UInt64,
  max_bvh_depth~ : Int,
  rightmost_slot~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_second_bvh_cull(
        view_entity_bits~,
        max_bvh_depth~,
        rightmost_slot~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_second_bvh_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_second_bvh_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_second_bvh_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_second_meshlet_cull(
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_second_meshlet_cull(
        view_entity_bits~,
        rightmost_slot~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_second_meshlet_cull", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_second_meshlet_cull_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_second_meshlet_cull_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_visibility_buffer_software_raster(
  view_entity_bits~ : UInt64,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_visibility_buffer_software_raster(
        view_entity_bits~,
      ) catch {
        err => {
          debug_runtime_error(
            "execute_meshlet_visibility_buffer_software_raster", err,
          )
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_visibility_buffer_software_raster_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) =>
      backend.meshlet_visibility_buffer_software_raster_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_visibility_buffer_hardware_raster(
  view_entity_bits~ : UInt64,
  rightmost_slot~ : Int,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_visibility_buffer_hardware_raster(
        view_entity_bits~,
        rightmost_slot~,
      ) catch {
        err => {
          debug_runtime_error(
            "execute_meshlet_visibility_buffer_hardware_raster", err,
          )
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_visibility_buffer_hardware_raster_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) =>
      backend.meshlet_visibility_buffer_hardware_raster_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_fill_counts(view_entity_bits~ : UInt64) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_fill_counts(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_fill_counts", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_fill_counts_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_fill_counts_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_downsample_depth(view_entity_bits~ : UInt64) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_downsample_depth(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_downsample_depth", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_downsample_depth_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_downsample_depth_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_resolve_depth(view_entity_bits~ : UInt64) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_resolve_depth(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_resolve_depth", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_resolve_depth_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_resolve_depth_dispatch_count
    None => 0
  }
}

///|
pub fn execute_meshlet_resolve_material_depth(
  view_entity_bits~ : UInt64,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_resolve_material_depth(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_resolve_material_depth", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn execute_meshlet_main_opaque_material_shade(
  view_entity_bits~ : UInt64,
  draws~ : Array[HostMeshletMaterialShadeDrawEntry],
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_main_opaque_material_shade(
        view_entity_bits~,
        draws~,
      ) catch {
        err => {
          debug_runtime_error("execute_meshlet_main_opaque_material_shade", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_resolve_material_depth_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_resolve_material_depth_dispatch_count
    None => 0
  }
}

///|
pub fn GpuBackend::prepare_meshlet_frame_resources(
  self : GpuBackend,
  cluster_buffer_slots~ : Int,
  scene_instance_count~ : Int,
) -> Unit {
  let cull_queue_size = meshlet_cull_queue_size(cluster_buffer_slots)
  let storage = @wgpu.BUFFER_USAGE_STORAGE
  let storage_copy = @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
  let (raster_clusters, raster_clusters_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_visibility_buffer_raster_clusters_buf,
    self.meshlet_visibility_buffer_raster_clusters_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_visibility_buffer_raster_clusters",
  )
  self.meshlet_visibility_buffer_raster_clusters_buf = Some(raster_clusters)
  self.meshlet_visibility_buffer_raster_clusters_capacity = raster_clusters_capacity
  self.meshlet_visibility_buffer_raster_cluster_prev_counts_buf = Some(
    meshlet_fixed_buffer_write(
      self,
      self.meshlet_visibility_buffer_raster_cluster_prev_counts_buf,
      8UL,
      storage_copy,
      "mgstudio_meshlet_visibility_buffer_raster_cluster_prev_counts",
      u32le_pack([0U, 0U]),
    ),
  )
  self.meshlet_software_raster_cluster_count_buf = Some(
    meshlet_fixed_buffer_write(
      self,
      self.meshlet_software_raster_cluster_count_buf,
      4UL,
      storage_copy,
      "mgstudio_meshlet_software_raster_cluster_count",
      u32le_pack([0U]),
    ),
  )
  let (bvh_queue_0, bvh_queue_0_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_bvh_traversal_queue_0_buf,
    self.meshlet_bvh_traversal_queue_0_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_bvh_traversal_queue_0",
  )
  self.meshlet_bvh_traversal_queue_0_buf = Some(bvh_queue_0)
  self.meshlet_bvh_traversal_queue_0_capacity = bvh_queue_0_capacity
  let (bvh_queue_1, bvh_queue_1_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_bvh_traversal_queue_1_buf,
    self.meshlet_bvh_traversal_queue_1_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_bvh_traversal_queue_1",
  )
  self.meshlet_bvh_traversal_queue_1_buf = Some(bvh_queue_1)
  self.meshlet_bvh_traversal_queue_1_capacity = bvh_queue_1_capacity
  let (cluster_candidates, cluster_candidates_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_cluster_cull_candidate_queue_buf,
    self.meshlet_cluster_cull_candidate_queue_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_cluster_cull_candidate_queue",
  )
  self.meshlet_cluster_cull_candidate_queue_buf = Some(cluster_candidates)
  self.meshlet_cluster_cull_candidate_queue_capacity = cluster_candidates_capacity
  let second_pass_size = meshlet_second_pass_candidate_size(
    scene_instance_count,
  )
  let (second_pass_candidates, second_pass_candidates_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_second_pass_candidates_buf,
    self.meshlet_second_pass_candidates_capacity,
    second_pass_size,
    storage,
    "mgstudio_meshlet_second_pass_candidates",
  )
  self.meshlet_second_pass_candidates_buf = Some(second_pass_candidates)
  self.meshlet_second_pass_candidates_capacity = second_pass_candidates_capacity
  self.meshlet_frame_resource_revision = self.meshlet_frame_resource_revision +
    1
}

///|
pub fn prepare_meshlet_frame_resources(
  cluster_buffer_slots~ : Int,
  scene_instance_count~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_frame_resources(
      cluster_buffer_slots~,
      scene_instance_count~,
    )
  }
}

///|
pub fn meshlet_frame_resource_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_frame_resource_revision
    None => 0
  }
}

///|
pub fn GpuBackend::prepare_meshlet_storage_buffers(
  self : GpuBackend,
  vertex_positions~ : Bytes,
  vertex_normals~ : Bytes,
  vertex_uvs~ : Bytes,
  indices~ : Bytes,
  bvh_nodes~ : Bytes,
  meshlets~ : Bytes,
  cull_data~ : Bytes,
  instance_uniforms~ : Bytes,
  instance_aabbs~ : Bytes,
  instance_material_ids~ : Bytes,
  instance_bvh_root_nodes~ : Bytes,
) -> Unit {
  let (vertex_positions_buf, vertex_positions_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_positions_buf,
    self.meshlet_vertex_positions_capacity,
    vertex_positions,
    "mgstudio_meshlet_vertex_positions",
  )
  self.meshlet_vertex_positions_buf = Some(vertex_positions_buf)
  self.meshlet_vertex_positions_capacity = vertex_positions_capacity
  let (vertex_normals_buf, vertex_normals_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_normals_buf,
    self.meshlet_vertex_normals_capacity,
    vertex_normals,
    "mgstudio_meshlet_vertex_normals",
  )
  self.meshlet_vertex_normals_buf = Some(vertex_normals_buf)
  self.meshlet_vertex_normals_capacity = vertex_normals_capacity
  let (vertex_uvs_buf, vertex_uvs_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_uvs_buf,
    self.meshlet_vertex_uvs_capacity,
    vertex_uvs,
    "mgstudio_meshlet_vertex_uvs",
  )
  self.meshlet_vertex_uvs_buf = Some(vertex_uvs_buf)
  self.meshlet_vertex_uvs_capacity = vertex_uvs_capacity
  let (indices_buf, indices_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_indices_buf,
    self.meshlet_indices_capacity,
    indices,
    "mgstudio_meshlet_indices",
  )
  self.meshlet_indices_buf = Some(indices_buf)
  self.meshlet_indices_capacity = indices_capacity
  let (bvh_nodes_buf, bvh_nodes_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_bvh_nodes_buf,
    self.meshlet_bvh_nodes_capacity,
    bvh_nodes,
    "mgstudio_meshlet_bvh_nodes",
  )
  self.meshlet_bvh_nodes_buf = Some(bvh_nodes_buf)
  self.meshlet_bvh_nodes_capacity = bvh_nodes_capacity
  let (meshlets_buf, meshlets_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_meshlets_buf,
    self.meshlet_meshlets_capacity,
    meshlets,
    "mgstudio_meshlets",
  )
  self.meshlet_meshlets_buf = Some(meshlets_buf)
  self.meshlet_meshlets_capacity = meshlets_capacity
  let (cull_data_buf, cull_data_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_cull_data_buf,
    self.meshlet_cull_data_capacity,
    cull_data,
    "mgstudio_meshlet_cull_data",
  )
  self.meshlet_cull_data_buf = Some(cull_data_buf)
  self.meshlet_cull_data_capacity = cull_data_capacity
  let (instance_uniforms_buf, instance_uniforms_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_uniforms_buf,
    self.meshlet_instance_uniforms_capacity,
    instance_uniforms,
    "mgstudio_meshlet_instance_uniforms",
  )
  self.meshlet_instance_uniforms_buf = Some(instance_uniforms_buf)
  self.meshlet_instance_uniforms_capacity = instance_uniforms_capacity
  let (instance_aabbs_buf, instance_aabbs_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_aabbs_buf,
    self.meshlet_instance_aabbs_capacity,
    instance_aabbs,
    "mgstudio_meshlet_instance_aabbs",
  )
  self.meshlet_instance_aabbs_buf = Some(instance_aabbs_buf)
  self.meshlet_instance_aabbs_capacity = instance_aabbs_capacity
  let (instance_material_ids_buf, instance_material_ids_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_material_ids_buf,
    self.meshlet_instance_material_ids_capacity,
    instance_material_ids,
    "mgstudio_meshlet_instance_material_ids",
  )
  self.meshlet_instance_material_ids_buf = Some(instance_material_ids_buf)
  self.meshlet_instance_material_ids_capacity = instance_material_ids_capacity
  let (instance_bvh_root_nodes_buf, instance_bvh_root_nodes_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_bvh_root_nodes_buf,
    self.meshlet_instance_bvh_root_nodes_capacity,
    instance_bvh_root_nodes,
    "mgstudio_meshlet_instance_bvh_root_nodes",
  )
  self.meshlet_instance_bvh_root_nodes_buf = Some(instance_bvh_root_nodes_buf)
  self.meshlet_instance_bvh_root_nodes_capacity = instance_bvh_root_nodes_capacity
  self.meshlet_gpu_buffer_revision = self.meshlet_gpu_buffer_revision + 1
}

///|
pub fn prepare_meshlet_storage_buffers(
  vertex_positions~ : Bytes,
  vertex_normals~ : Bytes,
  vertex_uvs~ : Bytes,
  indices~ : Bytes,
  bvh_nodes~ : Bytes,
  meshlets~ : Bytes,
  cull_data~ : Bytes,
  instance_uniforms~ : Bytes,
  instance_aabbs~ : Bytes,
  instance_material_ids~ : Bytes,
  instance_bvh_root_nodes~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_storage_buffers(
      vertex_positions~,
      vertex_normals~,
      vertex_uvs~,
      indices~,
      bvh_nodes~,
      meshlets~,
      cull_data~,
      instance_uniforms~,
      instance_aabbs~,
      instance_material_ids~,
      instance_bvh_root_nodes~,
    )
  }
}

///|
pub fn meshlet_gpu_buffer_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_gpu_buffer_revision
    None => 0
  }
}
