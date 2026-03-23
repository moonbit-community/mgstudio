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
/// Component-key-based accessor that mirrors `ComponentStore` operations.
///
/// This is used to migrate store-style callsites to key-based ECS
/// without requiring an immediate rewrite to query helpers.
pub struct ComponentAccess[T] {
  world : World
  key : ComponentKey[T]
}

///|
pub fn[T] World::component(
  self : World,
  key : ComponentKey[T],
) -> ComponentAccess[T] {
  ComponentAccess::{ world: self, key }
}

///|
pub fn[T] ComponentAccess::len(self : ComponentAccess[T]) -> Int {
  match self.world.component_store(self.key.id()) {
    Some(store_ref) => store_ref.val.len()
    None => 0
  }
}

///|
pub fn[T] ComponentAccess::contains(
  self : ComponentAccess[T],
  entity : @core.Entity,
) -> Bool {
  match self.world.component_store(self.key.id()) {
    Some(store_ref) => store_ref.val.contains(entity)
    None => false
  }
}

///|
pub fn[T] ComponentAccess::get(
  self : ComponentAccess[T],
  entity : @core.Entity,
) -> T? {
  guard self.world.component_store(self.key.id()) is Some(store_ref) else {
    return None
  }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  try self.world.component_value(self.key, entity, payload) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
}

///|
#callsite(autofill(loc))
pub fn[T] ComponentAccess::set(
  self : ComponentAccess[T],
  entity : @core.Entity,
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  let store_ref = self.world.ensure_component_store(self.key.id())
  let payload = erased_value(value)
  let replacing = store_ref.val.get(entity) is Some(_)
  if !replacing {
    return false
  }
  let outermost = self.world.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  self.world.run_component_replace_hooks(entity, self.key.id(), caller~)
  ignore(store_ref.val.set(entity, payload))
  self.world.run_component_insert_hooks(entity, self.key.id(), caller~)
  self.world.end_deferred_hook_command_scope(outermost)
  true
}

///|
#callsite(autofill(loc))
pub fn[T] ComponentAccess::update(
  self : ComponentAccess[T],
  entity : @core.Entity,
  update : (T) -> T,
  loc~ : SourceLoc,
) -> Bool {
  match self.get(entity) {
    Some(value) => self.set(entity, update(value), loc~)
    None => false
  }
}

///|
#callsite(autofill(loc))
pub fn[T] ComponentAccess::insert(
  self : ComponentAccess[T],
  entity : @core.Entity,
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  try! self.world.insert_component_with_requirements(
    entity,
    self.key.id(),
    erased_value(value),
    caller=hook_caller_from_loc(loc),
  )
}

///|
#callsite(autofill(loc))
pub fn[T] ComponentAccess::upsert(
  self : ComponentAccess[T],
  entity : @core.Entity,
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  self.insert(entity, value, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ComponentAccess::remove(
  self : ComponentAccess[T],
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> T? {
  guard self.world.component_store(self.key.id()) is Some(store_ref) else {
    return None
  }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
  let outermost = self.world.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  self.world.run_component_replace_hooks(entity, self.key.id(), caller~)
  self.world.run_component_remove_hooks(entity, self.key.id(), caller~)
  ignore(store_ref.val.remove(entity))
  self.world.ensure_removed_component_messages(self.key.id()).val.send(
    component_write_sequence(self.world),
    entity,
  )
  self.world.end_deferred_hook_command_scope(outermost)
  try self.world.component_value(self.key, entity, payload) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
}

///|
pub fn[T] ComponentAccess::for_each(
  self : ComponentAccess[T],
  f : (@core.Entity, T) -> Unit,
) -> Unit {
  guard self.world.component_store(self.key.id()) is Some(store_ref) else {
    return
  }
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    try self.world.component_value(self.key, entry.0, entry.1) catch {
      _ => ()
    } noraise {
      value => f(entry.0, value)
    }
  }
}
