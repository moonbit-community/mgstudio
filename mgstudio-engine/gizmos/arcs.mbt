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
// Bevy source: `bevy/crates/bevy_gizmos/src/arcs.rs`.

///|
pub fn[Config] gizmo_arc_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  arc_angle : Float,
  radius : Float,
  color : @color.Color,
) -> Arc2dBuilder {
  gizmos.arc_2d(isometry, arc_angle, radius, color)
}

///|
pub fn[Config] gizmo_arc_3d(
  gizmos : Gizmos[Config],
  isometry : @math.Isometry3d,
  angle : Float,
  radius : Float,
  color : @color.Color,
) -> Unit {
  gizmos.arc_3d(isometry, angle, radius, color)
}

///|
pub fn[Config] gizmo_short_arc_2d_between(
  gizmos : Gizmos[Config],
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> Arc2dBuilder {
  gizmos.short_arc_2d_between(center, from, to, color)
}

///|
pub fn[Config] gizmo_long_arc_2d_between(
  gizmos : Gizmos[Config],
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> Arc2dBuilder {
  gizmos.long_arc_2d_between(center, from, to, color)
}

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/arcs.rs`.

///|
fn retained_resolution_from_angle(angle : Float) -> Int {
  let ratio = retained_abs_float(angle) / RETAINED_TAU
  let raw = ratio * retained_float_from_int(RETAINED_DEFAULT_CIRCLE_RESOLUTION)
  let base = raw.to_int()
  let base_float = retained_float_from_int(base)
  let result = if raw > base_float { base + 1 } else { base }
  retained_max_int(result, 1)
}

///|
fn retained_long_arc_3d_angle(angle : Float) -> Float {
  if angle > 0.0F {
    RETAINED_TAU - angle
  } else if angle < 0.0F {
    -RETAINED_TAU - angle
  } else {
    0.0F
  }
}

///|
struct RetainedPendingArc {
  order : Int
  is_2d : Bool
  start_vertex : @math.Vec3
  isometry2d : Isometry2d
  isometry3d : @math.Isometry3d
  angle : Float
  radius : Float
  color : @color.Color
  mut resolution : Int
  mut has_resolution : Bool
}

///|
fn retained_arc_2d_points(
  arc_angle : Float,
  radius : Float,
  resolution : Int,
) -> Array[@math.Vec2] {
  let steps = retained_max_int(resolution, 1)
  let points : Array[@math.Vec2] = []
  let denom = retained_float_from_int(steps)
  for i in 0..<=steps {
    let angle = arc_angle * retained_float_from_int(i) / denom +
      RETAINED_HALF_PI
    points.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
  }
  points
}

///|
fn retained_arc_3d_points(
  start_vertex : @math.Vec3,
  isometry : @math.Isometry3d,
  angle : Float,
  radius : Float,
  resolution : Int,
) -> Array[@math.Vec3] {
  let steps = retained_max_int(resolution, 1)
  let clamped_angle = retained_clamp_float(angle, -RETAINED_TAU, RETAINED_TAU)
  let points : Array[@math.Vec3] = []
  let denom = retained_float_from_int(steps)
  for i in 0..<=steps {
    let fraction = retained_float_from_int(i) / denom
    let rotation = @math.Quat::from_rotation_y(clamped_angle * fraction)
    let rotated = @math.Isometry3d::new(@math.Vec3::zero(), rotation).transform_point3(
      start_vertex,
    )
    points.push(isometry.transform_point3(rotated.mul_scalar(radius)))
  }
  points
}

///|
pub struct RetainedArcBuilder {
  id : Int
  buffer : GizmoBuffer
}

///|
pub fn RetainedArcBuilder::resolution(
  self : RetainedArcBuilder,
  resolution : Int,
) -> RetainedArcBuilder {
  if self.id >= 0 && self.id < self.buffer.pending_arcs.length() {
    self.buffer.pending_arcs[self.id].resolution = retained_max_int(
      resolution, 1,
    )
    self.buffer.pending_arcs[self.id].has_resolution = true
  }
  self
}

///|
pub fn GizmoBuffer::arc_2d(
  self : GizmoBuffer,
  isometry : Isometry2d,
  arc_angle : Float,
  radius : Float,
  color : @color.Color,
) -> RetainedArcBuilder {
  let id = self.pending_arcs.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_arcs.push({
    order,
    is_2d: true,
    start_vertex: @math.Vec3::new(1.0F, 0.0F, 0.0F),
    isometry2d: isometry,
    isometry3d: @math.Isometry3d::identity(),
    angle: arc_angle,
    radius,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
    has_resolution: false,
  })
  { id, buffer: self }
}

///|
pub fn GizmoBuffer::arc_3d(
  self : GizmoBuffer,
  angle : Float,
  radius : Float,
  isometry : @math.Isometry3d,
  color : @color.Color,
) -> RetainedArcBuilder {
  let id = self.pending_arcs.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_arcs.push({
    order,
    is_2d: false,
    start_vertex: @math.Vec3::new(1.0F, 0.0F, 0.0F),
    isometry2d: Isometry2d::identity(),
    isometry3d: isometry,
    angle,
    radius,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
    has_resolution: false,
  })
  { id, buffer: self }
}

///|
fn GizmoBuffer::arc_2d_from_to(
  self : GizmoBuffer,
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
  long : Bool,
) -> RetainedArcBuilder {
  let from_axis = from.sub(center).normalize_or_zero()
  let to_axis = to.sub(center).normalize_or_zero()
  let rotation = @math.Vec2::new(0.0F, 1.0F).angle_to(from_axis)
  let arc_angle_raw = from_axis.angle_to(to_axis)
  let arc_angle = if long {
    arc_angle_raw - RETAINED_TAU
  } else {
    arc_angle_raw
  }
  self.arc_2d(
    Isometry2d::new(center, rotation),
    arc_angle,
    center.distance(from),
    color,
  )
}

///|
pub fn GizmoBuffer::short_arc_2d_between(
  self : GizmoBuffer,
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.arc_2d_from_to(center, from, to, color, false)
}

///|
pub fn GizmoBuffer::long_arc_2d_between(
  self : GizmoBuffer,
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.arc_2d_from_to(center, from, to, color, true)
}

///|
fn GizmoBuffer::arc_3d_from_to(
  self : GizmoBuffer,
  center : @math.Vec3,
  from : @math.Vec3,
  to : @math.Vec3,
  color : @color.Color,
  long : Bool,
) -> RetainedArcBuilder {
  let from_axis = from.sub(center).normalize_or_zero()
  let to_axis = to.sub(center).normalize_or_zero()
  let (up, angle_raw) = @math.Quat::from_rotation_arc(from_axis, to_axis).to_axis_angle()
  let angle = if long {
    retained_long_arc_3d_angle(angle_raw)
  } else {
    angle_raw
  }
  let radius = center.distance(from)
  let rotation = @math.Quat::from_rotation_arc(
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    up,
  )
  let start_vertex = rotation.inverse().mul_vec3(from_axis)
  let id = self.pending_arcs.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_arcs.push({
    order,
    is_2d: false,
    start_vertex,
    isometry2d: Isometry2d::identity(),
    isometry3d: @math.Isometry3d::new(center, rotation),
    angle,
    radius,
    color,
    resolution: RETAINED_DEFAULT_CIRCLE_RESOLUTION,
    has_resolution: false,
  })
  { id, buffer: self }
}

///|
pub fn GizmoBuffer::short_arc_3d_between(
  self : GizmoBuffer,
  center : @math.Vec3,
  from : @math.Vec3,
  to : @math.Vec3,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.arc_3d_from_to(center, from, to, color, false)
}

///|
pub fn GizmoBuffer::long_arc_3d_between(
  self : GizmoBuffer,
  center : @math.Vec3,
  from : @math.Vec3,
  to : @math.Vec3,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.arc_3d_from_to(center, from, to, color, true)
}

///|
pub fn GizmoAsset::arc_2d(
  self : GizmoAsset,
  isometry : Isometry2d,
  arc_angle : Float,
  radius : Float,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.arc_2d(isometry, arc_angle, radius, color)
}

///|
pub fn GizmoAsset::arc_3d(
  self : GizmoAsset,
  angle : Float,
  radius : Float,
  isometry : @math.Isometry3d,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.arc_3d(angle, radius, isometry, color)
}

///|
pub fn GizmoAsset::short_arc_2d_between(
  self : GizmoAsset,
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.short_arc_2d_between(center, from, to, color)
}

///|
pub fn GizmoAsset::long_arc_2d_between(
  self : GizmoAsset,
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.long_arc_2d_between(center, from, to, color)
}

///|
pub fn GizmoAsset::short_arc_3d_between(
  self : GizmoAsset,
  center : @math.Vec3,
  from : @math.Vec3,
  to : @math.Vec3,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.short_arc_3d_between(center, from, to, color)
}

///|
pub fn GizmoAsset::long_arc_3d_between(
  self : GizmoAsset,
  center : @math.Vec3,
  from : @math.Vec3,
  to : @math.Vec3,
  color : @color.Color,
) -> RetainedArcBuilder {
  self.buffer.long_arc_3d_between(center, from, to, color)
}
