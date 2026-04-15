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
pub struct Laba {
  lightness : Float
  a : Float
  b : Float
  alpha : Float
}

///|
fn laba_cie_epsilon() -> Float {
  216.0F / 24389.0F
}

///|
fn laba_cie_kappa() -> Float {
  24389.0F / 27.0F
}

///|
pub fn Laba::new(
  lightness : Float,
  a : Float,
  b : Float,
  alpha : Float,
) -> Laba {
  Laba::{ lightness, a, b, alpha: color_clamp_unit(alpha) }
}

///|
pub fn Laba::lab(lightness : Float, a : Float, b : Float) -> Laba {
  Laba::new(lightness, a, b, 1.0F)
}

///|
pub fn Laba::with_lightness(self : Laba, lightness : Float) -> Laba {
  Laba::new(lightness, self.a, self.b, self.alpha)
}

///|
pub fn Laba::luminance(self : Laba) -> Float {
  self.lightness
}

///|
pub fn Laba::with_luminance(self : Laba, lightness : Float) -> Laba {
  Laba::new(color_clamp_unit(lightness), self.a, self.b, self.alpha)
}

///|
pub fn Laba::darker(self : Laba, amount : Float) -> Laba {
  Laba::new(
    color_clamp_unit(self.lightness - color_clamp_unit(amount)),
    self.a,
    self.b,
    self.alpha,
  )
}

///|
pub fn Laba::lighter(self : Laba, amount : Float) -> Laba {
  Laba::new(
    color_clamp_unit(self.lightness + color_clamp_unit(amount)),
    self.a,
    self.b,
    self.alpha,
  )
}

///|
pub fn Laba::mix(self : Laba, other : Laba, factor : Float) -> Laba {
  let t = color_clamp_unit(factor)
  let inv = 1.0F - t
  Laba::new(
    self.lightness * inv + other.lightness * t,
    self.a * inv + other.a * t,
    self.b * inv + other.b * t,
    self.alpha * inv + other.alpha * t,
  )
}

///|
pub fn xyza_from_laba(color : Laba) -> Xyza {
  let l = 100.0F * color.lightness
  let a = 100.0F * color.a
  let b = 100.0F * color.b
  let fy = (l + 16.0F) / 116.0F
  let fx = a / 500.0F + fy
  let fz = fy - b / 200.0F
  let fx3 = @math.pow(fx, 3.0F)
  let xr = if fx3 > laba_cie_epsilon() {
    fx3
  } else {
    (116.0F * fx - 16.0F) / laba_cie_kappa()
  }
  let yr = if l > laba_cie_epsilon() * laba_cie_kappa() {
    @math.pow((l + 16.0F) / 116.0F, 3.0F)
  } else {
    l / laba_cie_kappa()
  }
  let fz3 = @math.pow(fz, 3.0F)
  let zr = if fz3 > laba_cie_epsilon() {
    fz3
  } else {
    (116.0F * fz - 16.0F) / laba_cie_kappa()
  }
  let white = xyza_d65_white()
  Xyza::new(xr * white.x, yr * white.y, zr * white.z, color.alpha)
}

///|
pub fn laba_from_xyza(color : Xyza) -> Laba {
  let white = xyza_d65_white()
  let xr = color.x / white.x
  let yr = color.y / white.y
  let zr = color.z / white.z
  let fx = if xr > laba_cie_epsilon() {
    color_signed_cbrt(xr)
  } else {
    (laba_cie_kappa() * xr + 16.0F) / 116.0F
  }
  let fy = if yr > laba_cie_epsilon() {
    color_signed_cbrt(yr)
  } else {
    (laba_cie_kappa() * yr + 16.0F) / 116.0F
  }
  let fz = if zr > laba_cie_epsilon() {
    color_signed_cbrt(zr)
  } else {
    (laba_cie_kappa() * zr + 16.0F) / 116.0F
  }
  let l = 1.16F * fy - 0.16F
  let a = 5.0F * (fx - fy)
  let b = 2.0F * (fy - fz)
  Laba::new(l, a, b, color.alpha)
}

///|
pub fn laba_from_color(color : Color) -> Laba {
  laba_from_xyza(xyza_from_color(color))
}

///|
pub fn laba_to_color(color : Laba) -> Color {
  xyza_to_color(xyza_from_laba(color))
}

///|
pub fn laba_gray(lightness : Float) -> Laba {
  Laba::new(color_clamp_unit(lightness), 0.0F, 0.0F, 1.0F)
}
