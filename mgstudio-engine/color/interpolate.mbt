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
fn color_max3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a >= b { a } else { b }
  if ab >= c {
    ab
  } else {
    c
  }
}

///|
fn color_min3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a <= b { a } else { b }
  if ab <= c {
    ab
  } else {
    c
  }
}

///|
fn color_hue_from_srgb(
  r : Float,
  g : Float,
  b : Float,
  max_channel : Float,
  delta : Float,
) -> Float {
  if delta <= 0.0F {
    0.0F
  } else if max_channel == r {
    color_wrap_hue(60.0F * ((g - b) / delta))
  } else if max_channel == g {
    color_wrap_hue(60.0F * ((b - r) / delta + 2.0F))
  } else {
    color_wrap_hue(60.0F * ((r - g) / delta + 4.0F))
  }
}

///|
pub fn color_lerp_float(start : Float, end_ : Float, factor : Float) -> Float {
  let t = color_clamp_unit(factor)
  start + (end_ - start) * t
}

///|
pub fn color_lerp_hue(start : Float, end_ : Float, factor : Float) -> Float {
  let t = color_clamp_unit(factor)
  let diff = color_wrap_hue(end_ - start + 180.0F) - 180.0F
  color_wrap_hue(start + diff * t)
}

///|
pub fn color_lerp(start : Color, end_ : Color, factor : Float) -> Color {
  start.mix(end_, factor)
}
