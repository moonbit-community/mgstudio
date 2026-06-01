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
pub struct GpuTextureInfo {
  id : Int
  width : Int
  height : Int
  mip_level_count : Int
  base_mip_level : Int
  format : @wgpu.TextureFormat
  texture : @wgpu.Texture
  view : @wgpu.TextureView
  sample_view : @wgpu.TextureView?
  layer_views : Array[@wgpu.TextureView]
  sampler : @wgpu.Sampler
  bind_group : @wgpu.BindGroup
}

///|
pub struct GpuMeshInfo {
  id : Int
  index_count : UInt
  vertex_count : UInt
  index_start : UInt
  vertex_start : UInt
  index_slab_id : Int
  vertex_slab_id : Int
  primitive_topology : UInt
  vertex_stride_bytes : UInt64
  mesh_vertex_layout : @mesh.MeshVertexBufferLayout?
  vertex_layout : @mesh.VertexBufferLayout?
  index_stride_bytes : UInt64
  uses_u32_indices : Bool
  vertex_buf : @wgpu.Buffer
  index_buf : @wgpu.Buffer
}

///|
struct GpuMeshAllocatorBuffer {
  slab_id : Int
  usage_kind : Int
  buffer : @wgpu.Buffer
}

///|
pub struct SpriteBatch {
  texture_id : Int
  first_instance : UInt
  mut instance_count : UInt
}

///|
pub struct UiBatch {
  texture_id : Int
  first_instance : UInt
  mut instance_count : UInt
  anti_alias : Bool
}

///|
pub struct UiShadowBatch {
  first_instance : UInt
  mut instance_count : UInt
  samples : Int
}

///|
pub struct UiShadowPipelineCacheEntry {
  format : @wgpu.TextureFormat
  samples : Int
  pipeline : @wgpu.RenderPipeline
}

///|
struct GpuStorageSlot {
  buffer : @wgpu.Buffer
  bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh3dMaterialBindGroupCacheEntry {
  material_pipeline_id : UInt64
  base_texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  anisotropy_texture_id : Int
  specular_tint_texture_id : Int
  material_uniform_bytes : Bytes
  material_uniform_buffer : @wgpu.Buffer
  bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh3dMaterialPipelineLayoutCacheEntry {
  material_pipeline_id : UInt64
  view_layout_key_bits : UInt
  view_bind_group_layout_descriptor : @render_resource.BindGroupLayoutDescriptor
  view_bind_group_layout : @wgpu.BindGroupLayout
  binding_arrays_bind_group_layout_descriptor : @render_resource.BindGroupLayoutDescriptor
  binding_arrays_bind_group_layout : @wgpu.BindGroupLayout
  draw_bind_group_layout_descriptor : @render_resource.BindGroupLayoutDescriptor
  draw_bind_group_layout : @wgpu.BindGroupLayout
  material_bind_group_layout : @wgpu.BindGroupLayout
  pipeline_layout : @wgpu.PipelineLayout
}

///|
pub struct Mesh3dViewBindGroupCacheEntry {
  material_pipeline_id : UInt64
  tonemap_in_shader : Bool
  transmission_source_texture_id : Int
  point_shadow_texture_id : Int
  directional_shadow_texture_id : Int
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  tonemapping_lut_texture_id : Int
  bind_group : @wgpu.BindGroup
  binding_arrays_bind_group : @wgpu.BindGroup
}

///|
struct Mesh3dPassUniformState {
  frame_count : UInt
  camera_key_hi : Int
  camera_key_lo : Int
  pass_kind : Int
  view_buffer : @wgpu.Buffer
  lights_buffer : @wgpu.Buffer
  mut shadow_view_bind_group : @wgpu.BindGroup?
}

///|
struct Mesh3dFrameViewBindGroupCacheEntry {
  material_pipeline_id : UInt64
  tonemap_in_shader : Bool
  frame_count : UInt
  camera_key_hi : Int
  camera_key_lo : Int
  pass_kind : Int
  transmission_source_texture_id : Int
  point_shadow_texture_id : Int
  directional_shadow_texture_id : Int
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  tonemapping_lut_texture_id : Int
  bind_group : @wgpu.BindGroup
  binding_arrays_bind_group : @wgpu.BindGroup
}

///|
struct Mesh3dMotionVectorViewBindGroupCacheEntry {
  material_pipeline_id : UInt64
  frame_count : UInt
  view_bind_group : @wgpu.BindGroup
  empty_bind_group : @wgpu.BindGroup
  empty_material_bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh2dPipelineCacheEntry {
  key : String
  pipeline : @wgpu.RenderPipeline
}

///|
pub struct Mesh2dRegisteredPipelineDescriptor {
  pipeline_id : UInt64
  shader_path : String
}

///|
pub struct Mesh2dMaterialLayoutCacheEntry {
  key : Array[(UInt, Int)]
  bind_group_layout : @wgpu.BindGroupLayout
  pipeline_layout : @wgpu.PipelineLayout
}

///|
struct Mesh2dMaterialBindGroupCacheEntry {
  key : Array[HostMaterial2dBinding]
  bind_group : @wgpu.BindGroup
  uniform_buffers : Array[@wgpu.Buffer]
}

///|
pub struct TonemappingPipelineCacheEntry {
  key : String
  state : RenderPipelineCacheState
}

///|
struct GpuMesh3dPreprocessCameraUploadState {
  key_hi : Int
  key_lo : Int
  mut mesh_input_buffer : @wgpu.Buffer?
  mut mesh_input_capacity : UInt64
  mut previous_mesh_input_buffer : @wgpu.Buffer?
  mut previous_mesh_input_capacity : UInt64
  mut output_buffer : @wgpu.Buffer?
  mut output_capacity : UInt64
  mut output_count : Int
  mut motion_vector_mesh_bind_group : @wgpu.BindGroup?
  mut motion_vector_mesh_bind_group_skin_revision : Int
  mut motion_vector_mesh_bind_group_morph_revision : Int
  mut motion_vector_mesh_bind_group_morph_target_texture_id : Int
  mut motion_vector_mesh_bind_group_layout_mask : Int
  mut preprocess_main_direct_bind_group : @wgpu.BindGroup?
  mut preprocess_main_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_main_non_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_early_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_early_non_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_late_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_late_non_indexed_bind_group : @wgpu.BindGroup?
  mut build_indirect_reset_indexed_bind_group : @wgpu.BindGroup?
  mut build_indirect_reset_non_indexed_bind_group : @wgpu.BindGroup?
  mut build_indirect_indexed_bind_group : @wgpu.BindGroup?
  mut build_indirect_non_indexed_bind_group : @wgpu.BindGroup?
  mut preprocess_view_buffer : @wgpu.Buffer?
  mut preprocess_view_capacity : UInt64
  mut previous_view_buffer : @wgpu.Buffer?
  mut previous_view_capacity : UInt64
  mut mesh_culling_data_buffer : @wgpu.Buffer?
  mut mesh_culling_data_capacity : UInt64
  mut direct_work_item_buffer : @wgpu.Buffer?
  mut direct_work_item_capacity : UInt64
  mut direct_work_item_count : Int
  mut indexed_work_item_buffer : @wgpu.Buffer?
  mut indexed_work_item_capacity : UInt64
  mut indexed_work_item_count : Int
  mut non_indexed_work_item_buffer : @wgpu.Buffer?
  mut non_indexed_work_item_capacity : UInt64
  mut non_indexed_work_item_count : Int
  mut late_indexed_work_item_buffer : @wgpu.Buffer?
  mut late_indexed_work_item_capacity : UInt64
  mut late_indexed_work_item_count : Int
  mut late_non_indexed_work_item_buffer : @wgpu.Buffer?
  mut late_non_indexed_work_item_capacity : UInt64
  mut late_non_indexed_work_item_count : Int
  mut late_indexed_dispatch_indirect_buffer : @wgpu.Buffer?
  mut late_indexed_dispatch_indirect_capacity : UInt64
  mut late_non_indexed_dispatch_indirect_buffer : @wgpu.Buffer?
  mut late_non_indexed_dispatch_indirect_capacity : UInt64
  mut indexed_cpu_metadata_buffer : @wgpu.Buffer?
  mut indexed_cpu_metadata_capacity : UInt64
  mut indexed_gpu_metadata_buffer : @wgpu.Buffer?
  mut indexed_gpu_metadata_capacity : UInt64
  mut indexed_gpu_metadata_count : Int
  mut indexed_batch_set_buffer : @wgpu.Buffer?
  mut indexed_batch_set_capacity : UInt64
  mut indexed_batch_set_count : Int
  mut indexed_indirect_parameters_buffer : @wgpu.Buffer?
  mut indexed_indirect_parameters_capacity : UInt64
  mut non_indexed_cpu_metadata_buffer : @wgpu.Buffer?
  mut non_indexed_cpu_metadata_capacity : UInt64
  mut non_indexed_gpu_metadata_buffer : @wgpu.Buffer?
  mut non_indexed_gpu_metadata_capacity : UInt64
  mut non_indexed_gpu_metadata_count : Int
  mut non_indexed_batch_set_buffer : @wgpu.Buffer?
  mut non_indexed_batch_set_capacity : UInt64
  mut non_indexed_batch_set_count : Int
  mut non_indexed_indirect_parameters_buffer : @wgpu.Buffer?
  mut non_indexed_indirect_parameters_capacity : UInt64
  mut dispatch_metadata_buffer : @wgpu.Buffer?
  mut dispatch_metadata_capacity : UInt64
  mut direct_workgroup_count : Int
  mut indexed_workgroup_count : Int
  mut non_indexed_workgroup_count : Int
  mut depth_pyramid_texture : @wgpu.Texture?
  mut depth_pyramid_all_mips_view : @wgpu.TextureView?
  mut depth_pyramid_mips : Array[@wgpu.TextureView]
  mut depth_pyramid_width : Int
  mut depth_pyramid_height : Int
  mut depth_pyramid_mip_count : Int
}

///|
struct CustomPostProcessPipelineCacheEntry {
  shader_path : String
  fragment_entry : String
  surface_format : @wgpu.TextureFormat
  pipeline : @wgpu.RenderPipeline
}

///|
struct CasPipelineCacheEntry {
  surface_format : @wgpu.TextureFormat
  denoise : Bool
  pipeline : @wgpu.RenderPipeline
}
