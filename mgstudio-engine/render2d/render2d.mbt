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
}

///|
pub fn Camera2d::new(clear_color : Color) -> Camera2d {
  Camera2d::{ clear_color, }
}

///|
pub struct SpriteBundle {
  sprite : Sprite
  transform : @math.Transform
  texture : @asset.Handle[@asset.Image]
}

///|
pub fn SpriteBundle::new(
  sprite : Sprite,
  transform : @math.Transform,
  texture : @asset.Handle[@asset.Image],
) -> SpriteBundle {
  SpriteBundle::{ sprite, transform, texture }
}

///|
pub struct Camera2dBundle {
  camera : Camera2d
  transform : @math.Transform
}

///|
pub fn Camera2dBundle::new(
  camera : Camera2d,
  transform : @math.Transform,
) -> Camera2dBundle {
  Camera2dBundle::{ camera, transform }
}

///|
priv struct RenderState {
  mut draw_enabled : Bool
  mut sprite_transform : @math.Transform
  mut camera_transform : @math.Transform
}

///|
let render_state : Ref[RenderState] = @ref.new(RenderState::{
  draw_enabled: false,
  sprite_transform: @math.Transform::identity(),
  camera_transform: @math.Transform::identity(),
})

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
  let transform = render_state.val.sprite_transform
  @window.host_gpu_set_sprite_transform(
    transform.translation.x,
    transform.translation.y,
    transform.rotation,
    transform.scale.x,
    transform.scale.y,
  )
  let camera = render_state.val.camera_transform
  @window.host_gpu_set_camera_transform(
    camera.translation.x,
    camera.translation.y,
    camera.rotation,
  )
  @window.host_gpu_set_draw_enabled(render_state.val.draw_enabled)
  render_state.val.draw_enabled = false
}

///|
pub fn render2d_set_sprite_transform(transform : @math.Transform) -> Unit {
  render_state.val.sprite_transform = transform
}

///|
pub fn render2d_set_camera_transform(transform : @math.Transform) -> Unit {
  render_state.val.camera_transform = transform
}

///|
pub fn render2d_viewport_to_world_2d(screen : @math.Vec2) -> @math.Vec2? {
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return None
  }
  let half_width = Float::from_double(width.to_double()) / 2.0F
  let half_height = Float::from_double(height.to_double()) / 2.0F
  let view_x = screen.x - half_width
  let view_y = half_height - screen.y
  let camera = render_state.val.camera_transform
  let cosv = @math.cos(camera.rotation)
  let sinv = @math.sin(camera.rotation)
  let world_x = camera.translation.x + view_x * cosv + view_y * sinv
  let world_y = camera.translation.y - view_x * sinv + view_y * cosv
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
