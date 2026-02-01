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
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_scale_setup)
  .add_system(sprite_scale_update)
  .run()
}

///|
fn sprite_scale_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn(world) |> ignore
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn sprite_scale_update(world : @ecs_world.World) -> Unit {
  let t = @time.time_elapsed_seconds()
  let pulse = 1.0F + @math.sin(t) * 0.5F
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {
    entities.push((entity, transform))
  })
  for entry in entities {
    let transform = entry.1
    let next_transform = @math.Transform::new(
      transform.translation,
      transform.rotation,
      @math.Vec2::new(pulse, pulse),
    )
    transform_store.set(entry.0, next_transform, tick) |> ignore
  }
}
