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
priv struct CounterState {
  mut count : Int
}

///|
let counter_state_resource_key : @ecs.ResourceKey[CounterState] = @ecs.register_resource(
  debug_name="examples.app.headless.CounterState",
)

///|
impl @app.Resource for CounterState with resource() {
  counter_state_resource_key
}

///|
fn hello_world_system(_world : @ecs.World) -> Unit {
  println("hello world")
}

///|
fn counter_system(state : @app.ResMut[CounterState]) -> Unit {
  let count = state.peek().count
  if count % 60 == 0 {
    println(count.to_string())
  }
  state.modify(fn(value) { value.count = value.count + 1 })
}

///|
fn run_once_app() -> Unit {
  @app.App::new(@ecs.World::new())
  .add_plugins(@app.ScheduleRunnerPlugin::run_once())
  .add_systems(@app.Update, @app.system(hello_world_system))
  .run()
}

///|
fn run_loop_app() -> Unit {
  @app.App::new(@ecs.World::new())
  .add_plugins(@app.ScheduleRunnerPlugin::run_loop(1.0F / 60.0F))
  .insert_resource(CounterState::{ count: 0 })
  .add_systems(@app.Update, @app.system(@app.system_param(counter_system)))
  .run()
}

///|
fn main {
  run_once_app()
  run_loop_app()
}
