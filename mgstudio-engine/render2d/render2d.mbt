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
pub fn Color::white() -> Color {
  Color::new(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
pub fn Color::black() -> Color {
  Color::new(0.0F, 0.0F, 0.0F, 1.0F)
}

///|

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RenderLayers {
  mask : Int
}

///|
pub fn RenderLayers::default() -> RenderLayers {
  RenderLayers::{ mask: 1 }
}

///|
pub fn RenderLayers::layer(index : Int) -> RenderLayers {
  let clamped = if index < 0 { 0 } else { index }
  RenderLayers::{ mask: 1 << clamped }
}

///|
pub fn RenderLayers::matches(self : RenderLayers, other : RenderLayers) -> Bool {
  (self.mask & other.mask) != 0
}

///|
pub struct Viewport {
  physical_position : @math.IVec2
  physical_size : @math.IVec2
}

///|
pub fn Viewport::new(
  physical_position : @math.IVec2,
  physical_size : @math.IVec2,
) -> Viewport {
  Viewport::{ physical_position, physical_size }
}

///|

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Sprite {
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  color : Color
  flip_x : Bool
  flip_y : Bool
  custom_size : @math.Vec2?
  rect : @math.Rect?
  image_mode : SpriteImageMode
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
  Sliced(TextureSlicer)
}

///|
pub fn SpriteImageMode::default() -> SpriteImageMode {
  SpriteImageMode::Auto
}

///|
fn sprite_image_mode_uses_slices(mode : SpriteImageMode) -> Bool {
  match mode {
    SpriteImageMode::Sliced(_) => true
    _ => false
  }
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
#ecs.component
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
}

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
}

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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Camera {
  viewport : Viewport?
  order : Int
  clear_color : Color
}

///|
pub fn Camera::new(clear_color : Color) -> Camera {
  Camera::{ viewport: None, order: 0, clear_color }
}

///|
pub fn Camera::default() -> Camera {
  Camera::new(Color::new(0.5F, 0.5F, 0.5F, 1.0F))
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
/// The projection parameters for an orthographic camera.
/// Stored inside `Projection` (mirrors Bevy's `Projection::Orthographic`).
pub struct OrthographicProjection {
  scale : Float
}

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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum Projection {
  Orthographic(OrthographicProjection)
}

///|
pub fn Projection::orthographic_2d() -> Projection {
  Orthographic(OrthographicProjection::default_2d())
}

///|
/// Marker component that enables 2D camera semantics (mirrors Bevy's `Camera2d`).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Camera2d {}

///|
pub fn Camera2d::default() -> Camera2d {
  Camera2d::{  }
}

///|

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
}

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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
}

///|
pub fn CircularSector::new(
  radius : Float,
  half_angle : Float,
) -> CircularSector {
  CircularSector::{ radius, half_angle, vertices: 32 }
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
pub struct CircularSegment {
  radius : Float
  half_angle : Float
  vertices : Int
}

///|
pub fn CircularSegment::new(
  radius : Float,
  half_angle : Float,
) -> CircularSegment {
  CircularSegment::{ radius, half_angle, vertices: 32 }
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Mesh2d {
  mesh : @asset.Handle[@mesh.Mesh]
}

///|
let mesh_assets : Ref[@asset.Assets[@mesh.Mesh]] = Ref::new(
  @asset.Assets::new(),
)

///|
fn mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_assets.val.add(mesh)
}

///|
fn mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_assets.val.get(handle)
}

///|
pub fn Mesh2d::new(mesh : @asset.Handle[@mesh.Mesh]) -> Mesh2d {
  Mesh2d::{ mesh, }
}

///|
fn rectangle_to_mesh2d_geometry(rectangle : Rectangle) -> @mesh.Mesh2dGeometry {
  let hx = rectangle.half_size.x
  let hy = rectangle.half_size.y
  let positions = [
    @math.Vec2::new(-hx, -hy),
    @math.Vec2::new(hx, -hy),
    @math.Vec2::new(hx, hy),
    @math.Vec2::new(-hx, hy),
  ]
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
fn rhombus_to_mesh2d_geometry(rhombus : Rhombus) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.y), 0.5F)
  let perimeter = [
    @math.Vec2::new(0.0F, hy),
    @math.Vec2::new(hx, 0.0F),
    @math.Vec2::new(0.0F, -hy),
    @math.Vec2::new(-hx, 0.0F),
  ]
  shape_geometry_from_nonindexed_positions(shape_triangulate_fan(perimeter))
}

///|
fn regular_polygon_to_mesh2d_geometry(
  polygon : RegularPolygon,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(polygon.radius), 0.5F)
  let sides = shape_safe_segments(polygon.sides, 3)
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
  shape_geometry_from_nonindexed_positions(shape_triangulate_fan(perimeter))
}

///|
fn triangle_to_mesh2d_geometry(triangle : Triangle2d) -> @mesh.Mesh2dGeometry {
  shape_geometry_from_nonindexed_positions([triangle.a, triangle.b, triangle.c])
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
        @math.cos(-angle) * 0.5F + 0.5F,
        @math.sin(-angle) * 0.5F + 0.5F,
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
  let resolution = shape_safe_segments(segment.vertices, 2)
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  let midpoint_y = circular_segment_apothem(radius, half_angle)
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  positions.push(@math.Vec2::new(0.0F, midpoint_y))
  uvs.push(@math.Vec2::new(0.5F, 0.5F - 0.5F * midpoint_y / radius))
  for i in 0..<resolution {
    let angle = arc_angle_from_index(first_angle, last_angle, i, resolution)
    positions.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
    uvs.push(
      @math.Vec2::new(
        @math.cos(-angle) * 0.5F + 0.5F,
        @math.sin(-angle) * 0.5F + 0.5F,
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
  let r = capsule.radius
  let half = capsule.half_length
  let mut segments = capsule.segments
  if segments < 4 {
    segments = 4
  }
  let pi = @math.pi_half() * 2.0F
  // Build a convex polygon perimeter (CCW), then triangulate as an indexed fan.
  let perimeter : Array[@math.Vec2] = []
  // Top arc: theta 0..pi (includes endpoints).
  for i in 0..<(segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = t * pi
    // theta in [0, pi]
    let x = @math.cos(theta) * r
    let y = @math.sin(theta) * r + half
    perimeter.push(@math.Vec2::new(x, y))
  }
  // Left side down to bottom arc start.
  perimeter.push(@math.Vec2::new(-r, -half))
  // Bottom arc: theta pi..2pi (skip first point to avoid dup).
  for i in 1..<(segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = pi + t * pi
    let x = @math.cos(theta) * r
    let y = @math.sin(theta) * r - half
    perimeter.push(@math.Vec2::new(x, y))
  }
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
  }
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

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
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
  }
}

///|
fn[W : HasRes_RenderState] render_state_ref(world : W) -> Ref[RenderState]? {
  HasRes_RenderState::get_render_state_resource(world).get_ref()
}

///|
fn[W : HasRes_RenderState + @core.ChangeTickWorld] render_state_ref_mut(
  world : W,
) -> Ref[RenderState]? {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_RenderState::get_render_state_resource(world).get_ref_mut(tick)
}

///|
fn[W : HasRes_RenderState + @core.ChangeTickWorld] init_render_state_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_RenderState::get_render_state_resource(world)
  if !res.is_present() {
    res.insert(RenderState::new(), tick)
    gizmos_reset()
  }
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
) -> @math.Vec2 {
  let a = anchor.as_vec()
  let offset_local = @math.Vec2::new(-a.x * draw_scale.x, -a.y * draw_scale.y)
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_create_render_target(
  world : W,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @window.host_gpu_create_render_target(width, height, nearest)
  let rs = render_state_ref_mut(world).unwrap()
  rs.val.render_targets.push(RenderTargetInfo::{ id, width, height })
  @asset.Handle::new(id)
}

///|
pub fn[
  W : @core.SpawnWorld + @core.ChangeTickWorld + Has_Sprite + Has_Anchor + Has_RenderLayers + @math.Has_Transform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility,
] SpriteBundle::spawn(
  self : SpriteBundle,
  world : W,
) -> @core.Entity {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let e = @core.SpawnWorld::spawn_empty(world)
  Has_Sprite::get_sprite_store(world).insert(e, self.sprite, tick)
  Has_Anchor::get_anchor_store(world).insert(e, self.anchor, tick)
  Has_RenderLayers::get_render_layers_store(world).insert(e, self.layers, tick)
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    e,
    self.visibility,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    e,
    self.inherited_visibility,
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    e,
    self.view_visibility,
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    self.transform,
    tick,
  )
  e
}

///|
pub fn[
  W : @core.SpawnWorld + @core.ChangeTickWorld + Has_Camera2d + Has_Camera + Has_Projection + Has_RenderTarget + Has_RenderLayers + @math.Has_Transform,
] Camera2dBundle::spawn(
  self : Camera2dBundle,
  world : W,
) -> @core.Entity {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let e = @core.SpawnWorld::spawn_empty(world)
  Has_Camera2d::get_camera2d_store(world).insert(e, self.camera2d, tick)
  Has_Camera::get_camera_store(world).insert(e, self.camera, tick)
  Has_Projection::get_projection_store(world).insert(e, self.projection, tick)
  Has_RenderTarget::get_render_target_store(world).insert(e, self.target, tick)
  Has_RenderLayers::get_render_layers_store(world).insert(e, self.layers, tick)
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    self.transform,
    tick,
  )
  e
}

///|
pub fn[
  W : @core.SpawnWorld + @core.ChangeTickWorld + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + Has_RenderLayers + @math.Has_Transform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility,
] Mesh2dBundle::spawn(
  self : Mesh2dBundle,
  world : W,
) -> @core.Entity {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let e = @core.SpawnWorld::spawn_empty(world)
  Has_Mesh2d::get_mesh2d_store(world).insert(e, self.mesh, tick)
  Has_ColorMaterial::get_color_material_store(world).insert(
    e,
    self.material,
    tick,
  )
  Has_RenderLayers::get_render_layers_store(world).insert(e, self.layers, tick)
  @visibility.Has_Visibility::get_visibility_store(world).insert(
    e,
    self.visibility,
    tick,
  )
  @visibility.Has_InheritedVisibility::get_inherited_visibility_store(world).insert(
    e,
    self.inherited_visibility,
    tick,
  )
  @visibility.Has_ViewVisibility::get_view_visibility_store(world).insert(
    e,
    self.view_visibility,
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    self.transform,
    tick,
  )
  let mesh_id = match mesh_asset_get(self.mesh.mesh) {
    Some(mesh_asset) =>
      match mesh_asset.geometry2d.encode_triangle_positions_csv() {
        Some(vertices_csv) =>
          @window.host_gpu_create_mesh_triangles(vertices_csv)
        None => {
          let geometry = mesh_asset.geometry2d
          let message = match geometry.validate() {
            Some(err) => "Mesh2dGeometry validation failed: " + err.to_string()
            None => "Mesh2dGeometry flatten failed"
          }
          @window.host_debug_string(message)
          0
        }
      }
    None => {
      @window.host_debug_string("Mesh2d spawn failed: mesh handle not found")
      0
    }
  }
  Has_GpuMesh2d::get_gpu_mesh2d_store(world).insert(
    e,
    GpuMesh2d::new(mesh_id),
    tick,
  )
  e
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_clear_overlay_sprites(
  world : W,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) { rs.val.extra_sprites.clear() })
  |> ignore
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_clear_overlay_sprite_texture_slices(
  world : W,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) {
    rs.val.extra_sprite_texture_slices.clear()
  })
  |> ignore
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_push_sprite_uv(
  world : W,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) {
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_push_sprite_uv_scissor(
  world : W,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) {
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_clear_overlay_ui_rects(
  world : W,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) { rs.val.extra_ui_rects.clear() })
  |> ignore
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_clear_overlay_ui_box_shadows(
  world : W,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) { rs.val.extra_ui_box_shadows.clear() })
  |> ignore
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_clear_overlay_ui_texture_slices(
  world : W,
) -> Unit {
  render_state_ref_mut(world).map(fn(rs) {
    rs.val.extra_ui_texture_slices.clear()
  })
  |> ignore
}

///|
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_push_ui_rect_uv_scissor(
  world : W,
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
  render_state_ref_mut(world).map(fn(rs) {
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_push_ui_box_shadow_scissor(
  world : W,
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
  render_state_ref_mut(world).map(fn(rs) {
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render2d_push_ui_texture_slice_scissor(
  world : W,
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
  render_state_ref_mut(world).map(fn(rs) {
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
fn render2d_clamp_viewport(
  viewport : Viewport,
  target_size : @math.IVec2,
) -> Viewport {
  let mut position = viewport.physical_position
  let mut size = viewport.physical_size
  if position.x < 0 || position.y < 0 {
    position = @math.IVec2::new(
      if position.x < 0 {
        0
      } else {
        position.x
      },
      if position.y < 0 {
        0
      } else {
        position.y
      },
    )
  }
  if size.x < 0 || size.y < 0 {
    size = @math.IVec2::new(
      if size.x < 0 {
        0
      } else {
        size.x
      },
      if size.y < 0 {
        0
      } else {
        size.y
      },
    )
  }
  let max_position = target_size.saturating_sub(size)
  position = position.min(max_position)
  let max_size = target_size.saturating_sub(position)
  size = size.min(max_size)
  Viewport::new(position, size)
}

///|
pub fn[W] render2d_camera_system(_world : W) -> Unit {
  // Legacy system retained for API compatibility; camera extraction computes
  // derived values each frame in `render_extract_system`.
}

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
pub fn[
  W : HasRes_RenderState + Has_Camera2d + Has_Camera + Has_Projection + Has_RenderTarget + Has_RenderLayers + Has_Sprite + Has_ScissorRect + Has_Anchor + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] render_extract_system(
  world : W,
) -> Unit {
  guard render_state_ref_mut(world) is Some(rs) else { return }
  rs.val.draw_enabled = true
  rs.val.primary_camera = @core.Entity::placeholder()
  rs.val.sprites.clear()
  rs.val.cameras.clear()
  rs.val.meshes.clear()
  let camera2d_store = Has_Camera2d::get_camera2d_store(world)
  let camera_store = Has_Camera::get_camera_store(world)
  let projection_store = Has_Projection::get_projection_store(world)
  let target_store = Has_RenderTarget::get_render_target_store(world)
  let layers_store = Has_RenderLayers::get_render_layers_store(world)
  let view_visibility_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let global_store = @transform.Has_GlobalTransform::get_global_transform_store(
    world,
  )
  camera2d_store.for_each(fn(entity, _marker) {
    let target = match target_store.get(entity) {
      Some(t) => t
      None => RenderTarget::Screen
    }
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => RenderLayers::default()
    }
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
    let mut camera_value = camera
    if render2d_target_info(rs.val, target) is Some(info) {
      computed = CameraComputed::{
        target_size: info.size,
        scale_factor: info.scale_factor,
      }
      if camera_value.viewport is Some(viewport) {
        let clamped = render2d_clamp_viewport(viewport, info.size)
        camera_value = Camera::{
          viewport: Some(clamped),
          order: camera_value.order,
          clear_color: camera_value.clear_color,
        }
      }
    }
    rs.val.cameras.push(CameraInstance::{
      entity,
      camera: camera_value,
      projection,
      transform,
      target,
      layers,
      computed,
    })
  })
  if rs.val.cameras.length() > 0 {
    let order = render2d_sorted_camera_indices(rs.val.cameras)
    if order.length() > 0 {
      rs.val.primary_camera = rs.val.cameras[order[0]].entity
    }
  }
  let sprite_store = Has_Sprite::get_sprite_store(world)
  let anchor_store = Has_Anchor::get_anchor_store(world)
  let scissor_store = Has_ScissorRect::get_scissor_rect_store(world)
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
    let anchor_offset = sprite_anchor_offset(
      anchor,
      transform.rotation_z(),
      draw_scale,
    )
    let scissor = match scissor_store.get(entity) {
      Some(v) => Some(v.rect)
      None => None
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
        draw_scale,
        color: sprite.color,
        texture: sprite.image,
        layers,
        uv_min,
        uv_max,
        scissor,
      })
    }
  })
  let mesh_store = Has_Mesh2d::get_mesh2d_store(world)
  let gpu_mesh_store = Has_GpuMesh2d::get_gpu_mesh2d_store(world)
  let material_store = Has_ColorMaterial::get_color_material_store(world)
  mesh_store.for_each(fn(entity, _mesh) {
    if view_visibility_store.get(entity) is Some(vv) && !vv.is_visible() {
      return
    }
    guard gpu_mesh_store.get(entity) is Some(gpu) else { return }
    guard material_store.get(entity) is Some(mat) else { return }
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
  })
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
    circular_sector_to_mesh2d_geometry(
      CircularSector::from_turns(10.0F, 0.35F).with_vertices(24),
    ),
    circular_segment_to_mesh2d_geometry(
      CircularSegment::from_turns(10.0F, 0.35F).with_vertices(24),
    ),
    rhombus_to_mesh2d_geometry(Rhombus::new(12.0F, 20.0F)),
    regular_polygon_to_mesh2d_geometry(RegularPolygon::new(10.0F, 6)),
    triangle_to_mesh2d_geometry(Triangle2d::default()),
    segment_to_mesh2d_geometry(
      Segment2d::new(
        @math.Vec2::new(-30.0F, 30.0F),
        @math.Vec2::new(30.0F, -30.0F),
      ).with_half_thickness(3.0F),
    ),
    polyline_to_mesh2d_geometry(polyline),
    capsule_to_mesh2d_geometry(Capsule2d::new(5.0F, 10.0F, 16)),
    rectangle_to_mesh2d_geometry(Rectangle::new(10.0F, 20.0F)),
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
pub fn[W : HasRes_RenderState + @core.ChangeTickWorld] render_execute_system(
  world : W,
) -> Unit {
  guard render_state_ref_mut(world) is Some(rs) else { return }
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
      view_width = viewport_width
      view_height = viewport_height
    }
    let view_width_f = Float::from_double(view_width.to_double()) / scale_factor
    let view_height_f = Float::from_double(view_height.to_double()) /
      scale_factor
    let view_width_logical = view_width_f.to_int()
    let view_height_logical = view_height_f.to_int()
    if view_width_logical <= 0 || view_height_logical <= 0 {
      continue
    }
    let clear = camera.camera.clear_color
    @window.host_gpu_begin_pass(
      target_id,
      view_width_logical,
      view_height_logical,
      clear.r,
      clear.g,
      clear.b,
      clear.a,
      camera.transform.translation.x,
      camera.transform.translation.y,
      camera.transform.rotation_z(),
      camera.projection.scale,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
    )
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
            rect, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
          )
          if !scissor_active ||
            sx != scissor_x ||
            sy != scissor_y ||
            sw != scissor_w ||
            sh != scissor_h {
            @window.host_gpu_set_scissor(sx, sy, sw, sh)
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
            sprite.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            sprite.draw_scale.x,
            sprite.draw_scale.y,
            sprite.color.r,
            sprite.color.g,
            sprite.color.b,
            sprite.color.a,
            sprite.uv_min.x,
            sprite.uv_min.y,
            sprite.uv_max.x,
            sprite.uv_max.y,
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
            sprite.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            sprite.draw_scale.x,
            sprite.draw_scale.y,
            sprite.color.r,
            sprite.color.g,
            sprite.color.b,
            sprite.color.a,
            sprite.uv_min.x,
            sprite.uv_min.y,
            sprite.uv_max.x,
            sprite.uv_max.y,
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
            slice.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            slice.draw_scale.x,
            slice.draw_scale.y,
            slice.color.r,
            slice.color.g,
            slice.color.b,
            slice.color.a,
            slice.texture_slices.x,
            slice.texture_slices.y,
            slice.texture_slices.z,
            slice.texture_slices.w,
            slice.target_slices.x,
            slice.target_slices.y,
            slice.target_slices.z,
            slice.target_slices.w,
            slice.repeat.x,
            slice.repeat.y,
            slice.repeat.z,
            slice.repeat.w,
            slice.atlas_rect.x,
            slice.atlas_rect.y,
            slice.atlas_rect.z,
            slice.atlas_rect.w,
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
            mesh.mesh_id,
            transform.translation.x,
            transform.translation.y,
            transform.rotation_z(),
            transform.scale.x,
            transform.scale.y,
            mesh.color.r,
            mesh.color.g,
            mesh.color.b,
            draw_alpha,
            texture_id,
            mesh.uv_offset.x,
            mesh.uv_offset.y,
            mesh.uv_scale.x,
            mesh.uv_scale.y,
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
            rect.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            rect.draw_scale.x,
            rect.draw_scale.y,
            rect.color.r,
            rect.color.g,
            rect.color.b,
            rect.color.a,
            rect.uv_min.x,
            rect.uv_min.y,
            rect.uv_max.x,
            rect.uv_max.y,
            rect.flags,
            rect.radius.top_left,
            rect.radius.top_right,
            rect.radius.bottom_right,
            rect.radius.bottom_left,
            rect.border.left,
            rect.border.top,
            rect.border.right,
            rect.border.bottom,
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
            shadow.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            shadow.draw_scale.x,
            shadow.draw_scale.y,
            shadow.color.r,
            shadow.color.g,
            shadow.color.b,
            shadow.color.a,
            shadow.size.x,
            shadow.size.y,
            shadow.radius.top_left,
            shadow.radius.top_right,
            shadow.radius.bottom_right,
            shadow.radius.bottom_left,
            shadow.blur,
            shadow.samples,
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
            slice.texture.id(),
            pos.x,
            pos.y,
            transform.rotation_z(),
            slice.draw_scale.x,
            slice.draw_scale.y,
            slice.color.r,
            slice.color.g,
            slice.color.b,
            slice.color.a,
            slice.texture_slices.x,
            slice.texture_slices.y,
            slice.texture_slices.z,
            slice.texture_slices.w,
            slice.target_slices.x,
            slice.target_slices.y,
            slice.target_slices.z,
            slice.target_slices.w,
            slice.repeat.x,
            slice.repeat.y,
            slice.repeat.z,
            slice.repeat.w,
            slice.atlas_rect.x,
            slice.atlas_rect.y,
            slice.atlas_rect.z,
            slice.atlas_rect.w,
          )
        }
      }
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
}

///|
pub fn[W : HasRes_RenderState] render2d_viewport_to_world_2d(
  world : W,
  screen : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world) is Some(rs) else { return None }
  let id = rs.val.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : CameraInstance? = None
  for camera in rs.val.cameras {
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
pub fn[W : HasRes_RenderState] render2d_world_to_viewport(
  world_ : W,
  world : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world_) is Some(rs) else { return None }
  let id = rs.val.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : CameraInstance? = None
  for camera in rs.val.cameras {
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
pub fn[W : HasRes_RenderState] render2d_debug_log_primary_camera(
  world : W,
) -> Unit {
  guard render_state_ref(world) is Some(rs) else { return }
  let id = rs.val.primary_camera
  if id.is_placeholder() {
    return
  }
  for camera in rs.val.cameras {
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
      @window.host_debug_string(message)
      return
    }
  }
}

///|
pub fn[
  W : HasRes_RenderState + Has_Camera2d + Has_Camera + Has_Projection + Has_RenderTarget + Has_RenderLayers + Has_Sprite + Has_ScissorRect + Has_Anchor + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] render2d_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_startup_system(init_render_state_system)
  .add_system(render_extract_system)
  .add_post_update_system(render_prepare_system)
  .add_post_update_system(render_queue_system)
  .add_post_update_system(render_execute_system)
}
