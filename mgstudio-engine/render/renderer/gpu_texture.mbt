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
fn find_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo? {
  for t in backend.textures {
    if t.id == id {
      return Some(t)
    }
  }
  None
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
    let bgl_tex = backend.sprite_bgl_tex.unwrap()
    let w = 128U
    let h = 128U
    let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC
    let usage = @wgpu.TextureUsage::from_u64(usage_bits)
    let tex = backend.device.create_texture_rgba8_2d_with_usage(w, h, usage)
    let view = tex.create_view()
    let sampler = backend.device.create_sampler_linear_clamp()
    let bg = backend.device.create_bind_group_sampler_texture_2d(
      bgl_tex, sampler, view,
    )
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
      format_raw: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      texture: tex,
      view,
      sample_view: None,
      layer_views: [],
      sampler,
      bind_group: bg,
    }
    backend.textures.push(info)
    mesh3d_material_cache_clear(backend)
    info
  }
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
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_rgba8_2d_with_usage(w, h, usage)
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  let expected_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
  if pixels_rgba8.length() != expected_len {
    fatal(
      "wgpu: invalid RGBA8 texture byte length, expected " +
      expected_len.to_string() +
      ", got " +
      pixels_rgba8.length().to_string(),
    )
  }
  self.queue.write_texture_rgba8_2d(tex, w, h, pixels_rgba8)
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
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
  format_raw : UInt,
  levels : Array[Bytes],
  nearest : Bool,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for texture upload")
  }
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported texture format for upload: " +
      format_raw.reinterpret_as_int().to_string(),
    )
  }

  let id = alloc_id(self)
  let w = if width <= 0 { 1 } else { width }
  let h_per_slice = if height_per_slice <= 0 { 1 } else { height_per_slice }
  let slices = if slice_count <= 0 { 1 } else { slice_count }
  let total_height = h_per_slice * slices
  if total_height <= 0 {
    fatal("wgpu: stacked texture height overflow")
  }

  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    w.reinterpret_as_uint(),
    total_height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  let view = tex.create_view()
  view.set_label("mgstudio_render_target_\{id}")
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
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
    let mip_height_per_slice = {
      let v = h_per_slice >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_height = mip_height_per_slice * slices
    if mip_height <= 0 {
      fatal("wgpu: stacked mip height overflow")
    }
    guard texture_layout_for_level(block_info, mip_width, mip_height)
      is Some((bytes_per_row, rows_per_image, expected_bytes)) else {
      fatal("wgpu: failed to compute texture upload layout")
    }
    let level_data = levels[level_index]
    if level_data.length() < expected_bytes {
      fatal(
        "wgpu: mip upload size mismatch at level " + level_index.to_string(),
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
      1U,
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
    height: total_height,
    mip_level_count: levels.length(),
    base_mip_level: 0,
    format_raw,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
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
  format_raw : UInt,
  levels : Array[Bytes],
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for 3D texture upload")
  }
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported 3D texture format for upload: " +
      format_raw.reinterpret_as_int().to_string(),
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
    tf(format_raw),
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  let view = tex.create_view_u32(
    tf(format_raw),
    @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    texture_view_aspect_for_format(format_raw),
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
        "wgpu: 3D mip upload size mismatch at level " + level_index.to_string(),
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
    format_raw,
    texture: tex,
    view,
    sample_view: None,
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
/// Update a sub-rectangle of an RGBA8 2D texture.
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
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let origin_x = if x < 0 { 0U } else { x.reinterpret_as_uint() }
      let origin_y = if y < 0 { 0U } else { y.reinterpret_as_uint() }
      let bytes_per_row = width * 4
      if bytes_per_row <= 0 {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let expected = bytes_per_row * height
      if pixels_rgba8.length() != expected {
        return
      }
      let src = pixels_rgba8
      let upload = if aligned == bytes_per_row {
        src
      } else {
        Bytes::makei(aligned * height, i => {
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
        h,
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(tex_info, upload, layout, extent)
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
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let bytes_per_row = width * 4
      if bytes_per_row <= 0 {
        return
      }
      let expected = bytes_per_row * height
      if pixels_rgba8.length() != expected {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let upload = if aligned == bytes_per_row {
        pixels_rgba8
      } else {
        Bytes::makei(aligned * height, i => {
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
        h,
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(tex_info, upload, layout, extent)
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
    tf(source.format_raw),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(source.format_raw),
    0U,
    1U,
    absolute_mip.reinterpret_as_uint(),
    1U,
  )
  let bind_group = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    source.sampler,
    view,
  )
  let id = alloc_id(self)
  let info = GpuTextureInfo::{
    id,
    width,
    height,
    mip_level_count: 1,
    base_mip_level: absolute_mip,
    format_raw: source.format_raw,
    texture: source.texture,
    view,
    sample_view: None,
    layer_views: [],
    sampler: source.sampler,
    bind_group,
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
  if self.device.supported_features_contains_u32(0x00000007U) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_ASTC_LDR
  }
  if self.device.supported_features_contains_u32(0x00000004U) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_BC
  }
  if self.device.supported_features_contains_u32(0x00000006U) {
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
  let bgl_tex = self.sprite_bgl_tex.unwrap()
  let count = self.textures.length()
  for i in 0..<count {
    let info = self.textures[i]
    if info.id == texture_id {
      let sampler = gpu_sampler_get_or_create(
        self, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
        mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
      )
      let bg = self.device.create_bind_group_sampler_texture_2d(
        bgl_tex,
        sampler,
        info.view,
      )
      self.textures[i] = GpuTextureInfo::{
        id: info.id,
        width: info.width,
        height: info.height,
        mip_level_count: info.mip_level_count,
        base_mip_level: info.base_mip_level,
        format_raw: info.format_raw,
        texture: info.texture,
        view: info.view,
        sample_view: info.sample_view,
        layer_views: info.layer_views,
        sampler,
        bind_group: bg,
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
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
}

///|
pub fn GpuBackend::create_render_target_rgba16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
  )
}

///|
pub fn GpuBackend::create_render_target_rg16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    @wgpu.TEXTURE_FORMAT_RG16_FLOAT,
  )
}

///|
pub fn GpuBackend::create_point_light_shadow_target(
  self : GpuBackend,
  size : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let default_texture = ensure_default_texture(self)
  let id = alloc_id(self)
  let safe_size = if size <= 0 { 1U } else { size.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    safe_size,
    safe_size,
    6U,
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
  for face in 0..<6 {
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
  // Sampling uses cubemap semantics aligned with Bevy face selection order.
  let cube_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    6U,
    0U,
    1U,
  )
  let info = GpuTextureInfo::{
    id,
    width: safe_size.reinterpret_as_int(),
    height: safe_size.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    texture: tex,
    view: face0_view,
    sample_view: Some(cube_view),
    layer_views,
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
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
  format_raw : UInt,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
  )
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
  }
  self.textures.push(info)
  mesh3d_material_cache_clear(self)
  id
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
      Some(frame) => Some(frame.surface_view)
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
          Some(texture) => Some(tf(texture.format_raw))
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
      None => None
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
) -> @wgpu.TextureView? {
  guard target_size_for_pass(backend, target_id) is Some((raw_w, raw_h)) else {
    return None
  }
  let width = if raw_w <= 0 { 1 } else { raw_w }
  let height = if raw_h <= 0 { 1 } else { raw_h }
  if backend.depth_target_id == target_id &&
    backend.depth_width == width &&
    backend.depth_height == height {
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
  )
  let depth_view = depth_tex.create_view()
  backend.depth_texture = Some(depth_tex)
  backend.depth_view = Some(depth_view)
  backend.depth_target_id = target_id
  backend.depth_width = width
  backend.depth_height = height
  Some(depth_view)
}

///|
fn ensure_shadow_color_view(
  backend : GpuBackend,
  width : Int,
  height : Int,
) -> @wgpu.TextureView {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if backend.shadow_color_width == safe_width &&
    backend.shadow_color_height == safe_height {
    if backend.shadow_color_view is Some(view) {
      return view
    }
  }
  if backend.shadow_color_view is Some(old_view) {
    old_view.release()
  }
  if backend.shadow_color_texture is Some(old_tex) {
    old_tex.release()
  }
  let tex = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
  )
  let view = tex.create_view()
  backend.shadow_color_texture = Some(tex)
  backend.shadow_color_view = Some(view)
  backend.shadow_color_width = safe_width
  backend.shadow_color_height = safe_height
  view
}
