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
pub struct Sprite {
  color : Color
}

///|
pub fn Sprite::new(color : Color) -> Sprite {
  Sprite::{ color, }
}

///|
pub struct Camera2d {
  clear_color : Color
  order : Int
  scale : Float
}

///|
pub fn Camera2d::new(clear_color : Color) -> Camera2d {
  Camera2d::{ clear_color, order: 0, scale: 1.0F }
}

///|
pub fn Camera2d::default() -> Camera2d {
  Camera2d::new(Color::new(0.5F, 0.5F, 0.5F, 1.0F))
}

///|
pub fn Camera2d::with_order(self : Camera2d, order : Int) -> Camera2d {
  Camera2d::{ ..self, order, }
}

///|
pub fn Camera2d::with_scale(self : Camera2d, scale : Float) -> Camera2d {
  Camera2d::{ ..self, scale, }
}

///|
pub(all) enum RenderTarget {
  Screen
  Image(@asset.Handle[@asset.Image])
}

///|
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
}

///|
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
  camera : Camera2d
  transform : @math.Transform
  target : RenderTarget
  layers : RenderLayers
}

///|
pub fn Camera2dBundle::new(
  camera : Camera2d,
  transform : @math.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{
    camera,
    transform,
    target: RenderTarget::Screen,
    layers: RenderLayers::default(),
  }
}

///|
pub fn Camera2dBundle::new_with_target(
  camera : Camera2d,
  transform : @math.Transform,
  target : RenderTarget,
) -> Camera2dBundle {
  Camera2dBundle::{ camera, transform, target, layers: RenderLayers::default() }
}

///|
pub fn Camera2dBundle::new_with_layers(
  camera : Camera2d,
  transform : @math.Transform,
  target : RenderTarget,
  layers : RenderLayers,
) -> Camera2dBundle {
  Camera2dBundle::{ camera, transform, target, layers }
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
pub struct SpriteHandle {
  id : Int
}

///|
pub struct CameraHandle {
  id : Int
}

///|
pub struct MeshHandle {
  id : Int
}

///|
pub fn SpriteHandle::new(id : Int) -> SpriteHandle {
  SpriteHandle::{ id, }
}

///|
pub fn CameraHandle::new(id : Int) -> CameraHandle {
  CameraHandle::{ id, }
}

///|
pub fn MeshHandle::new(id : Int) -> MeshHandle {
  MeshHandle::{ id, }
}

///|
priv struct SpriteInstance {
  id : Int
  mut transform : @math.Transform
  color : Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
}

///|
priv struct CameraInstance {
  id : Int
  mut camera : Camera2d
  mut transform : @math.Transform
  target : RenderTarget
  layers : RenderLayers
}

///|
priv struct MeshInstance {
  id : Int
  mesh_id : Int
  mut transform : @math.Transform
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
priv struct RenderState {
  mut draw_enabled : Bool
  mut next_sprite_id : Int
  mut next_camera_id : Int
  mut next_mesh_id : Int
  mut primary_sprite : Int
  mut primary_camera : Int
  sprites : Array[SpriteInstance]
  cameras : Array[CameraInstance]
  meshes : Array[MeshInstance]
  render_targets : Array[RenderTargetInfo]
}

///|
let render_state : Ref[RenderState] = @ref.new(RenderState::{
  draw_enabled: false,
  next_sprite_id: 0,
  next_camera_id: 0,
  next_mesh_id: 0,
  primary_sprite: -1,
  primary_camera: -1,
  sprites: [],
  cameras: [],
  meshes: [],
  render_targets: [],
})

///|
pub fn render2d_create_render_target(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @window.host_gpu_create_render_target(width, height, nearest)
  render_state.val.render_targets.push(RenderTargetInfo::{ id, width, height })
  @asset.Handle::new(id)
}

///|
pub fn SpriteBundle::spawn(self : SpriteBundle) -> SpriteHandle {
  render2d_spawn_sprite(self)
}

///|
pub fn Camera2dBundle::spawn(self : Camera2dBundle) -> CameraHandle {
  render2d_spawn_camera(self)
}

///|
pub fn Mesh2dBundle::spawn(self : Mesh2dBundle) -> MeshHandle {
  render2d_spawn_mesh(self)
}

///|
pub fn render2d_spawn_sprite(bundle : SpriteBundle) -> SpriteHandle {
  let id = render_state.val.next_sprite_id
  render_state.val.next_sprite_id = id + 1
  render_state.val.sprites.push(SpriteInstance::{
    id,
    transform: bundle.transform,
    color: bundle.sprite.color,
    texture: bundle.texture,
    layers: bundle.layers,
  })
  render_state.val.primary_sprite = id
  SpriteHandle::{ id, }
}

///|
pub fn render2d_spawn_camera(bundle : Camera2dBundle) -> CameraHandle {
  let id = render_state.val.next_camera_id
  render_state.val.next_camera_id = id + 1
  render_state.val.cameras.push(CameraInstance::{
    id,
    camera: bundle.camera,
    transform: bundle.transform,
    target: bundle.target,
    layers: bundle.layers,
  })
  render_state.val.primary_camera = id
  CameraHandle::{ id, }
}

///|
pub fn render2d_spawn_mesh(bundle : Mesh2dBundle) -> MeshHandle {
  let id = render_state.val.next_mesh_id
  render_state.val.next_mesh_id = id + 1
  let mesh_id = match bundle.mesh.kind {
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
  }
  render_state.val.meshes.push(MeshInstance::{
    id,
    mesh_id,
    transform: bundle.transform,
    color: bundle.material.color,
    layers: bundle.layers,
  })
  MeshHandle::{ id, }
}

///|
pub fn render2d_set_sprite_transform_handle(
  handle : SpriteHandle,
  transform : @math.Transform,
) -> Unit {
  let count = render_state.val.sprites.length()
  for i in 0..<count {
    if render_state.val.sprites[i].id == handle.id {
      render_state.val.sprites[i].transform = transform
      return
    }
  }
}

///|
pub fn render2d_set_camera_transform_handle(
  handle : CameraHandle,
  transform : @math.Transform,
) -> Unit {
  let count = render_state.val.cameras.length()
  for i in 0..<count {
    if render_state.val.cameras[i].id == handle.id {
      render_state.val.cameras[i].transform = transform
      return
    }
  }
}

///|
pub fn render2d_set_mesh_transform_handle(
  handle : MeshHandle,
  transform : @math.Transform,
) -> Unit {
  let count = render_state.val.meshes.length()
  for i in 0..<count {
    if render_state.val.meshes[i].id == handle.id {
      render_state.val.meshes[i].transform = transform
      return
    }
  }
}

///|
pub fn render2d_set_sprite_transform(transform : @math.Transform) -> Unit {
  let id = render_state.val.primary_sprite
  if id < 0 {
    return
  }
  render2d_set_sprite_transform_handle(SpriteHandle::{ id, }, transform)
}

///|
pub fn render2d_set_camera_transform(transform : @math.Transform) -> Unit {
  let id = render_state.val.primary_camera
  if id < 0 {
    return
  }
  render2d_set_camera_transform_handle(CameraHandle::{ id, }, transform)
}

///|
pub fn render2d_set_camera_scale_handle(
  handle : CameraHandle,
  scale : Float,
) -> Unit {
  let count = render_state.val.cameras.length()
  for i in 0..<count {
    if render_state.val.cameras[i].id == handle.id {
      let camera = render_state.val.cameras[i].camera
      render_state.val.cameras[i].camera = Camera2d::{
        clear_color: camera.clear_color,
        order: camera.order,
        scale,
      }
      return
    }
  }
}

///|
pub fn render2d_set_camera_scale(scale : Float) -> Unit {
  let id = render_state.val.primary_camera
  if id < 0 {
    return
  }
  render2d_set_camera_scale_handle(CameraHandle::{ id, }, scale)
}

///|
fn render2d_find_render_target_size(id : Int) -> RenderTargetInfo? {
  for target in render_state.val.render_targets {
    if target.id == id {
      return Some(target)
    }
  }
  None
}

///|
fn render2d_sorted_camera_indices() -> Array[Int] {
  let count = render_state.val.cameras.length()
  let indices : Array[Int] = []
  for i in 0..<count {
    indices.push(i)
  }
  for i in 0..<count {
    let mut min_index = i
    let mut min_order = render_state.val.cameras[indices[i]].camera.order
    for j in (i + 1)..<count {
      let order = render_state.val.cameras[indices[j]].camera.order
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
pub fn render_extract_system() -> Unit {
  render_state.val.draw_enabled = true
}

///|
pub fn render_prepare_system() -> Unit {

}

///|
pub fn render_queue_system() -> Unit {

}

///|
pub fn render_execute_system() -> Unit {
  if !render_state.val.draw_enabled {
    return
  }
  render_state.val.draw_enabled = false
  let cameras = render_state.val.cameras
  if cameras.length() == 0 {
    return
  }
  let sprites = render_state.val.sprites
  let meshes = render_state.val.meshes
  for index in render2d_sorted_camera_indices() {
    let camera = cameras[index]
    let mut target_id = -1
    let mut target_width = @window.window_width()
    let mut target_height = @window.window_height()
    if camera.target is Image(handle) {
      target_id = handle.id()
      if render2d_find_render_target_size(target_id) is Some(info) {
        target_width = info.width
        target_height = info.height
      }
    }
    if target_width <= 0 || target_height <= 0 {
      continue
    }
    let clear = camera.camera.clear_color
    @window.host_gpu_begin_pass(
      target_id,
      target_width,
      target_height,
      clear.r,
      clear.g,
      clear.b,
      clear.a,
      camera.transform.translation.x,
      camera.transform.translation.y,
      camera.transform.rotation,
      camera.camera.scale,
    )
    for sprite in sprites {
      if sprite.layers.matches(camera.layers) {
        let transform = sprite.transform
        @window.host_gpu_draw_sprite(
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
        )
      }
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
    @window.host_gpu_end_pass()
  }
}

///|
pub fn render2d_viewport_to_world_2d(screen : @math.Vec2) -> @math.Vec2? {
  let id = render_state.val.primary_camera
  if id < 0 {
    return None
  }
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return None
  }
  let mut found : CameraInstance? = None
  for camera in render_state.val.cameras {
    if camera.id == id {
      found = Some(camera)
      break
    }
  }
  if found is None {
    return None
  }
  let cam = if found is Some(value) { value } else { return None }
  let half_width = Float::from_double(width.to_double()) / 2.0F
  let half_height = Float::from_double(height.to_double()) / 2.0F
  let inv_scale = if cam.camera.scale == 0.0F {
    1.0F
  } else {
    1.0F / cam.camera.scale
  }
  let view_x = (screen.x - half_width) * inv_scale
  let view_y = (half_height - screen.y) * inv_scale
  let cosv = @math.cos(cam.transform.rotation)
  let sinv = @math.sin(cam.transform.rotation)
  let world_x = cam.transform.translation.x + view_x * cosv + view_y * sinv
  let world_y = cam.transform.translation.y - view_x * sinv + view_y * cosv
  Some(@math.Vec2::new(world_x, world_y))
}

///|
pub fn render2d_plugin(app : @app.App) -> @app.App {
  app
  .add_system(render_extract_system)
  .add_post_update_system(render_prepare_system)
  .add_post_update_system(render_queue_system)
  .add_post_update_system(render_execute_system)
}
