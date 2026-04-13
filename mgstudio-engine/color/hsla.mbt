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
pub struct Hsla {
  hue : Float
  saturation : Float
  lightness : Float
  alpha : Float
}

///|
pub fn Hsla::new(
  hue : Float,
  saturation : Float,
  lightness : Float,
  alpha : Float,
) -> Hsla {
  Hsla::{
    hue: color_wrap_hue(hue),
    saturation: color_clamp_unit(saturation),
    lightness: color_clamp_unit(lightness),
    alpha: color_clamp_unit(alpha),
  }
}

///|
pub fn Hsla::hsl(hue : Float, saturation : Float, lightness : Float) -> Hsla {
  Hsla::new(hue, saturation, lightness, 1.0F)
}

///|
pub fn Hsla::to_color(self : Hsla) -> Color {
  let chroma = (1.0F - color_abs(2.0F * self.lightness - 1.0F)) *
    self.saturation
  let m = self.lightness - chroma / 2.0F
  let (r1, g1, b1) = if self.hue < 60.0F {
    let x = chroma * self.hue / 60.0F
    (chroma, x, 0.0F)
  } else if self.hue < 120.0F {
    let x = chroma * (1.0F - (self.hue - 60.0F) / 60.0F)
    (x, chroma, 0.0F)
  } else if self.hue < 180.0F {
    let x = chroma * (self.hue - 120.0F) / 60.0F
    (0.0F, chroma, x)
  } else if self.hue < 240.0F {
    let x = chroma * (1.0F - (self.hue - 180.0F) / 60.0F)
    (0.0F, x, chroma)
  } else if self.hue < 300.0F {
    let x = chroma * (self.hue - 240.0F) / 60.0F
    (x, 0.0F, chroma)
  } else {
    let x = chroma * (1.0F - (self.hue - 300.0F) / 60.0F)
    (chroma, 0.0F, x)
  }
  Color::srgba(
    color_clamp_unit(r1 + m),
    color_clamp_unit(g1 + m),
    color_clamp_unit(b1 + m),
    self.alpha,
  )
}

///|
pub fn Hsla::from_color(color : Color) -> Hsla {
  let (r, g, b, a) = color.to_srgba_tuple()
  let max_channel = color_max3(r, g, b)
  let min_channel = color_min3(r, g, b)
  let delta = max_channel - min_channel
  let lightness = (max_channel + min_channel) / 2.0F
  let saturation = if delta <= 0.0F {
    0.0F
  } else {
    delta / (1.0F - color_abs(2.0F * lightness - 1.0F))
  }
  let hue = color_hue_from_srgb(r, g, b, max_channel, delta)
  Hsla::new(hue, saturation, lightness, a)
}

///|
pub fn Hsla::mix(self : Hsla, other : Hsla, factor : Float) -> Hsla {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Hsla::new(
    color_lerp_hue(self.hue, other.hue, t),
    self.saturation * inv + other.saturation * t,
    self.lightness * inv + other.lightness * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Color::hsla(
  hue : Float,
  saturation : Float,
  lightness : Float,
  alpha : Float,
) -> Color {
  Hsla::new(hue, saturation, lightness, alpha).to_color()
}

///|
pub fn Color::hsl(hue : Float, saturation : Float, lightness : Float) -> Color {
  Hsla::hsl(hue, saturation, lightness).to_color()
}

///|
pub fn Color::to_hsla(self : Color) -> Hsla {
  Hsla::from_color(self)
}
