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
pub struct Lcha {
  lightness : Float
  chroma : Float
  hue : Float
  alpha : Float
}

///|
pub fn Lcha::new(
  lightness : Float,
  chroma : Float,
  hue : Float,
  alpha : Float,
) -> Lcha {
  Lcha::{
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
pub fn Lcha::lch(lightness : Float, chroma : Float, hue : Float) -> Lcha {
  Lcha::new(lightness, chroma, hue, 1.0F)
}

///|
pub fn Lcha::with_chroma(self : Lcha, chroma : Float) -> Lcha {
  Lcha::new(self.lightness, chroma, self.hue, self.alpha)
}

///|
pub fn Lcha::with_lightness(self : Lcha, lightness : Float) -> Lcha {
  Lcha::new(lightness, self.chroma, self.hue, self.alpha)
}

///|
pub fn Lcha::sequential_dispersed(index : UInt) -> Lcha {
  let frac_u32max_golden_ratio = 2654435769U
  let ratio_360 = 360.0F / Float::from_double(0xFFFF_FFFFU.to_double())
  let hue = Float::from_double((index * frac_u32max_golden_ratio).to_double()) *
    ratio_360
  Lcha::lch(0.75F, 0.35F, hue)
}

///|
pub fn Lcha::mix(self : Lcha, other : Lcha, factor : Float) -> Lcha {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Lcha::new(
    self.lightness * inv + other.lightness * t,
    self.chroma * inv + other.chroma * t,
    color_lerp_hue(self.hue, other.hue, t),
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Lcha::luminance(self : Lcha) -> Float {
  self.lightness
}

///|
pub fn Lcha::with_luminance(self : Lcha, lightness : Float) -> Lcha {
  Lcha::new(color_clamp_unit(lightness), self.chroma, self.hue, self.alpha)
}

///|
pub fn Lcha::darker(self : Lcha, amount : Float) -> Lcha {
  Lcha::new(
    color_clamp_unit(self.lightness - color_clamp_unit(amount)),
    self.chroma,
    self.hue,
    self.alpha,
  )
}

///|
pub fn Lcha::lighter(self : Lcha, amount : Float) -> Lcha {
  Lcha::new(
    color_clamp_unit(self.lightness + color_clamp_unit(amount)),
    self.chroma,
    self.hue,
    self.alpha,
  )
}

///|
pub fn laba_from_lcha(color : Lcha) -> Laba {
  let hue_radians = color.hue * @math.pi() / 180.0F
  let sinv = @math.sin(hue_radians)
  let cosv = @math.cos(hue_radians)
  let a = color.chroma * cosv
  let b = color.chroma * sinv
  Laba::new(color.lightness, a, b, color.alpha)
}

///|
pub fn lcha_from_laba(color : Laba) -> Lcha {
  let chroma = @math.sqrt(color.a * color.a + color.b * color.b)
  let mut hue = @math.atan2(color.b, color.a) * 180.0F / @math.pi()
  if hue < 0.0F {
    hue = hue + 360.0F
  }
  let clamped_chroma = if chroma < 0.0F {
    0.0F
  } else if chroma > 1.5F {
    1.5F
  } else {
    chroma
  }
  Lcha::new(color.lightness, clamped_chroma, hue, color.alpha)
}

///|
pub fn lcha_from_color(color : Color) -> Lcha {
  lcha_from_laba(laba_from_color(color))
}

///|
pub fn lcha_to_color(color : Lcha) -> Color {
  laba_to_color(laba_from_lcha(color))
}

///|
pub fn lcha_gray(lightness : Float) -> Lcha {
  Lcha::new(color_clamp_unit(lightness), 0.0F, 0.0000136603785F, 1.0F)
}
