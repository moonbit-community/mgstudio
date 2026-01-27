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
