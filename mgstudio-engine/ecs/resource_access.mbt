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
pub struct ResourceAccess[T] {
  world : World
  key : ResourceKey[T]
}

///|
pub struct ResourceMut[T] {
  world : World?
  key : ResourceKey[T]?
}

///|
pub fn[T] World::resource(
  self : World,
  key : ResourceKey[T],
) -> ResourceAccess[T] {
  ResourceAccess::{ world: self, key }
}

///|
pub fn[T] World::get_resource_mut(
  self : World,
  key : ResourceKey[T],
) -> ResourceMut[T]? raise EcsError {
  match self.get_resource(key) {
    Some(_) => Some(ResourceMut::{ world: Some(self), key: Some(key) })
    None => None
  }
}

///|
pub fn[T] World::get_resource_ref_mut(
  self : World,
  key : ResourceKey[T],
) -> Ref[T]? raise EcsError {
  match self.get_resource_mut(key) {
    Some(resource) => Some(Ref::new(resource.peek()))
    None => None
  }
}

///|
pub fn[T] World::get_resource_ref(
  self : World,
  key : ResourceKey[T],
) -> Ref[T]? raise EcsError {
  match self.get_resource(key) {
    Some(resource) => Some(Ref::new(resource))
    None => None
  }
}

///|
pub fn[T] ResourceAccess::is_present(self : ResourceAccess[T]) -> Bool {
  self.world.resources.contains(self.key.id())
}

///|
pub fn[T] ResourceAccess::get(self : ResourceAccess[T]) -> T? {
  guard self.world.resources.get(self.key.id()) is Some(slot) else {
    return None
  }
  try self.world.resource_value(self.key, slot.payload) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
}

///|
pub fn[T] ResourceAccess::get_mut(
  self : ResourceAccess[T],
) -> ResourceMut[T]? raise EcsError {
  self.world.get_resource_mut(self.key)
}

///|
pub fn[T] ResourceAccess::insert(self : ResourceAccess[T], value : T) -> Unit {
  self.world.insert_resource(self.key, value)
}

///|
pub fn[T] ResourceAccess::set(self : ResourceAccess[T], value : T) -> Bool {
  self.insert(value)
  true
}

///|
pub fn[T] ResourceAccess::upsert(self : ResourceAccess[T], value : T) -> Unit {
  self.insert(value)
}

///|
pub fn[T] ResourceAccess::remove(self : ResourceAccess[T]) -> T? {
  try! self.world.remove_resource(self.key)
}

///|
pub fn[T] ResourceAccess::update(
  self : ResourceAccess[T],
  update : (T) -> T,
) -> Bool {
  match self.get() {
    Some(value) => self.set(update(value))
    None => false
  }
}

///|
fn[T] resource_mut_world_or_abort(item : ResourceMut[T]) -> World {
  match item.world {
    Some(world) => world
    None => abort("ResourceMut expected a fetched resource")
  }
}

///|
fn[T] resource_mut_key_or_abort(item : ResourceMut[T]) -> ResourceKey[T] {
  match item.key {
    Some(key) => key
    None => abort("ResourceMut expected a fetched resource")
  }
}

///|
fn[T] resource_mut_value_or_abort(item : ResourceMut[T]) -> T {
  let world = resource_mut_world_or_abort(item)
  let key = resource_mut_key_or_abort(item)
  match world.resources.get(key.id()) {
    Some(slot) => try! world.resource_value(key, slot.payload)
    None => abort("ResourceMut expected a fetched resource")
  }
}

///|
fn[T] resource_mut_replace_value_or_abort(
  item : ResourceMut[T],
  value : T,
) -> Unit {
  let world = resource_mut_world_or_abort(item)
  let key = resource_mut_key_or_abort(item)
  match world.resources.get(key.id()) {
    Some(slot) => slot.payload = erased_value(value)
    None => abort("ResourceMut expected a fetched resource")
  }
}

///|
pub fn[T] ResourceMut::peek(self : ResourceMut[T]) -> T {
  resource_mut_value_or_abort(self)
}

///|
pub fn[T] ResourceMut::value(self : ResourceMut[T]) -> T {
  self.peek()
}

///|
pub fn[T] ResourceMut::is_added(self : ResourceMut[T]) -> Bool {
  let world = resource_mut_world_or_abort(self)
  world.is_resource_added(
    resource_mut_key_or_abort(self),
    world.get_sequence_context().sequence(),
  )
}

///|
pub fn[T] ResourceMut::is_changed(self : ResourceMut[T]) -> Bool {
  let world = resource_mut_world_or_abort(self)
  world.is_resource_changed(
    resource_mut_key_or_abort(self),
    world.get_sequence_context().sequence(),
  )
}

///|
pub fn[T] ResourceMut::added(self : ResourceMut[T]) -> @core.Sequence {
  let world = resource_mut_world_or_abort(self)
  match world.resource_added_tick(resource_mut_key_or_abort(self)) {
    Some(sequence) => sequence
    None => abort("ResourceMut::added expected resource sequence metadata")
  }
}

///|
pub fn[T] ResourceMut::last_changed(self : ResourceMut[T]) -> @core.Sequence {
  let world = resource_mut_world_or_abort(self)
  match world.resource_changed_tick(resource_mut_key_or_abort(self)) {
    Some(sequence) => sequence
    None =>
      abort("ResourceMut::last_changed expected resource sequence metadata")
  }
}

///|
pub fn[T] ResourceMut::changed_by(self : ResourceMut[T]) -> String? {
  let world = resource_mut_world_or_abort(self)
  world.resource_changed_by(resource_mut_key_or_abort(self))
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::set_changed(
  self : ResourceMut[T],
  loc~ : SourceLoc,
) -> Unit {
  let world = resource_mut_world_or_abort(self)
  world.mark_resource_changed(
    resource_mut_key_or_abort(self),
    caller=Some(loc.to_string()),
  )
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::set_added(
  self : ResourceMut[T],
  loc~ : SourceLoc,
) -> Unit {
  let world = resource_mut_world_or_abort(self)
  world.mark_resource_added(
    resource_mut_key_or_abort(self),
    caller=Some(loc.to_string()),
  )
}

///|
#callsite(autofill(loc))
pub fn[T, R] ResourceMut::modify(
  self : ResourceMut[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let value = self.peek()
  let result = f(value)
  self.set_changed(loc~)
  resource_mut_replace_value_or_abort(self, value)
  result
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::update(
  self : ResourceMut[T],
  f : (T) -> T,
  loc~ : SourceLoc,
) -> Unit {
  self.set(f(self.peek()), loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::set(
  self : ResourceMut[T],
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  self.set_changed(loc~)
  resource_mut_replace_value_or_abort(self, value)
}

///|
#callsite(autofill(loc))
pub fn[T : Eq] ResourceMut::set_if_neq(
  self : ResourceMut[T],
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
