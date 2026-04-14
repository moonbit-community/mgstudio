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
const SCREEN_SPACE_AMBIENT_OCCLUSION_PLUGIN_NAME : String = "mgstudio.pbr.ssao.ScreenSpaceAmbientOcclusionPlugin"

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
pub impl @app.PluginReplacement for ScreenSpaceAmbientOcclusionPlugin with plugin_name(
  _self,
) {
  SCREEN_SPACE_AMBIENT_OCCLUSION_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for ScreenSpaceAmbientOcclusionPlugin with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    ssao_plugin_install_with(app, self)
  }
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
let ecs_key_ssao_plugin_state : @ecs.ResourceKey[
  ScreenSpaceAmbientOcclusionPluginState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ScreenSpaceAmbientOcclusionPluginState",
)

///|
pub impl @app.Resource for ScreenSpaceAmbientOcclusionPluginState with resource() {
  ecs_key_ssao_plugin_state
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

///|
pub fn ssao_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ssao_plugin_install_with(app, ScreenSpaceAmbientOcclusionPlugin::default())
}

///|
pub fn ssao_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : ScreenSpaceAmbientOcclusionPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(ecs_key_ssao_plugin_state) {
    app
  } else {
    app.insert_world_resource(
      ecs_key_ssao_plugin_state,
      ScreenSpaceAmbientOcclusionPluginState::default(),
    )
  }
}
