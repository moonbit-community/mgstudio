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
// Bevy source: `bevy/crates/bevy_ui/src/geometry.rs`.
pub(all) enum Val {
  Auto
  Px(Float)
  Percent(Float)
  Vw(Float)
  Vh(Float)
  VMin(Float)
  VMax(Float)
} derive(Debug, ToJson, FromJson)

///|
pub(all) suberror ValParseError {
  UnitMissing
  ValueMissing
  InvalidValue
  InvalidUnit
}

///|
pub(all) suberror ValArithmeticError {
  NonEvaluable
}

///|
fn Val::numeric_payload(self : Val) -> Float? {
  match self {
    Auto => None
    Px(value)
    | Percent(value)
    | Vw(value)
    | Vh(value)
    | VMin(value)
    | VMax(value) => Some(value)
  }
}

///|
fn Val::same_unit_as(self : Val, other : Val) -> Bool {
  match (self, other) {
    (Auto, Auto)
    | (Px(_), Px(_))
    | (Percent(_), Percent(_))
    | (Vw(_), Vw(_))
    | (Vh(_), Vh(_))
    | (VMin(_), VMin(_))
    | (VMax(_), VMax(_)) => true
    _ => false
  }
}

///|
pub impl Eq for Val with equal(self, other) {
  let same_unit = self.same_unit_as(other)
  match (same_unit, self.numeric_payload(), other.numeric_payload()) {
    (true, None, None) => true
    (true, Some(left), Some(right)) => left == right
    (false, Some(left), Some(right)) => left == 0.0F && right == 0.0F
    _ => false
  }
}

///|
pub impl Eq for Val with not_equal(self, other) {
  !(self == other)
}

///|
pub fn Val::default() -> Val {
  Val::Auto
}

///|
pub fn Val::zero() -> Val {
  Val::Px(0.0F)
}

///|
fn val_is_number_char(code : Int) -> Bool {
  (code >= 48 && code <= 57) || code == 46 || code == 45 || code == 43
}

///|
pub fn Val::parse(input : String) -> Val raise ValParseError {
  let text = input.trim().to_owned()
  let lower = text.to_lower()
  if lower == "auto" {
    return Val::Auto
  }
  let mut end_of_number = -1
  for i in 0..<text.length() {
    if !val_is_number_char(text.code_unit_at(i).to_int()) {
      end_of_number = i
      break
    }
  }
  if end_of_number < 0 {
    raise ValParseError::UnitMissing
  }
  if end_of_number == 0 {
    raise ValParseError::ValueMissing
  }
  let value_text = text[0:end_of_number].to_owned()
  let value_double : Double = @strconv.from_str(value_text) catch {
    _ => raise ValParseError::InvalidValue
  }
  let value = Float::from_double(value_double)
  let unit = text[end_of_number:text.length()].trim().to_owned().to_lower()
  match unit {
    "px" => Val::Px(value)
    "%" => Val::Percent(value)
    "vw" => Val::Vw(value)
    "vh" => Val::Vh(value)
    "vmin" => Val::VMin(value)
    "vmax" => Val::VMax(value)
    _ => raise ValParseError::InvalidUnit
  }
}

///|
pub fn Val::left(self : Val) -> UiRect {
  UiRect::left(self)
}

///|
pub fn Val::right(self : Val) -> UiRect {
  UiRect::right(self)
}

///|
pub fn Val::top(self : Val) -> UiRect {
  UiRect::top(self)
}

///|
pub fn Val::bottom(self : Val) -> UiRect {
  UiRect::bottom(self)
}

///|
pub fn Val::all(self : Val) -> UiRect {
  UiRect::all(self)
}

///|
pub fn Val::horizontal(self : Val) -> UiRect {
  UiRect::horizontal(self)
}

///|
pub fn Val::vertical(self : Val) -> UiRect {
  UiRect::vertical(self)
}

///|
pub fn Val::mul(self : Val, rhs : Float) -> Val {
  match self {
    Auto => Auto
    Px(value) => Px(value * rhs)
    Percent(value) => Percent(value * rhs)
    Vw(value) => Vw(value * rhs)
    Vh(value) => Vh(value * rhs)
    VMin(value) => VMin(value * rhs)
    VMax(value) => VMax(value * rhs)
  }
}

///|
pub fn Val::div(self : Val, rhs : Float) -> Val {
  match self {
    Auto => Auto
    Px(value) => Px(value / rhs)
    Percent(value) => Percent(value / rhs)
    Vw(value) => Vw(value / rhs)
    Vh(value) => Vh(value / rhs)
    VMin(value) => VMin(value / rhs)
    VMax(value) => VMax(value / rhs)
  }
}

///|
pub fn Val::neg(self : Val) -> Val {
  match self {
    Auto => Auto
    Px(value) => Px(-value)
    Percent(value) => Percent(-value)
    Vw(value) => Vw(-value)
    Vh(value) => Vh(-value)
    VMin(value) => VMin(-value)
    VMax(value) => VMax(-value)
  }
}

///|
pub fn Val::resolve(
  self : Val,
  scale_factor : Float,
  physical_base_value : Float,
  physical_target_size : @math.Vec2,
) -> Float raise ValArithmeticError {
  match self {
    Auto => raise ValArithmeticError::NonEvaluable
    Percent(value) => physical_base_value * value / 100.0F
    Px(value) => value * scale_factor
    Vw(value) => physical_target_size.x * value / 100.0F
    Vh(value) => physical_target_size.y * value / 100.0F
    VMin(value) => {
      let size = if physical_target_size.x < physical_target_size.y {
        physical_target_size.x
      } else {
        physical_target_size.y
      }
      size * value / 100.0F
    }
    VMax(value) => {
      let size = if physical_target_size.x > physical_target_size.y {
        physical_target_size.x
      } else {
        physical_target_size.y
      }
      size * value / 100.0F
    }
  }
}

///|
pub fn auto() -> Val {
  Val::Auto
}

///|
pub fn px(value : Float) -> Val {
  Val::Px(value)
}

///|
pub fn percent(value : Float) -> Val {
  Val::Percent(value)
}

///|
pub fn vw(value : Float) -> Val {
  Val::Vw(value)
}

///|
pub fn vh(value : Float) -> Val {
  Val::Vh(value)
}

///|
pub fn vmin(value : Float) -> Val {
  Val::VMin(value)
}

///|
pub fn vmax(value : Float) -> Val {
  Val::VMax(value)
}

///|
pub(all) struct UiRect {
  left : Val
  right : Val
  top : Val
  bottom : Val
} derive(ToJson, FromJson)

///|
pub fn UiRect::new(left : Val, right : Val, top : Val, bottom : Val) -> UiRect {
  UiRect::{ left, right, top, bottom }
}

///|
pub fn UiRect::default() -> UiRect {
  UiRect::new(Val::Px(0.0F), Val::Px(0.0F), Val::Px(0.0F), Val::Px(0.0F))
}

///|
pub fn UiRect::all(value : Val) -> UiRect {
  UiRect::new(value, value, value, value)
}

///|
pub fn UiRect::px(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> UiRect {
  UiRect::new(Val::Px(left), Val::Px(right), Val::Px(top), Val::Px(bottom))
}

///|
pub fn UiRect::percent(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> UiRect {
  UiRect::new(
    Val::Percent(left),
    Val::Percent(right),
    Val::Percent(top),
    Val::Percent(bottom),
  )
}

///|
pub fn UiRect::horizontal(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), left: value, right: value }
}

///|
pub fn UiRect::vertical(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), top: value, bottom: value }
}

///|
pub fn UiRect::axes(horizontal : Val, vertical : Val) -> UiRect {
  UiRect::{
    left: horizontal,
    right: horizontal,
    top: vertical,
    bottom: vertical,
  }
}

///|
pub fn UiRect::left(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), left: value }
}

///|
pub fn UiRect::right(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), right: value }
}

///|
pub fn UiRect::top(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), top: value }
}

///|
pub fn UiRect::bottom(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), bottom: value }
}

///|
pub fn UiRect::with_left(self : UiRect, left : Val) -> UiRect {
  UiRect::{ ..self, left, }
}

///|
pub fn UiRect::with_right(self : UiRect, right : Val) -> UiRect {
  UiRect::{ ..self, right, }
}

///|
pub fn UiRect::with_top(self : UiRect, top : Val) -> UiRect {
  UiRect::{ ..self, top, }
}

///|
pub fn UiRect::with_bottom(self : UiRect, bottom : Val) -> UiRect {
  UiRect::{ ..self, bottom, }
}

///|
pub struct BorderRadius {
  top_left : Val
  top_right : Val
  bottom_right : Val
  bottom_left : Val
} derive(ToJson, FromJson)

///|
pub fn BorderRadius::default() -> BorderRadius {
  BorderRadius::{
    top_left: Val::Px(0.0F),
    top_right: Val::Px(0.0F),
    bottom_left: Val::Px(0.0F),
    bottom_right: Val::Px(0.0F),
  }
}

///|
pub fn BorderRadius::all(radius : Val) -> BorderRadius {
  BorderRadius::{
    top_left: radius,
    top_right: radius,
    bottom_right: radius,
    bottom_left: radius,
  }
}

///|
pub fn BorderRadius::new(
  top_left : Val,
  top_right : Val,
  bottom_right : Val,
  bottom_left : Val,
) -> BorderRadius {
  BorderRadius::{ top_left, top_right, bottom_right, bottom_left }
}

///|
pub fn BorderRadius::px(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Px(top_left),
    Val::Px(top_right),
    Val::Px(bottom_right),
    Val::Px(bottom_left),
  )
}

///|
pub fn BorderRadius::percent(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Percent(top_left),
    Val::Percent(top_right),
    Val::Percent(bottom_right),
    Val::Percent(bottom_left),
  )
}

///|
pub fn BorderRadius::top_left(radius : Val) -> BorderRadius {
  BorderRadius::{ ..BorderRadius::default(), top_left: radius }
}

///|
pub fn BorderRadius::top_right(radius : Val) -> BorderRadius {
  BorderRadius::{ ..BorderRadius::default(), top_right: radius }
}

///|
pub fn BorderRadius::bottom_right(radius : Val) -> BorderRadius {
  BorderRadius::{ ..BorderRadius::default(), bottom_right: radius }
}

///|
pub fn BorderRadius::bottom_left(radius : Val) -> BorderRadius {
  BorderRadius::{ ..BorderRadius::default(), bottom_left: radius }
}

///|
pub fn BorderRadius::left(radius : Val) -> BorderRadius {
  BorderRadius::{
    ..BorderRadius::default(),
    top_left: radius,
    bottom_left: radius,
  }
}

///|
pub fn BorderRadius::right(radius : Val) -> BorderRadius {
  BorderRadius::{
    ..BorderRadius::default(),
    top_right: radius,
    bottom_right: radius,
  }
}

///|
pub fn BorderRadius::top(radius : Val) -> BorderRadius {
  BorderRadius::{
    ..BorderRadius::default(),
    top_left: radius,
    top_right: radius,
  }
}

///|
pub fn BorderRadius::bottom(radius : Val) -> BorderRadius {
  BorderRadius::{
    ..BorderRadius::default(),
    bottom_left: radius,
    bottom_right: radius,
  }
}

///|
pub fn BorderRadius::with_top_left(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, top_left: radius }
}

///|
pub fn BorderRadius::with_top_right(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, top_right: radius }
}

///|
pub fn BorderRadius::with_bottom_right(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, bottom_right: radius }
}

///|
pub fn BorderRadius::with_bottom_left(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, bottom_left: radius }
}

///|
pub fn BorderRadius::with_left(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, top_left: radius, bottom_left: radius }
}

///|
pub fn BorderRadius::with_right(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, top_right: radius, bottom_right: radius }
}

///|
pub fn BorderRadius::with_top(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, top_left: radius, top_right: radius }
}

///|
pub fn BorderRadius::with_bottom(
  self : BorderRadius,
  radius : Val,
) -> BorderRadius {
  BorderRadius::{ ..self, bottom_left: radius, bottom_right: radius }
}

///|
pub fn BorderRadius::resolve_single_corner(
  radius : Val,
  scale_factor : Float,
  min_length : Float,
  viewport_size : @math.Vec2,
) -> Float {
  let raw = radius.resolve(scale_factor, min_length, viewport_size) catch {
    _ => 0.0F
  }
  raw.clamp(min=0.0F, max=0.5F * min_length)
}

///|
pub struct Outline {
  width : Val
  offset : Val
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn Outline::new(
  width : Val,
  offset : Val,
  color : @sprite.Color,
) -> Outline {
  Outline::{ width, offset, color }
}

///|
pub fn Outline::default() -> Outline {
  Outline::{
    width: Val::Px(0.0F),
    offset: Val::Px(0.0F),
    color: @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
  }
}

///|
pub struct BorderColor {
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn BorderColor::new(color : @sprite.Color) -> BorderColor {
  BorderColor::{ color, }
}
