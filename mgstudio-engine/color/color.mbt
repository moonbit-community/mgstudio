// Copyright 2026 International Digital Economy Academy
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
pub struct Color {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
pub fn Color::new(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{ r, g, b, a }
}

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
fn color_wrap_hue(hue : Float) -> Float {
  let mut wrapped = hue
  while wrapped < 0.0F {
    wrapped = wrapped + 360.0F
  }
  while wrapped >= 360.0F {
    wrapped = wrapped - 360.0F
  }
  wrapped
}

///|
pub fn Color::srgb(r : Float, g : Float, b : Float) -> Color {
  Color::{
    r: color_srgb_to_linear(r),
    g: color_srgb_to_linear(g),
    b: color_srgb_to_linear(b),
    a: 1.0F,
  }
}

///|
pub fn Color::srgba(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{
    r: color_srgb_to_linear(r),
    g: color_srgb_to_linear(g),
    b: color_srgb_to_linear(b),
    a,
  }
}

///|
pub fn Color::hsla(
  hue : Float,
  saturation : Float,
  lightness : Float,
  alpha : Float,
) -> Color {
  let h = color_wrap_hue(hue)
  let s = color_clamp_unit(saturation)
  let l = color_clamp_unit(lightness)
  let a = color_clamp_unit(alpha)
  let chroma = (1.0F - color_abs(2.0F * l - 1.0F)) * s
  let m = l - chroma / 2.0F
  let (r1, g1, b1) = if h < 60.0F {
    let x = chroma * h / 60.0F
    (chroma, x, 0.0F)
  } else if h < 120.0F {
    let x = chroma * (1.0F - (h - 60.0F) / 60.0F)
    (x, chroma, 0.0F)
  } else if h < 180.0F {
    let x = chroma * (h - 120.0F) / 60.0F
    (0.0F, chroma, x)
  } else if h < 240.0F {
    let x = chroma * (1.0F - (h - 180.0F) / 60.0F)
    (0.0F, x, chroma)
  } else if h < 300.0F {
    let x = chroma * (h - 240.0F) / 60.0F
    (x, 0.0F, chroma)
  } else {
    let x = chroma * (1.0F - (h - 300.0F) / 60.0F)
    (chroma, 0.0F, x)
  }
  Color::srgba(
    color_clamp_unit(r1 + m),
    color_clamp_unit(g1 + m),
    color_clamp_unit(b1 + m),
    a,
  )
}

///|
pub fn Color::hsl(hue : Float, saturation : Float, lightness : Float) -> Color {
  Color::hsla(hue, saturation, lightness, 1.0F)
}

///|
pub fn Color::white() -> Color {
  Color::new(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
pub fn Color::black() -> Color {
  Color::new(0.0F, 0.0F, 0.0F, 1.0F)
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
pub impl ToJson for Color with to_json(self) {
  (self.r, self.g, self.b, self.a).to_json()
}

///|
pub impl @json.FromJson for Color with from_json(json, _path) {
  match (@json.from_json(json) catch { _ => None }) {
    Some((r, g, b, a)) => Color::new(r, g, b, a)
    None => {
      let values : Array[Float] = @json.from_json(json)
      if values.length() >= 4 {
        Color::new(values[0], values[1], values[2], values[3])
      } else if values.length() == 3 {
        Color::new(values[0], values[1], values[2], 1.0F)
      } else {
        Color::white()
      }
    }
  }
}
