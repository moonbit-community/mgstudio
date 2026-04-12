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

pub const GIZMO_PLUGIN_ID : String = "mgstudio_gizmos::GizmoPlugin"

///|
priv struct GizmoPluginMarker {}

///|
let ecs_res_key_gizmo_plugin_marker : @ecs.ResourceKey[GizmoPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoPluginMarker",
)

///|
pub struct GizmoPlugin {}

///|
pub fn GizmoPlugin::default() -> GizmoPlugin {
  GizmoPlugin::{  }
}

///|
pub type Isometry2d = @sprite.Isometry2d

///|
pub type GizmoLineJoint = @sprite.GizmoLineJoint

///|
pub type GizmoLineStyle = @sprite.GizmoLineStyle

///|
pub type GizmoLineConfig = @sprite.GizmoLineConfig

///|
pub type GizmoConfig = @sprite.GizmoConfig

///|
pub type DefaultGizmoConfigGroup = @sprite.DefaultGizmoConfigGroup

///|
pub type GizmoConfigStore = @sprite.GizmoConfigStore

///|
pub fn[G : Default + @sprite.GizmoConfigGroup] init_gizmo_group(
  app : @app.App[@ecs.World],
  group : G,
) -> @app.App[@ecs.World] {
  @sprite.init_gizmo_group(app, group)
}

///|
pub type Gizmos[G] = @sprite.Gizmos[G]

///|
pub type RoundedRectBuilder = @sprite.RoundedRectBuilder

///|
pub type Ellipse2dBuilder = @sprite.Ellipse2dBuilder

///|
pub type Arc2dBuilder = @sprite.Arc2dBuilder

///|
pub type ArrowBuilder = @sprite.ArrowBuilder

///|
pub type Grid2dBuilder = @sprite.Grid2dBuilder

///|
pub fn gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gizmo_plugin_with(app, GizmoPlugin::default())
}

///|
pub impl @app.PluginReplacement for GizmoPlugin with replacement_id(_self) {
  GIZMO_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for GizmoPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    gizmo_plugin_with(app, self)
  }
}

///|
pub fn gizmo_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GizmoPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let mut next = app
  if next.contains_resource(ecs_res_key_gizmo_plugin_marker) {
    return next
  }
  next = next.insert_world_resource(ecs_res_key_gizmo_plugin_marker, GizmoPluginMarker::{

  })
  next = @sprite_render.sprite_render_plugin(next)
  next = @gizmos_render.gizmo_render_plugin(next)
  next = global_gizmos_plugin(next)
  next = aabb_gizmo_plugin(next)
  next = frustum_gizmo_plugin(next)
  next = skinned_mesh_bounds_gizmo_plugin(next)
  next
}
