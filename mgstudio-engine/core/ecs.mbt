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
} derive(Eq, Hash, Debug, ToJson, FromJson)

///|
pub fn Entity::new(id : Int, generation : Int) -> Entity {
  { id, generation }
}

///|
pub fn Entity::placeholder() -> Entity {
  { id: -1, generation: 0 }
}

///|
pub fn Entity::is_placeholder(self : Entity) -> Bool {
  self.id < 0
}

///|
pub fn Entity::to_bits(self : Entity) -> UInt64 {
  let hi = self.id.reinterpret_as_uint().to_uint64()
  let lo = self.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
pub fn Entity::from_bits(bits : UInt64) -> Entity {
  let hi = (bits >> 32).to_uint()
  let lo = (bits & 0xFFFF_FFFFUL).to_uint()
  Entity::new(hi.reinterpret_as_int(), lo.reinterpret_as_int())
}

///|
pub(all) suberror EntityError {
  InvalidId(Int)
  NotSpawned(Entity)
  GenerationMismatch(Entity, Int)
  AlreadySpawned(Entity)
}

///|
struct Entities {
  generations : Array[Int]
  alive : Array[Bool]
}

///|
const FIRST_GENERATION : Int = 1

///|
pub fn Entities::new() -> Entities {
  { generations: [], alive: [] }
}

///|
/// Allocates valid entity IDs that are not spawned until inserted into a
/// world's entity storage.
pub struct EntityAllocator {
  priv mut next_id : Int
  priv free : Array[Entity]
}

///|
pub fn EntityAllocator::new() -> EntityAllocator {
  { next_id: 0, free: [] }
}

///|
pub fn EntityAllocator::alloc(self : EntityAllocator) -> Entity {
  match self.free.pop() {
    Some(entity) => entity
    None => {
      let entity = Entity::{ id: self.next_id, generation: FIRST_GENERATION }
      self.next_id = self.next_id + 1
      entity
    }
  }
}

///|
pub fn EntityAllocator::free(self : EntityAllocator, entity : Entity) -> Unit {
  self.free.push(entity)
}

///|
pub fn Entities::len(self : Entities) -> Int {
  self.generations.length()
}

///|
pub fn Entities::count_spawned(self : Entities) -> Int {
  let mut count = 0
  for is_alive in self.alive {
    if is_alive {
      count = count + 1
    }
  }
  count
}

///|
pub fn Entities::alive_entities(self : Entities) -> Array[Entity] {
  let entities : Array[Entity] = []
  let len = self.generations.length()
  for id in 0..<len {
    if self.alive[id] {
      entities.push({ id, generation: self.generations[id] })
    }
  }
  entities
}

///|
pub fn Entities::spawn_at(
  self : Entities,
  entity : Entity,
) -> Unit raise EntityError {
  if entity.id < 0 {
    raise InvalidId(entity.id)
  }
  if entity.id >= self.generations.length() {
    while self.generations.length() < entity.id {
      self.generations.push(FIRST_GENERATION)
      self.alive.push(false)
    }
    self.generations.push(entity.generation)
    self.alive.push(true)
    return
  }
  guard self.generations.get(entity.id) is Some(generation) else {
    raise NotSpawned(entity)
  }
  if generation != entity.generation {
    raise GenerationMismatch(entity, generation)
  }
  if self.alive[entity.id] {
    raise AlreadySpawned(entity)
  }
  self.alive[entity.id] = true
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
) -> Entity raise EntityError {
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
  let freed = Entity::{ id: entity.id, generation: gen + 1 }
  self.generations[entity.id] = freed.generation
  freed
}

///|
struct World {
  entities : Entities
  entity_allocator : EntityAllocator
}

///|
pub fn World::new() -> World {
  { entities: Entities::new(), entity_allocator: EntityAllocator::new() }
}

///|
pub fn World::spawn_empty(self : World) -> Entity {
  let entity = self.entity_allocator.alloc()
  try! self.entities.spawn_at(entity)
  entity
}

///|
pub fn World::despawn(self : World, entity : Entity) -> Unit raise EntityError {
  let freed = self.entities.despawn(entity)
  self.entity_allocator.free(freed)
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
  let sparse_len = self.sparse.length()
  if entity.id >= sparse_len {
    return None
  }
  let i = self.sparse.unsafe_get(entity.id)
  let dense_len = self.dense_entities.length()
  if i < 0 || i >= dense_len {
    return None
  }
  let e = self.dense_entities.unsafe_get(i)
  if e.generation == entity.generation {
    Some(i)
  } else {
    None
  }
}

///|
pub fn[T] SparseSet::get(self : SparseSet[T], entity : Entity) -> T? {
  match self.index_of(entity) {
    Some(i) => Some(self.dense_values.unsafe_get(i))
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

///|
pub fn[T] SparseSet::entity_at(
  self : SparseSet[T],
  dense_index : Int,
) -> Entity {
  self.dense_entities[dense_index]
}

///|
pub fn[T] SparseSet::value_at(self : SparseSet[T], dense_index : Int) -> T {
  self.dense_values[dense_index]
}
