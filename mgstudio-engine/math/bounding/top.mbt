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
// Bevy source: `bevy/crates/bevy_math/src/bounding/mod.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub fn[T : @math.Bounded2d] aabb_2d_of(
  shape : T,
  isometry : @math.Isometry2d,
) -> @math.Aabb2d {
  @math.aabb_2d_of(shape, isometry)
}

///|
pub fn[T : @math.Bounded2d] bounding_circle_of(
  shape : T,
  isometry : @math.Isometry2d,
) -> @math.BoundingCircle {
  @math.bounding_circle_of(shape, isometry)
}

///|
pub fn[T : @math.Bounded3d] aabb_3d_of(
  shape : T,
  isometry : @math.Isometry3d,
) -> @math.Aabb3d {
  @math.aabb_3d_of(shape, isometry)
}

///|
pub fn[T : @math.Bounded3d] bounding_sphere_of(
  shape : T,
  isometry : @math.Isometry3d,
) -> @math.BoundingSphere {
  @math.bounding_sphere_of(shape, isometry)
}
