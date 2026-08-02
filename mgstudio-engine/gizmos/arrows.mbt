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
// Bevy source: `bevy/crates/bevy_gizmos/src/arrows.rs`.

///|
pub fn[Config] gizmo_arrow_2d(
  gizmos : Gizmos[Config],
  start : @math.Vec2,
  end : @math.Vec2,
  color : @color.Color,
) -> ArrowBuilder {
  gizmos.arrow_2d(start, end, color)
}

///|
pub fn[Config] gizmo_arrow_3d(
  gizmos : Gizmos[Config],
  start : @math.Vec3,
  end : @math.Vec3,
  color : @color.Color,
) -> Unit {
  gizmos.arrow_3d(start, end, color)
}

///|
pub fn[Config] gizmo_axes_2d(
  gizmos : Gizmos[Config],
  isometry : Isometry2d,
  base_length : Float,
) -> Unit {
  gizmos.axes_2d(isometry, base_length)
}

///|
pub fn[Config] gizmo_axes_3d(
  gizmos : Gizmos[Config],
  transform : @transform.Transform,
  base_length : Float,
) -> Unit {
  gizmos.axes_3d(transform, base_length)
}

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/arrows.rs`.

///|
struct RetainedPendingArrow {
  order : Int
  start : @math.Vec3
  end : @math.Vec3
  color : @color.Color
  mut double_ended : Bool
  mut tip_length : Float
}

///|
fn GizmoBuffer::flush_pending_arrow_raw(
  self : GizmoBuffer,
  arrow : RetainedPendingArrow,
) -> Unit {
  if !self.enabled {
    return
  }
  self.line_raw(arrow.start, arrow.end, arrow.color)
  let pointing_end = arrow.end.sub(arrow.start).normalize()
  let rotation_end = @math.Quat::from_rotation_arc(
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    pointing_end,
  )
  self.flush_pending_arrow_tips_raw(
    arrow.end,
    rotation_end,
    arrow.tip_length,
    arrow.color,
  )
  if arrow.double_ended {
    let pointing_start = arrow.start.sub(arrow.end).normalize()
    let rotation_start = @math.Quat::from_rotation_arc(
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      pointing_start,
    )
    self.flush_pending_arrow_tips_raw(
      arrow.start,
      rotation_start,
      arrow.tip_length,
      arrow.color,
    )
  }
}

///|
fn GizmoBuffer::flush_pending_arrow_tips_raw(
  self : GizmoBuffer,
  anchor : @math.Vec3,
  rotation : @math.Quat,
  tip_length : Float,
  color : @color.Color,
) -> Unit {
  let tips = [
    @math.Vec3::new(-1.0F, 1.0F, 0.0F),
    @math.Vec3::new(-1.0F, 0.0F, 1.0F),
    @math.Vec3::new(-1.0F, -1.0F, 0.0F),
    @math.Vec3::new(-1.0F, 0.0F, -1.0F),
  ]
  for tip in tips {
    let tip_end = rotation
      .mul_vec3(tip.normalize().mul_scalar(tip_length))
      .add(anchor)
    self.line_raw(anchor, tip_end, color)
  }
}

///|
pub struct RetainedArrowBuilder {
  id : Int
  buffer : GizmoBuffer
}

///|
pub fn RetainedArrowBuilder::with_tip_length(
  self : RetainedArrowBuilder,
  length : Float,
) -> RetainedArrowBuilder {
  if self.id >= 0 && self.id < self.buffer.pending_arrows.length() {
    self.buffer.pending_arrows[self.id].tip_length = length
  }
  self
}

///|
pub fn RetainedArrowBuilder::with_double_end(
  self : RetainedArrowBuilder,
) -> RetainedArrowBuilder {
  if self.id >= 0 && self.id < self.buffer.pending_arrows.length() {
    self.buffer.pending_arrows[self.id].double_ended = true
  }
  self
}

///|
pub fn GizmoBuffer::arrow(
  self : GizmoBuffer,
  start : @math.Vec3,
  end : @math.Vec3,
  color : @color.Color,
) -> RetainedArrowBuilder {
  let id = self.pending_arrows.length()
  let order = self.pending_order_next
  self.pending_order_next = order + 1
  self.pending_arrows.push({
    order,
    start,
    end,
    color,
    double_ended: false,
    tip_length: end.sub(start).length() / 10.0F,
  })
  { id, buffer: self }
}

///|
pub fn GizmoBuffer::arrow_2d(
  self : GizmoBuffer,
  start : @math.Vec2,
  end : @math.Vec2,
  color : @color.Color,
) -> RetainedArrowBuilder {
  self.arrow(
    gizmo_buffer_vec2_to_vec3(start),
    gizmo_buffer_vec2_to_vec3(end),
    color,
  )
}

///|
pub fn[T : @transform.TransformPoint] GizmoBuffer::axes(
  self : GizmoBuffer,
  transform : T,
  base_length : Float,
) -> Unit {
  let start = transform.transform_point(@math.Vec3::zero())
  let end_x = transform.transform_point(
    @math.Vec3::new(base_length, 0.0F, 0.0F),
  )
  let end_y = transform.transform_point(
    @math.Vec3::new(0.0F, base_length, 0.0F),
  )
  let end_z = transform.transform_point(
    @math.Vec3::new(0.0F, 0.0F, base_length),
  )
  ignore(self.arrow(start, end_x, @color.Color::srgb(1.0F, 0.0F, 0.0F)))
  ignore(self.arrow(start, end_y, @color.Color::srgb(0.0F, 1.0F, 0.0F)))
  ignore(self.arrow(start, end_z, @color.Color::srgb(0.0F, 0.0F, 1.0F)))
}

///|
pub fn[T : @transform.TransformPoint] GizmoBuffer::axes_2d(
  self : GizmoBuffer,
  transform : T,
  base_length : Float,
) -> Unit {
  let start = transform.transform_point(@math.Vec3::zero())
  let end_x = transform.transform_point(
    @math.Vec3::new(base_length, 0.0F, 0.0F),
  )
  let end_y = transform.transform_point(
    @math.Vec3::new(0.0F, base_length, 0.0F),
  )
  ignore(
    self.arrow_2d(
      gizmo_buffer_vec3_xy(start),
      gizmo_buffer_vec3_xy(end_x),
      @color.Color::srgb(1.0F, 0.0F, 0.0F),
    ),
  )
  ignore(
    self.arrow_2d(
      gizmo_buffer_vec3_xy(start),
      gizmo_buffer_vec3_xy(end_y),
      @color.Color::srgb(0.0F, 1.0F, 0.0F),
    ),
  )
}

///|
pub fn GizmoAsset::arrow(
  self : GizmoAsset,
  start : @math.Vec3,
  end : @math.Vec3,
  color : @color.Color,
) -> RetainedArrowBuilder {
  self.buffer.arrow(start, end, color)
}

///|
pub fn GizmoAsset::arrow_2d(
  self : GizmoAsset,
  start : @math.Vec2,
  end : @math.Vec2,
  color : @color.Color,
) -> RetainedArrowBuilder {
  self.buffer.arrow_2d(start, end, color)
}

///|
pub fn[T : @transform.TransformPoint] GizmoAsset::axes(
  self : GizmoAsset,
  transform : T,
  base_length : Float,
) -> Unit {
  self.buffer.axes(transform, base_length)
}

///|
pub fn[T : @transform.TransformPoint] GizmoAsset::axes_2d(
  self : GizmoAsset,
  transform : T,
  base_length : Float,
) -> Unit {
  self.buffer.axes_2d(transform, base_length)
}
