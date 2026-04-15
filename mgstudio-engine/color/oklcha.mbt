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
pub struct Oklcha {
  lightness : Float
  chroma : Float
  hue : Float
  alpha : Float
}

///|
pub fn Oklcha::new(
  lightness : Float,
  chroma : Float,
  hue : Float,
  alpha : Float,
) -> Oklcha {
  Oklcha::{
    lightness,
    chroma: if chroma < 0.0F {
      0.0F
    } else {
      chroma
    },
    hue: color_wrap_hue(hue),
    alpha: color_clamp_unit(alpha),
  }
}

///|
pub fn Oklcha::lch(lightness : Float, chroma : Float, hue : Float) -> Oklcha {
  Oklcha::new(lightness, chroma, hue, 1.0F)
}

///|
pub fn Oklcha::with_lightness(self : Oklcha, lightness : Float) -> Oklcha {
  Oklcha::new(lightness, self.chroma, self.hue, self.alpha)
}

///|
pub fn Oklcha::with_chroma(self : Oklcha, chroma : Float) -> Oklcha {
  Oklcha::new(self.lightness, chroma, self.hue, self.alpha)
}

///|
pub fn Oklcha::sequential_dispersed(index : UInt) -> Oklcha {
  let frac_u32max_golden_ratio = 2654435769U
  let ratio_360 = 360.0F / Float::from_double(0xFFFF_FFFFU.to_double())
  let hue = Float::from_double((index * frac_u32max_golden_ratio).to_double()) *
    ratio_360
  Oklcha::lch(0.75F, 0.1F, hue)
}

///|
pub fn Oklcha::mix(self : Oklcha, other : Oklcha, factor : Float) -> Oklcha {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Oklcha::new(
    self.lightness * inv + other.lightness * t,
    self.chroma * inv + other.chroma * t,
    color_lerp_hue(self.hue, other.hue, t),
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Oklcha::luminance(self : Oklcha) -> Float {
  self.lightness
}

///|
pub fn Oklcha::with_luminance(self : Oklcha, lightness : Float) -> Oklcha {
  Oklcha::new(color_clamp_unit(lightness), self.chroma, self.hue, self.alpha)
}

///|
pub fn Oklcha::darker(self : Oklcha, amount : Float) -> Oklcha {
  Oklcha::new(
    color_clamp_unit(self.lightness - color_clamp_unit(amount)),
    self.chroma,
    self.hue,
    self.alpha,
  )
}

///|
pub fn Oklcha::lighter(self : Oklcha, amount : Float) -> Oklcha {
  Oklcha::new(
    color_clamp_unit(self.lightness + color_clamp_unit(amount)),
    self.chroma,
    self.hue,
    self.alpha,
  )
}

///|
pub fn oklcha_from_oklaba(color : Oklaba) -> Oklcha {
  let chroma = @math.sqrt(color.a * color.a + color.b * color.b)
  let mut hue = @math.atan2(color.b, color.a) * 180.0F / @math.pi()
  if hue < 0.0F {
    hue = hue + 360.0F
  }
  Oklcha::new(color.lightness, chroma, hue, color.alpha)
}

///|
pub fn oklaba_from_oklcha(color : Oklcha) -> Oklaba {
  let hue_radians = color.hue * @math.pi() / 180.0F
  let sinv = @math.sin(hue_radians)
  let cosv = @math.cos(hue_radians)
  let a = color.chroma * cosv
  let b = color.chroma * sinv
  Oklaba::new(color.lightness, a, b, color.alpha)
}

///|
pub fn oklcha_from_color(color : Color) -> Oklcha {
  oklcha_from_oklaba(oklaba_from_color(color))
}

///|
pub fn oklcha_to_color(color : Oklcha) -> Color {
  oklaba_to_color(oklaba_from_oklcha(color))
}

///|
pub fn oklcha_gray(lightness : Float) -> Oklcha {
  Oklcha::new(color_clamp_unit(lightness), 0.000000059604645F, 90.0F, 1.0F)
}
