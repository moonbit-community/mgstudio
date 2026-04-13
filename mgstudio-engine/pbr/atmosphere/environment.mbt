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
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub struct AtmosphereEnvironmentMap {
  environment_map : @asset.Handle[@asset.Image]?
  size : @math.UVec2
}

///|
pub fn AtmosphereEnvironmentMap::default() -> AtmosphereEnvironmentMap {
  AtmosphereEnvironmentMap::{
    environment_map: None,
    size: @math.UVec2::new(512, 512),
  }
}

///|
fn atmosphere_next_power_of_two(value : Int) -> Int {
  if value <= 1 {
    1
  } else {
    let mut out = 1
    while out < value {
      out = out * 2
    }
    out
  }
}

///|
pub fn pbr_validate_atmosphere_environment_map_size(
  size : @math.UVec2,
) -> @math.UVec2 {
  @math.UVec2::new(
    atmosphere_next_power_of_two(if size.x <= 0 { 1 } else { size.x }),
    atmosphere_next_power_of_two(if size.y <= 0 { 1 } else { size.y }),
  )
}

///|
pub fn pbr_atmosphere_environment_map(
  environment_map : @asset.Handle[@asset.Image]?,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMap {
  AtmosphereEnvironmentMap::{
    environment_map,
    size: pbr_validate_atmosphere_environment_map_size(size),
  }
}

///|
pub fn pbr_generated_environment_map_light_from_atmosphere(
  environment_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::new(environment_map, intensity).with_affects_lightmapped_mesh_diffuse(
    affects_lightmapped_mesh_diffuse,
  )
}

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
