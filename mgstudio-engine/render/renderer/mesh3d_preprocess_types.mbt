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
pub(all) struct HostMesh3dPreprocessShaderWorkItem {
  input_index : Int
  output_or_indirect_parameters_index : Int
}

///|
pub(all) struct HostMesh3dPreprocessMeshInput {
  translation_x : Float
  translation_y : Float
  translation_z : Float
  rotation_x : Float
  rotation_y : Float
  rotation_z : Float
  rotation_w : Float
  scale_x : Float
  scale_y : Float
  scale_z : Float
  previous_translation_x : Float
  previous_translation_y : Float
  previous_translation_z : Float
  previous_rotation_x : Float
  previous_rotation_y : Float
  previous_rotation_z : Float
  previous_rotation_w : Float
  previous_scale_x : Float
  previous_scale_y : Float
  previous_scale_z : Float
  flags : UInt
  first_vertex_index : Int
  first_index_index : Int
  index_count : Int
  tag : Int
}

///|
pub(all) struct HostMesh3dPreprocessFrustumPlane {
  normal_x : Float
  normal_y : Float
  normal_z : Float
  distance : Float
}

///|
pub(all) struct HostMesh3dPreprocessView {
  clip_from_world : GpuClipMatrix
  unjittered_clip_from_world : GpuClipMatrix
  world_from_clip : GpuClipMatrix
  world_from_view : GpuClipMatrix
  view_from_world : GpuClipMatrix
  clip_from_view : GpuClipMatrix
  view_from_clip : GpuClipMatrix
  world_position_x : Float
  world_position_y : Float
  world_position_z : Float
  exposure : Float
  viewport_x : Float
  viewport_y : Float
  viewport_width : Float
  viewport_height : Float
  main_pass_viewport_x : Float
  main_pass_viewport_y : Float
  main_pass_viewport_width : Float
  main_pass_viewport_height : Float
  frustum_planes : Array[HostMesh3dPreprocessFrustumPlane]
  mip_bias : Float
}

///|
pub(all) struct HostMesh3dPreprocessPreviousView {
  view_from_world : GpuClipMatrix
  clip_from_world : GpuClipMatrix
  clip_from_view : GpuClipMatrix
  world_from_clip : GpuClipMatrix
  view_from_clip : GpuClipMatrix
}

///|
pub(all) struct HostMesh3dPreprocessMeshCullingData {
  aabb_center_x : Float
  aabb_center_y : Float
  aabb_center_z : Float
  aabb_half_extents_x : Float
  aabb_half_extents_y : Float
  aabb_half_extents_z : Float
}

///|
pub(all) struct HostMesh3dPreprocessIndirectParametersCpuMetadata {
  base_output_index : Int
  batch_set_index : Int
}

///|
pub(all) struct HostMesh3dPreprocessIndirectParametersGpuMetadata {
  mesh_index : Int
  early_instance_count : Int
  late_instance_count : Int
}

///|
pub(all) struct HostMesh3dPreprocessIndirectBatchSet {
  indirect_parameters_count : Int
  indirect_parameters_base : Int
}

///|
pub(all) struct HostMesh3dPreprocessDispatchMetadata {
  direct_workgroup_count : Int
  indexed_workgroup_count : Int
  non_indexed_workgroup_count : Int
  late_indexed_workgroup_count : Int
  late_non_indexed_workgroup_count : Int
}

///|
pub(all) struct HostMesh3dPreprocessCameraPayload {
  view : HostMesh3dPreprocessView
  previous_view : HostMesh3dPreprocessPreviousView
  mesh_culling_data : Array[HostMesh3dPreprocessMeshCullingData]
  mesh_inputs : Array[HostMesh3dPreprocessMeshInput]
  direct_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  non_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  late_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  late_non_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  indexed_cpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ]
  indexed_gpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ]
  indexed_batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet]
  non_indexed_cpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ]
  non_indexed_gpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ]
  non_indexed_batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet]
  dispatch_metadata : HostMesh3dPreprocessDispatchMetadata
}

///|
pub const MESH3D_PREPROCESS_PHASE_MAIN : Int = 0

///|
pub const MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION : Int = 1

///|
pub const MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION : Int = 2

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_MAIN : Int = 0

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_EARLY : Int = 1

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_LATE : Int = 2

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_OCCLUSION_MAIN : Int = 3
