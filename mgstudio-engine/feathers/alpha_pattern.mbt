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
// Bevy source: `bevy/crates/bevy_feathers/src/alpha_pattern.rs`.

///|
pub struct AlphaPatternMaterial {}

///|
pub fn AlphaPatternMaterial::default() -> AlphaPatternMaterial {
  AlphaPatternMaterial::{  }
}

///|
pub struct AlphaPatternResource {
  material_id : Int
}

///|
let alpha_pattern_resource_key : @ecs.ResourceKey[AlphaPatternResource] = @ecs.register_resource(
  debug_name="mgstudio.feathers.alpha_pattern.resource",
)

///|
pub struct AlphaPattern {} derive(Default, Debug)

///|
pub fn AlphaPatternResource::default() -> AlphaPatternResource {
  AlphaPatternResource::{ material_id: -1 }
}

///|
pub impl @app.Resource for AlphaPatternResource with resource() {
  alpha_pattern_resource_key
}

///|
pub struct AlphaPatternPlugin {}

///|
pub(all) struct AlphaPatternPluginMarker {}

///|
let alpha_pattern_plugin_marker_key : @ecs.ResourceKey[AlphaPatternPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio.feathers.alpha_pattern.plugin_marker",
)

///|
pub fn AlphaPatternPlugin::default() -> AlphaPatternPlugin {
  AlphaPatternPlugin::{  }
}

///|
pub fn alpha_pattern_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(alpha_pattern_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(alpha_pattern_plugin_marker_key, AlphaPatternPluginMarker::{

    })
    app.init_resource(fn() { AlphaPatternResource::default() })
  }
}
