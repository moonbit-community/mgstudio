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
pub struct RayCast3d {
  origin : Vec3
  direction : Dir3
  max : Float
  direction_recip : Vec3
}

///|
pub fn RayCast3d::new(
  origin : Vec3,
  direction : Dir3,
  max : Float,
) -> RayCast3d {
  let dir = direction.as_vec3()
  let recip = Vec3::new(
    if raycast3d_abs(dir.x) <= 1.0e-8F {
      1.0e30F
    } else {
      1.0F / dir.x
    },
    if raycast3d_abs(dir.y) <= 1.0e-8F {
      1.0e30F
    } else {
      1.0F / dir.y
    },
    if raycast3d_abs(dir.z) <= 1.0e-8F {
      1.0e30F
    } else {
      1.0F / dir.z
    },
  )
  RayCast3d::{ origin, direction, max, direction_recip: recip }
}

///|
pub fn RayCast3d::from_ray(ray : Ray3d, max : Float) -> RayCast3d {
  RayCast3d::new(ray.origin, ray.direction, max)
}

///|
pub fn RayCast3d::direction_recip(self : RayCast3d) -> Vec3 {
  self.direction_recip
}

///|
pub fn RayCast3d::aabb_intersection_at(
  self : RayCast3d,
  aabb : Aabb3d,
) -> Float? {
  let direction = self.direction.as_vec3()
  let min = Vec3::new(
    if direction.x >= 0.0F {
      aabb.min.x
    } else {
      aabb.max.x
    },
    if direction.y >= 0.0F {
      aabb.min.y
    } else {
      aabb.max.y
    },
    if direction.z >= 0.0F {
      aabb.min.z
    } else {
      aabb.max.z
    },
  )
  let max = Vec3::new(
    if direction.x >= 0.0F {
      aabb.max.x
    } else {
      aabb.min.x
    },
    if direction.y >= 0.0F {
      aabb.max.y
    } else {
      aabb.min.y
    },
    if direction.z >= 0.0F {
      aabb.max.z
    } else {
      aabb.min.z
    },
  )
  let tmin = Vec3::new(
    (min.x - self.origin.x) * self.direction_recip.x,
    (min.y - self.origin.y) * self.direction_recip.y,
    (min.z - self.origin.z) * self.direction_recip.z,
  )
  let tmax = Vec3::new(
    (max.x - self.origin.x) * self.direction_recip.x,
    (max.y - self.origin.y) * self.direction_recip.y,
    (max.z - self.origin.z) * self.direction_recip.z,
  )
  let start = raycast3d_max(
    raycast3d_max(tmin.x, tmin.y),
    raycast3d_max(tmin.z, 0.0F),
  )
  let finish = raycast3d_min(
    raycast3d_min(tmax.x, tmax.y),
    raycast3d_min(tmax.z, self.max),
  )
  if start <= finish {
    Some(start)
  } else {
    None
  }
}

///|
pub fn RayCast3d::sphere_intersection_at(
  self : RayCast3d,
  sphere : BoundingSphere,
) -> Float? {
  let direction = self.direction.as_vec3()
  let offset = self.origin.sub(sphere.center)
  let projected = offset.dot(direction)
  let closest = offset.sub(direction.mul_scalar(projected))
  let distance_squared = sphere.radius() * sphere.radius() -
    closest.length_squared()
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
pub struct AabbCast3d {
  ray : RayCast3d
  aabb : Aabb3d
}

///|
pub fn AabbCast3d::new(
  aabb : Aabb3d,
  origin : Vec3,
  direction : Dir3,
  max : Float,
) -> AabbCast3d {
  AabbCast3d::{ ray: RayCast3d::new(origin, direction, max), aabb }
}

///|
pub fn AabbCast3d::from_ray(
  aabb : Aabb3d,
  ray : Ray3d,
  max : Float,
) -> AabbCast3d {
  AabbCast3d::new(aabb, ray.origin, ray.direction, max)
}

///|
pub fn AabbCast3d::aabb_collision_at(
  self : AabbCast3d,
  other : Aabb3d,
) -> Float? {
  let translated = Aabb3d::{
    min: other.min.sub(self.aabb.max),
    max: other.max.sub(self.aabb.min),
  }
  self.ray.aabb_intersection_at(translated)
}

///|
pub struct BoundingSphereCast {
  ray : RayCast3d
  sphere : BoundingSphere
}

///|
pub fn BoundingSphereCast::new(
  sphere : BoundingSphere,
  origin : Vec3,
  direction : Dir3,
  max : Float,
) -> BoundingSphereCast {
  BoundingSphereCast::{ ray: RayCast3d::new(origin, direction, max), sphere }
}

///|
pub fn BoundingSphereCast::from_ray(
  sphere : BoundingSphere,
  ray : Ray3d,
  max : Float,
) -> BoundingSphereCast {
  BoundingSphereCast::new(sphere, ray.origin, ray.direction, max)
}

///|
pub fn BoundingSphereCast::sphere_collision_at(
  self : BoundingSphereCast,
  other : BoundingSphere,
) -> Float? {
  let sphere = BoundingSphere::new(
    other.center.sub(self.sphere.center),
    other.radius() + self.sphere.radius(),
  )
  self.ray.sphere_intersection_at(sphere)
}

///|
fn raycast3d_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn raycast3d_min(lhs : Float, rhs : Float) -> Float {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn raycast3d_max(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}
