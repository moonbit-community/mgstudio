// Copyright 2026 International Digital Economy Academy
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
struct Position {
  mut x : Int
}

///|
struct Velocity {
  dx : Int
}

///|
let position_key : @ecs.ComponentKey[Position] = @ecs.register_component(
  debug_name="examples.ecs.custom_query_param.Position",
)

///|
let velocity_key : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.ecs.custom_query_param.Velocity",
)

///|
pub impl @ecs.Component for Position with component() {
  position_key
}

///|
pub impl @ecs.Component for Velocity with component() {
  velocity_key
}

///|
struct MovementParam[P] {
  query : P
  state : Ref[Json]
}

///|
type MovementQuery = @ecs.Query[
  (@ecs.Mut[Position], @ecs.Comp[Velocity]),
  @ecs.All,
]

///|
type MovementSystemParam = MovementParam[MovementQuery]

///|
impl[P : @app.SystemParam] @app.SystemParam for MovementParam[P] with init_state(
  world,
) {
  P::init_state(world)
}

///|
impl[P : @app.SystemParam] @app.SystemParam for MovementParam[P] with get(state) {
  let query_state = Ref::new(state.val)
  { query: P::get(query_state), state: query_state }
}

///|
impl[P : @app.SystemParam] @app.SystemParam for MovementParam[P] with store(
  self,
  state,
) {
  P::store(self.query, self.state)
  state.val = self.state.val
}

///|
fn MovementSystemParam::integrate(self : MovementSystemParam) -> Int {
  let moved : Ref[Int] = Ref::new(0)
  try! self.query.view(fn(_entity, data) {
    let (position, velocity) = data
    position.get_ref().val.x = position.get_ref().val.x + velocity.value().dx
    moved.val = moved.val + 1
  })
  moved.val
}

///|
fn spawn(commands : @app.Commands) -> Unit {
  commands.spawn((Position::{ x: 0 }, Velocity::{ dx: 1 })) |> ignore
  commands.spawn((Position::{ x: 10 }, Velocity::{ dx: -2 })) |> ignore
}

///|
fn run_custom_query_param(param : MovementSystemParam) -> Unit {
  let moved = param.integrate()
  println("Updated entities: " + moved.to_string())
}

///|
fn print_positions(query : @ecs.Query[@ecs.Comp[Position], @ecs.All]) -> Unit {
  try! query.view(fn(_entity, position) {
    println("Position: " + position.value().x.to_string())
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins([
    @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_once()),
  ])
  .add_systems(@app.Startup, @app.system(@app.system_param(spawn)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(run_custom_query_param)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param(print_positions)))
  .run()
}
