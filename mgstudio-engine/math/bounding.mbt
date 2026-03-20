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
/// Shared surface for bounding-volume modules.

///|
pub fn[T : Bounded2d] aabb_2d_of(shape : T, isometry : Isometry2d) -> Aabb2d {
  shape.aabb_2d(isometry)
}

///|
pub fn[T : Bounded2d] bounding_circle_of(
  shape : T,
  isometry : Isometry2d,
) -> BoundingCircle {
  shape.bounding_circle(isometry)
}

///|
pub fn[T : Bounded3d] aabb_3d_of(shape : T, isometry : Isometry3d) -> Aabb3d {
  shape.aabb_3d(isometry)
}

///|
pub fn[T : Bounded3d] bounding_sphere_of(
  shape : T,
  isometry : Isometry3d,
) -> BoundingSphere {
  shape.bounding_sphere(isometry)
}
