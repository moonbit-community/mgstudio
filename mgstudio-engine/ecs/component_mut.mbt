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
pub struct ComponentMutWriteback[T] {
  world : World
  key : ComponentKey[T]
  entity : @core.Entity
}

///|
pub struct ComponentMut[T] {
  value_ref : Ref[T]
  ticks : @core.ComponentTicks
  system : @core.SystemTicks
  mut changed : Bool
  writeback : ComponentMutWriteback[T]?
}

///|
pub fn[T] ComponentMut::get(self : ComponentMut[T]) -> T {
  self.value_ref.val
}

///|
pub fn[T] ComponentMut::get_ref(self : ComponentMut[T]) -> Ref[T] {
  self.touch()
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
  self.touch()
}

///|
fn[T] ComponentMut::touch(self : ComponentMut[T]) -> Unit {
  guard !self.changed else { return }
  guard self.writeback is Some(writeback) else { return }
  guard writeback.world.component_store(writeback.key.id()) is Some(store_ref) else {
    return
  }
  let tick = component_write_change_tick(writeback.world)
  guard store_ref.val.set_changed(writeback.entity, tick) else { return }
  self.ticks.set_changed(tick)
  self.changed = true
}
