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
// Bevy source: `bevy/crates/bevy_math/src/primitives/dim2.rs`.

///|
pub fn[T : @math.Measured2d] perimeter_2d_of(shape : T) -> Float {
  shape.perimeter()
}

///|
pub fn[T : @math.Measured2d] area_2d_of(shape : T) -> Float {
  shape.area()
}

///|
pub fn circle_diameter(shape : @math.Circle) -> Float {
  shape.diameter()
}

///|
pub fn arc2d_length(shape : @math.Arc2d) -> Float {
  shape.length()
}
