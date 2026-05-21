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
pub(all) enum GpuClusteringStep {
  ZSlicing
  CountRasterization
  LocalAllocation
  GlobalAllocation
  PopulateRasterization
} derive(Eq, Debug)

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
