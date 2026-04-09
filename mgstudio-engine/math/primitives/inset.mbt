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
// Bevy source: `bevy/crates/bevy_math/src/primitives/inset.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub fn inset_circle(shape : @math.Circle, distance : Float) -> @math.Circle {
  shape.inset(distance)
}

///|
pub fn inset_triangle2d(
  shape : @math.Triangle2d,
  distance : Float,
) -> @math.Triangle2d {
  shape.inset(distance)
}

///|
pub fn inset_rhombus(shape : @math.Rhombus, distance : Float) -> @math.Rhombus {
  shape.inset(distance)
}

///|
pub fn inset_capsule2d(
  shape : @math.Capsule2d,
  distance : Float,
) -> @math.Capsule2d {
  shape.inset(distance)
}

///|
pub fn inset_rectangle(
  shape : @math.Rectangle,
  distance : Float,
) -> @math.Rectangle {
  shape.inset(distance)
}

///|
pub fn inset_circular_segment(
  shape : @math.CircularSegment,
  distance : Float,
) -> @math.CircularSegment {
  shape.inset(distance)
}

///|
pub fn inset_regular_polygon(
  shape : @math.RegularPolygon,
  distance : Float,
) -> @math.RegularPolygon {
  shape.inset(distance)
}
