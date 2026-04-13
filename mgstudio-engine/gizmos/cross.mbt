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
// Bevy source: `bevy/crates/bevy_gizmos/src/cross.rs`.

///|
pub fn[Config] gizmo_cross(
  gizmos : Gizmos[Config],
  isometry : @math.Isometry3d,
  half_size : Float,
  color : @sprite.Color,
) -> Unit {
  let axis_x = @math.Vec3::new(half_size, 0.0F, 0.0F)
  let axis_y = @math.Vec3::new(0.0F, half_size, 0.0F)
  let axis_z = @math.Vec3::new(0.0F, 0.0F, half_size)
  gizmos.line_3d(
    isometry.transform_point3(axis_x),
    isometry.transform_point3(axis_x.neg()),
    color,
  )
  gizmos.line_3d(
    isometry.transform_point3(axis_y),
    isometry.transform_point3(axis_y.neg()),
    color,
  )
  gizmos.line_3d(
    isometry.transform_point3(axis_z),
    isometry.transform_point3(axis_z.neg()),
    color,
  )
}

///|
pub fn[Config] gizmo_cross_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  half_size : Float,
  color : @sprite.Color,
) -> Unit {
  let axis_x = @math.Vec2::new(half_size, 0.0F)
  let axis_y = @math.Vec2::new(0.0F, half_size)
  gizmos.line_2d(
    isometry.transform_point(axis_x),
    isometry.transform_point(axis_x.mul_scalar(-1.0F)),
    color,
  )
  gizmos.line_2d(
    isometry.transform_point(axis_y),
    isometry.transform_point(axis_y.mul_scalar(-1.0F)),
    color,
  )
}
