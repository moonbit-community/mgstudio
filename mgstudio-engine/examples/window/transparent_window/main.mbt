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
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.transparent = true
  window.decorations = false
  window
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: Some(@window.CursorOptions::CursorOptions()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .insert_resource(
    @camera_clear_color.ClearColor::new(
      @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    ),
  )
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)
  let asset_server = @asset.AssetServer::new()
  try! (world.spawn_bundle(
    (
      @sprite.Sprite::from_image(asset_server.load("branding/icon.png")),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)
}
