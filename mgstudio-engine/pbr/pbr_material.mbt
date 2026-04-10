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
pub type AlphaMode3d = @material.AlphaMode3d

///|
pub type Face3d = @material.Face3d

///|
pub type OpaqueRendererMethod = @material.OpaqueRendererMethod

///|
pub type DefaultOpaqueRendererMethod = @material.DefaultOpaqueRendererMethod

///|
pub type StandardMaterial = @material.StandardMaterial

///|
pub const STANDARD_MATERIAL_PLUGIN_ID : String = "bevy_pbr::MaterialPlugin<StandardMaterial>"

///|
pub(all) struct StandardMaterialPlugin {
  prepass_enabled : Bool
}

///|
pub fn StandardMaterialPlugin::default() -> StandardMaterialPlugin {
  StandardMaterialPlugin::{ prepass_enabled: true }
}

///|
pub struct StandardMaterialPluginState {
  prepass_enabled : Bool
}

///|
pub fn StandardMaterialPluginState::from_plugin(
  plugin : StandardMaterialPlugin,
) -> StandardMaterialPluginState {
  StandardMaterialPluginState::{ prepass_enabled: plugin.prepass_enabled }
}

///|
pub let ecs_key_standard_material_plugin_state : @ecs.ResourceKey[
  StandardMaterialPluginState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::StandardMaterialPluginState",
)

///|
pub impl @app.PluginReplacement for StandardMaterialPlugin with replacement_id(
  _self,
) {
  STANDARD_MATERIAL_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for StandardMaterialPlugin with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    standard_material_plugin_with(app, self)
  }
}

///|
pub fn standard_material_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  standard_material_plugin_with(app, StandardMaterialPlugin::default())
}

///|
pub fn standard_material_plugin_with(
  app : @app.App[@ecs.World],
  plugin : StandardMaterialPlugin,
) -> @app.App[@ecs.World] {
  app.insert_world_resource(
    ecs_key_standard_material_plugin_state,
    StandardMaterialPluginState::from_plugin(plugin),
  )
}

///|
pub fn standard_material_prepass_enabled(world : @ecs.World) -> Bool {
  match (try! world.get_resource(ecs_key_standard_material_plugin_state)) {
    Some(state) => state.prepass_enabled
    None => true
  }
}
