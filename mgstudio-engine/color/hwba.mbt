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
pub struct Hwba {
  hue : Float
  whiteness : Float
  blackness : Float
  alpha : Float
}

///|
pub fn Hwba::new(
  hue : Float,
  whiteness : Float,
  blackness : Float,
  alpha : Float,
) -> Hwba {
  Hwba::{
    hue: color_wrap_hue(hue),
    whiteness: color_clamp_unit(whiteness),
    blackness: color_clamp_unit(blackness),
    alpha: color_clamp_unit(alpha),
  }
}

///|
pub fn Hwba::hwb(hue : Float, whiteness : Float, blackness : Float) -> Hwba {
  Hwba::new(hue, whiteness, blackness, 1.0F)
}

///|
pub fn Hwba::from_hsva(hsva : Hsva) -> Hwba {
  Hwba::new(
    hsva.hue,
    (1.0F - hsva.saturation) * hsva.value,
    1.0F - hsva.value,
    hsva.alpha,
  )
}

///|
pub fn Hwba::to_hsva(self : Hwba) -> Hsva {
  let value = 1.0F - self.blackness
  let saturation = if value <= 0.0F {
    0.0F
  } else {
    1.0F - self.whiteness / value
  }
  Hsva::new(self.hue, saturation, value, self.alpha)
}

///|
pub fn Hwba::to_color(self : Hwba) -> Color {
  let sum = self.whiteness + self.blackness
  if sum >= 1.0F {
    let gray = if sum <= 0.0F { 0.0F } else { self.whiteness / sum }
    Color::srgba(gray, gray, gray, self.alpha)
  } else {
    self.to_hsva().to_color()
  }
}

///|
pub fn Hwba::from_color(color : Color) -> Hwba {
  Hwba::from_hsva(color.to_hsva())
}

///|
pub fn Hwba::mix(self : Hwba, other : Hwba, factor : Float) -> Hwba {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Hwba::new(
    color_lerp_hue(self.hue, other.hue, t),
    self.whiteness * inv + other.whiteness * t,
    self.blackness * inv + other.blackness * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn Color::hwba(
  hue : Float,
  whiteness : Float,
  blackness : Float,
  alpha : Float,
) -> Color {
  Hwba::new(hue, whiteness, blackness, alpha).to_color()
}

///|
pub fn Color::hwb(hue : Float, whiteness : Float, blackness : Float) -> Color {
  Hwba::hwb(hue, whiteness, blackness).to_color()
}

///|
pub fn Color::to_hwba(self : Color) -> Hwba {
  Hwba::from_color(self)
}
