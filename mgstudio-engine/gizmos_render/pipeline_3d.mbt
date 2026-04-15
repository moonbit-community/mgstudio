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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/pipeline_3d.rs`.

///|
pub struct LineGizmo3dPlugin {}

///|
const LINE_GIZMO_3D_PLUGIN_NAME : String = "mgstudio.gizmos_render.LineGizmo3dPlugin"

///|
pub fn LineGizmo3dPlugin::default() -> LineGizmo3dPlugin {
  LineGizmo3dPlugin::{  }
}

///|
pub fn line_gizmo_3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  line_gizmo_3d_plugin_with(app, LineGizmo3dPlugin::default())
}

///|
pub fn line_gizmo_3d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : LineGizmo3dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @pbr.render3d_plugin(app)
}

///|
pub impl @app.Plugin for LineGizmo3dPlugin with name(_self) {
  LINE_GIZMO_3D_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LineGizmo3dPlugin with build(self, app) {
  line_gizmo_3d_plugin_with(app, self)
}
