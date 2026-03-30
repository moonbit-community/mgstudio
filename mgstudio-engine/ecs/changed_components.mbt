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
  reader : @core.MessageReader[@core.Entity]
}

///|
pub fn[T] ChangedComponents::read(
  self : ChangedComponents[T],
) -> Array[@core.Entity] {
  self.reader.read()
}

///|
pub fn[T] ChangedComponents::len(self : ChangedComponents[T]) -> Int {
  self.reader.len()
}

///|
pub fn[T] ChangedComponents::is_empty(self : ChangedComponents[T]) -> Bool {
  self.reader.is_empty()
}

///|
pub fn[T] ChangedComponents::clear(self : ChangedComponents[T]) -> Unit {
  self.reader.clear()
}

///|
pub fn[T] World::changed_components(
  self : World,
  key : ComponentKey[T],
  system : @core.SystemSequence,
) -> ChangedComponents[T] {
  let reader = match self.changed_component_messages(key.id()) {
    Some(messages_ref) => messages_ref.val.reader(system)
    None => @core.Messages::new().reader(system)
  }
  ChangedComponents::{ reader, }
}

///|
pub fn[T] World::is_changed_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  system : @core.SystemSequence,
) -> Bool {
  if !self.is_alive(entity) || !entity_has_component_id(self, key.id(), entity) {
    return false
  }
  match self.changed_component_sequence(key.id(), entity.id) {
    Some(sequence) => system.contains(sequence)
    None => false
  }
}
