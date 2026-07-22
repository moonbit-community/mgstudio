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
#warnings("-unnecessary_annotation")
pub fn MipGenerationPlugin::MipGenerationPlugin() -> MipGenerationPlugin {
  MipGenerationPlugin::{  }
}

///|
pub fn mip_generation_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.add_plugins(MipGenerationPlugin::MipGenerationPlugin())
}

///|
pub impl @app.Plugin for MipGenerationPlugin with fn name(_self) {
  MIP_GENERATION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MipGenerationPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  mip_generation_plugin_install_with(app, self)
}

///|
pub impl @app.Plugin for MipGenerationPlugin with fn finish(self, app) {
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
  let next = app.add_plugins(
    @experimental.ExperimentalMipGeneration::ExperimentalMipGeneration(),
  )
  let downsample_shaders = downsample_shaders_from_world(next.world())
  next.world().insert_resource(ecs_key_downsample_shaders, downsample_shaders)
  @render.with_render_app(next, fn(sub_app) {
    mip_generation_configure_render_sub_app(sub_app, downsample_shaders)
  })
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
        MipGenerationResources(),
      )
    }
    sub_app
  })
}

///|
fn mip_generation_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
  downsample_shaders : DownsampleShaders,
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if !world.resource(ecs_key_downsample_shaders).is_present() {
    world.insert_resource(ecs_key_downsample_shaders, downsample_shaders)
  }
  if !world.resource(ecs_key_mip_generation_jobs).is_present() {
    world.insert_resource(ecs_key_mip_generation_jobs, MipGenerationJobs())
  }
  if !world.resource(ecs_key_mip_generation_pipelines).is_present() {
    world.insert_resource(
      ecs_key_mip_generation_pipelines,
      MipGenerationPipelines(),
    )
  }
  @render.configure_base_render_sets(sub_app)
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_mip_generator_pipelines).in_set(
      @render.render_system_set_prepare_resources,
    ),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(reset_mip_generation_jobs).in_set(
      @render.render_system_set_cleanup,
    ),
  )
}

///|
pub const REQUIRED_STORAGE_TEXTURES : Int = 12

///|
const DOWNSAMPLE_SHADER_PATH : String = "core_pipeline/mip_generation/downsample.wgsl"

///|
const DOWNSAMPLE_DEPTH_SHADER_PATH : String = "core_pipeline/mip_generation/experimental/downsample_depth.wgsl"

///|
pub struct MipGenerationResources {
  sampler_label : String
  mag_filter : String
  min_filter : String
  mipmap_filter : String
  mut sampler : @wgpu.Sampler?
}

///|
pub fn MipGenerationResources::MipGenerationResources() -> MipGenerationResources {
  {
    sampler_label: "mip generation sampler",
    mag_filter: "Linear",
    min_filter: "Linear",
    mipmap_filter: "Nearest",
    sampler: None,
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
fn MipGenerationResources::ensure_sampler(
  self : MipGenerationResources,
  render_device : @renderer.RenderDevice,
) -> @wgpu.Sampler {
  match self.sampler {
    Some(sampler) => sampler
    None => {
      let sampler = render_device
        .wgpu_device()
        .create_sampler_u32(
          @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
          @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
          @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
          @wgpu.FILTER_MODE_LINEAR,
          @wgpu.FILTER_MODE_LINEAR,
          @wgpu.MIPMAP_FILTER_MODE_NEAREST,
        )
      sampler.set_label(self.sampler_label)
      self.sampler = Some(sampler)
      sampler
    }
  }
}

///|
pub let ecs_key_mip_generation_resources : @ecs.ResourceKey[
  MipGenerationResources,
] = @ecs.register_resource(debug_name="core_pipeline.mip_generation.resources")

///|
pub impl @app.Resource for MipGenerationResources with fn resource() {
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
fn downsample_specialized_wgsl_source(identifier : String) -> String {
  @mip_generation_source.downsample_specialized_wgsl_source(identifier)
}

///|
fn downsample_shaders_from_world(world : @ecs.World) -> DownsampleShaders {
  let depth : @asset.Handle[@shader.Shader] = @asset.asset_world_load(
    world,
    DOWNSAMPLE_DEPTH_SHADER_PATH,
  )
  let asset_server = world.get_resource(@asset.AssetServer::resource()).unwrap()
  let general : Map[String, @asset.Handle[@shader.Shader]] = Map([])
  for entry in downsample_texture_formats() {
    let (target_format, identifier) = entry
    let source = downsample_specialized_wgsl_source(identifier)
    let handle = @asset.asset_with_world(world, fn() {
      asset_server.add(
        @shader.Shader::from_wgsl(source, DOWNSAMPLE_SHADER_PATH),
      )
    })
    general.set(target_format, handle)
  }
  DownsampleShaders::new(depth~, general~)
}

///|
pub struct DownsampleShaders {
  depth : @asset.Handle[@shader.Shader]
  general : Map[String, @asset.Handle[@shader.Shader]]
}

///|
pub fn DownsampleShaders::new(
  depth~ : @asset.Handle[@shader.Shader],
  general~ : Map[String, @asset.Handle[@shader.Shader]],
) -> DownsampleShaders {
  { depth, general }
}

///|
pub fn DownsampleShaders::depth(
  self : DownsampleShaders,
) -> @asset.Handle[@shader.Shader] {
  self.depth
}

///|
pub fn DownsampleShaders::general_shader_count(self : DownsampleShaders) -> Int {
  self.general.length()
}

///|
pub fn DownsampleShaders::general_shader(
  self : DownsampleShaders,
  target_format : String,
) -> @asset.Handle[@shader.Shader]? {
  self.general.get(target_format)
}

///|
pub let ecs_key_downsample_shaders : @ecs.ResourceKey[DownsampleShaders] = @ecs.register_resource(
  debug_name="core_pipeline.mip_generation.downsample_shaders",
)

///|
pub impl @app.Resource for DownsampleShaders with fn resource() {
  ecs_key_downsample_shaders
}

///|
pub struct MipGenerationPhaseId {
  value : UInt
} derive(Eq, Debug)

///|
pub fn MipGenerationPhaseId::new(value~ : UInt) -> MipGenerationPhaseId {
  { value, }
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
pub fn MipGenerationPhase::MipGenerationPhase() -> MipGenerationPhase {
  { image_asset_ids: [] }
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
  { image_asset_ids: next }
}

///|
pub struct MipGenerationJobs {
  phases : Map[UInt, MipGenerationPhase]
}

///|
pub fn MipGenerationJobs::MipGenerationJobs() -> MipGenerationJobs {
  { phases: Map([]) }
}

///|
pub fn MipGenerationJobs::clear(_ : MipGenerationJobs) -> MipGenerationJobs {
  MipGenerationJobs()
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
    None => MipGenerationPhase::MipGenerationPhase().push(image_asset_id)
  }
  phases.set(key, next_phase)
  { phases, }
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
  ({ phases: next }, removed)
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
pub impl @app.Resource for MipGenerationJobs with fn resource() {
  ecs_key_mip_generation_jobs
}

///|
fn reset_mip_generation_jobs(world : @ecs.World) -> Unit {
  ignore(
    world
    .resource(ecs_key_mip_generation_jobs)
    .update(fn(_) { MipGenerationJobs() }),
  )
}

///|
pub(all) struct MipGenerationTextureFormatPipelines {
  format_raw : UInt
  bind_group_layout_pass_1 : @wgpu.BindGroupLayout
  bind_group_layout_pass_2 : @wgpu.BindGroupLayout
  pipeline_layout_pass_1 : @wgpu.PipelineLayout
  pipeline_layout_pass_2 : @wgpu.PipelineLayout
  pipeline_pass_1 : @wgpu.ComputePipeline
  pipeline_pass_2 : @wgpu.ComputePipeline
}

///|
pub(all) struct MipGenerationStorageView {
  view : @wgpu.TextureView
  dummy_texture : @wgpu.Texture?
}

///|
pub(all) struct MipGenerationJobBindGroups {
  bind_group_pass_1 : @wgpu.BindGroup
  bind_group_pass_2 : @wgpu.BindGroup
  constants_buffer : @wgpu.Buffer
  input_view_pass_1 : @wgpu.TextureView
  input_view_pass_2 : @wgpu.TextureView
  storage_views_pass_1 : Array[MipGenerationStorageView]
  storage_views_pass_2 : Array[MipGenerationStorageView]
}

///|
pub struct MipGenerationPipelines {
  pipelines : @hashmap.HashMap[UInt, MipGenerationTextureFormatPipelines]
  bind_groups : @hashmap.HashMap[Int, MipGenerationJobBindGroups]
}

///|
pub fn MipGenerationPipelines::MipGenerationPipelines() -> MipGenerationPipelines {
  { pipelines: HashMap([]), bind_groups: HashMap([]) }
}

///|
pub fn MipGenerationPipelines::reset_bind_group_cache(
  self : MipGenerationPipelines,
) -> MipGenerationPipelines {
  for entry in self.bind_groups.to_array() {
    entry.1.release()
  }
  self.bind_groups.clear()
  self
}

///|
pub fn MipGenerationPipelines::clear(
  _ : MipGenerationPipelines,
) -> MipGenerationPipelines {
  MipGenerationPipelines()
}

///|
pub let ecs_key_mip_generation_pipelines : @ecs.ResourceKey[
  MipGenerationPipelines,
] = @ecs.register_resource(debug_name="core_pipeline.mip_generation.pipelines")

///|
pub impl @app.Resource for MipGenerationPipelines with fn resource() {
  ecs_key_mip_generation_pipelines
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
