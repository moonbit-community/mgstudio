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
pub struct Capsule2d {
  radius : Float
  half_length : Float
  segments : Int
}

///|
pub fn Capsule2d::new(radius : Float, length : Float) -> Capsule2d {
  Capsule2d::{ radius, half_length: length / 2.0F, segments: 16 }
}

///|
pub fn Capsule2d::with_segments(self : Capsule2d, segments : Int) -> Capsule2d {
  Capsule2d::{ ..self, segments, }
}

///|
pub fn Capsule2d::default() -> Capsule2d {
  Capsule2d::new(0.5F, 1.0F)
}

///|
pub struct Rectangle {
  half_size : Vec2
}

///|
pub fn Rectangle::new(width : Float, height : Float) -> Rectangle {
  Rectangle::{ half_size: Vec2::new(width / 2.0F, height / 2.0F) }
}

///|
pub fn Rectangle::from_size(size : Vec2) -> Rectangle {
  Rectangle::{ half_size: Vec2::new(size.x / 2.0F, size.y / 2.0F) }
}

///|
pub fn Rectangle::default() -> Rectangle {
  Rectangle::{ half_size: Vec2::new(0.5F, 0.5F) }
}

///|
pub struct Circle {
  radius : Float
  vertices : Int
}

///|
pub fn Circle::new(radius : Float) -> Circle {
  Circle::{ radius, vertices: 32 }
}

///|
pub fn Circle::with_vertices(self : Circle, vertices : Int) -> Circle {
  Circle::{ ..self, vertices, }
}

///|
pub fn Circle::default() -> Circle {
  Circle::new(0.5F)
}

///|
pub fn Circle::diameter(self : Circle) -> Float {
  self.radius * 2.0F
}

///|
pub struct Arc2d {
  radius : Float
  half_angle : Float
}

///|
pub fn Arc2d::new(radius : Float, half_angle : Float) -> Arc2d {
  Arc2d::{ radius, half_angle }
}

///|
pub fn Arc2d::from_radians(radius : Float, angle : Float) -> Arc2d {
  Arc2d::{ radius, half_angle: angle / 2.0F }
}

///|
pub fn Arc2d::from_degrees(radius : Float, angle : Float) -> Arc2d {
  Arc2d::from_radians(radius, angle * pi() / 180.0F)
}

///|
pub fn Arc2d::from_turns(radius : Float, fraction : Float) -> Arc2d {
  Arc2d::{ radius, half_angle: fraction * pi() }
}

///|
pub fn Arc2d::angle(self : Arc2d) -> Float {
  self.half_angle * 2.0F
}

///|
pub fn Arc2d::length(self : Arc2d) -> Float {
  self.angle() * self.radius
}

///|
pub fn Arc2d::right_endpoint(self : Arc2d) -> Vec2 {
  Vec2::from_angle(pi_half() - self.half_angle).mul_scalar(self.radius)
}

///|
pub fn Arc2d::left_endpoint(self : Arc2d) -> Vec2 {
  Vec2::from_angle(pi_half() + self.half_angle).mul_scalar(self.radius)
}

///|
pub fn Arc2d::endpoints(self : Arc2d) -> Array[Vec2] {
  [self.left_endpoint(), self.right_endpoint()]
}

///|
pub fn Arc2d::midpoint(self : Arc2d) -> Vec2 {
  Vec2::new(0.0F, self.radius)
}

///|
pub fn Arc2d::half_chord_length(self : Arc2d) -> Float {
  self.radius * sin(self.half_angle)
}

///|
pub struct Ellipse {
  half_size : Vec2
  vertices : Int
}

///|
pub fn Ellipse::new(half_width : Float, half_height : Float) -> Ellipse {
  Ellipse::{ half_size: Vec2::new(half_width, half_height), vertices: 32 }
}

///|
pub fn Ellipse::with_vertices(self : Ellipse, vertices : Int) -> Ellipse {
  Ellipse::{ ..self, vertices, }
}

///|
pub fn Ellipse::default() -> Ellipse {
  Ellipse::new(0.5F, 0.25F)
}

///|
pub struct Annulus {
  inner_radius : Float
  outer_radius : Float
  vertices : Int
}

///|
pub fn Annulus::new(inner_radius : Float, outer_radius : Float) -> Annulus {
  Annulus::{ inner_radius, outer_radius, vertices: 48 }
}

///|
pub fn Annulus::with_vertices(self : Annulus, vertices : Int) -> Annulus {
  Annulus::{ ..self, vertices, }
}

///|
pub fn Annulus::default() -> Annulus {
  Annulus::new(0.25F, 0.5F)
}

///|
pub struct Line2d {
  direction : Dir2
}

///|
pub fn Line2d::new(direction : Vec2) -> Line2d {
  let safe_direction = Dir2::new(direction) catch { _ => Dir2::x() }
  Line2d::{ direction: safe_direction }
}

///|
pub fn Line2d::from_dir(direction : Dir2) -> Line2d {
  Line2d::{ direction, }
}

///|
pub struct Plane2d {
  normal : Dir2
}

///|
pub fn Plane2d::new(normal : Vec2) -> Plane2d {
  let safe_normal = Dir2::new(normal) catch { _ => Dir2::y() }
  Plane2d::{ normal: safe_normal }
}

///|
pub fn Plane2d::from_normal(normal : Dir2) -> Plane2d {
  Plane2d::{ normal, }
}

///|
pub struct Rhombus {
  half_diagonal : Vec2
}

///|
pub fn Rhombus::new(width : Float, height : Float) -> Rhombus {
  Rhombus::{ half_diagonal: Vec2::new(width / 2.0F, height / 2.0F) }
}

///|
pub fn Rhombus::default() -> Rhombus {
  Rhombus::new(1.0F, 1.0F)
}

///|
pub struct RegularPolygon {
  radius : Float
  sides : Int
}

///|
pub fn RegularPolygon::new(radius : Float, sides : Int) -> RegularPolygon {
  RegularPolygon::{ radius, sides }
}

///|
pub fn RegularPolygon::default() -> RegularPolygon {
  RegularPolygon::new(0.5F, 6)
}

///|
pub struct Triangle2d {
  a : Vec2
  b : Vec2
  c : Vec2
}

///|
pub fn Triangle2d::new(a : Vec2, b : Vec2, c : Vec2) -> Triangle2d {
  Triangle2d::{ a, b, c }
}

///|
pub fn Triangle2d::default() -> Triangle2d {
  Triangle2d::{
    a: Vec2::new(0.0F, 0.5F),
    b: Vec2::new(-0.5F, -0.5F),
    c: Vec2::new(0.5F, -0.5F),
  }
}

///|
pub struct Segment2d {
  start : Vec2
  end : Vec2
  half_thickness : Float
}

///|
pub fn Segment2d::new(start : Vec2, end : Vec2) -> Segment2d {
  Segment2d::{ start, end, half_thickness: 2.5F }
}

///|
pub fn Segment2d::with_half_thickness(
  self : Segment2d,
  half_thickness : Float,
) -> Segment2d {
  Segment2d::{ ..self, half_thickness, }
}

///|
pub struct Polyline2d {
  points : Array[Vec2]
  half_thickness : Float
}

///|
pub fn Polyline2d::new(points : Array[Vec2]) -> Polyline2d {
  Polyline2d::{ points, half_thickness: 2.5F }
}

///|
pub fn Polyline2d::with_half_thickness(
  self : Polyline2d,
  half_thickness : Float,
) -> Polyline2d {
  Polyline2d::{ ..self, half_thickness, }
}

///|
pub struct Polygon {
  vertices : Array[Vec2]
}

///|
pub fn Polygon::new(vertices : Array[Vec2]) -> Polygon {
  Polygon::{ vertices, }
}

///|
pub struct ConvexPolygon {
  vertices : Array[Vec2]
}

///|
pub fn ConvexPolygon::new(vertices : Array[Vec2]) -> ConvexPolygon {
  ConvexPolygon::{ vertices, }
}

///|
pub(all) enum CircularMeshUvMode {
  Mask(Float)
} derive(Eq, ToJson, FromJson)

///|
pub struct CircularSector {
  radius : Float
  half_angle : Float
  vertices : Int
  uv_mode : CircularMeshUvMode
}

///|
pub fn CircularSector::new(
  radius : Float,
  half_angle : Float,
) -> CircularSector {
  CircularSector::{ radius, half_angle, vertices: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSector::from_turns(
  radius : Float,
  fraction : Float,
) -> CircularSector {
  CircularSector::new(radius, fraction * pi_half() * 2.0F)
}

///|
pub fn CircularSector::with_vertices(
  self : CircularSector,
  vertices : Int,
) -> CircularSector {
  CircularSector::{ ..self, vertices, }
}

///|
pub fn CircularSector::with_uv_mode(
  self : CircularSector,
  uv_mode : CircularMeshUvMode,
) -> CircularSector {
  CircularSector::{ ..self, uv_mode, }
}

///|
pub fn CircularSector::with_uv_mask_angle(
  self : CircularSector,
  angle : Float,
) -> CircularSector {
  self.with_uv_mode(Mask(angle))
}

///|
pub fn CircularSector::half_angle(self : CircularSector) -> Float {
  self.half_angle
}

///|
pub fn CircularSector::angle(self : CircularSector) -> Float {
  self.half_angle * 2.0F
}

///|
pub fn CircularSector::default() -> CircularSector {
  CircularSector::new(0.5F, pi_half() * 2.0F / 3.0F)
}

///|
pub struct CircularSegment {
  radius : Float
  half_angle : Float
  vertices : Int
  uv_mode : CircularMeshUvMode
}

///|
pub fn CircularSegment::new(
  radius : Float,
  half_angle : Float,
) -> CircularSegment {
  CircularSegment::{ radius, half_angle, vertices: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSegment::from_turns(
  radius : Float,
  fraction : Float,
) -> CircularSegment {
  CircularSegment::new(radius, fraction * pi_half() * 2.0F)
}

///|
pub fn CircularSegment::with_vertices(
  self : CircularSegment,
  vertices : Int,
) -> CircularSegment {
  CircularSegment::{ ..self, vertices, }
}

///|
pub fn CircularSegment::with_uv_mode(
  self : CircularSegment,
  uv_mode : CircularMeshUvMode,
) -> CircularSegment {
  CircularSegment::{ ..self, uv_mode, }
}

///|
pub fn CircularSegment::with_uv_mask_angle(
  self : CircularSegment,
  angle : Float,
) -> CircularSegment {
  self.with_uv_mode(Mask(angle))
}

///|
pub fn CircularSegment::half_angle(self : CircularSegment) -> Float {
  self.half_angle
}

///|
pub fn CircularSegment::angle(self : CircularSegment) -> Float {
  self.half_angle * 2.0F
}

///|
pub fn CircularSegment::default() -> CircularSegment {
  CircularSegment::new(0.5F, pi_half() * 2.0F / 3.0F)
}

///|
pub struct Ring[P] {
  outer_shape : P
  inner_shape : P
}

///|
pub fn[P] Ring::new(outer_shape : P, inner_shape : P) -> Ring[P] {
  Ring::{ outer_shape, inner_shape }
}

///|
pub struct Capsule2dRing {
  outer_shape : Capsule2d
  inner_shape : Capsule2d
}

///|
pub fn Capsule2dRing::new(
  outer_shape : Capsule2d,
  inner_shape : Capsule2d,
) -> Capsule2dRing {
  Capsule2dRing::{ outer_shape, inner_shape }
}

///|
pub struct RectangleRing {
  outer_shape : Rectangle
  inner_shape : Rectangle
}

///|
pub fn RectangleRing::new(
  outer_shape : Rectangle,
  inner_shape : Rectangle,
) -> RectangleRing {
  RectangleRing::{ outer_shape, inner_shape }
}

///|
pub struct EllipseRing {
  outer_shape : Ellipse
  inner_shape : Ellipse
}

///|
pub fn EllipseRing::new(
  outer_shape : Ellipse,
  inner_shape : Ellipse,
) -> EllipseRing {
  EllipseRing::{ outer_shape, inner_shape }
}

///|
pub struct Ring2d {
  outer_radius : Float
  inner_radius : Float
  vertices : Int
}

///|
pub fn Ring2d::new(outer_radius : Float, inner_radius : Float) -> Ring2d {
  Ring2d::{ outer_radius, inner_radius, vertices: 48 }
}

///|
pub fn Ring2d::with_vertices(self : Ring2d, vertices : Int) -> Ring2d {
  Ring2d::{ ..self, vertices, }
}

///|
pub fn Ring2d::default() -> Ring2d {
  Ring2d::new(0.5F, 0.25F)
}

///|
pub struct RhombusRing {
  outer_shape : Rhombus
  inner_shape : Rhombus
}

///|
pub fn RhombusRing::new(
  outer_shape : Rhombus,
  inner_shape : Rhombus,
) -> RhombusRing {
  RhombusRing::{ outer_shape, inner_shape }
}

///|
pub struct RegularPolygonRing {
  outer_shape : RegularPolygon
  inner_shape : RegularPolygon
}

///|
pub fn RegularPolygonRing::new(
  outer_shape : RegularPolygon,
  inner_shape : RegularPolygon,
) -> RegularPolygonRing {
  RegularPolygonRing::{ outer_shape, inner_shape }
}

///|
pub struct Triangle2dRing {
  outer_shape : Triangle2d
  inner_shape : Triangle2d
}

///|
pub fn Triangle2dRing::new(
  outer_shape : Triangle2d,
  inner_shape : Triangle2d,
) -> Triangle2dRing {
  Triangle2dRing::{ outer_shape, inner_shape }
}

///|
pub struct CircularSectorRing {
  outer_shape : CircularSector
  inner_shape : CircularSector
}

///|
pub fn CircularSectorRing::new(
  outer_shape : CircularSector,
  inner_shape : CircularSector,
) -> CircularSectorRing {
  CircularSectorRing::{ outer_shape, inner_shape }
}

///|
pub struct CircularSegmentRing {
  outer_shape : CircularSegment
  inner_shape : CircularSegment
}

///|
pub fn CircularSegmentRing::new(
  outer_shape : CircularSegment,
  inner_shape : CircularSegment,
) -> CircularSegmentRing {
  CircularSegmentRing::{ outer_shape, inner_shape }
}

///|
fn ring_vec2_add(a : Vec2, b : Vec2) -> Vec2 {
  Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn ring_vec2_sub(a : Vec2, b : Vec2) -> Vec2 {
  Vec2::new(a.x - b.x, a.y - b.y)
}

///|
fn ring_vec2_mul_scalar(v : Vec2, scalar : Float) -> Vec2 {
  Vec2::new(v.x * scalar, v.y * scalar)
}

///|
fn ring_vec2_dot(a : Vec2, b : Vec2) -> Float {
  a.x * b.x + a.y * b.y
}

///|
fn ring_vec2_normalize_or_zero(v : Vec2) -> Vec2 {
  let len_sq = ring_vec2_dot(v, v)
  if len_sq <= 1.0e-12F {
    return Vec2::new(0.0F, 0.0F)
  }
  let inv_len = 1.0F / sqrt(len_sq)
  ring_vec2_mul_scalar(v, inv_len)
}

///|
fn ring_safe_acos(value : Float) -> Float {
  let clamped = dim2_clamp_float(value, -1.0F, 1.0F)
  let y_sq = 1.0F - clamped * clamped
  let y = if y_sq <= 0.0F { 0.0F } else { sqrt(y_sq) }
  atan2(y, clamped)
}

///|
fn triangle_inset_point(a : Vec2, b : Vec2, c : Vec2, distance : Float) -> Vec2 {
  let unit_ab = ring_vec2_normalize_or_zero(ring_vec2_sub(b, a))
  let unit_ac = ring_vec2_normalize_or_zero(ring_vec2_sub(c, a))
  let half_angle = ring_safe_acos(ring_vec2_dot(unit_ab, unit_ac)) / 2.0F
  let direction = ring_vec2_normalize_or_zero(
    ring_vec2_mul_scalar(ring_vec2_add(unit_ab, unit_ac), 0.5F),
  )
  let sin_half_angle = sin(half_angle)
  if dim2_abs_float(sin_half_angle) <= 1.0e-6F {
    return a
  }
  ring_vec2_add(a, ring_vec2_mul_scalar(direction, distance / sin_half_angle))
}

///|
fn dim2_abs_float(v : Float) -> Float {
  if v < 0.0F {
    -v
  } else {
    v
  }
}

///|
fn dim2_clamp_float(value : Float, minimum : Float, maximum : Float) -> Float {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
  } else {
    value
  }
}

///|
fn dim2_safe_positive(v : Float, fallback : Float) -> Float {
  if v <= 0.0F {
    fallback
  } else {
    v
  }
}

///|
fn circular_segment_apothem(radius : Float, half_angle : Float) -> Float {
  radius * cos(half_angle)
}

///|
fn arc_safe_half_angle(half_angle : Float) -> Float {
  dim2_clamp_float(half_angle, 0.0F, pi() - 1.0e-6F)
}

///|
pub fn Circle::to_ring(self : Circle, thickness : Float) -> Ring2d {
  Ring2d::new(self.radius, self.radius - thickness).with_vertices(self.vertices)
}

///|
pub fn CircularSegment::to_ring(
  self : CircularSegment,
  distance : Float,
) -> CircularSegmentRing {
  let old_radius = dim2_safe_positive(dim2_abs_float(self.radius), 0.5F)
  let old_half_angle = arc_safe_half_angle(self.half_angle)
  let old_apothem = circular_segment_apothem(old_radius, old_half_angle)
  let radius = old_radius - distance
  let apothem = old_apothem + distance
  let safe_radius = if radius <= 1.0e-6F { 1.0e-6F } else { radius }
  let half_angle = ring_safe_acos(apothem / safe_radius)
  let inner = CircularSegment::new(safe_radius, half_angle)
    .with_vertices(self.vertices)
    .with_uv_mode(self.uv_mode)
  CircularSegmentRing::new(self, inner)
}

///|
pub fn Capsule2d::to_ring(self : Capsule2d, distance : Float) -> Capsule2dRing {
  let inner = Capsule2d::{
    radius: self.radius - distance,
    half_length: self.half_length,
    segments: self.segments,
  }
  Capsule2dRing::new(self, inner)
}

///|
pub fn Rhombus::to_ring(self : Rhombus, distance : Float) -> RhombusRing {
  let half_width = self.half_diagonal.x
  let half_height = self.half_diagonal.y
  let angle = atan2(half_height, half_width)
  let sin_angle = sin(angle)
  let cos_angle = cos(angle)
  let x_offset = if dim2_abs_float(sin_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / sin_angle
  }
  let y_offset = if dim2_abs_float(cos_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / cos_angle
  }
  let inner = Rhombus::new(
    half_width * 2.0F - x_offset * 2.0F,
    half_height * 2.0F - y_offset * 2.0F,
  )
  RhombusRing::new(self, inner)
}

///|
pub fn Rectangle::to_ring(self : Rectangle, distance : Float) -> RectangleRing {
  let inner = Rectangle::new(
    self.half_size.x * 2.0F - distance * 2.0F,
    self.half_size.y * 2.0F - distance * 2.0F,
  )
  RectangleRing::new(self, inner)
}

///|
pub fn RegularPolygon::to_ring(
  self : RegularPolygon,
  distance : Float,
) -> RegularPolygonRing {
  let sides = if self.sides < 3 { 3 } else { self.sides }
  let half_angle = pi() *
    Float::from_double((sides - 2).to_double()) /
    Float::from_double((2 * sides).to_double())
  let sin_half_angle = sin(half_angle)
  let offset = if dim2_abs_float(sin_half_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / sin_half_angle
  }
  let inner = RegularPolygon::new(self.radius - offset, self.sides)
  RegularPolygonRing::new(self, inner)
}

///|
pub fn Triangle2d::to_ring(
  self : Triangle2d,
  distance : Float,
) -> Triangle2dRing {
  let inner = Triangle2d::new(
    triangle_inset_point(self.a, self.b, self.c, distance),
    triangle_inset_point(self.b, self.c, self.a, distance),
    triangle_inset_point(self.c, self.a, self.b, distance),
  )
  Triangle2dRing::new(self, inner)
}
