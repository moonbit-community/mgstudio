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
pub fn viewport_to_world_2d_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(viewport_to_world_setup)
  .add_system(viewport_to_world_update)
  .run()
}

///|
priv struct ViewportToWorldState {
  mut sprite_transform : @math.Transform
  mut camera_transform : @math.Transform
}

///|
let viewport_state : Ref[ViewportToWorldState] = @ref.new(ViewportToWorldState::{
  sprite_transform: @math.Transform::identity(),
  camera_transform: @math.Transform::identity(),
})

///|
fn viewport_to_world_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let sprite_transform = @math.Transform::identity()
  let sprite_bundle = @render2d.SpriteBundle::new(
    sprite, sprite_transform, texture,
  )
  let camera = @render2d.Camera2d::new(@render2d.Color::white())
  let camera_transform = @math.Transform::identity()
  let camera_bundle = @render2d.Camera2dBundle::new(camera, camera_transform)
  viewport_state.val.sprite_transform = sprite_transform
  viewport_state.val.camera_transform = camera_transform
  @render2d.render2d_set_sprite_transform(sprite_transform)
  @render2d.render2d_set_camera_transform(camera_transform)
  sprite_bundle |> ignore
  camera_bundle |> ignore
}

///|
fn viewport_to_world_update() -> Unit {
  let delta = @time.time_delta_seconds()
  let speed = 400.0F * delta
  let camera_transform = viewport_state.val.camera_transform
  let mut x = camera_transform.translation.x
  let mut y = camera_transform.translation.y
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    y = y + speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    y = y - speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    x = x - speed
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    x = x + speed
  }
  if x != camera_transform.translation.x || y != camera_transform.translation.y {
    let next_camera = @math.Transform::new(
      @math.Vec2::new(x, y),
      camera_transform.rotation,
      camera_transform.scale,
    )
    viewport_state.val.camera_transform = next_camera
    @render2d.render2d_set_camera_transform(next_camera)
  }
  if @input.mouse_position() is Some(screen_pos) {
    if @render2d.render2d_viewport_to_world_2d(screen_pos) is Some(world_pos) {
      let sprite_transform = viewport_state.val.sprite_transform
      let next_sprite = @math.Transform::new(
        world_pos,
        sprite_transform.rotation,
        sprite_transform.scale,
      )
      viewport_state.val.sprite_transform = next_sprite
      @render2d.render2d_set_sprite_transform(next_sprite)
    }
  }
}
