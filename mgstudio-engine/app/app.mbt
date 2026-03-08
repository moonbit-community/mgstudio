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
pub(all) suberror PluginGroupError {
  MissingPlugin(String)
}

///|
pub(open) trait PluginReplacement {
  replacement_id(Self) -> String
  world_plugin(Self) -> Plugin[@ecs.World]
}

///|
pub struct PluginGroupEntry[W] {
  id : String
  mut plugin : Plugin[W]
  mut enabled : Bool
}

///|
pub struct PluginGroupBuilder[W] {
  group_name : String
  plugins : Array[PluginGroupEntry[W]]
}

///|
pub fn[W] PluginGroupBuilder::start() -> PluginGroupBuilder[W] {
  PluginGroupBuilder::start_named("")
}

///|
pub fn[W] PluginGroupBuilder::start_named(
  group_name : String,
) -> PluginGroupBuilder[W] {
  { group_name, plugins: [] }
}

///|
fn plugin_group_anonymous_id(index : Int) -> String {
  "__plugin_group_anon__:" + index.to_string()
}

///|
fn[W] PluginGroupBuilder::plugin_group_find_index(
  self : PluginGroupBuilder[W],
  id : String,
) -> Int? {
  for i in 0..<self.plugins.length() {
    if self.plugins[i].id == id {
      return Some(i)
    }
  }
  None
}

///|
pub fn[W] PluginGroupBuilder::contains(
  self : PluginGroupBuilder[W],
  id : String,
) -> Bool {
  self.plugin_group_find_index(id) is Some(_)
}

///|
pub fn[W] PluginGroupBuilder::enabled(
  self : PluginGroupBuilder[W],
  id : String,
) -> Bool {
  guard self.plugin_group_find_index(id) is Some(index) else { return false }
  self.plugins[index].enabled
}

///|
pub fn[W] PluginGroupBuilder::add(
  self : PluginGroupBuilder[W],
  plugin : Plugin[W],
) -> PluginGroupBuilder[W] {
  self.add_named(id=plugin_group_anonymous_id(self.plugins.length()), plugin)
}

///|
pub fn[W] PluginGroupBuilder::add_named(
  self : PluginGroupBuilder[W],
  id~ : String,
  plugin : Plugin[W],
) -> PluginGroupBuilder[W] {
  self.plugins.push({ id, plugin, enabled: true })
  self
}

///|
pub fn[W] PluginGroupBuilder::set_plugin(
  self : PluginGroupBuilder[W],
  id~ : String,
  plugin : Plugin[W],
) -> PluginGroupBuilder[W] {
  try! self.try_set_plugin(id~, plugin)
}

///|
pub fn[W] PluginGroupBuilder::try_set_plugin(
  self : PluginGroupBuilder[W],
  id~ : String,
  plugin : Plugin[W],
) -> PluginGroupBuilder[W] raise PluginGroupError {
  guard self.plugin_group_find_index(id) is Some(index) else {
    raise MissingPlugin(id)
  }
  self.plugins[index].plugin = plugin
  self.plugins[index].enabled = true
  self
}

///|
pub fn[P : PluginReplacement] PluginGroupBuilder::set(
  self : PluginGroupBuilder[@ecs.World],
  replacement : P,
) -> PluginGroupBuilder[@ecs.World] {
  self.set_plugin(
    id=P::replacement_id(replacement),
    P::world_plugin(replacement),
  )
}

///|
pub fn[P : PluginReplacement] PluginGroupBuilder::try_set(
  self : PluginGroupBuilder[@ecs.World],
  replacement : P,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  self.try_set_plugin(
    id=P::replacement_id(replacement),
    P::world_plugin(replacement),
  )
}

///|
pub fn[W] PluginGroupBuilder::disable(
  self : PluginGroupBuilder[W],
  id : String,
) -> PluginGroupBuilder[W] {
  try! self.try_disable(id)
}

///|
pub fn[W] PluginGroupBuilder::try_disable(
  self : PluginGroupBuilder[W],
  id : String,
) -> PluginGroupBuilder[W] raise PluginGroupError {
  guard self.plugin_group_find_index(id) is Some(index) else {
    raise MissingPlugin(id)
  }
  self.plugins[index].enabled = false
  self
}

///|
pub fn[W] PluginGroupBuilder::enable(
  self : PluginGroupBuilder[W],
  id : String,
) -> PluginGroupBuilder[W] {
  guard self.plugin_group_find_index(id) is Some(index) else { return self }
  self.plugins[index].enabled = true
  self
}

///|
pub fn[W] PluginGroupBuilder::build(
  self : PluginGroupBuilder[W],
) -> Array[Plugin[W]] {
  let plugins : Array[Plugin[W]] = []
  for entry in self.plugins {
    if entry.enabled {
      plugins.push(entry.plugin)
    }
  }
  plugins
}

///|
pub type PluginGroup[W] = () -> PluginGroupBuilder[W]

///|
pub type RunConditionFn[W] = (W) -> Bool

///|
pub type StatefulRunConditionFn[W] = (W, Ref[Json]) -> Bool

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
  Main
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
  Custom(String)
} derive(Eq, Show)

///|
pub fn schedule_label(name : String) -> ScheduleStage {
  Custom(name)
}

///|
pub(all) enum ExecutorKind {
  SingleThreaded
  MultiThreaded
} derive(Eq, Show)

///|
pub(open) trait SystemParam {
  init_state(@ecs.World) -> Json
  get(Ref[Json]) -> Self
  store(Self, Ref[Json]) -> Unit
}

///|
pub(open) trait Resource {
  resource() -> @ecs.ResourceKey[Self]
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
pub fn[T : Resource] Res::is_added(self : Res[T]) -> Bool {
  let value : T = self.value
  ignore(value)
  let key : @ecs.ResourceKey[T] = T::resource()
  match system_param_abort_missing_world().get_resource_ticks(key) {
    Some(ticks) => ticks.is_added(current_system_ticks())
    None => abort("Missing resource for system parameter")
  }
}

///|
pub fn[T : Resource] Res::is_changed(self : Res[T]) -> Bool {
  let value : T = self.value
  ignore(value)
  let key : @ecs.ResourceKey[T] = T::resource()
  match system_param_abort_missing_world().get_resource_ticks(key) {
    Some(ticks) => ticks.is_changed(current_system_ticks())
    None => abort("Missing resource for system parameter")
  }
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
fn[T : Resource] world_resource_value_or_abort(world : @ecs.World) -> T {
  match
    (try world.get_resource(Resource::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => system_param_abort_missing_resource()
  }
}

///|
fn[T : Resource] world_resource_ref_mut_or_abort(
  world : @ecs.World,
  change_tick : @core.Tick,
) -> Ref[T] {
  match
    (try world.get_resource_ref_mut(Resource::resource(), change_tick) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => system_param_abort_missing_resource()
  }
}

///|
fn system_param_abort_missing_world() -> @ecs.World {
  match current_world() {
    Some(world) => world
    None => abort("Missing current world for system parameter")
  }
}

///|
pub fn system_param_empty_state(_world : @ecs.World) -> Json {
  Json::null()
}

///|
pub fn[T] system_param_store_no_state(_self : T, _state : Ref[Json]) -> Unit {
  ()
}

///|
pub fn[W, P : SystemParam] system_param(system : (P) -> Unit) -> SystemFn[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  fn(_world : W) {
    if !state_initialized.val {
      state.val = P::init_state(system_param_abort_missing_world())
      state_initialized.val = true
    }
    let param : P = P::get(state)
    system(param)
    P::store(param, state)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] system_param2(
  system : (P1, P2) -> Unit,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    if !state1_initialized.val {
      state1.val = P1::init_state(world)
      state1_initialized.val = true
    }
    if !state2_initialized.val {
      state2.val = P2::init_state(world)
      state2_initialized.val = true
    }
    let p1 : P1 = P1::get(state1)
    let p2 : P2 = P2::get(state2)
    system(p1, p2)
    P1::store(p1, state1)
    P2::store(p2, state2)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] system_param3(
  system : (P1, P2, P3) -> Unit,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    if !state1_initialized.val {
      state1.val = P1::init_state(world)
      state1_initialized.val = true
    }
    if !state2_initialized.val {
      state2.val = P2::init_state(world)
      state2_initialized.val = true
    }
    if !state3_initialized.val {
      state3.val = P3::init_state(world)
      state3_initialized.val = true
    }
    let p1 : P1 = P1::get(state1)
    let p2 : P2 = P2::get(state2)
    let p3 : P3 = P3::get(state3)
    system(p1, p2, p3)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
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
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state4 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  let state4_initialized = Ref::new(false)
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    if !state1_initialized.val {
      state1.val = P1::init_state(world)
      state1_initialized.val = true
    }
    if !state2_initialized.val {
      state2.val = P2::init_state(world)
      state2_initialized.val = true
    }
    if !state3_initialized.val {
      state3.val = P3::init_state(world)
      state3_initialized.val = true
    }
    if !state4_initialized.val {
      state4.val = P4::init_state(world)
      state4_initialized.val = true
    }
    let p1 : P1 = P1::get(state1)
    let p2 : P2 = P2::get(state2)
    let p3 : P3 = P3::get(state3)
    let p4 : P4 = P4::get(state4)
    system(p1, p2, p3, p4)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
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
let current_app_schedule_ref : Ref[ScheduleRegistry[@ecs.World]?] = Ref::new(
  None,
)

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
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with get(
  _state,
) {
  @core.Message::reader(current_system_ticks())
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with get(
  _state,
) {
  @core.Message::writer(current_system_ticks().this_run)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with get(_state) {
  Res::{
    value: world_resource_value_or_abort(system_param_abort_missing_world()),
  }
}

///|
pub impl[T : Resource] SystemParam for Res[T] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with get(_state) {
  let world = system_param_abort_missing_world()
  ResMut::{
    value: world_resource_ref_mut_or_abort(
      world,
      current_system_ticks().this_run,
    ),
  }
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct SystemConfig[W] {
  system : SystemFn[W]
  run_if : StatefulRunConditionFn[W]?
  run_if_state : Ref[Json]
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
    run_if_state: Ref::new(Json::null()),
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
  self.run_if_stateful(Json::null(), fn(world : W, _state : Ref[Json]) {
    cond(world)
  })
}

///|
pub fn[W] SystemConfig::run_if_stateful(
  self : SystemConfig[W],
  init_state : Json,
  cond : StatefulRunConditionFn[W],
) -> SystemConfig[W] {
  SystemConfig::{
    ..self,
    run_if: Some(cond),
    run_if_state: Ref::new(init_state),
  }
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
pub struct App[W] {
  mut sub_apps : SubApps[W]
  runner_builder : RunnerBuilder[W]?
}

///|
pub fn App::new(world : @ecs.World) -> App[@ecs.World] {
  let app_exit_key : @ecs.MessageKey[AppExit] = @ecs.Message::message()
  let main_sub_app = SubApp::new(world)
    .add_message(app_exit_key)
    .set_update_schedule(Some(Main))
  App::{ sub_apps: SubApps::new(main_sub_app), runner_builder: None }
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
pub fn[W] App::add_plugin(self : App[W], plugin : Plugin[W]) -> App[W] {
  plugin(self)
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
  sub_app : SubApp[W],
) -> App[W] {
  self.sub_apps = self.sub_apps.insert(label, sub_app)
  self
}

///|
pub fn[W] App::remove_sub_app(self : App[W], label : AppLabel) -> SubApp[W]? {
  self.sub_apps.remove(label)
}

///|
pub fn[W] App::get_sub_app(self : App[W], label : AppLabel) -> SubApp[W]? {
  self.sub_apps.get(label)
}

///|
pub fn[W] App::get_sub_app_mut(
  self : App[W],
  label : AppLabel,
) -> Ref[SubApp[W]]? {
  self.sub_apps.get_mut(label)
}

///|
pub fn[W] App::sub_app(self : App[W], label : AppLabel) -> SubApp[W] {
  match self.get_sub_app(label) {
    Some(sub_app) => sub_app
    None => abort("Missing sub app for label: " + label.to_string())
  }
}

///|
pub fn[W] App::sub_app_mut(self : App[W], label : AppLabel) -> Ref[SubApp[W]] {
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
  if self.sub_apps.get_mut(label) is Some(sub_app_ref) {
    sub_app_ref.val = sub_app_ref.val.set_extract(extract)
  }
  self
}

///|
pub fn[W] App::take_sub_app_extract(
  self : App[W],
  label : AppLabel,
) -> SubAppExtractFn[W]? {
  match self.sub_apps.get_mut(label) {
    Some(sub_app_ref) => {
      let (next_sub_app, extract) = sub_app_ref.val.take_extract()
      sub_app_ref.val = next_sub_app
      extract
    }
    None => None
  }
}

///|
pub fn[W] App::sub_apps(self : App[W]) -> Array[(AppLabel, SubApp[W])] {
  self.sub_apps.list()
}

///|
pub fn[W] App::sub_apps_mut(self : App[W]) -> Array[(AppLabel, Ref[SubApp[W]])] {
  self.sub_apps.list_mut()
}

///|
pub fn App::update_sub_app_by_label(
  self : App[@ecs.World],
  label : AppLabel,
) -> App[@ecs.World] {
  self.sub_apps = self.sub_apps.update_sub_app_by_label(label)
  self
}

///|
pub fn App::world(self : App[@ecs.World]) -> @ecs.World {
  self.sub_apps.main.world
}

///|
pub fn[T : Resource] App::insert_resource(
  self : App[@ecs.World],
  value : T,
) -> App[@ecs.World] {
  self.sub_apps.main.world.increment_change_tick() |> ignore
  self.sub_apps.main.world.insert_resource(Resource::resource(), value)
  self
}

///|
pub fn[T] App::insert_world_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
  value : T,
) -> App[@ecs.World] {
  self.sub_apps.main.world.increment_change_tick() |> ignore
  self.sub_apps.main.world.insert_resource(key, value)
  self
}

///|
pub fn[T : Resource] App::init_resource(
  self : App[@ecs.World],
  init : () -> T,
) -> App[@ecs.World] {
  let key = Resource::resource()
  let has_resource = match
    (try self.sub_apps.main.world.get_resource(key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(_) => true
    None => false
  }
  if !has_resource {
    self.sub_apps.main.world.insert_resource(key, init())
  }
  self
}

///|
pub fn[T] App::contains_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
) -> Bool {
  match
    (try self.sub_apps.main.world.get_resource(key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(_) => true
    None => false
  }
}

///|
pub fn[T] App::remove_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
) -> T? {
  try self.sub_apps.main.world.remove_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
pub fn[W] App::add_pre_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, PreStartup, config)
  self
}

///|
pub fn[W] App::add_pre_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_pre_startup_system_param(
  self : App[W],
  pre_startup_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_param(pre_startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_pre_startup_system_param2(
  self : App[W],
  pre_startup_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_param2(pre_startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_pre_startup_system_param3(
  self : App[W],
  pre_startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_param3(pre_startup_system)),
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
] App::add_pre_startup_system_param4(
  self : App[W],
  pre_startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_param4(pre_startup_system)),
  )
  self
}

///|
pub fn[W] App::add_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Startup, config)
  self
}

///|
pub fn[W] App::add_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Startup, system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_startup_system_param(
  self : App[W],
  startup_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Startup,
    system(system_param(startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_startup_system_param2(
  self : App[W],
  startup_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Startup,
    system(system_param2(startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_startup_system_param3(
  self : App[W],
  startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Startup,
    system(system_param3(startup_system)),
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
] App::add_startup_system_param4(
  self : App[W],
  startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Startup,
    system(system_param4(startup_system)),
  )
  self
}

///|
pub fn[W] App::add_post_startup_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, PostStartup, config)
  self
}

///|
pub fn[W] App::add_post_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_post_startup_system_param(
  self : App[W],
  post_startup_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_param(post_startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_post_startup_system_param2(
  self : App[W],
  post_startup_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_param2(post_startup_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_post_startup_system_param3(
  self : App[W],
  post_startup_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_param3(post_startup_system)),
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
] App::add_post_startup_system_param4(
  self : App[W],
  post_startup_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_param4(post_startup_system)),
  )
  self
}

///|
pub fn[W] App::add_first_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, First, config)
  self
}

///|
pub fn[W] App::add_first_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, First, system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_first_system_param(
  self : App[W],
  first_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    First,
    system(system_param(first_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_first_system_param2(
  self : App[W],
  first_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    First,
    system(system_param2(first_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_first_system_param3(
  self : App[W],
  first_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    First,
    system(system_param3(first_system)),
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
] App::add_first_system_param4(
  self : App[W],
  first_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    First,
    system(system_param4(first_system)),
  )
  self
}

///|
pub fn[W] App::add_pre_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, PreUpdate, config)
  self
}

///|
pub fn[W] App::add_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_pre_update_system_param(
  self : App[W],
  pre_update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_param(pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_pre_update_system_param2(
  self : App[W],
  pre_update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_param2(pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_pre_update_system_param3(
  self : App[W],
  pre_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_param3(pre_update_system)),
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
] App::add_pre_update_system_param4(
  self : App[W],
  pre_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_param4(pre_update_system)),
  )
  self
}

///|
pub fn[W] App::add_run_fixed_main_loop_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, RunFixedMainLoop, config)
  self
}

///|
pub fn[W] App::add_run_fixed_main_loop_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_run_fixed_main_loop_system_param(
  self : App[W],
  run_fixed_main_loop_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
    system(system_param(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_run_fixed_main_loop_system_param2(
  self : App[W],
  run_fixed_main_loop_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
    system(system_param2(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_run_fixed_main_loop_system_param3(
  self : App[W],
  run_fixed_main_loop_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
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
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
    system(system_param4(run_fixed_main_loop_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_first_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, FixedFirst, config)
  self
}

///|
pub fn[W] App::add_fixed_first_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_first_system_param(
  self : App[W],
  fixed_first_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_param(fixed_first_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_first_system_param2(
  self : App[W],
  fixed_first_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_param2(fixed_first_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_first_system_param3(
  self : App[W],
  fixed_first_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_param3(fixed_first_system)),
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
] App::add_fixed_first_system_param4(
  self : App[W],
  fixed_first_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_param4(fixed_first_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_pre_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, FixedPreUpdate, config)
  self
}

///|
pub fn[W] App::add_fixed_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_pre_update_system_param(
  self : App[W],
  fixed_pre_update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
    system(system_param(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_pre_update_system_param2(
  self : App[W],
  fixed_pre_update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
    system(system_param2(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_pre_update_system_param3(
  self : App[W],
  fixed_pre_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
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
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
    system(system_param4(fixed_pre_update_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, FixedUpdate, config)
  self
}

///|
pub fn[W] App::add_fixed_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_update_system_param(
  self : App[W],
  fixed_update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_param(fixed_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_update_system_param2(
  self : App[W],
  fixed_update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_param2(fixed_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_update_system_param3(
  self : App[W],
  fixed_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_param3(fixed_update_system)),
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
] App::add_fixed_update_system_param4(
  self : App[W],
  fixed_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_param4(fixed_update_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_post_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, FixedPostUpdate, config)
  self
}

///|
pub fn[W] App::add_fixed_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_post_update_system_param(
  self : App[W],
  fixed_post_update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
    system(system_param(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_post_update_system_param2(
  self : App[W],
  fixed_post_update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
    system(system_param2(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_post_update_system_param3(
  self : App[W],
  fixed_post_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
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
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
    system(system_param4(fixed_post_update_system)),
  )
  self
}

///|
pub fn[W] App::add_fixed_last_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, FixedLast, config)
  self
}

///|
pub fn[W] App::add_fixed_last_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_fixed_last_system_param(
  self : App[W],
  fixed_last_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_param(fixed_last_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_fixed_last_system_param2(
  self : App[W],
  fixed_last_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_param2(fixed_last_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_fixed_last_system_param3(
  self : App[W],
  fixed_last_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_param3(fixed_last_system)),
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
] App::add_fixed_last_system_param4(
  self : App[W],
  fixed_last_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_param4(fixed_last_system)),
  )
  self
}

///|
pub fn[W] App::add_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Update, config)
  self
}

///|
pub fn[W] App::add_system(self : App[W], system_fn : SystemFn[W]) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Update, system(system_fn))
  self
}

///|
pub fn[A] App::add_system_query1_ecs(
  self : App[@ecs.World],
  key_a : @ecs.ComponentKey[A],
  update_system : (@ecs.Query1[A], @ecs.World) -> Unit,
) -> App[@ecs.World] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_query1_ecs(key_a, update_system)),
  )
  self
}

///|
pub fn[A, B] App::add_system_query2_ecs(
  self : App[@ecs.World],
  key_a : @ecs.ComponentKey[A],
  key_b : @ecs.ComponentKey[B],
  update_system : (@ecs.Query2[A, B], @ecs.World) -> Unit,
) -> App[@ecs.World] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
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
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_query3_ecs(key_a, key_b, key_c, update_system)),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_system_param(
  self : App[W],
  update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_param(update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_system_param2(
  self : App[W],
  update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_param2(update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_system_param3(
  self : App[W],
  update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_param3(update_system)),
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
] App::add_system_param4(
  self : App[W],
  update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_param4(update_system)),
  )
  self
}

///|
pub fn[W] App::add_spawn_scene_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, SpawnScene, config)
  self
}

///|
pub fn[W] App::add_spawn_scene_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_spawn_scene_system_param(
  self : App[W],
  spawn_scene_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_param(spawn_scene_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_spawn_scene_system_param2(
  self : App[W],
  spawn_scene_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_param2(spawn_scene_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_spawn_scene_system_param3(
  self : App[W],
  spawn_scene_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_param3(spawn_scene_system)),
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
] App::add_spawn_scene_system_param4(
  self : App[W],
  spawn_scene_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_param4(spawn_scene_system)),
  )
  self
}

///|
pub fn[W] App::add_post_update_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, PostUpdate, config)
  self
}

///|
pub fn[W] App::add_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_fn),
  )
  self
}

///|
pub fn[W, P : SystemParam] App::add_post_update_system_param(
  self : App[W],
  post_update_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_param(post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_post_update_system_param2(
  self : App[W],
  post_update_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_param2(post_update_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_post_update_system_param3(
  self : App[W],
  post_update_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_param3(post_update_system)),
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
] App::add_post_update_system_param4(
  self : App[W],
  post_update_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_param4(post_update_system)),
  )
  self
}

///|
pub fn[W] App::add_last_system_config(
  self : App[W],
  config : SystemConfig[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Last, config)
  self
}

///|
pub fn[W] App::add_last_system(
  self : App[W],
  system_fn : SystemFn[W],
) -> App[W] {
  schedule_push_config(self.sub_apps.main.schedule, Last, system(system_fn))
  self
}

///|
pub fn[W, P : SystemParam] App::add_last_system_param(
  self : App[W],
  last_system : (P) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Last,
    system(system_param(last_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] App::add_last_system_param2(
  self : App[W],
  last_system : (P1, P2) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Last,
    system(system_param2(last_system)),
  )
  self
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] App::add_last_system_param3(
  self : App[W],
  last_system : (P1, P2, P3) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Last,
    system(system_param3(last_system)),
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
] App::add_last_system_param4(
  self : App[W],
  last_system : (P1, P2, P3, P4) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Last,
    system(system_param4(last_system)),
  )
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
        let should_run = cond(world, cfg.run_if_state)
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
  schedule : ScheduleRegistry[@ecs.World],
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
  self.sub_apps = self.sub_apps.run_startup()
  self
}

///|
pub fn App::update(self : App[@ecs.World]) -> App[@ecs.World] {
  self.sub_apps = self.sub_apps.update()
  self
}

///|
pub fn App::run_once(self : App[@ecs.World]) -> App[@ecs.World] {
  self.update()
}

///|
pub fn App::run(self : App[@ecs.World]) -> Unit {
  if self.runner_builder is Some(builder) {
    let runner = builder(self)
    runner()
  } else {
    self.update() |> ignore
  }
}

///|
pub fn[W] App::set_runner(self : App[W], builder : RunnerBuilder[W]) -> App[W] {
  App::{ ..self, runner_builder: Some(builder) }
}
