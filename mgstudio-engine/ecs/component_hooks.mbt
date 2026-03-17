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
pub struct ComponentHooks {
  on_add : ((World, HookContext) -> Unit)?
  on_insert : ((World, HookContext) -> Unit)?
  on_replace : ((World, HookContext) -> Unit)?
  on_remove : ((World, HookContext) -> Unit)?
  on_despawn : ((World, HookContext) -> Unit)?
}

///|
pub struct ComponentHooksBuilder[T] {
  key : ComponentKey[T]
}

///|
pub fn ComponentHooks::new(
  on_add? : ((World, HookContext) -> Unit)? = None,
  on_insert? : ((World, HookContext) -> Unit)? = None,
  on_replace? : ((World, HookContext) -> Unit)? = None,
  on_remove? : ((World, HookContext) -> Unit)? = None,
  on_despawn? : ((World, HookContext) -> Unit)? = None,
) -> ComponentHooks {
  { on_add, on_insert, on_replace, on_remove, on_despawn }
}

///|
let component_hooks_registry : @hashmap.HashMap[Int, ComponentHooks] = @hashmap.HashMap::new()

///|
pub fn[T] register_component_hooks_for_key(
  key : ComponentKey[T],
) -> ComponentHooksBuilder[T] {
  if component_hooks_registry.get(key.id()) is None {
    component_hooks_registry.set(key.id(), ComponentHooks::new())
  }
  ComponentHooksBuilder::{ key, }
}

///|
pub fn[T : Component] register_component_hooks_for() -> ComponentHooksBuilder[T] {
  register_component_hooks_for_key(Component::component())
}

///|
pub fn[T] World::register_component_hooks_for_key(
  self : World,
  key : ComponentKey[T],
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  if self.component_has_been_used(key.id()) {
    raise ComponentAlreadyInUse(key.id())
  }
  register_component_hooks_for_key(key)
}

///|
pub fn[T : Component] World::register_component_hooks(
  self : World,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  self.register_component_hooks_for_key(Component::component())
}

///|
pub fn[T] register_component_hooks(
  key : ComponentKey[T],
  hooks : ComponentHooks,
) -> Unit raise ComponentHooksError {
  if component_hooks_registry.contains(key.id()) {
    raise DuplicateRegistration(key.id())
  }
  component_hooks_registry.set(key.id(), hooks)
}

///|
fn component_hooks(component_id : Int) -> ComponentHooks? {
  component_hooks_registry.get(component_id)
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
  component_id : Int,
  kind : ComponentHookKind,
  hook : (World, HookContext) -> Unit,
) -> Unit raise ComponentHooksError {
  let hooks = component_hooks(component_id).unwrap_or(ComponentHooks::new())
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
  component_hooks_registry.set(component_id, updated)
}

///|
pub fn[T] ComponentHooksBuilder::on_add(
  self : ComponentHooksBuilder[T],
  hook : (World, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.key.id(), OnAdd, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_insert(
  self : ComponentHooksBuilder[T],
  hook : (World, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.key.id(), OnInsert, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_replace(
  self : ComponentHooksBuilder[T],
  hook : (World, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.key.id(), OnReplace, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_remove(
  self : ComponentHooksBuilder[T],
  hook : (World, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.key.id(), OnRemove, hook)
  self
}

///|
pub fn[T] ComponentHooksBuilder::on_despawn(
  self : ComponentHooksBuilder[T],
  hook : (World, HookContext) -> Unit,
) -> ComponentHooksBuilder[T] raise ComponentHooksError {
  component_hooks_register_kind(self.key.id(), OnDespawn, hook)
  self
}

///|
fn World::run_component_add_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_add is Some(on_add) {
    on_add(self, hook_context(entity, component_id, caller~))
  }
}

///|
fn World::run_component_insert_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_insert is Some(on_insert) {
    on_insert(self, hook_context(entity, component_id, caller~))
  }
}

///|
fn World::run_component_replace_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_replace is Some(on_replace) {
    on_replace(self, hook_context(entity, component_id, caller~))
  }
}

///|
fn World::run_component_remove_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_remove is Some(on_remove) {
    on_remove(self, hook_context(entity, component_id, caller~))
  }
}

///|
fn World::run_component_despawn_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  caller? : String? = None,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_despawn is Some(on_despawn) {
    on_despawn(self, hook_context(entity, component_id, caller~))
  }
}
