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
pub struct GlyphAtlasLocation {
  glyph_index : Int
  offset : @math.IVec2
}

///|
pub struct GlyphAtlasInfo {
  texture : @asset.Handle[@asset.Image]
  texture_atlas : @asset.Handle[@asset.TextureAtlasLayout]
  location : GlyphAtlasLocation
}

///|
pub struct PositionedGlyph {
  position : @math.Vec2
  size : @math.Vec2
  atlas_info : GlyphAtlasInfo
  span_index : Int
  line_index : Int
  byte_index : Int
  byte_length : Int
}

///|
pub struct RunGeometry {
  span_index : Int
  bounds : @math.Rect
  strikethrough_y : Float
  strikethrough_thickness : Float
  underline_y : Float
  underline_thickness : Float
}

///|
pub fn RunGeometry::strikethrough_position(self : RunGeometry) -> @math.Vec2 {
  @math.Vec2::new(
    self.bounds.center().x,
    self.strikethrough_y + 0.5F * self.strikethrough_thickness,
  )
}

///|
pub fn RunGeometry::strikethrough_size(self : RunGeometry) -> @math.Vec2 {
  @math.Vec2::new(self.bounds.size().x, self.strikethrough_thickness)
}

///|
pub fn RunGeometry::underline_position(self : RunGeometry) -> @math.Vec2 {
  @math.Vec2::new(
    self.bounds.center().x,
    self.underline_y + 0.5F * self.underline_thickness,
  )
}

///|
pub fn RunGeometry::underline_size(self : RunGeometry) -> @math.Vec2 {
  @math.Vec2::new(self.bounds.size().x, self.underline_thickness)
}

///|
pub struct TextLayoutInfo {
  scale_factor : Float
  glyphs : Array[PositionedGlyph]
  run_geometry : Array[RunGeometry]
  size : @math.Vec2
}

///|
pub fn TextLayoutInfo::default() -> TextLayoutInfo {
  TextLayoutInfo::{
    scale_factor: 1.0F,
    glyphs: [],
    run_geometry: [],
    size: @math.Vec2::new(0.0F, 0.0F),
  }
}

///|
pub fn TextLayoutInfo::clear(self : TextLayoutInfo) -> TextLayoutInfo {
  self |> ignore
  TextLayoutInfo::default()
}
