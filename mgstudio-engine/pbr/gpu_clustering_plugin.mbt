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
// Bevy source: `bevy/crates/bevy_pbr/src/cluster/gpu.rs`.

///|
pub const GPU_CLUSTERING_ALLOCATION_WORKGROUP_SIZE : Int = 256

///|
pub const GPU_CLUSTERING_Z_SLICING_WORKGROUP_SIZE : Int = 64

///|
pub const GPU_CLUSTERING_CLUSTER_METADATA_SIZE_BYTES : UInt64 = 48UL

///|
const GPU_CLUSTERING_PLUGIN_NAME : String = "mgstudio.pbr.GpuClusteringPlugin"

///|
pub(all) enum GpuClusteringStep {
  ZSlicing
  CountRasterization
  LocalAllocation
  GlobalAllocation
  PopulateRasterization
} derive(Eq, Debug)

///|
pub struct ClusteringRasterPipelineKey {
  populate_pass : Bool
} derive(Eq, Debug)

///|
pub fn ClusteringRasterPipelineKey::count_pass() -> ClusteringRasterPipelineKey {
  ClusteringRasterPipelineKey::{ populate_pass: false }
}

///|
pub fn ClusteringRasterPipelineKey::new_populate_pass() -> ClusteringRasterPipelineKey {
  ClusteringRasterPipelineKey::{ populate_pass: true }
}

///|
pub fn ClusteringRasterPipelineKey::populate_pass(
  self : ClusteringRasterPipelineKey,
) -> Bool {
  self.populate_pass
}

///|
pub struct ClusteringAllocationPipelineKey {
  global_pass : Bool
} derive(Eq, Debug)

///|
pub fn ClusteringAllocationPipelineKey::local_pass() -> ClusteringAllocationPipelineKey {
  ClusteringAllocationPipelineKey::{ global_pass: false }
}

///|
pub fn ClusteringAllocationPipelineKey::new_global_pass() -> ClusteringAllocationPipelineKey {
  ClusteringAllocationPipelineKey::{ global_pass: true }
}

///|
pub fn ClusteringAllocationPipelineKey::global_pass(
  self : ClusteringAllocationPipelineKey,
) -> Bool {
  self.global_pass
}

///|
pub struct ClusteringRasterPipeline {
  bind_group_layout_count_pass : @render_resource.BindGroupLayoutDescriptor
  bind_group_layout_populate_pass : @render_resource.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct ClusteringZSlicingPipeline {
  bind_group_layout : @render_resource.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct ClusteringAllocationPipeline {
  bind_group_layout : @render_resource.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct SpecializedClusteringRasterPipelines {
  entries : Array[
    (ClusteringRasterPipelineKey, @render_resource.CachedRenderPipelineId),
  ]
}

///|
pub struct SpecializedClusteringZSlicingPipelines {
  entries : Array[@render_resource.CachedComputePipelineId]
}

///|
pub struct SpecializedClusteringAllocationPipelines {
  entries : Array[
    (ClusteringAllocationPipelineKey, @render_resource.CachedComputePipelineId),
  ]
}

///|
pub struct ViewClusteringLastFrameStatistics {
  index_list_size : UInt
  farthest_z : Float
} derive(Eq, Debug)

///|
pub struct ViewClusteringReadbackData {
  mut z_slice_list_capacity : Int
  mut max_index_list_capacity : Int
  metadata_staging_pending_buffers : Array[@wgpu.Buffer]
  metadata_staging_free_buffers : Array[@wgpu.Buffer]
  mut last_frame_statistics : ViewClusteringLastFrameStatistics?
}

///|
pub struct ClusterableObjectZSlice {
  object_index : UInt
  object_type : UInt
  z_slice : UInt
} derive(Eq, Debug)

///|
pub struct ClusterRasterIndirectDrawParams {
  index_count : UInt
  instance_count : UInt
  first_index : UInt
  base_vertex : UInt
  first_instance : UInt
} derive(Eq, Debug)

///|
pub struct ClusterMetadata {
  indirect_draw_params : ClusterRasterIndirectDrawParams
  clustered_light_count : UInt
  reflection_probe_count : UInt
  irradiance_volume_count : UInt
  decal_count : UInt
  z_slice_list_capacity : UInt
  index_list_capacity : UInt
  farthest_z : UInt
} derive(Eq, Debug)

///|
pub struct RenderViewClusteringReadbackData {
  views : Map[UInt64, ViewClusteringReadbackData]
}

///|
pub struct GpuClusteringReadbackRequest {
  view_clustering_readback_data : ViewClusteringReadbackData
  staging_buffer : @wgpu.Buffer
}

///|
pub struct ViewGpuClusteringBuffers {
  z_slices_buffer : @render_resource.StorageBuffer[ClusterableObjectZSlice]
  scratchpad_offsets_and_counts_buffer : @render_resource.StorageBuffer[
    GpuClusterOffsetAndCounts,
  ]
  cluster_metadata_buffer : @render_resource.StorageBuffer[ClusterMetadata]
  mut z_slices_gpu_buffer : @wgpu.Buffer?
  mut z_slices_gpu_capacity : UInt64
  mut scratchpad_offsets_and_counts_gpu_buffer : @wgpu.Buffer?
  mut scratchpad_offsets_and_counts_gpu_capacity : UInt64
  mut cluster_metadata_gpu_buffer : @wgpu.Buffer?
  mut cluster_metadata_gpu_capacity : UInt64
}

///|
pub struct GpuClusteringMeshBuffers {
  vertex_buffer : @wgpu.Buffer
  index_buffer : @wgpu.Buffer
}

///|
pub struct ViewClusteringDummyTexture {
  texture : @render_texture.CachedTexture
}

///|
pub struct ViewClusteringBindGroups {
  clustering_bind_group_z_slicing_pass : @wgpu.BindGroup
  clustering_bind_group_count_pass : @wgpu.BindGroup
  clustering_bind_group_allocate_pass : @wgpu.BindGroup
  clustering_bind_group_populate_pass : @wgpu.BindGroup
}

///|
pub struct ViewGpuClusteringPipelineIds {
  clustering_z_slicing_pipeline_id : @render_resource.CachedComputePipelineId
  clustering_count_pipeline_id : @render_resource.CachedRenderPipelineId
  clustering_allocation_local_pipeline_id : @render_resource.CachedComputePipelineId
  clustering_allocation_global_pipeline_id : @render_resource.CachedComputePipelineId
  clustering_populate_pipeline_id : @render_resource.CachedRenderPipelineId
}

///|
pub struct GpuClusteringPlugin {}

///|
pub fn GpuClusteringPlugin::GpuClusteringPlugin() -> GpuClusteringPlugin {
  GpuClusteringPlugin::{  }
}

///|
pub struct GpuClusteringPluginState {
  enabled : Bool
  max_storage_buffers_per_shader_stage : Int
} derive(Eq, Debug)

///|
pub fn GpuClusteringPluginState::new(
  max_storage_buffers_per_shader_stage : Int,
) -> GpuClusteringPluginState {
  GpuClusteringPluginState::{
    enabled: max_storage_buffers_per_shader_stage > 0,
    max_storage_buffers_per_shader_stage,
  }
}

///|
pub fn GpuClusteringPluginState::enabled(
  self : GpuClusteringPluginState,
) -> Bool {
  self.enabled
}

///|
pub fn GpuClusteringPluginState::max_storage_buffers_per_shader_stage(
  self : GpuClusteringPluginState,
) -> Int {
  self.max_storage_buffers_per_shader_stage
}

///|
let ecs_key_clustering_raster_pipeline : @ecs.ResourceKey[
  ClusteringRasterPipeline,
] = @ecs.register_resource(debug_name="mgstudio_pbr::ClusteringRasterPipeline")

///|
pub impl @app.Resource for ClusteringRasterPipeline with fn resource() {
  ecs_key_clustering_raster_pipeline
}

///|
let ecs_key_clustering_z_slicing_pipeline : @ecs.ResourceKey[
  ClusteringZSlicingPipeline,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ClusteringZSlicingPipeline",
)

///|
pub impl @app.Resource for ClusteringZSlicingPipeline with fn resource() {
  ecs_key_clustering_z_slicing_pipeline
}

///|
let ecs_key_clustering_allocation_pipeline : @ecs.ResourceKey[
  ClusteringAllocationPipeline,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ClusteringAllocationPipeline",
)

///|
pub impl @app.Resource for ClusteringAllocationPipeline with fn resource() {
  ecs_key_clustering_allocation_pipeline
}

///|
let ecs_key_specialized_clustering_raster_pipelines : @ecs.ResourceKey[
  SpecializedClusteringRasterPipelines,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedRenderPipelines<ClusteringRasterPipeline>",
)

///|
pub impl @app.Resource for SpecializedClusteringRasterPipelines with fn resource() {
  ecs_key_specialized_clustering_raster_pipelines
}

///|
let ecs_key_specialized_clustering_z_slicing_pipelines : @ecs.ResourceKey[
  SpecializedClusteringZSlicingPipelines,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedComputePipelines<ClusteringZSlicingPipeline>",
)

///|
pub impl @app.Resource for SpecializedClusteringZSlicingPipelines with fn resource() {
  ecs_key_specialized_clustering_z_slicing_pipelines
}

///|
let ecs_key_specialized_clustering_allocation_pipelines : @ecs.ResourceKey[
  SpecializedClusteringAllocationPipelines,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedComputePipelines<ClusteringAllocationPipeline>",
)

///|
pub impl @app.Resource for SpecializedClusteringAllocationPipelines with fn resource() {
  ecs_key_specialized_clustering_allocation_pipelines
}

///|
let ecs_key_render_view_clustering_readback_data : @ecs.ResourceKey[
  RenderViewClusteringReadbackData,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderViewClusteringReadbackData",
)

///|
pub impl @app.Resource for RenderViewClusteringReadbackData with fn resource() {
  ecs_key_render_view_clustering_readback_data
}

///|
let ecs_key_gpu_clustering_mesh_buffers : @ecs.ResourceKey[
  GpuClusteringMeshBuffers,
] = @ecs.register_resource(debug_name="mgstudio_pbr::GpuClusteringMeshBuffers")

///|
pub impl @app.Resource for GpuClusteringMeshBuffers with fn resource() {
  ecs_key_gpu_clustering_mesh_buffers
}

///|
pub let ecs_key_view_clustering_dummy_texture : @ecs.ComponentKey[
  ViewClusteringDummyTexture,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewClusteringDummyTexture",
)

///|
pub let ecs_key_view_gpu_clustering_buffers : @ecs.ComponentKey[
  ViewGpuClusteringBuffers,
] = @ecs.register_component(debug_name="mgstudio_pbr::ViewGpuClusteringBuffers")

///|
pub impl @ecs.Component for ViewClusteringDummyTexture with fn component() {
  ecs_key_view_clustering_dummy_texture
}

///|
pub impl @ecs.Component for ViewGpuClusteringBuffers with fn component() {
  ecs_key_view_gpu_clustering_buffers
}

///|
pub let ecs_key_view_clustering_bind_groups : @ecs.ComponentKey[
  ViewClusteringBindGroups,
] = @ecs.register_component(debug_name="mgstudio_pbr::ViewClusteringBindGroups")

///|
pub impl @ecs.Component for ViewClusteringBindGroups with fn component() {
  ecs_key_view_clustering_bind_groups
}

///|
pub let ecs_key_view_gpu_clustering_pipeline_ids : @ecs.ComponentKey[
  ViewGpuClusteringPipelineIds,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewGpuClusteringPipelineIds",
)

///|
pub impl @ecs.Component for ViewGpuClusteringPipelineIds with fn component() {
  ecs_key_view_gpu_clustering_pipeline_ids
}

///|
pub fn gpu_clustering_pipeline_steps() -> Array[GpuClusteringStep] {
  [
    ZSlicing,
    CountRasterization,
    LocalAllocation,
    GlobalAllocation,
    PopulateRasterization,
  ]
}

///|
pub fn gpu_clustering_z_slice_dispatch_count(
  clusterable_object_count : Int,
) -> Int {
  gpu_clustering_div_ceil(
    clusterable_object_count,
    GPU_CLUSTERING_Z_SLICING_WORKGROUP_SIZE,
  )
}

///|
pub fn gpu_clustering_allocation_dispatch_count(cluster_count : Int) -> Int {
  gpu_clustering_div_ceil(
    cluster_count,
    GPU_CLUSTERING_ALLOCATION_WORKGROUP_SIZE,
  )
}

///|
fn gpu_clustering_clusterable_object_count(metadata : ClusterMetadata) -> UInt {
  metadata.clustered_light_count() +
  metadata.reflection_probe_count() +
  metadata.irradiance_volume_count() +
  metadata.decal_count()
}

///|
fn gpu_clustering_allocation_pass_workgroup_count(
  extracted_cluster_config : ExtractedClusterConfig,
  global_pass : Bool,
) -> UInt {
  if global_pass {
    1U
  } else {
    let dimensions = extracted_cluster_config.dimensions()
    gpu_clustering_allocation_dispatch_count(
      dimensions.0 * dimensions.1 * dimensions.2,
    ).reinterpret_as_uint()
  }
}

///|
fn gpu_clustering_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("gpu clustering divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}

///|
fn gpu_clustering_storage(read_only : Bool) -> @render_resource.BindingType {
  @render_resource.BindingType::BufferBinding(
    @render_resource.BufferBindingType::Storage(read_only),
    false,
    0UL,
  )
}

///|
fn gpu_clustering_uniform_dynamic() -> @render_resource.BindingType {
  @render_resource.BindingType::BufferBinding(
    @render_resource.BufferBindingType::Uniform,
    true,
    0UL,
  )
}

///|
fn gpu_clustering_layout_entry(
  binding : Int,
  visibility : UInt,
  kind : @render_resource.BindingType,
) -> @render_resource.BindGroupLayoutEntry {
  @render_resource.BindGroupLayoutEntry::new(binding, visibility, kind)
}

///|
fn gpu_clustering_vertex_fragment_stage() -> UInt {
  (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
}

///|
fn gpu_clustering_fragment_stage() -> UInt {
  @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
}

///|
fn gpu_clustering_compute_stage() -> UInt {
  @wgpu.SHADER_STAGE_COMPUTE.to_uint()
}

///|
pub fn ClusteringRasterPipeline::ClusteringRasterPipeline() -> ClusteringRasterPipeline {
  let vertex_fragment = gpu_clustering_vertex_fragment_stage()
  let fragment = gpu_clustering_fragment_stage()
  let count_entries = [
    gpu_clustering_layout_entry(
      0,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(1, fragment, gpu_clustering_storage(false)),
    gpu_clustering_layout_entry(
      2,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(
      3,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(
      4,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(
      5,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(
      6,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(7, fragment, gpu_clustering_storage(false)),
  ]
  let populate_entries = [
    gpu_clustering_layout_entry(
      0,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(1, fragment, gpu_clustering_storage(false)),
    gpu_clustering_layout_entry(
      2,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(
      3,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(
      4,
      vertex_fragment,
      gpu_clustering_storage(true),
    ),
    gpu_clustering_layout_entry(
      5,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(
      6,
      vertex_fragment,
      gpu_clustering_uniform_dynamic(),
    ),
    gpu_clustering_layout_entry(7, fragment, gpu_clustering_storage(true)),
    gpu_clustering_layout_entry(8, fragment, gpu_clustering_storage(false)),
  ]
  ClusteringRasterPipeline::{
    bind_group_layout_count_pass: @render_resource.BindGroupLayoutDescriptor::new(
      "clustering count pass bind group layout", count_entries,
    ),
    bind_group_layout_populate_pass: @render_resource.BindGroupLayoutDescriptor::new(
      "clustering populate pass bind group layout", populate_entries,
    ),
    shader: "pbr/cluster/cluster_raster.wgsl",
  }
}

///|
pub fn ClusteringRasterPipeline::count_pass_layout(
  self : ClusteringRasterPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.bind_group_layout_count_pass
}

///|
pub fn ClusteringRasterPipeline::populate_pass_layout(
  self : ClusteringRasterPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.bind_group_layout_populate_pass
}

///|
pub fn ClusteringRasterPipeline::shader(
  self : ClusteringRasterPipeline,
) -> String {
  self.shader
}

///|
pub fn ClusteringZSlicingPipeline::ClusteringZSlicingPipeline() -> ClusteringZSlicingPipeline {
  let compute = gpu_clustering_compute_stage()
  ClusteringZSlicingPipeline::{
    bind_group_layout: @render_resource.BindGroupLayoutDescriptor::new(
      "clustering Z slicing pass bind group layout",
      [
        gpu_clustering_layout_entry(0, compute, gpu_clustering_storage(false)),
        gpu_clustering_layout_entry(1, compute, gpu_clustering_storage(false)),
        gpu_clustering_layout_entry(2, compute, gpu_clustering_storage(true)),
        gpu_clustering_layout_entry(
          3,
          compute,
          gpu_clustering_uniform_dynamic(),
        ),
        gpu_clustering_layout_entry(4, compute, gpu_clustering_storage(true)),
        gpu_clustering_layout_entry(
          5,
          compute,
          gpu_clustering_uniform_dynamic(),
        ),
        gpu_clustering_layout_entry(
          6,
          compute,
          gpu_clustering_uniform_dynamic(),
        ),
      ],
    ),
    shader: "pbr/cluster/cluster_z_slice.wgsl",
  }
}

///|
pub fn ClusteringZSlicingPipeline::layout(
  self : ClusteringZSlicingPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.bind_group_layout
}

///|
pub fn ClusteringZSlicingPipeline::shader(
  self : ClusteringZSlicingPipeline,
) -> String {
  self.shader
}

///|
pub fn ClusteringAllocationPipeline::ClusteringAllocationPipeline() -> ClusteringAllocationPipeline {
  let compute = gpu_clustering_compute_stage()
  ClusteringAllocationPipeline::{
    bind_group_layout: @render_resource.BindGroupLayoutDescriptor::new(
      "clustering allocation pass bind group layout",
      [
        gpu_clustering_layout_entry(0, compute, gpu_clustering_storage(false)),
        gpu_clustering_layout_entry(
          1,
          compute,
          gpu_clustering_uniform_dynamic(),
        ),
        gpu_clustering_layout_entry(2, compute, gpu_clustering_storage(false)),
        gpu_clustering_layout_entry(3, compute, gpu_clustering_storage(false)),
      ],
    ),
    shader: "pbr/cluster/cluster_allocate.wgsl",
  }
}

///|
pub fn ClusteringAllocationPipeline::layout(
  self : ClusteringAllocationPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.bind_group_layout
}

///|
pub fn ClusteringAllocationPipeline::shader(
  self : ClusteringAllocationPipeline,
) -> String {
  self.shader
}

///|
pub fn ClusteringRasterPipeline::specialize(
  self : ClusteringRasterPipeline,
  key : ClusteringRasterPipelineKey,
) -> @render_resource.RenderPipelineDescriptor {
  let pass_def = if key.populate_pass { "POPULATE_PASS" } else { "COUNT_PASS" }
  let vertex_defs = [
    @render_resource.ShaderDefVal::Flag(pass_def),
    @render_resource.ShaderDefVal::Flag("VERTEX_SHADER"),
  ]
  let fragment_defs = [@render_resource.ShaderDefVal::Flag(pass_def)]
  let layout = if key.populate_pass {
    self.bind_group_layout_populate_pass
  } else {
    self.bind_group_layout_count_pass
  }
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(
    Some(
      if key.populate_pass {
        "clustering populate pipeline"
      } else {
        "clustering count pipeline"
      },
    ),
  )
  .with_layout([layout])
  .with_vertex(
    @render_resource.VertexState::new(
      Some(self.shader),
      vertex_defs,
      Some("vertex_main"),
      [
        @mesh.VertexBufferLayout::new(
          array_stride=8,
          step_mode=@mesh.MeshVertexStepMode::Vertex,
          attributes=[
            @mesh.VertexAttribute::new(
              offset=0,
              format=@mesh.MeshVertexFormat::Float32x2,
              shader_location=0,
            ),
          ],
        ),
      ],
    ),
  )
  .with_fragment(
    Some(
      @render_resource.FragmentState::new(
        Some(self.shader),
        fragment_defs,
        Some("fragment_main"),
        [
          Some(
            @render_resource.ColorTargetState::new(
              @wgpu.TEXTURE_FORMAT_R8_UNORM,
              0UL,
            ),
          ),
        ],
      ),
    ),
  )
}

///|
pub fn ClusteringZSlicingPipeline::specialize(
  self : ClusteringZSlicingPipeline,
) -> @render_resource.ComputePipelineDescriptor {
  @render_resource.ComputePipelineDescriptor::ComputePipelineDescriptor()
  .with_label(Some("clustering Z slicing pipeline"))
  .with_layout([self.bind_group_layout])
  .with_shader(Some(self.shader))
  .with_entry_point(Some("z_slice_main"))
}

///|
pub fn ClusteringAllocationPipeline::specialize(
  self : ClusteringAllocationPipeline,
  key : ClusteringAllocationPipelineKey,
) -> @render_resource.ComputePipelineDescriptor {
  @render_resource.ComputePipelineDescriptor::ComputePipelineDescriptor()
  .with_label(
    Some(
      if key.global_pass {
        "clustering allocation global pass pipeline"
      } else {
        "clustering allocation local pass pipeline"
      },
    ),
  )
  .with_layout([self.bind_group_layout])
  .with_shader(Some(self.shader))
  .with_entry_point(
    Some(
      if key.global_pass {
        "allocate_global_main"
      } else {
        "allocate_local_main"
      },
    ),
  )
}

///|
pub fn SpecializedClusteringRasterPipelines::SpecializedClusteringRasterPipelines() -> SpecializedClusteringRasterPipelines {
  SpecializedClusteringRasterPipelines::{ entries: [] }
}

///|
pub fn SpecializedClusteringRasterPipelines::len(
  self : SpecializedClusteringRasterPipelines,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedClusteringRasterPipelines::queue(
  self : SpecializedClusteringRasterPipelines,
  pipeline_cache : @render_resource.PipelineCache,
  pipeline : ClusteringRasterPipeline,
  key : ClusteringRasterPipelineKey,
) -> @render_resource.CachedRenderPipelineId {
  for entry in self.entries {
    let (entry_key, pipeline_id) = entry
    if entry_key == key {
      return pipeline_id
    }
  }
  let pipeline_id = pipeline_cache.queue_render_pipeline(
    pipeline.specialize(key),
  )
  self.entries.push((key, pipeline_id))
  pipeline_id
}

///|
pub fn SpecializedClusteringZSlicingPipelines::SpecializedClusteringZSlicingPipelines() -> SpecializedClusteringZSlicingPipelines {
  SpecializedClusteringZSlicingPipelines::{ entries: [] }
}

///|
pub fn SpecializedClusteringZSlicingPipelines::len(
  self : SpecializedClusteringZSlicingPipelines,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedClusteringZSlicingPipelines::queue(
  self : SpecializedClusteringZSlicingPipelines,
  pipeline_cache : @render_resource.PipelineCache,
  pipeline : ClusteringZSlicingPipeline,
) -> @render_resource.CachedComputePipelineId {
  if self.entries.length() > 0 {
    return self.entries[0]
  }
  let pipeline_id = pipeline_cache.queue_compute_pipeline(pipeline.specialize())
  self.entries.push(pipeline_id)
  pipeline_id
}

///|
pub fn SpecializedClusteringAllocationPipelines::SpecializedClusteringAllocationPipelines() -> SpecializedClusteringAllocationPipelines {
  SpecializedClusteringAllocationPipelines::{ entries: [] }
}

///|
pub fn SpecializedClusteringAllocationPipelines::len(
  self : SpecializedClusteringAllocationPipelines,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedClusteringAllocationPipelines::queue(
  self : SpecializedClusteringAllocationPipelines,
  pipeline_cache : @render_resource.PipelineCache,
  pipeline : ClusteringAllocationPipeline,
  key : ClusteringAllocationPipelineKey,
) -> @render_resource.CachedComputePipelineId {
  for entry in self.entries {
    let (entry_key, pipeline_id) = entry
    if entry_key == key {
      return pipeline_id
    }
  }
  let pipeline_id = pipeline_cache.queue_compute_pipeline(
    pipeline.specialize(key),
  )
  self.entries.push((key, pipeline_id))
  pipeline_id
}

///|
pub fn ClusterableObjectZSlice::ClusterableObjectZSlice() -> ClusterableObjectZSlice {
  ClusterableObjectZSlice::{ object_index: 0U, object_type: 0U, z_slice: 0U }
}

///|
pub fn ClusterRasterIndirectDrawParams::ClusterRasterIndirectDrawParams() -> ClusterRasterIndirectDrawParams {
  ClusterRasterIndirectDrawParams::{
    index_count: 0U,
    instance_count: 0U,
    first_index: 0U,
    base_vertex: 0U,
    first_instance: 0U,
  }
}

///|
pub fn ClusterRasterIndirectDrawParams::new(
  index_count : UInt,
  instance_count : UInt,
  first_index : UInt,
  base_vertex : UInt,
  first_instance : UInt,
) -> ClusterRasterIndirectDrawParams {
  ClusterRasterIndirectDrawParams::{
    index_count,
    instance_count,
    first_index,
    base_vertex,
    first_instance,
  }
}

///|
pub fn ClusterRasterIndirectDrawParams::instance_count(
  self : ClusterRasterIndirectDrawParams,
) -> UInt {
  self.instance_count
}

///|
pub fn ClusterRasterIndirectDrawParams::index_count(
  self : ClusterRasterIndirectDrawParams,
) -> UInt {
  self.index_count
}

///|
pub fn ClusterRasterIndirectDrawParams::first_index(
  self : ClusterRasterIndirectDrawParams,
) -> UInt {
  self.first_index
}

///|
pub fn ClusterRasterIndirectDrawParams::base_vertex(
  self : ClusterRasterIndirectDrawParams,
) -> UInt {
  self.base_vertex
}

///|
pub fn ClusterRasterIndirectDrawParams::first_instance(
  self : ClusterRasterIndirectDrawParams,
) -> UInt {
  self.first_instance
}

///|
pub fn ClusterMetadata::ClusterMetadata() -> ClusterMetadata {
  ClusterMetadata::{
    indirect_draw_params: ClusterRasterIndirectDrawParams::ClusterRasterIndirectDrawParams(),
    clustered_light_count: 0U,
    reflection_probe_count: 0U,
    irradiance_volume_count: 0U,
    decal_count: 0U,
    z_slice_list_capacity: 0U,
    index_list_capacity: 0U,
    farthest_z: 0U,
  }
}

///|
pub fn ClusterMetadata::new(
  clustered_light_count : UInt,
  reflection_probe_count : UInt,
  irradiance_volume_count : UInt,
  decal_count : UInt,
  index_list_capacity : UInt,
  z_slice_list_capacity : UInt,
) -> ClusterMetadata {
  ClusterMetadata::{
    indirect_draw_params: ClusterRasterIndirectDrawParams::new(
      6U, 0U, 0U, 0U, 0U,
    ),
    clustered_light_count,
    reflection_probe_count,
    irradiance_volume_count,
    decal_count,
    z_slice_list_capacity,
    index_list_capacity,
    farthest_z: 0U,
  }
}

///|
pub fn ClusterMetadata::from_gpu_readback(
  indirect_draw_params : ClusterRasterIndirectDrawParams,
  clustered_light_count : UInt,
  reflection_probe_count : UInt,
  irradiance_volume_count : UInt,
  decal_count : UInt,
  z_slice_list_capacity : UInt,
  index_list_capacity : UInt,
  farthest_z : UInt,
) -> ClusterMetadata {
  ClusterMetadata::{
    indirect_draw_params,
    clustered_light_count,
    reflection_probe_count,
    irradiance_volume_count,
    decal_count,
    z_slice_list_capacity,
    index_list_capacity,
    farthest_z,
  }
}

///|
fn gpu_clustering_read_u8(bytes : Bytes, offset : Int) -> Int? {
  guard offset >= 0 && offset < bytes.length() else { return None }
  Some(bytes[offset].to_int() & 0xFF)
}

///|
fn gpu_clustering_read_u32_le(bytes : Bytes, offset : Int) -> UInt? {
  guard gpu_clustering_read_u8(bytes, offset) is Some(b0) else { return None }
  guard gpu_clustering_read_u8(bytes, offset + 1) is Some(b1) else {
    return None
  }
  guard gpu_clustering_read_u8(bytes, offset + 2) is Some(b2) else {
    return None
  }
  guard gpu_clustering_read_u8(bytes, offset + 3) is Some(b3) else {
    return None
  }
  Some(
    b0.reinterpret_as_uint() |
    (b1.reinterpret_as_uint() << 8) |
    (b2.reinterpret_as_uint() << 16) |
    (b3.reinterpret_as_uint() << 24),
  )
}

///|
pub fn ClusterMetadata::from_readback_bytes(bytes : Bytes) -> ClusterMetadata? {
  guard bytes.length() >= GPU_CLUSTERING_CLUSTER_METADATA_SIZE_BYTES.to_int() else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 0) is Some(index_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 4) is Some(instance_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 8) is Some(first_index) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 12) is Some(base_vertex) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 16) is Some(first_instance) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 20) is Some(clustered_light_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 24) is Some(reflection_probe_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 28) is Some(irradiance_volume_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 32) is Some(decal_count) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 36) is Some(z_slice_list_capacity) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 40) is Some(index_list_capacity) else {
    return None
  }
  guard gpu_clustering_read_u32_le(bytes, 44) is Some(farthest_z) else {
    return None
  }
  Some(
    ClusterMetadata::from_gpu_readback(
      ClusterRasterIndirectDrawParams::new(
        index_count, instance_count, first_index, base_vertex, first_instance,
      ),
      clustered_light_count,
      reflection_probe_count,
      irradiance_volume_count,
      decal_count,
      z_slice_list_capacity,
      index_list_capacity,
      farthest_z,
    ),
  )
}

///|
pub fn ClusterMetadata::clustered_light_count(self : ClusterMetadata) -> UInt {
  self.clustered_light_count
}

///|
pub fn ClusterMetadata::reflection_probe_count(self : ClusterMetadata) -> UInt {
  self.reflection_probe_count
}

///|
pub fn ClusterMetadata::irradiance_volume_count(self : ClusterMetadata) -> UInt {
  self.irradiance_volume_count
}

///|
pub fn ClusterMetadata::decal_count(self : ClusterMetadata) -> UInt {
  self.decal_count
}

///|
pub fn ClusterMetadata::index_list_capacity(self : ClusterMetadata) -> UInt {
  self.index_list_capacity
}

///|
pub fn ClusterMetadata::z_slice_list_capacity(self : ClusterMetadata) -> UInt {
  self.z_slice_list_capacity
}

///|
pub fn ClusterMetadata::farthest_z(self : ClusterMetadata) -> UInt {
  self.farthest_z
}

///|
pub fn ClusterMetadata::indirect_draw_params(
  self : ClusterMetadata,
) -> ClusterRasterIndirectDrawParams {
  self.indirect_draw_params
}

///|
fn gpu_clustering_next_power_of_two(value : Int) -> Int {
  if value <= 1 {
    return 1
  }
  let mut current = 1
  while current < value {
    current = current * 2
  }
  current
}

///|
pub fn gpu_clustering_sortable_u32_to_f32_bits(bits : UInt) -> UInt {
  let mask = if (bits & 0x8000_0000U) != 0U {
    0x8000_0000U
  } else {
    0xFFFF_FFFFU
  }
  bits ^ mask
}

///|
pub fn ViewClusteringReadbackData::new(
  settings : @light_cluster.GlobalClusterGpuSettings,
) -> ViewClusteringReadbackData {
  ViewClusteringReadbackData::{
    z_slice_list_capacity: settings.initial_z_slice_list_capacity(),
    max_index_list_capacity: settings.initial_index_list_capacity(),
    metadata_staging_pending_buffers: [],
    metadata_staging_free_buffers: [],
    last_frame_statistics: None,
  }
}

///|
pub fn ViewClusteringLastFrameStatistics::new(
  index_list_size : UInt,
  farthest_z : Float,
) -> ViewClusteringLastFrameStatistics {
  ViewClusteringLastFrameStatistics::{ index_list_size, farthest_z }
}

///|
pub fn ViewClusteringLastFrameStatistics::index_list_size(
  self : ViewClusteringLastFrameStatistics,
) -> UInt {
  self.index_list_size
}

///|
pub fn ViewClusteringLastFrameStatistics::farthest_z(
  self : ViewClusteringLastFrameStatistics,
) -> Float {
  self.farthest_z
}

///|
pub fn ViewClusteringReadbackData::z_slice_list_capacity(
  self : ViewClusteringReadbackData,
) -> Int {
  self.z_slice_list_capacity
}

///|
pub fn ViewClusteringReadbackData::max_index_list_capacity(
  self : ViewClusteringReadbackData,
) -> Int {
  self.max_index_list_capacity
}

///|
pub fn ViewClusteringReadbackData::update_from_metadata(
  self : ViewClusteringReadbackData,
  gpu_clustering_metadata : ClusterMetadata,
) -> Unit {
  let instance_count = gpu_clustering_metadata.indirect_draw_params
    .instance_count()
    .reinterpret_as_int()
  if self.z_slice_list_capacity < instance_count {
    self.z_slice_list_capacity = gpu_clustering_next_power_of_two(
      instance_count,
    )
  }
  let index_list_capacity = gpu_clustering_metadata
    .index_list_capacity()
    .reinterpret_as_int()
  if self.max_index_list_capacity < index_list_capacity {
    self.max_index_list_capacity = gpu_clustering_next_power_of_two(
      index_list_capacity,
    )
  }
  self.last_frame_statistics = Some(
    ViewClusteringLastFrameStatistics::new(
      gpu_clustering_metadata.index_list_capacity(),
      Float::reinterpret_from_uint(
        gpu_clustering_sortable_u32_to_f32_bits(
          gpu_clustering_metadata.farthest_z(),
        ),
      ),
    ),
  )
}

///|
pub fn ViewClusteringReadbackData::pending_staging_buffer_count(
  self : ViewClusteringReadbackData,
) -> Int {
  self.metadata_staging_pending_buffers.length()
}

///|
pub fn ViewClusteringReadbackData::free_staging_buffer_count(
  self : ViewClusteringReadbackData,
) -> Int {
  self.metadata_staging_free_buffers.length()
}

///|
pub fn ViewClusteringReadbackData::get_or_create_staging_buffer(
  self : ViewClusteringReadbackData,
  render_device : @renderer.RenderDevice,
) -> @wgpu.Buffer {
  let staging_buffer = match self.metadata_staging_free_buffers.pop() {
    Some(buffer) => buffer
    None => {
      let buffer = render_device
        .wgpu_device()
        .create_buffer(
          size=GPU_CLUSTERING_CLUSTER_METADATA_SIZE_BYTES,
          usage=pbr_gpu_clustering_buffer_usage(
            @wgpu.BUFFER_USAGE_COPY_DST | @wgpu.BUFFER_USAGE_MAP_READ,
          ),
        )
      buffer.set_label("clustering metadata staging buffer")
      buffer
    }
  }
  self.metadata_staging_pending_buffers.push(staging_buffer)
  staging_buffer
}

///|
pub fn ViewClusteringReadbackData::recycle_staging_buffer(
  self : ViewClusteringReadbackData,
  staging_buffer : @wgpu.Buffer,
) -> Unit {
  self.metadata_staging_free_buffers.push(staging_buffer)
}

///|
pub fn ViewClusteringReadbackData::last_frame_statistics(
  self : ViewClusteringReadbackData,
) -> ViewClusteringLastFrameStatistics? {
  self.last_frame_statistics
}

///|
pub fn RenderViewClusteringReadbackData::RenderViewClusteringReadbackData() -> RenderViewClusteringReadbackData {
  RenderViewClusteringReadbackData::{ views: {} }
}

///|
pub fn RenderViewClusteringReadbackData::len(
  self : RenderViewClusteringReadbackData,
) -> Int {
  self.views.length()
}

///|
pub fn RenderViewClusteringReadbackData::contains_main_entity(
  self : RenderViewClusteringReadbackData,
  main_entity : @render.MainEntity,
) -> Bool {
  self.views.get(main_entity.id().to_bits()) is Some(_)
}

///|
pub fn RenderViewClusteringReadbackData::view_data(
  self : RenderViewClusteringReadbackData,
  main_entity : @render.MainEntity,
) -> ViewClusteringReadbackData? {
  self.views.get(main_entity.id().to_bits())
}

///|
pub fn ViewGpuClusteringBuffers::ViewGpuClusteringBuffers() -> ViewGpuClusteringBuffers {
  let metadata_buffer : @render_resource.StorageBuffer[ClusterMetadata] = @render_resource.StorageBuffer::with_label(
    "clustering Z slicing metadata buffer",
  )
  metadata_buffer.push(ClusterMetadata::ClusterMetadata())
  ViewGpuClusteringBuffers::{
    z_slices_buffer: @render_resource.StorageBuffer::new(),
    scratchpad_offsets_and_counts_buffer: @render_resource.StorageBuffer::new(),
    cluster_metadata_buffer: metadata_buffer,
    z_slices_gpu_buffer: None,
    z_slices_gpu_capacity: 0UL,
    scratchpad_offsets_and_counts_gpu_buffer: None,
    scratchpad_offsets_and_counts_gpu_capacity: 0UL,
    cluster_metadata_gpu_buffer: None,
    cluster_metadata_gpu_capacity: 0UL,
  }
}

///|
pub fn ViewGpuClusteringBuffers::z_slices_len(
  self : ViewGpuClusteringBuffers,
) -> Int {
  self.z_slices_buffer.len()
}

///|
pub fn ViewGpuClusteringBuffers::scratchpad_offsets_and_counts_len(
  self : ViewGpuClusteringBuffers,
) -> Int {
  self.scratchpad_offsets_and_counts_buffer.len()
}

///|
pub fn ViewGpuClusteringBuffers::metadata(
  self : ViewGpuClusteringBuffers,
) -> ClusterMetadata {
  match self.cluster_metadata_buffer.values() {
    [metadata, ..] => metadata
    [] => ClusterMetadata::ClusterMetadata()
  }
}

///|
fn ViewGpuClusteringBuffers::set_metadata(
  self : ViewGpuClusteringBuffers,
  metadata : ClusterMetadata,
) -> Unit {
  self.cluster_metadata_buffer.clear()
  self.cluster_metadata_buffer.push(metadata)
}

///|
fn ViewGpuClusteringBuffers::ensure_z_slices_capacity(
  self : ViewGpuClusteringBuffers,
  capacity : Int,
) -> Unit {
  let missing = capacity - self.z_slices_buffer.len()
  if missing > 0 {
    for _ in 0..<missing {
      self.z_slices_buffer.push(
        ClusterableObjectZSlice::ClusterableObjectZSlice(),
      )
    }
  }
}

///|
fn ViewGpuClusteringBuffers::reserve_scratchpad_offsets_and_counts(
  self : ViewGpuClusteringBuffers,
  cluster_count : Int,
) -> Unit {
  for _ in 0..<cluster_count {
    self.scratchpad_offsets_and_counts_buffer.push(
      GpuClusterOffsetAndCounts::GpuClusterOffsetAndCounts(),
    )
  }
}

///|
fn ViewGpuClusteringBuffers::ensure_nonempty_scratchpad_offsets_and_counts(
  self : ViewGpuClusteringBuffers,
) -> Unit {
  if self.scratchpad_offsets_and_counts_buffer.len() == 0 {
    self.scratchpad_offsets_and_counts_buffer.push(
      GpuClusterOffsetAndCounts::GpuClusterOffsetAndCounts(),
    )
  }
}

///|
pub fn ViewGpuClusteringBuffers::z_slices_gpu_buffer(
  self : ViewGpuClusteringBuffers,
) -> @wgpu.Buffer? {
  self.z_slices_gpu_buffer
}

///|
pub fn ViewGpuClusteringBuffers::scratchpad_offsets_and_counts_gpu_buffer(
  self : ViewGpuClusteringBuffers,
) -> @wgpu.Buffer? {
  self.scratchpad_offsets_and_counts_gpu_buffer
}

///|
pub fn ViewGpuClusteringBuffers::cluster_metadata_gpu_buffer(
  self : ViewGpuClusteringBuffers,
) -> @wgpu.Buffer? {
  self.cluster_metadata_gpu_buffer
}

///|
pub fn ViewGpuClusteringBuffers::z_slices_gpu_capacity(
  self : ViewGpuClusteringBuffers,
) -> UInt64 {
  self.z_slices_gpu_capacity
}

///|
pub fn ViewGpuClusteringBuffers::scratchpad_offsets_and_counts_gpu_capacity(
  self : ViewGpuClusteringBuffers,
) -> UInt64 {
  self.scratchpad_offsets_and_counts_gpu_capacity
}

///|
pub fn ViewGpuClusteringBuffers::cluster_metadata_gpu_capacity(
  self : ViewGpuClusteringBuffers,
) -> UInt64 {
  self.cluster_metadata_gpu_capacity
}

///|
fn gpu_clustering_cluster_metadata_buffer_bytes(
  buffer : @render_resource.StorageBuffer[ClusterMetadata],
) -> Bytes {
  let out : Array[Byte] = []
  for metadata in buffer.values() {
    pbr_gpu_clustering_push_u32_le(
      out,
      metadata.indirect_draw_params.index_count,
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      metadata.indirect_draw_params.instance_count,
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      metadata.indirect_draw_params.first_index,
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      metadata.indirect_draw_params.base_vertex,
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      metadata.indirect_draw_params.first_instance,
    )
    pbr_gpu_clustering_push_u32_le(out, metadata.clustered_light_count)
    pbr_gpu_clustering_push_u32_le(out, metadata.reflection_probe_count)
    pbr_gpu_clustering_push_u32_le(out, metadata.irradiance_volume_count)
    pbr_gpu_clustering_push_u32_le(out, metadata.decal_count)
    pbr_gpu_clustering_push_u32_le(out, metadata.z_slice_list_capacity)
    pbr_gpu_clustering_push_u32_le(out, metadata.index_list_capacity)
    pbr_gpu_clustering_push_u32_le(out, metadata.farthest_z)
  }
  Bytes::from_array(out)
}

///|
fn ViewGpuClusteringBuffers::write_buffers(
  self : ViewGpuClusteringBuffers,
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
) -> Unit {
  let z_slices_required_size = (self.z_slices_buffer.len() * 12).to_uint64()
  let (z_slices_buffer, z_slices_capacity) = pbr_gpu_clustering_reuse_or_create_buffer(
    render_device,
    self.z_slices_gpu_buffer,
    self.z_slices_gpu_capacity,
    z_slices_required_size,
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
    "clusterable object Z slices",
  )
  self.z_slices_gpu_buffer = Some(z_slices_buffer)
  self.z_slices_gpu_capacity = z_slices_capacity
  let metadata_bytes = gpu_clustering_cluster_metadata_buffer_bytes(
    self.cluster_metadata_buffer,
  )
  let (metadata_buffer, metadata_capacity) = pbr_gpu_clustering_write_buffer(
    render_device,
    render_queue,
    self.cluster_metadata_gpu_buffer,
    self.cluster_metadata_gpu_capacity,
    metadata_bytes,
    "clustering Z slicing metadata buffer",
    usage_bits=@wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_COPY_DST |
      @wgpu.BUFFER_USAGE_COPY_SRC |
      @wgpu.BUFFER_USAGE_INDIRECT,
  )
  self.cluster_metadata_gpu_buffer = Some(metadata_buffer)
  self.cluster_metadata_gpu_capacity = metadata_capacity
  let scratchpad_required_size = (self.scratchpad_offsets_and_counts_buffer.len() *
  32).to_uint64()
  let (scratchpad_buffer, scratchpad_capacity) = pbr_gpu_clustering_reuse_or_create_buffer(
    render_device,
    self.scratchpad_offsets_and_counts_gpu_buffer,
    self.scratchpad_offsets_and_counts_gpu_capacity,
    scratchpad_required_size,
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
    "clustering scratchpad offsets and counts",
  )
  self.scratchpad_offsets_and_counts_gpu_buffer = Some(scratchpad_buffer)
  self.scratchpad_offsets_and_counts_gpu_capacity = scratchpad_capacity
}

///|
fn gpu_clustering_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
fn gpu_clustering_mesh_f32le_bytes(vertices : Array[@math.Vec2]) -> Bytes {
  let out : Array[Byte] = []
  for vertex in vertices {
    gpu_clustering_push_u32_le(out, vertex.x.reinterpret_as_uint())
    gpu_clustering_push_u32_le(out, vertex.y.reinterpret_as_uint())
  }
  Bytes::from_array(out)
}

///|
fn gpu_clustering_mesh_u32le_bytes(indices : Array[UInt]) -> Bytes {
  let out : Array[Byte] = []
  for index in indices {
    gpu_clustering_push_u32_le(out, index)
  }
  Bytes::from_array(out)
}

///|
fn gpu_clustering_vertices() -> Array[@math.Vec2] {
  [
    @math.Vec2::new(0.0, 0.0),
    @math.Vec2::new(1.0, 0.0),
    @math.Vec2::new(0.0, 1.0),
    @math.Vec2::new(1.0, 1.0),
  ]
}

///|
fn gpu_clustering_indices() -> Array[UInt] {
  [0U, 1U, 2U, 1U, 3U, 2U]
}

///|
pub fn GpuClusteringMeshBuffers::GpuClusteringMeshBuffers(
  render_device : @renderer.RenderDevice,
) -> GpuClusteringMeshBuffers {
  let vertex_buffer = render_device
    .wgpu_device()
    .create_buffer_init(
      usage=@wgpu.BufferUsage::from_u64(
        @wgpu.BUFFER_USAGE_COPY_DST | @wgpu.BUFFER_USAGE_VERTEX,
      ),
      gpu_clustering_mesh_f32le_bytes(gpu_clustering_vertices()),
    )
  vertex_buffer.set_label("GPU clustering vertex buffer")
  let index_buffer = render_device
    .wgpu_device()
    .create_buffer_init(
      usage=@wgpu.BufferUsage::from_u64(
        @wgpu.BUFFER_USAGE_COPY_DST | @wgpu.BUFFER_USAGE_INDEX,
      ),
      gpu_clustering_mesh_u32le_bytes(gpu_clustering_indices()),
    )
  index_buffer.set_label("GPU clustering index buffer")
  GpuClusteringMeshBuffers::{ vertex_buffer, index_buffer }
}

///|
pub fn GpuClusteringMeshBuffers::vertex_buffer(
  self : GpuClusteringMeshBuffers,
) -> @wgpu.Buffer {
  self.vertex_buffer
}

///|
pub fn GpuClusteringMeshBuffers::index_buffer(
  self : GpuClusteringMeshBuffers,
) -> @wgpu.Buffer {
  self.index_buffer
}

///|
pub fn ViewClusteringDummyTexture::new(
  texture : @render_texture.CachedTexture,
) -> ViewClusteringDummyTexture {
  ViewClusteringDummyTexture::{ texture, }
}

///|
pub fn ViewClusteringDummyTexture::texture(
  self : ViewClusteringDummyTexture,
) -> @render_texture.CachedTexture {
  self.texture
}

///|
pub fn ViewClusteringBindGroups::new(
  clustering_bind_group_z_slicing_pass : @wgpu.BindGroup,
  clustering_bind_group_count_pass : @wgpu.BindGroup,
  clustering_bind_group_allocate_pass : @wgpu.BindGroup,
  clustering_bind_group_populate_pass : @wgpu.BindGroup,
) -> ViewClusteringBindGroups {
  ViewClusteringBindGroups::{
    clustering_bind_group_z_slicing_pass,
    clustering_bind_group_count_pass,
    clustering_bind_group_allocate_pass,
    clustering_bind_group_populate_pass,
  }
}

///|
pub fn ViewClusteringBindGroups::z_slicing_bind_group(
  self : ViewClusteringBindGroups,
) -> @wgpu.BindGroup {
  self.clustering_bind_group_z_slicing_pass
}

///|
pub fn ViewClusteringBindGroups::count_bind_group(
  self : ViewClusteringBindGroups,
) -> @wgpu.BindGroup {
  self.clustering_bind_group_count_pass
}

///|
pub fn ViewClusteringBindGroups::allocate_bind_group(
  self : ViewClusteringBindGroups,
) -> @wgpu.BindGroup {
  self.clustering_bind_group_allocate_pass
}

///|
pub fn ViewClusteringBindGroups::populate_bind_group(
  self : ViewClusteringBindGroups,
) -> @wgpu.BindGroup {
  self.clustering_bind_group_populate_pass
}

///|
fn gpu_clustering_next_multiple_of(value : Int, quantum : Int) -> Int {
  if quantum <= 0 {
    abort("GPU clustering texture quantum must be positive")
  }
  if value < 0 {
    abort("GPU clustering texture dimension must be non-negative")
  }
  (value + quantum - 1) / quantum * quantum
}

///|
fn gpu_clustering_int_to_uint(value : Int, label : String) -> UInt {
  if value < 0 {
    abort("\{label} must be non-negative")
  }
  value.reinterpret_as_uint()
}

///|
pub fn ViewGpuClusteringPipelineIds::new(
  clustering_z_slicing_pipeline_id : @render_resource.CachedComputePipelineId,
  clustering_count_pipeline_id : @render_resource.CachedRenderPipelineId,
  clustering_allocation_local_pipeline_id : @render_resource.CachedComputePipelineId,
  clustering_allocation_global_pipeline_id : @render_resource.CachedComputePipelineId,
  clustering_populate_pipeline_id : @render_resource.CachedRenderPipelineId,
) -> ViewGpuClusteringPipelineIds {
  ViewGpuClusteringPipelineIds::{
    clustering_z_slicing_pipeline_id,
    clustering_count_pipeline_id,
    clustering_allocation_local_pipeline_id,
    clustering_allocation_global_pipeline_id,
    clustering_populate_pipeline_id,
  }
}

///|
pub fn ViewGpuClusteringPipelineIds::clustering_z_slicing_pipeline_id(
  self : ViewGpuClusteringPipelineIds,
) -> @render_resource.CachedComputePipelineId {
  self.clustering_z_slicing_pipeline_id
}

///|
pub fn ViewGpuClusteringPipelineIds::clustering_count_pipeline_id(
  self : ViewGpuClusteringPipelineIds,
) -> @render_resource.CachedRenderPipelineId {
  self.clustering_count_pipeline_id
}

///|
pub fn ViewGpuClusteringPipelineIds::clustering_allocation_local_pipeline_id(
  self : ViewGpuClusteringPipelineIds,
) -> @render_resource.CachedComputePipelineId {
  self.clustering_allocation_local_pipeline_id
}

///|
pub fn ViewGpuClusteringPipelineIds::clustering_allocation_global_pipeline_id(
  self : ViewGpuClusteringPipelineIds,
) -> @render_resource.CachedComputePipelineId {
  self.clustering_allocation_global_pipeline_id
}

///|
pub fn ViewGpuClusteringPipelineIds::clustering_populate_pipeline_id(
  self : ViewGpuClusteringPipelineIds,
) -> @render_resource.CachedRenderPipelineId {
  self.clustering_populate_pipeline_id
}

///|
fn[T] gpu_clustering_resource_or_abort(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  label : String,
) -> T {
  match world.get_resource(key) {
    Some(value) => value
    None => abort("missing GPU clustering render resource: \{label}")
  }
}

///|
fn gpu_clustering_buffer_binding_type_to_wgpu(
  kind : @render_resource.BufferBindingType,
) -> UInt {
  match kind {
    Uniform => @wgpu.BUFFER_BINDING_TYPE_UNIFORM
    Storage(read_only) =>
      if read_only {
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE
      } else {
        @wgpu.BUFFER_BINDING_TYPE_STORAGE
      }
  }
}

///|
fn gpu_clustering_texture_sample_type_to_wgpu(
  kind : @render_resource.TextureSampleType,
) -> UInt {
  match kind {
    Float(filterable) =>
      if filterable {
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT
      } else {
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT
      }
    Depth => @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH
    SInt => @wgpu.TEXTURE_SAMPLE_TYPE_SINT
    UInt => @wgpu.TEXTURE_SAMPLE_TYPE_UINT
  }
}

///|
fn gpu_clustering_texture_view_dimension_to_wgpu(
  dimension : @render_resource.TextureViewDimension,
) -> UInt {
  match dimension {
    D1 => @wgpu.TEXTURE_VIEW_DIMENSION_1D
    D2 => @wgpu.TEXTURE_VIEW_DIMENSION_2D
    D2Array => @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY
    Cube => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE
    CubeArray => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE_ARRAY
    D3 => @wgpu.TEXTURE_VIEW_DIMENSION_3D
  }
}

///|
fn gpu_clustering_sampler_binding_type_to_wgpu(
  kind : @render_resource.SamplerBindingType,
) -> UInt {
  match kind {
    Filtering => @wgpu.SAMPLER_BINDING_TYPE_FILTERING
    NonFiltering => @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING
    Comparison => @wgpu.SAMPLER_BINDING_TYPE_COMPARISON
  }
}

///|
fn gpu_clustering_storage_texture_access_to_wgpu(
  access : @render_resource.StorageTextureAccess,
) -> UInt {
  match access {
    WriteOnly => @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY
    ReadOnly => @wgpu.STORAGE_TEXTURE_ACCESS_READ_ONLY
    ReadWrite => @wgpu.STORAGE_TEXTURE_ACCESS_READ_WRITE
  }
}

///|
fn gpu_clustering_add_render_resource_layout_entry(
  builder : @wgpu.BindGroupLayoutBuilder,
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  if entry.binding() < 0 {
    return false
  }
  let binding = entry.binding().reinterpret_as_uint()
  let visibility = @wgpu.ShaderStage::from_u64(entry.visibility().to_uint64())
  let count = if entry.count() > 1 {
    entry.count().reinterpret_as_uint()
  } else {
    1U
  }
  match entry.kind() {
    Buffer =>
      builder.add_buffer(
        binding,
        visibility,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=0UL,
      )
    Texture =>
      builder.add_texture(
        binding,
        visibility,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        count~,
      )
    Sampler =>
      builder.add_sampler(
        binding,
        visibility,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
        count~,
      )
    StorageTexture =>
      builder.add_storage_texture(
        binding,
        visibility,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
    External => false
    BufferBinding(buffer_kind, has_dynamic_offset, min_binding_size) =>
      builder.add_buffer(
        binding,
        visibility,
        gpu_clustering_buffer_binding_type_to_wgpu(buffer_kind),
        has_dynamic_offset~,
        min_binding_size~,
      )
    TextureBinding(sample_type, view_dimension, multisampled) =>
      builder.add_texture(
        binding,
        visibility,
        gpu_clustering_texture_sample_type_to_wgpu(sample_type),
        gpu_clustering_texture_view_dimension_to_wgpu(view_dimension),
        multisampled~,
        count~,
      )
    SamplerBinding(sampler_type) =>
      builder.add_sampler(
        binding,
        visibility,
        gpu_clustering_sampler_binding_type_to_wgpu(sampler_type),
        count~,
      )
    StorageTextureBinding(access, format, view_dimension) =>
      builder.add_storage_texture(
        binding,
        visibility,
        gpu_clustering_storage_texture_access_to_wgpu(access),
        @wgpu.TextureFormat::from_u32(format),
        gpu_clustering_texture_view_dimension_to_wgpu(view_dimension),
      )
  }
}

///|
fn gpu_clustering_create_bind_group_layout_from_descriptor(
  render_device : @renderer.RenderDevice,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  label_suffix : String,
) -> @wgpu.BindGroupLayout {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupLayoutBuilder::new(
    max_entries=entries.length().to_uint64(),
  )
  for entry in entries {
    if !gpu_clustering_add_render_resource_layout_entry(builder, entry) {
      builder.free()
      abort(
        "wgpu: unsupported GPU clustering bind group layout descriptor entry in " +
        descriptor.label(),
      )
    }
  }
  builder.finish(
    render_device.wgpu_device(),
    label="mgstudio_gpu_clustering_" + label_suffix + "_" + descriptor.label(),
  )
}

///|
pub fn gpu_clustering_is_enabled(world : @ecs.World) -> Bool {
  match world.get_resource(@light_cluster.GlobalClusterSettings::resource()) {
    Some(settings) => settings.gpu_clustering() is Some(_)
    None => false
  }
}

///|
fn gpu_clustering_view_environment_map_light_probe_count(
  world : @ecs.World,
  view : @core.Entity,
) -> Int {
  match
    (world.get_by_key(
      view,
      @pbr_light_probe.RenderViewEnvironmentMapLightProbes::component(),
    ) catch {
      _ =>
        abort(
          "prepare_clusters_for_gpu_clustering: failed to read light probes",
        )
    }) {
    Some(probes) => probes.probe_count()
    None => 0
  }
}

///|
fn gpu_clustering_view_irradiance_volume_light_probe_count(
  world : @ecs.World,
  view : @core.Entity,
) -> Int {
  match
    (world.get_by_key(
      view,
      @pbr_light_probe.RenderViewIrradianceVolumeLightProbes::component(),
    ) catch {
      _ =>
        abort(
          "prepare_clusters_for_gpu_clustering: failed to read light probes",
        )
    }) {
    Some(probes) => probes.probe_count()
    None => 0
  }
}

///|
fn gpu_clustering_render_clustered_decal_count(world : @ecs.World) -> Int {
  match world.get_resource(@pbr_decal.RenderClusteredDecals::resource()) {
    Some(decals) => decals.len()
    None => 0
  }
}

///|
fn gpu_clustering_readback_data_for_view(
  readback : RenderViewClusteringReadbackData,
  main_entity : @render.MainEntity,
  settings : @light_cluster.GlobalClusterGpuSettings,
) -> ViewClusteringReadbackData {
  let key = main_entity.id().to_bits()
  match readback.views.get(key) {
    Some(data) => data
    None => {
      let data = ViewClusteringReadbackData::new(settings)
      readback.views.set(key, data)
      data
    }
  }
}

///|
fn gpu_clustering_retain_live_readback_views(
  readback : RenderViewClusteringReadbackData,
  live_view_main_entities : Map[UInt64, Bool],
) -> Unit {
  let stale_keys : Array[UInt64] = []
  for key, _ in readback.views {
    if live_view_main_entities.get(key) is None {
      stale_keys.push(key)
    }
  }
  for key in stale_keys {
    ignore(readback.views.remove(key))
  }
}

///|
pub fn prepare_clusters_for_gpu_clustering(world : @ecs.World) -> Unit {
  let render_device = gpu_clustering_resource_or_abort(
    world, @render.render_device_resource_key, "RenderDevice",
  )
  let render_queue = gpu_clustering_resource_or_abort(
    world, @render.render_queue_resource_key, "RenderQueue",
  )
  let global_cluster_settings = gpu_clustering_resource_or_abort(
    world,
    @light_cluster.GlobalClusterSettings::resource(),
    "GlobalClusterSettings",
  )
  let global_cluster_settings_gpu = match
    global_cluster_settings.gpu_clustering() {
    Some(settings) => settings
    None => {
      @app.log_error(
        "`prepare_clusters_for_gpu_clustering()` called when GPU clustering is disabled",
      )
      return
    }
  }
  let global_clusterable_object_meta = gpu_clustering_resource_or_abort(
    world,
    GlobalClusterableObjectMeta::resource(),
    "GlobalClusterableObjectMeta",
  )
  let render_view_clustering_index_list_sizes = gpu_clustering_resource_or_abort(
    world,
    RenderViewClusteringReadbackData::resource(),
    "RenderViewClusteringReadbackData",
  )
  let decal_count = gpu_clustering_render_clustered_decal_count(world)
  let live_view_main_entities : Map[UInt64, Bool] = {}
  world.for_each_component(ExtractedClusterConfig::component(), fn(
    view_entity,
    extracted_cluster_config,
  ) {
    guard (world.get_by_key(
        view_entity,
        @render_view.ExtractedView::component(),
      ) catch {
        _ =>
          abort(
            "prepare_clusters_for_gpu_clustering: failed to read extracted view",
          )
      })
      is Some(_) else {
      return
    }
    guard (world.get_by_key(view_entity, @render.ecs_key_main_entity) catch {
        _ =>
          abort(
            "prepare_clusters_for_gpu_clustering: failed to read MainEntity",
          )
      })
      is Some(view_main_entity) else {
      return
    }
    let dimensions = extracted_cluster_config.dimensions()
    let cluster_count = dimensions.0 * dimensions.1 * dimensions.2
    let view_clusters_bindings = ViewClusterBindings::ViewClusterBindings()
    view_clusters_bindings.clear()
    view_clusters_bindings.reserve_clusters(cluster_count)
    live_view_main_entities.set(view_main_entity.id().to_bits(), true)
    let view_clustering_buffer_size_data = gpu_clustering_readback_data_for_view(
      render_view_clustering_index_list_sizes, view_main_entity, global_cluster_settings_gpu,
    )
    let view_gpu_clustering_buffers = ViewGpuClusteringBuffers::ViewGpuClusteringBuffers()
    let reflection_probe_count = gpu_clustering_view_environment_map_light_probe_count(
      world, view_entity,
    )
    let irradiance_volume_count = gpu_clustering_view_irradiance_volume_light_probe_count(
      world, view_entity,
    )
    view_gpu_clustering_buffers.set_metadata(
      ClusterMetadata::new(
        gpu_clustering_int_to_uint(
          global_clusterable_object_meta.gpu_clustered_light_count(),
          "clustered_light_count",
        ),
        gpu_clustering_int_to_uint(
          reflection_probe_count, "reflection_probe_count",
        ),
        gpu_clustering_int_to_uint(
          irradiance_volume_count, "irradiance_volume_count",
        ),
        gpu_clustering_int_to_uint(decal_count, "decal_count"),
        gpu_clustering_int_to_uint(
          view_clustering_buffer_size_data.max_index_list_capacity(),
          "index_list_capacity",
        ),
        gpu_clustering_int_to_uint(
          view_clustering_buffer_size_data.z_slice_list_capacity(),
          "z_slice_list_capacity",
        ),
      ),
    )
    view_gpu_clustering_buffers.ensure_z_slices_capacity(
      view_clustering_buffer_size_data.z_slice_list_capacity(),
    )
    view_clusters_bindings.reserve_indices(
      view_clustering_buffer_size_data.max_index_list_capacity(),
    )
    view_clusters_bindings.write_buffers(render_device, render_queue)
    view_gpu_clustering_buffers.reserve_scratchpad_offsets_and_counts(
      cluster_count,
    )
    world.set_by_key(
      view_entity,
      ViewClusterBindings::component(),
      view_clusters_bindings,
    ) catch {
      _ =>
        abort("prepare_clusters_for_gpu_clustering: failed to insert bindings")
    }
    world.set_by_key(
      view_entity,
      ViewGpuClusteringBuffers::component(),
      view_gpu_clustering_buffers,
    ) catch {
      _ =>
        abort("prepare_clusters_for_gpu_clustering: failed to insert buffers")
    }
  })
  gpu_clustering_retain_live_readback_views(
    render_view_clustering_index_list_sizes, live_view_main_entities,
  )
}

///|
pub fn extract_clusters_for_gpu_clustering(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  render_world
  .components_registrator()
  .register_component_by_key(ExtractedClusterConfig::component())
  |> ignore
  let readback = render_world.get_resource(
    RenderViewClusteringReadbackData::resource(),
  )
  source_world.for_each_component(@light_cluster.Clusters::component(), fn(
    source_view_entity,
    clusters,
  ) {
    guard (try! source_world.get_by_key(
        source_view_entity, @render.ecs_key_render_entity,
      ))
      is Some(render_entity) else {
      return
    }
    let render_view_entity = render_entity.id()
    let camera_is_active = match
      (try! source_world.get_by_key(
        source_view_entity, @camera_camera.ecs_key_camera,
      )) {
      Some(camera) => camera.is_active
      None => true
    }
    if !camera_is_active {
      ignore(
        render_world.remove_by_key(
          render_view_entity,
          ExtractedClusterConfig::component(),
        ) catch {
          _ => false
        },
      )
      return
    }
    render_world.set_by_key(
      render_view_entity,
      ExtractedClusterConfig::component(),
      ExtractedClusterConfig::from_clusters(clusters),
    ) catch {
      _ => abort("extract_clusters_for_gpu_clustering: failed to insert config")
    }
    match readback {
      Some(readback_data) =>
        match
          readback_data.view_data(@render.MainEntity::new(source_view_entity)) {
          Some(view_clustering_buffer_size_data) =>
            match view_clustering_buffer_size_data.last_frame_statistics() {
              Some(statistics) => {
                let updated_clusters = clusters.with_last_frame_statistics(
                  statistics.farthest_z(),
                  statistics.index_list_size().reinterpret_as_int(),
                )
                source_world.set_by_key(
                  source_view_entity,
                  @light_cluster.Clusters::component(),
                  updated_clusters,
                ) catch {
                  _ =>
                    abort(
                      "extract_clusters_for_gpu_clustering: failed to update source clusters",
                    )
                }
              }
              None => ()
            }
          None => ()
        }
      None => ()
    }
  })
}

///|
pub fn upload_view_gpu_clustering_buffers(world : @ecs.World) -> Unit {
  let render_device = gpu_clustering_resource_or_abort(
    world, @render.render_device_resource_key, "RenderDevice",
  )
  let render_queue = gpu_clustering_resource_or_abort(
    world, @render.render_queue_resource_key, "RenderQueue",
  )
  world.for_each_component(ViewGpuClusteringBuffers::component(), fn(
    _view_entity,
    view_gpu_clustering_buffers,
  ) {
    view_gpu_clustering_buffers.ensure_nonempty_scratchpad_offsets_and_counts()
    view_gpu_clustering_buffers.write_buffers(render_device, render_queue)
  })
}

///|
pub fn gpu_clustering_schedule_readback_staging(
  command_encoder : @wgpu.CommandEncoder,
  view_gpu_clustering_buffers : ViewGpuClusteringBuffers,
  staging_buffer : @wgpu.Buffer,
) -> Bool {
  match view_gpu_clustering_buffers.cluster_metadata_gpu_buffer() {
    None => {
      @app.log_error("No clustering Z slicing metadata buffer found")
      false
    }
    Some(metadata_buffer) => {
      command_encoder.copy_buffer_to_buffer(
        metadata_buffer,
        0UL,
        staging_buffer,
        0UL,
        GPU_CLUSTERING_CLUSTER_METADATA_SIZE_BYTES,
      )
      true
    }
  }
}

///|
pub fn gpu_clustering_process_readback_staging_buffer(
  view_clustering_readback_data : ViewClusteringReadbackData,
  status : UInt,
  bytes : Bytes,
  staging_buffer : @wgpu.Buffer,
) -> Bool {
  if status != @wgpu.MAP_ASYNC_STATUS_SUCCESS || bytes.length() == 0 {
    view_clustering_readback_data.recycle_staging_buffer(staging_buffer)
    return false
  }
  match ClusterMetadata::from_readback_bytes(bytes) {
    None => {
      view_clustering_readback_data.recycle_staging_buffer(staging_buffer)
      false
    }
    Some(gpu_clustering_metadata) => {
      view_clustering_readback_data.update_from_metadata(
        gpu_clustering_metadata,
      )
      view_clustering_readback_data.recycle_staging_buffer(staging_buffer)
      true
    }
  }
}

///|
priv struct ResolvedViewGpuClusteringPipelines {
  z_slicing : @render_resource.ComputePipeline
  count : @render_resource.RenderPipeline
  allocation_local : @render_resource.ComputePipeline
  allocation_global : @render_resource.ComputePipeline
  populate : @render_resource.RenderPipeline
}

///|
fn gpu_clustering_resolve_view_pipelines(
  pipeline_cache : @render_resource.PipelineCache,
  pipeline_ids : ViewGpuClusteringPipelineIds,
) -> ResolvedViewGpuClusteringPipelines? {
  guard pipeline_cache.get_compute_pipeline(
      pipeline_ids.clustering_z_slicing_pipeline_id(),
    )
    is Some(z_slicing) else {
    return None
  }
  guard pipeline_cache.get_render_pipeline(
      pipeline_ids.clustering_count_pipeline_id(),
    )
    is Some(count) else {
    return None
  }
  guard pipeline_cache.get_compute_pipeline(
      pipeline_ids.clustering_allocation_local_pipeline_id(),
    )
    is Some(allocation_local) else {
    return None
  }
  guard pipeline_cache.get_compute_pipeline(
      pipeline_ids.clustering_allocation_global_pipeline_id(),
    )
    is Some(allocation_global) else {
    return None
  }
  guard pipeline_cache.get_render_pipeline(
      pipeline_ids.clustering_populate_pipeline_id(),
    )
    is Some(populate) else {
    return None
  }
  Some(ResolvedViewGpuClusteringPipelines::{
    z_slicing,
    count,
    allocation_local,
    allocation_global,
    populate,
  })
}

///|
fn gpu_clustering_run_z_slicing_pass(
  command_encoder : @wgpu.CommandEncoder,
  clustering_z_slicing_pipeline : @render_resource.ComputePipeline,
  clustering_z_slicing_bind_group : @wgpu.BindGroup,
  view_gpu_clustering_buffers : ViewGpuClusteringBuffers,
  view_light_probes_uniform_offset : @pbr_light_probe.ViewLightProbesUniformOffset,
  view_lights_uniform_offset : @pbr_render.ViewLightsUniformOffset,
  view_uniform_offset : @render_view.ViewUniformOffset,
) -> Unit {
  let compute_pass = command_encoder.begin_compute_pass()
  compute_pass.set_pipeline(clustering_z_slicing_pipeline.into_inner())
  compute_pass.set_bind_group(0U, clustering_z_slicing_bind_group, [
    view_light_probes_uniform_offset.offset(),
    view_lights_uniform_offset.offset(),
    view_uniform_offset.offset(),
  ])
  let workgroup_count = gpu_clustering_z_slice_dispatch_count(
    gpu_clustering_clusterable_object_count(
      view_gpu_clustering_buffers.metadata(),
    ).reinterpret_as_int(),
  ).reinterpret_as_uint()
  compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
  compute_pass.end()
  compute_pass.release()
}

///|
fn gpu_clustering_begin_raster_pass(
  command_encoder : @wgpu.CommandEncoder,
  view_clustering_dummy_texture : ViewClusteringDummyTexture,
  populate_pass : Bool,
) -> @wgpu.RenderPass {
  populate_pass |> ignore
  let builder = @wgpu.RenderPassDescBuilder::new(1U) catch {
    _ => abort("wgpu: failed to create GPU clustering raster pass descriptor")
  }
  builder.set_color_attachment(
    0U,
    view_clustering_dummy_texture.texture().default_view().into_inner(),
    load_op_u32=@wgpu.LOAD_OP_CLEAR,
    store_op_u32=@wgpu.STORE_OP_DISCARD,
    clear_r_f32=0.0F,
    clear_g_f32=0.0F,
    clear_b_f32=0.0F,
    clear_a_f32=1.0F,
  ) catch {
    _ => abort("wgpu: failed to set GPU clustering raster attachment")
  }
  builder.begin(command_encoder) catch {
    _ => abort("wgpu: failed to begin GPU clustering raster pass")
  }
}

///|
fn gpu_clustering_run_rasterization_pass(
  command_encoder : @wgpu.CommandEncoder,
  clustering_render_pipeline : @render_resource.RenderPipeline,
  clustering_bind_group : @wgpu.BindGroup,
  view_gpu_clustering_buffers : ViewGpuClusteringBuffers,
  view_light_probes_uniform_offset : @pbr_light_probe.ViewLightProbesUniformOffset,
  view_lights_uniform_offset : @pbr_render.ViewLightsUniformOffset,
  view_uniform_offset : @render_view.ViewUniformOffset,
  view_clustering_dummy_texture : ViewClusteringDummyTexture,
  extracted_cluster_config : ExtractedClusterConfig,
  clustering_mesh_buffers : GpuClusteringMeshBuffers,
  populate_pass : Bool,
) -> Bool {
  guard view_gpu_clustering_buffers.cluster_metadata_gpu_buffer()
    is Some(cluster_metadata_buffer) else {
    @app.log_error("Z slicing metadata buffer was never uploaded")
    return false
  }
  let render_pass = gpu_clustering_begin_raster_pass(
    command_encoder, view_clustering_dummy_texture, populate_pass,
  )
  render_pass.set_pipeline(clustering_render_pipeline.into_inner())
  render_pass.set_bind_group(0U, clustering_bind_group, [
    view_light_probes_uniform_offset.offset(),
    view_lights_uniform_offset.offset(),
    view_uniform_offset.offset(),
  ])
  let dimensions = extracted_cluster_config.dimensions()
  render_pass.set_viewport(
    0.0F,
    0.0F,
    Float::from_double(dimensions.0.to_double()),
    Float::from_double(dimensions.1.to_double()),
    0.0F,
    1.0F,
  )
  let vertex_buffer = clustering_mesh_buffers.vertex_buffer()
  render_pass.set_vertex_buffer(0U, vertex_buffer, 0UL, vertex_buffer.size())
  let index_buffer = clustering_mesh_buffers.index_buffer()
  render_pass.set_index_buffer_u32(index_buffer, 0UL, index_buffer.size())
  render_pass.draw_indexed_indirect(cluster_metadata_buffer, 0UL)
  render_pass.end()
  render_pass.release()
  true
}

///|
fn gpu_clustering_run_allocation_pass(
  command_encoder : @wgpu.CommandEncoder,
  clustering_allocation_pipeline : @render_resource.ComputePipeline,
  view_clustering_bind_groups : ViewClusteringBindGroups,
  view_lights_uniform_offset : @pbr_render.ViewLightsUniformOffset,
  extracted_cluster_config : ExtractedClusterConfig,
  global_pass : Bool,
) -> Unit {
  let compute_pass = command_encoder.begin_compute_pass()
  compute_pass.set_pipeline(clustering_allocation_pipeline.into_inner())
  compute_pass.set_bind_group(
    0U,
    view_clustering_bind_groups.allocate_bind_group(),
    [view_lights_uniform_offset.offset()],
  )
  compute_pass.dispatch_workgroups(
    gpu_clustering_allocation_pass_workgroup_count(
      extracted_cluster_config, global_pass,
    ),
    1U,
    1U,
  )
  compute_pass.end()
  compute_pass.release()
}

///|
pub fn gpu_clustering_cluster_on_gpu_commands(
  command_encoder : @wgpu.CommandEncoder,
  render_device : @renderer.RenderDevice,
  pipeline_cache : @render_resource.PipelineCache,
  clustering_mesh_buffers : GpuClusteringMeshBuffers,
  render_view_clustering_readback_data : RenderViewClusteringReadbackData,
  view_main_entity : @render.MainEntity,
  view_gpu_clustering_buffers : ViewGpuClusteringBuffers,
  view_gpu_clustering_pipeline_ids : ViewGpuClusteringPipelineIds,
  view_clustering_dummy_texture : ViewClusteringDummyTexture,
  view_clustering_bind_groups : ViewClusteringBindGroups,
  view_light_probes_uniform_offset : @pbr_light_probe.ViewLightProbesUniformOffset,
  view_lights_uniform_offset : @pbr_render.ViewLightsUniformOffset,
  view_uniform_offset : @render_view.ViewUniformOffset,
  extracted_cluster_config : ExtractedClusterConfig,
) -> GpuClusteringReadbackRequest? {
  guard render_view_clustering_readback_data.view_data(view_main_entity)
    is Some(view_clustering_readback_data) else {
    return None
  }
  guard gpu_clustering_resolve_view_pipelines(
      pipeline_cache, view_gpu_clustering_pipeline_ids,
    )
    is Some(pipelines) else {
    return None
  }
  let staging_buffer = view_clustering_readback_data.get_or_create_staging_buffer(
    render_device,
  )
  gpu_clustering_run_z_slicing_pass(
    command_encoder,
    pipelines.z_slicing,
    view_clustering_bind_groups.z_slicing_bind_group(),
    view_gpu_clustering_buffers,
    view_light_probes_uniform_offset,
    view_lights_uniform_offset,
    view_uniform_offset,
  )
  if !gpu_clustering_run_rasterization_pass(
      command_encoder,
      pipelines.count,
      view_clustering_bind_groups.count_bind_group(),
      view_gpu_clustering_buffers,
      view_light_probes_uniform_offset,
      view_lights_uniform_offset,
      view_uniform_offset,
      view_clustering_dummy_texture,
      extracted_cluster_config,
      clustering_mesh_buffers,
      false,
    ) {
    view_clustering_readback_data.recycle_staging_buffer(staging_buffer)
    return None
  }
  gpu_clustering_run_allocation_pass(
    command_encoder,
    pipelines.allocation_local,
    view_clustering_bind_groups,
    view_lights_uniform_offset,
    extracted_cluster_config,
    false,
  )
  gpu_clustering_run_allocation_pass(
    command_encoder,
    pipelines.allocation_global,
    view_clustering_bind_groups,
    view_lights_uniform_offset,
    extracted_cluster_config,
    true,
  )
  if !gpu_clustering_run_rasterization_pass(
      command_encoder,
      pipelines.populate,
      view_clustering_bind_groups.populate_bind_group(),
      view_gpu_clustering_buffers,
      view_light_probes_uniform_offset,
      view_lights_uniform_offset,
      view_uniform_offset,
      view_clustering_dummy_texture,
      extracted_cluster_config,
      clustering_mesh_buffers,
      true,
    ) {
    view_clustering_readback_data.recycle_staging_buffer(staging_buffer)
    return None
  }
  ignore(
    gpu_clustering_schedule_readback_staging(
      command_encoder, view_gpu_clustering_buffers, staging_buffer,
    ),
  )
  Some(GpuClusteringReadbackRequest::{
    view_clustering_readback_data,
    staging_buffer,
  })
}

///|
fn[T] cluster_on_gpu_component(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> T? {
  world.get_by_key(entity, key) catch {
    _ => abort("cluster_on_gpu: failed to read view component")
  }
}

///|
fn cluster_on_gpu(world : @ecs.World) -> Unit {
  let render_device = match
    world.get_resource(@render.render_device_resource_key) {
    Some(value) => value
    None => return
  }
  let pipeline_cache = match
    world.get_resource(@render.pipeline_cache_resource_key) {
    Some(value) => value
    None => return
  }
  let clustering_mesh_buffers = match
    world.get_resource(GpuClusteringMeshBuffers::resource()) {
    Some(value) => value
    None => return
  }
  let render_view_clustering_readback_data = match
    world.get_resource(RenderViewClusteringReadbackData::resource()) {
    Some(value) => value
    None => return
  }
  let pending = match
    world.get_resource(@render.pending_command_buffers_resource_key) {
    Some(value) => value
    None => return
  }
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    guard cluster_on_gpu_component(
        world, view_entity, @render.ecs_key_main_entity,
      )
      is Some(view_main_entity) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        ViewGpuClusteringBuffers::component(),
      )
      is Some(view_gpu_clustering_buffers) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        ViewGpuClusteringPipelineIds::component(),
      )
      is Some(view_gpu_clustering_pipeline_ids) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        ViewClusteringDummyTexture::component(),
      )
      is Some(view_clustering_dummy_texture) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        ViewClusteringBindGroups::component(),
      )
      is Some(view_clustering_bind_groups) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        @pbr_light_probe.ViewLightProbesUniformOffset::component(),
      )
      is Some(view_light_probes_uniform_offset) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        @pbr_render.ViewLightsUniformOffset::component(),
      )
      is Some(view_lights_uniform_offset) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        @render_view.ViewUniformOffset::component(),
      )
      is Some(view_uniform_offset) else {
      return
    }
    guard cluster_on_gpu_component(
        world,
        view_entity,
        ExtractedClusterConfig::component(),
      )
      is Some(extracted_cluster_config) else {
      return
    }
    let encoder = render_device.create_command_encoder()
    match
      gpu_clustering_cluster_on_gpu_commands(
        encoder, render_device, pipeline_cache, clustering_mesh_buffers, render_view_clustering_readback_data,
        view_main_entity, view_gpu_clustering_buffers, view_gpu_clustering_pipeline_ids,
        view_clustering_dummy_texture, view_clustering_bind_groups, view_light_probes_uniform_offset,
        view_lights_uniform_offset, view_uniform_offset, extracted_cluster_config,
      ) {
      None => encoder.release()
      Some(readback_request) =>
        pending.push_encoder_map_read(
          encoder,
          readback_request.staging_buffer,
          0UL,
          GPU_CLUSTERING_CLUSTER_METADATA_SIZE_BYTES,
          fn(status, bytes, staging_buffer) {
            ignore(
              gpu_clustering_process_readback_staging_buffer(
                readback_request.view_clustering_readback_data,
                status,
                bytes,
                staging_buffer,
              ),
            )
          },
        )
    }
  })
}

///|
fn gpu_clustering_finish_bind_group_or_abort(
  builder : @wgpu.BindGroupBuilder,
  device : @wgpu.Device,
  layout : @wgpu.BindGroupLayout,
  label : String,
) -> @wgpu.BindGroup {
  builder.finish(device, layout, label~)
}

///|
pub fn prepare_clustering_bind_groups(world : @ecs.World) -> Unit {
  let render_device = gpu_clustering_resource_or_abort(
    world, @render.render_device_resource_key, "RenderDevice",
  )
  let clustering_z_slicing_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringZSlicingPipeline::resource(),
    "ClusteringZSlicingPipeline",
  )
  let clustering_raster_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringRasterPipeline::resource(),
    "ClusteringRasterPipeline",
  )
  let clustering_allocation_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringAllocationPipeline::resource(),
    "ClusteringAllocationPipeline",
  )
  let global_clusterable_object_meta = gpu_clustering_resource_or_abort(
    world,
    GlobalClusterableObjectMeta::resource(),
    "GlobalClusterableObjectMeta",
  )
  let light_probes_buffer = gpu_clustering_resource_or_abort(
    world,
    @pbr_light_probe.LightProbesBuffer::resource(),
    "LightProbesBuffer",
  )
  let decals_buffer_resource = gpu_clustering_resource_or_abort(
    world,
    @pbr_decal.DecalsBuffer::resource(),
    "DecalsBuffer",
  )
  let light_meta = gpu_clustering_resource_or_abort(
    world,
    @pbr_render.LightMeta::resource(),
    "LightMeta",
  )
  let view_uniforms = gpu_clustering_resource_or_abort(
    world,
    @render_view.ViewUniforms::resource(),
    "ViewUniforms",
  )
  let gpu_clustered_lights_binding = match
    global_clusterable_object_meta.gpu_clustered_lights_binding() {
    Some(buffer) => buffer
    None => return
  }
  let light_probes_binding = match light_probes_buffer.binding() {
    Some(buffer) => buffer
    None => return
  }
  let decals_buffer = match decals_buffer_resource.buffer() {
    Some(buffer) => buffer
    None => return
  }
  let lights_binding = match light_meta.view_gpu_lights_binding() {
    Some(buffer) => buffer
    None => return
  }
  let view_binding = match view_uniforms.binding() {
    Some(buffer) => buffer
    None => return
  }
  let device = render_device.wgpu_device()
  let z_slicing_layout = gpu_clustering_create_bind_group_layout_from_descriptor(
    render_device,
    clustering_z_slicing_pipeline.layout(),
    "z_slicing_pass",
  )
  let count_layout = gpu_clustering_create_bind_group_layout_from_descriptor(
    render_device,
    clustering_raster_pipeline.count_pass_layout(),
    "count_pass",
  )
  let allocation_layout = gpu_clustering_create_bind_group_layout_from_descriptor(
    render_device,
    clustering_allocation_pipeline.layout(),
    "allocation_pass",
  )
  let populate_layout = gpu_clustering_create_bind_group_layout_from_descriptor(
    render_device,
    clustering_raster_pipeline.populate_pass_layout(),
    "populate_pass",
  )
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    let view_gpu_clustering_buffers = match
      (world.get_by_key(view_entity, ViewGpuClusteringBuffers::component()) catch {
        _ =>
          abort(
            "prepare_clustering_bind_groups: failed to read view GPU clustering buffers",
          )
      }) {
      Some(value) => value
      None => return
    }
    let view_cluster_bindings = match
      (world.get_by_key(view_entity, ViewClusterBindings::component()) catch {
        _ =>
          abort(
            "prepare_clustering_bind_groups: failed to read view cluster bindings",
          )
      }) {
      Some(value) => value
      None => return
    }
    let z_slices_buffer = match
      view_gpu_clustering_buffers.z_slices_gpu_buffer() {
      Some(buffer) => buffer
      None => return
    }
    let cluster_metadata_buffer = match
      view_gpu_clustering_buffers.cluster_metadata_gpu_buffer() {
      Some(buffer) => buffer
      None => return
    }
    let scratchpad_offsets_and_counts_buffer = match
      view_gpu_clustering_buffers.scratchpad_offsets_and_counts_gpu_buffer() {
      Some(buffer) => buffer
      None => return
    }
    let clusterable_object_index_lists = match
      view_cluster_bindings.clusterable_object_index_lists_gpu_buffer() {
      Some(buffer) => buffer
      None => return
    }
    let cluster_offsets_and_counts = match
      view_cluster_bindings.cluster_offsets_and_counts_gpu_buffer() {
      Some(buffer) => buffer
      None => return
    }
    let z_slicing_builder = @wgpu.BindGroupBuilder::new(max_entries=7UL)
    let z_slicing_ok = z_slicing_builder.add_buffer(0U, cluster_metadata_buffer) &&
      z_slicing_builder.add_buffer(1U, z_slices_buffer) &&
      z_slicing_builder.add_buffer(2U, gpu_clustered_lights_binding) &&
      z_slicing_builder.add_buffer(
        3U,
        light_probes_binding,
        size=@pbr_light_probe.LIGHT_PROBES_UNIFORM_SIZE_BYTES.to_uint64(),
      ) &&
      z_slicing_builder.add_buffer(4U, decals_buffer) &&
      z_slicing_builder.add_buffer(5U, lights_binding) &&
      z_slicing_builder.add_buffer(
        6U,
        view_binding,
        size=@render_view.VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
      )
    if !z_slicing_ok {
      z_slicing_builder.free()
      abort("prepare_clustering_bind_groups: failed to build z slicing group")
    }
    let count_builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
    let count_ok = count_builder.add_buffer(0U, z_slices_buffer) &&
      count_builder.add_buffer(1U, clusterable_object_index_lists) &&
      count_builder.add_buffer(2U, gpu_clustered_lights_binding) &&
      count_builder.add_buffer(
        3U,
        light_probes_binding,
        size=@pbr_light_probe.LIGHT_PROBES_UNIFORM_SIZE_BYTES.to_uint64(),
      ) &&
      count_builder.add_buffer(4U, decals_buffer) &&
      count_builder.add_buffer(5U, lights_binding) &&
      count_builder.add_buffer(
        6U,
        view_binding,
        size=@render_view.VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
      ) &&
      count_builder.add_buffer(7U, cluster_offsets_and_counts)
    if !count_ok {
      count_builder.free()
      abort("prepare_clustering_bind_groups: failed to build count group")
    }
    let allocation_builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let allocation_ok = allocation_builder.add_buffer(
        0U, cluster_offsets_and_counts,
      ) &&
      allocation_builder.add_buffer(1U, lights_binding) &&
      allocation_builder.add_buffer(2U, cluster_metadata_buffer) &&
      allocation_builder.add_buffer(3U, scratchpad_offsets_and_counts_buffer)
    if !allocation_ok {
      allocation_builder.free()
      abort("prepare_clustering_bind_groups: failed to build allocation group")
    }
    let populate_builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
    let populate_ok = populate_builder.add_buffer(0U, z_slices_buffer) &&
      populate_builder.add_buffer(1U, clusterable_object_index_lists) &&
      populate_builder.add_buffer(2U, gpu_clustered_lights_binding) &&
      populate_builder.add_buffer(
        3U,
        light_probes_binding,
        size=@pbr_light_probe.LIGHT_PROBES_UNIFORM_SIZE_BYTES.to_uint64(),
      ) &&
      populate_builder.add_buffer(4U, decals_buffer) &&
      populate_builder.add_buffer(5U, lights_binding) &&
      populate_builder.add_buffer(
        6U,
        view_binding,
        size=@render_view.VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
      ) &&
      populate_builder.add_buffer(7U, cluster_offsets_and_counts) &&
      populate_builder.add_buffer(8U, scratchpad_offsets_and_counts_buffer)
    if !populate_ok {
      populate_builder.free()
      abort("prepare_clustering_bind_groups: failed to build populate group")
    }
    let z_slicing_bind_group = gpu_clustering_finish_bind_group_or_abort(
      z_slicing_builder, device, z_slicing_layout, "clustering Z slicing pass bind group",
    )
    let count_bind_group = gpu_clustering_finish_bind_group_or_abort(
      count_builder, device, count_layout, "clustering count pass bind group",
    )
    let allocation_bind_group = gpu_clustering_finish_bind_group_or_abort(
      allocation_builder, device, allocation_layout, "clustering allocate pass bind group",
    )
    let populate_bind_group = gpu_clustering_finish_bind_group_or_abort(
      populate_builder, device, populate_layout, "clustering populate pass bind group",
    )
    world.set_by_key(
      view_entity,
      ViewClusteringBindGroups::component(),
      ViewClusteringBindGroups::new(
        z_slicing_bind_group, count_bind_group, allocation_bind_group, populate_bind_group,
      ),
    ) catch {
      _ =>
        abort(
          "prepare_clustering_bind_groups: failed to insert clustering bind groups",
        )
    }
  })
}

///|
pub fn prepare_cluster_dummy_textures(world : @ecs.World) -> Unit {
  let render_device = gpu_clustering_resource_or_abort(
    world, @render.render_device_resource_key, "RenderDevice",
  )
  let texture_cache = gpu_clustering_resource_or_abort(
    world,
    @render_texture.TextureCache::resource(),
    "TextureCache",
  )
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    match
      (world.get_by_key(view_entity, ExtractedClusterConfig::component()) catch {
        _ =>
          abort("prepare_cluster_dummy_textures: failed to read cluster config")
      }) {
      Some(view_cluster_config) => {
        let dimensions = view_cluster_config.dimensions()
        let dummy_texture = texture_cache.get(
          render_device,
          @render_texture.TextureCacheDescriptor::new(
            label=Some("clustering dummy texture"),
            width=gpu_clustering_next_multiple_of(dimensions.0, 32),
            height=gpu_clustering_next_multiple_of(dimensions.1, 32),
            depth_or_array_layers=1,
            mip_level_count=1,
            sample_count=1,
            dimension_raw=@wgpu.TEXTURE_DIMENSION_2D,
            format_raw=@wgpu.TEXTURE_FORMAT_R8_UNORM,
            usage_bits=@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
              @wgpu.TEXTURE_USAGE_COPY_DST,
          ),
        )
        world.set_by_key(
          view_entity,
          ViewClusteringDummyTexture::component(),
          ViewClusteringDummyTexture::new(dummy_texture),
        ) catch {
          _ =>
            abort(
              "prepare_cluster_dummy_textures: failed to insert dummy texture",
            )
        }
      }
      None => ()
    }
  })
}

///|
pub fn prepare_clustering_pipelines(world : @ecs.World) -> Unit {
  let pipeline_cache = gpu_clustering_resource_or_abort(
    world, @render.pipeline_cache_resource_key, "PipelineCache",
  )
  let clustering_z_slicing_pipelines = gpu_clustering_resource_or_abort(
    world,
    SpecializedClusteringZSlicingPipelines::resource(),
    "SpecializedComputePipelines<ClusteringZSlicingPipeline>",
  )
  let clustering_raster_pipelines = gpu_clustering_resource_or_abort(
    world,
    SpecializedClusteringRasterPipelines::resource(),
    "SpecializedRenderPipelines<ClusteringRasterPipeline>",
  )
  let clustering_allocation_pipelines = gpu_clustering_resource_or_abort(
    world,
    SpecializedClusteringAllocationPipelines::resource(),
    "SpecializedComputePipelines<ClusteringAllocationPipeline>",
  )
  let clustering_z_slicing_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringZSlicingPipeline::resource(),
    "ClusteringZSlicingPipeline",
  )
  let clustering_raster_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringRasterPipeline::resource(),
    "ClusteringRasterPipeline",
  )
  let clustering_allocation_pipeline = gpu_clustering_resource_or_abort(
    world,
    ClusteringAllocationPipeline::resource(),
    "ClusteringAllocationPipeline",
  )
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    let clustering_z_slicing_pipeline_id = clustering_z_slicing_pipelines.queue(
      pipeline_cache, clustering_z_slicing_pipeline,
    )
    let clustering_count_pipeline_id = clustering_raster_pipelines.queue(
      pipeline_cache,
      clustering_raster_pipeline,
      ClusteringRasterPipelineKey::count_pass(),
    )
    let clustering_local_allocation_pipeline_id = clustering_allocation_pipelines.queue(
      pipeline_cache,
      clustering_allocation_pipeline,
      ClusteringAllocationPipelineKey::local_pass(),
    )
    let clustering_global_allocation_pipeline_id = clustering_allocation_pipelines.queue(
      pipeline_cache,
      clustering_allocation_pipeline,
      ClusteringAllocationPipelineKey::new_global_pass(),
    )
    let clustering_populate_pipeline_id = clustering_raster_pipelines.queue(
      pipeline_cache,
      clustering_raster_pipeline,
      ClusteringRasterPipelineKey::new_populate_pass(),
    )
    world.set_by_key(
      view_entity,
      ViewGpuClusteringPipelineIds::component(),
      ViewGpuClusteringPipelineIds::new(
        clustering_z_slicing_pipeline_id, clustering_count_pipeline_id, clustering_local_allocation_pipeline_id,
        clustering_global_allocation_pipeline_id, clustering_populate_pipeline_id,
      ),
    ) catch {
      _ => abort("prepare_clustering_pipelines: failed to insert pipeline ids")
    }
  })
}

///|
fn gpu_clustering_register_embedded_assets() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/cluster/cluster.wgsl", pbr_cluster_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/cluster/cluster_allocate.wgsl", pbr_cluster_allocate_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/cluster/cluster_raster.wgsl", pbr_cluster_raster_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/cluster/cluster_z_slice.wgsl", pbr_cluster_z_slice_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/cluster/cluster.wgsl",
    @asset.asset_text_to_bytes(pbr_cluster_wgsl_source),
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/cluster/cluster_allocate.wgsl",
    @asset.asset_text_to_bytes(pbr_cluster_allocate_wgsl_source),
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/cluster/cluster_raster.wgsl",
    @asset.asset_text_to_bytes(pbr_cluster_raster_wgsl_source),
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/cluster/cluster_z_slice.wgsl",
    @asset.asset_text_to_bytes(pbr_cluster_z_slice_wgsl_source),
  )
}

///|
pub fn gpu_clustering_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GpuClusteringPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  gpu_clustering_register_embedded_assets()
  let extract_plugin : @render.ExtractResourcePlugin[
    @light_cluster.GlobalClusterSettings,
    GpuClusteringPlugin,
  ] = @render.ExtractResourcePlugin::ExtractResourcePlugin()
  @render.extract_resource_plugin_with(app, extract_plugin)
}

///|
pub impl @app.Plugin for GpuClusteringPlugin with fn name(_self) {
  GPU_CLUSTERING_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GpuClusteringPlugin with fn build(self, app) {
  gpu_clustering_plugin_with(app, self)
}

///|
fn[T] gpu_clustering_init_render_resource_if_missing(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  init : () -> T,
) -> Unit {
  if world.get_resource(key) is None {
    world.insert_resource(key, init())
  }
}

///|
fn gpu_clustering_configure_render_app_finish(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let render_world = sub_app.world()
  let render_device : @renderer.RenderDevice = match
    render_world.get_resource(@render.render_device_resource_key) {
    Some(device) => device
    None => return sub_app
  }
  if render_device.limits_max_storage_buffers_per_shader_stage_u32() == 0U {
    return sub_app
  }
  let graph_stage = @render.RenderGraph::schedule()
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    SpecializedClusteringRasterPipelines::resource(),
    fn() {
      SpecializedClusteringRasterPipelines::SpecializedClusteringRasterPipelines()
    },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    SpecializedClusteringZSlicingPipelines::resource(),
    fn() {
      SpecializedClusteringZSlicingPipelines::SpecializedClusteringZSlicingPipelines()
    },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    SpecializedClusteringAllocationPipelines::resource(),
    fn() {
      SpecializedClusteringAllocationPipelines::SpecializedClusteringAllocationPipelines()
    },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    RenderViewClusteringReadbackData::resource(),
    fn() {
      RenderViewClusteringReadbackData::RenderViewClusteringReadbackData()
    },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    GpuClusteringMeshBuffers::resource(),
    fn() { GpuClusteringMeshBuffers::GpuClusteringMeshBuffers(render_device) },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    ClusteringRasterPipeline::resource(),
    fn() { ClusteringRasterPipeline::ClusteringRasterPipeline() },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    ClusteringZSlicingPipeline::resource(),
    fn() { ClusteringZSlicingPipeline::ClusteringZSlicingPipeline() },
  )
  gpu_clustering_init_render_resource_if_missing(
    render_world,
    ClusteringAllocationPipeline::resource(),
    fn() { ClusteringAllocationPipeline::ClusteringAllocationPipeline() },
  )
  sub_app
  .add_systems(
    @render.render_schedule_stage(),
    @app.chain(
      (
        @app.system(prepare_clusters_for_gpu_clustering),
        @app.system(upload_view_gpu_clustering_buffers),
      ),
    )
    .in_set(@render.render_system_set_prepare_resources)
    .run_if(gpu_clustering_is_enabled),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_cluster_dummy_textures)
    .in_set(@render.render_system_set_prepare)
    .run_if(gpu_clustering_is_enabled),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_clustering_pipelines)
    .in_set(@render.render_system_set_prepare)
    .run_if(gpu_clustering_is_enabled),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_clustering_bind_groups)
    .in_set(@render.render_system_set_prepare_bind_groups)
    .run_if(gpu_clustering_is_enabled),
  )
  .add_systems(
    graph_stage,
    @app.system(cluster_on_gpu)
    .named("mgstudio_pbr::cluster_on_gpu")
    .in_set(@core_pipeline.core3d_system_set_prepass())
    .run_if(gpu_clustering_is_enabled),
  )
}

///|
pub impl @app.Plugin for GpuClusteringPlugin with fn finish(_self, app) {
  @render.try_with_render_app(app, gpu_clustering_configure_render_app_finish)
}
