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
  color : @color.Color,
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
  color : @color.Color,
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

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/cross.rs`.

///|
pub fn GizmoBuffer::cross(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  let axes = [
    @math.Vec3::new(half_size, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, half_size, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, half_size),
  ]
  for axis in axes {
    self.line(
      isometry.transform_point3(axis),
      isometry.transform_point3(gizmo_buffer_vec3_neg(axis)),
      color,
    )
  }
}

///|
pub fn GizmoBuffer::cross_2d(
  self : GizmoBuffer,
  isometry : Isometry2d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  let axes = [
    @math.Vec2::new(half_size, 0.0F),
    @math.Vec2::new(0.0F, half_size),
  ]
  for axis in axes {
    self.line_2d(
      isometry.transform_point(axis),
      isometry.transform_point(gizmo_buffer_vec2_neg(axis)),
      color,
    )
  }
}

///|
pub fn GizmoAsset::cross(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  self.buffer.cross(isometry, half_size, color)
}

///|
pub fn GizmoAsset::cross_2d(
  self : GizmoAsset,
  isometry : Isometry2d,
  half_size : Float,
  color : @color.Color,
) -> Unit {
  self.buffer.cross_2d(isometry, half_size, color)
}
