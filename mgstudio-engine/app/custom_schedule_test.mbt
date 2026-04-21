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
test "app: custom schedules can be inserted into main schedule order" {
  let log : Array[String] = []
  let single_threaded_update = schedule_label("SingleThreadedUpdate")
  let custom_startup = schedule_label("CustomStartup")

  let startup_schedule = Schedule::new(custom_startup)
  let update_schedule = Schedule::new(single_threaded_update).set_executor_kind(
    SingleThreaded,
  )
  let mut app = App::new(@ecs.World::new())
    .add_schedule(update_schedule)
    .add_schedule(startup_schedule)

  let order = world_main_schedule_order(app.world())
    .insert_after(Update, single_threaded_update)
    .insert_startup_after(PreStartup, custom_startup)
  app.world().insert_resource(main_schedule_order_resource_key(), order)

  app = app
    .add_systems(
      PreStartup,
      system(fn(_world : @ecs.World) { log.push("Pre Startup") }),
    )
    .add_systems(
      custom_startup,
      system(fn(_world : @ecs.World) { log.push("Custom Startup") }),
    )
    .add_systems(
      Startup,
      system(fn(_world : @ecs.World) { log.push("Startup") }),
    )
    .add_systems(First, system(fn(_world : @ecs.World) { log.push("First") }))
    .add_systems(Update, system(fn(_world : @ecs.World) { log.push("Update") }))
    .add_systems(
      single_threaded_update,
      system(fn(_world : @ecs.World) { log.push("Single Threaded Update") }),
    )
    .add_systems(Last, system(fn(_world : @ecs.World) { log.push("Last") }))

  app.run_once() |> ignore

  debug_inspect(
    log.join(","),
    content="\"Pre Startup,Custom Startup,Startup,First,Update,Single Threaded Update,Last\"",
  )
}

///|
test "app: schedule surface keeps configured executor kind" {
  let schedule = Schedule::new(schedule_label("SingleThreadedUpdate")).set_executor_kind(
    SingleThreaded,
  )

  debug_inspect(schedule.get_executor_kind(), content="SingleThreaded")
}

///|
struct ScheduleBatchMarker {} derive(Eq, Debug)

///|
let schedule_batch_marker_key : @ecs.ComponentKey[ScheduleBatchMarker] = @ecs.register_component(
  debug_name="tests.app.schedule.batch.marker",
)

///|
pub impl @ecs.Component for ScheduleBatchMarker with component() {
  schedule_batch_marker_key
}

///|
test "app: multithreaded schedules defer Commands until the compatible batch ends" {
  let stage = schedule_label("DeferredBatchingUpdate")
  let observed : Array[Int] = []
  let mut sub_app = SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(MultiThreaded))
    .add_systems(stage, system_config_param(fn(commands : Commands) {
      ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
    }))
    .add_systems(stage, system_config_param(fn(
      query : @ecs.Query[@ecs.Comp[ScheduleBatchMarker], @ecs.All],
    ) {
      observed.push(query.count())
    }))

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Comp[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: single-threaded schedules apply Commands after each system" {
  let stage = schedule_label("ImmediateBatchingUpdate")
  let observed : Array[Int] = []
  let mut sub_app = SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(stage, system_config_param(fn(commands : Commands) {
      ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
    }))
    .add_systems(stage, system_config_param(fn(
      query : @ecs.Query[@ecs.Comp[ScheduleBatchMarker], @ecs.All],
    ) {
      observed.push(query.count())
    }))

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Comp[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}
