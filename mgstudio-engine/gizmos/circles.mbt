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
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  radius : Float,
  color : @color.Color,
) -> Ellipse2dBuilder {
  gizmos.circle_2d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_circle_3d(
  gizmos : Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> Unit {
  gizmos.circle_3d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_ellipse_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  half_size : @math.Vec2,
  color : @color.Color,
) -> Ellipse2dBuilder {
  gizmos.ellipse_2d(isometry, half_size, color)
}

///|
pub fn[Config] gizmo_sphere_3d(
  gizmos : Gizmos[Config],
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> Unit {
  gizmos.sphere_3d(isometry, radius, color)
}

///|
pub fn[Config] gizmo_draw_circle_shape_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  circle : @math.Circle,
  color : @color.Color,
) -> Ellipse2dBuilder {
  gizmos.circle_2d(isometry, circle.radius, color)
}

///|
pub fn[Config] gizmo_draw_arc_shape_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  arc : @math.Arc2d,
  color : @color.Color,
) -> Arc2dBuilder {
  let start = Isometry2d::new(
    isometry.translation,
    isometry.rotation - arc.half_angle,
  )
  gizmos.arc_2d(start, arc.half_angle * 2.0F, arc.radius, color)
}

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/circles.rs`.

///|
const RETAINED_DEFAULT_CIRCLE_RESOLUTION : Int = 32

///|
struct RetainedPendingEllipse {
  order : Int
  is_2d : Bool
  isometry2d : Isometry2d
  isometry3d : @math.Isometry3d
  half_size : @math.Vec2
  color : @color.Color
  mut resolution : Int
}

///|
struct RetainedPendingSphere {
  order : Int
  isometry : @math.Isometry3d
  radius : Float
  color : @color.Color
  mut resolution : Int
}

///|
fn retained_ellipse_points(
  half_size : @math.Vec2,
  resolution : Int,
) -> Array[@math.Vec2] {
  let steps = retained_max_int(resolution, 3)
  let points : Array[@math.Vec2] = []
  let total = steps + 1
  let denom = retained_float_from_int(steps)
  for i in 0..<total {
    let angle = RETAINED_TAU * retained_float_from_int(i) / denom
    let x = @math.cos(angle) * half_size.x
    let y = @math.sin(angle) * half_size.y
    points.push(@math.Vec2::new(x, y))
  }
  points
}

///|
pub struct RetainedEllipseBuilder {
  id : Int
  buffer : GizmoBuffer
}

///|
pub fn RetainedEllipseBuilder::resolution(
  self : RetainedEllipseBuilder,
  resolution : Int,
) -> RetainedEllipseBuilder {
  if self.id >= 0 && self.id < self.buffer.pending_ellipses.length() {
    self.buffer.pending_ellipses[self.id].resolution = retained_max_int(
      resolution, 3,
    )
  }
  self
}

///|
pub struct RetainedSphereBuilder {
  id : Int
  buffer : GizmoBuffer
}

///|
pub fn RetainedSphereBuilder::resolution(
  self : RetainedSphereBuilder,
  resolution : Int,
) -> RetainedSphereBuilder {
  if self.id >= 0 && self.id < self.buffer.pending_spheres.length() {
    self.buffer.pending_spheres[self.id].resolution = retained_max_int(
      resolution, 3,
    )
  }
  self
}

///|
pub fn GizmoBuffer::ellipse(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  half_size : @math.Vec2,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  let id = self.pending_ellipses.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_ellipses.push({
    order,
    is_2d: false,
    isometry2d: Isometry2d::identity(),
    isometry3d: isometry,
    half_size,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
  })
  { id, buffer: self }
}

///|
pub fn GizmoBuffer::ellipse_2d(
  self : GizmoBuffer,
  isometry : Isometry2d,
  half_size : @math.Vec2,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  let id = self.pending_ellipses.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_ellipses.push({
    order,
    is_2d: true,
    isometry2d: isometry,
    isometry3d: @math.Isometry3d::identity(),
    half_size,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
  })
  { id, buffer: self }
}

///|
pub fn GizmoBuffer::circle(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.ellipse(isometry, @math.Vec2::new(radius, radius), color)
}

///|
pub fn GizmoBuffer::circle_2d(
  self : GizmoBuffer,
  isometry : Isometry2d,
  radius : Float,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.ellipse_2d(isometry, @math.Vec2::new(radius, radius), color)
}

///|
pub fn GizmoBuffer::sphere(
  self : GizmoBuffer,
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> RetainedSphereBuilder {
  let id = self.pending_spheres.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_spheres.push({
    order,
    isometry,
    radius,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
  })
  { id, buffer: self }
}

///|
pub fn GizmoAsset::ellipse(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  half_size : @math.Vec2,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.buffer.ellipse(isometry, half_size, color)
}

///|
pub fn GizmoAsset::ellipse_2d(
  self : GizmoAsset,
  isometry : Isometry2d,
  half_size : @math.Vec2,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.buffer.ellipse_2d(isometry, half_size, color)
}

///|
pub fn GizmoAsset::circle(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.buffer.circle(isometry, radius, color)
}

///|
pub fn GizmoAsset::circle_2d(
  self : GizmoAsset,
  isometry : Isometry2d,
  radius : Float,
  color : @color.Color,
) -> RetainedEllipseBuilder {
  self.buffer.circle_2d(isometry, radius, color)
}

///|
pub fn GizmoAsset::sphere(
  self : GizmoAsset,
  isometry : @math.Isometry3d,
  radius : Float,
  color : @color.Color,
) -> RetainedSphereBuilder {
  self.buffer.sphere(isometry, radius, color)
}
