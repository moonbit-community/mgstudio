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
pub struct Xyza {
  x : Float
  y : Float
  z : Float
  alpha : Float
}

///|
pub fn Xyza::new(x : Float, y : Float, z : Float, alpha : Float) -> Xyza {
  Xyza::{ x, y, z, alpha: color_clamp_unit(alpha) }
}

///|
pub fn Xyza::xyz(x : Float, y : Float, z : Float) -> Xyza {
  Xyza::new(x, y, z, 1.0F)
}

///|
pub fn xyza_d65_white() -> Xyza {
  Xyza::xyz(0.95047F, 1.0F, 1.08883F)
}

///|
pub fn Xyza::luminance(self : Xyza) -> Float {
  self.y
}

///|
pub fn Xyza::with_luminance(self : Xyza, lightness : Float) -> Xyza {
  Xyza::new(self.x, color_clamp_unit(lightness), self.z, self.alpha)
}

///|
pub fn Xyza::darker(self : Xyza, amount : Float) -> Xyza {
  Xyza::new(
    self.x,
    color_clamp_unit(self.y - color_clamp_unit(amount)),
    self.z,
    self.alpha,
  )
}

///|
pub fn Xyza::lighter(self : Xyza, amount : Float) -> Xyza {
  Xyza::new(
    self.x,
    color_clamp_unit(self.y + color_clamp_unit(amount)),
    self.z,
    self.alpha,
  )
}

///|
pub fn Xyza::mix(self : Xyza, other : Xyza, factor : Float) -> Xyza {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Xyza::new(
    self.x * inv + other.x * t,
    self.y * inv + other.y * t,
    self.z * inv + other.z * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn xyza_from_linear_rgba(color : LinearRgba) -> Xyza {
  let x = color.r * 0.4124564F + color.g * 0.3575761F + color.b * 0.1804375F
  let y = color.r * 0.2126729F + color.g * 0.7151522F + color.b * 0.072175F
  let z = color.r * 0.0193339F + color.g * 0.119192F + color.b * 0.9503041F
  Xyza::new(x, y, z, color.a)
}

///|
pub fn linear_rgba_from_xyza(color : Xyza) -> LinearRgba {
  let r = color.x * 3.2404542F + color.y * -1.5371385F + color.z * -0.4985314F
  let g = color.x * -0.969266F + color.y * 1.8760108F + color.z * 0.041556F
  let b = color.x * 0.0556434F + color.y * -0.2040259F + color.z * 1.0572252F
  linear_rgba_with_alpha(r, g, b, color.alpha)
}

///|
pub fn xyza_from_color(color : Color) -> Xyza {
  xyza_from_linear_rgba(linear_rgba_from_color(color))
}

///|
pub fn xyza_to_color(color : Xyza) -> Color {
  linear_rgba_to_color(linear_rgba_from_xyza(color))
}

///|
pub fn xyza_gray(lightness : Float) -> Xyza {
  let t = color_clamp_unit(lightness)
  Xyza::new(0.95047F * t, t, 1.08883F * t, 1.0F)
}
