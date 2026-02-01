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
  .add_startup_system(rotate_to_cursor_setup)
  .add_system(rotate_to_cursor_update)
  .run()
}

///|
fn rotate_to_cursor_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/simplespace/ship_C.png")
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
fn rotate_to_cursor_update(world : @ecs_world.World) -> Unit {
  if @input.mouse_position() is Some(screen_pos) {
    if @render2d.render2d_viewport_to_world_2d(world, screen_pos)
      is Some(world_pos) {
      let tick = @core.ChangeTickWorld::read_change_tick(world)
      let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
      let transform_store = @math.Has_Transform::get_transform_store(world)
      let entities : Array[(@core.Entity, @math.Transform)] = []
      @core.query2(transform_store, sprite_store, fn(
        entity,
        transform,
        _sprite,
      ) {
        entities.push((entity, transform))
      })
      for entry in entities {
        let transform = entry.1
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
        transform_store.set(entry.0, next_transform, tick) |> ignore
      }
    }
  }
}
