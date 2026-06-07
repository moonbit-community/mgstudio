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
/// Minimal ECS end-to-end example with Position/Velocity and a move system.

///|
pub struct Position {
  mut x : Float
  mut y : Float
} derive(Debug, Eq)

///|
pub struct Velocity {
  x : Float
  y : Float
} derive(Debug, Eq)

///|
let comp_position : @ecs.ComponentKey[Position] = @ecs.register_component(
  debug_name="examples.ecs_json_move.position",
)

///|
let comp_velocity : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.ecs_json_move.velocity",
)

///|
pub impl @ecs.Component for Position with fn component() {
  comp_position
}

///|
pub impl @ecs.Component for Velocity with fn component() {
  comp_velocity
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_systems(
    @app.Startup,
    @app.system_config_world(fn(world) {
      let entity = world.spawn()
      try! world.set_by_key(entity, comp_position, Position::{ x: 0.0, y: 0.0 })
      try! world.set_by_key(entity, comp_velocity, Velocity::{ x: 1.0, y: 0.5 })
    }),
  )
  .add_systems_param(@app.Update, move_system)
  .update()
  |> ignore
}

///|
fn move_system(
  query : @ecs.Query[(@ecs.Write[Position], @ecs.Read[Velocity]), @ecs.All],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (position, velocity) = data
    let delta = velocity.value()
    position.modify(fn(value) {
      value.x = value.x + delta.x
      value.y = value.y + delta.y
    })
  })
}
