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
pub fn color_approx_eq(lhs : Color, rhs : Color, tolerance : Float) -> Bool {
  color_abs(lhs.r - rhs.r) <= tolerance &&
  color_abs(lhs.g - rhs.g) <= tolerance &&
  color_abs(lhs.b - rhs.b) <= tolerance &&
  color_abs(lhs.a - rhs.a) <= tolerance
}

///|
pub fn color_component_delta(
  lhs : Color,
  rhs : Color,
) -> (Float, Float, Float, Float) {
  (lhs.r - rhs.r, lhs.g - rhs.g, lhs.b - rhs.b, lhs.a - rhs.a)
}
