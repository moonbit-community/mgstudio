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
pub fn rotate_to_cursor_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(rotate_to_cursor_setup)
  .add_system(rotate_to_cursor_update)
  .run()
}

///|
priv struct RotateToCursorState {
  mut transform : @math.Transform
}

///|
let rotate_state : Ref[RotateToCursorState] = Ref::new(RotateToCursorState::{
  transform: @math.Transform::identity(),
})

///|
fn rotate_to_cursor_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/simplespace/ship_C.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn() |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  rotate_state.val.transform = transform
  @render2d.render2d_set_sprite_transform(transform)
  @render2d.render2d_set_camera_transform(@math.Transform::identity())
}

///|
fn rotate_to_cursor_update() -> Unit {
  if @input.mouse_position() is Some(screen_pos) {
    if @render2d.render2d_viewport_to_world_2d(screen_pos) is Some(world_pos) {
      let transform = rotate_state.val.transform
      let delta = @math.Vec2::new(
        world_pos.x - transform.translation.x,
        world_pos.y - transform.translation.y,
      )
      let angle = delta.to_angle() - @math.pi_half()
      let next_transform = @math.Transform::new(
        transform.translation,
        angle,
        transform.scale,
      )
      rotate_state.val.transform = next_transform
      @render2d.render2d_set_sprite_transform(next_transform)
    }
  }
}
