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
fn[T] read_time_test_resource(
  app : @app.App[@ecs.World],
  key : @ecs.ResourceKey[T],
) -> T {
  try! app.world().get_resource(key).unwrap()
}

///|
fn read_default_time_test_resource(app : @app.App[@ecs.World]) -> Time[Unit] {
  read_time_test_resource(app, default_time_resource_key())
}

///|
fn read_real_time_test_resource(app : @app.App[@ecs.World]) -> Time[Real] {
  read_time_test_resource(app, real_time_resource_key())
}

///|
fn read_virtual_time_test_resource(app : @app.App[@ecs.World]) -> Time[Virtual] {
  read_time_test_resource(app, virtual_time_resource_key())
}

///|
fn read_fixed_time_test_resource(app : @app.App[@ecs.World]) -> Time[Fixed] {
  read_time_test_resource(app, fixed_time_resource_key())
}

///|
fn update_virtual_test_resource(
  app : @app.App[@ecs.World],
  update : (Time[Virtual]) -> Time[Virtual],
) -> @app.App[@ecs.World] {
  let world = app.world()
  let virtual_ref = try! world
    .get_resource_ref_mut(virtual_time_resource_key())
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(default_time_resource_key())
    .unwrap()
  let next_virtual = update(virtual_ref.val)
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
  app
}

///|
fn set_virtual_max_delta_seconds(
  app : @app.App[@ecs.World],
  max_delta_seconds : Float,
) -> @app.App[@ecs.World] {
  update_virtual_test_resource(app, fn(virtual_time : Time[Virtual]) {
    virtual_time.set_max_delta_seconds(max_delta_seconds)
  })
}

///|
fn pause_virtual_time(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  update_virtual_test_resource(app, fn(virtual_time : Time[Virtual]) {
    virtual_time.pause()
  })
}

///|
fn unpause_virtual_time(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  update_virtual_test_resource(app, fn(virtual_time : Time[Virtual]) {
    virtual_time.unpause()
  })
}

///|
fn set_virtual_relative_speed(
  app : @app.App[@ecs.World],
  speed : Float,
) -> @app.App[@ecs.World] {
  update_virtual_test_resource(app, fn(virtual_time : Time[Virtual]) {
    virtual_time.set_relative_speed(speed)
  })
}

///|
fn current_stage_label() -> String {
  match @app.current_schedule_stage() {
    Some(@app.Main) => "Main"
    Some(@app.PreStartup) => "PreStartup"
    Some(@app.Startup) => "Startup"
    Some(@app.PostStartup) => "PostStartup"
    Some(@app.First) => "First"
    Some(@app.PreUpdate) => "PreUpdate"
    Some(@app.StateTransition) => "StateTransition"
    Some(@app.RunFixedMainLoop) => "RunFixedMainLoop"
    Some(@app.FixedFirst) => "FixedFirst"
    Some(@app.FixedPreUpdate) => "FixedPreUpdate"
    Some(@app.FixedUpdate) => "FixedUpdate"
    Some(@app.FixedPostUpdate) => "FixedPostUpdate"
    Some(@app.FixedLast) => "FixedLast"
    Some(@app.FixedMain) => "FixedMain"
    Some(@app.Update) => "Update"
    Some(@app.SpawnScene) => "SpawnScene"
    Some(@app.PostUpdate) => "PostUpdate"
    Some(@app.Last) => "Last"
    Some(@app.Custom(name)) => name
    None => "None"
  }
}

///|
test "time: manual instant keeps first update delta at zero" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    TimePlugin::default(),
  )
  app = set_virtual_max_delta_seconds(app, 10.0F)

  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualInstant(@core.Instant::from_secs_f32(10.0F)),
    )
    .run_once()
  debug_inspect(
    read_real_time_test_resource(app).first_update_seconds(),
    content="Some(10)",
  )
  debug_inspect(read_real_time_test_resource(app).delta_seconds(), content="0")
  debug_inspect(
    read_real_time_test_resource(app).elapsed_seconds(),
    content="0",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).delta_seconds(),
    content="0",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="0",
  )

  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualInstant(@core.Instant::from_secs_f32(12.5F)),
    )
    .run_once()
  debug_inspect(
    read_real_time_test_resource(app).last_update_seconds(),
    content="Some(12.5)",
  )
  debug_inspect(
    read_real_time_test_resource(app).delta_seconds(),
    content="2.5",
  )
  debug_inspect(
    read_real_time_test_resource(app).elapsed_seconds(),
    content="2.5",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).delta_seconds(),
    content="2.5",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="2.5",
  )
}

///|
test "time: virtual time clamps large deltas by default" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    TimePlugin::default(),
  )

  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualDuration(@core.Duration::from_secs_f32(1.0F)),
    )
    .run_once()
  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualDuration(@core.Duration::from_secs_f32(1.0F)),
    )
    .run_once()
  debug_inspect(read_real_time_test_resource(app).delta_seconds(), content="1")
  debug_inspect(
    read_virtual_time_test_resource(app).delta_seconds(),
    content="0.25",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="0.25",
  )
}

///|
test "time: pause and relative speed follow bevy virtual semantics" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    TimePlugin::default(),
  )
  app = set_virtual_max_delta_seconds(app, 10.0F)

  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualDuration(@core.Duration::from_secs_f32(1.0F)),
    )
    .run_once()
  app = pause_virtual_time(app)
  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualDuration(@core.Duration::from_secs_f32(2.0F)),
    )
    .run_once()
  debug_inspect(read_real_time_test_resource(app).delta_seconds(), content="2")
  debug_inspect(
    read_virtual_time_test_resource(app).delta_seconds(),
    content="0",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).effective_speed(),
    content="0",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).was_paused(),
    content="true",
  )

  app = unpause_virtual_time(app)
  app = set_virtual_relative_speed(app, 0.5F)
  app = app
    .insert_resource(
      TimeUpdateStrategy::ManualDuration(@core.Duration::from_secs_f32(2.0F)),
    )
    .run_once()
  debug_inspect(read_real_time_test_resource(app).delta_seconds(), content="2")
  debug_inspect(
    read_virtual_time_test_resource(app).delta_seconds(),
    content="1",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).effective_speed(),
    content="0.5",
  )
  debug_inspect(
    read_virtual_time_test_resource(app).was_paused(),
    content="false",
  )
}

///|
test "time: fixed timesteps strategy drives fixed update loop" {
  let counter : Ref[Int] = Ref::new(0)
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.125F))
    .add_fixed_update_system(fn(_world : @ecs.World) {
      counter.val = counter.val + 1
    })
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(counter.val, content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(counter.val, content="2")
  debug_inspect(time_fixed_steps_ran_this_frame(), content="2")
  debug_inspect(
    read_fixed_time_test_resource(app).delta_seconds(),
    content="0.125",
  )
  debug_inspect(
    read_fixed_time_test_resource(app).elapsed_seconds(),
    content="0.25",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="0.25",
  )
}

///|
test "time: generic time switches to fixed during fixed update and restores after loop" {
  let fixed_log : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.125F))
    .add_fixed_update_system(fn(world : @ecs.World) {
      let generic_time : Time[Unit] = try! world
        .get_resource(default_time_resource_key())
        .unwrap()
      let fixed_time : Time[Fixed] = try! world
        .get_resource(fixed_time_resource_key())
        .unwrap()
      fixed_log.push(
        "\{generic_time.delta_seconds().to_string()}/\{generic_time.elapsed_seconds().to_string()}|\{fixed_time.delta_seconds().to_string()}/\{fixed_time.elapsed_seconds().to_string()}",
      )
    })
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(fixed_log.length(), content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(
    fixed_log.join(","),
    content="0.125/0.125|0.125/0.125,0.125/0.25|0.125/0.25",
  )
  debug_inspect(
    read_default_time_test_resource(app).delta_seconds(),
    content="0.25",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="0.25",
  )
}

///|
test "time: fixed resource timestep changes affect later steps in the same frame" {
  let steps : Ref[Int] = Ref::new(0)
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.2F))
    .add_fixed_update_system_param(fn(fixed_time : @app.ResMut[Time[Fixed]]) {
      steps.val = steps.val + 1
      if steps.val == 1 {
        fixed_time.get_ref().val = fixed_time.get_ref().val.set_timestep_seconds(
          0.1F,
        )
      }
    })
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(steps.val, content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  debug_inspect(steps.val, content="3")
  debug_inspect(time_fixed_steps_ran_this_frame(), content="3")
  debug_inspect(
    read_fixed_time_test_resource(app).timestep_seconds(),
    content="0.10000000149011612",
  )
  debug_inspect(
    read_fixed_time_test_resource(app).elapsed_seconds(),
    content="0.4000000059604645",
  )
  debug_inspect(
    read_default_time_test_resource(app).elapsed_seconds(),
    content="0.4000000059604645",
  )
}

///|
test "time: fixed main schedule runs substages in bevy order" {
  let log : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.25F))
    .add_fixed_first_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
    .add_fixed_pre_update_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
    .add_fixed_update_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
    .add_fixed_post_update_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
    .add_fixed_last_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(log.length(), content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(
    log.join(","),
    content="FixedFirst,FixedPreUpdate,FixedUpdate,FixedPostUpdate,FixedLast",
  )
}

///|
test "time: run fixed main loop system sets order before fixed and after hooks" {
  let log : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.25F))
    .add_run_fixed_main_loop_system_config(
      @app.system(fn(_world : @ecs.World) { log.push("before") }).in_set(
        @app.run_fixed_main_loop_system_set_name(
          @app.RunFixedMainLoopSystems::BeforeFixedMainLoop,
        ),
      ),
    )
    .add_fixed_update_system(fn(_world : @ecs.World) {
      log.push("fixed_update")
    })
    .add_run_fixed_main_loop_system_config(
      @app.system(fn(_world : @ecs.World) { log.push("after") }).in_set(
        @app.run_fixed_main_loop_system_set_name(
          @app.RunFixedMainLoopSystems::AfterFixedMainLoop,
        ),
      ),
    )
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(log.join(","), content="before,after")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(log.join(","), content="before,after,before,fixed_update,after")
}

///|
test "time: fixed main schedule order resource drives fixed substage order" {
  let log : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(TimePlugin::default())
    .insert_resource(Time::from_seconds(0.25F))
    .insert_world_resource(
      @app.fixed_main_schedule_order_resource_key(),
      @app.FixedMainScheduleOrder::new([@app.FixedLast, @app.FixedUpdate]),
    )
    .add_fixed_last_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
    .add_fixed_update_system(fn(_world : @ecs.World) {
      log.push(current_stage_label())
    })
  app = set_virtual_max_delta_seconds(app, 1.0F)

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(log.length(), content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(1)).run_once()
  debug_inspect(log.join(","), content="FixedLast,FixedUpdate")
}
