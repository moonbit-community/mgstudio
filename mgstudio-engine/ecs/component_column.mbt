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
  store_ref : Ref[@core.ComponentStore[ErasedValue]]
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
  match self.component_store(key.id()) {
    Some(store_ref) =>
      Some({
        world: self,
        key,
        store_ref,
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
  self.store_ref.val.contains(entity)
}

///|
pub fn[T] ComponentColumn::get(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.store_ref.val.get(entity) {
    Some(payload) => erased_value_value_fast(payload)
    None => None
  }
}

///|
pub fn[T] ComponentColumn::get_ref(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Ref[T]? {
  match self.store_ref.val.get(entity) {
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
  self.store_ref.val.for_each(fn(entity, payload) {
    match erased_value_ref_fast(payload) {
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
  match self.get_ref(entity) {
    Some(value_ref) => {
      value_ref.val = value
      let sequence = component_write_sequence(self.world)
      self.changed_sequence_table.set(entity.id, sequence)
      self.world.ensure_changed_component_messages(self.key.id()).val.send(
        sequence, entity,
      )
      true
    }
    None => false
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  match self.get_ref(entity) {
    Some(value_ref) => {
      value_ref.val = value
      self.changed_sequence_table.set(
        entity.id,
        component_write_sequence(self.world),
      )
      true
    }
    None => false
  }
}
