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
pub struct AtmospherePlugin {
  enabled : Bool
  supports_compute : Bool
  supports_storage_binding : Bool
}

///|
pub fn AtmospherePlugin::default() -> AtmospherePlugin {
  AtmospherePlugin::{
    enabled: true,
    supports_compute: true,
    supports_storage_binding: true,
  }
}

///|
pub impl @app.Plugin for AtmospherePlugin with name(_self) {
  ATMOSPHERE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AtmospherePlugin with build(self, app) {
  atmosphere_plugin_install_with(app, self)
}

///|
pub struct AtmospherePluginState {
  plugin : AtmospherePlugin
  extracted_camera_count : Int
  lut_ready : Bool
}

///|
pub fn AtmospherePluginState::default() -> AtmospherePluginState {
  AtmospherePluginState::{
    plugin: AtmospherePlugin::default(),
    extracted_camera_count: 0,
    lut_ready: false,
  }
}

///|
let ecs_key_atmosphere_plugin_state : @ecs.ResourceKey[AtmospherePluginState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::AtmospherePluginState",
)

///|
pub impl @app.Resource for AtmospherePluginState with resource() {
  ecs_key_atmosphere_plugin_state
}

///|
pub fn atmosphere_plugin_state_with_extracted_camera_count(
  state : AtmospherePluginState,
  extracted_camera_count : Int,
) -> AtmospherePluginState {
  AtmospherePluginState::{
    ..state,
    extracted_camera_count: if extracted_camera_count < 0 {
      0
    } else {
      extracted_camera_count
    },
  }
}

///|
pub fn atmosphere_plugin_state_with_lut_ready(
  state : AtmospherePluginState,
  lut_ready : Bool,
) -> AtmospherePluginState {
  AtmospherePluginState::{ ..state, lut_ready, }
}

///|
pub fn atmosphere_plugin() -> AtmospherePlugin {
  AtmospherePlugin::default()
}

///|
pub fn atmosphere_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  atmosphere_plugin_install_with(app, AtmospherePlugin::default())
}

///|
pub fn atmosphere_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : AtmospherePlugin,
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_atmosphere_plugin_state) {
    app
  } else {
    app.insert_world_resource(ecs_key_atmosphere_plugin_state, AtmospherePluginState::{
      ..AtmospherePluginState::default(),
      plugin,
    })
  }
}
