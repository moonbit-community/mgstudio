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
/// Minimal native GPU backend for `mgstudio_host` built on `Milky2018/wgpu_mbt`.
///
/// This is intentionally small and incremental:
/// - supports surface frame begin/end + a single render pass
/// - supports textured sprite quads (alpha blending)
/// - supports solid-color mesh draw for rectangle/capsule meshes
///
/// Missing capabilities should be tracked in project issues and reported upstream.

///|
const MESH2D_VIEW_BUFFER_SIZE : UInt64 = 1024UL

///|
const MESH2D_GLOBALS_BUFFER_SIZE : UInt64 = 16UL

///|
const MESH2D_UNIFORM_STRIDE_BYTES : UInt64 = 96UL

///|
const MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES : UInt64 = 256UL

///|
const MESH3D_DRAW_STORAGE_STRIDE_BYTES : UInt64 = 208UL

///|
const MESH3D_VIEW_BUFFER_SIZE : UInt64 = 256UL

///|
const MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE : UInt64 = 320UL

///|
const MESH3D_PREPASS_GLOBALS_BUFFER_SIZE : UInt64 = 16UL

///|
const MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE : UInt64 = 16UL

///|
const MESH3D_PREPASS_MESH_BUFFER_SIZE : UInt64 = 176UL

///|
const MESH3D_PREPROCESS_VIEW_BUFFER_SIZE : UInt64 = 768UL

///|
const MESH3D_PREPROCESS_MESH_CULLING_DATA_STRIDE_BYTES : UInt64 = 32UL

///|
const MESH3D_VERTEX_STRIDE_BYTES : UInt64 = 48UL

///|
const BLOOM_UNIFORM_BUFFER_SIZE : UInt64 = 240UL

///|
pub struct GpuTextureInfo {
  id : Int
  width : Int
  height : Int
  mip_level_count : Int
  base_mip_level : Int
  format_raw : UInt
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
  primitive_topology : UInt
  vertex_stride_bytes : UInt64
  index_stride_bytes : UInt64
  uses_u32_indices : Bool
  vertex_buf : @wgpu.Buffer
  index_buf : @wgpu.Buffer
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
  base_texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  anisotropy_texture_id : Int
  specular_tint_texture_id : Int
  bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh2dPipelineCacheEntry {
  key : String
  pipeline : @wgpu.RenderPipeline
}

///|
pub struct Mesh2dMaterialLayoutCacheEntry {
  key : String
  bind_group_layout : @wgpu.BindGroupLayout
  pipeline_layout : @wgpu.PipelineLayout
}

///|
struct Mesh2dMaterialBindGroupCacheEntry {
  key : String
  bind_group : @wgpu.BindGroup
  uniform_buffers : Array[@wgpu.Buffer]
}

///|
pub struct TonemappingPipelineCacheEntry {
  key : String
  pipeline : @wgpu.RenderPipeline
}

///|
pub struct GpuClipMatrix {
  x_axis_x : Float
  x_axis_y : Float
  x_axis_z : Float
  x_axis_w : Float
  y_axis_x : Float
  y_axis_y : Float
  y_axis_z : Float
  y_axis_w : Float
  z_axis_x : Float
  z_axis_y : Float
  z_axis_z : Float
  z_axis_w : Float
  w_axis_x : Float
  w_axis_y : Float
  w_axis_z : Float
  w_axis_w : Float
}

///|
fn gpu_clip_matrix_identity() -> GpuClipMatrix {
  GpuClipMatrix::{
    x_axis_x: 1.0F,
    x_axis_y: 0.0F,
    x_axis_z: 0.0F,
    x_axis_w: 0.0F,
    y_axis_x: 0.0F,
    y_axis_y: 1.0F,
    y_axis_z: 0.0F,
    y_axis_w: 0.0F,
    z_axis_x: 0.0F,
    z_axis_y: 0.0F,
    z_axis_z: 1.0F,
    z_axis_w: 0.0F,
    w_axis_x: 0.0F,
    w_axis_y: 0.0F,
    w_axis_z: 0.0F,
    w_axis_w: 1.0F,
  }
}

///|
pub struct GpuPassState {
  target_id : Int
  target_layer : Int
  secondary_target_id : Int
  width_logical : Float
  height_logical : Float
  is_3d : Bool
  camera_x : Float
  camera_y : Float
  camera_rot : Float
  camera_scale : Float
  camera_z : Float
  camera_exposure : Float
  camera_rot_x : Float
  camera_rot_y : Float
  camera_rot_z : Float
  camera_rot_w : Float
  clip_from_world : GpuClipMatrix
  unjittered_clip_from_world : GpuClipMatrix
  previous_clip_from_world : GpuClipMatrix
  pass_kind : Int
  viewport_x : UInt
  viewport_y : UInt
  viewport_w : UInt
  viewport_h : UInt
  viewport_depth_min : Float
  viewport_depth_max : Float
  ambient_r : Float
  ambient_g : Float
  ambient_b : Float
  ambient_brightness : Float
  directional_dir_x : Float
  directional_dir_y : Float
  directional_dir_z : Float
  directional_color_r : Float
  directional_color_g : Float
  directional_color_b : Float
  directional_illuminance : Float
  point_pos_x : Float
  point_pos_y : Float
  point_pos_z : Float
  point_color_r : Float
  point_color_g : Float
  point_color_b : Float
  point_intensity : Float
  point_range : Float
  spot_pos_x : Float
  spot_pos_y : Float
  spot_pos_z : Float
  spot_dir_x : Float
  spot_dir_y : Float
  spot_dir_z : Float
  spot_color_r : Float
  spot_color_g : Float
  spot_color_b : Float
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
  point_shadow_near : Float
}

///|
pub struct GpuFrameState {
  surface_tex : @wgpu.SurfaceTexture
  surface_texture : @wgpu.Texture
  surface_view : @wgpu.TextureView
  encoder : @wgpu.CommandEncoder
  mut pass : @wgpu.RenderPass?
}

///|
pub struct GpuSurfaceState {
  surface_id : Int
  target_id : Int
  surface : @wgpu.Surface
  mut surface_format : @wgpu.TextureFormat?
  mut configured_width : Int
  mut configured_height : Int
  mut configured_present_mode : UInt
  mut configured_alpha_mode : UInt
  mut configured_desired_maximum_frame_latency : UInt
  mut frame : GpuFrameState?
  mut cleared_this_frame : Bool
}

///|

///|
struct GpuMesh3dPreprocessCameraUploadState {
  key_hi : Int
  key_lo : Int
  mut mesh_input_buffer : @wgpu.Buffer?
  mut mesh_input_capacity : UInt64
  mut mesh_input_count : Int
  mut previous_mesh_input_buffer : @wgpu.Buffer?
  mut previous_mesh_input_capacity : UInt64
  mut output_buffer : @wgpu.Buffer?
  mut output_capacity : UInt64
  mut output_count : Int
  mut motion_vector_mesh_bind_group : @wgpu.BindGroup?
  mut preprocess_view_buffer : @wgpu.Buffer?
  mut preprocess_view_capacity : UInt64
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
  mut late_non_indexed_work_item_buffer : @wgpu.Buffer?
  mut late_non_indexed_work_item_capacity : UInt64
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
  mut indexed_indirect_parameters_count : Int
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
  mut non_indexed_indirect_parameters_count : Int
  mut dispatch_metadata_buffer : @wgpu.Buffer?
  mut dispatch_metadata_capacity : UInt64
  mut direct_workgroup_count : Int
  mut indexed_workgroup_count : Int
  mut non_indexed_workgroup_count : Int
}

///|

///|
pub struct GpuBackend {
  instance : @wgpu.Instance
  adapter : @wgpu.Adapter
  device : @wgpu.Device
  queue : @wgpu.Queue
  assets_base : String
  mut surface : @wgpu.Surface?
  mut surface_format : @wgpu.TextureFormat?
  mut configured_width : Int
  mut configured_height : Int
  mut surface_capture_active : Bool
  mut surface_cleared_this_frame : Bool
  mut frame : GpuFrameState?
  mut pass_state : GpuPassState?
  mut frame_count : UInt
  mut depth_texture : @wgpu.Texture?
  mut depth_view : @wgpu.TextureView?
  mut depth_target_id : Int
  mut depth_width : Int
  mut depth_height : Int

  // Sprite pipeline (textured quads).
  mut sprite_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bgl_globals : @wgpu.BindGroupLayout?
  mut sprite_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_pipeline : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface_format : @wgpu.TextureFormat?
  mut sprite_globals_buf : @wgpu.Buffer?
  mut sprite_instance_buf : @wgpu.Buffer?
  mut sprite_index_buf : @wgpu.Buffer?
  mut sprite_instance_capacity : UInt64
  mut sprite_globals_bg : @wgpu.BindGroup?
  mut sprite_view_bgl : @wgpu.BindGroupLayout?
  mut sprite_texture_bgl : @wgpu.BindGroupLayout?
  mut sprite_render_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_view_buf : @wgpu.Buffer?
  mut sprite_view_bg : @wgpu.BindGroup?
  mut sprite_lut_texture : @wgpu.Texture?
  mut sprite_lut_view : @wgpu.TextureView?
  mut sprite_lut_sampler : @wgpu.Sampler?
  sprite_instance_data : Array[Float]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : UInt

  // UI pipeline (rounded rect + border, Bevy-aligned).
  mut ui_view_bgl : @wgpu.BindGroupLayout?
  mut ui_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_pipeline : @wgpu.RenderPipeline?
  mut ui_pipeline_anti_alias : @wgpu.RenderPipeline?
  mut ui_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_anti_alias : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_view_buf : @wgpu.Buffer?
  mut ui_view_bg : @wgpu.BindGroup?
  mut ui_vertex_buf : @wgpu.Buffer?
  mut ui_vertex_capacity : UInt64
  ui_vertex_data : Array[UInt]
  ui_batches : Array[UiBatch]
  mut ui_vertex_count : UInt

  // UI box shadow pipeline (Bevy-aligned).
  mut ui_shadow_view_bgl : @wgpu.BindGroupLayout?
  mut ui_shadow_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_shadow_view_buf : @wgpu.Buffer?
  mut ui_shadow_view_bg : @wgpu.BindGroup?
  mut ui_shadow_vertex_buf : @wgpu.Buffer?
  mut ui_shadow_vertex_capacity : UInt64
  ui_shadow_vertex_data : Array[UInt]
  ui_shadow_batches : Array[UiShadowBatch]
  ui_shadow_pipeline_cache : Array[UiShadowPipelineCacheEntry]
  mut ui_shadow_vertex_count : UInt

  // UI texture slice pipeline (Bevy-aligned).
  mut ui_slice_view_bgl : @wgpu.BindGroupLayout?
  mut ui_slice_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_slice_pipeline : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_slice_view_buf : @wgpu.Buffer?
  mut ui_slice_globals_buf : @wgpu.Buffer?
  mut ui_slice_view_bg : @wgpu.BindGroup?
  mut ui_slice_vertex_buf : @wgpu.Buffer?
  mut ui_slice_vertex_capacity : UInt64
  ui_slice_vertex_data : Array[UInt]
  ui_slice_batches : Array[UiBatch]
  mut ui_slice_vertex_count : UInt

  // Mesh pipeline (solid-color).
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh2d_view_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_mesh_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_material_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_view_buf : @wgpu.Buffer?
  mut mesh2d_globals_buf : @wgpu.Buffer?
  mut mesh2d_view_bg : @wgpu.BindGroup?
  mut mesh2d_lut_texture : @wgpu.Texture?
  mut mesh2d_lut_view : @wgpu.TextureView?
  mut mesh2d_lut_sampler : @wgpu.Sampler?
  mut mesh2d_instance_buf : @wgpu.Buffer?
  mut mesh2d_instance_bg : @wgpu.BindGroup?
  mut mesh2d_instance_capacity : UInt64
  mut mesh2d_instance_used : Int
  mesh2d_pipeline_cache : Array[Mesh2dPipelineCacheEntry]
  mesh2d_material_layout_cache : Array[Mesh2dMaterialLayoutCacheEntry]
  mesh2d_material_bg_cache : Array[Mesh2dMaterialBindGroupCacheEntry]
  mut mesh3d_bgl_view : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_draw : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_material : @wgpu.BindGroupLayout?
  mut mesh3d_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_pipeline : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_line_list : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_line_list_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_line_strip : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_line_strip_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_line_list : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_line_list_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_line_strip : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_line_strip_transparent : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh3d_pipeline_rgba8_cull_mode : Int
  mut mesh3d_pipeline_surface_cull_mode : Int
  mut mesh3d_point_shadow_compare_sampler : @wgpu.Sampler?
  mut mesh3d_view_buf : @wgpu.Buffer?
  mesh3d_draw_slots : Array[GpuStorageSlot]
  mut mesh3d_draw_slot_used : Int
  mut mesh3d_gpu_instance_builder_enabled : Bool
  mut mesh3d_instance_draw_buf : @wgpu.Buffer?
  mut mesh3d_instance_draw_bg : @wgpu.BindGroup?
  mut mesh3d_instance_draw_capacity : UInt64
  mut mesh3d_instance_draw_used : Int
  mesh3d_preprocess_camera_upload_states : Array[
    GpuMesh3dPreprocessCameraUploadState,
  ]
  mut mesh3d_preprocess_reset_batch_sets_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_reset_batch_sets_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_reset_batch_sets_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_direct_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_direct_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_direct_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_indexed_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_build_indexed_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_build_indexed_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_non_indexed_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_build_non_indexed_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_motion_vector_bgl_view : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_bgl_empty : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_bgl_mesh : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_motion_vector_pipeline : @wgpu.RenderPipeline?
  mut mesh3d_motion_vector_view_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_globals_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_previous_view_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_visibility_ranges_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_view_bg : @wgpu.BindGroup?
  mesh3d_motion_vector_mesh_slots : Array[GpuStorageSlot]
  mut mesh3d_motion_vector_mesh_slot_used : Int
  mut mesh3d_motion_vector_instance_mesh_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_instance_mesh_bg : @wgpu.BindGroup?
  mut mesh3d_motion_vector_instance_mesh_capacity : UInt64
  mut mesh3d_motion_vector_instance_mesh_used : Int
  mut motion_blur_bgl : @wgpu.BindGroupLayout?
  mut motion_blur_pipeline : @wgpu.RenderPipeline?
  mut motion_blur_pipeline_surface : @wgpu.RenderPipeline?
  mut motion_blur_pipeline_surface_format : @wgpu.TextureFormat?
  mut motion_blur_settings_buf : @wgpu.Buffer?
  mut motion_blur_globals_buf : @wgpu.Buffer?
  mut effect_stack_bgl : @wgpu.BindGroupLayout?
  mut effect_stack_pipeline_layout : @wgpu.PipelineLayout?
  mut effect_stack_pipeline : @wgpu.RenderPipeline?
  mut effect_stack_pipeline_surface : @wgpu.RenderPipeline?
  mut effect_stack_pipeline_surface_format : @wgpu.TextureFormat?
  mut effect_stack_sampler : @wgpu.Sampler?
  mut effect_stack_lut_sampler : @wgpu.Sampler?
  mut effect_stack_chromatic_settings_buf : @wgpu.Buffer?
  mut effect_stack_vignette_settings_buf : @wgpu.Buffer?
  mut effect_stack_default_lut_texture_id : Int
  mut fxaa_bgl : @wgpu.BindGroupLayout?
  mut fxaa_pipeline_layout : @wgpu.PipelineLayout?
  mut fxaa_pipeline : @wgpu.RenderPipeline?
  mut fxaa_pipeline_surface : @wgpu.RenderPipeline?
  mut fxaa_pipeline_surface_format : @wgpu.TextureFormat?
  mut fxaa_pipeline_edge_threshold_mode : Int
  mut fxaa_pipeline_edge_threshold_min_mode : Int
  mut fxaa_pipeline_surface_edge_threshold_mode : Int
  mut fxaa_pipeline_surface_edge_threshold_min_mode : Int
  mut fxaa_sampler : @wgpu.Sampler?
  mut bloom_intermediate_bgl : @wgpu.BindGroupLayout?
  mut bloom_intermediate_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping_bgl : @wgpu.BindGroupLayout?
  mut tonemapping_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping_view_buf : @wgpu.Buffer?
  mut tonemapping_sampler : @wgpu.Sampler?
  tonemapping_pipeline_cache : Array[TonemappingPipelineCacheEntry]
  mut bloom_downsample_first_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_no_threshold_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_no_threshold_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_upsample_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom_upsample_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_format : @wgpu.TextureFormat?
  mut bloom_settings_buf : @wgpu.Buffer?
  mut bloom_sampler : @wgpu.Sampler?
  mut bloom_mip_texture : @wgpu.Texture?
  bloom_mip_views : Array[@wgpu.TextureView]
  mut bloom_mip_count : Int
  mut bloom_mip_width : Int
  mut bloom_mip_height : Int
  mut tonemapping_fallback_lut_texture_id : Int
  mut auto_exposure_compute_bgl : @wgpu.BindGroupLayout?
  mut auto_exposure_compute_pipeline_layout : @wgpu.PipelineLayout?
  mut auto_exposure_histogram_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_average_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_globals_buf : @wgpu.Buffer?
  mut auto_exposure_settings_buf : @wgpu.Buffer?
  mut auto_exposure_curve_extents_buf : @wgpu.Buffer?
  mut auto_exposure_histogram_buf : @wgpu.Buffer?
  mut auto_exposure_curve_texture : @wgpu.Texture?
  mut auto_exposure_curve_view : @wgpu.TextureView?
  mut auto_exposure_active_state_buf : @wgpu.Buffer?
  auto_exposure_view_states : Array[GpuAutoExposureViewState]
  mesh3d_material_bg_cache : Array[Mesh3dMaterialBindGroupCacheEntry]
  sampler_cache : @hashmap.HashMap[String, @wgpu.Sampler]
  mut next_id : Int
  mut normal_map_fallback_texture_id : Int
  mut point_shadow_fallback_texture_id : Int
  mut shadow_color_texture : @wgpu.Texture?
  mut shadow_color_view : @wgpu.TextureView?
  mut shadow_color_width : Int
  mut shadow_color_height : Int
  surfaces : Array[GpuSurfaceState]
  mut active_surface_target_id : Int
  textures : Array[GpuTextureInfo]
  meshes : Array[GpuMeshInfo]
}

///|
const COMPRESSED_IMAGE_FORMAT_ASTC_LDR : Int = 1

///|
const COMPRESSED_IMAGE_FORMAT_BC : Int = 2

///|
const COMPRESSED_IMAGE_FORMAT_ETC2 : Int = 4

///|
const MESH3D_TOPOLOGY_TRIANGLE_LIST : UInt = @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST

///|
const MESH3D_TOPOLOGY_LINE_LIST : UInt = @wgpu.PRIMITIVE_TOPOLOGY_LINE_LIST

///|
const MESH3D_TOPOLOGY_LINE_STRIP : UInt = @wgpu.PRIMITIVE_TOPOLOGY_LINE_STRIP

///|
fn mesh3d_topology_from_kind(kind : Int) -> UInt {
  match kind {
    1 => MESH3D_TOPOLOGY_LINE_LIST
    2 => MESH3D_TOPOLOGY_LINE_STRIP
    _ => MESH3D_TOPOLOGY_TRIANGLE_LIST
  }
}

///|
fn mesh3d_topology_suffix(topology : UInt) -> String {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    "line_list"
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    "line_strip"
  } else {
    "triangle_list"
  }
}

///|
const PASS_KIND_BASE_MASK : Int = 255

///|
const PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
const PASS_KIND_BASE_POINT_SHADOW : Int = 2

///|
const MESH3D_CULL_MODE_MASK : Int = 3

///|
const MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
const MESH3D_DRAW_FLAG_FOG : Int = 1 << 9

///|
const MESH3D_DRAW_FLAG_POSTPROCESS_PROXY : Int = 1 << 10

///|
fn pass_kind_base_kind(pass_kind : Int) -> Int {
  pass_kind & PASS_KIND_BASE_MASK
}

///|
fn pass_kind_postprocess_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_POSTPROCESS_FLAG) == 0
}

///|
fn pass_kind_fog_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_FOG_FLAG) == 0
}

///|
fn pass_kind_decal_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_DECAL_FLAG) == 0
}

///|
fn mesh3d_draw_is_decal(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_DECAL) != 0
}

///|
fn mesh3d_draw_is_fog(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_FOG) != 0
}

///|
fn mesh3d_draw_is_postprocess_proxy(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_POSTPROCESS_PROXY) != 0
}

///|
fn mesh3d_cull_mode_sanitize(cull_mode : Int) -> Int {
  match cull_mode & MESH3D_CULL_MODE_MASK {
    1 => 1
    2 => 2
    _ => 0
  }
}

///|
fn mesh3d_cull_mode_wgpu(cull_mode : Int) -> UInt {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => @wgpu.CULL_MODE_FRONT
    2 => @wgpu.CULL_MODE_BACK
    _ => @wgpu.CULL_MODE_NONE
  }
}

///|
fn mesh3d_cull_mode_suffix(cull_mode : Int) -> String {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => "front"
    2 => "back"
    _ => "none"
  }
}

///|
pub fn GpuBackend::new(
  assets_base? : String = "",
) -> GpuBackend raise GpuBackendError {
  let instance = @wgpu.Instance::create() catch {
    err => fatal("wgpu: Instance::create failed: " + err.message())
  }
  let adapter = instance.request_adapter_sync() catch {
    err =>
      fatal("wgpu: Instance::request_adapter_sync failed: " + err.message())
  }
  let required_features : Array[UInt] = []
  if adapter.supported_features_contains_u32(0x00000007U) {
    required_features.push(0x00000007U)
  }
  if adapter.supported_features_contains_u32(0x00000004U) {
    required_features.push(0x00000004U)
  }
  if adapter.supported_features_contains_u32(0x00000006U) {
    required_features.push(0x00000006U)
  }
  if adapter.has_feature_native_polygon_mode_line() {
    required_features.push(@wgpu.NATIVE_FEATURE_POLYGON_MODE_LINE)
  }
  let device = adapter.request_device_sync_with_features(
    instance, required_features,
  ) catch {
    err => fatal("wgpu: Adapter::request_device_sync failed: " + err.message())
  }
  if @sys.get_env_var("MGSTUDIO_WGPU_UNCAPTURED_ERROR_STDERR") is Some(flag) &&
    flag == "1" {
    @wgpu.set_uncaptured_error_stderr_enabled(true)
  }
  let queue = device.queue()
  GpuBackend::{
    instance,
    adapter,
    device,
    queue,
    assets_base,
    surface: None,
    surface_format: None,
    configured_width: 0,
    configured_height: 0,
    surface_capture_active: false,
    surface_cleared_this_frame: false,
    frame: None,
    pass_state: None,
    frame_count: 0U,
    depth_texture: None,
    depth_view: None,
    depth_target_id: -2,
    depth_width: 0,
    depth_height: 0,
    sprite_bgl_tex: None,
    sprite_bgl_globals: None,
    sprite_pipeline_layout: None,
    sprite_pipeline: None,
    sprite_pipeline_surface: None,
    sprite_pipeline_surface_format: None,
    sprite_globals_buf: None,
    sprite_instance_buf: None,
    sprite_index_buf: None,
    sprite_instance_capacity: 0UL,
    sprite_globals_bg: None,
    sprite_view_bgl: None,
    sprite_texture_bgl: None,
    sprite_render_pipeline_layout: None,
    sprite_view_buf: None,
    sprite_view_bg: None,
    sprite_lut_texture: None,
    sprite_lut_view: None,
    sprite_lut_sampler: None,
    sprite_instance_data: [],
    sprite_batches: [],
    sprite_instance_count: 0U,
    ui_view_bgl: None,
    ui_pipeline_layout: None,
    ui_pipeline: None,
    ui_pipeline_anti_alias: None,
    ui_pipeline_surface: None,
    ui_pipeline_surface_anti_alias: None,
    ui_pipeline_surface_format: None,
    ui_view_buf: None,
    ui_view_bg: None,
    ui_vertex_buf: None,
    ui_vertex_capacity: 0UL,
    ui_vertex_data: [],
    ui_batches: [],
    ui_vertex_count: 0U,
    ui_shadow_view_bgl: None,
    ui_shadow_pipeline_layout: None,
    ui_shadow_view_buf: None,
    ui_shadow_view_bg: None,
    ui_shadow_vertex_buf: None,
    ui_shadow_vertex_capacity: 0UL,
    ui_shadow_vertex_data: [],
    ui_shadow_batches: [],
    ui_shadow_pipeline_cache: [],
    ui_shadow_vertex_count: 0U,
    ui_slice_view_bgl: None,
    ui_slice_pipeline_layout: None,
    ui_slice_pipeline: None,
    ui_slice_pipeline_surface: None,
    ui_slice_pipeline_surface_format: None,
    ui_slice_view_buf: None,
    ui_slice_globals_buf: None,
    ui_slice_view_bg: None,
    ui_slice_vertex_buf: None,
    ui_slice_vertex_capacity: 0UL,
    ui_slice_vertex_data: [],
    ui_slice_batches: [],
    ui_slice_vertex_count: 0U,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_pipeline_surface: None,
    mesh_pipeline_surface_format: None,
    mesh2d_view_bgl: None,
    mesh2d_mesh_bgl: None,
    mesh2d_material_bgl: None,
    mesh2d_view_buf: None,
    mesh2d_globals_buf: None,
    mesh2d_view_bg: None,
    mesh2d_lut_texture: None,
    mesh2d_lut_view: None,
    mesh2d_lut_sampler: None,
    mesh2d_instance_buf: None,
    mesh2d_instance_bg: None,
    mesh2d_instance_capacity: 0UL,
    mesh2d_instance_used: 0,
    mesh2d_pipeline_cache: [],
    mesh2d_material_layout_cache: [],
    mesh2d_material_bg_cache: [],
    mesh3d_bgl_view: None,
    mesh3d_bgl_draw: None,
    mesh3d_bgl_material: None,
    mesh3d_pipeline_layout: None,
    mesh3d_pipeline: None,
    mesh3d_pipeline_transparent: None,
    mesh3d_pipeline_line_list: None,
    mesh3d_pipeline_line_list_transparent: None,
    mesh3d_pipeline_line_strip: None,
    mesh3d_pipeline_line_strip_transparent: None,
    mesh3d_pipeline_surface: None,
    mesh3d_pipeline_surface_transparent: None,
    mesh3d_pipeline_surface_line_list: None,
    mesh3d_pipeline_surface_line_list_transparent: None,
    mesh3d_pipeline_surface_line_strip: None,
    mesh3d_pipeline_surface_line_strip_transparent: None,
    mesh3d_pipeline_surface_format: None,
    mesh3d_pipeline_rgba8_cull_mode: -1,
    mesh3d_pipeline_surface_cull_mode: -1,
    mesh3d_point_shadow_compare_sampler: None,
    mesh3d_view_buf: None,
    mesh3d_draw_slots: [],
    mesh3d_draw_slot_used: 0,
    mesh3d_gpu_instance_builder_enabled: false,
    mesh3d_instance_draw_buf: None,
    mesh3d_instance_draw_bg: None,
    mesh3d_instance_draw_capacity: 0UL,
    mesh3d_instance_draw_used: 0,
    mesh3d_preprocess_camera_upload_states: [],
    mesh3d_preprocess_reset_batch_sets_bgl: None,
    mesh3d_preprocess_reset_batch_sets_pipeline_layout: None,
    mesh3d_preprocess_reset_batch_sets_pipeline: None,
    mesh3d_preprocess_direct_bgl: None,
    mesh3d_preprocess_direct_pipeline_layout: None,
    mesh3d_preprocess_direct_pipeline: None,
    mesh3d_preprocess_indirect_bgl: None,
    mesh3d_preprocess_indirect_pipeline_layout: None,
    mesh3d_preprocess_indirect_pipeline: None,
    mesh3d_preprocess_build_indexed_indirect_bgl: None,
    mesh3d_preprocess_build_indexed_indirect_pipeline_layout: None,
    mesh3d_preprocess_build_indexed_indirect_pipeline: None,
    mesh3d_preprocess_build_non_indexed_indirect_bgl: None,
    mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout: None,
    mesh3d_preprocess_build_non_indexed_indirect_pipeline: None,
    mesh3d_motion_vector_bgl_view: None,
    mesh3d_motion_vector_bgl_empty: None,
    mesh3d_motion_vector_bgl_mesh: None,
    mesh3d_motion_vector_pipeline_layout: None,
    mesh3d_motion_vector_pipeline: None,
    mesh3d_motion_vector_view_buf: None,
    mesh3d_motion_vector_globals_buf: None,
    mesh3d_motion_vector_previous_view_buf: None,
    mesh3d_motion_vector_visibility_ranges_buf: None,
    mesh3d_motion_vector_view_bg: None,
    mesh3d_motion_vector_mesh_slots: [],
    mesh3d_motion_vector_mesh_slot_used: 0,
    mesh3d_motion_vector_instance_mesh_buf: None,
    mesh3d_motion_vector_instance_mesh_bg: None,
    mesh3d_motion_vector_instance_mesh_capacity: 0UL,
    mesh3d_motion_vector_instance_mesh_used: 0,
    motion_blur_bgl: None,
    motion_blur_pipeline: None,
    motion_blur_pipeline_surface: None,
    motion_blur_pipeline_surface_format: None,
    motion_blur_settings_buf: None,
    motion_blur_globals_buf: None,
    effect_stack_bgl: None,
    effect_stack_pipeline_layout: None,
    effect_stack_pipeline: None,
    effect_stack_pipeline_surface: None,
    effect_stack_pipeline_surface_format: None,
    effect_stack_sampler: None,
    effect_stack_lut_sampler: None,
    effect_stack_chromatic_settings_buf: None,
    effect_stack_vignette_settings_buf: None,
    effect_stack_default_lut_texture_id: -1,
    fxaa_bgl: None,
    fxaa_pipeline_layout: None,
    fxaa_pipeline: None,
    fxaa_pipeline_surface: None,
    fxaa_pipeline_surface_format: None,
    fxaa_pipeline_edge_threshold_mode: -1,
    fxaa_pipeline_edge_threshold_min_mode: -1,
    fxaa_pipeline_surface_edge_threshold_mode: -1,
    fxaa_pipeline_surface_edge_threshold_min_mode: -1,
    fxaa_sampler: None,
    bloom_intermediate_bgl: None,
    bloom_intermediate_pipeline_layout: None,
    tonemapping_bgl: None,
    tonemapping_pipeline_layout: None,
    tonemapping_view_buf: None,
    tonemapping_sampler: None,
    tonemapping_pipeline_cache: [],
    bloom_downsample_first_pipeline: None,
    bloom_downsample_first_no_threshold_pipeline: None,
    bloom_downsample_first_uniform_pipeline: None,
    bloom_downsample_first_no_threshold_uniform_pipeline: None,
    bloom_downsample_pipeline: None,
    bloom_downsample_uniform_pipeline: None,
    bloom_upsample_pipeline_energy: None,
    bloom_upsample_pipeline_additive: None,
    bloom_upsample_final_pipeline_energy: None,
    bloom_upsample_final_pipeline_additive: None,
    bloom_upsample_final_pipeline_format: None,
    bloom_settings_buf: None,
    bloom_sampler: None,
    bloom_mip_texture: None,
    bloom_mip_views: [],
    bloom_mip_count: 0,
    bloom_mip_width: 0,
    bloom_mip_height: 0,
    tonemapping_fallback_lut_texture_id: -1,
    auto_exposure_compute_bgl: None,
    auto_exposure_compute_pipeline_layout: None,
    auto_exposure_histogram_pipeline: None,
    auto_exposure_average_pipeline: None,
    auto_exposure_globals_buf: None,
    auto_exposure_settings_buf: None,
    auto_exposure_curve_extents_buf: None,
    auto_exposure_histogram_buf: None,
    auto_exposure_curve_texture: None,
    auto_exposure_curve_view: None,
    auto_exposure_active_state_buf: None,
    auto_exposure_view_states: [],
    mesh3d_material_bg_cache: [],
    sampler_cache: @hashmap.HashMap::new(),
    next_id: 1,
    normal_map_fallback_texture_id: -1,
    point_shadow_fallback_texture_id: -1,
    shadow_color_texture: None,
    shadow_color_view: None,
    shadow_color_width: 0,
    shadow_color_height: 0,
    surfaces: [],
    active_surface_target_id: -1,
    textures: [],
    meshes: [],
  }
}

///|
const PI : Float = 3.141592653589793F

///|
const MESH3D_FORWARD_SHADER_PATH : String = "shaders/custom/mesh3d_forward.wgsl"

///|
fn cosf(x : Float) -> Float {
  Float::from_double(@coremath.cos(x.to_double()))
}

///|
fn sinf(x : Float) -> Float {
  Float::from_double(@coremath.sin(x.to_double()))
}

///|
fn atan2f(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
fn quat_to_z_rotation(x : Float, y : Float, z : Float, w : Float) -> Float {
  let siny_cosp = 2.0F * (w * z + x * y)
  let cosy_cosp = 1.0F - 2.0F * (y * y + z * z)
  atan2f(siny_cosp, cosy_cosp)
}

///|
pub(all) suberror GpuBackendError {
  Fatal(String)
} derive(Show)

///|
fn[T] fatal(message : String) -> T raise GpuBackendError {
  raise GpuBackendError::Fatal(message)
}

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE : Int = 0

///|
const IMAGE_SAMPLER_ADDRESS_MODE_REPEAT : Int = 1

///|
const IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT : Int = 2

///|
const IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER : Int = 3

///|
const IMAGE_SAMPLER_FILTER_MODE_NEAREST : Int = 0

///|
const IMAGE_SAMPLER_FILTER_MODE_LINEAR : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_COMPARE_NEVER : Int = 0

///|
const IMAGE_SAMPLER_COMPARE_LESS : Int = 1

///|
const IMAGE_SAMPLER_COMPARE_EQUAL : Int = 2

///|
const IMAGE_SAMPLER_COMPARE_LESS_EQUAL : Int = 3

///|
const IMAGE_SAMPLER_COMPARE_GREATER : Int = 4

///|
const IMAGE_SAMPLER_COMPARE_NOT_EQUAL : Int = 5

///|
const IMAGE_SAMPLER_COMPARE_GREATER_EQUAL : Int = 6

///|
const IMAGE_SAMPLER_COMPARE_ALWAYS : Int = 7

///|
const IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED : Int = -1

///|
const IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK : Int = 0

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK : Int = 1

///|
const IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE : Int = 2

///|
const IMAGE_SAMPLER_BORDER_COLOR_ZERO : Int = 3

///|
fn ss(raw : UInt64) -> @wgpu.ShaderStage {
  @wgpu.ShaderStage::from_u64(raw)
}

///|
fn bu(raw : UInt64) -> @wgpu.BufferUsage {
  @wgpu.BufferUsage::from_u64(raw)
}

///|
fn tf(raw : UInt) -> @wgpu.TextureFormat {
  @wgpu.TextureFormat::from_u32(raw)
}

///|
priv struct TextureBlockInfo {
  block_width : Int
  block_height : Int
  block_bytes : Int
}

///|
fn texture_block_info(format_raw : UInt) -> TextureBlockInfo? {
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 4,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 4,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT {
    return Some(TextureBlockInfo::{
      block_width: 1,
      block_height: 1,
      block_bytes: 8,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if format_raw == @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB {
    return Some(TextureBlockInfo::{
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  None
}

///|
fn texture_layout_for_level(
  info : TextureBlockInfo,
  width : Int,
  height : Int,
) -> (Int, Int, Int)? {
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let blocks_w = (w + info.block_width - 1) / info.block_width
  let blocks_h = (h + info.block_height - 1) / info.block_height
  if blocks_w <= 0 || blocks_h <= 0 {
    return None
  }
  let bytes_per_row = blocks_w * info.block_bytes
  if bytes_per_row <= 0 {
    return None
  }
  let total = bytes_per_row * blocks_h
  if total <= 0 {
    return None
  }
  Some((bytes_per_row, blocks_h, total))
}

///|
fn alloc_id(backend : GpuBackend) -> Int {
  let id = backend.next_id
  backend.next_id = id + 1
  id
}

///|
fn texture_view_aspect_for_format(format_raw : UInt) -> UInt {
  if format_raw == @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT {
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY
  } else {
    @wgpu.TEXTURE_ASPECT_ALL
  }
}

///|
fn f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn image_sampler_address_mode_wgpu_raw(raw : Int) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE => @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT => @wgpu.ADDRESS_MODE_REPEAT
    IMAGE_SAMPLER_ADDRESS_MODE_MIRROR_REPEAT => @wgpu.ADDRESS_MODE_MIRROR_REPEAT
    IMAGE_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER =>
      fatal(
        "wgpu: ImageAddressMode::ClampToBorder is blocked because Milky2018/wgpu_mbt does not expose ADDRESS_MODE_CLAMP_TO_BORDER or sampler border-color creation",
      )
    _ =>
      fatal(
        "wgpu: unsupported image sampler address mode raw=" + raw.to_string(),
      )
  }
}

///|
fn image_sampler_filter_mode_wgpu_raw(raw : Int) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_FILTER_MODE_NEAREST => @wgpu.FILTER_MODE_NEAREST
    IMAGE_SAMPLER_FILTER_MODE_LINEAR => @wgpu.FILTER_MODE_LINEAR
    _ =>
      fatal(
        "wgpu: unsupported image sampler filter mode raw=" + raw.to_string(),
      )
  }
}

///|
fn image_sampler_mipmap_filter_mode_wgpu_raw(
  raw : Int,
) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_FILTER_MODE_NEAREST => @wgpu.MIPMAP_FILTER_MODE_NEAREST
    IMAGE_SAMPLER_FILTER_MODE_LINEAR => @wgpu.MIPMAP_FILTER_MODE_LINEAR
    _ =>
      fatal(
        "wgpu: unsupported image sampler mipmap filter mode raw=" +
        raw.to_string(),
      )
  }
}

///|
fn image_sampler_compare_function_wgpu_raw(
  raw : Int,
) -> UInt raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_COMPARE_UNDEFINED => @wgpu.COMPARE_FUNCTION_UNDEFINED
    IMAGE_SAMPLER_COMPARE_NEVER => @wgpu.COMPARE_FUNCTION_NEVER
    IMAGE_SAMPLER_COMPARE_LESS => @wgpu.COMPARE_FUNCTION_LESS
    IMAGE_SAMPLER_COMPARE_EQUAL => @wgpu.COMPARE_FUNCTION_EQUAL
    IMAGE_SAMPLER_COMPARE_LESS_EQUAL => @wgpu.COMPARE_FUNCTION_LESS_EQUAL
    IMAGE_SAMPLER_COMPARE_GREATER => @wgpu.COMPARE_FUNCTION_GREATER
    IMAGE_SAMPLER_COMPARE_NOT_EQUAL => @wgpu.COMPARE_FUNCTION_NOT_EQUAL
    IMAGE_SAMPLER_COMPARE_GREATER_EQUAL => @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
    IMAGE_SAMPLER_COMPARE_ALWAYS => @wgpu.COMPARE_FUNCTION_ALWAYS
    _ =>
      fatal(
        "wgpu: unsupported image sampler compare function raw=" +
        raw.to_string(),
      )
  }
}

///|
fn image_sampler_border_color_validate(raw : Int) -> Unit raise GpuBackendError {
  match raw {
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED => ()
    IMAGE_SAMPLER_BORDER_COLOR_TRANSPARENT_BLACK
    | IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_BLACK
    | IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE
    | IMAGE_SAMPLER_BORDER_COLOR_ZERO =>
      fatal(
        "wgpu: ImageSamplerBorderColor is blocked because Milky2018/wgpu_mbt does not expose sampler border-color creation",
      )
    _ =>
      fatal(
        "wgpu: unsupported image sampler border color raw=" + raw.to_string(),
      )
  }
}

///|
fn image_sampler_cache_key(
  address_mode_u : Int,
  address_mode_v : Int,
  address_mode_w : Int,
  mag_filter : Int,
  min_filter : Int,
  mipmap_filter : Int,
  lod_min_clamp : Float,
  lod_max_clamp : Float,
  compare : Int,
  anisotropy_clamp : Int,
  border_color : Int,
) -> String {
  address_mode_u.to_string() +
  "|" +
  address_mode_v.to_string() +
  "|" +
  address_mode_w.to_string() +
  "|" +
  mag_filter.to_string() +
  "|" +
  min_filter.to_string() +
  "|" +
  mipmap_filter.to_string() +
  "|" +
  f32_bits(lod_min_clamp).to_string() +
  "|" +
  f32_bits(lod_max_clamp).to_string() +
  "|" +
  compare.to_string() +
  "|" +
  anisotropy_clamp.to_string() +
  "|" +
  border_color.to_string()
}

///|
fn gpu_sampler_get_or_create(
  backend : GpuBackend,
  address_mode_u : Int,
  address_mode_v : Int,
  address_mode_w : Int,
  mag_filter : Int,
  min_filter : Int,
  mipmap_filter : Int,
  lod_min_clamp : Float,
  lod_max_clamp : Float,
  compare : Int,
  anisotropy_clamp : Int,
  border_color : Int,
) -> @wgpu.Sampler raise GpuBackendError {
  if anisotropy_clamp < 1 {
    fatal(
      "wgpu: ImageSamplerDescriptor.anisotropy_clamp must be >= 1, got " +
      anisotropy_clamp.to_string(),
    )
  }
  image_sampler_border_color_validate(border_color)
  let key = image_sampler_cache_key(
    address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter, mipmap_filter,
    lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
  )
  match backend.sampler_cache.get(key) {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        image_sampler_address_mode_wgpu_raw(address_mode_u),
        image_sampler_address_mode_wgpu_raw(address_mode_v),
        image_sampler_address_mode_wgpu_raw(address_mode_w),
        image_sampler_filter_mode_wgpu_raw(mag_filter),
        image_sampler_filter_mode_wgpu_raw(min_filter),
        image_sampler_mipmap_filter_mode_wgpu_raw(mipmap_filter),
        lod_min_clamp_f32=lod_min_clamp,
        lod_max_clamp_f32=lod_max_clamp,
        compare_u32=image_sampler_compare_function_wgpu_raw(compare),
        max_anisotropy_u32=anisotropy_clamp.reinterpret_as_uint(),
      )
      backend.sampler_cache.set(key, sampler)
      sampler
    }
  }
}

///|
fn u16le_pack(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length() * 2, i => {
    let v = xs[i / 2]
    let b = if i % 2 == 0 { v & 0xFF } else { (v >> 8) & 0xFF }
    b.to_byte()
  })
}

///|
fn u32le_pack(xs : Array[UInt]) -> Bytes {
  let n = xs.length()
  Bytes::makei(n * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn f32le_pack(xs : Array[Float]) -> Bytes {
  u32le_pack(xs.map(f32_bits))
}

///|
fn normalize_shader_rel_path(rel : String) -> String {
  @naga_oil.normalize_shader_rel_path(rel)
}

///|
type WgslComposer = @naga_oil.Composer

///|
fn wgsl_composer() -> WgslComposer {
  @naga_oil.Composer::default()
}

///|
fn[T] raise_composer_error(
  err : @naga_oil.ComposerError,
) -> T raise GpuBackendError {
  fatal("wgpu: " + err.message())
}

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  @naga_oil.clear_registered_wgsl_source_registry()
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  @naga_oil.register_wgsl_source(rel_path, source)
}

///|
fn registered_wgsl_source_required(
  rel_path : String,
) -> String raise GpuBackendError {
  @naga_oil.registered_wgsl_source_required(rel_path) catch {
    err => raise_composer_error(err)
  }
}

///|
fn copy_registered_wgsl_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  @naga_oil.copy_registered_wgsl_import_module_paths()
}

///|
fn build_wgsl_import_module_paths(
  assets_base : String,
) -> @hashmap.HashMap[String, String] {
  @naga_oil.build_wgsl_import_module_paths(assets_base)
}

///|
fn split_once_text(text : String, sep : String) -> (String, String)? {
  let parts : Array[String] = []
  for piece in text.split(sep) {
    parts.push(piece.to_string())
  }
  if parts.length() != 2 {
    return None
  }
  Some((parts[0], parts[1]))
}

///|
fn default_wgsl_value_defines() -> @hashmap.HashMap[String, Int] {
  @naga_oil.default_wgsl_value_defines()
}

///|
fn preprocess_wgsl_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  visited : @hashmap.HashMap[String, Bool],
  modules : @hashmap.HashMap[String, String],
) -> String raise GpuBackendError {
  wgsl_composer().preprocess_wgsl_source(
    assets_base, source, defines, value_defines, visited, modules,
  ) catch {
    err => raise_composer_error(err)
  }
}

///|
fn load_wgsl_preprocessed(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  visited : @hashmap.HashMap[String, Bool],
  modules : @hashmap.HashMap[String, String],
) -> String raise GpuBackendError {
  wgsl_composer().load_wgsl_preprocessed(
    assets_base, rel, defines, value_defines, visited, modules,
  ) catch {
    err => raise_composer_error(err)
  }
}

///|
fn load_wgsl_from_assets_required(
  backend : GpuBackend,
  rel : String,
) -> String raise GpuBackendError {
  load_wgsl_from_assets_base_required(backend.assets_base, rel)
}

///|
fn load_wgsl_from_assets_base_required(
  assets_base : String,
  rel : String,
) -> String raise GpuBackendError {
  wgsl_composer().load_wgsl_from_assets_base_required(assets_base, rel) catch {
    err => raise_composer_error(err)
  }
}

///|
fn mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
  layout : @wgpu.PipelineLayout,
  shader : @wgpu.ShaderModule,
  format : UInt,
  with_depth? : Bool = false,
  depth_write_enabled? : Bool = true,
  position3d? : Bool = false,
  alpha_blend? : Bool = true,
  topology? : UInt = @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
  cull_mode? : UInt = @wgpu.CULL_MODE_NONE,
) -> @wgpu_c.WGPURenderPipelineDescriptorPtr raise GpuBackendError {
  let builder = @wgpu_c.render_pipeline_desc_builder_new(
    layout.raw_handle(),
    shader.raw_handle(),
  )
  let set_format_err = @wgpu_c.render_pipeline_desc_builder_set_color_target_format(
    builder, format,
  )
  let set_blend_err = if alpha_blend {
    @wgpu_c.render_pipeline_desc_builder_enable_alpha_blend(builder)
  } else {
    0U
  }
  let vertex_stride = if position3d { MESH3D_VERTEX_STRIDE_BYTES } else { 32UL }
  let pos_format = if position3d {
    @wgpu.VERTEX_FORMAT_FLOAT32X3
  } else {
    @wgpu.VERTEX_FORMAT_FLOAT32X2
  }
  let normal_offset = 12UL
  let uv_offset = if position3d { 24UL } else { 8UL }
  let color_offset = if position3d { 32UL } else { 16UL }
  let set_vertex_layout_err = @wgpu_c.render_pipeline_desc_builder_set_vertex_buffer_layout(
    builder,
    vertex_stride,
    @wgpu.VERTEX_STEP_MODE_VERTEX,
  )
  let pos_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder, pos_format, 0UL, 0U,
  )
  let normal_err = if position3d {
    @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
      builder,
      @wgpu.VERTEX_FORMAT_FLOAT32X3,
      normal_offset,
      1U,
    )
  } else {
    0U
  }
  let uv_location = if position3d { 2U } else { 1U }
  let color_location = if position3d { 3U } else { 2U }
  let uv_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X2,
    uv_offset,
    uv_location,
  )
  let color_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X4,
    color_offset,
    color_location,
  )
  if set_format_err != 0U ||
    set_blend_err != 0U ||
    set_vertex_layout_err != 0U ||
    pos_err != 0U ||
    normal_err != 0U ||
    uv_err != 0U ||
    color_err != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: failed to configure mesh vertex attributes for runtime mesh pipeline",
    )
  }
  let set_topology_err = @wgpu_c.render_pipeline_desc_builder_set_topology(
    builder, topology,
  )
  cull_mode |> ignore
  if set_topology_err != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal("wgpu: failed to configure mesh pipeline primitive state")
  }
  if with_depth {
    let set_depth_err = @wgpu_c.render_pipeline_desc_builder_set_depth_stencil(
      builder,
      @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
      depth_write_enabled,
      @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    if set_depth_err != 0U {
      @wgpu_c.render_pipeline_desc_builder_free(builder)
      fatal("wgpu: failed to configure mesh pipeline depth-stencil state")
    }
  }
  let desc = @wgpu_c.render_pipeline_desc_builder_finish(builder)
  if @wgpu_c.render_pipeline_descriptor_ptr_is_null(desc) {
    let last_error = @wgpu_c.render_pipeline_desc_builder_last_error_u32(
      builder,
    )
    let last_error_args = @wgpu_c.render_pipeline_desc_builder_last_error_args_u64(
      builder,
    )
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: mesh pipeline descriptor builder finish failed (error=\{last_error.reinterpret_as_int()}, args=\{last_error_args.to_int()})",
    )
  }
  desc
}

///|

///|
