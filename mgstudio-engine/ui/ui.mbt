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
/// Bevy-aligned UI (in progress).
///
/// Baseline: Bevy v0.15.3 (see docs/BEVY_BASELINE.md).

///|
/// Bevy-aligned display (matches Taffy).
pub(all) enum Display {
  Block
  Flex
  Grid
  None
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned position type (subset).
pub(all) enum PositionType {
  Relative
  Absolute
} derive(Eq, Show, ToJson, FromJson)

///|
pub(all) enum OverflowAxis {
  Clip
  Hidden
  Scroll
  Visible
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct Overflow {
  x : OverflowAxis
  y : OverflowAxis
} derive(ToJson, FromJson)

///|
pub fn Overflow::new(x : OverflowAxis, y : OverflowAxis) -> Overflow {
  Overflow::{ x, y }
}

///|
pub fn Overflow::default() -> Overflow {
  Overflow::new(OverflowAxis::Visible, OverflowAxis::Visible)
}

///|
pub(all) enum OverflowClipBox {
  BorderBox
  PaddingBox
  ContentBox
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct OverflowClipMargin {
  visual_box : OverflowClipBox
  margin : Float
} derive(ToJson, FromJson)

///|
pub fn OverflowClipMargin::default() -> OverflowClipMargin {
  OverflowClipMargin::{ visual_box: OverflowClipBox::ContentBox, margin: 0.0F }
}

///|
pub fn OverflowClipMargin::new(
  visual_box : OverflowClipBox,
  margin : Float,
) -> OverflowClipMargin {
  OverflowClipMargin::{ visual_box, margin }
}

///|
pub fn OverflowClipMargin::content_box() -> OverflowClipMargin {
  OverflowClipMargin::new(OverflowClipBox::ContentBox, 0.0F)
}

///|
pub fn OverflowClipMargin::padding_box() -> OverflowClipMargin {
  OverflowClipMargin::new(OverflowClipBox::PaddingBox, 0.0F)
}

///|
pub fn OverflowClipMargin::border_box() -> OverflowClipMargin {
  OverflowClipMargin::new(OverflowClipBox::BorderBox, 0.0F)
}

///|
pub fn OverflowClipMargin::with_margin(
  self : OverflowClipMargin,
  margin : Float,
) -> OverflowClipMargin {
  OverflowClipMargin::{ ..self, margin, }
}

///|
/// Bevy-aligned flex direction.
pub(all) enum FlexDirection {
  Column
  ColumnReverse
  Row
  RowReverse
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned flex wrap.
pub(all) enum FlexWrap {
  NoWrap
  Wrap
  WrapReverse
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned justify content.
pub(all) enum JustifyContent {
  Center
  Default
  End
  FlexEnd
  FlexStart
  SpaceAround
  SpaceBetween
  SpaceEvenly
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned justify items.
pub(all) enum JustifyItems {
  Baseline
  Center
  Default
  End
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned justify self.
pub(all) enum JustifySelf {
  Auto
  Baseline
  Center
  End
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned align items.
pub(all) enum AlignItems {
  Baseline
  Center
  Default
  End
  FlexEnd
  FlexStart
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned align self.
pub(all) enum AlignSelf {
  Auto
  Baseline
  Center
  End
  FlexEnd
  FlexStart
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned align content.
pub(all) enum AlignContent {
  Center
  Default
  End
  FlexEnd
  FlexStart
  SpaceAround
  SpaceBetween
  SpaceEvenly
  Start
  Stretch
} derive(Eq, Show, ToJson, FromJson)

///|
pub(all) enum GridAutoFlow {
  Column
  ColumnDense
  Row
  RowDense
} derive(Eq, Show, ToJson, FromJson)

///|
pub(all) enum GridTrack {
  Auto
  Px(Float)
  Percent(Float)
  Fr(Float)
  MinContent
  MaxContent
} derive(Eq, Show, ToJson, FromJson)

///|
pub(all) enum GridTrackRepetition {
  Count(Int)
  AutoFill
  AutoFit
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct RepeatedGridTrack {
  repetition : GridTrackRepetition
  tracks : Array[GridTrack]
} derive(ToJson, FromJson)

///|
pub fn RepeatedGridTrack::new(
  repetition : GridTrackRepetition,
  tracks : Array[GridTrack],
) -> RepeatedGridTrack {
  RepeatedGridTrack::{ repetition, tracks }
}

///|
pub fn RepeatedGridTrack::default() -> RepeatedGridTrack {
  RepeatedGridTrack::{
    repetition: GridTrackRepetition::Count(1),
    tracks: [GridTrack::Auto],
  }
}

///|
pub struct GridPlacement {
  start : Int?
  span : Int?
  end : Int?
} derive(ToJson, FromJson)

///|
pub fn GridPlacement::default() -> GridPlacement {
  GridPlacement::{ start: None, span: Some(1), end: None }
}

///|
pub fn GridPlacement::auto() -> GridPlacement {
  GridPlacement::default()
}

///|
pub fn GridPlacement::span(span : Int) -> GridPlacement {
  if span == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ start: None, end: None, span: Some(span) }
  }
}

///|
pub fn GridPlacement::start(start : Int) -> GridPlacement {
  if start == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ ..GridPlacement::default(), start: Some(start) }
  }
}

///|
pub fn GridPlacement::end(end : Int) -> GridPlacement {
  if end == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ ..GridPlacement::default(), end: Some(end) }
  }
}

///|
pub fn GridPlacement::start_span(start : Int, span : Int) -> GridPlacement {
  if start == 0 || span == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ start: Some(start), end: None, span: Some(span) }
  }
}

///|
pub fn GridPlacement::start_end(start : Int, end : Int) -> GridPlacement {
  if start == 0 || end == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ start: Some(start), end: Some(end), span: None }
  }
}

///|
pub fn GridPlacement::end_span(end : Int, span : Int) -> GridPlacement {
  if end == 0 || span == 0 {
    GridPlacement::default()
  } else {
    GridPlacement::{ start: None, end: Some(end), span: Some(span) }
  }
}

///|
/// The style of a UI node (Bevy v0.15.3-aligned surface).
pub(all) struct Node {
  display : Display
  position_type : PositionType
  overflow : Overflow
  overflow_clip_margin : OverflowClipMargin
  left : Val
  right : Val
  top : Val
  bottom : Val
  width : Val
  height : Val
  min_width : Val
  min_height : Val
  max_width : Val
  max_height : Val
  aspect_ratio : Float?
  align_items : AlignItems
  justify_items : JustifyItems
  align_self : AlignSelf
  justify_self : JustifySelf
  align_content : AlignContent
  justify_content : JustifyContent
  margin : UiRect
  padding : UiRect
  border : UiRect
  flex_direction : FlexDirection
  flex_wrap : FlexWrap
  flex_grow : Float
  flex_shrink : Float
  flex_basis : Val
  row_gap : Val
  column_gap : Val
  grid_auto_flow : GridAutoFlow
  grid_template_rows : Array[RepeatedGridTrack]
  grid_template_columns : Array[RepeatedGridTrack]
  grid_auto_rows : Array[GridTrack]
  grid_auto_columns : Array[GridTrack]
  grid_row : GridPlacement
  grid_column : GridPlacement
} derive(ToJson, FromJson)

///|
pub fn Node::default() -> Node {
  Node::{
    display: Display::Flex,
    position_type: PositionType::Relative,
    overflow: Overflow::default(),
    overflow_clip_margin: OverflowClipMargin::default(),
    left: Val::Auto,
    right: Val::Auto,
    top: Val::Auto,
    bottom: Val::Auto,
    width: Val::Auto,
    height: Val::Auto,
    min_width: Val::Auto,
    min_height: Val::Auto,
    max_width: Val::Auto,
    max_height: Val::Auto,
    aspect_ratio: None,
    align_items: AlignItems::Default,
    justify_items: JustifyItems::Default,
    align_self: AlignSelf::Auto,
    justify_self: JustifySelf::Auto,
    align_content: AlignContent::Default,
    justify_content: JustifyContent::Default,
    margin: UiRect::default(),
    padding: UiRect::default(),
    border: UiRect::default(),
    flex_direction: FlexDirection::Row,
    flex_wrap: FlexWrap::NoWrap,
    flex_grow: 0.0F,
    flex_shrink: 1.0F,
    flex_basis: Val::Auto,
    row_gap: Val::Px(0.0F),
    column_gap: Val::Px(0.0F),
    grid_auto_flow: GridAutoFlow::Row,
    grid_template_rows: [],
    grid_template_columns: [],
    grid_auto_rows: [],
    grid_auto_columns: [],
    grid_row: GridPlacement::default(),
    grid_column: GridPlacement::default(),
  }
}

///|
pub fn Node::with_position_type(
  self : Node,
  position_type : PositionType,
) -> Node {
  Node::{ ..self, position_type, }
}

///|
pub fn Node::with_display(self : Node, display : Display) -> Node {
  Node::{ ..self, display, }
}

///|
pub fn Node::with_overflow(self : Node, overflow : Overflow) -> Node {
  Node::{ ..self, overflow, }
}

///|
pub fn Node::with_overflow_clip_margin(
  self : Node,
  overflow_clip_margin : OverflowClipMargin,
) -> Node {
  Node::{ ..self, overflow_clip_margin, }
}

///|
pub fn Node::with_padding(self : Node, padding : UiRect) -> Node {
  Node::{ ..self, padding, }
}

///|
pub fn Node::with_margin(self : Node, margin : UiRect) -> Node {
  Node::{ ..self, margin, }
}

///|
pub fn Node::with_border(self : Node, border : UiRect) -> Node {
  Node::{ ..self, border, }
}

///|
pub fn Node::with_left(self : Node, left : Val) -> Node {
  Node::{ ..self, left, }
}

///|
pub fn Node::with_right(self : Node, right : Val) -> Node {
  Node::{ ..self, right, }
}

///|
pub fn Node::with_top(self : Node, top : Val) -> Node {
  Node::{ ..self, top, }
}

///|
pub fn Node::with_bottom(self : Node, bottom : Val) -> Node {
  Node::{ ..self, bottom, }
}

///|
pub fn Node::with_width(self : Node, width : Val) -> Node {
  Node::{ ..self, width, }
}

///|
pub fn Node::with_height(self : Node, height : Val) -> Node {
  Node::{ ..self, height, }
}

///|
pub fn Node::with_justify_content(
  self : Node,
  justify_content : JustifyContent,
) -> Node {
  Node::{ ..self, justify_content, }
}

///|
pub fn Node::with_align_items(self : Node, align_items : AlignItems) -> Node {
  Node::{ ..self, align_items, }
}

///|
pub fn Node::with_flex_direction(
  self : Node,
  flex_direction : FlexDirection,
) -> Node {
  Node::{ ..self, flex_direction, }
}

///|
pub fn Node::with_flex_grow(self : Node, flex_grow : Float) -> Node {
  Node::{ ..self, flex_grow, }
}

///|
pub fn Node::with_flex_shrink(self : Node, flex_shrink : Float) -> Node {
  Node::{ ..self, flex_shrink, }
}

///|
pub fn Node::with_flex_basis(self : Node, flex_basis : Val) -> Node {
  Node::{ ..self, flex_basis, }
}

///|
pub fn Node::with_row_gap(self : Node, row_gap : Val) -> Node {
  Node::{ ..self, row_gap, }
}

///|
pub fn Node::with_column_gap(self : Node, column_gap : Val) -> Node {
  Node::{ ..self, column_gap, }
}

///|
pub fn Node::with_grid_template_rows(
  self : Node,
  grid_template_rows : Array[RepeatedGridTrack],
) -> Node {
  Node::{ ..self, grid_template_rows, }
}

///|
pub fn Node::with_grid_template_columns(
  self : Node,
  grid_template_columns : Array[RepeatedGridTrack],
) -> Node {
  Node::{ ..self, grid_template_columns, }
}

///|
pub struct GhostNode {} derive(ToJson, FromJson)

///|
pub fn GhostNode::default() -> GhostNode {
  GhostNode::{  }
}

///|
pub struct UiRoot {} derive(ToJson, FromJson)

///|
pub fn UiRoot::default() -> UiRoot {
  UiRoot::{  }
}

///|
pub struct UiImage {
  color : @sprite.Color
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.Rect?
} derive(ToJson, FromJson)

///|
pub fn UiImage::new(image : @asset.Handle[@asset.Image]) -> UiImage {
  UiImage::{
    color: @sprite.Color::white(),
    image,
    texture_atlas: None,
    flip_x: false,
    flip_y: false,
    rect: None,
  }
}

///|
pub fn UiImage::with_color(self : UiImage, color : @sprite.Color) -> UiImage {
  UiImage::{ ..self, color, }
}

///|
pub fn UiImage::with_texture_atlas(
  self : UiImage,
  texture_atlas : @asset.TextureAtlas?,
) -> UiImage {
  UiImage::{ ..self, texture_atlas, }
}

///|
pub fn UiImage::with_flip_x(self : UiImage) -> UiImage {
  UiImage::{ ..self, flip_x: true }
}

///|
pub fn UiImage::with_flip_y(self : UiImage) -> UiImage {
  UiImage::{ ..self, flip_y: true }
}

///|
pub fn UiImage::with_rect(self : UiImage, rect : @math.Rect?) -> UiImage {
  UiImage::{ ..self, rect, }
}

///|

///|
/// Controls how an image widget is altered to fit within layout constraints.
///
/// This is Bevy-aligned (`NodeImageMode` / `ImageNode`), but currently only
/// `Auto` and `Stretch` are always supported, with `Sliced` / `Tiled` backed by
/// the texture slicing shader pipeline.

///|
/// Pixel padding for 9-slicing borders (Bevy `BorderRect`).
pub struct BorderRect {
  left : Float
  right : Float
  top : Float
  bottom : Float
} derive(ToJson, FromJson)

///|
pub fn BorderRect::new(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> BorderRect {
  BorderRect::{ left, right, top, bottom }
}

///|
pub fn BorderRect::square(value : Float) -> BorderRect {
  BorderRect::{ left: value, right: value, top: value, bottom: value }
}

///|
pub fn BorderRect::rectangle(
  horizontal : Float,
  vertical : Float,
) -> BorderRect {
  BorderRect::{
    left: horizontal,
    right: horizontal,
    top: vertical,
    bottom: vertical,
  }
}

///|
pub fn BorderRect::default() -> BorderRect {
  BorderRect::square(0.0F)
}

///|
/// Defines how a texture slice scales when resized (Bevy `SliceScaleMode`).
pub(all) enum SliceScaleMode {
  Stretch
  Tile(Float)
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn SliceScaleMode::default() -> SliceScaleMode {
  SliceScaleMode::Stretch
}

///|
/// 9-slicing configuration (Bevy `TextureSlicer`).
pub struct TextureSlicer {
  border : BorderRect
  center_scale_mode : SliceScaleMode
  sides_scale_mode : SliceScaleMode
  max_corner_scale : Float
} derive(ToJson, FromJson)

///|
pub fn TextureSlicer::new(border : BorderRect) -> TextureSlicer {
  TextureSlicer::{
    border,
    center_scale_mode: SliceScaleMode::Stretch,
    sides_scale_mode: SliceScaleMode::Stretch,
    max_corner_scale: 1.0F,
  }
}

///|
pub fn TextureSlicer::default() -> TextureSlicer {
  TextureSlicer::new(BorderRect::default())
}

///|
pub fn TextureSlicer::with_center_scale_mode(
  self : TextureSlicer,
  center_scale_mode : SliceScaleMode,
) -> TextureSlicer {
  TextureSlicer::{ ..self, center_scale_mode, }
}

///|
pub fn TextureSlicer::with_sides_scale_mode(
  self : TextureSlicer,
  sides_scale_mode : SliceScaleMode,
) -> TextureSlicer {
  TextureSlicer::{ ..self, sides_scale_mode, }
}

///|
pub fn TextureSlicer::with_max_corner_scale(
  self : TextureSlicer,
  max_corner_scale : Float,
) -> TextureSlicer {
  TextureSlicer::{ ..self, max_corner_scale, }
}

///|
pub(all) enum NodeImageMode {
  /// Size is determined by the source image, then clamped by layout constraints.
  Auto
  /// The image is resized to match the node's layout size (ignores aspect ratio).
  Stretch
  /// 9-sliced scaling using a `TextureSlicer`.
  Sliced(TextureSlicer)
  /// Tiled scaling for the full texture region.
  Tiled(Bool, Bool, Float)
} derive(ToJson, FromJson)

///|
pub fn NodeImageMode::default() -> NodeImageMode {
  NodeImageMode::Auto
}

///|
pub fn NodeImageMode::uses_slices(self : NodeImageMode) -> Bool {
  match self {
    NodeImageMode::Sliced(_) => true
    NodeImageMode::Tiled(_, _, _) => true
    _ => false
  }
}

///|
/// A UI node that renders an image (Bevy v0.15.3 `ImageNode`).
pub struct ImageNode {
  color : @sprite.Color
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.Rect?
  image_mode : NodeImageMode
} derive(ToJson, FromJson)

///|
pub fn ImageNode::default() -> ImageNode {
  ImageNode::{
    color: @sprite.Color::white(),
    image: @asset.asset_transparent_texture(),
    texture_atlas: None,
    flip_x: false,
    flip_y: false,
    rect: None,
    image_mode: NodeImageMode::Auto,
  }
}

///|
pub fn ImageNode::new(image : @asset.Handle[@asset.Image]) -> ImageNode {
  ImageNode::{ ..ImageNode::default(), image, }
}

///|
pub fn ImageNode::from_atlas_image(
  image : @asset.Handle[@asset.Image],
  texture_atlas : @asset.TextureAtlas,
) -> ImageNode {
  ImageNode::new(image).with_texture_atlas(Some(texture_atlas))
}

///|
pub fn ImageNode::with_color(
  self : ImageNode,
  color : @sprite.Color,
) -> ImageNode {
  ImageNode::{ ..self, color, }
}

///|
pub fn ImageNode::with_texture_atlas(
  self : ImageNode,
  texture_atlas : @asset.TextureAtlas?,
) -> ImageNode {
  ImageNode::{ ..self, texture_atlas, }
}

///|
pub fn ImageNode::with_flip_x(self : ImageNode) -> ImageNode {
  ImageNode::{ ..self, flip_x: true }
}

///|
pub fn ImageNode::with_flip_y(self : ImageNode) -> ImageNode {
  ImageNode::{ ..self, flip_y: true }
}

///|
pub fn ImageNode::with_rect(self : ImageNode, rect : @math.Rect?) -> ImageNode {
  ImageNode::{ ..self, rect, }
}

///|
pub fn ImageNode::with_mode(
  self : ImageNode,
  image_mode : NodeImageMode,
) -> ImageNode {
  ImageNode::{ ..self, image_mode, }
}

///|
/// Bevy-aligned interaction state component.
pub(all) enum Interaction {
  None
  Hovered
  Pressed
} derive(Eq, Show, ToJson, FromJson)

///|
/// Bevy-aligned button marker component.
pub struct Button {} derive(ToJson, FromJson)

///|
pub fn Button::default() -> Button {
  Button::{  }
}

///|
/// Bevy-aligned label marker component (Bevy v0.15.3 `Label` widget marker).
pub struct Label {} derive(ToJson, FromJson)

///|
pub fn Label::default() -> Label {
  Label::{  }
}

///|
pub struct ButtonColors {
  normal : @sprite.Color
  hovered : @sprite.Color
  pressed : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn ButtonColors::new(
  normal : @sprite.Color,
  hovered : @sprite.Color,
  pressed : @sprite.Color,
) -> ButtonColors {
  ButtonColors::{ normal, hovered, pressed }
}

///|
const UI_STACK_Z_BASE : Float = 10000.0F

///|
const UI_STACK_Z_STEP : Float = 10.0F

///|
const UI_STACK_Z_CONTENT : Float = 1.0F

///|
const UI_STACK_Z_TEXT : Float = 3.0F

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn safe_scale_factor(scale : Float) -> Float {
  if scale <= 0.0F {
    1.0F
  } else {
    scale
  }
}

///|
fn safe_camera_scale(scale : Float) -> Float {
  if scale <= 0.0F {
    1.0F
  } else {
    scale
  }
}

///|
priv struct UiResolvedCameraState {
  viewport_origin : @math.Vec2
  viewport_size : @math.Vec2
  camera_entity : @core.Entity?
  camera_transform : @transform.Transform
  camera_scale : Float
}

///|
fn ui_resolved_camera_state_default() -> UiResolvedCameraState {
  UiResolvedCameraState::{
    viewport_origin: @math.Vec2::new(0.0F, 0.0F),
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    camera_entity: None,
    camera_transform: @transform.Transform::identity(),
    camera_scale: 1.0F,
  }
}

///|
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn ui_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn ui_rect_intersect(a : @math.Rect, b : @math.Rect) -> @math.Rect {
  let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
  let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
  let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
  let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
  let min = @math.Vec2::new(min_x, min_y)
  let max = @math.Vec2::new(
    if max_x < min_x {
      min_x
    } else {
      max_x
    },
    if max_y < min_y {
      min_y
    } else {
      max_y
    },
  )
  @math.Rect::new(min, max)
}

///|
fn ui_viewport_point_to_world(
  world : @ecs.World,
  entity_ctx : UiResolvedCameraState,
  point : @math.Vec2,
) -> @math.Vec2 {
  if entity_ctx.camera_entity is Some(camera_entity) &&
    (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera))
    is Some(camera) {
    let projection = match
      (try! world.get_by_key(camera_entity, @sprite.ecs_key_projection)) {
      Some(@sprite.Orthographic(orthographic)) => orthographic
      _ => @sprite.OrthographicProjection::default_2d()
    }
    let target_size = match camera.physical_target_size() {
      Some(size) => size
      None => {
        let fallback_scale = safe_scale_factor(@window.window_scale_factor())
        @math.IVec2::new(
          (int_to_float(@window.window_width()) * fallback_scale).to_int(),
          (int_to_float(@window.window_height()) * fallback_scale).to_int(),
        )
      }
    }
    let scale_factor = safe_scale_factor(
      camera.target_scaling_factor().unwrap_or(@window.window_scale_factor()),
    )
    if @sprite.render2d_camera_viewport_to_world_2d(
        point,
        camera,
        projection,
        entity_ctx.camera_transform,
        target_size,
        scale_factor,
      )
      is Some(world_point) {
      return world_point
    }
  }
  let cam_scale = safe_camera_scale(entity_ctx.camera_scale)
  let cam_rot = entity_ctx.camera_transform.rotation_z()
  let cam_pos = @math.Vec2::new(
    entity_ctx.camera_transform.translation.x,
    entity_ctx.camera_transform.translation.y,
  )
  let half_w = entity_ctx.viewport_size.x / 2.0F
  let half_h = entity_ctx.viewport_size.y / 2.0F
  let centered = @math.Vec2::new(point.x - half_w, half_h - point.y)
  let scaled = @math.Vec2::new(centered.x * cam_scale, centered.y * cam_scale)
  let world_offset = rotate_vec2(scaled, cam_rot)
  @math.Vec2::new(cam_pos.x + world_offset.x, cam_pos.y + world_offset.y)
}

///|
fn ui_pointer_hit_for_entity_transform(
  world : @ecs.World,
  entity : @core.Entity,
  node_rect : @math.Rect,
  pointer : @math.Vec2,
  entity_ctx : UiResolvedCameraState,
) -> Bool {
  let size = node_rect.size()
  if size.x <= 0.0F || size.y <= 0.0F {
    return false
  }
  // Bevy UI hit-testing runs in UI layout space for regular Node entities.
  // Keep this path aligned and avoid world-space camera conversion drift.
  if (try! world.contains_by_key(entity, ecs_key_node)) {
    return node_rect.contains(pointer)
  }
  let transform_opt = ui_pointer_hit_transform_for_entity(world, entity)
  match transform_opt {
    Some(node_transform) => {
      let pointer_world = ui_viewport_point_to_world(world, entity_ctx, pointer)
      let relative = @math.Vec2::new(
        pointer_world.x - node_transform.translation.x,
        pointer_world.y - node_transform.translation.y,
      )
      let local_point = rotate_vec2(relative, -node_transform.rotation_z())
      let scale_x = node_transform.scale.x
      let scale_y = node_transform.scale.y
      if ui_abs_float(scale_x) <= 1.0e-6F || ui_abs_float(scale_y) <= 1.0e-6F {
        return false
      }
      let half_w_world = size.x / 2.0F * ui_abs_float(scale_x)
      let half_h_world = size.y / 2.0F * ui_abs_float(scale_y)
      ui_abs_float(local_point.x) <= half_w_world &&
      ui_abs_float(local_point.y) <= half_h_world
    }
    None => node_rect.contains(pointer)
  }
}

///|
fn ui_pointer_hit_transform_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform? {
  match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(transform) => Some(transform)
    None =>
      match
        (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
        Some(global_transform) => Some(global_transform.to_transform_approx())
        None => None
      }
  }
}

///|
fn ensure_ui_context_resource(world : @ecs.World) -> UiContext {
  let res = get_ui_context_resource(world)
  match res.get() {
    Some(value) => value
    None => {
      let value = UiContext::default()
      res.insert(value)
      value
    }
  }
}

///|
fn ensure_ui_scale_resource(world : @ecs.World) -> UiScale {
  let res = get_ui_scale_resource(world)
  match res.get() {
    Some(value) => value
    None => {
      let value = UiScale::new(1.0F)
      res.insert(value)
      value
    }
  }
}

///|
fn create_white_texture_if_needed(ctx : Ref[UiContext]) -> Unit {
  // In unit tests we may pre-seed a dummy handle; avoid touching host APIs then.
  if ctx.val.white_texture.id() > 0 {
    return
  }
  let size = @math.UVec2::new(1, 1)
  let handle = @asset.asset_create_dynamic_texture(size, true)
  let rect = @math.URect::new(@math.UVec2::new(0, 0), @math.UVec2::new(1, 1))
  // moonbitlang/parser may not accept method calls on integer literals.
  let u : Int = 255
  let b : Byte = u.to_byte()
  let bytes = Bytes::from_array([b, b, b, b])
  @asset.asset_update_texture_region_rgba8(handle, rect, bytes)
  ctx.val.white_texture = handle
}

///|
fn clamp_viewport_to_window(
  viewport : @sprite.Viewport,
  win_w : Int,
  win_h : Int,
) -> @sprite.Viewport {
  let mut x = viewport.physical_position.x
  let mut y = viewport.physical_position.y
  let mut w = viewport.physical_size.x
  let mut h = viewport.physical_size.y
  if x < 0 {
    x = 0
  }
  if y < 0 {
    y = 0
  }
  if w < 0 {
    w = 0
  }
  if h < 0 {
    h = 0
  }
  let max_w = if win_w - x < 0 { 0 } else { win_w - x }
  let max_h = if win_h - y < 0 { 0 } else { win_h - y }
  if w > max_w {
    w = max_w
  }
  if h > max_h {
    h = max_h
  }
  @sprite.Viewport::new(@math.IVec2::new(x, y), @math.IVec2::new(w, h))
}

///|
fn ui_render_target_targets_primary_window(
  world : @ecs.World,
  target : @sprite.RenderTarget,
) -> Bool {
  match target {
    @sprite.RenderTarget::Screen => true
    @sprite.RenderTarget::Window(window_ref) =>
      match window_ref {
        @window.WindowRef::Primary => true
        @window.WindowRef::Entity(window_entity) =>
          match
            @window.window_entity_for_ref(world, @window.WindowRef::Primary) {
            Some(primary_window) => ui_entity_eq(window_entity, primary_window)
            None => false
          }
      }
    @sprite.RenderTarget::Image(_) => false
  }
}

///|
fn ui_select_default_camera_entity(world : @ecs.World) -> @core.Entity? {
  let marked : Array[@core.Entity] = []
  world.for_each_component(ecs_key_is_default_ui_camera, fn(entity, _marker) {
    if (try! world.contains_by_key(entity, @sprite.ecs_key_camera)) {
      marked.push(entity)
    }
  })
  if marked.length() == 1 {
    return Some(marked[0])
  }

  let mut best_entity : @core.Entity? = None
  let mut best_order = 0
  world.for_each_component(@sprite.ecs_key_camera, fn(entity, camera) {
    let target = match
      (try! world.get_by_key(entity, @sprite.ecs_key_render_target)) {
      Some(value) => value
      None => @sprite.RenderTarget::Screen
    }
    if !ui_render_target_targets_primary_window(world, target) {
      return
    }
    match best_entity {
      None => {
        best_entity = Some(entity)
        best_order = camera.order
      }
      Some(current_best) =>
        if camera.order > best_order ||
          (camera.order == best_order && ui_entity_gt(entity, current_best)) {
          best_entity = Some(entity)
          best_order = camera.order
        }
    }
  })
  best_entity
}

///|
fn ui_camera_transform_for_entity(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(camera_entity, @sprite.ecs_key_projection)) {
    Some(@sprite.Orthographic(_)) => ()
    _ => return @transform.Transform::identity()
  }
  match
    (try! world.get_by_key(camera_entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => global_transform.to_transform_approx()
    None =>
      match
        (try! world.get_by_key(camera_entity, @transform.ecs_key_transform)) {
        Some(transform) => transform
        None => @transform.Transform::identity()
      }
  }
}

///|
fn ui_camera_scale_for_entity(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Float {
  match (try! world.get_by_key(camera_entity, @sprite.ecs_key_projection)) {
    Some(@sprite.Orthographic(projection)) =>
      safe_camera_scale(projection.scale)
    _ => 1.0F
  }
}

///|
fn ui_camera_viewport_origin(camera : @sprite.Camera) -> @math.Vec2 {
  match camera.viewport {
    Some(viewport) => {
      let scale_factor = safe_scale_factor(
        camera.target_scaling_factor().unwrap_or(1.0F),
      )
      @math.Vec2::new(
        int_to_float(viewport.physical_position.x) / scale_factor,
        int_to_float(viewport.physical_position.y) / scale_factor,
      )
    }
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}

///|
fn ui_compute_render_target_info(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> ComputedUiRenderTargetInfo {
  let ui_scale = ensure_ui_scale_resource(world)
  let ui_scale_value = if ui_scale.value <= 0.0F {
    1.0F
  } else {
    ui_scale.value
  }
  match (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera)) {
    Some(camera) => {
      let (target_physical_size, target_scale_factor) = match
        camera.computed.target_info {
        Some(target_info) =>
          (target_info.physical_size, target_info.scale_factor)
        None => {
          let target = match
            (try! world.get_by_key(camera_entity, @sprite.ecs_key_render_target)) {
            Some(value) => value
            None => @sprite.RenderTarget::Screen
          }
          match target {
            @sprite.RenderTarget::Screen =>
              (
                @math.IVec2::new(
                  @window.window_physical_width_for(
                    world,
                    @window.WindowRef::Primary,
                  ),
                  @window.window_physical_height_for(
                    world,
                    @window.WindowRef::Primary,
                  ),
                ),
                @window.window_scale_factor_for(
                  world,
                  @window.WindowRef::Primary,
                ),
              )
            @sprite.RenderTarget::Window(window_ref) =>
              (
                @math.IVec2::new(
                  @window.window_physical_width_for(world, window_ref),
                  @window.window_physical_height_for(world, window_ref),
                ),
                @window.window_scale_factor_for(world, window_ref),
              )
            @sprite.RenderTarget::Image(handle) =>
              (
                @math.IVec2::new(
                  @asset.asset_texture_width(handle),
                  @asset.asset_texture_height(handle),
                ),
                1.0F,
              )
          }
        }
      }
      let target_scale_factor = safe_scale_factor(target_scale_factor)
      let physical_size = match camera.viewport {
        Some(viewport) =>
          clamp_viewport_to_window(
            viewport,
            target_physical_size.x,
            target_physical_size.y,
          ).physical_size
        None => target_physical_size
      }
      let scale_factor = target_scale_factor * ui_scale_value
      ComputedUiRenderTargetInfo::new(scale_factor, physical_size)
    }
    None => ComputedUiRenderTargetInfo::default()
  }
}

///|
fn ui_resolved_camera_state_from_legacy(
  ctx : UiContext,
) -> UiResolvedCameraState {
  UiResolvedCameraState::{
    viewport_origin: ctx.viewport_origin,
    viewport_size: ctx.viewport_size,
    camera_entity: ctx.camera_entity,
    camera_transform: ctx.camera_transform,
    camera_scale: ctx.camera_scale,
  }
}

///|
fn ui_resolved_camera_state_from_computed(
  world : @ecs.World,
  camera_entity : @core.Entity?,
  render_target_info : ComputedUiRenderTargetInfo,
) -> UiResolvedCameraState {
  let mut viewport_origin = @math.Vec2::new(0.0F, 0.0F)
  let mut camera_transform = @transform.Transform::identity()
  let mut camera_scale = 1.0F
  if camera_entity is Some(entity) {
    if (try! world.get_by_key(entity, @sprite.ecs_key_camera)) is Some(camera) {
      viewport_origin = ui_camera_viewport_origin(camera)
    }
    camera_transform = ui_camera_transform_for_entity(world, entity)
    camera_scale = ui_camera_scale_for_entity(world, entity)
  }
  UiResolvedCameraState::{
    viewport_origin,
    viewport_size: render_target_info.logical_size(),
    camera_entity,
    camera_transform,
    camera_scale,
  }
}

///|
fn ui_root_resolved_camera_state(
  world : @ecs.World,
  root : @core.Entity,
  legacy_ctx : UiContext?,
) -> UiResolvedCameraState {
  match (try! world.get_by_key(root, ecs_key_computed_ui_render_target_info)) {
    Some(render_target_info) =>
      ui_resolved_camera_state_from_computed(
        world,
        match (try! world.get_by_key(root, ecs_key_computed_ui_target_camera)) {
          Some(value) => value.get()
          None => None
        },
        render_target_info,
      )
    None =>
      match legacy_ctx {
        Some(ctx) => ui_resolved_camera_state_from_legacy(ctx)
        None => ui_resolved_camera_state_default()
      }
  }
}

///|
fn ui_entity_resolved_camera_state(
  world : @ecs.World,
  entity : @core.Entity,
  legacy_ctx : UiContext?,
) -> UiResolvedCameraState {
  match
    (try! world.get_by_key(entity, ecs_key_computed_ui_render_target_info)) {
    Some(render_target_info) =>
      ui_resolved_camera_state_from_computed(
        world,
        match
          (try! world.get_by_key(entity, ecs_key_computed_ui_target_camera)) {
          Some(value) => value.get()
          None => None
        },
        render_target_info,
      )
    None =>
      match legacy_ctx {
        Some(ctx) => ui_resolved_camera_state_from_legacy(ctx)
        None => ui_resolved_camera_state_default()
      }
  }
}

///|
fn ui_propagate_target_camera_subtree(
  world : @ecs.World,
  entity : @core.Entity,
  computed_camera : ComputedUiTargetCamera,
  render_target_info : ComputedUiRenderTargetInfo,
) -> Unit {
  try! world.set_by_key(
    entity, ecs_key_computed_ui_target_camera, computed_camera,
  )
  try! world.set_by_key(
    entity, ecs_key_computed_ui_render_target_info, render_target_info,
  )
  if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
    is Some(children) {
    for child in children.entities {
      ui_propagate_target_camera_subtree(
        world, child, computed_camera, render_target_info,
      )
    }
  }
}

///|
pub fn ui_update_context_system(world : @ecs.World) -> Unit {
  let ctx = Ref::new(ensure_ui_context_resource(world))
  create_white_texture_if_needed(ctx)
  let win_w = @window.window_width()
  let win_h = @window.window_height()
  let sf = safe_scale_factor(@window.window_scale_factor())

  // Legacy singleton UI context remains tied to the default UI camera so
  // existing consumers keep working while per-root routing migrates to
  // `UiTargetCamera`.
  let best_entity = ui_select_default_camera_entity(world)
  let mut viewport_origin = @math.Vec2::new(0.0F, 0.0F)
  let mut viewport_size = @math.Vec2::new(
    int_to_float(win_w) / sf,
    int_to_float(win_h) / sf,
  )
  let mut camera_transform = @transform.Transform::identity()
  let mut camera_scale = 1.0F
  if best_entity is Some(cam_entity) {
    camera_transform = ui_camera_transform_for_entity(world, cam_entity)
    camera_scale = ui_camera_scale_for_entity(world, cam_entity)
    if (try! world.get_by_key(cam_entity, @sprite.ecs_key_camera))
      is Some(camera) {
      viewport_origin = ui_camera_viewport_origin(camera)
      if camera.logical_viewport_size() is Some(size) {
        viewport_size = size
      } else if camera.viewport is Some(vp0) {
        let vp = clamp_viewport_to_window(vp0, win_w, win_h)
        viewport_size = @math.Vec2::new(
          int_to_float(vp.physical_size.x) / sf,
          int_to_float(vp.physical_size.y) / sf,
        )
      }
    }
  }

  // Pointer (window space -> viewport space).
  let pointer_pos = match @input.mouse_position() {
    Some(mouse) =>
      ui_pointer_pos_in_viewport(mouse, viewport_origin, viewport_size)
    None => None
  }
  ctx.val.viewport_origin = viewport_origin
  ctx.val.viewport_size = viewport_size
  ctx.val.camera_entity = best_entity
  ctx.val.camera_transform = camera_transform
  ctx.val.camera_scale = camera_scale
  ctx.val.pointer_pos = pointer_pos
  ctx.val.pointer_down = @input.mouse_button_pressed(@window.MouseButton::Left)
  ctx.val.pointer_just_pressed = @input.mouse_button_just_pressed(
    @window.MouseButton::Left,
  )
  ctx.val.pointer_just_released = @input.mouse_button_just_released(
    @window.MouseButton::Left,
  )
  ctx.val.wheel_delta = match @input.mouse_wheel_delta_opt() {
    Some(v) => v
    None => @math.Vec2::new(0.0F, 0.0F)
  }
  get_ui_context_resource(world).insert(ctx.val)
}

///|
fn image_measure_size_px(
  rect : @math.Rect?,
  atlas_rect : @math.Rect?,
  texture_size_fn : () -> @math.Vec2,
) -> @math.Vec2 {
  match rect {
    Some(r) => r.size()
    None =>
      match atlas_rect {
        Some(ar) => ar.size()
        None => texture_size_fn()
      }
  }
}

///|
/// Update `ContentSize` for image nodes when `NodeImageMode::Auto`.
///
/// This mirrors Bevy's `update_image_content_size_system`, adapted to mgstudio's
/// logical UI coordinate space.
pub fn ui_image_content_size_system(world : @ecs.World) -> Unit {
  let res = get_ui_context_resource(world)
  guard res.get() is Some(_) else { return }
  let ui_scale = ensure_ui_scale_resource(world)
  let sf = safe_scale_factor(@window.window_scale_factor())
  let ui_scale_value = if ui_scale.value <= 0.0F {
    1.0F
  } else {
    ui_scale.value
  }
  let legacy_inv_px_scale = ui_scale_value / sf
  let transparent_id = @asset.asset_transparent_texture().id()
  fn texture_size(handle : @asset.Handle[@asset.Image]) -> @math.Vec2 {
    let w = @asset.asset_texture_width(handle)
    let h = @asset.asset_texture_height(handle)
    @math.Vec2::new(int_to_float(w), int_to_float(h))
  }

  fn atlas_rect_for(atlas : @asset.TextureAtlas) -> @math.Rect? {
    match @asset.asset_get_texture_atlas_layout(atlas.layout) {
      Some(layout_value) =>
        if atlas.index >= 0 && atlas.index < layout_value.textures.length() {
          Some(layout_value.textures[atlas.index].as_rect())
        } else {
          None
        }
      None => None
    }
  }

  fn uvec2_from_size_px(size_px : @math.Vec2) -> @math.UVec2 {
    let w = if size_px.x <= 0.0F { 0 } else { size_px.x.to_int() }
    let h = if size_px.y <= 0.0F { 0 } else { size_px.y.to_int() }
    @math.UVec2::new(w, h)
  }

  fn update_content_size(entity : @core.Entity, size_px : @math.Vec2) -> Unit {
    if size_px.x <= 0.0F || size_px.y <= 0.0F {
      return
    }
    let inv_px_scale = match
      (try! world.get_by_key(entity, ecs_key_computed_ui_render_target_info)) {
      Some(render_target_info) => 1.0F / render_target_info.scale_factor()
      None => legacy_inv_px_scale
    }
    let next = ContentSize::new(
      @math.Vec2::new(size_px.x * inv_px_scale, size_px.y * inv_px_scale),
    )
    match (try! world.get_by_key(entity, ecs_key_content_size)) {
      Some(prev) =>
        if prev.size.x == next.size.x && prev.size.y == next.size.y {
          ()
        } else {
          try! (world.replace(entity, ecs_key_content_size, next) |> ignore)
        }
      None => try! world.set_by_key(entity, ecs_key_content_size, next)
    }
  }

  fn update_image_node_size(
    entity : @core.Entity,
    size_px : @math.Vec2,
  ) -> Unit {
    let next = ImageNodeSize::{ size: uvec2_from_size_px(size_px) }
    match (try! world.get_by_key(entity, ecs_key_image_node_size)) {
      Some(prev) =>
        if prev.size.x == next.size.x && prev.size.y == next.size.y {
          ()
        } else {
          try! (world.replace(entity, ecs_key_image_node_size, next) |> ignore)
        }
      None => try! world.set_by_key(entity, ecs_key_image_node_size, next)
    }
  }

  // ImageNode (Bevy-aligned).
  world.for_each_component(ecs_key_image_node, fn(entity, image_node) {
    if !((try! world.contains_by_key(entity, ecs_key_node)) ||
      (try! world.contains_by_key(entity, @text.ecs_key_text))) {
      return
    }
    let is_auto = match image_node.image_mode {
      NodeImageMode::Auto => true
      _ => false
    }
    if image_node.image.id() == transparent_id || !is_auto {
      if (try! world.contains_by_key(entity, ecs_key_content_size)) {
        try! (world.take(entity, ecs_key_content_size) |> ignore)
      }
      return
    }
    let atlas_rect = match image_node.texture_atlas {
      Some(atlas) => atlas_rect_for(atlas)
      None => None
    }
    let size_px = image_measure_size_px(image_node.rect, atlas_rect, () => {
      texture_size(image_node.image)
    })
    update_content_size(entity, size_px)
    update_image_node_size(entity, size_px)
  })

  // Legacy UiImage compatibility: treat as Auto-sized content when ImageNode is absent.
  world.for_each_component(ecs_key_ui_image, fn(entity, ui_image) {
    if (try! world.contains_by_key(entity, ecs_key_image_node)) {
      return
    }
    if !((try! world.contains_by_key(entity, ecs_key_node)) ||
      (try! world.contains_by_key(entity, @text.ecs_key_text))) {
      return
    }
    if ui_image.image.id() == transparent_id {
      if (try! world.contains_by_key(entity, ecs_key_content_size)) {
        try! (world.take(entity, ecs_key_content_size) |> ignore)
      }
      return
    }
    let atlas_rect = match ui_image.texture_atlas {
      Some(atlas) => atlas_rect_for(atlas)
      None => None
    }
    let size_px = image_measure_size_px(ui_image.rect, atlas_rect, () => {
      texture_size(ui_image.image)
    })
    update_content_size(entity, size_px)
  })
}

///|
pub fn ui_layout_system(world : @ecs.World) -> Unit {
  let res = get_ui_context_resource(world)
  let legacy_ctx = res.get()
  let roots = ui_collect_root_entities(world)
  fn auto_size_for_entity(entity : @core.Entity) -> @math.Vec2 {
    match (try! world.get_by_key(entity, ecs_key_content_size)) {
      Some(v) => v.size
      None =>
        match @text.ui_text_ecs_handle(world, entity) {
          Some(handle) =>
            match @text.text_get_layout_size(handle) {
              Some(sz) => sz
              None => @math.Vec2::new(0.0F, 0.0F)
            }
          None => @math.Vec2::new(0.0F, 0.0F)
        }
    }
  }

  fn f2d(v : Float) -> Double {
    v.to_double()
  }

  fn d2f(v : Double) -> Float {
    Float::from_double(v)
  }

  let root_viewport_size = Ref::new(@math.Vec2::new(0.0F, 0.0F))

  fn dim_for_val(val : Val) -> @moon_taffy.Dimension {
    match val {
      Auto => @moon_taffy.auto()
      Px(px) => @moon_taffy.length(f2d(px))
      Percent(p) => @moon_taffy.percent(f2d(p / 100.0F))
      Vw(p) => @moon_taffy.length(f2d(root_viewport_size.val.x * (p / 100.0F)))
      Vh(p) => @moon_taffy.length(f2d(root_viewport_size.val.y * (p / 100.0F)))
      VMin(p) => {
        let m = if root_viewport_size.val.x < root_viewport_size.val.y {
          root_viewport_size.val.x
        } else {
          root_viewport_size.val.y
        }
        @moon_taffy.length(f2d(m * (p / 100.0F)))
      }
      VMax(p) => {
        let m = if root_viewport_size.val.x > root_viewport_size.val.y {
          root_viewport_size.val.x
        } else {
          root_viewport_size.val.y
        }
        @moon_taffy.length(f2d(m * (p / 100.0F)))
      }
    }
  }

  fn clamp_nonneg(v : Float) -> Float {
    if v < 0.0F {
      0.0F
    } else {
      v
    }
  }

  fn resolve_axis(
    val : Val,
    node_axis : Float,
    viewport_size : @math.Vec2,
  ) -> Float {
    match val {
      Val::Auto => 0.0F
      Val::Px(px) => px
      Val::Percent(p) => node_axis * (p / 100.0F)
      Val::Vw(p) => viewport_size.x * (p / 100.0F)
      Val::Vh(p) => viewport_size.y * (p / 100.0F)
      Val::VMin(p) => {
        let m = if viewport_size.x < viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
      Val::VMax(p) => {
        let m = if viewport_size.x > viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
    }
  }

  fn rect_for_uirect(r : UiRect) -> @moon_taffy.Rect[@moon_taffy.Dimension] {
    @moon_taffy.Rect::new(
      left=dim_for_val(r.left),
      right=dim_for_val(r.right),
      top=dim_for_val(r.top),
      bottom=dim_for_val(r.bottom),
    )
  }

  fn size_for_vals(
    w : Val,
    h : Val,
  ) -> @moon_taffy.Size[@moon_taffy.Dimension] {
    @moon_taffy.Size::new(width=dim_for_val(w), height=dim_for_val(h))
  }

  fn grid_track_to_taffy(track : GridTrack) -> @moon_taffy.Dimension {
    match track {
      GridTrack::Auto => @moon_taffy.auto()
      GridTrack::Px(px) => @moon_taffy.length(f2d(px))
      GridTrack::Percent(p) => @moon_taffy.percent(f2d(p))
      GridTrack::Fr(w) => @moon_taffy.fr(f2d(w))
      GridTrack::MinContent => @moon_taffy.grid_min_content()
      GridTrack::MaxContent => @moon_taffy.grid_max_content()
    }
  }

  fn grid_track_repetition_to_taffy(
    repetition : GridTrackRepetition,
  ) -> @moon_taffy.GridTrackRepetition {
    match repetition {
      GridTrackRepetition::Count(n) => @moon_taffy.repeat_count(n)
      GridTrackRepetition::AutoFill => @moon_taffy.repeat_auto_fill()
      GridTrackRepetition::AutoFit => @moon_taffy.repeat_auto_fit()
    }
  }

  fn repeated_grid_track_to_taffy(
    rep : RepeatedGridTrack,
  ) -> @moon_taffy.Dimension {
    let tracks : Array[@moon_taffy.Dimension] = []
    for track in rep.tracks {
      tracks.push(grid_track_to_taffy(track))
    }
    match rep.repetition {
      GridTrackRepetition::Count(1) =>
        if tracks.length() == 1 {
          tracks[0]
        } else {
          @moon_taffy.repeat(
            grid_track_repetition_to_taffy(rep.repetition),
            tracks,
          )
        }
      _ =>
        @moon_taffy.repeat(
          grid_track_repetition_to_taffy(rep.repetition),
          tracks,
        )
    }
  }

  fn grid_template_to_taffy(
    template : Array[RepeatedGridTrack],
  ) -> Array[@moon_taffy.Dimension] {
    let dims : Array[@moon_taffy.Dimension] = []
    for rep in template {
      dims.push(repeated_grid_track_to_taffy(rep))
    }
    dims
  }

  fn grid_tracks_to_taffy(
    tracks : Array[GridTrack],
  ) -> Array[@moon_taffy.Dimension] {
    let dims : Array[@moon_taffy.Dimension] = []
    for track in tracks {
      dims.push(grid_track_to_taffy(track))
    }
    dims
  }

  fn overflow_axis_to_taffy(axis : OverflowAxis) -> @moon_taffy.Overflow {
    match axis {
      OverflowAxis::Visible => @moon_taffy.overflow_visible()
      OverflowAxis::Hidden => @moon_taffy.overflow_hidden()
      OverflowAxis::Scroll => @moon_taffy.overflow_scroll()
      OverflowAxis::Clip => @moon_taffy.overflow_clip()
    }
  }

  fn overflow_to_taffy(
    overflow : Overflow,
  ) -> @moon_taffy.Point[@moon_taffy.Overflow] {
    @moon_taffy.Point::new(
      x=overflow_axis_to_taffy(overflow.x),
      y=overflow_axis_to_taffy(overflow.y),
    )
  }

  fn display_to_taffy(display : Display) -> @moon_taffy.Display {
    match display {
      Display::Block => @moon_taffy.display_block()
      Display::Flex => @moon_taffy.display_flex()
      Display::Grid => @moon_taffy.display_grid()
      Display::None => @moon_taffy.display_none()
    }
  }

  fn position_to_taffy(position_type : PositionType) -> @moon_taffy.Position {
    match position_type {
      PositionType::Relative => @moon_taffy.position_relative()
      PositionType::Absolute => @moon_taffy.position_absolute()
    }
  }

  fn flex_direction_to_taffy(dir : FlexDirection) -> @moon_taffy.FlexDirection {
    match dir {
      FlexDirection::Row => @moon_taffy.flex_direction_row()
      FlexDirection::RowReverse => @moon_taffy.flex_direction_row_reverse()
      FlexDirection::Column => @moon_taffy.flex_direction_column()
      FlexDirection::ColumnReverse =>
        @moon_taffy.flex_direction_column_reverse()
    }
  }

  fn flex_wrap_to_taffy(wrap : FlexWrap) -> @moon_taffy.FlexWrap {
    match wrap {
      FlexWrap::NoWrap => @moon_taffy.flex_wrap_no_wrap()
      FlexWrap::Wrap => @moon_taffy.flex_wrap_wrap()
      FlexWrap::WrapReverse => @moon_taffy.flex_wrap_wrap_reverse()
    }
  }

  fn align_items_to_taffy(items : AlignItems) -> @moon_taffy.AlignItems? {
    match items {
      AlignItems::Default => None
      AlignItems::Baseline => Some(@moon_taffy.align_items_baseline())
      AlignItems::Center => Some(@moon_taffy.align_items_center())
      AlignItems::End => Some(@moon_taffy.align_items_end())
      AlignItems::FlexEnd => Some(@moon_taffy.align_items_flex_end())
      AlignItems::FlexStart => Some(@moon_taffy.align_items_flex_start())
      AlignItems::Start => Some(@moon_taffy.align_items_start())
      AlignItems::Stretch => Some(@moon_taffy.align_items_stretch())
    }
  }

  fn justify_items_to_taffy(items : JustifyItems) -> @moon_taffy.JustifyItems? {
    match items {
      JustifyItems::Default => None
      JustifyItems::Baseline => Some(@moon_taffy.align_items_baseline())
      JustifyItems::Center => Some(@moon_taffy.align_items_center())
      JustifyItems::End => Some(@moon_taffy.align_items_end())
      JustifyItems::Start => Some(@moon_taffy.align_items_start())
      JustifyItems::Stretch => Some(@moon_taffy.align_items_stretch())
    }
  }

  fn align_self_to_taffy(align_self : AlignSelf) -> @moon_taffy.AlignSelf? {
    match align_self {
      AlignSelf::Auto => None
      AlignSelf::Baseline => Some(@moon_taffy.align_items_baseline())
      AlignSelf::Center => Some(@moon_taffy.align_items_center())
      AlignSelf::End => Some(@moon_taffy.align_items_end())
      AlignSelf::FlexEnd => Some(@moon_taffy.align_items_flex_end())
      AlignSelf::FlexStart => Some(@moon_taffy.align_items_flex_start())
      AlignSelf::Start => Some(@moon_taffy.align_items_start())
      AlignSelf::Stretch => Some(@moon_taffy.align_items_stretch())
    }
  }

  fn justify_self_to_taffy(
    justify_self : JustifySelf,
  ) -> @moon_taffy.JustifySelf? {
    match justify_self {
      JustifySelf::Auto => None
      JustifySelf::Baseline => Some(@moon_taffy.align_items_baseline())
      JustifySelf::Center => Some(@moon_taffy.align_items_center())
      JustifySelf::End => Some(@moon_taffy.align_items_end())
      JustifySelf::Start => Some(@moon_taffy.align_items_start())
      JustifySelf::Stretch => Some(@moon_taffy.align_items_stretch())
    }
  }

  fn align_content_to_taffy(
    content : AlignContent,
  ) -> @moon_taffy.AlignContent? {
    match content {
      AlignContent::Default => None
      AlignContent::Center => Some(@moon_taffy.align_content_center())
      AlignContent::End => Some(@moon_taffy.align_content_end())
      AlignContent::FlexEnd => Some(@moon_taffy.align_content_flex_end())
      AlignContent::FlexStart => Some(@moon_taffy.align_content_flex_start())
      AlignContent::SpaceAround =>
        Some(@moon_taffy.align_content_space_around())
      AlignContent::SpaceBetween =>
        Some(@moon_taffy.align_content_space_between())
      AlignContent::SpaceEvenly =>
        Some(@moon_taffy.align_content_space_evenly())
      AlignContent::Start => Some(@moon_taffy.align_content_start())
      AlignContent::Stretch => Some(@moon_taffy.align_content_stretch())
    }
  }

  fn justify_content_to_taffy(
    content : JustifyContent,
  ) -> @moon_taffy.JustifyContent? {
    match content {
      JustifyContent::Default => None
      JustifyContent::Center => Some(@moon_taffy.justify_content_center())
      JustifyContent::End => Some(@moon_taffy.justify_content_end())
      JustifyContent::FlexEnd => Some(@moon_taffy.justify_content_flex_end())
      JustifyContent::FlexStart =>
        Some(@moon_taffy.justify_content_flex_start())
      JustifyContent::SpaceAround =>
        Some(@moon_taffy.justify_content_space_around())
      JustifyContent::SpaceBetween =>
        Some(@moon_taffy.justify_content_space_between())
      JustifyContent::SpaceEvenly =>
        Some(@moon_taffy.justify_content_space_evenly())
      JustifyContent::Start => Some(@moon_taffy.justify_content_start())
      JustifyContent::Stretch => Some(@moon_taffy.justify_content_stretch())
    }
  }

  fn grid_auto_flow_to_taffy(flow : GridAutoFlow) -> @moon_taffy.GridAutoFlow {
    match flow {
      GridAutoFlow::Row => @moon_taffy.grid_auto_flow_row()
      GridAutoFlow::RowDense => @moon_taffy.grid_auto_flow_row_dense()
      GridAutoFlow::Column => @moon_taffy.grid_auto_flow_column()
      GridAutoFlow::ColumnDense => @moon_taffy.grid_auto_flow_column_dense()
    }
  }

  fn grid_placement_to_taffy(
    value : GridPlacement,
  ) -> @moon_taffy.Line[@moon_taffy.GridPlacement] {
    let span = match value.span {
      Some(v) => if v == 0 { 1 } else { v }
      None => 1
    }
    match (value.start, value.end) {
      (Some(start), Some(end)) =>
        @moon_taffy.Line::new(
          start=@moon_taffy.line(start),
          end=@moon_taffy.line(end),
        )
      (Some(start), None) =>
        @moon_taffy.Line::new(
          start=@moon_taffy.line(start),
          end=@moon_taffy.span(span),
        )
      (None, Some(end)) =>
        @moon_taffy.Line::new(
          start=@moon_taffy.span(span),
          end=@moon_taffy.line(end),
        )
      (None, None) =>
        @moon_taffy.Line::new(
          start=@moon_taffy.span(span),
          end=@moon_taffy.place_auto(),
        )
    }
  }

  fn entity_key(e : @core.Entity) -> (Int, Int) {
    (e.id, e.generation)
  }

  fn style_for_entity(
    entity : @core.Entity,
    is_root : Bool,
  ) -> @moon_taffy.Style {
    let node = match (try! world.get_by_key(entity, ecs_key_node)) {
      Some(v) => v
      None => Node::default()
    }
    let mut style = @moon_taffy.Style::default()
      .with_display(display_to_taffy(node.display))
      .with_position(position_to_taffy(node.position_type))
      .with_inset(
        @moon_taffy.Rect::new(
          left=dim_for_val(node.left),
          right=dim_for_val(node.right),
          top=dim_for_val(node.top),
          bottom=dim_for_val(node.bottom),
        ),
      )
      .with_margin(rect_for_uirect(node.margin))
      .with_padding(rect_for_uirect(node.padding))
      .with_border(rect_for_uirect(node.border))
      .with_size(size_for_vals(node.width, node.height))
      .with_min_size(size_for_vals(node.min_width, node.min_height))
      .with_max_size(size_for_vals(node.max_width, node.max_height))
      .with_flex_direction(flex_direction_to_taffy(node.flex_direction))
      .with_flex_wrap(flex_wrap_to_taffy(node.flex_wrap))
      .with_flex_grow(node.flex_grow.to_double())
      .with_flex_shrink(node.flex_shrink.to_double())
      .with_flex_basis(dim_for_val(node.flex_basis))
      .with_grid_template_rows(grid_template_to_taffy(node.grid_template_rows))
      .with_grid_template_columns(
        grid_template_to_taffy(node.grid_template_columns),
      )
      .with_grid_auto_rows(grid_tracks_to_taffy(node.grid_auto_rows))
      .with_grid_auto_columns(grid_tracks_to_taffy(node.grid_auto_columns))
      .with_grid_auto_flow(grid_auto_flow_to_taffy(node.grid_auto_flow))
      .with_grid_row(grid_placement_to_taffy(node.grid_row))
      .with_grid_column(grid_placement_to_taffy(node.grid_column))
      .with_gap(
        @moon_taffy.Size::new(
          width=dim_for_val(node.column_gap),
          height=dim_for_val(node.row_gap),
        ),
      )
      .with_overflow(overflow_to_taffy(node.overflow))
    if node.aspect_ratio is Some(r) {
      style = style.with_aspect_ratio(r.to_double())
    }
    match align_items_to_taffy(node.align_items) {
      Some(v) => style = style.with_align_items(v)
      None => ()
    }
    match justify_items_to_taffy(node.justify_items) {
      Some(v) => style = style.with_justify_items(v)
      None => ()
    }
    match align_content_to_taffy(node.align_content) {
      Some(v) => style = style.with_align_content(v)
      None => ()
    }
    match justify_content_to_taffy(node.justify_content) {
      Some(v) => style = style.with_justify_content(v)
      None => ()
    }
    match align_self_to_taffy(node.align_self) {
      Some(v) => style = style.with_align_self(v)
      None => ()
    }
    match justify_self_to_taffy(node.justify_self) {
      Some(v) => style = style.with_justify_self(v)
      None => ()
    }
    if is_root {
      style = style
        .with_position(@moon_taffy.position_relative())
        .with_size(
          @moon_taffy.Size::new(
            width=@moon_taffy.length(f2d(root_viewport_size.val.x)),
            height=@moon_taffy.length(f2d(root_viewport_size.val.y)),
          ),
        )
    }
    style
  }

  fn layout_root(root : @core.Entity) -> Unit {
    let root_ctx = ui_root_resolved_camera_state(world, root, legacy_ctx)
    root_viewport_size.val = root_ctx.viewport_size
    let explicit_root = try! world.contains_by_key(root, ecs_key_ui_root)
    let root_rect = @math.Rect::new(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(root_ctx.viewport_size.x, root_ctx.viewport_size.y),
    )
    let taffy = @moon_taffy.TaffyTree::new()
    let entity_to_node : @hashmap.HashMap[(Int, Int), Int] = @hashmap.HashMap::new()
    fn build(entity : @core.Entity, is_root : Bool) -> Array[Int] {
      let child_ids : Array[Int] = []
      for child in ui_collect_effective_children(world, entity) {
        for child_id in build(child, false) {
          child_ids.push(child_id)
        }
      }
      if ui_is_ghost_node(world, entity) {
        return child_ids
      }
      let style = style_for_entity(entity, is_root)
      let id = if child_ids.length() == 0 {
        taffy.new_leaf(style)
      } else {
        taffy.new_with_children(style, child_ids)
      }
      if (try! world.contains_by_key(entity, ecs_key_content_size)) ||
        (try! world.contains_by_key(entity, @text.ecs_key_text)) {
        try! taffy.set_node_context(id, entity)
      }
      entity_to_node.set(entity_key(entity), id)
      [id]
    }

    let root_children = build(
      root,
      explicit_root && !ui_is_ghost_node(world, root),
    )
    let root_node_id = if explicit_root &&
      !ui_is_ghost_node(world, root) &&
      root_children.length() == 1 {
      root_children[0]
    } else {
      let viewport_root_style = @moon_taffy.Style::default()
        .with_position(@moon_taffy.position_relative())
        .with_size(
          @moon_taffy.Size::new(
            width=@moon_taffy.length(f2d(root_ctx.viewport_size.x)),
            height=@moon_taffy.length(f2d(root_ctx.viewport_size.y)),
          ),
        )
      taffy.new_with_children(viewport_root_style, root_children)
    }
    let avail = @moon_taffy.Size::new(
      width=@moon_taffy.available_space_definite(f2d(root_ctx.viewport_size.x)),
      height=@moon_taffy.available_space_definite(f2d(root_ctx.viewport_size.y)),
    )
    fn available_to_option(v : @moon_taffy.AvailableSpace) -> Double? {
      match v {
        @moon_taffy.AvailDefinite(x) => Some(x)
        _ => None
      }
    }

    fn resolve_dimension(
      dim : @moon_taffy.Dimension,
      parent : Double?,
    ) -> Double? {
      match dim {
        @moon_taffy.DimLength(x) => Some(x)
        @moon_taffy.DimPercent(p) =>
          match parent {
            Some(base) => Some(base * p)
            None => None
          }
        _ => None
      }
    }

    fn clamp_f64(v : Double, min_v : Double?, max_v : Double?) -> Double {
      let mut out = v
      match min_v {
        Some(mn) => if out < mn { out = mn }
        None => ()
      }
      match max_v {
        Some(mx) => if out > mx { out = mx }
        None => ()
      }
      out
    }

    fn maybe_clamp_f64(
      v : Double?,
      min_v : Double?,
      max_v : Double?,
    ) -> Double? {
      match v {
        Some(x) => Some(clamp_f64(x, min_v, max_v))
        None => None
      }
    }

    fn measure(
      known : @moon_taffy.Size[Double?],
      available : @moon_taffy.Size[@moon_taffy.AvailableSpace],
      _node_id : Int,
      ctx : @core.Entity?,
      style : @moon_taffy.Style,
    ) -> @moon_taffy.Size[Double] {
      match ctx {
        Some(entity) => {
          let intrinsic = auto_size_for_entity(entity)
          let intrinsic_w = f2d(intrinsic.x)
          let intrinsic_h = f2d(intrinsic.y)
          let parent_w = available_to_option(available.width)
          let parent_h = available_to_option(available.height)
          let s_w = resolve_dimension(style.size.width, parent_w)
          let s_min_w = resolve_dimension(style.min_size.width, parent_w)
          let s_max_w = resolve_dimension(style.max_size.width, parent_w)
          let s_h = resolve_dimension(style.size.height, parent_h)
          let s_min_h = resolve_dimension(style.min_size.height, parent_h)
          let s_max_h = resolve_dimension(style.max_size.height, parent_h)
          let width0 = match known.width {
            Some(w) => Some(w)
            None => {
              let base = match s_w {
                Some(x) => Some(x)
                None => s_min_w
              }
              maybe_clamp_f64(base, s_min_w, s_max_w)
            }
          }
          let height0 = match known.height {
            Some(h) => Some(h)
            None => {
              let base = match s_h {
                Some(x) => Some(x)
                None => s_min_h
              }
              maybe_clamp_f64(base, s_min_h, s_max_h)
            }
          }
          let intrinsic_aspect = if intrinsic_h == 0.0 {
            1.0
          } else {
            intrinsic_w / intrinsic_h
          }
          let aspect = match style.aspect_ratio {
            Some(ar) => ar
            None => intrinsic_aspect
          }
          let mut width = width0
          let mut height = height0
          match (width, height) {
            (Some(w), None) => if aspect != 0.0 { height = Some(w / aspect) }
            (None, Some(h)) => width = Some(h * aspect)
            _ => ()
          }
          let out_w = clamp_f64(width.unwrap_or(intrinsic_w), s_min_w, s_max_w)
          let out_h = clamp_f64(height.unwrap_or(intrinsic_h), s_min_h, s_max_h)
          @moon_taffy.Size::new(width=out_w, height=out_h)
        }
        None => @moon_taffy.Size::zero()
      }
    }

    taffy.compute_layout_with_measure(root_node_id, avail, measure) catch {
      _ => return
    }
    fn apply_layout(entity : @core.Entity, parent_rect : @math.Rect) -> Unit {
      if ui_is_ghost_node(world, entity) {
        if (try! world.contains_by_key(entity, ecs_key_ui_layout)) {
          try! (world.take(entity, ecs_key_ui_layout) |> ignore)
        }
        for child in ui_collect_effective_children(world, entity) {
          apply_layout(child, parent_rect)
        }
        return
      }
      guard entity_to_node.get(entity_key(entity)) is Some(node_id) else {
        return
      }
      let tl = taffy.layout(node_id) catch { _ => return }
      let parent_origin = parent_rect.min
      let loc = @math.Vec2::new(d2f(tl.location.x), d2f(tl.location.y))
      let size = @math.Vec2::new(d2f(tl.size.width), d2f(tl.size.height))
      let min = @math.Vec2::new(
        parent_origin.x + loc.x,
        parent_origin.y + loc.y,
      )
      let max = @math.Vec2::new(min.x + size.x, min.y + size.y)
      let rect = @math.Rect::new(min, max)
      let layout = UiLayout::new(rect)
      if (try! world.contains_by_key(entity, ecs_key_ui_layout)) {
        try! (world.replace(entity, ecs_key_ui_layout, layout) |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_ui_layout, layout)
      }

      // Update render2d / transform for UI nodes (Node component required).
      if (try! world.contains_by_key(entity, ecs_key_node)) {
        let transform = ui_world_transform(root_ctx, rect, 0.0F)
        if (try! world.contains_by_key(entity, @transform.ecs_key_transform)) {
          try! (world.replace(entity, @transform.ecs_key_transform, transform)
          |> ignore)
        } else {
          try! world.set_by_key(entity, @transform.ecs_key_transform, transform)
        }
        let layers = ensure_layers_default(world, entity)
        ensure_visibility_defaults(world, entity)
        if (try! world.contains_by_key(entity, ecs_key_ui_image)) &&
          (try! world.contains_by_key(entity, @sprite.ecs_key_sprite)) {
          // UiImage rendering is handled by the UI pipeline, not the Sprite pipeline.
          try! (world.take(entity, @sprite.ecs_key_sprite) |> ignore)
        }

        // Sync text handles (state-based text pipeline) for UI text nodes.
        if @text.ui_text_ecs_handle(world, entity) is Some(text_handle) {
          @text.text_set_ui_camera_entity(text_handle, root_ctx.camera_entity)
          @text.text_set_logical_viewport_size(
            text_handle,
            Some(root_ctx.viewport_size),
          )
          let node = match (try! world.get_by_key(entity, ecs_key_node)) {
            Some(v) => v
            None => Node::default()
          }
          let border_l = clamp_nonneg(
            resolve_axis(node.border.left, size.x, root_ctx.viewport_size),
          )
          let border_r = clamp_nonneg(
            resolve_axis(node.border.right, size.x, root_ctx.viewport_size),
          )
          let border_t = clamp_nonneg(
            resolve_axis(node.border.top, size.y, root_ctx.viewport_size),
          )
          let border_b = clamp_nonneg(
            resolve_axis(node.border.bottom, size.y, root_ctx.viewport_size),
          )
          let pad_l = clamp_nonneg(
            resolve_axis(node.padding.left, size.x, root_ctx.viewport_size),
          )
          let pad_r = clamp_nonneg(
            resolve_axis(node.padding.right, size.x, root_ctx.viewport_size),
          )
          let pad_t = clamp_nonneg(
            resolve_axis(node.padding.top, size.y, root_ctx.viewport_size),
          )
          let pad_b = clamp_nonneg(
            resolve_axis(node.padding.bottom, size.y, root_ctx.viewport_size),
          )
          let inset_l = border_l + pad_l
          let inset_r = border_r + pad_r
          let inset_t = border_t + pad_t
          let inset_b = border_b + pad_b
          let content_size = @math.Vec2::new(
            clamp_nonneg(size.x - inset_l - inset_r),
            clamp_nonneg(size.y - inset_t - inset_b),
          )
          let content_min = @math.Vec2::new(
            rect.min.x + inset_l,
            rect.min.y + inset_t,
          )
          let content_rect = @math.Rect::new(
            content_min,
            @math.Vec2::new(
              content_min.x + content_size.x,
              content_min.y + content_size.y,
            ),
          )
          let text_transform = ui_world_transform(root_ctx, content_rect, 0.0F)
          @text.text_set_y_axis(
            text_handle,
            @text.YAxisOrientation::TopToBottom,
          )
          @text.text_set_ui_node_size(text_handle, Some(content_size))
          @text.text_set_transform(text_handle, text_transform)
          @text.text_set_layers(text_handle, layers)
        }
      }
      let scroll_raw = match
        (try! world.get_by_key(entity, ecs_key_scroll_position)) {
        Some(v) => v
        None => ScrollPosition::default()
      }
      let scroll = match (try! world.get_by_key(entity, ecs_key_node)) {
        Some(node) => {
          let x = if node.overflow.x == OverflowAxis::Scroll &&
            scroll_raw.offset_x > 0.0F {
            scroll_raw.offset_x
          } else {
            0.0F
          }
          let y = if node.overflow.y == OverflowAxis::Scroll &&
            scroll_raw.offset_y > 0.0F {
            scroll_raw.offset_y
          } else {
            0.0F
          }
          ScrollPosition::new(x, y)
        }
        None => ScrollPosition::default()
      }
      let child_rect = @math.Rect::new(
        @math.Vec2::new(
          rect.min.x - scroll.offset_x,
          rect.min.y - scroll.offset_y,
        ),
        @math.Vec2::new(
          rect.max.x - scroll.offset_x,
          rect.max.y - scroll.offset_y,
        ),
      )
      for child in ui_collect_effective_children(world, entity) {
        apply_layout(child, child_rect)
      }
    }

    apply_layout(root, root_rect)
  }

  let mut any_root = false
  for root in roots {
    any_root = true
    layout_root(root)
  }
  any_root |> ignore
}

///|
/// Update `ScrollPosition` using the current mouse wheel delta.
///
/// This is an MVP scroll implementation:
/// - Picks the topmost scroll container under the pointer by `UiStack`.
/// - Applies wheel deltas directly to the stored offsets (clamped to >= 0).
pub fn ui_scroll_system(world : @ecs.World) -> Unit {
  let res = get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  let stack_res = get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  guard ctx0.pointer_pos is Some(pointer) else { return }
  let delta = ctx0.wheel_delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }
  let mut target : @core.Entity? = None
  for i in 0..<stack0.uinodes.length() {
    let idx = stack0.uinodes.length() - 1 - i
    let entity = stack0.uinodes[idx]
    if !(try! world.contains_by_key(entity, ecs_key_scroll_position)) {
      continue
    }
    guard (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) else {
      continue
    }
    guard (try! world.get_by_key(entity, ecs_key_node)) is Some(node) else {
      continue
    }
    if !layout.rect.contains(pointer) {
      continue
    }
    let can_scroll = node.overflow.x == OverflowAxis::Scroll ||
      node.overflow.y == OverflowAxis::Scroll
    if !can_scroll {
      continue
    }
    target = Some(entity)
    break
  }
  guard target is Some(target_e) else { return }
  let prev = match (try! world.get_by_key(target_e, ecs_key_scroll_position)) {
    Some(v) => v
    None => ScrollPosition::default()
  }
  guard (try! world.get_by_key(target_e, ecs_key_node)) is Some(target_node) else {
    return
  }
  let scrolls_x = target_node.overflow.x == OverflowAxis::Scroll
  let scrolls_y = target_node.overflow.y == OverflowAxis::Scroll
  let abs_dx = if delta.x < 0.0F { 0.0F - delta.x } else { delta.x }
  let abs_dy = if delta.y < 0.0F { 0.0F - delta.y } else { delta.y }
  let mut dx = delta.x
  let mut dy = delta.y
  // Match the host accessibility wheel bridge: when both axes are scrollable,
  // pick the dominant axis to avoid accidental horizontal drift from touchpads.
  if scrolls_x && scrolls_y {
    if abs_dy >= abs_dx {
      dx = 0.0F
    } else {
      dy = 0.0F
    }
  }
  let mut max_offset_x = 0.0F
  let mut max_offset_y = 0.0F
  if (try! world.get_by_key(target_e, ecs_key_ui_layout)) is Some(target_layout) {
    let target_size = target_layout.rect.size()
    let children = ui_collect_effective_children(world, target_e)
    if target_size.x > 0.0F && target_size.y > 0.0F {
      let mut content_min : @math.Vec2? = None
      let mut content_max : @math.Vec2? = None
      for child in children {
        if (try! world.get_by_key(child, ecs_key_ui_layout))
          is Some(child_layout) {
          let unscrolled_min = @math.Vec2::new(
            child_layout.rect.min.x + prev.offset_x,
            child_layout.rect.min.y + prev.offset_y,
          )
          let unscrolled_max = @math.Vec2::new(
            child_layout.rect.max.x + prev.offset_x,
            child_layout.rect.max.y + prev.offset_y,
          )
          content_min = match content_min {
            Some(current) =>
              Some(
                @math.Vec2::new(
                  if unscrolled_min.x < current.x {
                    unscrolled_min.x
                  } else {
                    current.x
                  },
                  if unscrolled_min.y < current.y {
                    unscrolled_min.y
                  } else {
                    current.y
                  },
                ),
              )
            None => Some(unscrolled_min)
          }
          content_max = match content_max {
            Some(current) =>
              Some(
                @math.Vec2::new(
                  if unscrolled_max.x > current.x {
                    unscrolled_max.x
                  } else {
                    current.x
                  },
                  if unscrolled_max.y > current.y {
                    unscrolled_max.y
                  } else {
                    current.y
                  },
                ),
              )
            None => Some(unscrolled_max)
          }
        }
      }
      match (content_min, content_max) {
        (Some(min_v), Some(max_v)) => {
          let content_w = max_v.x - min_v.x
          let content_h = max_v.y - min_v.y
          let overflow_x = content_w - target_size.x
          let overflow_y = content_h - target_size.y
          if overflow_x > 0.0F {
            max_offset_x = overflow_x
          }
          if overflow_y > 0.0F {
            max_offset_y = overflow_y
          }
        }
        _ => ()
      }
    }
  }
  let mut next_x = if target_node.overflow.x == OverflowAxis::Scroll {
    prev.offset_x + dx
  } else {
    0.0F
  }
  let mut next_y = if target_node.overflow.y == OverflowAxis::Scroll {
    prev.offset_y + dy
  } else {
    0.0F
  }
  if next_x < 0.0F {
    next_x = 0.0F
  }
  if next_y < 0.0F {
    next_y = 0.0F
  }
  if next_x > max_offset_x {
    next_x = max_offset_x
  }
  if next_y > max_offset_y {
    next_y = max_offset_y
  }
  let next = ScrollPosition::{ offset_x: next_x, offset_y: next_y }
  if (try! world.contains_by_key(target_e, ecs_key_scroll_position)) {
    try! (world.replace(target_e, ecs_key_scroll_position, next) |> ignore)
  } else {
    try! world.set_by_key(target_e, ecs_key_scroll_position, next)
  }
}

///|
/// Compute `CalculatedClip` and attach `@sprite.ScissorRect` for clipped UI.
pub fn ui_clip_system(world : @ecs.World) -> Unit {
  let res = get_ui_context_resource(world)
  let legacy_ctx = res.get()
  let roots = ui_collect_root_entities(world)
  fn clamp_nonneg(v : Float) -> Float {
    if v < 0.0F {
      0.0F
    } else {
      v
    }
  }

  fn resolve_axis(
    val : Val,
    node_axis : Float,
    viewport_size : @math.Vec2,
  ) -> Float {
    match val {
      Val::Auto => 0.0F
      Val::Px(px) => px
      Val::Percent(p) => node_axis * (p / 100.0F)
      Val::Vw(p) => viewport_size.x * (p / 100.0F)
      Val::Vh(p) => viewport_size.y * (p / 100.0F)
      Val::VMin(p) => {
        let m = if viewport_size.x < viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
      Val::VMax(p) => {
        let m = if viewport_size.x > viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
    }
  }

  fn resolve_uirect_px(
    rect : UiRect,
    node_size : @math.Vec2,
    viewport_size : @math.Vec2,
  ) -> (Float, Float, Float, Float) {
    let left = clamp_nonneg(resolve_axis(rect.left, node_size.x, viewport_size))
    let right = clamp_nonneg(
      resolve_axis(rect.right, node_size.x, viewport_size),
    )
    let top = clamp_nonneg(resolve_axis(rect.top, node_size.y, viewport_size))
    let bottom = clamp_nonneg(
      resolve_axis(rect.bottom, node_size.y, viewport_size),
    )
    (left, top, right, bottom)
  }

  fn rect_intersect(a : @math.Rect, b : @math.Rect) -> @math.Rect {
    let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
    let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
    let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
    let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
    let min = @math.Vec2::new(min_x, min_y)
    let max = @math.Vec2::new(
      if max_x < min_x {
        min_x
      } else {
        max_x
      },
      if max_y < min_y {
        min_y
      } else {
        max_y
      },
    )
    @math.Rect::new(min, max)
  }

  fn rect_is_full_viewport(r : @math.Rect, viewport_rect : @math.Rect) -> Bool {
    r.min.x <= 0.0F &&
    r.min.y <= 0.0F &&
    r.max.x >= viewport_rect.max.x &&
    r.max.y >= viewport_rect.max.y
  }

  fn walk(
    entity : @core.Entity,
    inherited_clip : @math.Rect,
    clipped_by_parent : Bool,
    viewport_rect : @math.Rect,
    viewport_size : @math.Vec2,
  ) -> Unit {
    if ui_is_ghost_node(world, entity) {
      if (try! world.contains_by_key(entity, ecs_key_calculated_clip)) {
        try! (world.take(entity, ecs_key_calculated_clip) |> ignore)
      }
      if (try! world.contains_by_key(entity, @sprite.ecs_key_scissor_rect)) {
        try! (world.take(entity, @sprite.ecs_key_scissor_rect) |> ignore)
      }
      for child in ui_collect_effective_children(world, entity) {
        walk(
          child, inherited_clip, clipped_by_parent, viewport_rect, viewport_size,
        )
      }
      return
    }
    // Default to viewport clip if this node does not have layout yet.
    let self_clip = inherited_clip
    let calc = CalculatedClip::{ clip: self_clip }
    if (try! world.contains_by_key(entity, ecs_key_calculated_clip)) {
      try! (world.replace(entity, ecs_key_calculated_clip, calc) |> ignore)
    } else {
      try! world.set_by_key(entity, ecs_key_calculated_clip, calc)
    }
    if clipped_by_parent && !rect_is_full_viewport(self_clip, viewport_rect) {
      let scissor = @sprite.ScissorRect::new(self_clip)
      if (try! world.contains_by_key(entity, @sprite.ecs_key_scissor_rect)) {
        try! (world.replace(entity, @sprite.ecs_key_scissor_rect, scissor)
        |> ignore)
      } else {
        try! world.set_by_key(entity, @sprite.ecs_key_scissor_rect, scissor)
      }
    } else if (try! world.contains_by_key(entity, @sprite.ecs_key_scissor_rect)) {
      try! (world.take(entity, @sprite.ecs_key_scissor_rect) |> ignore)
    }
    if @text.ui_text_ecs_handle(world, entity) is Some(text_handle) {
      let text_scissor = if clipped_by_parent &&
        !rect_is_full_viewport(self_clip, viewport_rect) {
        Some(self_clip)
      } else {
        None
      }
      @text.text_set_ui_scissor(text_handle, text_scissor)
    }
    let node = match (try! world.get_by_key(entity, ecs_key_node)) {
      Some(v) => v
      None => Node::default()
    }
    let mut child_clip = self_clip
    let mut child_clipped = clipped_by_parent
    if (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) {
      let overflow_clips = node.overflow.x != OverflowAxis::Visible ||
        node.overflow.y != OverflowAxis::Visible
      if overflow_clips {
        let size = layout.rect.size()
        let (border_l, border_t, border_r, border_b) = resolve_uirect_px(
          node.border,
          size,
          viewport_size,
        )
        let (padding_l, padding_t, padding_r, padding_b) = resolve_uirect_px(
          node.padding,
          size,
          viewport_size,
        )
        let (inset_l, inset_t, inset_r, inset_b) = match
          node.overflow_clip_margin.visual_box {
          OverflowClipBox::BorderBox => (0.0F, 0.0F, 0.0F, 0.0F)
          OverflowClipBox::PaddingBox =>
            (border_l, border_t, border_r, border_b)
          OverflowClipBox::ContentBox =>
            (
              border_l + padding_l,
              border_t + padding_t,
              border_r + padding_r,
              border_b + padding_b,
            )
        }
        let margin = clamp_nonneg(node.overflow_clip_margin.margin)
        let min = @math.Vec2::new(
          layout.rect.min.x + inset_l - margin,
          layout.rect.min.y + inset_t - margin,
        )
        let max = @math.Vec2::new(
          layout.rect.max.x - inset_r + margin,
          layout.rect.max.y - inset_b + margin,
        )
        let mut clip_rect = @math.Rect::new(min, max)
        if node.overflow.x == OverflowAxis::Visible {
          clip_rect = @math.Rect::new(
            @math.Vec2::new(self_clip.min.x, clip_rect.min.y),
            @math.Vec2::new(self_clip.max.x, clip_rect.max.y),
          )
        }
        if node.overflow.y == OverflowAxis::Visible {
          clip_rect = @math.Rect::new(
            @math.Vec2::new(clip_rect.min.x, self_clip.min.y),
            @math.Vec2::new(clip_rect.max.x, self_clip.max.y),
          )
        }
        child_clip = rect_intersect(self_clip, clip_rect)
        child_clipped = true
      }
    }
    for child in ui_collect_effective_children(world, entity) {
      walk(child, child_clip, child_clipped, viewport_rect, viewport_size)
    }
  }

  for root in roots {
    let root_ctx = ui_root_resolved_camera_state(world, root, legacy_ctx)
    let viewport_rect = @math.Rect::new(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(root_ctx.viewport_size.x, root_ctx.viewport_size.y),
    )
    walk(root, viewport_rect, false, viewport_rect, root_ctx.viewport_size)
  }
}

///|
/// Build `UiStack` ordering (back-to-front), aligned with Bevy `ui_stack_system`.
///
/// Roots are:
/// - Any UI entity with `UiLayout` and no `Parent`
/// - Any entity with `GlobalZIndex` and `UiLayout` (even if parented)
/// - Any entity tagged `UiRoot` (compat with older code paths)
///
/// Children are visited in depth-first order, sorted by `ZIndex` ascending,
/// while preserving insertion order for ties.
pub fn ui_stack_system(world : @ecs.World) -> Unit {
  let res = get_ui_stack_resource(world)
  let stack = Ref::new(res.get().unwrap_or(UiStack::default()))
  UiStack::clear(stack)
  fn cmp_int(a : Int, b : Int) -> Int {
    if a < b {
      -1
    } else if a > b {
      1
    } else {
      0
    }
  }

  fn local_z(entity : @core.Entity) -> Int {
    match (try! world.get_by_key(entity, ecs_key_z_index)) {
      Some(v) => v.value
      None => 0
    }
  }

  fn global_z(entity : @core.Entity) -> Int {
    match (try! world.get_by_key(entity, ecs_key_global_z_index)) {
      Some(v) => v.value
      None => 0
    }
  }

  let visited : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  let roots : Array[(@core.Entity, Int, Int, Int)] = []

  // Root candidates: unparented UI layout nodes.
  let mut root_tie = 0
  world.for_each_component(ecs_key_ui_layout, fn(entity, _layout) {
    if ui_effective_parent(world, entity) is Some(_) {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push((entity, global_z(entity), local_z(entity), root_tie))
    root_tie = root_tie + 1
  })

  // Compat roots: explicit UiRoot markers.
  world.for_each_component(ecs_key_ui_root, fn(entity, _marker) {
    guard (try! world.contains_by_key(entity, ecs_key_ui_layout)) else {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push((entity, global_z(entity), local_z(entity), root_tie))
    root_tie = root_tie + 1
  })

  // Global-z roots (even if parented).
  world.for_each_component(ecs_key_global_z_index, fn(entity, _gz) {
    guard (try! world.contains_by_key(entity, ecs_key_ui_layout)) else {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push((entity, global_z(entity), local_z(entity), root_tie))
    root_tie = root_tie + 1
  })

  // Sort roots by (global_z, local_z, tie).
  roots.sort_by(fn(a, b) {
    let cg = cmp_int(a.1, b.1)
    if cg != 0 {
      return cg
    }
    let cl = cmp_int(a.2, b.2)
    if cl != 0 {
      return cl
    }
    cmp_int(a.3, b.3)
  })
  fn visit(entity : @core.Entity, stack : Ref[UiStack]) -> Unit {
    guard (try! world.contains_by_key(entity, ecs_key_ui_layout)) else {
      return
    }
    stack.val.uinodes.push(entity)
    let children = ui_collect_effective_children(world, entity)
    if children.length() == 0 {
      return
    }
    let buf : Array[(@core.Entity, Int, Int)] = []
    for i in 0..<children.length() {
      let child = children[i]
      if !(try! world.contains_by_key(child, ecs_key_ui_layout)) {
        continue
      }
      // Avoid revisiting nodes that will be treated as separate roots.
      if (try! world.contains_by_key(child, ecs_key_global_z_index)) {
        continue
      }
      buf.push((child, local_z(child), i))
    }
    buf.sort_by(fn(a, b) {
      let cz = cmp_int(a.1, b.1)
      if cz != 0 {
        return cz
      }
      cmp_int(a.2, b.2)
    })
    for item in buf {
      visit(item.0, stack)
    }
  }

  for root in roots {
    visit(root.0, stack)
  }

  // Convert the Bevy-style UiStack ordering into a stable render z for the
  // engine's 2D renderer. We reserve a high base z to keep UI on top of 2D
  // world sprites, and use a coarse step to allow per-node sublayers.
  for i in 0..<stack.val.uinodes.length() {
    let entity = stack.val.uinodes[i]
    let z_base = UI_STACK_Z_BASE + int_to_float(i) * UI_STACK_Z_STEP
    let z = z_base + UI_STACK_Z_CONTENT
    match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(t0) => {
        let pos = @math.Vec2::new(t0.translation.x, t0.translation.y)
        let scale = @math.Vec2::new(t0.scale.x, t0.scale.y)
        let t = @transform.Transform::from_xy_rotation_scale(
          pos,
          t0.rotation_z(),
          scale,
          z~,
        )
        if (try! world.contains_by_key(entity, @transform.ecs_key_transform)) {
          try! (world.replace(entity, @transform.ecs_key_transform, t) |> ignore)
        } else {
          try! world.set_by_key(entity, @transform.ecs_key_transform, t)
        }
      }
      None => ()
    }
    if @text.ui_text_ecs_handle(world, entity) is Some(text_handle) {
      match @text.text_get_transform(text_handle) {
        Some(t1) => {
          let pos = @math.Vec2::new(t1.translation.x, t1.translation.y)
          let scale = @math.Vec2::new(t1.scale.x, t1.scale.y)
          let z = z_base + UI_STACK_Z_TEXT
          let t_text = @transform.Transform::from_xy_rotation_scale(
            pos,
            t1.rotation_z(),
            scale,
            z~,
          )
          @text.text_set_transform(text_handle, t_text)
        }
        None => ()
      }
    }
  }
  res.insert(stack.val)
}

///|
/// Build an AccessKit `TreeUpdate` for the current UI tree.
pub fn ui_build_a11y_tree_update(
  world : @ecs.World,
) -> @moon_accesskit.TreeUpdate {
  let res = get_ui_context_resource(world)
  let legacy_ctx = res.get()
  let stack_res = get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else {
    let root = @moon_accesskit.NodeId::root()
    let update = @moon_accesskit.TreeUpdate::new(
      @moon_accesskit.TreeId::root(),
      root,
    )
    update.set_tree(@moon_accesskit.Tree::new(root))
    update
  }
  let a11y_state_res = @a11y.get_a11y_state_resource(world)

  // Build the set of required nodes (focusables + their ancestor chain), so
  // every node's parent always exists in this update.
  let required : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  fn key(entity : @core.Entity) -> (Int, Int) {
    (entity.id, entity.generation)
  }

  fn mark_required(
    required : @hashmap.HashMap[(Int, Int), Bool],
    entity : @core.Entity,
  ) -> Unit {
    let mut cur = Some(entity)
    while cur is Some(e) {
      if !(try! world.contains_by_key(e, ecs_key_ui_layout)) {
        break
      }
      let k = key(e)
      if required.contains(k) {
        break
      }
      required.set(k, true)
      cur = ui_effective_parent(world, e)
    }
  }

  for entity in stack0.uinodes {
    if (try! world.get_by_key(entity, ecs_key_ui_layout)) is None {
      continue
    }
    if (try! world.contains_by_key(entity, ecs_key_button)) ||
      (try! world.contains_by_key(entity, ecs_key_label)) ||
      (try! world.contains_by_key(entity, ecs_key_image_node)) ||
      (try! world.contains_by_key(entity, ecs_key_accessibility_label)) {
      mark_required(required, entity)
    }
  }
  fn push_nonempty(parts : Ref[Array[String]], text : String) -> Unit {
    let trimmed = text.trim()
    if trimmed != "" {
      parts.val.push(trimmed.to_string())
    }
  }

  fn collect_subtree_text(
    entity : @core.Entity,
    out : Ref[Array[String]],
  ) -> Unit {
    if (try! world.get_by_key(entity, @text.ecs_key_text)) is Some(text_root) {
      push_nonempty(out, text_root.content)
    }
    if (try! world.get_by_key(entity, @text.ecs_key_text_span))
      is Some(text_span) {
      push_nonempty(out, text_span.content)
    }
    let children = ui_collect_effective_children(world, entity)
    if children.length() == 0 {
      return
    }
    for child in children {
      collect_subtree_text(child, out)
    }
  }

  fn join_with_space(parts : Array[String]) -> String {
    if parts.length() == 0 {
      return ""
    }
    let sb = StringBuilder::new(size_hint=0)
    for i in 0..<parts.length() {
      if i > 0 {
        sb.write_char(' ')
      }
      sb.write_string(parts[i])
    }
    sb.to_string()
  }

  fn calc_label_from_children(entity : @core.Entity) -> String? {
    let children = ui_collect_effective_children(world, entity)
    if children.length() == 0 {
      return None
    }
    let mut name : String? = None
    for child in children {
      let parts : Array[String] = []
      let out = Ref::new(parts)
      collect_subtree_text(child, out)
      if out.val.length() > 0 {
        name = Some(join_with_space(out.val))
      }
    }
    name
  }

  fn calc_value_from_self(entity : @core.Entity) -> String {
    let parts : Array[String] = []
    let out = Ref::new(parts)
    collect_subtree_text(entity, out)
    join_with_space(out.val)
  }

  // Root node.
  let tree_id = @moon_accesskit.TreeId::root()
  let root_id = @moon_accesskit.NodeId::root()
  let mut focus_id = match a11y_state_res.get() {
    Some(state) => @a11y.A11yState::focused_node(state)
    None => root_id
  }
  if focus_id != root_id {
    let mut exists = false
    for entity in stack0.uinodes {
      if required.contains(key(entity)) &&
        @a11y.node_id_for_entity(entity) == focus_id {
        exists = true
      }
    }
    if !exists {
      focus_id = root_id
    }
  }
  let update = @moon_accesskit.TreeUpdate::new(tree_id, focus_id)
  update.set_tree(@moon_accesskit.Tree::new(root_id))
  let root_node = @moon_accesskit.Node::new(@moon_accesskit.Role::Window)
  let mut root_min_x = 0.0
  let mut root_min_y = 0.0
  let mut root_max_x = 0.0
  let mut root_max_y = 0.0
  let mut has_root_bounds = false
  for entity in stack0.uinodes {
    if !required.contains(key(entity)) {
      continue
    }
    guard (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) else {
      continue
    }
    let entity_ctx = ui_entity_resolved_camera_state(world, entity, legacy_ctx)
    let size = layout.rect.size()
    let x0 = (entity_ctx.viewport_origin.x + layout.rect.min.x).to_double()
    let y0 = (entity_ctx.viewport_origin.y + layout.rect.min.y).to_double()
    let x1 = (entity_ctx.viewport_origin.x + layout.rect.min.x + size.x).to_double()
    let y1 = (entity_ctx.viewport_origin.y + layout.rect.min.y + size.y).to_double()
    if !has_root_bounds {
      root_min_x = x0
      root_min_y = y0
      root_max_x = x1
      root_max_y = y1
      has_root_bounds = true
    } else {
      if x0 < root_min_x {
        root_min_x = x0
      }
      if y0 < root_min_y {
        root_min_y = y0
      }
      if x1 > root_max_x {
        root_max_x = x1
      }
      if y1 > root_max_y {
        root_max_y = y1
      }
    }
  }
  root_node.set_bounds(
    @moon_accesskit.Rect::new(root_min_x, root_min_y, root_max_x, root_max_y),
  )

  // Attach top-level required nodes under the root.
  for entity in stack0.uinodes {
    if !required.contains(key(entity)) {
      continue
    }
    let parent_required = match ui_effective_parent(world, entity) {
      Some(parent) =>
        required.contains(key(parent)) &&
        (try! world.contains_by_key(parent, ecs_key_ui_layout))
      None => false
    }
    if !parent_required {
      root_node.push_child(@a11y.node_id_for_entity(entity))
    }
  }
  update.push_node(root_id, root_node)
  for entity in stack0.uinodes {
    if !required.contains(key(entity)) {
      continue
    }
    guard (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) else {
      continue
    }
    let node_id = @a11y.node_id_for_entity(entity)
    let explicit_label = match
      (try! world.get_by_key(entity, ecs_key_accessibility_label)) {
      Some(v) => v.text
      None => ""
    }
    let is_editable = (try! world.contains_by_key(entity, ecs_key_label)) &&
      (try! world.contains_by_key(entity, @text.ecs_key_text)) &&
      explicit_label != ""
    let role = if (try! world.contains_by_key(entity, ecs_key_button)) {
      @moon_accesskit.Role::Button
    } else if is_editable {
      @moon_accesskit.Role::TextInput
    } else if (try! world.contains_by_key(entity, ecs_key_label)) {
      @moon_accesskit.Role::Label
    } else if (try! world.contains_by_key(entity, ecs_key_image_node)) {
      @moon_accesskit.Role::Image
    } else {
      @moon_accesskit.Role::GenericContainer
    }
    let node = @moon_accesskit.Node::new(role)

    // Children in hierarchy order (filtered to required set).
    for child in ui_collect_effective_children(world, entity) {
      if required.contains(key(child)) {
        node.push_child(@a11y.node_id_for_entity(child))
      }
    }
    let rect = layout.rect
    let entity_ctx = ui_entity_resolved_camera_state(world, entity, legacy_ctx)
    let x0 = (entity_ctx.viewport_origin.x + rect.min.x).to_double()
    let y0 = (entity_ctx.viewport_origin.y + rect.min.y).to_double()
    let size = rect.size()
    let x1 = (entity_ctx.viewport_origin.x + rect.min.x + size.x).to_double()
    let y1 = (entity_ctx.viewport_origin.y + rect.min.y + size.y).to_double()
    node.set_bounds(@moon_accesskit.Rect::new(x0, y0, x1, y1))
    if (try! world.contains_by_key(entity, ecs_key_calculated_clip)) {
      node.set_clips_children()
    }
    match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
      Some(vv) => if !vv.is_visible() { node.set_hidden() }
      None => ()
    }
    let can_set_value = role == @moon_accesskit.Role::TextInput
    if role == @moon_accesskit.Role::Button {
      node.add_action(@moon_accesskit.Action::Focus)
      node.add_action(@moon_accesskit.Action::Click)
    }
    if (try! world.contains_by_key(entity, ecs_key_scroll_position)) {
      node.add_action(@moon_accesskit.Action::ScrollUp)
      node.add_action(@moon_accesskit.Action::ScrollDown)
      node.add_action(@moon_accesskit.Action::ScrollLeft)
      node.add_action(@moon_accesskit.Action::ScrollRight)
    }
    if can_set_value {
      node.add_action(@moon_accesskit.Action::SetValue)
      node.add_action(@moon_accesskit.Action::Focus)
    }
    if role == @moon_accesskit.Role::Button ||
      role == @moon_accesskit.Role::Image {
      let name = if explicit_label != "" {
        Some(explicit_label)
      } else {
        calc_label_from_children(entity)
      }
      match name {
        Some(s) => if s != "" { node.set_label(s) }
        None => ()
      }
    } else if role == @moon_accesskit.Role::Label {
      let value = calc_value_from_self(entity)
      if explicit_label != "" {
        node.set_label(explicit_label)
      }
      // Bevy-aligned: keep a `Label` node's value even if it is empty.
      node.set_value(value)
    } else if role == @moon_accesskit.Role::TextInput {
      if explicit_label != "" {
        node.set_label(explicit_label)
      }
      node.set_value(calc_value_from_self(entity))
    } else if explicit_label != "" {
      node.set_label(explicit_label)
    }
    update.push_node(node_id, node)
  }
  update
}

///|
/// Extract UI accessibility nodes and send them to the host bridge.
pub fn ui_a11y_update_system(world : @ecs.World) -> Unit {
  let update = ui_build_a11y_tree_update(world)
  @a11y.a11y_host_apply_update(update)
}

///|
pub fn ui_interaction_system(world : @ecs.World) -> Unit {
  let res = get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  let stack_res = get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  let pointer_window = @input.mouse_position()
  let pointer_ctx = ctx0.pointer_pos
  let legacy_ctx = Some(ctx0)
  let down = ctx0.pointer_down
  fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
    a.id == b.id && a.generation == b.generation
  }

  fn candidates_contains(xs : Array[@core.Entity], e : @core.Entity) -> Bool {
    for v in xs {
      if entity_eq(v, e) {
        return true
      }
    }
    false
  }

  // Collect interactive candidates:
  // - Anything that already has `Interaction`
  // - Anything tagged as `Button` (we auto-initialize `Interaction` for convenience)
  let candidates : Array[@core.Entity] = []
  world.for_each_component(ecs_key_interaction, fn(entity, _interaction) {
    candidates.push(entity)
  })
  world.for_each_component(ecs_key_button, fn(entity, _button) {
    if !candidates_contains(candidates, entity) {
      candidates.push(entity)
    }
    if !(try! world.contains_by_key(entity, ecs_key_interaction)) {
      try! world.set_by_key(entity, ecs_key_interaction, Interaction::None)
    }
  })
  fn rect_intersect(a : @math.Rect, b : @math.Rect) -> @math.Rect {
    let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
    let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
    let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
    let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
    let min = @math.Vec2::new(min_x, min_y)
    let max = @math.Vec2::new(
      if max_x < min_x {
        min_x
      } else {
        max_x
      },
      if max_y < min_y {
        min_y
      } else {
        max_y
      },
    )
    @math.Rect::new(min, max)
  }

  fn abs_float(value : Float) -> Float {
    if value < 0.0F {
      -value
    } else {
      value
    }
  }

  fn same_vec2(a : @math.Vec2, b : @math.Vec2) -> Bool {
    abs_float(a.x - b.x) <= 0.001F && abs_float(a.y - b.y) <= 0.001F
  }

  fn pointer_hit_for_entity(
    entity : @core.Entity,
    node_rect : @math.Rect,
    pointer : @math.Vec2,
    entity_ctx : UiResolvedCameraState,
  ) -> (Bool, @math.Vec2?) {
    let size = node_rect.size()
    if size.x <= 0.0F || size.y <= 0.0F {
      return (false, None)
    }
    let normalized_by_rect = Some(
      @math.Vec2::new(
        (pointer.x - node_rect.min.x) / size.x,
        (pointer.y - node_rect.min.y) / size.y,
      ),
    )
    if (try! world.contains_by_key(entity, ecs_key_node)) {
      return (node_rect.contains(pointer), normalized_by_rect)
    }
    let transform_opt = ui_pointer_hit_transform_for_entity(world, entity)
    match transform_opt {
      Some(node_transform) => {
        let pointer_world = ui_viewport_point_to_world(
          world, entity_ctx, pointer,
        )
        let relative = @math.Vec2::new(
          pointer_world.x - node_transform.translation.x,
          pointer_world.y - node_transform.translation.y,
        )
        let local_point = rotate_vec2(relative, -node_transform.rotation_z())
        let scale_x = node_transform.scale.x
        let scale_y = node_transform.scale.y
        if abs_float(scale_x) <= 1.0e-6F || abs_float(scale_y) <= 1.0e-6F {
          return (false, normalized_by_rect)
        }
        let half_w_world = size.x / 2.0F * abs_float(scale_x)
        let half_h_world = size.y / 2.0F * abs_float(scale_y)
        let contains = abs_float(local_point.x) <= half_w_world &&
          abs_float(local_point.y) <= half_h_world
        let local_unscaled = @math.Vec2::new(
          local_point.x / scale_x,
          local_point.y / scale_y,
        )
        let normalized_by_transform = Some(
          @math.Vec2::new(
            (local_unscaled.x + size.x / 2.0F) / size.x,
            (size.y / 2.0F - local_unscaled.y) / size.y,
          ),
        )
        (contains, normalized_by_transform)
      }
      None => (node_rect.contains(pointer), normalized_by_rect)
    }
  }

  // Apply interactions in UiStack order (front-to-back) until a `Block` focus
  // policy is hit. This matches Bevy: the last entry in UiStack receives input
  // first.
  let active : Array[@core.Entity] = []
  let mut captured = false
  if pointer_window is Some(_) || pointer_ctx is Some(_) {
    for i in 0..<stack0.uinodes.length() {
      if captured {
        break
      }
      let idx = stack0.uinodes.length() - 1 - i
      let entity = stack0.uinodes[idx]
      let entity_ctx = ui_entity_resolved_camera_state(
        world, entity, legacy_ctx,
      )
      let pointer = match pointer_window {
        Some(pointer_window_pos) =>
          ui_pointer_pos_in_viewport(
            pointer_window_pos,
            entity_ctx.viewport_origin,
            entity_ctx.viewport_size,
          )
        None =>
          if pointer_ctx is Some(p) &&
            same_vec2(entity_ctx.viewport_origin, ctx0.viewport_origin) &&
            same_vec2(entity_ctx.viewport_size, ctx0.viewport_size) {
            Some(p)
          } else {
            None
          }
      }
      guard pointer is Some(p) else { continue }
      if !candidates_contains(candidates, entity) {
        continue
      }
      if (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
        is Some(vv) &&
        !vv.is_visible() {
        continue
      }
      guard (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) else {
        continue
      }
      let node_rect = layout.rect
      let (contains_pointer, normalized) = pointer_hit_for_entity(
        entity, node_rect, p, entity_ctx,
      )
      if !contains_pointer {
        continue
      }
      let (clip_rect, has_clip) = match
        (try! world.get_by_key(entity, ecs_key_calculated_clip)) {
        Some(v) => (v.clip, true)
        None => (node_rect, false)
      }
      let visible_rect = rect_intersect(node_rect, clip_rect)
      if has_clip && !visible_rect.contains(p) {
        continue
      }

      // Update (or insert) RelativeCursorPosition.
      let size = node_rect.size()
      let mut normalized_visible = @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
      )
      let mut normalized_value = normalized
      if normalized_value is None && size.x > 0.0F && size.y > 0.0F {
        normalized_value = Some(
          @math.Vec2::new(
            (p.x - node_rect.min.x) / size.x,
            (p.y - node_rect.min.y) / size.y,
          ),
        )
      }
      if size.x > 0.0F && size.y > 0.0F {
        let vmin = @math.Vec2::new(
          (visible_rect.min.x - node_rect.min.x) / size.x,
          (visible_rect.min.y - node_rect.min.y) / size.y,
        )
        let vmax = @math.Vec2::new(
          (visible_rect.max.x - node_rect.min.x) / size.x,
          (visible_rect.max.y - node_rect.min.y) / size.y,
        )
        normalized_visible = @math.Rect::new(vmin, vmax)
      }
      let rcp = RelativeCursorPosition::{
        normalized_visible_node_rect: normalized_visible,
        normalized: normalized_value,
      }
      if (try! world.contains_by_key(entity, ecs_key_relative_cursor_position)) {
        try! (world.replace(entity, ecs_key_relative_cursor_position, rcp)
        |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_relative_cursor_position, rcp)
      }
      let next = if down { Interaction::Pressed } else { Interaction::Hovered }
      if (try! world.contains_by_key(entity, ecs_key_interaction)) {
        try! (world.replace(entity, ecs_key_interaction, next) |> ignore)
      } else {
        try! world.set_by_key(entity, ecs_key_interaction, next)
      }
      active.push(entity)
      let focus = match (try! world.get_by_key(entity, ecs_key_focus_policy)) {
        Some(v) => v
        None => FocusPolicy::Block
      }
      if focus == FocusPolicy::Block {
        captured = true
      }
    }
  }

  // Reset remaining candidates to None (unless currently pressed by the pointer).
  for entity in candidates {
    if candidates_contains(active, entity) {
      continue
    }
    let prev = match (try! world.get_by_key(entity, ecs_key_interaction)) {
      Some(v) => v
      None => Interaction::None
    }
    if prev != Interaction::None {
      try! (world.replace(entity, ecs_key_interaction, Interaction::None)
      |> ignore)
    }
    if (try! world.contains_by_key(entity, ecs_key_relative_cursor_position)) {
      try! (world.replace(
        entity,
        ecs_key_relative_cursor_position,
        RelativeCursorPosition::default(),
      )
      |> ignore)
    }
  }
}
