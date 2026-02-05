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
pub(all) enum Val {
  Auto
  Px(Float)
  Percent(Float)
  Vw(Float)
  Vh(Float)
  VMin(Float)
  VMax(Float)
}

///|
pub struct UiRect {
  left : Val
  top : Val
  right : Val
  bottom : Val
}

///|
pub fn UiRect::new(left : Val, top : Val, right : Val, bottom : Val) -> UiRect {
  UiRect::{ left, top, right, bottom }
}

///|
pub fn UiRect::default() -> UiRect {
  UiRect::new(Val::Auto, Val::Auto, Val::Auto, Val::Auto)
}

///|
/// Bevy-aligned display (matches Taffy).
pub(all) enum Display {
  Block
  Flex
  Grid
  None
} derive(Eq, Show)

///|
/// Bevy-aligned position type (subset).
pub(all) enum PositionType {
  Relative
  Absolute
} derive(Eq, Show)

///|
pub(all) enum OverflowAxis {
  Clip
  Hidden
  Scroll
  Visible
} derive(Eq, Show)

///|
pub struct Overflow {
  x : OverflowAxis
  y : OverflowAxis
}

///|
pub fn Overflow::default() -> Overflow {
  Overflow::{ x: OverflowAxis::Visible, y: OverflowAxis::Visible }
}

///|
pub(all) enum OverflowClipBox {
  BorderBox
  PaddingBox
  ContentBox
} derive(Eq, Show)

///|
pub struct OverflowClipMargin {
  visual_box : OverflowClipBox
  margin : Float
}

///|
pub fn OverflowClipMargin::default() -> OverflowClipMargin {
  OverflowClipMargin::{ visual_box: OverflowClipBox::BorderBox, margin: 0.0F }
}

///|
/// Bevy-aligned flex direction.
pub(all) enum FlexDirection {
  Column
  ColumnReverse
  Row
  RowReverse
} derive(Eq, Show)

///|
/// Bevy-aligned flex wrap.
pub(all) enum FlexWrap {
  NoWrap
  Wrap
  WrapReverse
} derive(Eq, Show)

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
} derive(Eq, Show)

///|
/// Bevy-aligned justify items.
pub(all) enum JustifyItems {
  Baseline
  Center
  Default
  End
  Start
  Stretch
} derive(Eq, Show)

///|
/// Bevy-aligned justify self.
pub(all) enum JustifySelf {
  Auto
  Baseline
  Center
  End
  Start
  Stretch
} derive(Eq, Show)

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
} derive(Eq, Show)

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
} derive(Eq, Show)

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
} derive(Eq, Show)

///|
pub(all) enum GridAutoFlow {
  Column
  ColumnDense
  Row
  RowDense
} derive(Eq, Show)

///|
pub(all) enum GridTrack {
  Auto
  Px(Float)
  Percent(Float)
  Fr(Float)
  MinContent
  MaxContent
} derive(Eq, Show)

///|
pub(all) enum GridTrackRepetition {
  Count(Int)
  AutoFill
  AutoFit
} derive(Eq, Show)

///|
pub struct RepeatedGridTrack {
  repetition : GridTrackRepetition
  tracks : Array[GridTrack]
}

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
}

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
#ecs.component
pub struct ZIndex {
  value : Int
}

///|
pub fn ZIndex::new(value : Int) -> ZIndex {
  ZIndex::{ value, }
}

///|
#ecs.component
pub struct GlobalZIndex {
  value : Int
}

///|
pub fn GlobalZIndex::new(value : Int) -> GlobalZIndex {
  GlobalZIndex::{ value, }
}

///|
#ecs.resource
pub struct UiScale {
  value : Float
}

///|
pub fn UiScale::new(value : Float) -> UiScale {
  UiScale::{ value, }
}

///|
#ecs.resource
pub struct UiStack {
  mut uinodes : Array[@core.Entity]
}

///|
pub fn UiStack::default() -> UiStack {
  UiStack::{ uinodes: [] }
}

///|
pub fn UiStack::uinodes(self : UiStack) -> Array[@core.Entity] {
  self.uinodes
}

///|
pub fn UiStack::clear(self : Ref[UiStack]) -> Unit {
  self.val.uinodes = []
}

///|
#ecs.component
pub struct ScrollPosition {
  offset_x : Float
  offset_y : Float
}

///|
pub fn ScrollPosition::default() -> ScrollPosition {
  ScrollPosition::{ offset_x: 0.0F, offset_y: 0.0F }
}

///|
#ecs.component
pub struct CalculatedClip {
  clip : @math.Rect
}

///|
#ecs.component
pub struct RelativeCursorPosition {
  normalized_visible_node_rect : @math.Rect
  normalized : @math.Vec2?
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum FocusPolicy {
  Block
  Pass
} derive(Eq, Show)

///|
pub fn FocusPolicy::default() -> FocusPolicy {
  FocusPolicy::Pass
}

///|
pub(all) enum UiAntiAlias {
  Off
  On
} derive(Eq, Show)

///|
pub struct BorderRadius {
  top_left : Val
  top_right : Val
  bottom_left : Val
  bottom_right : Val
}

///|
pub fn BorderRadius::default() -> BorderRadius {
  BorderRadius::{
    top_left: Val::Px(0.0F),
    top_right: Val::Px(0.0F),
    bottom_left: Val::Px(0.0F),
    bottom_right: Val::Px(0.0F),
  }
}

///|
#ecs.component
pub struct BorderColor {
  color : @render2d.Color
}

///|
pub fn BorderColor::new(color : @render2d.Color) -> BorderColor {
  BorderColor::{ color, }
}

///|
/// The style of a UI node (Bevy v0.15.3-aligned surface).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Node {
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
}

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
pub fn Node::with_left(self : Node, left : Val) -> Node {
  Node::{ ..self, left, }
}

///|
pub fn Node::with_top(self : Node, top : Val) -> Node {
  Node::{ ..self, top, }
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiRoot {}

///|
pub fn UiRoot::default() -> UiRoot {
  UiRoot::{  }
}

///|
/// Computed layout rectangle in logical pixels, top-left origin (viewport space).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiLayout {
  rect : @math.Rect
}

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  UiLayout::{ rect, }
}

///|
/// Intrinsic content size used by the layout engine when width/height are `Auto`.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ContentSize {
  size : @math.Vec2
}

///|
pub fn ContentSize::new(size : @math.Vec2) -> ContentSize {
  ContentSize::{ size, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct BackgroundColor {
  color : @render2d.Color
}

///|
pub fn BackgroundColor::new(color : @render2d.Color) -> BackgroundColor {
  BackgroundColor::{ color, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiImage {
  image : @asset.Handle[@asset.Image]
}

///|
pub fn UiImage::new(image : @asset.Handle[@asset.Image]) -> UiImage {
  UiImage::{ image, }
}

///|

///|
/// Bevy-aligned interaction state component.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum Interaction {
  None
  Hovered
  Pressed
} derive(Eq, Show)

///|
/// Bevy-aligned button marker component.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Button {}

///|
pub fn Button::default() -> Button {
  Button::{  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ButtonColors {
  normal : @render2d.Color
  hovered : @render2d.Color
  pressed : @render2d.Color
}

///|
pub fn ButtonColors::new(
  normal : @render2d.Color,
  hovered : @render2d.Color,
  pressed : @render2d.Color,
) -> ButtonColors {
  ButtonColors::{ normal, hovered, pressed }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiText {
  handle : @text.TextHandle
}

///|
pub fn UiText::new(handle : @text.TextHandle) -> UiText {
  UiText::{ handle, }
}

///|
/// Optional accessibility label for UI nodes (used by the host a11y bridge).
#ecs.component
pub struct AccessibilityLabel {
  text : String
}

///|
pub fn AccessibilityLabel::new(text : String) -> AccessibilityLabel {
  AccessibilityLabel::{ text, }
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct UiContext {
  mut white_texture : @asset.Handle[@asset.Image]
  mut viewport_origin : @math.Vec2
  mut viewport_size : @math.Vec2
  mut camera_entity : @core.Entity?
  mut camera_transform : @math.Transform
  mut camera_scale : Float
  mut pointer_pos : @math.Vec2?
  mut pointer_down : Bool
  mut pointer_just_pressed : Bool
  mut pointer_just_released : Bool
  mut wheel_delta : @math.Vec2
}

///|
pub fn UiContext::default() -> UiContext {
  UiContext::{
    white_texture: @asset.Handle::new(-1),
    viewport_origin: @math.Vec2::new(0.0F, 0.0F),
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    camera_entity: None,
    camera_transform: @math.Transform::identity(),
    camera_scale: 1.0F,
    pointer_pos: None,
    pointer_down: false,
    pointer_just_pressed: false,
    pointer_just_released: false,
    wheel_delta: @math.Vec2::new(0.0F, 0.0F),
  }
}

///|
/// Public constructor (required because `UiContext` contains `mut` fields).
pub fn UiContext::new(
  white_texture : @asset.Handle[@asset.Image],
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
  camera_entity : @core.Entity?,
  camera_transform : @math.Transform,
  camera_scale : Float,
  pointer_pos : @math.Vec2?,
  pointer_down : Bool,
  pointer_just_pressed? : Bool = false,
  pointer_just_released? : Bool = false,
  wheel_delta? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
) -> UiContext {
  UiContext::{
    white_texture,
    viewport_origin,
    viewport_size,
    camera_entity,
    camera_transform,
    camera_scale,
    pointer_pos,
    pointer_down,
    pointer_just_pressed,
    pointer_just_released,
    wheel_delta,
  }
}

///|
pub let ui_set_context : @app.SystemSet = @app.system_set("mgstudio.ui.context")

///|
pub let ui_set_layout : @app.SystemSet = @app.system_set("mgstudio.ui.layout")

///|
pub let ui_set_interaction : @app.SystemSet = @app.system_set(
  "mgstudio.ui.interaction",
)

///|
pub let ui_set_scroll : @app.SystemSet = @app.system_set("mgstudio.ui.scroll")

///|
pub let ui_set_clip : @app.SystemSet = @app.system_set("mgstudio.ui.clip")

///|
pub let ui_set_stack : @app.SystemSet = @app.system_set("mgstudio.ui.stack")

///|
pub let ui_set_a11y : @app.SystemSet = @app.system_set("mgstudio.ui.a11y")

///|
pub let ui_set_a11y_apply : @app.SystemSet = @app.system_set(
  "mgstudio.ui.a11y_apply",
)

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
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
/// Convert a window-space pointer into viewport-space coordinates.
///
/// Returns `None` if the pointer is outside the viewport bounds.
pub fn ui_pointer_pos_in_viewport(
  mouse_pos : @math.Vec2,
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
) -> @math.Vec2? {
  let pos_in_view = @math.Vec2::new(
    mouse_pos.x - viewport_origin.x,
    mouse_pos.y - viewport_origin.y,
  )
  if pos_in_view.x >= 0.0F &&
    pos_in_view.y >= 0.0F &&
    pos_in_view.x <= viewport_size.x &&
    pos_in_view.y <= viewport_size.y {
    Some(pos_in_view)
  } else {
    None
  }
}

///|
fn[W : HasRes_UiContext + @core.ChangeTickWorld] ensure_ui_context_resource(
  world : W,
) -> Ref[UiContext]? {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_UiContext::get_ui_context_resource(world)
  if !res.is_present() {
    res.insert(UiContext::default(), tick)
  }
  res.get_ref_mut(tick)
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
  viewport : @render2d.Viewport,
  win_w : Int,
  win_h : Int,
) -> @render2d.Viewport {
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
  @render2d.Viewport::new(@math.IVec2::new(x, y), @math.IVec2::new(w, h))
}

///|
pub fn[
  W : HasRes_UiContext + @render2d.Has_Camera2d + @render2d.Has_Camera + @render2d.Has_Projection + @render2d.Has_RenderTarget + @math.Has_Transform + @transform.Has_GlobalTransform + @core.ChangeTickWorld,
] ui_update_context_system(
  world : W,
) -> Unit {
  guard ensure_ui_context_resource(world) is Some(ctx) else { return }
  create_white_texture_if_needed(ctx)
  let win_w = @window.window_width()
  let win_h = @window.window_height()
  let sf = safe_scale_factor(@window.window_scale_factor())

  // Select a screen Camera2d with the smallest order (Bevy-like).
  let camera2d_store = @render2d.Has_Camera2d::get_camera2d_store(world)
  let camera_store = @render2d.Has_Camera::get_camera_store(world)
  let projection_store = @render2d.Has_Projection::get_projection_store(world)
  let target_store = @render2d.Has_RenderTarget::get_render_target_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let global_store = @transform.Has_GlobalTransform::get_global_transform_store(
    world,
  )
  let mut best_entity : @core.Entity? = None
  let mut best_order : Int = 0
  camera2d_store.for_each(fn(entity, _marker) {
    let target = match target_store.get(entity) {
      Some(t) => t
      None => @render2d.RenderTarget::Screen
    }
    if target is @render2d.Image(_) {
      return
    }
    let camera = match camera_store.get(entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    match best_entity {
      None => {
        best_entity = Some(entity)
        best_order = camera.order
      }
      Some(_) =>
        if camera.order < best_order {
          best_entity = Some(entity)
          best_order = camera.order
        }
    }
  })
  let mut viewport_origin = @math.Vec2::new(0.0F, 0.0F)
  let mut viewport_size = @math.Vec2::new(
    int_to_float(win_w) / sf,
    int_to_float(win_h) / sf,
  )
  let mut camera_transform = @math.Transform::identity()
  let mut camera_scale = 1.0F
  if best_entity is Some(cam_entity) {
    let camera = match camera_store.get(cam_entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    let projection = match projection_store.get(cam_entity) {
      Some(@render2d.Orthographic(p)) => p
      _ => @render2d.OrthographicProjection::default_2d()
    }
    camera_scale = safe_camera_scale(projection.scale)
    camera_transform = match global_store.get(cam_entity) {
      Some(gt) => gt.to_transform_approx()
      None =>
        match transform_store.get(cam_entity) {
          Some(t) => t
          None => @math.Transform::identity()
        }
    }
    if camera.viewport is Some(vp0) {
      let vp = clamp_viewport_to_window(vp0, win_w, win_h)
      viewport_origin = @math.Vec2::new(
        int_to_float(vp.physical_position.x) / sf,
        int_to_float(vp.physical_position.y) / sf,
      )
      viewport_size = @math.Vec2::new(
        int_to_float(vp.physical_size.x) / sf,
        int_to_float(vp.physical_size.y) / sf,
      )
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
}

///|
fn[
  W : @core.ChangeTickWorld + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility,
] ensure_visibility_defaults(
  world : W,
  entity : @core.Entity,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let vis_store = @visibility.Has_Visibility::get_visibility_store(world)
  if !vis_store.contains(entity) {
    vis_store.insert(entity, @visibility.Visibility::Inherited, tick)
  }
  let inherited_store = @visibility.Has_InheritedVisibility::get_inherited_visibility_store(
    world,
  )
  if !inherited_store.contains(entity) {
    inherited_store.insert(
      entity,
      @visibility.InheritedVisibility::new(true),
      tick,
    )
  }
  let view_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  if !view_store.contains(entity) {
    view_store.insert(entity, @visibility.ViewVisibility::new(true), tick)
  }
}

///|
fn[W : @core.ChangeTickWorld + @render2d.Has_RenderLayers] ensure_layers_default(
  world : W,
  entity : @core.Entity,
) -> @render2d.RenderLayers {
  let store = @render2d.Has_RenderLayers::get_render_layers_store(world)
  match store.get(entity) {
    Some(v) => v
    None => {
      let tick = @core.ChangeTickWorld::read_change_tick(world)
      let layers = @render2d.RenderLayers::default()
      store.insert(entity, layers, tick)
      layers
    }
  }
}

///|
fn ui_world_transform(
  ctx : UiContext,
  rect : @math.Rect,
  z_index : Int,
) -> @math.Transform {
  let viewport_w = ctx.viewport_size.x
  let viewport_h = ctx.viewport_size.y
  let cam_scale = safe_camera_scale(ctx.camera_scale)
  let cam_rot = ctx.camera_transform.rotation_z()
  let cam_pos = @math.Vec2::new(
    ctx.camera_transform.translation.x,
    ctx.camera_transform.translation.y,
  )
  let center = rect.center()
  let half_w = viewport_w / 2.0F
  let half_h = viewport_h / 2.0F
  // Viewport top-left origin -> viewport center origin, with +Y up.
  let center_px = @math.Vec2::new(center.x - half_w, half_h - center.y)
  let center_scaled = @math.Vec2::new(
    center_px.x * cam_scale,
    center_px.y * cam_scale,
  )
  let offset = rotate_vec2(center_scaled, cam_rot)
  let world_pos = @math.Vec2::new(cam_pos.x + offset.x, cam_pos.y + offset.y)
  let z = 10000.0F + Float::from_double(z_index.to_double())
  @math.Transform::from_xy_rotation_scale(
    world_pos,
    cam_rot,
    @math.Vec2::new(cam_scale, cam_scale),
    z~,
  )
}

///|
fn button_color_for_state(
  colors : ButtonColors,
  state : Interaction?,
) -> @render2d.Color {
  match state {
    Some(s) =>
      match s {
        Interaction::Pressed => colors.pressed
        Interaction::Hovered => colors.hovered
        Interaction::None => colors.normal
      }
    None => colors.normal
  }
}

///|
pub fn[
  W : HasRes_UiContext + Has_UiRoot + Has_Node + Has_ContentSize + Has_ZIndex + Has_ScrollPosition + Has_UiLayout + Has_BackgroundColor + Has_UiImage + Has_ButtonColors + Has_Interaction + Has_UiText + @hierarchy.Has_Children + @render2d.Has_Sprite + @render2d.Has_RenderLayers + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility + @math.Has_Transform + @core.ChangeTickWorld,
] ui_layout_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }
  let root_store = Has_UiRoot::get_ui_root_store(world)
  let node_store = Has_Node::get_node_store(world)
  let content_size_store = Has_ContentSize::get_content_size_store(world)
  let z_store = Has_ZIndex::get_z_index_store(world)
  let scroll_store = Has_ScrollPosition::get_scroll_position_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let bg_store = Has_BackgroundColor::get_background_color_store(world)
  let img_store = Has_UiImage::get_ui_image_store(world)
  let button_store = Has_ButtonColors::get_button_colors_store(world)
  let interaction_store = Has_Interaction::get_interaction_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let root_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(ctx0.viewport_size.x, ctx0.viewport_size.y),
  )
  fn should_draw_node(
    sprite_store : @core.ComponentStore[@render2d.Sprite],
    bg_store : @core.ComponentStore[BackgroundColor],
    img_store : @core.ComponentStore[UiImage],
    button_store : @core.ComponentStore[ButtonColors],
    entity : @core.Entity,
  ) -> Bool {
    sprite_store.contains(entity) ||
    bg_store.contains(entity) ||
    img_store.contains(entity) ||
    button_store.contains(entity)
  }

  fn auto_size_for_entity(entity : @core.Entity) -> @math.Vec2 {
    match content_size_store.get(entity) {
      Some(v) => v.size
      None =>
        match ui_text_store.get(entity) {
          Some(text_node) =>
            match @text.text_get_layout_size(text_node.handle) {
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

  fn dim_for_val(val : Val) -> @moon_taffy.Dimension {
    match val {
      Auto => @moon_taffy.auto()
      Px(px) => @moon_taffy.length(f2d(px))
      Percent(p) => @moon_taffy.percent(f2d(p))
      Vw(p) => @moon_taffy.length(f2d(ctx0.viewport_size.x * (p / 100.0F)))
      Vh(p) => @moon_taffy.length(f2d(ctx0.viewport_size.y * (p / 100.0F)))
      VMin(p) => {
        let m = if ctx0.viewport_size.x < ctx0.viewport_size.y {
          ctx0.viewport_size.x
        } else {
          ctx0.viewport_size.y
        }
        @moon_taffy.length(f2d(m * (p / 100.0F)))
      }
      VMax(p) => {
        let m = if ctx0.viewport_size.x > ctx0.viewport_size.y {
          ctx0.viewport_size.x
        } else {
          ctx0.viewport_size.y
        }
        @moon_taffy.length(f2d(m * (p / 100.0F)))
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

  fn align_items_to_taffy(items : AlignItems) -> @moon_taffy.AlignItems {
    match items {
      AlignItems::Baseline => @moon_taffy.align_items_baseline()
      AlignItems::Center => @moon_taffy.align_items_center()
      AlignItems::Default => @moon_taffy.align_items_stretch()
      AlignItems::End => @moon_taffy.align_items_end()
      AlignItems::FlexEnd => @moon_taffy.align_items_flex_end()
      AlignItems::FlexStart => @moon_taffy.align_items_flex_start()
      AlignItems::Start => @moon_taffy.align_items_start()
      AlignItems::Stretch => @moon_taffy.align_items_stretch()
    }
  }

  fn justify_items_to_taffy(items : JustifyItems) -> @moon_taffy.JustifyItems {
    match items {
      JustifyItems::Baseline => @moon_taffy.align_items_baseline()
      JustifyItems::Center => @moon_taffy.align_items_center()
      JustifyItems::Default => @moon_taffy.align_items_stretch()
      JustifyItems::End => @moon_taffy.align_items_end()
      JustifyItems::Start => @moon_taffy.align_items_start()
      JustifyItems::Stretch => @moon_taffy.align_items_stretch()
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
  ) -> @moon_taffy.AlignContent {
    match content {
      AlignContent::Center => @moon_taffy.align_content_center()
      AlignContent::Default => @moon_taffy.align_content_stretch()
      AlignContent::End => @moon_taffy.align_content_end()
      AlignContent::FlexEnd => @moon_taffy.align_content_flex_end()
      AlignContent::FlexStart => @moon_taffy.align_content_flex_start()
      AlignContent::SpaceAround => @moon_taffy.align_content_space_around()
      AlignContent::SpaceBetween => @moon_taffy.align_content_space_between()
      AlignContent::SpaceEvenly => @moon_taffy.align_content_space_evenly()
      AlignContent::Start => @moon_taffy.align_content_start()
      AlignContent::Stretch => @moon_taffy.align_content_stretch()
    }
  }

  fn justify_content_to_taffy(
    content : JustifyContent,
  ) -> @moon_taffy.JustifyContent {
    match content {
      JustifyContent::Center => @moon_taffy.justify_content_center()
      JustifyContent::Default => @moon_taffy.justify_content_flex_start()
      JustifyContent::End => @moon_taffy.justify_content_end()
      JustifyContent::FlexEnd => @moon_taffy.justify_content_flex_end()
      JustifyContent::FlexStart => @moon_taffy.justify_content_flex_start()
      JustifyContent::SpaceAround => @moon_taffy.align_content_space_around()
      JustifyContent::SpaceBetween => @moon_taffy.align_content_space_between()
      JustifyContent::SpaceEvenly => @moon_taffy.align_content_space_evenly()
      JustifyContent::Start => @moon_taffy.justify_content_start()
      JustifyContent::Stretch => @moon_taffy.align_content_stretch()
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
    let node = match node_store.get(entity) {
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
      .with_align_items(align_items_to_taffy(node.align_items))
      .with_justify_items(justify_items_to_taffy(node.justify_items))
      .with_align_content(align_content_to_taffy(node.align_content))
      .with_justify_content(justify_content_to_taffy(node.justify_content))
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
            width=@moon_taffy.length(f2d(ctx0.viewport_size.x)),
            height=@moon_taffy.length(f2d(ctx0.viewport_size.y)),
          ),
        )
    }
    style
  }

  fn layout_root(root : @core.Entity) -> Unit {
    let taffy = @moon_taffy.TaffyTree::new()
    let entity_to_node : @hashmap.HashMap[(Int, Int), Int] = @hashmap.HashMap::new()
    let node_to_entity : @hashmap.HashMap[Int, @core.Entity] = @hashmap.HashMap::new()
    fn build(entity : @core.Entity, is_root : Bool) -> Int {
      let style = style_for_entity(entity, is_root)
      let child_ids : Array[Int] = []
      if children_store.get(entity) is Some(children) {
        for child in children.entities {
          child_ids.push(build(child, false))
        }
      }
      let id = if child_ids.length() == 0 {
        taffy.new_leaf(style)
      } else {
        taffy.new_with_children(style, child_ids)
      }
      entity_to_node.set(entity_key(entity), id)
      node_to_entity.set(id, entity)
      id
    }

    let root_node_id = build(root, true)
    let avail = @moon_taffy.Size::new(
      width=@moon_taffy.available_space_definite(f2d(ctx0.viewport_size.x)),
      height=@moon_taffy.available_space_definite(f2d(ctx0.viewport_size.y)),
    )
    fn measure(
      _known : @moon_taffy.Size[Double?],
      _available : @moon_taffy.Size[@moon_taffy.AvailableSpace],
      node_id : Int,
      _ctx : Unit?,
      _style : @moon_taffy.Style,
    ) -> @moon_taffy.Size[Double] {
      match node_to_entity.get(node_id) {
        Some(entity) => {
          let sz = auto_size_for_entity(entity)
          @moon_taffy.Size::new(width=f2d(sz.x), height=f2d(sz.y))
        }
        None => @moon_taffy.Size::zero()
      }
    }

    let compute_res = try? taffy.compute_layout_with_measure(
      root_node_id, avail, measure,
    )
    match compute_res {
      Ok(_) => ()
      Err(_) => return
    }
    fn apply_layout(entity : @core.Entity, parent_rect : @math.Rect) -> Unit {
      guard entity_to_node.get(entity_key(entity)) is Some(node_id) else {
        return
      }
      let layout_res = try? taffy.layout(node_id)
      guard layout_res is Ok(tl) else { return }
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
      if layout_store.contains(entity) {
        layout_store.set(entity, layout, tick) |> ignore
      } else {
        layout_store.insert(entity, layout, tick)
      }

      // Update render2d / transform for UI nodes (Node component required).
      if node_store.contains(entity) {
        let z_index = match z_store.get(entity) {
          Some(v) => v.value
          None => 0
        }
        let transform = ui_world_transform(ctx0, rect, z_index)
        if transform_store.contains(entity) {
          transform_store.set(entity, transform, tick) |> ignore
        } else {
          transform_store.insert(entity, transform, tick)
        }
        let layers = ensure_layers_default(world, entity)
        ensure_visibility_defaults(world, entity)
        if should_draw_node(
            sprite_store, bg_store, img_store, button_store, entity,
          ) {
          let texture = match img_store.get(entity) {
            Some(v) => v.image
            None => ctx0.white_texture
          }
          let button_colors_opt = button_store.get(entity)
          let color = match button_colors_opt {
            Some(colors) =>
              button_color_for_state(colors, interaction_store.get(entity))
            None =>
              match bg_store.get(entity) {
                Some(v) => v.color
                None => @render2d.Color::white()
              }
          }
          let sprite = @render2d.Sprite::from_image(texture)
            .with_color(color)
            .with_custom_size(Some(size))
          if sprite_store.contains(entity) {
            sprite_store.set(entity, sprite, tick) |> ignore
          } else {
            sprite_store.insert(entity, sprite, tick)
          }
        }

        // Sync text handles (state-based text pipeline) for label nodes.
        if ui_text_store.get(entity) is Some(text_node) {
          @text.text_set_y_axis(
            text_node.handle,
            @text.YAxisOrientation::TopToBottom,
          )
          @text.text_set_ui_node_size(text_node.handle, Some(size))
          @text.text_set_transform(text_node.handle, transform)
          @text.text_set_layers(text_node.handle, layers)
        }
      }
      let scroll = match scroll_store.get(entity) {
        Some(v) => v
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
      if children_store.get(entity) is Some(children) {
        for child in children.entities {
          apply_layout(child, child_rect)
        }
      }
    }

    apply_layout(root, root_rect)
  }

  let mut any_root = false
  root_store.for_each(fn(root, _marker) {
    any_root = true
    layout_root(root)
  })
  any_root |> ignore
}

///|
/// Update `ScrollPosition` using the current mouse wheel delta.
///
/// This is an MVP scroll implementation:
/// - Picks the topmost scroll container under the pointer by `UiStack`.
/// - Applies wheel deltas directly to the stored offsets (clamped to >= 0).
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + Has_Node + Has_UiLayout + Has_ScrollPosition + @core.ChangeTickWorld,
] ui_scroll_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  let stack_res = HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  guard ctx0.pointer_pos is Some(pointer) else { return }
  let delta = ctx0.wheel_delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }
  let node_store = Has_Node::get_node_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let scroll_store = Has_ScrollPosition::get_scroll_position_store(world)
  let mut target : @core.Entity? = None
  for i in 0..<stack0.uinodes.length() {
    let idx = stack0.uinodes.length() - 1 - i
    let entity = stack0.uinodes[idx]
    if !scroll_store.contains(entity) {
      continue
    }
    guard layout_store.get(entity) is Some(layout) else { continue }
    guard node_store.get(entity) is Some(node) else { continue }
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
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let prev = match scroll_store.get(target_e) {
    Some(v) => v
    None => ScrollPosition::default()
  }
  let mut next_x = prev.offset_x + delta.x
  let mut next_y = prev.offset_y + delta.y
  if next_x < 0.0F {
    next_x = 0.0F
  }
  if next_y < 0.0F {
    next_y = 0.0F
  }
  let next = ScrollPosition::{ offset_x: next_x, offset_y: next_y }
  if scroll_store.contains(target_e) {
    scroll_store.set(target_e, next, tick) |> ignore
  } else {
    scroll_store.insert(target_e, next, tick)
  }
}

///|
/// Compute `CalculatedClip` and attach `@render2d.ScissorRect` for clipped UI.
pub fn[
  W : HasRes_UiContext + Has_UiRoot + Has_Node + Has_UiLayout + Has_CalculatedClip + @render2d.Has_ScissorRect + @hierarchy.Has_Children + @core.ChangeTickWorld,
] ui_clip_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }
  let root_store = Has_UiRoot::get_ui_root_store(world)
  let node_store = Has_Node::get_node_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let clip_store = Has_CalculatedClip::get_calculated_clip_store(world)
  let scissor_store = @render2d.Has_ScissorRect::get_scissor_rect_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let viewport_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(ctx0.viewport_size.x, ctx0.viewport_size.y),
  )
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

  fn rect_is_full_viewport(r : @math.Rect) -> Bool {
    r.min.x <= 0.0F &&
    r.min.y <= 0.0F &&
    r.max.x >= viewport_rect.max.x &&
    r.max.y >= viewport_rect.max.y
  }

  fn walk(
    entity : @core.Entity,
    inherited_clip : @math.Rect,
    clipped_by_parent : Bool,
  ) -> Unit {
    // Default to viewport clip if this node does not have layout yet.
    let self_clip = inherited_clip
    let calc = CalculatedClip::{ clip: self_clip }
    if clip_store.contains(entity) {
      clip_store.set(entity, calc, tick) |> ignore
    } else {
      clip_store.insert(entity, calc, tick)
    }
    if clipped_by_parent && !rect_is_full_viewport(self_clip) {
      let scissor = @render2d.ScissorRect::new(self_clip)
      if scissor_store.contains(entity) {
        scissor_store.set(entity, scissor, tick) |> ignore
      } else {
        scissor_store.insert(entity, scissor, tick)
      }
    } else if scissor_store.contains(entity) {
      scissor_store.remove(entity) |> ignore
    }
    let node = match node_store.get(entity) {
      Some(v) => v
      None => Node::default()
    }
    let mut child_clip = self_clip
    let mut child_clipped = clipped_by_parent
    if layout_store.get(entity) is Some(layout) {
      let overflow_clips = node.overflow.x != OverflowAxis::Visible ||
        node.overflow.y != OverflowAxis::Visible
      if overflow_clips {
        child_clip = rect_intersect(self_clip, layout.rect)
        child_clipped = true
      }
    }
    if children_store.get(entity) is Some(children) {
      for child in children.entities {
        walk(child, child_clip, child_clipped)
      }
    }
  }

  root_store.for_each(fn(root, _marker) { walk(root, viewport_rect, false) })
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
pub fn[
  W : HasRes_UiStack + Has_UiRoot + Has_UiLayout + Has_ZIndex + Has_GlobalZIndex + @hierarchy.Has_Children + @hierarchy.Has_Parent + @core.ChangeTickWorld,
] ui_stack_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_UiStack::get_ui_stack_resource(world)
  if !res.is_present() {
    res.insert(UiStack::default(), tick)
  }
  guard res.get_ref_mut(tick) is Some(stack) else { return }
  UiStack::clear(stack)
  let root_store = Has_UiRoot::get_ui_root_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let z_store = Has_ZIndex::get_z_index_store(world)
  let gz_store = Has_GlobalZIndex::get_global_z_index_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)
  fn entity_key(e : @core.Entity) -> (Int, Int) {
    (e.id, e.generation)
  }

  fn cmp_int(a : Int, b : Int) -> Int {
    if a < b {
      -1
    } else if a > b {
      1
    } else {
      0
    }
  }

  fn local_z(
    z_store : @core.ComponentStore[ZIndex],
    entity : @core.Entity,
  ) -> Int {
    match z_store.get(entity) {
      Some(v) => v.value
      None => 0
    }
  }

  fn global_z(
    gz_store : @core.ComponentStore[GlobalZIndex],
    entity : @core.Entity,
  ) -> Int {
    match gz_store.get(entity) {
      Some(v) => v.value
      None => 0
    }
  }

  let visited : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  let roots : Array[(@core.Entity, Int, Int, Int)] = []

  // Root candidates: unparented UI layout nodes.
  let mut root_tie = 0
  layout_store.for_each(fn(entity, _layout) {
    if parent_store.contains(entity) {
      return
    }
    let key = entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(
      (entity, global_z(gz_store, entity), local_z(z_store, entity), root_tie),
    )
    root_tie = root_tie + 1
  })

  // Compat roots: explicit UiRoot markers.
  root_store.for_each(fn(entity, _marker) {
    guard layout_store.contains(entity) else { return }
    let key = entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(
      (entity, global_z(gz_store, entity), local_z(z_store, entity), root_tie),
    )
    root_tie = root_tie + 1
  })

  // Global-z roots (even if parented).
  gz_store.for_each(fn(entity, _gz) {
    guard layout_store.contains(entity) else { return }
    let key = entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(
      (entity, global_z(gz_store, entity), local_z(z_store, entity), root_tie),
    )
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
  fn visit(
    entity : @core.Entity,
    layout_store : @core.ComponentStore[UiLayout],
    z_store : @core.ComponentStore[ZIndex],
    gz_store : @core.ComponentStore[GlobalZIndex],
    children_store : @core.ComponentStore[@hierarchy.Children],
    stack : Ref[UiStack],
  ) -> Unit {
    guard layout_store.contains(entity) else { return }
    stack.val.uinodes.push(entity)
    guard children_store.get(entity) is Some(children) else { return }
    let buf : Array[(@core.Entity, Int, Int)] = []
    for i in 0..<children.entities.length() {
      let child = children.entities[i]
      if !layout_store.contains(child) {
        continue
      }
      // Avoid revisiting nodes that will be treated as separate roots.
      if gz_store.contains(child) {
        continue
      }
      buf.push((child, local_z(z_store, child), i))
    }
    buf.sort_by(fn(a, b) {
      let cz = cmp_int(a.1, b.1)
      if cz != 0 {
        return cz
      }
      cmp_int(a.2, b.2)
    })
    for item in buf {
      visit(item.0, layout_store, z_store, gz_store, children_store, stack)
    }
  }

  for root in roots {
    visit(root.0, layout_store, z_store, gz_store, children_store, stack)
  }
}

///|
/// Extract UI accessibility nodes and send them to the host bridge.
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + Has_UiLayout + Has_Button + Has_AccessibilityLabel + @hierarchy.Has_Parent,
] ui_a11y_update_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }
  let stack_res = HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let label_store = Has_AccessibilityLabel::get_accessibility_label_store(world)
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)

  // Host root id should not collide with entity-derived node ids.
  let root_id = -1
  @a11y.a11y_host_begin_update(root_id)

  // Build the set of required nodes (focusables + their ancestor chain), so
  // `parent_id` always points to a node present in this update.
  let required : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  fn key(entity : @core.Entity) -> (Int, Int) {
    (entity.id, entity.generation)
  }

  fn mark_required(
    required : @hashmap.HashMap[(Int, Int), Bool],
    parent_store : @core.ComponentStore[@hierarchy.Parent],
    layout_store : @core.ComponentStore[UiLayout],
    entity : @core.Entity,
  ) -> Unit {
    let mut cur = Some(entity)
    while cur is Some(e) {
      if !layout_store.contains(e) {
        break
      }
      let k = key(e)
      if required.contains(k) {
        break
      }
      required.set(k, true)
      cur = match parent_store.get(e) {
        Some(p) => Some(p.entity)
        None => None
      }
    }
  }

  for entity in stack0.uinodes {
    if layout_store.get(entity) is None {
      continue
    }
    if button_store.contains(entity) || label_store.contains(entity) {
      mark_required(required, parent_store, layout_store, entity)
    }
  }
  for entity in stack0.uinodes {
    if !required.contains(key(entity)) {
      continue
    }
    guard layout_store.get(entity) is Some(layout) else { continue }
    let rect = layout.rect
    let x = ctx0.viewport_origin.x + rect.min.x
    let y = ctx0.viewport_origin.y + rect.min.y
    let size = rect.size()
    let width = size.x
    let height = size.y
    let node_id = @a11y.node_id_for_entity(entity)
    let parent_id = match parent_store.get(entity) {
      Some(p) =>
        if required.contains(key(p.entity)) && layout_store.contains(p.entity) {
          @a11y.node_id_for_entity(p.entity)
        } else {
          root_id
        }
      None => root_id
    }
    let role_id = if button_store.contains(entity) {
      @a11y.host_role_button
    } else if label_store.contains(entity) {
      @a11y.host_role_label
    } else {
      @a11y.host_role_container
    }
    let mut actions_mask = 0
    if role_id == @a11y.host_role_button {
      actions_mask = @a11y.host_action_focus_bit + @a11y.host_action_default_bit
    }
    let name = match label_store.get(entity) {
      Some(v) => v.text
      None => if role_id == @a11y.host_role_button { "Button" } else { "" }
    }
    @core.with_host_string_id(name, fn(name_id) {
      @a11y.a11y_host_push_node(
        node_id, parent_id, role_id, x, y, width, height, name_id, actions_mask,
      )
    })
  }
  @a11y.a11y_host_end_update()
}

///|
/// Apply host-driven accessibility actions to UI state and picking events.
pub fn[
  W : @a11y.HasRes_A11yState + @picking.HasRes_PickingEvents + Has_Interaction + @core.ChangeTickWorld,
] ui_a11y_apply_actions_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  guard @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(tick)
    is Some(state) else {
    return
  }
  let actions = @a11y.A11yState::drain_actions(state)
  if actions.length() == 0 {
    return
  }
  guard @picking.HasRes_PickingEvents::get_picking_events_resource(world).get_ref_mut(
      tick,
    )
    is Some(events) else {
    return
  }
  let interaction_store = Has_Interaction::get_interaction_store(world)
  fn entity_from_node_id(node_id : Int) -> @core.Entity {
    let id = node_id / 65536
    let gen = node_id - id * 65536
    @core.Entity::new(id, gen)
  }

  for req in actions {
    let entity = entity_from_node_id(req.target)
    match req.action {
      @accesskit.Action::Focus =>
        // MVP: focus is handled by the host (tab/VO). Engine-side focus routing is TODO.
        entity |> ignore
      _ => {
        // Treat `Default` as an activation/click.
        if interaction_store.contains(entity) {
          interaction_store.set(entity, Interaction::Pressed, tick) |> ignore
        } else {
          interaction_store.insert(entity, Interaction::Pressed, tick)
        }
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(
            0,
            @picking.PointerEventKind::Click,
            @math.Vec2::new(0.0F, 0.0F),
            target=Some(entity),
          ),
        )
      }
    }
  }
}

///|
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + @picking.HasRes_PickingEvents + @picking.HasRes_PickingState + Has_UiLayout + Has_Button + Has_Interaction + Has_RelativeCursorPosition + Has_FocusPolicy + Has_CalculatedClip + Has_ButtonColors + @render2d.Has_Sprite + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] ui_interaction_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  let stack_res = HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let state_store = Has_Interaction::get_interaction_store(world)
  let cursor_store = Has_RelativeCursorPosition::get_relative_cursor_position_store(
    world,
  )
  let focus_store = Has_FocusPolicy::get_focus_policy_store(world)
  let clip_store = Has_CalculatedClip::get_calculated_clip_store(world)
  let colors_store = Has_ButtonColors::get_button_colors_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let pointer = ctx0.pointer_pos
  let down = ctx0.pointer_down
  let just_pressed = ctx0.pointer_just_pressed
  let just_released = ctx0.pointer_just_released
  fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
    a.id == b.id && a.generation == b.generation
  }

  fn option_entity_eq(a : @core.Entity?, b : @core.Entity?) -> Bool {
    match (a, b) {
      (None, None) => true
      (Some(x), Some(y)) => entity_eq(x, y)
      _ => false
    }
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
  state_store.for_each(fn(entity, _interaction) { candidates.push(entity) })
  button_store.for_each(fn(entity, _button) {
    if !candidates_contains(candidates, entity) {
      candidates.push(entity)
    }
    if !state_store.contains(entity) {
      state_store.insert(entity, Interaction::None, tick)
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

  // Apply interactions in UiStack order (front-to-back) until a `Block` focus
  // policy is hit. This matches Bevy: the last entry in UiStack receives input
  // first.
  let active : Array[@core.Entity] = []
  let mut captured = false
  if pointer is Some(p) {
    for i in 0..<stack0.uinodes.length() {
      if captured {
        break
      }
      let idx = stack0.uinodes.length() - 1 - i
      let entity = stack0.uinodes[idx]
      if !candidates_contains(candidates, entity) {
        continue
      }
      if vv_store.get(entity) is Some(vv) && !vv.is_visible() {
        continue
      }
      guard layout_store.get(entity) is Some(layout) else { continue }
      let node_rect = layout.rect
      if !node_rect.contains(p) {
        continue
      }
      let clip_rect = match clip_store.get(entity) {
        Some(v) => v.clip
        None => node_rect
      }
      let visible_rect = rect_intersect(node_rect, clip_rect)
      if !visible_rect.contains(p) {
        continue
      }

      // Update (or insert) RelativeCursorPosition.
      let size = node_rect.size()
      let mut normalized : @math.Vec2? = None
      let mut normalized_visible = @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
      )
      if size.x > 0.0F && size.y > 0.0F {
        let rel = @math.Vec2::new(
          (p.x - node_rect.min.x) / size.x,
          (p.y - node_rect.min.y) / size.y,
        )
        normalized = Some(rel)
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
        normalized,
      }
      if cursor_store.contains(entity) {
        cursor_store.set(entity, rcp, tick) |> ignore
      } else {
        cursor_store.insert(entity, rcp, tick)
      }
      let next = if down { Interaction::Pressed } else { Interaction::Hovered }
      if state_store.contains(entity) {
        state_store.set(entity, next, tick) |> ignore
      } else {
        state_store.insert(entity, next, tick)
      }
      active.push(entity)
      let focus = match focus_store.get(entity) {
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
    let prev = match state_store.get(entity) {
      Some(v) => v
      None => Interaction::None
    }
    if prev != Interaction::None {
      state_store.set(entity, Interaction::None, tick) |> ignore
    }
  }

  // Keep sprite colors in sync when `ButtonColors` is present (MVP compatibility).
  colors_store.for_each(fn(entity, colors) {
    if sprite_store.get(entity) is Some(sprite0) {
      let desired = button_color_for_state(colors, state_store.get(entity))
      let sprite = sprite0.with_color(desired)
      sprite_store.set(entity, sprite, tick) |> ignore
    }
  })

  // Picking event generation (single pointer = 0).
  let events_res = @picking.HasRes_PickingEvents::get_picking_events_resource(
    world,
  )
  let state_res = @picking.HasRes_PickingState::get_picking_state_resource(
    world,
  )
  guard events_res.get_ref_mut(tick) is Some(events) else { return }
  guard state_res.get_ref_mut(tick) is Some(picking_state) else { return }
  let pointer_id : @picking.PointerId = 0
  let hit_top : @core.Entity? = if active.length() > 0 {
    Some(active[0])
  } else {
    None
  }

  // Move.
  if pointer is Some(pos) {
    match picking_state.val.last_position {
      Some(prev) =>
        if prev.x != pos.x || prev.y != pos.y {
          @picking.PickingEvents::push(
            events,
            @picking.PointerEvent::new(
              pointer_id,
              @picking.PointerEventKind::Move,
              pos,
            ),
          )
        }
      None =>
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(
            pointer_id,
            @picking.PointerEventKind::Move,
            pos,
          ),
        )
    }
    @picking.PickingState::set_last_position(picking_state, Some(pos))
  } else {
    @picking.PickingState::set_last_position(picking_state, None)
  }

  // Hover enter/leave.
  let prev_hovered = picking_state.val.hovered
  if !option_entity_eq(prev_hovered, hit_top) {
    match prev_hovered {
      Some(prev_e) => {
        let pos = match pointer {
          Some(v) => v
          None => @math.Vec2::new(0.0F, 0.0F)
        }
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(
            pointer_id,
            @picking.PointerEventKind::Leave,
            pos,
            target=Some(prev_e),
          ),
        )
      }
      None => ()
    }
    match hit_top {
      Some(next_e) => {
        let pos = match pointer {
          Some(v) => v
          None => @math.Vec2::new(0.0F, 0.0F)
        }
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(
            pointer_id,
            @picking.PointerEventKind::Enter,
            pos,
            target=Some(next_e),
          ),
        )
      }
      None => ()
    }
    @picking.PickingState::set_hovered(picking_state, hit_top)
  }

  // Down / up / click.
  if just_pressed {
    if pointer is Some(pos) && hit_top is Some(target) {
      @picking.PickingEvents::push(
        events,
        @picking.PointerEvent::new(
          pointer_id,
          @picking.PointerEventKind::Down,
          pos,
          target=Some(target),
        ),
      )
      @picking.PickingState::set_pressed(picking_state, Some(target))
    }
  }
  if just_released {
    let pos = match pointer {
      Some(v) => v
      None => @math.Vec2::new(0.0F, 0.0F)
    }
    match picking_state.val.pressed {
      Some(pressed_entity) => {
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(
            pointer_id,
            @picking.PointerEventKind::Up,
            pos,
            target=Some(pressed_entity),
          ),
        )
        if hit_top is Some(hit_entity) && entity_eq(hit_entity, pressed_entity) {
          @picking.PickingEvents::push(
            events,
            @picking.PointerEvent::new(
              pointer_id,
              @picking.PointerEventKind::Click,
              pos,
              target=Some(pressed_entity),
            ),
          )
        }
      }
      None => ()
    }
    @picking.PickingState::set_pressed(picking_state, None)
  }
}

///|
pub fn[
  W : HasRes_UiContext + @picking.HasRes_PickingEvents + @picking.HasRes_PickingState + @a11y.HasRes_A11yState + Has_UiRoot + Has_Node + Has_ContentSize + Has_ZIndex + Has_GlobalZIndex + HasRes_UiStack + Has_ScrollPosition + Has_UiLayout + Has_CalculatedClip + Has_RelativeCursorPosition + Has_FocusPolicy + Has_BackgroundColor + Has_UiImage + Has_ButtonColors + Has_Button + Has_Interaction + Has_UiText + Has_AccessibilityLabel + @hierarchy.Has_Children + @hierarchy.Has_Parent + @render2d.Has_Camera2d + @render2d.Has_Camera + @render2d.Has_Projection + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @render2d.Has_Sprite + @render2d.Has_ScissorRect + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] ui_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_pre_update_system_config(
    @app.system(ui_update_context_system).in_set(ui_set_context),
  )
  .add_pre_update_system_config(
    @app.system(ui_scroll_system).in_set(ui_set_scroll),
  )
  .add_pre_update_system_config(
    @app.system(ui_layout_system).in_set(ui_set_layout),
  )
  .add_pre_update_system_config(@app.system(ui_clip_system).in_set(ui_set_clip))
  .add_pre_update_system_config(
    @app.system(ui_stack_system).in_set(ui_set_stack),
  )
  .add_pre_update_system_config(
    @app.system(ui_a11y_update_system).in_set(ui_set_a11y),
  )
  .add_pre_update_system_config(
    @app.system(ui_interaction_system).in_set(ui_set_interaction),
  )
  .add_pre_update_system_config(
    @app.system(ui_a11y_apply_actions_system).in_set(ui_set_a11y_apply),
  )
  .configure_set(@app.PreUpdate, ui_set_context, after=[@picking.picking_set], before=[
    ui_set_scroll,
  ])
  .configure_set(@app.PreUpdate, ui_set_scroll, after=[ui_set_context], before=[
    ui_set_layout,
  ])
  .configure_set(
    @app.PreUpdate,
    ui_set_layout,
    after=[@transform.transform_set_update_children],
    before=[@transform.transform_set_propagate],
  )
  .configure_set(@app.PreUpdate, ui_set_clip, after=[ui_set_layout], before=[
    ui_set_stack,
  ])
  .configure_set(@app.PreUpdate, ui_set_stack, after=[ui_set_clip], before=[
    ui_set_a11y,
  ])
  .configure_set(@app.PreUpdate, ui_set_a11y, after=[ui_set_stack], before=[
    ui_set_interaction,
  ])
  .configure_set(@app.PreUpdate, ui_set_interaction, after=[ui_set_a11y])
  .configure_set(@app.PreUpdate, ui_set_a11y_apply, after=[ui_set_interaction])
}
