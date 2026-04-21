// Copyright 2026 International Digital Economy Academy
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
pub struct ComponentColumn[T] {
  world : World
  key : ComponentKey[T]
  changed_sequence_table : ComponentSequenceTable
}

///|
fn[T] erased_value_ref_fast(payload : ErasedValue) -> Ref[T]? {
  Some(payload.unsafe_to_ref())
}

///|
fn[T] erased_value_value_fast(payload : ErasedValue) -> T? {
  match erased_value_ref_fast(payload) {
    Some(value_ref) => Some(value_ref.val)
    None => None
  }
}

///|
pub fn[T] World::component_column(
  self : World,
  key : ComponentKey[T],
) -> ComponentColumn[T]? {
  match self.local_component_id(key.id()) {
    Some(_) =>
      Some({
        world: self,
        key,
        changed_sequence_table: self.ensure_changed_component_sequence_table(
          key.id(),
        ),
      })
    None => None
  }
}

///|
pub fn[T] ComponentColumn::contains(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Bool {
  self.world.component_payload(self.key.id(), entity) is Some(_)
}

///|
pub fn[T] ComponentColumn::get(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.world.component_payload(self.key.id(), entity) {
    Some(payload) => erased_value_value_fast(payload)
    None => None
  }
}

///|
pub fn[T] ComponentColumn::get_ref(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Ref[T]? {
  match self.world.component_payload(self.key.id(), entity) {
    Some(payload) => erased_value_ref_fast(payload)
    None => None
  }
}

///|
pub fn[T] ComponentColumn::get_mut(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Mut[T]? {
  match self.get_ref(entity) {
    Some(value_ref) =>
      Some({
        value_ref: Some(value_ref),
        world: Some(self.world),
        entity: Some(entity),
        key_id: Some(self.key.id()),
      })
    None => None
  }
}

///|
pub fn[T] ComponentColumn::for_each_ref(
  self : ComponentColumn[T],
  visit : (@core.Entity, Ref[T]) -> Unit,
) -> Unit {
  self.world.for_each_component(self.key, fn(entity, _value) {
    match self.get_ref(entity) {
      Some(value_ref) => visit(entity, value_ref)
      None => ()
    }
  })
}

///|
pub fn[T] ComponentColumn::set(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let payload = erased_value(value)
  if self.world.replace_component_payload(self.key.id(), entity, payload) {
      let sequence = component_write_sequence(self.world)
      self.changed_sequence_table.set(entity.id, sequence)
      self.world.ensure_changed_component_messages(self.key.id()).val.send(
        sequence, entity,
      )
      true
  } else {
    false
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let payload = erased_value(value)
  if self.world.replace_component_payload(self.key.id(), entity, payload) {
      self.changed_sequence_table.set(
        entity.id,
        component_write_sequence(self.world),
      )
      true
  } else {
    false
  }
}
