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
  let plugins : Array[@app.Plugin] = [@window.window_plugin]
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
fn move_sprite_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  let direction = Direction::Right
  texture |> ignore
  sprite |> ignore
  transform |> ignore
  direction |> ignore
}

///|
fn move_sprite_movement() -> Unit {
  let direction = Direction::Right
  let transform = @math.Transform::identity()
  let delta_secs = 0.0F
  let speed = 150.0F
  let delta = speed * delta_secs
  let move_x = if direction is Right { delta } else { -delta }
  let translation = @math.Vec2::new(
    transform.translation.x + move_x,
    transform.translation.y,
  )
  let next_transform = @math.Transform::new(
    translation,
    transform.rotation,
    transform.scale,
  )
  next_transform |> ignore
}
