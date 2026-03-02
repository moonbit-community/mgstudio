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
pub let ecs_components : Array[String] = ["SceneRoot", "SceneInstanceReady"]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_SceneRoot {
  get_scene_root_store(self : Self) -> @core.ComponentStore[SceneRoot]
}

///|
pub(open) trait Has_SceneInstanceReady {
  get_scene_instance_ready_store(self : Self) -> @core.ComponentStore[
    SceneInstanceReady,
  ]
}

///|
pub fn[W : Has_SceneRoot] query_get_scene_root_store(
  world : W,
) -> @core.ComponentStore[SceneRoot] {
  world.get_scene_root_store()
}

///|
pub fn[W : Has_SceneInstanceReady] query_get_scene_instance_ready_store(
  world : W,
) -> @core.ComponentStore[SceneInstanceReady] {
  world.get_scene_instance_ready_store()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_scene_root_store_by_world : Map[
  Int,
  @core.ComponentStore[SceneRoot],
] = {}

///|
pub impl Has_SceneRoot for @ecs.World with get_scene_root_store(self) {
  bridge_get_scene_root_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_scene_instance_ready_store_by_world : Map[
  Int,
  @core.ComponentStore[SceneInstanceReady],
] = {}

///|
pub impl Has_SceneInstanceReady for @ecs.World with get_scene_instance_ready_store(
  self,
) {
  bridge_get_scene_instance_ready_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
/// End ECS bridge impls.
