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
pub(all) enum WindingOrder {
  Clockwise
  CounterClockwise
  Invalid
} derive(Eq, Show, ToJson, FromJson)

///|
pub(open) trait Primitive2d {}

///|
pub(open) trait Primitive3d {}

///|
pub(open) trait Measured2d {
  perimeter(self : Self) -> Float
  area(self : Self) -> Float
}

///|
pub(open) trait Measured3d {
  area(self : Self) -> Float
  volume(self : Self) -> Float
}

///|
pub impl Primitive2d for Capsule2d

///|
pub impl Primitive2d for Rectangle

///|
pub impl Primitive2d for Circle

///|
pub impl Primitive2d for Arc2d

///|
pub impl Primitive2d for Ellipse

///|
pub impl Primitive2d for Annulus

///|
pub impl Primitive2d for Line2d

///|
pub impl Primitive2d for Plane2d

///|
pub impl Primitive2d for Rhombus

///|
pub impl Primitive2d for RegularPolygon

///|
pub impl Primitive2d for Triangle2d

///|
pub impl Primitive2d for Segment2d

///|
pub impl Primitive2d for Polyline2d

///|
pub impl Primitive2d for Polygon

///|
pub impl Primitive2d for ConvexPolygon

///|
pub impl Primitive2d for CircularSector

///|
pub impl Primitive2d for CircularSegment

///|
pub impl[P : Primitive2d] Primitive2d for Ring[P]

///|
pub impl Primitive2d for Capsule2dRing

///|
pub impl Primitive2d for RectangleRing

///|
pub impl Primitive2d for EllipseRing

///|
pub impl Primitive2d for Ring2d

///|
pub impl Primitive2d for RhombusRing

///|
pub impl Primitive2d for RegularPolygonRing

///|
pub impl Primitive2d for Triangle2dRing

///|
pub impl Primitive2d for CircularSectorRing

///|
pub impl Primitive2d for CircularSegmentRing

///|
pub impl Primitive3d for Sphere

///|
pub impl Primitive3d for Cuboid

///|
pub impl Primitive3d for Cylinder

///|
pub impl Primitive3d for Capsule3d

///|
pub impl Primitive3d for Triangle3d

///|
pub impl Primitive3d for Tetrahedron

///|
pub impl Primitive3d for Plane3d

///|
pub impl Primitive3d for InfinitePlane3d

///|
pub impl Primitive3d for Line3d

///|
pub impl Primitive3d for Segment3d

///|
pub impl Primitive3d for Polyline3d

///|
pub impl Primitive3d for Cone

///|
pub impl Primitive3d for ConicalFrustum

///|
pub impl Primitive3d for Torus

///|
pub impl Measured2d for Circle with perimeter(self) {
  2.0F * pi() * self.radius
}

///|
pub impl Measured2d for Circle with area(self) {
  pi() * self.radius * self.radius
}

///|
pub impl Measured2d for Rectangle with perimeter(self) {
  let size = self.half_size.mul_scalar(2.0F)
  2.0F * (size.x + size.y)
}

///|
pub impl Measured2d for Rectangle with area(self) {
  let size = self.half_size.mul_scalar(2.0F)
  size.x * size.y
}

///|
pub impl Measured2d for Triangle2d with perimeter(self) {
  let ab = self.b.sub(self.a).length()
  let bc = self.c.sub(self.b).length()
  let ca = self.a.sub(self.c).length()
  ab + bc + ca
}

///|
pub impl Measured2d for Triangle2d with area(self) {
  let ab = self.b.sub(self.a)
  let ac = self.c.sub(self.a)
  primitives_absf(ab.x * ac.y - ab.y * ac.x) * 0.5F
}

///|
pub impl Measured2d for RegularPolygon with perimeter(self) {
  let safe_sides = primitives_safe_polygon_sides(self.sides)
  2.0F *
  primitives_float_from_int(safe_sides) *
  self.radius *
  sin(pi() / primitives_float_from_int(safe_sides))
}

///|
pub impl Measured2d for RegularPolygon with area(self) {
  let safe_sides = primitives_safe_polygon_sides(self.sides)
  0.5F *
  primitives_float_from_int(safe_sides) *
  self.radius *
  self.radius *
  sin(2.0F * pi() / primitives_float_from_int(safe_sides))
}

///|
pub impl Measured2d for Ellipse with perimeter(self) {
  let a = primitives_abs_float(self.half_size.x)
  let b = primitives_abs_float(self.half_size.y)
  let sum = a + b
  if sum <= 0.0F {
    return 0.0F
  }
  let h = (a - b) * (a - b) / (sum * sum)
  pi() * sum * (1.0F + 3.0F * h / (10.0F + sqrt(4.0F - 3.0F * h)))
}

///|
pub impl Measured2d for Ellipse with area(self) {
  pi() *
  primitives_abs_float(self.half_size.x) *
  primitives_abs_float(self.half_size.y)
}

///|
pub impl Measured2d for Annulus with perimeter(self) {
  2.0F *
  pi() *
  (
    primitives_abs_float(self.outer_radius) +
    primitives_abs_float(self.inner_radius)
  )
}

///|
pub impl Measured2d for Annulus with area(self) {
  pi() *
  (
    self.outer_radius * self.outer_radius -
    self.inner_radius * self.inner_radius
  )
}

///|
pub impl Measured2d for Rhombus with perimeter(self) {
  let side = sqrt(
    self.half_diagonal.x * self.half_diagonal.x +
    self.half_diagonal.y * self.half_diagonal.y,
  )
  4.0F * side
}

///|
pub impl Measured2d for Rhombus with area(self) {
  2.0F * primitives_abs_float(self.half_diagonal.x * self.half_diagonal.y)
}

///|
pub impl Measured2d for CircularSector with perimeter(self) {
  let arc = Arc2d::new(self.radius, self.half_angle())
  2.0F * self.radius + arc.length()
}

///|
pub impl Measured2d for CircularSector with area(self) {
  self.radius * self.radius * self.half_angle()
}

///|
pub impl Measured2d for CircularSegment with perimeter(self) {
  let arc = Arc2d::new(self.radius, self.half_angle())
  arc.length() + 2.0F * arc.half_chord_length()
}

///|
pub impl Measured2d for CircularSegment with area(self) {
  let angle = self.half_angle()
  self.radius * self.radius * (angle - sin(angle) * cos(angle))
}

///|
pub impl Measured2d for Ring2d with perimeter(self) {
  2.0F * pi() * (self.outer_radius + self.inner_radius)
}

///|
pub impl Measured2d for Ring2d with area(self) {
  pi() *
  (
    self.outer_radius * self.outer_radius -
    self.inner_radius * self.inner_radius
  )
}

///|
pub impl[P : Measured2d] Measured2d for Ring[P] with perimeter(self) {
  self.outer_shape.perimeter() + self.inner_shape.perimeter()
}

///|
pub impl[P : Measured2d] Measured2d for Ring[P] with area(self) {
  self.outer_shape.area() - self.inner_shape.area()
}

///|
pub impl Measured2d for Plane3d with perimeter(self) {
  let size = self.half_size.mul_scalar(2.0F)
  2.0F * (size.x + size.y)
}

///|
pub impl Measured2d for Plane3d with area(self) {
  let size = self.half_size.mul_scalar(2.0F)
  size.x * size.y
}

///|
pub impl Measured2d for Triangle3d with perimeter(self) {
  let ab = self.vertices[1].sub(self.vertices[0]).length()
  let bc = self.vertices[2].sub(self.vertices[1]).length()
  let ca = self.vertices[0].sub(self.vertices[2]).length()
  ab + bc + ca
}

///|
pub impl Measured2d for Triangle3d with area(self) {
  let ab = self.vertices[1].sub(self.vertices[0])
  let ac = self.vertices[2].sub(self.vertices[0])
  ab.cross(ac).length() * 0.5F
}

///|
pub impl Measured3d for Sphere with area(self) {
  4.0F * pi() * self.radius * self.radius
}

///|
pub impl Measured3d for Sphere with volume(self) {
  4.0F * pi() * self.radius * self.radius * self.radius / 3.0F
}

///|
pub impl Measured3d for Cuboid with area(self) {
  let size = self.size()
  2.0F * (size.x * size.y + size.y * size.z + size.z * size.x)
}

///|
pub impl Measured3d for Cuboid with volume(self) {
  let size = self.size()
  size.x * size.y * size.z
}

///|
pub impl Measured3d for Cylinder with area(self) {
  let height = self.half_height * 2.0F
  2.0F * pi() * self.radius * (height + self.radius)
}

///|
pub impl Measured3d for Cylinder with volume(self) {
  pi() * self.radius * self.radius * self.half_height * 2.0F
}

///|
pub impl Measured3d for Capsule3d with area(self) {
  4.0F * pi() * self.radius * (self.radius + self.half_length)
}

///|
pub impl Measured3d for Capsule3d with volume(self) {
  let cylinder_volume = pi() *
    self.radius *
    self.radius *
    self.half_length *
    2.0F
  let sphere_volume = 4.0F *
    pi() *
    self.radius *
    self.radius *
    self.radius /
    3.0F
  cylinder_volume + sphere_volume
}

///|
pub impl Measured3d for Tetrahedron with area(self) {
  self
  .faces()
  .iter()
  .map(fn(face) { face.area() })
  .fold(init=0.0F, fn(acc, value) { acc + value })
}

///|
pub impl Measured3d for Tetrahedron with volume(self) {
  if self.vertices.length() != 4 {
    return 0.0F
  }
  let a = self.vertices[0]
  let b = self.vertices[1]
  let c = self.vertices[2]
  let d = self.vertices[3]
  primitives_absf(b.sub(a).dot(c.sub(a).cross(d.sub(a)))) / 6.0F
}

///|
pub impl Measured3d for Cone with area(self) {
  let slant = sqrt(self.radius * self.radius + self.height * self.height)
  pi() * self.radius * (self.radius + slant)
}

///|
pub impl Measured3d for Cone with volume(self) {
  pi() * self.radius * self.radius * self.height / 3.0F
}

///|
pub impl Measured3d for ConicalFrustum with area(self) {
  let slant = sqrt(
    (self.radius_bottom - self.radius_top) *
    (self.radius_bottom - self.radius_top) +
    self.height * self.height,
  )
  pi() *
  (
    self.radius_top * self.radius_top +
    self.radius_bottom * self.radius_bottom +
    (self.radius_top + self.radius_bottom) * slant
  )
}

///|
pub impl Measured3d for ConicalFrustum with volume(self) {
  pi() *
  self.height *
  (
    self.radius_top * self.radius_top +
    self.radius_top * self.radius_bottom +
    self.radius_bottom * self.radius_bottom
  ) /
  3.0F
}

///|
pub impl Measured3d for Torus with area(self) {
  4.0F * pi() * pi() * self.major_radius * self.minor_radius
}

///|
pub impl Measured3d for Torus with volume(self) {
  2.0F * pi() * pi() * self.major_radius * self.minor_radius * self.minor_radius
}

///|
fn primitives_safe_polygon_sides(sides : Int) -> Int {
  if sides < 3 {
    3
  } else {
    sides
  }
}

///|
fn primitives_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn primitives_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn primitives_absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}
