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
// Bevy source: `bevy/crates/bevy_pbr/src/transmission/mod.rs::ScreenSpaceTransmissionPlugin`.

///|
const SCREEN_SPACE_TRANSMISSION_PLUGIN_NAME : String = "mgstudio.pbr.ScreenSpaceTransmissionPlugin"

///|
pub struct ScreenSpaceTransmissionPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn ScreenSpaceTransmissionPlugin::ScreenSpaceTransmissionPlugin() -> ScreenSpaceTransmissionPlugin {
  ScreenSpaceTransmissionPlugin::{  }
}

///|
fn screen_space_transmission_plugin_register_required_components(
  world : @ecs.World,
) -> Unit {
  world.register_required_components_with(
    ecs_key_camera3d,
    @transmission.ecs_key_screen_space_transmission,
    fn() { ScreenSpaceTransmission() },
  ) catch {
    _ =>
      abort(
        "ScreenSpaceTransmissionPlugin failed to register Camera3d required components",
      )
  }
}

///|
pub fn screen_space_transmission_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ScreenSpaceTransmissionPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @transmission.register_embedded_wgsl_sources()
  let extract_plugin : @render.ExtractComponentPlugin[
    @transmission.ScreenSpaceTransmission,
    ScreenSpaceTransmissionPlugin,
  ] = ExtractComponentPlugin()
  let next = @render.extract_component_plugin_with(app, extract_plugin)
  screen_space_transmission_plugin_register_required_components(next.world())
  next
}

///|
pub impl @app.Plugin for ScreenSpaceTransmissionPlugin with fn name(_self) {
  SCREEN_SPACE_TRANSMISSION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScreenSpaceTransmissionPlugin with fn build(self, app) {
  screen_space_transmission_plugin_with(app, self)
}
