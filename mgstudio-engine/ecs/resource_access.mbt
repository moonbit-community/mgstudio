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
pub fn[T] World::resource(
  self : World,
  key : ResourceKey[T],
) -> ResourceAccess[T] {
  ResourceAccess::{ world: self, key }
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
  guard self.get() is Some(value) else { return None }
  self.world.resources.remove(self.key.id())
  Some(value)
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
