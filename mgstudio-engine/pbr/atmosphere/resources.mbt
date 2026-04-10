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
