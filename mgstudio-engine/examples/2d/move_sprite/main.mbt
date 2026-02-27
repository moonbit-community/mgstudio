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
priv struct MoveSpriteState {
  mut directions : Array[(@core.Entity, Direction)]
}

///|
let move_state : Ref[MoveSpriteState] = Ref::new(MoveSpriteState::{
  directions: [],
})

///|
fn entity_is_same(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn direction_get(entity : @core.Entity) -> Direction {
  for entry in move_state.val.directions {
    if entity_is_same(entry.0, entity) {
      return entry.1
    }
  }
  Direction::Right
}

///|
fn direction_set(entity : @core.Entity, direction : Direction) -> Unit {
  let mut updated = false
  let next : Array[(@core.Entity, Direction)] = []
  for entry in move_state.val.directions {
    if entity_is_same(entry.0, entity) {
      next.push((entity, direction))
      updated = true
    } else {
      next.push(entry)
    }
  }
  if !updated {
    next.push((entity, direction))
  }
  move_state.val.directions = next
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
  move_state.val.directions = []
  direction_set(sprite_entity, Direction::Right)
}

///|
fn move_sprite_movement(world : @ecs_world.World) -> Unit {
  let delta_secs = @time.time_delta_seconds()
  let speed = 150.0F
  let tick = world.read_change_tick()
  let sprite_store = world.get_sprite_store()
  let transform_store = world.get_transform_store()
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {
    entities.push((entity, transform))
  })
  for entry in entities {
    let entity = entry.0
    let direction = direction_get(entity)
    let delta = speed * delta_secs
    let move_x = if direction is Right { delta } else { -delta }
    let transform = entry.1
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
    transform_store.set(entity, next_transform, tick) |> ignore
    if translation.x > 200.0F {
      direction_set(entity, Direction::Left)
    } else if translation.x < -200.0F {
      direction_set(entity, Direction::Right)
    }
  }
}
