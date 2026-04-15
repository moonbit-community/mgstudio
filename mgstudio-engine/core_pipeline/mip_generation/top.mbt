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
const MIP_GENERATION_PLUGIN_NAME : String = "mgstudio.core_pipeline.mip_generation.MipGenerationPlugin"

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
  app.add_plugins(MipGenerationPlugin::default())
}

///|
pub impl @app.Plugin for MipGenerationPlugin with name(_self) {
  MIP_GENERATION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MipGenerationPlugin with build(self, app) {
  register_embedded_wgsl_sources()
  mip_generation_plugin_install_with(app, self)
}

///|
pub impl @app.Plugin for MipGenerationPlugin with finish(self, app) {
  mip_generation_plugin_finish_with(app, self)
}

///|
pub fn mip_generation_plugin_with(
  app : @app.App[@ecs.World],
  plugin : MipGenerationPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugins(plugin)
}

///|
fn mip_generation_plugin_install_with(
  app : @app.App[@ecs.World],
  _plugin : MipGenerationPlugin,
) -> @app.App[@ecs.World] {
  let next = app.add_plugins(@experimental.ExperimentalMipGeneration::default())
  @render.with_render_app(next, mip_generation_configure_render_sub_app)
}

///|
fn mip_generation_plugin_finish_with(
  app : @app.App[@ecs.World],
  _plugin : MipGenerationPlugin,
) -> @app.App[@ecs.World] {
  @render.with_render_app(app, fn(sub_app : @app.SubApp[@ecs.World]) {
    let world = sub_app.world()
    if !world.resource(ecs_key_mip_generation_resources).is_present() {
      world.insert_resource(
        ecs_key_mip_generation_resources,
        MipGenerationResources::default(),
      )
    }
    sub_app
  })
}

///|
fn mip_generation_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if !world.resource(ecs_key_downsample_shaders).is_present() {
    world.insert_resource(
      ecs_key_downsample_shaders,
      DownsampleShaders::default(),
    )
  }
  if !world.resource(ecs_key_mip_generation_jobs).is_present() {
    world.insert_resource(
      ecs_key_mip_generation_jobs,
      MipGenerationJobs::default(),
    )
  }
  if !world.resource(ecs_key_mip_generation_pipelines).is_present() {
    world.insert_resource(
      ecs_key_mip_generation_pipelines,
      MipGenerationPipelines::default(),
    )
  }
  @render.configure_base_render_sets(sub_app).add_systems(
    @render.render_schedule_stage(),
    @app.system(reset_mip_generation_jobs).in_set(
      @render.render_system_set_cleanup,
    ),
  )
}

///|
pub const REQUIRED_STORAGE_TEXTURES : Int = 12

///|
pub struct MipGenerationResources {
  sampler_label : String
  mag_filter : String
  min_filter : String
  mipmap_filter : String
} derive(Eq, Debug)

///|
pub fn MipGenerationResources::default() -> MipGenerationResources {
  MipGenerationResources::{
    sampler_label: "mip generation sampler",
    mag_filter: "Linear",
    min_filter: "Linear",
    mipmap_filter: "Nearest",
  }
}

///|
pub fn MipGenerationResources::sampler_label(
  self : MipGenerationResources,
) -> String {
  self.sampler_label
}

///|
pub fn MipGenerationResources::mag_filter(
  self : MipGenerationResources,
) -> String {
  self.mag_filter
}

///|
pub fn MipGenerationResources::min_filter(
  self : MipGenerationResources,
) -> String {
  self.min_filter
}

///|
pub fn MipGenerationResources::mipmap_filter(
  self : MipGenerationResources,
) -> String {
  self.mipmap_filter
}

///|
pub let ecs_key_mip_generation_resources : @ecs.ResourceKey[
  MipGenerationResources,
] = @ecs.register_resource(debug_name="core_pipeline.mip_generation.resources")

///|
pub impl @app.Resource for MipGenerationResources with resource() {
  ecs_key_mip_generation_resources
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/mip_generation/mod.rs`
// (`TEXTURE_FORMATS`).
pub fn downsample_texture_formats() -> Array[(String, String)] {
  [
    ("Rgba8Unorm", "rgba8unorm"),
    ("Rgba8Snorm", "rgba8snorm"),
    ("Rgba8Uint", "rgba8uint"),
    ("Rgba8Sint", "rgba8sint"),
    ("Rgba16Unorm", "rgba16unorm"),
    ("Rgba16Snorm", "rgba16snorm"),
    ("Rgba16Uint", "rgba16uint"),
    ("Rgba16Sint", "rgba16sint"),
    ("Rgba16Float", "rgba16float"),
    ("Rg8Unorm", "rg8unorm"),
    ("Rg8Snorm", "rg8snorm"),
    ("Rg8Uint", "rg8uint"),
    ("Rg8Sint", "rg8sint"),
    ("Rg16Unorm", "rg16unorm"),
    ("Rg16Snorm", "rg16snorm"),
    ("Rg16Uint", "rg16uint"),
    ("Rg16Sint", "rg16sint"),
    ("Rg16Float", "rg16float"),
    ("R32Uint", "r32uint"),
    ("R32Sint", "r32sint"),
    ("R32Float", "r32float"),
    ("Rg32Uint", "rg32uint"),
    ("Rg32Sint", "rg32sint"),
    ("Rg32Float", "rg32float"),
    ("Rgba32Uint", "rgba32uint"),
    ("Rgba32Sint", "rgba32sint"),
    ("Rgba32Float", "rgba32float"),
    ("Bgra8Unorm", "bgra8unorm"),
    ("R8Unorm", "r8unorm"),
    ("R8Snorm", "r8snorm"),
    ("R8Uint", "r8uint"),
    ("R8Sint", "r8sint"),
    ("R16Unorm", "r16unorm"),
    ("R16Snorm", "r16snorm"),
    ("R16Uint", "r16uint"),
    ("R16Sint", "r16sint"),
    ("R16Float", "r16float"),
    ("Rgb10a2Unorm", "rgb10a2unorm"),
    ("Rgb10a2Uint", "rgb10a2uint"),
    ("Rg11b10Ufloat", "rg11b10ufloat"),
  ]
}

///|
pub struct DownsampleShaders {
  depth_shader_path : String
  general_shader_count : Int
}

///|
pub fn DownsampleShaders::default() -> DownsampleShaders {
  DownsampleShaders::new(
    general_shader_count=downsample_texture_formats().length(),
  )
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
pub fn DownsampleShaders::depth_shader_path(self : DownsampleShaders) -> String {
  self.depth_shader_path
}

///|
pub fn DownsampleShaders::general_shader_count(self : DownsampleShaders) -> Int {
  self.general_shader_count
}

///|
pub let ecs_key_downsample_shaders : @ecs.ResourceKey[DownsampleShaders] = @ecs.register_resource(
  debug_name="core_pipeline.mip_generation.downsample_shaders",
)

///|
pub impl @app.Resource for DownsampleShaders with resource() {
  ecs_key_downsample_shaders
}

///|
pub struct MipGenerationPhaseId {
  value : UInt
} derive(Eq, Debug)

///|
pub fn MipGenerationPhaseId::new(value~ : UInt) -> MipGenerationPhaseId {
  MipGenerationPhaseId::{ value, }
}

///|
pub fn MipGenerationPhaseId::value(self : MipGenerationPhaseId) -> UInt {
  self.value
}

///|
pub struct MipGenerationPhase {
  image_asset_ids : Array[@asset.AssetId[@asset.Image]]
}

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
pub fn MipGenerationPhase::to_array(
  self : MipGenerationPhase,
) -> Array[@asset.AssetId[@asset.Image]] {
  self.image_asset_ids.copy()
}

///|
pub fn MipGenerationPhase::push(
  self : MipGenerationPhase,
  image_asset_id : @asset.AssetId[@asset.Image],
) -> MipGenerationPhase {
  let next = self.image_asset_ids.copy()
  next.push(image_asset_id)
  MipGenerationPhase::{ image_asset_ids: next }
}

///|
pub struct MipGenerationJobs {
  phases : Map[UInt, MipGenerationPhase]
}

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
  image_asset_id : @asset.AssetId[@asset.Image],
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
pub fn MipGenerationJobs::add_handle(
  self : MipGenerationJobs,
  phase : MipGenerationPhaseId,
  image : @asset.Handle[@asset.Image],
) -> MipGenerationJobs {
  self.add(phase, image.asset_id())
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
) -> (MipGenerationJobs, Array[@asset.AssetId[@asset.Image]]) {
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
fn reset_mip_generation_jobs(world : @ecs.World) -> Unit {
  ignore(
    world
    .resource(ecs_key_mip_generation_jobs)
    .update(fn(_) { MipGenerationJobs::default() }),
  )
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
  image_asset_id : @asset.AssetId[@asset.Image]
}

///|
pub fn MipGenerationJob::new(
  phase : MipGenerationPhaseId,
  image_asset_id~ : @asset.AssetId[@asset.Image],
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
