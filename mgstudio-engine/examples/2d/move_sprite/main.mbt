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
/// Port of `bevy/examples/2d/move_sprite.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(move_sprite_setup))
  .add_system_query2_ecs(
    @transform.ecs_key_transform, @sprite.ecs_key_sprite, move_sprite_movement,
  )
  .run()
}

///|
pub(all) enum Direction {
  Left
  Right
}

///|
const SPEED : Float = 150.0F

///|
const EDGE_LIMIT : Float = 200.0F

///|
priv struct MoveSpriteState {
  mut direction : Direction
}

///|
let move_state : Ref[MoveSpriteState] = Ref::new(MoveSpriteState::{
  direction: Direction::Right,
})

///|
fn move_sprite_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @sprite.Sprite::from_image(texture)
  let transform = @transform.Transform::identity()
  @sprite.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore
  move_state.val.direction = Direction::Right
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in move_sprite example")
  }
}

///|
fn move_sprite_movement(
  query : @ecs.Query2[@transform.Transform, @sprite.Sprite],
  world : @ecs.World,
) -> Unit {
  let delta = SPEED * world_time(world).delta_seconds()
  let move_x = if move_state.val.direction is Right { delta } else { -delta }
  let mut next_direction = move_state.val.direction
  try! query.for_each(fn(_entity, transform, _sprite) {
    let next_x = transform.translation.x + move_x
    if next_x > EDGE_LIMIT {
      next_direction = Direction::Left
    } else if next_x < -EDGE_LIMIT {
      next_direction = Direction::Right
    }
    transform.translation.x = next_x
  })
  move_state.val.direction = next_direction
}
