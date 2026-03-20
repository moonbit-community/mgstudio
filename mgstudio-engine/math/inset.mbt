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
pub(open) trait Inset {
  inset(self : Self, distance : Float) -> Self
}

///|
pub impl Inset for Circle with inset(self, distance) {
  Circle::{ radius: self.radius - distance, vertices: self.vertices }
}

///|
pub impl Inset for Triangle2d with inset(self, distance) {
  let new_a = inset_triangle_point(self.a, self.b, self.c, distance)
  let new_b = inset_triangle_point(self.b, self.c, self.a, distance)
  let new_c = inset_triangle_point(self.c, self.a, self.b, distance)
  Triangle2d::new(new_a, new_b, new_c)
}

///|
pub impl Inset for Rhombus with inset(self, distance) {
  let half_width = self.half_diagonal.x
  let half_height = self.half_diagonal.y
  let angle = atan2(half_height, half_width)
  let x_offset = distance / sin(angle)
  let y_offset = distance / cos(angle)
  Rhombus::{
    half_diagonal: self.half_diagonal.sub(Vec2::new(x_offset, y_offset)),
  }
}

///|
pub impl Inset for Capsule2d with inset(self, distance) {
  Capsule2d::{
    radius: self.radius - distance,
    half_length: self.half_length,
    segments: self.segments,
  }
}

///|
pub impl Inset for Rectangle with inset(self, distance) {
  Rectangle::{ half_size: self.half_size.sub(Vec2::new(distance, distance)) }
}

///|
pub impl Inset for CircularSegment with inset(self, distance) {
  let radius = self.radius - distance
  let apothem = inset_circular_segment_apothem(self.radius, self.half_angle()) +
    distance
  let half_angle = if radius <= 0.0F {
    0.0F
  } else {
    inset_safe_acos(apothem / radius)
  }
  CircularSegment::{
    radius,
    half_angle,
    vertices: self.vertices,
    uv_mode: self.uv_mode,
  }
}

///|
pub impl Inset for RegularPolygon with inset(self, distance) {
  let half_angle = pi() *
    (inset_float_from_int(self.sides) - 2.0F) /
    inset_float_from_int(self.sides) /
    2.0F
  let offset = distance / sin(half_angle)
  RegularPolygon::{ radius: self.radius - offset, sides: self.sides }
}

///|
fn inset_triangle_point(a : Vec2, b : Vec2, c : Vec2, distance : Float) -> Vec2 {
  let ab = b.sub(a).normalize_or_zero()
  let ac = c.sub(a).normalize_or_zero()
  let half_angle = (ab.to_angle() - ac.to_angle()).abs() * 0.5F
  let direction = ab.add(ac).normalize_or_zero()
  let magnitude = if inset_absf(sin(half_angle)) <= 1.0e-6F {
    0.0F
  } else {
    distance / sin(half_angle)
  }
  a.add(direction.mul_scalar(magnitude))
}

///|
fn inset_safe_acos(value : Float) -> Float {
  let clamped = if value < -1.0F {
    -1.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
  Float::from_double(@coremath.acos(clamped.to_double()))
}

///|
fn inset_circular_segment_apothem(radius : Float, half_angle : Float) -> Float {
  radius * cos(half_angle)
}

///|
fn inset_absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn inset_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}
