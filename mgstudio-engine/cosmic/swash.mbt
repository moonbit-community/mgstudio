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
/// Swash rasterization cache (ported from `cosmic-text/src/swash.rs`).
///
/// This implementation uses `Milky2018/moon_swash/scale` directly.
fn Color::raw(self : Color) -> UInt {
  self.value
}

///|
fn f32_from_bits(bits : UInt) -> Float {
  Float::reinterpret_from_uint(bits)
}

///|
fn clamp_double(v : Double, lo : Double, hi : Double) -> Double {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn build_scaler(
  context : @scale.ScaleContext,
  font : @moon_swash.FontRef,
  cache_key : CacheKey,
) -> @scale.Scaler {
  let size = f32_from_bits(cache_key.font_size_bits).to_double()
  let mut builder = context.builder(font).size(size)
  builder = builder.hint(!cache_key.has_disable_hinting())

  // Apply variable font weight axis if present (upstream uses "wght").
  let wght_tag = @moon_swash.tag_from_str_lossy("wght")
  match font.variations().find_by_tag(wght_tag) {
    None => ()
    Some(variation) => {
      let weight = clamp_double(
        cache_key.font_weight.to_double(),
        variation.min_value(),
        variation.max_value(),
      )
      let settings : Array[@moon_swash.Setting[Double]] = [
        @moon_swash.Setting::new(wght_tag, weight),
      ]
      builder = builder.variations(settings[:])
    }
  }
  builder.build()
}

///|
fn swash_image(
  font_system : FontSystem,
  context : @scale.ScaleContext,
  cache_key : CacheKey,
) -> @scale.Image? {
  let font_opt = font_system.get_font(cache_key.font_id)
  let font = match font_opt {
    None => return None
    Some(f) => f
  }

  // Build scaler (with variable font weight axis when available).
  let scaler = build_scaler(context, font, cache_key)
  let offset = if cache_key.has_pixel_font() {
    // Quantize to pixel grid (x + 1 matches upstream).
    @scale.Vector::new(
      cache_key.x_bin.as_float().to_double().round() + 1.0,
      cache_key.y_bin.as_float().to_double().round(),
    )
  } else {
    @scale.Vector::new(
      cache_key.x_bin.as_float().to_double(),
      cache_key.y_bin.as_float().to_double(),
    )
  }

  // Renderer: for now prefer outline -> bitmap fallbacks are TODO.
  @scale.Render::new([
    @scale.Source::ColorOutline(0),
    @scale.Source::ColorBitmap(@scale.StrikeWith::BestFit),
    @scale.Source::Outline,
  ])
  .format(@scale.Format::Alpha)
  .offset(offset)
  .transform(
    if cache_key.has_fake_italic() {
      Some(
        @moon_zeno.Transform::skew(
          @moon_zeno.Angle::from_degrees(14.0),
          @moon_zeno.Angle::from_degrees(0.0),
        ),
      )
    } else {
      None
    },
  )
  .render(scaler, cache_key.glyph_id.to_uint16())
}

///|
fn swash_outline_path(
  font_system : FontSystem,
  context : @scale.ScaleContext,
  cache_key : CacheKey,
) -> (Array[@moon_zeno.Vector], Array[@moon_zeno.Verb])? {
  let font_opt = font_system.get_font(cache_key.font_id)
  let font = match font_opt {
    None => return None
    Some(f) => f
  }
  let scaler = build_scaler(context, font, cache_key)
  let outline_opt = match scaler.scale_outline(cache_key.glyph_id.to_uint16()) {
    None => scaler.scale_color_outline(cache_key.glyph_id.to_uint16())
    Some(o) => Some(o)
  }
  let outline = match outline_opt {
    None => return None
    Some(o) => o
  }
  if cache_key.has_fake_italic() {
    outline.transform(
      @moon_zeno.Transform::skew(
        @moon_zeno.Angle::from_degrees(14.0),
        @moon_zeno.Angle::from_degrees(0.0),
      ),
    )
  }
  Some(outline.path())
}

///|
pub struct SwashCache {
  context : @scale.ScaleContext
  image_cache : @hashmap.HashMap[CacheKey, @scale.Image?]
  outline_path_cache : @hashmap.HashMap[
    CacheKey,
    (Array[@moon_zeno.Vector], Array[@moon_zeno.Verb])?,
  ]
}

///|
pub fn SwashCache::new() -> SwashCache {
  SwashCache::{
    context: @scale.ScaleContext::new(),
    image_cache: @hashmap.HashMap::default(),
    outline_path_cache: @hashmap.HashMap::default(),
  }
}

///|
pub fn SwashCache::get_image_uncached(
  self : SwashCache,
  font_system : FontSystem,
  cache_key : CacheKey,
) -> @scale.Image? {
  swash_image(font_system, self.context, cache_key)
}

///|
pub fn SwashCache::get_image(
  self : SwashCache,
  font_system : FontSystem,
  cache_key : CacheKey,
) -> @scale.Image? {
  match self.image_cache.get(cache_key) {
    Some(v) => v
    None => {
      let img = swash_image(font_system, self.context, cache_key)
      self.image_cache.set(cache_key, img)
      img
    }
  }
}

///|
/// Create outline commands (path data) from a cache key, without caching results.
///
/// This matches upstream `SwashCache::get_outline_commands_uncached`.
pub fn SwashCache::get_outline_commands_uncached(
  self : SwashCache,
  font_system : FontSystem,
  cache_key : CacheKey,
) -> (Array[@moon_zeno.Vector], Array[@moon_zeno.Verb])? {
  swash_outline_path(font_system, self.context, cache_key)
}

///|
/// Create outline commands (path data) from a cache key, caching results.
///
/// This matches upstream `SwashCache::get_outline_commands`.
pub fn SwashCache::get_outline_commands(
  self : SwashCache,
  font_system : FontSystem,
  cache_key : CacheKey,
) -> (Array[@moon_zeno.Vector], Array[@moon_zeno.Verb])? {
  match self.outline_path_cache.get(cache_key) {
    Some(v) => v
    None => {
      let path = swash_outline_path(font_system, self.context, cache_key)
      self.outline_path_cache.set(cache_key, path)
      path
    }
  }
}

///|
/// Enumerate pixels in a cached glyph image.
pub fn SwashCache::with_pixels(
  self : SwashCache,
  font_system : FontSystem,
  cache_key : CacheKey,
  base : Color,
  f : (Int, Int, Color) -> Unit,
) -> Unit {
  match self.get_image(font_system, cache_key) {
    None => ()
    Some(image) => {
      let placement = image.placement()
      let x0 = placement.left
      let y0 = -placement.top
      let width = placement.width.reinterpret_as_int()
      let height = placement.height.reinterpret_as_int()
      let data = image.data()
      match image.content() {
        Mask => {
          let mut i = 0
          for off_y in 0..<height {
            for off_x in 0..<width {
              let a = if data.get(i) is Some(v) { v } else { 0x00 }
              // TODO: blend base alpha.
              let color = Color::{
                value: (a.to_int().reinterpret_as_uint() << 24) |
                (base.raw() & 0x00FF_FFFF),
              }
              f(x0 + off_x, y0 + off_y, color)
              i = i + 1
            }
          }
        }
        Color => {
          let mut i = 0
          for off_y in 0..<height {
            for off_x in 0..<width {
              let r = if data.get(i) is Some(v) { v } else { 0x00 }
              let g = if data.get(i + 1) is Some(v) { v } else { 0x00 }
              let b = if data.get(i + 2) is Some(v) { v } else { 0x00 }
              let a = if data.get(i + 3) is Some(v) { v } else { 0x00 }
              f(x0 + off_x, y0 + off_y, Color::rgba(r, g, b, a))
              i = i + 4
            }
          }
        }
        SubpixelMask =>
          // TODO
          ()
      }
    }
  }
}
