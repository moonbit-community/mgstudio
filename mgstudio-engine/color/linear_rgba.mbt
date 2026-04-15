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
pub type LinearRgba = Color

///|
fn color_srgb_to_linear(value : Float) -> Float {
  if value <= 0.0F {
    value
  } else if value <= 0.04045F {
    value / 12.92F
  } else {
    @math.pow((value + 0.055F) / 1.055F, 2.4F)
  }
}

///|
fn color_linear_to_srgb(value : Float) -> Float {
  let clamped = color_clamp_unit(value)
  if clamped <= 0.0031308F {
    clamped * 12.92F
  } else {
    1.055F * @math.pow(clamped, 1.0F / 2.4F) - 0.055F
  }
}

///|
fn color_signed_cbrt(value : Float) -> Float {
  if value < 0.0F {
    0.0F - @math.pow(0.0F - value, 1.0F / 3.0F)
  } else if value == 0.0F {
    0.0F
  } else {
    @math.pow(value, 1.0F / 3.0F)
  }
}

///|
pub fn linear_rgba(red : Float, green : Float, blue : Float) -> LinearRgba {
  Color::new(red, green, blue, 1.0F)
}

///|
pub fn linear_rgba_with_alpha(
  red : Float,
  green : Float,
  blue : Float,
  alpha : Float,
) -> LinearRgba {
  Color::new(red, green, blue, color_clamp_unit(alpha))
}

///|
pub fn linear_rgba_from_color(color : Color) -> LinearRgba {
  color
}

///|
pub fn linear_rgba_to_color(color : LinearRgba) -> Color {
  color
}

///|
pub fn Color::as_linear_rgba(self : Color) -> LinearRgba {
  self
}

///|
pub fn Color::to_linear_rgba_tuple(
  self : Color,
) -> (Float, Float, Float, Float) {
  (self.r, self.g, self.b, self.a)
}
