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
pub(all) struct PreparedSkinBinding3d {
  entity_generation : Int
  key_hi : Int
  key_lo : Int
}

///|
pub(all) struct MeshPreprocessStatic3d {
  topology_kind : Int
  is_indexed : Bool
  first_vertex_index : Int
  first_index_index : Int
  index_count : Int
  has_local_aabb : Bool
  aabb_center : @math.Vec3
  aabb_half_extents : @math.Vec3
}

///|
pub(all) struct GpuPreprocessPhaseRange3d {
  phase : Int
  start : Int
  end : Int
}

///|
pub(all) struct GpuPreprocessIndirectParametersCpuMetadata3d {
  base_output_index : Int
  batch_set_index : Int
}

///|
pub(all) struct GpuPreprocessIndirectParametersGpuMetadata3d {
  mesh_index : Int
  early_instance_count : Int
  late_instance_count : Int
}

///|
pub(all) struct GpuPreprocessIndirectBatchSet3d {
  indirect_parameters_count : Int
  indirect_parameters_base : Int
}

///|
pub(all) struct GpuPreprocessIndirectMeshClassMetadata3d {
  indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ]
  indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ]
  indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d]
}

///|
pub(all) struct GpuPreprocessIndirectMetadata3d {
  indexed : GpuPreprocessIndirectMeshClassMetadata3d
  non_indexed : GpuPreprocessIndirectMeshClassMetadata3d
}

///|
pub(all) struct GpuPreprocessShaderWorkItem3d {
  input_index : Int
  output_or_indirect_parameters_index : Int
}

///|
pub(all) struct GpuOcclusionCullingWorkItemBuffers3d {
  enabled : Bool
}

///|
pub(all) enum GpuPreprocessWorkItemBuffers3d {
  Direct(Array[GpuPreprocessShaderWorkItem3d])
  Indirect(
    Array[GpuPreprocessShaderWorkItem3d],
    Array[GpuPreprocessShaderWorkItem3d],
    GpuOcclusionCullingWorkItemBuffers3d?
  )
}

///|
pub const RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE : Int = 64

///|
pub(all) struct GpuPreprocessDispatchMetadata3d {
  direct_workgroup_count : Int
  indexed_workgroup_count : Int
  non_indexed_workgroup_count : Int
  late_indexed_workgroup_count : Int
  late_non_indexed_workgroup_count : Int
}
