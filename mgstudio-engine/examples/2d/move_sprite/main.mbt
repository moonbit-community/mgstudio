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
const SPEED : Float = 150.0F

///|
const EDGE_LIMIT : Float = 200.0F

///|
priv struct MoveSpriteState {
  mut sprite : @core.Entity
  mut direction : Direction
}

///|
let move_state : Ref[MoveSpriteState] = Ref::new(MoveSpriteState::{
  sprite: @core.Entity::placeholder(),
  direction: Direction::Right,
})

///|
fn entity_is_same(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn move_sprite_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::from_image(texture)
  let transform = @math.Transform::identity()
  let sprite_entity = @render2d.SpriteBundle::new(sprite, transform).spawn(
    world,
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  move_state.val.sprite = sprite_entity
  move_state.val.direction = Direction::Right
}

///|
fn move_sprite_movement(world : @ecs_world.World) -> Unit {
  if move_state.val.sprite.is_placeholder() {
    return
  }
  let sprite_entity = move_state.val.sprite
  let delta = SPEED * @time.time_delta_seconds()
  let move_x = if move_state.val.direction is Right { delta } else { -delta }
  let tick = world.read_change_tick()
  let sprite_store = world.get_sprite_store()
  let transform_store = world.get_transform_store()
  let mut next_direction = move_state.val.direction
  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {
    if !entity_is_same(entity, sprite_entity) {
      return
    }
    let translation = @math.Vec2::new(
      transform.translation.x + move_x,
      transform.translation.y,
    )
    let next_transform = @math.Transform::from_xy_rotation_scale(
      translation,
      transform.rotation_z(),
      @math.Vec2::new(transform.scale.x, transform.scale.y),
      z=transform.translation.z,
    )
    transform_store.set(sprite_entity, next_transform, tick) |> ignore
    if translation.x > EDGE_LIMIT {
      next_direction = Direction::Left
    } else if translation.x < -EDGE_LIMIT {
      next_direction = Direction::Right
    }
  })
  move_state.val.direction = next_direction
}
