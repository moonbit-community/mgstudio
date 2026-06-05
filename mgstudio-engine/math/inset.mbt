// Copyright 2026 International Digital Economy Academy
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
pub(open) trait Inset: Primitive2d {
  fn inset(Self, Float) -> Self
}

///|
pub(open) trait ToRing: Primitive2d + Inset {
  fn to_ring(Self, Float) -> Ring[Self]
}

///|
pub fn[P : Inset] Ring::from_primitive_and_thickness(
  primitive : P,
  thickness : Float,
) -> Ring[P] {
  Ring::new(primitive, primitive.inset(thickness))
}

///|
pub impl ToRing for Circle with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for Triangle2d with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for Rhombus with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for Capsule2d with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for Rectangle with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for CircularSegment with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl ToRing for RegularPolygon with fn to_ring(self, thickness) {
  Ring::from_primitive_and_thickness(self, thickness)
}

///|
pub impl Inset for Circle with fn inset(self, distance) {
  Circle::{ ..self, radius: self.radius - distance }
}

///|
pub impl Inset for Triangle2d with fn inset(self, distance) {
  fn find_inset_point(a : Vec2, b : Vec2, c : Vec2, distance : Float) -> Vec2 {
    let unit_vector_ab = b.sub(a).normalize()
    let unit_vector_ac = c.sub(a).normalize()
    let half_angle_bac = unit_vector_ab.angle_to(unit_vector_ac) / 2.0F
    let mean = unit_vector_ab.add(unit_vector_ac).mul_scalar(0.5F)
    let direction = mean.normalize()
    let magnitude = distance / sin(half_angle_bac)
    a.add(direction.mul_scalar(magnitude))
  }

  Triangle2d::new(
    find_inset_point(self.a, self.b, self.c, distance),
    find_inset_point(self.b, self.c, self.a, distance),
    find_inset_point(self.c, self.a, self.b, distance),
  )
}

///|
pub impl Inset for Rhombus with fn inset(self, distance) {
  let half_width = self.half_diagonal.x
  let half_height = self.half_diagonal.y
  let angle = Float::from_double(
    @coremath.atan(half_height.to_double() / half_width.to_double()),
  )
  let x_offset = distance / sin(angle)
  let y_offset = distance / cos(angle)
  Rhombus::{
    half_diagonal: self.half_diagonal.sub(Vec2::new(x_offset, y_offset)),
  }
}

///|
pub impl Inset for Capsule2d with fn inset(self, distance) {
  Capsule2d::{ ..self, radius: self.radius - distance }
}

///|
pub impl Inset for Rectangle with fn inset(self, distance) {
  Rectangle::{ half_size: self.half_size.sub(Vec2::splat(distance)) }
}

///|
pub impl Inset for CircularSegment with fn inset(self, distance) {
  let radius = self.radius - distance
  let apothem = self.radius * cos(self.half_angle) + distance
  let half_angle = acos(apothem / radius)
  CircularSegment::{ ..self, radius, half_angle }
}

///|
pub impl Inset for RegularPolygon with fn inset(self, distance) {
  let safe_sides = if self.sides < 3 { 3 } else { self.sides }
  let internal_angle = pi() *
    Float::from_double((safe_sides - 2).to_double()) /
    Float::from_double(safe_sides.to_double())
  let half_angle = internal_angle / 2.0F
  let offset = distance / sin(half_angle)
  RegularPolygon::{ ..self, radius: self.radius - offset }
}
