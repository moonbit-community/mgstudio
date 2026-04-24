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
type PluginFn[W] = (App[W]) -> App[W]

///|
pub(all) suberror PluginGroupError {
  MissingPlugin(String)
}

///|
pub(open) trait Plugin {
  build(Self, App[@ecs.World]) -> App[@ecs.World]
  name(Self) -> String = _
  is_unique(Self) -> Bool = _
  ready(Self, App[@ecs.World]) -> Bool = _
  finish(Self, App[@ecs.World]) -> App[@ecs.World] = _
  cleanup(Self, App[@ecs.World]) -> App[@ecs.World] = _
}

///|
impl Plugin with name(self) {
  @any.of(self).type_name()
}

///|
impl Plugin with is_unique(_self) {
  true
}

///|
impl Plugin with ready(_self, _app) {
  true
}

///|
impl Plugin with finish(_self, app) {
  app
}

///|
impl Plugin with cleanup(_self, app) {
  app
}

///|
pub struct PluginGroupEntry[W] {
  id : String
  plugin : PluginFn[W]
  is_unique : Bool
  ready : (App[W]) -> Bool
  finish : PluginFn[W]
  cleanup : PluginFn[W]
  mut enabled : Bool
}

///|
pub struct PluginGroupBuilder[W] {
  group_name : String
  plugins : Array[PluginGroupEntry[W]]
}

///|
pub(open) trait PluginGroup {
  build(Self) -> PluginGroupBuilder[@ecs.World]
  name(Self) -> String = _
}

///|
impl PluginGroup with name(self) {
  @any.of(self).type_name()
}

///|
fn[W] plugin_group_ready_default(_app : App[W]) -> Bool {
  true
}

///|
fn[W] plugin_group_finish_default(app : App[W]) -> App[W] {
  app
}

///|
fn[W] plugin_group_cleanup_default(app : App[W]) -> App[W] {
  app
}

///|
fn[W] plugin_group_entry_new(
  id : String,
  plugin : PluginFn[W],
  is_unique? : Bool = false,
  ready? : (App[W]) -> Bool = plugin_group_ready_default,
  finish? : PluginFn[W] = plugin_group_finish_default,
  cleanup? : PluginFn[W] = plugin_group_cleanup_default,
) -> PluginGroupEntry[W] {
  { id, plugin, is_unique, ready, finish, cleanup, enabled: true }
}

///|
fn[P : Plugin] plugin_group_entry_from_plugin(
  plugin : P,
) -> PluginGroupEntry[@ecs.World] {
  plugin_group_entry_new(
    P::name(plugin),
    fn(app) { P::build(plugin, app) },
    is_unique=P::is_unique(plugin),
    ready=fn(app) { P::ready(plugin, app) },
    finish=fn(app) { P::finish(plugin, app) },
    cleanup=fn(app) { P::cleanup(plugin, app) },
  )
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
fn[W] PluginGroupBuilder::plugin_group_contains_id(
  self : PluginGroupBuilder[W],
  id : String,
) -> Bool {
  self.plugin_group_find_index(id) is Some(_)
}

///|
fn[W] PluginGroupBuilder::plugin_group_enabled_id(
  self : PluginGroupBuilder[W],
  id : String,
) -> Bool {
  guard self.plugin_group_find_index(id) is Some(index) else { return false }
  self.plugins[index].enabled
}

///|
fn[W] PluginGroupBuilder::plugin_group_add_entry(
  self : PluginGroupBuilder[W],
  entry : PluginGroupEntry[W],
) -> PluginGroupBuilder[W] {
  self.plugins.push(entry)
  self
}

///|
fn[W] PluginGroupBuilder::plugin_group_try_set_entry(
  self : PluginGroupBuilder[W],
  id~ : String,
  entry : PluginGroupEntry[W],
) -> PluginGroupBuilder[W] raise PluginGroupError {
  guard self.plugin_group_find_index(id) is Some(index) else {
    raise MissingPlugin(id)
  }
  self.plugins[index] = entry
  self.plugins[index].enabled = true
  self
}

///|
pub fn[P : Plugin] PluginGroupBuilder::add(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] {
  self.plugin_group_add_entry(plugin_group_entry_from_plugin(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::contains(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> Bool {
  self.plugin_group_contains_id(P::name(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::enabled(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> Bool {
  self.plugin_group_enabled_id(P::name(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::set(
  self : PluginGroupBuilder[@ecs.World],
  replacement : P,
) -> PluginGroupBuilder[@ecs.World] {
  try! self.plugin_group_try_set_entry(
    id=P::name(replacement),
    plugin_group_entry_from_plugin(replacement),
  )
}

///|
pub fn[P : Plugin] PluginGroupBuilder::try_set(
  self : PluginGroupBuilder[@ecs.World],
  replacement : P,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  self.plugin_group_try_set_entry(
    id=P::name(replacement),
    plugin_group_entry_from_plugin(replacement),
  )
}

///|
fn[W] PluginGroupBuilder::plugin_group_try_disable_id(
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
fn[W] PluginGroupBuilder::plugin_group_enable_id(
  self : PluginGroupBuilder[W],
  id : String,
) -> PluginGroupBuilder[W] {
  guard self.plugin_group_find_index(id) is Some(index) else { return self }
  self.plugins[index].enabled = true
  self
}

///|
pub fn[P : Plugin] PluginGroupBuilder::disable(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] {
  try! self.plugin_group_try_disable_id(P::name(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::try_disable(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  self.plugin_group_try_disable_id(P::name(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::enable(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] {
  self.plugin_group_enable_id(P::name(plugin))
}

///|
pub impl PluginGroup for PluginGroupBuilder[@ecs.World] with build(self) {
  self
}

///|
pub impl PluginGroup for PluginGroupBuilder[@ecs.World] with name(self) {
  self.group_name
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with name(self) {
  if self.group_name == "" {
    "mgstudio.app.PluginGroupBuilder"
  } else {
    self.group_name
  }
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with is_unique(_self) {
  false
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with build(self, app) {
  app.add_plugin_entries(self.build_entries())
}

///|
pub fn[W] PluginGroupBuilder::build_entries(
  self : PluginGroupBuilder[W],
) -> Array[PluginGroupEntry[W]] {
  let entries : Array[PluginGroupEntry[W]] = []
  for entry in self.plugins {
    if entry.enabled {
      entries.push(entry)
    }
  }
  entries
}

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
  access(@ecs.World) -> SystemAccess = _
}

///|
impl SystemParam with access(_world) {
  SystemAccess::new()
}

///|
pub(open) trait Resource {
  resource() -> @ecs.ResourceKey[Self]
}

///|
pub struct Res[T] {
  value : T
  world : @ecs.World?
  key_id : Int?
}

///|
pub fn[T] Res::get(self : Res[T]) -> T {
  self.value
}

///|
fn[T] res_world_or_abort(item : Res[T]) -> @ecs.World {
  match item.world {
    Some(world) => world
    None => abort("Res expected a fetched system parameter")
  }
}

///|
fn[T] res_key_id_or_abort(item : Res[T]) -> Int {
  match item.key_id {
    Some(key_id) => key_id
    None => abort("Res expected a fetched system parameter")
  }
}

///|
pub fn[T : Resource] Res::is_added(self : Res[T]) -> Bool {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  world.is_resource_added(T::resource(), current_system_sequence())
}

///|
pub fn[T : Resource] Res::is_changed(self : Res[T]) -> Bool {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  world.is_resource_changed(T::resource(), current_system_sequence())
}

///|
pub fn[T : Resource] Res::added(self : Res[T]) -> @core.Sequence {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  match world.resource_added_tick(T::resource()) {
    Some(sequence) => sequence
    None => abort("Res::added expected resource sequence metadata")
  }
}

///|
pub fn[T : Resource] Res::last_changed(self : Res[T]) -> @core.Sequence {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  match world.resource_changed_tick(T::resource()) {
    Some(sequence) => sequence
    None => abort("Res::last_changed expected resource sequence metadata")
  }
}

///|
pub fn[T : Resource] Res::changed_by(self : Res[T]) -> String? {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  world.resource_changed_by(T::resource())
}

///|
pub struct ResMut[T] {
  world : @ecs.World?
  key : @ecs.ResourceKey[T]?
}

///|
pub fn[T : Resource] ResMut::get(self : ResMut[T]) -> T {
  self.peek()
}

///|
fn[T] res_mut_world_or_abort(item : ResMut[T]) -> @ecs.World {
  match item.world {
    Some(world) => world
    None => abort("ResMut expected a fetched system parameter")
  }
}

///|
fn[T] res_mut_key_id_or_abort(item : ResMut[T]) -> Int {
  match item.key {
    Some(key) => key.id()
    None => abort("ResMut expected a fetched system parameter")
  }
}

///|
pub fn[T : Resource] ResMut::is_added(self : ResMut[T]) -> Bool {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  world.is_resource_added(T::resource(), current_system_sequence())
}

///|
pub fn[T : Resource] ResMut::is_changed(self : ResMut[T]) -> Bool {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  world.is_resource_changed(T::resource(), current_system_sequence())
}

///|
pub fn[T : Resource] ResMut::added(self : ResMut[T]) -> @core.Sequence {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  match world.resource_added_tick(T::resource()) {
    Some(sequence) => sequence
    None => abort("ResMut::added expected resource sequence metadata")
  }
}

///|
pub fn[T : Resource] ResMut::last_changed(self : ResMut[T]) -> @core.Sequence {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  match world.resource_changed_tick(T::resource()) {
    Some(sequence) => sequence
    None => abort("ResMut::last_changed expected resource sequence metadata")
  }
}

///|
pub fn[T : Resource] ResMut::changed_by(self : ResMut[T]) -> String? {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  world.resource_changed_by(T::resource())
}

///|
#callsite(autofill(loc))
pub fn[T : Resource] ResMut::set_changed(
  self : ResMut[T],
  loc~ : SourceLoc,
) -> Unit {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  world.mark_resource_changed(T::resource(), caller=Some(loc.to_string()))
}

///|
#callsite(autofill(loc))
pub fn[T : Resource] ResMut::set_added(
  self : ResMut[T],
  loc~ : SourceLoc,
) -> Unit {
  let world = res_mut_world_or_abort(self)
  ignore(res_mut_key_id_or_abort(self))
  world.mark_resource_added(T::resource(), caller=Some(loc.to_string()))
}

///|
fn[T : Resource] res_mut_value_or_abort(item : ResMut[T]) -> T {
  let world = res_mut_world_or_abort(item)
  match
    (try world.get_resource(T::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => abort("ResMut expected a fetched system parameter")
  }
}

///|
pub fn[T : Resource] ResMut::peek(self : ResMut[T]) -> T {
  res_mut_value_or_abort(self)
}

///|
#callsite(autofill(loc))
pub fn[T : Resource, R] ResMut::modify(
  self : ResMut[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let value = self.peek()
  let result = f(value)
  res_mut_world_or_abort(self).insert_resource(T::resource(), value)
  self.set_changed(loc~)
  result
}

///|
#callsite(autofill(loc))
pub fn[T : Resource] ResMut::update(
  self : ResMut[T],
  f : (T) -> T,
  loc~ : SourceLoc,
) -> Unit {
  self.set(f(self.peek()), loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Resource] ResMut::set(
  self : ResMut[T],
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  res_mut_world_or_abort(self).insert_resource(T::resource(), value)
  self.set_changed(loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Resource + Eq] ResMut::set_if_neq(
  self : ResMut[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  let current = self.peek()
  if current != value {
    self.set(value, loc~)
    true
  } else {
    false
  }
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
  access_factory : ((@ecs.World) -> SystemAccess)?
}

///|
pub fn[W, O] system_output(system : (W) -> O) -> OutputSystemConfig[W, O] {
  OutputSystemConfig::{
    system: fn(world : W) { Some(system(world)) },
    access_factory: None,
  }
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
    access_factory: Some(fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P::access(world),
        @hashmap.HashMap::new(),
      )
      access
    }),
  }
}

///|
fn[W, O] OutputSystemConfig::output_system_base_access(
  self : OutputSystemConfig[W, O],
  world : @ecs.World,
) -> SystemAccess {
  match self.access_factory {
    Some(access_factory) => access_factory(world)
    None => SystemAccess::new()
  }
}

///|
pub fn[W, O] OutputSystemConfig::pipe(
  self : OutputSystemConfig[W, O],
  handler : (In[O]) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(
    fn(world : W) {
      guard (self.system)(world) is Some(output) else { return }
      handler(In::{ value: output })
    },
    fn(world : @ecs.World) { self.output_system_base_access(world) },
  )
}

///|
pub fn[W, O, P : SystemParam] OutputSystemConfig::pipe_param(
  self : OutputSystemConfig[W, O],
  handler : (In[O], P) -> Unit,
) -> SystemConfig[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  system_config_with_access(
    fn(world : W) {
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
    },
    fn(world : @ecs.World) {
      let access = self.output_system_base_access(world)
      system_access_merge_validated(
        access,
        P::access(world),
        @hashmap.HashMap::new(),
      )
      access
    },
  )
}

///|
pub fn[W, O] OutputSystemConfig::map(
  self : OutputSystemConfig[W, O],
  handler : (O) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(
    fn(world : W) {
      guard (self.system)(world) is Some(output) else { return }
      handler(output)
    },
    fn(world : @ecs.World) { self.output_system_base_access(world) },
  )
}

///|
pub fn[W, O, P : SystemParam] OutputSystemConfig::map_param(
  self : OutputSystemConfig[W, O],
  handler : (O, P) -> Unit,
) -> SystemConfig[W] {
  let state = Ref::new(Json::null())
  let state_initialized = Ref::new(false)
  system_config_with_access(
    fn(world : W) {
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
    },
    fn(world : @ecs.World) {
      let access = self.output_system_base_access(world)
      system_access_merge_validated(
        access,
        P::access(world),
        @hashmap.HashMap::new(),
      )
      access
    },
  )
}

///|
#callsite(autofill(loc))
fn[W] system_config_with_access(
  system : SystemFn[W],
  access_factory : (@ecs.World) -> SystemAccess,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  SystemConfig::{
    system,
    name: None,
    debug_name: Some(loc.to_string()),
    error_handler: None,
    run_ifs: [],
    run_if_states: [],
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_sequences: [],
    last_run_sequence: 0,
    access_factory: Some(access_factory),
  }
}

///|
pub fn[W, P : SystemParam] system_config_param(
  system : (P) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(system_param(system), fn(world : @ecs.World) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[W, P : SystemParam] fallible_system_config_param(
  system : (P) -> Unit raise,
) -> SystemConfig[W] {
  system_config_with_access(fallible_system_param(system), fn(
    world : @ecs.World,
  ) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] system_config_param2(
  system : (P1, P2) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(system_param2(system), fn(world : @ecs.World) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam] fallible_system_config_param2(
  system : (P1, P2) -> Unit raise,
) -> SystemConfig[W] {
  system_config_with_access(fallible_system_param2(system), fn(
    world : @ecs.World,
  ) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] system_config_param3(
  system : (P1, P2, P3) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(system_param3(system), fn(world : @ecs.World) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P3::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] fallible_system_config_param3(
  system : (P1, P2, P3) -> Unit raise,
) -> SystemConfig[W] {
  system_config_with_access(fallible_system_param3(system), fn(
    world : @ecs.World,
  ) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P3::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] system_config_param4(
  system : (P1, P2, P3, P4) -> Unit,
) -> SystemConfig[W] {
  system_config_with_access(system_param4(system), fn(world : @ecs.World) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P3::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P4::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] fallible_system_config_param4(
  system : (P1, P2, P3, P4) -> Unit raise,
) -> SystemConfig[W] {
  system_config_with_access(fallible_system_param4(system), fn(
    world : @ecs.World,
  ) {
    let access = SystemAccess::new()
    system_access_merge_validated(
      access,
      P1::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P2::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P3::access(world),
      @hashmap.HashMap::new(),
    )
    system_access_merge_validated(
      access,
      P4::access(world),
      @hashmap.HashMap::new(),
    )
    access
  })
}

///|
#callsite(autofill(loc))
pub fn[W] fallible_system(
  system : FallibleSystemFn[W],
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  let wrapped = fn(world : W) { run_fallible_system_body(() => system(world)) }
  SystemConfig::{
    system: wrapped,
    name: None,
    debug_name: Some(loc.to_string()),
    error_handler: None,
    run_ifs: [],
    run_if_states: [],
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_sequences: [],
    last_run_sequence: 0,
    access_factory: None,
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
let current_allowed_ambiguous_components_ref : Ref[@hashmap.HashMap[Int, Bool]?] = Ref::new(
  None,
)

///|
pub fn current_world() -> @ecs.World? {
  current_world_ref.val
}

///|
fn current_allowed_ambiguous_components() -> @hashmap.HashMap[Int, Bool] {
  match current_allowed_ambiguous_components_ref.val {
    Some(allowed) => allowed
    None => @hashmap.HashMap::new()
  }
}

///|
pub fn run_current_fixed_update_schedule(world : @ecs.World) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_schedule_stage(world, schedule, FixedUpdate)
}

///|
pub fn run_current_schedule_stage(
  world : @ecs.World,
  stage : ScheduleStage,
) -> Unit {
  guard current_app_schedule_ref.val is Some(schedule) else { return }
  run_schedule_stage(world, schedule, stage)
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
  let world = system_param_abort_missing_world()
  Res::{
    value: world_resource_value_or_raise(world),
    world: Some(world),
    key_id: Some(T::resource().id()),
  }
}

///|
pub impl[T : Resource] SystemParam for Res[T] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with access(_world) {
  let access = SystemAccess::new()
  access.add_read_resource(T::resource().id())
  access
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with get(_state) {
  let world = system_param_abort_missing_world()
  ResMut::{ world: Some(world), key: Some(T::resource()) }
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with access(_world) {
  let access = SystemAccess::new()
  access.add_write_resource(T::resource().id())
  access
}

///|
pub struct SystemConfig[W] {
  system : SystemFn[W]
  name : String?
  debug_name : String?
  error_handler : ErrorHandler?
  run_ifs : Array[StatefulRunConditionFn[W]]
  run_if_states : Array[Ref[Json]]
  chain_members : Array[SystemConfig[W]]?
  chain_ignore_deferred : Bool
  set : SystemSet?
  member_sets : Array[SystemSet]
  before : Array[SystemSet]
  after : Array[SystemSet]
  before_ignore_deferred : Array[SystemSet]
  after_ignore_deferred : Array[SystemSet]
  is_apply_deferred_node : Bool
  run_if_last_run_sequences : Array[@core.Sequence]
  mut last_run_sequence : @core.Sequence
  mut access_factory : ((@ecs.World) -> SystemAccess)?
}

///|
#callsite(autofill(loc))
pub fn[W] system(system : SystemFn[W], loc~ : SourceLoc) -> SystemConfig[W] {
  SystemConfig::{
    system,
    name: None,
    debug_name: Some(loc.to_string()),
    error_handler: None,
    run_ifs: [],
    run_if_states: [],
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_sequences: [],
    last_run_sequence: 0,
    access_factory: None,
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
pub fn[W] SystemConfig::chain_ignore_deferred(
  self : SystemConfig[W],
) -> SystemConfig[W] {
  SystemConfig::{ ..self, chain_ignore_deferred: true }
}

///|
pub fn[W] SystemConfig::in_set(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  if !self.member_sets.contains(set) {
    self.member_sets.push(set)
  }
  let primary_set = match self.set {
    Some(current) => Some(current)
    None => Some(set)
  }
  SystemConfig::{ ..self, set: primary_set }
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
pub fn[W] SystemConfig::before_ignore_deferred(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  self.before_ignore_deferred.push(set)
  self
}

///|
pub fn[W] SystemConfig::after_ignore_deferred(
  self : SystemConfig[W],
  set : SystemSet,
) -> SystemConfig[W] {
  self.after_ignore_deferred.push(set)
  self
}

///|
pub fn apply_deferred_system() -> SystemConfig[@ecs.World] {
  let config = system(fn(world : @ecs.World) {
    end_deferred_command_batch(world)
    begin_deferred_command_batch()
  })
  SystemConfig::{
    ..config,
    name: Some("bevy_ecs::apply_deferred"),
    is_apply_deferred_node: true,
    access_factory: Some(fn(_world : @ecs.World) { SystemAccess::new() }),
  }
}

///|
fn[W] auto_apply_deferred_system(sync_i : Int) -> SystemConfig[W] {
  let config = system(fn(_world : W) {
    let world = current_world_or_abort()
    end_deferred_command_batch(world)
    begin_deferred_command_batch()
  })
  SystemConfig::{
    ..config,
    name: Some("bevy_ecs::apply_deferred#auto\{sync_i.to_string()}"),
    is_apply_deferred_node: true,
    access_factory: Some(fn(_world : @ecs.World) { SystemAccess::new() }),
  }
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
fn chain_group_config(
  members : Array[SystemConfig[@ecs.World]],
) -> SystemConfig[@ecs.World] {
  let config = system(fn(_world : @ecs.World) -> Unit {  })
  SystemConfig::{
    ..config,
    chain_members: Some(members),
    // This wrapper is expanded in schedule_push_config and never executed directly.
    access_factory: None,
  }
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second) = self
  chain_group_config([first, second])
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third) = self
  chain_group_config([first, second, third])
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with chain(self) {
  let (first, second, third, fourth) = self
  chain_group_config([first, second, third, fourth])
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
  chain_group_config([first, second, third, fourth, fifth])
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
  chain_group_config([first, second, third, fourth, fifth, sixth])
}

///|
pub type RunnerFn = () -> Unit

///|
pub type RunnerBuilder[W] = (App[W]) -> RunnerFn

///|
pub type SubAppExtractFn[W] = (W, W) -> (W, W)

///|
pub(all) enum PluginsState {
  Adding
  Ready
  Finished
  Cleaned
} derive(Eq, Debug)

///|
pub struct App[W] {
  mut sub_apps : SubApps[W]
  mut plugin_names : Array[String]
  mut plugin_registry : Array[PluginGroupEntry[W]]
  mut plugins_state : PluginsState
  runner_builder : RunnerBuilder[W]?
}

///|
pub fn App::new(world : @ecs.World) -> App[@ecs.World] {
  let app_exit_key : @ecs.MessageKey[AppExit] = @ecs.Message::message()
  let main_sub_app = SubApp::new(world)
    .add_message(app_exit_key)
    .set_update_schedule(Some(Main))
  App::{
    sub_apps: SubApps::new(main_sub_app),
    plugin_names: [],
    plugin_registry: [],
    plugins_state: Adding,
    runner_builder: None,
  }
}

///|
fn[W] App::plugin_name_registered(self : App[W], plugin_name : String) -> Bool {
  for existing in self.plugin_names {
    if existing == plugin_name {
      return true
    }
  }
  false
}

///|
fn[W] App::add_plugin_entry(
  self : App[W],
  entry : PluginGroupEntry[W],
) -> App[W] {
  if entry.is_unique && self.plugin_name_registered(entry.id) {
    abort("Duplicate unique plugin: \{entry.id}")
  }
  self.plugin_names.push(entry.id)
  let app = (entry.plugin)(self)
  app.plugin_registry.push(entry)
  app.plugins_state = Adding
  app
}

///|
fn[W] App::add_plugin_entries(
  self : App[W],
  entries : Array[PluginGroupEntry[W]],
) -> App[W] {
  let mut app = self
  for entry in entries {
    app = app.add_plugin_entry(entry)
  }
  app
}

///|
fn[W] App::plugins_all_ready(self : App[W]) -> Bool {
  for entry in self.plugin_registry {
    if !(entry.ready)(self) {
      return false
    }
  }
  true
}

///|
pub fn[W] App::plugins_state(self : App[W]) -> PluginsState {
  if self.plugins_state == Adding && self.plugins_all_ready() {
    self.plugins_state = Ready
  }
  self.plugins_state
}

///|
pub fn[W] App::finish_plugins(self : App[W]) -> App[W] {
  if self.plugins_state == Adding {
    if !self.plugins_all_ready() {
      return self
    }
    self.plugins_state = Ready
  }
  if self.plugins_state != Ready {
    return self
  }
  let entries = self.plugin_registry
  let mut app = self
  for entry in entries {
    app = (entry.finish)(app)
  }
  app.plugins_state = Finished
  app
}

///|
pub fn[W] App::finish(self : App[W]) -> App[W] {
  self.finish_plugins()
}

///|
pub fn[W] App::cleanup_plugins(self : App[W]) -> App[W] {
  if self.plugins_state != Finished {
    return self
  }
  let entries = self.plugin_registry
  let mut app = self
  for entry in entries {
    app = (entry.cleanup)(app)
  }
  app.plugins_state = Cleaned
  app
}

///|
pub fn[W] App::cleanup(self : App[W]) -> App[W] {
  self.cleanup_plugins()
}

///|
fn[W] App::finalize_plugins(self : App[W]) -> App[W] {
  self.finish_plugins().cleanup_plugins()
}

///|
fn[W] App::plugins_finalized(self : App[W]) -> Bool {
  self.plugin_registry.length() == 0 || self.plugins_state == Cleaned
}

///|
pub fn[P : Plugin] App::add_plugins(
  self : App[@ecs.World],
  plugin : P,
) -> App[@ecs.World] {
  self.add_plugin_entry(plugin_group_entry_from_plugin(plugin))
}

///|
pub fn[W] App::plugin_names(self : App[W]) -> Array[String] {
  self.plugin_names
}

///|
pub fn[W] App::clear_plugin_names(self : App[W]) -> App[W] {
  self.plugin_names.clear()
  self
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
    system_config_param(pre_startup_system),
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
    system_config_param2(pre_startup_system),
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
    system_config_param3(pre_startup_system),
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
    system_config_param4(pre_startup_system),
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
    system_config_param(startup_system),
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
    system_config_param2(startup_system),
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
    system_config_param3(startup_system),
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
    system_config_param4(startup_system),
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
    system_config_param(post_startup_system),
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
    system_config_param2(post_startup_system),
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
    system_config_param3(post_startup_system),
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
    system_config_param4(post_startup_system),
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
    system_config_param(first_system),
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
    system_config_param2(first_system),
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
    system_config_param3(first_system),
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
    system_config_param4(first_system),
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
    system_config_param(pre_update_system),
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
    system_config_param2(pre_update_system),
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
    system_config_param3(pre_update_system),
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
    system_config_param4(pre_update_system),
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
    system_config_param(run_fixed_main_loop_system),
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
    system_config_param2(run_fixed_main_loop_system),
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
    system_config_param3(run_fixed_main_loop_system),
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
    system_config_param4(run_fixed_main_loop_system),
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
    system_config_param(fixed_first_system),
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
    system_config_param2(fixed_first_system),
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
    system_config_param3(fixed_first_system),
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
    system_config_param4(fixed_first_system),
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
    system_config_param(fixed_pre_update_system),
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
    system_config_param2(fixed_pre_update_system),
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
    system_config_param3(fixed_pre_update_system),
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
    system_config_param4(fixed_pre_update_system),
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
    system_config_param(fixed_update_system),
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
    system_config_param2(fixed_update_system),
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
    system_config_param3(fixed_update_system),
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
    system_config_param4(fixed_update_system),
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
    system_config_param(fixed_post_update_system),
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
    system_config_param2(fixed_post_update_system),
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
    system_config_param3(fixed_post_update_system),
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
    system_config_param4(fixed_post_update_system),
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
    system_config_param(fixed_last_system),
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
    system_config_param2(fixed_last_system),
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
    system_config_param3(fixed_last_system),
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
    system_config_param4(fixed_last_system),
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
    system_config_param(update_system),
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
    system_config_param2(update_system),
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
    system_config_param3(update_system),
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
    system_config_param4(update_system),
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
    system_config_param(spawn_scene_system),
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
    system_config_param2(spawn_scene_system),
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
    system_config_param3(spawn_scene_system),
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
    system_config_param4(spawn_scene_system),
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
    system_config_param(post_update_system),
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
    system_config_param2(post_update_system),
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
    system_config_param3(post_update_system),
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
    system_config_param4(post_update_system),
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
    system_config_param(last_system),
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
    system_config_param2(last_system),
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
    system_config_param3(last_system),
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
    system_config_param4(last_system),
  )
  self
}

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
  let execution_plan = schedule_execution_plan(
    schedule,
    stage,
    world,
    current_allowed_ambiguous_components(),
  )
  match execution_plan.build_error {
    Some(message) => {
      if execution_plan.report_build_error {
        report_world_error(
          world,
          @ecs.Invalid(message),
          ErrorContext::new(
            ErrorContextKind::Validation,
            "\{to_repr(stage).to_string()}::<schedule>",
            stage=Some(stage),
          ),
        )
      }
      current_schedule_stage_ref.val = None
      timeline_trace_end_span(
        TimelineTraceCategory::ScheduleStage,
        to_repr(stage).to_string(),
        stage_trace_start_us,
      )
      return
    }
    None => ()
  }
  // Runtime validation reports are produced by system execution outcomes.
  ignore(execution_plan.invalid_system_errors.length())
  ignore(execution_plan.report_invalid_system_errors)
  run_systems(
    world,
    execution_plan.schedule,
    execution_plan.execution_batches,
    Some(stage),
    executor_kind=execution_plan.executor_kind,
    apply_final_deferred=execution_plan.apply_final_deferred,
    executor_state_ref=Some(execution_plan.executor_state),
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
  let self = self.finalize_plugins()
  if !self.plugins_finalized() {
    return self
  }
  self.sub_apps = self.sub_apps.run_startup()
  self
}

///|
pub fn App::update(self : App[@ecs.World]) -> App[@ecs.World] {
  let self = self.finalize_plugins()
  if !self.plugins_finalized() {
    return self
  }
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
