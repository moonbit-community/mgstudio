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
pub struct Schedule {
  label : ScheduleStage
  mut executor_kind : ExecutorKind
}

///|
pub fn Schedule::new(label : ScheduleStage) -> Schedule {
  { label, executor_kind: MultiThreaded }
}

///|
pub fn Schedule::label(self : Schedule) -> ScheduleStage {
  self.label
}

///|
pub fn Schedule::get_executor_kind(self : Schedule) -> ExecutorKind {
  self.executor_kind
}

///|
pub fn Schedule::set_executor_kind(
  self : Schedule,
  executor_kind : ExecutorKind,
) -> Schedule {
  self.executor_kind = executor_kind
  self
}

///|
priv struct ScheduleEntry[W] {
  systems : Array[SystemConfig[W]]
  set_edges : Array[(SystemSet, SystemSet)]
  mut executor_kind : ExecutorKind
  mut chain_internal_set_counter : Int
}

///|
fn[W] ScheduleEntry::new() -> ScheduleEntry[W] {
  {
    systems: [],
    set_edges: [],
    executor_kind: MultiThreaded,
    chain_internal_set_counter: 0,
  }
}

///|
struct ScheduleRegistry[W] {
  entries : @hashmap.HashMap[String, Ref[ScheduleEntry[W]]]
}

///|
fn schedule_stage_storage_key(stage : ScheduleStage) -> String {
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
    Custom(name) => "__custom__:\{name}"
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
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Ref[ScheduleEntry[W]] {
  let key = schedule_stage_storage_key(stage)
  match schedule_registry.entries.get(key) {
    Some(entry_ref) => entry_ref
    None => {
      let entry_ref = Ref::new(ScheduleEntry::new())
      schedule_registry.entries.set(key, entry_ref)
      entry_ref
    }
  }
}

///|
fn[W] ScheduleRegistry::new() -> ScheduleRegistry[W] {
  let schedule = ScheduleRegistry::{ entries: @hashmap.HashMap::new() }
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
fn[W] schedule_next_chain_internal_set(
  schedule_entry : ScheduleEntry[W],
  stage : ScheduleStage,
) -> SystemSet {
  let next_id = schedule_entry.chain_internal_set_counter
  schedule_entry.chain_internal_set_counter = next_id + 1
  "__chain__:\{schedule_stage_storage_key(stage)}:\{next_id.to_string()}"
}

///|
fn[W] schedule_chain_inherit_config(
  child : SystemConfig[W],
  wrapper : SystemConfig[W],
) -> SystemConfig[W] {
  let inherited_error_handler = match child.error_handler {
    Some(_) => child.error_handler
    None => wrapper.error_handler
  }
  let inherited_set = match child.set {
    Some(_) => child.set
    None => wrapper.set
  }
  let run_ifs : Array[StatefulRunConditionFn[W]] = []
  for cond in child.run_ifs {
    run_ifs.push(cond)
  }
  for cond in wrapper.run_ifs {
    run_ifs.push(cond)
  }
  let run_if_states : Array[Ref[Json]] = []
  for state in child.run_if_states {
    run_if_states.push(state)
  }
  for state in wrapper.run_if_states {
    run_if_states.push(Ref::new(state.val))
  }
  let before : Array[SystemSet] = []
  for set in child.before {
    before.push(set)
  }
  for set in wrapper.before {
    before.push(set)
  }
  let after : Array[SystemSet] = []
  for set in child.after {
    after.push(set)
  }
  for set in wrapper.after {
    after.push(set)
  }
  let run_if_last_run_sequences : Array[@core.Sequence] = []
  for sequence in child.run_if_last_run_sequences {
    run_if_last_run_sequences.push(sequence)
  }
  for _ in wrapper.run_if_last_run_sequences {
    run_if_last_run_sequences.push(0)
  }
  SystemConfig::{
    ..child,
    error_handler: inherited_error_handler,
    run_ifs,
    run_if_states,
    set: inherited_set,
    before,
    after,
    run_if_last_run_sequences,
  }
}

///|
fn[W] schedule_collect_expanded_chain_members(
  config : SystemConfig[W],
  out : Array[SystemConfig[W]],
) -> Unit {
  match config.chain_members {
    Some(members) =>
      for child_config in members {
        let inherited = schedule_chain_inherit_config(child_config, config)
        schedule_collect_expanded_chain_members(inherited, out)
      }
    None => out.push(config)
  }
}

///|
fn[W] schedule_push_config(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  config : SystemConfig[W],
) -> Unit {
  let entry_ref = schedule_entry_ref(schedule_registry, stage)
  match config.chain_members {
    Some(_) => {
      let expanded_members : Array[SystemConfig[W]] = []
      schedule_collect_expanded_chain_members(config, expanded_members)
      if expanded_members.length() == 0 {
        return
      }
      let normalized_members : Array[SystemConfig[W]] = []
      for child_config in expanded_members {
        let normalized_member = match child_config.set {
          Some(_) => child_config
          None =>
            SystemConfig::{
              ..child_config,
              set: Some(
                schedule_next_chain_internal_set(entry_ref.val, stage),
              ),
            }
        }
        normalized_members.push(normalized_member)
        entry_ref.val.systems.push(normalized_member)
      }
      if normalized_members.length() <= 1 {
        return
      }
      for i in 0..<(normalized_members.length() - 1) {
        guard normalized_members[i].set is Some(left_set) else { continue }
        guard normalized_members[i + 1].set is Some(right_set) else { continue }
        if left_set != right_set {
          entry_ref.val.set_edges.push((left_set, right_set))
        }
      }
    }
    None => entry_ref.val.systems.push(config)
  }
}

///|
fn[W] schedule_systems(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Array[SystemConfig[W]] {
  schedule_entry_ref(schedule_registry, stage).val.systems
}

///|
fn[W] schedule_set_edges(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Array[(SystemSet, SystemSet)] {
  schedule_entry_ref(schedule_registry, stage).val.set_edges
}

///|
fn[W] schedule_set_executor_kind(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  executor_kind : ExecutorKind,
) -> Unit {
  schedule_entry_ref(schedule_registry, stage).val.executor_kind = executor_kind
}

///|
fn[W] schedule_executor_kind(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> ExecutorKind {
  schedule_entry_ref(schedule_registry, stage).val.executor_kind
}

///|
pub fn[W] SubApp::add_schedule(
  self : SubApp[W],
  schedule : Schedule,
) -> SubApp[W] {
  schedule_set_executor_kind(
    self.schedule,
    schedule.label(),
    schedule.get_executor_kind(),
  )
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
pub fn[W] App::add_schedule(self : App[W], schedule : Schedule) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.add_schedule(schedule)
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
