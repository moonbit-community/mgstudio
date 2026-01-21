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
pub fn sprite_scale_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(sprite_scale_setup)
  .add_system(sprite_scale_update)
  .run()
}

///|
priv struct SpriteScaleState {
  mut transform : @math.Transform
}

///|
let scale_state : Ref[SpriteScaleState] = @ref.new(SpriteScaleState::{
  transform: @math.Transform::identity(),
})

///|
fn sprite_scale_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn() |> ignore
  let camera = @render2d.Camera2d::new(@render2d.Color::white())
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  scale_state.val.transform = transform
  @render2d.render2d_set_sprite_transform(transform)
  @render2d.render2d_set_camera_transform(@math.Transform::identity())
}

///|
fn sprite_scale_update() -> Unit {
  let t = @time.time_elapsed_seconds()
  let pulse = 1.0F + @math.sin(t) * 0.5F
  let transform = scale_state.val.transform
  let next_transform = @math.Transform::new(
    transform.translation,
    transform.rotation,
    @math.Vec2::new(pulse, pulse),
  )
  scale_state.val.transform = next_transform
  @render2d.render2d_set_sprite_transform(next_transform)
}
