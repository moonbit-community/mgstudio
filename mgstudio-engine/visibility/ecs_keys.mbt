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
pub let ecs_key_visibility : @ecs.ComponentKey[Visibility] = @ecs.register_component(
  debug_name="visibility.visibility",
)

///|
pub let ecs_key_inherited_visibility : @ecs.ComponentKey[InheritedVisibility] = @ecs.register_component(
  debug_name="visibility.inherited_visibility",
)

///|
pub let ecs_key_view_visibility : @ecs.ComponentKey[ViewVisibility] = @ecs.register_component(
  debug_name="visibility.view_visibility",
)

///|
pub let ecs_key_no_frustum_culling : @ecs.ComponentKey[NoFrustumCulling] = @ecs.register_component(
  debug_name="visibility.no_frustum_culling",
)

///|
pub let ecs_key_visibility_range : @ecs.ComponentKey[VisibilityRange] = @ecs.register_component(
  debug_name="visibility.visibility_range",
)

///|
pub impl @ecs.Component for Visibility with component() {
  ecs_key_visibility
}

///|
pub impl @ecs.Component for InheritedVisibility with component() {
  ecs_key_inherited_visibility
}

///|
pub impl @ecs.Component for ViewVisibility with component() {
  ecs_key_view_visibility
}

///|
pub impl @ecs.Component for NoFrustumCulling with component() {
  ecs_key_no_frustum_culling
}

///|
pub impl @ecs.Component for VisibilityRange with component() {
  ecs_key_visibility_range
}
