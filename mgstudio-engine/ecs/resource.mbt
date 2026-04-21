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
  let existed = self.resources.contains(key.id())
  let payload = erased_value(value)
  self.resources.set(key.id(), ResourceSlot::{ payload, })
  if !existed {
    self.record_resource_added(key.id())
  }
  self.record_resource_changed(key.id())
}

///|
pub fn[T] World::get_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  match self.resources.get(key.id()) {
    Some(slot) => Some(self.resource_value(key, slot.payload))
    None => None
  }
}

///|
pub fn[T] World::get_resource_ref(
  self : World,
  key : ResourceKey[T],
) -> Ref[T]? raise EcsError {
  match self.resources.get(key.id()) {
    Some(slot) => Some(self.resource_ref(key, slot.payload))
    None => None
  }
}

///|
pub fn[T] World::get_resource_ref_mut(
  self : World,
  key : ResourceKey[T],
) -> Ref[T]? raise EcsError {
  match self.resources.get(key.id()) {
    Some(slot) => {
      self.record_resource_changed(key.id())
      Some(self.resource_ref(key, slot.payload))
    }
    None => None
  }
}

///|
pub fn[T] World::remove_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  guard self.get_resource(key) is Some(value) else { return None }
  self.resources.remove(key.id())
  self.resource_added_sequences.remove(key.id())
  self.resource_changed_sequences.remove(key.id())
  self.resource_changed_callers.remove(key.id())
  Some(value)
}

///|
pub fn[T] World::update_resource(
  self : World,
  key : ResourceKey[T],
  update : (T) -> T,
) -> Bool raise EcsError {
  guard self.get_resource(key) is Some(old_value) else { return false }
  let new_value = update(old_value)
  self.insert_resource(key, new_value)
  true
}

///|
fn[T] World::resource_ref(
  _self : World,
  key : ResourceKey[T],
  payload : ErasedValue,
) -> Ref[T] raise EcsError {
  payload.to_ref() catch {
    _ =>
      raise ResourceTypeMismatch(
        key.id(),
        key.debug_name(),
        payload.type_name(),
      )
  }
}

///|
fn[T] World::resource_value(
  self : World,
  key : ResourceKey[T],
  payload : ErasedValue,
) -> T raise EcsError {
  self.resource_ref(key, payload).val
}

///|
pub fn[T] World::resource_added_since(
  self : World,
  key : ResourceKey[T],
  sequence : @core.Sequence,
) -> Bool {
  match self.resource_added_sequence(key.id()) {
    Some(recorded) => recorded > sequence
    None => false
  }
}

///|
pub fn[T] World::is_resource_added(
  self : World,
  key : ResourceKey[T],
  system : @core.SystemSequence,
) -> Bool {
  match self.resource_added_sequence(key.id()) {
    Some(sequence) => system.contains(sequence)
    None => false
  }
}

///|
pub fn[T] World::resource_added_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Sequence? {
  self.resource_added_sequence(key.id())
}

///|
pub fn[T] World::resource_changed_since(
  self : World,
  key : ResourceKey[T],
  sequence : @core.Sequence,
) -> Bool {
  match self.resource_changed_sequence(key.id()) {
    Some(recorded) => recorded > sequence
    None => false
  }
}

///|
pub fn[T] World::is_resource_changed(
  self : World,
  key : ResourceKey[T],
  system : @core.SystemSequence,
) -> Bool {
  match self.resource_changed_sequence(key.id()) {
    Some(sequence) => system.contains(sequence)
    None => false
  }
}

///|
pub fn[T] World::resource_changed_tick(
  self : World,
  key : ResourceKey[T],
) -> @core.Sequence? {
  self.resource_changed_sequence(key.id())
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
