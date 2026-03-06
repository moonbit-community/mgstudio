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
pub fn[T : ToJson] World::insert_resource(
  self : World,
  key : ResourceKey[T],
  value : T,
) -> Unit {
  self.insert_resource_with_change_tick(
    key,
    value,
    resource_write_change_tick(self, 0),
  )
}

///|
pub fn[T : ToJson] World::insert_resource_with_change_tick(
  self : World,
  key : ResourceKey[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  let payload = value.to_json()
  let effective_tick = resource_write_change_tick(self, change_tick)
  match self.resources.get(key.id()) {
    Some(slot) =>
      self.resources.set(key.id(), ResourceSlot::{
        payload,
        added_tick: slot.added_tick,
        changed_tick: effective_tick,
      })
    None =>
      self.resources.set(key.id(), ResourceSlot::{
        payload,
        added_tick: effective_tick,
        changed_tick: effective_tick,
      })
  }
}

///|
pub fn[T : @json.FromJson] World::get_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  match self.resources.get(key.id()) {
    Some(slot) => Some(self.decode_resource_payload(key, slot.payload))
    None => None
  }
}

///|
pub fn[T] World::get_resource_ticks(
  self : World,
  key : ResourceKey[T],
) -> @core.ComponentTicks? {
  match self.resources.get(key.id()) {
    Some(slot) => Some(resource_slot_ticks(slot))
    None => None
  }
}

///|
pub fn[T : @json.FromJson] World::remove_resource(
  self : World,
  key : ResourceKey[T],
) -> T? raise EcsError {
  guard self.get_resource(key) is Some(value) else { return None }
  self.resources.remove(key.id())
  Some(value)
}

///|
pub fn[T : ToJson + @json.FromJson] World::update_resource(
  self : World,
  key : ResourceKey[T],
  update : (T) -> T,
) -> Bool raise EcsError {
  guard self.get_resource(key) is Some(old_value) else { return false }
  let new_value = update(old_value)
  self.insert_resource_with_change_tick(
    key,
    new_value,
    resource_write_change_tick(self, 0),
  )
  true
}

///|
fn resource_write_change_tick(
  world : World,
  change_tick : @core.Tick,
) -> @core.Tick {
  if change_tick > 0 {
    return change_tick
  }
  let world_tick = world.read_change_tick()
  if world_tick > 0 {
    world_tick
  } else {
    1
  }
}

///|
fn resource_slot_ticks(slot : ResourceSlot) -> @core.ComponentTicks {
  let ticks = @core.ComponentTicks::new(slot.added_tick)
  ticks.set_changed(slot.changed_tick)
  ticks
}

///|
fn[T : @json.FromJson] World::decode_resource_payload(
  _self : World,
  key : ResourceKey[T],
  payload : Json,
) -> T raise EcsError {
  @json.from_json(payload) catch {
    err => raise ResourceDecodeFailed(key.id(), key.debug_name(), err)
  }
}
