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
pub fn Color::srgb(r : Float, g : Float, b : Float) -> Color {
  Color::srgba(r, g, b, 1.0F)
}

///|
pub fn Color::srgba(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{
    r: color_srgb_to_linear(r),
    g: color_srgb_to_linear(g),
    b: color_srgb_to_linear(b),
    a: color_clamp_unit(a),
  }
}

///|
pub fn color_srgb(r : Float, g : Float, b : Float) -> Color {
  Color::srgb(r, g, b)
}

///|
pub fn color_srgba(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::srgba(r, g, b, a)
}

///|
pub fn Color::to_srgba_tuple(self : Color) -> (Float, Float, Float, Float) {
  (
    color_linear_to_srgb(self.r),
    color_linear_to_srgb(self.g),
    color_linear_to_srgb(self.b),
    color_clamp_unit(self.a),
  )
}
