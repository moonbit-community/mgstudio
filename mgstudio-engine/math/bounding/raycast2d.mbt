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
// Bevy source: `bevy/crates/bevy_math/src/bounding/raycast2d.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.
pub using @math {type AabbCast2d}

///|
pub using @math {type BoundingCircleCast}

///|
pub using @math {type Ray2d}

///|
pub using @math {type RayCast2d}

///|
pub fn ray2d(origin : @math.Vec2, direction : @math.Dir2) -> @math.Ray2d {
  @math.Ray2d::new(origin, direction)
}

///|
pub fn ray_cast2d_from_ray(ray : @math.Ray2d, max_t : Float) -> @math.RayCast2d {
  @math.RayCast2d::from_ray(ray, max_t)
}

///|
pub fn aabb_cast2d_from_ray(
  aabb : @math.Aabb2d,
  ray : @math.Ray2d,
  max_t : Float,
) -> @math.AabbCast2d {
  @math.AabbCast2d::from_ray(aabb, ray, max_t)
}

///|
pub fn bounding_circle_cast_from_ray(
  circle : @math.BoundingCircle,
  ray : @math.Ray2d,
  max_t : Float,
) -> @math.BoundingCircleCast {
  @math.BoundingCircleCast::from_ray(circle, ray, max_t)
}
