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
  DuplicatePlugin(String)
}

///|
pub(open) trait Plugin {
  fn build(Self, App[@ecs.World]) -> App[@ecs.World]
  fn name(Self) -> String = _
  fn is_unique(Self) -> Bool = _
  fn ready(Self, App[@ecs.World]) -> Bool = _
  fn finish(Self, App[@ecs.World]) -> App[@ecs.World] = _
  fn cleanup(Self, App[@ecs.World]) -> App[@ecs.World] = _
}

///|
impl Plugin with fn name(self) {
  ignore(self)
  "mgstudio.app.Plugin"
}

///|
impl Plugin with fn is_unique(_self) {
  true
}

///|
impl Plugin with fn ready(_self, _app) {
  true
}

///|
impl Plugin with fn finish(_self, app) {
  app
}

///|
impl Plugin with fn cleanup(_self, app) {
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
  fn build(Self) -> PluginGroupBuilder[@ecs.World]
  fn name(Self) -> String = _
}

///|
pub struct NoopPluginGroup {}

///|
impl PluginGroup with fn name(self) {
  ignore(self)
  "mgstudio.app.PluginGroup"
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
fn[W] plugin_group_placeholder_entry() -> PluginGroupEntry[W] {
  plugin_group_entry_new(
    "mgstudio.app.PlaceholderPlugin",
    fn(app) { app },
    is_unique=false,
    ready=plugin_group_ready_default,
    finish=plugin_group_finish_default,
    cleanup=plugin_group_cleanup_default,
  )
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
  self.plugin_group_insert_entry_at(entry, self.plugins.length())
}

///|
fn[W] PluginGroupBuilder::plugin_group_insert_entry_at(
  self : PluginGroupBuilder[W],
  entry : PluginGroupEntry[W],
  index : Int,
) -> PluginGroupBuilder[W] {
  let mut target_index = index
  if target_index < 0 {
    target_index = 0
  }
  if target_index > self.plugins.length() {
    target_index = self.plugins.length()
  }
  if self.plugin_group_find_index(entry.id) is Some(old_index) {
    self.plugins.remove(old_index) |> ignore
    if old_index < target_index {
      target_index = target_index - 1
    }
  }
  self.plugins.insert(target_index, entry)
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
  let enabled = self.plugins[index].enabled
  self.plugins[index] = entry
  self.plugins[index].enabled = enabled
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
pub fn[P : Plugin] PluginGroupBuilder::try_add(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  let id = P::name(plugin)
  if self.plugin_group_contains_id(id) {
    raise DuplicatePlugin(id)
  }
  self.plugin_group_add_entry(plugin_group_entry_from_plugin(plugin))
}

///|
pub fn[G : PluginGroup] PluginGroupBuilder::add_group(
  self : PluginGroupBuilder[@ecs.World],
  group : G,
) -> PluginGroupBuilder[@ecs.World] {
  let mut builder = self
  let group_builder = G::build(group)
  for entry in group_builder.plugins {
    builder = builder.plugin_group_insert_entry_at(
      entry,
      builder.plugins.length(),
    )
  }
  builder
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::add_before(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] {
  try! self.try_add_before_overwrite(target, plugin)
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::try_add_before(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  let plugin_id = Insert::name(plugin)
  if self.plugin_group_contains_id(plugin_id) {
    raise DuplicatePlugin(plugin_id)
  }
  self.try_add_before_overwrite(target, plugin)
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::try_add_before_overwrite(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  let target_id = Target::name(target)
  guard self.plugin_group_find_index(target_id) is Some(target_index) else {
    raise MissingPlugin(target_id)
  }
  self.plugin_group_insert_entry_at(
    plugin_group_entry_from_plugin(plugin),
    target_index,
  )
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::add_after(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] {
  try! self.try_add_after_overwrite(target, plugin)
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::try_add_after(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  let plugin_id = Insert::name(plugin)
  if self.plugin_group_contains_id(plugin_id) {
    raise DuplicatePlugin(plugin_id)
  }
  self.try_add_after_overwrite(target, plugin)
}

///|
pub fn[Target : Plugin, Insert : Plugin] PluginGroupBuilder::try_add_after_overwrite(
  self : PluginGroupBuilder[@ecs.World],
  target : Target,
  plugin : Insert,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  let target_id = Target::name(target)
  guard self.plugin_group_find_index(target_id) is Some(target_index) else {
    raise MissingPlugin(target_id)
  }
  self.plugin_group_insert_entry_at(
    plugin_group_entry_from_plugin(plugin),
    target_index + 1,
  )
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
fn[W] PluginGroupBuilder::plugin_group_try_enable_id(
  self : PluginGroupBuilder[W],
  id : String,
) -> PluginGroupBuilder[W] raise PluginGroupError {
  guard self.plugin_group_find_index(id) is Some(index) else {
    raise MissingPlugin(id)
  }
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
  try! self.plugin_group_try_enable_id(P::name(plugin))
}

///|
pub fn[P : Plugin] PluginGroupBuilder::try_enable(
  self : PluginGroupBuilder[@ecs.World],
  plugin : P,
) -> PluginGroupBuilder[@ecs.World] raise PluginGroupError {
  self.plugin_group_try_enable_id(P::name(plugin))
}

///|
pub impl PluginGroup for PluginGroupBuilder[@ecs.World] with fn build(self) {
  self
}

///|
pub impl PluginGroup for PluginGroupBuilder[@ecs.World] with fn name(self) {
  self.group_name
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with fn name(self) {
  if self.group_name == "" {
    "mgstudio.app.PluginGroupBuilder"
  } else {
    self.group_name
  }
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with fn is_unique(_self) {
  false
}

///|
pub impl Plugin for PluginGroupBuilder[@ecs.World] with fn build(self, app) {
  app.add_plugin_entries(self.build_entries())
}

///|
pub fn NoopPluginGroup::NoopPluginGroup() -> NoopPluginGroup {
  NoopPluginGroup::{  }
}

///|
pub impl PluginGroup for NoopPluginGroup with fn name(_self) {
  "mgstudio.app.NoopPluginGroup"
}

///|
pub impl PluginGroup for NoopPluginGroup with fn build(_self) {
  let builder : PluginGroupBuilder[@ecs.World] = PluginGroupBuilder::start_named(
    "mgstudio.app.NoopPluginGroup",
  )
  builder
}

///|
pub impl Plugin for NoopPluginGroup with fn name(_self) {
  "mgstudio.app.NoopPluginGroup"
}

///|
pub impl Plugin for NoopPluginGroup with fn build(_self, app) {
  app
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
pub type StatefulRunConditionFn[W] = (W) -> Bool

///|
priv struct RunConditionStateCell[S] {
  mut value : S
}

///|
pub struct RunConditionState[S] {
  priv cell : RunConditionStateCell[S]
}

///|
pub fn[S] RunConditionState::get(self : RunConditionState[S]) -> S {
  self.cell.value
}

///|
pub fn[S] RunConditionState::set(
  self : RunConditionState[S],
  value : S,
) -> Unit {
  self.cell.value = value
}

///|
pub fn[S] RunConditionState::update(
  self : RunConditionState[S],
  f : (S) -> S,
) -> Unit {
  self.cell.value = f(self.cell.value)
}

///|
pub struct RunConditionConfig[W] {
  priv condition : StatefulRunConditionFn[W]
  priv clone_condition : () -> RunConditionConfig[W]
}

///|
pub fn[W] RunConditionConfig::run(
  self : RunConditionConfig[W],
  world : W,
) -> Bool {
  (self.condition)(world)
}

///|
pub fn[W] RunConditionConfig::clone(
  self : RunConditionConfig[W],
) -> RunConditionConfig[W] {
  (self.clone_condition)()
}

///|
pub fn[W] run_condition(cond : RunConditionFn[W]) -> RunConditionConfig[W] {
  RunConditionConfig::{
    condition: fn(world : W) { cond(world) },
    clone_condition: fn() { run_condition(cond) },
  }
}

///|
pub fn[W] run_condition_fn(cond : () -> Bool) -> RunConditionConfig[W] {
  RunConditionConfig::{
    condition: fn(_world : W) { cond() },
    clone_condition: fn() { run_condition_fn(cond) },
  }
}

///|
pub fn[W, S] stateful_run_condition(
  init_state : S,
  cond : (W, RunConditionState[S]) -> Bool,
) -> RunConditionConfig[W] {
  let cell = RunConditionStateCell::{ value: init_state }
  let state = RunConditionState::{ cell, }
  RunConditionConfig::{
    condition: fn(world : W) { cond(world, state) },
    clone_condition: fn() { stateful_run_condition(init_state, cond) },
  }
}

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
  fn init_state(@ecs.World) -> SystemParamState[Self]
  fn get(SystemParamState[Self]) -> Self raise
  fn store(Self, SystemParamState[Self]) -> Unit
  fn access(@ecs.World) -> SystemAccess = _
}

///|
impl SystemParam with fn access(_world) {
  SystemAccess::new()
}

///|
fn system_access_from_param_accesses(
  param_accesses : Array[SystemAccess],
) -> SystemAccess {
  let access = SystemAccess::new()
  for param_access in param_accesses {
    system_access_merge_validated(access, param_access, @utils.IntBitSet::new())
  }
  access
}

///|
pub struct SystemParamState[P] {
  priv get_param : () -> P raise
  priv store_param : (P) -> Unit
}

///|
pub fn[P] SystemParamState::new(
  get_param : () -> P raise,
  store_param : (P) -> Unit,
) -> SystemParamState[P] {
  { get_param, store_param }
}

///|
pub fn[P] SystemParamState::stateless(
  get_param : () -> P raise,
) -> SystemParamState[P] {
  { get_param, store_param: fn(_value : P) { () } }
}

///|
pub fn[P] SystemParamState::get(self : SystemParamState[P]) -> P raise {
  (self.get_param)()
}

///|
pub fn[P] SystemParamState::store(
  self : SystemParamState[P],
  value : P,
) -> Unit {
  (self.store_param)(value)
}

///|
priv struct SystemParamStateSlot[P] {
  mut state : SystemParamState[P]?
}

///|
fn[P] system_param_state_slot_new() -> SystemParamStateSlot[P] {
  { state: None }
}

///|
fn[P : SystemParam] SystemParamStateSlot::get_or_init(
  self : SystemParamStateSlot[P],
  world : @ecs.World,
) -> SystemParamState[P] {
  match self.state {
    Some(state) => state
    None => {
      let state = P::init_state(world)
      self.state = Some(state)
      state
    }
  }
}

///|
pub(open) trait Resource {
  fn resource() -> @ecs.ResourceKey[Self]
}

///|
pub struct Res[T] {
  value : T
  scope : SystemParamScope?
  key_id : Int?
}

///|
pub fn[T] Res::get(self : Res[T]) -> T {
  self.value
}

///|
fn[T] res_world_or_abort(item : Res[T]) -> @ecs.World {
  match item.scope {
    Some(scope) => scope.world_or_abort()
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
  world.is_resource_added(T::resource(), current_system_ticks())
}

///|
pub fn[T : Resource] Res::is_changed(self : Res[T]) -> Bool {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  world.is_resource_changed(T::resource(), current_system_ticks())
}

///|
pub fn[T : Resource] Res::added(self : Res[T]) -> @core.Tick {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  match world.resource_added_tick(T::resource()) {
    Some(tick) => tick
    None => abort("Res::added expected resource tick metadata")
  }
}

///|
pub fn[T : Resource] Res::last_changed(self : Res[T]) -> @core.Tick {
  let world = res_world_or_abort(self)
  ignore(res_key_id_or_abort(self))
  match world.resource_changed_tick(T::resource()) {
    Some(tick) => tick
    None => abort("Res::last_changed expected resource tick metadata")
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
  scope : SystemParamScope?
  key : @ecs.ResourceKey[T]?
}

///|
pub fn[T] ResMut::is_active(self : ResMut[T]) -> Bool {
  match self.scope {
    Some(scope) => scope.is_active()
    None => false
  }
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::get(self : ResMut[T], loc~ : SourceLoc) -> T {
  self.peek(loc~)
}

///|
fn[T] res_mut_world_or_abort(item : ResMut[T]) -> @ecs.World {
  match item.scope {
    Some(scope) => scope.world_or_abort()
    None => abort("ResMut expected a fetched system parameter")
  }
}

///|
fn[T] res_mut_inner_or_abort(item : ResMut[T]) -> @ecs.ResourceMut[T] {
  let world = res_mut_world_or_abort(item)
  match item.key {
    Some(key) =>
      match world.get_resource_mut(key) {
        Some(inner) => inner
        None => abort("ResMut expected a fetched resource")
      }
    None => abort("ResMut expected a fetched system parameter")
  }
}

///|
pub fn[T : Resource] ResMut::is_added(self : ResMut[T]) -> Bool {
  let world = res_mut_world_or_abort(self)
  world.is_resource_added(T::resource(), current_system_ticks())
}

///|
pub fn[T : Resource] ResMut::is_changed(self : ResMut[T]) -> Bool {
  let world = res_mut_world_or_abort(self)
  world.is_resource_changed(T::resource(), current_system_ticks())
}

///|
pub fn[T] ResMut::added(self : ResMut[T]) -> @core.Tick {
  res_mut_inner_or_abort(self).added()
}

///|
pub fn[T] ResMut::last_changed(self : ResMut[T]) -> @core.Tick {
  res_mut_inner_or_abort(self).last_changed()
}

///|
pub fn[T] ResMut::changed_by(self : ResMut[T]) -> String? {
  res_mut_inner_or_abort(self).changed_by()
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::set_changed(self : ResMut[T], loc~ : SourceLoc) -> Unit {
  res_mut_inner_or_abort(self).set_changed(loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::set_added(self : ResMut[T], loc~ : SourceLoc) -> Unit {
  res_mut_inner_or_abort(self).set_added(loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::peek(self : ResMut[T], loc~ : SourceLoc) -> T {
  res_mut_inner_or_abort(self).peek(loc~)
}

///|
#callsite(autofill(loc))
pub fn[T, R] ResMut::modify(
  self : ResMut[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  res_mut_inner_or_abort(self).modify(f, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::update(
  self : ResMut[T],
  f : (T) -> T,
  loc~ : SourceLoc,
) -> Unit {
  res_mut_inner_or_abort(self).update(f, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ResMut::set(self : ResMut[T], value : T, loc~ : SourceLoc) -> Unit {
  res_mut_inner_or_abort(self).set(value, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Eq] ResMut::set_if_neq(
  self : ResMut[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  res_mut_inner_or_abort(self).set_if_neq(value, loc~)
}

///|
fn[T] system_param_raise_invalid_missing_resource() -> T raise @ecs.SystemParamValidationError {
  raise @ecs.Invalid("Missing resource for system parameter")
}

///|
fn[T : Resource] world_resource_value_or_raise(
  world : @ecs.World,
) -> T raise @ecs.SystemParamValidationError {
  match world.get_resource(Resource::resource()) {
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
pub fn[P] system_param_empty_state(_world : @ecs.World) -> SystemParamState[P] {
  SystemParamState::stateless(fn() {
    abort("SystemParamState::get called for an empty system parameter state")
  })
}

///|
pub fn[T] system_param_store_no_state(
  _self : T,
  _state : SystemParamState[T],
) -> Unit {
  ()
}

///|
fn[P : SystemParam] system_param_get_or_record(
  state : SystemParamState[P],
) -> P? {
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
  let state = system_param_state_slot_new()
  OutputSystemConfig::{
    system: fn(_world : W) {
      let param_state = state.get_or_init(system_param_abort_missing_world())
      let param_opt : P? = system_param_get_or_record(param_state)
      guard param_opt is Some(param) else { return None }
      let output = system(param)
      P::store(param, param_state)
      Some(output)
    },
    access_factory: Some(fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P::access(world),
        @utils.IntBitSet::new(),
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
  let state = system_param_state_slot_new()
  system_config_with_access(
    fn(world : W) {
      guard (self.system)(world) is Some(output) else { return }
      let current_world = system_param_abort_missing_world()
      let param_state = state.get_or_init(current_world)
      let param_opt : P? = system_param_get_or_record(param_state)
      guard param_opt is Some(param) else { return }
      handler(In::{ value: output }, param)
      P::store(param, param_state)
    },
    fn(world : @ecs.World) {
      let access = self.output_system_base_access(world)
      system_access_merge_validated(
        access,
        P::access(world),
        @utils.IntBitSet::new(),
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
  let state = system_param_state_slot_new()
  system_config_with_access(
    fn(world : W) {
      guard (self.system)(world) is Some(output) else { return }
      let current_world = system_param_abort_missing_world()
      let param_state = state.get_or_init(current_world)
      let param_opt : P? = system_param_get_or_record(param_state)
      guard param_opt is Some(param) else { return }
      handler(output, param)
      P::store(param, param_state)
    },
    fn(world : @ecs.World) {
      let access = self.output_system_base_access(world)
      system_access_merge_validated(
        access,
        P::access(world),
        @utils.IntBitSet::new(),
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
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_ticks: [],
    last_run_tick: 0,
    access_factory: Some(access_factory),
  }
}

///|
#callsite(autofill(loc))
pub fn[W, P : SystemParam] system_config_param(
  system : (P) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W] system_config_fn(
  system : () -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fn(_world : W) { system() },
    fn(_world : @ecs.World) { SystemAccess::new() },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W] fallible_system_config_fn(
  system : () -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fn(_world : W) { run_fallible_system_body(system) },
    fn(_world : @ecs.World) { SystemAccess::new() },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W, P : SystemParam] fallible_system_config_param(
  system : (P) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W, P1 : SystemParam, P2 : SystemParam] system_config_param2(
  system : (P1, P2) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param2(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W, P1 : SystemParam, P2 : SystemParam] fallible_system_config_param2(
  system : (P1, P2) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param2(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] system_config_param3(
  system : (P1, P2, P3) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param3(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P3::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] fallible_system_config_param3(
  system : (P1, P2, P3) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param3(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P3::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] system_config_param4(
  system : (P1, P2, P3, P4) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param4(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P3::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P4::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
] system_config_param9(
  system : (P1, P2, P3, P4, P5, P6, P7, P8, P9) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param9(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
        P8::access(world),
        P9::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
  P10 : SystemParam,
] system_config_param10(
  system : (P1, P2, P3, P4, P5, P6, P7, P8, P9, P10) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param10(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
        P8::access(world),
        P9::access(world),
        P10::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] fallible_system_config_param4(
  system : (P1, P2, P3, P4) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param4(system),
    fn(world : @ecs.World) {
      let access = SystemAccess::new()
      system_access_merge_validated(
        access,
        P1::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P2::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P3::access(world),
        @utils.IntBitSet::new(),
      )
      system_access_merge_validated(
        access,
        P4::access(world),
        @utils.IntBitSet::new(),
      )
      access
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] system_config_param5(
  system : (P1, P2, P3, P4, P5) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param5(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] fallible_system_config_param5(
  system : (P1, P2, P3, P4, P5) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param5(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] system_config_param6(
  system : (P1, P2, P3, P4, P5, P6) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param6(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] fallible_system_config_param6(
  system : (P1, P2, P3, P4, P5, P6) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param6(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] system_config_param7(
  system : (P1, P2, P3, P4, P5, P6, P7) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param7(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] fallible_system_config_param7(
  system : (P1, P2, P3, P4, P5, P6, P7) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param7(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] system_config_param8(
  system : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    system_param8(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
        P8::access(world),
      ])
    },
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] fallible_system_config_param8(
  system : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit raise,
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system_config_with_access(
    fallible_system_param8(system),
    fn(world : @ecs.World) {
      system_access_from_param_accesses([
        P1::access(world),
        P2::access(world),
        P3::access(world),
        P4::access(world),
        P5::access(world),
        P6::access(world),
        P7::access(world),
        P8::access(world),
      ])
    },
    loc~,
  )
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
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_ticks: [],
    last_run_tick: 0,
    access_factory: None,
  }
}

///|
fn[W, P : SystemParam] system_param(system : (P) -> Unit) -> SystemFn[W] {
  let state = system_param_state_slot_new()
  fn(_world : W) {
    let param_state = state.get_or_init(system_param_abort_missing_world())
    let param_opt : P? = system_param_get_or_record(param_state)
    guard param_opt is Some(param) else { return }
    system(param)
    P::store(param, param_state)
  }
}

///|
fn[W, P : SystemParam] fallible_system_param(
  system : (P) -> Unit raise,
) -> SystemFn[W] {
  let state = system_param_state_slot_new()
  fn(_world : W) {
    let param_state = state.get_or_init(system_param_abort_missing_world())
    let param_opt : P? = system_param_get_or_record(param_state)
    guard param_opt is Some(param) else { return }
    run_fallible_system_body(() => system(param))
    P::store(param, param_state)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam] system_param2(
  system : (P1, P2) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    system(p1, p2)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam] fallible_system_param2(
  system : (P1, P2) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    run_fallible_system_body(() => system(p1, p2))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] system_param3(
  system : (P1, P2, P3) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    system(p1, p2, p3)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] fallible_system_param3(
  system : (P1, P2, P3) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    run_fallible_system_body(() => system(p1, p2, p3))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] system_param4(
  system : (P1, P2, P3, P4) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    system(p1, p2, p3, p4)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
  }
}

///|
fn[W, P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] fallible_system_param4(
  system : (P1, P2, P3, P4) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] system_param5(
  system : (P1, P2, P3, P4, P5) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    system(p1, p2, p3, p4, p5)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] fallible_system_param5(
  system : (P1, P2, P3, P4, P5) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
  }
}

///|
fn[
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
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    system(p1, p2, p3, p4, p5, p6)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
  }
}

///|
fn[
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
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5, p6))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] system_param7(
  system : (P1, P2, P3, P4, P5, P6, P7) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    system(p1, p2, p3, p4, p5, p6, p7)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] fallible_system_param7(
  system : (P1, P2, P3, P4, P5, P6, P7) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5, p6, p7))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] system_param8(
  system : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  let state8 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    let param_state8 = state8.get_or_init(world)
    let p8_opt : P8? = system_param_get_or_record(param_state8)
    guard p8_opt is Some(p8) else { return }
    system(p1, p2, p3, p4, p5, p6, p7, p8)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
    P8::store(p8, param_state8)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
] system_param9(
  system : (P1, P2, P3, P4, P5, P6, P7, P8, P9) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  let state8 = system_param_state_slot_new()
  let state9 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    let param_state8 = state8.get_or_init(world)
    let p8_opt : P8? = system_param_get_or_record(param_state8)
    guard p8_opt is Some(p8) else { return }
    let param_state9 = state9.get_or_init(world)
    let p9_opt : P9? = system_param_get_or_record(param_state9)
    guard p9_opt is Some(p9) else { return }
    system(p1, p2, p3, p4, p5, p6, p7, p8, p9)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
    P8::store(p8, param_state8)
    P9::store(p9, param_state9)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
  P10 : SystemParam,
] system_param10(
  system : (P1, P2, P3, P4, P5, P6, P7, P8, P9, P10) -> Unit,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  let state8 = system_param_state_slot_new()
  let state9 = system_param_state_slot_new()
  let state10 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    let param_state8 = state8.get_or_init(world)
    let p8_opt : P8? = system_param_get_or_record(param_state8)
    guard p8_opt is Some(p8) else { return }
    let param_state9 = state9.get_or_init(world)
    let p9_opt : P9? = system_param_get_or_record(param_state9)
    guard p9_opt is Some(p9) else { return }
    let param_state10 = state10.get_or_init(world)
    let p10_opt : P10? = system_param_get_or_record(param_state10)
    guard p10_opt is Some(p10) else { return }
    system(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
    P8::store(p8, param_state8)
    P9::store(p9, param_state9)
    P10::store(p10, param_state10)
  }
}

///|
fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] fallible_system_param8(
  system : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit raise,
) -> SystemFn[W] {
  let state1 = system_param_state_slot_new()
  let state2 = system_param_state_slot_new()
  let state3 = system_param_state_slot_new()
  let state4 = system_param_state_slot_new()
  let state5 = system_param_state_slot_new()
  let state6 = system_param_state_slot_new()
  let state7 = system_param_state_slot_new()
  let state8 = system_param_state_slot_new()
  fn(_world : W) {
    let world = system_param_abort_missing_world()
    let param_state1 = state1.get_or_init(world)
    let p1_opt : P1? = system_param_get_or_record(param_state1)
    guard p1_opt is Some(p1) else { return }
    let param_state2 = state2.get_or_init(world)
    let p2_opt : P2? = system_param_get_or_record(param_state2)
    guard p2_opt is Some(p2) else { return }
    let param_state3 = state3.get_or_init(world)
    let p3_opt : P3? = system_param_get_or_record(param_state3)
    guard p3_opt is Some(p3) else { return }
    let param_state4 = state4.get_or_init(world)
    let p4_opt : P4? = system_param_get_or_record(param_state4)
    guard p4_opt is Some(p4) else { return }
    let param_state5 = state5.get_or_init(world)
    let p5_opt : P5? = system_param_get_or_record(param_state5)
    guard p5_opt is Some(p5) else { return }
    let param_state6 = state6.get_or_init(world)
    let p6_opt : P6? = system_param_get_or_record(param_state6)
    guard p6_opt is Some(p6) else { return }
    let param_state7 = state7.get_or_init(world)
    let p7_opt : P7? = system_param_get_or_record(param_state7)
    guard p7_opt is Some(p7) else { return }
    let param_state8 = state8.get_or_init(world)
    let p8_opt : P8? = system_param_get_or_record(param_state8)
    guard p8_opt is Some(p8) else { return }
    run_fallible_system_body(() => system(p1, p2, p3, p4, p5, p6, p7, p8))
    P1::store(p1, param_state1)
    P2::store(p2, param_state2)
    P3::store(p3, param_state3)
    P4::store(p4, param_state4)
    P5::store(p5, param_state5)
    P6::store(p6, param_state6)
    P7::store(p7, param_state7)
    P8::store(p8, param_state8)
  }
}

///|
priv struct AppExecutionContextState {
  mut current_system_ticks : @core.SystemTicks?
  mut current_schedule_stage : ScheduleStage?
  mut current_world : @ecs.World?
  mut current_system_param_scope : SystemParamScope?
  mut current_app_schedule : ScheduleRegistry[@ecs.World]?
  mut current_allowed_ambiguous_components : @utils.IntBitSet?
  mut current_allowed_ambiguous_resources : @utils.IntBitSet?
}

///|
let app_execution_context_state : AppExecutionContextState = {
  current_system_ticks: None,
  current_schedule_stage: None,
  current_world: None,
  current_system_param_scope: None,
  current_app_schedule: None,
  current_allowed_ambiguous_components: None,
  current_allowed_ambiguous_resources: None,
}

///|
pub fn current_system_ticks() -> @core.SystemTicks {
  match app_execution_context_state.current_system_ticks {
    Some(tick) => tick
    None => @core.SystemTicks::new(0, 0)
  }
}

///|
pub fn current_schedule_stage() -> ScheduleStage? {
  app_execution_context_state.current_schedule_stage
}

///|
pub fn current_world() -> @ecs.World? {
  app_execution_context_state.current_world
}

///|
fn current_allowed_ambiguous_components() -> @utils.IntBitSet {
  match app_execution_context_state.current_allowed_ambiguous_components {
    Some(allowed) => allowed
    None => @utils.IntBitSet::new()
  }
}

///|
fn current_allowed_ambiguous_resources() -> @utils.IntBitSet {
  match app_execution_context_state.current_allowed_ambiguous_resources {
    Some(allowed) => allowed
    None => @utils.IntBitSet::new()
  }
}

///|
pub fn run_current_fixed_update_schedule(world : @ecs.World) -> Unit {
  guard app_execution_context_state.current_app_schedule is Some(schedule) else {
    return
  }
  run_schedule_stage(world, schedule, FixedUpdate)
}

///|
pub fn run_current_schedule_stage(
  world : @ecs.World,
  stage : ScheduleStage,
) -> Unit {
  guard app_execution_context_state.current_app_schedule is Some(schedule) else {
    return
  }
  run_schedule_stage(world, schedule, stage)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with fn init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with fn get(
  _state,
) {
  @core.Message::reader(current_system_ticks())
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageReader[T] with fn store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with fn init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with fn get(
  _state,
) {
  @core.Message::writer(current_system_ticks().this_run)
}

///|
pub impl[T : @core.Message] SystemParam for @core.MessageWriter[T] with fn store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with fn init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with fn get(_state) {
  let world = system_param_abort_missing_world()
  Res::{
    value: world_resource_value_or_raise(world),
    scope: Some(current_system_param_scope_or_abort()),
    key_id: Some(T::resource().id()),
  }
}

///|
pub impl[T : Resource] SystemParam for Res[T] with fn store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for Res[T] with fn access(_world) {
  let access = SystemAccess::new()
  access.add_read_resource(T::resource().id())
  access
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with fn init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with fn get(_state) {
  let world = system_param_abort_missing_world()
  let _resource : T = world_resource_value_or_raise(world)
  ResMut::{
    scope: Some(current_system_param_scope_or_abort()),
    key: Some(T::resource()),
  }
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with fn store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : Resource] SystemParam for ResMut[T] with fn access(_world) {
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
  run_ifs : Array[RunConditionConfig[W]]
  chain_members : Array[SystemConfig[W]]?
  chain_ignore_deferred : Bool
  set : SystemSet?
  member_sets : Array[SystemSet]
  before : Array[SystemSet]
  after : Array[SystemSet]
  before_ignore_deferred : Array[SystemSet]
  after_ignore_deferred : Array[SystemSet]
  is_apply_deferred_node : Bool
  run_if_last_run_ticks : Array[@core.Tick]
  mut last_run_tick : @core.Tick
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
    chain_members: None,
    chain_ignore_deferred: false,
    set: None,
    member_sets: [],
    before: [],
    after: [],
    before_ignore_deferred: [],
    after_ignore_deferred: [],
    is_apply_deferred_node: false,
    run_if_last_run_ticks: [],
    last_run_tick: 0,
    access_factory: None,
  }
}

///|
#callsite(autofill(loc))
pub fn[W] system_config_world(
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> SystemConfig[W] {
  system(system_fn, loc~)
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
  self.run_ifs.push(run_condition(cond))
  self.run_if_last_run_ticks.push(0)
  self
}

///|
pub fn[W] SystemConfig::run_if_fn(
  self : SystemConfig[W],
  cond : () -> Bool,
) -> SystemConfig[W] {
  self.run_ifs.push(run_condition_fn(cond))
  self.run_if_last_run_ticks.push(0)
  self
}

///|
pub fn[W, S] SystemConfig::run_if_stateful(
  self : SystemConfig[W],
  init_state : S,
  cond : (W, RunConditionState[S]) -> Bool,
) -> SystemConfig[W] {
  self.run_ifs.push(stateful_run_condition(init_state, cond))
  self.run_if_last_run_ticks.push(0)
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
    begin_deferred_command_batch(world)
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
    begin_deferred_command_batch(world)
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
  fn chain(Self) -> SystemConfig[@ecs.World]
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
) with fn chain(self) {
  let (first, second) = self
  chain_group_config([first, second])
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with fn chain(self) {
  let (first, second, third) = self
  chain_group_config([first, second, third])
}

///|
pub impl ChainedSystemConfigs for (
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
  SystemConfig[@ecs.World],
) with fn chain(self) {
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
) with fn chain(self) {
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
) with fn chain(self) {
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
  mut plugin_build_depth : Int
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
    plugin_build_depth: 0,
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
  let index = self.plugin_registry.length()
  self.plugin_registry.push(plugin_group_placeholder_entry())
  self.plugin_build_depth = self.plugin_build_depth + 1
  let app = (entry.plugin)(self)
  app.plugin_build_depth = app.plugin_build_depth - 1
  app.plugin_names.push(entry.id)
  app.plugin_registry[index] = entry
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
    Ready
  } else {
    self.plugins_state
  }
}

///|
pub fn[W] App::is_building_plugins(self : App[W]) -> Bool {
  self.plugin_build_depth > 0
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
  let mut app = self
  let plugin_count = app.plugin_registry.length()
  for index in 0..<plugin_count {
    let entry = app.plugin_registry[index]
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
  let mut app = self
  let plugin_count = app.plugin_registry.length()
  for index in 0..<plugin_count {
    let entry = app.plugin_registry[index]
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
  match self.plugins_state() {
    Cleaned | Finished =>
      abort(
        "Plugins cannot be added after App::cleanup() or App::finish() has been called.",
      )
    Adding | Ready => ()
  }
  self.add_plugin_entry(plugin_group_entry_from_plugin(plugin))
}

///|
pub fn[P : Plugin] App::is_plugin_added(
  self : App[@ecs.World],
  plugin : P,
) -> Bool {
  self.plugin_name_registered(plugin.name())
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
pub fn[W] App::replace_sub_app(
  self : App[W],
  label : AppLabel,
  sub_app : SubApp[W],
) -> SubApp[W]? {
  self.sub_apps.replace(label, sub_app)
}

///|
pub fn[W] App::modify_sub_app(
  self : App[W],
  label : AppLabel,
  update : (SubApp[W]) -> SubApp[W],
) -> Bool {
  self.sub_apps.modify(label, update)
}

///|
pub fn[W] App::sub_app(self : App[W], label : AppLabel) -> SubApp[W] {
  match self.get_sub_app(label) {
    Some(sub_app) => sub_app
    None => abort("Missing sub app for label: \{to_repr(label).to_string()}")
  }
}

///|
pub fn[W] App::set_sub_app_extract(
  self : App[W],
  label : AppLabel,
  extract : SubAppExtractFn[W],
) -> App[W] {
  ignore(
    self.sub_apps.modify(label, fn(sub_app) { sub_app.set_extract(extract) }),
  )
  self
}

///|
pub fn[W] App::take_sub_app_extract(
  self : App[W],
  label : AppLabel,
) -> SubAppExtractFn[W]? {
  let mut extracted : SubAppExtractFn[W]? = None
  ignore(
    self.sub_apps.modify(label, fn(sub_app) {
      let (next_sub_app, extract) = sub_app.take_extract()
      extracted = extract
      next_sub_app
    }),
  )
  extracted
}

///|
pub fn[W] App::sub_apps(self : App[W]) -> Array[(AppLabel, SubApp[W])] {
  self.sub_apps.list()
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
  let has_resource = match self.sub_apps.main.world.get_resource(key) {
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
  match self.sub_apps.main.world.get_resource(key) {
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
pub fn[T : Resource] App::allow_ambiguous_resource(
  self : App[@ecs.World],
  key? : @ecs.ResourceKey[T] = T::resource(),
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.allow_ambiguous_resource(key~)
  self
}

///|
pub fn[T : Resource] App::is_ambiguous_resource_allowed(
  self : App[@ecs.World],
  key? : @ecs.ResourceKey[T] = T::resource(),
) -> Bool {
  self.sub_apps.main.is_ambiguous_resource_allowed(key~)
}

///|
pub fn[T] App::remove_resource(
  self : App[@ecs.World],
  key : @ecs.ResourceKey[T],
) -> T? {
  self.sub_apps.main.world.remove_resource(key)
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
#callsite(autofill(loc))
pub fn[W] App::add_pre_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreStartup,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Startup,
    system(system_fn, loc~),
  )
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
#callsite(autofill(loc))
pub fn[W] App::add_post_startup_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostStartup,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_first_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    First,
    system(system_fn, loc~),
  )
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
#callsite(autofill(loc))
pub fn[W] App::add_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PreUpdate,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_run_fixed_main_loop_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    RunFixedMainLoop,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_fixed_first_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedFirst,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_fixed_pre_update_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPreUpdate,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_fixed_update_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedUpdate,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_fixed_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedPostUpdate,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_fixed_last_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    FixedLast,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system(system_fn, loc~),
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
pub fn[
  W,
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] App::add_system_param5(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param5(update_system),
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
  P5 : SystemParam,
  P6 : SystemParam,
] App::add_system_param6(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5, P6) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param6(update_system),
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
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] App::add_system_param7(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5, P6, P7) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param7(update_system),
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
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] App::add_system_param8(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param8(update_system),
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
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
] App::add_system_param9(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5, P6, P7, P8, P9) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param9(update_system),
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
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
  P9 : SystemParam,
  P10 : SystemParam,
] App::add_system_param10(
  self : App[W],
  update_system : (P1, P2, P3, P4, P5, P6, P7, P8, P9, P10) -> Unit,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Update,
    system_config_param10(update_system),
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
#callsite(autofill(loc))
pub fn[W] App::add_spawn_scene_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    SpawnScene,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_post_update_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    PostUpdate,
    system(system_fn, loc~),
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
#callsite(autofill(loc))
pub fn[W] App::add_last_system(
  self : App[W],
  system_fn : SystemFn[W],
  loc~ : SourceLoc,
) -> App[W] {
  schedule_push_config(
    self.sub_apps.main.schedule,
    Last,
    system(system_fn, loc~),
  )
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
  app_execution_context_state.current_schedule_stage = Some(stage)
  let execution_plan = schedule_execution_plan(
    schedule,
    stage,
    world,
    current_allowed_ambiguous_components(),
    current_allowed_ambiguous_resources(),
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
      app_execution_context_state.current_schedule_stage = None
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
    executor_state=Some(execution_plan.executor_state),
  )
  app_execution_context_state.current_schedule_stage = None
  timeline_trace_end_span(
    TimelineTraceCategory::ScheduleStage,
    to_repr(stage).to_string(),
    stage_trace_start_us,
  )
}

///|
pub fn App::run_startup(self : App[@ecs.World]) -> App[@ecs.World] {
  if self.is_building_plugins() {
    abort("App::run_startup() was called while a plugin was building.")
  }
  let self = self.finalize_plugins()
  if !self.plugins_finalized() {
    return self
  }
  self.sub_apps = self.sub_apps.run_startup()
  self
}

///|
pub fn App::update(self : App[@ecs.World]) -> App[@ecs.World] {
  if self.is_building_plugins() {
    abort("App::update() was called while a plugin was building.")
  }
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
pub fn App::shutdown(self : App[@ecs.World]) -> App[@ecs.World] {
  let app = self.finalize_plugins()
  app.sub_apps = app.sub_apps.shutdown()
  app
}

///|
pub fn App::run(self : App[@ecs.World]) -> Unit {
  if self.is_building_plugins() {
    abort("App::run() was called while a plugin was building.")
  }
  let shutdown_worlds = self.sub_apps.shutdown_worlds()
  defer (for world in shutdown_worlds {
    world.close()
  })
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
