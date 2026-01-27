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
/// Component storage wrapper around `SparseSet` that also tracks change ticks.

///|
pub struct ComponentStore[T] {
  storage : SparseSet[T]
  ticks : Array[ComponentTicks]
}

///|
pub fn[T] ComponentStore::new() -> ComponentStore[T] {
  { storage: SparseSet::new(), ticks: [] }
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
pub fn[T] ComponentStore::get_ticks(
  self : ComponentStore[T],
  entity : Entity,
) -> ComponentTicks? {
  match self.storage.index_of(entity) {
    None => None
    Some(i) => self.ticks.get(i)
  }
}

///|
pub fn[T] ComponentStore::set(
  self : ComponentStore[T],
  entity : Entity,
  value : T,
  change_tick : Tick,
) -> Bool {
  match self.storage.index_of(entity) {
    None => false
    Some(i) => {
      self.storage.set(entity, value) |> ignore
      self.ticks[i].set_changed(change_tick)
      true
    }
  }
}

///|
pub fn[T] ComponentStore::insert(
  self : ComponentStore[T],
  entity : Entity,
  value : T,
  change_tick : Tick,
) -> Unit {
  match self.storage.index_of(entity) {
    Some(i) => {
      self.storage.insert(entity, value)
      self.ticks[i].set_changed(change_tick)
    }
    None => {
      let before = self.storage.len()
      self.storage.insert(entity, value)
      // `SparseSet::insert` appends for new entities.
      if self.storage.len() == before + 1 {
        self.ticks.push(ComponentTicks::new(change_tick))
      }
    }
  }
}

///|
pub fn[T] ComponentStore::remove(
  self : ComponentStore[T],
  entity : Entity,
) -> T? {
  match self.storage.index_of(entity) {
    None => None
    Some(i) => {
      let last = self.storage.len() - 1
      if i != last {
        self.ticks[i] = self.ticks[last]
      }
      self.ticks.pop() |> ignore
      self.storage.remove(entity)
    }
  }
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

///|
pub fn[T] ComponentStore::for_each_changed(
  self : ComponentStore[T],
  system : SystemTicks,
  f : (Entity, T) -> Unit,
) -> Unit {
  let len = self.storage.len()
  for i in 0..<len {
    if self.ticks[i].is_changed(system) {
      f(self.storage.entity_at(i), self.storage.value_at(i))
    }
  }
}

///|
pub fn[T] ComponentStore::for_each_added(
  self : ComponentStore[T],
  system : SystemTicks,
  f : (Entity, T) -> Unit,
) -> Unit {
  let len = self.storage.len()
  for i in 0..<len {
    if self.ticks[i].is_added(system) {
      f(self.storage.entity_at(i), self.storage.value_at(i))
    }
  }
}
