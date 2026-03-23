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
  self.insert_resource_with_change_tick(key, value, 0)
}

///|
pub fn[T] World::insert_resource_with_change_tick(
  self : World,
  key : ResourceKey[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  ignore(change_tick)
  let payload = erased_value(value)
  self.resources.set(key.id(), ResourceSlot::{ payload, })
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
  change_tick : @core.Tick,
) -> Ref[T]? raise EcsError {
  ignore(change_tick)
  self.get_resource_ref(key)
}

///|
pub fn[T] World::remove_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  guard self.get_resource(key) is Some(value) else { return None }
  self.resources.remove(key.id())
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
  self.insert_resource_with_change_tick(key, new_value, 0)
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
