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
fn color_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn color_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn color_luminance(color : Color) -> Float {
  color.r * 0.2126F + color.g * 0.7152F + color.b * 0.0722F
}

///|
fn color_mix(a : Color, b : Color, factor : Float) -> Color {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Color::new(
    a.r * inv + b.r * t,
    a.g * inv + b.g * t,
    a.b * inv + b.b * t,
    a.a * inv + b.a * t,
  )
}

///|
pub fn Color::alpha(self : Color) -> Float {
  self.a
}

///|
pub fn Color::with_alpha(self : Color, alpha : Float) -> Color {
  Color::new(self.r, self.g, self.b, color_clamp_unit(alpha))
}

///|
pub fn Color::luminance(self : Color) -> Float {
  color_luminance(self)
}

///|
pub fn Color::mix(self : Color, other : Color, factor : Float) -> Color {
  color_mix(self, other, factor)
}

///|
pub fn Color::darker(self : Color, amount : Float) -> Color {
  let luminance = color_luminance(self)
  let target_luminance = color_clamp_unit(luminance - color_clamp_unit(amount))
  if target_luminance >= luminance || luminance <= 0.0F {
    self
  } else {
    let adjustment = color_clamp_unit(
      (luminance - target_luminance) / luminance,
    )
    color_mix(self, Color::new(0.0F, 0.0F, 0.0F, self.a), adjustment)
  }
}

///|
pub fn Color::lighter(self : Color, amount : Float) -> Color {
  let luminance = color_luminance(self)
  let target_luminance = color_clamp_unit(luminance + color_clamp_unit(amount))
  if target_luminance <= luminance || luminance >= 1.0F {
    self
  } else {
    let remaining = 1.0F - luminance
    if remaining <= 0.0F {
      self
    } else {
      let adjustment = color_clamp_unit(
        (target_luminance - luminance) / remaining,
      )
      color_mix(self, Color::new(1.0F, 1.0F, 1.0F, self.a), adjustment)
    }
  }
}

///|
pub fn Color::is_fully_transparent(self : Color) -> Bool {
  self.a <= 0.0F
}

///|
pub fn Color::is_fully_opaque(self : Color) -> Bool {
  self.a >= 1.0F
}
