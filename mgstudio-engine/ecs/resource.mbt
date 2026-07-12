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
/// Inserts or replaces a resource through the ECS mutation path.
///
/// The first insertion records both added and changed metadata. Later
/// replacements record changed metadata.
pub fn[T] World::insert_resource(
  self : World,
  key : ResourceKey[T],
  value : T,
) -> Unit {
  guard self.is_active() else {
    abort("cannot insert a resource after World closing has started")
  }
  let existed = key.resource_contains(self)
  key.resource_set(self, value)
  if !self.resource_finalizers.contains(key.id()) {
    self.resource_finalizer_order.push(key.id())
  }
  self.resource_finalizers.set(key.id(), fn(world) {
    key.resource_finalize_world(world)
  })
  self.resource_tick_registry.track(key.id(), fn(present_tick) {
    key.resource_check_change_ticks(self, present_tick)
  })
  if !existed {
    key.resource_record_added(self, resource_write_tick(self), None)
  }
  key.resource_record_changed(self, resource_write_tick(self), None)
}

///|
/// Returns the resource value for read-only use.
///
/// MoonBit cannot prevent direct mutation through the returned value when `T`
/// contains mutable fields. Use `World::get_resource_mut`,
/// `World::update_resource`, or the `ResourceMut` write APIs for writes that
/// must update resource change metadata.
pub fn[T] World::get_resource(self : World, key : ResourceKey[T]) -> T? {
  key.resource_get(self)
}

///|
pub fn[T] World::remove_resource(self : World, key : ResourceKey[T]) -> T? {
  guard self.is_active() else {
    abort("cannot remove a resource after World closing has started")
  }
  guard key.resource_remove(self) is Some(value) else { return None }
  self.resource_tick_registry.untrack(key.id())
  self.resource_finalizers.remove(key.id())
  for index in 0..<self.resource_finalizer_order.length() {
    if self.resource_finalizer_order[index] == key.id() {
      ignore(self.resource_finalizer_order.remove(index))
      break
    }
  }
  Some(value)
}

///|
/// Replaces an existing resource through the ECS mutation path.
///
/// The update closure receives the current value and must return the value to
/// store. Missing resources return `false` and do not create a resource.
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
  match key.resource_added_tick(self) {
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
  match key.resource_added_tick(self) {
    Some(tick) => system.contains(tick)
    None => false
  }
}

///|
pub fn[T] World::resource_added_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Tick? {
  key.resource_added_tick(self)
}

///|
pub fn[T] World::resource_changed_since(
  self : World,
  key : ResourceKey[T],
  tick : @core.Tick,
) -> Bool {
  match key.resource_changed_tick(self) {
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
  match key.resource_changed_tick(self) {
    Some(tick) => system.contains(tick)
    None => false
  }
}

///|
pub fn[T] World::resource_changed_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Tick? {
  key.resource_changed_tick(self)
}

///|
pub fn[T] World::resource_changed_by(
  self : World,
  key : ResourceKey[T],
) -> String? {
  key.resource_changed_caller(self)
}

///|
pub fn[T] World::mark_resource_changed(
  self : World,
  key : ResourceKey[T],
  caller? : String? = None,
) -> Unit {
  key.resource_record_changed(self, resource_write_tick(self), caller)
}

///|
pub fn[T] World::mark_resource_added(
  self : World,
  key : ResourceKey[T],
  caller? : String? = None,
) -> Unit {
  let tick = resource_write_tick(self)
  key.resource_record_added(self, tick, caller)
  key.resource_record_changed(self, tick, caller)
}
