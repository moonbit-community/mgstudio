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
/// ECS foundation (dependency-free), aligned with Bevy concepts:
/// - Entity uses (id, generation) to avoid ABA after despawn/reuse.
/// - SparseSet[T] provides a cache-friendly component storage.

///|
pub struct Entity {
  id : Int
  generation : Int
}

///|
pub fn Entity::new(id : Int, generation : Int) -> Entity {
  Entity::{ id, generation }
}

///|
pub fn Entity::placeholder() -> Entity {
  Entity::{ id: -1, generation: 0 }
}

///|
pub fn Entity::is_placeholder(self : Entity) -> Bool {
  self.id < 0
}

///|
pub(all) suberror EntityError {
  InvalidId(Int)
  NotSpawned(Entity)
  GenerationMismatch(Entity, Int)
}

///|
struct Entities {
  generations : Array[Int]
  alive : Array[Bool]
  free : Array[Int]
}

///|
const FIRST_GENERATION : Int = 1

///|
pub fn Entities::new() -> Entities {
  { generations: [], alive: [], free: [] }
}

///|
pub fn Entities::len(self : Entities) -> Int {
  self.generations.length()
}

///|
pub fn Entities::spawn(self : Entities) -> Entity {
  match self.free.pop() {
    Some(id) => {
      self.alive[id] = true
      Entity::{ id, generation: self.generations[id] }
    }
    None => {
      let id = self.generations.length()
      self.generations.push(FIRST_GENERATION)
      self.alive.push(true)
      Entity::{ id, generation: FIRST_GENERATION }
    }
  }
}

///|
pub fn Entities::is_alive(self : Entities, entity : Entity) -> Bool {
  if entity.id < 0 {
    return false
  }
  match (self.alive.get(entity.id), self.generations.get(entity.id)) {
    (Some(is_alive), Some(gen)) => is_alive && gen == entity.generation
    _ => false
  }
}

///|
pub fn Entities::despawn(
  self : Entities,
  entity : Entity,
) -> Unit raise EntityError {
  if entity.id < 0 {
    raise InvalidId(entity.id)
  }
  guard self.alive.get(entity.id) is Some(is_alive) else {
    raise NotSpawned(entity)
  }
  guard self.generations.get(entity.id) is Some(gen) else {
    raise NotSpawned(entity)
  }
  if !is_alive {
    raise NotSpawned(entity)
  }
  if gen != entity.generation {
    raise GenerationMismatch(entity, gen)
  }
  self.alive[entity.id] = false
  self.generations[entity.id] = gen + 1
  self.free.push(entity.id)
}

///|
struct World {
  entities : Entities
}

///|
pub fn World::new() -> World {
  { entities: Entities::new() }
}

///|
pub fn World::spawn_empty(self : World) -> Entity {
  self.entities.spawn()
}

///|
pub fn World::despawn(self : World, entity : Entity) -> Unit raise EntityError {
  self.entities.despawn(entity)
}

///|
pub fn World::is_alive(self : World, entity : Entity) -> Bool {
  self.entities.is_alive(entity)
}

///|
struct SparseSet[T] {
  sparse : Array[Int]
  dense_entities : Array[Entity]
  dense_values : Array[T]
}

///|
pub fn[T] SparseSet::new() -> SparseSet[T] {
  { sparse: [], dense_entities: [], dense_values: [] }
}

///|
pub fn[T] SparseSet::len(self : SparseSet[T]) -> Int {
  self.dense_entities.length()
}

///|
pub fn[T] SparseSet::is_empty(self : SparseSet[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] SparseSet::contains(self : SparseSet[T], entity : Entity) -> Bool {
  self.index_of(entity) is Some(_)
}

///|
fn[T] SparseSet::ensure_sparse_len(self : SparseSet[T], len : Int) -> Unit {
  while self.sparse.length() < len {
    self.sparse.push(-1)
  }
}

///|
pub fn[T] SparseSet::index_of(self : SparseSet[T], entity : Entity) -> Int? {
  if entity.id < 0 {
    return None
  }
  match self.sparse.get(entity.id) {
    Some(i) if i >= 0 && self.dense_entities.get(i) is Some(e) =>
      if e.generation == entity.generation {
        Some(i)
      } else {
        None
      }
    _ => None
  }
}

///|
pub fn[T] SparseSet::get(self : SparseSet[T], entity : Entity) -> T? {
  match self.index_of(entity) {
    Some(i) => self.dense_values.get(i)
    None => None
  }
}

///|
pub fn[T] SparseSet::set(
  self : SparseSet[T],
  entity : Entity,
  value : T,
) -> Bool {
  match self.index_of(entity) {
    Some(i) => {
      self.dense_values[i] = value
      true
    }
    None => false
  }
}

///|
pub fn[T] SparseSet::insert(
  self : SparseSet[T],
  entity : Entity,
  value : T,
) -> Unit {
  if entity.id < 0 {
    return
  }
  self.ensure_sparse_len(entity.id + 1)
  match self.index_of(entity) {
    Some(i) => self.dense_values[i] = value
    None => {
      let i = self.dense_entities.length()
      self.dense_entities.push(entity)
      self.dense_values.push(value)
      self.sparse[entity.id] = i
    }
  }
}

///|
pub fn[T] SparseSet::remove(self : SparseSet[T], entity : Entity) -> T? {
  match self.index_of(entity) {
    None => None
    Some(i) => {
      let last = self.dense_entities.length() - 1
      let removed_value = self.dense_values.get(i)
      // Remove sparse mapping for this id.
      self.sparse[entity.id] = -1
      if i != last {
        // Swap-remove to keep dense storage packed.
        let moved_entity = self.dense_entities[last]
        let moved_value = self.dense_values[last]
        self.dense_entities[i] = moved_entity
        self.dense_values[i] = moved_value
        self.sparse[moved_entity.id] = i
      }
      self.dense_entities.pop() |> ignore
      self.dense_values.pop() |> ignore
      removed_value
    }
  }
}
