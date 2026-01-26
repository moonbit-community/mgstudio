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
pub struct GlyphCacheKey {
  glyph_id : Int
  subpixel_x : Int
  subpixel_y : Int
}

///|
pub fn GlyphCacheKey::new(
  glyph_id : Int,
  subpixel_x : Int,
  subpixel_y : Int,
) -> GlyphCacheKey {
  GlyphCacheKey::{ glyph_id, subpixel_x, subpixel_y }
}

///|
fn glyph_cache_key_equals(a : GlyphCacheKey, b : GlyphCacheKey) -> Bool {
  a.glyph_id == b.glyph_id &&
  a.subpixel_x == b.subpixel_x &&
  a.subpixel_y == b.subpixel_y
}

///|
pub struct GlyphRaster {
  id : Int
  size : @math.UVec2
  offset : @math.IVec2
}

///|
pub fn host_font_rasterize_glyph(
  font_id : Int,
  font_size : Float,
  codepoint : Int,
  smoothing : Int,
) -> Int = "mgstudio_host" "font_rasterize_glyph"

///|
pub fn host_font_glyph_width(glyph_id : Int) -> Int = "mgstudio_host" "font_glyph_width"

///|
pub fn host_font_glyph_height(glyph_id : Int) -> Int = "mgstudio_host" "font_glyph_height"

///|
pub fn host_font_glyph_offset_x(glyph_id : Int) -> Int = "mgstudio_host" "font_glyph_offset_x"

///|
pub fn host_font_glyph_offset_y(glyph_id : Int) -> Int = "mgstudio_host" "font_glyph_offset_y"

///|
pub fn host_font_measure_advance(
  font_id : Int,
  font_size : Float,
  codepoint : Int,
) -> Float = "mgstudio_host" "font_measure_advance"

///|
pub fn font_rasterize_glyph(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  codepoint : Int,
  smoothing : FontSmoothing,
) -> GlyphRaster? {
  let smoothing_id = match smoothing {
    FontSmoothing::None => 0
    FontSmoothing::AntiAliased => 1
  }
  let id = host_font_rasterize_glyph(
    font.id(),
    font_size,
    codepoint,
    smoothing_id,
  )
  if id < 0 {
    return None
  }
  let width = host_font_glyph_width(id)
  let height = host_font_glyph_height(id)
  let offset_x = host_font_glyph_offset_x(id)
  let offset_y = host_font_glyph_offset_y(id)
  if width <= 0 || height <= 0 {
    return None
  }
  Some(GlyphRaster::{
    id,
    size: @math.UVec2::new(width, height),
    offset: @math.IVec2::new(offset_x, offset_y),
  })
}

///|
pub struct FontAtlas {
  dynamic_texture_atlas_builder : @asset.DynamicTextureAtlasBuilder
  glyph_locations : Array[(GlyphCacheKey, GlyphAtlasLocation)]
  texture_atlas : @asset.Handle[@asset.TextureAtlasLayout]
  texture : @asset.Handle[@asset.Image]
}

///|
pub fn FontAtlas::new(
  size : @math.UVec2,
  font_smoothing : FontSmoothing,
) -> FontAtlas {
  let nearest = match font_smoothing {
    FontSmoothing::None => true
    FontSmoothing::AntiAliased => false
  }
  let texture = @asset.asset_create_dynamic_texture(size, nearest)
  let texture_atlas = @asset.asset_add_texture_atlas_layout(
    @asset.TextureAtlasLayout::new_empty(size),
  )
  FontAtlas::{
    dynamic_texture_atlas_builder: @asset.DynamicTextureAtlasBuilder::new(
      size, 1,
    ),
    glyph_locations: [],
    texture_atlas,
    texture,
  }
}

///|
pub fn FontAtlas::get_glyph_index(
  self : FontAtlas,
  cache_key : GlyphCacheKey,
) -> GlyphAtlasLocation? {
  let count = self.glyph_locations.length()
  for i in 0..<count {
    let entry = self.glyph_locations[i]
    if glyph_cache_key_equals(entry.0, cache_key) {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn FontAtlas::has_glyph(
  self : FontAtlas,
  cache_key : GlyphCacheKey,
) -> Bool {
  self.get_glyph_index(cache_key) is Some(_)
}

///|
pub fn FontAtlas::add_glyph(
  self : FontAtlas,
  cache_key : GlyphCacheKey,
  raster : GlyphRaster,
) -> Bool {
  let layout = if @asset.asset_get_texture_atlas_layout(self.texture_atlas)
    is Some(value) {
    value
  } else {
    return false
  }
  let allocation = self.dynamic_texture_atlas_builder.add_texture(
    layout,
    raster.size,
  )
  if allocation is None {
    return false
  }
  let index = if allocation is Some(value) { value.0 } else { return false }
  let rect = if allocation is Some(value) { value.1 } else { return false }
  @asset.asset_set_texture_atlas_layout(self.texture_atlas, layout) |> ignore
  @asset.asset_update_texture_region(self.texture, rect, raster.id)
  self.glyph_locations.push(
    (
      cache_key,
      GlyphAtlasLocation::{ glyph_index: index, offset: raster.offset },
    ),
  )
  true
}

///|
pub fn get_glyph_atlas_info(
  atlases : Array[FontAtlas],
  cache_key : GlyphCacheKey,
) -> GlyphAtlasInfo? {
  let count = atlases.length()
  for i in 0..<count {
    let atlas = atlases[i]
    if atlas.get_glyph_index(cache_key) is Some(location) {
      return Some(GlyphAtlasInfo::{
        texture: atlas.texture,
        texture_atlas: atlas.texture_atlas,
        location,
      })
    }
  }
  None
}

///|
pub fn add_glyph_to_atlas(
  font_atlases : Array[FontAtlas],
  cache_key : GlyphCacheKey,
  raster : GlyphRaster,
  font_smoothing : FontSmoothing,
) -> GlyphAtlasInfo? {
  let count = font_atlases.length()
  for i in 0..<count {
    let atlas = font_atlases[i]
    if atlas.has_glyph(cache_key) {
      return get_glyph_atlas_info(font_atlases, cache_key)
    }
    if atlas.add_glyph(cache_key, raster) {
      font_atlases[i] = atlas
      return get_glyph_atlas_info(font_atlases, cache_key)
    }
  }
  let max_size = if raster.size.x > raster.size.y {
    raster.size.x
  } else {
    raster.size.y
  }
  let mut containing = 1
  while containing < max_size {
    containing = containing * 2
  }
  if containing < 512 {
    containing = 512
  }
  let new_atlas = FontAtlas::new(@math.UVec2::splat(containing), font_smoothing)
  if new_atlas.add_glyph(cache_key, raster) {
    font_atlases.push(new_atlas)
    return get_glyph_atlas_info(font_atlases, cache_key)
  }
  None
}
