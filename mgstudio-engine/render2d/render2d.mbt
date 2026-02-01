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
  color : Color
}

///|
pub fn Sprite::new(color : Color) -> Sprite {
  Sprite::{ color, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SpriteTexture {
  texture : @asset.Handle[@asset.Image]
}

///|
pub fn SpriteTexture::new(
  texture : @asset.Handle[@asset.Image],
) -> SpriteTexture {
  SpriteTexture::{ texture, }
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

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ColorMaterial {
  color : Color
}

///|
pub fn ColorMaterial::new(color : Color) -> ColorMaterial {
  ColorMaterial::{ color, }
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
pub(all) enum Mesh2dKind {
  Capsule(Capsule2d)
  Rectangle(Rectangle)
  Geometry(@mesh.Mesh2dGeometry)
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Mesh2d {
  kind : Mesh2dKind
}

///|
pub fn Mesh2d::from_capsule(capsule : Capsule2d) -> Mesh2d {
  Mesh2d::{ kind: Capsule(capsule) }
}

///|
pub fn Mesh2d::from_rectangle(rectangle : Rectangle) -> Mesh2d {
  Mesh2d::{ kind: Rectangle(rectangle) }
}

///|
pub fn Mesh2d::from_geometry(geometry : @mesh.Mesh2dGeometry) -> Mesh2d {
  Mesh2d::{ kind: Geometry(geometry) }
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
  transform : @math.Transform
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
}

///|
pub fn SpriteBundle::new(
  sprite : Sprite,
  transform : @math.Transform,
  texture : @asset.Handle[@asset.Image],
) -> SpriteBundle {
  SpriteBundle::{ sprite, transform, texture, layers: RenderLayers::default() }
}

///|
pub fn SpriteBundle::new_with_layers(
  sprite : Sprite,
  transform : @math.Transform,
  texture : @asset.Handle[@asset.Image],
  layers : RenderLayers,
) -> SpriteBundle {
  SpriteBundle::{ sprite, transform, texture, layers }
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
}

///|
pub fn Mesh2dBundle::new(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @math.Transform,
) -> Mesh2dBundle {
  Mesh2dBundle::{ mesh, material, transform, layers: RenderLayers::default() }
}

///|
pub fn Mesh2dBundle::new_with_layers(
  mesh : Mesh2d,
  material : ColorMaterial,
  transform : @math.Transform,
  layers : RenderLayers,
) -> Mesh2dBundle {
  Mesh2dBundle::{ mesh, material, transform, layers }
}

///|
priv struct SpriteInstance {
  transform : @math.Transform
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
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
fn sprite_uv_from_atlas_rect(
  atlas_size : @math.UVec2,
  rect : @math.URect,
) -> (@math.Vec2, @math.Vec2)? {
  if atlas_size.x <= 0 || atlas_size.y <= 0 {
    return None
  }
  let atlas_width = Float::from_double(atlas_size.x.to_double())
  let atlas_height = Float::from_double(atlas_size.y.to_double())
  let uv_min = @math.Vec2::new(
    Float::from_double(rect.min.x.to_double()) / atlas_width,
    Float::from_double(rect.min.y.to_double()) / atlas_height,
  )
  let uv_max = @math.Vec2::new(
    Float::from_double(rect.max.x.to_double()) / atlas_width,
    Float::from_double(rect.max.y.to_double()) / atlas_height,
  )
  Some((uv_min, uv_max))
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
  W : @core.SpawnWorld + @core.ChangeTickWorld + Has_Sprite + Has_SpriteTexture + Has_RenderLayers + @math.Has_Transform,
] SpriteBundle::spawn(
  self : SpriteBundle,
  world : W,
) -> @core.Entity {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let e = @core.SpawnWorld::spawn_empty(world)
  Has_Sprite::get_sprite_store(world).insert(e, self.sprite, tick)
  Has_SpriteTexture::get_sprite_texture_store(world).insert(
    e,
    SpriteTexture::new(self.texture),
    tick,
  )
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
  W : @core.SpawnWorld + @core.ChangeTickWorld + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + Has_RenderLayers + @math.Has_Transform,
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
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    self.transform,
    tick,
  )
  let mesh_id = match self.mesh.kind {
    Capsule(capsule) =>
      @window.host_gpu_create_mesh_capsule(
        capsule.radius,
        capsule.half_length,
        capsule.segments,
      )
    Rectangle(rectangle) => {
      let width = rectangle.half_size.x * 2.0F
      let height = rectangle.half_size.y * 2.0F
      @window.host_gpu_create_mesh_rectangle(width, height)
    }
    Geometry(geometry) =>
      match geometry.encode_triangle_positions_csv() {
        Some(vertices_csv) =>
          @window.host_gpu_create_mesh_triangles(vertices_csv)
        None => {
          let message = match geometry.validate() {
            Some(err) => "Mesh2dGeometry validation failed: " + err.to_string()
            None => "Mesh2dGeometry flatten failed"
          }
          @window.host_debug_string(message)
          0
        }
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
      transform,
      color,
      texture,
      layers,
      uv_min,
      uv_max,
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
  W : HasRes_RenderState + Has_Camera2d + Has_Camera + Has_Projection + Has_RenderTarget + Has_RenderLayers + Has_Sprite + Has_SpriteTexture + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + @math.Has_Transform + @transform.Has_GlobalTransform + @asset.Has_TextureAtlas + @core.ChangeTickWorld,
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
  let sprite_tex_store = Has_SpriteTexture::get_sprite_texture_store(world)
  let atlas_store = @asset.Has_TextureAtlas::get_texture_atlas_store(world)
  sprite_store.for_each(fn(entity, sprite) {
    guard sprite_tex_store.get(entity) is Some(sprite_tex) else { return }
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
    if atlas_store.get(entity) is Some(atlas) {
      if @asset.asset_get_texture_atlas_layout(atlas.layout)
        is Some(layout_value) {
        if atlas.index >= 0 && atlas.index < layout_value.textures.length() {
          let rect = layout_value.textures[atlas.index]
          if sprite_uv_from_atlas_rect(layout_value.size, rect) is Some(pair) {
            uv_min = pair.0
            uv_max = pair.1
          }
        }
      }
    }
    rs.val.sprites.push(SpriteInstance::{
      transform,
      color: sprite.color,
      texture: sprite_tex.texture,
      layers,
      uv_min,
      uv_max,
    })
  })
  let mesh_store = Has_Mesh2d::get_mesh2d_store(world)
  let gpu_mesh_store = Has_GpuMesh2d::get_gpu_mesh2d_store(world)
  let material_store = Has_ColorMaterial::get_color_material_store(world)
  mesh_store.for_each(fn(entity, _mesh) {
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
      mesh_id: gpu.mesh_id,
      transform,
      color: mat.color,
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
fn sprite_draw_indices(
  sprites : Array[SpriteInstance],
  layers : RenderLayers,
) -> Array[Int] {
  let opaque_indices : Array[Int] = []
  let transparent : Array[Int] = []
  let count = sprites.length()
  for i in 0..<count {
    let sprite = sprites[i]
    if !sprite.layers.matches(layers) {
      continue
    }
    if sprite.color.a >= 1.0F {
      opaque_indices.push(i)
    } else {
      transparent.push(i)
    }
  }
  // Opaque sprites can be safely re-ordered to improve batching.
  opaque_indices.sort_by(fn(a, b) {
    let ta = sprites[a].texture.id()
    let tb = sprites[b].texture.id()
    let c = cmp_int(ta, tb)
    if c != 0 {
      c
    } else {
      // Tie-break to keep the order deterministic.
      cmp_int(a, b)
    }
  })
  let out : Array[Int] = []
  for i in opaque_indices {
    out.push(i)
  }
  // Transparent sprites keep insertion order for stable blending.
  for i in transparent {
    out.push(i)
  }
  out
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
      camera.transform.rotation,
      camera.projection.scale,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
    )
    for sprite_index in sprite_draw_indices(sprites, camera.layers) {
      let sprite = sprites[sprite_index]
      let transform = sprite.transform
      @window.host_gpu_draw_sprite_uv(
        sprite.texture.id(),
        transform.translation.x,
        transform.translation.y,
        transform.rotation,
        transform.scale.x,
        transform.scale.y,
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
    for mesh in meshes {
      if mesh.layers.matches(camera.layers) {
        let transform = mesh.transform
        @window.host_gpu_draw_mesh(
          mesh.mesh_id,
          transform.translation.x,
          transform.translation.y,
          transform.rotation,
          transform.scale.x,
          transform.scale.y,
          mesh.color.r,
          mesh.color.g,
          mesh.color.b,
          mesh.color.a,
        )
      }
    }
    for sprite_index in sprite_draw_indices(extra_sprites, camera.layers) {
      let sprite = extra_sprites[sprite_index]
      let transform = sprite.transform
      @window.host_gpu_draw_sprite_uv(
        sprite.texture.id(),
        transform.translation.x,
        transform.translation.y,
        transform.rotation,
        transform.scale.x,
        transform.scale.y,
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
  let cosv = @math.cos(camera_transform.rotation)
  let sinv = @math.sin(camera_transform.rotation)
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
  let cosv = @math.cos(camera_transform.rotation)
  let sinv = @math.sin(camera_transform.rotation)
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
  W : HasRes_RenderState + Has_Camera2d + Has_Camera + Has_Projection + Has_RenderTarget + Has_RenderLayers + Has_Sprite + Has_SpriteTexture + Has_Mesh2d + Has_ColorMaterial + Has_GpuMesh2d + @math.Has_Transform + @transform.Has_GlobalTransform + @asset.Has_TextureAtlas + @core.ChangeTickWorld,
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
