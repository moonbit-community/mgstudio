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
// Bevy source: `bevy/crates/bevy_gizmos/src/primitives/dim2.rs`.

///|
pub fn[Config] gizmo_draw_circle_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  circle : @math.Circle,
  color : @sprite.Color,
) -> @sprite.Ellipse2dBuilder {
  gizmos.circle_2d(isometry, circle.radius, color)
}

///|
pub fn[Config] gizmo_draw_rect_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  rect : @math.Rectangle,
  color : @sprite.Color,
) -> Unit {
  gizmos.rect_2d(isometry, rect.half_size.mul_scalar(2.0F), color)
}

///|
pub fn[Config] gizmo_draw_capsule_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  capsule : @math.Capsule2d,
  color : @sprite.Color,
) -> Unit {
  if capsule.half_length <= 0.0F {
    ignore(gizmos.circle_2d(isometry, capsule.radius, color))
    return
  }
  gizmos.rect_2d(
    isometry,
    @math.Vec2::new(capsule.radius * 2.0F, capsule.half_length * 2.0F),
    color,
  )
  let top_center = isometry.transform_point(
    @math.Vec2::new(0.0F, capsule.half_length),
  )
  let bottom_center = isometry.transform_point(
    @math.Vec2::new(0.0F, -capsule.half_length),
  )
  let cap_isometry_top = @sprite.Isometry2d::new(top_center, isometry.rotation)
  let cap_isometry_bottom = @sprite.Isometry2d::new(
    bottom_center,
    isometry.rotation,
  )
  ignore(gizmos.circle_2d(cap_isometry_top, capsule.radius, color))
  ignore(gizmos.circle_2d(cap_isometry_bottom, capsule.radius, color))
  let top_right = isometry.transform_point(
    @math.Vec2::new(capsule.radius, capsule.half_length),
  )
  let bottom_right = isometry.transform_point(
    @math.Vec2::new(capsule.radius, -capsule.half_length),
  )
  let top_left = isometry.transform_point(
    @math.Vec2::new(-capsule.radius, capsule.half_length),
  )
  let bottom_left = isometry.transform_point(
    @math.Vec2::new(-capsule.radius, -capsule.half_length),
  )
  gizmos.line_2d(top_right, bottom_right, color)
  gizmos.line_2d(top_left, bottom_left, color)
}
