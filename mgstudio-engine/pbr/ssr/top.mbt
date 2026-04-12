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
// Bevy source: `bevy/crates/bevy_pbr/src/ssr/mod.rs`.

///|
pub const SCREEN_SPACE_REFLECTIONS_PLUGIN_ID : String = "bevy_pbr::ScreenSpaceReflectionsPlugin"

///|
pub type ScreenSpaceReflections = @post_process.ScreenSpaceReflections

///|
pub struct ScreenSpaceReflectionsPlugin {}

///|
pub fn ScreenSpaceReflectionsPlugin::default() -> ScreenSpaceReflectionsPlugin {
  ScreenSpaceReflectionsPlugin::{  }
}

///|
pub struct ScreenSpaceReflectionsPipelineId {
  id : Int
}

///|
pub fn ScreenSpaceReflectionsPipelineId::default() -> ScreenSpaceReflectionsPipelineId {
  ScreenSpaceReflectionsPipelineId::{ id: -1 }
}

///|
pub struct ScreenSpaceReflectionsPipelineKey {
  is_hdr : Bool
  has_environment_maps : Bool
  has_atmosphere : Bool
}

///|
pub fn ScreenSpaceReflectionsPipelineKey::default() -> ScreenSpaceReflectionsPipelineKey {
  ScreenSpaceReflectionsPipelineKey::{
    is_hdr: false,
    has_environment_maps: false,
    has_atmosphere: false,
  }
}

///|
pub struct ScreenSpaceReflectionsPluginState {
  enabled : Bool
  pipeline_id : ScreenSpaceReflectionsPipelineId
}

///|
pub fn ScreenSpaceReflectionsPluginState::default() -> ScreenSpaceReflectionsPluginState {
  ScreenSpaceReflectionsPluginState::{
    enabled: true,
    pipeline_id: ScreenSpaceReflectionsPipelineId::default(),
  }
}

///|
pub struct ScreenSpaceReflectionsUniform {
  min_perceptual_roughness_start : Float
  min_perceptual_roughness_end : Float
  max_perceptual_roughness_start : Float
  max_perceptual_roughness_end : Float
  edge_fadeout_start : Float
  edge_fadeout_end : Float
  thickness : Float
  linear_steps : Int
  linear_march_exponent : Float
  bisection_steps : Int
  use_secant : Bool
}

///|
pub fn ScreenSpaceReflectionsUniform::default() -> ScreenSpaceReflectionsUniform {
  ScreenSpaceReflectionsUniform::{
    min_perceptual_roughness_start: 0.08F,
    min_perceptual_roughness_end: 0.12F,
    max_perceptual_roughness_start: 0.55F,
    max_perceptual_roughness_end: 0.6F,
    edge_fadeout_start: 0.0F,
    edge_fadeout_end: 0.0F,
    thickness: 0.25F,
    linear_steps: 10,
    linear_march_exponent: 1.0F,
    bisection_steps: 5,
    use_secant: true,
  }
}

///|
pub fn pbr_ssr_uniform_with_linear_steps(
  uniform : ScreenSpaceReflectionsUniform,
  linear_steps : Int,
) -> ScreenSpaceReflectionsUniform {
  ScreenSpaceReflectionsUniform::{
    ..uniform,
    linear_steps: if linear_steps <= 0 {
      1
    } else {
      linear_steps
    },
  }
}

///|
pub fn pbr_ssr_uniform_with_bisection_steps(
  uniform : ScreenSpaceReflectionsUniform,
  bisection_steps : Int,
) -> ScreenSpaceReflectionsUniform {
  ScreenSpaceReflectionsUniform::{
    ..uniform,
    bisection_steps: if bisection_steps < 0 {
      0
    } else {
      bisection_steps
    },
  }
}

///|
pub fn pbr_ssr_default() -> ScreenSpaceReflections {
  ScreenSpaceReflections::default()
}
