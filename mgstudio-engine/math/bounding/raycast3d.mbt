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
// Bevy source: `bevy/crates/bevy_math/src/bounding/raycast3d.rs`.
pub using @math {type AabbCast3d}

///|
pub using @math {type BoundingSphereCast}

///|
pub using @math {type Ray3d}

///|
pub using @math {type RayCast3d}

///|
pub fn ray3d(origin : @math.Vec3, direction : @math.Dir3) -> @math.Ray3d {
  @math.Ray3d::new(origin, direction)
}

///|
pub fn ray_cast3d_from_ray(ray : @math.Ray3d, max_t : Float) -> @math.RayCast3d {
  @math.RayCast3d::from_ray(ray, max_t)
}

///|
pub fn aabb_cast3d_from_ray(
  aabb : @math.Aabb3d,
  ray : @math.Ray3d,
  max_t : Float,
) -> @math.AabbCast3d {
  @math.AabbCast3d::from_ray(aabb, ray, max_t)
}

///|
pub fn bounding_sphere_cast_from_ray(
  sphere : @math.BoundingSphere,
  ray : @math.Ray3d,
  max_t : Float,
) -> @math.BoundingSphereCast {
  @math.BoundingSphereCast::from_ray(sphere, ray, max_t)
}
