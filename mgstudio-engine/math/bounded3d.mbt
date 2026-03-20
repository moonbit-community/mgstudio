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
pub(open) trait Bounded3d {
  aabb_3d(self : Self, isometry : Isometry3d) -> Aabb3d
  bounding_sphere(self : Self, isometry : Isometry3d) -> BoundingSphere
}

///|
pub struct Aabb3d {
  min : Vec3
  max : Vec3
}

///|
pub fn Aabb3d::new(center : Vec3, half_size : Vec3) -> Aabb3d {
  Aabb3d::{ min: center.sub(half_size), max: center.add(half_size) }
}

///|
pub fn Aabb3d::from_min_max(min : Vec3, max : Vec3) -> Aabb3d {
  Aabb3d::{ min, max }
}

///|
pub fn Aabb3d::from_point_cloud(
  isometry : Isometry3d,
  points : Array[Vec3],
) -> Aabb3d {
  if points.length() == 0 {
    return Aabb3d::new(isometry.translation, Vec3::zero())
  }
  let first = isometry.transform_point3(points[0])
  let mut min_x = first.x
  let mut min_y = first.y
  let mut min_z = first.z
  let mut max_x = first.x
  let mut max_y = first.y
  let mut max_z = first.z
  for point in points {
    let transformed = isometry.transform_point3(point)
    min_x = bounded3d_min(min_x, transformed.x)
    min_y = bounded3d_min(min_y, transformed.y)
    min_z = bounded3d_min(min_z, transformed.z)
    max_x = bounded3d_max(max_x, transformed.x)
    max_y = bounded3d_max(max_y, transformed.y)
    max_z = bounded3d_max(max_z, transformed.z)
  }
  Aabb3d::{
    min: Vec3::new(min_x, min_y, min_z),
    max: Vec3::new(max_x, max_y, max_z),
  }
}

///|
pub fn Aabb3d::center(self : Aabb3d) -> Vec3 {
  self.min.add(self.max).mul_scalar(0.5F)
}

///|
pub fn Aabb3d::half_size(self : Aabb3d) -> Vec3 {
  self.max.sub(self.min).mul_scalar(0.5F)
}

///|
pub fn Aabb3d::closest_point(self : Aabb3d, point : Vec3) -> Vec3 {
  Vec3::new(
    bounded3d_clamp(point.x, self.min.x, self.max.x),
    bounded3d_clamp(point.y, self.min.y, self.max.y),
    bounded3d_clamp(point.z, self.min.z, self.max.z),
  )
}

///|
pub fn Aabb3d::bounding_sphere(self : Aabb3d) -> BoundingSphere {
  let center = self.center()
  BoundingSphere::new(center, self.max.sub(center).length())
}

///|
pub fn Aabb3d::intersects_aabb(self : Aabb3d, other : Aabb3d) -> Bool {
  self.min.x <= other.max.x &&
  self.max.x >= other.min.x &&
  self.min.y <= other.max.y &&
  self.max.y >= other.min.y &&
  self.min.z <= other.max.z &&
  self.max.z >= other.min.z
}

///|
pub fn Aabb3d::intersects_sphere(self : Aabb3d, other : BoundingSphere) -> Bool {
  let closest = self.closest_point(other.center)
  closest.sub(other.center).length_squared() <= other.radius() * other.radius()
}

///|
pub struct BoundingSphere {
  center : Vec3
  sphere : Sphere
}

///|
pub fn BoundingSphere::new(center : Vec3, radius : Float) -> BoundingSphere {
  BoundingSphere::{ center, sphere: Sphere::new(radius) }
}

///|
pub fn BoundingSphere::radius(self : BoundingSphere) -> Float {
  self.sphere.radius
}

///|
pub fn BoundingSphere::from_point_cloud(
  isometry : Isometry3d,
  points : Array[Vec3],
) -> BoundingSphere {
  if points.length() == 0 {
    return BoundingSphere::new(isometry.translation, 0.0F)
  }
  let transformed : Array[Vec3] = []
  for point in points {
    transformed.push(isometry.transform_point3(point))
  }
  let center = bounded3d_point_cloud_center(transformed)
  let mut radius = 0.0F
  for point in transformed {
    radius = bounded3d_max(radius, point.sub(center).length())
  }
  BoundingSphere::new(center, radius)
}

///|
pub fn BoundingSphere::intersects_sphere(
  self : BoundingSphere,
  other : BoundingSphere,
) -> Bool {
  let radius_sum = self.radius() + other.radius()
  self.center.sub(other.center).length_squared() <= radius_sum * radius_sum
}

///|
pub fn BoundingSphere::intersects_aabb(
  self : BoundingSphere,
  other : Aabb3d,
) -> Bool {
  other.intersects_sphere(self)
}

///|
pub impl Bounded3d for Sphere with aabb_3d(self, isometry) {
  Aabb3d::new(isometry.translation, Vec3::splat(self.radius))
}

///|
pub impl Bounded3d for Sphere with bounding_sphere(self, isometry) {
  BoundingSphere::new(isometry.translation, self.radius)
}

///|
pub impl Bounded3d for Cuboid with aabb_3d(self, isometry) {
  let half = self.half_size
  let corners = [
    Vec3::new(-half.x, -half.y, -half.z),
    Vec3::new(half.x, -half.y, -half.z),
    Vec3::new(half.x, half.y, -half.z),
    Vec3::new(-half.x, half.y, -half.z),
    Vec3::new(-half.x, -half.y, half.z),
    Vec3::new(half.x, -half.y, half.z),
    Vec3::new(half.x, half.y, half.z),
    Vec3::new(-half.x, half.y, half.z),
  ]
  Aabb3d::from_point_cloud(isometry, corners)
}

///|
pub impl Bounded3d for Cuboid with bounding_sphere(self, isometry) {
  BoundingSphere::new(isometry.translation, self.half_size.length())
}

///|
pub impl Bounded3d for Cylinder with aabb_3d(self, isometry) {
  let points : Array[Vec3] = []
  let steps = 32
  for index in 0..<steps {
    let angle = 2.0F *
      pi() *
      bounded3d_float_from_int(index) /
      bounded3d_float_from_int(steps)
    let x = cos(angle) * self.radius
    let z = sin(angle) * self.radius
    points.push(Vec3::new(x, self.half_height, z))
    points.push(Vec3::new(x, -self.half_height, z))
  }
  Aabb3d::from_point_cloud(isometry, points)
}

///|
pub impl Bounded3d for Cylinder with bounding_sphere(self, isometry) {
  BoundingSphere::new(
    isometry.translation,
    sqrt(self.radius * self.radius + self.half_height * self.half_height),
  )
}

///|
pub impl Bounded3d for Capsule3d with aabb_3d(self, isometry) {
  let half = Vec3::new(self.radius, self.radius + self.half_length, self.radius)
  Aabb3d::from_point_cloud(isometry, [
    Vec3::new(-half.x, -half.y, -half.z),
    Vec3::new(half.x, -half.y, -half.z),
    Vec3::new(half.x, half.y, -half.z),
    Vec3::new(-half.x, half.y, -half.z),
    Vec3::new(-half.x, -half.y, half.z),
    Vec3::new(half.x, -half.y, half.z),
    Vec3::new(half.x, half.y, half.z),
    Vec3::new(-half.x, half.y, half.z),
  ])
}

///|
pub impl Bounded3d for Capsule3d with bounding_sphere(self, isometry) {
  BoundingSphere::new(isometry.translation, self.radius + self.half_length)
}

///|
pub impl Bounded3d for Triangle3d with aabb_3d(self, isometry) {
  Aabb3d::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for Triangle3d with bounding_sphere(self, isometry) {
  BoundingSphere::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for Tetrahedron with aabb_3d(self, isometry) {
  Aabb3d::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for Tetrahedron with bounding_sphere(self, isometry) {
  BoundingSphere::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for Segment3d with aabb_3d(self, isometry) {
  Aabb3d::from_point_cloud(isometry, [self.point1(), self.point2()])
}

///|
pub impl Bounded3d for Segment3d with bounding_sphere(self, isometry) {
  BoundingSphere::new(
    isometry.transform_point3(self.center()),
    self.length() * 0.5F,
  )
}

///|
pub impl Bounded3d for Polyline3d with aabb_3d(self, isometry) {
  Aabb3d::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for Polyline3d with bounding_sphere(self, isometry) {
  BoundingSphere::from_point_cloud(isometry, self.vertices)
}

///|
pub impl Bounded3d for InfinitePlane3d with aabb_3d(self, isometry) {
  ignore(self)
  Aabb3d::new(isometry.translation, Vec3::splat(1.0e12F))
}

///|
pub impl Bounded3d for InfinitePlane3d with bounding_sphere(self, isometry) {
  ignore(self)
  BoundingSphere::new(isometry.translation, 1.0e12F)
}

///|
pub impl Bounded3d for Line3d with aabb_3d(self, isometry) {
  ignore(self)
  Aabb3d::new(isometry.translation, Vec3::splat(1.0e12F))
}

///|
pub impl Bounded3d for Line3d with bounding_sphere(self, isometry) {
  ignore(self)
  BoundingSphere::new(isometry.translation, 1.0e12F)
}

///|
pub impl Bounded3d for Cone with aabb_3d(self, isometry) {
  let half_height = self.height * 0.5F
  let half = Vec3::new(self.radius, half_height, self.radius)
  Aabb3d::from_point_cloud(isometry, [
    Vec3::new(-half.x, -half.y, -half.z),
    Vec3::new(half.x, -half.y, -half.z),
    Vec3::new(half.x, -half.y, half.z),
    Vec3::new(-half.x, -half.y, half.z),
    Vec3::new(0.0F, half.y, 0.0F),
  ])
}

///|
pub impl Bounded3d for Cone with bounding_sphere(self, isometry) {
  let half_height = self.height * 0.5F
  BoundingSphere::new(
    isometry.translation,
    sqrt(self.radius * self.radius + half_height * half_height),
  )
}

///|
pub impl Bounded3d for ConicalFrustum with aabb_3d(self, isometry) {
  let half_height = self.height * 0.5F
  let radius = bounded3d_max(self.radius_top, self.radius_bottom)
  let half = Vec3::new(radius, half_height, radius)
  Aabb3d::from_point_cloud(isometry, [
    Vec3::new(-half.x, -half.y, -half.z),
    Vec3::new(half.x, -half.y, -half.z),
    Vec3::new(half.x, half.y, half.z),
    Vec3::new(-half.x, half.y, half.z),
  ])
}

///|
pub impl Bounded3d for ConicalFrustum with bounding_sphere(self, isometry) {
  let half_height = self.height * 0.5F
  BoundingSphere::new(
    isometry.translation,
    sqrt(
      bounded3d_max(self.radius_top, self.radius_bottom) *
      bounded3d_max(self.radius_top, self.radius_bottom) +
      half_height * half_height,
    ),
  )
}

///|
pub impl Bounded3d for Torus with aabb_3d(self, isometry) {
  let outer = self.outer_radius()
  Aabb3d::new(isometry.translation, Vec3::new(outer, self.minor_radius, outer))
}

///|
pub impl Bounded3d for Torus with bounding_sphere(self, isometry) {
  BoundingSphere::new(isometry.translation, self.outer_radius())
}

///|
fn bounded3d_point_cloud_center(points : Array[Vec3]) -> Vec3 {
  let mut sum = Vec3::zero()
  for point in points {
    sum = sum.add(point)
  }
  sum.mul_scalar(1.0F / bounded3d_float_from_int(points.length()))
}

///|
fn bounded3d_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn bounded3d_min(lhs : Float, rhs : Float) -> Float {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn bounded3d_max(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn bounded3d_clamp(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}
