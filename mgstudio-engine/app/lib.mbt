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
pub type FallibleSystemFn[W] = (W) -> Unit raise

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
  "__plugin_group_anon__:\{index.to_string()}"
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
  RenderExtractApp
  Custom(String)
} derive(Eq, Debug)

///|
pub fn app_label(name : String) -> AppLabel {
  Custom(name)
}

///|
fn app_label_storage_key(label : AppLabel) -> String {
  match label {
    MainApp => "__main__"
    RenderApp => "__render__"
    RenderExtractApp => "__render_extract__"
    Custom(name) => "__custom__:\{name}"
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
} derive(Eq, Debug)

///|
pub fn schedule_label(name : String) -> ScheduleStage {
  Custom(name)
}

///|
pub(all) enum ExecutorKind {
  SingleThreaded
  MultiThreaded
} derive(Eq, Debug)

///|
pub(open) trait SystemParam {
  init_state(@ecs.World) -> Json
  get(Ref[Json]) -> Self raise
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
pub struct ResMut[T] {
  value : Ref[T]
}

///|
pub fn[T] ResMut::get_ref(self : ResMut[T]) -> Ref[T] {
  self.value
}

///|
fn[T] system_param_raise_invalid_missing_resource() -> T raise @ecs.SystemParamValidationError {
  raise @ecs.Invalid("Missing resource for system parameter")
}

///|
fn[T : Resource] world_resource_value_or_raise(
  world : @ecs.World,
) -> T raise @ecs.SystemParamValidationError {
  match
    (try world.get_resource(Resource::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => system_param_raise_invalid_missing_resource()
  }
}

///|
fn[T : Resource] world_resource_ref_mut_or_raise(
  world : @ecs.World,
) -> Ref[T] raise @ecs.SystemParamValidationError {
  match
    (try world.get_resource_ref_mut(Resource::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => system_param_raise_invalid_missing_resource()
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
fn[P : SystemParam] system_param_get_or_record(state : Ref[Json]) -> P? {
  try Some(P::get(state)) catch {
    @ecs.Skipped(message) => {
      mark_system_execution_skipped(message)
      None
    }
    @ecs.Invalid(message) => {
      mark_system_execution_invalid(message)
      None
    }
    err => {
      mark_system_execution_error(err)
      None
    }
  } noraise {
    value => value
  }
}

///|
fn run_fallible_system_body(f : () -> Unit raise) -> Unit {
  f() catch {
    err => mark_system_execution_error(err)
  }
}

///|
pub struct In[T] {
  value : T
}

///|
pub fn[T] In::get(self : In[T]) -> T {
  self.value
}

///|
pub fn[T] In::into_inner(self : In[T]) -> T {
  self.value
}

///|
pub struct OutputSystemConfig[W, O] {
  system : (W) -> O?
}

///|
pub fn[W, O] system_output(system : (W) -> O) -> OutputSystemConfig[W, O] {
  OutputSystemConfig::{ system: fn(world : W) { Some(system(world)) } }
}

///|
pub fn[W, P : SystemParam, O] system_param_output(
  system : (P) -> O,
) -> OutputSystemConfig[W, O] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  OutputSystemConfig::{
    system: fn(_world : W) {
      if !state_initialized.val {
        state.val = P::init_state(system_param_abort_missing_world())
        state_initialized.val = true
      }
      let param_opt : P? = system_param_get_or_record(state)
      guard param_opt is Some(param) else { return None }
      let output = system(param)
      P::store(param, state)
      Some(output)
    },
  }
}

///|
pub fn[W, O] OutputSystemConfig::pipe(
  self : OutputSystemConfig[W, O],
  handler : (In[O]) -> Unit,
) -> SystemConfig[W] {
  system(fn(world : W) {
    guard (self.system)(world) is Some(output) else { return }
    handler(In::{ value: output })
  })
}

///|
pub fn[W, O, P : SystemParam] OutputSystemConfig::pipe_param(
  self : OutputSystemConfig[W, O],
  handler : (In[O], P) -> Unit,
) -> SystemConfig[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  system(fn(world : W) {
    guard (self.system)(world) is Some(output) else { return }
    let current_world = system_param_abort_missing_world()
    if !state_initialized.val {
      state.val = P::init_state(current_world)
      state_initialized.val = true
    }
    let param_opt : P? = system_param_get_or_record(state)
    guard param_opt is Some(param) else { return }
    handler(In::{ value: output }, param)
    P::store(param, state)
  })
}

///|
pub fn[W, O] OutputSystemConfig::map(
  self : OutputSystemConfig[W, O],
  handler : (O) -> Unit,
) -> SystemConfig[W] {
  system(fn(world : W) {
    guard (self.system)(world) is Some(output) else { return }
    handler(output)
  })
}

///|
pub fn[W, O, P : SystemParam] OutputSystemConfig::map_param(
  self : OutputSystemConfig[W, O],
  handler : (O, P) -> Unit,
) -> SystemConfig[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  system(fn(world : W) {
    guard (self.system)(world) is Some(output) else { return }
    let current_world = system_param_abort_missing_world()
    if !state_initialized.val {
      state.val = P::init_state(current_world)
      state_initialized.val = true
    }
    let param_opt : P? = system_param_get_or_record(state)
    guard param_opt is Some(param) else { return }
    handler(output, param)
    P::store(param, state)
  })
}

///|
pub fn[W] fallible_system(system : FallibleSystemFn[W]) -> SystemConfig[W] {
  let wrapped = fn(world : W) { run_fallible_system_body(() => system(world)) }
  SystemConfig::{
    system: wrapped,
    name: None,
    error_handler: None,
    run_ifs: [],
    run_if_states: [],
    set: None,
    before: [],
    after: [],
    run_if_last_run_sequences: [],
    last_run_sequence: 0,
  }
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
    let param_opt : P? = system_param_get_or_record(state)
    guard param_opt is Some(param) else { return }
    system(param)
    P::store(param, state)
  }
}

///|
pub fn[W, P : SystemParam] fallible_system_param(
  system : (P) -> Unit raise,
) -> SystemFn[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  fn(_world : W) {
    if !state_initialized.val {
      state.val = P::init_state(system_param_abort_missing_world())
      state_initialized.val = true
    }
    let param_opt : P? = system_param_get_or_record(state)
    guard param_opt is Some(param) else { return }
    run_fallible_system_body(() => system(param))
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    system(p1, p2)
    P1::store(p1, state1)
    P2::store(p2, state2)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] fallible_system_param2(
  system : (P1, P2) -> Unit raise,
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    run_fallible_system_body(() => system(p1, p2))
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    system(p1, p2, p3)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
  }
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] fallible_system_param3(
  system : (P1, P2, P3) -> Unit raise,
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    run_fallible_system_body(() => system(p1, p2, p3))
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    system(p1, p2, p3, p4)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] fallible_system_param4(
  system : (P1, P2, P3, P4) -> Unit raise,
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
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4))
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] system_param5(
  system : (P1, P2, P3, P4, P5) -> Unit,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state4 = Ref::new(Json::null())
  let state5 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  let state4_initialized = Ref::new(false)
  let state5_initialized = Ref::new(false)
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
    if !state5_initialized.val {
      state5.val = P5::init_state(world)
      state5_initialized.val = true
    }
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    let p5_opt : P5? = system_param_get_or_record(state5)
    guard p5_opt is Some(p5) else { return }
    system(p1, p2, p3, p4, p5)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
    P5::store(p5, state5)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] fallible_system_param5(
  system : (P1, P2, P3, P4, P5) -> Unit raise,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state4 = Ref::new(Json::null())
  let state5 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  let state4_initialized = Ref::new(false)
  let state5_initialized = Ref::new(false)
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
    if !state5_initialized.val {
      state5.val = P5::init_state(world)
      state5_initialized.val = true
    }
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    let p5_opt : P5? = system_param_get_or_record(state5)
    guard p5_opt is Some(p5) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5))
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
    P5::store(p5, state5)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] system_param6(
  system : (P1, P2, P3, P4, P5, P6) -> Unit,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state4 = Ref::new(Json::null())
  let state5 = Ref::new(Json::null())
  let state6 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  let state4_initialized = Ref::new(false)
  let state5_initialized = Ref::new(false)
  let state6_initialized = Ref::new(false)
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
    if !state5_initialized.val {
      state5.val = P5::init_state(world)
      state5_initialized.val = true
    }
    if !state6_initialized.val {
      state6.val = P6::init_state(world)
      state6_initialized.val = true
    }
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    let p5_opt : P5? = system_param_get_or_record(state5)
    guard p5_opt is Some(p5) else { return }
    let p6_opt : P6? = system_param_get_or_record(state6)
    guard p6_opt is Some(p6) else { return }
    system(p1, p2, p3, p4, p5, p6)
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
    P5::store(p5, state5)
    P6::store(p6, state6)
  }
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] fallible_system_param6(
  system : (P1, P2, P3, P4, P5, P6) -> Unit raise,
) -> SystemFn[W] {
  let state1 = Ref::new(Json::null())
  let state2 = Ref::new(Json::null())
  let state3 = Ref::new(Json::null())
  let state4 = Ref::new(Json::null())
  let state5 = Ref::new(Json::null())
  let state6 = Ref::new(Json::null())
  let state1_initialized = Ref::new(false)
  let state2_initialized = Ref::new(false)
  let state3_initialized = Ref::new(false)
  let state4_initialized = Ref::new(false)
  let state5_initialized = Ref::new(false)
  let state6_initialized = Ref::new(false)
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
    if !state5_initialized.val {
      state5.val = P5::init_state(world)
      state5_initialized.val = true
    }
    if !state6_initialized.val {
      state6.val = P6::init_state(world)
      state6_initialized.val = true
    }
    let p1_opt : P1? = system_param_get_or_record(state1)
    guard p1_opt is Some(p1) else { return }
    let p2_opt : P2? = system_param_get_or_record(state2)
    guard p2_opt is Some(p2) else { return }
    let p3_opt : P3? = system_param_get_or_record(state3)
    guard p3_opt is Some(p3) else { return }
    let p4_opt : P4? = system_param_get_or_record(state4)
    guard p4_opt is Some(p4) else { return }
    let p5_opt : P5? = system_param_get_or_record(state5)
    guard p5_opt is Some(p5) else { return }
    let p6_opt : P6? = system_param_get_or_record(state6)
    guard p6_opt is Some(p6) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5, p6))
    P1::store(p1, state1)
    P2::store(p2, state2)
    P3::store(p3, state3)
    P4::store(p4, state4)
    P5::store(p5, state5)
    P6::store(p6, state6)
  }
}

///|
let current_system_sequence_ref : Ref[@core.SystemSequence?] = Ref::new(None)

///|
pub fn current_system_sequence() -> @core.SystemSequence {
  match current_system_sequence_ref.val {
    Some(sequence) => sequence
    None => @core.SystemSequence::new(0, 0)
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
  @core.Message::reader(current_system_sequence())
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
  @core.Message::writer(current_system_sequence().this_run)
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
    value: world_resource_value_or_raise(system_param_abort_missing_world()),
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
  ResMut::{ value: world_resource_ref_mut_or_raise(world) }
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct SystemConfig[W] {
  system : SystemFn[W]
  name : String?
  error_handler : ErrorHandler?
  run_ifs : Array[StatefulRunConditionFn[W]]
  run_if_states : Array[Ref[Json]]
  set : SystemSet?
  before : Array[SystemSet]
  after : Array[SystemSet]
  run_if_last_run_sequences : Array[@core.Sequence]
  mut last_run_sequence : @core.Sequence
}

///|
pub fn[W] system(system : SystemFn[W]) -> SystemConfig[W] {
  SystemConfig::{
    system,
    name: None,
    error_handler: None,
    run_ifs: [],
    run_if_states: [],
    set: None,
    before: [],
    after: [],
    run_if_last_run_sequences: [],
    last_run_sequence: 0,
  }
}

///|
pub fn[W] SystemConfig::named(
  self : SystemConfig[W],
  name : String,
) -> SystemConfig[W] {
  SystemConfig::{ ..self, name: Some(name) }
}

///|
pub fn[W] SystemConfig::handle_error_with(
  self : SystemConfig[W],
  handler : ErrorHandler,
) -> SystemConfig[W] {
  SystemConfig::{ ..self, error_handler: Some(handler) }
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
  self.run_ifs.push(cond)
  self.run_if_states.push(Ref::new(init_state))
  self.run_if_last_run_sequences.push(0)
  self
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
pub(open) trait ChainedSystemConfigs {
  chain(Self) -> SystemConfig[@ecs.World]
}

///|
pub fn[T : ChainedSystemConfigs] chain(configs : T) -> SystemConfig[@ecs.World] {
  ChainedSystemConfigs::chain(configs)
}

///|
fn run_chained_system_config(
  world : @ecs.World,
  config_ref : Ref[SystemConfig[@ecs.World]],
) -> Unit {
  let mut should_skip = false
  for cond_i in 0..<config_ref.val.run_ifs.length() {
    let cond = config_ref.val.run_ifs[cond_i]
    let cond_this_run = world.advance_sequence()
    let cond_ticks = @core.SystemSequence::new(
      config_ref.val.run_if_last_run_sequences[cond_i],
      cond_this_run,
    )
    let cond_ctx = world.get_sequence_context()
    cond_ctx.set(cond_ticks)
    world.set_sequence_context(cond_ctx)
    let prev_world = current_world_ref.val
    current_world_ref.val = Some(world)
    let prev_ticks = current_system_sequence_ref.val
    ignore(prev_ticks)
    current_system_sequence_ref.val = Some(cond_ticks)
    let should_run = cond(world, config_ref.val.run_if_states[cond_i])
    current_system_sequence_ref.val = prev_ticks
    current_world_ref.val = prev_world
    config_ref.val.run_if_last_run_sequences[cond_i] = cond_this_run
    if !should_run {
      should_skip = true
      break
    }
  }
  if should_skip {
    return
  }

  let this_run = world.advance_sequence()
  let sys_ticks = @core.SystemSequence::new(
    config_ref.val.last_run_sequence,
    this_run,
  )
  let ctx = world.get_sequence_context()
  ctx.set(sys_ticks)
  world.set_sequence_context(ctx)
  let prev_world = current_world_ref.val
  current_world_ref.val = Some(world)
  let prev_ticks = current_system_sequence_ref.val
  ignore(prev_ticks)
  current_system_sequence_ref.val = Some(sys_ticks)
  let prev_outcome = current_system_execution_outcome()
  reset_system_execution_outcome()
  (config_ref.val.system)(world)
  let outcome = current_system_execution_outcome()
  current_system_execution_outcome_ref.val = prev_outcome
  current_system_sequence_ref.val = prev_ticks
  current_world_ref.val = prev_world
  match outcome {
    Success => config_ref.val.last_run_sequence = this_run
    Skipped(_) => return
    Invalid(message) => {
      report_world_error(
        world,
        @ecs.Invalid(message),
        system_context(
          config_ref.val,
          ErrorContextKind::Validation,
          current_schedule_stage(),
        ),
      )
      return
    }
    Error(err) => {
      config_ref.val.last_run_sequence = this_run
      match config_ref.val.error_handler {
        Some(handler) =>
          handler(
            err,
            system_context(
              config_ref.val,
              ErrorContextKind::System,
              current_schedule_stage(),
            ),
          )
        None =>
          report_world_error(
            world,
            err,
            system_context(
              config_ref.val,
              ErrorContextKind::System,
              current_schedule_stage(),
            ),
          )
      }
    }
  }
}

///|
fn chain_copy_order_edges(
  target : SystemConfig[@ecs.World],
  source : SystemConfig[@ecs.World],
) -> Unit {
  for before_set in source.before {
    target.before.push(before_set)
  }
  for after_set in source.after {
    target.after.push(after_set)
  }
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second) = self
  let first_ref = Ref::new(first)
  let second_ref = Ref::new(second)
  let chained = system(fn(world) {
    run_chained_system_config(world, first_ref)
    run_chained_system_config(world, second_ref)
  })
  chain_copy_order_edges(chained, first_ref.val)
  chain_copy_order_edges(chained, second_ref.val)
  chained
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third) = self
  let first_ref = Ref::new(first)
  let second_ref = Ref::new(second)
  let third_ref = Ref::new(third)
  let chained = system(fn(world) {
    run_chained_system_config(world, first_ref)
    run_chained_system_config(world, second_ref)
    run_chained_system_config(world, third_ref)
  })
  chain_copy_order_edges(chained, first_ref.val)
  chain_copy_order_edges(chained, second_ref.val)
  chain_copy_order_edges(chained, third_ref.val)
  chained
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third, fourth) = self
  let first_ref = Ref::new(first)
  let second_ref = Ref::new(second)
  let third_ref = Ref::new(third)
  let fourth_ref = Ref::new(fourth)
  let chained = system(fn(world) {
    run_chained_system_config(world, first_ref)
    run_chained_system_config(world, second_ref)
    run_chained_system_config(world, third_ref)
    run_chained_system_config(world, fourth_ref)
  })
  chain_copy_order_edges(chained, first_ref.val)
  chain_copy_order_edges(chained, second_ref.val)
  chain_copy_order_edges(chained, third_ref.val)
  chain_copy_order_edges(chained, fourth_ref.val)
  chained
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third, fourth, fifth) = self
  let first_ref = Ref::new(first)
  let second_ref = Ref::new(second)
  let third_ref = Ref::new(third)
  let fourth_ref = Ref::new(fourth)
  let fifth_ref = Ref::new(fifth)
  let chained = system(fn(world) {
    run_chained_system_config(world, first_ref)
    run_chained_system_config(world, second_ref)
    run_chained_system_config(world, third_ref)
    run_chained_system_config(world, fourth_ref)
    run_chained_system_config(world, fifth_ref)
  })
  chain_copy_order_edges(chained, first_ref.val)
  chain_copy_order_edges(chained, second_ref.val)
  chain_copy_order_edges(chained, third_ref.val)
  chain_copy_order_edges(chained, fourth_ref.val)
  chain_copy_order_edges(chained, fifth_ref.val)
  chained
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third, fourth, fifth, sixth) = self
  let first_ref = Ref::new(first)
  let second_ref = Ref::new(second)
  let third_ref = Ref::new(third)
  let fourth_ref = Ref::new(fourth)
  let fifth_ref = Ref::new(fifth)
  let sixth_ref = Ref::new(sixth)
  let chained = system(fn(world) {
    run_chained_system_config(world, first_ref)
    run_chained_system_config(world, second_ref)
    run_chained_system_config(world, third_ref)
    run_chained_system_config(world, fourth_ref)
    run_chained_system_config(world, fifth_ref)
    run_chained_system_config(world, sixth_ref)
  })
  chain_copy_order_edges(chained, first_ref.val)
  chain_copy_order_edges(chained, second_ref.val)
  chain_copy_order_edges(chained, third_ref.val)
  chain_copy_order_edges(chained, fourth_ref.val)
  chain_copy_order_edges(chained, fifth_ref.val)
  chain_copy_order_edges(chained, sixth_ref.val)
  chained
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
    None => abort("Missing sub app for label: \{to_repr(label).to_string()}")
  }
}

///|
pub fn[W] App::sub_app_mut(self : App[W], label : AppLabel) -> Ref[SubApp[W]] {
  match self.get_sub_app_mut(label) {
    Some(sub_app_ref) => sub_app_ref
    None => abort("Missing sub app for label: \{to_repr(label).to_string()}")
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
  self.sub_apps.main.world.advance_sequence() |> ignore
  self.sub_apps.main.world.insert_resource(Resource::resource(), value)
  self
}

///|
pub fn[T] App::insert_world_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
  value : T,
) -> App[@ecs.World] {
  self.sub_apps.main.world.advance_sequence() |> ignore
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
pub fn[T : @ecs.Component] App::allow_ambiguous_component(
  self : App[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.allow_ambiguous_component(key~)
  self
}

///|
pub fn[T : @ecs.Component] App::is_ambiguous_component_allowed(
  self : App[@ecs.World],
  key? : @ecs.ComponentKey[T] = T::component(),
) -> Bool {
  self.sub_apps.main.is_ambiguous_component_allowed(key~)
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
  stage : ScheduleStage?,
) -> Unit {
  let timeline_enabled = timeline_trace_enabled()
  current_system_sequence_ref.val = None
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
    let set = if cfg.set is Some(s) { s } else { "__anon#\{i.to_string()}" }
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
  let execution_order : Array[Int] = []
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
      execution_order.push(system_i)
    }
  }
  let stepping_ref = stepping_resource_ref(world)
  stepping_prepare_stage(stepping_ref, stage, systems, execution_order)
  for execution_i in 0..<execution_order.length() {
    let system_i = execution_order[execution_i]
    let cfg = systems[system_i]
    if !stepping_should_run_system(
        stepping_ref, stage, systems, system_i, execution_i,
      ) {
      continue
    }
    let mut should_skip = false
    for cond_i in 0..<cfg.run_ifs.length() {
      let cond = cfg.run_ifs[cond_i]
      let cond_this_run = world.advance_sequence()
      let cond_ticks = @core.SystemSequence::new(
        cfg.run_if_last_run_sequences[cond_i],
        cond_this_run,
      )
      let cond_ctx = world.get_sequence_context()
      cond_ctx.set(cond_ticks)
      world.set_sequence_context(cond_ctx)
      let prev_world = current_world_ref.val
      current_world_ref.val = Some(world)
      current_system_sequence_ref.val = Some(cond_ticks)
      let should_run = cond(world, cfg.run_if_states[cond_i])
      current_system_sequence_ref.val = None
      current_world_ref.val = prev_world
      systems[system_i].run_if_last_run_sequences[cond_i] = cond_this_run
      if !should_run {
        should_skip = true
        break
      }
    }
    if should_skip {
      continue
    }

    let system_trace_start_us = if timeline_enabled {
      let trace_name = match cfg.name {
        Some(name) => name
        None =>
          match cfg.set {
            Some(set) => "\{set}#\{execution_i.to_string()}"
            None => "__system#\{execution_i.to_string()}"
          }
      }
      timeline_trace_begin_span(TimelineTraceCategory::System, trace_name)
    } else {
      -1L
    }

    // Align with Bevy: increment global change tick once per executed system
    // and expose SystemSequence via World-backed context for change detection.
    let this_run = world.advance_sequence()
    let sys_ticks = @core.SystemSequence::new(cfg.last_run_sequence, this_run)
    ignore(sys_ticks)
    let ctx = world.get_sequence_context()
    ctx.set(sys_ticks)
    world.set_sequence_context(ctx)
    let prev_world = current_world_ref.val
    current_world_ref.val = Some(world)
    let prev_ticks = current_system_sequence_ref.val
    current_system_sequence_ref.val = Some(sys_ticks)
    let prev_outcome = current_system_execution_outcome()
    reset_system_execution_outcome()
    (cfg.system)(world)
    let outcome = current_system_execution_outcome()
    current_system_execution_outcome_ref.val = prev_outcome
    current_system_sequence_ref.val = prev_ticks
    current_world_ref.val = prev_world
    match outcome {
      Success => {
        if timeline_enabled {
          let trace_name = match systems[system_i].name {
            Some(name) => name
            None =>
              match systems[system_i].set {
                Some(set) => "\{set}#\{execution_i.to_string()}"
                None => "__system#\{execution_i.to_string()}"
              }
          }
          timeline_trace_end_span(
            TimelineTraceCategory::System,
            trace_name,
            system_trace_start_us,
          )
        }
        systems[system_i].last_run_sequence = this_run
        stepping_record_system_run(
          stepping_ref, stage, systems, system_i, execution_i,
        )
      }
      Skipped(_) => continue
      Invalid(message) => {
        if timeline_enabled {
          let trace_name = match systems[system_i].name {
            Some(name) => name
            None =>
              match systems[system_i].set {
                Some(set) => "\{set}#\{execution_i.to_string()}"
                None => "__system#\{execution_i.to_string()}"
              }
          }
          timeline_trace_end_span(
            TimelineTraceCategory::System,
            trace_name,
            system_trace_start_us,
          )
        }
        report_world_error(
          world,
          @ecs.Invalid(message),
          system_context(
            systems[system_i],
            ErrorContextKind::Validation,
            current_schedule_stage(),
          ),
        )
        continue
      }
      Error(err) => {
        if timeline_enabled {
          let trace_name = match systems[system_i].name {
            Some(name) => name
            None =>
              match systems[system_i].set {
                Some(set) => "\{set}#\{execution_i.to_string()}"
                None => "__system#\{execution_i.to_string()}"
              }
          }
          timeline_trace_end_span(
            TimelineTraceCategory::System,
            trace_name,
            system_trace_start_us,
          )
        }
        systems[system_i].last_run_sequence = this_run
        stepping_record_system_run(
          stepping_ref, stage, systems, system_i, execution_i,
        )
        match systems[system_i].error_handler {
          Some(handler) =>
            handler(
              err,
              system_context(
                systems[system_i],
                ErrorContextKind::System,
                current_schedule_stage(),
              ),
            )
          None =>
            report_world_error(
              world,
              err,
              system_context(
                systems[system_i],
                ErrorContextKind::System,
                current_schedule_stage(),
              ),
            )
        }
      }
    }
  }
  stepping_finish_stage(stepping_ref, stage, execution_order.length())
}

///|
fn run_schedule_stage(
  world : @ecs.World,
  schedule : ScheduleRegistry[@ecs.World],
  stage : ScheduleStage,
) -> Unit {
  let stage_trace_start_us = timeline_trace_begin_span(
    TimelineTraceCategory::ScheduleStage,
    to_repr(stage).to_string(),
  )
  current_schedule_stage_ref.val = Some(stage)
  run_systems(
    world,
    schedule_systems(schedule, stage),
    schedule_set_edges(schedule, stage),
    Some(stage),
  )
  current_schedule_stage_ref.val = None
  timeline_trace_end_span(
    TimelineTraceCategory::ScheduleStage,
    to_repr(stage).to_string(),
    stage_trace_start_us,
  )
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
