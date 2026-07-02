// Copyright 2025 International Digital Economy Academy
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
/// Texture creation, upload, and render target helpers.
///
/// Split from gpu.mbt to keep subsystems cohesive and closer to Bevy's module layout.

///|
const IMAGE_USAGE_TEXTURE_BINDING_BIT : Int = 1

///|
const IMAGE_USAGE_COPY_DST_BIT : Int = 2

///|
const IMAGE_USAGE_COPY_SRC_BIT : Int = 4

///|
const IMAGE_USAGE_RENDER_ATTACHMENT_BIT : Int = 8

///|
const IMAGE_USAGE_STORAGE_BINDING_BIT : Int = 16

///|
const IMAGE_USAGE_DEFAULT_SAMPLED_BITS : Int = IMAGE_USAGE_TEXTURE_BINDING_BIT |
  IMAGE_USAGE_COPY_DST_BIT |
  IMAGE_USAGE_COPY_SRC_BIT

///|
fn texture_usage_bits_to_wgpu(usage_bits : Int) -> UInt64 {
  let usage = usage_bits.reinterpret_as_uint()
  let mut bits : UInt64 = 0UL
  if (usage & IMAGE_USAGE_TEXTURE_BINDING_BIT.reinterpret_as_uint()) != 0U {
    bits = bits | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  }
  if (usage & IMAGE_USAGE_COPY_DST_BIT.reinterpret_as_uint()) != 0U {
    bits = bits | @wgpu.TEXTURE_USAGE_COPY_DST
  }
  if (usage & IMAGE_USAGE_COPY_SRC_BIT.reinterpret_as_uint()) != 0U {
    bits = bits | @wgpu.TEXTURE_USAGE_COPY_SRC
  }
  if (usage & IMAGE_USAGE_RENDER_ATTACHMENT_BIT.reinterpret_as_uint()) != 0U {
    bits = bits | @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT
  }
  if (usage & IMAGE_USAGE_STORAGE_BINDING_BIT.reinterpret_as_uint()) != 0U {
    bits = bits | @wgpu.TEXTURE_USAGE_STORAGE_BINDING
  }
  if bits == 0UL {
    texture_usage_bits_to_wgpu(IMAGE_USAGE_DEFAULT_SAMPLED_BITS)
  } else {
    bits
  }
}

///|
fn find_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo? {
  for t in backend.textures {
    if t.id == id {
      return Some(t)
    }
  }
  None
}

///|
fn find_prepass_depth_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuPrepassDepthTextureInfo? {
  for t in backend.prepass_depth_textures {
    if t.id == id {
      ignore(t.texture)
      return Some(t)
    }
  }
  None
}

///|
pub fn asset_texture_info(texture_id~ : Int) -> GpuTextureInfo? {
  guard ensure_backend() is Some(backend) else { return None }
  find_texture(backend, texture_id)
}

///|
fn create_cached_texture_bind_group(
  backend : GpuBackend,
  sampler : @wgpu.Sampler,
  view : @wgpu.TextureView,
) -> @wgpu.BindGroup raise GpuBackendError {
  ensure_sprite_resources(backend)
  guard backend.sprite_texture_bgl is Some(layout) else {
    fatal("wgpu: sprite texture bind group layout is None")
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok = builder.add_texture_view(0U, view) &&
    builder.add_sampler(1U, sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build cached texture bind group")
  }
  builder.finish(
    backend.device,
    layout,
    label="mgstudio_cached_texture_bind_group",
  )
}

///|
fn ensure_default_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  let id = -1
  if find_texture(backend, id) is Some(t) {
    t
  } else {
    ensure_sprite_resources(backend)
    let w = 128U
    let h = 128U
    let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC
    let usage = @wgpu.TextureUsage::from_u64(usage_bits)
    let tex = backend.device.create_texture_rgba8_2d_with_usage(w, h, usage)
    let view = tex.create_view()
    let sampler = backend.device.create_sampler_linear_clamp()
    let bg = create_cached_texture_bind_group(backend, sampler, view)
    // Fill the texture with white.
    let byte_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
    let data = Bytes::makei(byte_len, _ => (255).to_byte())
    backend.queue.write_texture_rgba8_2d(tex, w, h, data)
    let info = GpuTextureInfo::{
      id,
      width: w.reinterpret_as_int(),
      height: h.reinterpret_as_int(),
      mip_level_count: 1,
      base_mip_level: 0,
      format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
      texture: tex,
      view,
      sample_view: None,
      msaa_texture: None,
      msaa_view: None,
      sample_count: 1,
      layer_views: [],
      sampler,
      bind_group: Some(bg),
    }
    backend.textures.push(info)
    mesh3d_material_cache_clear(backend)
    info
  }
}

///|
fn ensure_normal_map_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.normal_map_fallback_texture_id >= 0 {
    if find_texture(backend, backend.normal_map_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  ensure_sprite_resources(backend)
  let tex = backend.device.create_texture_rgba8_2d_with_usage(
    1U,
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC,
    ),
  )
  let view = tex.create_view()
  let sampler = backend.device.create_sampler_linear_clamp()
  let bg = create_cached_texture_bind_group(backend, sampler, view)
  backend.queue.write_texture_rgba8_2d(
    tex,
    1U,
    1U,
    Bytes::from_array([
      (128).to_byte(),
      (128).to_byte(),
      (255).to_byte(),
      (255).to_byte(),
    ]),
  )
  let info = GpuTextureInfo::{
    id: alloc_id(backend),
    width: 1,
    height: 1,
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler,
    bind_group: Some(bg),
  }
  backend.normal_map_fallback_texture_id = info.id
  backend.textures.push(info)
  mesh3d_material_cache_clear(backend)
  info
}

///|
fn ensure_environment_map_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.environment_map_fallback_texture_id >= 0 {
    if find_texture(backend, backend.environment_map_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  ensure_sprite_resources(backend)
  let default_texture = ensure_default_texture(backend)
  let id = alloc_id(backend)
  let tex = backend.device.create_texture_u32(
    1U,
    1U,
    6U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    mip_level_count=1U,
  )
  let data = Bytes::from_array([
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
  ])
  let tex_info = @wgpu_c.texel_copy_texture_info_new(tex.raw, 0U, 0U, 0U, 0U)
  let layout = @wgpu_c.texel_copy_buffer_layout_new(0UL, 4U, 1U)
  let extent = @wgpu_c.extent3d_new(1U, 1U, 6U)
  backend.queue.write_texture_ptr(
    tex_info,
    data,
    layout,
    extent,
    data_size=24UL,
  )
  @wgpu_c.extent3d_free(extent)
  @wgpu_c.texel_copy_buffer_layout_free(layout)
  @wgpu_c.texel_copy_texture_info_free(tex_info)
  let face0_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  let cube_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    6U,
    0U,
    1U,
  )
  let info = GpuTextureInfo::{
    id,
    width: 1,
    height: 1,
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    texture: tex,
    view: face0_view,
    sample_view: Some(cube_view),
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
  }
  backend.environment_map_fallback_texture_id = id
  backend.textures.push(info)
  mesh3d_material_cache_clear(backend)
  info
}

///|
fn ensure_irradiance_volume_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.irradiance_volume_fallback_texture_id >= 0 {
    if find_texture(backend, backend.irradiance_volume_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let id = backend.create_texture_3d_with_format(
    1,
    1,
    1,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    [
      Bytes::from_array([
        (255).to_byte(),
        (255).to_byte(),
        (255).to_byte(),
        (255).to_byte(),
      ]),
    ],
  )
  guard find_texture(backend, id) is Some(texture) else {
    fatal("wgpu: failed to create irradiance volume fallback texture")
  }
  backend.irradiance_volume_fallback_texture_id = id
  texture
}

///|
fn resolve_draw_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  if id < 0 {
    Some(ensure_default_texture(backend))
  } else {
    find_texture(backend, id)
  }
}

///|
pub fn GpuBackend::create_texture_rgba8(
  self : GpuBackend,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
  nearest : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage = @wgpu.TextureUsage::from_u64(
    texture_usage_bits_to_wgpu(usage_bits) |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let tex = self.device.create_texture_rgba8_2d_with_usage(w, h, usage)
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = create_cached_texture_bind_group(self, sampler, view)
  let expected_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
  if pixels_rgba8.length() != expected_len {
    fatal(
      "wgpu: invalid RGBA8 texture byte length, expected \{expected_len.to_string()}, got \{pixels_rgba8.length().to_string()}",
    )
  }
  self.queue.write_texture_rgba8_2d(tex, w, h, pixels_rgba8)
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler,
    bind_group: Some(bg),
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_texture_stacked_2d_with_format(
  self : GpuBackend,
  width : Int,
  height_per_slice : Int,
  slice_count : Int,
  format : @wgpu.TextureFormat,
  levels : Array[Bytes],
  nearest : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  label? : String? = None,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for texture upload")
  }
  let format_raw = format.to_u32()
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported texture format for upload: \{format_raw.reinterpret_as_int().to_string()}",
    )
  }

  let id = alloc_id(self)
  let w = if width <= 0 { 1 } else { width }
  let h_per_slice = if height_per_slice <= 0 { 1 } else { height_per_slice }
  let slices = if slice_count <= 0 { 1 } else { slice_count }
  let usage = @wgpu.TextureUsage::from_u64(
    texture_usage_bits_to_wgpu(usage_bits) |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let tex = self.device.create_texture_u32(
    w.reinterpret_as_uint(),
    h_per_slice.reinterpret_as_uint(),
    slices.reinterpret_as_uint(),
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  if label is Some(value) {
    tex.set_label(value)
  }
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    levels.length().reinterpret_as_uint(),
  )
  let sample_view = if slices > 1 {
    Some(
      tex.create_view_u32(
        format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
        texture_view_aspect_for_format(format),
        0U,
        slices.reinterpret_as_uint(),
        0U,
        levels.length().reinterpret_as_uint(),
      ),
    )
  } else {
    None
  }
  view.set_label("mgstudio_stacked_2d_texture_layer0_\{id}")
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = create_cached_texture_bind_group(self, sampler, view)

  for level_index in 0..<levels.length() {
    let mip_width = {
      let v = w >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_height_per_slice = {
      let v = h_per_slice >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    guard texture_layout_for_level(block_info, mip_width, mip_height_per_slice)
      is Some((bytes_per_row, rows_per_image, bytes_per_slice)) else {
      fatal("wgpu: failed to compute texture upload layout")
    }
    let expected_bytes = bytes_per_slice * slices
    if expected_bytes <= 0 {
      fatal("wgpu: invalid stacked texture upload size")
    }
    let level_data = levels[level_index]
    if level_data.length() < expected_bytes {
      fatal(
        "wgpu: mip upload size mismatch at level \{level_index.to_string()}",
      )
    }
    let upload_data = if level_data.length() == expected_bytes {
      level_data
    } else {
      Bytes::makei(expected_bytes, i => {
        match level_data.get(i) {
          Some(b) => b
          None => (0).to_byte()
        }
      })
    }
    let tex_info = @wgpu_c.texel_copy_texture_info_new(
      tex.raw,
      level_index.reinterpret_as_uint(),
      0U,
      0U,
      0U,
    )
    let layout = @wgpu_c.texel_copy_buffer_layout_new(
      0UL,
      bytes_per_row.reinterpret_as_uint(),
      rows_per_image.reinterpret_as_uint(),
    )
    let extent = @wgpu_c.extent3d_new(
      mip_width.reinterpret_as_uint(),
      mip_height_per_slice.reinterpret_as_uint(),
      slices.reinterpret_as_uint(),
    )
    self.queue.write_texture_ptr(
      tex_info,
      upload_data,
      layout,
      extent,
      data_size=expected_bytes.to_uint64(),
    )
    @wgpu_c.extent3d_free(extent)
    @wgpu_c.texel_copy_buffer_layout_free(layout)
    @wgpu_c.texel_copy_texture_info_free(tex_info)
  }

  let info = GpuTextureInfo::{
    id,
    width: w,
    height: h_per_slice,
    mip_level_count: levels.length(),
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler,
    bind_group: Some(bg),
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_texture_3d_with_format(
  self : GpuBackend,
  width : Int,
  height : Int,
  depth : Int,
  format : @wgpu.TextureFormat,
  levels : Array[Bytes],
  label? : String? = None,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for 3D texture upload")
  }
  let format_raw = format.to_u32()
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported 3D texture format for upload: \{format_raw.reinterpret_as_int().to_string()}",
    )
  }

  let id = alloc_id(self)
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let d = if depth <= 0 { 1 } else { depth }
  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    w.reinterpret_as_uint(),
    h.reinterpret_as_uint(),
    d.reinterpret_as_uint(),
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_3D),
    format,
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  if label is Some(value) {
    tex.set_label(value)
  }
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    levels.length().reinterpret_as_uint(),
  )

  for level_index in 0..<levels.length() {
    let mip_width = {
      let v = w >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_height = {
      let v = h >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_depth = {
      let v = d >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    guard texture_layout_for_level(block_info, mip_width, mip_height)
      is Some((bytes_per_row, rows_per_image, bytes_per_slice)) else {
      fatal("wgpu: failed to compute 3D texture upload layout")
    }
    let expected_bytes = bytes_per_slice * mip_depth
    if expected_bytes <= 0 {
      fatal("wgpu: invalid 3D texture upload size")
    }
    let level_data = levels[level_index]
    if level_data.length() < expected_bytes {
      fatal(
        "wgpu: 3D mip upload size mismatch at level \{level_index.to_string()}",
      )
    }
    let upload_data = if level_data.length() == expected_bytes {
      level_data
    } else {
      Bytes::makei(expected_bytes, i => {
        match level_data.get(i) {
          Some(b) => b
          None => (0).to_byte()
        }
      })
    }
    let tex_info = @wgpu_c.texel_copy_texture_info_new(
      tex.raw,
      level_index.reinterpret_as_uint(),
      0U,
      0U,
      0U,
    )
    let layout = @wgpu_c.texel_copy_buffer_layout_new(
      0UL,
      bytes_per_row.reinterpret_as_uint(),
      rows_per_image.reinterpret_as_uint(),
    )
    let extent = @wgpu_c.extent3d_new(
      mip_width.reinterpret_as_uint(),
      mip_height.reinterpret_as_uint(),
      mip_depth.reinterpret_as_uint(),
    )
    self.queue.write_texture_ptr(
      tex_info,
      upload_data,
      layout,
      extent,
      data_size=expected_bytes.to_uint64(),
    )
    @wgpu_c.extent3d_free(extent)
    @wgpu_c.texel_copy_buffer_layout_free(layout)
    @wgpu_c.texel_copy_texture_info_free(tex_info)
  }

  let default_texture = ensure_default_texture(self)
  let info = GpuTextureInfo::{
    id,
    width: w,
    height: h,
    mip_level_count: levels.length(),
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::texture_width(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.width
    None => 0
  }
}

///|
pub fn GpuBackend::texture_height(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.height
    None => 0
  }
}

///|
/// Update a sub-rectangle of a 2D texture.
///
/// Note: WGPU requires `bytes_per_row` to be 256-byte aligned, so we may need to
/// pad each row before calling `Queue::write_texture_ptr`.
pub fn GpuBackend::write_texture_region_rgba8(
  self : GpuBackend,
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  match find_texture(self, texture_id) {
    None => ()
    Some(info) => {
      if width <= 0 || height <= 0 {
        return
      }
      guard texture_block_info(info.format.to_u32()) is Some(block_info) else {
        return
      }
      if x < 0 || y < 0 {
        return
      }
      if x + width > info.width || y + height > info.height {
        return
      }
      if x % block_info.block_width != 0 ||
        y % block_info.block_height != 0 ||
        width % block_info.block_width != 0 ||
        height % block_info.block_height != 0 {
        return
      }
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let origin_x = x.reinterpret_as_uint()
      let origin_y = y.reinterpret_as_uint()
      guard texture_layout_for_level(block_info, width, height)
        is Some((bytes_per_row, rows_per_image, expected)) else {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      if pixels_rgba8.length() != expected {
        return
      }
      let src = pixels_rgba8
      let upload_size = aligned * rows_per_image
      let upload = if aligned == bytes_per_row {
        src
      } else {
        Bytes::makei(upload_size, i => {
          let row = i / aligned
          let col = i % aligned
          if col < bytes_per_row {
            let src_i = row * bytes_per_row + col
            match src.get(src_i) {
              Some(b) => b
              None => (0).to_byte()
            }
          } else {
            (0).to_byte()
          }
        })
      }
      let tex_info = @wgpu_c.texel_copy_texture_info_new(
        info.texture.raw,
        0U,
        origin_x,
        origin_y,
        0U,
      )
      let layout = @wgpu_c.texel_copy_buffer_layout_new(
        0UL,
        aligned.reinterpret_as_uint(),
        rows_per_image.reinterpret_as_uint(),
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(
        tex_info,
        upload,
        layout,
        extent,
        data_size=upload_size.to_uint64(),
      )
      @wgpu_c.extent3d_free(extent)
      @wgpu_c.texel_copy_buffer_layout_free(layout)
      @wgpu_c.texel_copy_texture_info_free(tex_info)
    }
  }
}

///|
pub fn GpuBackend::write_texture_region_rgba8_mip(
  self : GpuBackend,
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  mip_level : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  match find_texture(self, texture_id) {
    None => ()
    Some(info) => {
      if width <= 0 || height <= 0 || mip_level < 0 {
        return
      }
      if mip_level >= info.mip_level_count {
        return
      }
      guard texture_block_info(info.format.to_u32()) is Some(block_info) else {
        return
      }
      let target_width = {
        let shifted = info.width >> mip_level
        if shifted <= 0 {
          1
        } else {
          shifted
        }
      }
      let target_height = {
        let shifted = info.height >> mip_level
        if shifted <= 0 {
          1
        } else {
          shifted
        }
      }
      let origin_x_i = if x < 0 { 0 } else { x }
      let origin_y_i = if y < 0 { 0 } else { y }
      if origin_x_i + width > target_width ||
        origin_y_i + height > target_height {
        return
      }
      if origin_x_i % block_info.block_width != 0 ||
        origin_y_i % block_info.block_height != 0 ||
        width % block_info.block_width != 0 ||
        height % block_info.block_height != 0 {
        return
      }
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      guard texture_layout_for_level(block_info, width, height)
        is Some((bytes_per_row, rows_per_image, expected)) else {
        return
      }
      if pixels_rgba8.length() != expected {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let upload_size = aligned * rows_per_image
      let upload = if aligned == bytes_per_row {
        pixels_rgba8
      } else {
        Bytes::makei(upload_size, i => {
          let row = i / aligned
          let col = i % aligned
          if col < bytes_per_row {
            let src_i = row * bytes_per_row + col
            match pixels_rgba8.get(src_i) {
              Some(b) => b
              None => (0).to_byte()
            }
          } else {
            (0).to_byte()
          }
        })
      }
      let absolute_mip = (info.base_mip_level + mip_level).reinterpret_as_uint()
      let tex_info = @wgpu_c.texel_copy_texture_info_new(
        info.texture.raw,
        absolute_mip,
        origin_x_i.reinterpret_as_uint(),
        origin_y_i.reinterpret_as_uint(),
        0U,
      )
      let layout = @wgpu_c.texel_copy_buffer_layout_new(
        0UL,
        aligned.reinterpret_as_uint(),
        rows_per_image.reinterpret_as_uint(),
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(
        tex_info,
        upload,
        layout,
        extent,
        data_size=upload_size.to_uint64(),
      )
      @wgpu_c.extent3d_free(extent)
      @wgpu_c.texel_copy_buffer_layout_free(layout)
      @wgpu_c.texel_copy_texture_info_free(tex_info)
      mesh3d_material_cache_clear(self)
    }
  }
}

///|
pub fn GpuBackend::copy_texture_to_texture(
  self : GpuBackend,
  dst_texture_id : Int,
  dst_x : Int,
  dst_y : Int,
  src_texture_id : Int,
) -> Unit {
  guard find_texture(self, src_texture_id) is Some(src) else { return }
  guard find_texture(self, dst_texture_id) is Some(dst) else { return }
  let origin_x = if dst_x < 0 { 0 } else { dst_x }
  let origin_y = if dst_y < 0 { 0 } else { dst_y }
  let max_width = dst.width - origin_x
  let max_height = dst.height - origin_y
  if max_width <= 0 || max_height <= 0 {
    return
  }
  let copy_width = if src.width < max_width { src.width } else { max_width }
  let copy_height = if src.height < max_height {
    src.height
  } else {
    max_height
  }
  if copy_width <= 0 || copy_height <= 0 {
    return
  }
  let encoder = self.device.create_command_encoder()
  encoder.copy_texture_to_texture_rgba8_mip_layer(
    src.texture,
    src.base_mip_level.reinterpret_as_uint(),
    0U,
    dst.texture,
    dst.base_mip_level.reinterpret_as_uint(),
    0U,
    copy_width.reinterpret_as_uint(),
    copy_height.reinterpret_as_uint(),
  )
  let command_buffer = encoder.finish()
  self.queue.submit_one(command_buffer)
  command_buffer.release()
  encoder.release()
}

///|
pub fn GpuBackend::frame_copy_texture_to_texture(
  self : GpuBackend,
  dst_texture_id : Int,
  dst_x : Int,
  dst_y : Int,
  src_texture_id : Int,
) -> Unit {
  guard self.frame is Some(frame) else { return }
  guard find_texture(self, src_texture_id) is Some(src) else { return }
  guard find_texture(self, dst_texture_id) is Some(dst) else { return }
  let origin_x = if dst_x < 0 { 0 } else { dst_x }
  let origin_y = if dst_y < 0 { 0 } else { dst_y }
  let max_width = dst.width - origin_x
  let max_height = dst.height - origin_y
  if max_width <= 0 || max_height <= 0 {
    return
  }
  let copy_width = if src.width < max_width { src.width } else { max_width }
  let copy_height = if src.height < max_height {
    src.height
  } else {
    max_height
  }
  if copy_width <= 0 || copy_height <= 0 {
    return
  }
  frame.encoder.copy_texture_to_texture_rgba8_mip_layer(
    src.texture,
    src.base_mip_level.reinterpret_as_uint(),
    0U,
    dst.texture,
    dst.base_mip_level.reinterpret_as_uint(),
    0U,
    copy_width.reinterpret_as_uint(),
    copy_height.reinterpret_as_uint(),
  )
}

///|
pub fn GpuBackend::create_texture_mip_view(
  self : GpuBackend,
  texture_id : Int,
  mip_level : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  guard find_texture(self, texture_id) is Some(source) else { return -1 }
  if mip_level < 0 || mip_level >= source.mip_level_count {
    return -1
  }
  let absolute_mip = source.base_mip_level + mip_level
  let width = {
    let shifted = source.width >> mip_level
    if shifted <= 0 {
      1
    } else {
      shifted
    }
  }
  let height = {
    let shifted = source.height >> mip_level
    if shifted <= 0 {
      1
    } else {
      shifted
    }
  }
  let view = source.texture.create_view_u32(
    source.format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(source.format),
    0U,
    1U,
    absolute_mip.reinterpret_as_uint(),
    1U,
  )
  let bind_group = create_cached_texture_bind_group(self, source.sampler, view)
  let id = alloc_id(self)
  let info = GpuTextureInfo::{
    id,
    width,
    height,
    mip_level_count: 1,
    base_mip_level: absolute_mip,
    format: source.format,
    texture: source.texture,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler: source.sampler,
    bind_group: Some(bind_group),
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::is_texture_loaded(
  self : GpuBackend,
  texture_id : Int,
) -> Bool {
  find_texture(self, texture_id) is Some(_)
}

///|
pub fn GpuBackend::supported_compressed_image_formats_mask(
  self : GpuBackend,
) -> Int {
  let mut gpu_feature_mask = 0
  if self.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_TEXTURE_COMPRESSION_ASTC,
    ) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_ASTC_LDR
  }
  if self.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_TEXTURE_COMPRESSION_BC,
    ) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_BC
  }
  if self.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_TEXTURE_COMPRESSION_ETC2,
    ) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_ETC2
  }
  let runtime_decoder_mask = COMPRESSED_IMAGE_FORMAT_ASTC_LDR |
    COMPRESSED_IMAGE_FORMAT_BC |
    COMPRESSED_IMAGE_FORMAT_ETC2
  gpu_feature_mask & runtime_decoder_mask
}

///|
pub fn GpuBackend::set_texture_sampler(
  self : GpuBackend,
  texture_id : Int,
  address_mode_u : Int,
  address_mode_v : Int,
  address_mode_w : Int,
  mag_filter : Int,
  min_filter : Int,
  mipmap_filter : Int,
  lod_min_clamp : Float,
  lod_max_clamp : Float,
  compare : Int,
  anisotropy_clamp : Int,
  border_color : Int,
) -> Unit raise GpuBackendError {
  if self.sprite_bgl_tex is None {
    ensure_sprite_resources(self)
  }
  let count = self.textures.length()
  for i in 0..<count {
    let info = self.textures[i]
    if info.id == texture_id {
      let sampler = gpu_sampler_get_or_create(
        self, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
        mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
      )
      let bind_group = if info.texture.dimension_u32().raw ==
        @wgpu.TEXTURE_DIMENSION_2D &&
        info.texture.sample_count_u32() == 1U {
        Some(create_cached_texture_bind_group(self, sampler, info.view))
      } else {
        None
      }
      self.textures[i] = GpuTextureInfo::{
        id: info.id,
        width: info.width,
        height: info.height,
        mip_level_count: info.mip_level_count,
        base_mip_level: info.base_mip_level,
        format: info.format,
        texture: info.texture,
        view: info.view,
        sample_view: info.sample_view,
        msaa_texture: info.msaa_texture,
        msaa_view: info.msaa_view,
        sample_count: info.sample_count,
        layer_views: info.layer_views,
        sampler,
        bind_group,
      }
      mesh3d_material_cache_clear(self)
      break
    }
  }
}

///|
pub fn GpuBackend::create_render_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
  )
}

///|
pub fn GpuBackend::create_render_target_rgba16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    sample_count~,
  )
}

///|
pub fn GpuBackend::create_render_target_rg16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT),
    sample_count~,
  )
}

///|
pub fn GpuBackend::create_transmission_source_texture_rgba16f(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=1U,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let sampler = self.device.create_sampler_linear_clamp()
  let bind_group = create_cached_texture_bind_group(self, sampler, view)
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler,
    bind_group: Some(bind_group),
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_motion_vector_prepass_target_rg16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let safe_sample_count = if sample_count <= 1 {
    1U
  } else {
    sample_count.reinterpret_as_uint()
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
  )
  let format = tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT)
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=safe_sample_count,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bind_group = if safe_sample_count == 1U {
    Some(create_cached_texture_bind_group(self, sampler, view))
  } else {
    None
  }
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: safe_sample_count.reinterpret_as_int(),
    layer_views: [],
    sampler,
    bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_normal_prepass_target_rgb10a2unorm(
  self : GpuBackend,
  width : Int,
  height : Int,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let safe_sample_count = if sample_count <= 1 {
    1U
  } else {
    sample_count.reinterpret_as_uint()
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
  )
  let format = tf(@wgpu.TEXTURE_FORMAT_RGB10_A2_UNORM)
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=safe_sample_count,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let sampler = self.device.create_sampler_nearest_clamp()
  let bind_group = if safe_sample_count == 1U {
    Some(create_cached_texture_bind_group(self, sampler, view))
  } else {
    None
  }
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: safe_sample_count.reinterpret_as_int(),
    layer_views: [],
    sampler,
    bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
fn GpuBackend::create_prepass_color_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  format : @wgpu.TextureFormat,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let safe_sample_count = if sample_count <= 1 {
    1U
  } else {
    sample_count.reinterpret_as_uint()
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
  )
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=safe_sample_count,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let sampler = self.device.create_sampler_nearest_clamp()
  let bind_group = None
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: safe_sample_count.reinterpret_as_int(),
    layer_views: [],
    sampler,
    bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_deferred_prepass_target_rgba32uint(
  self : GpuBackend,
  width : Int,
  height : Int,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  self.create_prepass_color_target(
    width,
    height,
    tf(@wgpu.TEXTURE_FORMAT_RGBA32_UINT),
    sample_count~,
  )
}

///|
pub fn GpuBackend::create_deferred_lighting_pass_id_target_r8uint(
  self : GpuBackend,
  width : Int,
  height : Int,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  self.create_prepass_color_target(
    width,
    height,
    tf(@wgpu.TEXTURE_FORMAT_R8_UINT),
    sample_count~,
  )
}

///|
pub fn GpuBackend::create_depth_prepass_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  sample_count? : Int = 1,
  usage_bits : Int,
) -> Int {
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let safe_sample_count = if sample_count <= 1 {
    1U
  } else {
    sample_count.reinterpret_as_uint()
  }
  let usage = @wgpu.TextureUsage::from_u64(
    texture_usage_bits_to_wgpu(usage_bits) |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let format = tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT)
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=safe_sample_count,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  self.prepass_depth_textures.push(GpuPrepassDepthTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    sample_count: safe_sample_count.reinterpret_as_int(),
    texture: tex,
    view,
  })
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_point_light_shadow_target(
  self : GpuBackend,
  size : Int,
  cubes? : Int = 1,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let default_texture = ensure_default_texture(self)
  let id = alloc_id(self)
  let safe_size = if size <= 0 { 1U } else { size.reinterpret_as_uint() }
  let safe_cubes = if cubes <= 0 { 1U } else { cubes.reinterpret_as_uint() }
  let safe_layers = safe_cubes * 6U
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    safe_size,
    safe_size,
    safe_layers,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
  )
  // Render passes attach one depth face at a time as 2D targets.
  let face0_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    1U,
    0U,
    1U,
  )
  let layer_views : Array[@wgpu.TextureView] = []
  for face in 0..<safe_layers.reinterpret_as_int() {
    layer_views.push(
      tex.create_view_u32(
        tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
        face.reinterpret_as_uint(),
        1U,
        0U,
        1U,
      ),
    )
  }
  // Bevy binds point light shadow maps as a cube-array texture, even for one cube.
  let cube_array_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_CUBE_ARRAY,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    safe_layers,
    0U,
    1U,
  )
  let info = GpuTextureInfo::{
    id,
    width: safe_size.reinterpret_as_int(),
    height: safe_size.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    texture: tex,
    view: face0_view,
    sample_view: Some(cube_array_view),
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views,
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_directional_light_shadow_target(
  self : GpuBackend,
  size : Int,
  layers : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let default_texture = ensure_default_texture(self)
  let id = alloc_id(self)
  let safe_size = if size <= 0 { 1U } else { size.reinterpret_as_uint() }
  let safe_layers = if layers <= 0 { 1U } else { layers.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    safe_size,
    safe_size,
    safe_layers,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
  )
  let array_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    safe_layers,
    0U,
    1U,
  )
  let layer_views : Array[@wgpu.TextureView] = []
  for layer in 0..<safe_layers.reinterpret_as_int() {
    layer_views.push(
      tex.create_view_u32(
        tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
        layer.reinterpret_as_uint(),
        1U,
        0U,
        1U,
      ),
    )
  }
  let info = GpuTextureInfo::{
    id,
    width: safe_size.reinterpret_as_int(),
    height: safe_size.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    texture: tex,
    view: array_view,
    sample_view: Some(array_view),
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views,
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_texture_cube_with_format(
  self : GpuBackend,
  width : Int,
  height : Int,
  format : @wgpu.TextureFormat,
  levels : Array[Bytes],
  nearest : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  label? : String? = None,
  replace_texture_id? : Int = -2147483648,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for cube texture upload")
  }
  let format_raw = format.to_u32()
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported cube texture format for upload: \{format_raw.reinterpret_as_int().to_string()}",
    )
  }

  let replacing = replace_texture_id >= 0
  let id = if replacing { replace_texture_id } else { alloc_id(self) }
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let usage = @wgpu.TextureUsage::from_u64(
    texture_usage_bits_to_wgpu(usage_bits) | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
  )
  let tex = self.device.create_texture_u32(
    w.reinterpret_as_uint(),
    h.reinterpret_as_uint(),
    6U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  if label is Some(value) {
    tex.set_label(value)
  }

  for level_index in 0..<levels.length() {
    let mip_width = {
      let shifted = w >> level_index
      if shifted <= 0 {
        1
      } else {
        shifted
      }
    }
    let mip_height = {
      let shifted = h >> level_index
      if shifted <= 0 {
        1
      } else {
        shifted
      }
    }
    guard texture_layout_for_level(block_info, mip_width, mip_height)
      is Some((bytes_per_row, rows_per_image, bytes_per_face)) else {
      fatal("wgpu: failed to compute cube texture upload layout")
    }
    let expected_bytes = bytes_per_face * 6
    if expected_bytes <= 0 {
      fatal("wgpu: invalid cube texture upload size")
    }
    let level_data = levels[level_index]
    if level_data.length() < expected_bytes {
      fatal(
        "wgpu: cube mip upload size mismatch at level \{level_index.to_string()}",
      )
    }
    let upload_data = if level_data.length() == expected_bytes {
      level_data
    } else {
      Bytes::makei(expected_bytes, i => {
        match level_data.get(i) {
          Some(b) => b
          None => (0).to_byte()
        }
      })
    }
    let tex_info = @wgpu_c.texel_copy_texture_info_new(
      tex.raw,
      level_index.reinterpret_as_uint(),
      0U,
      0U,
      0U,
    )
    let layout = @wgpu_c.texel_copy_buffer_layout_new(
      0UL,
      bytes_per_row.reinterpret_as_uint(),
      rows_per_image.reinterpret_as_uint(),
    )
    let extent = @wgpu_c.extent3d_new(
      mip_width.reinterpret_as_uint(),
      mip_height.reinterpret_as_uint(),
      6U,
    )
    self.queue.write_texture_ptr(
      tex_info,
      upload_data,
      layout,
      extent,
      data_size=expected_bytes.to_uint64(),
    )
    @wgpu_c.extent3d_free(extent)
    @wgpu_c.texel_copy_buffer_layout_free(layout)
    @wgpu_c.texel_copy_texture_info_free(tex_info)
  }

  let face0_view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let layer_views : Array[@wgpu.TextureView] = []
  for face in 0..<6 {
    layer_views.push(
      tex.create_view_u32(
        format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        texture_view_aspect_for_format(format),
        face.reinterpret_as_uint(),
        1U,
        0U,
        1U,
      ),
    )
  }
  let cube_view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
    texture_view_aspect_for_format(format),
    0U,
    6U,
    0U,
    levels.length().reinterpret_as_uint(),
  )
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bind_group = create_cached_texture_bind_group(self, sampler, face0_view)
  let info = GpuTextureInfo::{
    id,
    width: w,
    height: h,
    mip_level_count: levels.length(),
    base_mip_level: 0,
    format,
    texture: tex,
    view: face0_view,
    sample_view: Some(cube_view),
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views,
    sampler,
    bind_group: Some(bind_group),
  }
  if replacing {
    let kept : Array[GpuTextureInfo] = []
    for texture in self.textures {
      if texture.id != id {
        kept.push(texture)
      }
    }
    self.textures.clear()
    for texture in kept {
      self.textures.push(texture)
    }
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_render_target_with_formats(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  format : @wgpu.TextureFormat,
  sample_format : @wgpu.TextureFormat?,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let format_raw = format.to_u32()
  let sample_format_raw = sample_format.map(fn(format) { format.to_u32() })
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let safe_sample_count = if sample_count <= 1 {
    1U
  } else {
    sample_count.reinterpret_as_uint()
  }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let view_formats = match sample_format_raw {
    Some(raw) if raw != format_raw => [tf(raw)]
    _ => []
  }
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    view_formats~,
    sample_count=1U,
  )
  let view = tex.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  let sample_view = match sample_format_raw {
    Some(raw) if raw != format_raw =>
      Some(
        tex.create_view_u32(
          tf(raw),
          @wgpu.TEXTURE_VIEW_DIMENSION_2D,
          texture_view_aspect_for_format(tf(raw)),
          0U,
          1U,
          0U,
          1U,
        ),
      )
    _ => None
  }
  let (msaa_texture, msaa_view) = if safe_sample_count > 1U {
    let msaa_tex = self.device.create_texture_u32(
      w,
      h,
      1U,
      @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      format,
      view_formats~,
      sample_count=safe_sample_count,
    )
    let msaa_view = msaa_tex.create_view_u32(
      format,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      texture_view_aspect_for_format(format),
      0U,
      1U,
      0U,
      1U,
    )
    (Some(msaa_tex), Some(msaa_view))
  } else {
    (None, None)
  }
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bind_group = match sample_view {
    Some(sampled) => create_cached_texture_bind_group(self, sampler, sampled)
    None => create_cached_texture_bind_group(self, sampler, view)
  }
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format,
    texture: tex,
    view,
    sample_view,
    msaa_texture,
    msaa_view,
    sample_count: safe_sample_count.reinterpret_as_int(),
    layer_views: [],
    sampler,
    bind_group: Some(bind_group),
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
fn GpuBackend::create_render_target_with_format(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  format : @wgpu.TextureFormat,
  sample_count? : Int = 1,
) -> Int raise GpuBackendError {
  self.create_render_target_with_formats(
    width,
    height,
    nearest,
    format,
    None,
    sample_count~,
  )
}

///|
fn target_view(
  backend : GpuBackend,
  target_id : Int,
  target_layer : Int,
) -> @wgpu.TextureView? {
  if target_id < 0 {
    if backend.active_surface_target_id != target_id {
      return None
    }
    match backend.frame {
      Some(frame) => {
        mark_frame_needs_present_for_target(target_id)
        Some(frame.surface_view)
      }
      None => None
    }
  } else {
    match find_texture(backend, target_id) {
      Some(texture) =>
        if target_layer >= 0 && target_layer < texture.layer_views.length() {
          Some(texture.layer_views[target_layer])
        } else {
          Some(texture.view)
        }
      None => None
    }
  }
}

///|
fn ensure_surface_msaa_color_view_for_target(
  backend : GpuBackend,
  target_id : Int,
  sample_count : Int,
) -> @wgpu.TextureView? {
  guard target_id < 0 else { return None }
  guard surface_target_size(backend, target_id) is Some((raw_w, raw_h)) else {
    return None
  }
  guard surface_target_format(backend, target_id) is Some(format) else {
    return None
  }
  let width = if raw_w <= 0 { 1 } else { raw_w }
  let height = if raw_h <= 0 { 1 } else { raw_h }
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  guard safe_sample_count > 1 else { return None }
  if backend.surface_msaa_target_id == target_id &&
    backend.surface_msaa_width == width &&
    backend.surface_msaa_height == height &&
    backend.surface_msaa_sample_count == safe_sample_count &&
    backend.surface_msaa_format is Some(cached_format) &&
    cached_format.raw == format.raw {
    if backend.surface_msaa_view is Some(view) {
      return Some(view)
    }
  }
  if backend.surface_msaa_view is Some(old_view) {
    old_view.release()
  }
  if backend.surface_msaa_texture is Some(old_tex) {
    old_tex.release()
  }
  let msaa_texture = backend.device.create_texture_u32(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=safe_sample_count.reinterpret_as_uint(),
  )
  let msaa_view = msaa_texture.create_view()
  backend.surface_msaa_texture = Some(msaa_texture)
  backend.surface_msaa_view = Some(msaa_view)
  backend.surface_msaa_target_id = target_id
  backend.surface_msaa_width = width
  backend.surface_msaa_height = height
  backend.surface_msaa_sample_count = safe_sample_count
  backend.surface_msaa_format = Some(format)
  Some(msaa_view)
}

///|
fn target_color_attachment(
  backend : GpuBackend,
  target_id : Int,
  target_layer : Int,
  sample_count : Int,
) -> (@wgpu.TextureView, @wgpu.TextureView?)? {
  if target_id < 0 {
    match target_view(backend, target_id, target_layer) {
      Some(view) =>
        match
          ensure_surface_msaa_color_view_for_target(
            backend, target_id, sample_count,
          ) {
          Some(msaa_view) => Some((msaa_view, Some(view)))
          None => Some((view, None))
        }
      None => None
    }
  } else {
    match find_texture(backend, target_id) {
      Some(texture) =>
        if target_layer >= 0 && target_layer < texture.layer_views.length() {
          Some((texture.layer_views[target_layer], None))
        } else {
          match texture.msaa_view {
            Some(msaa_view) => Some((msaa_view, Some(texture.view)))
            None => Some((texture.view, None))
          }
        }
      None => None
    }
  }
}

///|
fn current_pass_color_format(backend : GpuBackend) -> @wgpu.TextureFormat? {
  match backend.pass_state {
    Some(pass_state) =>
      if pass_kind_base_kind(pass_state.pass_kind) ==
        PASS_KIND_BASE_POINT_SHADOW {
        Some(tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM))
      } else if pass_state.target_id < 0 {
        surface_target_format(backend, pass_state.target_id)
      } else {
        match find_texture(backend, pass_state.target_id) {
          Some(texture) => Some(texture.format)
          None => None
        }
      }
    None => None
  }
}

///|
fn target_size_for_pass(backend : GpuBackend, target_id : Int) -> (Int, Int)? {
  if target_id < 0 {
    surface_target_size(backend, target_id)
  } else {
    match find_texture(backend, target_id) {
      Some(info) => Some((info.width, info.height))
      None =>
        match find_prepass_depth_texture(backend, target_id) {
          Some(info) => Some((info.width, info.height))
          None => None
        }
    }
  }
}

///|
fn clamp_scissor_to_target(
  backend : GpuBackend,
  target_id : Int,
  x : UInt,
  y : UInt,
  width : UInt,
  height : UInt,
) -> (UInt, UInt, UInt, UInt) {
  guard target_size_for_pass(backend, target_id)
    is Some((target_w_i, target_h_i)) else {
    return (0U, 0U, 1U, 1U)
  }
  let target_w = if target_w_i <= 0 {
    1U
  } else {
    target_w_i.reinterpret_as_uint()
  }
  let target_h = if target_h_i <= 0 {
    1U
  } else {
    target_h_i.reinterpret_as_uint()
  }

  let sx = if x >= target_w { target_w - 1U } else { x }
  let sy = if y >= target_h { target_h - 1U } else { y }
  let max_w = target_w - sx
  let max_h = target_h - sy
  let sw = if width == 0U { 1U } else if width > max_w { max_w } else { width }
  let sh = if height == 0U {
    1U
  } else if height > max_h {
    max_h
  } else {
    height
  }
  (sx, sy, sw, sh)
}

///|
fn ensure_depth_view_for_target(
  backend : GpuBackend,
  target_id : Int,
  sample_count : Int,
) -> @wgpu.TextureView? {
  guard target_size_for_pass(backend, target_id) is Some((raw_w, raw_h)) else {
    return None
  }
  let width = if raw_w <= 0 { 1 } else { raw_w }
  let height = if raw_h <= 0 { 1 } else { raw_h }
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  if backend.depth_target_id == target_id &&
    backend.depth_width == width &&
    backend.depth_height == height &&
    backend.depth_sample_count == safe_sample_count {
    if backend.depth_view is Some(view) {
      return Some(view)
    }
  }
  if backend.depth_view is Some(old_view) {
    old_view.release()
  }
  if backend.depth_texture is Some(old_tex) {
    old_tex.release()
  }
  let depth_tex = backend.device.create_texture_u32(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    sample_count=safe_sample_count.reinterpret_as_uint(),
  )
  let depth_view = depth_tex.create_view()
  backend.depth_texture = Some(depth_tex)
  backend.depth_view = Some(depth_view)
  backend.depth_target_id = target_id
  backend.depth_width = width
  backend.depth_height = height
  backend.depth_sample_count = safe_sample_count
  Some(depth_view)
}

///|
fn mip_dim(base : Int, level : Int) -> Int {
  let shifted = base >> level
  if shifted <= 0 {
    1
  } else {
    shifted
  }
}

///|
pub fn create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_rgba16f(
        width,
        height,
        nearest,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_rg16f(
        width,
        height,
        nearest,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_transmission_source_texture_rgba16f(
  width~ : Int,
  height~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_transmission_source_texture_rgba16f(width, height)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_motion_vector_prepass_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_motion_vector_prepass_target_rg16f(
        width,
        height,
        nearest,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_normal_prepass_target_rgb10a2unorm(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_normal_prepass_target_rgb10a2unorm(
        width,
        height,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_deferred_prepass_target_rgba32uint(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_deferred_prepass_target_rgba32uint(
        width,
        height,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_deferred_lighting_pass_id_target_r8uint(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_deferred_lighting_pass_id_target_r8uint(
        width,
        height,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_depth_prepass_target(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
  usage_bits~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_depth_prepass_target(
      width,
      height,
      sample_count~,
      usage_bits,
    )
  }
  -1
}

///|
pub fn create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format~ : @wgpu.TextureFormat,
  sample_format~ : @wgpu.TextureFormat?,
  sample_count? : Int = 1,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_with_formats(
        width,
        height,
        nearest,
        format,
        sample_format,
        sample_count~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_point_light_shadow_target(size~ : Int, cubes? : Int = 1) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_point_light_shadow_target(size, cubes~)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_directional_light_shadow_target(
  size~ : Int,
  layers~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_directional_light_shadow_target(size, layers)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let safe_mips = if mip_level_count <= 0 { 1 } else { mip_level_count }
  if ensure_backend() is Some(backend) {
    try {
      if safe_mips == 1 {
        let bytes = Bytes::makei(safe_width * safe_height * 4, _ => {
          (0).to_byte()
        })
        return backend.create_texture_rgba8(
          safe_width,
          safe_height,
          bytes,
          nearest,
          usage_bits~,
        )
      }
      let levels : Array[Bytes] = []
      for level in 0..<safe_mips {
        let level_width = mip_dim(safe_width, level)
        let level_height = mip_dim(safe_height, level)
        levels.push(
          Bytes::makei(level_width * level_height * 4, _ => (0).to_byte()),
        )
      }
      return backend.create_texture_stacked_2d_with_format(
        safe_width,
        safe_height,
        1,
        tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
        levels,
        nearest,
        usage_bits~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format~ : @wgpu.TextureFormat,
  pixels~ : Bytes,
  label? : String? = None,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let safe_depth = if depth <= 0 { 1 } else { depth }
  if ensure_backend() is Some(backend) {
    try {
      let levels = [pixels]
      return backend.create_texture_3d_with_format(
        safe_width,
        safe_height,
        safe_depth,
        format,
        levels,
        label~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_create_texture_stacked_2d_with_format(
  width~ : Int,
  height_per_slice~ : Int,
  slice_count~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  label? : String? = None,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height_per_slice = if height_per_slice <= 0 {
    1
  } else {
    height_per_slice
  }
  let safe_slice_count = if slice_count <= 0 { 1 } else { slice_count }
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_stacked_2d_with_format(
        safe_width,
        safe_height_per_slice,
        safe_slice_count,
        format,
        levels,
        nearest,
        usage_bits~,
        label~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_create_texture_cube_with_format(
  width~ : Int,
  height~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  label? : String? = None,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_cube_with_format(
        safe_width,
        safe_height,
        format,
        levels,
        nearest,
        usage_bits~,
        label~,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_replace_texture_cube_with_format(
  texture_id~ : Int,
  width~ : Int,
  height~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
  usage_bits? : Int = IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
) -> Bool {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if texture_id < 0 {
    return false
  }
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_cube_with_format(
          safe_width,
          safe_height,
          format,
          levels,
          nearest,
          usage_bits~,
          replace_texture_id=texture_id,
        ) ==
        texture_id
    } catch {
      _ => ()
    }
  }
  false
}

///|
pub fn asset_write_texture_region_rgba8(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8(
      texture_id, x, y, width, height, pixels_rgba8,
    )
  }
}

///|
pub fn asset_write_texture_region_rgba8_mip(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8_mip(
      texture_id, x, y, width, height, mip_level, pixels_rgba8,
    )
  }
}

///|
pub fn asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_mip_view(texture_id, mip_level)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_texture_width(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_width(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_texture_height(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_height(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_is_texture_loaded(texture_id~ : Int) -> Bool {
  if ensure_backend() is Some(backend) {
    backend.is_texture_loaded(texture_id)
  } else {
    false
  }
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  if ensure_backend() is Some(backend) {
    backend.supported_compressed_image_formats_mask()
  } else {
    0
  }
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.copy_texture_to_texture(
      dst_texture_id, dst_x, dst_y, src_texture_id,
    )
  }
}

///|
pub fn frame_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.frame_copy_texture_to_texture(
      dst_texture_id, dst_x, dst_y, src_texture_id,
    )
  }
}

///|
pub fn asset_set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_texture_sampler(
      texture_id, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
      mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
    ) catch {
      err => {
        let error_message = match err {
          Fatal(message) => message
          ShaderNotReady(message) => message
        }
        abort(
          "wgpu: failed to set texture sampler for texture \{texture_id.to_string()}: \{error_message}",
        )
      }
    }
  }
}
