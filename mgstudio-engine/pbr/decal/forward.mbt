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
/// Marker component aligned with Bevy's `ForwardDecal`.
pub struct ForwardDecal {} derive(ToJson, FromJson)

///|
const FORWARD_DECAL_PLUGIN_NAME : String = "mgstudio.pbr.decal.ForwardDecalPlugin"

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
pub struct ForwardDecalPlugin {}

///|
pub fn ForwardDecalPlugin::default() -> ForwardDecalPlugin {
  ForwardDecalPlugin::{  }
}

///|
pub impl @app.PluginReplacement for ForwardDecalPlugin with plugin_name(_self) {
  FORWARD_DECAL_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for ForwardDecalPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    ignore(self)
    app
  }
}

///|
pub struct ForwardDecalMaterialExtUniform {
  inv_depth_fade_factor : Float
}

///|
pub fn ForwardDecalMaterialExtUniform::default() -> ForwardDecalMaterialExtUniform {
  ForwardDecalMaterialExtUniform::{ inv_depth_fade_factor: 1.0F / 8.0F }
}

///|
pub fn pbr_forward_decal_material_ext_uniform(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExtUniform {
  let safe = if depth_fade_factor < 0.001F { 0.001F } else { depth_fade_factor }
  ForwardDecalMaterialExtUniform::{ inv_depth_fade_factor: 1.0F / safe }
}

///|
pub struct ForwardDecalPipelineKey {
  alpha_blend : Bool
  depth_compare_always : Bool
}

///|
pub fn ForwardDecalPipelineKey::default() -> ForwardDecalPipelineKey {
  ForwardDecalPipelineKey::{ alpha_blend: true, depth_compare_always: true }
}

///|
pub fn pbr_forward_decal_shader_defs(
  _key : ForwardDecalPipelineKey,
) -> Array[String] {
  ["FORWARD_DECAL"]
}

///|
pub fn pbr_forward_decal_specialized_label(base : String) -> String {
  "forward_decal_\{base}"
}

///|
pub fn ForwardDecal::default() -> ForwardDecal {
  ForwardDecal::{  }
}

///|
pub let ecs_key_forward_decal : @ecs.ComponentKey[ForwardDecal] = @ecs.register_component(
  debug_name="render3d.forward_decal",
)

///|
pub impl @ecs.Component for ForwardDecal with component() {
  ecs_key_forward_decal
}
