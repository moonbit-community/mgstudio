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
const DEFERRED_PBR_LIGHTING_PLUGIN_NAME : String = "mgstudio.pbr.DeferredPbrLightingPlugin"

///|
pub const DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID : Int = 1

///|
pub struct DeferredPbrLightingState {
  enabled : Bool
}

///|
pub fn DeferredPbrLightingState::enabled() -> DeferredPbrLightingState {
  DeferredPbrLightingState::{ enabled: true }
}

///|
pub fn DeferredPbrLightingState::disabled() -> DeferredPbrLightingState {
  DeferredPbrLightingState::{ enabled: false }
}

///|
pub let ecs_key_deferred_pbr_lighting_state : @ecs.ResourceKey[
  DeferredPbrLightingState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::DeferredPbrLightingState")

///|
pub struct DeferredPbrLightingPlugin {}

///|
pub fn DeferredPbrLightingPlugin::default() -> DeferredPbrLightingPlugin {
  DeferredPbrLightingPlugin::{  }
}

///|
pub impl @app.PluginReplacement for DeferredPbrLightingPlugin with plugin_name(
  _self,
) {
  DEFERRED_PBR_LIGHTING_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for DeferredPbrLightingPlugin with world_plugin(
  _self,
) {
  deferred_pbr_lighting_plugin
}

///|
pub struct PbrDeferredLightingDepthId {
  mut depth_id : Int
}

///|
pub fn PbrDeferredLightingDepthId::default() -> PbrDeferredLightingDepthId {
  PbrDeferredLightingDepthId::{
    depth_id: DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID,
  }
}

///|
pub fn PbrDeferredLightingDepthId::new(
  value : Int,
) -> PbrDeferredLightingDepthId {
  PbrDeferredLightingDepthId::{
    depth_id: if value < 0 {
      0
    } else if value > 255 {
      255
    } else {
      value
    },
  }
}

///|
pub fn PbrDeferredLightingDepthId::set(
  self : PbrDeferredLightingDepthId,
  value : Int,
) -> Unit {
  self.depth_id = if value < 0 { 0 } else if value > 255 { 255 } else { value }
}

///|
pub fn PbrDeferredLightingDepthId::get(
  self : PbrDeferredLightingDepthId,
) -> Int {
  self.depth_id
}

///|
pub fn deferred_pbr_lighting_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.insert_world_resource(
    ecs_key_deferred_pbr_lighting_state,
    DeferredPbrLightingState::enabled(),
  )
}

///|
pub fn deferred_pbr_lighting_enabled(world : @ecs.World) -> Bool {
  match (try! world.get_resource(ecs_key_deferred_pbr_lighting_state)) {
    Some(state) => state.enabled
    None => false
  }
}
