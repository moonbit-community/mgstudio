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
  msaa_texture : @wgpu.Texture?
  msaa_view : @wgpu.TextureView?
  sample_count : Int
  layer_views : Array[@wgpu.TextureView]
  sampler : @wgpu.Sampler
  bind_group : @wgpu.BindGroup?
}

///|
struct GpuPrepassDepthTextureInfo {
  id : Int
  width : Int
  height : Int
  sample_count : Int
  texture : @wgpu.Texture
  view : @wgpu.TextureView
}

///|
struct GpuMesh3dMorphTargetBufferInfo {
  id : Int
  buffer : @wgpu.Buffer
  byte_size : UInt64
  vertex_count : Int
  weight_count : Int
}

///|
struct GpuMesh3dInstanceVertexBufferInfo {
  id : Int
  buffer : @wgpu.Buffer
  byte_size : UInt64
  length : Int
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
  specular_texture_id : Int
  specular_tint_texture_id : Int
  clearcoat_texture_id : Int
  clearcoat_roughness_texture_id : Int
  clearcoat_normal_texture_id : Int
  material_uniform_bytes : Bytes
  material_uniform_buffer : @wgpu.Buffer
  forward_decal_uniform_bytes : Bytes
  forward_decal_uniform_buffer : @wgpu.Buffer?
  material_extension_bind_group_data : @render_resource.MaterialBindGroupResolvedData
  material_extension_uniform_buffers : Array[@wgpu.Buffer]
  bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh3dMaterialPipelineLayoutCacheEntry {
  material_pipeline_id : UInt64
  view_layout_key_bits : UInt
  draw_layout_lightmapped : Bool
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
  view_layout_key_bits : UInt
  tonemap_in_shader : Bool
  transmission_source_texture_id : Int
  point_shadow_texture_id : Int
  directional_shadow_texture_id : Int
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  environment_texture_ids_signature : String
  irradiance_volume_texture_ids_signature : String
  prepass_depth_texture_id : Int
  prepass_normal_texture_id : Int
  prepass_motion_vector_texture_id : Int
  prepass_deferred_texture_id : Int
  tonemapping_lut_texture_id : Int
  pbr_blue_noise_texture_id : Int
  pbr_area_light_luts_texture_id : Int
  pbr_dfg_lut_texture_id : Int
  atmosphere_resource_revision : Int
  ssao_resource_revision : Int
  clustered_decals_revision : Int
  bind_group : @wgpu.BindGroup
  main_offsets : Array[UInt]
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
  view_layout_key_bits : UInt
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
  environment_texture_ids_signature : String
  irradiance_volume_texture_ids_signature : String
  prepass_depth_texture_id : Int
  prepass_normal_texture_id : Int
  prepass_motion_vector_texture_id : Int
  prepass_deferred_texture_id : Int
  tonemapping_lut_texture_id : Int
  pbr_blue_noise_texture_id : Int
  pbr_area_light_luts_texture_id : Int
  pbr_dfg_lut_texture_id : Int
  atmosphere_resource_revision : Int
  ssao_resource_revision : Int
  clustered_decals_revision : Int
  bind_group : @wgpu.BindGroup
  main_offsets : Array[UInt]
  binding_arrays_bind_group : @wgpu.BindGroup
}

///|
struct GpuSsaoResources {
  width : Int
  height : Int
  depth_format : @wgpu.TextureFormat
  preprocessed_depth_texture : @wgpu.Texture
  preprocessed_depth_view : @wgpu.TextureView
  preprocessed_depth_mip_views : Array[@wgpu.TextureView]
  ssao_noisy_texture : @wgpu.Texture
  ssao_noisy_view : @wgpu.TextureView
  screen_space_ambient_occlusion_texture : @wgpu.Texture
  screen_space_ambient_occlusion_view : @wgpu.TextureView
  depth_differences_texture : @wgpu.Texture
  depth_differences_view : @wgpu.TextureView
  thickness_buffer : @wgpu.Buffer
  constant_object_thickness : Float
  revision : Int
}

///|
struct GpuSsaoPipelines {
  common_bind_group_layout : @wgpu.BindGroupLayout
  preprocess_depth_bind_group_layout : @wgpu.BindGroupLayout
  ssao_bind_group_layout : @wgpu.BindGroupLayout
  spatial_denoise_bind_group_layout : @wgpu.BindGroupLayout
  preprocess_depth_pipeline_layout : @wgpu.PipelineLayout
  ssao_pipeline_layout : @wgpu.PipelineLayout
  spatial_denoise_pipeline_layout : @wgpu.PipelineLayout
  preprocess_depth_pipeline : @wgpu.ComputePipeline
  spatial_denoise_pipeline : @wgpu.ComputePipeline
  hilbert_index_lut_texture : @wgpu.Texture
  hilbert_index_lut_view : @wgpu.TextureView
  point_clamp_sampler : @wgpu.Sampler
  linear_clamp_sampler : @wgpu.Sampler
  depth_format : @wgpu.TextureFormat
}

///|
struct GpuSsaoPipelineCacheEntry {
  quality_level : Int
  slice_count : Int
  samples_per_slice_side : Int
  temporal_jitter : Bool
  pipeline : @wgpu.ComputePipeline
}

///|
struct GpuTaaHistoryTextures {
  camera_key_hi : Int
  camera_key_lo : Int
  width : Int
  height : Int
  format : @wgpu.TextureFormat
  texture_0 : @wgpu.Texture
  view_0 : @wgpu.TextureView
  texture_1 : @wgpu.Texture
  view_1 : @wgpu.TextureView
  mut next_write_index : Int
}

///|
struct GpuTaaPipelineCacheEntry {
  format : @wgpu.TextureFormat
  tonemap : Bool
  reset : Bool
  pipeline : @wgpu.RenderPipeline
}

///|
struct GpuAtmosphereResources {
  transmittance_texture : @wgpu.Texture
  transmittance_view : @wgpu.TextureView
  multiscattering_texture : @wgpu.Texture
  multiscattering_view : @wgpu.TextureView
  sky_view_texture : @wgpu.Texture
  sky_view_view : @wgpu.TextureView
  aerial_view_texture : @wgpu.Texture
  aerial_view_view : @wgpu.TextureView
  sampler : @wgpu.Sampler
  atmosphere_buffer : @wgpu.Buffer
  settings_buffer : @wgpu.Buffer
  transform_buffer : @wgpu.Buffer
  transmittance_lut_bgl : @wgpu.BindGroupLayout
  transmittance_lut_pipeline_layout : @wgpu.PipelineLayout
  transmittance_lut_pipeline : @wgpu.ComputePipeline
  multiscattering_lut_bgl : @wgpu.BindGroupLayout
  multiscattering_lut_pipeline_layout : @wgpu.PipelineLayout
  multiscattering_lut_pipeline : @wgpu.ComputePipeline
  sky_view_lut_bgl : @wgpu.BindGroupLayout
  sky_view_lut_pipeline_layout : @wgpu.PipelineLayout
  sky_view_lut_pipeline : @wgpu.ComputePipeline
  aerial_view_lut_bgl : @wgpu.BindGroupLayout
  aerial_view_lut_pipeline_layout : @wgpu.PipelineLayout
  aerial_view_lut_pipeline : @wgpu.ComputePipeline
  environment_bgl : @wgpu.BindGroupLayout
  environment_pipeline : @wgpu.ComputePipeline
  render_sky_bgl : @wgpu.BindGroupLayout
  render_sky_pipeline_layout : @wgpu.PipelineLayout
  render_sky_pipeline : @wgpu.RenderPipeline
  render_sky_msaa_bgl : @wgpu.BindGroupLayout
  render_sky_msaa_pipeline_layout : @wgpu.PipelineLayout
  mut render_sky_msaa_pipeline : @wgpu.RenderPipeline?
  mut render_sky_msaa_sample_count : Int
  transmittance_width : Int
  transmittance_height : Int
  multiscattering_width : Int
  multiscattering_height : Int
  sky_view_width : Int
  sky_view_height : Int
  aerial_view_width : Int
  aerial_view_height : Int
  aerial_view_depth : Int
  revision : Int
}

///|
struct GpuDeferredLightingIdDepthTexture {
  width : Int
  height : Int
  texture : @wgpu.Texture
  view : @wgpu.TextureView
}

///|
struct GpuDeferredLightingPipelineCacheEntry {
  color_format : UInt
  view_layout_key_bits : UInt
  tonemap_in_shader : Bool
  tonemapping_mode : Int
  deband_dither_enabled : Bool
  shadow_filter_method : Int
  screen_space_ambient_occlusion : Bool
  screen_space_reflections : Bool
  distance_fog : Bool
  atmosphere : Bool
  pipeline_layout : @wgpu.PipelineLayout
  depth_id_bind_group_layout : @wgpu.BindGroupLayout
  pipeline : @wgpu.RenderPipeline
}

///|
struct GpuScreenSpaceReflectionsPipelineCacheEntry {
  color_format : UInt
  view_layout_key_bits : UInt
  atmosphere : Bool
  pipeline_layout : @wgpu.PipelineLayout
  bind_group_layout : @wgpu.BindGroupLayout
  pipeline : @wgpu.RenderPipeline
}

///|
struct GpuScatteringMediumResources {
  density_texture : @wgpu.Texture
  density_view : @wgpu.TextureView
  scattering_texture : @wgpu.Texture
  scattering_view : @wgpu.TextureView
  sampler : @wgpu.Sampler
  density_bytes : Bytes
  scattering_bytes : Bytes
  density_width : Int
  density_height : Int
  scattering_width : Int
  scattering_height : Int
  revision : Int
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
struct LineGizmoPipelineCacheEntry {
  key : String
  view_bind_group_layout : @wgpu.BindGroupLayout
  uniform_bind_group_layout : @wgpu.BindGroupLayout
  pipeline : @wgpu.RenderPipeline
}

///|
struct GpuQueuedLineGizmoDraw {
  phase_kind : Int
  render_layers_mask : Int
  shader_path : String
  vertex_entry : String
  fragment_entry : String
  shader_defs : Array[@render_resource.ShaderDefVal]
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout]
  depth_write_enabled : Bool
  depth_compare : UInt
  line_uniform_bytes : Bytes
  list_position_buffer : @wgpu.Buffer
  list_color_buffer : @wgpu.Buffer
  strip_position_buffer : @wgpu.Buffer
  strip_color_buffer : @wgpu.Buffer
  binding_buffer_kinds : Array[Int]
  binding_slots : Array[UInt]
  binding_offsets : Array[UInt64]
  binding_sizes : Array[UInt64]
  vertex_count : UInt
  instance_count : UInt
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
struct SkyboxPipelineCacheEntry {
  surface_format : @wgpu.TextureFormat
  samples : Int
  pipeline : @wgpu.RenderPipeline
}

///|
struct SkyboxPreparedBindGroupEntry {
  id : Int
  bind_group : @wgpu.BindGroup
  uniform_buffer : @wgpu.Buffer
}

///|
struct CasPipelineCacheEntry {
  surface_format : @wgpu.TextureFormat
  denoise : Bool
  pipeline : @wgpu.RenderPipeline
}
