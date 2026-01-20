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
pub fn rotation_run() -> Unit {
  let plugins : Array[@app.Plugin] = [@window.window_plugin]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(rotation_setup)
  .add_system(rotation_update)
  .run()
}

///|
fn rotation_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  let sprite_bundle = @render2d.SpriteBundle::new(sprite, transform, texture)
  let camera = @render2d.Camera2d::new(@render2d.Color::white())
  let camera_bundle = @render2d.Camera2dBundle::new(
    camera,
    @math.Transform::identity(),
  )
  sprite_bundle |> ignore
  camera_bundle |> ignore
}

///|
fn rotation_update() -> Unit {
  let transform = @math.Transform::identity()
  let delta_secs = 0.0F
  let speed = 1.0F
  let next_rotation = transform.rotation + speed * delta_secs
  let next_transform = @math.Transform::new(
    transform.translation,
    next_rotation,
    transform.scale,
  )
  next_transform |> ignore
}
