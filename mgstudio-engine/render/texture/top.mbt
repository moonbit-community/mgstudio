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
pub fn host_gpu_create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.create_render_target(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  @renderer.create_render_target_rgba16f(
    width~,
    height~,
    nearest~,
    sample_count~,
  )
}

///|
pub fn host_gpu_create_render_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  @renderer.create_render_target_rg16f(width~, height~, nearest~, sample_count~)
}

///|
pub fn host_gpu_create_transmission_source_texture_rgba16f(
  width~ : Int,
  height~ : Int,
) -> Int {
  @renderer.create_transmission_source_texture_rgba16f(width~, height~)
}

///|
pub fn host_gpu_create_motion_vector_prepass_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  sample_count? : Int = 1,
) -> Int {
  @renderer.create_motion_vector_prepass_target_rg16f(
    width~,
    height~,
    nearest~,
    sample_count~,
  )
}

///|
pub fn host_gpu_create_normal_prepass_target_rgb10a2unorm(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
) -> Int {
  @renderer.create_normal_prepass_target_rgb10a2unorm(
    width~,
    height~,
    sample_count~,
  )
}

///|
pub fn host_gpu_create_depth_prepass_target(
  width~ : Int,
  height~ : Int,
  sample_count? : Int = 1,
  usage_bits~ : Int,
) -> Int {
  @renderer.create_depth_prepass_target(
    width~,
    height~,
    sample_count~,
    usage_bits~,
  )
}

///|
pub fn host_gpu_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  @renderer.frame_copy_texture_to_texture(
    dst_texture_id~,
    dst_x~,
    dst_y~,
    src_texture_id~,
  )
}

///|
pub fn asset_create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format~ : @wgpu.TextureFormat,
  sample_format~ : @wgpu.TextureFormat?,
  sample_count? : Int = 1,
) -> Int {
  @renderer.create_render_target_with_formats(
    width~,
    height~,
    nearest~,
    format~,
    sample_format~,
    sample_count~,
  )
}

///|
pub fn host_gpu_create_point_light_shadow_target(size~ : Int) -> Int {
  @renderer.create_point_light_shadow_target(size~)
}

///|
pub fn host_gpu_create_directional_light_shadow_target(
  size~ : Int,
  layers~ : Int,
) -> Int {
  @renderer.create_directional_light_shadow_target(size~, layers~)
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
  usage_bits? : Int = @asset.IMAGE_USAGE_TEXTURE_BINDING |
    @asset.IMAGE_USAGE_COPY_DST |
    @asset.IMAGE_USAGE_COPY_SRC,
) -> Int {
  @renderer.asset_create_texture_empty(
    width~,
    height~,
    mip_level_count~,
    nearest~,
    usage_bits~,
  )
}

///|
pub fn asset_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format~ : @wgpu.TextureFormat,
  pixels~ : Bytes,
) -> Int {
  @renderer.asset_create_texture_3d_with_format(
    width~,
    height~,
    depth~,
    format~,
    pixels~,
  )
}

///|
pub fn asset_create_texture_stacked_2d_with_format(
  width~ : Int,
  height_per_slice~ : Int,
  slice_count~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
  usage_bits? : Int = @asset.IMAGE_USAGE_TEXTURE_BINDING |
    @asset.IMAGE_USAGE_COPY_DST |
    @asset.IMAGE_USAGE_COPY_SRC,
) -> Int {
  @renderer.asset_create_texture_stacked_2d_with_format(
    width~,
    height_per_slice~,
    slice_count~,
    format~,
    levels~,
    nearest~,
    usage_bits~,
  )
}

///|
pub fn asset_create_texture_cube_with_format(
  width~ : Int,
  height~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Int {
  @renderer.asset_create_texture_cube_with_format(
    width~,
    height~,
    format~,
    levels~,
    nearest~,
  )
}

///|
pub fn asset_replace_texture_cube_with_format(
  texture_id~ : Int,
  width~ : Int,
  height~ : Int,
  format~ : @wgpu.TextureFormat,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Bool {
  @renderer.asset_replace_texture_cube_with_format(
    texture_id~,
    width~,
    height~,
    format~,
    levels~,
    nearest~,
  )
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
  @renderer.asset_write_texture_region_rgba8(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    pixels_rgba8~,
  )
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
  @renderer.asset_write_texture_region_rgba8_mip(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    mip_level~,
    pixels_rgba8~,
  )
}

///|
pub fn asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  @renderer.asset_create_texture_mip_view(texture_id~, mip_level~)
}

///|
pub fn asset_texture_width(texture_id~ : Int) -> Int {
  @renderer.asset_texture_width(texture_id~)
}

///|
pub fn asset_texture_height(texture_id~ : Int) -> Int {
  @renderer.asset_texture_height(texture_id~)
}

///|
pub fn asset_texture_format_raw(texture_id~ : Int) -> UInt {
  match @renderer.asset_texture_info(texture_id~) {
    Some(info) => info.format.to_u32()
    None => 0U
  }
}

///|
pub fn asset_is_texture_loaded(texture_id~ : Int) -> Bool {
  @renderer.asset_is_texture_loaded(texture_id~)
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  @renderer.asset_supported_compressed_image_formats()
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  @renderer.asset_copy_texture_to_texture(
    dst_texture_id~,
    dst_x~,
    dst_y~,
    src_texture_id~,
  )
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
  @renderer.asset_set_texture_sampler(
    texture_id~,
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
}

///|
pub fn register_asset_texture_backend() -> Unit {
  @asset.register_asset_texture_backend(
    @asset.AssetTextureBackend::new(
      create_render_target_with_formats_fn=fn(
        width,
        height,
        nearest,
        format,
        sample_format,
      ) {
        asset_create_render_target_with_formats(
          width~,
          height~,
          nearest~,
          format~,
          sample_format~,
        )
      },
      create_texture_empty_fn=fn(
        width,
        height,
        mip_level_count,
        nearest,
        usage_bits,
      ) {
        asset_create_texture_empty(
          width~,
          height~,
          mip_level_count~,
          nearest~,
          usage_bits~,
        )
      },
      create_texture_3d_with_format_fn=fn(
        width,
        height,
        depth,
        format,
        pixels,
      ) {
        asset_create_texture_3d_with_format(
          width~,
          height~,
          depth~,
          format~,
          pixels~,
        )
      },
      create_texture_stacked_2d_with_format_fn=fn(
        width,
        height_per_slice,
        slice_count,
        format,
        levels,
        nearest,
        usage_bits,
      ) {
        asset_create_texture_stacked_2d_with_format(
          width~,
          height_per_slice~,
          slice_count~,
          format~,
          levels~,
          nearest~,
          usage_bits~,
        )
      },
      create_texture_cube_with_format_fn=fn(
        width,
        height,
        format,
        levels,
        nearest,
      ) {
        asset_create_texture_cube_with_format(
          width~,
          height~,
          format~,
          levels~,
          nearest~,
        )
      },
      replace_texture_cube_with_format_fn=fn(
        texture_id,
        width,
        height,
        format,
        levels,
        nearest,
      ) {
        asset_replace_texture_cube_with_format(
          texture_id~,
          width~,
          height~,
          format~,
          levels~,
          nearest~,
        )
      },
      write_texture_region_rgba8_fn=fn(
        texture_id,
        x,
        y,
        width,
        height,
        pixels_rgba8,
      ) {
        asset_write_texture_region_rgba8(
          texture_id~,
          x~,
          y~,
          width~,
          height~,
          pixels_rgba8~,
        )
      },
      write_texture_region_rgba8_mip_fn=fn(
        texture_id,
        x,
        y,
        width,
        height,
        mip_level,
        pixels_rgba8,
      ) {
        asset_write_texture_region_rgba8_mip(
          texture_id~,
          x~,
          y~,
          width~,
          height~,
          mip_level~,
          pixels_rgba8~,
        )
      },
      create_texture_mip_view_fn=fn(texture_id, mip_level) {
        asset_create_texture_mip_view(texture_id~, mip_level~)
      },
      texture_width_fn=fn(texture_id) { asset_texture_width(texture_id~) },
      texture_height_fn=fn(texture_id) { asset_texture_height(texture_id~) },
      is_texture_loaded_fn=fn(texture_id) {
        asset_is_texture_loaded(texture_id~)
      },
      supported_compressed_image_formats_fn=fn() {
        asset_supported_compressed_image_formats()
      },
      copy_texture_to_texture_fn=fn(
        dst_texture_id,
        dst_x,
        dst_y,
        src_texture_id,
      ) {
        asset_copy_texture_to_texture(
          dst_texture_id~,
          dst_x~,
          dst_y~,
          src_texture_id~,
        )
      },
      set_texture_sampler_fn=fn(
        texture_id,
        address_mode_u,
        address_mode_v,
        address_mode_w,
        mag_filter,
        min_filter,
        mipmap_filter,
        lod_min_clamp,
        lod_max_clamp,
        compare,
        anisotropy_clamp,
        border_color,
      ) {
        asset_set_texture_sampler(
          texture_id~,
          address_mode_u~,
          address_mode_v~,
          address_mode_w~,
          mag_filter~,
          min_filter~,
          mipmap_filter~,
          lod_min_clamp~,
          lod_max_clamp~,
          compare~,
          anisotropy_clamp~,
          border_color~,
        )
      },
      capture_texture_rgba8_fn=fn(texture_id) {
        match @renderer.screenshot_capture_texture_sync(texture_id~) {
          Some(capture) =>
            Some(
              @asset.AssetTextureCapture::new(
                width=capture.width,
                height=capture.height,
                pixels=capture.pixels,
              ),
            )
          None => None
        }
      },
    ),
  )
}
