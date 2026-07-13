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
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let mut app = App::new(lifecycle_world_15_0)
    .add_schedule(update_schedule)
    .add_schedule(startup_schedule)

  let order = world_main_schedule_order(app.world())
    .insert_after(Update, single_threaded_update)
    .insert_startup_after(PreStartup, custom_startup)
  app.world().insert_resource(main_schedule_order_resource_key, order)

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
  let build_settings = ScheduleBuildSettings::new().set_auto_insert_apply_deferred(
    false,
  )
  let schedule = Schedule::new(schedule_label("SingleThreadedUpdate"))
    .set_executor_kind(SingleThreaded)
    .set_apply_final_deferred(false)
    .set_build_settings(build_settings)

  debug_inspect(schedule.get_executor_kind(), content="SingleThreaded")
  debug_inspect(
    schedule.get_build_settings().auto_insert_apply_deferred(),
    content="false",
  )
  debug_inspect(schedule.get_apply_final_deferred(), content="false")
}

///|
test "app: main/fixed main/run fixed loop default to single threaded executors" {
  let lifecycle_world_81_0 = @ecs.World::new()
  defer lifecycle_world_81_0.close()
  let sub_app = SubApp::new(lifecycle_world_81_0)
  debug_inspect(
    sub_app.get_schedule_executor_kind(Main),
    content="SingleThreaded",
  )
  debug_inspect(
    sub_app.get_schedule_executor_kind(FixedMain),
    content="SingleThreaded",
  )
  debug_inspect(
    sub_app.get_schedule_executor_kind(RunFixedMainLoop),
    content="SingleThreaded",
  )
}

///|
struct ScheduleBatchMarker {} derive(Eq, Debug)

///|
struct MissingRunIfParityResource {} derive(Eq, Debug)

///|
let schedule_batch_marker_key : @ecs.ComponentKey[ScheduleBatchMarker] = @ecs.register_component(
  debug_name="tests.app.schedule.batch.marker",
)

///|
pub impl @ecs.Component for ScheduleBatchMarker with fn component() {
  schedule_batch_marker_key
}

///|
let missing_run_if_parity_resource_key : @ecs.ResourceKey[
  MissingRunIfParityResource,
] = @ecs.register_resource(
  debug_name="tests.app.schedule.missing_run_if_parity",
)

///|
pub impl Resource for MissingRunIfParityResource with fn resource() {
  missing_run_if_parity_resource_key
}

///|
test "app: multithreaded schedules defer Commands until the compatible batch ends" {
  let stage = schedule_label("DeferredBatchingUpdate")
  let observed : Array[Int] = []
  let lifecycle_world_126_0 = @ecs.World::new()
  defer lifecycle_world_126_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_126_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(MultiThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }),
    )

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: single-threaded schedules do not auto-apply Commands without deferred dependencies" {
  let stage = schedule_label("ImmediateBatchingUpdate")
  let observed : Array[Int] = []
  let lifecycle_world_158_0 = @ecs.World::new()
  defer lifecycle_world_158_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_158_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }),
    )

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: auto_insert_apply_deferred inserts apply boundary for chained deferred dependency" {
  let stage = schedule_label("AutoApplyDeferredUpdate")
  let observed : Array[Int] = []
  let deferred_system : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  })
  let read_system : SystemConfig[@ecs.World] = system_config_param(fn(
    query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    observed.push(query.count())
  })
  let lifecycle_world_190_0 = @ecs.World::new()
  defer lifecycle_world_190_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_190_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(stage, chain((deferred_system, read_system)))

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: disabling auto_insert_apply_deferred removes automatic apply boundaries" {
  let stage = schedule_label("DisableAutoApplyDeferredUpdate")
  let observed : Array[Int] = []
  let build_settings = ScheduleBuildSettings::new().set_auto_insert_apply_deferred(
    false,
  )
  let deferred_system : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  })
  let read_system : SystemConfig[@ecs.World] = system_config_param(fn(
    query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    observed.push(query.count())
  })
  let lifecycle_world_219_0 = @ecs.World::new()
  defer lifecycle_world_219_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_219_0)
    .set_update_schedule(Some(stage))
    .add_schedule(
      Schedule::new(stage)
      .set_executor_kind(SingleThreaded)
      .set_build_settings(build_settings),
    )
    .add_systems(stage, chain((deferred_system, read_system)))

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: chain_ignore_deferred keeps chained deferred systems in one buffer epoch" {
  let stage = schedule_label("ChainIgnoreDeferredUpdate")
  let observed : Array[Int] = []
  let deferred_system : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  })
  let read_system : SystemConfig[@ecs.World] = system_config_param(fn(
    query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    observed.push(query.count())
  })
  let lifecycle_world_255_0 = @ecs.World::new()
  defer lifecycle_world_255_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_255_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      chain((deferred_system, read_system)).chain_ignore_deferred(),
    )

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: explicit apply_deferred_system syncs commands when auto insertion is disabled" {
  let stage = schedule_label("ExplicitApplyDeferredUpdate")
  let observed : Array[Int] = []
  let build_settings = ScheduleBuildSettings::new().set_auto_insert_apply_deferred(
    false,
  )
  let deferred_system : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  })
  let read_system : SystemConfig[@ecs.World] = system_config_param(fn(
    query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    observed.push(query.count())
  })
  let lifecycle_world_287_0 = @ecs.World::new()
  defer lifecycle_world_287_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_287_0)
    .set_update_schedule(Some(stage))
    .add_schedule(
      Schedule::new(stage)
      .set_executor_kind(SingleThreaded)
      .set_build_settings(build_settings),
    )
    .add_systems(
      stage,
      chain((deferred_system, apply_deferred_system(), read_system)),
    )

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: deferred command batches are scoped to the executing world" {
  let outer_stage = schedule_label("DeferredBatchOuterWorld")
  let inner_stage = schedule_label("DeferredBatchInnerWorld")
  let lifecycle_world_326_0 = @ecs.World::new()
  defer lifecycle_world_326_0.close()
  let nested_ref : Ref[SubApp[@ecs.World]] = Ref(
    SubApp::new(lifecycle_world_326_0)
    .set_update_schedule(Some(inner_stage))
    .add_schedule(Schedule::new(inner_stage).set_executor_kind(SingleThreaded))
    .add_systems(inner_stage, system(fn(_world : @ecs.World) { () })),
  )
  let lifecycle_world_326_1 = @ecs.World::new()
  defer lifecycle_world_326_1.close()
  let mut outer_app = SubApp::new(lifecycle_world_326_1)
    .set_update_schedule(Some(outer_stage))
    .add_schedule(Schedule::new(outer_stage).set_executor_kind(SingleThreaded))
    .add_systems(
      outer_stage,
      system(fn(_world : @ecs.World) {
        queue_deferred_world_action(
          fn(world) {
            let entity = world.spawn_empty()
            world.set_by_key(entity, schedule_batch_marker_key, ScheduleBatchMarker::{

            }) catch {
              _ => abort("failed to insert deferred schedule batch marker")
            }
          },
          source="test::deferred_command_batches_are_world_scoped",
        )
        nested_ref.val = nested_ref.val.update()
      }),
    )

  outer_app = outer_app.update()

  let outer_query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    outer_app.world(),
  )
  let inner_query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    nested_ref.val.world(),
  )
  debug_inspect(outer_query.count(), content="1")
  debug_inspect(inner_query.count(), content="0")
}

///|
test "app: configure_sets before_ignore_deferred preserves order without forcing sync" {
  let stage = schedule_label("SetIgnoreDeferredUpdate")
  let observed : Array[Int] = []
  let set_a = system_set("SetIgnoreDeferred.A")
  let set_b = system_set("SetIgnoreDeferred.B")
  let deferred_system : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  }).in_set(set_a)
  let read_system : SystemConfig[@ecs.World] = system_config_param(fn(
    query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    observed.push(query.count())
  }).in_set(set_b)
  let lifecycle_world_369_0 = @ecs.World::new()
  defer lifecycle_world_369_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_369_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(stage, deferred_system)
    .add_systems(stage, read_system)
    .configure_sets(stage, set_a, before_ignore_deferred=[set_b])

  sub_app = sub_app.update()

  debug_inspect(observed, content="[0]")
  let world = sub_app.world()
  let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(query.count(), content="1")
}

///|
test "app: do_not_consider_ignore_deferred_before_exclusive_system" {
  let stage = schedule_label("IgnoreDeferredExclusiveBoundary")
  let observed : Array[Int] = []
  let set_a = system_set("IgnoreDeferredExclusive.A")
  let set_b = system_set("IgnoreDeferredExclusive.B")
  let lifecycle_world_402_0 = @ecs.World::new()
  defer lifecycle_world_402_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_402_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }).in_set(set_a),
    )
    .add_systems(
      stage,
      system(fn(world : @ecs.World) {
        let query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
          world,
        )
        observed.push(query.count())
      }).in_set(set_b),
    )
    .configure_sets(stage, set_a, before_ignore_deferred=[set_b])

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
}

///|
test "app: bubble_sync_point_through_ignore_deferred_node" {
  let stage = schedule_label("BubbleSyncThroughIgnoreDeferred")
  let observed : Array[Int] = []
  let set_a = system_set("BubbleSync.A")
  let set_b = system_set("BubbleSync.B")
  let set_c = system_set("BubbleSync.C")
  let lifecycle_world_433_0 = @ecs.World::new()
  defer lifecycle_world_433_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_433_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }).in_set(set_a),
    )
    .add_systems(stage, system(fn(_world : @ecs.World) {  }).in_set(set_b))
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_c),
    )
    .configure_sets(stage, set_a, before_ignore_deferred=[set_b])
    .configure_sets(stage, set_b, before=[set_c])

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
}

///|
test "app: explicit_sync_point_used_as_auto_sync_point" {
  let stage = schedule_label("ExplicitSyncReuse")
  let observed : Array[Int] = []
  let set_a = system_set("ExplicitSyncReuse.A")
  let set_b = system_set("ExplicitSyncReuse.B")
  let set_c = system_set("ExplicitSyncReuse.C")
  let lifecycle_world_466_0 = @ecs.World::new()
  defer lifecycle_world_466_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_466_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }).in_set(set_a),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_b),
    )
    .add_systems(stage, apply_deferred_system().in_set(set_b))
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_c),
    )
    .configure_sets(stage, set_a, before=[set_b])
    .configure_sets(stage, set_b, before=[set_c])

  sub_app = sub_app.update()

  // Bevy reuses the explicit sync point by inserting it on the dependency edge,
  // so the reader in the same target set must run after ApplyDeferred.
  debug_inspect(observed, content="[1, 1]")
}

///|
test "app: conditional_explicit_sync_point_not_used_as_auto_sync_point" {
  let stage = schedule_label("ConditionalExplicitSyncNoReuse")
  let observed : Array[Int] = []
  let set_a = system_set("ConditionalSync.A")
  let set_b = system_set("ConditionalSync.B")
  let set_c = system_set("ConditionalSync.C")
  let lifecycle_world_509_0 = @ecs.World::new()
  defer lifecycle_world_509_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_509_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }).in_set(set_a),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_b),
    )
    .add_systems(
      stage,
      apply_deferred_system()
      .run_if(fn(_world : @ecs.World) { false })
      .in_set(set_b),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_c),
    )
    .configure_sets(stage, set_a, before=[set_b])
    .configure_sets(stage, set_b, before=[set_c])

  sub_app = sub_app.update()

  // Conditional explicit ApplyDeferred cannot be reused, so an automatic sync
  // point is inserted before the dependent reader instead.
  debug_inspect(observed, content="[1, 1]")
}

///|
test "app: conditional explicit sync point in child set is not reused as auto sync point" {
  let stage = schedule_label("ConditionalNestedExplicitSyncNoReuse")
  let observed : Array[Int] = []
  let set_a = system_set("ConditionalNestedSync.A")
  let set_b = system_set("ConditionalNestedSync.B")
  let set_c = system_set("ConditionalNestedSync.C")
  let parent_set = system_set("ConditionalNestedSync.Parent")
  let lifecycle_world_557_0 = @ecs.World::new()
  defer lifecycle_world_557_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_557_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }).in_set(set_a),
    )
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_b),
    )
    .add_systems(stage, apply_deferred_system().in_set(set_b))
    .add_systems(
      stage,
      system_config_param(fn(
        query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
      ) {
        observed.push(query.count())
      }).in_set(set_c),
    )
    .configure_sets(stage, set_a, before=[set_b])
    .configure_sets(stage, set_b, before=[set_c], in_sets=[parent_set])
    .configure_sets(stage, parent_set, set_run_ifs=[
      fn(_world : @ecs.World) { false },
    ])

  sub_app = sub_app.update()

  debug_inspect(observed, content="[1]")
}

///|
test "app: set run_if evaluates once per run and gates all systems in the set" {
  let stage = schedule_label("SetRunIfOncePerFrame")
  let gated_set = system_set("SetRunIf.Once")
  let condition_eval_count = Ref(0)
  let executed : Array[String] = []
  let lifecycle_world_602_0 = @ecs.World::new()
  defer lifecycle_world_602_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_602_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { executed.push("A") }).in_set(gated_set),
    )
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { executed.push("B") }).in_set(gated_set),
    )
    .configure_sets(stage, gated_set, set_run_ifs=[
      fn(_world : @ecs.World) {
        condition_eval_count.val = condition_eval_count.val + 1
        condition_eval_count.val % 2 == 0
      },
    ])

  sub_app = sub_app.update()
  debug_inspect(condition_eval_count.val, content="1")
  debug_inspect(executed, content="[]")

  sub_app = sub_app.update()
  debug_inspect(condition_eval_count.val, content="2")
  debug_inspect(executed, content="[\"A\", \"B\"]")
}

///|
test "app: disabling apply_final_deferred keeps deferred commands pending until a later apply" {
  let enqueue_stage = schedule_label("NoFinalDeferredFlush.Enqueue")
  let flush_stage = schedule_label("NoFinalDeferredFlush.Flush")
  let lifecycle_world_635_0 = @ecs.World::new()
  defer lifecycle_world_635_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_635_0)
    .set_update_schedule(Some(enqueue_stage))
    .add_schedule(
      Schedule::new(enqueue_stage)
      .set_executor_kind(SingleThreaded)
      .set_apply_final_deferred(false),
    )
    .add_schedule(Schedule::new(flush_stage).set_executor_kind(SingleThreaded))
    .add_systems(
      enqueue_stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }),
    )

  sub_app = sub_app.update()
  let world_after_first = sub_app.world()
  let query_after_first : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world_after_first,
  )
  debug_inspect(query_after_first.count(), content="0")

  sub_app = sub_app.set_update_schedule(Some(flush_stage))
  sub_app = sub_app.update()
  let world_after_second = sub_app.world()
  let query_after_second : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world_after_second,
  )
  debug_inspect(query_after_second.count(), content="1")
}

///|
test "app: add_schedule reinserts and replaces previous schedule content" {
  let stage = schedule_label("ReinsertScheduleReplacesContent")
  let lifecycle_world_670_0 = @ecs.World::new()
  defer lifecycle_world_670_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_670_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system_config_param(fn(commands : Commands) {
        ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
      }),
    )

  sub_app = sub_app.update()
  let world_after_first = sub_app.world()
  let query_after_first : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world_after_first,
  )
  debug_inspect(query_after_first.count(), content="1")

  // Bevy parity: re-inserting the same schedule label replaces the old schedule.
  sub_app = sub_app.add_schedule(
    Schedule::new(stage).set_executor_kind(SingleThreaded),
  )
  sub_app = sub_app.update()
  let world_after_second = sub_app.world()
  let query_after_second : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All] = @ecs.query(
    world_after_second,
  )
  debug_inspect(query_after_second.count(), content="1")
}

///|
test "app: system run_if evaluates all conditions without short-circuiting" {
  let second_condition_seen : Array[Int] = []
  let system_runs = Ref(0)
  let lifecycle_world_702_0 = @ecs.World::new()
  defer lifecycle_world_702_0.close()
  let app = App::new(lifecycle_world_702_0).add_system_config(
    system(fn(_world : @ecs.World) { system_runs.val = system_runs.val + 1 })
    .run_if(fn(_world : @ecs.World) { false })
    .run_if_stateful(0, fn(
      _world : @ecs.World,
      state : RunConditionState[Int],
    ) {
      let value = state.get()
      second_condition_seen.push(value)
      state.set(value + 1)
      true
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(system_runs.val, content="0")
  debug_inspect(second_condition_seen, content="[0, 1]")
}

///|
test "app: set run_if evaluates all conditions without short-circuiting and caches once per run" {
  let stage = schedule_label("SetRunIfNoShortCircuit")
  let set_a = system_set("SetRunIf.NoShortCircuit")
  let second_condition_seen : Array[Int] = []
  let system_runs : Array[String] = []
  let lifecycle_world_727_0 = @ecs.World::new()
  defer lifecycle_world_727_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_727_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { system_runs.push("one") }).in_set(set_a),
    )
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { system_runs.push("two") }).in_set(set_a),
    )
    .configure_sets(
      stage,
      set_a,
      set_run_ifs=[fn(_world : @ecs.World) { false }],
      set_run_if_statefuls=[
        stateful_run_condition(0, fn(
          _world : @ecs.World,
          state : RunConditionState[Int],
        ) {
          let value = state.get()
          second_condition_seen.push(value)
          state.set(value + 1)
          true
        }),
      ],
    )

  sub_app = sub_app.update()
  sub_app = sub_app.update()

  debug_inspect(system_runs, content="[]")
  debug_inspect(second_condition_seen, content="[0, 1]")
}

///|
test "app: failed set run_if does not skip other set or system conditions" {
  let stage = schedule_label("SetRunIfEvaluatesAllAncestors")
  let set_a = system_set("SetRunIf.All.A")
  let set_b = system_set("SetRunIf.All.B")
  let set_b_condition_hits : Array[Int] = []
  let system_condition_hits : Array[Int] = []
  let system_runs : Array[String] = []
  let lifecycle_world_768_0 = @ecs.World::new()
  defer lifecycle_world_768_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_768_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { system_runs.push("body") })
      .in_set(set_a)
      .in_set(set_b)
      .run_if_stateful(0, fn(
        _world : @ecs.World,
        state : RunConditionState[Int],
      ) {
        let value = state.get()
        system_condition_hits.push(value)
        state.set(value + 1)
        true
      }),
    )
    .configure_sets(stage, set_a, set_run_ifs=[
      fn(_world : @ecs.World) { false },
    ])
    .configure_sets(stage, set_b, set_run_if_statefuls=[
      stateful_run_condition(0, fn(
        _world : @ecs.World,
        state : RunConditionState[Int],
      ) {
        let value = state.get()
        set_b_condition_hits.push(value)
        state.set(value + 1)
        true
      }),
    ])

  sub_app = sub_app.update()
  sub_app = sub_app.update()

  debug_inspect(system_runs, content="[]")
  debug_inspect(set_b_condition_hits, content="[0, 1]")
  debug_inspect(system_condition_hits, content="[0, 1]")
}

///|
test "app: failed set run_if marks remaining set systems completed" {
  let stage = schedule_label("SetRunIfCompletesRemainingSystems")
  let set_a = system_set("SetRunIf.CompletesRemaining")
  let first_system_condition_hits : Array[Int] = []
  let second_system_condition_hits : Array[Int] = []
  let system_runs : Array[String] = []
  let lifecycle_world_817_0 = @ecs.World::new()
  defer lifecycle_world_817_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_817_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { system_runs.push("first") })
      .in_set(set_a)
      .run_if_stateful(0, fn(
        _world : @ecs.World,
        state : RunConditionState[Int],
      ) {
        let value = state.get()
        first_system_condition_hits.push(value)
        state.set(value + 1)
        true
      }),
    )
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { system_runs.push("second") })
      .in_set(set_a)
      .run_if_stateful(0, fn(
        _world : @ecs.World,
        state : RunConditionState[Int],
      ) {
        let value = state.get()
        second_system_condition_hits.push(value)
        state.set(value + 1)
        true
      }),
    )
    .configure_sets(stage, set_a, set_run_ifs=[
      fn(_world : @ecs.World) { false },
    ])

  sub_app = sub_app.update()
  sub_app = sub_app.update()

  debug_inspect(system_runs, content="[]")
  debug_inspect(first_system_condition_hits, content="[0, 1]")
  debug_inspect(second_system_condition_hits, content="[]")
}

///|
test "app: runtime-invalid system is still scheduled and validated during execution" {
  ignore(MissingRunIfParityResource::{  })
  let validation_kinds : Array[ErrorContextKind] = []
  let run_if_hits = Ref(0)
  let body_runs = Ref(0)
  let follower_runs = Ref(0)
  let lifecycle_world_867_0 = @ecs.World::new()
  defer lifecycle_world_867_0.close()
  let app = App::new(lifecycle_world_867_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .add_system_config(
      system_config_param(fn(_res : Res[MissingRunIfParityResource]) {
        body_runs.val = body_runs.val + 1
      }).run_if(fn(_world : @ecs.World) {
        run_if_hits.val = run_if_hits.val + 1
        true
      }),
    )
    .add_system(fn(_world : @ecs.World) {
      follower_runs.val = follower_runs.val + 1
    })

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(run_if_hits.val, content="2")
  debug_inspect(body_runs.val, content="0")
  debug_inspect(follower_runs.val, content="2")
  debug_inspect(validation_kinds.length(), content="2")
  debug_inspect(
    validation_kinds[0] == ErrorContextKind::Validation &&
    validation_kinds[1] == ErrorContextKind::Validation,
    content="true",
  )
}

///|
test "app: statically invalid system stays in order and evaluates conditions before validation" {
  let validation_kinds : Array[ErrorContextKind] = []
  let run_if_hits = Ref(0)
  let body_runs = Ref(0)
  let follower_runs = Ref(0)
  let lifecycle_world_904_0 = @ecs.World::new()
  defer lifecycle_world_904_0.close()
  let app = App::new(lifecycle_world_904_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .add_system_config(
      system_config_param2(fn(
        _a : @ecs.Query[@ecs.Write[ScheduleBatchMarker], @ecs.All],
        _b : @ecs.Query[@ecs.Write[ScheduleBatchMarker], @ecs.All],
      ) {
        body_runs.val = body_runs.val + 1
      }).run_if(fn(_world : @ecs.World) {
        run_if_hits.val = run_if_hits.val + 1
        true
      }),
    )
    .add_system(fn(_world : @ecs.World) {
      follower_runs.val = follower_runs.val + 1
    })

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(run_if_hits.val, content="2")
  debug_inspect(body_runs.val, content="0")
  debug_inspect(follower_runs.val, content="2")
  debug_inspect(validation_kinds.length(), content="2")
  debug_inspect(
    validation_kinds[0] == ErrorContextKind::Validation &&
    validation_kinds[1] == ErrorContextKind::Validation,
    content="true",
  )
}

///|
test "app: consecutive deferred chain inserts one sync point per deferred edge" {
  let stage = schedule_label("ConsecutiveDeferredSyncPoints")
  let command_a : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  }).named("tests.command_a")
  let command_b : SystemConfig[@ecs.World] = system_config_param(fn(
    commands : Commands,
  ) {
    ignore(commands.spawn_component(ScheduleBatchMarker::{  }))
  }).named("tests.command_b")
  let reader : SystemConfig[@ecs.World] = system_config_param(fn(
    _query : @ecs.Query[@ecs.Read[ScheduleBatchMarker], @ecs.All],
  ) {
    ()
  }).named("tests.reader")
  let lifecycle_world_943_0 = @ecs.World::new()
  defer lifecycle_world_943_0.close()
  let app = App::new(lifecycle_world_943_0)
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(stage, chain((command_a, command_b, reader)))

  let dot = app.schedule_graph_dot(stage)
  debug_inspect(
    dot.contains("\"bevy_ecs::apply_deferred#auto0\""),
    content="true",
  )
  debug_inspect(
    dot.contains("\"bevy_ecs::apply_deferred#auto1\""),
    content="true",
  )
  debug_inspect(
    dot.contains("\"bevy_ecs::apply_deferred#auto2\""),
    content="false",
  )
}

///|
test "app: chain run_if is a collective set condition evaluated once" {
  let stage = schedule_label("ChainCollectiveRunIf")
  let condition_hits = Ref(0)
  let system_runs : Array[String] = []
  let lifecycle_world_980_0 = @ecs.World::new()
  defer lifecycle_world_980_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_980_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      chain(
        (
          system(fn(_world : @ecs.World) { system_runs.push("a") }),
          system(fn(_world : @ecs.World) { system_runs.push("b") }),
        ),
      ).run_if(fn(_world : @ecs.World) {
        condition_hits.val = condition_hits.val + 1
        condition_hits.val % 2 == 0
      }),
    )

  sub_app = sub_app.update()
  sub_app = sub_app.update()

  debug_inspect(condition_hits.val, content="2")
  debug_inspect(system_runs, content="[\"a\", \"b\"]")
}

///|
test "app: parent set run_if is evaluated before child set run_if" {
  let stage = schedule_label("ParentBeforeChildRunIf")
  let parent = system_set("ParentBeforeChild.Parent")
  let child = system_set("ParentBeforeChild.Child")
  let log : Array[String] = []
  let lifecycle_world_1008_0 = @ecs.World::new()
  defer lifecycle_world_1008_0.close()
  let mut sub_app = SubApp::new(lifecycle_world_1008_0)
    .set_update_schedule(Some(stage))
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { log.push("system") }).in_set(child),
    )
    .configure_sets(stage, parent, set_run_ifs=[
      fn(_world : @ecs.World) {
        log.push("parent")
        true
      },
    ])
    .configure_sets(stage, child, in_sets=[parent], set_run_ifs=[
      fn(_world : @ecs.World) {
        log.push("child")
        true
      },
    ])

  sub_app = sub_app.update()

  debug_inspect(log, content="[\"parent\", \"child\", \"system\"]")
}

///|
test "app: ordered overlapping sets fail schedule build" {
  let stage = schedule_label("OrderedOverlappingSets")
  let set_a = system_set("OrderedOverlappingSets.A")
  let set_b = system_set("OrderedOverlappingSets.B")
  let validation_kinds : Array[ErrorContextKind] = []
  let lifecycle_world_1039_0 = @ecs.World::new()
  defer lifecycle_world_1039_0.close()
  let mut app = App::new(lifecycle_world_1039_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .add_schedule(Schedule::new(stage).set_executor_kind(SingleThreaded))
    .add_systems(
      stage,
      system(fn(_world : @ecs.World) { () }).in_set(set_a).in_set(set_b),
    )
    .configure_sets(stage, set_a, before=[set_b])
  let order = world_main_schedule_order(app.world()).insert_after(Update, stage)
  app.world().insert_resource(main_schedule_order_resource_key, order)

  app = app.run_once()

  ignore(app)
  debug_inspect(validation_kinds, content="[Validation]")
}

///|
test "app: hierarchy redundancy can be promoted to build error" {
  let stage = schedule_label("HierarchyRedundancyAsError")
  let child = system_set("HierarchyRedundancy.Child")
  let parent = system_set("HierarchyRedundancy.Parent")
  let grandparent = system_set("HierarchyRedundancy.Grandparent")
  let validation_kinds : Array[ErrorContextKind] = []
  let settings = ScheduleBuildSettings::new().set_hierarchy_detection(
    ScheduleBuildError,
  )
  let lifecycle_world_1064_0 = @ecs.World::new()
  defer lifecycle_world_1064_0.close()
  let mut app = App::new(lifecycle_world_1064_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .add_schedule(
      Schedule::new(stage)
      .set_executor_kind(SingleThreaded)
      .set_build_settings(settings),
    )
    .add_systems(stage, system(fn(_world : @ecs.World) { () }).in_set(child))
    .configure_sets(stage, child, in_sets=[parent, grandparent])
    .configure_sets(stage, parent, in_sets=[grandparent])
  let order = world_main_schedule_order(app.world()).insert_after(Update, stage)
  app.world().insert_resource(main_schedule_order_resource_key, order)

  app = app.run_once()

  ignore(app)
  debug_inspect(validation_kinds, content="[Validation]")
}

///|
test "app: ambiguity detection can be promoted to build error" {
  let stage = schedule_label("AmbiguityDetectionAsError")
  let validation_kinds : Array[ErrorContextKind] = []
  let settings = ScheduleBuildSettings::new().set_ambiguity_detection(
    ScheduleBuildError,
  )
  let lifecycle_world_1095_0 = @ecs.World::new()
  defer lifecycle_world_1095_0.close()
  let mut app = App::new(lifecycle_world_1095_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .insert_resource(MissingRunIfParityResource::{  })
    .add_schedule(
      Schedule::new(stage)
      .set_executor_kind(SingleThreaded)
      .set_build_settings(settings),
    )
    .add_systems(
      stage,
      system_config_param(fn(_res : ResMut[MissingRunIfParityResource]) { () }).named(
        "tests.ambiguous_a",
      ),
    )
    .add_systems(
      stage,
      system_config_param(fn(_res : ResMut[MissingRunIfParityResource]) { () }).named(
        "tests.ambiguous_b",
      ),
    )
  let order = world_main_schedule_order(app.world()).insert_after(Update, stage)
  app.world().insert_resource(main_schedule_order_resource_key, order)

  app = app.run_once()

  ignore(app)
  debug_inspect(validation_kinds, content="[Validation]")
}

///|
test "app: allowed ambiguous resource suppresses resource ambiguity" {
  let stage = schedule_label("AllowedAmbiguousResource")
  let validation_kinds : Array[ErrorContextKind] = []
  let settings = ScheduleBuildSettings::new().set_ambiguity_detection(
    ScheduleBuildError,
  )
  let key : @ecs.ResourceKey[MissingRunIfParityResource] = MissingRunIfParityResource::resource()
  let lifecycle_world_1133_0 = @ecs.World::new()
  defer lifecycle_world_1133_0.close()
  let mut app = App::new(lifecycle_world_1133_0)
    .set_error_handler(fn(_error, context) {
      validation_kinds.push(context.kind())
    })
    .insert_resource(MissingRunIfParityResource::{  })
    .allow_ambiguous_resource(key~)
    .add_schedule(
      Schedule::new(stage)
      .set_executor_kind(SingleThreaded)
      .set_build_settings(settings),
    )
    .add_systems(
      stage,
      system_config_param(fn(_res : ResMut[MissingRunIfParityResource]) { () }).named(
        "tests.allowed_ambiguous_resource_a",
      ),
    )
    .add_systems(
      stage,
      system_config_param(fn(_res : ResMut[MissingRunIfParityResource]) { () }).named(
        "tests.allowed_ambiguous_resource_b",
      ),
    )
  let order = world_main_schedule_order(app.world()).insert_after(Update, stage)
  app.world().insert_resource(main_schedule_order_resource_key, order)

  app = app.run_once()

  ignore(app)
  debug_inspect(validation_kinds, content="[]")
}
