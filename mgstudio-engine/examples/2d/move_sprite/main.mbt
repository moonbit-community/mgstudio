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
  .add_startup_system(move_sprite_setup)
  .add_system(move_sprite_movement)
  .run()
}

///|
pub(all) enum Direction {
  Left
  Right
}

///|
priv struct MoveSpriteState {
  mut direction : Direction
}

///|
let move_state : Ref[MoveSpriteState] = Ref::new(MoveSpriteState::{
  direction: Direction::Right,
})

///|
fn move_sprite_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  @render2d.SpriteBundle::new(sprite, transform, texture).spawn(world) |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  move_state.val.direction = Direction::Right
}

///|
fn move_sprite_movement(world : @ecs_world.World) -> Unit {
  let delta_secs = @time.time_delta_seconds()
  let speed = 150.0F
  let delta = speed * delta_secs
  let move_x = if move_state.val.direction is Right { delta } else { -delta }
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {
    entities.push((entity, transform))
  })
  for entry in entities {
    let transform = entry.1
    let translation = @math.Vec2::new(
      transform.translation.x + move_x,
      transform.translation.y,
    )
    let next_transform = @math.Transform::new(
      translation,
      transform.rotation,
      transform.scale,
    )
    transform_store.set(entry.0, next_transform, tick) |> ignore
    if translation.x > 200.0F {
      move_state.val.direction = Direction::Left
    } else if translation.x < -200.0F {
      move_state.val.direction = Direction::Right
    }
  }
}
