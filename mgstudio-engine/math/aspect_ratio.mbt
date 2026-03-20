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
pub(all) suberror AspectRatioError {
  Zero
  Infinite
  NaN
}

///|
pub struct AspectRatio {
  value : Float
}

///|
pub fn AspectRatio::sixteen_nine() -> AspectRatio {
  AspectRatio::{ value: 16.0F / 9.0F }
}

///|
pub fn AspectRatio::four_three() -> AspectRatio {
  AspectRatio::{ value: 4.0F / 3.0F }
}

///|
pub fn AspectRatio::ultrawide() -> AspectRatio {
  AspectRatio::{ value: 21.0F / 9.0F }
}

///|
pub fn AspectRatio::try_new(
  width : Float,
  height : Float,
) -> Result[AspectRatio, AspectRatioError] {
  if width == 0.0F || height == 0.0F {
    return Err(AspectRatioError::Zero)
  }
  if width.is_nan() || height.is_nan() {
    return Err(AspectRatioError::NaN)
  }
  if width.is_inf() || height.is_inf() {
    return Err(AspectRatioError::Infinite)
  }
  Ok(AspectRatio::{ value: width / height })
}

///|
pub fn AspectRatio::try_from_pixels(
  x : Int,
  y : Int,
) -> Result[AspectRatio, AspectRatioError] {
  AspectRatio::try_new(
    Float::from_double(x.to_double()),
    Float::from_double(y.to_double()),
  )
}

///|
pub fn AspectRatio::ratio(self : AspectRatio) -> Float {
  self.value
}

///|
pub fn AspectRatio::inverse(self : AspectRatio) -> AspectRatio {
  AspectRatio::{ value: 1.0F / self.value }
}

///|
pub fn AspectRatio::is_landscape(self : AspectRatio) -> Bool {
  self.value > 1.0F
}

///|
pub fn AspectRatio::is_portrait(self : AspectRatio) -> Bool {
  self.value < 1.0F
}

///|
pub fn AspectRatio::is_square(self : AspectRatio) -> Bool {
  self.value == 1.0F
}

///|
pub fn aspect_ratio_try_from_vec2(
  value : Vec2,
) -> Result[AspectRatio, AspectRatioError] {
  AspectRatio::try_new(value.x, value.y)
}
