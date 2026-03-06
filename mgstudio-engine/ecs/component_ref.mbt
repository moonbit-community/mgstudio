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
pub struct ComponentRef[T] {
  value : T
  ticks : @core.ComponentTicks
  system : @core.SystemTicks
}

///|
pub fn[T] ComponentRef::value(self : ComponentRef[T]) -> T {
  self.value
}

///|
pub fn[T] ComponentRef::ticks(self : ComponentRef[T]) -> @core.ComponentTicks {
  self.ticks
}

///|
pub fn[T] ComponentRef::is_added(self : ComponentRef[T]) -> Bool {
  self.ticks.is_added(self.system)
}

///|
pub fn[T] ComponentRef::is_changed(self : ComponentRef[T]) -> Bool {
  self.ticks.is_changed(self.system)
}

///|
pub fn[A : @json.FromJson] World::get_ref(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[A],
) -> ComponentRef[A]? raise EcsError {
  guard self.get(entity, key) is Some(value) else { return None }
  guard self.component(key).get_ticks(entity) is Some(ticks) else {
    return None
  }
  Some(ComponentRef::{ value, ticks, system: self.get_system_context().ticks() })
}
