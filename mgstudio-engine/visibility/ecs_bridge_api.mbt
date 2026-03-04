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
pub let ecs_components : Array[String] = [
  "Visibility", "ViewVisibility", "VisibilityRange", "InheritedVisibility",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = []

///|
pub(open) trait Has_Visibility {
  get_visibility_store(self : Self) -> @ecs.ComponentAccess[Visibility]
}

///|
pub(open) trait Has_ViewVisibility {
  get_view_visibility_store(self : Self) -> @ecs.ComponentAccess[ViewVisibility]
}

///|
pub(open) trait Has_VisibilityRange {
  get_visibility_range_store(self : Self) -> @ecs.ComponentAccess[
    VisibilityRange,
  ]
}

///|
pub(open) trait Has_InheritedVisibility {
  get_inherited_visibility_store(self : Self) -> @ecs.ComponentAccess[
    InheritedVisibility,
  ]
}

///|
pub fn[W : Has_Visibility] get_visibility_store(
  world : W,
) -> @ecs.ComponentAccess[Visibility] {
  world.get_visibility_store()
}

///|
pub fn[W : Has_ViewVisibility] get_view_visibility_store(
  world : W,
) -> @ecs.ComponentAccess[ViewVisibility] {
  world.get_view_visibility_store()
}

///|
pub fn[W : Has_VisibilityRange] get_visibility_range_store(
  world : W,
) -> @ecs.ComponentAccess[VisibilityRange] {
  world.get_visibility_range_store()
}

///|
pub fn[W : Has_InheritedVisibility] get_inherited_visibility_store(
  world : W,
) -> @ecs.ComponentAccess[InheritedVisibility] {
  world.get_inherited_visibility_store()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Visibility for @ecs.World with get_visibility_store(self) {
  self.component(ecs_key_visibility)
}

///|
pub impl Has_ViewVisibility for @ecs.World with get_view_visibility_store(self) {
  self.component(ecs_key_view_visibility)
}

///|
pub impl Has_VisibilityRange for @ecs.World with get_visibility_range_store(
  self,
) {
  self.component(ecs_key_visibility_range)
}

///|
pub impl Has_InheritedVisibility for @ecs.World with get_inherited_visibility_store(
  self,
) {
  self.component(ecs_key_inherited_visibility)
}

///|
/// End ECS bridge impls.
