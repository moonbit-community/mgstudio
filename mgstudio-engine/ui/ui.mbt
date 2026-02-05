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
} derive(Eq, Show)

///|
pub struct OverflowClipMargin {
  visual_box : OverflowClipBox
  margin : Float
}

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
/// Controls whether UI should render with antialiasing.
///
/// This is Bevy-aligned (`UiAntiAlias`) and is currently consumed by the UI
/// render pipeline (tracked separately).
#ecs.component
pub(all) enum UiAntiAlias {
  Off
  On
} derive(Eq, Show)

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
pub fn BorderRadius::all(radius : Val) -> BorderRadius {
  BorderRadius::{
    top_left: radius,
    top_right: radius,
    bottom_left: radius,
    bottom_right: radius,
  }
}

///|
pub fn BorderRadius::new(
  top_left : Val,
  top_right : Val,
  bottom_right : Val,
  bottom_left : Val,
) -> BorderRadius {
  BorderRadius::{ top_left, top_right, bottom_left, bottom_right }
}

///|
pub fn BorderRadius::px(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Px(top_left),
    Val::Px(top_right),
    Val::Px(bottom_right),
    Val::Px(bottom_left),
  )
}

///|
pub fn BorderRadius::percent(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Percent(top_left),
    Val::Percent(top_right),
    Val::Percent(bottom_right),
    Val::Percent(bottom_left),
  )
}

///|
#ecs.component
pub struct Outline {
  width : Val
  offset : Val
  color : @render2d.Color
}

///|
pub fn Outline::new(
  width : Val,
  offset : Val,
  color : @render2d.Color,
) -> Outline {
  Outline::{ width, offset, color }
}

///|
pub fn Outline::default() -> Outline {
  Outline::{
    width: Val::Px(0.0F),
    offset: Val::Px(0.0F),
    color: @render2d.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
  }
}

///|
#ecs.component
pub struct BoxShadow {
  color : @render2d.Color
  x_offset : Val
  y_offset : Val
  spread_radius : Val
  blur_radius : Val
}

///|
pub fn BoxShadow::new(
  color : @render2d.Color,
  x_offset : Val,
  y_offset : Val,
  spread_radius : Val,
  blur_radius : Val,
) -> BoxShadow {
  BoxShadow::{ color, x_offset, y_offset, spread_radius, blur_radius }
}

///|
pub fn BoxShadow::default() -> BoxShadow {
  // Match Bevy defaults (v0.15.3).
  BoxShadow::{
    color: @render2d.Color::black(),
    x_offset: Val::Percent(20.0F),
    y_offset: Val::Percent(20.0F),
    spread_radius: Val::Px(0.0F),
    blur_radius: Val::Percent(10.0F),
  }
}

///|
#ecs.component
pub struct UiBoxShadowSamples {
  samples : Int
}

///|
pub fn UiBoxShadowSamples::new(samples : Int) -> UiBoxShadowSamples {
  let safe = if samples < 0 { 0 } else { samples }
  UiBoxShadowSamples::{ samples: safe }
}

///|
pub fn UiBoxShadowSamples::default() -> UiBoxShadowSamples {
  UiBoxShadowSamples::new(4)
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
pub fn Node::with_border(self : Node, border : UiRect) -> Node {
  Node::{ ..self, border, }
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
/// Bevy-aligned image size component (Bevy v0.15.3 `ImageNodeSize`).
///
/// Stores the size of the selected image region in pixels (rect/atlas/texture).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ImageNodeSize {
  size : @math.UVec2
}

///|
pub fn ImageNodeSize::default() -> ImageNodeSize {
  ImageNodeSize::{ size: @math.UVec2::zero() }
}

///|
pub fn ImageNodeSize::size(self : ImageNodeSize) -> @math.UVec2 {
  self.size
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
  color : @render2d.Color
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.Rect?
}

///|
pub fn UiImage::new(image : @asset.Handle[@asset.Image]) -> UiImage {
  UiImage::{
    color: @render2d.Color::white(),
    image,
    texture_atlas: None,
    flip_x: false,
    flip_y: false,
    rect: None,
  }
}

///|
pub fn UiImage::with_color(self : UiImage, color : @render2d.Color) -> UiImage {
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
}

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
} derive(Eq, Show)

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
}

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
pub(all) enum NodeImageMode {
  /// Size is determined by the source image, then clamped by layout constraints.
  Auto
  /// The image is resized to match the node's layout size (ignores aspect ratio).
  Stretch
  /// 9-sliced scaling using a `TextureSlicer`.
  Sliced(TextureSlicer)
  /// Tiled scaling for the full texture region.
  Tiled(Bool, Bool, Float)
}

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
fn clamp_stretch_value(v : Float) -> Float {
  if v < 0.001F {
    0.001F
  } else {
    v
  }
}

///|
fn min3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
fn compute_tiled_axis(
  tile : Bool,
  image_extent : Float,
  target_extent : Float,
  stretch_value : Float,
) -> Float {
  if tile {
    let denom = image_extent * clamp_stretch_value(stretch_value)
    if denom == 0.0F {
      1.0F
    } else {
      target_extent / denom
    }
  } else {
    1.0F
  }
}

///|
fn compute_tiled_subaxis(
  image_extent : Float,
  target_extent : Float,
  mode : SliceScaleMode,
) -> Float {
  match mode {
    SliceScaleMode::Stretch => 1.0F
    SliceScaleMode::Tile(stretch_value) => {
      let denom = image_extent * clamp_stretch_value(stretch_value)
      if denom == 0.0F {
        1.0F
      } else {
        target_extent / denom
      }
    }
  }
}

///|
fn compute_texture_slices(
  image_size : @math.Vec2,
  target_size : @math.Vec2,
  mode : NodeImageMode,
) -> (@math.Vec4, @math.Vec4, @math.Vec4) {
  match mode {
    NodeImageMode::Sliced(slicer) => {
      let denom_x = if image_size.x == 0.0F { 1.0F } else { image_size.x }
      let denom_y = if image_size.y == 0.0F { 1.0F } else { image_size.y }
      let tdenom_x = if target_size.x == 0.0F { 1.0F } else { target_size.x }
      let tdenom_y = if target_size.y == 0.0F { 1.0F } else { target_size.y }
      let min_coeff = min3(
        target_size.x / denom_x,
        target_size.y / denom_y,
        slicer.max_corner_scale,
      )
      let slices = @math.Vec4::new(
        slicer.border.left / denom_x,
        slicer.border.top / denom_y,
        1.0F - slicer.border.right / denom_x,
        1.0F - slicer.border.bottom / denom_y,
      )
      let border = @math.Vec4::new(
        slicer.border.left / tdenom_x * min_coeff,
        slicer.border.top / tdenom_y * min_coeff,
        1.0F - slicer.border.right / tdenom_x * min_coeff,
        1.0F - slicer.border.bottom / tdenom_y * min_coeff,
      )
      let image_side_width = denom_x * (slices.z - slices.x)
      let image_side_height = denom_y * (slices.w - slices.y)
      let target_side_width = tdenom_x * (border.z - border.x)
      let target_side_height = tdenom_y * (border.w - border.y)
      let repeat_side_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.sides_scale_mode,
      )
      let repeat_side_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.sides_scale_mode,
      )
      let repeat_center_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.center_scale_mode,
      )
      let repeat_center_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.center_scale_mode,
      )
      (
        slices,
        border,
        @math.Vec4::new(
          repeat_side_x, repeat_side_y, repeat_center_x, repeat_center_y,
        ),
      )
    }
    NodeImageMode::Tiled(tile_x, tile_y, stretch_value) => {
      let rx = compute_tiled_axis(
        tile_x,
        image_size.x,
        target_size.x,
        stretch_value,
      )
      let ry = compute_tiled_axis(
        tile_y,
        image_size.y,
        target_size.y,
        stretch_value,
      )
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, rx, ry),
      )
    }
    _ =>
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
  }
}

///|
/// A UI node that renders an image (Bevy v0.15.3 `ImageNode`).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ImageNode {
  color : @render2d.Color
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.Rect?
  image_mode : NodeImageMode
}

///|
pub fn ImageNode::default() -> ImageNode {
  ImageNode::{
    color: @render2d.Color::white(),
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
pub fn ImageNode::with_color(
  self : ImageNode,
  color : @render2d.Color,
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
/// Bevy-aligned label marker component (Bevy v0.15.3 `Label` widget marker).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Label {}

///|
pub fn Label::default() -> Label {
  Label::{  }
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
pub let ui_set_measure : @app.SystemSet = @app.system_set("mgstudio.ui.measure")

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
pub let ui_set_render_extract : @app.SystemSet = @app.system_set(
  "mgstudio.ui.render_extract",
)

///|
const UI_DRAW_FLAG_TEXTURED : Int = 1

///|
const UI_DRAW_FLAG_BORDER : Int = 2

///|
const UI_DRAW_FLAG_ANTIALIAS : Int = 4

///|
const UI_STACK_Z_BASE : Float = 10000.0F

///|
const UI_STACK_Z_STEP : Float = 10.0F

///|
const UI_STACK_Z_BACKGROUND : Float = 0.0F

///|
const UI_STACK_Z_SHADOW : Float = -1.0F

///|
const UI_STACK_Z_CONTENT : Float = 1.0F

///|
const UI_STACK_Z_BORDER : Float = 2.0F

///|
const UI_STACK_Z_TEXT : Float = 3.0F

///|
const UI_STACK_Z_OUTLINE : Float = 4.0F

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
fn[W : HasRes_UiScale + @core.ChangeTickWorld] ensure_ui_scale_resource(
  world : W,
) -> Ref[UiScale]? {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_UiScale::get_ui_scale_resource(world)
  if !res.is_present() {
    res.insert(UiScale::new(1.0F), tick)
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
  z : Float,
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
/// Update `ContentSize` for image nodes when `NodeImageMode::Auto`.
///
/// This mirrors Bevy's `update_image_content_size_system`, adapted to mgstudio's
/// logical UI coordinate space.
pub fn[
  W : HasRes_UiContext + HasRes_UiScale + Has_Node + Has_ContentSize + Has_ImageNodeSize + Has_UiText + Has_UiImage + Has_ImageNode + @core.ChangeTickWorld,
] ui_image_content_size_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(_) else { return }
  guard ensure_ui_scale_resource(world) is Some(ui_scale) else { return }
  let node_store = Has_Node::get_node_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)
  let ui_image_store = Has_UiImage::get_ui_image_store(world)
  let image_node_store = Has_ImageNode::get_image_node_store(world)
  let image_size_store = Has_ImageNodeSize::get_image_node_size_store(world)
  let content_size_store = Has_ContentSize::get_content_size_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let sf = safe_scale_factor(@window.window_scale_factor())
  let ui_scale_value = if ui_scale.val.value <= 0.0F {
    1.0F
  } else {
    ui_scale.val.value
  }
  let inv_px_scale = ui_scale_value / sf
  let transparent_id = @asset.asset_transparent_texture().id()
  fn rect_size(rect : @math.Rect) -> @math.Vec2 {
    rect.size()
  }

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
    let next = ContentSize::new(
      @math.Vec2::new(size_px.x * inv_px_scale, size_px.y * inv_px_scale),
    )
    match content_size_store.get(entity) {
      Some(prev) =>
        if prev.size.x == next.size.x && prev.size.y == next.size.y {
          ()
        } else {
          content_size_store.set(entity, next, tick) |> ignore
        }
      None => content_size_store.insert(entity, next, tick)
    }
  }

  fn update_image_node_size(
    entity : @core.Entity,
    size_px : @math.Vec2,
  ) -> Unit {
    let next = ImageNodeSize::{ size: uvec2_from_size_px(size_px) }
    match image_size_store.get(entity) {
      Some(prev) =>
        if prev.size.x == next.size.x && prev.size.y == next.size.y {
          ()
        } else {
          image_size_store.set(entity, next, tick) |> ignore
        }
      None => image_size_store.insert(entity, next, tick)
    }
  }

  // ImageNode (Bevy-aligned).
  image_node_store.for_each(fn(entity, image_node) {
    if !node_store.contains(entity) || ui_text_store.contains(entity) {
      return
    }
    let is_auto = match image_node.image_mode {
      NodeImageMode::Auto => true
      _ => false
    }
    if image_node.image.id() == transparent_id || !is_auto {
      if content_size_store.contains(entity) {
        content_size_store.remove(entity) |> ignore
      }
      return
    }
    let size_px = match image_node.rect {
      Some(r) => rect_size(r)
      None =>
        match image_node.texture_atlas {
          Some(atlas) =>
            match atlas_rect_for(atlas) {
              Some(ar) => rect_size(ar)
              None => texture_size(image_node.image)
            }
          None => texture_size(image_node.image)
        }
    }
    update_content_size(entity, size_px)
    update_image_node_size(entity, size_px)
  })

  // Legacy UiImage compatibility: treat as Auto-sized content when ImageNode is absent.
  ui_image_store.for_each(fn(entity, ui_image) {
    if image_node_store.contains(entity) {
      return
    }
    if !node_store.contains(entity) || ui_text_store.contains(entity) {
      return
    }
    if ui_image.image.id() == transparent_id {
      if content_size_store.contains(entity) {
        content_size_store.remove(entity) |> ignore
      }
      return
    }
    let size_px = match ui_image.rect {
      Some(r) => rect_size(r)
      None =>
        match ui_image.texture_atlas {
          Some(atlas) =>
            match atlas_rect_for(atlas) {
              Some(ar) => rect_size(ar)
              None => texture_size(ui_image.image)
            }
          None => texture_size(ui_image.image)
        }
    }
    update_content_size(entity, size_px)
  })
}

///|
pub fn[
  W : HasRes_UiContext + Has_UiRoot + Has_Node + Has_ContentSize + Has_ScrollPosition + Has_UiLayout + Has_UiImage + Has_UiText + @hierarchy.Has_Children + @render2d.Has_Sprite + @render2d.Has_RenderLayers + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility + @math.Has_Transform + @core.ChangeTickWorld,
] ui_layout_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }
  let root_store = Has_UiRoot::get_ui_root_store(world)
  let node_store = Has_Node::get_node_store(world)
  let content_size_store = Has_ContentSize::get_content_size_store(world)
  let scroll_store = Has_ScrollPosition::get_scroll_position_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let img_store = Has_UiImage::get_ui_image_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let root_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(ctx0.viewport_size.x, ctx0.viewport_size.y),
  )
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
            Some(base) => Some(base * (p / 100.0))
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
      node_id : Int,
      _ctx : Unit?,
      style : @moon_taffy.Style,
    ) -> @moon_taffy.Size[Double] {
      match node_to_entity.get(node_id) {
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
        let transform = ui_world_transform(ctx0, rect, 0.0F)
        if transform_store.contains(entity) {
          transform_store.set(entity, transform, tick) |> ignore
        } else {
          transform_store.insert(entity, transform, tick)
        }
        let layers = ensure_layers_default(world, entity)
        ensure_visibility_defaults(world, entity)
        if img_store.contains(entity) && sprite_store.contains(entity) {
          // UiImage rendering is handled by the UI pipeline, not the Sprite pipeline.
          sprite_store.remove(entity) |> ignore
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
        let size = layout.rect.size()
        let (border_l, border_t, border_r, border_b) = resolve_uirect_px(
          node.border,
          size,
          ctx0.viewport_size,
        )
        let (padding_l, padding_t, padding_r, padding_b) = resolve_uirect_px(
          node.padding,
          size,
          ctx0.viewport_size,
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
  W : HasRes_UiStack + Has_UiRoot + Has_UiLayout + Has_ZIndex + Has_GlobalZIndex + Has_UiText + @hierarchy.Has_Children + @hierarchy.Has_Parent + @math.Has_Transform + @core.ChangeTickWorld,
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
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)
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

  // Convert the Bevy-style UiStack ordering into a stable render z for the
  // engine's 2D renderer. We reserve a high base z to keep UI on top of 2D
  // world sprites, and use a coarse step to allow per-node sublayers.
  for i in 0..<stack.val.uinodes.length() {
    let entity = stack.val.uinodes[i]
    let z_base = UI_STACK_Z_BASE + int_to_float(i) * UI_STACK_Z_STEP
    let z = z_base + UI_STACK_Z_CONTENT
    match transform_store.get(entity) {
      Some(t0) => {
        let pos = @math.Vec2::new(t0.translation.x, t0.translation.y)
        let scale = @math.Vec2::new(t0.scale.x, t0.scale.y)
        let t = @math.Transform::from_xy_rotation_scale(
          pos,
          t0.rotation_z(),
          scale,
          z~,
        )
        if transform_store.contains(entity) {
          transform_store.set(entity, t, tick) |> ignore
        } else {
          transform_store.insert(entity, t, tick)
        }
      }
      None => ()
    }
    if ui_text_store.get(entity) is Some(text_node) {
      match transform_store.get(entity) {
        Some(t1) => {
          let pos = @math.Vec2::new(t1.translation.x, t1.translation.y)
          let scale = @math.Vec2::new(t1.scale.x, t1.scale.y)
          let z = z_base + UI_STACK_Z_TEXT
          let t_text = @math.Transform::from_xy_rotation_scale(
            pos,
            t1.rotation_z(),
            scale,
            z~,
          )
          @text.text_set_transform(text_node.handle, t_text)
        }
        None => ()
      }
    }
  }
}

///|
/// Build an AccessKit `TreeUpdate` for the current UI tree.
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + Has_UiLayout + Has_Button + Has_Label + Has_ImageNode + Has_AccessibilityLabel + Has_UiText + @hierarchy.Has_Parent + @hierarchy.Has_Children,
] ui_build_a11y_tree_update(
  world : W,
) -> @moon_accesskit.TreeUpdate {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else {
    let root = @moon_accesskit.NodeId::root()
    let update = @moon_accesskit.TreeUpdate::new(
      @moon_accesskit.TreeId::root(),
      root,
    )
    update.set_tree(@moon_accesskit.Tree::new(root))
    update
  }
  guard ctx0.camera_entity is Some(_) else {
    let root = @moon_accesskit.NodeId::root()
    let update = @moon_accesskit.TreeUpdate::new(
      @moon_accesskit.TreeId::root(),
      root,
    )
    update.set_tree(@moon_accesskit.Tree::new(root))
    update
  }
  let stack_res = HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else {
    let root = @moon_accesskit.NodeId::root()
    let update = @moon_accesskit.TreeUpdate::new(
      @moon_accesskit.TreeId::root(),
      root,
    )
    update.set_tree(@moon_accesskit.Tree::new(root))
    update
  }
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let label_widget_store = Has_Label::get_label_store(world)
  let image_node_store = Has_ImageNode::get_image_node_store(world)
  let label_store = Has_AccessibilityLabel::get_accessibility_label_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)

  // Build the set of required nodes (focusables + their ancestor chain), so
  // every node's parent always exists in this update.
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
    if button_store.contains(entity) ||
      label_widget_store.contains(entity) ||
      image_node_store.contains(entity) ||
      label_store.contains(entity) {
      mark_required(required, parent_store, layout_store, entity)
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
    children_store : @core.ComponentStore[@hierarchy.Children],
    ui_text_store : @core.ComponentStore[UiText],
    out : Ref[Array[String]],
  ) -> Unit {
    if ui_text_store.get(entity) is Some(text_node) {
      match @text.text_get_content(text_node.handle) {
        Some(s) => push_nonempty(out, s)
        None => ()
      }
    }
    guard children_store.get(entity) is Some(children) else { return }
    for i in 0..<children.entities.length() {
      collect_subtree_text(
        children.entities[i],
        children_store,
        ui_text_store,
        out,
      )
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

  fn calc_label_from_children(
    entity : @core.Entity,
    children_store : @core.ComponentStore[@hierarchy.Children],
    ui_text_store : @core.ComponentStore[UiText],
  ) -> String? {
    guard children_store.get(entity) is Some(children) else { return None }
    let mut name : String? = None
    for i in 0..<children.entities.length() {
      let child = children.entities[i]
      let parts : Array[String] = []
      let out = Ref::new(parts)
      collect_subtree_text(child, children_store, ui_text_store, out)
      if out.val.length() > 0 {
        name = Some(join_with_space(out.val))
      }
    }
    name
  }

  fn calc_value_from_self(
    entity : @core.Entity,
    children_store : @core.ComponentStore[@hierarchy.Children],
    ui_text_store : @core.ComponentStore[UiText],
  ) -> String? {
    let parts : Array[String] = []
    let out = Ref::new(parts)
    collect_subtree_text(entity, children_store, ui_text_store, out)
    if out.val.length() == 0 {
      None
    } else {
      Some(join_with_space(out.val))
    }
  }

  // Root node.
  let tree_id = @moon_accesskit.TreeId::root()
  let root_id = @moon_accesskit.NodeId::root()
  let update = @moon_accesskit.TreeUpdate::new(tree_id, root_id)
  update.set_tree(@moon_accesskit.Tree::new(root_id))
  let root_node = @moon_accesskit.Node::new(@moon_accesskit.Role::Window)
  root_node.set_bounds(
    @moon_accesskit.Rect::new(
      ctx0.viewport_origin.x.to_double(),
      ctx0.viewport_origin.y.to_double(),
      (ctx0.viewport_origin.x + ctx0.viewport_size.x).to_double(),
      (ctx0.viewport_origin.y + ctx0.viewport_size.y).to_double(),
    ),
  )

  // Attach top-level required nodes under the root.
  for entity in stack0.uinodes {
    if !required.contains(key(entity)) {
      continue
    }
    let parent_required = match parent_store.get(entity) {
      Some(p) =>
        required.contains(key(p.entity)) && layout_store.contains(p.entity)
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
    guard layout_store.get(entity) is Some(layout) else { continue }
    let node_id = @a11y.node_id_for_entity(entity)
    let role = if button_store.contains(entity) {
      @moon_accesskit.Role::Button
    } else if label_widget_store.contains(entity) {
      @moon_accesskit.Role::Label
    } else if image_node_store.contains(entity) {
      @moon_accesskit.Role::Image
    } else {
      @moon_accesskit.Role::GenericContainer
    }
    let node = @moon_accesskit.Node::new(role)

    // Children in hierarchy order (filtered to required set).
    if children_store.get(entity) is Some(children) {
      for i in 0..<children.entities.length() {
        let child = children.entities[i]
        if required.contains(key(child)) {
          node.push_child(@a11y.node_id_for_entity(child))
        }
      }
    }
    let rect = layout.rect
    let x0 = (ctx0.viewport_origin.x + rect.min.x).to_double()
    let y0 = (ctx0.viewport_origin.y + rect.min.y).to_double()
    let size = rect.size()
    let x1 = (ctx0.viewport_origin.x + rect.min.x + size.x).to_double()
    let y1 = (ctx0.viewport_origin.y + rect.min.y + size.y).to_double()
    node.set_bounds(@moon_accesskit.Rect::new(x0, y0, x1, y1))
    if role == @moon_accesskit.Role::Button {
      node.add_action(@moon_accesskit.Action::Focus)
      node.add_action(@moon_accesskit.Action::Click)
    }
    let explicit_label = match label_store.get(entity) {
      Some(v) => v.text
      None => ""
    }
    if role == @moon_accesskit.Role::Button ||
      role == @moon_accesskit.Role::Image {
      let name = if explicit_label != "" {
        Some(explicit_label)
      } else {
        calc_label_from_children(entity, children_store, ui_text_store)
      }
      match name {
        Some(s) => if s != "" { node.set_label(s) }
        None => ()
      }
    } else if role == @moon_accesskit.Role::Label {
      let value = if explicit_label != "" {
        Some(explicit_label)
      } else {
        calc_value_from_self(entity, children_store, ui_text_store)
      }
      match value {
        Some(s) => if s != "" { node.set_value(s) }
        None => ()
      }
    } else if explicit_label != "" {
      node.set_label(explicit_label)
    }
    update.push_node(node_id, node)
  }
  update
}

///|
/// Extract UI accessibility nodes and send them to the host bridge.
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + Has_UiLayout + Has_Button + Has_Label + Has_ImageNode + Has_AccessibilityLabel + Has_UiText + @hierarchy.Has_Parent + @hierarchy.Has_Children,
] ui_a11y_update_system(
  world : W,
) -> Unit {
  let update = ui_build_a11y_tree_update(world)
  @a11y.a11y_host_apply_update(update)
}

///|
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + Has_UiLayout + Has_Button + Has_Interaction + Has_RelativeCursorPosition + Has_FocusPolicy + Has_CalculatedClip + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
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
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let pointer = ctx0.pointer_pos
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
}

///|
fn vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn ui_uv_from_image_rects(
  image_size : @math.Vec2,
  atlas_rect : @math.Rect?,
  rect : @math.Rect?,
  flip_x : Bool,
  flip_y : Bool,
) -> (@math.Vec2, @math.Vec2) {
  let denom_x = image_size.x
  let denom_y = image_size.y
  if denom_x <= 0.0F || denom_y <= 0.0F {
    return (@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F))
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(denom_x, denom_y),
  )
  let texture_rect = match (atlas_rect, rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = vec2_add(r.min, ar.min)
      let max = vec2_add(r.max, ar.min)
      @math.Rect::new(min, max)
    }
  }
  let mut uv_min = @math.Vec2::new(
    texture_rect.min.x / denom_x,
    texture_rect.min.y / denom_y,
  )
  let mut uv_max = @math.Vec2::new(
    texture_rect.max.x / denom_x,
    texture_rect.max.y / denom_y,
  )
  if flip_x {
    let tmp = uv_min.x
    uv_min = @math.Vec2::new(uv_max.x, uv_min.y)
    uv_max = @math.Vec2::new(tmp, uv_max.y)
  }
  if flip_y {
    let tmp = uv_min.y
    uv_min = @math.Vec2::new(uv_min.x, uv_max.y)
    uv_max = @math.Vec2::new(uv_max.x, tmp)
  }
  (uv_min, uv_max)
}

///|
pub fn[
  W : HasRes_UiContext + HasRes_UiStack + HasRes_UiScale + Has_UiLayout + Has_Node + Has_BackgroundColor + Has_UiImage + Has_ImageNode + Has_ButtonColors + Has_Interaction + Has_Outline + Has_BoxShadow + Has_UiBoxShadowSamples + Has_BorderColor + Has_BorderRadius + Has_UiAntiAlias + @render2d.HasRes_RenderState + @render2d.Has_RenderLayers + @render2d.Has_ScissorRect + @math.Has_Transform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] ui_render_extract_system(
  world : W,
) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  let stack_res = HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  @render2d.render2d_clear_overlay_ui_rects(world)
  @render2d.render2d_clear_overlay_ui_box_shadows(world)
  @render2d.render2d_clear_overlay_ui_texture_slices(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let node_store = Has_Node::get_node_store(world)
  let bg_store = Has_BackgroundColor::get_background_color_store(world)
  let img_store = Has_UiImage::get_ui_image_store(world)
  let image_node_store = Has_ImageNode::get_image_node_store(world)
  let button_store = Has_ButtonColors::get_button_colors_store(world)
  let interaction_store = Has_Interaction::get_interaction_store(world)
  let outline_store = Has_Outline::get_outline_store(world)
  let shadow_store = Has_BoxShadow::get_box_shadow_store(world)
  let shadow_samples_store = Has_UiBoxShadowSamples::get_ui_box_shadow_samples_store(
    world,
  )
  let border_color_store = Has_BorderColor::get_border_color_store(world)
  let radius_store = Has_BorderRadius::get_border_radius_store(world)
  let aa_store = Has_UiAntiAlias::get_ui_anti_alias_store(world)
  let layers_store = @render2d.Has_RenderLayers::get_render_layers_store(world)
  let scissor_store = @render2d.Has_ScissorRect::get_scissor_rect_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
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

  fn resolve_radius_single(
    val : Val,
    node_size : @math.Vec2,
    viewport_size : @math.Vec2,
  ) -> Float {
    let min_elem = if node_size.x < node_size.y {
      node_size.x
    } else {
      node_size.y
    }
    let raw = match val {
      Val::Auto => 0.0F
      Val::Px(px) => px
      Val::Percent(p) => min_elem * (p / 100.0F)
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
    let clamped = clamp_nonneg(raw)
    let max_r = 0.5F * min_elem
    if clamped > max_r {
      max_r
    } else {
      clamped
    }
  }

  fn clamp_radius_nonneg(radius : Float, node_size : @math.Vec2) -> Float {
    let clamped = clamp_nonneg(radius)
    let min_elem = if node_size.x < node_size.y {
      node_size.x
    } else {
      node_size.y
    }
    let max_r = 0.5F * min_elem
    if clamped > max_r {
      max_r
    } else {
      clamped
    }
  }

  fn transform_with_z(t : @math.Transform, z : Float) -> @math.Transform {
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(t.translation.x, t.translation.y),
      t.rotation_z(),
      @math.Vec2::new(t.scale.x, t.scale.y),
      z~,
    )
  }

  let shadow_samples = match ctx0.camera_entity {
    Some(cam) =>
      match shadow_samples_store.get(cam) {
        Some(v) => v.samples
        None => UiBoxShadowSamples::default().samples
      }
    None => UiBoxShadowSamples::default().samples
  }
  let uv_min = @math.Vec2::new(0.0F, 0.0F)
  let uv_max = @math.Vec2::new(1.0F, 1.0F)
  for i in 0..<stack0.uinodes.length() {
    let entity = stack0.uinodes[i]
    if vv_store.get(entity) is Some(vv) && !vv.is_visible() {
      continue
    }
    guard layout_store.get(entity) is Some(layout) else { continue }
    guard node_store.get(entity) is Some(node) else { continue }
    guard transform_store.get(entity) is Some(t0) else { continue }
    let rect = layout.rect
    let size = rect.size()
    if size.x <= 0.0F || size.y <= 0.0F {
      continue
    }
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => @render2d.RenderLayers::default()
    }
    let scissor = match scissor_store.get(entity) {
      Some(v) => Some(v.rect)
      None => None
    }
    let scale_x = t0.scale.x
    let scale_y = t0.scale.y
    let draw_scale = @math.Vec2::new(scale_x * size.x, scale_y * size.y)
    let scale_min = if scale_x < scale_y { scale_x } else { scale_y }
    let border_left = clamp_nonneg(
        resolve_axis(node.border.left, size.x, ctx0.viewport_size),
      ) *
      scale_x
    let border_right = clamp_nonneg(
        resolve_axis(node.border.right, size.x, ctx0.viewport_size),
      ) *
      scale_x
    let border_top = clamp_nonneg(
        resolve_axis(node.border.top, size.y, ctx0.viewport_size),
      ) *
      scale_y
    let border_bottom = clamp_nonneg(
        resolve_axis(node.border.bottom, size.y, ctx0.viewport_size),
      ) *
      scale_y
    let border = @render2d.UiBorderRect::new(
      border_left, border_top, border_right, border_bottom,
    )
    let radius = match radius_store.get(entity) {
      Some(r) => {
        let tl = resolve_radius_single(r.top_left, size, ctx0.viewport_size) *
          scale_min
        let tr = resolve_radius_single(r.top_right, size, ctx0.viewport_size) *
          scale_min
        let br = resolve_radius_single(r.bottom_right, size, ctx0.viewport_size) *
          scale_min
        let bl = resolve_radius_single(r.bottom_left, size, ctx0.viewport_size) *
          scale_min
        @render2d.UiCornerRadii::new(tl, tr, br, bl)
      }
      None => @render2d.UiCornerRadii::zero()
    }
    let mut flags = 0
    let aa_enabled = match aa_store.get(entity) {
      Some(UiAntiAlias::Off) => false
      _ => true
    }
    if aa_enabled {
      flags = flags | UI_DRAW_FLAG_ANTIALIAS
    }
    let z_base = UI_STACK_Z_BASE + int_to_float(i) * UI_STACK_Z_STEP

    // BoxShadow (behind background/content/border/text).
    match shadow_store.get(entity) {
      Some(shadow) =>
        if shadow.color.a > 0.0F {
          let spread_x = resolve_axis(
            shadow.spread_radius,
            size.x,
            ctx0.viewport_size,
          )
          let spread_ratio = (spread_x + size.x) / size.x
          let spread_y = size.y * spread_ratio - size.y
          let shadow_size = @math.Vec2::new(
            size.x + spread_x,
            size.y + spread_y,
          )
          if shadow_size.x > 0.0F && shadow_size.y > 0.0F {
            let blur = clamp_nonneg(
              resolve_axis(shadow.blur_radius, size.x, ctx0.viewport_size),
            )
            let bounds = @math.Vec2::new(
              shadow_size.x + 6.0F * blur,
              shadow_size.y + 6.0F * blur,
            )
            if bounds.x > 0.0F && bounds.y > 0.0F {
              let offset_x = resolve_axis(
                shadow.x_offset,
                size.x,
                ctx0.viewport_size,
              )
              let offset_y = resolve_axis(
                shadow.y_offset,
                size.y,
                ctx0.viewport_size,
              )
              // UI uses +Y down; world uses +Y up.
              let offset_local = @math.Vec2::new(
                offset_x * scale_x,
                -offset_y * scale_y,
              )
              let offset_world = rotate_vec2(offset_local, t0.rotation_z())
              let t_shadow = @math.Transform::from_xy_rotation_scale(
                @math.Vec2::new(
                  t0.translation.x + offset_world.x,
                  t0.translation.y + offset_world.y,
                ),
                t0.rotation_z(),
                @math.Vec2::new(t0.scale.x, t0.scale.y),
                z=z_base + UI_STACK_Z_SHADOW,
              )
              let radius_shadow = match radius_store.get(entity) {
                Some(r) => {
                  let tl = resolve_radius_single(
                      r.top_left,
                      size,
                      ctx0.viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let tr = resolve_radius_single(
                      r.top_right,
                      size,
                      ctx0.viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let br = resolve_radius_single(
                      r.bottom_right,
                      size,
                      ctx0.viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let bl = resolve_radius_single(
                      r.bottom_left,
                      size,
                      ctx0.viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  @render2d.UiCornerRadii::new(tl, tr, br, bl)
                }
                None => @render2d.UiCornerRadii::zero()
              }
              let draw_scale_shadow = @math.Vec2::new(
                scale_x * bounds.x,
                scale_y * bounds.y,
              )
              let size_shadow_world = @math.Vec2::new(
                scale_x * shadow_size.x,
                scale_y * shadow_size.y,
              )
              @render2d.render2d_push_ui_box_shadow_scissor(
                world,
                entity,
                ctx0.white_texture,
                t_shadow,
                draw_scale_shadow,
                shadow.color,
                layers,
                scissor,
                size_shadow_world,
                radius_shadow,
                blur * scale_min,
                shadow_samples,
              )
            }
          }
        }
      None => ()
    }

    // Background color.
    let bg_color_opt = match button_store.get(entity) {
      Some(colors) =>
        Some(button_color_for_state(colors, interaction_store.get(entity)))
      None =>
        match bg_store.get(entity) {
          Some(v) => Some(v.color)
          None => None
        }
    }
    match bg_color_opt {
      Some(color) =>
        if color.a > 0.0F {
          let t_bg = transform_with_z(t0, z_base + UI_STACK_Z_BACKGROUND)
          @render2d.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            ctx0.white_texture,
            t_bg,
            draw_scale,
            uv_min,
            uv_max,
            color,
            layers,
            scissor,
            flags,
            radius,
            border,
          )
        }
      None => ()
    }

    // Image content (Bevy `ImageNode`, with `UiImage` compatibility).
    let image_info = match image_node_store.get(entity) {
      Some(img) =>
        Some(
          (
            img.image,
            img.color,
            img.texture_atlas,
            img.rect,
            img.flip_x,
            img.flip_y,
            Some(img.image_mode),
          ),
        )
      None =>
        match img_store.get(entity) {
          Some(img) =>
            Some(
              (
                img.image,
                img.color,
                img.texture_atlas,
                img.rect,
                img.flip_x,
                img.flip_y,
                None,
              ),
            )
          None => None
        }
    }
    match image_info {
      Some(info) => {
        let texture = info.0
        let color = info.1
        let texture_atlas = info.2
        let rect = info.3
        let flip_x = info.4
        let flip_y = info.5
        let mode = match info.6 {
          Some(m) => m
          None => NodeImageMode::Stretch
        }
        let mut image_width = @asset.asset_texture_width(texture)
        let mut image_height = @asset.asset_texture_height(texture)
        if image_width <= 0 || image_height <= 0 {
          // Avoid division by zero for not-yet-loaded textures.
          image_width = 1
          image_height = 1
        }
        let image_size = @math.Vec2::new(
          Float::from_double(image_width.to_double()),
          Float::from_double(image_height.to_double()),
        )
        let atlas_rect = match texture_atlas {
          Some(atlas) =>
            match @asset.asset_get_texture_atlas_layout(atlas.layout) {
              Some(layout_value) =>
                if atlas.index >= 0 &&
                  atlas.index < layout_value.textures.length() {
                  Some(layout_value.textures[atlas.index].as_rect())
                } else {
                  None
                }
              None => None
            }
          None => None
        }
        let pair = ui_uv_from_image_rects(
          image_size, atlas_rect, rect, flip_x, flip_y,
        )
        let uv_min_img = pair.0
        let uv_max_img = pair.1
        let t_content = transform_with_z(t0, z_base + UI_STACK_Z_CONTENT)
        if color.a > 0.0F && NodeImageMode::uses_slices(mode) {
          let sf = safe_scale_factor(@window.window_scale_factor())
          let ui_scale_value = match ensure_ui_scale_resource(world) {
            Some(ui_scale) =>
              if ui_scale.val.value <= 0.0F {
                1.0F
              } else {
                ui_scale.val.value
              }
            None => 1.0F
          }
          // `size` is in logical UI units. Convert to physical pixels before
          // computing slice/tiling parameters to match Bevy.
          let px_per_ui = sf / ui_scale_value
          let target_size = @math.Vec2::new(
            size.x * px_per_ui,
            size.y * px_per_ui,
          )
          // Image slicing uses the size of the selected texture region (atlas/rect).
          let image_rect = @math.Rect::new(
            @math.Vec2::new(0.0F, 0.0F),
            @math.Vec2::new(image_size.x, image_size.y),
          )
          let texture_rect = match (atlas_rect, rect) {
            (None, None) => image_rect
            (None, Some(r)) => r
            (Some(ar), None) => ar
            (Some(ar), Some(r)) => {
              let min = vec2_add(r.min, ar.min)
              let max = vec2_add(r.max, ar.min)
              @math.Rect::new(min, max)
            }
          }
          let region_size = texture_rect.size()
          let (texture_slices, target_slices, repeat) = compute_texture_slices(
            region_size, target_size, mode,
          )
          let atlas_rect_uv = @math.Vec4::new(
            uv_min_img.x,
            uv_min_img.y,
            uv_max_img.x,
            uv_max_img.y,
          )
          @render2d.render2d_push_ui_texture_slice_scissor(
            world, entity, texture, t_content, draw_scale, color, layers, scissor,
            texture_slices, target_slices, repeat, atlas_rect_uv,
          )
        } else if color.a > 0.0F {
          @render2d.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            texture,
            t_content,
            draw_scale,
            uv_min_img,
            uv_max_img,
            color,
            layers,
            scissor,
            flags | UI_DRAW_FLAG_TEXTURED,
            radius,
            border,
          )
        }
      }
      None => ()
    }

    // Border.
    let has_border = border_left > 0.0F ||
      border_right > 0.0F ||
      border_top > 0.0F ||
      border_bottom > 0.0F
    if has_border &&
      border_color_store.get(entity) is Some(bc) &&
      bc.color.a > 0.0F {
      let t_border = transform_with_z(t0, z_base + UI_STACK_Z_BORDER)
      @render2d.render2d_push_ui_rect_uv_scissor(
        world,
        entity,
        ctx0.white_texture,
        t_border,
        draw_scale,
        uv_min,
        uv_max,
        bc.color,
        layers,
        scissor,
        flags | UI_DRAW_FLAG_BORDER,
        radius,
        border,
      )
    }

    // Outline.
    match outline_store.get(entity) {
      Some(outline) =>
        if outline.color.a > 0.0F {
          let outline_width = clamp_nonneg(
            resolve_axis(outline.width, size.x, ctx0.viewport_size),
          )
          if outline_width > 0.0F {
            let outline_offset = resolve_axis(
              outline.offset,
              size.x,
              ctx0.viewport_size,
            )
            let outer = outline_offset + outline_width
            let outline_size = @math.Vec2::new(
              size.x + 2.0F * outer,
              size.y + 2.0F * outer,
            )
            if outline_size.x > 0.0F && outline_size.y > 0.0F {
              let t_outline = transform_with_z(t0, z_base + UI_STACK_Z_OUTLINE)
              let outline_draw_scale = @math.Vec2::new(
                scale_x * outline_size.x,
                scale_y * outline_size.y,
              )
              let outline_border = @render2d.UiBorderRect::new(
                outline_width * scale_x,
                outline_width * scale_y,
                outline_width * scale_x,
                outline_width * scale_y,
              )
              let outline_radius = match radius_store.get(entity) {
                Some(r) => {
                  let tl = clamp_radius_nonneg(
                      resolve_radius_single(
                        r.top_left,
                        size,
                        ctx0.viewport_size,
                      ) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let tr = clamp_radius_nonneg(
                      resolve_radius_single(
                        r.top_right,
                        size,
                        ctx0.viewport_size,
                      ) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let br = clamp_radius_nonneg(
                      resolve_radius_single(
                        r.bottom_right,
                        size,
                        ctx0.viewport_size,
                      ) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let bl = clamp_radius_nonneg(
                      resolve_radius_single(
                        r.bottom_left,
                        size,
                        ctx0.viewport_size,
                      ) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  @render2d.UiCornerRadii::new(tl, tr, br, bl)
                }
                None =>
                  @render2d.UiCornerRadii::new(
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                  )
              }
              @render2d.render2d_push_ui_rect_uv_scissor(
                world,
                entity,
                ctx0.white_texture,
                t_outline,
                outline_draw_scale,
                uv_min,
                uv_max,
                outline.color,
                layers,
                scissor,
                flags | UI_DRAW_FLAG_BORDER,
                outline_radius,
                outline_border,
              )
            }
          }
        }
      None => ()
    }
  }
}

///|
pub fn[
  W : HasRes_UiContext + HasRes_UiScale + Has_UiRoot + Has_Node + Has_ContentSize + Has_ImageNodeSize + Has_ZIndex + Has_GlobalZIndex + HasRes_UiStack + Has_ScrollPosition + Has_UiLayout + Has_CalculatedClip + Has_RelativeCursorPosition + Has_FocusPolicy + Has_BackgroundColor + Has_UiImage + Has_ImageNode + Has_ButtonColors + Has_Button + Has_Label + Has_Interaction + Has_UiText + Has_AccessibilityLabel + Has_Outline + Has_BoxShadow + Has_UiBoxShadowSamples + Has_BorderColor + Has_BorderRadius + Has_UiAntiAlias + @hierarchy.Has_Children + @hierarchy.Has_Parent + @render2d.HasRes_RenderState + @render2d.Has_Camera2d + @render2d.Has_Camera + @render2d.Has_Projection + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @render2d.Has_Sprite + @render2d.Has_ScissorRect + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
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
    @app.system(ui_image_content_size_system).in_set(ui_set_measure),
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
    @app.system(ui_render_extract_system).in_set(ui_set_render_extract),
  )
  .configure_set(@app.PreUpdate, ui_set_context, before=[ui_set_scroll])
  .configure_set(@app.PreUpdate, ui_set_scroll, after=[ui_set_context], before=[
    ui_set_measure,
  ])
  .configure_set(@app.PreUpdate, ui_set_measure, after=[ui_set_scroll], before=[
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
  .configure_set(@app.PreUpdate, ui_set_render_extract, after=[
    ui_set_interaction,
  ])
}
