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
// Bevy source: `bevy/crates/bevy_dev_tools/src/frame_time_graph/mod.rs`.

///|
pub type FrameTimeGraphConfigUniform = @dev_tools.FrameTimeGraphConfigUniform

///|
pub type FrameTimeGraphPlugin = @dev_tools.FrameTimeGraphPlugin

///|
pub let fps_overlay_set_customize : @app.SystemSet = @dev_tools.fps_overlay_set_customize

///|
pub let fps_overlay_set_update_text : @app.SystemSet = @dev_tools.fps_overlay_set_update_text

///|
pub fn frame_time_graph_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @dev_tools.frame_time_graph_plugin(app)
}

///|
pub fn frame_time_graph_plugin_with(
  app : @app.App[@ecs.World],
  plugin : FrameTimeGraphPlugin,
) -> @app.App[@ecs.World] {
  @dev_tools.frame_time_graph_plugin_with(app, plugin)
}

///|
pub fn frame_time_graph_default_config() -> @dev_tools.FrameTimeGraphConfig {
  @dev_tools.FrameTimeGraphConfig::default()
}

///|
pub fn fps_overlay_default_config() -> @dev_tools.FpsOverlayConfig {
  @dev_tools.FpsOverlayConfig::default()
}
