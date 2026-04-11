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
  app
  .init_resource(fn() { MipGenerationJobs::default() })
  .init_resource(fn() { MipGenerationPipelines::default() })
  .add_plugin(@experimental.experimental_mip_generation_plugin)
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
pub fn MipGenerationPhaseId::value(self : MipGenerationPhaseId) -> Int {
  self.value
}

///|
pub struct MipGenerationPhase {
  image_asset_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn MipGenerationPhase::default() -> MipGenerationPhase {
  MipGenerationPhase::{ image_asset_ids: [] }
}

///|
pub fn MipGenerationPhase::len(self : MipGenerationPhase) -> Int {
  self.image_asset_ids.length()
}

///|
pub fn MipGenerationPhase::is_empty(self : MipGenerationPhase) -> Bool {
  self.image_asset_ids.length() == 0
}

///|
pub fn MipGenerationPhase::to_array(self : MipGenerationPhase) -> Array[Int] {
  self.image_asset_ids.copy()
}

///|
pub fn MipGenerationPhase::push(
  self : MipGenerationPhase,
  image_asset_id : Int,
) -> MipGenerationPhase {
  let next = self.image_asset_ids.copy()
  next.push(image_asset_id)
  MipGenerationPhase::{ image_asset_ids: next }
}

///|
pub struct MipGenerationJobs {
  phases : Map[Int, MipGenerationPhase]
} derive(Eq, Debug)

///|
pub fn MipGenerationJobs::default() -> MipGenerationJobs {
  MipGenerationJobs::{ phases: {} }
}

///|
pub fn MipGenerationJobs::clear(_ : MipGenerationJobs) -> MipGenerationJobs {
  MipGenerationJobs::default()
}

///|
pub fn MipGenerationJobs::phase(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
) -> MipGenerationPhase? {
  self.phases.get(phase.value())
}

///|
pub fn MipGenerationJobs::has_phase(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
) -> Bool {
  self.phases.contains(phase.value())
}

///|
pub fn MipGenerationJobs::add(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
  image_asset_id : Int,
) -> MipGenerationJobs {
  let key = phase.value()
  let phases = self.phases.copy()
  let next_phase = match phases.get(key) {
    Some(existing) => existing.push(image_asset_id)
    None => MipGenerationPhase::default().push(image_asset_id)
  }
  phases.set(key, next_phase)
  MipGenerationJobs::{ phases, }
}

///|
pub fn MipGenerationJobs::remove_phase(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
) -> (MipGenerationJobs, MipGenerationPhase?) {
  let key = phase.value()
  let removed = self.phases.get(key)
  let next = self.phases.copy()
  next.remove(key) |> ignore
  (MipGenerationJobs::{ phases: next }, removed)
}

///|
pub fn MipGenerationJobs::drain_phase(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
) -> (MipGenerationJobs, Array[Int]) {
  let (next_jobs, removed) = self.remove_phase(phase)
  match removed {
    Some(entries) => (next_jobs, entries.to_array())
    None => (next_jobs, [])
  }
}

///|
pub fn MipGenerationJobs::phase_count(self : MipGenerationJobs) -> Int {
  self.phases.length()
}

///|
pub fn MipGenerationJobs::job_count(self : MipGenerationJobs) -> Int {
  let mut total = 0
  for _, phase in self.phases {
    total = total + phase.len()
  }
  total
}

///|
pub let ecs_key_mip_generation_jobs : @ecs.ResourceKey[MipGenerationJobs] = @ecs.register_resource(
  debug_name="core_pipeline.mip_generation.jobs",
)

///|
pub impl @app.Resource for MipGenerationJobs with resource() {
  ecs_key_mip_generation_jobs
}

///|
pub struct MipGenerationPipelines {
  texture_format_pipeline_count : Int
  bind_group_cache_count : Int
} derive(Eq, Debug)

///|
pub fn MipGenerationPipelines::default() -> MipGenerationPipelines {
  MipGenerationPipelines::{
    texture_format_pipeline_count: 0,
    bind_group_cache_count: 0,
  }
}

///|
pub fn MipGenerationPipelines::new(
  texture_format_pipeline_count? : Int = 0,
  bind_group_cache_count? : Int = 0,
) -> MipGenerationPipelines {
  MipGenerationPipelines::{
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
pub fn MipGenerationPipelines::register_texture_format_pipeline(
  self : MipGenerationPipelines,
) -> MipGenerationPipelines {
  MipGenerationPipelines::{
    ..self,
    texture_format_pipeline_count: self.texture_format_pipeline_count + 1,
  }
}

///|
pub fn MipGenerationPipelines::cache_bind_group(
  self : MipGenerationPipelines,
) -> MipGenerationPipelines {
  MipGenerationPipelines::{
    ..self,
    bind_group_cache_count: self.bind_group_cache_count + 1,
  }
}

///|
pub fn MipGenerationPipelines::reset_bind_group_cache(
  self : MipGenerationPipelines,
) -> MipGenerationPipelines {
  MipGenerationPipelines::{ ..self, bind_group_cache_count: 0 }
}

///|
pub fn MipGenerationPipelines::clear(
  _ : MipGenerationPipelines,
) -> MipGenerationPipelines {
  MipGenerationPipelines::default()
}

///|
pub let ecs_key_mip_generation_pipelines : @ecs.ResourceKey[
  MipGenerationPipelines,
] = @ecs.register_resource(debug_name="core_pipeline.mip_generation.pipelines")

///|
pub impl @app.Resource for MipGenerationPipelines with resource() {
  ecs_key_mip_generation_pipelines
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
