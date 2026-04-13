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
// Bevy source: `bevy/crates/bevy_post_process/src/bloom/settings.rs`.
// Host-side uniform packing for the stable root bloom runtime.

///|
pub struct BloomSettingsUniform {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  threshold : Float
  threshold_softness : Float
  composite_mode_additive : Bool
  max_mip_dimension : Int
  scale_x : Float
  scale_y : Float
} derive(ToJson, FromJson)

///|
pub fn BloomSettingsUniform::from_settings(
  settings : Bloom,
) -> BloomSettingsUniform {
  BloomSettingsUniform::{
    intensity: settings.intensity,
    low_frequency_boost: settings.low_frequency_boost,
    low_frequency_boost_curvature: settings.low_frequency_boost_curvature,
    high_pass_frequency: settings.high_pass_frequency,
    threshold: settings.prefilter.threshold,
    threshold_softness: settings.prefilter.threshold_softness,
    composite_mode_additive: settings.composite_mode ==
    BloomCompositeMode::Additive,
    max_mip_dimension: settings.max_mip_dimension,
    scale_x: settings.scale.x,
    scale_y: settings.scale.y,
  }
}

///|
pub fn bloom_is_anamorphic(settings : Bloom) -> Bool {
  settings.scale.x > settings.scale.y
}
