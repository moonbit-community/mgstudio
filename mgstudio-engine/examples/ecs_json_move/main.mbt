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
  mut x : Float
  mut y : Float
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Velocity {
  x : Float
  y : Float
} derive(Show, Eq, ToJson, FromJson)

///|
fn main {
  let comp_position : @ecs.ComponentKey[Position] = @ecs.register_component(
    debug_name="examples.ecs_json_move.position",
  )
  let comp_velocity : @ecs.ComponentKey[Velocity] = @ecs.register_component(
    debug_name="examples.ecs_json_move.velocity",
  )

  @app.App::new(@ecs.World::new())
  .add_startup_system(fn(world) {
    let entity = world.spawn()
    try! world.set(entity, comp_position, Position::{ x: 0.0, y: 0.0 })
    try! world.set(entity, comp_velocity, Velocity::{ x: 1.0, y: 0.5 })
  })
  .add_system_query2_ecs(comp_position, comp_velocity, move_system)
  .update()
  |> ignore
}

///|
fn move_system(
  query : @ecs.Query2[Position, Velocity],
  _world : @ecs.World,
) -> Unit {
  try! query.for_each(fn(_entity, position, velocity) {
    position.x = position.x + velocity.x
    position.y = position.y + velocity.y
  })
}
