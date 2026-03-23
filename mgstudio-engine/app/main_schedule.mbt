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
pub(all) enum RunFixedMainLoopSystems {
  BeforeFixedMainLoop
  FixedMainLoop
  AfterFixedMainLoop
} derive(Eq, Show)

///|
pub fn run_fixed_main_loop_system_set_name(
  stage_set : RunFixedMainLoopSystems,
) -> SystemSet {
  match stage_set {
    BeforeFixedMainLoop =>
      system_set("mgstudio.app.run_fixed_main_loop.before_fixed_main_loop")
    FixedMainLoop =>
      system_set("mgstudio.app.run_fixed_main_loop.fixed_main_loop")
    AfterFixedMainLoop =>
      system_set("mgstudio.app.run_fixed_main_loop.after_fixed_main_loop")
  }
}

///|
pub struct MainScheduleOrder {
  labels : Array[ScheduleStage]
  startup_labels : Array[ScheduleStage]
} derive(Eq, Show)

///|
pub fn MainScheduleOrder::new(
  labels : Array[ScheduleStage],
  startup_labels : Array[ScheduleStage],
) -> MainScheduleOrder {
  MainScheduleOrder::{ labels, startup_labels }
}

///|
pub fn MainScheduleOrder::default() -> MainScheduleOrder {
  MainScheduleOrder::new(
    [First, PreUpdate, RunFixedMainLoop, Update, SpawnScene, PostUpdate, Last],
    [PreStartup, Startup, PostStartup],
  )
}

///|
pub struct FixedMainScheduleOrder {
  labels : Array[ScheduleStage]
} derive(Eq, Show)

///|
priv struct MainScheduleRuntimeState {
  startup_ran : Bool
}

///|
pub fn FixedMainScheduleOrder::new(
  labels : Array[ScheduleStage],
) -> FixedMainScheduleOrder {
  FixedMainScheduleOrder::{ labels, }
}

///|
pub fn FixedMainScheduleOrder::default() -> FixedMainScheduleOrder {
  FixedMainScheduleOrder::new([
    FixedFirst,
    FixedPreUpdate,
    FixedUpdate,
    FixedPostUpdate,
    FixedLast,
  ])
}

///|
pub fn main_schedule_order_resource_key() -> @ecs.ResourceKey[MainScheduleOrder] {
  @ecs.register_resource(debug_name="bevy_app::MainScheduleOrder")
}

///|
pub fn fixed_main_schedule_order_resource_key() -> @ecs.ResourceKey[
  FixedMainScheduleOrder,
] {
  @ecs.register_resource(debug_name="bevy_app::FixedMainScheduleOrder")
}

///|
fn main_schedule_runtime_state_resource_key() -> @ecs.ResourceKey[
  MainScheduleRuntimeState,
] {
  @ecs.register_resource(debug_name="bevy_app::MainScheduleRuntimeState")
}

///|
fn[T] world_schedule_resource(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
) -> T? {
  try world.get_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn schedule_stage_position(
  labels : Array[ScheduleStage],
  stage : ScheduleStage,
) -> Int? {
  for i in 0..<labels.length() {
    if labels[i] == stage {
      return Some(i)
    }
  }
  None
}

///|
fn schedule_stage_insert_after(
  labels : Array[ScheduleStage],
  after : ScheduleStage,
  stage : ScheduleStage,
) -> Unit {
  match schedule_stage_position(labels, after) {
    Some(index) => labels.insert(index + 1, stage)
    None => abort("Expected schedule stage to exist: " + after.to_string())
  }
}

///|
fn schedule_stage_insert_before(
  labels : Array[ScheduleStage],
  before : ScheduleStage,
  stage : ScheduleStage,
) -> Unit {
  match schedule_stage_position(labels, before) {
    Some(index) => labels.insert(index, stage)
    None => abort("Expected schedule stage to exist: " + before.to_string())
  }
}

///|
fn schedule_stage_contains(
  labels : Array[ScheduleStage],
  stage : ScheduleStage,
) -> Bool {
  schedule_stage_position(labels, stage) is Some(_)
}

///|
pub fn MainScheduleOrder::insert_after(
  self : MainScheduleOrder,
  after : ScheduleStage,
  stage : ScheduleStage,
) -> MainScheduleOrder {
  schedule_stage_insert_after(self.labels, after, stage)
  self
}

///|
pub fn MainScheduleOrder::insert_before(
  self : MainScheduleOrder,
  before : ScheduleStage,
  stage : ScheduleStage,
) -> MainScheduleOrder {
  schedule_stage_insert_before(self.labels, before, stage)
  self
}

///|
pub fn MainScheduleOrder::insert_startup_after(
  self : MainScheduleOrder,
  after : ScheduleStage,
  stage : ScheduleStage,
) -> MainScheduleOrder {
  schedule_stage_insert_after(self.startup_labels, after, stage)
  self
}

///|
pub fn MainScheduleOrder::insert_startup_before(
  self : MainScheduleOrder,
  before : ScheduleStage,
  stage : ScheduleStage,
) -> MainScheduleOrder {
  schedule_stage_insert_before(self.startup_labels, before, stage)
  self
}

///|
pub fn FixedMainScheduleOrder::insert_after(
  self : FixedMainScheduleOrder,
  after : ScheduleStage,
  stage : ScheduleStage,
) -> FixedMainScheduleOrder {
  schedule_stage_insert_after(self.labels, after, stage)
  self
}

///|
pub fn FixedMainScheduleOrder::insert_before(
  self : FixedMainScheduleOrder,
  before : ScheduleStage,
  stage : ScheduleStage,
) -> FixedMainScheduleOrder {
  schedule_stage_insert_before(self.labels, before, stage)
  self
}

///|
pub fn world_main_schedule_order(world : @ecs.World) -> MainScheduleOrder {
  match world_schedule_resource(world, main_schedule_order_resource_key()) {
    Some(order) => order
    None => MainScheduleOrder::default()
  }
}

///|
pub fn world_fixed_main_schedule_order(
  world : @ecs.World,
) -> FixedMainScheduleOrder {
  match
    world_schedule_resource(world, fixed_main_schedule_order_resource_key()) {
    Some(order) => order
    None => FixedMainScheduleOrder::default()
  }
}

///|
fn main_schedule_runtime_state(world : @ecs.World) -> MainScheduleRuntimeState {
  match
    world_schedule_resource(world, main_schedule_runtime_state_resource_key()) {
    Some(state) => state
    None => MainScheduleRuntimeState::{ startup_ran: false }
  }
}

///|
fn main_schedule_write_runtime_state(
  world : @ecs.World,
  state : MainScheduleRuntimeState,
) -> Unit {
  world.insert_resource(main_schedule_runtime_state_resource_key(), state)
}

///|
fn main_schedule_write_order(
  world : @ecs.World,
  update : (MainScheduleOrder) -> MainScheduleOrder,
) -> Unit {
  let next_order = update(world_main_schedule_order(world))
  world.insert_resource(main_schedule_order_resource_key(), next_order)
}

///|
fn main_schedule_insert_after_unique(
  world : @ecs.World,
  after : ScheduleStage,
  stage : ScheduleStage,
) -> Unit {
  main_schedule_write_order(world, fn(order : MainScheduleOrder) {
    if schedule_stage_contains(order.labels, stage) {
      order
    } else {
      order.insert_after(after, stage)
    }
  })
}

///|
fn main_schedule_insert_startup_before_unique(
  world : @ecs.World,
  before : ScheduleStage,
  stage : ScheduleStage,
) -> Unit {
  main_schedule_write_order(world, fn(order : MainScheduleOrder) {
    if schedule_stage_contains(order.startup_labels, stage) {
      order
    } else {
      order.insert_startup_before(before, stage)
    }
  })
}

///|
fn reset_main_schedule_resources(world : @ecs.World) -> Unit {
  world.insert_resource(
    main_schedule_order_resource_key(),
    MainScheduleOrder::default(),
  )
  world.insert_resource(
    fixed_main_schedule_order_resource_key(),
    FixedMainScheduleOrder::default(),
  )
  main_schedule_write_runtime_state(world, MainScheduleRuntimeState::{
    startup_ran: false,
  })
}

///|
fn run_main_schedule_stage(
  world : @ecs.World,
  schedule : ScheduleRegistry[@ecs.World],
  stage : ScheduleStage,
) -> Unit {
  match stage {
    StateTransition => run_registered_state_transitions(world)
    _ => run_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_main_schedule_startup(
  world : @ecs.World,
  schedule : ScheduleRegistry[@ecs.World],
) -> Unit {
  if main_schedule_runtime_state(world).startup_ran {
    return
  }
  for stage in world_main_schedule_order(world).startup_labels {
    run_main_schedule_stage(world, schedule, stage)
  }
  main_schedule_write_runtime_state(world, MainScheduleRuntimeState::{
    startup_ran: true,
  })
}

///|
fn run_main_schedule_update(
  world : @ecs.World,
  schedule : ScheduleRegistry[@ecs.World],
) -> Unit {
  run_main_schedule_startup(world, schedule)
  for stage in world_main_schedule_order(world).labels {
    run_main_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_fixed_main_schedule(
  world : @ecs.World,
  schedule : ScheduleRegistry[@ecs.World],
) -> Unit {
  for stage in world_fixed_main_schedule_order(world).labels {
    run_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_main_schedule_driver_system(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_main_schedule_update(world, schedule)
}

///|
fn run_fixed_main_schedule_driver_system(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_fixed_main_schedule(world, schedule)
}

///|
pub fn run_current_fixed_main_schedule(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_fixed_main_schedule(world, schedule)
}
