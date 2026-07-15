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
pub struct ChangedComponents[_] {
  priv entities : Array[@core.Entity]
}

///|
pub fn[T] ChangedComponents::read(
  self : ChangedComponents[T],
) -> Array[@core.Entity] {
  let entities = self.entities.copy()
  self.entities.clear()
  entities
}

///|
pub fn[T] ChangedComponents::len(self : ChangedComponents[T]) -> Int {
  self.entities.length()
}

///|
pub fn[T] ChangedComponents::is_empty(self : ChangedComponents[T]) -> Bool {
  self.entities.is_empty()
}

///|
pub fn[T] ChangedComponents::clear(self : ChangedComponents[T]) -> Unit {
  self.entities.clear()
}

///|
pub fn[T] World::changed_components(
  self : World,
  key : ComponentKey[T],
  system : @core.SystemTicks,
) -> ChangedComponents[T] {
  let entities : Array[@core.Entity] = []
  guard self.local_component_id(key.id()) is Some(local_component_id) else {
    return ChangedComponents::{ entities, }
  }
  key.component_for_each(self, fn(entity, _value) {
    if self.is_changed_by_local_id(entity, local_component_id, system) {
      entities.push(entity)
    }
  })
  ChangedComponents::{ entities, }
}

///|
pub fn[T] World::is_changed_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  system : @core.SystemTicks,
) -> Bool {
  if !self.is_alive(entity) || !entity_has_component_id(self, key.id(), entity) {
    return false
  }
  match self.changed_component_tick(key.id(), entity.id) {
    Some(tick) => system.contains(tick)
    None => false
  }
}

///|
fn World::is_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  system : @core.SystemTicks,
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  match self.changed_component_tick_by_local_id(local_component_id, entity.id) {
    Some(tick) => system.contains(tick)
    None => false
  }
}
