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
/// Port of `bevy/examples/app/headless.rs`.

///|
priv struct CounterState {
  mut count : Int
}

///|
let counter_state_resource_ref : Ref[@core.Resource[CounterState]] = Ref::new(
  @core.Resource::new(),
)

///|
impl @app.Resource for CounterState with resource() {
  counter_state_resource_ref.val
}

///|
fn hello_world_system(_world : @ecs.World) -> Unit {
  println("hello world")
}

///|
fn counter_system(state : @app.ResMut[CounterState]) -> Unit {
  let state_ref = state.get_ref()
  if state_ref.val.count % 60 == 0 {
    println(state_ref.val.count.to_string())
  }
  state_ref.val.count = state_ref.val.count + 1
}

///|
fn run_once_app() -> Unit {
  @app.App::new(@ecs.World::new())
  .add_plugins([
    @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_once()),
  ])
  .add_system(hello_world_system)
  .run()
}

///|
fn run_loop_app() -> Unit {
  @app.App::new(@ecs.World::new())
  .add_plugins([
    @app.schedule_runner_plugin(
      @app.ScheduleRunnerPlugin::run_loop(1.0F / 60.0F),
    ),
  ])
  .insert_resource(CounterState::{ count: 0 })
  .add_system_param(counter_system)
  .run()
}

///|
pub fn game_app() -> Unit {
  run_once_app()
  run_loop_app()
}
