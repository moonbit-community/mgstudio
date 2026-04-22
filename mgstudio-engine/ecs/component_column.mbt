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
  let result : Result[T?, EcsError] = try? self.world.component_value_by_key(
    entity,
    self.key,
  )
  match result {
    Ok(value) => value
    Err(_) => None
  }
}

///|
pub fn[T] ComponentColumn::get_mut(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Mut[T]? {
  match self.world.component_payload(self.key.id(), entity) {
    Some(_) =>
      Some({
        world: Some(self.world),
        entity: Some(entity),
        key: Some(self.key),
      })
    None => None
  }
}

///|
pub fn[T] ComponentColumn::for_each(
  self : ComponentColumn[T],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  self.world.for_each_component(self.key, fn(entity, _value) {
    match self.get(entity) {
      Some(value) => visit(entity, value)
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
  let replaced : Result[Bool, EcsError] = try? self.world
    .replace_component_value_by_key(entity, self.key, value)
  match replaced {
    Ok(true) => {
      self.world.record_component_changed_with_caller(
        entity,
        self.key.id(),
        None,
      )
      true
    }
    _ => false
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let replaced : Result[Bool, EcsError] = try? self.world
    .replace_component_value_by_key(entity, self.key, value)
  match replaced {
    Ok(true) => {
      self.world.record_component_changed_sequence_only_with_caller(
        entity,
        self.key.id(),
        None,
      )
      true
    }
    _ => false
  }
}
