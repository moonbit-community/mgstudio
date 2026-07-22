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
pub let ecs_key_camera_movement : @ecs.ComponentKey[CameraMovement] = @dev_tools_easy_camera_movement.ecs_key_camera_movement

///|
pub type CameraMovement = @dev_tools_easy_camera_movement.CameraMovement

///|
pub type EasyCameraMovementPlugin = @dev_tools_easy_camera_movement.EasyCameraMovementPlugin

///|
pub struct DevToolsDiagnosticsOverlayPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn DevToolsDiagnosticsOverlayPlugin::DevToolsDiagnosticsOverlayPlugin() -> DevToolsDiagnosticsOverlayPlugin {
  DevToolsDiagnosticsOverlayPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsDiagnosticsOverlayPlugin with fn name(_self) {
  DEV_TOOLS_DIAGNOSTICS_OVERLAY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsDiagnosticsOverlayPlugin with fn build(
  _self,
  app,
) {
  diagnostics_overlay_plugin(app)
}

///|
pub struct DevToolsFpsOverlayPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn DevToolsFpsOverlayPlugin::DevToolsFpsOverlayPlugin() -> DevToolsFpsOverlayPlugin {
  DevToolsFpsOverlayPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsFpsOverlayPlugin with fn name(_self) {
  DEV_TOOLS_FPS_OVERLAY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsFpsOverlayPlugin with fn build(_self, app) {
  fps_overlay_plugin(app)
}

///|
pub struct DevToolsPickingDebugPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn DevToolsPickingDebugPlugin::DevToolsPickingDebugPlugin() -> DevToolsPickingDebugPlugin {
  DevToolsPickingDebugPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsPickingDebugPlugin with fn name(_self) {
  DEV_TOOLS_PICKING_DEBUG_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsPickingDebugPlugin with fn build(_self, app) {
  dev_tools_picking_debug_plugin(app)
}

///|
pub struct DevToolsEasyScreenshotPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn DevToolsEasyScreenshotPlugin::DevToolsEasyScreenshotPlugin() -> DevToolsEasyScreenshotPlugin {
  DevToolsEasyScreenshotPlugin::{  }
}

///|
pub impl @app.Plugin for DevToolsEasyScreenshotPlugin with fn name(_self) {
  DEV_TOOLS_EASY_SCREENSHOT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DevToolsEasyScreenshotPlugin with fn build(_self, app) {
  dev_tools_easy_screenshot_plugin(app)
}

///|
pub struct DevToolsPlugins {}

///|
#warnings("-unnecessary_annotation")
pub fn DevToolsPlugins::DevToolsPlugins() -> DevToolsPlugins {
  DevToolsPlugins::{  }
}

///|
pub fn DevToolsPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("DevToolsPlugins")
  .add(DevToolsDiagnosticsOverlayPlugin::DevToolsDiagnosticsOverlayPlugin())
  .add(DevToolsFpsOverlayPlugin::DevToolsFpsOverlayPlugin())
  .add(DevToolsPickingDebugPlugin::DevToolsPickingDebugPlugin())
  .add(DevToolsEasyScreenshotPlugin::DevToolsEasyScreenshotPlugin())
  .add(@dev_tools_ci_testing.CiTestingPlugin::CiTestingPlugin())
}

///|
pub impl @app.Plugin for DevToolsPlugins with fn name(_self) {
  DEV_TOOLS_PLUGINS_NAME
}

///|
pub impl @app.Plugin for DevToolsPlugins with fn build(_self, app) {
  app.add_plugins(DevToolsPlugins::build())
}

///|
pub fn dev_tools_plugins() -> DevToolsPlugins {
  DevToolsPlugins()
}
