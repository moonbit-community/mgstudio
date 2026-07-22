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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  let sprite_handle = asset_server.get().load("branding/icon.png")

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(sprite_handle),
        @transform.Transform::from_xyz(-100.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(sprite_handle).with_color(
          @color.Color::srgba(0.0F, 0.0F, 1.0F, 0.7F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.1F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(sprite_handle).with_color(
          @color.Color::srgba(0.0F, 1.0F, 0.0F, 0.3F),
        ),
        @transform.Transform::from_xyz(100.0F, 0.0F, 0.2F),
      ),
    ),
  )
}
