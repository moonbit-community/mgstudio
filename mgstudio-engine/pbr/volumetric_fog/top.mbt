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
// Bevy source: `bevy/crates/bevy_pbr/src/volumetric_fog/mod.rs`.

///|
const VOLUMETRIC_FOG_PLUGIN_NAME : String = "mgstudio.pbr.volumetric_fog.VolumetricFogPlugin"

///|
pub type VolumetricFog = @light.VolumetricFog

///|
pub type FogVolume = @light.FogVolume

///|
pub struct VolumetricFogPlugin {}

///|
pub fn VolumetricFogPlugin::default() -> VolumetricFogPlugin {
  VolumetricFogPlugin::{  }
}

///|
pub impl @app.Plugin for VolumetricFogPlugin with name(_self) {
  VOLUMETRIC_FOG_PLUGIN_NAME
}

///|
pub impl @app.Plugin for VolumetricFogPlugin with build(self, app) {
  register_embedded_wgsl_sources()
  volumetric_fog_plugin_install_with(app, self)
}

///|
pub struct FogAssets {
  plane_mesh : @asset.Handle[@mesh.Mesh]?
  cube_mesh : @asset.Handle[@mesh.Mesh]?
}

///|
pub fn FogAssets::default() -> FogAssets {
  FogAssets::{ plane_mesh: None, cube_mesh: None }
}

///|
pub struct VolumetricFogPluginState {
  fog_assets : FogAssets
  extracted_view_count : Int
  extracted_volume_count : Int
}

///|
pub fn VolumetricFogPluginState::default() -> VolumetricFogPluginState {
  VolumetricFogPluginState::{
    fog_assets: FogAssets::default(),
    extracted_view_count: 0,
    extracted_volume_count: 0,
  }
}

///|
let ecs_key_volumetric_fog_plugin_state : @ecs.ResourceKey[
  VolumetricFogPluginState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::VolumetricFogPluginState")

///|
pub impl @app.Resource for VolumetricFogPluginState with resource() {
  ecs_key_volumetric_fog_plugin_state
}

///|
pub fn volumetric_fog_plugin_state_with_assets(
  state : VolumetricFogPluginState,
  fog_assets : FogAssets,
) -> VolumetricFogPluginState {
  VolumetricFogPluginState::{ ..state, fog_assets, }
}

///|
pub fn volumetric_fog_plugin_state_with_extracted_counts(
  state : VolumetricFogPluginState,
  extracted_view_count : Int,
  extracted_volume_count : Int,
) -> VolumetricFogPluginState {
  VolumetricFogPluginState::{
    ..state,
    extracted_view_count: if extracted_view_count < 0 {
      0
    } else {
      extracted_view_count
    },
    extracted_volume_count: if extracted_volume_count < 0 {
      0
    } else {
      extracted_volume_count
    },
  }
}

///|
pub fn pbr_volumetric_fog_default() -> VolumetricFog {
  VolumetricFog::default()
}

///|
pub fn pbr_fog_volume_default() -> FogVolume {
  FogVolume::default()
}

///|
pub fn volumetric_fog_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  volumetric_fog_plugin_install_with(app, VolumetricFogPlugin::default())
}

///|
pub fn volumetric_fog_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : VolumetricFogPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(ecs_key_volumetric_fog_plugin_state) {
    app
  } else {
    app.insert_world_resource(
      ecs_key_volumetric_fog_plugin_state,
      VolumetricFogPluginState::default(),
    )
  }
}
