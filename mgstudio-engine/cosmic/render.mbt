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
/// Helpers for rendering buffers and editors.
///
/// Ported from `cosmic-text/src/render.rs`.

///|
/// Custom renderer for buffers and editors.
pub(open) trait Renderer {
  /// Render a rectangle at x, y with size w, h and the provided `Color`.
  rectangle(Self, x : Int, y : Int, w : UInt, h : UInt, color : Color) -> Unit

  /// Render a `PhysicalGlyph` with the provided `Color`.
  ///
  /// For performance, consider using `SwashCache` directly.
  glyph(Self, physical_glyph : PhysicalGlyph, color : Color) -> Unit
}

///|
/// Helper to migrate from the legacy callback-based renderer.
///
/// This matches upstream `LegacyRenderer`: rectangles are forwarded to the callback,
/// and glyphs are rasterized through `SwashCache::with_pixels`.
pub struct LegacyRenderer {
  font_system : FontSystem
  cache : SwashCache
  callback : (Int, Int, UInt, UInt, Color) -> Unit
}

///|
pub fn LegacyRenderer::new(
  font_system : FontSystem,
  cache : SwashCache,
  callback : (Int, Int, UInt, UInt, Color) -> Unit,
) -> LegacyRenderer {
  LegacyRenderer::{ font_system, cache, callback }
}

///|
pub impl Renderer for LegacyRenderer with rectangle(self, x, y, w, h, color) {
  (self.callback)(x, y, w, h, color)
}

///|
pub impl Renderer for LegacyRenderer with glyph(self, physical_glyph, color) {
  self.cache.with_pixels(self.font_system, physical_glyph.cache_key, color, fn(
    px,
    py,
    pixel_color,
  ) {
    (self.callback)(
      physical_glyph.x + px,
      physical_glyph.y + py,
      1U,
      1U,
      pixel_color,
    )
  })
}
