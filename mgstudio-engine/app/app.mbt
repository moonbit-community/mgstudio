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
pub type SystemFn[W] = (W) -> Unit

///|
pub type Plugin[W] = (App[W]) -> App[W]

///|
pub type RunConditionFn[W] = (W) -> Bool

///|
pub type SystemSet = String

///|
pub fn system_set(name : String) -> SystemSet {
  name
}

///|
pub(all) enum ScheduleStage {
  Startup
  PreUpdate
  FixedUpdate
  Update
  PostUpdate
} derive(Eq, Show)

///|
pub(open) trait SystemParam {
  get() -> Self
}

///|
pub fn[W, P : SystemParam] system_param(system : (P) -> Unit) -> SystemFn[W] {
  fn(_world : W) {
    let param : P = SystemParam::get()
    system(param)
  }
}

///|
pub struct SystemConfig[W] {
  system : SystemFn[W]
  run_if : RunConditionFn[W]?
  set : SystemSet?
  before : Array[SystemSet]
  after : Array[SystemSet]
}

///|
pub fn[W] system(system : SystemFn[W]) -> SystemConfig[W] {
  SystemConfig::{ system, run_if: None, set: None, before: [], after: [] }
}

///|
pub fn[W] SystemConfig::run_if(
  self : SystemConfig[W],
  cond : RunConditionFn[W],
) -> SystemConfig[W] {
  SystemConfig::{ ..self, run_if: Some(cond) }
}

///|
pub fn[W] SystemConfig::in_set(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  SystemConfig::{ ..self, set: Some(set) }
}

///|
pub fn[W] SystemConfig::before(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  self.before.push(set)
  self
}

///|
pub fn[W] SystemConfig::after(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  self.after.push(set)
  self
}

///|
pub type DeltaSecondsFn = () -> Float

///|
pub type RunnerFn = () -> Unit

///|
pub type RunnerBuilder[W] = (App[W]) -> RunnerFn

///|
pub struct Schedule[W] {
  startup : Array[SystemConfig[W]]
  pre_update : Array[SystemConfig[W]]
  fixed_update : Array[SystemConfig[W]]
  update : Array[SystemConfig[W]]
  post_update : Array[SystemConfig[W]]
  startup_set_edges : Array[(SystemSet, SystemSet)]
  pre_update_set_edges : Array[(SystemSet, SystemSet)]
  fixed_update_set_edges : Array[(SystemSet, SystemSet)]
  update_set_edges : Array[(SystemSet, SystemSet)]
  post_update_set_edges : Array[(SystemSet, SystemSet)]
}

///|
pub struct App[W] {
  world : W
  schedule : Schedule[W]
  runner : RunnerFn?
}

///|
pub fn[W] App::new(world : W) -> App[W] {
  App::{
    world,
    schedule: Schedule::{
      startup: [],
      pre_update: [],
      fixed_update: [],
      update: [],
      post_update: [],
      startup_set_edges: [],
      pre_update_set_edges: [],
      fixed_update_set_edges: [],
      update_set_edges: [],
      post_update_set_edges: [],
    },
    runner: None,
  }
}

///|
pub fn[W] App::add_plugins(self : App[W], plugins : Array[Plugin[W]]) -> App[W] {
  let mut app = self
  for plugin in plugins {
    app = plugin(app)
  }
  app
}

///|
pub fn[W] App::add_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.startup.push(config)
  self
}

///|
pub fn[W] App::add_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.startup.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_startup_system_param(
  self : App[W],
  startup_system : (P) -> Unit,
) -> App[W] {
  self.schedule.startup.push(system(system_param(startup_system)))
  self
}

///|
pub fn[W] App::add_pre_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.pre_update.push(config)
  self
}

///|
pub fn[W] App::add_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.pre_update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_pre_update_system_param(
  self : App[W],
  pre_update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.pre_update.push(system(system_param(pre_update_system)))
  self
}

///|
pub fn[W] App::add_fixed_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.fixed_update.push(config)
  self
}

///|
pub fn[W] App::add_fixed_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.fixed_update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_update_system_param(
  self : App[W],
  fixed_update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.fixed_update.push(system(system_param(fixed_update_system)))
  self
}

///|
pub fn[W] App::add_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.update.push(config)
  self
}

///|
pub fn[W] App::add_system(self : App[W], system_fn : SystemFn[W]) -> App[W] {
  self.schedule.update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_system_param(
  self : App[W],
  update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.update.push(system(system_param(update_system)))
  self
}

///|
pub fn[W] App::add_post_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.post_update.push(config)
  self
}

///|
pub fn[W] App::add_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.post_update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_post_update_system_param(
  self : App[W],
  post_update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.post_update.push(system(system_param(post_update_system)))
  self
}

///|
fn[W] schedule_systems(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[SystemConfig[W]] {
  match stage {
    Startup => schedule.startup
    PreUpdate => schedule.pre_update
    FixedUpdate => schedule.fixed_update
    Update => schedule.update
    PostUpdate => schedule.post_update
  }
}

///|
fn[W] schedule_set_edges(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[(SystemSet, SystemSet)] {
  match stage {
    Startup => schedule.startup_set_edges
    PreUpdate => schedule.pre_update_set_edges
    FixedUpdate => schedule.fixed_update_set_edges
    Update => schedule.update_set_edges
    PostUpdate => schedule.post_update_set_edges
  }
}

///|
pub fn[W] App::configure_set(
  self : App[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
) -> App[W] {
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
priv struct FixedTimeState {
  mut timestep_seconds : Float
  mut max_delta_seconds : Float
  mut overstep_seconds : Float
  mut elapsed_seconds : Float
  mut did_run_this_frame : Bool
  mut steps_ran_this_frame : Int
}

///|
const DEFAULT_FIXED_TIMESTEP_SECONDS : Float = 0.015625F

///|
const DEFAULT_FIXED_MAX_DELTA_SECONDS : Float = 0.25F

///|
let fixed_time_state : Ref[FixedTimeState] = Ref::new(FixedTimeState::{
  timestep_seconds: DEFAULT_FIXED_TIMESTEP_SECONDS,
  max_delta_seconds: DEFAULT_FIXED_MAX_DELTA_SECONDS,
  overstep_seconds: 0.0F,
  elapsed_seconds: 0.0F,
  did_run_this_frame: false,
  steps_ran_this_frame: 0,
})

///|
let delta_seconds_provider : Ref[DeltaSecondsFn?] = Ref::new(None)

///|
pub fn set_delta_seconds_provider(provider : DeltaSecondsFn) -> Unit {
  delta_seconds_provider.val = Some(provider)
}

///|
pub fn clear_delta_seconds_provider() -> Unit {
  delta_seconds_provider.val = None
}

///|
pub fn fixed_time_reset() -> Unit {
  fixed_time_state.val.overstep_seconds = 0.0F
  fixed_time_state.val.elapsed_seconds = 0.0F
  fixed_time_state.val.did_run_this_frame = false
  fixed_time_state.val.steps_ran_this_frame = 0
}

///|
pub fn fixed_time_set_timestep_seconds(seconds : Float) -> Unit {
  if seconds > 0.0F {
    fixed_time_state.val.timestep_seconds = seconds
  }
}

///|
pub fn fixed_time_set_max_delta_seconds(seconds : Float) -> Unit {
  if seconds > 0.0F {
    fixed_time_state.val.max_delta_seconds = seconds
  }
}

///|
pub fn fixed_time_timestep_seconds() -> Float {
  fixed_time_state.val.timestep_seconds
}

///|
pub fn fixed_time_overstep_seconds() -> Float {
  fixed_time_state.val.overstep_seconds
}

///|
pub fn fixed_time_elapsed_seconds() -> Float {
  fixed_time_state.val.elapsed_seconds
}

///|
pub fn fixed_time_overstep_fraction() -> Float {
  let timestep = fixed_time_state.val.timestep_seconds
  if timestep <= 0.0F {
    0.0F
  } else {
    fixed_time_state.val.overstep_seconds / timestep
  }
}

///|
pub fn fixed_time_did_run_this_frame() -> Bool {
  fixed_time_state.val.did_run_this_frame
}

///|
pub fn fixed_time_steps_ran_this_frame() -> Int {
  fixed_time_state.val.steps_ran_this_frame
}

///|
fn[W] run_systems(
  world : W,
  systems : Array[SystemConfig[W]],
  set_edges : Array[(SystemSet, SystemSet)],
) -> Unit {
  let seen : @hashmap.HashMap[SystemSet, Bool] = @hashmap.HashMap::new()
  let set_order : Array[SystemSet] = []
  fn push_unique(
    seen : @hashmap.HashMap[SystemSet, Bool],
    set_order : Array[SystemSet],
    set : SystemSet,
  ) -> Unit {
    if !seen.contains(set) {
      set_order.push(set)
      seen.set(set, true)
    }
  }

  let system_count = systems.length()
  let groups : Array[SystemSet] = []
  for i in 0..<system_count {
    let cfg = systems[i]
    let set = if cfg.set is Some(s) { s } else { "__anon#" + i.to_string() }
    groups.push(set)
    push_unique(seen, set_order, set)
    for other in cfg.before {
      push_unique(seen, set_order, other)
    }
    for other in cfg.after {
      push_unique(seen, set_order, other)
    }
  }
  for edge in set_edges {
    push_unique(seen, set_order, edge.0)
    push_unique(seen, set_order, edge.1)
  }
  let set_count = set_order.length()
  let set_index : @hashmap.HashMap[SystemSet, Int] = @hashmap.HashMap::new()
  for i in 0..<set_count {
    set_index.set(set_order[i], i)
  }
  let indeg : Array[Int] = []
  let adj : Array[Array[Int]] = []
  for _ in 0..<set_count {
    indeg.push(0)
    adj.push([])
  }
  fn add_edge(
    set_index : @hashmap.HashMap[SystemSet, Int],
    indeg : Array[Int],
    adj : Array[Array[Int]],
    from : SystemSet,
    to : SystemSet,
  ) -> Unit {
    let from_i = set_index.at(from)
    let to_i = set_index.at(to)
    adj[from_i].push(to_i)
    indeg[to_i] = indeg[to_i] + 1
  }

  for edge in set_edges {
    add_edge(set_index, indeg, adj, edge.0, edge.1)
  }
  for i in 0..<system_count {
    let cfg = systems[i]
    let group = groups[i]
    for other in cfg.before {
      add_edge(set_index, indeg, adj, group, other)
    }
    for other in cfg.after {
      add_edge(set_index, indeg, adj, other, group)
    }
  }
  fn pop_smallest(ready : Array[Int]) -> Int {
    let mut best_pos = 0
    let mut best_value = ready[0]
    let len = ready.length()
    for i in 1..<len {
      let value = ready[i]
      if value < best_value {
        best_value = value
        best_pos = i
      }
    }
    let last_index = ready.length() - 1
    ready[best_pos] = ready[last_index]
    ready.pop().unwrap() |> ignore
    best_value
  }

  let ready : Array[Int] = []
  for i in 0..<set_count {
    if indeg[i] == 0 {
      ready.push(i)
    }
  }
  let topo : Array[Int] = []
  while ready.length() > 0 {
    let next = pop_smallest(ready)
    topo.push(next)
    for to in adj[next] {
      indeg[to] = indeg[to] - 1
      if indeg[to] == 0 {
        ready.push(to)
      }
    }
  }

  // Cycle fallback: preserve first-seen order.
  if topo.length() != set_count {
    topo.clear()
    for i in 0..<set_count {
      topo.push(i)
    }
  }
  let systems_by_set : Array[Array[Int]] = []
  for _ in 0..<set_count {
    systems_by_set.push([])
  }
  for i in 0..<system_count {
    let set_i = set_index.at(groups[i])
    systems_by_set[set_i].push(i)
  }
  for set_i in topo {
    for system_i in systems_by_set[set_i] {
      let cfg = systems[system_i]
      if cfg.run_if is Some(cond) {
        if !cond(world) {
          continue
        }
      }
      (cfg.system)(world)
    }
  }
}

///|
pub fn[W] App::run_startup(self : App[W]) -> App[W] {
  run_systems(
    self.world,
    schedule_systems(self.schedule, Startup),
    schedule_set_edges(self.schedule, Startup),
  )
  self
}

///|
pub fn[W] App::run_once(self : App[W]) -> App[W] {
  run_systems(
    self.world,
    schedule_systems(self.schedule, PreUpdate),
    schedule_set_edges(self.schedule, PreUpdate),
  )
  fixed_time_state.val.did_run_this_frame = false
  fixed_time_state.val.steps_ran_this_frame = 0
  let delta_raw = match delta_seconds_provider.val {
    Some(provider) => provider()
    None => 0.0F
  }
  let delta_non_negative = if delta_raw < 0.0F { 0.0F } else { delta_raw }
  let max_delta = fixed_time_state.val.max_delta_seconds
  let delta = if delta_non_negative > max_delta {
    max_delta
  } else {
    delta_non_negative
  }
  fixed_time_state.val.overstep_seconds = fixed_time_state.val.overstep_seconds +
    delta
  let timestep = fixed_time_state.val.timestep_seconds
  if timestep > 0.0F {
    let fixed_systems = schedule_systems(self.schedule, FixedUpdate)
    let fixed_edges = schedule_set_edges(self.schedule, FixedUpdate)
    let eps = 0.0000001F
    while fixed_time_state.val.overstep_seconds + eps >= timestep {
      fixed_time_state.val.overstep_seconds = fixed_time_state.val.overstep_seconds -
        timestep
      fixed_time_state.val.elapsed_seconds = fixed_time_state.val.elapsed_seconds +
        timestep
      fixed_time_state.val.did_run_this_frame = true
      fixed_time_state.val.steps_ran_this_frame = fixed_time_state.val.steps_ran_this_frame +
        1
      run_systems(self.world, fixed_systems, fixed_edges)
    }
  }
  run_systems(
    self.world,
    schedule_systems(self.schedule, Update),
    schedule_set_edges(self.schedule, Update),
  )
  run_systems(
    self.world,
    schedule_systems(self.schedule, PostUpdate),
    schedule_set_edges(self.schedule, PostUpdate),
  )
  self
}

///|
pub fn[W] App::run(self : App[W]) -> Unit {
  if self.runner is Some(runner) {
    runner()
  } else {
    self.run_startup().run_once() |> ignore
  }
}

///|
pub fn[W] App::set_runner(self : App[W], builder : RunnerBuilder[W]) -> App[W] {
  let runner = builder(self)
  App::{ ..self, runner: Some(runner) }
}
