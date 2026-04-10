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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/environment.rs`.

///|
pub type AtmosphereEnvironmentMapLight = @light.AtmosphereEnvironmentMapLight

///|
pub fn pbr_atmosphere_environment_map_light_default() -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::default()
}

///|
pub fn pbr_atmosphere_environment_map_light_new(
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::new(
    intensity, affects_lightmapped_mesh_diffuse, size,
  )
}

///|
pub fn pbr_atmosphere_environment_map_light_with_intensity(
  light : AtmosphereEnvironmentMapLight,
  intensity : Float,
) -> AtmosphereEnvironmentMapLight {
  light.with_intensity(intensity)
}
