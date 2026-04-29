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
// Bevy source: `bevy/crates/bevy_ui/src/ui_transform.rs`.
pub struct IsDefaultUiCamera {} derive(ToJson, FromJson)

///|
pub fn IsDefaultUiCamera::default() -> IsDefaultUiCamera {
  IsDefaultUiCamera::{  }
}

///|
pub struct UiTargetCamera {
  camera : @core.Entity
} derive(ToJson, FromJson)

///|
pub fn UiTargetCamera::new(camera : @core.Entity) -> UiTargetCamera {
  UiTargetCamera::{ camera, }
}

///|
pub fn UiTargetCamera::entity(self : UiTargetCamera) -> @core.Entity {
  self.camera
}

///|
pub struct ComputedUiTargetCamera {
  camera : @core.Entity
} derive(ToJson, FromJson)

///|
pub fn ComputedUiTargetCamera::new(
  camera : @core.Entity,
) -> ComputedUiTargetCamera {
  ComputedUiTargetCamera::{ camera, }
}

///|
pub fn ComputedUiTargetCamera::default() -> ComputedUiTargetCamera {
  ComputedUiTargetCamera::{ camera: @core.Entity::placeholder() }
}

///|
pub fn ComputedUiTargetCamera::get(
  self : ComputedUiTargetCamera,
) -> @core.Entity? {
  if self.camera.is_placeholder() {
    None
  } else {
    Some(self.camera)
  }
}

///|
pub struct ComputedUiRenderTargetInfo {
  scale_factor : Float
  physical_size : @math.IVec2
} derive(ToJson, FromJson)

///|
pub fn ComputedUiRenderTargetInfo::new(
  scale_factor : Float,
  physical_size : @math.IVec2,
) -> ComputedUiRenderTargetInfo {
  ComputedUiRenderTargetInfo::{ scale_factor, physical_size }
}

///|
pub fn ComputedUiRenderTargetInfo::default() -> ComputedUiRenderTargetInfo {
  ComputedUiRenderTargetInfo::{
    scale_factor: 1.0F,
    physical_size: @math.IVec2::new(0, 0),
  }
}

///|
pub fn ComputedUiRenderTargetInfo::scale_factor(
  self : ComputedUiRenderTargetInfo,
) -> Float {
  safe_scale_factor(self.scale_factor)
}

///|
pub fn ComputedUiRenderTargetInfo::physical_size(
  self : ComputedUiRenderTargetInfo,
) -> @math.IVec2 {
  self.physical_size
}

///|
pub fn ComputedUiRenderTargetInfo::logical_size(
  self : ComputedUiRenderTargetInfo,
) -> @math.Vec2 {
  let scale = self.scale_factor()
  @math.Vec2::new(
    int_to_float(self.physical_size.x) / scale,
    int_to_float(self.physical_size.y) / scale,
  )
}

///|
pub struct UiLayout {
  rect : @math.Rect
  border : @sprite.UiBorderRect
  padding : @sprite.UiBorderRect
  border_radius : ResolvedBorderRadius
  outline_width : Float
  outline_offset : Float
} derive(ToJson, FromJson)

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  UiLayout::{
    rect,
    border: @sprite.UiBorderRect::zero(),
    padding: @sprite.UiBorderRect::zero(),
    border_radius: ResolvedBorderRadius::default(),
    outline_width: 0.0F,
    outline_offset: 0.0F,
  }
}

///|
pub fn UiLayout::from_computed(
  rect : @math.Rect,
  border : @sprite.UiBorderRect,
  padding : @sprite.UiBorderRect,
  border_radius : ResolvedBorderRadius,
  outline_width : Float,
  outline_offset : Float,
) -> UiLayout {
  UiLayout::{
    rect,
    border,
    padding,
    border_radius,
    outline_width,
    outline_offset,
  }
}

///|
pub fn UiLayout::rect(self : UiLayout) -> @math.Rect {
  self.rect
}

///|
pub fn UiLayout::size(self : UiLayout) -> @math.Vec2 {
  self.rect.size()
}

///|
pub fn UiLayout::border(self : UiLayout) -> @sprite.UiBorderRect {
  self.border
}

///|
pub fn UiLayout::padding(self : UiLayout) -> @sprite.UiBorderRect {
  self.padding
}

///|
pub fn UiLayout::border_radius(self : UiLayout) -> ResolvedBorderRadius {
  self.border_radius
}

///|
pub fn UiLayout::outline_width(self : UiLayout) -> Float {
  self.outline_width
}

///|
pub fn UiLayout::outline_offset(self : UiLayout) -> Float {
  self.outline_offset
}

///|
pub fn UiLayout::outline_radius(self : UiLayout) -> ResolvedBorderRadius {
  self.border_radius.outline_radius(self.outline_width + self.outline_offset)
}

///|
pub fn UiLayout::is_empty(self : UiLayout) -> Bool {
  let size = self.size()
  size.x <= 0.0F || size.y <= 0.0F
}

///|
pub fn UiLayout::outlined_node_size(self : UiLayout) -> @math.Vec2 {
  let size = self.size()
  let offset = 2.0F * (self.outline_offset + self.outline_width)
  @math.Vec2::new(size.x + offset, size.y + offset)
}

///|
pub fn UiLayout::content_inset(self : UiLayout) -> @sprite.UiBorderRect {
  @sprite.UiBorderRect::new(
    self.border.left + self.padding.left,
    self.border.top + self.padding.top,
    self.border.right + self.padding.right,
    self.border.bottom + self.padding.bottom,
  )
}

///|
pub fn UiLayout::border_box(self : UiLayout) -> @math.Rect {
  let size = self.size()
  let half = @math.Vec2::new(size.x * 0.5F, size.y * 0.5F)
  @math.Rect::new(
    @math.Vec2::new(-half.x, -half.y),
    @math.Vec2::new(half.x, half.y),
  )
}

///|
pub fn UiLayout::padding_box(self : UiLayout) -> @math.Rect {
  let mut out = self.border_box()
  out = @math.Rect::new(
    @math.Vec2::new(out.min.x + self.border.left, out.min.y + self.border.top),
    @math.Vec2::new(
      out.max.x - self.border.right,
      out.max.y - self.border.bottom,
    ),
  )
  out
}

///|
pub fn UiLayout::content_box(self : UiLayout) -> @math.Rect {
  let inset = self.content_inset()
  let mut out = self.border_box()
  out = @math.Rect::new(
    @math.Vec2::new(out.min.x + inset.left, out.min.y + inset.top),
    @math.Vec2::new(out.max.x - inset.right, out.max.y - inset.bottom),
  )
  out
}

///|
pub fn UiLayout::resolve_clip_rect(
  self : UiLayout,
  overflow : Overflow,
  overflow_clip_margin : OverflowClipMargin,
) -> @math.Rect {
  let mut clip_rect = self.border_box()
  let clip_inset = match overflow_clip_margin.visual_box {
    OverflowClipBox::BorderBox => @sprite.UiBorderRect::zero()
    OverflowClipBox::ContentBox => self.content_inset()
    OverflowClipBox::PaddingBox => self.border
  }
  let margin = if overflow_clip_margin.margin < 0.0F {
    0.0F
  } else {
    overflow_clip_margin.margin
  }
  clip_rect = @math.Rect::new(
    @math.Vec2::new(
      clip_rect.min.x + clip_inset.left - margin,
      clip_rect.min.y + clip_inset.top - margin,
    ),
    @math.Vec2::new(
      clip_rect.max.x - clip_inset.right + margin,
      clip_rect.max.y - clip_inset.bottom + margin,
    ),
  )
  if overflow.x == OverflowAxis::Visible {
    clip_rect = @math.Rect::new(
      @math.Vec2::new(-1.0F / 0.0F, clip_rect.min.y),
      @math.Vec2::new(1.0F / 0.0F, clip_rect.max.y),
    )
  }
  if overflow.y == OverflowAxis::Visible {
    clip_rect = @math.Rect::new(
      @math.Vec2::new(clip_rect.min.x, -1.0F / 0.0F),
      @math.Vec2::new(clip_rect.max.x, 1.0F / 0.0F),
    )
  }
  clip_rect
}

///|
pub fn ui_propagate_target_cameras_system(world : @ecs.World) -> Unit {
  let roots = ui_collect_root_entities(world)
  let default_camera_entity = ui_select_default_camera_entity(world)
  for root in roots {
    let camera_entity = match
      (try! world.get_by_key(root, ecs_key_ui_target_camera)) {
      Some(target_camera) => Some(target_camera.entity())
      None => default_camera_entity
    }
    let computed_camera = match camera_entity {
      Some(entity) => ComputedUiTargetCamera::new(entity)
      None => ComputedUiTargetCamera::default()
    }
    let render_target_info = match camera_entity {
      Some(entity) => ui_compute_render_target_info(world, entity)
      None => ComputedUiRenderTargetInfo::default()
    }
    ui_propagate_target_camera_subtree(
      world, root, computed_camera, render_target_info,
    )
  }
}
