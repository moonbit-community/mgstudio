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
// Bevy source: `bevy/crates/bevy_pbr/src/ssao/mod.rs`.

///|
pub type ScreenSpaceAmbientOcclusionQualityLevel = @post_process.ScreenSpaceAmbientOcclusionQualityLevel

///|
pub type ScreenSpaceAmbientOcclusion = @post_process.ScreenSpaceAmbientOcclusion

///|
pub struct ScreenSpaceAmbientOcclusionPlugin {}

///|
pub fn ScreenSpaceAmbientOcclusionPlugin::default() -> ScreenSpaceAmbientOcclusionPlugin {
  ScreenSpaceAmbientOcclusionPlugin::{  }
}

///|
pub struct SsaoPipelineId {
  id : Int
}

///|
pub fn SsaoPipelineId::default() -> SsaoPipelineId {
  SsaoPipelineId::{ id: -1 }
}

///|
pub fn SsaoPipelineId::is_ready(self : SsaoPipelineId) -> Bool {
  self.id >= 0
}

///|
pub struct SsaoPipelines {
  preprocess_depth_pipeline : SsaoPipelineId
  spatial_denoise_pipeline : SsaoPipelineId
}

///|
pub fn SsaoPipelines::default() -> SsaoPipelines {
  SsaoPipelines::{
    preprocess_depth_pipeline: SsaoPipelineId::default(),
    spatial_denoise_pipeline: SsaoPipelineId::default(),
  }
}

///|
pub struct SsaoPipelineKey {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  temporal_jitter : Bool
}

///|
pub fn SsaoPipelineKey::default() -> SsaoPipelineKey {
  SsaoPipelineKey::{
    quality_level: ScreenSpaceAmbientOcclusionQualityLevel::default(),
    temporal_jitter: false,
  }
}

///|
pub struct ScreenSpaceAmbientOcclusionPluginState {
  supported : Bool
  pipelines : SsaoPipelines
}

///|
pub fn ScreenSpaceAmbientOcclusionPluginState::default() -> ScreenSpaceAmbientOcclusionPluginState {
  ScreenSpaceAmbientOcclusionPluginState::{
    supported: true,
    pipelines: SsaoPipelines::default(),
  }
}

///|
pub fn ssao_quality_sample_counts(
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
) -> (Int, Int) {
  match quality_level {
    Low => (1, 2)
    Medium => (2, 2)
    High => (3, 3)
    Ultra => (9, 3)
  }
}

///|
pub fn ssao_pipeline_key(
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
  temporal_jitter : Bool,
) -> SsaoPipelineKey {
  SsaoPipelineKey::{ quality_level, temporal_jitter }
}

///|
pub fn pbr_ssao_default() -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::default()
}
