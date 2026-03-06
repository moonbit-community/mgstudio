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
  PreStartup
  Startup
  PostStartup
  First
  PreUpdate
  StateTransition
  RunFixedMainLoop
  FixedFirst
  FixedPreUpdate
  FixedUpdate
  FixedPostUpdate
  FixedLast
  FixedMain
  Update
  SpawnScene
  PostUpdate
  Last
} derive(Eq, Show, ToJson, FromJson)

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
pub fn[A] system_query1_ecs(
  key_a : @ecs.ComponentKey[A],
  system : (@ecs.Query1[A], @ecs.World) -> Unit,
) -> SystemFn[@ecs.World] {
  fn(world : @ecs.World) { system(world.query1(key_a), world) }
}

///|
pub fn[A, B] system_query2_ecs(
  key_a : @ecs.ComponentKey[A],
  key_b : @ecs.ComponentKey[B],
  system : (@ecs.Query2[A, B], @ecs.World) -> Unit,
) -> SystemFn[@ecs.World] {
  fn(world : @ecs.World) { system(world.query2(key_a, key_b), world) }
}

///|
pub fn[A, B, C] system_query3_ecs(
  key_a : @ecs.ComponentKey[A],
  key_b : @ecs.ComponentKey[B],
  key_c : @ecs.ComponentKey[C],
  system : (@ecs.Query3[A, B, C], @ecs.World) -> Unit,
) -> SystemFn[@ecs.World] {
  fn(world : @ecs.World) { system(world.query3(key_a, key_b, key_c), world) }
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
let current_world_ref : Ref[@ecs.World?] = Ref::new(None)

///|
let current_app_schedule_ref : Ref[Schedule[@ecs.World]?] = Ref::new(None)

///|
pub fn current_world() -> @ecs.World? {
  current_world_ref.val
}

///|
pub fn run_current_fixed_update_schedule(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_schedule_stage(world, schedule, FixedUpdate)
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
  mut run_if_last_run_tick : @core.Tick
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
    run_if_last_run_tick: 0,
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
pub type RunnerFn = () -> Unit

///|
pub type RunnerBuilder[W] = (App[W]) -> RunnerFn

///|
pub type SubAppExtractFn[W] = (W, W) -> (W, W)

///|
pub struct Schedule[W] {
  pre_startup : Array[SystemConfig[W]]
  startup : Array[SystemConfig[W]]
  post_startup : Array[SystemConfig[W]]
  first : Array[SystemConfig[W]]
  pre_update : Array[SystemConfig[W]]
  run_fixed_main_loop : Array[SystemConfig[W]]
  fixed_first : Array[SystemConfig[W]]
  fixed_pre_update : Array[SystemConfig[W]]
  fixed_update : Array[SystemConfig[W]]
  fixed_post_update : Array[SystemConfig[W]]
  fixed_last : Array[SystemConfig[W]]
  update : Array[SystemConfig[W]]
  spawn_scene : Array[SystemConfig[W]]
  post_update : Array[SystemConfig[W]]
  last : Array[SystemConfig[W]]
  pre_startup_set_edges : Array[(SystemSet, SystemSet)]
  startup_set_edges : Array[(SystemSet, SystemSet)]
  post_startup_set_edges : Array[(SystemSet, SystemSet)]
  first_set_edges : Array[(SystemSet, SystemSet)]
  pre_update_set_edges : Array[(SystemSet, SystemSet)]
  run_fixed_main_loop_set_edges : Array[(SystemSet, SystemSet)]
  fixed_first_set_edges : Array[(SystemSet, SystemSet)]
  fixed_pre_update_set_edges : Array[(SystemSet, SystemSet)]
  fixed_update_set_edges : Array[(SystemSet, SystemSet)]
  fixed_post_update_set_edges : Array[(SystemSet, SystemSet)]
  fixed_last_set_edges : Array[(SystemSet, SystemSet)]
  update_set_edges : Array[(SystemSet, SystemSet)]
  spawn_scene_set_edges : Array[(SystemSet, SystemSet)]
  post_update_set_edges : Array[(SystemSet, SystemSet)]
  last_set_edges : Array[(SystemSet, SystemSet)]
}

///|
pub struct App[W] {
  mut world : W
  schedule : Schedule[W]
  runner_builder : RunnerBuilder[W]?
  sub_apps : @hashmap.HashMap[String, Ref[App[W]]]
  sub_app_labels : @hashmap.HashMap[String, AppLabel]
  sub_app_extractors : @hashmap.HashMap[String, SubAppExtractFn[W]]
}

///|
pub fn App::new(world : @ecs.World) -> App[@ecs.World] {
  app_runtime_reset()
  reset_main_schedule_resources(world)
  App::{
    world,
    schedule: Schedule::{
      pre_startup: [],
      startup: [],
      post_startup: [],
      first: [],
      pre_update: [],
      run_fixed_main_loop: [],
      fixed_first: [],
      fixed_pre_update: [],
      fixed_update: [],
      fixed_post_update: [],
      fixed_last: [],
      update: [],
      spawn_scene: [],
      post_update: [],
      last: [],
      pre_startup_set_edges: [],
      startup_set_edges: [],
      post_startup_set_edges: [],
      first_set_edges: [],
      pre_update_set_edges: [],
      run_fixed_main_loop_set_edges: [
        (
          run_fixed_main_loop_system_set_name(BeforeFixedMainLoop),
          run_fixed_main_loop_system_set_name(FixedMainLoop),
        ),
        (
          run_fixed_main_loop_system_set_name(FixedMainLoop),
          run_fixed_main_loop_system_set_name(AfterFixedMainLoop),
        ),
      ],
      fixed_first_set_edges: [],
      fixed_pre_update_set_edges: [],
      fixed_update_set_edges: [],
      fixed_post_update_set_edges: [],
      fixed_last_set_edges: [],
      update_set_edges: [],
      spawn_scene_set_edges: [],
      post_update_set_edges: [],
      last_set_edges: [],
    },
    runner_builder: None,
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
pub fn App::update_sub_app_by_label(
  self : App[@ecs.World],
  label : AppLabel,
) -> App[@ecs.World] {
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
pub fn[T : ToJson] App::insert_world_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
  value : T,
) -> App[@ecs.World] {
  self.world.insert_resource(key, value)
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
pub fn[W] App::add_pre_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.pre_startup.push(config)
  self
}

///|
pub fn[W] App::add_pre_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.pre_startup.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_pre_startup_system_param(
  self : App[W],
  pre_startup_system : (P) -> Unit,
) -> App[W] {
  self.schedule.pre_startup.push(system(system_param(pre_startup_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_pre_startup_system_param2(
  self : App[W],
  pre_startup_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.pre_startup.push(system(system_param2(pre_startup_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_pre_startup_system_param3(
  self : App[W],
  pre_startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.pre_startup.push(system(system_param3(pre_startup_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_pre_startup_system_param4(
  self : App[W],
  pre_startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.pre_startup.push(system(system_param4(pre_startup_system)))
  self
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
pub fn[W] App::add_post_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.post_startup.push(config)
  self
}

///|
pub fn[W] App::add_post_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.post_startup.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_post_startup_system_param(
  self : App[W],
  post_startup_system : (P) -> Unit,
) -> App[W] {
  self.schedule.post_startup.push(system(system_param(post_startup_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_post_startup_system_param2(
  self : App[W],
  post_startup_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.post_startup.push(system(system_param2(post_startup_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_post_startup_system_param3(
  self : App[W],
  post_startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.post_startup.push(system(system_param3(post_startup_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_post_startup_system_param4(
  self : App[W],
  post_startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.post_startup.push(system(system_param4(post_startup_system)))
  self
}

///|
pub fn[W] App::add_first_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.first.push(config)
  self
}

///|
pub fn[W] App::add_first_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.first.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_first_system_param(
  self : App[W],
  first_system : (P) -> Unit,
) -> App[W] {
  self.schedule.first.push(system(system_param(first_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_first_system_param2(
  self : App[W],
  first_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.first.push(system(system_param2(first_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_first_system_param3(
  self : App[W],
  first_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.first.push(system(system_param3(first_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_first_system_param4(
  self : App[W],
  first_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.first.push(system(system_param4(first_system)))
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
pub fn[W] App::add_run_fixed_main_loop_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(config)
  self
}

///|
pub fn[W] App::add_run_fixed_main_loop_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_run_fixed_main_loop_system_param(
  self : App[W],
  run_fixed_main_loop_system : (P) -> Unit,
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(
    system(system_param(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_run_fixed_main_loop_system_param2(
  self : App[W],
  run_fixed_main_loop_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(
    system(system_param2(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_run_fixed_main_loop_system_param3(
  self : App[W],
  run_fixed_main_loop_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(
    system(system_param3(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_run_fixed_main_loop_system_param4(
  self : App[W],
  run_fixed_main_loop_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.run_fixed_main_loop.push(
    system(system_param4(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_first_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.fixed_first.push(config)
  self
}

///|
pub fn[W] App::add_fixed_first_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.fixed_first.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_first_system_param(
  self : App[W],
  fixed_first_system : (P) -> Unit,
) -> App[W] {
  self.schedule.fixed_first.push(system(system_param(fixed_first_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_first_system_param2(
  self : App[W],
  fixed_first_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.fixed_first.push(system(system_param2(fixed_first_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_first_system_param3(
  self : App[W],
  fixed_first_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.fixed_first.push(system(system_param3(fixed_first_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_fixed_first_system_param4(
  self : App[W],
  fixed_first_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.fixed_first.push(system(system_param4(fixed_first_system)))
  self
}

///|
pub fn[W] App::add_fixed_pre_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.fixed_pre_update.push(config)
  self
}

///|
pub fn[W] App::add_fixed_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.fixed_pre_update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_pre_update_system_param(
  self : App[W],
  fixed_pre_update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.fixed_pre_update.push(
    system(system_param(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_pre_update_system_param2(
  self : App[W],
  fixed_pre_update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.fixed_pre_update.push(
    system(system_param2(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_pre_update_system_param3(
  self : App[W],
  fixed_pre_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.fixed_pre_update.push(
    system(system_param3(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_fixed_pre_update_system_param4(
  self : App[W],
  fixed_pre_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.fixed_pre_update.push(
    system(system_param4(fixed_pre_update_system)),
  )
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
pub fn[W] App::add_fixed_post_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.fixed_post_update.push(config)
  self
}

///|
pub fn[W] App::add_fixed_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.fixed_post_update.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_post_update_system_param(
  self : App[W],
  fixed_post_update_system : (P) -> Unit,
) -> App[W] {
  self.schedule.fixed_post_update.push(
    system(system_param(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_post_update_system_param2(
  self : App[W],
  fixed_post_update_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.fixed_post_update.push(
    system(system_param2(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_post_update_system_param3(
  self : App[W],
  fixed_post_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.fixed_post_update.push(
    system(system_param3(fixed_post_update_system)),
  )
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_fixed_post_update_system_param4(
  self : App[W],
  fixed_post_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.fixed_post_update.push(
    system(system_param4(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_last_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.fixed_last.push(config)
  self
}

///|
pub fn[W] App::add_fixed_last_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.fixed_last.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_last_system_param(
  self : App[W],
  fixed_last_system : (P) -> Unit,
) -> App[W] {
  self.schedule.fixed_last.push(system(system_param(fixed_last_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_last_system_param2(
  self : App[W],
  fixed_last_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.fixed_last.push(system(system_param2(fixed_last_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_last_system_param3(
  self : App[W],
  fixed_last_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.fixed_last.push(system(system_param3(fixed_last_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_fixed_last_system_param4(
  self : App[W],
  fixed_last_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.fixed_last.push(system(system_param4(fixed_last_system)))
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
pub fn[A] App::add_system_query1_ecs(
  self : App[@ecs.World],
  key_a : @ecs.ComponentKey[A],
  update_system : (@ecs.Query1[A], @ecs.World) -> Unit,
) -> App[@ecs.World] {
  self.schedule.update.push(system(system_query1_ecs(key_a, update_system)))
  self
}

///|
pub fn[A, B] App::add_system_query2_ecs(
  self : App[@ecs.World],
  key_a : @ecs.ComponentKey[A],
  key_b : @ecs.ComponentKey[B],
  update_system : (@ecs.Query2[A, B], @ecs.World) -> Unit,
) -> App[@ecs.World] {
  self.schedule.update.push(
    system(system_query2_ecs(key_a, key_b, update_system)),
  )
  self
}

///|
pub fn[A, B, C] App::add_system_query3_ecs(
  self : App[@ecs.World],
  key_a : @ecs.ComponentKey[A],
  key_b : @ecs.ComponentKey[B],
  key_c : @ecs.ComponentKey[C],
  update_system : (@ecs.Query3[A, B, C], @ecs.World) -> Unit,
) -> App[@ecs.World] {
  self.schedule.update.push(
    system(system_query3_ecs(key_a, key_b, key_c, update_system)),
  )
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
pub fn[W] App::add_spawn_scene_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.spawn_scene.push(config)
  self
}

///|
pub fn[W] App::add_spawn_scene_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.spawn_scene.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_spawn_scene_system_param(
  self : App[W],
  spawn_scene_system : (P) -> Unit,
) -> App[W] {
  self.schedule.spawn_scene.push(system(system_param(spawn_scene_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_spawn_scene_system_param2(
  self : App[W],
  spawn_scene_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.spawn_scene.push(system(system_param2(spawn_scene_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_spawn_scene_system_param3(
  self : App[W],
  spawn_scene_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.spawn_scene.push(system(system_param3(spawn_scene_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_spawn_scene_system_param4(
  self : App[W],
  spawn_scene_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.spawn_scene.push(system(system_param4(spawn_scene_system)))
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
pub fn[W] App::add_last_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  self.schedule.last.push(config)
  self
}

///|
pub fn[W] App::add_last_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  self.schedule.last.push(system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_last_system_param(
  self : App[W],
  last_system : (P) -> Unit,
) -> App[W] {
  self.schedule.last.push(system(system_param(last_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_last_system_param2(
  self : App[W],
  last_system : (P1, P2) -> Unit,
) -> App[W] {
  self.schedule.last.push(system(system_param2(last_system)))
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_last_system_param3(
  self : App[W],
  last_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  self.schedule.last.push(system(system_param3(last_system)))
  self
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_last_system_param4(
  self : App[W],
  last_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  self.schedule.last.push(system(system_param4(last_system)))
  self
}

///|
fn[W] schedule_systems(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[SystemConfig[W]] {
  match stage {
    PreStartup => schedule.pre_startup
    Startup => schedule.startup
    PostStartup => schedule.post_startup
    First => schedule.first
    PreUpdate => schedule.pre_update
    StateTransition => []
    RunFixedMainLoop => schedule.run_fixed_main_loop
    FixedFirst => schedule.fixed_first
    FixedPreUpdate => schedule.fixed_pre_update
    FixedUpdate => schedule.fixed_update
    FixedPostUpdate => schedule.fixed_post_update
    FixedLast => schedule.fixed_last
    FixedMain => []
    Update => schedule.update
    SpawnScene => schedule.spawn_scene
    PostUpdate => schedule.post_update
    Last => schedule.last
  }
}

///|
fn[W] schedule_set_edges(
  schedule : Schedule[W],
  stage : ScheduleStage,
) -> Array[(SystemSet, SystemSet)] {
  match stage {
    PreStartup => schedule.pre_startup_set_edges
    Startup => schedule.startup_set_edges
    PostStartup => schedule.post_startup_set_edges
    First => schedule.first_set_edges
    PreUpdate => schedule.pre_update_set_edges
    StateTransition => []
    RunFixedMainLoop => schedule.run_fixed_main_loop_set_edges
    FixedFirst => schedule.fixed_first_set_edges
    FixedPreUpdate => schedule.fixed_pre_update_set_edges
    FixedUpdate => schedule.fixed_update_set_edges
    FixedPostUpdate => schedule.fixed_post_update_set_edges
    FixedLast => schedule.fixed_last_set_edges
    FixedMain => []
    Update => schedule.update_set_edges
    SpawnScene => schedule.spawn_scene_set_edges
    PostUpdate => schedule.post_update_set_edges
    Last => schedule.last_set_edges
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
fn run_systems(
  world : @ecs.World,
  systems : Array[SystemConfig[@ecs.World]],
  set_edges : Array[(SystemSet, SystemSet)],
) -> Unit {
  current_system_ticks_ref.val = None
  current_world_ref.val = None
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
        let cond_this_run = world.increment_change_tick()
        let cond_ticks = @core.SystemTicks::new(
          cfg.run_if_last_run_tick,
          cond_this_run,
        )
        let cond_ctx = world.get_system_context()
        cond_ctx.set(cond_ticks)
        world.set_system_context(cond_ctx)
        let prev_world = current_world_ref.val
        current_world_ref.val = Some(world)
        current_system_ticks_ref.val = Some(cond_ticks)
        let should_run = cond(world)
        current_system_ticks_ref.val = None
        current_world_ref.val = prev_world
        systems[system_i].run_if_last_run_tick = cond_this_run
        if !should_run {
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
      let prev_world = current_world_ref.val
      current_world_ref.val = Some(world)
      current_system_ticks_ref.val = Some(sys_ticks)
      (cfg.system)(world)
      current_system_ticks_ref.val = None
      current_world_ref.val = prev_world
      systems[system_i].last_run_tick = this_run
    }
  }
}

///|
fn run_schedule_stage(
  world : @ecs.World,
  schedule : Schedule[@ecs.World],
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
pub fn App::run_startup(self : App[@ecs.World]) -> App[@ecs.World] {
  current_app_schedule_ref.val = Some(self.schedule)
  run_main_schedule_startup(self.world, self.schedule)
  current_app_schedule_ref.val = None
  for entry in self.sub_apps.iter() {
    let (_key, sub_app_ref) = entry
    sub_app_ref.val = sub_app_ref.val.run_startup()
  }
  self
}

///|
pub fn App::run_once(self : App[@ecs.World]) -> App[@ecs.World] {
  current_app_schedule_ref.val = Some(self.schedule)
  run_main_schedule_update(self.world, self.schedule)
  current_app_schedule_ref.val = None
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
pub fn App::run(self : App[@ecs.World]) -> Unit {
  if self.runner_builder is Some(builder) {
    let runner = builder(self)
    runner()
  } else {
    self.run_startup().run_once() |> ignore
  }
}

///|
pub fn[W] App::set_runner(self : App[W], builder : RunnerBuilder[W]) -> App[W] {
  App::{ ..self, runner_builder: Some(builder) }
}
