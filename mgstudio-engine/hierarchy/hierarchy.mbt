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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Children {
  entities : Array[@core.Entity]
}

///|
pub fn Children::new(entities : Array[@core.Entity]) -> Children {
  Children::{ entities, }
}

///|
pub fn Children::entities(self : Children) -> Array[@core.Entity] {
  self.entities
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
