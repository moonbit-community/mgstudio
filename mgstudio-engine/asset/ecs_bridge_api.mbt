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
/// ECS component bridge types.
pub let ecs_components : Array[String] = ["TextureAtlas"]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_TextureAtlas {
  get_texture_atlas_store(self : Self) -> @core.ComponentStore[TextureAtlas]
}

///|
pub fn[W : Has_TextureAtlas] get_texture_atlas_store(
  world : W,
) -> @core.ComponentStore[TextureAtlas] {
  world.get_texture_atlas_store()
}

///|
/// ECS bridge impls for @ecs.World.

///|
let bridge_get_texture_atlas_store_by_world : Map[
  Int,
  @core.ComponentStore[TextureAtlas],
] = {}

///|
pub impl Has_TextureAtlas for @ecs.World with get_texture_atlas_store(self) {
  bridge_get_texture_atlas_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
/// End ECS bridge impls.
