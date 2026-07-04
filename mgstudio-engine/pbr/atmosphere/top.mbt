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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/mod.rs`.

///|
const ATMOSPHERE_PLUGIN_NAME : String = "mgstudio.pbr.AtmospherePlugin"

///|
pub struct AtmospherePlugin {}

///|
pub fn AtmospherePlugin::AtmospherePlugin() -> AtmospherePlugin {
  AtmospherePlugin::{  }
}

///|
pub impl @app.Plugin for AtmospherePlugin with fn name(_self) {
  ATMOSPHERE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AtmospherePlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  atmosphere_plugin_install_with(app, self)
}

///|
pub fn atmosphere_plugin() -> AtmospherePlugin {
  AtmospherePlugin::AtmospherePlugin()
}

///|
pub fn atmosphere_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  atmosphere_plugin_install_with(app, AtmospherePlugin::AtmospherePlugin())
}

///|
pub fn atmosphere_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : AtmospherePlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.add_systems_world(@app.Update, prepare_atmosphere_probe_components)
}
