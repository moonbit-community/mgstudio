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
// Bevy source: `bevy/crates/bevy_gizmos/src/lib.rs`.
// Package-level plugin boundary aligned with Bevy gizmos crate.

const GIZMO_PLUGIN_NAME : String = "mgstudio.gizmos.GizmoPlugin"

///|
priv struct GizmoPluginMarker {}

///|
pub let gizmo_set_flush : @app.SystemSet = @app.system_set(
  "mgstudio.gizmos.flush",
)

///|
pub let gizmo_set_mesh : @app.SystemSet = @app.system_set(
  "mgstudio.gizmos.mesh",
)

///|
let ecs_res_key_gizmo_plugin_marker : @ecs.ResourceKey[GizmoPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoPluginMarker",
)

///|
pub struct GizmoPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn GizmoPlugin::GizmoPlugin() -> GizmoPlugin {
  GizmoPlugin::{  }
}

// The `Isometry2d`, `GizmoLine*`, `GizmoConfig*`, `Gizmos`, `GizmoStorage` and
// builder types are now defined by their own Bevy source owners in this package
// (`gizmos.mbt`, `config.mbt`), so the previous re-export bridge to `@sprite` is
// gone. `init_gizmo_group` is owned by `config.mbt`.

///|
pub fn gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gizmo_plugin_with(app, GizmoPlugin())
}

///|
pub impl @app.Plugin for GizmoPlugin with fn name(_self) {
  GIZMO_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GizmoPlugin with fn build(self, app) {
  gizmo_plugin_with(app, self)
}

///|
#warnings("-unnecessary_annotation")
pub fn gizmo_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GizmoPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let mut next = app
  if next.contains_resource(ecs_res_key_gizmo_plugin_marker) {
    return next
  }
  install_retained_gizmo_required_components(next.world())
  next = @asset.init_asset(next, fn() { GizmoAsset::GizmoAsset() })
  next = next.init_resource(fn() { GizmoHandles::GizmoHandles() })
  next = next.insert_world_resource(ecs_res_key_gizmo_plugin_marker, GizmoPluginMarker::{

  })
  next = global_gizmos_plugin(next)
  next = aabb_gizmo_plugin(next)
  next = frustum_gizmo_plugin(next)
  next = skinned_mesh_bounds_gizmo_plugin(next)
  next = next.add_last_system_config(
    @app.system(update_gizmo_meshes).in_set(gizmo_set_mesh),
  )
  next = next.configure_set(Last, gizmo_set_flush, before=[gizmo_set_mesh])
  next
}
