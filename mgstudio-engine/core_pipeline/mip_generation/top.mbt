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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/mip_generation/mod.rs`.
// Mip-generation plugin owner surface.

///|
pub const MIP_GENERATION_PLUGIN_ID : String = "bevy_core_pipeline::mip_generation::MipGenerationPlugin"

///|
pub struct MipGenerationPlugin {}

///|
pub fn MipGenerationPlugin::default() -> MipGenerationPlugin {
  MipGenerationPlugin::{  }
}

///|
pub fn mip_generation_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  mip_generation_plugin_with(app, MipGenerationPlugin::default())
}

///|
pub impl @app.PluginReplacement for MipGenerationPlugin with replacement_id(
  _self,
) {
  MIP_GENERATION_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for MipGenerationPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    mip_generation_plugin_with(app, self)
  }
}

///|
pub fn mip_generation_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : MipGenerationPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugin(@experimental.experimental_mip_generation_plugin)
}

///|
pub const REQUIRED_STORAGE_TEXTURES : Int = 12

///|
pub struct DownsampleShaders {
  depth_shader_path : String
  general_shader_count : Int
}

///|
pub fn DownsampleShaders::new(
  depth_shader_path? : String = "core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
  general_shader_count? : Int = 0,
) -> DownsampleShaders {
  let general_shader_count = if general_shader_count < 0 {
    0
  } else {
    general_shader_count
  }
  DownsampleShaders::{ depth_shader_path, general_shader_count }
}

///|
pub struct MipGenerationPhaseId {
  value : Int
} derive(Eq, Debug)

///|
pub fn MipGenerationPhaseId::new(value~ : Int) -> MipGenerationPhaseId {
  MipGenerationPhaseId::{ value, }
}

///|
pub struct MipGenerationJob {
  phase : MipGenerationPhaseId
  image_asset_id : Int
}

///|
pub fn MipGenerationJob::new(
  phase : MipGenerationPhaseId,
  image_asset_id~ : Int,
) -> MipGenerationJob {
  MipGenerationJob::{ phase, image_asset_id }
}

///|
pub struct MipGenerationPipelinesState {
  texture_format_pipeline_count : Int
  bind_group_cache_count : Int
}

///|
pub fn MipGenerationPipelinesState::new(
  texture_format_pipeline_count? : Int = 0,
  bind_group_cache_count? : Int = 0,
) -> MipGenerationPipelinesState {
  MipGenerationPipelinesState::{
    texture_format_pipeline_count: if texture_format_pipeline_count < 0 {
      0
    } else {
      texture_format_pipeline_count
    },
    bind_group_cache_count: if bind_group_cache_count < 0 {
      0
    } else {
      bind_group_cache_count
    },
  }
}

///|
pub fn mip_generation_supports_downsample(
  max_storage_textures_per_shader_stage : Int,
) -> Bool {
  max_storage_textures_per_shader_stage >= REQUIRED_STORAGE_TEXTURES
}

///|
pub fn mip_generation_job_should_run(
  image_mip_level_count : Int,
  max_storage_textures_per_shader_stage : Int,
) -> Bool {
  image_mip_level_count > 1 &&
  mip_generation_supports_downsample(max_storage_textures_per_shader_stage)
}
