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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`.

///|
const LIGHT_PLUGIN_NAME : String = "mgstudio.light.LightPlugin"

///|
pub struct LightPlugin {}

///|
pub fn LightPlugin::default() -> LightPlugin {
  LightPlugin::{  }
}

///|
pub impl @app.Plugin for LightPlugin with name(_self) {
  LIGHT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LightPlugin with build(_self, app) {
  light_plugin(app)
}

///|
pub fn light_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(ecs_key_global_ambient_light) {
    next = next.insert_world_resource(
      ecs_key_global_ambient_light,
      GlobalAmbientLight::default(),
    )
  }
  if !next.contains_resource(ecs_key_point_light_shadow_map) {
    next = next.insert_world_resource(
      ecs_key_point_light_shadow_map,
      PointLightShadowMap::default(),
    )
  }
  if !next.contains_resource(ecs_key_directional_light_shadow_map) {
    next = next.insert_world_resource(
      ecs_key_directional_light_shadow_map,
      DirectionalLightShadowMap::default(),
    )
  }
  next
  .add_systems(
    @app.Update,
    @app.system(
      @app.system_param2(automatically_add_parallax_correction_components),
    ),
  )
  .add_post_update_system(validate_directional_light_shadow_map_size)
}
