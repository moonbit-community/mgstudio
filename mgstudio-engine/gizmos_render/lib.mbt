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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/lib.rs`.
// Package-level render-queue boundary for gizmos.

const GIZMO_RENDER_PLUGIN_NAME : String = "mgstudio.gizmos_render.GizmoRenderPlugin"

///|
priv struct GizmoRenderPluginMarker {}

///|
let ecs_res_key_gizmo_render_plugin_marker : @ecs.ResourceKey[
  GizmoRenderPluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_gizmos_render::GizmoRenderPluginMarker",
)

///|
pub struct GizmoRenderPlugin {}

///|
pub fn GizmoRenderPlugin::default() -> GizmoRenderPlugin {
  GizmoRenderPlugin::{  }
}

///|
pub(all) enum GizmoRenderSystems {
  QueueLineGizmos2d
  QueueLineGizmos3d
} derive(Eq, Debug)

///|
pub fn gizmo_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gizmo_render_plugin_with(app, GizmoRenderPlugin::default())
}

///|
pub impl @app.Plugin for GizmoRenderPlugin with name(_self) {
  GIZMO_RENDER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GizmoRenderPlugin with build(self, app) {
  gizmo_render_plugin_with(app, self)
}

///|
pub fn gizmo_render_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GizmoRenderPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(ecs_res_key_gizmo_render_plugin_marker) {
    return app
  }
  @sprite_render.sprite_render_plugin(app).insert_world_resource(
    ecs_res_key_gizmo_render_plugin_marker,
    GizmoRenderPluginMarker::{  },
  )
}

///|
pub fn gizmo_render_system_set(system : GizmoRenderSystems) -> @app.SystemSet {
  match system {
    QueueLineGizmos2d => @sprite_render.render2d_set_queue
    QueueLineGizmos3d => @pbr.render3d_set_queue
  }
}
