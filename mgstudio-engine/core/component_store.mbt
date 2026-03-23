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
/// Component storage wrapper around `SparseSet`.

///|
pub struct ComponentStore[T] {
  storage : SparseSet[T]
}

///|
pub fn[T] ComponentStore::new() -> ComponentStore[T] {
  { storage: SparseSet::new() }
}

///|
pub fn[T] ComponentStore::len(self : ComponentStore[T]) -> Int {
  self.storage.len()
}

///|
pub fn[T] ComponentStore::contains(
  self : ComponentStore[T],
  entity : Entity,
) -> Bool {
  self.storage.contains(entity)
}

///|
pub fn[T] ComponentStore::get(self : ComponentStore[T], entity : Entity) -> T? {
  self.storage.get(entity)
}

///|
pub fn[T] ComponentStore::set(
  self : ComponentStore[T],
  entity : Entity,
  value : T,
) -> Bool {
  match self.storage.index_of(entity) {
    None => false
    Some(i) => {
      ignore(i)
      self.storage.set(entity, value) |> ignore
      true
    }
  }
}

///|
pub fn[T] ComponentStore::update(
  self : ComponentStore[T],
  entity : Entity,
  update : (T) -> T,
) -> Bool {
  match self.get(entity) {
    Some(value) => self.set(entity, update(value))
    None => false
  }
}

///|
pub fn[T] ComponentStore::insert(
  self : ComponentStore[T],
  entity : Entity,
  value : T,
) -> Unit {
  self.storage.insert(entity, value)
}

///|
pub fn[T] ComponentStore::upsert(
  self : ComponentStore[T],
  entity : Entity,
  value : T,
) -> Unit {
  self.insert(entity, value)
}

///|
pub fn[T] ComponentStore::remove(
  self : ComponentStore[T],
  entity : Entity,
) -> T? {
  self.storage.remove(entity)
}

///|
pub fn[T] ComponentStore::for_each(
  self : ComponentStore[T],
  f : (Entity, T) -> Unit,
) -> Unit {
  let len = self.storage.len()
  for i in 0..<len {
    f(self.storage.entity_at(i), self.storage.value_at(i))
  }
}
