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
pub struct Color {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
pub fn Color::new(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{ r, g, b, a }
}

///|
fn color_srgb_to_linear(value : Float) -> Float {
  if value <= 0.0F {
    value
  } else if value <= 0.04045F {
    value / 12.92F
  } else {
    @math.pow((value + 0.055F) / 1.055F, 2.4F)
  }
}

///|
fn color_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn color_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn color_wrap_hue(hue : Float) -> Float {
  let mut wrapped = hue
  while wrapped < 0.0F {
    wrapped = wrapped + 360.0F
  }
  while wrapped >= 360.0F {
    wrapped = wrapped - 360.0F
  }
  wrapped
}

///|
pub fn Color::srgb(r : Float, g : Float, b : Float) -> Color {
  Color::{
    r: color_srgb_to_linear(r),
    g: color_srgb_to_linear(g),
    b: color_srgb_to_linear(b),
    a: 1.0F,
  }
}

///|
pub fn Color::srgba(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{
    r: color_srgb_to_linear(r),
    g: color_srgb_to_linear(g),
    b: color_srgb_to_linear(b),
    a,
  }
}

///|
pub fn Color::hsla(
  hue : Float,
  saturation : Float,
  lightness : Float,
  alpha : Float,
) -> Color {
  let h = color_wrap_hue(hue)
  let s = color_clamp_unit(saturation)
  let l = color_clamp_unit(lightness)
  let a = color_clamp_unit(alpha)
  let chroma = (1.0F - color_abs(2.0F * l - 1.0F)) * s
  let m = l - chroma / 2.0F
  let (r1, g1, b1) = if h < 60.0F {
    let x = chroma * h / 60.0F
    (chroma, x, 0.0F)
  } else if h < 120.0F {
    let x = chroma * (1.0F - (h - 60.0F) / 60.0F)
    (x, chroma, 0.0F)
  } else if h < 180.0F {
    let x = chroma * (h - 120.0F) / 60.0F
    (0.0F, chroma, x)
  } else if h < 240.0F {
    let x = chroma * (1.0F - (h - 180.0F) / 60.0F)
    (0.0F, x, chroma)
  } else if h < 300.0F {
    let x = chroma * (h - 240.0F) / 60.0F
    (x, 0.0F, chroma)
  } else {
    let x = chroma * (1.0F - (h - 300.0F) / 60.0F)
    (chroma, 0.0F, x)
  }
  Color::srgba(
    color_clamp_unit(r1 + m),
    color_clamp_unit(g1 + m),
    color_clamp_unit(b1 + m),
    a,
  )
}

///|
pub fn Color::hsl(hue : Float, saturation : Float, lightness : Float) -> Color {
  Color::hsla(hue, saturation, lightness, 1.0F)
}

///|
pub fn Color::white() -> Color {
  Color::new(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
pub fn Color::black() -> Color {
  Color::new(0.0F, 0.0F, 0.0F, 1.0F)
}

///|

///|
pub struct RenderLayers {
  mask : Int
}

///|
fn render_layer_clamp_index(index : Int) -> Int {
  if index < 0 {
    0
  } else {
    index
  }
}

///|
fn render_layer_bit(index : Int) -> Int {
  1 << render_layer_clamp_index(index)
}

///|
pub fn RenderLayers::default() -> RenderLayers {
  RenderLayers::{ mask: 1 }
}

///|
pub fn RenderLayers::none() -> RenderLayers {
  RenderLayers::{ mask: 0 }
}

///|
pub fn RenderLayers::layer(index : Int) -> RenderLayers {
  RenderLayers::{ mask: render_layer_bit(index) }
}

///|
pub fn RenderLayers::matches(self : RenderLayers, other : RenderLayers) -> Bool {
  self.intersects(other)
}

///|
pub fn RenderLayers::intersects(
  self : RenderLayers,
  other : RenderLayers,
) -> Bool {
  (self.mask & other.mask) != 0
}

///|
pub fn RenderLayers::from_layers(layers : Array[Int]) -> RenderLayers {
  let mut mask = 0
  for layer in layers {
    mask = mask | render_layer_bit(layer)
  }
  RenderLayers::{ mask, }
}

///|
pub fn RenderLayers::with_layer(
  self : RenderLayers,
  index : Int,
) -> RenderLayers {
  RenderLayers::{ mask: self.mask | render_layer_bit(index) }
}

///|
pub fn RenderLayers::without_layer(
  self : RenderLayers,
  index : Int,
) -> RenderLayers {
  let bit = render_layer_bit(index)
  if (self.mask & bit) != 0 {
    RenderLayers::{ mask: self.mask ^ bit }
  } else {
    self
  }
}

///|
pub fn RenderLayers::add(self : RenderLayers, index : Int) -> RenderLayers {
  self.with_layer(index)
}

///|
pub fn RenderLayers::remove(self : RenderLayers, index : Int) -> RenderLayers {
  self.without_layer(index)
}

///|
pub fn RenderLayers::contains(self : RenderLayers, index : Int) -> Bool {
  (self.mask & render_layer_bit(index)) != 0
}

///|
pub fn RenderLayers::union(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  RenderLayers::{ mask: self.mask | other.mask }
}

///|
pub fn RenderLayers::intersection(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  RenderLayers::{ mask: self.mask & other.mask }
}

///|
pub fn RenderLayers::combine(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  self.union(other)
}

///|
pub struct Viewport {
  physical_position : @math.IVec2
  physical_size : @math.IVec2
  depth_min : Float
  depth_max : Float
}

///|
pub fn Viewport::new(
  physical_position : @math.IVec2,
  physical_size : @math.IVec2,
) -> Viewport {
  Viewport::{
    physical_position,
    physical_size,
    depth_min: 0.0F,
    depth_max: 1.0F,
  }
}

///|
pub fn Viewport::new_with_depth(
  physical_position : @math.IVec2,
  physical_size : @math.IVec2,
  depth_min : Float,
  depth_max : Float,
) -> Viewport {
  let mut min_depth = depth_min
  let mut max_depth = depth_max
  if min_depth < 0.0F {
    min_depth = 0.0F
  }
  if min_depth > 1.0F {
    min_depth = 1.0F
  }
  if max_depth < min_depth {
    max_depth = min_depth
  }
  if max_depth > 1.0F {
    max_depth = 1.0F
  }
  Viewport::{
    physical_position,
    physical_size,
    depth_min: min_depth,
    depth_max: max_depth,
  }
}

///|
pub fn Viewport::with_depth(
  self : Viewport,
  depth_min : Float,
  depth_max : Float,
) -> Viewport {
  Viewport::new_with_depth(
    self.physical_position,
    self.physical_size,
    depth_min,
    depth_max,
  )
}

///|
pub fn Viewport::default() -> Viewport {
  Viewport::new(@math.IVec2::new(0, 0), @math.IVec2::new(1, 1))
}

///|

///|
pub(all) struct Sprite {
  mut image : @asset.Handle[@asset.Image]
  mut texture_atlas : @asset.TextureAtlas?
  mut color : Color
  mut flip_x : Bool
  mut flip_y : Bool
  mut custom_size : @math.Vec2?
  mut rect : @math.Rect?
  mut image_mode : SpriteImageMode
}

///|
/// Marker component aligned with Bevy's `Wireframe2d`.
///
/// Meshes with this marker render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct Wireframe2d {}

///|
pub fn Wireframe2d::default() -> Wireframe2d {
  Wireframe2d::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe2d`.
///
/// Meshes with this marker never render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct NoWireframe2d {}

///|
pub fn NoWireframe2d::default() -> NoWireframe2d {
  NoWireframe2d::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `Wireframe2dColor`.
pub struct Wireframe2dColor {
  color : Color
}

///|
pub fn Wireframe2dColor::default() -> Wireframe2dColor {
  Wireframe2dColor::{ color: Color::white() }
}

///|
pub fn Wireframe2dColor::new(color : Color) -> Wireframe2dColor {
  Wireframe2dColor::{ color, }
}

///|
pub fn Wireframe2dColor::with_color(
  self : Wireframe2dColor,
  color : Color,
) -> Wireframe2dColor {
  self |> ignore
  Wireframe2dColor::{ color, }
}

///|
pub struct Wireframe2dConfig {
  global : Bool
  default_color : Color
} derive(ToJson, FromJson)

///|
pub fn Wireframe2dConfig::default() -> Wireframe2dConfig {
  Wireframe2dConfig::{ global: false, default_color: Color::white() }
}

///|
pub fn Wireframe2dConfig::new(
  global : Bool,
  default_color : Color,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ global, default_color }
}

///|
pub fn Wireframe2dConfig::with_global(
  self : Wireframe2dConfig,
  global : Bool,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ ..self, global, }
}

///|
pub fn Wireframe2dConfig::with_default_color(
  self : Wireframe2dConfig,
  default_color : Color,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ ..self, default_color, }
}

///|
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
pub fn BorderRect::default() -> BorderRect {
  BorderRect::square(0.0F)
}

///|
pub(all) enum SliceScaleMode {
  Stretch
  Tile(Float)
}

///|
pub fn SliceScaleMode::default() -> SliceScaleMode {
  SliceScaleMode::Stretch
}

///|
pub(all) enum SpriteScalingMode {
  FillCenter
  FillStart
  FillEnd
  FitCenter
  FitStart
  FitEnd
}

///|
pub fn SpriteScalingMode::default() -> SpriteScalingMode {
  SpriteScalingMode::FillCenter
}

///|
pub struct SpriteTiling {
  tile_x : Bool
  tile_y : Bool
  stretch_value : Float
}

///|
pub fn SpriteTiling::new(
  tile_x : Bool,
  tile_y : Bool,
  stretch_value : Float,
) -> SpriteTiling {
  SpriteTiling::{ tile_x, tile_y, stretch_value }
}

///|
pub fn SpriteTiling::default() -> SpriteTiling {
  SpriteTiling::new(true, true, 1.0F)
}

///|
pub fn SpriteTiling::with_tile_x(
  self : SpriteTiling,
  tile_x : Bool,
) -> SpriteTiling {
  SpriteTiling::{ ..self, tile_x, }
}

///|
pub fn SpriteTiling::with_tile_y(
  self : SpriteTiling,
  tile_y : Bool,
) -> SpriteTiling {
  SpriteTiling::{ ..self, tile_y, }
}

///|
pub fn SpriteTiling::with_stretch_value(
  self : SpriteTiling,
  stretch_value : Float,
) -> SpriteTiling {
  SpriteTiling::{ ..self, stretch_value, }
}

///|
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
pub(all) enum SpriteImageMode {
  Auto
  Scale(SpriteScalingMode)
  Sliced(TextureSlicer)
  Tiled(SpriteTiling)
}

///|
pub fn SpriteImageMode::default() -> SpriteImageMode {
  SpriteImageMode::Auto
}

///|
pub fn SpriteImageMode::scale(
  scaling_mode? : SpriteScalingMode = SpriteScalingMode::FillCenter,
) -> SpriteImageMode {
  SpriteImageMode::Scale(scaling_mode)
}

///|
fn sprite_image_mode_uses_slices(mode : SpriteImageMode) -> Bool {
  match mode {
    SpriteImageMode::Sliced(_) => true
    _ => false
  }
}

///|
pub fn SpriteImageMode::tiled(
  tile_x? : Bool = true,
  tile_y? : Bool = true,
  stretch_value? : Float = 1.0F,
) -> SpriteImageMode {
  SpriteImageMode::Tiled(SpriteTiling::new(tile_x, tile_y, stretch_value))
}

///|
pub fn Sprite::from_image(image : @asset.Handle[@asset.Image]) -> Sprite {
  Sprite::{
    image,
    texture_atlas: None,
    color: Color::white(),
    flip_x: false,
    flip_y: false,
    custom_size: None,
    rect: None,
    image_mode: SpriteImageMode::Auto,
  }
}

///|
pub fn Sprite::from_atlas_image(
  image : @asset.Handle[@asset.Image],
  atlas : @asset.TextureAtlas,
) -> Sprite {
  Sprite::{ ..Sprite::from_image(image), texture_atlas: Some(atlas) }
}

///|
pub fn Sprite::with_texture_atlas(
  self : Sprite,
  texture_atlas : @asset.TextureAtlas?,
) -> Sprite {
  Sprite::{ ..self, texture_atlas, }
}

///|
pub fn Sprite::with_color(self : Sprite, color : Color) -> Sprite {
  Sprite::{ ..self, color, }
}

///|
pub fn Sprite::with_flip_x(self : Sprite, flip_x : Bool) -> Sprite {
  Sprite::{ ..self, flip_x, }
}

///|
pub fn Sprite::with_flip_y(self : Sprite, flip_y : Bool) -> Sprite {
  Sprite::{ ..self, flip_y, }
}

///|
pub fn Sprite::with_custom_size(
  self : Sprite,
  custom_size : @math.Vec2?,
) -> Sprite {
  Sprite::{ ..self, custom_size, }
}

///|
pub fn Sprite::with_rect(self : Sprite, rect : @math.Rect?) -> Sprite {
  Sprite::{ ..self, rect, }
}

///|
pub fn Sprite::with_image_mode(
  self : Sprite,
  image_mode : SpriteImageMode,
) -> Sprite {
  Sprite::{ ..self, image_mode, }
}

///|
/// A per-entity scissor rectangle in *logical* pixels, relative to the active
/// camera's view (top-left origin).
///
/// When present, `render_execute_system` converts it into physical pixels using
/// the camera's scale factor and viewport offset, then applies it via
/// `host_gpu_set_scissor`.
///
/// This is primarily used by UI clipping (overflow/scroll).
pub struct ScissorRect {
  rect : @math.Rect
}

///|
pub fn ScissorRect::new(rect : @math.Rect) -> ScissorRect {
  ScissorRect::{ rect, }
}

///|
/// UI corner radii (top-left, top-right, bottom-right, bottom-left) in logical pixels.
pub struct UiCornerRadii {
  top_left : Float
  top_right : Float
  bottom_right : Float
  bottom_left : Float
} derive(ToJson, FromJson)

///|
pub fn UiCornerRadii::new(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> UiCornerRadii {
  UiCornerRadii::{ top_left, top_right, bottom_right, bottom_left }
}

///|
pub fn UiCornerRadii::zero() -> UiCornerRadii {
  UiCornerRadii::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
/// UI border thickness (left, top, right, bottom) in logical pixels.
pub struct UiBorderRect {
  left : Float
  top : Float
  right : Float
  bottom : Float
} derive(ToJson, FromJson)

///|
pub fn UiBorderRect::new(
  left : Float,
  top : Float,
  right : Float,
  bottom : Float,
) -> UiBorderRect {
  UiBorderRect::{ left, top, right, bottom }
}

///|
pub fn UiBorderRect::zero() -> UiBorderRect {
  UiBorderRect::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
pub struct Anchor {
  value : @math.Vec2
}

///|
pub fn Anchor::new(value : @math.Vec2) -> Anchor {
  Anchor::{ value, }
}

///|
pub fn Anchor::as_vec(self : Anchor) -> @math.Vec2 {
  self.value
}

///|
pub fn Anchor::bottom_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, -0.5F))
}

///|
pub fn Anchor::bottom_center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, -0.5F))
}

///|
pub fn Anchor::bottom_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, -0.5F))
}

///|
pub fn Anchor::center_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, 0.0F))
}

///|
pub fn Anchor::center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, 0.0F))
}

///|
pub fn Anchor::center_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, 0.0F))
}

///|
pub fn Anchor::top_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, 0.5F))
}

///|
pub fn Anchor::top_center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, 0.5F))
}

///|
pub fn Anchor::top_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, 0.5F))
}

///|
pub fn Anchor::default() -> Anchor {
  Anchor::center()
}

///|

///|
pub struct ClearColor {
  color : Color
}

///|
pub fn ClearColor::new(color : Color) -> ClearColor {
  ClearColor::{ color, }
}

///|
pub fn ClearColor::default() -> ClearColor {
  // Match Bevy's default `ClearColor` (`bevy_camera::clear_color`):
  // Color::srgb_u8(43, 44, 47)
  ClearColor::{
    color: Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
  }
}

///|
fn clear_color_default_value() -> Color {
  ClearColor::default().color
}

///|
let clear_color_resource : Ref[@core.Resource[ClearColor]] = Ref::new(
  @core.Resource::new(),
)

///|
pub impl @app.Resource for ClearColor with resource() {
  clear_color_resource.val
}

///|
fn clear_color_current_value() -> Color {
  if clear_color_resource.val.get() is Some(clear_color) {
    clear_color.color
  } else {
    clear_color_default_value()
  }
}

///|
/// Mirrors Bevy's `ClearColorConfig` for per-camera clear behavior.
pub(all) enum ClearColorConfig {
  Default
  Custom(Color)
  None
}

///|
pub fn ClearColorConfig::default() -> ClearColorConfig {
  Default
}

///|
pub fn ClearColorConfig::resolve(self : ClearColorConfig) -> (Bool, Color) {
  match self {
    Default => (true, clear_color_current_value())
    Custom(color) => (true, color)
    None => (false, Color::new(0.0F, 0.0F, 0.0F, 0.0F))
  }
}

///|
pub struct CameraTargetInfo {
  physical_size : @math.IVec2
  scale_factor : Float
}

///|
pub fn CameraTargetInfo::new(
  physical_size : @math.IVec2,
  scale_factor : Float,
) -> CameraTargetInfo {
  CameraTargetInfo::{ physical_size, scale_factor }
}

///|
pub fn CameraTargetInfo::default() -> CameraTargetInfo {
  CameraTargetInfo::{
    physical_size: @math.IVec2::new(0, 0),
    scale_factor: 1.0F,
  }
}

///|
pub struct CameraComputedValues {
  target_info : CameraTargetInfo?
  old_viewport_size : @math.IVec2?
}

///|
pub fn CameraComputedValues::default() -> CameraComputedValues {
  CameraComputedValues::{ target_info: None, old_viewport_size: None }
}

///|
pub struct Camera {
  viewport : Viewport?
  order : Int
  is_active : Bool
  computed : CameraComputedValues
  clear_color : ClearColorConfig
}

///|
pub fn Camera::new(clear_color : Color) -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: CameraComputedValues::default(),
    clear_color: Custom(clear_color),
  }
}

///|
pub fn Camera::default() -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: CameraComputedValues::default(),
    clear_color: ClearColorConfig::default(),
  }
}

///|
pub fn Camera::with_order(self : Camera, order : Int) -> Camera {
  Camera::{ ..self, order, }
}

///|
pub fn Camera::with_viewport(self : Camera, viewport : Viewport) -> Camera {
  Camera::{ ..self, viewport: Some(viewport) }
}

///|
pub fn Camera::clear_viewport(self : Camera) -> Camera {
  Camera::{ ..self, viewport: None }
}

///|
pub fn Camera::with_clear_color(self : Camera, clear_color : Color) -> Camera {
  Camera::{ ..self, clear_color: Custom(clear_color) }
}

///|
pub fn Camera::with_clear_color_config(
  self : Camera,
  clear_color : ClearColorConfig,
) -> Camera {
  Camera::{ ..self, clear_color, }
}

///|
pub fn Camera::with_clear_color_none(self : Camera) -> Camera {
  Camera::{ ..self, clear_color: None }
}

///|
pub fn Camera::with_is_active(self : Camera, is_active : Bool) -> Camera {
  Camera::{ ..self, is_active, }
}

///|
pub fn Camera::to_logical(
  self : Camera,
  physical_size : @math.IVec2,
) -> @math.Vec2? {
  guard self.computed.target_info is Some(target_info) else { return None }
  let mut scale = target_info.scale_factor
  if scale <= 0.0F {
    scale = 1.0F
  }
  Some(
    @math.Vec2::new(
      Float::from_double(physical_size.x.to_double()) / scale,
      Float::from_double(physical_size.y.to_double()) / scale,
    ),
  )
}

///|
pub fn Camera::physical_target_size(self : Camera) -> @math.IVec2? {
  self.computed.target_info.map(fn(target_info) { target_info.physical_size })
}

///|
pub fn Camera::logical_target_size(self : Camera) -> @math.Vec2? {
  match self.physical_target_size() {
    Some(size) => self.to_logical(size)
    None => None
  }
}

///|
pub fn Camera::physical_viewport_size(self : Camera) -> @math.IVec2? {
  match self.viewport {
    Some(viewport) => Some(viewport.physical_size)
    None => self.physical_target_size()
  }
}

///|
pub fn Camera::logical_viewport_size(self : Camera) -> @math.Vec2? {
  match self.viewport {
    Some(viewport) => self.to_logical(viewport.physical_size)
    None => self.logical_target_size()
  }
}

///|
pub fn Camera::target_scaling_factor(self : Camera) -> Float? {
  self.computed.target_info.map(fn(target_info) { target_info.scale_factor })
}

///|
/// The projection parameters for an orthographic camera.
/// Stored inside `Projection` (mirrors Bevy's `Projection::Orthographic`).
pub struct OrthographicProjection {
  scale : Float
} derive(ToJson, FromJson)

///|
pub fn OrthographicProjection::new(scale : Float) -> OrthographicProjection {
  let safe = if scale == 0.0F { 1.0F } else { scale }
  OrthographicProjection::{ scale: safe }
}

///|
pub fn OrthographicProjection::default_2d() -> OrthographicProjection {
  OrthographicProjection::new(1.0F)
}

///|
pub fn OrthographicProjection::with_scale(
  self : OrthographicProjection,
  scale : Float,
) -> OrthographicProjection {
  self |> ignore
  OrthographicProjection::new(scale)
}

///|
/// Camera projection type (mirrors Bevy's `Projection` component).
pub(all) enum Projection {
  Orthographic(OrthographicProjection)
}

///|
pub fn Projection::orthographic_2d() -> Projection {
  Orthographic(OrthographicProjection::default_2d())
}

///|
/// Marker component that enables 2D camera semantics (mirrors Bevy's `Camera2d`).
pub struct Camera2d {}

///|
pub fn Camera2d::default() -> Camera2d {
  Camera2d::{  }
}

///|

///|
pub(all) enum RenderTarget {
  Screen
  Image(@asset.Handle[@asset.Image])
}

///|
pub struct ColorMaterialAsset {
  color : Color
  alpha_mode : AlphaMode2d
  texture : @asset.Handle[@asset.Image]?
  uv_offset : @math.Vec2
  uv_scale : @math.Vec2
}

///|
pub(all) enum AlphaMode2d {
  Opaque
  Mask(Float)
  Blend
} derive(ToJson, FromJson)

///|
pub fn ColorMaterialAsset::new(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture? : @asset.Handle[@asset.Image]? = None,
  uv_offset? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
  uv_scale? : @math.Vec2 = @math.Vec2::new(1.0F, 1.0F),
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ color, alpha_mode, texture, uv_offset, uv_scale }
}

///|
let color_material_assets : Ref[@asset.Assets[ColorMaterialAsset]] = Ref::new(
  @asset.Assets::new(),
)

///|
fn color_material_get(
  handle : @asset.Handle[ColorMaterialAsset],
) -> ColorMaterialAsset? {
  color_material_assets.val.get(handle)
}

///|
pub struct ColorMaterial {
  handle : @asset.Handle[ColorMaterialAsset]
}

///|
fn color_material_add(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture : @asset.Handle[@asset.Image]?,
  uv_offset : @math.Vec2,
  uv_scale : @math.Vec2,
) -> ColorMaterial {
  let handle = color_material_assets.val.add(
    ColorMaterialAsset::new(color, alpha_mode, texture~, uv_offset~, uv_scale~),
  )
  ColorMaterial::{ handle, }
}

///|
pub fn ColorMaterial::new(color : Color) -> ColorMaterial {
  color_material_add(
    color,
    AlphaMode2d::Blend,
    None,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
}

///|
pub fn ColorMaterial::from_image(
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterial {
  color_material_add(
    Color::white(),
    AlphaMode2d::Blend,
    Some(texture),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
}

///|
pub fn ColorMaterial::color(self : ColorMaterial) -> Color {
  match color_material_get(self.handle) {
    Some(mat) => mat.color
    None => Color::white()
  }
}

///|
pub fn ColorMaterial::new_with_alpha_mode(
  color : Color,
  alpha_mode : AlphaMode2d,
) -> ColorMaterial {
  color_material_add(
    color,
    alpha_mode,
    None,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
}

///|
pub fn ColorMaterial::with_alpha_mode(
  self : ColorMaterial,
  alpha_mode : AlphaMode2d,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    alpha_mode,
    self.texture(),
    self.uv_offset(),
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::alpha_mode(self : ColorMaterial) -> AlphaMode2d {
  match color_material_get(self.handle) {
    Some(mat) => mat.alpha_mode
    None => AlphaMode2d::Blend
  }
}

///|
pub fn ColorMaterial::texture(
  self : ColorMaterial,
) -> @asset.Handle[@asset.Image]? {
  match color_material_get(self.handle) {
    Some(mat) => mat.texture
    None => None
  }
}

///|
pub fn ColorMaterial::uv_offset(self : ColorMaterial) -> @math.Vec2 {
  match color_material_get(self.handle) {
    Some(mat) => mat.uv_offset
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}

///|
pub fn ColorMaterial::uv_scale(self : ColorMaterial) -> @math.Vec2 {
  match color_material_get(self.handle) {
    Some(mat) => mat.uv_scale
    None => @math.Vec2::new(1.0F, 1.0F)
  }
}

///|
pub fn ColorMaterial::with_texture(
  self : ColorMaterial,
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    Some(texture),
    self.uv_offset(),
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::with_uv_offset(
  self : ColorMaterial,
  uv_offset : @math.Vec2,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    self.texture(),
    uv_offset,
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::with_uv_scale(
  self : ColorMaterial,
  uv_scale : @math.Vec2,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    self.texture(),
    self.uv_offset(),
    uv_scale,
  )
}

///|
pub(open) trait Material2d {
  color(self : Self) -> Color
  alpha_mode(self : Self) -> AlphaMode2d
  texture(self : Self) -> @asset.Handle[@asset.Image]?
  uv_offset(self : Self) -> @math.Vec2
  uv_scale(self : Self) -> @math.Vec2
}

///|
pub impl Material2d for ColorMaterial with color(self) {
  ColorMaterial::color(self)
}

///|
pub impl Material2d for ColorMaterial with alpha_mode(self) {
  ColorMaterial::alpha_mode(self)
}

///|
pub impl Material2d for ColorMaterial with texture(self) {
  ColorMaterial::texture(self)
}

///|
pub impl Material2d for ColorMaterial with uv_offset(self) {
  ColorMaterial::uv_offset(self)
}

///|
pub impl Material2d for ColorMaterial with uv_scale(self) {
  ColorMaterial::uv_scale(self)
}

///|
pub struct Material2dPlugin[M] {
  marker : M?
}

///|
pub fn[M] Material2dPlugin::default() -> Material2dPlugin[M] {
  Material2dPlugin::{ marker: None }
}

///|
pub fn[W, M] material2d_plugin(_plugin : Material2dPlugin[M]) -> @app.Plugin[W] {
  fn(app : @app.App[W]) -> @app.App[W] { app }
}

///|
pub struct MeshMaterial2d {
  handle : @asset.Handle[ColorMaterialAsset]
}

///|
pub fn MeshMaterial2d::new(
  material : @asset.Handle[ColorMaterialAsset],
) -> MeshMaterial2d {
  MeshMaterial2d::{ handle: material }
}

///|
pub fn MeshMaterial2d::from_color_material(
  material : ColorMaterial,
) -> MeshMaterial2d {
  MeshMaterial2d::{ handle: material.handle }
}

///|
pub fn MeshMaterial2d::to_color_material(
  self : MeshMaterial2d,
) -> ColorMaterial {
  ColorMaterial::{ handle: self.handle }
}

///|
pub fn MeshMaterial2d::with_alpha_mode(
  self : MeshMaterial2d,
  alpha_mode : AlphaMode2d,
) -> MeshMaterial2d {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_alpha_mode(alpha_mode),
  )
}

///|
pub fn MeshMaterial2d::with_texture(
  self : MeshMaterial2d,
  texture : @asset.Handle[@asset.Image],
) -> MeshMaterial2d {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_texture(texture),
  )
}

///|
pub fn MeshMaterial2d::with_uv_offset(
  self : MeshMaterial2d,
  uv_offset : @math.Vec2,
) -> MeshMaterial2d {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_uv_offset(uv_offset),
  )
}

///|
pub fn MeshMaterial2d::with_uv_scale(
  self : MeshMaterial2d,
  uv_scale : @math.Vec2,
) -> MeshMaterial2d {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_uv_scale(uv_scale),
  )
}

///|
pub impl Material2d for MeshMaterial2d with color(self) {
  self.to_color_material().color()
}

///|
pub impl Material2d for MeshMaterial2d with alpha_mode(self) {
  self.to_color_material().alpha_mode()
}

///|
pub impl Material2d for MeshMaterial2d with texture(self) {
  self.to_color_material().texture()
}

///|
pub impl Material2d for MeshMaterial2d with uv_offset(self) {
  self.to_color_material().uv_offset()
}

///|
pub impl Material2d for MeshMaterial2d with uv_scale(self) {
  self.to_color_material().uv_scale()
}

///|
pub struct Capsule2d {
  radius : Float
  half_length : Float
  segments : Int
}

///|
pub fn Capsule2d::new(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Capsule2d {
  Capsule2d::{ radius, half_length, segments }
}

///|
pub fn Capsule2d::default() -> Capsule2d {
  Capsule2d::new(0.5F, 0.5F, 16)
}

///|
pub struct Capsule2dRing {
  outer_shape : Capsule2d
  inner_shape : Capsule2d
}

///|
pub fn Capsule2dRing::new(
  outer_shape : Capsule2d,
  inner_shape : Capsule2d,
) -> Capsule2dRing {
  Capsule2dRing::{ outer_shape, inner_shape }
}

///|
pub struct Rectangle {
  half_size : @math.Vec2
}

///|
pub fn Rectangle::new(width : Float, height : Float) -> Rectangle {
  Rectangle::{ half_size: @math.Vec2::new(width / 2.0F, height / 2.0F) }
}

///|
pub fn Rectangle::from_size(size : @math.Vec2) -> Rectangle {
  Rectangle::{ half_size: @math.Vec2::new(size.x / 2.0F, size.y / 2.0F) }
}

///|
pub fn Rectangle::default() -> Rectangle {
  Rectangle::{ half_size: @math.Vec2::new(0.5F, 0.5F) }
}

///|
pub struct RectangleRing {
  outer_shape : Rectangle
  inner_shape : Rectangle
}

///|
pub fn RectangleRing::new(
  outer_shape : Rectangle,
  inner_shape : Rectangle,
) -> RectangleRing {
  RectangleRing::{ outer_shape, inner_shape }
}

///|
pub struct Circle {
  radius : Float
  vertices : Int
}

///|
pub fn Circle::new(radius : Float) -> Circle {
  Circle::{ radius, vertices: 32 }
}

///|
pub fn Circle::with_vertices(self : Circle, vertices : Int) -> Circle {
  Circle::{ ..self, vertices, }
}

///|
pub fn Circle::default() -> Circle {
  Circle::new(0.5F)
}

///|
pub struct Ellipse {
  half_size : @math.Vec2
  vertices : Int
}

///|
pub fn Ellipse::new(half_width : Float, half_height : Float) -> Ellipse {
  Ellipse::{ half_size: @math.Vec2::new(half_width, half_height), vertices: 32 }
}

///|
pub fn Ellipse::with_vertices(self : Ellipse, vertices : Int) -> Ellipse {
  Ellipse::{ ..self, vertices, }
}

///|
pub fn Ellipse::default() -> Ellipse {
  Ellipse::new(0.5F, 0.25F)
}

///|
pub struct EllipseRing {
  outer_shape : Ellipse
  inner_shape : Ellipse
}

///|
pub fn EllipseRing::new(
  outer_shape : Ellipse,
  inner_shape : Ellipse,
) -> EllipseRing {
  EllipseRing::{ outer_shape, inner_shape }
}

///|
pub struct Annulus {
  inner_radius : Float
  outer_radius : Float
  vertices : Int
}

///|
pub fn Annulus::new(inner_radius : Float, outer_radius : Float) -> Annulus {
  Annulus::{ inner_radius, outer_radius, vertices: 48 }
}

///|
pub fn Annulus::with_vertices(self : Annulus, vertices : Int) -> Annulus {
  Annulus::{ ..self, vertices, }
}

///|
pub fn Annulus::default() -> Annulus {
  Annulus::new(0.25F, 0.5F)
}

///|
pub struct Ring2d {
  outer_radius : Float
  inner_radius : Float
  vertices : Int
}

///|
pub fn Ring2d::new(outer_radius : Float, inner_radius : Float) -> Ring2d {
  Ring2d::{ outer_radius, inner_radius, vertices: 48 }
}

///|
pub fn Ring2d::with_vertices(self : Ring2d, vertices : Int) -> Ring2d {
  Ring2d::{ ..self, vertices, }
}

///|
pub fn Ring2d::default() -> Ring2d {
  Ring2d::new(0.5F, 0.25F)
}

///|
pub struct Rhombus {
  half_diagonal : @math.Vec2
}

///|
pub fn Rhombus::new(width : Float, height : Float) -> Rhombus {
  Rhombus::{ half_diagonal: @math.Vec2::new(width / 2.0F, height / 2.0F) }
}

///|
pub fn Rhombus::default() -> Rhombus {
  Rhombus::new(1.0F, 1.0F)
}

///|
pub struct RhombusRing {
  outer_shape : Rhombus
  inner_shape : Rhombus
}

///|
pub fn RhombusRing::new(
  outer_shape : Rhombus,
  inner_shape : Rhombus,
) -> RhombusRing {
  RhombusRing::{ outer_shape, inner_shape }
}

///|
pub struct RegularPolygon {
  radius : Float
  sides : Int
}

///|
pub fn RegularPolygon::new(radius : Float, sides : Int) -> RegularPolygon {
  RegularPolygon::{ radius, sides }
}

///|
pub fn RegularPolygon::default() -> RegularPolygon {
  RegularPolygon::new(0.5F, 6)
}

///|
pub struct RegularPolygonRing {
  outer_shape : RegularPolygon
  inner_shape : RegularPolygon
}

///|
pub fn RegularPolygonRing::new(
  outer_shape : RegularPolygon,
  inner_shape : RegularPolygon,
) -> RegularPolygonRing {
  RegularPolygonRing::{ outer_shape, inner_shape }
}

///|
pub struct Triangle2d {
  a : @math.Vec2
  b : @math.Vec2
  c : @math.Vec2
}

///|
pub fn Triangle2d::new(
  a : @math.Vec2,
  b : @math.Vec2,
  c : @math.Vec2,
) -> Triangle2d {
  Triangle2d::{ a, b, c }
}

///|
pub fn Triangle2d::default() -> Triangle2d {
  Triangle2d::{
    a: @math.Vec2::new(0.0F, 0.5F),
    b: @math.Vec2::new(-0.5F, -0.5F),
    c: @math.Vec2::new(0.5F, -0.5F),
  }
}

///|
pub struct Triangle2dRing {
  outer_shape : Triangle2d
  inner_shape : Triangle2d
}

///|
pub fn Triangle2dRing::new(
  outer_shape : Triangle2d,
  inner_shape : Triangle2d,
) -> Triangle2dRing {
  Triangle2dRing::{ outer_shape, inner_shape }
}

///|
pub struct Segment2d {
  start : @math.Vec2
  end : @math.Vec2
  half_thickness : Float
}

///|
pub fn Segment2d::new(start : @math.Vec2, end : @math.Vec2) -> Segment2d {
  Segment2d::{ start, end, half_thickness: 2.5F }
}

///|
pub fn Segment2d::with_half_thickness(
  self : Segment2d,
  half_thickness : Float,
) -> Segment2d {
  Segment2d::{ ..self, half_thickness, }
}

///|
pub struct Polyline2d {
  points : Array[@math.Vec2]
  half_thickness : Float
}

///|
pub fn Polyline2d::new(points : Array[@math.Vec2]) -> Polyline2d {
  Polyline2d::{ points, half_thickness: 2.5F }
}

///|
pub fn Polyline2d::with_half_thickness(
  self : Polyline2d,
  half_thickness : Float,
) -> Polyline2d {
  Polyline2d::{ ..self, half_thickness, }
}

///|
pub struct CircularSector {
  radius : Float
  half_angle : Float
  vertices : Int
  uv_mode : CircularMeshUvMode
}

///|
pub(all) enum CircularMeshUvMode {
  Mask(Float)
}

///|
pub fn CircularSector::new(
  radius : Float,
  half_angle : Float,
) -> CircularSector {
  CircularSector::{ radius, half_angle, vertices: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSector::from_turns(
  radius : Float,
  fraction : Float,
) -> CircularSector {
  CircularSector::new(radius, fraction * @math.pi_half() * 2.0F)
}

///|
pub fn CircularSector::with_vertices(
  self : CircularSector,
  vertices : Int,
) -> CircularSector {
  CircularSector::{ ..self, vertices, }
}

///|
pub fn CircularSector::with_uv_mode(
  self : CircularSector,
  uv_mode : CircularMeshUvMode,
) -> CircularSector {
  CircularSector::{ ..self, uv_mode, }
}

///|
pub fn CircularSector::with_uv_mask_angle(
  self : CircularSector,
  angle : Float,
) -> CircularSector {
  self.with_uv_mode(Mask(angle))
}

///|
pub fn CircularSector::half_angle(self : CircularSector) -> Float {
  self.half_angle
}

///|
pub fn CircularSector::angle(self : CircularSector) -> Float {
  self.half_angle * 2.0F
}

///|
pub fn CircularSector::default() -> CircularSector {
  CircularSector::new(0.5F, @math.pi_half() * 2.0F / 3.0F)
}

///|
pub struct CircularSectorRing {
  outer_shape : CircularSector
  inner_shape : CircularSector
}

///|
pub fn CircularSectorRing::new(
  outer_shape : CircularSector,
  inner_shape : CircularSector,
) -> CircularSectorRing {
  CircularSectorRing::{ outer_shape, inner_shape }
}

///|
pub struct CircularSegment {
  radius : Float
  half_angle : Float
  vertices : Int
  uv_mode : CircularMeshUvMode
}

///|
pub fn CircularSegment::new(
  radius : Float,
  half_angle : Float,
) -> CircularSegment {
  CircularSegment::{ radius, half_angle, vertices: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSegment::from_turns(
  radius : Float,
  fraction : Float,
) -> CircularSegment {
  CircularSegment::new(radius, fraction * @math.pi_half() * 2.0F)
}

///|
pub fn CircularSegment::with_vertices(
  self : CircularSegment,
  vertices : Int,
) -> CircularSegment {
  CircularSegment::{ ..self, vertices, }
}

///|
pub fn CircularSegment::with_uv_mode(
  self : CircularSegment,
  uv_mode : CircularMeshUvMode,
) -> CircularSegment {
  CircularSegment::{ ..self, uv_mode, }
}

///|
pub fn CircularSegment::with_uv_mask_angle(
  self : CircularSegment,
  angle : Float,
) -> CircularSegment {
  self.with_uv_mode(Mask(angle))
}

///|
pub fn CircularSegment::half_angle(self : CircularSegment) -> Float {
  self.half_angle
}

///|
pub fn CircularSegment::angle(self : CircularSegment) -> Float {
  self.half_angle * 2.0F
}

///|
pub fn CircularSegment::default() -> CircularSegment {
  CircularSegment::new(0.5F, @math.pi_half() * 2.0F / 3.0F)
}

///|
pub struct CircularSegmentRing {
  outer_shape : CircularSegment
  inner_shape : CircularSegment
}

///|
pub fn CircularSegmentRing::new(
  outer_shape : CircularSegment,
  inner_shape : CircularSegment,
) -> CircularSegmentRing {
  CircularSegmentRing::{ outer_shape, inner_shape }
}

///|
fn ring_vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn ring_vec2_sub(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x - b.x, a.y - b.y)
}

///|
fn ring_vec2_mul_scalar(v : @math.Vec2, scalar : Float) -> @math.Vec2 {
  @math.Vec2::new(v.x * scalar, v.y * scalar)
}

///|
fn ring_vec2_dot(a : @math.Vec2, b : @math.Vec2) -> Float {
  a.x * b.x + a.y * b.y
}

///|
fn ring_vec2_normalize_or_zero(v : @math.Vec2) -> @math.Vec2 {
  let len_sq = ring_vec2_dot(v, v)
  if len_sq <= 1.0e-12F {
    return @math.Vec2::new(0.0F, 0.0F)
  }
  let inv_len = 1.0F / @math.sqrt(len_sq)
  ring_vec2_mul_scalar(v, inv_len)
}

///|
fn ring_safe_acos(value : Float) -> Float {
  let clamped = shape_clamp_float(value, -1.0F, 1.0F)
  let y_sq = 1.0F - clamped * clamped
  let y = if y_sq <= 0.0F { 0.0F } else { @math.sqrt(y_sq) }
  @math.atan2(y, clamped)
}

///|
fn triangle_inset_point(
  a : @math.Vec2,
  b : @math.Vec2,
  c : @math.Vec2,
  distance : Float,
) -> @math.Vec2 {
  let unit_ab = ring_vec2_normalize_or_zero(ring_vec2_sub(b, a))
  let unit_ac = ring_vec2_normalize_or_zero(ring_vec2_sub(c, a))
  let half_angle = ring_safe_acos(ring_vec2_dot(unit_ab, unit_ac)) / 2.0F
  let direction = ring_vec2_normalize_or_zero(
    ring_vec2_mul_scalar(ring_vec2_add(unit_ab, unit_ac), 0.5F),
  )
  let sin_half_angle = @math.sin(half_angle)
  if shape_abs_float(sin_half_angle) <= 1.0e-6F {
    return a
  }
  ring_vec2_add(a, ring_vec2_mul_scalar(direction, distance / sin_half_angle))
}

///|
pub fn Circle::to_ring(self : Circle, thickness : Float) -> Ring2d {
  Ring2d::new(self.radius, self.radius - thickness).with_vertices(self.vertices)
}

///|
pub fn CircularSegment::to_ring(
  self : CircularSegment,
  distance : Float,
) -> CircularSegmentRing {
  let old_radius = shape_safe_positive(shape_abs_float(self.radius), 0.5F)
  let old_half_angle = arc_safe_half_angle(self.half_angle)
  let old_apothem = circular_segment_apothem(old_radius, old_half_angle)
  let radius = old_radius - distance
  let apothem = old_apothem + distance
  let safe_radius = if radius <= 1.0e-6F { 1.0e-6F } else { radius }
  let half_angle = ring_safe_acos(apothem / safe_radius)
  let inner = CircularSegment::new(safe_radius, half_angle)
    .with_vertices(self.vertices)
    .with_uv_mode(self.uv_mode)
  CircularSegmentRing::new(self, inner)
}

///|
pub fn Capsule2d::to_ring(self : Capsule2d, distance : Float) -> Capsule2dRing {
  let inner = Capsule2d::{
    radius: self.radius - distance,
    half_length: self.half_length,
    segments: self.segments,
  }
  Capsule2dRing::new(self, inner)
}

///|
pub fn Rhombus::to_ring(self : Rhombus, distance : Float) -> RhombusRing {
  let half_width = self.half_diagonal.x
  let half_height = self.half_diagonal.y
  let angle = @math.atan2(half_height, half_width)
  let sin_angle = @math.sin(angle)
  let cos_angle = @math.cos(angle)
  let x_offset = if shape_abs_float(sin_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / sin_angle
  }
  let y_offset = if shape_abs_float(cos_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / cos_angle
  }
  let inner = Rhombus::new(
    half_width * 2.0F - x_offset * 2.0F,
    half_height * 2.0F - y_offset * 2.0F,
  )
  RhombusRing::new(self, inner)
}

///|
pub fn Rectangle::to_ring(self : Rectangle, distance : Float) -> RectangleRing {
  let inner = Rectangle::new(
    self.half_size.x * 2.0F - distance * 2.0F,
    self.half_size.y * 2.0F - distance * 2.0F,
  )
  RectangleRing::new(self, inner)
}

///|
pub fn RegularPolygon::to_ring(
  self : RegularPolygon,
  distance : Float,
) -> RegularPolygonRing {
  let sides = if self.sides < 3 { 3 } else { self.sides }
  let pi = @math.pi_half() * 2.0F
  let half_angle = pi *
    Float::from_double((sides - 2).to_double()) /
    Float::from_double((2 * sides).to_double())
  let sin_half_angle = @math.sin(half_angle)
  let offset = if shape_abs_float(sin_half_angle) <= 1.0e-6F {
    0.0F
  } else {
    distance / sin_half_angle
  }
  let inner = RegularPolygon::new(self.radius - offset, self.sides)
  RegularPolygonRing::new(self, inner)
}

///|
pub fn Triangle2d::to_ring(
  self : Triangle2d,
  distance : Float,
) -> Triangle2dRing {
  let inner = Triangle2d::new(
    triangle_inset_point(self.a, self.b, self.c, distance),
    triangle_inset_point(self.b, self.c, self.a, distance),
    triangle_inset_point(self.c, self.a, self.b, distance),
  )
  Triangle2dRing::new(self, inner)
}

///|
pub struct Mesh2d {
  mesh : @asset.Handle[@mesh.Mesh]
}

///|
let mesh_assets : Ref[@asset.Assets[@mesh.Mesh]] = Ref::new(
  @asset.Assets::new(),
)

///|
let mesh_upload_cache : Ref[@hashmap.HashMap[Int, Int]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
fn mesh_upload_cache_sync_with_asset_events() -> Unit {
  for event in mesh_assets.val.drain_events() {
    match event {
      @asset.AssetEvent::Modified(handle) =>
        mesh_upload_cache.val.remove(handle.id())
      @asset.AssetEvent::Removed(handle) =>
        mesh_upload_cache.val.remove(handle.id())
      _ => ()
    }
  }
}

///|
fn mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_assets.val.add(mesh)
}

///|
pub fn render_mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_asset_add(mesh)
}

///|
fn mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_assets.val.get(handle)
}

///|
pub fn render_mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_asset_get(handle)
}

///|
fn mesh_asset_set(
  handle : @asset.Handle[@mesh.Mesh],
  mesh : @mesh.Mesh,
) -> Bool {
  mesh_assets.val.set(handle, mesh)
}

///|
pub fn render_mesh_asset_set(
  handle : @asset.Handle[@mesh.Mesh],
  mesh : @mesh.Mesh,
) -> Bool {
  mesh_asset_set(handle, mesh)
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  mesh_upload_cache_sync_with_asset_events()
  let mesh_handle_id = mesh.id()
  if mesh_upload_cache.val.get(mesh_handle_id) is Some(mesh_id) {
    return mesh_id
  }
  let uploaded_mesh_id = match mesh_asset_get(mesh) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry2d) =>
          match geometry2d.encode_triangle_interleaved_xy_uv_rgba_csv() {
            Some(vertices_csv) =>
              @window.host_gpu_create_mesh_triangles(
                vertices_xy_csv=vertices_csv,
              )
            None => {
              let message = match geometry2d.validate() {
                Some(err) =>
                  "Mesh2dGeometry validation failed: " + err.to_string()
                None => "Mesh2dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
        @mesh.MeshGeometry::Geometry3d(geometry3d) =>
          match geometry3d.encode_interleaved_xyz_uv_rgba_csv() {
            Some(vertices_csv) =>
              @window.host_gpu_create_mesh3d(
                vertices_xyzuvrgba_csv=vertices_csv,
                primitive_topology=geometry3d.primitive_topology().to_int(),
              )
            None => {
              let message = match geometry3d.validate() {
                Some(err) =>
                  "Mesh3dGeometry validation failed: " + err.to_string()
                None => "Mesh3dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
      }
    None => {
      @window.host_debug_string(
        value="Mesh2d upload failed: mesh handle not found",
      )
      0
    }
  }
  if uploaded_mesh_id > 0 {
    mesh_upload_cache.val.set(mesh_handle_id, uploaded_mesh_id)
  }
  uploaded_mesh_id
}

///|
pub fn Mesh2d::new(mesh : @asset.Handle[@mesh.Mesh]) -> Mesh2d {
  Mesh2d::{ mesh, }
}

///|
fn rectangle_to_mesh2d_geometry(rectangle : Rectangle) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(rectangle.half_size.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(rectangle.half_size.y), 0.5F)
  let positions = shape_perimeter_rectangle(@math.Vec2::new(hx, hy))
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn rectangle_ring_to_mesh2d_geometry(
  ring : RectangleRing,
) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_size.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_size.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_rectangle(@math.Vec2::new(outer_hx, outer_hy)),
    shape_perimeter_rectangle(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
    ),
  )
}

///|
fn shape_abs_float(v : Float) -> Float {
  if v < 0.0F {
    -v
  } else {
    v
  }
}

///|
fn shape_safe_positive(v : Float, fallback : Float) -> Float {
  if v <= 0.0F {
    fallback
  } else {
    v
  }
}

///|
fn shape_safe_segments(v : Int, minimum : Int) -> Int {
  if v < minimum {
    minimum
  } else {
    v
  }
}

///|
fn shape_tau() -> Float {
  @math.pi_half() * 4.0F
}

///|
fn shape_positions_to_uvs(positions : Array[@math.Vec2]) -> Array[@math.Vec2] {
  if positions.length() == 0 {
    return []
  }
  let mut min_x = positions[0].x
  let mut max_x = positions[0].x
  let mut min_y = positions[0].y
  let mut max_y = positions[0].y
  for p in positions {
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  let dx = if max_x - min_x == 0.0F { 1.0F } else { max_x - min_x }
  let dy = if max_y - min_y == 0.0F { 1.0F } else { max_y - min_y }
  let uvs : Array[@math.Vec2] = []
  for p in positions {
    let u = (p.x - min_x) / dx
    let v = (p.y - min_y) / dy
    uvs.push(@math.Vec2::new(u, v))
  }
  uvs
}

///|
fn shape_geometry_from_nonindexed_positions(
  positions : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let safe_positions : Array[@math.Vec2] = []
  if positions.length() >= 3 {
    for p in positions {
      safe_positions.push(p)
    }
  } else {
    safe_positions.push(@math.Vec2::new(-0.5F, -0.5F))
    safe_positions.push(@math.Vec2::new(0.5F, -0.5F))
    safe_positions.push(@math.Vec2::new(0.0F, 0.5F))
  }
  let uvs = shape_positions_to_uvs(safe_positions)
  @mesh.Mesh2dGeometry::new(safe_positions, uvs, None)
}

///|
fn shape_triangulate_fan(perimeter : Array[@math.Vec2]) -> Array[@math.Vec2] {
  let out : Array[@math.Vec2] = []
  let n = perimeter.length()
  if n < 3 {
    return out
  }
  let pivot = perimeter[0]
  for i in 1..<(n - 1) {
    out.push(pivot)
    out.push(perimeter[i])
    out.push(perimeter[i + 1])
  }
  out
}

///|
fn shape_perimeter_circle(radius : Float, segments : Int) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<segments {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = t * tau
    perimeter.push(
      @math.Vec2::new(@math.cos(theta) * radius, @math.sin(theta) * radius),
    )
  }
  perimeter
}

///|
fn shape_perimeter_ellipse(
  half_size : @math.Vec2,
  segments : Int,
) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<segments {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = t * tau
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * half_size.x,
        @math.sin(theta) * half_size.y,
      ),
    )
  }
  perimeter
}

///|
fn shape_perimeter_rectangle(half_size : @math.Vec2) -> Array[@math.Vec2] {
  [
    @math.Vec2::new(-half_size.x, -half_size.y),
    @math.Vec2::new(half_size.x, -half_size.y),
    @math.Vec2::new(half_size.x, half_size.y),
    @math.Vec2::new(-half_size.x, half_size.y),
  ]
}

///|
fn shape_perimeter_rhombus(half_diagonal : @math.Vec2) -> Array[@math.Vec2] {
  [
    @math.Vec2::new(0.0F, half_diagonal.y),
    @math.Vec2::new(half_diagonal.x, 0.0F),
    @math.Vec2::new(0.0F, -half_diagonal.y),
    @math.Vec2::new(-half_diagonal.x, 0.0F),
  ]
}

///|
fn shape_perimeter_triangle(triangle : Triangle2d) -> Array[@math.Vec2] {
  [triangle.a, triangle.b, triangle.c]
}

///|
fn shape_perimeter_capsule(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Array[@math.Vec2] {
  let mut safe_segments = segments
  if safe_segments < 4 {
    safe_segments = 4
  }
  let pi = @math.pi_half() * 2.0F
  let perimeter : Array[@math.Vec2] = []
  // Top arc: right -> left.
  for i in 0..<(safe_segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(safe_segments.to_double())
    let theta = t * pi
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * radius,
        @math.sin(theta) * radius + half_length,
      ),
    )
  }
  // Left side down to bottom-left.
  perimeter.push(@math.Vec2::new(-radius, -half_length))
  // Bottom arc: left -> right, skipping duplicated first point.
  for i in 1..<(safe_segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(safe_segments.to_double())
    let theta = pi + t * pi
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * radius,
        @math.sin(theta) * radius - half_length,
      ),
    )
  }
  perimeter
}

///|
fn shape_arc_points(
  radius : Float,
  half_angle : Float,
  count : Int,
) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  for i in 0..<count {
    let angle = arc_angle_from_index(first_angle, last_angle, i, count)
    points.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
  }
  points
}

///|
fn shape_ring_geometry_from_closed_loops(
  outer_loop : Array[@math.Vec2],
  inner_loop : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let n = outer_loop.length()
  if n < 3 || inner_loop.length() != n {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<n {
    let j = (i + 1) % n
    let o0 = outer_loop[i]
    let o1 = outer_loop[j]
    let i0 = inner_loop[i]
    let i1 = inner_loop[j]
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn shape_ring_geometry_from_open_loops(
  outer_loop : Array[@math.Vec2],
  inner_loop : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let n = outer_loop.length()
  if n < 2 || inner_loop.length() != n {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<(n - 1) {
    let o0 = outer_loop[i]
    let o1 = outer_loop[i + 1]
    let i0 = inner_loop[i]
    let i1 = inner_loop[i + 1]
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn circle_to_mesh2d_geometry(circle : Circle) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(circle.radius), 0.5F)
  let segments = shape_safe_segments(circle.vertices, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(shape_perimeter_circle(radius, segments)),
  )
}

///|
fn ellipse_to_mesh2d_geometry(ellipse : Ellipse) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(ellipse.half_size.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(ellipse.half_size.y), 0.5F)
  let segments = shape_safe_segments(ellipse.vertices, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(
      shape_perimeter_ellipse(@math.Vec2::new(hx, hy), segments),
    ),
  )
}

///|
fn annulus_to_mesh2d_geometry(annulus : Annulus) -> @mesh.Mesh2dGeometry {
  let mut inner = shape_abs_float(annulus.inner_radius)
  let mut outer = shape_abs_float(annulus.outer_radius)
  if outer < inner {
    let pair = swap_float_pair(inner, outer)
    inner = pair.0
    outer = pair.1
  }
  outer = shape_safe_positive(outer, 0.5F)
  if inner >= outer {
    inner = outer * 0.5F
  }
  let segments = shape_safe_segments(annulus.vertices, 3)
  let tau = shape_tau()
  let triangles : Array[@math.Vec2] = []
  for i in 0..<segments {
    let t0 = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let t1 = Float::from_double((i + 1).to_double()) /
      Float::from_double(segments.to_double())
    let theta0 = t0 * tau
    let theta1 = t1 * tau
    let o0 = @math.Vec2::new(
      @math.cos(theta0) * outer,
      @math.sin(theta0) * outer,
    )
    let o1 = @math.Vec2::new(
      @math.cos(theta1) * outer,
      @math.sin(theta1) * outer,
    )
    let i0 = @math.Vec2::new(
      @math.cos(theta0) * inner,
      @math.sin(theta0) * inner,
    )
    let i1 = @math.Vec2::new(
      @math.cos(theta1) * inner,
      @math.sin(theta1) * inner,
    )
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn ring_to_mesh2d_geometry(ring : Ring2d) -> @mesh.Mesh2dGeometry {
  annulus_to_mesh2d_geometry(
    Annulus::new(ring.inner_radius, ring.outer_radius).with_vertices(
      ring.vertices,
    ),
  )
}

///|
fn circular_sector_ring_to_mesh2d_geometry(
  ring : CircularSectorRing,
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half_angle = arc_safe_half_angle(ring.outer_shape.half_angle)
  let inner_half_angle = arc_safe_half_angle(ring.inner_shape.half_angle)
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 2)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 2)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_open_loops(
    shape_arc_points(outer_radius, outer_half_angle, count),
    shape_arc_points(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half_angle,
      count,
    ),
  )
}

///|
fn circular_segment_ring_to_mesh2d_geometry(
  ring : CircularSegmentRing,
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half_angle = arc_safe_half_angle(ring.outer_shape.half_angle)
  let inner_half_angle = arc_safe_half_angle(ring.inner_shape.half_angle)
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 2)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 2)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_closed_loops(
    shape_arc_points(outer_radius, outer_half_angle, count),
    shape_arc_points(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half_angle,
      count,
    ),
  )
}

///|
fn ellipse_ring_to_mesh2d_geometry(ring : EllipseRing) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_size.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_size.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 3)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 3)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_ellipse(@math.Vec2::new(outer_hx, outer_hy), count),
    shape_perimeter_ellipse(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
      count,
    ),
  )
}

///|
fn rhombus_to_mesh2d_geometry(rhombus : Rhombus) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.y), 0.5F)
  let perimeter = shape_perimeter_rhombus(@math.Vec2::new(hx, hy))
  shape_geometry_from_nonindexed_positions(shape_triangulate_fan(perimeter))
}

///|
fn rhombus_ring_to_mesh2d_geometry(ring : RhombusRing) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_diagonal.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_diagonal.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_diagonal.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_diagonal.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_rhombus(@math.Vec2::new(outer_hx, outer_hy)),
    shape_perimeter_rhombus(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
    ),
  )
}

///|
fn shape_perimeter_regular_polygon(
  radius : Float,
  sides : Int,
) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<sides {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(sides.to_double())
    let theta = t * tau + @math.pi_half()
    perimeter.push(
      @math.Vec2::new(@math.cos(theta) * radius, @math.sin(theta) * radius),
    )
  }
  perimeter
}

///|
fn regular_polygon_to_mesh2d_geometry(
  polygon : RegularPolygon,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(polygon.radius), 0.5F)
  let sides = shape_safe_segments(polygon.sides, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(shape_perimeter_regular_polygon(radius, sides)),
  )
}

///|
fn regular_polygon_ring_to_mesh2d_geometry(
  ring : RegularPolygonRing,
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_sides = shape_safe_segments(ring.outer_shape.sides, 3)
  let inner_sides = shape_safe_segments(ring.inner_shape.sides, 3)
  let sides = if outer_sides < inner_sides { outer_sides } else { inner_sides }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_regular_polygon(outer_radius, sides),
    shape_perimeter_regular_polygon(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      sides,
    ),
  )
}

///|
fn triangle_to_mesh2d_geometry(triangle : Triangle2d) -> @mesh.Mesh2dGeometry {
  shape_geometry_from_nonindexed_positions(shape_perimeter_triangle(triangle))
}

///|
fn triangle_ring_to_mesh2d_geometry(
  ring : Triangle2dRing,
) -> @mesh.Mesh2dGeometry {
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_triangle(ring.outer_shape),
    shape_perimeter_triangle(ring.inner_shape),
  )
}

///|
fn shape_segment_triangles(
  start : @math.Vec2,
  end : @math.Vec2,
  half_thickness : Float,
) -> Array[@math.Vec2] {
  let triangles : Array[@math.Vec2] = []
  let thickness = shape_safe_positive(shape_abs_float(half_thickness), 0.5F)
  let dx = end.x - start.x
  let dy = end.y - start.y
  let len = @math.sqrt(dx * dx + dy * dy)
  if len <= 0.0001F {
    let p0 = @math.Vec2::new(start.x - thickness, start.y - thickness)
    let p1 = @math.Vec2::new(start.x + thickness, start.y - thickness)
    let p2 = @math.Vec2::new(start.x + thickness, start.y + thickness)
    let p3 = @math.Vec2::new(start.x - thickness, start.y + thickness)
    triangles.push(p0)
    triangles.push(p1)
    triangles.push(p2)
    triangles.push(p0)
    triangles.push(p2)
    triangles.push(p3)
    return triangles
  }
  let nx = -dy / len * thickness
  let ny = dx / len * thickness
  let p0 = @math.Vec2::new(start.x + nx, start.y + ny)
  let p1 = @math.Vec2::new(end.x + nx, end.y + ny)
  let p2 = @math.Vec2::new(end.x - nx, end.y - ny)
  let p3 = @math.Vec2::new(start.x - nx, start.y - ny)
  triangles.push(p0)
  triangles.push(p1)
  triangles.push(p2)
  triangles.push(p0)
  triangles.push(p2)
  triangles.push(p3)
  triangles
}

///|
fn segment_to_mesh2d_geometry(segment : Segment2d) -> @mesh.Mesh2dGeometry {
  shape_geometry_from_nonindexed_positions(
    shape_segment_triangles(segment.start, segment.end, segment.half_thickness),
  )
}

///|
fn polyline_to_mesh2d_geometry(polyline : Polyline2d) -> @mesh.Mesh2dGeometry {
  let points = polyline.points
  if points.length() < 2 {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<(points.length() - 1) {
    let part = shape_segment_triangles(
      points[i],
      points[i + 1],
      polyline.half_thickness,
    )
    for p in part {
      triangles.push(p)
    }
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn shape_clamp_float(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn arc_safe_half_angle(raw_half_angle : Float) -> Float {
  shape_clamp_float(
    shape_abs_float(raw_half_angle),
    0.0F,
    @math.pi_half() * 2.0F,
  )
}

///|
fn arc_angle_from_index(
  first_angle : Float,
  last_angle : Float,
  index : Int,
  count : Int,
) -> Float {
  if count <= 1 {
    first_angle
  } else {
    let t = Float::from_double(index.to_double()) /
      Float::from_double((count - 1).to_double())
    first_angle + (last_angle - first_angle) * t
  }
}

///|
fn circular_sector_to_mesh2d_geometry(
  sector : CircularSector,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(sector.radius), 0.5F)
  let half_angle = arc_safe_half_angle(sector.half_angle)
  let uv_angle = match sector.uv_mode {
    Mask(angle) => angle
  }
  let resolution = shape_safe_segments(sector.vertices, 2)
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  positions.push(@math.Vec2::new(0.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  for i in 0..<resolution {
    let angle = arc_angle_from_index(first_angle, last_angle, i, resolution)
    positions.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
    uvs.push(
      @math.Vec2::new(
        @math.cos(-(angle + uv_angle)) * 0.5F + 0.5F,
        @math.sin(-(angle + uv_angle)) * 0.5F + 0.5F,
      ),
    )
  }
  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn circular_segment_apothem(radius : Float, half_angle : Float) -> Float {
  let half_chord = radius * @math.sin(half_angle)
  let leg = radius * radius - half_chord * half_chord
  let positive_leg = if leg < 0.0F { 0.0F } else { leg }
  let sign = if half_angle <= @math.pi_half() { 1.0F } else { -1.0F }
  sign * @math.sqrt(positive_leg)
}

///|
fn circular_segment_to_mesh2d_geometry(
  segment : CircularSegment,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(segment.radius), 0.5F)
  let half_angle = arc_safe_half_angle(segment.half_angle)
  let uv_angle = match segment.uv_mode {
    Mask(angle) => angle
  }
  let resolution = shape_safe_segments(segment.vertices, 2)
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  let midpoint_y = circular_segment_apothem(radius, half_angle)
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let midpoint_uv_scale = 0.5F * midpoint_y / radius
  positions.push(@math.Vec2::new(0.0F, midpoint_y))
  uvs.push(
    @math.Vec2::new(
      @math.cos(-uv_angle - @math.pi_half()) * midpoint_uv_scale + 0.5F,
      @math.sin(-uv_angle - @math.pi_half()) * midpoint_uv_scale + 0.5F,
    ),
  )
  for i in 0..<resolution {
    let angle = arc_angle_from_index(first_angle, last_angle, i, resolution)
    positions.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
    uvs.push(
      @math.Vec2::new(
        @math.cos(-(angle + uv_angle)) * 0.5F + 0.5F,
        @math.sin(-(angle + uv_angle)) * 0.5F + 0.5F,
      ),
    )
  }
  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn capsule_to_mesh2d_geometry(capsule : Capsule2d) -> @mesh.Mesh2dGeometry {
  let r = shape_safe_positive(shape_abs_float(capsule.radius), 0.5F)
  let half = shape_abs_float(capsule.half_length)
  let segments = shape_safe_segments(capsule.segments, 4)
  let perimeter = shape_perimeter_capsule(r, half, segments)
  // Right side back to start is implicit.
  let positions : Array[@math.Vec2] = []
  positions.push(@math.Vec2::new(0.0F, 0.0F)) // center
  for p in perimeter {
    positions.push(p)
  }
  // Simple UVs based on bounds.
  let denom_x = if r == 0.0F { 1.0F } else { 2.0F * r }
  let denom_y = if half + r == 0.0F { 1.0F } else { 2.0F * (half + r) }
  let uvs : Array[@math.Vec2] = []
  for p in positions {
    let u = p.x / denom_x + 0.5F
    let v = p.y / denom_y + 0.5F
    uvs.push(@math.Vec2::new(u, v))
  }
  let indices : Array[Int] = []
  let n = perimeter.length()
  for i in 0..<n {
    let a = 0
    let b = 1 + i
    let c = 1 + (i + 1) % n
    indices.push(a)
    indices.push(b)
    indices.push(c)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn capsule_ring_to_mesh2d_geometry(
  ring : Capsule2dRing,
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half = shape_abs_float(ring.outer_shape.half_length)
  let inner_half = shape_abs_float(ring.inner_shape.half_length)
  let outer_segments = shape_safe_segments(ring.outer_shape.segments, 4)
  let inner_segments = shape_safe_segments(ring.inner_shape.segments, 4)
  let segments = if outer_segments < inner_segments {
    outer_segments
  } else {
    inner_segments
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_capsule(outer_radius, outer_half, segments),
    shape_perimeter_capsule(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half,
      segments,
    ),
  )
}

///|
pub fn Mesh2d::from_capsule(capsule : Capsule2d) -> Mesh2d {
  Mesh2d::from_geometry(capsule_to_mesh2d_geometry(capsule))
}

///|
pub fn Mesh2d::from_circular_sector(sector : CircularSector) -> Mesh2d {
  Mesh2d::from_geometry(circular_sector_to_mesh2d_geometry(sector))
}

///|
pub fn Mesh2d::from_circular_segment(segment : CircularSegment) -> Mesh2d {
  Mesh2d::from_geometry(circular_segment_to_mesh2d_geometry(segment))
}

///|
pub fn Mesh2d::from_circle(circle : Circle) -> Mesh2d {
  Mesh2d::from_geometry(circle_to_mesh2d_geometry(circle))
}

///|
pub fn Mesh2d::from_ellipse(ellipse : Ellipse) -> Mesh2d {
  Mesh2d::from_geometry(ellipse_to_mesh2d_geometry(ellipse))
}

///|
pub fn Mesh2d::from_annulus(annulus : Annulus) -> Mesh2d {
  Mesh2d::from_geometry(annulus_to_mesh2d_geometry(annulus))
}

///|
pub fn Mesh2d::from_ring(ring : Ring2d) -> Mesh2d {
  Mesh2d::from_geometry(ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_circular_sector_ring(ring : CircularSectorRing) -> Mesh2d {
  Mesh2d::from_geometry(circular_sector_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_circular_segment_ring(ring : CircularSegmentRing) -> Mesh2d {
  Mesh2d::from_geometry(circular_segment_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_ellipse_ring(ring : EllipseRing) -> Mesh2d {
  Mesh2d::from_geometry(ellipse_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_capsule_ring(ring : Capsule2dRing) -> Mesh2d {
  Mesh2d::from_geometry(capsule_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_rhombus_ring(ring : RhombusRing) -> Mesh2d {
  Mesh2d::from_geometry(rhombus_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_rectangle_ring(ring : RectangleRing) -> Mesh2d {
  Mesh2d::from_geometry(rectangle_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_regular_polygon_ring(ring : RegularPolygonRing) -> Mesh2d {
  Mesh2d::from_geometry(regular_polygon_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_triangle_ring(ring : Triangle2dRing) -> Mesh2d {
  Mesh2d::from_geometry(triangle_ring_to_mesh2d_geometry(ring))
}

///|
pub fn Mesh2d::from_rhombus(rhombus : Rhombus) -> Mesh2d {
  Mesh2d::from_geometry(rhombus_to_mesh2d_geometry(rhombus))
}

///|
pub fn Mesh2d::from_regular_polygon(polygon : RegularPolygon) -> Mesh2d {
  Mesh2d::from_geometry(regular_polygon_to_mesh2d_geometry(polygon))
}

///|
pub fn Mesh2d::from_triangle(triangle : Triangle2d) -> Mesh2d {
  Mesh2d::from_geometry(triangle_to_mesh2d_geometry(triangle))
}

///|
pub fn Mesh2d::from_segment(segment : Segment2d) -> Mesh2d {
  Mesh2d::from_geometry(segment_to_mesh2d_geometry(segment))
}

///|
pub fn Mesh2d::from_polyline(polyline : Polyline2d) -> Mesh2d {
  Mesh2d::from_geometry(polyline_to_mesh2d_geometry(polyline))
}

///|
pub fn Mesh2d::from_rectangle(rectangle : Rectangle) -> Mesh2d {
  Mesh2d::from_geometry(rectangle_to_mesh2d_geometry(rectangle))
}

///|
pub fn Mesh2d::from_geometry(geometry : @mesh.Mesh2dGeometry) -> Mesh2d {
  let mesh = @mesh.Mesh::from_2d_geometry(geometry)
  Mesh2d::new(mesh_asset_add(mesh))
}

///|
pub struct GpuMesh2d {
  mesh_id : Int
}

///|
pub fn GpuMesh2d::new(mesh_id : Int) -> GpuMesh2d {
  GpuMesh2d::{ mesh_id, }
}

///|
pub struct SpriteBundle {
  sprite : Sprite
  anchor : Anchor
  transform : @math.Transform
  layers : RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn SpriteBundle::new(
  sprite : Sprite,
  transform : @math.Transform,
) -> SpriteBundle {
  SpriteBundle::{
    sprite,
    anchor: Anchor::default(),
    transform,
    layers: RenderLayers::default(),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
pub fn SpriteBundle::new_with_layers(
  sprite : Sprite,
  transform : @math.Transform,
  layers : RenderLayers,
) -> SpriteBundle {
  SpriteBundle::{
    sprite,
    anchor: Anchor::default(),
    transform,
    layers,
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
pub struct Camera2dBundle {
  camera : Camera
  projection : Projection
  camera2d : Camera2d
  transform : @math.Transform
  target : RenderTarget
  layers : RenderLayers
  bloom2d : Bloom2d?
}

///|
pub fn Camera2dBundle::new(
  camera : Camera,
  transform : @math.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection: Projection::orthographic_2d(),
    camera2d: Camera2d::default(),
    transform,
    target: RenderTarget::Screen,
    layers: RenderLayers::default(),
    bloom2d: None,
  }
}

///|
pub fn Camera2dBundle::new_with_projection(
  camera : Camera,
  projection : Projection,
  transform : @math.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection,
    camera2d: Camera2d::default(),
    transform,
    target: RenderTarget::Screen,
    layers: RenderLayers::default(),
    bloom2d: None,
  }
}

///|
pub fn Camera2dBundle::new_with_target(
  camera : Camera,
  transform : @math.Transform,
  target : RenderTarget,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection: Projection::orthographic_2d(),
    camera2d: Camera2d::default(),
    transform,
    target,
    layers: RenderLayers::default(),
    bloom2d: None,
  }
}

///|
pub fn Camera2dBundle::new_with_layers(
  camera : Camera,
  transform : @math.Transform,
  target : RenderTarget,
  layers : RenderLayers,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection: Projection::orthographic_2d(),
    camera2d: Camera2d::default(),
    transform,
    target,
    layers,
    bloom2d: None,
  }
}

///|
pub fn Camera2dBundle::with_bloom2d(
  self : Camera2dBundle,
  bloom2d : Bloom2d,
) -> Camera2dBundle {
  Camera2dBundle::{ ..self, bloom2d: Some(bloom2d) }
}

///|
pub struct Mesh2dBundle {
  mesh : Mesh2d
  material : ColorMaterial
  transform : @math.Transform
  layers : RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn Mesh2dBundle::new(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @math.Transform,
) -> Mesh2dBundle {
  Mesh2dBundle::{
    mesh,
    material,
    transform,
    layers: RenderLayers::default(),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
pub fn Mesh2dBundle::new_with_mesh_material(
  mesh : Mesh2d,
  material : MeshMaterial2d,
  transform : @math.Transform,
) -> Mesh2dBundle {
  Mesh2dBundle::new(mesh, material.to_color_material(), transform)
}

///|
pub fn Mesh2dBundle::new_with_layers(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @math.Transform,
  layers : RenderLayers,
) -> Mesh2dBundle {
  Mesh2dBundle::{
    mesh,
    material,
    transform,
    layers,
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
pub fn Mesh2dBundle::new_with_mesh_material_layers(
  mesh : Mesh2d,
  material : MeshMaterial2d,
  transform : @math.Transform,
  layers : RenderLayers,
) -> Mesh2dBundle {
  Mesh2dBundle::new_with_layers(
    mesh,
    material.to_color_material(),
    transform,
    layers,
  )
}

///|
pub struct TileData {
  tileset_index : Int
}

///|
pub fn TileData::from_tileset_index(tileset_index : Int) -> TileData {
  let value = if tileset_index < 0 { 0 } else { tileset_index }
  TileData::{ tileset_index: value }
}

///|
pub struct TilemapChunk {
  chunk_size : @math.UVec2
  tile_display_size : @math.UVec2
  tileset : @asset.Handle[@asset.Image]
  tileset_grid : @math.UVec2
}

///|
pub fn TilemapChunk::new(
  chunk_size : @math.UVec2,
  tile_display_size : @math.UVec2,
  tileset : @asset.Handle[@asset.Image],
  tileset_grid : @math.UVec2,
) -> TilemapChunk {
  TilemapChunk::{ chunk_size, tile_display_size, tileset, tileset_grid }
}

///|
pub fn TilemapChunk::tile_capacity(self : TilemapChunk) -> Int {
  self.chunk_size.x * self.chunk_size.y
}

///|
fn tilemap_chunk_safe_uvec2(
  value : @math.UVec2,
  fallback : @math.UVec2,
) -> @math.UVec2 {
  let x = if value.x <= 0 { fallback.x } else { value.x }
  let y = if value.y <= 0 { fallback.y } else { value.y }
  @math.UVec2::new(x, y)
}

///|
fn tilemap_chunk_local_center(
  chunk : TilemapChunk,
  tile_pos : @math.UVec2,
) -> @math.Vec2 {
  let safe_chunk_size = tilemap_chunk_safe_uvec2(
    chunk.chunk_size,
    @math.UVec2::new(1, 1),
  )
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    chunk.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  let tile_w = Float::from_double(safe_tile_size.x.to_double())
  let tile_h = Float::from_double(safe_tile_size.y.to_double())
  let chunk_w = Float::from_double(safe_chunk_size.x.to_double()) * tile_w
  let chunk_h = Float::from_double(safe_chunk_size.y.to_double()) * tile_h
  let origin_x = -chunk_w / 2.0F + tile_w / 2.0F
  let origin_y = chunk_h / 2.0F - tile_h / 2.0F
  let x = origin_x + Float::from_double(tile_pos.x.to_double()) * tile_w
  let y = origin_y - Float::from_double(tile_pos.y.to_double()) * tile_h
  @math.Vec2::new(x, y)
}

///|
pub fn TilemapChunk::calculate_tile_transform(
  self : TilemapChunk,
  tile_pos : @math.UVec2,
) -> @math.Transform {
  let local_center = tilemap_chunk_local_center(self, tile_pos)
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    self.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  @math.Transform::from_xy_rotation_scale(
    local_center,
    0.0F,
    @math.Vec2::new(
      Float::from_double(safe_tile_size.x.to_double()),
      Float::from_double(safe_tile_size.y.to_double()),
    ),
  )
}

///|
pub struct TilemapChunkTileData {
  tile_data : Array[TileData?]
}

///|
pub fn TilemapChunkTileData::new(
  tile_data : Array[TileData?],
) -> TilemapChunkTileData {
  TilemapChunkTileData::{ tile_data, }
}

///|
pub fn TilemapChunkTileData::tile_data_from_tile_pos(
  self : TilemapChunkTileData,
  chunk_size : @math.UVec2,
  tile_pos : @math.UVec2,
) -> TileData? {
  if tile_pos.x < 0 || tile_pos.y < 0 {
    return None
  }
  if tile_pos.x >= chunk_size.x || tile_pos.y >= chunk_size.y {
    return None
  }
  let index = tile_pos.y * chunk_size.x + tile_pos.x
  if index < 0 || index >= self.tile_data.length() {
    return None
  }
  self.tile_data[index]
}

///|
pub fn TilemapChunkTileData::set_tile_data_from_tile_pos(
  self : TilemapChunkTileData,
  chunk_size : @math.UVec2,
  tile_pos : @math.UVec2,
  value : TileData?,
) -> TilemapChunkTileData {
  if tile_pos.x < 0 || tile_pos.y < 0 {
    return self
  }
  if tile_pos.x >= chunk_size.x || tile_pos.y >= chunk_size.y {
    return self
  }
  let index = tile_pos.y * chunk_size.x + tile_pos.x
  if index < 0 || index >= self.tile_data.length() {
    return self
  }
  let next : Array[TileData?] = []
  for i in 0..<self.tile_data.length() {
    if i == index {
      next.push(value)
    } else {
      next.push(self.tile_data[i])
    }
  }
  TilemapChunkTileData::{ tile_data: next }
}

///|
fn render2d_transform_point_2d(
  transform : @math.Transform,
  point : @math.Vec2,
) -> @math.Vec2 {
  let scaled = @math.Vec2::new(
    point.x * transform.scale.x,
    point.y * transform.scale.y,
  )
  let rotation = transform.rotation_z()
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  let rotated_x = scaled.x * cosv - scaled.y * sinv
  let rotated_y = scaled.x * sinv + scaled.y * cosv
  @math.Vec2::new(
    rotated_x + transform.translation.x,
    rotated_y + transform.translation.y,
  )
}

///|
fn tilemap_chunk_uv_rect(
  tileset_index : Int,
  tileset_grid : @math.UVec2,
) -> (@math.Vec2, @math.Vec2)? {
  let safe_grid = tilemap_chunk_safe_uvec2(tileset_grid, @math.UVec2::new(1, 1))
  let tile_count = safe_grid.x * safe_grid.y
  if tileset_index < 0 || tileset_index >= tile_count {
    return None
  }
  let col = tileset_index % safe_grid.x
  let row = tileset_index / safe_grid.x
  let inv_w = 1.0F / Float::from_double(safe_grid.x.to_double())
  let inv_h = 1.0F / Float::from_double(safe_grid.y.to_double())
  let uv_min = @math.Vec2::new(
    Float::from_double(col.to_double()) * inv_w,
    Float::from_double(row.to_double()) * inv_h,
  )
  let uv_max = @math.Vec2::new(uv_min.x + inv_w, uv_min.y + inv_h)
  Some((uv_min, uv_max))
}

///|
fn tilemap_chunk_resolve_tileset_grid(chunk : TilemapChunk) -> @math.UVec2 {
  if @asset.asset_image_array_layout(chunk.tileset) is Some(array_layout) {
    match array_layout {
      @asset.ImageArrayLayout::RowCount(rows) => {
        let safe_rows = if rows <= 0 { 1 } else { rows }
        return @math.UVec2::new(1, safe_rows)
      }
      @asset.ImageArrayLayout::RowHeight(row_height) => {
        let safe_row_height = if row_height <= 0 { 1 } else { row_height }
        let texture_height = @asset.asset_texture_height(chunk.tileset)
        let rows = if texture_height <= 0 {
          1
        } else {
          texture_height / safe_row_height
        }
        let safe_rows = if rows <= 0 { 1 } else { rows }
        return @math.UVec2::new(1, safe_rows)
      }
    }
  }
  tilemap_chunk_safe_uvec2(chunk.tileset_grid, @math.UVec2::new(1, 1))
}

///|
pub fn render2d_draw_tilemap_chunk(
  world : @ecs.World,
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
  transform : @math.Transform,
  layers : RenderLayers,
) -> Unit {
  let safe_chunk_size = tilemap_chunk_safe_uvec2(
    chunk.chunk_size,
    @math.UVec2::new(1, 1),
  )
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    chunk.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  let resolved_tileset_grid = tilemap_chunk_resolve_tileset_grid(chunk)
  let texture_width = @asset.asset_texture_width(chunk.tileset)
  let texture_height = @asset.asset_texture_height(chunk.tileset)
  let tileset_columns = Float::from_double(resolved_tileset_grid.x.to_double())
  let tileset_rows = Float::from_double(resolved_tileset_grid.y.to_double())
  let region_width = if texture_width > 0 {
    Float::from_double(texture_width.to_double()) / tileset_columns
  } else {
    Float::from_double(safe_tile_size.x.to_double())
  }
  let region_height = if texture_height > 0 {
    Float::from_double(texture_height.to_double()) / tileset_rows
  } else {
    Float::from_double(safe_tile_size.y.to_double())
  }
  let safe_region_width = if region_width == 0.0F { 1.0F } else { region_width }
  let safe_region_height = if region_height == 0.0F {
    1.0F
  } else {
    region_height
  }
  let target_tile_width = Float::from_double(safe_tile_size.x.to_double()) *
    transform.scale.x
  let target_tile_height = Float::from_double(safe_tile_size.y.to_double()) *
    transform.scale.y
  // `render2d_push_sprite_uv` consumes host scale factors. Convert from desired
  // tile world size to host scale based on the UV region's pixel size.
  let tile_scale = @math.Vec2::new(
    target_tile_width / safe_region_width,
    target_tile_height / safe_region_height,
  )
  for y in 0..<safe_chunk_size.y {
    for x in 0..<safe_chunk_size.x {
      let tile_pos = @math.UVec2::new(x, y)
      guard tile_data.tile_data_from_tile_pos(safe_chunk_size, tile_pos)
        is Some(tile) else {
        continue
      }
      guard tilemap_chunk_uv_rect(tile.tileset_index, resolved_tileset_grid)
        is Some((uv_min, uv_max)) else {
        continue
      }
      let world_pos = render2d_transform_point_2d(
        transform,
        tilemap_chunk_local_center(
          TilemapChunk::{
            chunk_size: safe_chunk_size,
            tile_display_size: safe_tile_size,
            tileset: chunk.tileset,
            tileset_grid: resolved_tileset_grid,
          },
          tile_pos,
        ),
      )
      let tile_transform = @math.Transform::from_xy_rotation_scale(
        world_pos,
        transform.rotation_z(),
        tile_scale,
        z=transform.translation.z,
      )
      render2d_push_sprite_uv(
        world,
        chunk.tileset,
        tile_transform,
        uv_min,
        uv_max,
        Color::white(),
        layers,
      )
    }
  }
}

///|
/// Camera tonemapping mode aligned with Bevy's `Tonemapping`.
pub(all) enum Tonemapping {
  None
  Reinhard
  ReinhardLuminance
  AcesFitted
  AgX
  SomewhatBoringDisplayTransform
  TonyMcMapface
  BlenderFilmic
}

///|
pub fn Tonemapping::default() -> Tonemapping {
  Tonemapping::None
}

///|
/// Enables / disables screen-space deband dithering in the tonemapping pass.
pub(all) enum DebandDither {
  Disabled
  Enabled
}

///|
pub fn DebandDither::default() -> DebandDither {
  DebandDither::Disabled
}

///|
pub(all) struct Bloom2dSettings {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  prefilter : BloomPrefilter
  composite_mode : BloomCompositeMode
  max_mip_dimension : Int
  scale : @math.Vec2
}

///|
pub(all) struct BloomPrefilter {
  threshold : Float
  threshold_softness : Float
}

///|
pub(all) enum BloomCompositeMode {
  EnergyConserving
  Additive
}

///|
pub fn BloomPrefilter::default() -> BloomPrefilter {
  BloomPrefilter::{ threshold: 0.0F, threshold_softness: 0.0F }
}

///|
pub fn Bloom2dSettings::default() -> Bloom2dSettings {
  Bloom2dSettings::{
    intensity: 0.15F,
    low_frequency_boost: 0.7F,
    low_frequency_boost_curvature: 0.95F,
    high_pass_frequency: 1.0F,
    prefilter: BloomPrefilter::default(),
    composite_mode: EnergyConserving,
    max_mip_dimension: 512,
    scale: @math.Vec2::new(1.0F, 1.0F),
  }
}

///|
pub struct Bloom2d {
  source : @asset.Handle[@asset.Image]?
  enabled : Bool
  settings : Bloom2dSettings
}

///|
pub fn Bloom2d::new() -> Bloom2d {
  Bloom2d::{ source: None, enabled: true, settings: Bloom2dSettings::default() }
}

///|
pub fn Bloom2d::with_source(
  self : Bloom2d,
  source : @asset.Handle[@asset.Image],
) -> Bloom2d {
  Bloom2d::{ ..self, source: Some(source) }
}

///|
pub fn Bloom2d::with_settings(
  self : Bloom2d,
  settings : Bloom2dSettings,
) -> Bloom2d {
  Bloom2d::{ ..self, settings, }
}

///|
pub fn Bloom2d::with_enabled(self : Bloom2d, enabled : Bool) -> Bloom2d {
  Bloom2d::{ ..self, enabled, }
}

///|
fn bloom2d_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn bloom2d_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn bloom2d_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn bloom2d_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn bloom2d_sanitize_settings(settings : Bloom2dSettings) -> Bloom2dSettings {
  Bloom2dSettings::{
    intensity: bloom2d_clamp_non_negative(settings.intensity),
    low_frequency_boost: bloom2d_clamp_unit(settings.low_frequency_boost),
    low_frequency_boost_curvature: bloom2d_clamp_unit(
      settings.low_frequency_boost_curvature,
    ),
    high_pass_frequency: bloom2d_clamp_unit(settings.high_pass_frequency),
    prefilter: BloomPrefilter::{
      threshold: bloom2d_clamp_non_negative(settings.prefilter.threshold),
      threshold_softness: bloom2d_clamp_unit(
        settings.prefilter.threshold_softness,
      ),
    },
    composite_mode: settings.composite_mode,
    max_mip_dimension: bloom2d_safe_max_mip_dimension(
      settings.max_mip_dimension,
    ),
    scale: @math.Vec2::new(
      bloom2d_safe_scale_axis(settings.scale.x),
      bloom2d_safe_scale_axis(settings.scale.y),
    ),
  }
}

///|
fn bloom2d_log2_floor(value : Int) -> Int {
  let mut current = value
  let mut power = 0
  while current > 1 {
    current = current / 2
    power = power + 1
  }
  power
}

///|
fn bloom2d_mip_count(settings : Bloom2dSettings) -> Int {
  let logv = bloom2d_log2_floor(
    bloom2d_safe_max_mip_dimension(settings.max_mip_dimension),
  )
  let mip_count = if logv < 2 { 1 } else { logv - 1 }
  if mip_count < 1 {
    1
  } else {
    mip_count
  }
}

///|
fn bloom2d_prefilter_weight(settings : Bloom2dSettings) -> Float {
  let threshold = bloom2d_clamp_non_negative(settings.prefilter.threshold)
  let softness = bloom2d_clamp_unit(settings.prefilter.threshold_softness)
  // Approximate prefilter attenuation in sprite-overlay bloom path.
  let attenuation = 1.0F + threshold * (1.0F - softness * 0.5F)
  if attenuation <= 0.0F {
    1.0F
  } else {
    1.0F / attenuation
  }
}

///|
fn bloom2d_compute_blend_factor(
  settings : Bloom2dSettings,
  mip : Float,
  max_mip : Float,
) -> Float {
  if max_mip <= 0.0F {
    return settings.intensity
  }
  let mip_ratio = bloom2d_clamp_unit(mip / max_mip)
  let curvature = bloom2d_clamp_unit(settings.low_frequency_boost_curvature)
  let exponent = if curvature >= 0.9999F {
    10_000.0F
  } else {
    1.0F / (1.0F - curvature)
  }
  let mut lf_boost = (1.0F - @math.pow(1.0F - mip_ratio, exponent)) *
    settings.low_frequency_boost
  let high_pass = bloom2d_clamp_unit(settings.high_pass_frequency)
  let high_pass_lq = if high_pass <= 1.0e-6F {
    if mip_ratio <= 0.0F {
      1.0F
    } else {
      0.0F
    }
  } else {
    1.0F - bloom2d_clamp_unit((mip_ratio - high_pass) / high_pass)
  }
  let mode_factor = match settings.composite_mode {
    EnergyConserving => 1.0F - settings.intensity
    Additive => 1.0F
  }
  lf_boost = lf_boost * mode_factor
  (settings.intensity + lf_boost) * high_pass_lq
}

///|
fn bloom2d_pass_scale_factor(
  settings : Bloom2dSettings,
  pass_index : Int,
  max_mip : Int,
) -> @math.Vec2 {
  let max_mip_float = if max_mip <= 0 { 1.0F } else { Float::from_int(max_mip) }
  let pass_ratio = bloom2d_clamp_unit(
    Float::from_int(pass_index) / max_mip_float,
  )
  let blur_scale = 0.35F * (0.2F + pass_ratio * 0.8F)
  @math.Vec2::new(
    1.0F + blur_scale * settings.scale.x,
    1.0F + blur_scale * settings.scale.y,
  )
}

///|
pub fn render2d_draw_bloom_overlay(
  world : @ecs.World,
  source : @asset.Handle[@asset.Image],
  base_transform : @math.Transform,
  settings : Bloom2dSettings,
  layers : RenderLayers,
) -> Unit {
  let bloom = bloom2d_sanitize_settings(settings)
  let mip_count = bloom2d_mip_count(bloom)
  let max_mip = mip_count - 1
  let max_mip_f = if max_mip <= 0 { 1.0F } else { Float::from_int(max_mip) }
  let prefilter_weight = bloom2d_prefilter_weight(bloom)
  for pass in 0..<mip_count {
    let pass_f = Float::from_int(pass)
    let blend = bloom2d_compute_blend_factor(bloom, pass_f, max_mip_f)
    let alpha_weight = blend * prefilter_weight / Float::from_int(mip_count)
    if alpha_weight <= 0.0F {
      continue
    }
    let scale_factor = bloom2d_pass_scale_factor(bloom, pass, max_mip)
    let pass_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(
        base_transform.translation.x,
        base_transform.translation.y,
      ),
      base_transform.rotation_z(),
      @math.Vec2::new(
        base_transform.scale.x * scale_factor.x,
        base_transform.scale.y * scale_factor.y,
      ),
      z=base_transform.translation.z + pass_f * 0.001F,
    )
    render2d_push_sprite_uv(
      world,
      source,
      pass_transform,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      Color::new(1.0F, 1.0F, 1.0F, alpha_weight),
      layers,
    )
  }
}

///|
const TONEMAPPING_LUT_AGX_PATH : String = "textures/tonemapping/AgX-default_contrast.ktx2"

///|
const TONEMAPPING_LUT_TONY_PATH : String = "textures/tonemapping/tony_mc_mapface.ktx2"

///|
const TONEMAPPING_LUT_BLENDER_PATH : String = "textures/tonemapping/Blender_-11_12.ktx2"

///|
priv struct TonemappingLutHandles {
  agx : @asset.Handle[@asset.Image]
  tony : @asset.Handle[@asset.Image]
  blender : @asset.Handle[@asset.Image]
}

///|
let tonemapping_lut_handles_ref : Ref[TonemappingLutHandles?] = Ref::new(None)

///|
fn render2d_tonemapping_lut_handles() -> TonemappingLutHandles {
  if tonemapping_lut_handles_ref.val is Some(handles) {
    return handles
  }
  let asset_server = @asset.AssetServer::new()
  let handles = TonemappingLutHandles::{
    agx: asset_server.load(TONEMAPPING_LUT_AGX_PATH),
    tony: asset_server.load(TONEMAPPING_LUT_TONY_PATH),
    blender: asset_server.load(TONEMAPPING_LUT_BLENDER_PATH),
  }
  tonemapping_lut_handles_ref.val = Some(handles)
  handles
}

///|
fn render2d_draw_camera_bloom(
  camera : CameraInstance,
  source : @asset.Handle[@asset.Image],
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  guard camera.bloom2d is Some(bloom) else { return }
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let luts = render2d_tonemapping_lut_handles()
  let settings = bloom2d_sanitize_settings(bloom.settings)
  @window.host_gpu_draw_bloom2d(
    scene_texture_id=source.id(),
    enabled=if bloom.enabled { 1 } else { 0 },
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    tonemapping_mode~,
    deband_dither_enabled=if deband_dither_enabled { 1 } else { 0 },
    fxaa_enabled=0,
    fxaa_edge_threshold=0.125F,
    fxaa_edge_threshold_min=0.0312F,
    chromatic_aberration_intensity=0.0F,
    chromatic_aberration_max_samples=8,
    vignette_intensity=0.0F,
    vignette_radius=0.75F,
    vignette_smoothness=5.0F,
    vignette_roundness=1.0F,
    vignette_center_x=0.5F,
    vignette_center_y=0.5F,
    vignette_edge_compensation=1.0F,
    vignette_color_r=0.0F,
    vignette_color_g=0.0F,
    vignette_color_b=0.0F,
    vignette_color_a=1.0F,
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
  )
}

///|
priv struct SpriteInstance {
  entity : @core.Entity
  transform : @math.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  scissor : @math.Rect?
}

///|
priv struct SpriteTextureSliceInstance {
  entity : @core.Entity
  transform : @math.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  scissor : @math.Rect?
  texture_slices : @math.Vec4
  target_slices : @math.Vec4
  repeat : @math.Vec4
  atlas_rect : @math.Vec4
}

///|
priv struct UiRectInstance {
  entity : @core.Entity
  transform : @math.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  scissor : @math.Rect?
  flags : Int
  radius : UiCornerRadii
  border : UiBorderRect
}

///|
priv struct UiBoxShadowInstance {
  entity : @core.Entity
  transform : @math.Transform
  anchor_offset : @math.Vec2
  // Full geometry bounds (shadow size + 6*blur), in world units.
  draw_scale : @math.Vec2
  color : Color
  // Dummy texture binding (pipeline shares sprite/ui bind group layout).
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  // Inner shadow size (node size + spread), in world units.
  size : @math.Vec2
  // Corner radii: top-left, top-right, bottom-right, bottom-left (world units).
  radius : UiCornerRadii
  // Blur radius (world units).
  blur : Float
  // Shadow samples (host shader integration steps).
  samples : Int
  scissor : @math.Rect?
}

///|
priv struct UiTextureSliceInstance {
  entity : @core.Entity
  transform : @math.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  scissor : @math.Rect?
  // Normalized texture slice dividing lines (left, top, right, bottom).
  texture_slices : @math.Vec4
  // Normalized target slice dividing lines (left, top, right, bottom).
  target_slices : @math.Vec4
  // Repeat factors (side_x, side_y, center_x, center_y).
  repeat : @math.Vec4
  // Normalized atlas rect (left, top, right, bottom).
  atlas_rect : @math.Vec4
}

///|
priv struct CameraInstance {
  entity : @core.Entity
  camera : Camera
  projection : OrthographicProjection
  transform : @math.Transform
  target : RenderTarget
  layers : RenderLayers
  bloom2d : Bloom2d?
  computed : CameraComputed
}

///|
priv struct CameraComputed {
  target_size : @math.IVec2
  scale_factor : Float
}

///|
priv struct MeshInstance {
  entity : @core.Entity
  mesh_id : Int
  transform : @math.Transform
  color : Color
  alpha_mode : AlphaMode2d
  texture : @asset.Handle[@asset.Image]?
  uv_offset : @math.Vec2
  uv_scale : @math.Vec2
  layers : RenderLayers
}

///|
priv struct RenderTargetInfo {
  id : Int
  width : Int
  height : Int
}

///|
priv struct Bloom2dAutoTargetInfo {
  camera : @core.Entity
  width : Int
  height : Int
  target : @asset.Handle[@asset.Image]
}

///|

///|
struct RenderState {
  mut draw_enabled : Bool
  mut primary_camera : @core.Entity
  sprites : Array[SpriteInstance]
  extra_sprites : Array[SpriteInstance]
  extra_sprite_texture_slices : Array[SpriteTextureSliceInstance]
  extra_ui_rects : Array[UiRectInstance]
  extra_ui_box_shadows : Array[UiBoxShadowInstance]
  extra_ui_texture_slices : Array[UiTextureSliceInstance]
  cameras : Array[CameraInstance]
  meshes : Array[MeshInstance]
  render_targets : Array[RenderTargetInfo]
  bloom2d_auto_targets : Array[Bloom2dAutoTargetInfo]
}

///|
fn RenderState::new() -> RenderState {
  RenderState::{
    draw_enabled: false,
    primary_camera: @core.Entity::placeholder(),
    sprites: [],
    extra_sprites: [],
    extra_sprite_texture_slices: [],
    extra_ui_rects: [],
    extra_ui_box_shadows: [],
    extra_ui_texture_slices: [],
    cameras: [],
    meshes: [],
    render_targets: [],
    bloom2d_auto_targets: [],
  }
}

///|
let render_state_serde_next_id : Ref[Int] = Ref::new(1)

///|
let render_state_serde_values : Map[Int, RenderState] = {}

///|
pub impl ToJson for RenderState with to_json(self) {
  let id = render_state_serde_next_id.val
  render_state_serde_next_id.val = id + 1
  render_state_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for RenderState with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  render_state_serde_values.get(id).unwrap_or(RenderState::new())
}

///|
fn render_state_ref(world : @ecs.World) -> RenderState? {
  get_render_state_resource(world).get()
}

///|
fn render_state_update(
  world : @ecs.World,
  update : (Ref[RenderState]) -> Unit,
) -> Bool {
  let tick = world.read_change_tick()
  let res = get_render_state_resource(world)
  guard res.get() is Some(state_value) else { return false }
  let state = Ref::new(state_value)
  update(state)
  res.insert(state.val, tick)
  true
}

///|
fn ensure_render_state_resource(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let res = get_render_state_resource(world)
  if !res.is_present() {
    res.insert(RenderState::new(), tick)
    gizmos_reset()
  }
}

///|
fn init_render_state_system(world : @ecs.World) -> Unit {
  ensure_render_state_resource(world)
}

///|
fn init_wireframe2d_resources(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let wireframe_config = get_wireframe2d_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(Wireframe2dConfig::default(), tick)
  }
}

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_startup_system(init_wireframe2d_resources)
}

///|
fn default_uv_min() -> @math.Vec2 {
  @math.Vec2::new(0.0F, 0.0F)
}

///|
fn default_uv_max() -> @math.Vec2 {
  @math.Vec2::new(1.0F, 1.0F)
}

///|
priv struct SpriteUvInfo {
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  // Pixel size of the resolved sprite region (image rect / atlas rect / sprite rect).
  // This is used to interpret `Sprite.custom_size` as a final size (Bevy-style),
  // while the host expects a scale factor.
  region_size : @math.Vec2
}

///|
fn sprite_vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn sprite_vec2_mul(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x * b.x, a.y * b.y)
}

///|
fn sprite_draw_scale(
  sprite : Sprite,
  transform_scale : @math.Vec2,
  region_size : @math.Vec2,
) -> @math.Vec2 {
  match sprite.custom_size {
    None => transform_scale
    Some(custom_size) => {
      // The host's sprite shader uses a fixed 128x128 quad and scales it by:
      //   host_scale * (region_pixels / 128)
      // To make `custom_size` represent a final size in world units, we convert
      // it into a scale factor relative to the region size here.
      let denom_x = if region_size.x == 0.0F { 1.0F } else { region_size.x }
      let denom_y = if region_size.y == 0.0F { 1.0F } else { region_size.y }
      let factor = @math.Vec2::new(
        custom_size.x / denom_x,
        custom_size.y / denom_y,
      )
      sprite_vec2_mul(transform_scale, factor)
    }
  }
}

///|
fn sprite_anchor_offset(
  anchor : Anchor,
  rotation : Float,
  draw_scale : @math.Vec2,
  local_offset : @math.Vec2,
) -> @math.Vec2 {
  let a = anchor.as_vec()
  let offset_local = @math.Vec2::new(
    -a.x * draw_scale.x + local_offset.x,
    -a.y * draw_scale.y + local_offset.y,
  )
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  @math.Vec2::new(
    offset_local.x * cosv - offset_local.y * sinv,
    offset_local.x * sinv + offset_local.y * cosv,
  )
}

///|
fn swap_float_pair(a : Float, b : Float) -> (Float, Float) {
  (b, a)
}

///|
fn sprite_uv_from_sprite(sprite : Sprite) -> SpriteUvInfo? {
  let texture_id = sprite.image.id()
  let mut image_width = @asset.host_asset_texture_width(texture_id)
  let mut image_height = @asset.host_asset_texture_height(texture_id)
  if image_width <= 0 || image_height <= 0 {
    // Avoid division by zero for not-yet-loaded textures.
    image_width = 1
    image_height = 1
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(
      Float::from_double(image_width.to_double()),
      Float::from_double(image_height.to_double()),
    ),
  )
  let atlas_rect = match sprite.texture_atlas {
    Some(atlas) =>
      match @asset.asset_get_texture_atlas_layout(atlas.layout) {
        Some(layout_value) =>
          if atlas.index >= 0 && atlas.index < layout_value.textures.length() {
            Some(layout_value.textures[atlas.index].as_rect())
          } else {
            None
          }
        None => None
      }
    None => None
  }
  let texture_rect = match (atlas_rect, sprite.rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = sprite_vec2_add(r.min, ar.min)
      let max = sprite_vec2_add(r.max, ar.min)
      @math.Rect::new(min, max)
    }
  }
  let denom_x = Float::from_double(image_width.to_double())
  let denom_y = Float::from_double(image_height.to_double())
  if denom_x <= 0.0F || denom_y <= 0.0F {
    return None
  }
  let region_size = @math.Vec2::new(
    texture_rect.max.x - texture_rect.min.x,
    texture_rect.max.y - texture_rect.min.y,
  )
  let mut uv_min = @math.Vec2::new(
    texture_rect.min.x / denom_x,
    texture_rect.min.y / denom_y,
  )
  let mut uv_max = @math.Vec2::new(
    texture_rect.max.x / denom_x,
    texture_rect.max.y / denom_y,
  )
  if sprite.flip_x {
    let pair = swap_float_pair(uv_min.x, uv_max.x)
    uv_min = @math.Vec2::new(pair.0, uv_min.y)
    uv_max = @math.Vec2::new(pair.1, uv_max.y)
  }
  if sprite.flip_y {
    let pair = swap_float_pair(uv_min.y, uv_max.y)
    uv_min = @math.Vec2::new(uv_min.x, pair.0)
    uv_max = @math.Vec2::new(uv_max.x, pair.1)
  }
  Some(SpriteUvInfo::{ uv_min, uv_max, region_size })
}

///|
fn sprite_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
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
fn tiled_repeat_factor(draw_scale_axis : Float, stretch_value : Float) -> Float {
  let safe_stretch = clamp_stretch_value(stretch_value)
  let draw_abs = sprite_abs_float(draw_scale_axis)
  if draw_abs < 0.000001F {
    1.0F
  } else {
    draw_abs / safe_stretch
  }
}

///|
fn apply_tiled_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  image_mode : SpriteImageMode,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2, Bool) {
  match image_mode {
    SpriteImageMode::Tiled(tiling) => {
      let repeat_x = if tiling.tile_x {
        tiled_repeat_factor(draw_scale.x, tiling.stretch_value)
      } else {
        1.0F
      }
      let repeat_y = if tiling.tile_y {
        tiled_repeat_factor(draw_scale.y, tiling.stretch_value)
      } else {
        1.0F
      }
      let uv_span_x = uv_max.x - uv_min.x
      let uv_span_y = uv_max.y - uv_min.y
      let next_uv_max = @math.Vec2::new(
        uv_min.x + uv_span_x * repeat_x,
        uv_min.y + uv_span_y * repeat_y,
      )
      let next_draw_scale = @math.Vec2::new(
        if tiling.tile_x {
          draw_scale.x / repeat_x
        } else {
          draw_scale.x
        },
        if tiling.tile_y {
          draw_scale.y / repeat_y
        } else {
          draw_scale.y
        },
      )
      (uv_min, next_uv_max, next_draw_scale, @math.Vec2::new(0.0F, 0.0F), true)
    }
    _ => (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
  }
}

///|
fn apply_scale_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  scaling_mode : SpriteScalingMode,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2) {
  let region_w = sprite_abs_float(region_size.x)
  let region_h = sprite_abs_float(region_size.y)
  if region_w <= 0.0F || region_h <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }
  let draw_sign_x = if draw_scale.x < 0.0F { -1.0F } else { 1.0F }
  let draw_sign_y = if draw_scale.y < 0.0F { -1.0F } else { 1.0F }
  let mut target_size = @math.Vec2::new(
    sprite_abs_float(draw_scale.x) * region_w,
    sprite_abs_float(draw_scale.y) * region_h,
  )
  if target_size.x <= 0.0F || target_size.y <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }

  let texture_ratio = region_w / region_h
  let quad_ratio = target_size.x / target_size.y
  if texture_ratio <= 0.0F || quad_ratio <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }

  let tex_quad_scale = texture_ratio / quad_ratio
  let quad_tex_scale = quad_ratio / texture_ratio
  let mut uv_offset_scale = @math.Vec4::new(
    uv_min.x,
    uv_min.y,
    uv_max.x - uv_min.x,
    uv_max.y - uv_min.y,
  )
  let mut local_offset_target = @math.Vec2::new(0.0F, 0.0F)

  match scaling_mode {
    FillCenter =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y +
          (uv_offset_scale.w - uv_offset_scale.w * tex_quad_scale) * 0.5F,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x +
          (uv_offset_scale.z - uv_offset_scale.z * quad_tex_scale) * 0.5F,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FillStart =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y +
          uv_offset_scale.w -
          uv_offset_scale.w * tex_quad_scale,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FillEnd =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x +
          uv_offset_scale.z -
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FitCenter =>
      if texture_ratio > quad_ratio {
        target_size = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
      } else {
        target_size = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
      }
    FitStart =>
      if texture_ratio > quad_ratio {
        let new_quad = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(0.0F, -offset.y)
        target_size = new_quad
      } else {
        let new_quad = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(offset.x, 0.0F)
        target_size = new_quad
      }
    FitEnd =>
      if texture_ratio > quad_ratio {
        let new_quad = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(0.0F, offset.y)
        target_size = new_quad
      } else {
        let new_quad = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(-offset.x, 0.0F)
        target_size = new_quad
      }
  }

  let next_draw_scale = @math.Vec2::new(
    draw_sign_x * target_size.x / region_w,
    draw_sign_y * target_size.y / region_h,
  )
  let local_offset = @math.Vec2::new(
    local_offset_target.x / region_w,
    local_offset_target.y / region_h,
  )
  (
    @math.Vec2::new(uv_offset_scale.x, uv_offset_scale.y),
    @math.Vec2::new(
      uv_offset_scale.x + uv_offset_scale.z,
      uv_offset_scale.y + uv_offset_scale.w,
    ),
    next_draw_scale,
    local_offset,
  )
}

///|
fn apply_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  image_mode : SpriteImageMode,
  has_custom_size : Bool,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2, Bool) {
  match image_mode {
    SpriteImageMode::Scale(scaling_mode) =>
      if has_custom_size {
        let (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset) = apply_scale_sprite_image_mode(
          uv_min, uv_max, draw_scale, region_size, scaling_mode,
        )
        (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset, false)
      } else {
        (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
      }
    _ => apply_tiled_sprite_image_mode(uv_min, uv_max, draw_scale, image_mode)
  }
}

///|
fn render2d_mesh_should_draw_wireframe(
  has_wireframe : Bool,
  has_no_wireframe : Bool,
  wireframe_config : Wireframe2dConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if has_no_wireframe {
    false
  } else if has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn render2d_mesh_wireframe_color(
  mesh_color : Wireframe2dColor?,
  wireframe_config : Wireframe2dConfig?,
) -> Color {
  if mesh_color is Some(component) {
    component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    Color::white()
  }
}

///|
fn compute_sprite_texture_slices(
  image_size : @math.Vec2,
  target_size : @math.Vec2,
  mode : SpriteImageMode,
) -> (@math.Vec4, @math.Vec4, @math.Vec4) {
  match mode {
    SpriteImageMode::Sliced(slicer) => {
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
    _ =>
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
  }
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @window.host_gpu_create_render_target(width~, height~, nearest~)
  ensure_render_state_resource(world)
  let tick = world.read_change_tick()
  let res = get_render_state_resource(world)
  if res.get() is Some(state_value) {
    let rs = Ref::new(state_value)
    rs.val.render_targets.push(RenderTargetInfo::{ id, width, height })
    res.insert(rs.val, tick)
  }
  @asset.Handle::new(id)
}

///|
pub fn SpriteBundle::spawn(
  self : SpriteBundle,
  world : @ecs.World,
) -> @core.Entity {
  let e = world.spawn_empty()
  try! (world.set(e, ecs_key_sprite, self.sprite) |> ignore)
  try! (world.set(e, ecs_key_anchor, self.anchor) |> ignore)
  try! (world.set(e, ecs_key_render_layers, self.layers) |> ignore)
  try! (world.set(e, @visibility.ecs_key_visibility, self.visibility) |> ignore)
  try! (world.set(
    e,
    @visibility.ecs_key_inherited_visibility,
    self.inherited_visibility,
  )
  |> ignore)
  try! (world.set(e, @visibility.ecs_key_view_visibility, self.view_visibility)
  |> ignore)
  try! (world.set(e, @math.ecs_key_transform, self.transform) |> ignore)
  e
}

///|
pub fn Camera2dBundle::spawn(
  self : Camera2dBundle,
  world : @ecs.World,
) -> @core.Entity {
  let e = world.spawn_empty()
  try! (world.set(e, ecs_key_camera2d, self.camera2d) |> ignore)
  try! (world.set(e, ecs_key_camera, self.camera) |> ignore)
  try! (world.set(e, ecs_key_projection, self.projection) |> ignore)
  try! (world.set(e, ecs_key_render_target, self.target) |> ignore)
  try! (world.set(e, ecs_key_render_layers, self.layers) |> ignore)
  if self.bloom2d is Some(bloom2d) {
    try! (world.set(e, ecs_key_bloom2d, bloom2d) |> ignore)
  }
  try! (world.set(e, @math.ecs_key_transform, self.transform) |> ignore)
  e
}

///|
pub fn Mesh2dBundle::spawn(
  self : Mesh2dBundle,
  world : @ecs.World,
) -> @core.Entity {
  let e = world.spawn_empty()
  try! (world.set(e, ecs_key_mesh2d, self.mesh) |> ignore)
  try! (world.set(e, ecs_key_color_material, self.material) |> ignore)
  try! (world.set(
    e,
    ecs_key_mesh_material2d,
    MeshMaterial2d::from_color_material(self.material),
  )
  |> ignore)
  try! (world.set(e, ecs_key_render_layers, self.layers) |> ignore)
  try! (world.set(e, @visibility.ecs_key_visibility, self.visibility) |> ignore)
  try! (world.set(
    e,
    @visibility.ecs_key_inherited_visibility,
    self.inherited_visibility,
  )
  |> ignore)
  try! (world.set(e, @visibility.ecs_key_view_visibility, self.view_visibility)
  |> ignore)
  try! (world.set(e, @math.ecs_key_transform, self.transform) |> ignore)
  let mesh_id = render2d_upload_mesh_handle(self.mesh.mesh)
  try! (world.set(e, ecs_key_gpu_mesh2d, GpuMesh2d::new(mesh_id)) |> ignore)
  e
}

///|
pub fn render2d_clear_overlay_sprites(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) { rs.val.extra_sprites.clear() }) |> ignore
}

///|
pub fn render2d_clear_overlay_sprite_texture_slices(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_sprite_texture_slices.clear()
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_sprites.push(SpriteInstance::{
      entity: @core.Entity::placeholder(),
      transform,
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor: None,
    })
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv_scissor(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_sprites.push(SpriteInstance::{
      entity: @core.Entity::placeholder(),
      transform,
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor,
    })
  })
  |> ignore
}

///|
pub(all) struct OverlaySpriteUvScissor {
  texture : @asset.Handle[@asset.Image]
  transform : @math.Transform
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  color : Color
  layers : RenderLayers
  scissor : @math.Rect?
}

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[OverlaySpriteUvScissor],
) -> Unit {
  if sprites.length() == 0 {
    return
  }
  render_state_update(world, fn(rs) {
    for sprite in sprites {
      rs.val.extra_sprites.push(SpriteInstance::{
        entity: @core.Entity::placeholder(),
        transform: sprite.transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(
          sprite.transform.scale.x,
          sprite.transform.scale.y,
        ),
        color: sprite.color,
        texture: sprite.texture,
        layers: sprite.layers,
        uv_min: sprite.uv_min,
        uv_max: sprite.uv_max,
        scissor: sprite.scissor,
      })
    }
  })
  |> ignore
}

///|
pub fn render2d_clear_overlay_ui_rects(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) { rs.val.extra_ui_rects.clear() }) |> ignore
}

///|
pub fn render2d_clear_overlay_ui_box_shadows(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) { rs.val.extra_ui_box_shadows.clear() })
  |> ignore
}

///|
pub fn render2d_clear_overlay_ui_texture_slices(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) { rs.val.extra_ui_texture_slices.clear() })
  |> ignore
}

///|
pub fn render2d_push_ui_rect_uv_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
  flags : Int,
  radius : UiCornerRadii,
  border : UiBorderRect,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_ui_rects.push(UiRectInstance::{
      entity,
      transform,
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale,
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor,
      flags,
      radius,
      border,
    })
  })
  |> ignore
}

///|
pub fn render2d_push_ui_box_shadow_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
  size : @math.Vec2,
  radius : UiCornerRadii,
  blur : Float,
  samples : Int,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_ui_box_shadows.push(UiBoxShadowInstance::{
      entity,
      transform,
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale,
      color,
      texture,
      layers,
      size,
      radius,
      blur,
      samples,
      scissor,
    })
  })
  |> ignore
}

///|
pub fn render2d_push_ui_texture_slice_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
  texture_slices : @math.Vec4,
  target_slices : @math.Vec4,
  repeat : @math.Vec4,
  atlas_rect : @math.Vec4,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_ui_texture_slices.push(UiTextureSliceInstance::{
      entity,
      transform,
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale,
      color,
      texture,
      layers,
      scissor,
      texture_slices,
      target_slices,
      repeat,
      atlas_rect,
    })
  })
  |> ignore
}

///|
fn render2d_find_render_target_size(
  state : RenderState,
  id : Int,
) -> RenderTargetInfo? {
  for target in state.render_targets {
    if target.id == id {
      return Some(target)
    }
  }
  None
}

///|
priv struct RenderTargetComputed {
  size : @math.IVec2
  scale_factor : Float
}

///|
fn render2d_target_info(
  state : RenderState,
  target : RenderTarget,
) -> RenderTargetComputed? {
  let mut width = @window.window_width()
  let mut height = @window.window_height()
  let mut scale_factor = @window.window_scale_factor()
  if target is Image(handle) {
    let target_id = handle.id()
    if render2d_find_render_target_size(state, target_id) is Some(info) {
      width = info.width
      height = info.height
      scale_factor = 1.0F
    } else {
      return None
    }
  }
  if width <= 0 || height <= 0 {
    return None
  }
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  Some(RenderTargetComputed::{
    size: @math.IVec2::new(width, height),
    scale_factor,
  })
}

///|
fn render2d_same_entity(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render2d_prune_bloom2d_auto_targets(state : RenderState) -> Unit {
  let kept : Array[Bloom2dAutoTargetInfo] = []
  for entry in state.bloom2d_auto_targets {
    let mut active = false
    for camera in state.cameras {
      if render2d_same_entity(entry.camera, camera.entity) {
        active = true
        break
      }
    }
    if active {
      kept.push(entry)
    }
  }
  state.bloom2d_auto_targets.clear()
  for entry in kept {
    state.bloom2d_auto_targets.push(entry)
  }
}

///|
fn render2d_get_or_create_bloom2d_auto_target(
  state : RenderState,
  camera : @core.Entity,
  width : Int,
  height : Int,
) -> @asset.Handle[@asset.Image] {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  for entry in state.bloom2d_auto_targets {
    if render2d_same_entity(entry.camera, camera) &&
      entry.width == safe_width &&
      entry.height == safe_height {
      return entry.target
    }
  }
  let id = @window.host_gpu_create_render_target_rgba16f(
    width=safe_width,
    height=safe_height,
    nearest=false,
  )
  let handle : @asset.Handle[@asset.Image] = @asset.Handle::new(id)
  state.render_targets.push(RenderTargetInfo::{
    id,
    width: safe_width,
    height: safe_height,
  })
  for i in 0..<state.bloom2d_auto_targets.length() {
    let entry = state.bloom2d_auto_targets[i]
    if render2d_same_entity(entry.camera, camera) {
      state.bloom2d_auto_targets[i] = Bloom2dAutoTargetInfo::{
        camera,
        width: safe_width,
        height: safe_height,
        target: handle,
      }
      return handle
    }
  }
  state.bloom2d_auto_targets.push(Bloom2dAutoTargetInfo::{
    camera,
    width: safe_width,
    height: safe_height,
    target: handle,
  })
  handle
}

///|
fn render2d_clamp_viewport(
  viewport : Viewport,
  target_size : @math.IVec2,
) -> Viewport {
  let mut position_x = viewport.physical_position.x
  let mut position_y = viewport.physical_position.y
  let mut size_x = viewport.physical_size.x
  let mut size_y = viewport.physical_size.y
  let target_x = if target_size.x < 0 { 0 } else { target_size.x }
  let target_y = if target_size.y < 0 { 0 } else { target_size.y }
  if position_x < 0 {
    position_x = 0
  }
  if position_y < 0 {
    position_y = 0
  }
  if size_x < 0 {
    size_x = 0
  }
  if size_y < 0 {
    size_y = 0
  }
  if size_x + position_x > target_x {
    if position_x < target_x {
      size_x = target_x - position_x
    } else if target_x > 0 {
      position_x = target_x - 1
      size_x = 1
    } else {
      position_x = 0
      size_x = 0
    }
  }
  if size_y + position_y > target_y {
    if position_y < target_y {
      size_y = target_y - position_y
    } else if target_y > 0 {
      position_y = target_y - 1
      size_y = 1
    } else {
      position_y = 0
      size_y = 0
    }
  }
  Viewport::new(
    @math.IVec2::new(position_x, position_y),
    @math.IVec2::new(size_x, size_y),
  ).with_depth(viewport.depth_min, viewport.depth_max)
}

///|
fn render2d_camera_target_info_eq(
  a : CameraTargetInfo?,
  b : CameraTargetInfo?,
) -> Bool {
  match (a, b) {
    (Some(ta), Some(tb)) =>
      render2d_ivec2_eq(ta.physical_size, tb.physical_size) &&
      ta.scale_factor == tb.scale_factor
    (None, None) => true
    _ => false
  }
}

///|
fn render2d_camera_target_info_from_render_target(
  value : RenderTargetComputed?,
) -> CameraTargetInfo? {
  match value {
    Some(info) => Some(CameraTargetInfo::new(info.size, info.scale_factor))
    None => None
  }
}

///|
fn render2d_target_component_changed(
  target_store : @ecs.ComponentAccess[RenderTarget],
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  if !target_store.contains(entity) {
    return false
  }
  match target_store.get_ticks(entity) {
    Some(ticks) =>
      ticks.is_added(system_ticks) || ticks.is_changed(system_ticks)
    None => false
  }
}

///|
fn render2d_viewport_size_changed(camera : Camera) -> Bool {
  !render2d_opt_ivec2_eq(
    camera.computed.old_viewport_size,
    render2d_camera_viewport_size(camera),
  )
}

///|
fn render2d_ivec2_eq(a : @math.IVec2, b : @math.IVec2) -> Bool {
  a.x == b.x && a.y == b.y
}

///|
fn render2d_opt_ivec2_eq(a : @math.IVec2?, b : @math.IVec2?) -> Bool {
  match (a, b) {
    (Some(va), Some(vb)) => render2d_ivec2_eq(va, vb)
    (None, None) => true
    _ => false
  }
}

///|
fn render2d_scale_viewport_axis(value : Int, scale : Float) -> Int {
  if value <= 0 || scale <= 0.0F {
    return 0
  }
  let scaled = Float::from_double(value.to_double()) * scale
  if scaled <= 0.0F {
    return 0
  }
  scaled.to_int()
}

///|
fn render2d_scale_viewport(viewport : Viewport, scale : Float) -> Viewport {
  let position = @math.IVec2::new(
    render2d_scale_viewport_axis(viewport.physical_position.x, scale),
    render2d_scale_viewport_axis(viewport.physical_position.y, scale),
  )
  let size = @math.IVec2::new(
    render2d_scale_viewport_axis(viewport.physical_size.x, scale),
    render2d_scale_viewport_axis(viewport.physical_size.y, scale),
  )
  Viewport::new(position, size).with_depth(
    viewport.depth_min,
    viewport.depth_max,
  )
}

///|
fn render2d_camera_viewport_size(camera : Camera) -> @math.IVec2? {
  match camera.viewport {
    Some(viewport) => Some(viewport.physical_size)
    None => None
  }
}

///|
fn render2d_projection_changed(
  projection_store : @ecs.ComponentAccess[Projection],
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  if !projection_store.contains(entity) {
    return false
  }
  match projection_store.get_ticks(entity) {
    Some(ticks) =>
      ticks.is_added(system_ticks) || ticks.is_changed(system_ticks)
    None => false
  }
}

///|
fn render2d_camera_changed(
  camera_store : @ecs.ComponentAccess[Camera],
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  if !camera_store.contains(entity) {
    return false
  }
  match camera_store.get_ticks(entity) {
    Some(ticks) =>
      ticks.is_added(system_ticks) || ticks.is_changed(system_ticks)
    None => false
  }
}

///|
fn render2d_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
fn camera_tonemapping_mode(world : @ecs.World, camera : @core.Entity) -> Int {
  let store = world.component(ecs_key_tonemapping)
  match store.get(camera) {
    Some(mode) => render2d_tonemapping_mode_to_int(mode)
    None => 0
  }
}

///|
fn camera_deband_dither_enabled(
  world : @ecs.World,
  camera : @core.Entity,
) -> Bool {
  let store = world.component(ecs_key_deband_dither)
  match store.get(camera) {
    Some(Enabled) => true
    Some(Disabled) => false
    None => false
  }
}

///|
pub fn render2d_camera_system(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(render_state_ref_value) else { return }
  let tick = world.read_change_tick()
  let system_ticks = world.get_system_context().ticks()
  let ecs_world = world
  let camera2d_store = get_camera2d_store(ecs_world)
  let camera_store = get_camera_store(ecs_world)
  let projection_store = get_projection_store(ecs_world)
  let target_store = get_render_target_store(ecs_world)
  let render_state = render_state_ref_value
  camera2d_store.for_each(fn(entity, _marker) {
    let target = match target_store.get(entity) {
      Some(value) => value
      None => RenderTarget::Screen
    }
    let camera = match camera_store.get(entity) {
      Some(value) => value
      None => Camera::default()
    }
    projection_store.get(entity).unwrap_or(Projection::orthographic_2d())
    |> ignore

    let target_info = render2d_target_info(render_state, target)
    let next_target_info = render2d_camera_target_info_from_render_target(
      target_info,
    )
    let target_changed = render2d_target_component_changed(
        target_store, entity, system_ticks,
      ) ||
      !render2d_camera_target_info_eq(
        camera.computed.target_info,
        next_target_info,
      )
    let viewport_changed = render2d_viewport_size_changed(camera)
    let camera_changed = render2d_camera_changed(
      camera_store, entity, system_ticks,
    )
    let projection_changed = render2d_projection_changed(
      projection_store, entity, system_ticks,
    )
    let mut scale_factor_changed = false
    if target is RenderTarget::Screen &&
      camera.computed.target_info is Some(old_target_info) &&
      next_target_info is Some(new_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      new_target_info.scale_factor != old_target_info.scale_factor {
      scale_factor_changed = true
    }
    let should_update = target_changed ||
      viewport_changed ||
      camera_changed ||
      projection_changed ||
      scale_factor_changed

    let mut camera_value = camera
    if should_update {
      if scale_factor_changed &&
        camera.computed.target_info is Some(old_target_info) &&
        old_target_info.scale_factor > 0.0F &&
        camera_value.viewport is Some(viewport) &&
        next_target_info is Some(new_target_info) {
        let resize_factor = new_target_info.scale_factor /
          old_target_info.scale_factor
        let resized = render2d_scale_viewport(viewport, resize_factor)
        camera_value = camera_value.with_viewport(resized)
      }
      if target_info is Some(info) && camera_value.viewport is Some(viewport) {
        let clamped = render2d_clamp_viewport(viewport, info.size)
        camera_value = camera_value.with_viewport(clamped)
      }
      camera_value = Camera::{
        ..camera_value,
        computed: CameraComputedValues::{
          target_info: next_target_info,
          old_viewport_size: render2d_camera_viewport_size(camera_value),
        },
      }
      camera_store.set(entity, camera_value, tick) |> ignore
    }
  })
}

///|
fn render2d_transform_from_parent_chain_ecs(
  world : @ecs.World,
  entity : @core.Entity,
  max_depth : Int,
) -> @math.Transform {
  max_depth |> ignore
  (try! world.get(entity, @math.ecs_key_transform)).unwrap_or(
    @math.Transform::identity(),
  )
}

///|
fn render2d_resolve_transform_ecs(
  world : @ecs.World,
  entity : @core.Entity,
) -> @math.Transform {
  match (try! world.get(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None => render2d_transform_from_parent_chain_ecs(world, entity, 64)
  }
}

///|
fn render2d_visibility_from_parent_chain_ecs(
  world : @ecs.World,
  entity : @core.Entity,
  max_depth : Int,
) -> Bool {
  max_depth |> ignore
  let key : @ecs.ComponentKey[Json] = @visibility.ecs_key_view_visibility.cast()
  match (try! world.get(entity, key)) {
    Some(payload) => {
      let visible : Bool = try! @json.from_json(payload)
      visible
    }
    None => true
  }
}

///|
fn render2d_entity_visible_ecs(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  render2d_visibility_from_parent_chain_ecs(world, entity, 64)
}

///|
pub fn render2d_camera_system_ecs(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(render_state_ref_value) else { return }
  let render_state = render_state_ref_value
  let cameras : Array[@core.Entity] = []
  try! world
  .query1(ecs_key_camera2d)
  .view(fn(entity, _camera2d) { cameras.push(entity) })
  for entity in cameras {
    let target = (try! world.get(entity, ecs_key_render_target)).unwrap_or(
      RenderTarget::Screen,
    )
    let camera = (try! world.get(entity, ecs_key_camera)).unwrap_or(
      Camera::default(),
    )
    (try! world.get(entity, ecs_key_projection)).unwrap_or(
      Projection::orthographic_2d(),
    )
    |> ignore
    let target_info = render2d_target_info(render_state, target)
    let next_target_info = render2d_camera_target_info_from_render_target(
      target_info,
    )
    let mut camera_value = camera
    let mut scale_factor_changed = false
    if target is RenderTarget::Screen &&
      camera.computed.target_info is Some(old_target_info) &&
      next_target_info is Some(new_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      new_target_info.scale_factor != old_target_info.scale_factor {
      scale_factor_changed = true
    }
    if scale_factor_changed &&
      camera.computed.target_info is Some(old_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      camera_value.viewport is Some(viewport) &&
      next_target_info is Some(new_target_info) {
      let resize_factor = new_target_info.scale_factor /
        old_target_info.scale_factor
      let resized = render2d_scale_viewport(viewport, resize_factor)
      camera_value = camera_value.with_viewport(resized)
    }
    if target_info is Some(info) && camera_value.viewport is Some(viewport) {
      let clamped = render2d_clamp_viewport(viewport, info.size)
      camera_value = camera_value.with_viewport(clamped)
    }
    camera_value = Camera::{
      ..camera_value,
      computed: CameraComputedValues::{
        target_info: next_target_info,
        old_viewport_size: render2d_camera_viewport_size(camera_value),
      },
    }
    try! world.set(entity, ecs_key_camera, camera_value)
  }
}

///|
pub let camera_update_systems : @app.SystemSet = @app.system_set(
  "bevy.camera.update_systems",
)

///|
fn render2d_sorted_camera_indices(
  cameras : Array[CameraInstance],
) -> Array[Int] {
  let count = cameras.length()
  let indices : Array[Int] = []
  for i in 0..<count {
    indices.push(i)
  }
  for i in 0..<count {
    let mut min_index = i
    let mut min_order = cameras[indices[i]].camera.order
    for j in (i + 1)..<count {
      let order = cameras[indices[j]].camera.order
      if order < min_order {
        min_index = j
        min_order = order
      }
    }
    if min_index != i {
      let temp = indices[i]
      indices[i] = indices[min_index]
      indices[min_index] = temp
    }
  }
  indices
}

///|
pub fn render_extract_system(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.draw_enabled = true
    rs.val.primary_camera = @core.Entity::placeholder()
    rs.val.sprites.clear()
    rs.val.cameras.clear()
    rs.val.meshes.clear()
    let ecs_world = world
    let camera2d_store = get_camera2d_store(ecs_world)
    let camera_store = get_camera_store(ecs_world)
    let projection_store = get_projection_store(ecs_world)
    let target_store = get_render_target_store(ecs_world)
    let layers_store = get_render_layers_store(ecs_world)
    let bloom2d_store = get_bloom2d_store(ecs_world)
    let view_visibility_store = @visibility.get_view_visibility_store(ecs_world)
    let transform_store = @math.get_transform_store(ecs_world)
    let global_store = @transform.get_global_transform_store(ecs_world)
    camera2d_store.for_each(fn(entity, _marker) {
      let target = match target_store.get(entity) {
        Some(t) => t
        None => RenderTarget::Screen
      }
      let layers = match layers_store.get(entity) {
        Some(v) => v
        None => RenderLayers::default()
      }
      let bloom2d = bloom2d_store.get(entity)
      let camera = match camera_store.get(entity) {
        Some(v) => v
        None => Camera::default()
      }
      let projection = match projection_store.get(entity) {
        Some(Orthographic(p)) => p
        None => OrthographicProjection::default_2d()
      }
      let transform = match global_store.get(entity) {
        Some(gt) => gt.to_transform_approx()
        None =>
          match transform_store.get(entity) {
            Some(t) => t
            None => @math.Transform::identity()
          }
      }
      let mut computed = CameraComputed::{
        target_size: @math.IVec2::new(0, 0),
        scale_factor: 1.0F,
      }
      if camera.computed.target_info is Some(target_info) {
        let scale_factor = if target_info.scale_factor <= 0.0F {
          1.0F
        } else {
          target_info.scale_factor
        }
        computed = CameraComputed::{
          target_size: target_info.physical_size,
          scale_factor,
        }
      } else if render2d_target_info(rs.val, target) is Some(info) {
        let scale_factor = if info.scale_factor <= 0.0F {
          1.0F
        } else {
          info.scale_factor
        }
        computed = CameraComputed::{ target_size: info.size, scale_factor }
      }
      rs.val.cameras.push(CameraInstance::{
        entity,
        camera,
        projection,
        transform,
        target,
        layers,
        bloom2d,
        computed,
      })
    })
    if rs.val.cameras.length() > 0 {
      let order = render2d_sorted_camera_indices(rs.val.cameras)
      if order.length() > 0 {
        rs.val.primary_camera = rs.val.cameras[order[0]].entity
      }
    }
    render2d_prune_bloom2d_auto_targets(rs.val)
    let sprite_store = get_sprite_store(ecs_world)
    let anchor_store = get_anchor_store(ecs_world)
    let scissor_store = get_scissor_rect_store(ecs_world)
    sprite_store.for_each(fn(entity, sprite) {
      if view_visibility_store.get(entity) is Some(vv) && !vv.is_visible() {
        return
      }
      let anchor = match anchor_store.get(entity) {
        Some(a) => a
        None => Anchor::default()
      }
      let layers = match layers_store.get(entity) {
        Some(v) => v
        None => RenderLayers::default()
      }
      let transform = match global_store.get(entity) {
        Some(gt) => gt.to_transform_approx()
        None =>
          match transform_store.get(entity) {
            Some(t) => t
            None => @math.Transform::identity()
          }
      }
      let mut uv_min = default_uv_min()
      let mut uv_max = default_uv_max()
      let mut region_size = @math.Vec2::new(1.0F, 1.0F)
      if sprite_uv_from_sprite(sprite) is Some(info) {
        uv_min = info.uv_min
        uv_max = info.uv_max
        region_size = info.region_size
      }
      let draw_scale = sprite_draw_scale(
        sprite,
        @math.Vec2::new(transform.scale.x, transform.scale.y),
        region_size,
      )
      let scissor = match scissor_store.get(entity) {
        Some(v) => Some(v.rect)
        None => None
      }
      let has_custom_size = match sprite.custom_size {
        Some(_) => true
        None => false
      }
      let (
        uv_draw_min,
        uv_draw_max,
        draw_scale_for_host,
        local_offset,
        needs_repeat_sampler,
      ) = apply_sprite_image_mode(
        uv_min,
        uv_max,
        draw_scale,
        region_size,
        sprite.image_mode,
        has_custom_size,
      )
      let anchor_offset = sprite_anchor_offset(
        anchor,
        transform.rotation_z(),
        draw_scale_for_host,
        local_offset,
      )
      if needs_repeat_sampler {
        @asset.asset_set_texture_sampler(
          sprite.image,
          @asset.ImageSampler::LinearRepeat,
        )
      }
      if sprite_image_mode_uses_slices(sprite.image_mode) {
        let target_size = @math.Vec2::new(
          sprite_abs_float(draw_scale.x),
          sprite_abs_float(draw_scale.y),
        )
        let (texture_slices, target_slices, repeat) = compute_sprite_texture_slices(
          region_size,
          target_size,
          sprite.image_mode,
        )
        rs.val.extra_sprite_texture_slices.push(SpriteTextureSliceInstance::{
          entity,
          transform,
          anchor_offset,
          draw_scale,
          color: sprite.color,
          texture: sprite.image,
          layers,
          scissor,
          texture_slices,
          target_slices,
          repeat,
          atlas_rect: @math.Vec4::new(uv_min.x, uv_min.y, uv_max.x, uv_max.y),
        })
      } else {
        rs.val.sprites.push(SpriteInstance::{
          entity,
          transform,
          anchor_offset,
          draw_scale: draw_scale_for_host,
          color: sprite.color,
          texture: sprite.image,
          layers,
          uv_min: uv_draw_min,
          uv_max: uv_draw_max,
          scissor,
        })
      }
    })
    let mesh_store = get_mesh2d_store(ecs_world)
    let gpu_mesh_store = get_gpu_mesh2d_store(ecs_world)
    let color_material_store = get_color_material_store(ecs_world)
    let material_store = get_mesh_material2d_store(ecs_world)
    let wireframe_store = get_wireframe2d_store(ecs_world)
    let no_wireframe_store = get_no_wireframe2d_store(ecs_world)
    let wireframe_color_store = get_wireframe2d_color_store(ecs_world)
    let wireframe_config = if get_wireframe2d_config_resource(ecs_world).get()
      is Some(config) {
      Some(config)
    } else {
      None
    }
    mesh_store.for_each(fn(entity, mesh2d) {
      if view_visibility_store.get(entity) is Some(vv) && !vv.is_visible() {
        return
      }
      guard gpu_mesh_store.get(entity) is Some(gpu) else { return }
      let mat = if material_store.get(entity) is Some(material) {
        material.to_color_material()
      } else {
        match color_material_store.get(entity) {
          Some(color_material) => color_material
          None => return
        }
      }
      let layers = match layers_store.get(entity) {
        Some(v) => v
        None => RenderLayers::default()
      }
      let transform = match global_store.get(entity) {
        Some(gt) => gt.to_transform_approx()
        None =>
          match transform_store.get(entity) {
            Some(t) => t
            None => @math.Transform::identity()
          }
      }
      rs.val.meshes.push(MeshInstance::{
        entity,
        mesh_id: gpu.mesh_id,
        transform,
        color: mat.color(),
        alpha_mode: mat.alpha_mode(),
        texture: mat.texture(),
        uv_offset: mat.uv_offset(),
        uv_scale: mat.uv_scale(),
        layers,
      })

      if !render2d_mesh_should_draw_wireframe(
          wireframe_store.get(entity) is Some(_),
          no_wireframe_store.get(entity) is Some(_),
          wireframe_config,
        ) {
        return
      }
      guard render_mesh_asset_get(mesh2d.mesh) is Some(mesh_asset) else {
        return
      }
      let wireframe_color = render2d_mesh_wireframe_color(
        wireframe_color_store.get(entity),
        wireframe_config,
      )
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry) =>
          Gizmos::new()
          .with_layers(layers)
          .mesh_wireframe_2d(geometry, transform, wireframe_color)
        _ => ()
      }
    })
  })
  |> ignore
}

///|
pub fn render_extract_system_ecs(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.draw_enabled = true
    rs.val.primary_camera = @core.Entity::placeholder()
    rs.val.sprites.clear()
    rs.val.cameras.clear()
    rs.val.meshes.clear()
    // ECS camera components.
    try! world
    .query1(ecs_key_camera2d)
    .view(fn(entity, _camera2d) {
      let target = (try! world.get(entity, ecs_key_render_target)).unwrap_or(
        RenderTarget::Screen,
      )
      let layers = (try! world.get(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::default(),
      )
      let bloom2d = try! world.get(entity, ecs_key_bloom2d)
      let camera = (try! world.get(entity, ecs_key_camera)).unwrap_or(
        Camera::default(),
      )
      let projection = match (try! world.get(entity, ecs_key_projection)) {
        Some(Orthographic(p)) => p
        None => OrthographicProjection::default_2d()
      }
      let transform = render2d_resolve_transform_ecs(world, entity)
      let mut computed = CameraComputed::{
        target_size: @math.IVec2::new(0, 0),
        scale_factor: 1.0F,
      }
      if camera.computed.target_info is Some(target_info) {
        let scale_factor = if target_info.scale_factor <= 0.0F {
          1.0F
        } else {
          target_info.scale_factor
        }
        computed = CameraComputed::{
          target_size: target_info.physical_size,
          scale_factor,
        }
      } else if render2d_target_info(rs.val, target) is Some(info) {
        let scale_factor = if info.scale_factor <= 0.0F {
          1.0F
        } else {
          info.scale_factor
        }
        computed = CameraComputed::{ target_size: info.size, scale_factor }
      }
      rs.val.cameras.push(CameraInstance::{
        entity,
        camera,
        projection,
        transform,
        target,
        layers,
        bloom2d,
        computed,
      })
    })
    if rs.val.cameras.length() > 0 {
      let order = render2d_sorted_camera_indices(rs.val.cameras)
      if order.length() > 0 {
        rs.val.primary_camera = rs.val.cameras[order[0]].entity
      }
    }
    render2d_prune_bloom2d_auto_targets(rs.val)

    // ECS sprite components.
    try! world
    .query1(ecs_key_sprite)
    .view(fn(entity, sprite) {
      if !render2d_entity_visible_ecs(world, entity) {
        return
      }
      let anchor = (try! world.get(entity, ecs_key_anchor)).unwrap_or(
        Anchor::default(),
      )
      let layers = (try! world.get(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::default(),
      )
      let transform = render2d_resolve_transform_ecs(world, entity)
      let mut uv_min = default_uv_min()
      let mut uv_max = default_uv_max()
      let mut region_size = @math.Vec2::new(1.0F, 1.0F)
      if sprite_uv_from_sprite(sprite) is Some(info) {
        uv_min = info.uv_min
        uv_max = info.uv_max
        region_size = info.region_size
      }
      let draw_scale = sprite_draw_scale(
        sprite,
        @math.Vec2::new(transform.scale.x, transform.scale.y),
        region_size,
      )
      let scissor = match (try! world.get(entity, ecs_key_scissor_rect)) {
        Some(v) => Some(v.rect)
        None => None
      }
      let has_custom_size = match sprite.custom_size {
        Some(_) => true
        None => false
      }
      let (
        uv_draw_min,
        uv_draw_max,
        draw_scale_for_host,
        local_offset,
        needs_repeat_sampler,
      ) = apply_sprite_image_mode(
        uv_min,
        uv_max,
        draw_scale,
        region_size,
        sprite.image_mode,
        has_custom_size,
      )
      let anchor_offset = sprite_anchor_offset(
        anchor,
        transform.rotation_z(),
        draw_scale_for_host,
        local_offset,
      )
      if needs_repeat_sampler {
        @asset.asset_set_texture_sampler(
          sprite.image,
          @asset.ImageSampler::LinearRepeat,
        )
      }
      if sprite_image_mode_uses_slices(sprite.image_mode) {
        let target_size = @math.Vec2::new(
          sprite_abs_float(draw_scale.x),
          sprite_abs_float(draw_scale.y),
        )
        let (texture_slices, target_slices, repeat) = compute_sprite_texture_slices(
          region_size,
          target_size,
          sprite.image_mode,
        )
        rs.val.extra_sprite_texture_slices.push(SpriteTextureSliceInstance::{
          entity,
          transform,
          anchor_offset,
          draw_scale,
          color: sprite.color,
          texture: sprite.image,
          layers,
          scissor,
          texture_slices,
          target_slices,
          repeat,
          atlas_rect: @math.Vec4::new(uv_min.x, uv_min.y, uv_max.x, uv_max.y),
        })
      } else {
        rs.val.sprites.push(SpriteInstance::{
          entity,
          transform,
          anchor_offset,
          draw_scale: draw_scale_for_host,
          color: sprite.color,
          texture: sprite.image,
          layers,
          uv_min: uv_draw_min,
          uv_max: uv_draw_max,
          scissor,
        })
      }
    })

    let wireframe_config = if get_wireframe2d_config_resource(world).get()
      is Some(config) {
      Some(config)
    } else {
      None
    }

    // ECS mesh components.
    try! world
    .query1(ecs_key_mesh2d)
    .view(fn(entity, mesh2d) {
      if !render2d_entity_visible_ecs(world, entity) {
        return
      }
      guard (try! world.get(entity, ecs_key_gpu_mesh2d)) is Some(gpu) else {
        return
      }
      let mat = if (try! world.get(entity, ecs_key_mesh_material2d))
        is Some(material) {
        material.to_color_material()
      } else {
        match (try! world.get(entity, ecs_key_color_material)) {
          Some(color_material) => color_material
          None => return
        }
      }
      let layers = (try! world.get(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::default(),
      )
      let transform = render2d_resolve_transform_ecs(world, entity)
      rs.val.meshes.push(MeshInstance::{
        entity,
        mesh_id: gpu.mesh_id,
        transform,
        color: mat.color(),
        alpha_mode: mat.alpha_mode(),
        texture: mat.texture(),
        uv_offset: mat.uv_offset(),
        uv_scale: mat.uv_scale(),
        layers,
      })

      if !render2d_mesh_should_draw_wireframe(
          (try! world.get(entity, ecs_key_wireframe2d)) is Some(_),
          (try! world.get(entity, ecs_key_no_wireframe2d)) is Some(_),
          wireframe_config,
        ) {
        return
      }
      guard render_mesh_asset_get(mesh2d.mesh) is Some(mesh_asset) else {
        return
      }
      let wireframe_color = render2d_mesh_wireframe_color(
        try! world.get(entity, ecs_key_wireframe2d_color),
        wireframe_config,
      )
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry) =>
          Gizmos::new()
          .with_layers(layers)
          .mesh_wireframe_2d(geometry, transform, wireframe_color)
        _ => ()
      }
    })
  })
  |> ignore
}

///|
pub fn[W] render_prepare_system(_world : W) -> Unit {

}

///|
pub fn[W] render_queue_system(_world : W) -> Unit {

}

///|
fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn mesh_alpha_phase(alpha_mode : AlphaMode2d, alpha : Float) -> Int? {
  match alpha_mode {
    Opaque => Some(0)
    Blend => Some(if alpha >= 1.0F { 0 } else { 1 })
    Mask(cutoff) => if alpha >= cutoff { Some(0) } else { None }
  }
}

///|
fn mesh_draw_alpha(alpha_mode : AlphaMode2d, alpha : Float) -> Float? {
  match alpha_mode {
    Opaque => Some(1.0F)
    Blend => Some(alpha)
    Mask(cutoff) => if alpha >= cutoff { Some(1.0F) } else { None }
  }
}

///|
priv enum DrawKind {
  SpriteMain(Int)
  SpriteExtra(Int)
  SpriteTextureSliceExtra(Int)
  UiRectExtra(Int)
  UiBoxShadowExtra(Int)
  UiTextureSliceExtra(Int)
  Mesh(Int)
}

///|
priv struct DrawItem {
  kind : DrawKind
  z : Float
  // 0 = opaque, 1 = transparent (opaque first for stable blending).
  phase : Int
  // Rough pipeline grouping: 0 = sprite, 1 = mesh, 2 = ui.
  pipeline : Int
  // Batch key for opaque items (e.g. texture id / mesh id).
  batch : Int
  // Stable tie-break keys.
  entity_id : Int
  entity_generation : Int
  tie : Int
}

///|
fn draw_items_for_layers(
  sprites : Array[SpriteInstance],
  extra_sprites : Array[SpriteInstance],
  extra_sprite_texture_slices : Array[SpriteTextureSliceInstance],
  extra_ui_rects : Array[UiRectInstance],
  extra_ui_box_shadows : Array[UiBoxShadowInstance],
  extra_ui_texture_slices : Array[UiTextureSliceInstance],
  meshes : Array[MeshInstance],
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  for i in 0..<sprites.length() {
    let sprite = sprites[i]
    if !sprite.layers.matches(layers) {
      continue
    }
    let phase = if sprite.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: SpriteMain(i),
      z: sprite.transform.translation.z,
      phase,
      pipeline: 0,
      batch: sprite.texture.id(),
      entity_id: sprite.entity.id,
      entity_generation: sprite.entity.generation,
      tie: i,
    })
  }
  for i in 0..<extra_sprites.length() {
    let sprite = extra_sprites[i]
    if !sprite.layers.matches(layers) {
      continue
    }
    let phase = if sprite.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: SpriteExtra(i),
      z: sprite.transform.translation.z,
      phase,
      pipeline: 0,
      batch: sprite.texture.id(),
      entity_id: sprite.entity.id,
      entity_generation: sprite.entity.generation,
      // Ensure extra-sprites tie-break after main sprites with the same entity key.
      tie: 1_000_000 + i,
    })
  }
  for i in 0..<extra_sprite_texture_slices.length() {
    let slice = extra_sprite_texture_slices[i]
    if !slice.layers.matches(layers) {
      continue
    }
    let phase = if slice.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: SpriteTextureSliceExtra(i),
      z: slice.transform.translation.z,
      phase,
      pipeline: 0,
      batch: slice.texture.id(),
      entity_id: slice.entity.id,
      entity_generation: slice.entity.generation,
      tie: 1_500_000 + i,
    })
  }
  for i in 0..<extra_ui_rects.length() {
    let rect = extra_ui_rects[i]
    if !rect.layers.matches(layers) {
      continue
    }
    let phase = if rect.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: UiRectExtra(i),
      z: rect.transform.translation.z,
      phase,
      pipeline: 2,
      batch: rect.texture.id(),
      entity_id: rect.entity.id,
      entity_generation: rect.entity.generation,
      tie: 2_000_000 + i,
    })
  }
  for i in 0..<extra_ui_box_shadows.length() {
    let shadow = extra_ui_box_shadows[i]
    if !shadow.layers.matches(layers) {
      continue
    }
    let phase = if shadow.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: UiBoxShadowExtra(i),
      z: shadow.transform.translation.z,
      phase,
      pipeline: 2,
      batch: shadow.texture.id(),
      entity_id: shadow.entity.id,
      entity_generation: shadow.entity.generation,
      tie: 2_500_000 + i,
    })
  }
  for i in 0..<extra_ui_texture_slices.length() {
    let slice = extra_ui_texture_slices[i]
    if !slice.layers.matches(layers) {
      continue
    }
    let phase = if slice.color.a >= 1.0F { 0 } else { 1 }
    items.push(DrawItem::{
      kind: UiTextureSliceExtra(i),
      z: slice.transform.translation.z,
      phase,
      pipeline: 2,
      batch: slice.texture.id(),
      entity_id: slice.entity.id,
      entity_generation: slice.entity.generation,
      tie: 2_000_000 + i,
    })
  }
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.layers.matches(layers) {
      continue
    }
    guard mesh_alpha_phase(mesh.alpha_mode, mesh.color.a) is Some(phase) else {
      continue
    }
    items.push(DrawItem::{
      kind: Mesh(i),
      z: mesh.transform.translation.z,
      phase,
      pipeline: 1,
      batch: mesh.mesh_id,
      entity_id: mesh.entity.id,
      entity_generation: mesh.entity.generation,
      tie: i,
    })
  }
  items.sort_by(fn(a, b) {
    let cz = cmp_float(a.z, b.z)
    if cz != 0 {
      return cz
    }
    let cp = cmp_int(a.phase, b.phase)
    if cp != 0 {
      return cp
    }
    let cpipe = cmp_int(a.pipeline, b.pipeline)
    if cpipe != 0 {
      return cpipe
    }
    if a.phase == 0 {
      let cb = cmp_int(a.batch, b.batch)
      if cb != 0 {
        return cb
      }
    }
    let ce = cmp_int(a.entity_id, b.entity_id)
    if ce != 0 {
      return ce
    }
    let cg = cmp_int(a.entity_generation, b.entity_generation)
    if cg != 0 {
      return cg
    }
    cmp_int(a.tie, b.tie)
  })
  items
}

///|
test "render2d: unified draw items order sprites and meshes by z" {
  let layers = RenderLayers::default()
  let sprites : Array[SpriteInstance] = [
    SpriteInstance::{
      entity: @core.Entity::new(2, 0),
      transform: @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      anchor_offset: @math.Vec2::new(0.0F, 0.0F),
      draw_scale: @math.Vec2::new(1.0F, 1.0F),
      color: Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      texture: @asset.Handle::new(2),
      layers,
      uv_min: @math.Vec2::new(0.0F, 0.0F),
      uv_max: @math.Vec2::new(1.0F, 1.0F),
      scissor: None,
    },
  ]
  let extra : Array[SpriteInstance] = []
  let extra_sprite_slices : Array[SpriteTextureSliceInstance] = []
  let extra_ui : Array[UiRectInstance] = []
  let extra_shadow : Array[UiBoxShadowInstance] = []
  let extra_slices : Array[UiTextureSliceInstance] = []
  let meshes : Array[MeshInstance] = [
    MeshInstance::{
      entity: @core.Entity::new(1, 0),
      mesh_id: 7,
      transform: @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=-1.0F,
      ),
      color: Color::white(),
      alpha_mode: AlphaMode2d::Blend,
      texture: None,
      uv_offset: @math.Vec2::new(0.0F, 0.0F),
      uv_scale: @math.Vec2::new(1.0F, 1.0F),
      layers,
    },
  ]
  let items = draw_items_for_layers(
    sprites, extra, extra_sprite_slices, extra_ui, extra_shadow, extra_slices, meshes,
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
  inspect(ok, content="true")
}

///|
test "render2d: mesh opaque alpha mode stays in opaque phase" {
  let layers = RenderLayers::default()
  let sprites : Array[SpriteInstance] = []
  let extra : Array[SpriteInstance] = []
  let extra_sprite_slices : Array[SpriteTextureSliceInstance] = []
  let extra_ui : Array[UiRectInstance] = []
  let extra_shadow : Array[UiBoxShadowInstance] = []
  let extra_slices : Array[UiTextureSliceInstance] = []
  let meshes : Array[MeshInstance] = [
    MeshInstance::{
      entity: @core.Entity::new(2, 0),
      mesh_id: 10,
      transform: @math.Transform::identity(),
      color: Color::new(1.0F, 0.0F, 0.0F, 0.2F),
      alpha_mode: AlphaMode2d::Opaque,
      texture: None,
      uv_offset: @math.Vec2::new(0.0F, 0.0F),
      uv_scale: @math.Vec2::new(1.0F, 1.0F),
      layers,
    },
    MeshInstance::{
      entity: @core.Entity::new(1, 0),
      mesh_id: 11,
      transform: @math.Transform::identity(),
      color: Color::new(0.0F, 1.0F, 0.0F, 0.2F),
      alpha_mode: AlphaMode2d::Blend,
      texture: None,
      uv_offset: @math.Vec2::new(0.0F, 0.0F),
      uv_scale: @math.Vec2::new(1.0F, 1.0F),
      layers,
    },
  ]
  let items = draw_items_for_layers(
    sprites, extra, extra_sprite_slices, extra_ui, extra_shadow, extra_slices, meshes,
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is Mesh(1)
  inspect(ok, content="true")
}

///|
test "render2d: mesh mask alpha mode drops below cutoff" {
  let layers = RenderLayers::default()
  let sprites : Array[SpriteInstance] = []
  let extra : Array[SpriteInstance] = []
  let extra_sprite_slices : Array[SpriteTextureSliceInstance] = []
  let extra_ui : Array[UiRectInstance] = []
  let extra_shadow : Array[UiBoxShadowInstance] = []
  let extra_slices : Array[UiTextureSliceInstance] = []
  let meshes : Array[MeshInstance] = [
    MeshInstance::{
      entity: @core.Entity::new(1, 0),
      mesh_id: 20,
      transform: @math.Transform::identity(),
      color: Color::new(1.0F, 1.0F, 1.0F, 0.2F),
      alpha_mode: AlphaMode2d::Mask(0.5F),
      texture: None,
      uv_offset: @math.Vec2::new(0.0F, 0.0F),
      uv_scale: @math.Vec2::new(1.0F, 1.0F),
      layers,
    },
    MeshInstance::{
      entity: @core.Entity::new(2, 0),
      mesh_id: 21,
      transform: @math.Transform::identity(),
      color: Color::new(1.0F, 1.0F, 1.0F, 0.8F),
      alpha_mode: AlphaMode2d::Mask(0.5F),
      texture: None,
      uv_offset: @math.Vec2::new(0.0F, 0.0F),
      uv_scale: @math.Vec2::new(1.0F, 1.0F),
      layers,
    },
  ]
  let items = draw_items_for_layers(
    sprites, extra, extra_sprite_slices, extra_ui, extra_shadow, extra_slices, meshes,
    layers,
  )
  let ok = items.length() == 1 && items[0].kind is Mesh(1)
  inspect(ok, content="true")
}

///|
test "render2d: tiled sprite mode adjusts uv and draw scale" {
  let mode = SpriteImageMode::tiled(stretch_value=0.5F)
  let (uv_min, uv_max, draw_scale, local_offset, needs_repeat_sampler) = apply_tiled_sprite_image_mode(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.5F, 1.0F),
    mode,
  )
  let ok = uv_min.x == 0.0F &&
    uv_min.y == 0.0F &&
    uv_max.x == 1.0F &&
    uv_max.y == 2.0F &&
    draw_scale.x == 0.5F &&
    draw_scale.y == 0.5F &&
    local_offset.x == 0.0F &&
    local_offset.y == 0.0F &&
    needs_repeat_sampler
  inspect(ok, content="true")
}

///|
test "render2d: tiled sprite mode keeps non-tiled axis unchanged" {
  let mode = SpriteImageMode::tiled(
    tile_x=false,
    tile_y=true,
    stretch_value=0.25F,
  )
  let (uv_min, uv_max, draw_scale, local_offset, needs_repeat_sampler) = apply_tiled_sprite_image_mode(
    @math.Vec2::new(0.2F, 0.3F),
    @math.Vec2::new(0.6F, 0.9F),
    @math.Vec2::new(1.0F, 0.5F),
    mode,
  )
  let ok = uv_min.x == 0.2F &&
    uv_min.y == 0.3F &&
    uv_max.x == 0.6F &&
    uv_max.y == 1.5F &&
    draw_scale.x == 1.0F &&
    draw_scale.y == 0.25F &&
    local_offset.x == 0.0F &&
    local_offset.y == 0.0F &&
    needs_repeat_sampler
  inspect(ok, content="true")
}

///|
test "render2d: shape geometry builders validate" {
  let polyline = Polyline2d::new([
    @math.Vec2::new(-40.0F, 40.0F),
    @math.Vec2::new(0.0F, -40.0F),
    @math.Vec2::new(40.0F, 40.0F),
  ]).with_half_thickness(3.0F)
  let geometries : Array[@mesh.Mesh2dGeometry] = [
    circle_to_mesh2d_geometry(Circle::new(10.0F).with_vertices(24)),
    ellipse_to_mesh2d_geometry(Ellipse::new(8.0F, 12.0F).with_vertices(24)),
    annulus_to_mesh2d_geometry(Annulus::new(4.0F, 10.0F).with_vertices(24)),
    ring_to_mesh2d_geometry(Ring2d::new(10.0F, 7.0F).with_vertices(24)),
    circular_sector_ring_to_mesh2d_geometry(
      CircularSectorRing::new(
        CircularSector::new(10.0F, 1.0F).with_vertices(24),
        CircularSector::new(7.0F, 1.0F).with_vertices(24),
      ),
    ),
    circular_sector_to_mesh2d_geometry(
      CircularSector::from_turns(10.0F, 0.35F).with_vertices(24),
    ),
    circular_segment_ring_to_mesh2d_geometry(
      CircularSegment::from_turns(10.0F, 0.35F).with_vertices(24).to_ring(2.0F),
    ),
    circular_segment_to_mesh2d_geometry(
      CircularSegment::from_turns(10.0F, 0.35F).with_vertices(24),
    ),
    ellipse_ring_to_mesh2d_geometry(
      EllipseRing::new(
        Ellipse::new(8.0F, 12.0F).with_vertices(24),
        Ellipse::new(6.0F, 10.0F).with_vertices(24),
      ),
    ),
    rhombus_to_mesh2d_geometry(Rhombus::new(12.0F, 20.0F)),
    rhombus_ring_to_mesh2d_geometry(Rhombus::new(12.0F, 20.0F).to_ring(1.5F)),
    regular_polygon_to_mesh2d_geometry(RegularPolygon::new(10.0F, 6)),
    regular_polygon_ring_to_mesh2d_geometry(
      RegularPolygon::new(10.0F, 6).to_ring(1.0F),
    ),
    triangle_to_mesh2d_geometry(Triangle2d::default()),
    triangle_ring_to_mesh2d_geometry(Triangle2d::default().to_ring(0.1F)),
    segment_to_mesh2d_geometry(
      Segment2d::new(
        @math.Vec2::new(-30.0F, 30.0F),
        @math.Vec2::new(30.0F, -30.0F),
      ).with_half_thickness(3.0F),
    ),
    polyline_to_mesh2d_geometry(polyline),
    capsule_to_mesh2d_geometry(Capsule2d::new(5.0F, 10.0F, 16)),
    capsule_ring_to_mesh2d_geometry(
      Capsule2d::new(5.0F, 10.0F, 16).to_ring(1.0F),
    ),
    rectangle_to_mesh2d_geometry(Rectangle::new(10.0F, 20.0F)),
    rectangle_ring_to_mesh2d_geometry(
      Rectangle::new(10.0F, 20.0F).to_ring(1.0F),
    ),
  ]
  let mut ok = true
  for geometry in geometries {
    if geometry.validate() is Some(_) {
      ok = false
    }
    if geometry.triangle_count() is None {
      ok = false
    }
  }
  inspect(ok, content="true")
}

///|
test "render2d: camera viewport clamp matches bevy edge behavior" {
  let viewport = Viewport::new(
    @math.IVec2::new(260, 120),
    @math.IVec2::new(50, 20),
  )
  let clamped = render2d_clamp_viewport(viewport, @math.IVec2::new(200, 100))
  let ok = clamped.physical_position.x == 199 &&
    clamped.physical_position.y == 99 &&
    clamped.physical_size.x == 1 &&
    clamped.physical_size.y == 1
  inspect(ok, content="true")
}

///|
test "render2d: camera viewport scales with dpi resize factor" {
  let viewport = Viewport::new(
    @math.IVec2::new(10, 20),
    @math.IVec2::new(40, 30),
  )
  let scaled = render2d_scale_viewport(viewport, 1.5F)
  let ok = scaled.physical_position.x == 15 &&
    scaled.physical_position.y == 30 &&
    scaled.physical_size.x == 60 &&
    scaled.physical_size.y == 45
  inspect(ok, content="true")
}

///|
pub fn render_execute_system(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    if !rs.val.draw_enabled {
      return
    }
    rs.val.draw_enabled = false
    gizmos_prepare()
    let cameras = rs.val.cameras
    if cameras.length() == 0 {
      gizmos_clear()
      rs.val.extra_sprites.clear()
      rs.val.extra_sprite_texture_slices.clear()
      rs.val.extra_ui_rects.clear()
      rs.val.extra_ui_box_shadows.clear()
      rs.val.extra_ui_texture_slices.clear()
      return
    }
    let sprites = rs.val.sprites
    let extra_sprites = rs.val.extra_sprites
    let extra_sprite_texture_slices = rs.val.extra_sprite_texture_slices
    let extra_ui_rects = rs.val.extra_ui_rects
    let extra_ui_box_shadows = rs.val.extra_ui_box_shadows
    let extra_ui_texture_slices = rs.val.extra_ui_texture_slices
    let meshes = rs.val.meshes
    fn int_from_f32_floor_nonneg(x : Float) -> Int {
      if x <= 0.0F {
        0
      } else {
        x.to_int()
      }
    }

    fn physical_scissor_for_camera(
      rect : @math.Rect,
      viewport_x : Int,
      viewport_y : Int,
      viewport_w : Int,
      viewport_h : Int,
      scale_factor : Float,
    ) -> (Int, Int, Int, Int) {
      let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
      let min_x = int_from_f32_floor_nonneg(rect.min.x * sf)
      let min_y = int_from_f32_floor_nonneg(rect.min.y * sf)
      // Match Bevy-style clipping behavior more closely: clamp the max edge with
      // floor semantics to avoid leaking a trailing row/column into adjacent UI.
      let mut max_x = int_from_f32_floor_nonneg(rect.max.x * sf)
      let mut max_y = int_from_f32_floor_nonneg(rect.max.y * sf)
      if max_x < min_x {
        max_x = min_x
      }
      if max_y < min_y {
        max_y = min_y
      }
      let mut x = viewport_x + min_x
      let mut y = viewport_y + min_y
      let mut w = max_x - min_x
      let mut h = max_y - min_y
      // Clamp to the camera viewport in physical pixels.
      if x < viewport_x {
        let dx = viewport_x - x
        x = viewport_x
        w = w - dx
      }
      if y < viewport_y {
        let dy = viewport_y - y
        y = viewport_y
        h = h - dy
      }
      let max_w = viewport_w - (x - viewport_x)
      let max_h = viewport_h - (y - viewport_y)
      if w > max_w {
        w = max_w
      }
      if h > max_h {
        h = max_h
      }
      if w < 0 {
        w = 0
      }
      if h < 0 {
        h = 0
      }
      (x, y, w, h)
    }

    for index in render2d_sorted_camera_indices(cameras) {
      let camera = cameras[index]
      let mut target_id = -1
      let target_size = camera.computed.target_size
      let target_width = target_size.x
      let target_height = target_size.y
      if camera.target is Image(handle) {
        target_id = handle.id()
      }
      if target_width <= 0 || target_height <= 0 {
        continue
      }
      let mut scale_factor = camera.computed.scale_factor
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      let mut viewport_x = 0
      let mut viewport_y = 0
      let mut viewport_width = target_width
      let mut viewport_height = target_height
      let mut viewport_depth_min = 0.0F
      let mut viewport_depth_max = 1.0F
      let mut view_width = target_width
      let mut view_height = target_height
      if camera.camera.viewport is Some(viewport) {
        viewport_x = if viewport.physical_position.x < 0 {
          0
        } else {
          viewport.physical_position.x
        }
        viewport_y = if viewport.physical_position.y < 0 {
          0
        } else {
          viewport.physical_position.y
        }
        viewport_width = if viewport.physical_size.x < 0 {
          0
        } else {
          viewport.physical_size.x
        }
        viewport_height = if viewport.physical_size.y < 0 {
          0
        } else {
          viewport.physical_size.y
        }
        let max_width = if target_width - viewport_x < 0 {
          0
        } else {
          target_width - viewport_x
        }
        let max_height = if target_height - viewport_y < 0 {
          0
        } else {
          target_height - viewport_y
        }
        if viewport_width > max_width {
          viewport_width = max_width
        }
        if viewport_height > max_height {
          viewport_height = max_height
        }
        if viewport_width <= 0 || viewport_height <= 0 {
          continue
        }
        viewport_depth_min = viewport.depth_min
        viewport_depth_max = viewport.depth_max
        view_width = viewport_width
        view_height = viewport_height
      }
      let view_width_f = Float::from_double(view_width.to_double()) /
        scale_factor
      let view_height_f = Float::from_double(view_height.to_double()) /
        scale_factor
      let view_width_logical = view_width_f.to_int()
      let view_height_logical = view_height_f.to_int()
      if view_width_logical <= 0 || view_height_logical <= 0 {
        continue
      }
      let (clear_enabled, clear) = camera.camera.clear_color.resolve()
      let draw_items = draw_items_for_layers(
        sprites,
        extra_sprites,
        extra_sprite_texture_slices,
        extra_ui_rects,
        extra_ui_box_shadows,
        extra_ui_texture_slices,
        meshes,
        camera.layers,
      )
      fn draw_camera_items(
        draw_viewport_x : Int,
        draw_viewport_y : Int,
        draw_viewport_width : Int,
        draw_viewport_height : Int,
        draw_scale_factor : Float,
      ) -> Unit {
        let mut scissor_active = false
        let mut scissor_x = 0
        let mut scissor_y = 0
        let mut scissor_w = 0
        let mut scissor_h = 0
        fn apply_scissor(rect_opt : @math.Rect?) -> Unit {
          match rect_opt {
            None =>
              if scissor_active {
                @window.host_gpu_clear_scissor()
                scissor_active = false
              }
            Some(rect) => {
              let (sx, sy, sw, sh) = physical_scissor_for_camera(
                rect, draw_viewport_x, draw_viewport_y, draw_viewport_width, draw_viewport_height,
                draw_scale_factor,
              )
              if !scissor_active ||
                sx != scissor_x ||
                sy != scissor_y ||
                sw != scissor_w ||
                sh != scissor_h {
                @window.host_gpu_set_scissor(x=sx, y=sy, width=sw, height=sh)
                scissor_active = true
                scissor_x = sx
                scissor_y = sy
                scissor_w = sw
                scissor_h = sh
              }
            }
          }
        }

        for item in draw_items {
          match item.kind {
            SpriteMain(i) => {
              let sprite = sprites[i]
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @window.host_gpu_draw_sprite_uv(
                texture_id=sprite.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=sprite.draw_scale.x,
                scale_y=sprite.draw_scale.y,
                color_r=sprite.color.r,
                color_g=sprite.color.g,
                color_b=sprite.color.b,
                color_a=sprite.color.a,
                uv_min_x=sprite.uv_min.x,
                uv_min_y=sprite.uv_min.y,
                uv_max_x=sprite.uv_max.x,
                uv_max_y=sprite.uv_max.y,
              )
            }
            SpriteExtra(i) => {
              let sprite = extra_sprites[i]
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @window.host_gpu_draw_sprite_uv(
                texture_id=sprite.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=sprite.draw_scale.x,
                scale_y=sprite.draw_scale.y,
                color_r=sprite.color.r,
                color_g=sprite.color.g,
                color_b=sprite.color.b,
                color_a=sprite.color.a,
                uv_min_x=sprite.uv_min.x,
                uv_min_y=sprite.uv_min.y,
                uv_max_x=sprite.uv_max.x,
                uv_max_y=sprite.uv_max.y,
              )
            }
            SpriteTextureSliceExtra(i) => {
              let slice = extra_sprite_texture_slices[i]
              apply_scissor(slice.scissor)
              let transform = slice.transform
              let pos = @math.Vec2::new(
                transform.translation.x + slice.anchor_offset.x,
                transform.translation.y + slice.anchor_offset.y,
              )
              @window.host_gpu_draw_ui_texture_slice(
                texture_id=slice.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=slice.draw_scale.x,
                scale_y=slice.draw_scale.y,
                color_r=slice.color.r,
                color_g=slice.color.g,
                color_b=slice.color.b,
                color_a=slice.color.a,
                texture_slice_l=slice.texture_slices.x,
                texture_slice_t=slice.texture_slices.y,
                texture_slice_r=slice.texture_slices.z,
                texture_slice_b=slice.texture_slices.w,
                target_slice_l=slice.target_slices.x,
                target_slice_t=slice.target_slices.y,
                target_slice_r=slice.target_slices.z,
                target_slice_b=slice.target_slices.w,
                repeat_side_x=slice.repeat.x,
                repeat_side_y=slice.repeat.y,
                repeat_center_x=slice.repeat.z,
                repeat_center_y=slice.repeat.w,
                atlas_l=slice.atlas_rect.x,
                atlas_t=slice.atlas_rect.y,
                atlas_r=slice.atlas_rect.z,
                atlas_b=slice.atlas_rect.w,
              )
            }
            Mesh(i) => {
              apply_scissor(None)
              let mesh = meshes[i]
              guard mesh_draw_alpha(mesh.alpha_mode, mesh.color.a)
                is Some(draw_alpha) else {
                continue
              }
              let transform = mesh.transform
              let texture_id = match mesh.texture {
                Some(texture) => texture.id()
                None => -1
              }
              @window.host_gpu_draw_mesh(
                mesh_id=mesh.mesh_id,
                x=transform.translation.x,
                y=transform.translation.y,
                rotation=transform.rotation_z(),
                scale_x=transform.scale.x,
                scale_y=transform.scale.y,
                color_r=mesh.color.r,
                color_g=mesh.color.g,
                color_b=mesh.color.b,
                color_a=draw_alpha,
                texture_id~,
                uv_offset_x=mesh.uv_offset.x,
                uv_offset_y=mesh.uv_offset.y,
                uv_scale_x=mesh.uv_scale.x,
                uv_scale_y=mesh.uv_scale.y,
              )
            }
            UiRectExtra(i) => {
              let rect = extra_ui_rects[i]
              apply_scissor(rect.scissor)
              let transform = rect.transform
              let pos = @math.Vec2::new(
                transform.translation.x + rect.anchor_offset.x,
                transform.translation.y + rect.anchor_offset.y,
              )
              @window.host_gpu_draw_ui_rect(
                texture_id=rect.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=rect.draw_scale.x,
                scale_y=rect.draw_scale.y,
                color_r=rect.color.r,
                color_g=rect.color.g,
                color_b=rect.color.b,
                color_a=rect.color.a,
                uv_min_x=rect.uv_min.x,
                uv_min_y=rect.uv_min.y,
                uv_max_x=rect.uv_max.x,
                uv_max_y=rect.uv_max.y,
                flags=rect.flags,
                radius_tl=rect.radius.top_left,
                radius_tr=rect.radius.top_right,
                radius_br=rect.radius.bottom_right,
                radius_bl=rect.radius.bottom_left,
                border_left=rect.border.left,
                border_top=rect.border.top,
                border_right=rect.border.right,
                border_bottom=rect.border.bottom,
              )
            }
            UiBoxShadowExtra(i) => {
              let shadow = extra_ui_box_shadows[i]
              apply_scissor(shadow.scissor)
              let transform = shadow.transform
              let pos = @math.Vec2::new(
                transform.translation.x + shadow.anchor_offset.x,
                transform.translation.y + shadow.anchor_offset.y,
              )
              @window.host_gpu_draw_ui_box_shadow(
                texture_id=shadow.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=shadow.draw_scale.x,
                scale_y=shadow.draw_scale.y,
                color_r=shadow.color.r,
                color_g=shadow.color.g,
                color_b=shadow.color.b,
                color_a=shadow.color.a,
                size_x=shadow.size.x,
                size_y=shadow.size.y,
                radius_tl=shadow.radius.top_left,
                radius_tr=shadow.radius.top_right,
                radius_br=shadow.radius.bottom_right,
                radius_bl=shadow.radius.bottom_left,
                blur=shadow.blur,
                samples=shadow.samples,
              )
            }
            UiTextureSliceExtra(i) => {
              let slice = extra_ui_texture_slices[i]
              apply_scissor(slice.scissor)
              let transform = slice.transform
              let pos = @math.Vec2::new(
                transform.translation.x + slice.anchor_offset.x,
                transform.translation.y + slice.anchor_offset.y,
              )
              @window.host_gpu_draw_ui_texture_slice(
                texture_id=slice.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=slice.draw_scale.x,
                scale_y=slice.draw_scale.y,
                color_r=slice.color.r,
                color_g=slice.color.g,
                color_b=slice.color.b,
                color_a=slice.color.a,
                texture_slice_l=slice.texture_slices.x,
                texture_slice_t=slice.texture_slices.y,
                texture_slice_r=slice.texture_slices.z,
                texture_slice_b=slice.texture_slices.w,
                target_slice_l=slice.target_slices.x,
                target_slice_t=slice.target_slices.y,
                target_slice_r=slice.target_slices.z,
                target_slice_b=slice.target_slices.w,
                repeat_side_x=slice.repeat.x,
                repeat_side_y=slice.repeat.y,
                repeat_center_x=slice.repeat.z,
                repeat_center_y=slice.repeat.w,
                atlas_l=slice.atlas_rect.x,
                atlas_t=slice.atlas_rect.y,
                atlas_r=slice.atlas_rect.z,
                atlas_b=slice.atlas_rect.w,
              )
            }
          }
        }
      }

      let tonemapping_mode = camera_tonemapping_mode(world, camera.entity)
      let deband_dither_enabled = camera_deband_dither_enabled(
        world,
        camera.entity,
      )
      let mut auto_bloom_source : @asset.Handle[@asset.Image]? = None
      if camera.bloom2d is Some(bloom) {
        if bloom.source is None && camera.target is Screen {
          auto_bloom_source = Some(
            render2d_get_or_create_bloom2d_auto_target(
              rs.val,
              camera.entity,
              viewport_width,
              viewport_height,
            ),
          )
        }
      }

      if auto_bloom_source is Some(source) {
        @window.host_gpu_begin_pass(
          target_id=@asset.Handle::id(source),
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear.r,
          clear_g=clear.g,
          clear_b=clear.b,
          clear_a=clear.a,
          camera_x=camera.transform.translation.x,
          camera_y=camera.transform.translation.y,
          camera_rotation=camera.transform.rotation_z(),
          camera_scale=camera.projection.scale,
          viewport_x=0,
          viewport_y=0,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        draw_camera_items(0, 0, viewport_width, viewport_height, scale_factor)
        @window.host_gpu_end_pass()

        @window.host_gpu_begin_pass(
          target_id~,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear.r,
          clear_g=clear.g,
          clear_b=clear.b,
          clear_a=clear.a,
          camera_x=camera.transform.translation.x,
          camera_y=camera.transform.translation.y,
          camera_rotation=camera.transform.rotation_z(),
          camera_scale=camera.projection.scale,
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        render2d_draw_camera_bloom(
          camera, source, tonemapping_mode, deband_dither_enabled, viewport_width,
          viewport_height,
        )
        gizmos_draw_lines(camera.layers)
        @window.host_gpu_end_pass()
        continue
      }

      @window.host_gpu_begin_pass(
        target_id~,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear.r,
        clear_g=clear.g,
        clear_b=clear.b,
        clear_a=clear.a,
        camera_x=camera.transform.translation.x,
        camera_y=camera.transform.translation.y,
        camera_rotation=camera.transform.rotation_z(),
        camera_scale=camera.projection.scale,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=if clear_enabled { 1 } else { 0 },
      )
      draw_camera_items(
        viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
      )
      if camera.bloom2d is Some(bloom) && bloom.source is Some(source) {
        render2d_draw_camera_bloom(
          camera, source, tonemapping_mode, deband_dither_enabled, viewport_width,
          viewport_height,
        )
      }
      gizmos_draw_lines(camera.layers)
      @window.host_gpu_end_pass()
    }
    gizmos_clear()
    rs.val.extra_sprites.clear()
    rs.val.extra_sprite_texture_slices.clear()
    rs.val.extra_ui_rects.clear()
    rs.val.extra_ui_box_shadows.clear()
    rs.val.extra_ui_texture_slices.clear()
  })
  |> ignore
}

///|
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  screen : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world) is Some(rs) else { return None }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : CameraInstance? = None
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      found = Some(camera)
      break
    }
  }
  guard found is Some(cam) else { return None }
  render2d_camera_viewport_to_world_2d(
    screen,
    cam.camera,
    cam.projection,
    cam.transform,
    cam.computed.target_size,
    cam.computed.scale_factor,
  )
}

///|
pub fn render2d_world_to_viewport(
  world_ : @ecs.World,
  world : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world_) is Some(rs) else { return None }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : CameraInstance? = None
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      found = Some(camera)
      break
    }
  }
  guard found is Some(cam) else { return None }
  render2d_camera_world_to_viewport_2d(
    world,
    cam.camera,
    cam.projection,
    cam.transform,
    cam.computed.target_size,
    cam.computed.scale_factor,
  )
}

///|
/// Shared math for camera viewport conversions. `screen` is in logical pixels.
pub fn render2d_camera_viewport_to_world_2d(
  screen : @math.Vec2,
  camera : Camera,
  projection : OrthographicProjection,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut safe_scale_factor = scale_factor
  if safe_scale_factor <= 0.0F {
    safe_scale_factor = 1.0F
  }
  guard camera_viewport_rect_physical(width, height, camera.viewport)
    is Some((rect_x, rect_y, rect_width, rect_height)) else {
    return None
  }
  let rect_x_f = Float::from_double(rect_x.to_double()) / safe_scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / safe_scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) /
    safe_scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) /
    safe_scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let scale = if projection.scale == 0.0F { 1.0F } else { projection.scale }
  let local_x = screen.x - rect_x_f
  let local_y = screen.y - rect_y_f
  let view_x = (local_x - half_width) * scale
  let view_y = (half_height - local_y) * scale
  let rot_z = camera_transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let world_x = camera_transform.translation.x + view_x * cosv + view_y * sinv
  let world_y = camera_transform.translation.y - view_x * sinv + view_y * cosv
  Some(@math.Vec2::new(world_x, world_y))
}

///|
/// Shared math for camera viewport conversions. Return value is in logical pixels.
pub fn render2d_camera_world_to_viewport_2d(
  world : @math.Vec2,
  camera : Camera,
  projection : OrthographicProjection,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut safe_scale_factor = scale_factor
  if safe_scale_factor <= 0.0F {
    safe_scale_factor = 1.0F
  }
  guard camera_viewport_rect_physical(width, height, camera.viewport)
    is Some((rect_x, rect_y, rect_width, rect_height)) else {
    return None
  }
  let rect_x_f = Float::from_double(rect_x.to_double()) / safe_scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / safe_scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) /
    safe_scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) /
    safe_scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let dx = world.x - camera_transform.translation.x
  let dy = world.y - camera_transform.translation.y
  let rot_z = camera_transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let view_x = dx * cosv - dy * sinv
  let view_y = dx * sinv + dy * cosv
  let safe_scale = if projection.scale == 0.0F {
    1.0F
  } else {
    projection.scale
  }
  let local_x = view_x / safe_scale + half_width
  let local_y = half_height - view_y / safe_scale
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > rect_width_f ||
    local_y > rect_height_f {
    return None
  }
  Some(@math.Vec2::new(local_x + rect_x_f, local_y + rect_y_f))
}

///|
fn camera_viewport_rect_physical(
  target_width : Int,
  target_height : Int,
  viewport : Viewport?,
) -> (Int, Int, Int, Int)? {
  let width = target_width
  let height = target_height
  if width <= 0 || height <= 0 {
    return None
  }
  let mut rect_x = 0
  let mut rect_y = 0
  let mut rect_width = width
  let mut rect_height = height
  if viewport is Some(vp) {
    rect_x = if vp.physical_position.x < 0 { 0 } else { vp.physical_position.x }
    rect_y = if vp.physical_position.y < 0 { 0 } else { vp.physical_position.y }
    rect_width = if vp.physical_size.x < 0 { 0 } else { vp.physical_size.x }
    rect_height = if vp.physical_size.y < 0 { 0 } else { vp.physical_size.y }
    let max_width = if width - rect_x < 0 { 0 } else { width - rect_x }
    let max_height = if height - rect_y < 0 { 0 } else { height - rect_y }
    if rect_width > max_width {
      rect_width = max_width
    }
    if rect_height > max_height {
      rect_height = max_height
    }
    if rect_width <= 0 || rect_height <= 0 {
      return None
    }
  }
  Some((rect_x, rect_y, rect_width, rect_height))
}

///|
pub fn render2d_debug_log_primary_camera(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(rs) else { return }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return
  }
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      let target = camera.computed.target_size
      let scale = camera.computed.scale_factor
      let proj_scale = camera.projection.scale
      let mut viewport_text = "None"
      if camera.camera.viewport is Some(viewport) {
        let pos = viewport.physical_position
        let size = viewport.physical_size
        viewport_text = "pos=(" +
          pos.x.to_string() +
          "," +
          pos.y.to_string() +
          ") size=(" +
          size.x.to_string() +
          "," +
          size.y.to_string() +
          ")"
      }
      let message = "camera_debug target=(" +
        target.x.to_string() +
        "," +
        target.y.to_string() +
        ") scale=" +
        scale.to_string() +
        " proj_scale=" +
        proj_scale.to_string() +
        " viewport=" +
        viewport_text
      @window.host_debug_string(value=message)
      return
    }
  }
}

///|
pub let render2d_set_extract : @app.SystemSet = @app.system_set(
  "bevy.render2d.extract",
)

///|
pub let render2d_set_prepare : @app.SystemSet = @app.system_set(
  "bevy.render2d.prepare",
)

///|
pub let render2d_set_queue : @app.SystemSet = @app.system_set(
  "bevy.render2d.queue",
)

///|
pub let render2d_set_render : @app.SystemSet = @app.system_set(
  "bevy.render2d.render",
)

///|
/// Legacy alias kept for source compatibility.
pub let render2d_set_execute : @app.SystemSet = render2d_set_render

///|
pub fn render2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { ClearColor::default() })
  .add_startup_system(init_render_state_system)
  .add_post_update_system_config(
    @app.system(render2d_camera_system).in_set(camera_update_systems),
  )
  .add_post_update_system_config(
    @app.system(render_extract_system).in_set(render2d_set_extract),
  )
  .add_post_update_system_config(
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_post_update_system_config(
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(@app.PostUpdate, camera_update_systems, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare, before=[
    render2d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render2d_set_queue, before=[
    render2d_set_render,
  ])
}

///|
pub fn render2d_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { ClearColor::default() })
  .add_startup_system(init_render_state_system)
  .add_post_update_system_config(
    @app.system(render2d_camera_system_ecs).in_set(camera_update_systems),
  )
  .add_post_update_system_config(
    @app.system(render_extract_system_ecs).in_set(render2d_set_extract),
  )
  .add_post_update_system_config(
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_post_update_system_config(
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(@app.PostUpdate, camera_update_systems, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare, before=[
    render2d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render2d_set_queue, before=[
    render2d_set_render,
  ])
}
