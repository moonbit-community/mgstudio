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
pub(open) trait Bounded2d {
  aabb_2d(self : Self, isometry : Isometry2d) -> Aabb2d
  bounding_circle(self : Self, isometry : Isometry2d) -> BoundingCircle
}

///|
pub struct Aabb2d {
  min : Vec2
  max : Vec2
}

///|
pub fn Aabb2d::new(center : Vec2, half_size : Vec2) -> Aabb2d {
  Aabb2d::{ min: center.sub(half_size), max: center.add(half_size) }
}

///|
pub fn Aabb2d::from_point_cloud(
  isometry : Isometry2d,
  points : Array[Vec2],
) -> Aabb2d {
  if points.length() == 0 {
    return Aabb2d::new(isometry.translation, Vec2::zero())
  }
  let first = isometry.transform_point2(points[0])
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for point in points {
    let transformed = isometry.transform_point2(point)
    min_x = bounded_min(min_x, transformed.x)
    min_y = bounded_min(min_y, transformed.y)
    max_x = bounded_max(max_x, transformed.x)
    max_y = bounded_max(max_y, transformed.y)
  }
  Aabb2d::{ min: Vec2::new(min_x, min_y), max: Vec2::new(max_x, max_y) }
}

///|
pub fn Aabb2d::center(self : Aabb2d) -> Vec2 {
  self.min.add(self.max).mul_scalar(0.5F)
}

///|
pub fn Aabb2d::half_size(self : Aabb2d) -> Vec2 {
  self.max.sub(self.min).mul_scalar(0.5F)
}

///|
pub fn Aabb2d::visible_area(self : Aabb2d) -> Float {
  let size = self.max.sub(self.min)
  bounded_positive(size.x) * bounded_positive(size.y)
}

///|
pub fn Aabb2d::contains(self : Aabb2d, other : Aabb2d) -> Bool {
  other.min.x >= self.min.x &&
  other.min.y >= self.min.y &&
  other.max.x <= self.max.x &&
  other.max.y <= self.max.y
}

///|
pub fn Aabb2d::merge(self : Aabb2d, other : Aabb2d) -> Aabb2d {
  Aabb2d::{
    min: Vec2::new(
      bounded_min(self.min.x, other.min.x),
      bounded_min(self.min.y, other.min.y),
    ),
    max: Vec2::new(
      bounded_max(self.max.x, other.max.x),
      bounded_max(self.max.y, other.max.y),
    ),
  }
}

///|
pub fn Aabb2d::grow(self : Aabb2d, amount : Vec2) -> Aabb2d {
  Aabb2d::{ min: self.min.sub(amount), max: self.max.add(amount) }
}

///|
pub fn Aabb2d::shrink(self : Aabb2d, amount : Vec2) -> Aabb2d {
  Aabb2d::{ min: self.min.add(amount), max: self.max.sub(amount) }
}

///|
pub fn Aabb2d::scale_around_center(self : Aabb2d, scale : Vec2) -> Aabb2d {
  let center = self.center()
  let scaled_half_size = Vec2::new(
    self.half_size().x * scale.x,
    self.half_size().y * scale.y,
  )
  Aabb2d::new(center, scaled_half_size)
}

///|
pub fn Aabb2d::translated_by(self : Aabb2d, translation : Vec2) -> Aabb2d {
  Aabb2d::{ min: self.min.add(translation), max: self.max.add(translation) }
}

///|
pub fn Aabb2d::rotated_by(self : Aabb2d, rotation : Rot2) -> Aabb2d {
  let corners = [
    self.min,
    Vec2::new(self.max.x, self.min.y),
    self.max,
    Vec2::new(self.min.x, self.max.y),
  ]
  Aabb2d::from_point_cloud(Isometry2d::new(Vec2::zero(), rotation), corners)
}

///|
pub fn Aabb2d::transformed_by(
  self : Aabb2d,
  translation : Vec2,
  rotation : Rot2,
) -> Aabb2d {
  let corners = [
    self.min,
    Vec2::new(self.max.x, self.min.y),
    self.max,
    Vec2::new(self.min.x, self.max.y),
  ]
  Aabb2d::from_point_cloud(Isometry2d::new(translation, rotation), corners)
}

///|
pub fn Aabb2d::closest_point(self : Aabb2d, point : Vec2) -> Vec2 {
  Vec2::new(
    bounded_clamp(point.x, self.min.x, self.max.x),
    bounded_clamp(point.y, self.min.y, self.max.y),
  )
}

///|
pub fn Aabb2d::bounding_circle(self : Aabb2d) -> BoundingCircle {
  let center = self.center()
  let radius = self.max.sub(center).length()
  BoundingCircle::new(center, radius)
}

///|
pub fn Aabb2d::intersects_aabb(self : Aabb2d, other : Aabb2d) -> Bool {
  self.min.x <= other.max.x &&
  self.max.x >= other.min.x &&
  self.min.y <= other.max.y &&
  self.max.y >= other.min.y
}

///|
pub fn Aabb2d::intersects_circle(self : Aabb2d, other : BoundingCircle) -> Bool {
  let closest = self.closest_point(other.center)
  closest.sub(other.center).length_squared() <= other.radius() * other.radius()
}

///|
pub struct BoundingCircle {
  center : Vec2
  circle : Circle
}

///|
pub fn BoundingCircle::new(center : Vec2, radius : Float) -> BoundingCircle {
  BoundingCircle::{ center, circle: Circle::new(radius) }
}

///|
pub fn BoundingCircle::radius(self : BoundingCircle) -> Float {
  self.circle.radius
}

///|
pub fn BoundingCircle::from_point_cloud(
  isometry : Isometry2d,
  points : Array[Vec2],
) -> BoundingCircle {
  if points.length() == 0 {
    return BoundingCircle::new(isometry.translation, 0.0F)
  }

  let transformed : Array[Vec2] = []
  for point in points {
    transformed.push(isometry.transform_point2(point))
  }

  let mut best : BoundingCircle? = None
  for point in transformed {
    let candidate = BoundingCircle::new(point, 0.0F)
    if bounded_circle_contains_all(candidate, transformed) {
      best = bounded_choose_smaller_circle(best, candidate)
    }
  }

  for i in 0..<transformed.length() {
    for j in (i + 1)..<transformed.length() {
      let candidate = bounded_circle_from_diameter(
        transformed[i],
        transformed[j],
      )
      if bounded_circle_contains_all(candidate, transformed) {
        best = bounded_choose_smaller_circle(best, candidate)
      }
    }
  }

  for i in 0..<transformed.length() {
    for j in (i + 1)..<transformed.length() {
      for k in (j + 1)..<transformed.length() {
        if bounded_circumcircle(transformed[i], transformed[j], transformed[k])
          is Some(candidate) {
          if bounded_circle_contains_all(candidate, transformed) {
            best = bounded_choose_smaller_circle(best, candidate)
          }
        }
      }
    }
  }

  match best {
    Some(circle) => circle
    None => {
      let aabb = Aabb2d::from_point_cloud(Isometry2d::identity(), transformed)
      let center = aabb.center()
      let mut radius = 0.0F
      for point in transformed {
        radius = bounded_max(radius, point.sub(center).length())
      }
      BoundingCircle::new(center, radius)
    }
  }
}

///|
pub fn BoundingCircle::contains(
  self : BoundingCircle,
  other : BoundingCircle,
) -> Bool {
  self.center.sub(other.center).length() + other.radius() <=
  self.radius() + 0.0001F
}

///|
pub fn BoundingCircle::merge(
  self : BoundingCircle,
  other : BoundingCircle,
) -> BoundingCircle {
  let delta = other.center.sub(self.center)
  let distance = delta.length()
  if self.radius() >= distance + other.radius() {
    return self
  }
  if other.radius() >= distance + self.radius() {
    return other
  }
  if distance <= 1.0e-6F {
    return BoundingCircle::new(
      self.center,
      bounded_max(self.radius(), other.radius()),
    )
  }
  let direction = delta.normalize_or_zero()
  let min_point = self.center.sub(direction.mul_scalar(self.radius()))
  let max_point = other.center.add(direction.mul_scalar(other.radius()))
  let center = min_point.add(max_point).mul_scalar(0.5F)
  BoundingCircle::new(center, max_point.sub(center).length())
}

///|
pub fn BoundingCircle::translated_by(
  self : BoundingCircle,
  translation : Vec2,
) -> BoundingCircle {
  BoundingCircle::new(self.center.add(translation), self.radius())
}

///|
pub fn BoundingCircle::transformed_by(
  self : BoundingCircle,
  translation : Vec2,
  _rotation : Rot2,
) -> BoundingCircle {
  BoundingCircle::new(self.center.add(translation), self.radius())
}

///|
pub fn BoundingCircle::closest_point(
  self : BoundingCircle,
  point : Vec2,
) -> Vec2 {
  let offset = point.sub(self.center)
  if offset.length_squared() <= self.radius() * self.radius() {
    point
  } else {
    self.center.add(offset.normalize_or_zero().mul_scalar(self.radius()))
  }
}

///|
pub fn BoundingCircle::intersects_circle(
  self : BoundingCircle,
  other : BoundingCircle,
) -> Bool {
  let radius_sum = self.radius() + other.radius()
  self.center.sub(other.center).length_squared() <= radius_sum * radius_sum
}

///|
pub fn BoundingCircle::intersects_aabb(
  self : BoundingCircle,
  other : Aabb2d,
) -> Bool {
  other.intersects_circle(self)
}

///|
pub impl Bounded2d for Circle with aabb_2d(self, isometry) {
  Aabb2d::new(isometry.translation, Vec2::new(self.radius, self.radius))
}

///|
pub impl Bounded2d for Circle with bounding_circle(self, isometry) {
  BoundingCircle::new(isometry.translation, self.radius)
}

///|
pub impl Bounded2d for Rectangle with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_rectangle_points(self))
}

///|
pub impl Bounded2d for Rectangle with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_rectangle_points(self))
}

///|
pub impl Bounded2d for Triangle2d with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, [self.a, self.b, self.c])
}

///|
pub impl Bounded2d for Triangle2d with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, [self.a, self.b, self.c])
}

///|
pub impl Bounded2d for Segment2d with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, [self.start, self.end])
}

///|
pub impl Bounded2d for Segment2d with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, [self.start, self.end])
}

///|
pub impl Bounded2d for Capsule2d with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_capsule_points(self))
}

///|
pub impl Bounded2d for Capsule2d with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_capsule_points(self))
}

///|
pub impl Bounded2d for RegularPolygon with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_polygon_points(self))
}

///|
pub impl Bounded2d for RegularPolygon with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_polygon_points(self))
}

///|
pub impl Bounded2d for Polyline2d with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, self.points)
}

///|
pub impl Bounded2d for Polyline2d with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, self.points)
}

///|
pub impl Bounded2d for Polygon with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded2d for Polygon with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded2d for ConvexPolygon with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded2d for ConvexPolygon with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded2d for Arc2d with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_arc_points(self))
}

///|
pub impl Bounded2d for Arc2d with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_arc_points(self))
}

///|
pub impl Bounded2d for CircularSector with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_sector_points(self))
}

///|
pub impl Bounded2d for CircularSector with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_sector_points(self))
}

///|
pub impl Bounded2d for CircularSegment with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_segment_points(self))
}

///|
pub impl Bounded2d for CircularSegment with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_segment_points(self))
}

///|
pub impl Bounded2d for Ellipse with aabb_2d(self, isometry) {
  Aabb2d::from_point_cloud(isometry, bounded_ellipse_points(self))
}

///|
pub impl Bounded2d for Ellipse with bounding_circle(self, isometry) {
  BoundingCircle::from_point_cloud(isometry, bounded_ellipse_points(self))
}

///|
pub impl Bounded2d for Annulus with aabb_2d(self, isometry) {
  Aabb2d::new(
    isometry.translation,
    Vec2::new(self.outer_radius, self.outer_radius),
  )
}

///|
pub impl Bounded2d for Annulus with bounding_circle(self, isometry) {
  BoundingCircle::new(isometry.translation, self.outer_radius)
}

///|
pub impl Bounded2d for Rhombus with aabb_2d(self, isometry) {
  let points = [
    Vec2::new(self.half_diagonal.x, 0.0F),
    Vec2::new(0.0F, self.half_diagonal.y),
    Vec2::new(-self.half_diagonal.x, 0.0F),
    Vec2::new(0.0F, -self.half_diagonal.y),
  ]
  Aabb2d::from_point_cloud(isometry, points)
}

///|
pub impl Bounded2d for Rhombus with bounding_circle(self, isometry) {
  let radius = sqrt(
    self.half_diagonal.x * self.half_diagonal.x +
    self.half_diagonal.y * self.half_diagonal.y,
  )
  BoundingCircle::new(isometry.translation, radius)
}

///|
pub impl Bounded2d for Line2d with aabb_2d(self, isometry) {
  let direction = isometry.rotation.mul_vec2(self.direction.as_vec2())
  let max_value = 1.0e12F
  let half_size = Vec2::new(
    if direction.x == 0.0F {
      0.0F
    } else {
      max_value
    },
    if direction.y == 0.0F {
      0.0F
    } else {
      max_value
    },
  )
  Aabb2d::new(isometry.translation, half_size)
}

///|
pub impl Bounded2d for Line2d with bounding_circle(self, isometry) {
  ignore(self)
  BoundingCircle::new(isometry.translation, 1.0e12F)
}

///|
pub impl Bounded2d for Plane2d with aabb_2d(self, isometry) {
  let normal = isometry.rotation.mul_vec2(self.normal.as_vec2())
  let max_value = 1.0e12F
  let half_size = Vec2::new(
    if bounded_abs(normal.x) == 1.0F {
      0.0F
    } else {
      max_value
    },
    if bounded_abs(normal.y) == 1.0F {
      0.0F
    } else {
      max_value
    },
  )
  Aabb2d::new(isometry.translation, half_size)
}

///|
pub impl Bounded2d for Plane2d with bounding_circle(self, isometry) {
  ignore(self)
  BoundingCircle::new(isometry.translation, 1.0e12F)
}

///|
fn bounded_rectangle_points(rectangle : Rectangle) -> Array[Vec2] {
  let half = rectangle.half_size
  [
    Vec2::new(-half.x, -half.y),
    Vec2::new(half.x, -half.y),
    Vec2::new(half.x, half.y),
    Vec2::new(-half.x, half.y),
  ]
}

///|
fn bounded_arc_points(arc : Arc2d) -> Array[Vec2] {
  let points : Array[Vec2] = []
  let segments = 32
  for index in 0..<=segments {
    let t = bounded_float_from_int(index) / bounded_float_from_int(segments)
    let angle = pi_half() + arc.half_angle - 2.0F * arc.half_angle * t
    points.push(Vec2::new(cos(angle) * arc.radius, sin(angle) * arc.radius))
  }
  points
}

///|
fn bounded_sector_points(sector : CircularSector) -> Array[Vec2] {
  let points = bounded_arc_points(
    Arc2d::new(sector.radius, sector.half_angle()),
  )
  [Vec2::zero(), ..points]
}

///|
fn bounded_segment_points(segment : CircularSegment) -> Array[Vec2] {
  let arc = Arc2d::new(segment.radius, segment.half_angle())
  let points = bounded_arc_points(arc)
  [arc.left_endpoint(), ..points, arc.right_endpoint()]
}

///|
fn bounded_ellipse_points(ellipse : Ellipse) -> Array[Vec2] {
  let points : Array[Vec2] = []
  let segments = 48
  for index in 0..<segments {
    let angle = 2.0F *
      pi() *
      bounded_float_from_int(index) /
      bounded_float_from_int(segments)
    points.push(
      Vec2::new(
        cos(angle) * ellipse.half_size.x,
        sin(angle) * ellipse.half_size.y,
      ),
    )
  }
  points
}

///|
fn bounded_capsule_points(capsule : Capsule2d) -> Array[Vec2] {
  let points : Array[Vec2] = []
  let arc_segments = if capsule.segments < 12 { 12 } else { capsule.segments }
  for index in 0..<=arc_segments {
    let t = bounded_float_from_int(index) / bounded_float_from_int(arc_segments)
    let angle = t * pi()
    points.push(
      Vec2::new(
        cos(angle) * capsule.radius,
        sin(angle) * capsule.radius + capsule.half_length,
      ),
    )
  }
  for index in 0..<=arc_segments {
    let t = bounded_float_from_int(index) / bounded_float_from_int(arc_segments)
    let angle = pi() + t * pi()
    points.push(
      Vec2::new(
        cos(angle) * capsule.radius,
        sin(angle) * capsule.radius - capsule.half_length,
      ),
    )
  }
  points
}

///|
fn bounded_polygon_points(polygon : RegularPolygon) -> Array[Vec2] {
  let safe_sides = if polygon.sides < 3 { 3 } else { polygon.sides }
  let points : Array[Vec2] = []
  for index in 0..<safe_sides {
    let angle = pi_half() +
      2.0F *
      pi() *
      bounded_float_from_int(index) /
      bounded_float_from_int(safe_sides)
    points.push(
      Vec2::new(cos(angle) * polygon.radius, sin(angle) * polygon.radius),
    )
  }
  points
}

///|
fn bounded_circle_contains_all(
  circle : BoundingCircle,
  points : Array[Vec2],
) -> Bool {
  let limit = circle.radius() * circle.radius() + 0.001F
  for point in points {
    if point.sub(circle.center).length_squared() > limit {
      return false
    }
  }
  true
}

///|
fn bounded_choose_smaller_circle(
  current : BoundingCircle?,
  candidate : BoundingCircle,
) -> BoundingCircle? {
  match current {
    Some(best) =>
      if candidate.radius() < best.radius() {
        Some(candidate)
      } else {
        Some(best)
      }
    None => Some(candidate)
  }
}

///|
fn bounded_circle_from_diameter(a : Vec2, b : Vec2) -> BoundingCircle {
  let center = a.add(b).mul_scalar(0.5F)
  BoundingCircle::new(center, a.sub(center).length())
}

///|
fn bounded_circumcircle(a : Vec2, b : Vec2, c : Vec2) -> BoundingCircle? {
  let divisor = 2.0F *
    (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
  if bounded_abs(divisor) < 0.00001F {
    return None
  }
  let a_sq = a.x * a.x + a.y * a.y
  let b_sq = b.x * b.x + b.y * b.y
  let c_sq = c.x * c.x + c.y * c.y
  let center = Vec2::new(
    (a_sq * (b.y - c.y) + b_sq * (c.y - a.y) + c_sq * (a.y - b.y)) / divisor,
    (a_sq * (c.x - b.x) + b_sq * (a.x - c.x) + c_sq * (b.x - a.x)) / divisor,
  )
  Some(BoundingCircle::new(center, a.sub(center).length()))
}

///|
fn bounded_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn bounded_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn bounded_min(lhs : Float, rhs : Float) -> Float {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn bounded_max(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn bounded_clamp(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn bounded_positive(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}
