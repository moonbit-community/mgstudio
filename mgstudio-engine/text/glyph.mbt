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
// Bevy source: `bevy/crates/bevy_text/src/glyph.rs`.
// Runtime wrappers live in this file while the broader text implementation stays split across the package.

///|
pub fn text_measure_glyph_advance(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  codepoint : Int,
) -> Float {
  font_measure_advance(font, font_size, codepoint)
}

///|
pub fn text_rasterize_glyph(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  codepoint : Int,
  smoothing : FontSmoothing,
) -> GlyphRaster? {
  font_rasterize_glyph(font, font_size, codepoint, smoothing)
}
