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
// Bevy source: `bevy/crates/bevy_gizmos/src/circles.rs`.

///|
pub fn[Config] gizmo_circle_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  radius : Float,
  color : @sprite.Color,
) -> @sprite.Ellipse2dBuilder {
  gizmos.circle_2d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_circle_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : @sprite.Color,
) -> Unit {
  gizmos.circle_3d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_ellipse_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  half_size : @math.Vec2,
  color : @sprite.Color,
) -> @sprite.Ellipse2dBuilder {
  gizmos.ellipse_2d(isometry, half_size, color)
}

///|
pub fn[Config] gizmo_sphere_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : @sprite.Color,
) -> Unit {
  gizmos.sphere_3d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_draw_circle_shape_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  circle : @math.Circle,
  color : @sprite.Color,
) -> @sprite.Ellipse2dBuilder {
  gizmos.circle_2d(isometry, circle.radius, color)
}

///|
pub fn[Config] gizmo_draw_arc_shape_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  arc : @math.Arc2d,
  color : @sprite.Color,
) -> @sprite.Arc2dBuilder {
  let start = @sprite.Isometry2d::new(
    isometry.translation,
    isometry.rotation - arc.half_angle,
  )
  gizmos.arc_2d(start, arc.half_angle * 2.0F, arc.radius, color)
}
