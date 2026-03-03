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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = ["Parent", "Children"]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_Parent {
  get_parent_store(self : Self) -> @core.ComponentStore[Parent]
}

///|
pub(open) trait Has_Children {
  get_children_store(self : Self) -> @core.ComponentStore[Children]
}

///|
pub fn[W : Has_Parent] get_parent_store(
  world : W,
) -> @core.ComponentStore[Parent] {
  world.get_parent_store()
}

///|
pub fn[W : Has_Children] get_children_store(
  world : W,
) -> @core.ComponentStore[Children] {
  world.get_children_store()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_parent_store_by_world : Map[Int, @core.ComponentStore[Parent]] = {}

///|
pub impl Has_Parent for @ecs.World with get_parent_store(self) {
  bridge_get_parent_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_children_store_by_world : Map[
  Int,
  @core.ComponentStore[Children],
] = {}

///|
pub impl Has_Children for @ecs.World with get_children_store(self) {
  bridge_get_children_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
/// End ECS bridge impls.
