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
/// Minimal Json-backed ECS end-to-end example with Position/Velocity and a move system.

///|
pub struct Position {
  x : Float
  y : Float
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Velocity {
  x : Float
  y : Float
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct MovementKeys {
  comp_position_id : Int
  comp_velocity_id : Int
} derive(Show, Eq, ToJson, FromJson)

///|
let res_movement_keys : @ecs.ResourceKey[MovementKeys] = @ecs.register_resource(
  debug_name="examples.ecs_json_move.keys",
)

///|
pub fn game_app() -> Unit {
  let comp_position : @ecs.ComponentKey[Position] = @ecs.register_component(
    debug_name="examples.ecs_json_move.position",
  )
  let comp_velocity : @ecs.ComponentKey[Velocity] = @ecs.register_component(
    debug_name="examples.ecs_json_move.velocity",
  )

  @app.App::new(@ecs.World::new())
  .add_startup_system(fn(world) {
    world.insert_resource(res_movement_keys, MovementKeys::{
      comp_position_id: comp_position.id(),
      comp_velocity_id: comp_velocity.id(),
    })
    let entity = world.spawn()
    try! world.set(entity, comp_position, Position::{ x: 0.0, y: 0.0 })
    try! world.set(entity, comp_velocity, Velocity::{ x: 1.0, y: 0.5 })
  })
  .add_system(move_system)
  .run_startup()
  .run_once()
  |> ignore
}

///|
fn move_system(world : @ecs.World) -> Unit {
  let movement_keys = try! world.get_resource(res_movement_keys)
  guard movement_keys is Some(keys) else { return }

  let comp_position : @ecs.ComponentKey[Position] = @ecs.component_key_from_id(
    keys.comp_position_id,
    debug_name="examples.ecs_json_move.position",
  )
  let comp_velocity : @ecs.ComponentKey[Velocity] = @ecs.component_key_from_id(
    keys.comp_velocity_id,
    debug_name="examples.ecs_json_move.velocity",
  )

  try! world
  .query2(comp_position, comp_velocity)
  .update(fn(_entity, position, velocity) {
    (
      Position::{ x: position.x + velocity.x, y: position.y + velocity.y },
      velocity,
    )
  })
}
