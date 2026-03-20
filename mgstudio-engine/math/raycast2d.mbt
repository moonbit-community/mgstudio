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
pub struct RayCast2d {
  ray : Ray2d
  max : Float
  direction_recip : Vec2
}

///|
pub fn RayCast2d::new(
  origin : Vec2,
  direction : Dir2,
  max : Float,
) -> RayCast2d {
  RayCast2d::from_ray(Ray2d::new(origin, direction), max)
}

///|
pub fn RayCast2d::from_ray(ray : Ray2d, max : Float) -> RayCast2d {
  let direction = ray.direction.as_vec2()
  let recip_x = if raycast2d_abs(direction.x) <= 1.0e-8F {
    1.0e30F
  } else {
    1.0F / direction.x
  }
  let recip_y = if raycast2d_abs(direction.y) <= 1.0e-8F {
    1.0e30F
  } else {
    1.0F / direction.y
  }
  RayCast2d::{ ray, max, direction_recip: Vec2::new(recip_x, recip_y) }
}

///|
pub fn RayCast2d::direction_recip(self : RayCast2d) -> Vec2 {
  self.direction_recip
}

///|
pub fn RayCast2d::aabb_intersection_at(
  self : RayCast2d,
  aabb : Aabb2d,
) -> Float? {
  raycast2d_aabb_intersection_at(self, aabb)
}

///|
pub fn RayCast2d::circle_intersection_at(
  self : RayCast2d,
  circle : BoundingCircle,
) -> Float? {
  let offset = self.ray.origin.sub(circle.center)
  let direction = self.ray.direction.as_vec2()
  let projected = offset.dot(direction)
  let perpendicular = offset.x * direction.y - offset.y * direction.x
  let distance_squared = circle.radius() * circle.radius() -
    perpendicular * perpendicular
  if distance_squared < 0.0F || projected > sqrt(distance_squared) {
    return None
  }
  let toi = -projected - sqrt(distance_squared)
  if toi > self.max {
    None
  } else {
    Some(if toi < 0.0F { 0.0F } else { toi })
  }
}

///|
pub fn RayCast2d::intersects_aabb(self : RayCast2d, aabb : Aabb2d) -> Bool {
  self.aabb_intersection_at(aabb) is Some(_)
}

///|
pub fn RayCast2d::intersects_circle(
  self : RayCast2d,
  circle : BoundingCircle,
) -> Bool {
  self.circle_intersection_at(circle) is Some(_)
}

///|
pub struct AabbCast2d {
  ray : RayCast2d
  aabb : Aabb2d
}

///|
pub fn AabbCast2d::new(
  aabb : Aabb2d,
  origin : Vec2,
  direction : Dir2,
  max : Float,
) -> AabbCast2d {
  AabbCast2d::from_ray(aabb, Ray2d::new(origin, direction), max)
}

///|
pub fn AabbCast2d::from_ray(
  aabb : Aabb2d,
  ray : Ray2d,
  max : Float,
) -> AabbCast2d {
  AabbCast2d::{ ray: RayCast2d::from_ray(ray, max), aabb }
}

///|
pub fn AabbCast2d::aabb_collision_at(
  self : AabbCast2d,
  other : Aabb2d,
) -> Float? {
  let translated = Aabb2d::{
    min: other.min.sub(self.aabb.max),
    max: other.max.sub(self.aabb.min),
  }
  self.ray.aabb_intersection_at(translated)
}

///|
pub struct BoundingCircleCast {
  ray : RayCast2d
  circle : BoundingCircle
}

///|
pub fn BoundingCircleCast::new(
  circle : BoundingCircle,
  origin : Vec2,
  direction : Dir2,
  max : Float,
) -> BoundingCircleCast {
  BoundingCircleCast::from_ray(circle, Ray2d::new(origin, direction), max)
}

///|
pub fn BoundingCircleCast::from_ray(
  circle : BoundingCircle,
  ray : Ray2d,
  max : Float,
) -> BoundingCircleCast {
  BoundingCircleCast::{ ray: RayCast2d::from_ray(ray, max), circle }
}

///|
pub fn BoundingCircleCast::circle_collision_at(
  self : BoundingCircleCast,
  other : BoundingCircle,
) -> Float? {
  let circle = BoundingCircle::new(
    other.center.sub(self.circle.center),
    other.radius() + self.circle.radius(),
  )
  self.ray.circle_intersection_at(circle)
}

///|
fn raycast2d_aabb_intersection_at(
  ray_cast : RayCast2d,
  aabb : Aabb2d,
) -> Float? {
  let direction = ray_cast.ray.direction.as_vec2()
  let (min_x, max_x) = if direction.x >= 0.0F {
    (aabb.min.x, aabb.max.x)
  } else {
    (aabb.max.x, aabb.min.x)
  }
  let (min_y, max_y) = if direction.y >= 0.0F {
    (aabb.min.y, aabb.max.y)
  } else {
    (aabb.max.y, aabb.min.y)
  }
  let tmin_x = (min_x - ray_cast.ray.origin.x) * ray_cast.direction_recip.x
  let tmin_y = (min_y - ray_cast.ray.origin.y) * ray_cast.direction_recip.y
  let tmax_x = (max_x - ray_cast.ray.origin.x) * ray_cast.direction_recip.x
  let tmax_y = (max_y - ray_cast.ray.origin.y) * ray_cast.direction_recip.y
  let tmin = raycast2d_max(raycast2d_max(tmin_x, tmin_y), 0.0F)
  let tmax = raycast2d_min(raycast2d_min(tmax_x, tmax_y), ray_cast.max)
  if tmin <= tmax {
    Some(tmin)
  } else {
    None
  }
}

///|
fn raycast2d_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn raycast2d_min(lhs : Float, rhs : Float) -> Float {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn raycast2d_max(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}
