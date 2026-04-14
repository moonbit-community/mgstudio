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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/pipeline_2d.rs`.

///|
pub struct LineGizmo2dPlugin {}

///|
const LINE_GIZMO_2D_PLUGIN_NAME : String = "mgstudio.gizmos_render.LineGizmo2dPlugin"

///|
pub fn LineGizmo2dPlugin::default() -> LineGizmo2dPlugin {
  LineGizmo2dPlugin::{  }
}

///|
pub fn line_gizmo_2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  line_gizmo_2d_plugin_with(app, LineGizmo2dPlugin::default())
}

///|
pub fn line_gizmo_2d_plugin_with(
  app : @app.App[@ecs.World],
  plugin : LineGizmo2dPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @sprite_render.sprite_render_plugin(app)
}

///|
pub impl @app.PluginReplacement for LineGizmo2dPlugin with plugin_name(_self) {
  LINE_GIZMO_2D_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for LineGizmo2dPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    line_gizmo_2d_plugin_with(app, self)
  }
}
