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
pub suberror ColorGradientError {
  NotEnoughStops(Int)
}

///|
pub struct ColorGradient {
  colors : Array[Color]
}

///|
pub fn ColorGradient::new(
  colors : Array[Color],
) -> ColorGradient raise ColorGradientError {
  if colors.length() < 2 {
    raise NotEnoughStops(colors.length())
  }
  ColorGradient::{ colors, }
}

///|
pub fn ColorGradient::length(self : ColorGradient) -> Int {
  self.colors.length()
}

///|
pub fn ColorGradient::at(self : ColorGradient, factor : Float) -> Color {
  let stop_count = self.colors.length()
  if stop_count == 0 {
    Color::white()
  } else if stop_count == 1 {
    self.colors[0]
  } else {
    let scaled = color_clamp_unit(factor) * Float::from_int(stop_count - 1)
    let lower_index = scaled.floor().to_int()
    let upper_index = if lower_index + 1 < stop_count {
      lower_index + 1
    } else {
      lower_index
    }
    if lower_index == upper_index {
      self.colors[lower_index]
    } else {
      let local_factor = scaled - Float::from_int(lower_index)
      self.colors[lower_index].mix(self.colors[upper_index], local_factor)
    }
  }
}
