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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/resources.rs`.

///|
pub type AtmosphereMode = @light.AtmosphereMode

///|
pub type AtmosphereSettings = @light.AtmosphereSettings

///|
pub struct GpuAtmosphereSettings {
  transmittance_lut_size : @math.UVec2
  multiscattering_lut_size : @math.UVec2
  sky_view_lut_size : @math.UVec2
  aerial_view_lut_size : (@math.UVec2, Int)
  transmittance_lut_samples : Int
  multiscattering_lut_dirs : Int
  multiscattering_lut_samples : Int
  sky_view_lut_samples : Int
  aerial_view_lut_samples : Int
  aerial_view_lut_max_distance : Float
  scene_units_to_m : Float
  sky_max_samples : Int
  rendering_method : AtmosphereMode
}

///|
pub fn GpuAtmosphereSettings::default() -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::{
    transmittance_lut_size: @math.UVec2::new(256, 128),
    multiscattering_lut_size: @math.UVec2::new(32, 32),
    sky_view_lut_size: @math.UVec2::new(400, 200),
    aerial_view_lut_size: (@math.UVec2::new(32, 32), 32),
    transmittance_lut_samples: 40,
    multiscattering_lut_dirs: 64,
    multiscattering_lut_samples: 20,
    sky_view_lut_samples: 16,
    aerial_view_lut_samples: 10,
    aerial_view_lut_max_distance: 32_000.0F,
    scene_units_to_m: 1.0F,
    sky_max_samples: 16,
    rendering_method: AtmosphereMode::LookupTexture,
  }
}

///|
pub fn pbr_gpu_atmosphere_settings(
  _settings : AtmosphereSettings,
) -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::default()
}

///|
pub fn pbr_gpu_atmosphere_settings_with_runtime(
  scene_units_to_m : Float,
  sky_max_samples : Int,
  rendering_method : AtmosphereMode,
) -> GpuAtmosphereSettings {
  let defaults = GpuAtmosphereSettings::default()
  GpuAtmosphereSettings::{
    ..defaults,
    scene_units_to_m: if scene_units_to_m <= 0.0F {
      defaults.scene_units_to_m
    } else {
      scene_units_to_m
    },
    sky_max_samples: if sky_max_samples <= 0 {
      defaults.sky_max_samples
    } else {
      sky_max_samples
    },
    rendering_method,
  }
}

///|
pub fn pbr_atmosphere_settings_default() -> AtmosphereSettings {
  AtmosphereSettings::default()
}

///|
pub fn pbr_atmosphere_settings_with_scene_units_to_m(
  settings : AtmosphereSettings,
  scene_units_to_m : Float,
) -> AtmosphereSettings {
  settings.with_scene_units_to_m(scene_units_to_m)
}

///|
pub fn pbr_atmosphere_settings_with_sky_max_samples(
  settings : AtmosphereSettings,
  sky_max_samples : Int,
) -> AtmosphereSettings {
  settings.with_sky_max_samples(sky_max_samples)
}

///|
pub fn pbr_atmosphere_settings_with_rendering_method(
  settings : AtmosphereSettings,
  rendering_method : AtmosphereMode,
) -> AtmosphereSettings {
  settings.with_rendering_method(rendering_method)
}
