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
