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
// Bevy source: `bevy/crates/bevy_anti_alias/src/contrast_adaptive_sharpening/mod.rs`.

///|
pub const CAS_RUNTIME_SUPPORTED : Bool = false

///|
const CAS_PLUGIN_NAME : String = "mgstudio.anti_alias.contrast_adaptive_sharpening.CasPlugin"

///|
pub struct CasPlugin {}

///|
pub fn CasPlugin::default() -> CasPlugin {
  CasPlugin::{  }
}

///|
pub struct ContrastAdaptiveSharpening {
  enabled : Bool
  sharpening_strength : Float
  denoise : Bool
} derive(Eq, Debug)

///|
pub fn ContrastAdaptiveSharpening::default() -> ContrastAdaptiveSharpening {
  ContrastAdaptiveSharpening::{
    enabled: true,
    sharpening_strength: 0.6,
    denoise: false,
  }
}

///|
pub struct DenoiseCas {
  enabled : Bool
} derive(Eq, Debug)

///|
pub fn DenoiseCas::default() -> DenoiseCas {
  DenoiseCas::{ enabled: false }
}

///|
pub struct CasUniform {
  sharpness : Float
} derive(Eq, Debug)

///|
pub fn CasUniform::default() -> CasUniform {
  CasUniform::{ sharpness: 0.0 }
}

///|
let ecs_key_contrast_adaptive_sharpening : @ecs.ComponentKey[
  ContrastAdaptiveSharpening,
] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::ContrastAdaptiveSharpening",
)

///|
let ecs_key_denoise_cas : @ecs.ComponentKey[DenoiseCas] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::DenoiseCas",
)

///|
let ecs_key_cas_uniform : @ecs.ComponentKey[CasUniform] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::CasUniform",
)

///|
pub impl @ecs.Component for ContrastAdaptiveSharpening with component() {
  ecs_key_contrast_adaptive_sharpening
}

///|
pub impl @ecs.Component for DenoiseCas with component() {
  ecs_key_denoise_cas
}

///|
pub impl @ecs.Component for CasUniform with component() {
  ecs_key_cas_uniform
}

///|
pub struct CasRuntimeState {
  enabled_camera_count : Int
  active_camera_count : Int
  denoise_camera_count : Int
} derive(Eq, Debug)

///|
pub fn CasRuntimeState::default() -> CasRuntimeState {
  CasRuntimeState::{
    enabled_camera_count: 0,
    active_camera_count: 0,
    denoise_camera_count: 0,
  }
}

///|
pub let ecs_key_cas_runtime_state : @ecs.ResourceKey[CasRuntimeState] = @ecs.register_resource(
  debug_name="anti_alias.cas.runtime_state",
)

///|
pub impl @app.Resource for CasRuntimeState with resource() {
  ecs_key_cas_runtime_state
}

///|
pub impl @app.PluginReplacement for CasPlugin with plugin_name(_self) {
  CAS_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for CasPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    cas_plugin_with(app, self)
  }
}

///|
pub fn cas_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  cas_plugin_with(app, CasPlugin::default())
}

///|
pub fn cas_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : CasPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { CasRuntimeState::default() })
  .add_system(cas_update_runtime_state)
}

///|
fn cas_camera_component_present(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, @sprite.ecs_key_camera)
}

///|
pub fn cas_update_runtime_state(world : @ecs.World) -> Unit {
  let mut enabled_camera_count = 0
  let mut active_camera_count = 0
  let mut denoise_camera_count = 0
  world.for_each_component(ecs_key_contrast_adaptive_sharpening, fn(
    entity,
    cas : ContrastAdaptiveSharpening,
  ) {
    if cas_camera_component_present(world, entity) {
      enabled_camera_count = enabled_camera_count + 1
      if cas.enabled && cas.sharpening_strength > 0.0 {
        active_camera_count = active_camera_count + 1
      }
      if cas.denoise {
        denoise_camera_count = denoise_camera_count + 1
      }
    }
  })
  let next = CasRuntimeState::{
    enabled_camera_count,
    active_camera_count,
    denoise_camera_count,
  }
  let current : CasRuntimeState? = try! world.get_resource(
    ecs_key_cas_runtime_state,
  )
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(ecs_key_cas_runtime_state, next)
      }
    None => world.insert_resource(ecs_key_cas_runtime_state, next)
  }
}
