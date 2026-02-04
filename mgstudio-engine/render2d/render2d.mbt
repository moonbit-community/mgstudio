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
  ScissorRect::{ rect }
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
}

///|
pub fn ColorMaterialAsset::new(color : Color) -> ColorMaterialAsset {
  ColorMaterialAsset::{ color, }
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
pub fn ColorMaterial::new(color : Color) -> ColorMaterial {
  let handle = color_material_assets.val.add(ColorMaterialAsset::new(color))
  ColorMaterial::{ handle, }
}

///|
pub fn ColorMaterial::color(self : ColorMaterial) -> Color {
  match color_material_get(self.handle) {
    Some(mat) => mat.color
    None => Color::white()
  }
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
priv enum DrawKind {
  SpriteMain(Int)
  SpriteExtra(Int)
  Mesh(Int)
}

///|
priv struct DrawItem {
  kind : DrawKind
  z : Float
  // 0 = opaque, 1 = transparent (opaque first for stable blending).
  phase : Int
  // Rough pipeline grouping: 0 = sprite, 1 = mesh.
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
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.layers.matches(layers) {
      continue
    }
    let phase = if mesh.color.a >= 1.0F { 0 } else { 1 }
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
      layers,
    },
  ]
  let items = draw_items_for_layers(sprites, extra, meshes, layers)
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
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
    return
  }
  let sprites = rs.val.sprites
  let extra_sprites = rs.val.extra_sprites
  let meshes = rs.val.meshes

  fn int_from_f32_floor_nonneg(x : Float) -> Int {
    if x <= 0.0F { 0 } else { x.to_int() }
  }

  fn int_from_f32_ceil_nonneg(x : Float) -> Int {
    if x <= 0.0F {
      0
    } else {
      let i = x.to_int()
      let f = Float::from_double(i.to_double())
      if f < x { i + 1 } else { i }
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
    let max_x = int_from_f32_ceil_nonneg(rect.max.x * sf)
    let max_y = int_from_f32_ceil_nonneg(rect.max.y * sf)
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
    if w > max_w { w = max_w }
    if h > max_h { h = max_h }
    if w < 0 { w = 0 }
    if h < 0 { h = 0 }
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
      meshes,
      camera.layers,
    )
    let mut scissor_active = false
    let mut scissor_x = 0
    let mut scissor_y = 0
    let mut scissor_w = 0
    let mut scissor_h = 0

    fn apply_scissor(
      rect_opt : @math.Rect?,
    ) -> Unit {
      match rect_opt {
        None => {
          if scissor_active {
            @window.host_gpu_clear_scissor()
            scissor_active = false
          }
        }
        Some(rect) => {
          let (sx, sy, sw, sh) = physical_scissor_for_camera(
            rect,
            viewport_x,
            viewport_y,
            viewport_width,
            viewport_height,
            scale_factor,
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
        Mesh(i) => {
          apply_scissor(None)
          let mesh = meshes[i]
          let transform = mesh.transform
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
            mesh.color.a,
          )
        }
      }
    }
    gizmos_draw_lines(camera.layers)
    @window.host_gpu_end_pass()
  }
  gizmos_clear()
  rs.val.extra_sprites.clear()
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
