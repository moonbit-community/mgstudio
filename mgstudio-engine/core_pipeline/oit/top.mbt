// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/oit/mod.rs`.
// Order-independent transparency plugin and settings.

///|
const OIT_PLUGIN_NAME : String = "mgstudio.core_pipeline.oit.OrderIndependentTransparencyPlugin"

///|
pub struct OrderIndependentTransparencyPlugin {}

///|
pub fn OrderIndependentTransparencyPlugin::default() -> OrderIndependentTransparencyPlugin {
  OrderIndependentTransparencyPlugin::{  }
}

///|
pub struct OrderIndependentTransparencySettings {
  alpha_threshold : Float
  fragments_per_pixel_average : Float
  sorted_fragment_max_count : Int
} derive(ToJson, FromJson)

///|
pub fn OrderIndependentTransparencySettings::default() -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    alpha_threshold: 0.001F,
    fragments_per_pixel_average: 1.0F,
    sorted_fragment_max_count: 64,
  }
}

///|
pub let ecs_key_order_independent_transparency_settings : @ecs.ComponentKey[
  OrderIndependentTransparencySettings,
] = @ecs.register_component(
  debug_name="core_pipeline.order_independent_transparency_settings",
)

///|
pub impl @ecs.Component for OrderIndependentTransparencySettings with component() {
  ecs_key_order_independent_transparency_settings
}

///|
pub fn oit_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  oit_plugin_with(app, OrderIndependentTransparencyPlugin::default())
}

///|
pub impl @app.Plugin for OrderIndependentTransparencyPlugin with name(_self) {
  OIT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for OrderIndependentTransparencyPlugin with build(
  self,
  app,
) {
  oit_plugin_with(app, self)
}

///|
pub fn oit_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : OrderIndependentTransparencyPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugins(@resolve.OitResolvePlugin::default())
}
