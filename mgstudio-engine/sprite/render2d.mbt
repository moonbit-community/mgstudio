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
pub type Color = @color.Color

///|
pub type ColorGradingRange = @post_process.ColorGradingRange

///|
pub type ColorGradingGlobal = @post_process.ColorGradingGlobal

///|
pub type ColorGradingSection = @post_process.ColorGradingSection

///|
pub type ColorGrading = @post_process.ColorGrading

///|
pub type Tonemapping = @post_process.Tonemapping

///|
pub type DebandDither = @post_process.DebandDither

///|
pub type BloomPrefilter = @post_process.BloomPrefilter

///|
pub type BloomCompositeMode = @post_process.BloomCompositeMode

///|
pub type Bloom = @post_process.Bloom

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
let clear_color_resource_key : @ecs.ResourceKey[ClearColor] = @ecs.register_resource(
  debug_name="bevy_render::ClearColor",
)

///|
pub impl @app.Resource for ClearColor with resource() {
  clear_color_resource_key
}

///|
fn clear_color_current_value() -> Color {
  match @app.current_world() {
    Some(world) =>
      match (try! world.get_resource(ClearColor::resource())) {
        Some(clear_color) => clear_color.color
        None => clear_color_default_value()
      }
    None => clear_color_default_value()
  }
}

///|
fn render2d_current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "render2d asset helpers require an active app world; use the world-owned Assets<T> resources directly outside scheduled systems",
      )
  }
}

///|
fn[T] render2d_asset_store_or_abort() -> @asset.Assets[T] {
  let world = render2d_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None =>
      abort(
        "render2d asset resource is missing; Render2dPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn[T] render2d_asset_store_mut_or_abort() -> Ref[@asset.Assets[T]] {
  let world = render2d_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key, 0)) {
    Some(assets) => assets
    None =>
      abort(
        "render2d asset resource is missing; Render2dPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn mesh_assets_or_abort() -> @asset.Assets[@mesh.Mesh] {
  render2d_asset_store_or_abort()
}

///|
fn mesh_assets_mut_or_abort() -> Ref[@asset.Assets[@mesh.Mesh]] {
  render2d_asset_store_mut_or_abort()
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
pub(all) struct PanCamera {
  mut enabled : Bool
  mut zoom_factor : Float
  mut min_zoom : Float
  mut max_zoom : Float
  mut zoom_speed : Float
  mut key_zoom_in : @window.KeyCode?
  mut key_zoom_out : @window.KeyCode?
  mut pan_speed : Float
  mut key_up : @window.KeyCode?
  mut key_down : @window.KeyCode?
  mut key_left : @window.KeyCode?
  mut key_right : @window.KeyCode?
  mut rotation_speed : Float
  mut key_rotate_ccw : @window.KeyCode?
  mut key_rotate_cw : @window.KeyCode?
} derive(ToJson, FromJson)

///|
pub fn PanCamera::default() -> PanCamera {
  PanCamera::{
    enabled: true,
    zoom_factor: 1.0F,
    min_zoom: 0.1F,
    max_zoom: 5.0F,
    zoom_speed: 0.1F,
    key_zoom_in: Some(@window.KeyCode::Equal),
    key_zoom_out: Some(@window.KeyCode::Minus),
    pan_speed: 500.0F,
    key_up: Some(@window.KeyCode::KeyW),
    key_down: Some(@window.KeyCode::KeyS),
    key_left: Some(@window.KeyCode::KeyA),
    key_right: Some(@window.KeyCode::KeyD),
    rotation_speed: 3.141592653589793F,
    key_rotate_ccw: Some(@window.KeyCode::KeyQ),
    key_rotate_cw: Some(@window.KeyCode::KeyE),
  }
}

///|
fn pan_camera_keycode_to_string(code : @window.KeyCode) -> String {
  match code {
    @window.KeyCode::KeyA => "KeyA"
    @window.KeyCode::KeyB => "KeyB"
    @window.KeyCode::KeyC => "KeyC"
    @window.KeyCode::KeyD => "KeyD"
    @window.KeyCode::KeyE => "KeyE"
    @window.KeyCode::KeyF => "KeyF"
    @window.KeyCode::KeyG => "KeyG"
    @window.KeyCode::KeyH => "KeyH"
    @window.KeyCode::KeyI => "KeyI"
    @window.KeyCode::KeyJ => "KeyJ"
    @window.KeyCode::KeyK => "KeyK"
    @window.KeyCode::KeyL => "KeyL"
    @window.KeyCode::KeyM => "KeyM"
    @window.KeyCode::KeyN => "KeyN"
    @window.KeyCode::KeyO => "KeyO"
    @window.KeyCode::KeyP => "KeyP"
    @window.KeyCode::KeyQ => "KeyQ"
    @window.KeyCode::KeyR => "KeyR"
    @window.KeyCode::KeyS => "KeyS"
    @window.KeyCode::KeyT => "KeyT"
    @window.KeyCode::KeyU => "KeyU"
    @window.KeyCode::KeyV => "KeyV"
    @window.KeyCode::KeyW => "KeyW"
    @window.KeyCode::KeyX => "KeyX"
    @window.KeyCode::KeyY => "KeyY"
    @window.KeyCode::KeyZ => "KeyZ"
    @window.KeyCode::Digit1 => "Digit1"
    @window.KeyCode::Digit2 => "Digit2"
    @window.KeyCode::Digit3 => "Digit3"
    @window.KeyCode::Digit4 => "Digit4"
    @window.KeyCode::Digit5 => "Digit5"
    @window.KeyCode::Digit6 => "Digit6"
    @window.KeyCode::Digit7 => "Digit7"
    @window.KeyCode::Digit8 => "Digit8"
    @window.KeyCode::Tab => "Tab"
    @window.KeyCode::Enter => "Enter"
    @window.KeyCode::Backspace => "Backspace"
    @window.KeyCode::ShiftLeft => "ShiftLeft"
    @window.KeyCode::ShiftRight => "ShiftRight"
    @window.KeyCode::ControlLeft => "ControlLeft"
    @window.KeyCode::ControlRight => "ControlRight"
    @window.KeyCode::ArrowUp => "ArrowUp"
    @window.KeyCode::ArrowDown => "ArrowDown"
    @window.KeyCode::ArrowLeft => "ArrowLeft"
    @window.KeyCode::ArrowRight => "ArrowRight"
    @window.KeyCode::PageUp => "PageUp"
    @window.KeyCode::PageDown => "PageDown"
    @window.KeyCode::Space => "Space"
    @window.KeyCode::Escape => "Escape"
    @window.KeyCode::Semicolon => "Semicolon"
    @window.KeyCode::Comma => "Comma"
    @window.KeyCode::Period => "Period"
    @window.KeyCode::Slash => "Slash"
    @window.KeyCode::Minus => "Minus"
    @window.KeyCode::Equal => "Equal"
    @window.KeyCode::NumpadAdd => "NumpadAdd"
    @window.KeyCode::NumpadSubtract => "NumpadSubtract"
    @window.KeyCode::BracketLeft => "BracketLeft"
    @window.KeyCode::BracketRight => "BracketRight"
    @window.KeyCode::Quote => "Quote"
  }
}

///|
fn PanCamera::key_to_string(key : @window.KeyCode?) -> String {
  match key {
    Some(value) => pan_camera_keycode_to_string(value)
    None => "None"
  }
}

///|
pub impl Show for PanCamera with output(self, logger) {
  logger.write_string(
    "\nPanCamera Controls:\n" +
    "  Move Up / Down    - \{PanCamera::key_to_string(self.key_up)} / \{PanCamera::key_to_string(self.key_down)}\n" +
    "  Move Left / Right - \{PanCamera::key_to_string(self.key_left)} / \{PanCamera::key_to_string(self.key_right)}\n" +
    "  Rotate CCW / CW   - \{PanCamera::key_to_string(self.key_rotate_ccw)} / \{PanCamera::key_to_string(self.key_rotate_cw)}\n" +
    "  Zoom              - Mouse Scroll + \{PanCamera::key_to_string(self.key_zoom_in)} / \{PanCamera::key_to_string(self.key_zoom_out)}\n",
  )
}

///|

///|
pub(all) enum RenderTarget {
  Screen
  Window(@window.WindowRef)
  Image(@asset.Handle[@asset.Image])
}

///|
pub type Capsule2d = @math.Capsule2d

///|
pub type Rectangle = @math.Rectangle

///|
pub type Circle = @math.Circle

///|
pub type Arc2d = @math.Arc2d

///|
pub type Ellipse = @math.Ellipse

///|
pub type Annulus = @math.Annulus

///|
pub type Line2d = @math.Line2d

///|
pub type Plane2d = @math.Plane2d

///|
pub type Rhombus = @math.Rhombus

///|
pub type RegularPolygon = @math.RegularPolygon

///|
pub type Triangle2d = @math.Triangle2d

///|
pub type Segment2d = @math.Segment2d

///|
pub type Polyline2d = @math.Polyline2d

///|
pub type Polygon = @math.Polygon

///|
pub type ConvexPolygon = @math.ConvexPolygon

///|
pub type CircularMeshUvMode = @math.CircularMeshUvMode

///|
pub type CircularSector = @math.CircularSector

///|
pub type CircularSegment = @math.CircularSegment

///|
pub type Capsule2dRing = @math.Capsule2dRing

///|
pub type RectangleRing = @math.RectangleRing

///|
pub type EllipseRing = @math.EllipseRing

///|
pub type Ring2d = @math.Ring2d

///|
pub type RhombusRing = @math.RhombusRing

///|
pub type RegularPolygonRing = @math.RegularPolygonRing

///|
pub type Triangle2dRing = @math.Triangle2dRing

///|
pub type CircularSectorRing = @math.CircularSectorRing

///|
pub type CircularSegmentRing = @math.CircularSegmentRing

///|
pub struct Mesh2d {
  mesh : @asset.Handle[@mesh.Mesh]
}

///|
let mesh_upload_cache : Ref[@hashmap.HashMap[Int, Int]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
fn mesh_upload_cache_sync_with_asset_events() -> Unit {
  for event in mesh_assets_mut_or_abort().val.drain_events() {
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
  mesh_assets_mut_or_abort().val.add(mesh)
}

///|
pub fn render_mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_asset_add(mesh)
}

///|
fn mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_assets_or_abort().get(handle)
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
  mesh_assets_mut_or_abort().val.set(handle, mesh)
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
              @render.host_gpu_create_mesh_triangles_xyuvrgba(
                vertices_xyuvrgba_csv=vertices_csv,
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
          match geometry3d.encode_interleaved_xyz_normal_uv_rgba_csv() {
            Some(vertices_csv) =>
              @render.host_gpu_create_mesh3d(
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
    // Positions are ordered bottom-left -> bottom-right -> top-right -> top-left.
    // Use top-origin V (same visual orientation as Bevy's Rectangle mesh UVs).
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
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
  transform : @transform.Transform
  layers : RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn SpriteBundle::new(
  sprite : Sprite,
  transform : @transform.Transform,
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
  transform : @transform.Transform,
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
  transform : @transform.Transform
  target : RenderTarget
  layers : RenderLayers
  bloom : Bloom?
  tonemapping : Tonemapping?
  color_grading : ColorGrading?
  deband_dither : DebandDither?
}

///|
pub fn Camera2dBundle::new(
  camera : Camera,
  transform : @transform.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection: Projection::orthographic_2d(),
    camera2d: Camera2d::default(),
    transform,
    target: RenderTarget::Screen,
    layers: RenderLayers::default(),
    bloom: None,
    tonemapping: Some(Tonemapping::None),
    color_grading: None,
    deband_dither: Some(DebandDither::Disabled),
  }
}

///|
pub fn Camera2dBundle::new_with_projection(
  camera : Camera,
  projection : Projection,
  transform : @transform.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection,
    camera2d: Camera2d::default(),
    transform,
    target: RenderTarget::Screen,
    layers: RenderLayers::default(),
    bloom: None,
    tonemapping: Some(Tonemapping::None),
    color_grading: None,
    deband_dither: Some(DebandDither::Disabled),
  }
}

///|
pub fn Camera2dBundle::new_with_target(
  camera : Camera,
  transform : @transform.Transform,
  target : RenderTarget,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    projection: Projection::orthographic_2d(),
    camera2d: Camera2d::default(),
    transform,
    target,
    layers: RenderLayers::default(),
    bloom: None,
    tonemapping: Some(Tonemapping::None),
    color_grading: None,
    deband_dither: Some(DebandDither::Disabled),
  }
}

///|
pub fn Camera2dBundle::new_with_layers(
  camera : Camera,
  transform : @transform.Transform,
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
    bloom: None,
    tonemapping: Some(Tonemapping::None),
    color_grading: None,
    deband_dither: Some(DebandDither::Disabled),
  }
}

///|
pub fn Camera2dBundle::with_bloom(
  self : Camera2dBundle,
  bloom : Bloom?,
) -> Camera2dBundle {
  Camera2dBundle::{ ..self, bloom, }
}

///|
pub fn Camera2dBundle::with_tonemapping(
  self : Camera2dBundle,
  tonemapping : Tonemapping?,
) -> Camera2dBundle {
  Camera2dBundle::{ ..self, tonemapping, }
}

///|
pub fn Camera2dBundle::with_color_grading(
  self : Camera2dBundle,
  color_grading : ColorGrading?,
) -> Camera2dBundle {
  Camera2dBundle::{ ..self, color_grading, }
}

///|
pub fn Camera2dBundle::with_deband_dither(
  self : Camera2dBundle,
  deband_dither : DebandDither?,
) -> Camera2dBundle {
  Camera2dBundle::{ ..self, deband_dither, }
}

///|
pub struct Mesh2dBundle {
  mesh : Mesh2d
  material : MeshMaterial2d[ColorMaterialAsset]
  transform : @transform.Transform
  layers : RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn Mesh2dBundle::new(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @transform.Transform,
) -> Mesh2dBundle {
  Mesh2dBundle::new_with_mesh_material(
    mesh,
    MeshMaterial2d::from_color_material(material),
    transform,
  )
}

///|
pub fn Mesh2dBundle::new_with_mesh_material(
  mesh : Mesh2d,
  material : MeshMaterial2d[ColorMaterialAsset],
  transform : @transform.Transform,
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
pub fn Mesh2dBundle::new_with_layers(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @transform.Transform,
  layers : RenderLayers,
) -> Mesh2dBundle {
  Mesh2dBundle::new_with_mesh_material_layers(
    mesh,
    MeshMaterial2d::from_color_material(material),
    transform,
    layers,
  )
}

///|
pub fn Mesh2dBundle::new_with_mesh_material_layers(
  mesh : Mesh2d,
  material : MeshMaterial2d[ColorMaterialAsset],
  transform : @transform.Transform,
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
) -> @transform.Transform {
  let local_center = tilemap_chunk_local_center(self, tile_pos)
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    self.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  @transform.Transform::from_xy_rotation_scale(
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
  transform : @transform.Transform,
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
  transform : @transform.Transform,
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
      let tile_transform = @transform.Transform::from_xy_rotation_scale(
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
fn render2d_sanitize_bloom(bloom : Bloom) -> Bloom {
  Bloom::new(bloom.intensity)
  .with_low_frequency_boost(bloom.low_frequency_boost)
  .with_low_frequency_boost_curvature(bloom.low_frequency_boost_curvature)
  .with_high_pass_frequency(bloom.high_pass_frequency)
  .with_prefilter(bloom.prefilter.threshold, bloom.prefilter.threshold_softness)
  .with_composite_mode(bloom.composite_mode)
  .with_max_mip_dimension(
    bloom2d_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  .with_scale(
    @math.Vec2::new(
      bloom2d_safe_scale_axis(bloom.scale.x),
      bloom2d_safe_scale_axis(bloom.scale.y),
    ),
  )
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
fn bloom2d_mip_count(bloom : Bloom) -> Int {
  let logv = bloom2d_log2_floor(
    bloom2d_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  let mip_count = if logv < 2 { 1 } else { logv - 1 }
  if mip_count < 1 {
    1
  } else {
    mip_count
  }
}

///|
fn bloom2d_prefilter_weight(bloom : Bloom) -> Float {
  let threshold = bloom2d_clamp_non_negative(bloom.prefilter.threshold)
  let softness = bloom2d_clamp_unit(bloom.prefilter.threshold_softness)
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
  bloom : Bloom,
  mip : Float,
  max_mip : Float,
) -> Float {
  if max_mip <= 0.0F {
    return bloom.intensity
  }
  let mip_ratio = bloom2d_clamp_unit(mip / max_mip)
  let curvature = bloom2d_clamp_unit(bloom.low_frequency_boost_curvature)
  let exponent = if curvature >= 0.9999F {
    10_000.0F
  } else {
    1.0F / (1.0F - curvature)
  }
  let mut lf_boost = (1.0F - @math.pow(1.0F - mip_ratio, exponent)) *
    bloom.low_frequency_boost
  let high_pass = bloom2d_clamp_unit(bloom.high_pass_frequency)
  let high_pass_lq = if high_pass <= 1.0e-6F {
    if mip_ratio <= 0.0F {
      1.0F
    } else {
      0.0F
    }
  } else {
    1.0F - bloom2d_clamp_unit((mip_ratio - high_pass) / high_pass)
  }
  let mode_factor = match bloom.composite_mode {
    EnergyConserving => 1.0F - bloom.intensity
    Additive => 1.0F
  }
  lf_boost = lf_boost * mode_factor
  (bloom.intensity + lf_boost) * high_pass_lq
}

///|
fn bloom2d_pass_scale_factor(
  bloom : Bloom,
  pass_index : Int,
  max_mip : Int,
) -> @math.Vec2 {
  let max_mip_float = if max_mip <= 0 { 1.0F } else { Float::from_int(max_mip) }
  let pass_ratio = bloom2d_clamp_unit(
    Float::from_int(pass_index) / max_mip_float,
  )
  let blur_scale = 0.35F * (0.2F + pass_ratio * 0.8F)
  @math.Vec2::new(
    1.0F + blur_scale * bloom.scale.x,
    1.0F + blur_scale * bloom.scale.y,
  )
}

///|
pub fn render2d_draw_bloom_overlay(
  world : @ecs.World,
  source : @asset.Handle[@asset.Image],
  base_transform : @transform.Transform,
  bloom : Bloom,
  layers : RenderLayers,
) -> Unit {
  let bloom = render2d_sanitize_bloom(bloom)
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
    let pass_transform = @transform.Transform::from_xy_rotation_scale(
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
const MESH2D_SHADER_PATH : String = "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"

///|
const MESH2D_SHADER_BINDINGS_PATH : String = "shaders/bevy_sprite_render/mesh2d/mesh2d_bindings.wgsl"

///|
const MESH2D_WIREFRAME_SHADER_PATH : String = "shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl"

///|
const SPRITE_SHADER_PATH : String = "shaders/bevy_sprite_render/render/sprite.wgsl"

///|
const SPRITE_VIEW_BINDINGS_PATH : String = "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl"

///|
fn render2d_asset_server_or_abort(world : @ecs.World) -> @asset.AssetServer {
  match (try! world.get_resource(@asset.asset_server_resource_key())) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "Render2dPlugin requires the world-owned AssetServer resource; add AssetPlugin before Render2dPlugin",
      )
  }
}

///|
fn render2d_bevy_shader_asset_paths() -> Array[String] {
  [
    MESH2D_SHADER_PATH,
    MESH2D_SHADER_BINDINGS_PATH,
    "shaders/bevy_sprite_render/mesh2d/color_material.wgsl",
    MESH2D_WIREFRAME_SHADER_PATH,
    SPRITE_SHADER_PATH,
    SPRITE_VIEW_BINDINGS_PATH,
    "shaders/bevy_post_process/bloom/bloom.wgsl",
    "shaders/bevy_ui_render/ui.wgsl",
    "shaders/bevy_ui_render/box_shadow.wgsl",
    "shaders/bevy_ui_render/ui_texture_slice.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_types.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_vertex_output.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_view_types.wgsl",
    "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/lut_bindings.wgsl",
    "shaders/bevy_render/globals.wgsl",
    "shaders/bevy_render/maths.wgsl",
    "shaders/bevy_render/view/view.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping_shared.wgsl",
  ]
}

///|
fn register_render2d_bevy_shader_sources(world : @ecs.World) -> Unit {
  let asset_server = render2d_asset_server_or_abort(world)
  for path in render2d_bevy_shader_asset_paths() {
    let blob = asset_server.load_bytes(path)
    guard @asset.asset_blob_read_text(blob) is Some(source) else {
      abort("failed to load render2d shader asset text: " + path)
    }
    @render.register_wgsl_source(path, source)
  }
}

///|
priv struct TonemappingLutHandles {
  agx : @asset.Handle[@asset.Image]
  tony : @asset.Handle[@asset.Image]
  blender : @asset.Handle[@asset.Image]
}

///|
priv struct Render2dCameraPostprocessPlan {
  uses_intermediate_source : Bool
  apply_bloom_before_tonemapping : Bool
  tonemap_source_to_target : Bool
  draw_ui_overlay_after_postprocess : Bool
}

///|
fn render2d_camera_postprocess_plan(
  bloom : Bloom?,
  tonemapping_mode : Int,
  color_grading : ColorGrading?,
) -> Render2dCameraPostprocessPlan {
  let tonemapping_enabled = render2d_tonemapping_stage_enabled(
    tonemapping_mode, color_grading,
  )
  let uses_intermediate_source = bloom is Some(_) || tonemapping_enabled
  Render2dCameraPostprocessPlan::{
    uses_intermediate_source,
    apply_bloom_before_tonemapping: bloom is Some(_),
    tonemap_source_to_target: uses_intermediate_source,
    draw_ui_overlay_after_postprocess: uses_intermediate_source,
  }
}

///|
fn render2d_tonemapping_lut_handles(
  world : @ecs.World,
) -> TonemappingLutHandles {
  ensure_render_state_resource(world)
  if render_state_ref(world) is Some(state) {
    if state.tonemapping_lut_handles is Some(handles) {
      return handles
    }
  }
  let asset_server = render2d_asset_server_or_abort(world)
  let handles = TonemappingLutHandles::{
    agx: asset_server.load(TONEMAPPING_LUT_AGX_PATH),
    tony: asset_server.load(TONEMAPPING_LUT_TONY_PATH),
    blender: asset_server.load(TONEMAPPING_LUT_BLENDER_PATH),
  }
  render_state_update(world, fn(state) {
    state.val.tonemapping_lut_handles = Some(handles)
  })
  |> ignore
  handles
}

///|
fn render2d_draw_camera_tonemapping(
  world : @ecs.World,
  source : @asset.Handle[@asset.Image],
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  color_grading : ColorGrading?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let luts = render2d_tonemapping_lut_handles(world)
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_draw_tonemapping2d(
    scene_texture_id=source.id(),
    exposure=1.0F,
    tonemapping_mode~,
    deband_dither_enabled=if deband_dither_enabled { 1 } else { 0 },
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
    color_grading=color_grading_uniform,
  )
}

///|
fn render2d_apply_camera_bloom_from_source(
  camera : ExtractedCamera2d,
  source : @asset.Handle[@asset.Image],
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  guard camera.bloom is Some(bloom) else { return }
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let settings = render2d_sanitize_bloom(bloom)
  @render.host_gpu_apply_bloom(
    scene_texture_id=source.id(),
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
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
priv struct PhaseEntityRef {
  render_entity : @core.Entity
  main_entity : @core.Entity
}

///|
fn phase_entity_ref_for_main(main_entity : @core.Entity) -> PhaseEntityRef {
  PhaseEntityRef::{ render_entity: main_entity, main_entity }
}

///|
fn phase_entity_ref_placeholder() -> PhaseEntityRef {
  let placeholder = @core.Entity::placeholder()
  PhaseEntityRef::{ render_entity: placeholder, main_entity: placeholder }
}

///|
fn phase_entity_ref_cmp(lhs : PhaseEntityRef, rhs : PhaseEntityRef) -> Int {
  let render_id = cmp_int(lhs.render_entity.id, rhs.render_entity.id)
  if render_id != 0 {
    return render_id
  }
  let render_generation = cmp_int(
    lhs.render_entity.generation,
    rhs.render_entity.generation,
  )
  if render_generation != 0 {
    return render_generation
  }
  let main_id = cmp_int(lhs.main_entity.id, rhs.main_entity.id)
  if main_id != 0 {
    return main_id
  }
  cmp_int(lhs.main_entity.generation, rhs.main_entity.generation)
}

///|
priv struct SpriteDrawPayload {
  transform : @transform.Transform
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
priv struct ExtractedSprite {
  entity : PhaseEntityRef
  payload : SpriteDrawPayload
}

///|
priv struct UiRectDrawPayload {
  transform : @transform.Transform
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
priv struct ExtractedUiRect {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiRectDrawPayload
}

///|
priv struct UiBoxShadowDrawPayload {
  transform : @transform.Transform
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
priv struct ExtractedUiBoxShadow {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiBoxShadowDrawPayload
}

///|
priv struct UiTextureSliceDrawPayload {
  transform : @transform.Transform
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
priv struct ExtractedUiTextureSlice {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiTextureSliceDrawPayload
}

///|
priv struct ExtractedCamera2d {
  entity : @core.Entity
  camera : Camera
  projection : OrthographicProjection
  transform : @transform.Transform
  target : RenderTarget
  layers : RenderLayers
  bloom : Bloom?
  computed : CameraComputed
}

///|
priv struct CameraComputed {
  target_size : @math.IVec2
  scale_factor : Float
}

///|
priv struct Mesh2dDrawPayload {
  mesh_id : Int
  transform : @transform.Transform
  layers : RenderLayers
  wireframe : Bool
  wireframe_color : Color
}

///|
priv struct ExtractedMesh2d {
  entity : PhaseEntityRef
  payload : Mesh2dDrawPayload
}

///|
priv struct RenderTargetInfo {
  id : Int
  width : Int
  height : Int
}

///|
priv struct PostProcessIntermediateTargetInfo {
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
  mut tonemapping_lut_handles : TonemappingLutHandles?
  sprites : Array[ExtractedSprite]
  extra_sprites : Array[ExtractedSprite]
  extra_ui_rects : Array[ExtractedUiRect]
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow]
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice]
  cameras : Array[ExtractedCamera2d]
  meshes : Array[ExtractedMesh2d]
  render_targets : Array[RenderTargetInfo]
  postprocess_intermediate_targets : Array[PostProcessIntermediateTargetInfo]
  // Prepare stage output: stable camera iteration order for the frame.
  mut prepared_camera_indices : Array[Int]
  // Queue stage output: per-camera queued item counts for diagnostics/sanity.
  mut queued_draw_item_counts : Array[Int]
}

///|
let render2d_diagnostic_queued_draw_item_count_ref : Ref[Int] = Ref::new(0)

///|
let render2d_diagnostic_prepared_camera_count_ref : Ref[Int] = Ref::new(0)

///|
fn RenderState::new() -> RenderState {
  RenderState::{
    draw_enabled: false,
    primary_camera: @core.Entity::placeholder(),
    tonemapping_lut_handles: None,
    sprites: [],
    extra_sprites: [],
    extra_ui_rects: [],
    extra_ui_box_shadows: [],
    extra_ui_texture_slices: [],
    cameras: [],
    meshes: [],
    render_targets: [],
    postprocess_intermediate_targets: [],
    prepared_camera_indices: [],
    queued_draw_item_counts: [],
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
pub fn init_render_state_system(world : @ecs.World) -> Unit {
  ensure_render_state_resource(world)
}

///|
const PAN_CAMERA_SCROLL_UNIT_CONVERSION_FACTOR : Float = 16.0F

///|
fn pan_camera_press_if_pressed(
  key_input : @input.ButtonInput[@window.KeyCode],
  key : @window.KeyCode?,
) -> Unit {
  if key is Some(value) && @input.key_pressed(value) {
    key_input.press(value)
  }
}

///|
fn pan_camera_key_input_snapshot(
  controller : PanCamera,
) -> @input.ButtonInput[@window.KeyCode] {
  let key_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  pan_camera_press_if_pressed(key_input, controller.key_zoom_in)
  pan_camera_press_if_pressed(key_input, controller.key_zoom_out)
  pan_camera_press_if_pressed(key_input, controller.key_up)
  pan_camera_press_if_pressed(key_input, controller.key_down)
  pan_camera_press_if_pressed(key_input, controller.key_left)
  pan_camera_press_if_pressed(key_input, controller.key_right)
  pan_camera_press_if_pressed(key_input, controller.key_rotate_ccw)
  pan_camera_press_if_pressed(key_input, controller.key_rotate_cw)
  key_input
}

///|
fn pan_camera_zoom_bounds(controller : PanCamera) -> (Float, Float) {
  let safe_min = if controller.min_zoom <= 0.0F {
    0.0001F
  } else {
    controller.min_zoom
  }
  let safe_max = if controller.max_zoom >= safe_min {
    controller.max_zoom
  } else {
    safe_min
  }
  (safe_min, safe_max)
}

///|
fn pan_camera_scroll_delta(scroll : @input.AccumulatedMouseScroll) -> Float {
  match scroll.unit {
    @input.MouseScrollUnit::Line => scroll.delta.y
    @input.MouseScrollUnit::Pixel =>
      scroll.delta.y / PAN_CAMERA_SCROLL_UNIT_CONVERSION_FACTOR
  }
}

///|
fn pan_camera_step(
  transform : @transform.Transform,
  controller : PanCamera,
  delta_seconds : Float,
  key_input : @input.ButtonInput[@window.KeyCode],
  accumulated_mouse_scroll : @input.AccumulatedMouseScroll,
) -> (@transform.Transform, PanCamera) {
  let next_transform = transform
  let next_controller = controller
  if !next_controller.enabled {
    return (next_transform, next_controller)
  }

  let movement = @math.Vec2::zero()
  if next_controller.key_left is Some(key) && key_input.pressed(key) {
    movement.x = movement.x - 1.0F
  }
  if next_controller.key_right is Some(key) && key_input.pressed(key) {
    movement.x = movement.x + 1.0F
  }
  if next_controller.key_down is Some(key) && key_input.pressed(key) {
    movement.y = movement.y - 1.0F
  }
  if next_controller.key_up is Some(key) && key_input.pressed(key) {
    movement.y = movement.y + 1.0F
  }

  if movement.length_squared() > 0.0F {
    let right = next_transform.right()
    let up = next_transform.up()
    let delta = right
      .mul_scalar(movement.x)
      .add(up.mul_scalar(movement.y))
      .normalize_or_zero()
      .mul_scalar(next_controller.pan_speed * delta_seconds)
    next_transform.translation = next_transform.translation.add(
      @math.Vec3::new(delta.x, delta.y, 0.0F),
    )
  }

  if next_controller.key_rotate_ccw is Some(key) && key_input.pressed(key) {
    next_transform.rotate_z(next_controller.rotation_speed * delta_seconds)
  }
  if next_controller.key_rotate_cw is Some(key) && key_input.pressed(key) {
    next_transform.rotate_z(-next_controller.rotation_speed * delta_seconds)
  }

  let mut zoom_amount = 0.0F
  if next_controller.key_zoom_in is Some(key) && key_input.pressed(key) {
    zoom_amount = zoom_amount - next_controller.zoom_speed
  }
  if next_controller.key_zoom_out is Some(key) && key_input.pressed(key) {
    zoom_amount = zoom_amount + next_controller.zoom_speed
  }
  zoom_amount = zoom_amount +
    pan_camera_scroll_delta(accumulated_mouse_scroll) *
    next_controller.zoom_speed

  let (safe_min_zoom, safe_max_zoom) = pan_camera_zoom_bounds(next_controller)
  next_controller.zoom_factor = if next_controller.zoom_factor - zoom_amount <
    safe_min_zoom {
    safe_min_zoom
  } else if next_controller.zoom_factor - zoom_amount > safe_max_zoom {
    safe_max_zoom
  } else {
    next_controller.zoom_factor - zoom_amount
  }
  next_transform.scale = @math.Vec3::splat(next_controller.zoom_factor)
  (next_transform, next_controller)
}

///|
fn pan_camera_world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in pancamera controller")
  }
}

///|
pub fn run_pancamera_controller(world : @ecs.World) -> Unit {
  let delta_seconds = pan_camera_world_time(world).delta_seconds()
  let tick = world.read_change_tick()
  let camera_store = world.component(ecs_key_camera)
  let transform_store = world.component(@transform.ecs_key_transform)
  let pan_camera_store = world.component(ecs_key_pan_camera)
  let accumulated_mouse_scroll = match
    (try! world.get_resource(@input.AccumulatedMouseScroll::resource())) {
    Some(value) => value
    None => @input.AccumulatedMouseScroll::new()
  }
  let controlled_entities : Array[@core.Entity] = []
  pan_camera_store.for_each(fn(entity, _controller) {
    if camera_store.get(entity) is Some(_) &&
      transform_store.get(entity) is Some(_) {
      controlled_entities.push(entity)
    }
  })
  for controlled_entity in controlled_entities {
    guard pan_camera_store.get(controlled_entity) is Some(controller) else {
      continue
    }
    guard transform_store.get(controlled_entity) is Some(transform) else {
      continue
    }
    let key_input = pan_camera_key_input_snapshot(controller)
    let (next_transform, next_controller) = pan_camera_step(
      transform, controller, delta_seconds, key_input, accumulated_mouse_scroll,
    )
    transform_store.set(controlled_entity, next_transform, tick) |> ignore
    pan_camera_store.set(controlled_entity, next_controller, tick) |> ignore
  }
}

///|
pub fn pan_camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_systems(
    @app.RunFixedMainLoop,
    @app.system(run_pancamera_controller).in_set(
      @app.run_fixed_main_loop_system_set_name(
        @app.RunFixedMainLoopSystems::BeforeFixedMainLoop,
      ),
    ),
  )
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
fn sprite_sign(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else {
    1.0F
  }
}

///|
fn sprite_rotate_offset(offset : @math.Vec2, rotation : Float) -> @math.Vec2 {
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  @math.Vec2::new(
    offset.x * cosv - offset.y * sinv,
    offset.x * sinv + offset.y * cosv,
  )
}

///|
fn sprite_slice_uv_axis(
  uv_min : Float,
  uv_max : Float,
  slice_min : Float,
  slice_max : Float,
  region_extent : Float,
) -> (Float, Float) {
  if region_extent == 0.0F {
    (uv_min, uv_max)
  } else {
    let span = uv_max - uv_min
    (
      uv_min + span * (slice_min / region_extent),
      uv_min + span * (slice_max / region_extent),
    )
  }
}

///|
fn append_computed_sprite_slices(
  sprites : Array[ExtractedSprite],
  entity : @core.Entity,
  sprite : Sprite,
  anchor : Anchor,
  transform : @transform.Transform,
  layers : RenderLayers,
  scissor : @math.Rect?,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  region_size : @math.Vec2,
) -> Bool {
  guard compute_sprite_slices(sprite, region_size) is Some(computed_slices) else {
    return false
  }
  let base_size = match sprite.custom_size {
    Some(size) => size
    None => region_size
  }
  let extracted_slices = computed_slices.extract_slices(
    sprite,
    anchor,
    @math.Vec2::new(transform.scale.x, transform.scale.y),
    base_size,
  )
  let rotation = transform.rotation_z()
  let sign_x = sprite_sign(transform.scale.x)
  let sign_y = sprite_sign(transform.scale.y)
  for slice in extracted_slices {
    let slice_size = @math.Vec2::new(
      slice.texture_rect.max.x - slice.texture_rect.min.x,
      slice.texture_rect.max.y - slice.texture_rect.min.y,
    )
    let (slice_uv_min_x, slice_uv_max_x) = sprite_slice_uv_axis(
      uv_min.x,
      uv_max.x,
      slice.texture_rect.min.x,
      slice.texture_rect.max.x,
      region_size.x,
    )
    let (slice_uv_min_y, slice_uv_max_y) = sprite_slice_uv_axis(
      uv_min.y,
      uv_max.y,
      slice.texture_rect.min.y,
      slice.texture_rect.max.y,
      region_size.y,
    )
    let world_offset = sprite_rotate_offset(slice.offset, rotation)
    let draw_scale = @math.Vec2::new(
      if slice_size.x == 0.0F {
        1.0F * sign_x
      } else {
        sign_x * slice.draw_size.x / slice_size.x
      },
      if slice_size.y == 0.0F {
        1.0F * sign_y
      } else {
        sign_y * slice.draw_size.y / slice_size.y
      },
    )
    sprites.push(
      extracted_sprite_item(
        entity,
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(
            transform.translation.x + world_offset.x,
            transform.translation.y + world_offset.y,
          ),
          rotation,
          @math.Vec2::new(1.0F, 1.0F),
          z=transform.translation.z,
        ),
        @math.Vec2::new(0.0F, 0.0F),
        draw_scale,
        sprite.color,
        sprite.image,
        layers,
        @math.Vec2::new(slice_uv_min_x, slice_uv_min_y),
        @math.Vec2::new(slice_uv_max_x, slice_uv_max_y),
        scissor,
      ),
    )
  }
  true
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @render.host_gpu_create_render_target(width~, height~, nearest~)
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
  try! (world.set(e, @transform.ecs_key_transform, self.transform) |> ignore)
  e
}

///|
fn camera2d_bundle_insert(
  bundle : Camera2dBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit {
  try! (world.set(entity, ecs_key_camera2d, bundle.camera2d, loc~) |> ignore)
  try! (world.set(entity, ecs_key_camera, bundle.camera, loc~) |> ignore)
  try! (world.set(entity, ecs_key_projection, bundle.projection, loc~) |> ignore)
  try! (world.set(entity, ecs_key_render_target, bundle.target, loc~) |> ignore)
  try! (world.set(entity, ecs_key_render_layers, bundle.layers, loc~) |> ignore)
  if bundle.bloom is Some(bloom) {
    try! (world.set(entity, ecs_key_bloom, bloom, loc~) |> ignore)
  }
  if bundle.tonemapping is Some(tonemapping) {
    try! (world.set(entity, ecs_key_tonemapping, tonemapping, loc~) |> ignore)
  }
  if bundle.color_grading is Some(color_grading) {
    try! (world.set(entity, ecs_key_color_grading, color_grading, loc~)
    |> ignore)
  }
  if bundle.deband_dither is Some(deband_dither) {
    try! (world.set(entity, ecs_key_deband_dither, deband_dither, loc~)
    |> ignore)
  }
  try! (world.set(entity, @transform.ecs_key_transform, bundle.transform, loc~)
  |> ignore)
}

///|
pub impl @app.CommandSpawnComponents for Camera2dBundle with spawn_components(
  self,
  world,
  entity,
  _change_tick,
  loc~,
) {
  camera2d_bundle_insert(self, world, entity, loc~)
}

///|
#callsite(autofill(loc))
pub fn Camera2dBundle::spawn(
  self : Camera2dBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  let e = world.spawn_empty()
  camera2d_bundle_insert(self, world, e, loc~)
  e
}

///|
pub fn Mesh2dBundle::spawn(
  self : Mesh2dBundle,
  world : @ecs.World,
) -> @core.Entity {
  let e = world.spawn_empty()
  try! (world.set(e, ecs_key_mesh2d, self.mesh) |> ignore)
  try! (world.set(e, ecs_key_mesh_material2d, self.material) |> ignore)
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
  try! (world.set(e, @transform.ecs_key_transform, self.transform) |> ignore)
  let mesh_id = render2d_upload_mesh_handle(self.mesh.mesh)
  try! (world.set(e, ecs_key_gpu_mesh2d, GpuMesh2d::new(mesh_id)) |> ignore)
  e
}

///|
pub fn render2d_clear_overlay_sprites(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) { rs.val.extra_sprites.clear() }) |> ignore
}

///|
pub fn render2d_push_sprite_uv(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_sprites.push(ExtractedSprite::{
      entity: phase_entity_ref_placeholder(),
      payload: SpriteDrawPayload::{
        transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
        color,
        texture,
        layers,
        uv_min,
        uv_max,
        scissor: None,
      },
    })
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv_scissor(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.val.extra_sprites.push(ExtractedSprite::{
      entity: phase_entity_ref_placeholder(),
      payload: SpriteDrawPayload::{
        transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
        color,
        texture,
        layers,
        uv_min,
        uv_max,
        scissor,
      },
    })
  })
  |> ignore
}

///|
pub(all) struct OverlaySpriteUvScissor {
  texture : @asset.Handle[@asset.Image]
  transform : @transform.Transform
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
      rs.val.extra_sprites.push(ExtractedSprite::{
        entity: phase_entity_ref_placeholder(),
        payload: SpriteDrawPayload::{
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
        },
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
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
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
    rs.val.extra_ui_rects.push(ExtractedUiRect::{
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: render2d_ui_overlay_target_camera(target_camera),
      payload: UiRectDrawPayload::{
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
      },
    })
  })
  |> ignore
}

///|
pub fn render2d_push_ui_box_shadow_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
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
    rs.val.extra_ui_box_shadows.push(ExtractedUiBoxShadow::{
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: render2d_ui_overlay_target_camera(target_camera),
      payload: UiBoxShadowDrawPayload::{
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
      },
    })
  })
  |> ignore
}

///|
pub fn render2d_push_ui_texture_slice_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
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
    rs.val.extra_ui_texture_slices.push(ExtractedUiTextureSlice::{
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: render2d_ui_overlay_target_camera(target_camera),
      payload: UiTextureSliceDrawPayload::{
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
      },
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
fn render2d_targets_host_window(target : RenderTarget) -> Bool {
  match target {
    Screen => true
    Window(_) => true
    Image(_) => false
  }
}

///|
fn render2d_window_target_info(
  world : @ecs.World,
  window_ref : @window.WindowRef,
) -> RenderTargetComputed? {
  let width = @window.window_physical_width_for(world, window_ref)
  let height = @window.window_physical_height_for(world, window_ref)
  if width <= 0 || height <= 0 {
    return None
  }
  let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  Some(RenderTargetComputed::{
    size: @math.IVec2::new(width, height),
    scale_factor,
  })
}

///|
fn render2d_target_info(
  world : @ecs.World,
  state : RenderState,
  target : RenderTarget,
) -> RenderTargetComputed? {
  match target {
    Screen => render2d_window_target_info(world, @window.WindowRef::Primary)
    Window(window_ref) => render2d_window_target_info(world, window_ref)
    Image(handle) => {
      let target_id = handle.id()
      if render2d_find_render_target_size(state, target_id) is Some(info) {
        Some(RenderTargetComputed::{
          size: @math.IVec2::new(info.width, info.height),
          scale_factor: 1.0F,
        })
      } else {
        None
      }
    }
  }
}

///|
fn render2d_same_entity(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render2d_ui_overlay_target_camera(camera : @core.Entity?) -> @core.Entity {
  match camera {
    Some(entity) => entity
    None => @core.Entity::placeholder()
  }
}

///|
fn render2d_ui_overlay_matches_camera(
  target_camera : @core.Entity,
  camera_entity : @core.Entity,
) -> Bool {
  !target_camera.is_placeholder() &&
  render2d_same_entity(target_camera, camera_entity)
}

///|
fn render2d_prune_postprocess_intermediate_targets(state : RenderState) -> Unit {
  let kept : Array[PostProcessIntermediateTargetInfo] = []
  for entry in state.postprocess_intermediate_targets {
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
  state.postprocess_intermediate_targets.clear()
  for entry in kept {
    state.postprocess_intermediate_targets.push(entry)
  }
}

///|
fn render2d_get_or_create_postprocess_intermediate_target(
  state : RenderState,
  camera : @core.Entity,
  width : Int,
  height : Int,
) -> @asset.Handle[@asset.Image] {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  for entry in state.postprocess_intermediate_targets {
    if render2d_same_entity(entry.camera, camera) &&
      entry.width == safe_width &&
      entry.height == safe_height {
      return entry.target
    }
  }
  let id = @render.host_gpu_create_render_target_rgba16f(
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
  for i in 0..<state.postprocess_intermediate_targets.length() {
    let entry = state.postprocess_intermediate_targets[i]
    if render2d_same_entity(entry.camera, camera) {
      state.postprocess_intermediate_targets[i] = PostProcessIntermediateTargetInfo::{
        camera,
        width: safe_width,
        height: safe_height,
        target: handle,
      }
      return handle
    }
  }
  state.postprocess_intermediate_targets.push(PostProcessIntermediateTargetInfo::{
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
fn render2d_logical_view_extent_axis(value : Int, scale_factor : Float) -> Int {
  if value <= 0 {
    return 0
  }
  let safe_scale_factor = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical = Float::from_double(value.to_double()) / safe_scale_factor
  if logical <= 0.0F {
    1
  } else {
    let logical_i = logical.to_int()
    if logical_i <= 0 {
      1
    } else {
      logical_i
    }
  }
}

///|
fn render2d_camera_transform_scale_axis(value : Float) -> Float {
  let safe = if value < 0.0F { -value } else { value }
  if safe == 0.0F {
    1.0F
  } else {
    safe
  }
}

///|
fn render2d_camera_uniform_scale(
  projection : OrthographicProjection,
  camera_transform : @transform.Transform,
) -> Float {
  let projection_scale = if projection.scale == 0.0F {
    1.0F
  } else {
    projection.scale
  }
  // The native 2D camera backend currently uses a uniform camera scale, so the
  // X axis is authoritative. PanCamera always writes a uniform Vec3::splat scale.
  projection_scale *
  render2d_camera_transform_scale_axis(camera_transform.scale.x)
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
fn render2d_tonemapping_mode_enabled(mode : Int) -> Bool {
  mode != 0
}

///|
fn render2d_color_grading_enabled(color_grading : ColorGrading?) -> Bool {
  color_grading is Some(_)
}

///|
fn render2d_tonemapping_stage_enabled(
  tonemapping_mode : Int,
  color_grading : ColorGrading?,
) -> Bool {
  render2d_color_grading_enabled(color_grading) ||
  render2d_tonemapping_mode_enabled(tonemapping_mode)
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
fn camera_color_grading(
  world : @ecs.World,
  camera : @core.Entity,
) -> ColorGrading? {
  let store = world.component(ecs_key_color_grading)
  store.get(camera)
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

    let target_info = render2d_target_info(world, render_state, target)
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
    if render2d_targets_host_window(target) &&
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
) -> @transform.Transform {
  max_depth |> ignore
  (try! world.get(entity, @transform.ecs_key_transform)).unwrap_or(
    @transform.Transform::identity(),
  )
}

///|
fn render2d_resolve_transform_ecs(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
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
  match (try! world.get(entity, @visibility.ecs_key_view_visibility)) {
    Some(view_visibility) => view_visibility.is_visible()
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
    let target_info = render2d_target_info(world, render_state, target)
    let next_target_info = render2d_camera_target_info_from_render_target(
      target_info,
    )
    let mut camera_value = camera
    let mut scale_factor_changed = false
    if render2d_targets_host_window(target) &&
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
  cameras : Array[ExtractedCamera2d],
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
    let bloom_store = get_bloom_store(ecs_world)
    let view_visibility_store = @visibility.get_view_visibility_store(ecs_world)
    let transform_store = @transform.get_transform_store(ecs_world)
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
      let bloom = bloom_store.get(entity)
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
            None => @transform.Transform::identity()
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
      } else if render2d_target_info(world, rs.val, target) is Some(info) {
        let scale_factor = if info.scale_factor <= 0.0F {
          1.0F
        } else {
          info.scale_factor
        }
        computed = CameraComputed::{ target_size: info.size, scale_factor }
      }
      rs.val.cameras.push(ExtractedCamera2d::{
        entity,
        camera,
        projection,
        transform,
        target,
        layers,
        bloom,
        computed,
      })
    })
    if rs.val.cameras.length() > 0 {
      let order = render2d_sorted_camera_indices(rs.val.cameras)
      if order.length() > 0 {
        rs.val.primary_camera = rs.val.cameras[order[0]].entity
      }
    }
    render2d_prune_postprocess_intermediate_targets(rs.val)
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
            None => @transform.Transform::identity()
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
          @asset.ImageSampler::Descriptor(
            @asset.ImageSamplerDescriptor::linear().set_address_mode(
              @asset.ImageAddressMode::Repeat,
            ),
          ),
        )
      }
      if !append_computed_sprite_slices(
          rs.val.sprites,
          entity,
          sprite,
          anchor,
          transform,
          layers,
          scissor,
          uv_min,
          uv_max,
          region_size,
        ) {
        rs.val.sprites.push(ExtractedSprite::{
          entity: phase_entity_ref_for_main(entity),
          payload: SpriteDrawPayload::{
            transform,
            anchor_offset,
            draw_scale: draw_scale_for_host,
            color: sprite.color,
            texture: sprite.image,
            layers,
            uv_min: uv_draw_min,
            uv_max: uv_draw_max,
            scissor,
          },
        })
      }
    })
    let mesh_store = get_mesh2d_store(ecs_world)
    let gpu_mesh_store = get_gpu_mesh2d_store(ecs_world)
    let material_runtime_registry = material2d_runtime_registry_or_empty(
      ecs_world,
    )
    let wireframe_store = get_wireframe2d_store(ecs_world)
    let no_wireframe_store = get_no_wireframe2d_store(ecs_world)
    let wireframe_color_store = get_wireframe2d_color_store(ecs_world)
    let wireframe_config = if get_wireframe2d_config_resource(ecs_world).get()
      is Some(config) {
      Some(config)
    } else {
      None
    }
    mesh_store.for_each(fn(entity, _mesh2d) {
      if view_visibility_store.get(entity) is Some(vv) && !vv.is_visible() {
        return
      }
      guard gpu_mesh_store.get(entity) is Some(gpu) else { return }
      if !material2d_runtime_registry_contains_entity(
          ecs_world, material_runtime_registry, entity,
        ) {
        return
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
            None => @transform.Transform::identity()
          }
      }
      let wireframe = wireframe2d_mesh_should_draw(
        wireframe_store.get(entity) is Some(_),
        no_wireframe_store.get(entity) is Some(_),
        wireframe_config,
      )
      let wireframe_color = wireframe2d_mesh_color(
        wireframe_color_store.get(entity),
        wireframe_config,
      )
      rs.val.meshes.push(ExtractedMesh2d::{
        entity: phase_entity_ref_for_main(entity),
        payload: Mesh2dDrawPayload::{
          mesh_id: gpu.mesh_id,
          transform,
          layers,
          wireframe,
          wireframe_color,
        },
      })
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
      let bloom = try! world.get(entity, ecs_key_bloom)
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
      } else if render2d_target_info(world, rs.val, target) is Some(info) {
        let scale_factor = if info.scale_factor <= 0.0F {
          1.0F
        } else {
          info.scale_factor
        }
        computed = CameraComputed::{ target_size: info.size, scale_factor }
      }
      rs.val.cameras.push(ExtractedCamera2d::{
        entity,
        camera,
        projection,
        transform,
        target,
        layers,
        bloom,
        computed,
      })
    })
    if rs.val.cameras.length() > 0 {
      let order = render2d_sorted_camera_indices(rs.val.cameras)
      if order.length() > 0 {
        rs.val.primary_camera = rs.val.cameras[order[0]].entity
      }
    }
    render2d_prune_postprocess_intermediate_targets(rs.val)

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
          @asset.ImageSampler::Descriptor(
            @asset.ImageSamplerDescriptor::linear().set_address_mode(
              @asset.ImageAddressMode::Repeat,
            ),
          ),
        )
      }
      if !append_computed_sprite_slices(
          rs.val.sprites,
          entity,
          sprite,
          anchor,
          transform,
          layers,
          scissor,
          uv_min,
          uv_max,
          region_size,
        ) {
        rs.val.sprites.push(ExtractedSprite::{
          entity: phase_entity_ref_for_main(entity),
          payload: SpriteDrawPayload::{
            transform,
            anchor_offset,
            draw_scale: draw_scale_for_host,
            color: sprite.color,
            texture: sprite.image,
            layers,
            uv_min: uv_draw_min,
            uv_max: uv_draw_max,
            scissor,
          },
        })
      }
    })

    let material_runtime_registry = material2d_runtime_registry_or_empty(world)
    let wireframe_config = if get_wireframe2d_config_resource(world).get()
      is Some(config) {
      Some(config)
    } else {
      None
    }

    // ECS mesh components.
    try! world
    .query1(ecs_key_mesh2d)
    .view(fn(entity, _mesh2d) {
      if !render2d_entity_visible_ecs(world, entity) {
        return
      }
      guard (try! world.get(entity, ecs_key_gpu_mesh2d)) is Some(gpu) else {
        return
      }
      if !material2d_runtime_registry_contains_entity(
          world, material_runtime_registry, entity,
        ) {
        return
      }
      let layers = (try! world.get(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::default(),
      )
      let transform = render2d_resolve_transform_ecs(world, entity)
      let wireframe = wireframe2d_mesh_should_draw(
        (try! world.get(entity, ecs_key_wireframe2d)) is Some(_),
        (try! world.get(entity, ecs_key_no_wireframe2d)) is Some(_),
        wireframe_config,
      )
      let wireframe_color = wireframe2d_mesh_color(
        try! world.get(entity, ecs_key_wireframe2d_color),
        wireframe_config,
      )
      rs.val.meshes.push(ExtractedMesh2d::{
        entity: phase_entity_ref_for_main(entity),
        payload: Mesh2dDrawPayload::{
          mesh_id: gpu.mesh_id,
          transform,
          layers,
          wireframe,
          wireframe_color,
        },
      })
    })
  })
  |> ignore
}

///|
pub fn render_prepare_system(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    if !rs.val.draw_enabled {
      rs.val.prepared_camera_indices.clear()
      rs.val.queued_draw_item_counts.clear()
      render2d_diagnostic_prepared_camera_count_ref.val = 0
      render2d_diagnostic_queued_draw_item_count_ref.val = 0
      return
    }
    rs.val.prepared_camera_indices = render2d_sorted_camera_indices(
      rs.val.cameras,
    )
    render2d_diagnostic_prepared_camera_count_ref.val = rs.val.prepared_camera_indices.length()
    rs.val.queued_draw_item_counts.clear()
  })
  |> ignore
}

///|
pub fn render_queue_system(world : @ecs.World) -> Unit {
  let material_runtime_registry = material2d_runtime_registry_or_empty(world)
  render_state_update(world, fn(rs) {
    if !rs.val.draw_enabled {
      rs.val.queued_draw_item_counts.clear()
      render2d_diagnostic_queued_draw_item_count_ref.val = 0
      return
    }
    let cameras = rs.val.cameras
    let camera_indices = if rs.val.prepared_camera_indices.length() ==
      cameras.length() {
      rs.val.prepared_camera_indices
    } else {
      render2d_sorted_camera_indices(cameras)
    }
    let counts : Array[Int] = []
    for index in camera_indices {
      if index < 0 || index >= cameras.length() {
        continue
      }
      let camera = cameras[index]
      let items = draw_registered_items_for_layers(
        world,
        material_runtime_registry,
        rs.val.sprites,
        rs.val.extra_sprites,
        rs.val.extra_ui_rects,
        rs.val.extra_ui_box_shadows,
        rs.val.extra_ui_texture_slices,
        rs.val.meshes,
        camera.entity,
        camera.layers,
      )
      counts.push(items.length())
    }
    rs.val.queued_draw_item_counts = counts
    let mut total = 0
    for count in counts {
      total = total + count
    }
    render2d_diagnostic_queued_draw_item_count_ref.val = total
  })
  |> ignore
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  render2d_diagnostic_queued_draw_item_count_ref.val
}

///|
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  render2d_diagnostic_prepared_camera_count_ref.val
}

///|
pub fn render2d_prepared_camera_count(world : @ecs.World) -> Int? {
  guard render_state_ref(world) is Some(rs) else { return Some(0) }
  Some(rs.prepared_camera_indices.length())
}

///|
pub fn render2d_queued_draw_item_count(world : @ecs.World) -> Int? {
  guard render_state_ref(world) is Some(rs) else { return Some(0) }
  let mut total = 0
  for count in rs.queued_draw_item_counts {
    total = total + count
  }
  Some(total)
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
fn[M] append_material2d_mesh_draw_items(
  items : Array[DrawItem],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @asset.Assets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  layers : RenderLayers,
  tie : Int,
  material_runtime_index? : Int = -1,
) -> Int {
  let mut next_tie = tie
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.payload.layers.matches(layers) {
      continue
    }
    guard prepared_material2d_handle_for_mesh(mesh, material_instances)
      is Some(material_handle) else {
      continue
    }
    guard prepared_material2d_get(prepared_materials, material_handle)
      is Some(material) else {
      continue
    }
    guard prepared_material2d_alpha_phase(material) is Some(phase) else {
      continue
    }
    items.push(DrawItem::{
      kind: Mesh(i),
      entity: mesh.entity,
      z: mesh.payload.transform.translation.z,
      phase,
      tie: next_tie,
      material_runtime_index,
    })
    next_tie = next_tie + 1
  }
  next_tie
}

///|
priv enum DrawKind {
  SpriteMain(Int)
  SpriteExtra(Int)
  UiRectExtra(Int)
  UiBoxShadowExtra(Int)
  UiTextureSliceExtra(Int)
  Mesh(Int)
}

///|
priv struct DrawItem {
  kind : DrawKind
  entity : PhaseEntityRef
  z : Float
  // 0 = scene opaque/mask, 1 = scene transparent, 2 = UI overlay.
  phase : Int
  // Stable insertion order tie-break key.
  tie : Int
  material_runtime_index : Int
}

///|
fn append_registered_material2d_mesh_draw_items(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  items : Array[DrawItem],
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
  tie : Int,
) -> Int {
  let mut next_tie = tie
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.payload.layers.matches(layers) {
      continue
    }
    let mut matched = false
    for runtime_index in 0..<registry.entries.length() {
      let entry = registry.entries[runtime_index]
      guard (entry.mesh_phase_for_draw_fn)(world, mesh) is Some(phase) else {
        continue
      }
      items.push(DrawItem::{
        kind: Mesh(i),
        entity: mesh.entity,
        z: mesh.payload.transform.translation.z,
        phase,
        tie: next_tie,
        material_runtime_index: runtime_index,
      })
      next_tie = next_tie + 1
      matched = true
      break
    }
    if matched {
      continue
    }
  }
  next_tie
}

///|
fn[M] draw_material2d_items_for_layers(
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @asset.Assets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  for
    item in draw_material2d_scene_items_for_layers(
      sprites, extra_sprites, meshes, prepared_materials, material_instances, layers,
    ) {
    items.push(item)
  }
  for
    item in draw_ui_overlay_items_for_layers(
      extra_ui_rects, extra_ui_box_shadows, extra_ui_texture_slices, camera_entity,
      layers,
    ) {
    items.push(item)
  }
  sort_draw_items(items)
}

///|
fn draw_items_for_layers(
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]],
  material_instances : RenderMaterial2dInstances[ColorMaterialAsset],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  draw_material2d_items_for_layers(
    sprites, extra_sprites, extra_ui_rects, extra_ui_box_shadows, extra_ui_texture_slices,
    meshes, prepared_materials, material_instances, camera_entity, layers,
  )
}

///|
fn sort_draw_items(items : Array[DrawItem]) -> Array[DrawItem] {
  items.sort_by(fn(a, b) {
    let cp = cmp_int(a.phase, b.phase)
    if cp != 0 {
      return cp
    }
    let cz = cmp_float(a.z, b.z)
    if cz != 0 {
      return cz
    }
    let ce = phase_entity_ref_cmp(a.entity, b.entity)
    if ce != 0 {
      return ce
    }
    cmp_int(a.tie, b.tie)
  })
  items
}

///|
fn[M] draw_material2d_scene_items_for_layers(
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @asset.Assets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  let mut tie = 0
  // Align with Bevy queue structure: mesh phases are queued before sprite phases.
  // Transparent items are then sorted by z with stable insertion order.
  tie = append_material2d_mesh_draw_items(
    items, meshes, prepared_materials, material_instances, layers, tie,
  )
  for i in 0..<sprites.length() {
    let sprite = sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    items.push(DrawItem::{
      kind: SpriteMain(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprites.length() {
    let sprite = extra_sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    items.push(DrawItem::{
      kind: SpriteExtra(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  sort_draw_items(items)
}

///|
fn draw_scene_items_for_layers(
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]],
  material_instances : RenderMaterial2dInstances[ColorMaterialAsset],
  layers : RenderLayers,
) -> Array[DrawItem] {
  draw_material2d_scene_items_for_layers(
    sprites, extra_sprites, meshes, prepared_materials, material_instances, layers,
  )
}

///|
fn draw_registered_scene_items_for_layers(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  let mut tie = 0
  tie = append_registered_material2d_mesh_draw_items(
    world, registry, items, meshes, layers, tie,
  )
  for i in 0..<sprites.length() {
    let sprite = sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    items.push(DrawItem::{
      kind: SpriteMain(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprites.length() {
    let sprite = extra_sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    items.push(DrawItem::{
      kind: SpriteExtra(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  sort_draw_items(items)
}

///|
fn draw_wireframe_meshes_for_layers(
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
) -> Unit {
  for mesh in meshes {
    if !mesh.payload.layers.matches(layers) || !mesh.payload.wireframe {
      continue
    }
    let transform = mesh.payload.transform
    let color = mesh.payload.wireframe_color
    @render.host_gpu_draw_mesh_wireframe(
      mesh_id=mesh.payload.mesh_id,
      x=transform.translation.x,
      y=transform.translation.y,
      rotation=transform.rotation_z(),
      scale_x=transform.scale.x,
      scale_y=transform.scale.y,
      color_r=color.r,
      color_g=color.g,
      color_b=color.b,
      color_a=color.a,
    )
  }
}

///|
fn draw_registered_items_for_layers(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  sprites : Array[ExtractedSprite],
  extra_sprites : Array[ExtractedSprite],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  for
    item in draw_registered_scene_items_for_layers(
      world, registry, sprites, extra_sprites, meshes, layers,
    ) {
    items.push(item)
  }
  for
    item in draw_ui_overlay_items_for_layers(
      extra_ui_rects, extra_ui_box_shadows, extra_ui_texture_slices, camera_entity,
      layers,
    ) {
    items.push(item)
  }
  sort_draw_items(items)
}

///|
fn draw_ui_overlay_items_for_layers(
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  let mut tie = 0
  for i in 0..<extra_ui_rects.length() {
    let rect = extra_ui_rects[i]
    if !rect.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        rect.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiRectExtra(i),
      entity: rect.entity,
      z: rect.payload.transform.translation.z,
      phase: 2,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_box_shadows.length() {
    let shadow = extra_ui_box_shadows[i]
    if !shadow.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        shadow.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiBoxShadowExtra(i),
      entity: shadow.entity,
      z: shadow.payload.transform.translation.z,
      phase: 2,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_texture_slices.length() {
    let slice = extra_ui_texture_slices[i]
    if !slice.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        slice.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiTextureSliceExtra(i),
      entity: slice.entity,
      z: slice.payload.transform.translation.z,
      phase: 2,
      tie,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  sort_draw_items(items)
}

///|
fn extracted_sprite_item(
  entity : @core.Entity,
  transform : @transform.Transform,
  anchor_offset : @math.Vec2,
  draw_scale : @math.Vec2,
  color : Color,
  texture : @asset.Handle[@asset.Image],
  layers : RenderLayers,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  scissor : @math.Rect?,
) -> ExtractedSprite {
  ExtractedSprite::{
    entity: phase_entity_ref_for_main(entity),
    payload: SpriteDrawPayload::{
      transform,
      anchor_offset,
      draw_scale,
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor,
    },
  }
}

///|
fn extracted_ui_rect_item(
  entity : @core.Entity,
  extracted_camera_entity : @core.Entity,
  transform : @transform.Transform,
  anchor_offset : @math.Vec2,
  draw_scale : @math.Vec2,
  color : Color,
  texture : @asset.Handle[@asset.Image],
  layers : RenderLayers,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  scissor : @math.Rect?,
  flags : Int,
  radius : UiCornerRadii,
  border : UiBorderRect,
) -> ExtractedUiRect {
  ExtractedUiRect::{
    entity: phase_entity_ref_for_main(entity),
    extracted_camera_entity,
    payload: UiRectDrawPayload::{
      transform,
      anchor_offset,
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
    },
  }
}

///|
fn extracted_mesh2d_item(
  entity : @core.Entity,
  mesh_id : Int,
  transform : @transform.Transform,
  layers : RenderLayers,
  wireframe? : Bool = false,
  wireframe_color? : Color = Color::white(),
) -> ExtractedMesh2d {
  ExtractedMesh2d::{
    entity: phase_entity_ref_for_main(entity),
    payload: Mesh2dDrawPayload::{
      mesh_id,
      transform,
      layers,
      wireframe,
      wireframe_color,
    },
  }
}

///|
test "render2d: mesh prepared material handle resolves from extracted entity instance" {
  let entity = @core.Entity::new(1, 0)
  let handle : @asset.Handle[ColorMaterialAsset] = @asset.Handle::new(77)
  let extracted = extracted_mesh2d_item(
    entity,
    12,
    @transform.Transform::identity(),
    RenderLayers::default(),
  )
  let instances = render_material2d_instances_for_tests([(entity, handle)])
  let prepared_id = match
    prepared_material2d_handle_for_mesh(extracted, instances) {
    Some(prepared_handle) => prepared_handle.id()
    None => -1
  }
  inspect(prepared_id, content="77")
}

///|
test "render2d: extracted mesh keeps wireframe state out of gizmo path" {
  let extracted = extracted_mesh2d_item(
    @core.Entity::new(2, 0),
    12,
    @transform.Transform::identity(),
    RenderLayers::default(),
    wireframe=true,
    wireframe_color=Color::new(0.25F, 0.5F, 0.75F, 1.0F),
  )
  let ok = extracted.payload.wireframe &&
    extracted.payload.wireframe_color.r == 0.25F &&
    extracted.payload.wireframe_color.g == 0.5F &&
    extracted.payload.wireframe_color.b == 0.75F
  inspect(ok, content="true")
}

///|
test "render2d: unified draw items order sprites and meshes by z" {
  let layers = RenderLayers::default()
  let mesh_entity = @core.Entity::new(1, 0)
  let material_handle = @asset.Handle::new(1)
  let prepared_materials = prepared_color_material_assets_for_tests([
    (
      material_handle,
      ColorMaterialAsset::new(Color::white(), AlphaMode2d::Blend),
    ),
  ])
  let sprites : Array[ExtractedSprite] = [
    extracted_sprite_item(
      @core.Entity::new(2, 0),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      @asset.Handle::new(2),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
    ),
  ]
  let extra : Array[ExtractedSprite] = []
  let extra_ui : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      mesh_entity,
      7,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=-1.0F,
      ),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (mesh_entity, material_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    extra,
    extra_ui,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
  inspect(ok, content="true")
}

///|
test "render2d: UI overlay draw items route by target camera" {
  let layers = RenderLayers::default()
  let prepared_materials : @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]] = @asset.Assets::new()
  let material_instances : RenderMaterial2dInstances[ColorMaterialAsset] = RenderMaterial2dInstances::new()
  let camera_a = @core.Entity::new(10, 0)
  let camera_b = @core.Entity::new(11, 0)
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui : Array[ExtractedUiRect] = [
    extracted_ui_rect_item(
      @core.Entity::new(100, 0),
      camera_a,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      Color::white(),
      @asset.Handle::new(1),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      UiBorderRect::zero(),
    ),
    extracted_ui_rect_item(
      @core.Entity::new(101, 0),
      camera_b,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      Color::white(),
      @asset.Handle::new(2),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      UiBorderRect::zero(),
    ),
  ]
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = []
  let items = draw_items_for_layers(
    sprites, extra, extra_ui, extra_shadow, extra_slices, meshes, prepared_materials,
    material_instances, camera_a, layers,
  )
  let ok = items.length() == 1 && items[0].kind is UiRectExtra(0)
  inspect(ok, content="true")
}

///|
test "render2d: scene draw items exclude UI overlays" {
  let layers = RenderLayers::default()
  let prepared_materials : @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]] = @asset.Assets::new()
  let material_instances : RenderMaterial2dInstances[ColorMaterialAsset] = RenderMaterial2dInstances::new()
  let camera = @core.Entity::new(10, 0)
  let scene_items = draw_scene_items_for_layers(
    [],
    [],
    [],
    prepared_materials,
    material_instances,
    layers,
  )
  let ui_items = draw_ui_overlay_items_for_layers(
    [
      extracted_ui_rect_item(
        @core.Entity::new(100, 0),
        camera,
        @transform.Transform::identity(),
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        Color::white(),
        @asset.Handle::new(1),
        layers,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        None,
        0,
        UiCornerRadii::zero(),
        UiBorderRect::zero(),
      ),
    ],
    [],
    [],
    camera,
    layers,
  )
  let ok = scene_items.length() == 0 &&
    ui_items.length() == 1 &&
    ui_items[0].kind is UiRectExtra(0)
  inspect(ok, content="true")
}

///|
test "render2d: host window bloom postprocess keeps Bevy stage ownership" {
  let plan = render2d_camera_postprocess_plan(Some(Bloom::default()), 0, None)
  let ok = plan.uses_intermediate_source &&
    plan.apply_bloom_before_tonemapping &&
    plan.tonemap_source_to_target &&
    plan.draw_ui_overlay_after_postprocess
  inspect(ok, content="true")
}

///|
test "render2d: host window tonemapping without bloom still leaves UI after postprocess" {
  let plan = render2d_camera_postprocess_plan(
    None,
    render2d_tonemapping_mode_to_int(TonyMcMapface),
    None,
  )
  let ok = plan.uses_intermediate_source &&
    !plan.apply_bloom_before_tonemapping &&
    plan.tonemap_source_to_target &&
    plan.draw_ui_overlay_after_postprocess
  inspect(ok, content="true")
}

///|
test "render2d: color grading alone keeps host window tonemapping copy stage" {
  let plan = render2d_camera_postprocess_plan(
    None,
    0,
    Some(ColorGrading::default()),
  )
  let ok = plan.uses_intermediate_source &&
    !plan.apply_bloom_before_tonemapping &&
    plan.tonemap_source_to_target &&
    plan.draw_ui_overlay_after_postprocess
  inspect(ok, content="true")
}

///|
test "render2d: queue counts keep overlay UI isolated per camera pass" {
  let world = @ecs.World::new()
  ensure_render_state_resource(world)
  let layers = RenderLayers::default()
  let camera_a = @core.Entity::new(10, 0)
  let camera_b = @core.Entity::new(11, 0)
  render_state_update(world, fn(rs) {
    rs.val.draw_enabled = true
    rs.val.cameras.clear()
    rs.val.cameras.push(ExtractedCamera2d::{
      entity: camera_a,
      camera: Camera::default().with_order(0),
      projection: OrthographicProjection::default_2d(),
      transform: @transform.Transform::identity(),
      target: RenderTarget::Screen,
      layers,
      bloom: None,
      computed: CameraComputed::{
        target_size: @math.IVec2::new(640, 360),
        scale_factor: 1.0F,
      },
    })
    rs.val.cameras.push(ExtractedCamera2d::{
      entity: camera_b,
      camera: Camera::default().with_order(1),
      projection: OrthographicProjection::default_2d(),
      transform: @transform.Transform::identity(),
      target: RenderTarget::Screen,
      layers,
      bloom: None,
      computed: CameraComputed::{
        target_size: @math.IVec2::new(640, 360),
        scale_factor: 1.0F,
      },
    })
    rs.val.prepared_camera_indices.clear()
    rs.val.prepared_camera_indices.push(0)
    rs.val.prepared_camera_indices.push(1)
    rs.val.extra_ui_rects.clear()
    rs.val.extra_ui_rects.push(
      extracted_ui_rect_item(
        @core.Entity::new(200, 0),
        camera_a,
        @transform.Transform::identity(),
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        Color::white(),
        @asset.Handle::new(3),
        layers,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        None,
        0,
        UiCornerRadii::zero(),
        UiBorderRect::zero(),
      ),
    )
    rs.val.extra_ui_rects.push(
      extracted_ui_rect_item(
        @core.Entity::new(201, 0),
        camera_b,
        @transform.Transform::identity(),
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        Color::white(),
        @asset.Handle::new(4),
        layers,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        None,
        0,
        UiCornerRadii::zero(),
        UiBorderRect::zero(),
      ),
    )
    rs.val.extra_ui_box_shadows.clear()
    rs.val.extra_ui_texture_slices.clear()
  })
  |> ignore

  render_queue_system(world)

  let counts = render_state_ref(world).unwrap().queued_draw_item_counts
  inspect(counts.to_json(), content="Array([Number(1), Number(1)])")
}

///|
test "render2d: mesh opaque alpha mode stays in opaque phase" {
  let layers = RenderLayers::default()
  let opaque_entity = @core.Entity::new(2, 0)
  let blend_entity = @core.Entity::new(1, 0)
  let opaque_handle = @asset.Handle::new(20)
  let blend_handle = @asset.Handle::new(21)
  let prepared_materials = prepared_color_material_assets_for_tests([
    (
      opaque_handle,
      ColorMaterialAsset::new(
        Color::new(1.0F, 0.0F, 0.0F, 0.2F),
        AlphaMode2d::Opaque,
      ),
    ),
    (
      blend_handle,
      ColorMaterialAsset::new(
        Color::new(0.0F, 1.0F, 0.0F, 0.2F),
        AlphaMode2d::Blend,
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      opaque_entity,
      10,
      @transform.Transform::identity(),
      layers,
    ),
    extracted_mesh2d_item(
      blend_entity,
      11,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (opaque_entity, opaque_handle),
    (blend_entity, blend_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    extra,
    extra_ui,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is Mesh(1)
  inspect(ok, content="true")
}

///|
test "render2d: blend mesh with alpha=1 stays in transparent phase ordering" {
  let layers = RenderLayers::default()
  let mesh_entity = @core.Entity::new(1, 0)
  let material_handle = @asset.Handle::new(30)
  let prepared_materials = prepared_color_material_assets_for_tests([
    (
      material_handle,
      ColorMaterialAsset::new(
        Color::new(1.0F, 1.0F, 1.0F, 1.0F),
        AlphaMode2d::Blend,
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = [
    extracted_sprite_item(
      @core.Entity::new(2, 0),
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      Color::white(),
      @asset.Handle::new(10),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
    ),
  ]
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      mesh_entity,
      99,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (mesh_entity, material_handle),
  ])
  let items = draw_scene_items_for_layers(
    sprites,
    [],
    meshes,
    prepared_materials,
    material_instances,
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
  inspect(ok, content="true")
}

///|
test "render2d: mesh mask alpha mode queues both items for shader-side cutoff" {
  let layers = RenderLayers::default()
  let masked_low_entity = @core.Entity::new(1, 0)
  let masked_high_entity = @core.Entity::new(2, 0)
  let masked_low_handle = @asset.Handle::new(40)
  let masked_high_handle = @asset.Handle::new(41)
  let prepared_materials = prepared_color_material_assets_for_tests([
    (
      masked_low_handle,
      ColorMaterialAsset::new(
        Color::new(1.0F, 1.0F, 1.0F, 0.2F),
        AlphaMode2d::Mask(0.5F),
      ),
    ),
    (
      masked_high_handle,
      ColorMaterialAsset::new(
        Color::new(1.0F, 1.0F, 1.0F, 0.8F),
        AlphaMode2d::Mask(0.5F),
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      masked_low_entity,
      20,
      @transform.Transform::identity(),
      layers,
    ),
    extracted_mesh2d_item(
      masked_high_entity,
      21,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (masked_low_entity, masked_low_handle),
    (masked_high_entity, masked_high_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    extra,
    extra_ui,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is Mesh(1)
  inspect(ok, content="true")
}

///|
test "render2d: tiled sprite mode computes repeated slices" {
  let sprite = Sprite::from_image(@asset.Handle::new(1))
    .with_image_mode(
      SpriteImageMode::tiled(tile_x=true, tile_y=false, stretch_value=0.5F),
    )
    .with_custom_size(Some(@math.Vec2::new(64.0F, 32.0F)))
  guard compute_sprite_slices(sprite, @math.Vec2::new(32.0F, 32.0F))
    is Some(slices) else {
    inspect(false, content="true")
    return
  }
  let ok = slices.slices.length() == 4 &&
    slices.slices[0].draw_size.x == 16.0F &&
    slices.slices[0].draw_size.y == 32.0F &&
    slices.slices[3].offset.x == 24.0F
  inspect(ok, content="true")
}

///|
test "render2d: sliced sprite extraction follows computed slices instead of ui slice path" {
  let sprite = Sprite::from_image(@asset.Handle::new(1))
    .with_image_mode(
      SpriteImageMode::Sliced(TextureSlicer::new(BorderRect::square(8.0F))),
    )
    .with_custom_size(Some(@math.Vec2::new(96.0F, 64.0F)))
  let sprites : Array[ExtractedSprite] = []
  let appended = append_computed_sprite_slices(
    sprites,
    @core.Entity::new(1, 0),
    sprite,
    Anchor::center(),
    @transform.Transform::identity(),
    RenderLayers::default(),
    None,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(32.0F, 32.0F),
  )
  let ok = appended &&
    sprites.length() == 9 &&
    sprites[0].payload.texture.id() == 1 &&
    sprites[0].payload.uv_min.x == 0.0F &&
    sprites[0].payload.uv_max.x == 0.25F
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
test "render2d: logical view extent derives from physical viewport and scale factor" {
  let ok = render2d_logical_view_extent_axis(2560, 2.0F) == 1280 &&
    render2d_logical_view_extent_axis(1440, 2.0F) == 720 &&
    render2d_logical_view_extent_axis(999, 1.5F) == 666
  inspect(ok, content="true")
}

///|
pub fn render_execute_system(world : @ecs.World) -> Unit {
  let material_runtime_registry = material2d_runtime_registry_or_empty(world)
  render_state_update(world, fn(rs) {
    if !rs.val.draw_enabled {
      render2d_diagnostic_prepared_camera_count_ref.val = 0
      render2d_diagnostic_queued_draw_item_count_ref.val = 0
      return
    }
    rs.val.draw_enabled = false
    gizmos_prepare()
    let cameras = rs.val.cameras
    if cameras.length() == 0 {
      gizmos_clear()
      rs.val.prepared_camera_indices.clear()
      rs.val.queued_draw_item_counts.clear()
      render2d_diagnostic_prepared_camera_count_ref.val = 0
      render2d_diagnostic_queued_draw_item_count_ref.val = 0
      rs.val.extra_sprites.clear()
      rs.val.extra_ui_rects.clear()
      rs.val.extra_ui_box_shadows.clear()
      rs.val.extra_ui_texture_slices.clear()
      return
    }
    let sprites = rs.val.sprites
    let extra_sprites = rs.val.extra_sprites
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

    let camera_indices = if rs.val.prepared_camera_indices.length() ==
      cameras.length() {
      rs.val.prepared_camera_indices
    } else {
      render2d_sorted_camera_indices(cameras)
    }
    for index in camera_indices {
      let camera = cameras[index]
      let mut target_id = -1
      let target_size = camera.computed.target_size
      let target_width = target_size.x
      let target_height = target_size.y
      match camera.target {
        Screen => target_id = -1
        Window(window_ref) =>
          if @window.window_host_window_for_ref(world, window_ref)
            is Some(host_window) {
            let surface_target_id = @render.host_gpu_surface_target_id_for_window(
              host_window,
            )
            if surface_target_id < 0 {
              target_id = surface_target_id
            }
          }
        Image(handle) => target_id = handle.id()
      }
      @render.host_gpu_set_active_surface_target(target_id)
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
      // Keep render targets in physical pixels, but derive the camera
      // projection extent from the logical viewport size like Bevy does via
      // `Camera::logical_viewport_size()`.
      let view_width_logical = render2d_logical_view_extent_axis(
        view_width, scale_factor,
      )
      let view_height_logical = render2d_logical_view_extent_axis(
        view_height, scale_factor,
      )
      if view_width_logical <= 0 || view_height_logical <= 0 {
        continue
      }
      let (clear_enabled, clear) = camera.camera.clear_color.resolve()
      let draw_items = draw_registered_scene_items_for_layers(
        world,
        material_runtime_registry,
        sprites,
        extra_sprites,
        meshes,
        camera.layers,
      )
      let ui_overlay_draw_items = draw_ui_overlay_items_for_layers(
        extra_ui_rects,
        extra_ui_box_shadows,
        extra_ui_texture_slices,
        camera.entity,
        camera.layers,
      )
      fn draw_camera_items(
        items : Array[DrawItem],
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
                @render.host_gpu_clear_scissor()
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
                @render.host_gpu_set_scissor(x=sx, y=sy, width=sw, height=sh)
                scissor_active = true
                scissor_x = sx
                scissor_y = sy
                scissor_w = sw
                scissor_h = sh
              }
            }
          }
        }

        for item in items {
          match item.kind {
            SpriteMain(i) => {
              let sprite = sprites[i].payload
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @render.host_gpu_draw_sprite_uv(
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
              let sprite = extra_sprites[i].payload
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @render.host_gpu_draw_sprite_uv(
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
            Mesh(i) => {
              apply_scissor(None)
              let mesh = meshes[i]
              draw_registered_material2d_mesh_item(
                world,
                material_runtime_registry,
                item.material_runtime_index,
                mesh,
              )
            }
            UiRectExtra(i) => {
              let rect = extra_ui_rects[i].payload
              apply_scissor(rect.scissor)
              let transform = rect.transform
              let pos = @math.Vec2::new(
                transform.translation.x + rect.anchor_offset.x,
                transform.translation.y + rect.anchor_offset.y,
              )
              @render.host_gpu_draw_ui_rect(
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
              let shadow = extra_ui_box_shadows[i].payload
              apply_scissor(shadow.scissor)
              let transform = shadow.transform
              let pos = @math.Vec2::new(
                transform.translation.x + shadow.anchor_offset.x,
                transform.translation.y + shadow.anchor_offset.y,
              )
              @render.host_gpu_draw_ui_box_shadow(
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
              let slice = extra_ui_texture_slices[i].payload
              apply_scissor(slice.scissor)
              let transform = slice.transform
              let pos = @math.Vec2::new(
                transform.translation.x + slice.anchor_offset.x,
                transform.translation.y + slice.anchor_offset.y,
              )
              @render.host_gpu_draw_ui_texture_slice(
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
      let color_grading = camera_color_grading(world, camera.entity)
      let camera_postprocess_plan = render2d_camera_postprocess_plan(
        camera.bloom,
        tonemapping_mode,
        color_grading,
      )
      let mut auto_postprocess_source : @asset.Handle[@asset.Image]? = None
      if camera_postprocess_plan.uses_intermediate_source {
        auto_postprocess_source = Some(
          render2d_get_or_create_postprocess_intermediate_target(
            rs.val,
            camera.entity,
            viewport_width,
            viewport_height,
          ),
        )
      }

      if auto_postprocess_source is Some(source) {
        @render.host_gpu_begin_pass_with_depth(
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
          camera_scale=render2d_camera_uniform_scale(
            camera.projection,
            camera.transform,
          ),
          viewport_x=0,
          viewport_y=0,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        draw_camera_items(
          draw_items, 0, 0, viewport_width, viewport_height, scale_factor,
        )
        draw_wireframe_meshes_for_layers(meshes, camera.layers)
        @render.host_gpu_end_pass()

        @render.host_gpu_begin_pass(
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
          camera_scale=render2d_camera_uniform_scale(
            camera.projection,
            camera.transform,
          ),
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        if camera_postprocess_plan.apply_bloom_before_tonemapping {
          render2d_apply_camera_bloom_from_source(
            camera, source, viewport_width, viewport_height,
          )
        }
        if camera_postprocess_plan.tonemap_source_to_target {
          render2d_draw_camera_tonemapping(
            world, source, tonemapping_mode, deband_dither_enabled, color_grading,
            viewport_width, viewport_height,
          )
        }
        if camera_postprocess_plan.draw_ui_overlay_after_postprocess {
          draw_camera_items(
            ui_overlay_draw_items, viewport_x, viewport_y, viewport_width, viewport_height,
            scale_factor,
          )
        }
        gizmos_draw_lines(camera.layers)
        @render.host_gpu_end_pass()
        continue
      }

      if camera.bloom is None {
        @render.host_gpu_begin_pass_with_depth(
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
          camera_scale=render2d_camera_uniform_scale(
            camera.projection,
            camera.transform,
          ),
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        draw_camera_items(
          draw_items, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
        )
        draw_wireframe_meshes_for_layers(meshes, camera.layers)
        gizmos_draw_lines(camera.layers)
        @render.host_gpu_end_pass()
        if ui_overlay_draw_items.length() > 0 {
          @render.host_gpu_begin_pass(
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
            camera_scale=render2d_camera_uniform_scale(
              camera.projection,
              camera.transform,
            ),
            viewport_x~,
            viewport_y~,
            viewport_width~,
            viewport_height~,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=0,
          )
          draw_camera_items(
            ui_overlay_draw_items, viewport_x, viewport_y, viewport_width, viewport_height,
            scale_factor,
          )
          @render.host_gpu_end_pass()
        }
        continue
      }
      @render.host_gpu_begin_pass_with_depth(
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
        camera_scale=render2d_camera_uniform_scale(
          camera.projection,
          camera.transform,
        ),
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=if clear_enabled { 1 } else { 0 },
      )
      draw_camera_items(
        draw_items, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
      )
      draw_wireframe_meshes_for_layers(meshes, camera.layers)
      gizmos_draw_lines(camera.layers)
      @render.host_gpu_end_pass()
    }
    gizmos_clear()
    rs.val.prepared_camera_indices.clear()
    rs.val.queued_draw_item_counts.clear()
    rs.val.extra_sprites.clear()
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
  let mut found : ExtractedCamera2d? = None
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
  let mut found : ExtractedCamera2d? = None
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
  camera_transform : @transform.Transform,
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
  let scale = render2d_camera_uniform_scale(projection, camera_transform)
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
  camera_transform : @transform.Transform,
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
  let safe_scale = render2d_camera_uniform_scale(projection, camera_transform)
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
      let proj_scale = render2d_camera_uniform_scale(
        camera.projection,
        camera.transform,
      )
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
pub let render2d_set_extract_materials : @app.SystemSet = @app.system_set(
  "bevy.render2d.extract_materials",
)

///|
pub let render2d_set_prepare_materials : @app.SystemSet = @app.system_set(
  "bevy.render2d.prepare_materials",
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
  color_material_plugin(ColorMaterialPlugin::default())(
    app.init_resource(fn() { ClearColor::default() }),
  )
  .init_resource(fn() {
    let assets : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
    assets
  })
  .add_startup_system(register_render2d_bevy_shader_sources)
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
    render2d_set_extract_materials,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract_materials, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare_materials, before=[
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
  color_material_plugin(ColorMaterialPlugin::default())(
    app.init_resource(fn() { ClearColor::default() }),
  )
  .init_resource(fn() {
    let assets : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
    assets
  })
  .add_startup_system(register_render2d_bevy_shader_sources)
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
    render2d_set_extract_materials,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract_materials, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare_materials, before=[
    render2d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare, before=[
    render2d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render2d_set_queue, before=[
    render2d_set_render,
  ])
}
