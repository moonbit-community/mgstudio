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
#warnings("-unnecessary_annotation")
pub fn IsDefaultUiCamera::IsDefaultUiCamera() -> IsDefaultUiCamera {
  IsDefaultUiCamera::{  }
}

///|
pub struct UiTargetCamera {
  camera : @core.Entity
} derive(ToJson, FromJson)

///|
pub fn UiTargetCamera::new(camera : @core.Entity) -> UiTargetCamera {
  { camera, }
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
  { camera, }
}

///|
pub fn ComputedUiTargetCamera::ComputedUiTargetCamera() -> ComputedUiTargetCamera {
  { camera: @core.Entity::placeholder() }
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
  { scale_factor, physical_size }
}

///|
pub fn ComputedUiRenderTargetInfo::ComputedUiRenderTargetInfo() -> ComputedUiRenderTargetInfo {
  { scale_factor: 1.0F, physical_size: @math.IVec2::new(0, 0) }
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
pub(all) struct Val2 {
  x : Val
  y : Val
} derive(ToJson, FromJson)

///|
pub fn Val2::Val2() -> Val2 {
  { x: Val::zero(), y: Val::zero() }
}

///|
pub fn Val2::new(x : Val, y : Val) -> Val2 {
  { x, y }
}

///|
pub fn Val2::all(value : Val) -> Val2 {
  Val2::new(value, value)
}

///|
pub fn Val2::px(x : Float, y : Float) -> Val2 {
  Val2::new(Px(x), Px(y))
}

///|
pub fn Val2::percent(x : Float, y : Float) -> Val2 {
  Val2::new(Percent(x), Percent(y))
}

///|
pub fn Val2::resolve(
  self : Val2,
  scale_factor : Float,
  base_size : @math.Vec2,
  viewport_size : @math.Vec2,
) -> @math.Vec2 {
  let x = self.x.resolve(scale_factor, base_size.x, viewport_size) catch {
    _ => 0.0F
  }
  let y = self.y.resolve(scale_factor, base_size.y, viewport_size) catch {
    _ => 0.0F
  }
  @math.Vec2::new(x, y)
}

///|
pub(all) struct UiTransform {
  translation : Val2
  scale : @math.Vec2
  rotation : Float
} derive(ToJson, FromJson)

///|
pub fn UiTransform::UiTransform() -> UiTransform {
  { translation: Val2(), scale: @math.Vec2::new(1.0F, 1.0F), rotation: 0.0F }
}

///|
pub fn UiTransform::from_rotation(rotation : Float) -> UiTransform {
  { ..UiTransform(), rotation, }
}

///|
pub fn UiTransform::from_translation(translation : Val2) -> UiTransform {
  { ..UiTransform(), translation, }
}

///|
pub fn UiTransform::from_scale(scale : @math.Vec2) -> UiTransform {
  { ..UiTransform(), scale, }
}

///|
pub fn UiTransform::from_xy(x : Val, y : Val) -> UiTransform {
  UiTransform::from_translation(Val2::new(x, y))
}

///|
pub struct UiLayout {
  stack_index : Int
  rect : @math.Rect
  border : @sprite.BorderRect
  padding : @sprite.BorderRect
  border_radius : ResolvedBorderRadius
  outline_width : Float
  outline_offset : Float
} derive(ToJson, FromJson)

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  {
    stack_index: 0,
    rect,
    border: BorderRect(),
    padding: BorderRect(),
    border_radius: ResolvedBorderRadius(),
    outline_width: 0.0F,
    outline_offset: 0.0F,
  }
}

///|
pub fn UiLayout::from_computed(
  rect : @math.Rect,
  border : @sprite.BorderRect,
  padding : @sprite.BorderRect,
  border_radius : ResolvedBorderRadius,
  outline_width : Float,
  outline_offset : Float,
) -> UiLayout {
  {
    stack_index: 0,
    rect,
    border,
    padding,
    border_radius,
    outline_width,
    outline_offset,
  }
}

///|
pub fn UiLayout::with_stack_index(
  self : UiLayout,
  stack_index : Int,
) -> UiLayout {
  { ..self, stack_index, }
}

///|
pub fn UiLayout::stack_index(self : UiLayout) -> Int {
  self.stack_index
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
pub fn UiLayout::border(self : UiLayout) -> @sprite.BorderRect {
  self.border
}

///|
pub fn UiLayout::padding(self : UiLayout) -> @sprite.BorderRect {
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
pub fn UiLayout::content_inset(self : UiLayout) -> @sprite.BorderRect {
  @sprite.BorderRect::new(
    self.border.left + self.padding.left,
    self.border.right + self.padding.right,
    self.border.top + self.padding.top,
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
    BorderBox => @sprite.BorderRect::BorderRect()
    ContentBox => self.content_inset()
    PaddingBox => self.border
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
  if overflow.x == Visible {
    clip_rect = @math.Rect::new(
      @math.Vec2::new(-1.0F / 0.0F, clip_rect.min.y),
      @math.Vec2::new(1.0F / 0.0F, clip_rect.max.y),
    )
  }
  if overflow.y == Visible {
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
    let render_target_info = match camera_entity {
      Some(entity) => ui_compute_render_target_info(world, entity)
      None => ComputedUiRenderTargetInfo()
    }
    let (camera_id, camera_generation) = match camera_entity {
      Some(entity) => (entity.id, entity.generation)
      None => (-1, 0)
    }
    let physical_size = render_target_info.physical_size()
    ui_propagate_target_camera_subtree(
      world,
      root,
      camera_id,
      camera_generation,
      render_target_info.scale_factor(),
      physical_size.x,
      physical_size.y,
    )
  }
}
