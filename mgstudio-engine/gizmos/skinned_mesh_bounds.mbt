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
// Bevy source: `bevy/crates/bevy_gizmos/src/skinned_mesh_bounds.rs`.

///|
let ecs_key_show_skinned_mesh_bounds_gizmo : @ecs.ComponentKey[
  ShowSkinnedMeshBoundsGizmo,
] = @ecs.register_component(
  debug_name="mgstudio_gizmos::ShowSkinnedMeshBoundsGizmo",
)

///|
pub struct SkinnedMeshBoundsGizmoPlugin {}

///|
const SKINNED_MESH_BOUNDS_GIZMO_PLUGIN_NAME : String = "mgstudio.gizmos.SkinnedMeshBoundsGizmoPlugin"

///|
pub fn SkinnedMeshBoundsGizmoPlugin::default() -> SkinnedMeshBoundsGizmoPlugin {
  SkinnedMeshBoundsGizmoPlugin::{  }
}

///|
pub struct SkinnedMeshBoundsGizmoConfigGroup {
  draw_all : Bool
  default_color : @sprite.Color
}

///|
pub fn SkinnedMeshBoundsGizmoConfigGroup::default() -> SkinnedMeshBoundsGizmoConfigGroup {
  SkinnedMeshBoundsGizmoConfigGroup::{
    draw_all: false,
    default_color: @sprite.Color::white(),
  }
}

///|
pub impl Default for SkinnedMeshBoundsGizmoConfigGroup with default() {
  SkinnedMeshBoundsGizmoConfigGroup::default()
}

///|
pub impl @sprite.GizmoConfigGroup for SkinnedMeshBoundsGizmoConfigGroup with gizmo_config_group_marker(
  _self,
) {

}

///|
pub struct ShowSkinnedMeshBoundsGizmo {
  color : @sprite.Color?
}

///|
pub fn ShowSkinnedMeshBoundsGizmo::default() -> ShowSkinnedMeshBoundsGizmo {
  ShowSkinnedMeshBoundsGizmo::{ color: None }
}

///|
pub impl @ecs.Component for ShowSkinnedMeshBoundsGizmo with component() {
  ecs_key_show_skinned_mesh_bounds_gizmo
}

///|
pub fn skinned_mesh_bounds_gizmo_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  skinned_mesh_bounds_gizmo_plugin_with(
    app,
    SkinnedMeshBoundsGizmoPlugin::default(),
  )
}

///|
pub fn skinned_mesh_bounds_gizmo_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SkinnedMeshBoundsGizmoPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  init_gizmo_group(app, SkinnedMeshBoundsGizmoConfigGroup::default())
}

///|
pub impl @app.Plugin for SkinnedMeshBoundsGizmoPlugin with name(_self) {
  SKINNED_MESH_BOUNDS_GIZMO_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SkinnedMeshBoundsGizmoPlugin with build(self, app) {
  skinned_mesh_bounds_gizmo_plugin_with(app, self)
}
