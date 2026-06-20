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
  z_slice_list_capacity : Int
  max_index_list_capacity : Int
  last_frame_statistics : ViewClusteringLastFrameStatistics?
} derive(Eq, Debug)

///|
pub struct RenderViewClusteringReadbackData {
  views : Map[UInt64, ViewClusteringReadbackData]
}

///|
pub struct GpuClusteringMeshBuffers {
  vertices : Array[@math.Vec2]
  indices : Array[UInt]
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
pub fn ViewClusteringReadbackData::new(
  settings : @light_cluster.GlobalClusterGpuSettings,
) -> ViewClusteringReadbackData {
  ViewClusteringReadbackData::{
    z_slice_list_capacity: settings.initial_z_slice_list_capacity(),
    max_index_list_capacity: settings.initial_index_list_capacity(),
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
pub fn GpuClusteringMeshBuffers::GpuClusteringMeshBuffers() -> GpuClusteringMeshBuffers {
  GpuClusteringMeshBuffers::{
    vertices: [
      @math.Vec2::new(0.0, 0.0),
      @math.Vec2::new(1.0, 0.0),
      @math.Vec2::new(0.0, 1.0),
      @math.Vec2::new(1.0, 1.0),
    ],
    indices: [0U, 1U, 2U, 1U, 3U, 2U],
  }
}

///|
pub fn GpuClusteringMeshBuffers::vertices(
  self : GpuClusteringMeshBuffers,
) -> Array[@math.Vec2] {
  self.vertices.copy()
}

///|
pub fn GpuClusteringMeshBuffers::indices(
  self : GpuClusteringMeshBuffers,
) -> Array[UInt] {
  self.indices.copy()
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
pub fn gpu_clustering_is_enabled(world : @ecs.World) -> Bool {
  match world.get_resource(@light_cluster.GlobalClusterSettings::resource()) {
    Some(settings) => settings.gpu_clustering() is Some(_)
    None => false
  }
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
    fn() { GpuClusteringMeshBuffers::GpuClusteringMeshBuffers() },
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
  sub_app.add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_clustering_pipelines)
    .in_set(@render.render_system_set_prepare)
    .run_if(gpu_clustering_is_enabled),
  )
}

///|
pub impl @app.Plugin for GpuClusteringPlugin with fn finish(_self, app) {
  @render.try_with_render_app(app, gpu_clustering_configure_render_app_finish)
}
