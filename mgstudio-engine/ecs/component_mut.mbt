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
struct ComponentMutWriteback[T] {
  world : World
  key : ComponentKey[T]
  entity : @core.Entity
}

///|
pub struct ComponentMut[T] {
  value_ref : Ref[T]
  ticks : @core.ComponentTicks
  system : @core.SystemTicks
  mut original_payload : Json
  mut force_changed : Bool
  writeback : ComponentMutWriteback[T]?
}

///|
pub fn[T] ComponentMut::get(self : ComponentMut[T]) -> T {
  self.value_ref.val
}

///|
pub fn[T] ComponentMut::get_ref(self : ComponentMut[T]) -> Ref[T] {
  self.value_ref
}

///|
pub fn[T] ComponentMut::ticks(self : ComponentMut[T]) -> @core.ComponentTicks {
  self.ticks
}

///|
pub fn[T] ComponentMut::is_added(self : ComponentMut[T]) -> Bool {
  self.ticks.is_added(self.system)
}

///|
pub fn[T] ComponentMut::is_changed(self : ComponentMut[T]) -> Bool {
  self.ticks.is_changed(self.system)
}

///|
pub fn[T] ComponentMut::set_changed(self : ComponentMut[T]) -> Unit {
  self.force_changed = true
}

///|
pub fn[T] ComponentMut::has_writeback(self : ComponentMut[T]) -> Bool {
  self.writeback is Some(_)
}

///|
pub fn[T : ToJson] ComponentMut::has_pending_writeback(
  self : ComponentMut[T],
) -> Bool {
  self.force_changed || self.value_ref.val.to_json() != self.original_payload
}

///|
pub fn[T : ToJson] ComponentMut::flush(self : ComponentMut[T]) -> Bool {
  guard self.has_pending_writeback() else { return false }
  guard self.writeback is Some(writeback) else { return false }
  let payload = self.value_ref.val.to_json()
  let store_ref = writeback.world.ensure_component_store(writeback.key.id())
  let tick = component_write_change_tick(writeback.world)
  store_ref.val.set(writeback.entity, payload, tick) |> ignore
  self.original_payload = payload
  self.force_changed = false
  true
}
