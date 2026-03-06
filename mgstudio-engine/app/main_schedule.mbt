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
}

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
let main_schedule_order_resource : Ref[@core.Resource[MainScheduleOrder]] = Ref::new(
  @core.Resource::new(),
)

///|
let fixed_main_schedule_order_resource : Ref[
  @core.Resource[FixedMainScheduleOrder],
] = Ref::new(@core.Resource::new())

///|
fn[T] schedule_resource_sync(
  resource : @core.Resource[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  match resource.get_ref_mut(change_tick) {
    Some(cell) => cell.val = value
    None => resource.insert(value, change_tick)
  }
}

///|
pub impl Resource for MainScheduleOrder with resource() {
  main_schedule_order_resource.val
}

///|
pub impl Resource for FixedMainScheduleOrder with resource() {
  fixed_main_schedule_order_resource.val
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
fn main_schedule_order_or_default() -> MainScheduleOrder {
  match MainScheduleOrder::resource().get() {
    Some(order) => order
    None => MainScheduleOrder::default()
  }
}

///|
fn fixed_main_schedule_order_or_default() -> FixedMainScheduleOrder {
  match FixedMainScheduleOrder::resource().get() {
    Some(order) => order
    None => FixedMainScheduleOrder::default()
  }
}

///|
fn main_schedule_write_order(
  update : (MainScheduleOrder) -> MainScheduleOrder,
  change_tick : @core.Tick,
) -> Unit {
  let next_order = update(main_schedule_order_or_default())
  schedule_resource_sync(MainScheduleOrder::resource(), next_order, change_tick)
}

///|
fn main_schedule_insert_after_unique(
  after : ScheduleStage,
  stage : ScheduleStage,
  change_tick : @core.Tick,
) -> Unit {
  main_schedule_write_order(
    fn(order : MainScheduleOrder) {
      if schedule_stage_contains(order.labels, stage) {
        order
      } else {
        order.insert_after(after, stage)
      }
    },
    change_tick,
  )
}

///|
fn main_schedule_insert_startup_before_unique(
  before : ScheduleStage,
  stage : ScheduleStage,
  change_tick : @core.Tick,
) -> Unit {
  main_schedule_write_order(
    fn(order : MainScheduleOrder) {
      if schedule_stage_contains(order.startup_labels, stage) {
        order
      } else {
        order.insert_startup_before(before, stage)
      }
    },
    change_tick,
  )
}

///|
fn reset_main_schedule_resources() -> Unit {
  MainScheduleOrder::resource().insert(MainScheduleOrder::default(), 1)
  FixedMainScheduleOrder::resource().insert(
    FixedMainScheduleOrder::default(),
    1,
  )
}

///|
fn run_main_schedule_stage(
  world : @ecs.World,
  schedule : Schedule[@ecs.World],
  stage : ScheduleStage,
) -> Unit {
  match stage {
    StateTransition => run_registered_state_transitions(world)
    FixedMain => run_fixed_main_schedule(world, schedule)
    _ => run_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_main_schedule_startup(
  world : @ecs.World,
  schedule : Schedule[@ecs.World],
) -> Unit {
  for stage in main_schedule_order_or_default().startup_labels {
    run_main_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_main_schedule_update(
  world : @ecs.World,
  schedule : Schedule[@ecs.World],
) -> Unit {
  for stage in main_schedule_order_or_default().labels {
    run_main_schedule_stage(world, schedule, stage)
  }
}

///|
fn run_fixed_main_schedule(
  world : @ecs.World,
  schedule : Schedule[@ecs.World],
) -> Unit {
  for stage in fixed_main_schedule_order_or_default().labels {
    run_schedule_stage(world, schedule, stage)
  }
}

///|
pub fn run_current_fixed_main_schedule(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_fixed_main_schedule(world, schedule)
}
