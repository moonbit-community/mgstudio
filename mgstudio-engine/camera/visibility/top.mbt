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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs`.

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @root_visibility.visibility_plugin(app)
}

///|
pub fn visibility_component_keys() -> (
  @ecs.ComponentKey[@root_visibility.Visibility],
  @ecs.ComponentKey[@root_visibility.InheritedVisibility],
  @ecs.ComponentKey[@root_visibility.ViewVisibility],
) {
  (
    @root_visibility.ecs_key_visibility, @root_visibility.ecs_key_inherited_visibility,
    @root_visibility.ecs_key_view_visibility,
  )
}

///|
pub fn default_visibility() -> @root_visibility.Visibility {
  @root_visibility.Visibility::Inherited
}

///|
pub fn inherited_visibility(
  visible : Bool,
) -> @root_visibility.InheritedVisibility {
  @root_visibility.InheritedVisibility::new(visible)
}

///|
pub fn view_visibility(visible : Bool) -> @root_visibility.ViewVisibility {
  @root_visibility.ViewVisibility::new(visible)
}

///|
pub fn no_frustum_culling() -> @root_visibility.NoFrustumCulling {
  @root_visibility.NoFrustumCulling::default()
}
