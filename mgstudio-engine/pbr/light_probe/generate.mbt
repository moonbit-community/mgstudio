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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/generate.rs`.

///|
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub struct GeneratorBindGroupLayouts {
  downsampling_first : String
  downsampling_second : String
  radiance : String
  irradiance : String
  copy : String
}

///|
pub fn GeneratorBindGroupLayouts::default() -> GeneratorBindGroupLayouts {
  GeneratorBindGroupLayouts::{
    downsampling_first: "downsampling_first_bind_group_layout",
    downsampling_second: "downsampling_second_bind_group_layout",
    radiance: "radiance_bind_group_layout",
    irradiance: "irradiance_bind_group_layout",
    copy: "copy_bind_group_layout",
  }
}

///|
pub struct GeneratorSamplers {
  linear : String
}

///|
pub fn GeneratorSamplers::default() -> GeneratorSamplers {
  GeneratorSamplers::{ linear: "generator_linear_sampler" }
}

///|
pub struct GeneratorPipelines {
  downsample_first : Int
  downsample_second : Int
  copy : Int
  radiance : Int
  irradiance : Int
}

///|
pub fn GeneratorPipelines::default() -> GeneratorPipelines {
  GeneratorPipelines::{
    downsample_first: -1,
    downsample_second: -1,
    copy: -1,
    radiance: -1,
    irradiance: -1,
  }
}

///|
pub struct DownsamplingConfig {
  combine_bind_group : Bool
}

///|
pub fn DownsamplingConfig::default() -> DownsamplingConfig {
  DownsamplingConfig::{ combine_bind_group: false }
}

///|
pub fn DownsamplingConfig::combine_bind_group_enabled(
  self : DownsamplingConfig,
) -> Bool {
  self.combine_bind_group
}

///|
pub fn pbr_generated_environment_map_light_default() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::default()
}

///|
pub struct EnvironmentMapGenerationPlugin {}

///|
pub fn EnvironmentMapGenerationPlugin::default() -> EnvironmentMapGenerationPlugin {
  EnvironmentMapGenerationPlugin::{  }
}

///|
pub fn pbr_downsampling_config(
  max_storage_textures_per_shader_stage : Int,
  supports_read_write_storage_texture : Bool,
) -> DownsamplingConfig {
  DownsamplingConfig::{
    combine_bind_group: max_storage_textures_per_shader_stage >= 12 &&
    supports_read_write_storage_texture,
  }
}

///|
pub fn pbr_generated_environment_map_light_new() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::new(None, 1.0F)
}

///|
pub fn pbr_generated_environment_map_light_with_intensity(
  light : GeneratedEnvironmentMapLight,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  light.with_intensity(intensity)
}
