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
pub fn[T] World::insert_resource(
  self : World,
  key : ResourceKey[T],
  value : T,
) -> Unit {
  let existed = (key.access.contains)(self)
  (key.access.set)(self, value)
  if existed {
    guard self.resources.get(key.id()) is Some(slot) else { return }
    ignore(slot)
  } else {
    self.resources.set(key.id(), ResourceSlot::{
      added_tick: None,
      changed_tick: None,
      changed_caller: None,
    })
  }
  if !existed {
    self.record_resource_added(key.id())
  }
  self.record_resource_changed(key.id())
}

///|
pub fn[T] World::get_resource(self : World, key : ResourceKey[T]) -> T? {
  (key.access.get)(self)
}

///|
pub fn[T] World::remove_resource(self : World, key : ResourceKey[T]) -> T? {
  guard (key.access.remove)(self) is Some(value) else { return None }
  self.resources.remove(key.id())
  Some(value)
}

///|
pub fn[T] World::update_resource(
  self : World,
  key : ResourceKey[T],
  update : (T) -> T,
) -> Bool {
  guard self.get_resource(key) is Some(old_value) else { return false }
  let new_value = update(old_value)
  self.insert_resource(key, new_value)
  true
}

///|
pub fn[T] World::resource_added_since(
  self : World,
  key : ResourceKey[T],
  tick : @core.Tick,
) -> Bool {
  match self.resource_added_tick_by_id(key.id()) {
    Some(recorded) =>
      @core.tick_is_newer_than(recorded, tick, self.read_change_tick())
    None => false
  }
}

///|
pub fn[T] World::is_resource_added(
  self : World,
  key : ResourceKey[T],
  system : @core.SystemTicks,
) -> Bool {
  match self.resource_added_tick_by_id(key.id()) {
    Some(tick) => system.contains(tick)
    None => false
  }
}

///|
pub fn[T] World::resource_added_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Tick? {
  self.resource_added_tick_by_id(key.id())
}

///|
pub fn[T] World::resource_changed_since(
  self : World,
  key : ResourceKey[T],
  tick : @core.Tick,
) -> Bool {
  match self.resource_changed_tick_by_id(key.id()) {
    Some(recorded) =>
      @core.tick_is_newer_than(recorded, tick, self.read_change_tick())
    None => false
  }
}

///|
pub fn[T] World::is_resource_changed(
  self : World,
  key : ResourceKey[T],
  system : @core.SystemTicks,
) -> Bool {
  match self.resource_changed_tick_by_id(key.id()) {
    Some(tick) => system.contains(tick)
    None => false
  }
}

///|
pub fn[T] World::resource_changed_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Tick? {
  self.resource_changed_tick_by_id(key.id())
}

///|
pub fn[T] World::resource_changed_by(
  self : World,
  key : ResourceKey[T],
) -> String? {
  self.resource_changed_caller(key.id())
}

///|
pub fn[T] World::mark_resource_changed(
  self : World,
  key : ResourceKey[T],
  caller? : String? = None,
) -> Unit {
  self.record_resource_changed_with_caller(key.id(), caller)
}

///|
pub fn[T] World::mark_resource_added(
  self : World,
  key : ResourceKey[T],
  caller? : String? = None,
) -> Unit {
  self.record_resource_added_with_caller(key.id(), caller)
  self.record_resource_changed_with_caller(key.id(), caller)
}
