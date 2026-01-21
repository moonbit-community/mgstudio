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
pub fn sprite_flipping_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @asset.asset_plugin, @render2d.render2d_plugin, @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(sprite_flipping_setup)
  .run()
}

///|
fn sprite_flipping_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::new(
    @math.Vec2::new(0.0F, 0.0F),
    0.0F,
    @math.Vec2::new(-1.0F, 1.0F),
  )
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn() |> ignore
  let camera = @render2d.Camera2d::new(
    @render2d.Color::new(0.5F, 0.5F, 0.5F, 1.0F),
  )
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  @render2d.render2d_set_sprite_transform(transform)
  @render2d.render2d_set_camera_transform(@math.Transform::identity())
}
