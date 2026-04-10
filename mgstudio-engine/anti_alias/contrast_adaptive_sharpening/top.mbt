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
pub fn cas_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
