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

///|
pub fn inset_circle(shape : Circle, distance : Float) -> Circle {
  let ring = shape.to_ring(distance)
  Circle::new(ring.inner_radius).with_vertices(ring.vertices)
}

///|
pub fn inset_triangle2d(shape : Triangle2d, distance : Float) -> Triangle2d {
  shape.to_ring(distance).inner_shape
}

///|
pub fn inset_rhombus(shape : Rhombus, distance : Float) -> Rhombus {
  shape.to_ring(distance).inner_shape
}

///|
pub fn inset_capsule2d(shape : Capsule2d, distance : Float) -> Capsule2d {
  shape.to_ring(distance).inner_shape
}

///|
pub fn inset_rectangle(shape : Rectangle, distance : Float) -> Rectangle {
  shape.to_ring(distance).inner_shape
}

///|
pub fn inset_circular_segment(
  shape : CircularSegment,
  distance : Float,
) -> CircularSegment {
  shape.to_ring(distance).inner_shape
}

///|
pub fn inset_regular_polygon(
  shape : RegularPolygon,
  distance : Float,
) -> RegularPolygon {
  shape.to_ring(distance).inner_shape
}
