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
pub let ecs_components : Array[String] = [
  "Visibility", "ViewVisibility", "VisibilityRange", "InheritedVisibility",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_Visibility {
  get_visibility_store(self : Self) -> @core.ComponentStore[Visibility]
}

///|
pub(open) trait Has_ViewVisibility {
  get_view_visibility_store(self : Self) -> @core.ComponentStore[ViewVisibility]
}

///|
pub(open) trait Has_VisibilityRange {
  get_visibility_range_store(self : Self) -> @core.ComponentStore[
    VisibilityRange,
  ]
}

///|
pub(open) trait Has_InheritedVisibility {
  get_inherited_visibility_store(self : Self) -> @core.ComponentStore[
    InheritedVisibility,
  ]
}

///|
pub fn[W : Has_Visibility] query_get_visibility_store(
  world : W,
) -> @core.ComponentStore[Visibility] {
  world.get_visibility_store()
}

///|
pub fn[W : Has_ViewVisibility] query_get_view_visibility_store(
  world : W,
) -> @core.ComponentStore[ViewVisibility] {
  world.get_view_visibility_store()
}

///|
pub fn[W : Has_VisibilityRange] query_get_visibility_range_store(
  world : W,
) -> @core.ComponentStore[VisibilityRange] {
  world.get_visibility_range_store()
}

///|
pub fn[W : Has_InheritedVisibility] query_get_inherited_visibility_store(
  world : W,
) -> @core.ComponentStore[InheritedVisibility] {
  world.get_inherited_visibility_store()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_visibility_store_by_world : Map[
  Int,
  @core.ComponentStore[Visibility],
] = {}

///|
pub impl Has_Visibility for @ecs.World with get_visibility_store(self) {
  bridge_get_visibility_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_view_visibility_store_by_world : Map[
  Int,
  @core.ComponentStore[ViewVisibility],
] = {}

///|
pub impl Has_ViewVisibility for @ecs.World with get_view_visibility_store(self) {
  bridge_get_view_visibility_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_visibility_range_store_by_world : Map[
  Int,
  @core.ComponentStore[VisibilityRange],
] = {}

///|
pub impl Has_VisibilityRange for @ecs.World with get_visibility_range_store(
  self,
) {
  bridge_get_visibility_range_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_inherited_visibility_store_by_world : Map[
  Int,
  @core.ComponentStore[InheritedVisibility],
] = {}

///|
pub impl Has_InheritedVisibility for @ecs.World with get_inherited_visibility_store(
  self,
) {
  bridge_get_inherited_visibility_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
/// End ECS bridge impls.
