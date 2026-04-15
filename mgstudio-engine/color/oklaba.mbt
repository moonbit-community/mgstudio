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
pub struct Oklaba {
  lightness : Float
  a : Float
  b : Float
  alpha : Float
}

///|
pub fn Oklaba::new(
  lightness : Float,
  a : Float,
  b : Float,
  alpha : Float,
) -> Oklaba {
  Oklaba::{ lightness, a, b, alpha: color_clamp_unit(alpha) }
}

///|
pub fn Oklaba::lab(lightness : Float, a : Float, b : Float) -> Oklaba {
  Oklaba::new(lightness, a, b, 1.0F)
}

///|
pub fn Oklaba::with_lightness(self : Oklaba, lightness : Float) -> Oklaba {
  Oklaba::new(lightness, self.a, self.b, self.alpha)
}

///|
pub fn Oklaba::with_a(self : Oklaba, a : Float) -> Oklaba {
  Oklaba::new(self.lightness, a, self.b, self.alpha)
}

///|
pub fn Oklaba::with_b(self : Oklaba, b : Float) -> Oklaba {
  Oklaba::new(self.lightness, self.a, b, self.alpha)
}

///|
pub fn Oklaba::mix(self : Oklaba, other : Oklaba, factor : Float) -> Oklaba {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Oklaba::new(
    self.lightness * inv + other.lightness * t,
    self.a * inv + other.a * t,
    self.b * inv + other.b * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Oklaba::luminance(self : Oklaba) -> Float {
  self.lightness
}

///|
pub fn Oklaba::with_luminance(self : Oklaba, lightness : Float) -> Oklaba {
  Oklaba::new(color_clamp_unit(lightness), self.a, self.b, self.alpha)
}

///|
pub fn Oklaba::darker(self : Oklaba, amount : Float) -> Oklaba {
  Oklaba::new(
    color_clamp_unit(self.lightness - color_clamp_unit(amount)),
    self.a,
    self.b,
    self.alpha,
  )
}

///|
pub fn Oklaba::lighter(self : Oklaba, amount : Float) -> Oklaba {
  Oklaba::new(
    color_clamp_unit(self.lightness + color_clamp_unit(amount)),
    self.a,
    self.b,
    self.alpha,
  )
}

///|
pub fn oklaba_from_linear_rgba(color : LinearRgba) -> Oklaba {
  let l = 0.41222146F * color.r + 0.53633255F * color.g + 0.051445995F * color.b
  let m = 0.2119035F * color.r + 0.6806995F * color.g + 0.10739696F * color.b
  let s = 0.08830246F * color.r + 0.28171885F * color.g + 0.6299787F * color.b
  let l_ = color_signed_cbrt(l)
  let m_ = color_signed_cbrt(m)
  let s_ = color_signed_cbrt(s)
  let lightness = 0.21045426F * l_ + 0.7936178F * m_ - 0.004072047F * s_
  let a = 1.9779985F * l_ - 2.4285922F * m_ + 0.4505937F * s_
  let b = 0.025904037F * l_ + 0.78277177F * m_ - 0.80867577F * s_
  Oklaba::new(lightness, a, b, color.a)
}

///|
pub fn linear_rgba_from_oklaba(color : Oklaba) -> LinearRgba {
  let l_ = color.lightness + 0.39633778F * color.a + 0.21580376F * color.b
  let m_ = color.lightness - 0.105561346F * color.a - 0.06385417F * color.b
  let s_ = color.lightness - 0.08948418F * color.a - 1.2914855F * color.b
  let l = l_ * l_ * l_
  let m = m_ * m_ * m_
  let s = s_ * s_ * s_
  let r = 4.0767417F * l - 3.3077116F * m + 0.23096994F * s
  let g = -1.268438F * l + 2.6097574F * m - 0.34131938F * s
  let b = -0.0041960863F * l - 0.7034186F * m + 1.7076147F * s
  linear_rgba_with_alpha(r, g, b, color.alpha)
}

///|
pub fn oklaba_from_color(color : Color) -> Oklaba {
  oklaba_from_linear_rgba(linear_rgba_from_color(color))
}

///|
pub fn oklaba_to_color(color : Oklaba) -> Color {
  linear_rgba_to_color(linear_rgba_from_oklaba(color))
}

///|
pub fn oklaba_gray(lightness : Float) -> Oklaba {
  Oklaba::new(color_clamp_unit(lightness), 0.0F, 0.0F, 1.0F)
}
