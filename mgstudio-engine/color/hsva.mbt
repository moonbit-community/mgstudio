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
pub struct Hsva {
  hue : Float
  saturation : Float
  value : Float
  alpha : Float
}

///|
pub fn Hsva::new(
  hue : Float,
  saturation : Float,
  value : Float,
  alpha : Float,
) -> Hsva {
  Hsva::{
    hue: color_wrap_hue(hue),
    saturation: color_clamp_unit(saturation),
    value: color_clamp_unit(value),
    alpha: color_clamp_unit(alpha),
  }
}

///|
pub fn Hsva::hsv(hue : Float, saturation : Float, value : Float) -> Hsva {
  Hsva::new(hue, saturation, value, 1.0F)
}

///|
pub fn Hsva::to_color(self : Hsva) -> Color {
  let chroma = self.value * self.saturation
  let h = self.hue / 60.0F
  let x = chroma * (1.0F - color_abs(h % 2.0F - 1.0F))
  let m = self.value - chroma
  let (r1, g1, b1) = if h < 1.0F {
    (chroma, x, 0.0F)
  } else if h < 2.0F {
    (x, chroma, 0.0F)
  } else if h < 3.0F {
    (0.0F, chroma, x)
  } else if h < 4.0F {
    (0.0F, x, chroma)
  } else if h < 5.0F {
    (x, 0.0F, chroma)
  } else {
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
pub fn Hsva::from_color(color : Color) -> Hsva {
  let (r, g, b, a) = color.to_srgba_tuple()
  let max_channel = color_max3(r, g, b)
  let min_channel = color_min3(r, g, b)
  let delta = max_channel - min_channel
  let saturation = if max_channel <= 0.0F { 0.0F } else { delta / max_channel }
  let hue = color_hue_from_srgb(r, g, b, max_channel, delta)
  Hsva::new(hue, saturation, max_channel, a)
}

///|
pub fn Hsva::mix(self : Hsva, other : Hsva, factor : Float) -> Hsva {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Hsva::new(
    color_lerp_hue(self.hue, other.hue, t),
    self.saturation * inv + other.saturation * t,
    self.value * inv + other.value * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Color::hsva(
  hue : Float,
  saturation : Float,
  value : Float,
  alpha : Float,
) -> Color {
  Hsva::new(hue, saturation, value, alpha).to_color()
}

///|
pub fn Color::hsv(hue : Float, saturation : Float, value : Float) -> Color {
  Hsva::hsv(hue, saturation, value).to_color()
}

///|
pub fn Color::to_hsva(self : Color) -> Hsva {
  Hsva::from_color(self)
}
