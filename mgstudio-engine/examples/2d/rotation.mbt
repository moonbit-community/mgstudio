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
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(rotation_setup)
  .add_system(rotation_update)
  .run()
}

///|
priv struct RotationState {
  mut transform : @math.Transform
}

///|
let rotation_state : Ref[RotationState] = @ref.new(RotationState::{
  transform: @math.Transform::identity(),
})

///|
fn rotation_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn() |> ignore
  let camera = @render2d.Camera2d::new(@render2d.Color::white())
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  rotation_state.val.transform = transform
  @render2d.render2d_set_sprite_transform(transform)
  @render2d.render2d_set_camera_transform(@math.Transform::identity())
}

///|
fn rotation_update() -> Unit {
  let transform = rotation_state.val.transform
  let delta_secs = @time.time_delta_seconds()
  let speed = 1.0F
  let next_rotation = transform.rotation + speed * delta_secs
  let next_transform = @math.Transform::new(
    transform.translation,
    next_rotation,
    transform.scale,
  )
  rotation_state.val.transform = next_transform
  @render2d.render2d_set_sprite_transform(next_transform)
}
