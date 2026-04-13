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
) -> Int {
  @renderer.create_render_target_rgba16f(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_render_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.create_render_target_rg16f(width~, height~, nearest~)
}

///|
pub fn asset_create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format_raw~ : Int,
  sample_format_raw~ : Int,
) -> Int {
  @renderer.create_render_target_with_formats(
    width~,
    height~,
    nearest~,
    format_raw~,
    sample_format_raw~,
  )
}

///|
pub fn host_gpu_create_point_light_shadow_target(size~ : Int) -> Int {
  @renderer.create_point_light_shadow_target(size~)
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.asset_create_texture_empty(
    width~,
    height~,
    mip_level_count~,
    nearest~,
  )
}

///|
pub fn asset_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format_raw~ : Int,
  pixels~ : Bytes,
) -> Int {
  @renderer.asset_create_texture_3d_with_format(
    width~,
    height~,
    depth~,
    format_raw~,
    pixels~,
  )
}

///|
pub fn asset_create_texture_stacked_2d_with_format(
  width~ : Int,
  height_per_slice~ : Int,
  slice_count~ : Int,
  format_raw~ : Int,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Int {
  @renderer.asset_create_texture_stacked_2d_with_format(
    width~,
    height_per_slice~,
    slice_count~,
    format_raw~,
    levels~,
    nearest~,
  )
}

///|
pub fn asset_create_texture_cube_with_format(
  width~ : Int,
  height~ : Int,
  format_raw~ : Int,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Int {
  @renderer.asset_create_texture_cube_with_format(
    width~,
    height~,
    format_raw~,
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
