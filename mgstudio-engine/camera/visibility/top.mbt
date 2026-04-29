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
const VISIBILITY_PLUGIN_NAME : String = "mgstudio.camera.visibility.VisibilityPlugin"

///|
let visibility_set_update_skinned_mesh_bounds : @app.SystemSet = @app.system_set(
  "mgstudio.camera.visibility.update_skinned_mesh_bounds",
)

///|
pub struct VisibilityPlugin {}

///|
pub fn VisibilityPlugin::default() -> VisibilityPlugin {
  VisibilityPlugin::{  }
}

///|
pub fn visibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  visibility_plugin_with(app, VisibilityPlugin::default())
}

///|
pub fn visibility_plugin_with(
  app : @app.App[@ecs.World],
  plugin : VisibilityPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @root_visibility.visibility_plugin(app)
  .configure_set(
    @app.PostUpdate,
    @root_visibility.visibility_set_calculate_bounds,
    after=[@transform.transform_set_propagate, @asset.asset_event_system_set()],
  )
  .configure_set(@app.PostUpdate, visibility_set_update_skinned_mesh_bounds, after=[
    @root_visibility.visibility_set_calculate_bounds,
  ])
  .add_post_update_system_config(
    @app.system(@camera_primitives.calculate_bounds_system)
    .named("mgstudio.visibility.calculate_bounds")
    .in_set(@root_visibility.visibility_set_calculate_bounds),
  )
  .add_post_update_system_config(
    @app.system(@camera_primitives.update_skinned_mesh_bounds_system)
    .named("mgstudio.visibility.update_skinned_mesh_bounds")
    .in_set(visibility_set_update_skinned_mesh_bounds),
  )
}

///|
pub impl @app.Plugin for VisibilityPlugin with name(_self) {
  VISIBILITY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for VisibilityPlugin with build(self, app) {
  visibility_plugin_with(app, self)
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

///|
pub fn no_auto_aabb() -> @root_visibility.NoAutoAabb {
  @root_visibility.NoAutoAabb::default()
}

///|
pub fn no_cpu_culling() -> @root_visibility.NoCpuCulling {
  @root_visibility.NoCpuCulling::default()
}
