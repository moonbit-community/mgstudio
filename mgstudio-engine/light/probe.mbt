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
// Bevy source: `bevy/crates/bevy_light/src/probe.rs`.

///|
pub type LightProbeComponent = LightProbe

///|
pub type EnvironmentMapLightComponent = EnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLightComponent = GeneratedEnvironmentMapLight

///|
pub type IrradianceVolumeComponent = IrradianceVolume

///|
pub type ParallaxCorrectionComponent = ParallaxCorrection

///|
pub let ecs_key_light_probe_component : @ecs.ComponentKey[LightProbeComponent] = ecs_key_light_probe

///|
pub let ecs_key_environment_map_light_component : @ecs.ComponentKey[
  EnvironmentMapLightComponent,
] = ecs_key_environment_map_light

///|
pub let ecs_key_generated_environment_map_light_component : @ecs.ComponentKey[
  GeneratedEnvironmentMapLightComponent,
] = ecs_key_generated_environment_map_light

///|
pub let ecs_key_irradiance_volume_component : @ecs.ComponentKey[
  IrradianceVolumeComponent,
] = ecs_key_irradiance_volume

///|
pub let ecs_key_parallax_correction_component : @ecs.ComponentKey[
  ParallaxCorrectionComponent,
] = ecs_key_parallax_correction
