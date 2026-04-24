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
pub(all) enum SteppingAction {
  RunAll
  Waiting
  Continue
  Step
} derive(Eq, Debug)

///|
pub(all) enum SystemSteppingBehavior {
  AlwaysRun
  NeverRun
  Break
  Continue
} derive(Eq, Debug)

///|
priv struct SteppingScheduleState {
  behaviors : @hashmap.HashMap[String, SystemSteppingBehavior]
}

///|
struct Stepping {
  mut action : SteppingAction
  schedules : Array[ScheduleStage]
  schedule_states : @hashmap.HashMap[String, Ref[SteppingScheduleState]]
  mut cursor_schedule : Int
  mut cursor_system : Int
  mut continue_started : Bool
  updates : Array[SteppingUpdate]
}

///|
priv enum SteppingUpdate {
  SetAction(SteppingAction)
  AddSchedule(ScheduleStage)
  RemoveSchedule(ScheduleStage)
  ClearSchedule(ScheduleStage)
  SetBehavior(ScheduleStage, String, SystemSteppingBehavior)
  ClearBehavior(ScheduleStage, String)
}

///|
let stepping_resource_key : @ecs.ResourceKey[Stepping] = @ecs.register_resource(
  debug_name="mgstudio_ecs::schedule::Stepping",
)

///|
pub impl Resource for Stepping with resource() {
  stepping_resource_key
}

///|
pub fn Stepping::new() -> Stepping {
  Stepping::{
    action: RunAll,
    schedules: [],
    schedule_states: @hashmap.HashMap::new(),
    cursor_schedule: 0,
    cursor_system: 0,
    continue_started: false,
    updates: [],
  }
}

///|
pub fn Stepping::add_schedule(
  self : Stepping,
  schedule : ScheduleStage,
) -> Stepping {
  self.updates.push(AddSchedule(schedule))
  self
}

///|
pub fn Stepping::remove_schedule(
  self : Stepping,
  schedule : ScheduleStage,
) -> Stepping {
  self.updates.push(RemoveSchedule(schedule))
  self
}

///|
pub fn Stepping::clear_schedule(
  self : Stepping,
  schedule : ScheduleStage,
) -> Stepping {
  self.updates.push(ClearSchedule(schedule))
  self
}

///|
pub fn Stepping::enable(self : Stepping) -> Stepping {
  self.updates.push(SetAction(Waiting))
  self
}

///|
pub fn Stepping::disable(self : Stepping) -> Stepping {
  self.updates.push(SetAction(RunAll))
  self
}

///|
pub fn Stepping::is_enabled(self : Stepping) -> Bool {
  self.action != RunAll
}

///|
pub fn Stepping::step_frame(self : Stepping) -> Stepping {
  self.updates.push(SetAction(Step))
  self
}

///|
pub fn Stepping::continue_frame(self : Stepping) -> Stepping {
  self.updates.push(SetAction(Continue))
  self
}

///|
pub fn Stepping::always_run(
  self : Stepping,
  schedule : ScheduleStage,
  system_name : String,
) -> Stepping {
  self.updates.push(SetBehavior(schedule, system_name, AlwaysRun))
  self
}

///|
pub fn Stepping::never_run(
  self : Stepping,
  schedule : ScheduleStage,
  system_name : String,
) -> Stepping {
  self.updates.push(SetBehavior(schedule, system_name, NeverRun))
  self
}

///|
pub fn Stepping::set_breakpoint(
  self : Stepping,
  schedule : ScheduleStage,
  system_name : String,
) -> Stepping {
  self.updates.push(SetBehavior(schedule, system_name, Break))
  self
}

///|
pub fn Stepping::clear_breakpoint(
  self : Stepping,
  schedule : ScheduleStage,
  system_name : String,
) -> Stepping {
  self.updates.push(ClearBehavior(schedule, system_name))
  self
}

///|
pub fn Stepping::schedules(self : Stepping) -> Array[ScheduleStage] {
  self.schedules
}

///|
pub fn Stepping::cursor(self : Stepping) -> (ScheduleStage, Int)? {
  guard self.action != RunAll else { return None }
  guard self.cursor_schedule >= 0 &&
    self.cursor_schedule < self.schedules.length() else {
    return None
  }
  Some((self.schedules[self.cursor_schedule], self.cursor_system))
}

///|
fn stepping_schedule_key(schedule : ScheduleStage) -> String {
  to_repr(schedule).to_string()
}

///|
fn schedule_index(
  schedules : Array[ScheduleStage],
  schedule : ScheduleStage,
) -> Int? {
  for i in 0..<schedules.length() {
    if schedules[i] == schedule {
      return Some(i)
    }
  }
  None
}

///|
fn ensure_schedule_state(
  stepping : Stepping,
  schedule : ScheduleStage,
) -> Ref[SteppingScheduleState] {
  let key = stepping_schedule_key(schedule)
  match stepping.schedule_states.get(key) {
    Some(state_ref) => state_ref
    None => {
      let state_ref = Ref::new({ behaviors: @hashmap.HashMap::new() })
      stepping.schedule_states.set(key, state_ref)
      state_ref
    }
  }
}

///|
fn clear_schedule_state(stepping : Stepping, schedule : ScheduleStage) -> Unit {
  let key = stepping_schedule_key(schedule)
  if stepping.schedule_states.get(key) is Some(state_ref) {
    state_ref.val.behaviors.clear()
  }
}

///|
fn remove_schedule_entry(
  schedules : Array[ScheduleStage],
  schedule : ScheduleStage,
) -> Bool {
  for i in 0..<schedules.length() {
    if schedules[i] == schedule {
      schedules.remove(i) |> ignore
      return true
    }
  }
  false
}

///|
fn stepping_apply_updates(stepping : Stepping) -> Unit {
  let mut reset_cursor = false
  for update in stepping.updates {
    match update {
      SetAction(RunAll) => {
        stepping.action = RunAll
        reset_cursor = true
      }
      SetAction(Waiting) =>
        if stepping.action == RunAll {
          stepping.action = Waiting
        }
      SetAction(Step) =>
        if stepping.action != RunAll && stepping.action != Continue {
          stepping.action = Step
        }
      SetAction(Continue) =>
        if stepping.action != RunAll && stepping.action != Step {
          stepping.action = Continue
        }
      AddSchedule(schedule) => {
        if schedule_index(stepping.schedules, schedule) is None {
          stepping.schedules.push(schedule)
        }
        ignore(ensure_schedule_state(stepping, schedule))
      }
      RemoveSchedule(schedule) => {
        if remove_schedule_entry(stepping.schedules, schedule) {
          reset_cursor = true
        }
        stepping.schedule_states.remove(stepping_schedule_key(schedule))
      }
      ClearSchedule(schedule) => clear_schedule_state(stepping, schedule)
      SetBehavior(schedule, system_name, behavior) => {
        let state_ref = ensure_schedule_state(stepping, schedule)
        state_ref.val.behaviors.set(system_name, behavior)
      }
      ClearBehavior(schedule, system_name) => {
        let key = stepping_schedule_key(schedule)
        if stepping.schedule_states.get(key) is Some(state_ref) {
          state_ref.val.behaviors.remove(system_name)
        }
      }
    }
  }
  stepping.updates.clear()
  if reset_cursor {
    stepping.cursor_schedule = 0
    stepping.cursor_system = 0
  }
}

///|
fn stepping_next_frame(stepping : Stepping) -> Unit {
  if stepping.action != RunAll {
    stepping.action = Waiting
    stepping.continue_started = false
    if stepping.cursor_schedule >= stepping.schedules.length() {
      stepping.cursor_schedule = 0
      stepping.cursor_system = 0
    }
  }
  stepping_apply_updates(stepping)
}

///|
fn stepping_behavior_for(
  stepping : Stepping,
  schedule : ScheduleStage,
  system_name : String,
) -> SystemSteppingBehavior {
  let key = stepping_schedule_key(schedule)
  match stepping.schedule_states.get(key) {
    Some(state_ref) =>
      match state_ref.val.behaviors.get(system_name) {
        Some(behavior) => behavior
        None => Continue
      }
    None => Continue
  }
}

///|
fn stepping_advance_cursor(
  stepping : Stepping,
  schedule_index : Int,
  next_system : Int,
) -> Unit {
  stepping.cursor_schedule = schedule_index
  stepping.cursor_system = next_system
}

///|
fn stepping_resource_mut(world : @ecs.World) -> @ecs.ResourceMut[Stepping]? {
  try world.get_resource_mut(Stepping::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn system_config_name(
  config : SystemConfig[@ecs.World],
  system_index : Int,
) -> String {
  match config.name {
    Some(name) => name
    None =>
      match config.set {
        Some(set_name) =>
          if set_name.has_prefix("__chain__:") {
            "__anon_system#\{system_index.to_string()}"
          } else {
            set_name
          }
        None => "__anon_system#\{system_index.to_string()}"
      }
  }
}

///|
fn schedule_execution_node_name(
  systems : Array[SystemConfig[@ecs.World]],
  node : ScheduleExecutionNode,
) -> String {
  match node {
    ScheduledSystem(system_i) => system_config_name(systems[system_i], system_i)
  }
}

///|
fn stepping_begin_frame(world : @ecs.World) -> Unit {
  if stepping_resource_mut(world) is Some(stepping) {
    stepping.modify(fn(value) { stepping_next_frame(value) })
  }
}

///|
fn stepping_prepare_stage(
  stepping_ref : @ecs.ResourceMut[Stepping]?,
  stage : ScheduleStage?,
  systems : Array[SystemConfig[@ecs.World]],
  execution_order : Array[ScheduleExecutionNode],
) -> Unit {
  guard stage is Some(schedule) else { return }
  guard stepping_ref is Some(resource_ref) else { return }
  let stepping = resource_ref.peek()
  guard schedule_index(stepping.schedules, schedule) is Some(stage_index) else {
    return
  }
  if stepping.action == RunAll || stage_index != stepping.cursor_schedule {
    return
  }
  while stepping.cursor_system < execution_order.length() {
    let system_name = schedule_execution_node_name(
      systems,
      execution_order[stepping.cursor_system],
    )
    match stepping_behavior_for(stepping, schedule, system_name) {
      AlwaysRun | NeverRun =>
        stepping.cursor_system = stepping.cursor_system + 1
      _ => break
    }
  }
  if stepping.cursor_system >= execution_order.length() {
    stepping.cursor_schedule = stage_index + 1
    stepping.cursor_system = 0
  }
}

///|
fn stepping_should_run_system(
  stepping_ref : @ecs.ResourceMut[Stepping]?,
  stage : ScheduleStage?,
  systems : Array[SystemConfig[@ecs.World]],
  node : ScheduleExecutionNode,
  execution_index : Int,
) -> Bool {
  guard stage is Some(schedule) else { return true }
  guard stepping_ref is Some(resource_ref) else { return true }
  resource_ref.modify(fn(stepping) {
    guard schedule_index(stepping.schedules, schedule) is Some(stage_index) else {
      return true
    }
    let system_name = schedule_execution_node_name(systems, node)
    let behavior = stepping_behavior_for(stepping, schedule, system_name)
    guard stepping.action != RunAll else { return true }
    match behavior {
      AlwaysRun => true
      NeverRun => false
      Break =>
        match stepping.action {
          Waiting => false
          Step =>
            stage_index == stepping.cursor_schedule &&
            execution_index == stepping.cursor_system
          Continue =>
            if stage_index < stepping.cursor_schedule {
              false
            } else if stage_index == stepping.cursor_schedule &&
              execution_index < stepping.cursor_system {
              false
            } else if stepping.continue_started {
              stepping.action = Waiting
              false
            } else {
              true
            }
          RunAll => true
        }
      Continue =>
        match stepping.action {
          Waiting => false
          Step =>
            stage_index == stepping.cursor_schedule &&
            execution_index == stepping.cursor_system
          Continue =>
            if stage_index < stepping.cursor_schedule {
              false
            } else if stage_index == stepping.cursor_schedule &&
              execution_index < stepping.cursor_system {
              false
            } else {
              true
            }
          RunAll => true
        }
    }
  })
}

///|
fn stepping_record_system_run(
  stepping_ref : @ecs.ResourceMut[Stepping]?,
  stage : ScheduleStage?,
  systems : Array[SystemConfig[@ecs.World]],
  node : ScheduleExecutionNode,
  execution_index : Int,
) -> Unit {
  guard stage is Some(schedule) else { return }
  guard stepping_ref is Some(resource_ref) else { return }
  ignore(
    resource_ref.modify(fn(stepping) {
      guard schedule_index(stepping.schedules, schedule) is Some(stage_index) else {
        return ()
      }
      guard stepping.action != RunAll else { return () }
      let system_name = schedule_execution_node_name(systems, node)
      match stepping_behavior_for(stepping, schedule, system_name) {
        AlwaysRun | NeverRun => ()
        Break | Continue =>
          match stepping.action {
            Step => {
              stepping_advance_cursor(
                stepping,
                stage_index,
                execution_index + 1,
              )
              stepping.action = Waiting
            }
            Continue => {
              stepping.continue_started = true
              stepping_advance_cursor(
                stepping,
                stage_index,
                execution_index + 1,
              )
            }
            Waiting | RunAll => ()
          }
      }
    }),
  )
}

///|
fn stepping_finish_stage(
  stepping_ref : @ecs.ResourceMut[Stepping]?,
  stage : ScheduleStage?,
  stage_system_count : Int,
) -> Unit {
  guard stage is Some(schedule) else { return }
  guard stepping_ref is Some(resource_ref) else { return }
  ignore(
    resource_ref.modify(fn(stepping) {
      guard schedule_index(stepping.schedules, schedule) is Some(stage_index) else {
        return ()
      }
      if stepping.cursor_schedule == stage_index &&
        stepping.cursor_system >= stage_system_count {
        stepping.cursor_schedule = stage_index + 1
        stepping.cursor_system = 0
      }
    }),
  )
}
