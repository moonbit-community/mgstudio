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
  viewport : Viewport?
}

///|
pub fn Camera2d::new(clear_color : Color) -> Camera2d {
  Camera2d::{ clear_color, order: 0, scale: 1.0F, viewport: None }
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
pub fn Camera2d::with_viewport(
  self : Camera2d,
  viewport : Viewport,
) -> Camera2d {
  Camera2d::{ ..self, viewport: Some(viewport) }
}

///|
pub fn Camera2d::clear_viewport(self : Camera2d) -> Camera2d {
  Camera2d::{ ..self, viewport: None }
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
  computed : CameraComputed
}

///|
priv struct CameraComputed {
  mut target_size : @math.IVec2
  mut scale_factor : Float
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
    computed: CameraComputed::{
      target_size: @math.IVec2::new(0, 0),
      scale_factor: 1.0F,
    },
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
        viewport: camera.viewport,
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
pub fn render2d_set_camera_viewport_handle(
  handle : CameraHandle,
  viewport : Viewport?,
) -> Unit {
  let count = render_state.val.cameras.length()
  for i in 0..<count {
    if render_state.val.cameras[i].id == handle.id {
      let camera = render_state.val.cameras[i].camera
      render_state.val.cameras[i].camera = Camera2d::{
        clear_color: camera.clear_color,
        order: camera.order,
        scale: camera.scale,
        viewport,
      }
      return
    }
  }
}

///|
pub fn render2d_set_camera_viewport(viewport : Viewport?) -> Unit {
  let id = render_state.val.primary_camera
  if id < 0 {
    return
  }
  render2d_set_camera_viewport_handle(CameraHandle::{ id, }, viewport)
}

///|
pub fn render2d_debug_log_primary_camera() -> Unit {
  let id = render_state.val.primary_camera
  if id < 0 {
    return
  }
  for camera in render_state.val.cameras {
    if camera.id == id {
      let target = camera.computed.target_size
      let scale = camera.computed.scale_factor
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
        " viewport=" +
        viewport_text
      @window.host_debug_string(message)
      return
    }
  }
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
priv struct RenderTargetComputed {
  size : @math.IVec2
  scale_factor : Float
}

///|
fn render2d_target_info(camera : CameraInstance) -> RenderTargetComputed? {
  let mut width = @window.window_width()
  let mut height = @window.window_height()
  let mut scale_factor = @window.window_scale_factor()
  if camera.target is Image(handle) {
    let target_id = handle.id()
    if render2d_find_render_target_size(target_id) is Some(info) {
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
fn render2d_scale_ivec2(value : @math.IVec2, factor : Float) -> @math.IVec2 {
  let fx = value.x.to_double() * factor.to_double()
  let fy = value.y.to_double() * factor.to_double()
  @math.IVec2::new(fx.to_int(), fy.to_int())
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
pub fn render2d_camera_system() -> Unit {
  let count = render_state.val.cameras.length()
  for i in 0..<count {
    let camera_instance = render_state.val.cameras[i]
    let info_opt = render2d_target_info(camera_instance)
    if info_opt is None {
      render_state.val.cameras[i].computed.target_size = @math.IVec2::new(0, 0)
      render_state.val.cameras[i].computed.scale_factor = 1.0F
      continue
    }
    let info = if info_opt is Some(value) { value } else { continue }
    let old_scale = camera_instance.computed.scale_factor
    let new_scale = info.scale_factor
    let mut viewport_opt = camera_instance.camera.viewport
    if old_scale > 0.0F && new_scale != old_scale {
      if viewport_opt is Some(viewport) {
        let resize_factor = new_scale / old_scale
        let resized = Viewport::new(
          render2d_scale_ivec2(viewport.physical_position, resize_factor),
          render2d_scale_ivec2(viewport.physical_size, resize_factor),
        )
        viewport_opt = Some(resized)
      }
    }
    if viewport_opt is Some(viewport) {
      let clamped = render2d_clamp_viewport(viewport, info.size)
      viewport_opt = Some(clamped)
    }
    render_state.val.cameras[i].camera = Camera2d::{
      clear_color: camera_instance.camera.clear_color,
      order: camera_instance.camera.order,
      scale: camera_instance.camera.scale,
      viewport: viewport_opt,
    }
    render_state.val.cameras[i].computed.target_size = info.size
    render_state.val.cameras[i].computed.scale_factor = new_scale
  }
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
  gizmos_prepare()
  let cameras = render_state.val.cameras
  if cameras.length() == 0 {
    gizmos_clear()
    return
  }
  let sprites = render_state.val.sprites
  let meshes = render_state.val.meshes
  for index in render2d_sorted_camera_indices() {
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
      camera.camera.scale,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
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
    gizmos_draw_lines(camera.layers)
    @window.host_gpu_end_pass()
  }
  gizmos_clear()
}

///|
pub fn render2d_reset() -> Unit {
  render_state.val.draw_enabled = false
  render_state.val.next_sprite_id = 0
  render_state.val.next_camera_id = 0
  render_state.val.next_mesh_id = 0
  render_state.val.primary_sprite = -1
  render_state.val.primary_camera = -1
  render_state.val.sprites.clear()
  render_state.val.cameras.clear()
  render_state.val.meshes.clear()
  render_state.val.render_targets.clear()
  gizmos_reset()
}

///|
pub fn render2d_viewport_to_world_2d(screen : @math.Vec2) -> @math.Vec2? {
  let id = render_state.val.primary_camera
  if id < 0 {
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
  let target_size = cam.computed.target_size
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut scale_factor = cam.computed.scale_factor
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  let mut rect_x = 0
  let mut rect_y = 0
  let mut rect_width = width
  let mut rect_height = height
  if cam.camera.viewport is Some(viewport) {
    rect_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    rect_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    rect_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    rect_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
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
  let rect_x_f = Float::from_double(rect_x.to_double()) / scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) / scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) / scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let scale = if cam.camera.scale == 0.0F { 1.0F } else { cam.camera.scale }
  let local_x = screen.x - rect_x_f
  let local_y = screen.y - rect_y_f
  let view_x = (local_x - half_width) * scale
  let view_y = (half_height - local_y) * scale
  let cosv = @math.cos(cam.transform.rotation)
  let sinv = @math.sin(cam.transform.rotation)
  let world_x = cam.transform.translation.x + view_x * cosv + view_y * sinv
  let world_y = cam.transform.translation.y - view_x * sinv + view_y * cosv
  Some(@math.Vec2::new(world_x, world_y))
}

///|
pub fn render2d_world_to_viewport(world : @math.Vec2) -> @math.Vec2? {
  let id = render_state.val.primary_camera
  if id < 0 {
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
  let target_size = cam.computed.target_size
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut scale_factor = cam.computed.scale_factor
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  let mut rect_x = 0
  let mut rect_y = 0
  let mut rect_width = width
  let mut rect_height = height
  if cam.camera.viewport is Some(viewport) {
    rect_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    rect_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    rect_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    rect_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
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
  let rect_x_f = Float::from_double(rect_x.to_double()) / scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) / scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) / scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let dx = world.x - cam.transform.translation.x
  let dy = world.y - cam.transform.translation.y
  let cosv = @math.cos(cam.transform.rotation)
  let sinv = @math.sin(cam.transform.rotation)
  let view_x = dx * cosv - dy * sinv
  let view_y = dx * sinv + dy * cosv
  let safe_scale = if cam.camera.scale == 0.0F {
    1.0F
  } else {
    cam.camera.scale
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
pub fn render2d_plugin(app : @app.App) -> @app.App {
  render2d_reset()
  app
  .add_system(render2d_camera_system)
  .add_system(render_extract_system)
  .add_post_update_system(render_prepare_system)
  .add_post_update_system(render_queue_system)
  .add_post_update_system(render_execute_system)
}
