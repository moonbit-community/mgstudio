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
pub fn move_sprite_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(move_sprite_setup)
  .add_system(move_sprite_movement)
  .run()
}

///|
pub(all) enum Direction {
  Left
  Right
}

///|
priv struct MoveSpriteState {
  mut direction : Direction
  mut transform : @math.Transform
}

///|
let move_state : Ref[MoveSpriteState] = @ref.new(MoveSpriteState::{
  direction: Direction::Right,
  transform: @math.Transform::identity(),
})

///|
fn move_sprite_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn() |> ignore
  let camera = @render2d.Camera2d::new(
    @render2d.Color::new(0.5F, 0.5F, 0.5F, 1.0F),
  )
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  move_state.val.direction = Direction::Right
  move_state.val.transform = transform
  @render2d.render2d_set_sprite_transform(transform)
  @render2d.render2d_set_camera_transform(@math.Transform::identity())
}

///|
fn move_sprite_movement() -> Unit {
  let transform = move_state.val.transform
  let delta_secs = @time.time_delta_seconds()
  let speed = 150.0F
  let delta = speed * delta_secs
  let move_x = if move_state.val.direction is Right { delta } else { -delta }
  let translation = @math.Vec2::new(
    transform.translation.x + move_x,
    transform.translation.y,
  )
  let next_transform = @math.Transform::new(
    translation,
    transform.rotation,
    transform.scale,
  )
  move_state.val.transform = next_transform
  @render2d.render2d_set_sprite_transform(next_transform)
  if translation.x > 200.0F {
    move_state.val.direction = Direction::Left
  } else if translation.x < -200.0F {
    move_state.val.direction = Direction::Right
  }
}
