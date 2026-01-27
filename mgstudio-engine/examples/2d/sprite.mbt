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

///|
pub fn sprite_run() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_setup)
  .run()
}

///|
fn sprite_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn(world) |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}
