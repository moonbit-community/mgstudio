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
