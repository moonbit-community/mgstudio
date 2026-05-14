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
/// Bevy-like hierarchy components.

///|
pub struct Parent {
  entity : @core.Entity
}

///|
pub fn Parent::new(entity : @core.Entity) -> Parent {
  Parent::{ entity, }
}

///|
pub fn Parent::entity(self : Parent) -> @core.Entity {
  self.entity
}

///|
pub impl ToJson for Parent with to_json(self) {
  (self.entity.id, self.entity.generation).to_json()
}

///|
pub impl @json.FromJson for Parent with from_json(json, path) {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  Parent::new(@core.Entity::new(id, generation))
}

///|
pub struct Children {
  entities : Array[@core.Entity]
  entity_table_ids : Array[Int]
  entity_row_indices : Array[Int]
  priv entity_cache_world_generations : Array[Int]
  priv entity_cache_ids : Array[Int]
  priv entity_cache_entity_generations : Array[Int]
}

///|
pub fn Children::new(entities : Array[@core.Entity]) -> Children {
  Children::{
    entities,
    entity_table_ids: Array::make(entities.length(), -1),
    entity_row_indices: Array::make(entities.length(), -1),
    entity_cache_world_generations: Array::make(entities.length(), -1),
    entity_cache_ids: Array::make(entities.length(), -1),
    entity_cache_entity_generations: Array::make(entities.length(), -1),
  }
}

///|
pub fn Children::entities(self : Children) -> Array[@core.Entity] {
  self.entities
}

///|
fn Children::ensure_entity_row_cache(self : Children) -> Unit {
  while self.entity_table_ids.length() < self.entities.length() {
    self.entity_table_ids.push(-1)
  }
  while self.entity_row_indices.length() < self.entities.length() {
    self.entity_row_indices.push(-1)
  }
  while self.entity_cache_world_generations.length() < self.entities.length() {
    self.entity_cache_world_generations.push(-1)
  }
  while self.entity_cache_ids.length() < self.entities.length() {
    self.entity_cache_ids.push(-1)
  }
  while self.entity_cache_entity_generations.length() < self.entities.length() {
    self.entity_cache_entity_generations.push(-1)
  }
}

///|
pub fn Children::entity_table_row_cached(
  self : Children,
  world : @ecs.World,
  index : Int,
) -> (Int, Int)? {
  guard index >= 0 && index < self.entities.length() else { return None }
  self.ensure_entity_row_cache()
  let entity = self.entities[index]
  let world_generation = world.structural_generation()
  let table_id = self.entity_table_ids[index]
  let row_index = self.entity_row_indices[index]
  if table_id >= 0 &&
    row_index >= 0 &&
    self.entity_cache_world_generations[index] == world_generation &&
    self.entity_cache_ids[index] == entity.id &&
    self.entity_cache_entity_generations[index] == entity.generation {
    return Some((table_id, row_index))
  }
  guard world.entity_table_location(entity)
    is Some((next_table_id, next_row_index)) else {
    return None
  }
  self.entity_table_ids[index] = next_table_id
  self.entity_row_indices[index] = next_row_index
  self.entity_cache_world_generations[index] = world_generation
  self.entity_cache_ids[index] = entity.id
  self.entity_cache_entity_generations[index] = entity.generation
  Some((next_table_id, next_row_index))
}

///|
pub impl ToJson for Children with to_json(self) {
  let encoded : Array[(Int, Int)] = []
  for entity in self.entities {
    encoded.push((entity.id, entity.generation))
  }
  encoded.to_json()
}

///|
pub impl @json.FromJson for Children with from_json(json, path) {
  let encoded : Array[(Int, Int)] = @json.from_json(json, path~)
  let entities : Array[@core.Entity] = []
  for pair in encoded {
    entities.push(@core.Entity::new(pair.0, pair.1))
  }
  Children::new(entities)
}
