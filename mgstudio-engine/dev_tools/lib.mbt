// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_dev_tools/src/lib.rs`.
// Canonical dev-tools plugin set for diagnostics/profiling workflows.

///|
const DEV_TOOLS_PLUGINS_NAME : String = "mgstudio.dev_tools.DevToolsPlugins"

///|
const DEV_TOOLS_DIAGNOSTICS_OVERLAY_PLUGIN_NAME : String = "mgstudio.dev_tools.DiagnosticsOverlayPlugin"

///|
const DEV_TOOLS_FPS_OVERLAY_PLUGIN_NAME : String = "mgstudio.dev_tools.FpsOverlayPlugin"

///|
const DEV_TOOLS_PICKING_DEBUG_PLUGIN_NAME : String = "mgstudio.dev_tools.PickingDebugPlugin"

///|
const DEV_TOOLS_EASY_SCREENSHOT_PLUGIN_NAME : String = "mgstudio.dev_tools.EasyScreenshotPlugin"

///|
pub struct DevToolsDiagnosticsOverlayPlugin {}

///|
pub fn DevToolsDiagnosticsOverlayPlugin::default() -> DevToolsDiagnosticsOverlayPlugin {
  DevToolsDiagnosticsOverlayPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsDiagnosticsOverlayPlugin with name(_self) {
  DEV_TOOLS_DIAGNOSTICS_OVERLAY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsDiagnosticsOverlayPlugin with build(_self, app) {
  diagnostics_overlay_plugin(app)
}

///|
pub struct DevToolsFpsOverlayPlugin {}

///|
pub fn DevToolsFpsOverlayPlugin::default() -> DevToolsFpsOverlayPlugin {
  DevToolsFpsOverlayPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsFpsOverlayPlugin with name(_self) {
  DEV_TOOLS_FPS_OVERLAY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsFpsOverlayPlugin with build(_self, app) {
  fps_overlay_plugin(app)
}

///|
pub struct DevToolsPickingDebugPlugin {}

///|
pub fn DevToolsPickingDebugPlugin::default() -> DevToolsPickingDebugPlugin {
  DevToolsPickingDebugPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsPickingDebugPlugin with name(_self) {
  DEV_TOOLS_PICKING_DEBUG_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsPickingDebugPlugin with build(_self, app) {
  dev_tools_picking_debug_plugin(app)
}

///|
pub struct DevToolsEasyScreenshotPlugin {}

///|
pub fn DevToolsEasyScreenshotPlugin::default() -> DevToolsEasyScreenshotPlugin {
  DevToolsEasyScreenshotPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsEasyScreenshotPlugin with name(_self) {
  DEV_TOOLS_EASY_SCREENSHOT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsEasyScreenshotPlugin with build(_self, app) {
  dev_tools_easy_screenshot_plugin(app)
}

///|
pub struct DevToolsPlugins {}

///|
pub fn DevToolsPlugins::default() -> DevToolsPlugins {
  DevToolsPlugins::{  }
}

///|
pub fn DevToolsPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("DevToolsPlugins")
  .add(DevToolsDiagnosticsOverlayPlugin::default())
  .add(DevToolsFpsOverlayPlugin::default())
  .add(DevToolsPickingDebugPlugin::default())
  .add(DevToolsEasyScreenshotPlugin::default())
  .add(@dev_tools_ci_testing.CiTestingPlugin::default())
}

///|
pub impl @app.Plugin for DevToolsPlugins with name(_self) {
  DEV_TOOLS_PLUGINS_NAME
}

///|
pub impl @app.Plugin for DevToolsPlugins with build(_self, app) {
  app.add_plugins(DevToolsPlugins::build())
}

///|
pub fn dev_tools_plugins() -> DevToolsPlugins {
  DevToolsPlugins::default()
}
