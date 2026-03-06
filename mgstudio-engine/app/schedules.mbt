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
pub struct ScheduleEntry[W] {
  systems : Array[SystemConfig[W]]
  set_edges : Array[(SystemSet, SystemSet)]
}

///|
pub fn[W] ScheduleEntry::new() -> ScheduleEntry[W] {
  { systems: [], set_edges: [] }
}

///|
pub struct Schedule[W] {
  entries : @hashmap.HashMap[String, Ref[ScheduleEntry[W]]]
}

///|
pub fn schedule_stage_storage_key(stage : ScheduleStage) -> String {
  match stage {
    Main => "Main"
    PreStartup => "PreStartup"
    Startup => "Startup"
    PostStartup => "PostStartup"
    First => "First"
    PreUpdate => "PreUpdate"
    StateTransition => "StateTransition"
    RunFixedMainLoop => "RunFixedMainLoop"
    FixedFirst => "FixedFirst"
    FixedPreUpdate => "FixedPreUpdate"
    FixedUpdate => "FixedUpdate"
    FixedPostUpdate => "FixedPostUpdate"
    FixedLast => "FixedLast"
    FixedMain => "FixedMain"
    Update => "Update"
    SpawnScene => "SpawnScene"
    PostUpdate => "PostUpdate"
    Last => "Last"
  }
}

///|
fn default_schedule_labels() -> Array[ScheduleStage] {
  [
    Main,
    PreStartup,
    Startup,
    PostStartup,
    First,
    PreUpdate,
    StateTransition,
    RunFixedMainLoop,
    FixedFirst,
    FixedPreUpdate,
    FixedUpdate,
    FixedPostUpdate,
    FixedLast,
    FixedMain,
    Update,
    SpawnScene,
    PostUpdate,
    Last,
  ]
}

///|
fn[W] schedule_entry_ref(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Ref[ScheduleEntry[W]] {
  let key = schedule_stage_storage_key(stage)
  match schedule.entries.get(key) {
    Some(entry_ref) => entry_ref
    None => {
      let entry_ref = Ref::new(ScheduleEntry::new())
      schedule.entries.set(key, entry_ref)
      entry_ref
    }
  }
}

///|
pub fn[W] Schedule::new() -> Schedule[W] {
  let schedule = Schedule::{ entries: @hashmap.HashMap::new() }
  for stage in default_schedule_labels() {
    ignore(schedule_entry_ref(schedule, stage))
  }
  schedule_entry_ref(schedule, RunFixedMainLoop).val.set_edges.push(
    (
      run_fixed_main_loop_system_set_name(BeforeFixedMainLoop),
      run_fixed_main_loop_system_set_name(FixedMainLoop),
    ),
  )
  schedule_entry_ref(schedule, RunFixedMainLoop).val.set_edges.push(
    (
      run_fixed_main_loop_system_set_name(FixedMainLoop),
      run_fixed_main_loop_system_set_name(AfterFixedMainLoop),
    ),
  )
  schedule
}

///|
pub fn[W] schedule_push_config(
  schedule : Schedule[W],
  stage : ScheduleStage,
  config : SystemConfig[W],
) -> Unit {
  schedule_entry_ref(schedule, stage).val.systems.push(config)
}

///|
pub fn[W] schedule_systems(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[SystemConfig[W]] {
  schedule_entry_ref(schedule, stage).val.systems
}

///|
pub fn[W] schedule_set_edges(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[(SystemSet, SystemSet)] {
  schedule_entry_ref(schedule, stage).val.set_edges
}

///|
pub fn[W] SubApp::add_schedule(
  self : SubApp[W],
  stage : ScheduleStage,
) -> SubApp[W] {
  ignore(schedule_entry_ref(self.schedule, stage))
  self
}

///|
pub fn[W] SubApp::add_systems(
  self : SubApp[W],
  schedule : ScheduleStage,
  config : SystemConfig[W],
) -> SubApp[W] {
  schedule_push_config(self.schedule, schedule, config)
  self
}

///|
pub fn[W] SubApp::configure_set(
  self : SubApp[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
) -> SubApp[W] {
  let edges = schedule_set_edges(self.schedule, stage)
  for other in before {
    edges.push((set, other))
  }
  for other in after {
    edges.push((other, set))
  }
  self
}

///|
pub fn[W] SubApp::configure_sets(
  self : SubApp[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
) -> SubApp[W] {
  self.configure_set(stage, set, before~, after~)
}

///|
pub fn[W] App::add_schedule(self : App[W], stage : ScheduleStage) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.add_schedule(stage)
  self
}

///|
pub fn[W] App::add_systems(
  self : App[W],
  schedule : ScheduleStage,
  config : SystemConfig[W],
) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.add_systems(schedule, config)
  self
}

///|
pub fn[W] App::configure_set(
  self : App[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.configure_set(
    stage,
    set,
    before~,
    after~,
  )
  self
}

///|
pub fn[W] App::configure_sets(
  self : App[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
) -> App[W] {
  self.configure_set(stage, set, before~, after~)
}
