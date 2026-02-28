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
pub struct PluginGroupBuilder[W] {
  plugins : Array[Plugin[W]]
}

///|
pub fn[W] PluginGroupBuilder::start() -> PluginGroupBuilder[W] {
  { plugins: [] }
}

///|
pub fn[W] PluginGroupBuilder::add(
  self : PluginGroupBuilder[W],
  plugin : Plugin[W],
) -> PluginGroupBuilder[W] {
  self.plugins.push(plugin)
  self
}

///|
pub fn[W] PluginGroupBuilder::build(
  self : PluginGroupBuilder[W],
) -> Array[Plugin[W]] {
  self.plugins
}

///|
pub type PluginGroup[W] = () -> PluginGroupBuilder[W]

///|
pub type RunConditionFn[W] = (W) -> Bool

///|
pub type SystemSet = String

///|
pub fn system_set(name : String) -> SystemSet {
  name
}

///|
pub(all) enum AppLabel {
  MainApp
  RenderApp
  Custom(String)
} derive(Eq, Show)

///|
pub fn app_label(name : String) -> AppLabel {
  Custom(name)
}

///|
fn app_label_storage_key(label : AppLabel) -> String {
  match label {
    MainApp => "__main__"
    RenderApp => "__render__"
    Custom(name) => "__custom__:" + name
  }
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
pub(open) trait Resource {
  resource() -> @core.Resource[Self]
}

///|
pub struct Res[T] {
  value : T
}

///|
pub fn[T] Res::get(self : Res[T]) -> T {
  self.value
}

///|
pub struct ResMut[T] {
  value : Ref[T]
}

///|
pub fn[T] ResMut::get_ref(self : ResMut[T]) -> Ref[T] {
  self.value
}

///|
fn[T] system_param_abort_missing_resource() -> T {
  abort("Missing resource for system parameter")
}

///|
pub fn[W, P : SystemParam] system_param(system : (P) -> Unit) -> SystemFn[W] {
  fn(_world : W) {
    let param : P = SystemParam::get()
    system(param)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] system_param2(
  system : (P1, P2) -> Unit,
) -> SystemFn[W] {
  fn(_world : W) {
    let p1 : P1 = SystemParam::get()
    let p2 : P2 = SystemParam::get()
    system(p1, p2)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] system_param3(
  system : (P1, P2, P3) -> Unit,
) -> SystemFn[W] {
  fn(_world : W) {
    let p1 : P1 = SystemParam::get()
    let p2 : P2 = SystemParam::get()
    let p3 : P3 = SystemParam::get()
    system(p1, p2, p3)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] system_param4(
  system : (P1, P2, P3, P4) -> Unit,
) -> SystemFn[W] {
  fn(_world : W) {
    let p1 : P1 = SystemParam::get()
    let p2 : P2 = SystemParam::get()
    let p3 : P3 = SystemParam::get()
    let p4 : P4 = SystemParam::get()
    system(p1, p2, p3, p4)
  }
}

///|
pub type QueryGetter[W, T] = (W) -> @core.ComponentStore[T]

///|
pub fn[W, A] system_query1(
  get_a : QueryGetter[W, A],
  system : (@core.Query1[A], W) -> Unit,
) -> SystemFn[W] {
  fn(world : W) { system(@core.Query1::new(get_a(world)), world) }
}

///|
pub fn[W, A, B] system_query2(
  get_a : QueryGetter[W, A],
  get_b : QueryGetter[W, B],
  system : (@core.Query2[A, B], W) -> Unit,
) -> SystemFn[W] {
  fn(world : W) { system(@core.Query2::new(get_a(world), get_b(world)), world) }
}

///|
pub fn[W, A, B, C] system_query3(
  get_a : QueryGetter[W, A],
  get_b : QueryGetter[W, B],
  get_c : QueryGetter[W, C],
  system : (@core.Query3[A, B, C], W) -> Unit,
) -> SystemFn[W] {
  fn(world : W) {
    system(@core.Query3::new(get_a(world), get_b(world), get_c(world)), world)
  }
}

///|
let current_system_ticks_ref : Ref[@core.SystemTicks?] = Ref::new(None)

///|
pub fn current_system_ticks() -> @core.SystemTicks {
  match current_system_ticks_ref.val {
    Some(ticks) => ticks
    None => @core.SystemTicks::new(0, 0)
  }
}

///|
let current_schedule_stage_ref : Ref[ScheduleStage?] = Ref::new(None)

///|
pub fn current_schedule_stage() -> ScheduleStage? {
  current_schedule_stage_ref.val
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with get() {
  @core.Message::reader(current_system_ticks())
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with get() {
  @core.Message::writer(current_system_ticks().this_run)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with get() {
  match Resource::resource().get() {
    Some(value) => Res::{ value, }
    None => system_param_abort_missing_resource()
  }
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with get() {
  let tick = current_system_ticks().this_run
  match Resource::resource().get_ref_mut(tick) {
    Some(value) => ResMut::{ value, }
    None => system_param_abort_missing_resource()
  }
}

///|
pub struct SystemConfig[W] {
  system : SystemFn[W]
  run_if : RunConditionFn[W]?
  set : SystemSet?
  before : Array[SystemSet]
  after : Array[SystemSet]
  mut last_run_tick : @core.Tick
}

///|
pub fn[W] system(system : SystemFn[W]) -> SystemConfig[W] {
  SystemConfig::{
    system,
    run_if: None,
    set: None,
    before: [],
    after: [],
    last_run_tick: 0,
  }
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
pub type SubAppExtractFn[W] = (W, W) -> (W, W)

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
  mut world : W
  schedule : Schedule[W]
  runner : RunnerFn?
  sub_apps : @hashmap.HashMap[String, Ref[App[W]]]
  sub_app_labels : @hashmap.HashMap[String, AppLabel]
  sub_app_extractors : @hashmap.HashMap[String, SubAppExtractFn[W]]
}

///|
pub fn[W] App::new(world : W) -> App[W] {
  app_runtime_reset()
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
    sub_apps: @hashmap.HashMap::new(),
    sub_app_labels: @hashmap.HashMap::new(),
    sub_app_extractors: @hashmap.HashMap::new(),
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
pub fn[W] App::add_plugin_group(
  self : App[W],
  group : PluginGroup[W],
) -> App[W] {
  self.add_plugins(group().build())
}

///|
pub fn[W] App::insert_sub_app(
  self : App[W],
  label : AppLabel,
  sub_app : App[W],
) -> App[W] {
  let key = app_label_storage_key(label)
  self.sub_apps.set(key, Ref::new(sub_app))
  self.sub_app_labels.set(key, label)
  self
}

///|
pub fn[W] App::remove_sub_app(self : App[W], label : AppLabel) -> App[W]? {
  let key = app_label_storage_key(label)
  let removed = self.sub_apps.get(key)
  self.sub_apps.remove(key)
  self.sub_app_labels.remove(key)
  self.sub_app_extractors.remove(key)
  removed.map(fn(sub_app_ref) { sub_app_ref.val })
}

///|
pub fn[W] App::get_sub_app(self : App[W], label : AppLabel) -> App[W]? {
  let key = app_label_storage_key(label)
  self.sub_apps.get(key).map(fn(sub_app_ref) { sub_app_ref.val })
}

///|
pub fn[W] App::get_sub_app_mut(self : App[W], label : AppLabel) -> Ref[App[W]]? {
  let key = app_label_storage_key(label)
  self.sub_apps.get(key)
}

///|
pub fn[W] App::sub_app(self : App[W], label : AppLabel) -> App[W] {
  match self.get_sub_app(label) {
    Some(sub_app) => sub_app
    None => abort("Missing sub app for label: " + label.to_string())
  }
}

///|
pub fn[W] App::sub_app_mut(self : App[W], label : AppLabel) -> Ref[App[W]] {
  match self.get_sub_app_mut(label) {
    Some(sub_app_ref) => sub_app_ref
    None => abort("Missing sub app for label: " + label.to_string())
  }
}

///|
pub fn[W] App::set_sub_app_extract(
  self : App[W],
  label : AppLabel,
  extract : SubAppExtractFn[W],
) -> App[W] {
  let key = app_label_storage_key(label)
  if self.sub_apps.contains(key) {
    self.sub_app_extractors.set(key, extract)
  }
  self
}

///|
pub fn[W] App::take_sub_app_extract(
  self : App[W],
  label : AppLabel,
) -> SubAppExtractFn[W]? {
  let key = app_label_storage_key(label)
  let extract = self.sub_app_extractors.get(key)
  self.sub_app_extractors.remove(key)
  extract
}

///|
pub fn[W] App::sub_apps(self : App[W]) -> Array[(AppLabel, App[W])] {
  let out : Array[(AppLabel, App[W])] = []
  for entry in self.sub_apps.iter() {
    let (key, sub_app_ref) = entry
    let label = match self.sub_app_labels.get(key) {
      Some(stored) => stored
      None => Custom(key)
    }
    out.push((label, sub_app_ref.val))
  }
  out
}

///|
pub fn[W] App::sub_apps_mut(self : App[W]) -> Array[(AppLabel, Ref[App[W]])] {
  let out : Array[(AppLabel, Ref[App[W]])] = []
  for entry in self.sub_apps.iter() {
    let (key, sub_app_ref) = entry
    let label = match self.sub_app_labels.get(key) {
      Some(stored) => stored
      None => Custom(key)
    }
    out.push((label, sub_app_ref))
  }
  out
}

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] App::update_sub_app_by_label(
  self : App[W],
  label : AppLabel,
) -> App[W] {
  let key = app_label_storage_key(label)
  if self.sub_apps.get(key) is Some(sub_app_ref) {
    if self.sub_app_extractors.get(key) is Some(extract) {
      let worlds = extract(self.world, sub_app_ref.val.world)
      self.world = worlds.0
      sub_app_ref.val = App::{ ..sub_app_ref.val, world: worlds.1 }
    }
    sub_app_ref.val = sub_app_ref.val.run_once()
  }
  self
}

///|
pub fn[W, T : Resource] App::insert_resource(
  self : App[W],
  value : T,
) -> App[W] {
  Resource::resource().insert(value, current_system_ticks().this_run)
  self
}

///|
pub fn[W, T : Resource] App::init_resource(
  self : App[W],
  init : () -> T,
) -> App[W] {
  let resource : @core.Resource[T] = Resource::resource()
  if !resource.is_present() {
    resource.insert(init(), current_system_ticks().this_run)
  }
  self
}

///|
pub fn[W, T] App::contains_resource(
  _self : App[W],
  resource : @core.Resource[T],
) -> Bool {
  resource.is_present()
}

///|
pub fn[W, T] App::remove_resource(
  _self : App[W],
  resource : @core.Resource[T],
) -> T? {
  resource.remove()
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
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_startup_system_param2(
  self : App[W],
  startup_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.startup.push(system(system_param2(startup_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_startup_system_param3(
  self : App[W],
  startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.startup.push(system(system_param3(startup_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_startup_system_param4(
  self : App[W],
  startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.startup.push(system(system_param4(startup_system)))
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
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_pre_update_system_param2(
  self : App[W],
  pre_update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.pre_update.push(system(system_param2(pre_update_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_pre_update_system_param3(
  self : App[W],
  pre_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.pre_update.push(system(system_param3(pre_update_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_pre_update_system_param4(
  self : App[W],
  pre_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.pre_update.push(system(system_param4(pre_update_system)))
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
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_update_system_param2(
  self : App[W],
  fixed_update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.fixed_update.push(system(system_param2(fixed_update_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_update_system_param3(
  self : App[W],
  fixed_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.fixed_update.push(system(system_param3(fixed_update_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_fixed_update_system_param4(
  self : App[W],
  fixed_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.fixed_update.push(system(system_param4(fixed_update_system)))
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
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_system_param2(
  self : App[W],
  update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.update.push(system(system_param2(update_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_system_param3(
  self : App[W],
  update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.update.push(system(system_param3(update_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_system_param4(
  self : App[W],
  update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.update.push(system(system_param4(update_system)))
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
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_post_update_system_param2(
  self : App[W],
  post_update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.post_update.push(system(system_param2(post_update_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_post_update_system_param3(
  self : App[W],
  post_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.post_update.push(system(system_param3(post_update_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_post_update_system_param4(
  self : App[W],
  post_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.post_update.push(system(system_param4(post_update_system)))
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
fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] run_systems(
  world : W,
  systems : Array[SystemConfig[W]],
  set_edges : Array[(SystemSet, SystemSet)],
) -> Unit {
  current_system_ticks_ref.val = None
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

      // Align with Bevy: increment global change tick once per executed system
      // and expose SystemTicks via World-backed context for change detection.
      let this_run = world.increment_change_tick()
      let sys_ticks = @core.SystemTicks::new(cfg.last_run_tick, this_run)
      let ctx = world.get_system_context()
      ctx.set(sys_ticks)
      world.set_system_context(ctx)
      current_system_ticks_ref.val = Some(sys_ticks)
      (cfg.system)(world)
      current_system_ticks_ref.val = None
      systems[system_i].last_run_tick = this_run
    }
  }
}

///|
fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] run_schedule_stage(
  world : W,
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Unit {
  current_schedule_stage_ref.val = Some(stage)
  run_systems(
    world,
    schedule_systems(schedule, stage),
    schedule_set_edges(schedule, stage),
  )
  current_schedule_stage_ref.val = None
}

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] App::run_startup(
  self : App[W],
) -> App[W] {
  run_schedule_stage(self.world, self.schedule, Startup)
  for entry in self.sub_apps.iter() {
    let (_key, sub_app_ref) = entry
    sub_app_ref.val = sub_app_ref.val.run_startup()
  }
  self
}

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] App::run_once(
  self : App[W],
) -> App[W] {
  run_schedule_stage(self.world, self.schedule, PreUpdate)
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
    current_schedule_stage_ref.val = Some(FixedUpdate)
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
    current_schedule_stage_ref.val = None
  }
  run_schedule_stage(self.world, self.schedule, Update)
  run_schedule_stage(self.world, self.schedule, PostUpdate)
  for entry in self.sub_apps.iter() {
    let (key, sub_app_ref) = entry
    if self.sub_app_extractors.get(key) is Some(extract) {
      let worlds = extract(self.world, sub_app_ref.val.world)
      self.world = worlds.0
      sub_app_ref.val = App::{ ..sub_app_ref.val, world: worlds.1 }
    }
    sub_app_ref.val = sub_app_ref.val.run_once()
  }
  self
}

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] App::run(
  self : App[W],
) -> Unit {
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
