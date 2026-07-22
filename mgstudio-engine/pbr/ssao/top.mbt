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
#warnings("-unnecessary_annotation")
pub fn ScreenSpaceAmbientOcclusionPlugin::ScreenSpaceAmbientOcclusionPlugin() -> ScreenSpaceAmbientOcclusionPlugin {
  ScreenSpaceAmbientOcclusionPlugin::{  }
}

///|
pub impl @app.Plugin for ScreenSpaceAmbientOcclusionPlugin with fn name(_self) {
  SCREEN_SPACE_AMBIENT_OCCLUSION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScreenSpaceAmbientOcclusionPlugin with fn build(
  self,
  app,
) {
  register_embedded_wgsl_sources()
  ssao_plugin_install_with(app, self)
}

///|
pub struct SsaoPipelineId {
  id : Int
}

///|
pub fn SsaoPipelineId::SsaoPipelineId() -> SsaoPipelineId {
  { id: -1 }
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
pub fn SsaoPipelines::SsaoPipelines() -> SsaoPipelines {
  {
    preprocess_depth_pipeline: SsaoPipelineId(),
    spatial_denoise_pipeline: SsaoPipelineId(),
  }
}

///|
pub struct SsaoPipelineKey {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  temporal_jitter : Bool
}

///|
pub fn SsaoPipelineKey::SsaoPipelineKey() -> SsaoPipelineKey {
  {
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
pub fn ScreenSpaceAmbientOcclusionPluginState::ScreenSpaceAmbientOcclusionPluginState() -> ScreenSpaceAmbientOcclusionPluginState {
  { supported: true, pipelines: SsaoPipelines() }
}

///|
let ecs_key_ssao_plugin_state : @ecs.ResourceKey[
  ScreenSpaceAmbientOcclusionPluginState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ScreenSpaceAmbientOcclusionPluginState",
)

///|
pub impl @app.Resource for ScreenSpaceAmbientOcclusionPluginState with fn resource() {
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
    Custom(slice_count, samples_per_slice_side) =>
      (slice_count, samples_per_slice_side)
  }
}

///|
pub fn ssao_pipeline_key(
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
  temporal_jitter : Bool,
) -> SsaoPipelineKey {
  { quality_level, temporal_jitter }
}

///|
pub fn pbr_ssao_default() -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion()
}

///|
pub struct ScreenSpaceAmbientOcclusionResources {
  preprocessed_depth_texture_id : Int
  ssao_noisy_texture_id : Int
  screen_space_ambient_occlusion_texture_id : Int
  depth_differences_texture_id : Int
  thickness_buffer_id : Int
} derive(Eq, Debug)

///|
pub fn ScreenSpaceAmbientOcclusionResources::ScreenSpaceAmbientOcclusionResources() -> ScreenSpaceAmbientOcclusionResources {
  {
    preprocessed_depth_texture_id: -1,
    ssao_noisy_texture_id: -1,
    screen_space_ambient_occlusion_texture_id: -1,
    depth_differences_texture_id: -1,
    thickness_buffer_id: -1,
  }
}

///|
pub fn ScreenSpaceAmbientOcclusionResources::screen_space_ambient_occlusion_texture_id(
  self : ScreenSpaceAmbientOcclusionResources,
) -> Int {
  self.screen_space_ambient_occlusion_texture_id
}

///|
pub struct SsaoBindGroups {
  common_bind_group_id : Int
  preprocess_depth_bind_group_id : Int
  ssao_bind_group_id : Int
  spatial_denoise_bind_group_id : Int
} derive(Eq, Debug)

///|
pub fn SsaoBindGroups::SsaoBindGroups() -> SsaoBindGroups {
  {
    common_bind_group_id: -1,
    preprocess_depth_bind_group_id: -1,
    ssao_bind_group_id: -1,
    spatial_denoise_bind_group_id: -1,
  }
}

///|
pub const SSAO_HILBERT_WIDTH : Int = 64

///|
pub fn ssao_hilbert_index(x : Int, y : Int) -> Int {
  let mut x = x
  let mut y = y
  let mut index = 0
  let mut level = SSAO_HILBERT_WIDTH / 2
  while level > 0 {
    let region_x = if (x & level) > 0 { 1 } else { 0 }
    let region_y = if (y & level) > 0 { 1 } else { 0 }
    index = index + level * level * ((3 * region_x) ^ region_y)
    if region_y == 0 {
      if region_x == 1 {
        x = SSAO_HILBERT_WIDTH - 1 - x
        y = SSAO_HILBERT_WIDTH - 1 - y
      }
      let old_x = x
      x = y
      y = old_x
    }
    level = level / 2
  }
  index
}

///|
pub fn ssao_generate_hilbert_index_lut() -> Array[Array[Int]] {
  let lut : Array[Array[Int]] = []
  for x in 0..<SSAO_HILBERT_WIDTH {
    let row : Array[Int] = []
    for y in 0..<SSAO_HILBERT_WIDTH {
      row.push(ssao_hilbert_index(x, y))
    }
    lut.push(row)
  }
  lut
}

///|
pub fn ssao_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ssao_plugin_install_with(app, ScreenSpaceAmbientOcclusionPlugin())
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
      ScreenSpaceAmbientOcclusionPluginState(),
    )
  }
}
