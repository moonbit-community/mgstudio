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
pub(all) suberror ComponentHooksError {
  DuplicateRegistration(Int)
  DuplicateHookRegistration(Int, ComponentHookKind)
  ComponentAlreadyInUse(Int)
}

///|
pub(all) enum ComponentHookKind {
  OnAdd
  OnInsert
  OnReplace
  OnRemove
  OnDespawn
}

///|
pub struct HookContext {
  entity : @core.Entity
  component_id : Int
  caller : String?
}

///|
type DeferredHookCommand = (World) -> Unit

///|
pub struct DeferredWorld {
  world : World
}

///|
pub struct DeferredWorldCommands {
  world : World
}

///|
pub struct DeferredEntityCommands {
  commands : DeferredWorldCommands
  entity : @core.Entity
}

///|
pub struct ComponentHooks {
  on_add : ((DeferredWorld, HookContext) -> Unit)?
  on_insert : ((DeferredWorld, HookContext) -> Unit)?
  on_replace : ((DeferredWorld, HookContext) -> Unit)?
  on_remove : ((DeferredWorld, HookContext) -> Unit)?
  on_despawn : ((DeferredWorld, HookContext) -> Unit)?
}

///|
pub struct ComponentHooksBuilder[T] {
  world : World
  key : ComponentKey[T]
}

///|
pub fn DeferredWorld::world(self : DeferredWorld) -> World {
  self.world
}

///|
pub fn DeferredWorld::read_sequence(self : DeferredWorld) -> @core.Sequence {
  self.world.read_sequence()
}

///|
pub fn DeferredWorld::is_alive(
  self : DeferredWorld,
  entity : @core.Entity,
) -> Bool {
  self.world.is_alive(entity)
}

///|
pub fn DeferredWorld::spawn_empty(self : DeferredWorld) -> @core.Entity {
  self.world.spawn_empty()
}

///|
pub fn[T] DeferredWorld::get(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  self.world.get_by_key(entity, key)
}

///|
pub fn[T] DeferredWorld::get_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  self.get(entity, key)
}

///|
pub fn[T] DeferredWorld::contains(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  if !self.world.is_alive(entity) {
    return false
  }
  entity_has_component_id(self.world, key.id(), entity)
}

///|
pub fn[T] DeferredWorld::contains_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  self.contains(entity, key)
}

///|
pub fn[T] DeferredWorld::resource(
  self : DeferredWorld,
  key : ResourceKey[T],
) -> ResourceAccess[T] {
  self.world.resource(key)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::set(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  component : T,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.world.set_by_key(entity, key, component, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::set_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  component : T,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.set(entity, key, component, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::replace(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  component : T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.world.replace(entity, key, component, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::replace_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  component : T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.replace(entity, key, component, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::take(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> T? raise EcsError {
  self.world.take(entity, key, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::take_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> T? raise EcsError {
  self.take(entity, key, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::remove(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.world.remove_by_key(entity, key, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] DeferredWorld::remove_by_key(
  self : DeferredWorld,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.remove(entity, key, loc~)
}

///|
#callsite(autofill(loc))
pub fn DeferredWorld::despawn(
  self : DeferredWorld,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.world.despawn(entity, loc~)
}

///|
pub fn DeferredWorld::commands(self : DeferredWorld) -> DeferredWorldCommands {
  { world: self.world }
}

///|
pub fn DeferredWorldCommands::entity(
  self : DeferredWorldCommands,
  entity : @core.Entity,
) -> DeferredEntityCommands {
  { commands: self, entity }
}

///|
#callsite(autofill(loc))
pub fn DeferredEntityCommands::despawn(
  self : DeferredEntityCommands,
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.world.enqueue_deferred_hook_command(fn(world : World) {
    try! world.despawn(entity, loc~)
  })
}

///|
pub fn ComponentHooks::new(
  on_add? : ((DeferredWorld, HookContext) -> Unit)? = None,
  on_insert? : ((DeferredWorld, HookContext) -> Unit)? = None,
  on_replace? : ((DeferredWorld, HookContext) -> Unit)? = None,
  on_remove? : ((DeferredWorld, HookContext) -> Unit)? = None,
  on_despawn? : ((DeferredWorld, HookContext) -> Unit)? = None,
) -> ComponentHooks {
  { on_add, on_insert, on_replace, on_remove, on_despawn }
}

///|
pub fn[T] World::register_component_hooks_for_key(
  self : World,
  key : ComponentKey[T],
) -> ComponentHooksBuilder[T] {
  if self.component_hooks_registry.get(key.id()) is None {
    self.component_hooks_registry.set(key.id(), ComponentHooks::new())
  }
  ComponentHooksBuilder::{ world: self, key }
}

///|
pub fn[T : Component] World::register_component_hooks(
  self : World,
) -> ComponentHooksBuilder[T] {
  self.register_component_hooks_for_key(Component::component())
}

///|
pub fn[T] World::register_component_hooks_with(
  self : World,
  key : ComponentKey[T],
  hooks : ComponentHooks,
) -> Unit raise ComponentHooksError {
  if self.component_hooks_registry.contains(key.id()) {
    raise DuplicateRegistration(key.id())
  }
  self.component_hooks_registry.set(key.id(), hooks)
}

///|
fn World::component_hooks(self : World, component_id : Int) -> ComponentHooks? {
  self.component_hooks_registry.get(component_id)
}

///|
fn hook_caller_from_loc(loc : SourceLoc) -> String? {
  Some(loc.to_string())
}

///|
fn hook_context(
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> HookContext {
  { entity, component_id, caller }
}

///|
fn component_hooks_kind_registered(
  hooks : ComponentHooks,
  kind : ComponentHookKind,
) -> Bool {
  match kind {
    OnAdd => hooks.on_add is Some(_)
    OnInsert => hooks.on_insert is Some(_)
    OnReplace => hooks.on_replace is Some(_)
    OnRemove => hooks.on_remove is Some(_)
    OnDespawn => hooks.on_despawn is Some(_)
  }
}

///|
fn component_hooks_register_kind(
  world : World,
  component_id : Int,
  kind : ComponentHookKind,
  hook : (DeferredWorld, HookContext) -> Unit,
) -> Unit raise ComponentHooksError {
  let hooks = world
    .component_hooks(component_id)
    .unwrap_or(ComponentHooks::new())
  if component_hooks_kind_registered(hooks, kind) {
    raise DuplicateHookRegistration(component_id, kind)
  }
  let updated = match kind {
    OnAdd => ComponentHooks::{ ..hooks, on_add: Some(hook) }
    OnInsert => ComponentHooks::{ ..hooks, on_insert: Some(hook) }
    OnReplace => ComponentHooks::{ ..hooks, on_replace: Some(hook) }
    OnRemove => ComponentHooks::{ ..hooks, on_remove: Some(hook) }
    OnDespawn => ComponentHooks::{ ..hooks, on_despawn: Some(hook) }
  }
  world.component_hooks_registry.set(component_id, updated)
}

///|
pub fn[T] ComponentHooksBuilder::on_add(
  self : ComponentHooksBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.world, self.key.id(), OnAdd, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_insert(
  self : ComponentHooksBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.world, self.key.id(), OnInsert, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_replace(
  self : ComponentHooksBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.world, self.key.id(), OnReplace, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_remove(
  self : ComponentHooksBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.world, self.key.id(), OnRemove, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_despawn(
  self : ComponentHooksBuilder[T],
  hook : (DeferredWorld, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.world, self.key.id(), OnDespawn, hook)
  self
}

///|
fn World::enqueue_deferred_hook_command(
  self : World,
  command : DeferredHookCommand,
) -> Unit {
  self.deferred_hook_commands.push(command)
}

///|
fn World::begin_deferred_hook_command_scope(self : World) -> Bool {
  let outermost = self.deferred_hook_command_depth == 0
  self.deferred_hook_command_depth = self.deferred_hook_command_depth + 1
  outermost
}

///|
fn World::flush_deferred_hook_commands(self : World) -> Unit {
  while self.deferred_hook_commands.length() > 0 {
    let commands = self.deferred_hook_commands.copy()
    self.deferred_hook_commands.clear()
    for command in commands {
      command(self)
    }
  }
}

///|
fn World::end_deferred_hook_command_scope(
  self : World,
  outermost : Bool,
) -> Unit {
  self.deferred_hook_command_depth = self.deferred_hook_command_depth - 1
  if outermost {
    self.flush_deferred_hook_commands()
  }
}

///|
fn World::run_component_hook(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
  hook : (DeferredWorld, HookContext) -> Unit,
) -> Unit {
  hook(
    DeferredWorld::{ world: self },
    hook_context(entity, component_id, caller~),
  )
}

///|
fn World::run_component_add_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard self.component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_add is Some(on_add) {
    self.run_component_hook(entity, component_id, caller~, on_add)
  }
}

///|
fn World::run_component_insert_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard self.component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_insert is Some(on_insert) {
    self.run_component_hook(entity, component_id, caller~, on_insert)
  }
}

///|
fn World::run_component_replace_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard self.component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_replace is Some(on_replace) {
    self.run_component_hook(entity, component_id, caller~, on_replace)
  }
}

///|
fn World::run_component_remove_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard self.component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_remove is Some(on_remove) {
    self.run_component_hook(entity, component_id, caller~, on_remove)
  }
}

///|
fn World::run_component_despawn_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard self.component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_despawn is Some(on_despawn) {
    self.run_component_hook(entity, component_id, caller~, on_despawn)
  }
}
