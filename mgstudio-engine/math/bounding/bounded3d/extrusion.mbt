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
// Bevy source: `bevy/crates/bevy_math/src/bounding/bounded3d/extrusion.rs`.
// `Milky2018/mgstudio/math` runtime owner.

///|
pub fn extrusion_aabb_3d(
  isometry : @math.Isometry3d,
  points : Array[@math.Vec3],
) -> @math.Aabb3d {
  @math.Aabb3d::from_point_cloud(isometry, points)
}

///|
pub fn extrusion_bounding_sphere(
  isometry : @math.Isometry3d,
  points : Array[@math.Vec3],
) -> @math.BoundingSphere {
  @math.BoundingSphere::from_point_cloud(isometry, points)
}
