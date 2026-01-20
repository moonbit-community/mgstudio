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
pub struct Entity {
  id : Int
}

///|
pub struct World {
  mut next_id : Int
}

///|
pub fn World::new() -> World {
  World::{ next_id: 0 }
}

///|
pub fn World::spawn(self : World) -> Entity {
  let entity = Entity::{ id: self.next_id }
  self.next_id = self.next_id + 1
  entity
}

///|
pub struct Commands {
  world : World
}

///|
pub fn Commands::new(world : World) -> Commands {
  Commands::{ world, }
}

///|
pub fn Commands::spawn(self : Commands) -> Entity {
  self.world.spawn()
}

///|
pub struct Res[T] {
  value : T
}

///|
pub fn[T] Res::new(value : T) -> Res[T] {
  Res::{ value, }
}

///|
pub struct Query[T] {
  items : Array[T]
}

///|
pub fn[T] Query::new(items : Array[T]) -> Query[T] {
  Query::{ items, }
}
