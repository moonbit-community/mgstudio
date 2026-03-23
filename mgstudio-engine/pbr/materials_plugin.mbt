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
pub const MATERIALS_PLUGIN_ID : String = "bevy_pbr::MaterialsPlugin"

///|
pub struct MaterialsPlugin {}

///|
pub fn MaterialsPlugin::default() -> MaterialsPlugin {
  MaterialsPlugin::{  }
}

///|
pub struct MaterialsPluginState {}

///|
pub let ecs_key_materials_plugin_state : @ecs.ResourceKey[MaterialsPluginState] = @ecs.register_resource(
  debug_name="bevy_pbr::MaterialsPluginState",
)

///|
fn init_materials_resources(world : @ecs.World) -> Unit {
  let default_opaque_renderer_method = get_default_opaque_renderer_method_resource(
    world,
  )
  if !default_opaque_renderer_method.is_present() {
    default_opaque_renderer_method.insert(
      DefaultOpaqueRendererMethod::forward(),
    )
  }
}

///|
pub impl @app.PluginReplacement for MaterialsPlugin with replacement_id(_self) {
  MATERIALS_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for MaterialsPlugin with world_plugin(_self) {
  materials_plugin
}

///|
pub fn materials_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_materials_plugin_state) {
    app
  } else {
    app
    .insert_world_resource(ecs_key_materials_plugin_state, MaterialsPluginState::{

    })
    .add_startup_system(init_materials_resources)
  }
}
