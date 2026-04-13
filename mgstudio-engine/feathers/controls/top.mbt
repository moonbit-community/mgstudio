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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/mod.rs`.

///|
pub struct ControlsPlugin {}

///|
pub(all) struct ControlsRuntimePluginMarker {}

///|
let controls_runtime_plugin_marker_key : @ecs.ResourceKey[
  ControlsRuntimePluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio.feathers.controls.runtime_plugin_marker",
)

///|
pub fn ControlsPlugin::default() -> ControlsPlugin {
  ControlsPlugin::{  }
}

///|
fn ensure_controls_runtime(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(controls_runtime_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(controls_runtime_plugin_marker_key, ControlsRuntimePluginMarker::{

    })
    @ui_widgets.ui_widgets_plugin(app)
  }
}

///|
pub fn controls_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app).add_plugins([
    button_plugin, checkbox_plugin, color_plane_plugin, color_slider_plugin, color_swatch_plugin,
    radio_plugin, slider_plugin, toggle_switch_plugin,
  ])
}
