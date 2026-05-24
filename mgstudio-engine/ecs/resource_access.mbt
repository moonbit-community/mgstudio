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
  priv world : World
  priv key : ResourceKey[T]
}

///|
pub struct ResourceMut[T] {
  priv world : World
  priv key : ResourceKey[T]
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
) -> ResourceMut[T]? {
  match self.get_resource(key) {
    Some(_) => Some(ResourceMut::{ world: self, key })
    None => None
  }
}

///|
pub fn[T] ResourceAccess::is_present(self : ResourceAccess[T]) -> Bool {
  self.key.resource_contains(self.world)
}

///|
pub fn[T] ResourceAccess::get(self : ResourceAccess[T]) -> T? {
  self.key.resource_get(self.world)
}

///|
pub fn[T] ResourceAccess::get_mut(self : ResourceAccess[T]) -> ResourceMut[T]? {
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
  self.world.remove_resource(self.key)
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
fn[T] resource_mut_value_or_abort(item : ResourceMut[T]) -> T {
  match item.key.resource_get(item.world) {
    Some(value) => value
    None => abort("ResourceMut expected a fetched resource")
  }
}

///|
fn[T] resource_mut_replace_value_or_abort(
  item : ResourceMut[T],
  value : T,
) -> Unit {
  if item.key.resource_contains(item.world) {
    item.key.resource_set(item.world, value)
  } else {
    abort("ResourceMut expected a fetched resource")
  }
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::peek(self : ResourceMut[T], loc~ : SourceLoc) -> T {
  ignore(loc)
  resource_mut_value_or_abort(self)
}

///|
pub fn[T] ResourceMut::is_added(self : ResourceMut[T]) -> Bool {
  self.world.is_resource_added(self.key, self.world.get_tick_context().ticks())
}

///|
pub fn[T] ResourceMut::is_changed(self : ResourceMut[T]) -> Bool {
  self.world.is_resource_changed(
    self.key,
    self.world.get_tick_context().ticks(),
  )
}

///|
pub fn[T] ResourceMut::added(self : ResourceMut[T]) -> @core.Tick {
  match self.world.resource_added_tick(self.key) {
    Some(tick) => tick
    None => abort("ResourceMut::added expected resource tick metadata")
  }
}

///|
pub fn[T] ResourceMut::last_changed(self : ResourceMut[T]) -> @core.Tick {
  match self.world.resource_changed_tick(self.key) {
    Some(tick) => tick
    None => abort("ResourceMut::last_changed expected resource tick metadata")
  }
}

///|
pub fn[T] ResourceMut::changed_by(self : ResourceMut[T]) -> String? {
  self.world.resource_changed_by(self.key)
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::set_changed(
  self : ResourceMut[T],
  loc~ : SourceLoc,
) -> Unit {
  self.world.mark_resource_changed(self.key, caller=Some(loc.to_string()))
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::set_added(
  self : ResourceMut[T],
  loc~ : SourceLoc,
) -> Unit {
  self.world.mark_resource_added(self.key, caller=Some(loc.to_string()))
}

///|
#callsite(autofill(loc))
pub fn[T, R] ResourceMut::modify(
  self : ResourceMut[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let value = self.peek(loc~)
  let result = f(value)
  resource_mut_replace_value_or_abort(self, value)
  self.set_changed(loc~)
  result
}

///|
#callsite(autofill(loc))
pub fn[T] ResourceMut::update(
  self : ResourceMut[T],
  f : (T) -> T,
  loc~ : SourceLoc,
) -> Unit {
  self.set(f(self.peek(loc~)), loc~)
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
  let current = self.peek(loc~)
  if current != value {
    self.set(value, loc~)
    true
  } else {
    false
  }
}
