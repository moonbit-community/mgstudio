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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(transparency_2d_setup)
  .run()
}

///|
fn spawn_logo_sprite(
  world : @ecs.World,
  image : @asset.Handle[@asset.Image],
  position : @math.Vec2,
  color : @render2d.Color,
  z : Float,
) -> Unit {
  let sprite = @render2d.Sprite::from_image(image).with_color(color)
  let transform = @math.Transform::from_xyz(position.x, position.y, z)
  @render2d.SpriteBundle::new(sprite, transform).spawn_ecs(world) |> ignore
}

///|
fn transparency_2d_setup(world : @ecs.World) -> Unit {
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn_ecs(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let icon = asset_server.load("branding/icon.png")

  spawn_logo_sprite(
    world,
    icon,
    @math.Vec2::new(-100.0F, 0.0F),
    @render2d.Color::white(),
    0.0F,
  )
  spawn_logo_sprite(
    world,
    icon,
    @math.Vec2::new(0.0F, 0.0F),
    @render2d.Color::new(0.0F, 0.0F, 1.0F, 0.7F),
    0.1F,
  )
  spawn_logo_sprite(
    world,
    icon,
    @math.Vec2::new(100.0F, 0.0F),
    @render2d.Color::new(0.0F, 1.0F, 0.0F, 0.3F),
    0.2F,
  )
}
