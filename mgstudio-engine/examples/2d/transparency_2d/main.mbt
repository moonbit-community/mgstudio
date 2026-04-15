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
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}

///|
fn spawn_logo_sprite(
  commands : @app.Commands,
  image : @asset.Handle[@asset.Image],
  position : @math.Vec2,
  color : @sprite.Color,
  z : Float,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(image).with_color(color),
        @transform.Transform::from_xyz(position.x, position.y, z),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let icon = asset_server.get().load("branding/icon.png")

  spawn_logo_sprite(
    commands,
    icon,
    @math.Vec2::new(-100.0F, 0.0F),
    @sprite.Color::white(),
    0.0F,
  )
  spawn_logo_sprite(
    commands,
    icon,
    @math.Vec2::new(0.0F, 0.0F),
    @sprite.Color::new(0.0F, 0.0F, 1.0F, 0.7F),
    0.1F,
  )
  spawn_logo_sprite(
    commands,
    icon,
    @math.Vec2::new(100.0F, 0.0F),
    @sprite.Color::new(0.0F, 1.0F, 0.0F, 0.3F),
    0.2F,
  )
}
