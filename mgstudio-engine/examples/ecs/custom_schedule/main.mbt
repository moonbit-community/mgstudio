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
/// Port of `bevy/examples/ecs/custom_schedule.rs`.

///|
let single_threaded_update : @app.ScheduleStage = @app.schedule_label(
  "SingleThreadedUpdate",
)

///|
let custom_startup : @app.ScheduleStage = @app.schedule_label("CustomStartup")

///|
fn pre_startup_system(_world : @ecs.World) -> Unit {
  println("Pre Startup")
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  println("Startup")
}

///|
fn custom_startup_system(_world : @ecs.World) -> Unit {
  println("Custom Startup")
}

///|
fn first_system(_world : @ecs.World) -> Unit {
  println("First")
}

///|
fn update_system(_world : @ecs.World) -> Unit {
  println("Update")
}

///|
fn single_threaded_update_system(_world : @ecs.World) -> Unit {
  println("Single Threaded Update")
}

///|
fn last_system(_world : @ecs.World) -> Unit {
  println("Last")
}

///|
fn main {
  let mut custom_update_schedule = @app.Schedule::new(single_threaded_update)
  custom_update_schedule = custom_update_schedule.set_executor_kind(
    @app.SingleThreaded,
  )

  let app = @app.App::new(@ecs.World::new())
    .add_schedule(custom_update_schedule)
    .add_schedule(@app.Schedule::new(custom_startup))

  let order = @app.world_main_schedule_order(app.world())
    .insert_after(@app.Update, single_threaded_update)
    .insert_startup_after(@app.PreStartup, custom_startup)
  app.world().insert_resource(@app.main_schedule_order_resource_key(), order)

  app
  .add_systems(@app.PreStartup, @app.system(pre_startup_system))
  .add_systems(custom_startup, @app.system(custom_startup_system))
  .add_systems(@app.Startup, @app.system(startup_system))
  .add_systems(@app.First, @app.system(first_system))
  .add_systems(@app.Update, @app.system(update_system))
  .add_systems(
    single_threaded_update,
    @app.system(single_threaded_update_system),
  )
  .add_systems(@app.Last, @app.system(last_system))
  .run()
}
