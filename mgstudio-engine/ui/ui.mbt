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

///| Bevy-aligned display (matches Taffy).
pub(all) enum Display {
  Block
  Flex
  Grid
  None
} derive(Eq, Show)

///| Bevy-aligned position type (subset).
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

///| Bevy-aligned flex direction.
pub(all) enum FlexDirection {
  Column
  ColumnReverse
  Row
  RowReverse
} derive(Eq, Show)

///| Bevy-aligned flex wrap.
pub(all) enum FlexWrap {
  NoWrap
  Wrap
  WrapReverse
} derive(Eq, Show)

///| Bevy-aligned justify content.
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

///| Bevy-aligned justify items.
pub(all) enum JustifyItems {
  Baseline
  Center
  Default
  End
  Start
  Stretch
} derive(Eq, Show)

///| Bevy-aligned justify self.
pub(all) enum JustifySelf {
  Auto
  Baseline
  Center
  End
  Start
  Stretch
} derive(Eq, Show)

///| Bevy-aligned align items.
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

///| Bevy-aligned align self.
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

///| Bevy-aligned align content.
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
  if start == 0 { GridPlacement::default() } else {
    GridPlacement::{ ..GridPlacement::default(), start: Some(start) }
  }
}

///|
pub fn GridPlacement::end(end : Int) -> GridPlacement {
  if end == 0 { GridPlacement::default() } else {
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
  ZIndex::{ value }
}

///|
#ecs.component
pub struct GlobalZIndex {
  value : Int
}

///|
pub fn GlobalZIndex::new(value : Int) -> GlobalZIndex {
  GlobalZIndex::{ value }
}

///|
#ecs.resource
pub struct UiScale {
  value : Float
}

///|
pub fn UiScale::new(value : Float) -> UiScale {
  UiScale::{ value }
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
  BorderColor::{ color }
}

///| The style of a UI node (Bevy v0.15.3-aligned surface).
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
pub fn Node::with_position_type(self : Node, position_type : PositionType) -> Node {
  Node::{ ..self, position_type }
}

///|
pub fn Node::with_left(self : Node, left : Val) -> Node {
  Node::{ ..self, left }
}

///|
pub fn Node::with_top(self : Node, top : Val) -> Node {
  Node::{ ..self, top }
}

///|
pub fn Node::with_width(self : Node, width : Val) -> Node {
  Node::{ ..self, width }
}

///|
pub fn Node::with_height(self : Node, height : Val) -> Node {
  Node::{ ..self, height }
}

///|
pub fn Node::with_justify_content(
  self : Node,
  justify_content : JustifyContent,
) -> Node {
  Node::{ ..self, justify_content }
}

///|
pub fn Node::with_align_items(self : Node, align_items : AlignItems) -> Node {
  Node::{ ..self, align_items }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiRoot {}

///|
pub fn UiRoot::default() -> UiRoot {
  UiRoot::{  }
}

///| Computed layout rectangle in logical pixels, top-left origin (viewport space).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiLayout {
  rect : @math.Rect
}

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  UiLayout::{ rect }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct BackgroundColor {
  color : @render2d.Color
}

///|
pub fn BackgroundColor::new(color : @render2d.Color) -> BackgroundColor {
  BackgroundColor::{ color }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiImage {
  image : @asset.Handle[@asset.Image]
}

///|
pub fn UiImage::new(image : @asset.Handle[@asset.Image]) -> UiImage {
  UiImage::{ image }
}

///|
///| Bevy-aligned interaction state component.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum Interaction {
  None
  Hovered
  Pressed
} derive(Eq, Show)

///| Bevy-aligned button marker component.
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
  UiText::{ handle }
}

///|
/// Optional accessibility label for UI nodes (used by the host a11y bridge).
#ecs.component
pub struct AccessibilityLabel {
  text : String
}

///|
pub fn AccessibilityLabel::new(text : String) -> AccessibilityLabel {
  AccessibilityLabel::{ text }
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

///| Public constructor (required because `UiContext` contains `mut` fields).
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
  if scale <= 0.0F { 1.0F } else { scale }
}

///|
fn safe_camera_scale(scale : Float) -> Float {
  if scale <= 0.0F { 1.0F } else { scale }
}

///| Resolve a UI `Val` against a parent size in pixels.
fn resolve_val(val : Val, parent_px : Float, viewport_size : @math.Vec2) -> Float {
  match val {
    Auto => 0.0F
    Px(v) => v
    Percent(p) => parent_px * (p / 100.0F)
    Vw(p) => viewport_size.x * (p / 100.0F)
    Vh(p) => viewport_size.y * (p / 100.0F)
    VMin(p) => {
      let m = if viewport_size.x < viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
    VMax(p) => {
      let m = if viewport_size.x > viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
  }
}

///|
fn resolve_val_with_auto(
  val : Val,
  parent_px : Float,
  viewport_size : @math.Vec2,
  auto_px : Float,
) -> Float {
  match val {
    Auto => auto_px
    Px(v) => v
    Percent(p) => parent_px * (p / 100.0F)
    Vw(p) => viewport_size.x * (p / 100.0F)
    Vh(p) => viewport_size.y * (p / 100.0F)
    VMin(p) => {
      let m = if viewport_size.x < viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
    VMax(p) => {
      let m = if viewport_size.x > viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
  }
}

///|
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///| Convert a window-space pointer into viewport-space coordinates.
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

  if x < 0 { x = 0 }
  if y < 0 { y = 0 }
  if w < 0 { w = 0 }
  if h < 0 { h = 0 }

  let max_w = if win_w - x < 0 { 0 } else { win_w - x }
  let max_h = if win_h - y < 0 { 0 } else { win_h - y }
  if w > max_w { w = max_w }
  if h > max_h { h = max_h }

  @render2d.Viewport::new(@math.IVec2::new(x, y), @math.IVec2::new(w, h))
}

///|
pub fn[
  W :
    HasRes_UiContext +
    @render2d.Has_Camera2d +
    @render2d.Has_Camera +
    @render2d.Has_Projection +
    @render2d.Has_RenderTarget +
    @math.Has_Transform +
    @transform.Has_GlobalTransform +
    @core.ChangeTickWorld,
] ui_update_context_system(world : W) -> Unit {
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
      Some(_) => {
        if camera.order < best_order {
          best_entity = Some(entity)
          best_order = camera.order
        }
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
    Some(mouse) => ui_pointer_pos_in_viewport(mouse, viewport_origin, viewport_size)
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
  W :
    @core.ChangeTickWorld +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility,
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
    inherited_store.insert(entity, @visibility.InheritedVisibility::new(true), tick)
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
fn node_size(
  parent : @math.Rect,
  node : Node,
  viewport_size : @math.Vec2,
  auto_size : @math.Vec2,
) -> @math.Vec2 {
  let parent_size = parent.size()
  let w = resolve_val_with_auto(node.width, parent_size.x, viewport_size, auto_size.x)
  let h = resolve_val_with_auto(node.height, parent_size.y, viewport_size, auto_size.y)
  @math.Vec2::new(w, h)
}

///|
fn node_rect_absolute(
  parent : @math.Rect,
  node : Node,
  viewport_size : @math.Vec2,
  auto_size : @math.Vec2,
) -> @math.Rect {
  let parent_size = parent.size()
  let size = node_size(parent, node, viewport_size, auto_size)
  let x = resolve_val(node.left, parent_size.x, viewport_size)
  let y = resolve_val(node.top, parent_size.y, viewport_size)
  let min = @math.Vec2::new(parent.min.x + x, parent.min.y + y)
  let max = @math.Vec2::new(min.x + size.x, min.y + size.y)
  @math.Rect::new(min, max)
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
    z=z,
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
  W :
    HasRes_UiContext +
    Has_UiRoot +
    Has_Node +
    Has_ZIndex +
    Has_ScrollPosition +
    Has_UiLayout +
    Has_BackgroundColor +
    Has_UiImage +
    Has_ButtonColors +
    Has_Interaction +
    Has_UiText +
    @hierarchy.Has_Children +
    @render2d.Has_Sprite +
    @render2d.Has_RenderLayers +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility +
    @math.Has_Transform +
    @core.ChangeTickWorld,
] ui_layout_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }

  let root_store = Has_UiRoot::get_ui_root_store(world)
  let node_store = Has_Node::get_node_store(world)
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
    match ui_text_store.get(entity) {
      Some(text_node) =>
        match @text.text_get_layout_size(text_node.handle) {
          Some(sz) => sz
          None => @math.Vec2::new(0.0F, 0.0F)
        }
      None => @math.Vec2::new(0.0F, 0.0F)
    }
  }

  fn layout_subtree(
    entity : @core.Entity,
    parent_rect : @math.Rect,
    assigned_rect : @math.Rect?,
  ) -> Unit {
    let node_opt = node_store.get(entity)
    let self_rect = match (assigned_rect, node_opt) {
      (Some(r), _) => r
      (None, Some(node)) =>
        match node.position_type {
          PositionType::Absolute =>
            node_rect_absolute(
              parent_rect,
              node,
              ctx0.viewport_size,
              auto_size_for_entity(entity),
            )
          PositionType::Relative => parent_rect
        }
      (None, None) => parent_rect
    }
    // Container style defaults (mirrors Bevy defaults loosely; only the subset we implement matters).
    let self_node = match node_opt {
      Some(s) => s
      None => Node::default()
    }
    let scroll = match scroll_store.get(entity) {
      Some(v) => v
      None => ScrollPosition::default()
    }
    let rect_for_children = @math.Rect::new(
      @math.Vec2::new(
        self_rect.min.x - scroll.offset_x,
        self_rect.min.y - scroll.offset_y,
      ),
      @math.Vec2::new(
        self_rect.max.x - scroll.offset_x,
        self_rect.max.y - scroll.offset_y,
      ),
    )

    // Update UiLayout when this node has an explicit Node.
    if node_opt is Some(_) {
      let layout = UiLayout::new(self_rect)
      if layout_store.contains(entity) {
        layout_store.set(entity, layout, tick) |> ignore
      } else {
        layout_store.insert(entity, layout, tick)
      }
    }

    // Update render2d / transform for UI nodes.
    if node_opt is Some(_node) {
      let z_index = match z_store.get(entity) {
        Some(v) => v.value
        None => 0
      }
      let transform = ui_world_transform(ctx0, self_rect, z_index)
      if transform_store.contains(entity) {
        transform_store.set(entity, transform, tick) |> ignore
      } else {
        transform_store.insert(entity, transform, tick)
      }
      let layers = ensure_layers_default(world, entity)
      ensure_visibility_defaults(world, entity)

      if should_draw_node(sprite_store, bg_store, img_store, button_store, entity) {
        let texture = match img_store.get(entity) {
          Some(v) => v.image
          None => ctx0.white_texture
        }
        let size = self_rect.size()
        let button_colors_opt = button_store.get(entity)
        let color = match button_colors_opt {
          Some(colors) => button_color_for_state(colors, interaction_store.get(entity))
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
        let text_node_size = self_rect.size()
        // Bevy UI parity: glyph positions are laid out in top-left origin (+Y down).
        // The text renderer uses `ui_node_size` to translate from node center to node top-left.
        @text.text_set_y_axis(text_node.handle, @text.YAxisOrientation::TopToBottom)
        @text.text_set_ui_node_size(text_node.handle, Some(text_node_size))
        @text.text_set_transform(text_node.handle, transform)
        @text.text_set_layers(text_node.handle, layers)
      }
    }

    // Traverse children.
    if children_store.get(entity) is Some(children) {
      // First pass: layout absolute-positioned children immediately; collect relative children
      // for a minimal row-layout (Bevy-like defaults).
      let relative_entities : Array[@core.Entity] = []
      let relative_sizes : Array[@math.Vec2] = []
      for child in children.entities {
        match node_store.get(child) {
          None => layout_subtree(child, rect_for_children, None)
          Some(child_node) =>
            match child_node.position_type {
              PositionType::Absolute => {
                let child_rect = node_rect_absolute(
                  rect_for_children,
                  child_node,
                  ctx0.viewport_size,
                  auto_size_for_entity(child),
                )
                layout_subtree(child, rect_for_children, Some(child_rect))
              }
              PositionType::Relative => {
                let child_size = node_size(
                  self_rect,
                  child_node,
                  ctx0.viewport_size,
                  auto_size_for_entity(child),
                )
                relative_entities.push(child)
                relative_sizes.push(child_size)
              }
            }
        }
      }

      if relative_entities.length() > 0 {
        let parent_size = self_rect.size()
        let mut total_w = 0.0F
        for i in 0..<relative_entities.length() {
          total_w = total_w + relative_sizes[i].x
        }
        let mut start_x = 0.0F
        match self_node.justify_content {
          JustifyContent::FlexStart => start_x = 0.0F
          JustifyContent::Center => {
            let dx = (parent_size.x - total_w) / 2.0F
            start_x = if dx < 0.0F { 0.0F } else { dx }
          }
          _ => start_x = 0.0F
        }
        let mut cursor_x = start_x
        for i in 0..<relative_entities.length() {
          let child = relative_entities[i]
          let child_size = relative_sizes[i]
          let mut y = 0.0F
          match self_node.align_items {
            AlignItems::FlexStart => y = 0.0F
            AlignItems::Center => {
              let dy = (parent_size.y - child_size.y) / 2.0F
              y = if dy < 0.0F { 0.0F } else { dy }
            }
            _ => y = 0.0F
          }
          let min = @math.Vec2::new(
            rect_for_children.min.x + cursor_x,
            rect_for_children.min.y + y,
          )
          let max = @math.Vec2::new(min.x + child_size.x, min.y + child_size.y)
          let child_rect = @math.Rect::new(min, max)
          layout_subtree(child, rect_for_children, Some(child_rect))
          cursor_x = cursor_x + child_size.x
        }
      }
    }
  }

  let mut any_root = false
  root_store.for_each(fn(root, _marker) {
    any_root = true
    layout_subtree(root, root_rect, None)
  })
  any_root |> ignore
}

///| Update `ScrollPosition` using the current mouse wheel delta.
///
/// This is an MVP scroll implementation:
/// - Picks the topmost scroll container under the pointer by `ZIndex`.
/// - Applies wheel deltas directly to the stored offsets (clamped to >= 0).
pub fn[
  W :
    HasRes_UiContext +
    Has_Node +
    Has_ZIndex +
    Has_UiLayout +
    Has_ScrollPosition +
    @core.ChangeTickWorld,
] ui_scroll_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.pointer_pos is Some(pointer) else { return }
  let delta = ctx0.wheel_delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  let node_store = Has_Node::get_node_store(world)
  let z_store = Has_ZIndex::get_z_index_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let scroll_store = Has_ScrollPosition::get_scroll_position_store(world)

  let mut best_entity : @core.Entity? = None
  let mut best_z = 0

  scroll_store.for_each(fn(entity, _scroll) {
    guard layout_store.get(entity) is Some(layout) else { return }
    guard node_store.get(entity) is Some(node) else { return }
    if !(layout.rect.contains(pointer)) {
      return
    }
    let can_scroll = node.overflow.x == OverflowAxis::Scroll ||
      node.overflow.y == OverflowAxis::Scroll
    if !can_scroll {
      return
    }
    let z = match z_store.get(entity) {
      Some(v) => v.value
      None => 0
    }
    match best_entity {
      None => {
        best_entity = Some(entity)
        best_z = z
      }
      Some(_) => {
        if z >= best_z {
          best_entity = Some(entity)
          best_z = z
        }
      }
    }
  })

  guard best_entity is Some(target) else { return }
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let prev = match scroll_store.get(target) {
    Some(v) => v
    None => ScrollPosition::default()
  }
  let mut next_x = prev.offset_x + delta.x
  let mut next_y = prev.offset_y + delta.y
  if next_x < 0.0F { next_x = 0.0F }
  if next_y < 0.0F { next_y = 0.0F }
  let next = ScrollPosition::{ offset_x: next_x, offset_y: next_y }
  if scroll_store.contains(target) {
    scroll_store.set(target, next, tick) |> ignore
  } else {
    scroll_store.insert(target, next, tick)
  }
}

///| Compute `CalculatedClip` and attach `@render2d.ScissorRect` for clipped UI.
pub fn[
  W :
    HasRes_UiContext +
    Has_UiRoot +
    Has_Node +
    Has_UiLayout +
    Has_CalculatedClip +
    @render2d.Has_ScissorRect +
    @hierarchy.Has_Children +
    @core.ChangeTickWorld,
] ui_clip_system(world : W) -> Unit {
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
      if max_x < min_x { min_x } else { max_x },
      if max_y < min_y { min_y } else { max_y },
    )
    @math.Rect::new(min, max)
  }

  fn rect_is_full_viewport(r : @math.Rect) -> Bool {
    r.min.x <= 0.0F &&
    r.min.y <= 0.0F &&
    r.max.x >= viewport_rect.max.x &&
    r.max.y >= viewport_rect.max.y
  }

  fn walk(entity : @core.Entity, inherited_clip : @math.Rect, clipped_by_parent : Bool) -> Unit {
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
    } else {
      if scissor_store.contains(entity) {
        scissor_store.remove(entity) |> ignore
      }
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

  root_store.for_each(fn(root, _marker) {
    walk(root, viewport_rect, false)
  })
}

///| Extract UI accessibility nodes and send them to the host bridge.
pub fn[
  W :
    HasRes_UiContext +
    Has_UiLayout +
    Has_Button +
    Has_AccessibilityLabel +
    @hierarchy.Has_Parent +
    @core.ChangeTickWorld,
] ui_a11y_update_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }

  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let label_store = Has_AccessibilityLabel::get_accessibility_label_store(world)
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)

  let root_id = 1
  @a11y.a11y_host_begin_update(root_id)

  let entities : Array[@core.Entity] = []
  button_store.for_each(fn(entity, _btn) { entities.push(entity) })
  label_store.for_each(fn(entity, _label) {
    // Avoid duplicates.
    let mut exists = false
    for e in entities {
      if e.id == entity.id && e.generation == entity.generation {
        exists = true
        break
      }
    }
    if !exists {
      entities.push(entity)
    }
  })

  for entity in entities {
    guard layout_store.get(entity) is Some(layout) else { continue }
    let rect = layout.rect
    let x = ctx0.viewport_origin.x + rect.min.x
    let y = ctx0.viewport_origin.y + rect.min.y
    let size = rect.size()
    let width = size.x
    let height = size.y

    let node_id = @a11y.node_id_for_entity(entity)
    let parent_id = match parent_store.get(entity) {
      Some(p) => @a11y.node_id_for_entity(p.entity)
      None => root_id
    }
    let role_id = if button_store.contains(entity) {
      @a11y.host_role_button
    } else {
      @a11y.host_role_label
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
        node_id,
        parent_id,
        role_id,
        x,
        y,
        width,
        height,
        name_id,
        actions_mask,
      )
    })
  }

  @a11y.a11y_host_end_update()
}

///| Apply host-driven accessibility actions to UI state and picking events.
pub fn[
  W :
    @a11y.HasRes_A11yState +
    @picking.HasRes_PickingEvents +
    Has_Interaction +
    @core.ChangeTickWorld,
] ui_a11y_apply_actions_system(world : W) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  guard @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(tick) is Some(state) else {
    return
  }
  let actions = @a11y.A11yState::drain_actions(state)
  if actions.length() == 0 {
    return
  }
  guard @picking.HasRes_PickingEvents::get_picking_events_resource(world).get_ref_mut(tick) is Some(events) else {
    return
  }
  let interaction_store = Has_Interaction::get_interaction_store(world)

  fn entity_from_node_id(node_id : Int) -> @core.Entity {
    let id = node_id / 65536
    let gen = node_id - (id * 65536)
    @core.Entity::new(id, gen)
  }

  for req in actions {
    let entity = entity_from_node_id(req.target)
    match req.action {
      @accesskit.Action::Focus => {
        // MVP: focus is handled by the host (tab/VO). Engine-side focus routing is TODO.
        entity |> ignore
      }
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
  W :
    HasRes_UiContext +
    @picking.HasRes_PickingEvents +
    @picking.HasRes_PickingState +
    Has_ZIndex +
    Has_UiLayout +
    Has_Button +
    Has_Interaction +
    Has_RelativeCursorPosition +
    Has_FocusPolicy +
    Has_CalculatedClip +
    Has_ButtonColors +
    @render2d.Has_Sprite +
    @visibility.Has_ViewVisibility +
    @core.ChangeTickWorld,
] ui_interaction_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }

  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let state_store = Has_Interaction::get_interaction_store(world)
  let cursor_store = Has_RelativeCursorPosition::get_relative_cursor_position_store(
    world,
  )
  let focus_store = Has_FocusPolicy::get_focus_policy_store(world)
  let clip_store = Has_CalculatedClip::get_calculated_clip_store(world)
  let z_store = Has_ZIndex::get_z_index_store(world)
  let colors_store = Has_ButtonColors::get_button_colors_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(world)
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
      if max_x < min_x { min_x } else { max_x },
      if max_y < min_y { min_y } else { max_y },
    )
    @math.Rect::new(min, max)
  }

  // Build the moused-over list (potentially multiple, ordered later).
  let hovered : Array[@core.Entity] = []
  if pointer is Some(p) {
    for entity in candidates {
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

      hovered.push(entity)
    }
  }

  // Sort by z desc, then stable entity key.
  hovered.sort_by(fn(a, b) {
    let za = match z_store.get(a) {
      Some(v) => v.value
      None => 0
    }
    let zb = match z_store.get(b) {
      Some(v) => v.value
      None => 0
    }
    if za != zb {
      // Descending by z.
      if za > zb { -1 } else { 1 }
    } else if a.id != b.id {
      if a.id > b.id { -1 } else { 1 }
    } else if a.generation != b.generation {
      if a.generation > b.generation { -1 } else { 1 }
    } else {
      0
    }
  })

  // Apply interactions: top nodes until a `Block` focus policy is hit.
  let active : Array[@core.Entity] = []
  let mut captured = false
  for entity in hovered {
    if captured {
      break
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
  let state_res = @picking.HasRes_PickingState::get_picking_state_resource(world)
  guard events_res.get_ref_mut(tick) is Some(events) else { return }
  guard state_res.get_ref_mut(tick) is Some(picking_state) else { return }

  let pointer_id : @picking.PointerId = 0
  let hit_top : @core.Entity? = if active.length() > 0 { Some(active[0]) } else { None }

  // Move.
  if pointer is Some(pos) {
    match picking_state.val.last_position {
      Some(prev) => {
        if prev.x != pos.x || prev.y != pos.y {
          @picking.PickingEvents::push(
            events,
            @picking.PointerEvent::new(pointer_id, @picking.PointerEventKind::Move, pos),
          )
        }
      }
      None => {
        @picking.PickingEvents::push(
          events,
          @picking.PointerEvent::new(pointer_id, @picking.PointerEventKind::Move, pos),
        )
      }
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
  W :
    HasRes_UiContext +
    @picking.HasRes_PickingEvents +
    @picking.HasRes_PickingState +
    @a11y.HasRes_A11yState +
    Has_UiRoot +
    Has_Node +
    Has_ZIndex +
    Has_ScrollPosition +
    Has_UiLayout +
    Has_CalculatedClip +
    Has_RelativeCursorPosition +
    Has_FocusPolicy +
    Has_BackgroundColor +
    Has_UiImage +
    Has_ButtonColors +
    Has_Button +
    Has_Interaction +
    Has_UiText +
    Has_AccessibilityLabel +
    @hierarchy.Has_Children +
    @hierarchy.Has_Parent +
    @render2d.Has_Camera2d +
    @render2d.Has_Camera +
    @render2d.Has_Projection +
    @render2d.Has_RenderTarget +
    @render2d.Has_RenderLayers +
    @render2d.Has_Sprite +
    @render2d.Has_ScissorRect +
    @math.Has_Transform +
    @transform.Has_GlobalTransform +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility +
    @core.ChangeTickWorld,
] ui_plugin(app : @app.App[W]) -> @app.App[W] {
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
    @app.system(ui_a11y_update_system).in_set(ui_set_a11y),
  )
  .add_pre_update_system_config(
    @app.system(ui_interaction_system).in_set(ui_set_interaction),
  )
  .add_pre_update_system_config(
    @app.system(ui_a11y_apply_actions_system).in_set(ui_set_a11y_apply),
  )
  .configure_set(@app.PreUpdate, ui_set_context, after=[@picking.picking_set], before=[ui_set_scroll])
  .configure_set(@app.PreUpdate, ui_set_scroll, after=[ui_set_context], before=[ui_set_layout])
  .configure_set(
    @app.PreUpdate,
    ui_set_layout,
    after=[@transform.transform_set_update_children],
    before=[@transform.transform_set_propagate],
  )
  .configure_set(@app.PreUpdate, ui_set_clip, after=[ui_set_layout], before=[ui_set_a11y])
  .configure_set(@app.PreUpdate, ui_set_a11y, after=[ui_set_clip], before=[ui_set_interaction])
  .configure_set(@app.PreUpdate, ui_set_interaction, after=[ui_set_a11y])
  .configure_set(@app.PreUpdate, ui_set_a11y_apply, after=[ui_set_interaction])
}
