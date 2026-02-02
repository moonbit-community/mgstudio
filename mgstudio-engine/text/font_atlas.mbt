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
  glyph_id : Int
  size : @math.UVec2
  offset : @math.IVec2
  pixels_rgba8 : Bytes
}

///|
priv struct SwashFontCacheEntry {
  font_id : Int
  font : @swash.FontRef
  charmap : @swash.Charmap
}

///|
priv struct SwashFontCache {
  entries : Array[SwashFontCacheEntry]
}

///|
let swash_font_cache : Ref[SwashFontCache] = Ref::new(SwashFontCache::{
  entries: [],
})

///|
let swash_scale_context : Ref[@swash_scale.ScaleContext] = Ref::new(
  @swash_scale.ScaleContext::new(),
)

///|
fn swash_get_font(
  font_handle : @asset.Handle[@asset.Font],
) -> SwashFontCacheEntry? {
  let entries = swash_font_cache.val.entries
  let n = entries.length()
  for i in 0..<n {
    if entries[i].font_id == font_handle.id() {
      return Some(entries[i])
    }
  }
  let bytes_opt = @asset.asset_font_read_bytes(font_handle)
  if bytes_opt is None {
    return None
  }
  let bytes = if bytes_opt is Some(b) { b } else { return None }
  let data_ref_opt = @swash.FontDataRef::new(bytes)
  if data_ref_opt is None {
    return None
  }
  let data_ref = if data_ref_opt is Some(v) { v } else { return None }
  let font_opt = data_ref.get(0)
  if font_opt is None {
    return None
  }
  let font = if font_opt is Some(v) { v } else { return None }
  let entry = SwashFontCacheEntry::{
    font_id: font_handle.id(),
    font,
    charmap: @swash.Charmap::from_font(font),
  }
  swash_font_cache.val.entries.push(entry)
  Some(entry)
}

///|
pub fn font_measure_advance(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  codepoint : Int,
) -> Float {
  let entry_opt = swash_get_font(font)
  if entry_opt is None {
    return 0.0F
  }
  let entry = if entry_opt is Some(v) { v } else { return 0.0F }
  let gid = entry.charmap.map(codepoint.reinterpret_as_uint()).to_int()
  let glyph_metrics = entry.font
    .glyph_metrics([].op_as_view())
    .scale(font_size.to_double())
  Float::from_double(glyph_metrics.advance_width(gid.to_uint16()))
}

///|
pub fn font_rasterize_glyph(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  codepoint : Int,
  smoothing : FontSmoothing,
) -> GlyphRaster? {
  let entry_opt = swash_get_font(font)
  if entry_opt is None {
    return None
  }
  let entry = if entry_opt is Some(v) { v } else { return None }
  let gid = entry.charmap.map(codepoint.reinterpret_as_uint())
  if gid.to_int() == 0 {
    return None
  }
  font_rasterize_glyph_id(font, font_size, gid.to_int(), smoothing)
}

///|
/// Rasterize a glyph by its glyph ID (already shaped).
///
/// This is required for complex shaping (ligatures, marks) where mapping from
/// codepoint -> glyph_id is not sufficient.
pub fn font_rasterize_glyph_id(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  glyph_id : Int,
  smoothing : FontSmoothing,
) -> GlyphRaster? {
  // Default to the "zero bin" for subpixel placement.
  font_rasterize_glyph_id_subpixel(font, font_size, glyph_id, smoothing, 0, 0)
}

///|
/// Rasterize a glyph with a subpixel cache key (cosmic-text compatible).
///
/// `subpixel_x/subpixel_y` are bin indices in [0..3], matching
/// `cosmic-text`/`moon_cosmic` (`Zero/One/Two/Three` → 0/1/2/3).
pub fn font_rasterize_glyph_id_subpixel(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  glyph_id : Int,
  smoothing : FontSmoothing,
  subpixel_x : Int,
  subpixel_y : Int,
) -> GlyphRaster? {
  fn subpixel_bin_as_double(bin : Int) -> Double {
    match bin {
      1 => 0.25
      2 => 0.5
      3 => 0.75
      _ => 0.0
    }
  }

  if glyph_id <= 0 || glyph_id > 0xFFFF {
    return None
  }
  let entry_opt = swash_get_font(font)
  if entry_opt is None {
    return None
  }
  let entry = if entry_opt is Some(v) { v } else { return None }
  let gid = glyph_id.to_uint16()
  let hint = match smoothing {
    FontSmoothing::None => false
    FontSmoothing::AntiAliased => true
  }
  let scaler = swash_scale_context.val
    .builder(entry.font)
    .size(font_size.to_double())
    .hint(hint)
    .build()
  let render = @swash_scale.Render::new([@swash_scale.Source::Outline]).offset(
    @moon_zeno.Vector::new(
      subpixel_bin_as_double(subpixel_x),
      subpixel_bin_as_double(subpixel_y),
    ),
  )
  let img_opt = render.render(scaler, gid)
  if img_opt is None {
    return None
  }
  let img = if img_opt is Some(v) { v } else { return None }
  // `placement()` comes from moon_zeno; we keep the explicit type so the
  // dependency is tracked and fields are accessible.
  let placement : @moon_zeno.Placement = img.placement()
  let width = placement.width.reinterpret_as_int()
  let height = placement.height.reinterpret_as_int()
  if width <= 0 || height <= 0 {
    return None
  }
  let pixel_count = width * height
  // Normalize all swash image formats (Mask/SubpixelMask/Color) into
  // premultiplied RGBA8 (bevy/cosmic-text compatible).
  let ok = img.to_rgba8([
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
  ])
  if !ok {
    return None
  }
  let pixels = img.data()
  // Defensive: ensure the size matches RGBA8.
  if pixels.length() != pixel_count * 4 {
    return None
  }
  Some(GlyphRaster::{
    glyph_id: gid.to_int(),
    size: @math.UVec2::new(width, height),
    offset: @math.IVec2::new(placement.left, placement.top),
    pixels_rgba8: pixels,
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
  @asset.asset_update_texture_region_rgba8(
    self.texture,
    rect,
    raster.pixels_rgba8,
  )
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
