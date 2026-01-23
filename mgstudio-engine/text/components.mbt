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
pub struct Text2d {
  content : String
}

///|
pub fn Text2d::new(content : String) -> Text2d {
  Text2d::{ content, }
}

///|
pub struct TextSpan {
  content : String
}

///|
pub fn TextSpan::new(content : String) -> TextSpan {
  TextSpan::{ content, }
}

///|
pub(all) enum Justify {
  Left
  Center
  Right
  Justified
}

///|
pub(all) enum LineBreak {
  WordBoundary
  AnyCharacter
  WordOrCharacter
  NoWrap
}

///|
pub struct TextLayout {
  justify : Justify
  linebreak : LineBreak
}

///|
pub fn TextLayout::default() -> TextLayout {
  TextLayout::{ justify: Justify::Left, linebreak: LineBreak::WordBoundary }
}

///|
pub fn TextLayout::new(justify : Justify, linebreak : LineBreak) -> TextLayout {
  TextLayout::{ justify, linebreak }
}

///|
pub fn TextLayout::new_with_justify(justify : Justify) -> TextLayout {
  TextLayout::{ ..TextLayout::default(), justify, }
}

///|
pub fn TextLayout::new_with_linebreak(linebreak : LineBreak) -> TextLayout {
  TextLayout::{ ..TextLayout::default(), linebreak, }
}

///|
pub fn TextLayout::new_with_no_wrap() -> TextLayout {
  TextLayout::new_with_linebreak(LineBreak::NoWrap)
}

///|
pub fn TextLayout::with_justify(
  self : TextLayout,
  justify : Justify,
) -> TextLayout {
  TextLayout::{ ..self, justify, }
}

///|
pub fn TextLayout::with_linebreak(
  self : TextLayout,
  linebreak : LineBreak,
) -> TextLayout {
  TextLayout::{ ..self, linebreak, }
}

///|
pub fn TextLayout::with_no_wrap(self : TextLayout) -> TextLayout {
  TextLayout::{ ..self, linebreak: LineBreak::NoWrap }
}

///|
pub(all) enum FontSmoothing {
  None
  AntiAliased
}

///|
pub struct TextFont {
  font : @asset.Handle[@asset.Font]
  font_size : Float
  font_smoothing : FontSmoothing
}

///|
pub fn TextFont::default() -> TextFont {
  TextFont::{
    font: @asset.Handle::new(-1),
    font_size: 20.0F,
    font_smoothing: FontSmoothing::AntiAliased,
  }
}

///|
pub fn TextFont::with_font(
  self : TextFont,
  font : @asset.Handle[@asset.Font],
) -> TextFont {
  TextFont::{ ..self, font, }
}

///|
pub fn TextFont::with_font_size(self : TextFont, font_size : Float) -> TextFont {
  TextFont::{ ..self, font_size, }
}

///|
pub fn TextFont::with_font_smoothing(
  self : TextFont,
  font_smoothing : FontSmoothing,
) -> TextFont {
  TextFont::{ ..self, font_smoothing, }
}

///|
pub struct TextColor {
  color : @render2d.Color
}

///|
pub fn TextColor::new(color : @render2d.Color) -> TextColor {
  TextColor::{ color, }
}

///|
pub fn TextColor::default() -> TextColor {
  TextColor::new(@render2d.Color::white())
}

///|
pub(all) enum LineHeight {
  Px(Float)
  RelativeToFont(Float)
}

///|
pub fn LineHeight::default() -> LineHeight {
  LineHeight::RelativeToFont(1.2F)
}

///|
pub fn LineHeight::eval(self : LineHeight, font_size : Float) -> Float {
  match self {
    Px(value) => value
    RelativeToFont(scale) => scale * font_size
  }
}

///|
pub struct TextBounds {
  width : Float?
  height : Float?
}

///|
pub fn TextBounds::default() -> TextBounds {
  TextBounds::{ width: None, height: None }
}

///|
pub fn TextBounds::new(width : Float, height : Float) -> TextBounds {
  TextBounds::{ width: Some(width), height: Some(height) }
}

///|
pub fn TextBounds::new_horizontal(width : Float) -> TextBounds {
  TextBounds::{ width: Some(width), height: None }
}

///|
pub fn TextBounds::new_vertical(height : Float) -> TextBounds {
  TextBounds::{ width: None, height: Some(height) }
}

///|
pub struct Text2dShadow {
  offset : @math.Vec2
  color : @render2d.Color
}

///|
pub fn Text2dShadow::default() -> Text2dShadow {
  Text2dShadow::{
    offset: @math.Vec2::new(4.0F, -4.0F),
    color: @render2d.Color::black(),
  }
}
