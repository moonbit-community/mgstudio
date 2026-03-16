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
const MESH2D_BEVY_VIEW_BUFFER_SIZE : UInt64 = 1024UL

///|
const MESH2D_BEVY_GLOBALS_BUFFER_SIZE : UInt64 = 16UL

///|
const MESH2D_BEVY_UNIFORM_STRIDE_BYTES : UInt64 = 96UL

///|
const MESH2D_BEVY_UNIFORM_DYNAMIC_STRIDE_BYTES : UInt64 = 256UL

///|
const MESH2D_BEVY_COLOR_MATERIAL_UNIFORM_BUFFER_SIZE : UInt64 = 80UL

///|
const MESH3D_UNIFORM_BUFFER_SIZE : UInt64 = 512UL

///|
const BLOOM2D_UNIFORM_BUFFER_SIZE : UInt64 = 240UL

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
}

///|
struct GpuUniformSlot {
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
  transmission_source_texture_id : Int
  point_shadow_texture_id : Int
  bind_group : @wgpu.BindGroup
}

///|
pub struct Mesh2dPipelineCacheEntry {
  key : String
  pipeline : @wgpu.RenderPipeline
}

///|
struct Mesh2dMaterialBindGroupCacheEntry {
  key : String
  bind_group : @wgpu.BindGroup
  uniform_buf : @wgpu.Buffer
}

///|
pub struct Tonemapping2dPipelineCacheEntry {
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
  mut direct_work_item_buffer : @wgpu.Buffer?
  mut direct_work_item_capacity : UInt64
  mut indexed_work_item_buffer : @wgpu.Buffer?
  mut indexed_work_item_capacity : UInt64
  mut non_indexed_work_item_buffer : @wgpu.Buffer?
  mut non_indexed_work_item_capacity : UInt64
  mut late_indexed_work_item_buffer : @wgpu.Buffer?
  mut late_indexed_work_item_capacity : UInt64
  mut late_non_indexed_work_item_buffer : @wgpu.Buffer?
  mut late_non_indexed_work_item_capacity : UInt64
  mut indexed_cpu_metadata_buffer : @wgpu.Buffer?
  mut indexed_cpu_metadata_capacity : UInt64
  mut indexed_gpu_metadata_buffer : @wgpu.Buffer?
  mut indexed_gpu_metadata_capacity : UInt64
  mut indexed_batch_set_buffer : @wgpu.Buffer?
  mut indexed_batch_set_capacity : UInt64
  mut non_indexed_cpu_metadata_buffer : @wgpu.Buffer?
  mut non_indexed_cpu_metadata_capacity : UInt64
  mut non_indexed_gpu_metadata_buffer : @wgpu.Buffer?
  mut non_indexed_gpu_metadata_capacity : UInt64
  mut non_indexed_batch_set_buffer : @wgpu.Buffer?
  mut non_indexed_batch_set_capacity : UInt64
  mut dispatch_metadata_buffer : @wgpu.Buffer?
  mut dispatch_metadata_capacity : UInt64
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
  mut sprite_bevy_bgl_view : @wgpu.BindGroupLayout?
  mut sprite_bevy_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bevy_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_bevy_view_buf : @wgpu.Buffer?
  mut sprite_bevy_view_bg : @wgpu.BindGroup?
  mut sprite_bevy_lut_texture : @wgpu.Texture?
  mut sprite_bevy_lut_view : @wgpu.TextureView?
  mut sprite_bevy_lut_sampler : @wgpu.Sampler?
  sprite_instance_data : Array[Float]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : UInt

  // UI pipeline (rounded rect + border, Bevy-aligned).
  mut ui_pipeline : @wgpu.RenderPipeline?
  mut ui_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_instance_buf : @wgpu.Buffer?
  mut ui_instance_capacity : UInt64
  mut ui_globals_bg : @wgpu.BindGroup?
  ui_instance_data : Array[Float]
  ui_batches : Array[UiBatch]
  mut ui_instance_count : UInt

  // UI box shadow pipeline (Bevy-aligned).
  mut ui_shadow_pipeline : @wgpu.RenderPipeline?
  mut ui_shadow_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_shadow_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_shadow_instance_buf : @wgpu.Buffer?
  mut ui_shadow_instance_capacity : UInt64
  mut ui_shadow_globals_bg : @wgpu.BindGroup?
  ui_shadow_instance_data : Array[Float]
  ui_shadow_batches : Array[UiBatch]
  mut ui_shadow_instance_count : UInt

  // UI texture slice pipeline (Bevy-aligned).
  mut ui_slice_pipeline : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_slice_instance_buf : @wgpu.Buffer?
  mut ui_slice_instance_capacity : UInt64
  mut ui_slice_globals_bg : @wgpu.BindGroup?
  ui_slice_instance_data : Array[Float]
  ui_slice_batches : Array[UiBatch]
  mut ui_slice_instance_count : UInt

  // Mesh pipeline (solid-color).
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh2d_bevy_bgl_view : @wgpu.BindGroupLayout?
  mut mesh2d_bevy_bgl_mesh : @wgpu.BindGroupLayout?
  mut mesh2d_bevy_bgl_material : @wgpu.BindGroupLayout?
  mut mesh2d_bevy_view_buf : @wgpu.Buffer?
  mut mesh2d_bevy_globals_buf : @wgpu.Buffer?
  mut mesh2d_bevy_view_bg : @wgpu.BindGroup?
  mut mesh2d_bevy_lut_texture : @wgpu.Texture?
  mut mesh2d_bevy_lut_view : @wgpu.TextureView?
  mut mesh2d_bevy_lut_sampler : @wgpu.Sampler?
  mut mesh2d_bevy_instance_buf : @wgpu.Buffer?
  mut mesh2d_bevy_instance_bg : @wgpu.BindGroup?
  mut mesh2d_bevy_instance_capacity : UInt64
  mut mesh2d_bevy_instance_used : Int
  mesh2d_pipeline_cache : Array[Mesh2dPipelineCacheEntry]
  mesh2d_material_bg_cache : Array[Mesh2dMaterialBindGroupCacheEntry]
  mut mesh3d_bgl_uniform : @wgpu.BindGroupLayout?
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
  mesh3d_uniform_slots : Array[GpuUniformSlot]
  mut mesh3d_uniform_slot_used : Int
  mut mesh3d_gpu_instance_builder_enabled : Bool
  mut mesh3d_instance_uniform_buf : @wgpu.Buffer?
  mut mesh3d_instance_uniform_bg : @wgpu.BindGroup?
  mut mesh3d_instance_uniform_capacity : UInt64
  mut mesh3d_instance_uniform_used : Int
  mesh3d_preprocess_camera_upload_states : Array[
    GpuMesh3dPreprocessCameraUploadState,
  ]
  mut mesh3d_motion_vector_bgl_uniform : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_motion_vector_pipeline : @wgpu.RenderPipeline?
  mut mesh3d_motion_vector_uniform_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_uniform_bg : @wgpu.BindGroup?
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
  mut bloom2d_intermediate_bgl : @wgpu.BindGroupLayout?
  mut bloom2d_intermediate_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping2d_bgl : @wgpu.BindGroupLayout?
  mut tonemapping2d_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping2d_view_buf : @wgpu.Buffer?
  mut tonemapping2d_sampler : @wgpu.Sampler?
  tonemapping2d_pipeline_cache : Array[Tonemapping2dPipelineCacheEntry]
  mut bloom2d_downsample_first_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_no_threshold_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_no_threshold_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_upsample_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom2d_upsample_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom2d_upsample_final_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom2d_upsample_final_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom2d_upsample_final_pipeline_format : @wgpu.TextureFormat?
  mut bloom2d_settings_buf : @wgpu.Buffer?
  mut bloom2d_sampler : @wgpu.Sampler?
  mut bloom2d_mip_texture : @wgpu.Texture?
  bloom2d_mip_views : Array[@wgpu.TextureView]
  mut bloom2d_mip_count : Int
  mut bloom2d_mip_width : Int
  mut bloom2d_mip_height : Int
  mut tonemapping_fallback_lut_texture_id : Int
  mut auto_exposure_compute_bgl : @wgpu.BindGroupLayout?
  mut auto_exposure_compute_pipeline_layout : @wgpu.PipelineLayout?
  mut auto_exposure_histogram_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_average_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_settings_buf : @wgpu.Buffer?
  mut auto_exposure_curve_extents_buf : @wgpu.Buffer?
  mut auto_exposure_histogram_buf : @wgpu.Buffer?
  mut auto_exposure_curve_texture : @wgpu.Texture?
  mut auto_exposure_curve_view : @wgpu.TextureView?
  mut auto_exposure_dummy_state_buf : @wgpu.Buffer?
  mut auto_exposure_active_state_buf : @wgpu.Buffer?
  auto_exposure_view_states : Array[GpuAutoExposureViewState]
  mesh3d_material_bg_cache : Array[Mesh3dMaterialBindGroupCacheEntry]
  sampler_cache : @hashmap.HashMap[String, @wgpu.Sampler]
  mut next_id : Int
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
    sprite_bevy_bgl_view: None,
    sprite_bevy_bgl_tex: None,
    sprite_bevy_pipeline_layout: None,
    sprite_bevy_view_buf: None,
    sprite_bevy_view_bg: None,
    sprite_bevy_lut_texture: None,
    sprite_bevy_lut_view: None,
    sprite_bevy_lut_sampler: None,
    sprite_instance_data: [],
    sprite_batches: [],
    sprite_instance_count: 0U,
    ui_pipeline: None,
    ui_pipeline_surface: None,
    ui_pipeline_surface_format: None,
    ui_instance_buf: None,
    ui_instance_capacity: 0UL,
    ui_globals_bg: None,
    ui_instance_data: [],
    ui_batches: [],
    ui_instance_count: 0U,
    ui_shadow_pipeline: None,
    ui_shadow_pipeline_surface: None,
    ui_shadow_pipeline_surface_format: None,
    ui_shadow_instance_buf: None,
    ui_shadow_instance_capacity: 0UL,
    ui_shadow_globals_bg: None,
    ui_shadow_instance_data: [],
    ui_shadow_batches: [],
    ui_shadow_instance_count: 0U,
    ui_slice_pipeline: None,
    ui_slice_pipeline_surface: None,
    ui_slice_pipeline_surface_format: None,
    ui_slice_instance_buf: None,
    ui_slice_instance_capacity: 0UL,
    ui_slice_globals_bg: None,
    ui_slice_instance_data: [],
    ui_slice_batches: [],
    ui_slice_instance_count: 0U,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_pipeline_surface: None,
    mesh_pipeline_surface_format: None,
    mesh2d_bevy_bgl_view: None,
    mesh2d_bevy_bgl_mesh: None,
    mesh2d_bevy_bgl_material: None,
    mesh2d_bevy_view_buf: None,
    mesh2d_bevy_globals_buf: None,
    mesh2d_bevy_view_bg: None,
    mesh2d_bevy_lut_texture: None,
    mesh2d_bevy_lut_view: None,
    mesh2d_bevy_lut_sampler: None,
    mesh2d_bevy_instance_buf: None,
    mesh2d_bevy_instance_bg: None,
    mesh2d_bevy_instance_capacity: 0UL,
    mesh2d_bevy_instance_used: 0,
    mesh2d_pipeline_cache: [],
    mesh2d_material_bg_cache: [],
    mesh3d_bgl_uniform: None,
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
    mesh3d_uniform_slots: [],
    mesh3d_uniform_slot_used: 0,
    mesh3d_gpu_instance_builder_enabled: false,
    mesh3d_instance_uniform_buf: None,
    mesh3d_instance_uniform_bg: None,
    mesh3d_instance_uniform_capacity: 0UL,
    mesh3d_instance_uniform_used: 0,
    mesh3d_preprocess_camera_upload_states: [],
    mesh3d_motion_vector_bgl_uniform: None,
    mesh3d_motion_vector_pipeline_layout: None,
    mesh3d_motion_vector_pipeline: None,
    mesh3d_motion_vector_uniform_buf: None,
    mesh3d_motion_vector_uniform_bg: None,
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
    bloom2d_intermediate_bgl: None,
    bloom2d_intermediate_pipeline_layout: None,
    tonemapping2d_bgl: None,
    tonemapping2d_pipeline_layout: None,
    tonemapping2d_view_buf: None,
    tonemapping2d_sampler: None,
    tonemapping2d_pipeline_cache: [],
    bloom2d_downsample_first_pipeline: None,
    bloom2d_downsample_first_no_threshold_pipeline: None,
    bloom2d_downsample_first_uniform_pipeline: None,
    bloom2d_downsample_first_no_threshold_uniform_pipeline: None,
    bloom2d_downsample_pipeline: None,
    bloom2d_downsample_uniform_pipeline: None,
    bloom2d_upsample_pipeline_energy: None,
    bloom2d_upsample_pipeline_additive: None,
    bloom2d_upsample_final_pipeline_energy: None,
    bloom2d_upsample_final_pipeline_additive: None,
    bloom2d_upsample_final_pipeline_format: None,
    bloom2d_settings_buf: None,
    bloom2d_sampler: None,
    bloom2d_mip_texture: None,
    bloom2d_mip_views: [],
    bloom2d_mip_count: 0,
    bloom2d_mip_width: 0,
    bloom2d_mip_height: 0,
    tonemapping_fallback_lut_texture_id: -1,
    auto_exposure_compute_bgl: None,
    auto_exposure_compute_pipeline_layout: None,
    auto_exposure_histogram_pipeline: None,
    auto_exposure_average_pipeline: None,
    auto_exposure_settings_buf: None,
    auto_exposure_curve_extents_buf: None,
    auto_exposure_histogram_buf: None,
    auto_exposure_curve_texture: None,
    auto_exposure_curve_view: None,
    auto_exposure_dummy_state_buf: None,
    auto_exposure_active_state_buf: None,
    auto_exposure_view_states: [],
    mesh3d_material_bg_cache: [],
    sampler_cache: @hashmap.HashMap::new(),
    next_id: 1,
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
const MESH3D_SHADER_PATH : String = "shaders/bevy/mgstudio_runtime/mesh3d.wgsl"

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
fn join_asset_path(base : String, rel : String) -> String {
  if base == "" {
    rel
  } else {
    @path.Path::join(base, rel).normalize().to_string()
  }
}

///|
fn normalize_shader_rel_path(rel : String) -> String {
  let mut text = rel.trim().to_string()
  let n = text.length()
  let mut i = 0
  while i < n && text.code_unit_at(i).to_int() == 47 { // '/'
    i = i + 1
  }
  if i != 0 {
    text = text[i:n].to_string()
  }
  while text.length() >= 2 && text[:2].to_string() == "./" {
    text = text[2:text.length()].to_string()
  }
  if text.length() >= 7 && text[:7].to_string() == "assets/" {
    text = text[7:text.length()].to_string()
  }
  text
}

///|
fn starts_with_text(text : String, prefix : String) -> Bool {
  let p = prefix.length()
  if text.length() < p {
    return false
  }
  for i in 0..<p {
    if text.code_unit_at(i) != prefix.code_unit_at(i) {
      return false
    }
  }
  true
}

///|
fn ends_with_text(text : String, suffix : String) -> Bool {
  let n = text.length()
  let m = suffix.length()
  if n < m {
    return false
  }
  let offset = n - m
  for i in 0..<m {
    if text.code_unit_at(offset + i) != suffix.code_unit_at(i) {
      return false
    }
  }
  true
}

///|
fn trim_trailing_semicolons(text : String) -> String {
  let mut end = text.length()
  while end > 0 && text.code_unit_at(end - 1).to_int() == 59 { // ';'
    end = end - 1
  }
  if end == text.length() {
    text
  } else {
    text[:end].to_string()
  }
}

///|
priv struct WgslImportTarget {
  raw_path : String
  alias_name : String
}

///|
priv struct WgslResolvedImportModule {
  module_path : String
  rel_path : String
}

///|
fn join_wgsl_import_prefix(prefix : String, path : String) -> String {
  let lhs = prefix.trim().to_string()
  let rhs = path.trim().to_string()
  if lhs == "" {
    rhs
  } else if rhs == "" {
    lhs
  } else {
    lhs + "::" + rhs
  }
}

///|
fn wgsl_import_default_alias(module_path : String) -> String {
  let mut alias_name = ""
  for seg in module_path.split("::") {
    let text = seg.to_string().trim().to_string()
    if text != "" {
      alias_name = text
    }
  }
  alias_name
}

///|
fn split_top_level_wgsl_import_items(text : String) -> Array[String] {
  let items : Array[String] = []
  let mut start = 0
  let mut depth = 0
  for i in 0..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      continue
    }
    if ch == 44 && depth == 0 { // ','
      let item = text[start:i].to_string().trim().to_string()
      if item != "" {
        items.push(trim_trailing_semicolons(item))
      }
      start = i + 1
    }
  }
  let tail = text[start:text.length()].to_string().trim().to_string()
  if tail != "" {
    items.push(trim_trailing_semicolons(tail))
  }
  items
}

///|
fn find_top_level_wgsl_group_separator(text : String) -> Int {
  let mut depth = 0
  let mut i = 0
  while i + 2 < text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      i = i + 1
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      i = i + 1
      continue
    }
    if depth == 0 &&
      ch == 58 &&
      text.code_unit_at(i + 1).to_int() == 58 &&
      text.code_unit_at(i + 2).to_int() == 123 {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn extract_wgsl_group_body(text : String, open_brace_index : Int) -> String {
  let mut depth = 0
  let mut body_start = open_brace_index + 1
  for i in open_brace_index..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      if depth == 1 {
        body_start = i + 1
      }
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      if depth == 0 {
        return text[body_start:i].to_string()
      }
    }
  }
  ""
}

///|
fn collect_wgsl_import_targets(
  spec : String,
  prefix : String,
  targets : Array[WgslImportTarget],
) -> Unit {
  let text = trim_trailing_semicolons(spec.trim().to_string())
  if text == "" {
    return
  }
  let group_separator = find_top_level_wgsl_group_separator(text)
  if group_separator >= 0 {
    let group_prefix = text[:group_separator].to_string().trim().to_string()
    let body = extract_wgsl_group_body(text, group_separator + 2)
    let next_prefix = join_wgsl_import_prefix(prefix, group_prefix)
    for item in split_top_level_wgsl_import_items(body) {
      collect_wgsl_import_targets(item, next_prefix, targets)
    }
    return
  }
  let mut raw_path = text
  let mut alias_name = ""
  let mut saw_first = false
  for part in text.split(" as ") {
    if !saw_first {
      raw_path = part.to_string().trim().to_string()
      saw_first = true
      continue
    }
    alias_name = trim_trailing_semicolons(part.to_string().trim().to_string())
    break
  }
  raw_path = trim_trailing_semicolons(raw_path.trim().to_string())
  if raw_path == "" {
    return
  }
  targets.push(WgslImportTarget::{
    raw_path: join_wgsl_import_prefix(prefix, raw_path),
    alias_name,
  })
}

///|
fn path_is_file(path : String) -> Bool {
  @fs.is_file(path) catch {
    _ => false
  }
}

///|
fn path_is_file_exact(path : String) -> Bool {
  if !path_is_file(path) {
    return false
  }
  let mut sep_index = -1
  for i in 0..<path.length() {
    if path.code_unit_at(i).to_int() == 47 { // '/'
      sep_index = i
    }
  }
  let dir = if sep_index < 0 {
    "."
  } else if sep_index == 0 {
    "/"
  } else {
    path[:sep_index].to_string()
  }
  let base = if sep_index < 0 {
    path
  } else if sep_index + 1 >= path.length() {
    ""
  } else {
    path[sep_index + 1:path.length()].to_string()
  }
  if base == "" {
    return false
  }
  let entries : Array[String] = @fs.read_dir(dir) catch { _ => [] }
  for entry in entries {
    if entry.to_string() == base {
      return true
    }
  }
  false
}

///|
fn path_is_dir(path : String) -> Bool {
  @fs.is_dir(path) catch {
    _ => false
  }
}

///|
let registered_wgsl_sources_ref : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let registered_wgsl_import_modules_ref : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  registered_wgsl_sources_ref.val = @hashmap.HashMap::new()
  registered_wgsl_import_modules_ref.val = @hashmap.HashMap::new()
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  let normalized_rel = normalize_shader_rel_path(rel_path)
  if normalized_rel == "" {
    return
  }
  registered_wgsl_sources_ref.val.set(normalized_rel, source)
  let import_path = parse_wgsl_define_import_path(source)
  if import_path != "" {
    registered_wgsl_import_modules_ref.val.set(import_path, normalized_rel)
  }
}

///|
fn registered_wgsl_source(rel_path : String) -> String? {
  let normalized_rel = normalize_shader_rel_path(rel_path)
  if normalized_rel == "" {
    return None
  }
  registered_wgsl_sources_ref.val.get(normalized_rel)
}

///|
fn registered_wgsl_source_required(
  rel_path : String,
) -> String raise GpuBackendError {
  match registered_wgsl_source(rel_path) {
    Some(source) => source
    None => fatal("wgpu: missing registered WGSL source: " + rel_path)
  }
}

///|
fn copy_registered_wgsl_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  let copied : @hashmap.HashMap[String, String] = @hashmap.HashMap::new()
  for entry in registered_wgsl_import_modules_ref.val.iter() {
    let (module_path, rel_path) = entry
    copied.set(module_path, rel_path)
  }
  copied
}

///|
fn parse_wgsl_define_import_path(source : String) -> String {
  for line_item in source.split("\n") {
    let line = line_item.to_string().trim().to_string()
    if starts_with_text(line, "#define_import_path ") {
      return trim_trailing_semicolons(
        line[20:line.length()].to_string().trim().to_string(),
      )
    }
  }
  ""
}

///|
fn collect_wgsl_import_module_paths(
  assets_base : String,
  rel_dir : String,
  modules : @hashmap.HashMap[String, String],
) -> Unit {
  let dir_path = join_asset_path(assets_base, rel_dir)
  if !path_is_dir(dir_path) {
    return
  }
  let entries : Array[String] = @fs.read_dir(dir_path) catch { _ => [] }
  entries.sort()
  for entry in entries {
    let name = entry.trim().to_string()
    if name == "" {
      continue
    }
    let child_rel = if rel_dir == "" { name } else { rel_dir + "/" + name }
    let child_path = join_asset_path(assets_base, child_rel)
    if path_is_dir(child_path) {
      collect_wgsl_import_module_paths(assets_base, child_rel, modules)
      continue
    }
    if !path_is_file(child_path) || !ends_with_text(name, ".wgsl") {
      continue
    }
    let source = @fs.read_file_to_string(child_path) catch { _ => continue }
    let import_path = parse_wgsl_define_import_path(source)
    if import_path == "" {
      continue
    }
    let normalized_child_rel = normalize_shader_rel_path(child_rel)
    if !modules.contains(import_path) {
      modules.set(import_path, normalized_child_rel)
    }
  }
}

///|
fn build_wgsl_import_module_paths(
  assets_base : String,
) -> @hashmap.HashMap[String, String] {
  let modules = copy_registered_wgsl_import_module_paths()
  let normalized_assets_base = assets_base.trim().to_string()
  if normalized_assets_base != "" {
    collect_wgsl_import_module_paths(normalized_assets_base, "shaders", modules)
  }
  modules
}

///|
fn resolve_wgsl_import_module(
  assets_base : String,
  import_path : String,
  modules : @hashmap.HashMap[String, String],
) -> WgslResolvedImportModule? {
  let normalized_assets_base = assets_base.trim().to_string()
  let segments : Array[String] = []
  for seg in import_path.split("::") {
    let text = seg.to_string().trim().to_string()
    if text != "" {
      segments.push(text)
    }
  }
  while segments.length() > 0 {
    let mut module_path = segments[0]
    for i in 1..<segments.length() {
      module_path = module_path + "::" + segments[i]
    }
    if modules.get(module_path) is Some(rel_path) {
      return Some(WgslResolvedImportModule::{ module_path, rel_path })
    }
    if normalized_assets_base != "" {
      let bevy_rel = wgsl_module_path_to_rel_path(module_path)
      if path_is_file_exact(join_asset_path(normalized_assets_base, bevy_rel)) {
        return Some(WgslResolvedImportModule::{
          module_path,
          rel_path: bevy_rel,
        })
      }
      let namespace_rel = wgsl_module_path_to_rel_path_namespace(module_path)
      if namespace_rel != "" &&
        namespace_rel != bevy_rel &&
        path_is_file_exact(
          join_asset_path(normalized_assets_base, namespace_rel),
        ) {
        return Some(WgslResolvedImportModule::{
          module_path,
          rel_path: namespace_rel,
        })
      }
    }
    segments.pop() |> ignore
  }
  None
}

///|
fn wgsl_import_brace_balance(text : String) -> Int {
  let mut balance = 0
  for i in 0..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      balance = balance + 1
      continue
    }
    if ch == 125 { // '}'
      balance = balance - 1
    }
  }
  balance
}

///|
fn wgsl_module_path_to_rel_path(module_path : String) -> String {
  let mut rel = "shaders/bevy/"
  let mut first = true
  for seg in module_path.split("::") {
    let text = seg.to_string()
    if text == "" {
      continue
    }
    if first {
      first = false
    } else {
      rel = rel + "/"
    }
    rel = rel + text
  }
  rel + ".wgsl"
}

///|
fn wgsl_module_path_to_rel_path_namespace(module_path : String) -> String {
  let segments : Array[String] = []
  for seg in module_path.split("::") {
    let text = seg.to_string().trim().to_string()
    if text != "" {
      segments.push(text)
    }
  }
  if segments.length() == 0 {
    return ""
  }
  let mut rel = "shaders/" + segments[0]
  for i in 1..<segments.length() {
    rel = rel + "/" + segments[i]
  }
  rel + ".wgsl"
}

///|
fn strip_wgsl_line_comment(text : String) -> String {
  let mut i = 0
  while i + 1 < text.length() {
    if text.code_unit_at(i).to_int() == 47 && // '/'
      text.code_unit_at(i + 1).to_int() == 47 { // '/'
      return text[:i].to_string()
    }
    i = i + 1
  }
  text
}

///|
fn wgsl_directive_tail(text : String, prefix_length : Int) -> String {
  strip_wgsl_line_comment(text[prefix_length:text.length()].to_string())
  .trim()
  .to_string()
}

///|
fn parse_wgsl_uint_literal(text : String) -> Int? {
  let mut token = strip_wgsl_line_comment(text).trim().to_string()
  if token == "" {
    return None
  }
  if ends_with_text(token, "u") || ends_with_text(token, "U") {
    token = token[:token.length() - 1].to_string().trim().to_string()
  }
  if token == "" {
    return None
  }
  let parsed = @strconv.parse_int(token[:], base=10) catch { _ => return None }
  Some(parsed)
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
fn wgsl_define_value(
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  name : String,
) -> Int {
  if value_defines.get(name) is Some(value) {
    return value
  }
  if defines.get(name) is Some(flag) && flag {
    return 1
  }
  0
}

///|
fn wgsl_define_enabled(
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  name : String,
) -> Bool {
  if value_defines.contains(name) {
    return true
  }
  defines.get(name).unwrap_or(false)
}

///|
fn wgsl_if_expr_value(
  token : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> Int {
  let text = strip_wgsl_line_comment(token).trim().to_string()
  if text == "" {
    return 0
  }
  if parse_wgsl_uint_literal(text) is Some(value) {
    return value
  }
  wgsl_define_value(defines, value_defines, text)
}

///|
fn eval_wgsl_if_expr(
  expr : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> Bool {
  let text = strip_wgsl_line_comment(expr).trim().to_string()
  if text == "" {
    return false
  }
  if split_once_text(text, ">=") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) >=
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  if split_once_text(text, "<=") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) <=
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  if split_once_text(text, "==") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) ==
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  if split_once_text(text, "!=") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) !=
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  if split_once_text(text, ">") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) >
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  if split_once_text(text, "<") is Some((lhs, rhs)) {
    return wgsl_if_expr_value(lhs, defines, value_defines) <
      wgsl_if_expr_value(rhs, defines, value_defines)
  }
  wgsl_if_expr_value(text, defines, value_defines) != 0
}

///|
fn apply_wgsl_template_consts(
  source : String,
  value_defines : @hashmap.HashMap[String, Int],
) -> String {
  let mut out = ""
  let mut i = 0
  let n = source.length()
  while i < n {
    if i + 1 < n &&
      source.code_unit_at(i).to_int() == 35 && // '#'
      source.code_unit_at(i + 1).to_int() == 123 { // '{'
      let mut j = i + 2
      while j < n && source.code_unit_at(j).to_int() != 125 { // '}'
        j = j + 1
      }
      if j < n {
        let name = source[i + 2:j].to_string().trim().to_string()
        if value_defines.get(name) is Some(value) {
          out = out + value.to_string()
          i = j + 1
          continue
        }
      }
    }
    out = out + source[i:i + 1].to_string()
    i = i + 1
  }
  out
}

///|
fn default_wgsl_value_defines() -> @hashmap.HashMap[String, Int] {
  let defines : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
  defines.set("AVAILABLE_STORAGE_BUFFER_BINDINGS", 8)
  defines.set("MAX_DIRECTIONAL_LIGHTS", 10)
  defines.set("MAX_CASCADES_PER_LIGHT", 4)
  defines.set("MATERIAL_BIND_GROUP", 3)
  defines.set("SORTED_FRAGMENT_MAX_COUNT", 8)
  defines.set("WORLD_CACHE_SIZE", 1048576)
  defines.set("PER_OBJECT_BUFFER_BATCH_SIZE", 1)
  defines.set("SCREEN_SPACE_SPECULAR_TRANSMISSION_BLUR_TAPS", 8)
  defines
}

///|
fn apply_wgsl_ifdefs(
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> String {
  let mut out = ""
  let active_stack : Array[Bool] = [true]
  let branch_taken_stack : Array[Bool] = []
  for line_item in source.split("\n") {
    let line = line_item.to_string()
    let trimmed = line.trim().to_string()
    if starts_with_text(trimmed, "#ifdef ") {
      let name = wgsl_directive_tail(trimmed, 7)
      let cond = wgsl_define_enabled(defines, value_defines, name)
      let parent = active_stack[active_stack.length() - 1]
      active_stack.push(parent && cond)
      branch_taken_stack.push(cond)
      continue
    }
    if starts_with_text(trimmed, "#ifndef ") {
      let name = wgsl_directive_tail(trimmed, 8)
      let cond = !wgsl_define_enabled(defines, value_defines, name)
      let parent = active_stack[active_stack.length() - 1]
      active_stack.push(parent && cond)
      branch_taken_stack.push(cond)
      continue
    }
    if starts_with_text(trimmed, "#if ") {
      let expr = wgsl_directive_tail(trimmed, 4)
      let cond = eval_wgsl_if_expr(expr, defines, value_defines)
      let parent = active_stack[active_stack.length() - 1]
      active_stack.push(parent && cond)
      branch_taken_stack.push(cond)
      continue
    }
    if starts_with_text(trimmed, "#else ifdef ") {
      if branch_taken_stack.length() > 0 {
        let idx = branch_taken_stack.length() - 1
        let name = wgsl_directive_tail(trimmed, 13)
        let cond = !branch_taken_stack[idx] &&
          wgsl_define_enabled(defines, value_defines, name)
        let parent = if active_stack.length() >= 2 {
          active_stack[active_stack.length() - 2]
        } else {
          true
        }
        active_stack[active_stack.length() - 1] = parent && cond
        branch_taken_stack[idx] = branch_taken_stack[idx] || cond
      }
      continue
    }
    if starts_with_text(trimmed, "#else ifndef ") {
      if branch_taken_stack.length() > 0 {
        let idx = branch_taken_stack.length() - 1
        let name = wgsl_directive_tail(trimmed, 14)
        let cond = !branch_taken_stack[idx] &&
          !wgsl_define_enabled(defines, value_defines, name)
        let parent = if active_stack.length() >= 2 {
          active_stack[active_stack.length() - 2]
        } else {
          true
        }
        active_stack[active_stack.length() - 1] = parent && cond
        branch_taken_stack[idx] = branch_taken_stack[idx] || cond
      }
      continue
    }
    if starts_with_text(trimmed, "#else") {
      if branch_taken_stack.length() > 0 {
        let idx = branch_taken_stack.length() - 1
        let cond = !branch_taken_stack[idx]
        let parent = if active_stack.length() >= 2 {
          active_stack[active_stack.length() - 2]
        } else {
          true
        }
        active_stack[active_stack.length() - 1] = parent && cond
        branch_taken_stack[idx] = branch_taken_stack[idx] || cond
      }
      continue
    }
    if starts_with_text(trimmed, "#endif") {
      if active_stack.length() > 1 {
        active_stack.pop() |> ignore
      }
      if branch_taken_stack.length() > 0 {
        branch_taken_stack.pop() |> ignore
      }
      continue
    }
    if active_stack[active_stack.length() - 1] {
      out = out + line + "\n"
    }
  }
  out
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
  let mut merged = ""
  let aliases : Array[String] = []
  let lines : Array[String] = []
  let import_active_stack : Array[Bool] = [true]
  let import_branch_taken_stack : Array[Bool] = []
  for line_item in source.split("\n") {
    lines.push(line_item.to_string())
  }
  let mut line_index = 0
  while line_index < lines.length() {
    let line = lines[line_index]
    let trimmed = line.trim().to_string()
    if starts_with_text(trimmed, "#ifdef ") {
      let name = wgsl_directive_tail(trimmed, 7)
      let cond = wgsl_define_enabled(defines, value_defines, name)
      let parent = import_active_stack[import_active_stack.length() - 1]
      import_active_stack.push(parent && cond)
      import_branch_taken_stack.push(cond)
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#ifndef ") {
      let name = wgsl_directive_tail(trimmed, 8)
      let cond = !wgsl_define_enabled(defines, value_defines, name)
      let parent = import_active_stack[import_active_stack.length() - 1]
      import_active_stack.push(parent && cond)
      import_branch_taken_stack.push(cond)
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#if ") {
      let expr = wgsl_directive_tail(trimmed, 4)
      let cond = eval_wgsl_if_expr(expr, defines, value_defines)
      let parent = import_active_stack[import_active_stack.length() - 1]
      import_active_stack.push(parent && cond)
      import_branch_taken_stack.push(cond)
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#else ifdef ") {
      if import_branch_taken_stack.length() > 0 {
        let idx = import_branch_taken_stack.length() - 1
        let name = wgsl_directive_tail(trimmed, 13)
        let cond = !import_branch_taken_stack[idx] &&
          wgsl_define_enabled(defines, value_defines, name)
        let parent = if import_active_stack.length() >= 2 {
          import_active_stack[import_active_stack.length() - 2]
        } else {
          true
        }
        import_active_stack[import_active_stack.length() - 1] = parent && cond
        import_branch_taken_stack[idx] = import_branch_taken_stack[idx] || cond
      }
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#else ifndef ") {
      if import_branch_taken_stack.length() > 0 {
        let idx = import_branch_taken_stack.length() - 1
        let name = wgsl_directive_tail(trimmed, 14)
        let cond = !import_branch_taken_stack[idx] &&
          !wgsl_define_enabled(defines, value_defines, name)
        let parent = if import_active_stack.length() >= 2 {
          import_active_stack[import_active_stack.length() - 2]
        } else {
          true
        }
        import_active_stack[import_active_stack.length() - 1] = parent && cond
        import_branch_taken_stack[idx] = import_branch_taken_stack[idx] || cond
      }
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#else") {
      if import_branch_taken_stack.length() > 0 {
        let idx = import_branch_taken_stack.length() - 1
        let cond = !import_branch_taken_stack[idx]
        let parent = if import_active_stack.length() >= 2 {
          import_active_stack[import_active_stack.length() - 2]
        } else {
          true
        }
        import_active_stack[import_active_stack.length() - 1] = parent && cond
        import_branch_taken_stack[idx] = import_branch_taken_stack[idx] || cond
      }
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#endif") {
      if import_active_stack.length() > 1 {
        import_active_stack.pop() |> ignore
      }
      if import_branch_taken_stack.length() > 0 {
        import_branch_taken_stack.pop() |> ignore
      }
      merged = merged + line + "\n"
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#define_import_path") {
      line_index = line_index + 1
      continue
    }
    if starts_with_text(trimmed, "#import ") {
      if !import_active_stack[import_active_stack.length() - 1] {
        merged = merged + line + "\n"
        line_index = line_index + 1
        continue
      }
      let mut spec = trimmed[8:trimmed.length()].to_string()
      let mut brace_balance = wgsl_import_brace_balance(spec)
      while brace_balance > 0 && line_index + 1 < lines.length() {
        line_index = line_index + 1
        let next_line = lines[line_index]
        spec = spec + "\n" + next_line
        brace_balance = brace_balance + wgsl_import_brace_balance(next_line)
      }
      let targets : Array[WgslImportTarget] = []
      collect_wgsl_import_targets(spec, "", targets)
      for target in targets {
        guard resolve_wgsl_import_module(assets_base, target.raw_path, modules)
          is Some(resolved_module) else {
          fatal("wgpu: failed to resolve shader import: " + target.raw_path)
        }
        let module_path = resolved_module.module_path
        let module_alias = if target.alias_name != "" {
          target.alias_name
        } else if module_path == target.raw_path {
          wgsl_import_default_alias(module_path)
        } else {
          ""
        }
        if module_alias != "" && !source.contains(module_alias + "::") {
          continue
        }
        if module_alias != "" {
          aliases.push(module_alias)
        }
        let module_source = load_wgsl_preprocessed(
          assets_base,
          resolved_module.rel_path,
          defines,
          value_defines,
          visited,
          modules,
        )
        if module_source != "" {
          merged = merged + module_source
          let merged_len = merged.length()
          if merged_len == 0 ||
            merged.code_unit_at(merged_len - 1).to_int() != 10 {
            merged = merged + "\n"
          }
        }
      }
      line_index = line_index + 1
      continue
    }
    merged = merged + line + "\n"
    line_index = line_index + 1
  }
  let mut out = apply_wgsl_ifdefs(merged, defines, value_defines)
  out = apply_wgsl_template_consts(out, value_defines)
  for module_alias in aliases {
    out = replace_substring_all(out, module_alias + "::", "")
  }
  out
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
  let normalized_rel = normalize_shader_rel_path(rel)
  if normalized_rel == "" {
    return ""
  }
  if visited.contains(normalized_rel) {
    return ""
  }
  visited.set(normalized_rel, true)
  let source = match registered_wgsl_sources_ref.val.get(normalized_rel) {
    Some(source) => source
    None => {
      let normalized_assets_base = assets_base.trim().to_string()
      if normalized_assets_base == "" {
        fatal(
          "wgpu: shader source was not startup-registered: " + normalized_rel,
        )
      }
      let full_path = join_asset_path(normalized_assets_base, normalized_rel)
      @fs.read_file_to_string(full_path) catch {
        err =>
          fatal(
            "wgpu: failed to read shader: " + full_path + ": " + err.to_string(),
          )
      }
    }
  }
  preprocess_wgsl_source(
    assets_base, source, defines, value_defines, visited, modules,
  )
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
  let base = assets_base.trim().to_string()
  if base == "" {
    fatal("wgpu: assets_base is empty; cannot load shader: " + rel)
  }
  let normalized_rel = normalize_shader_rel_path(rel)
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(base)
  load_wgsl_preprocessed(
    base, normalized_rel, defines, value_defines, visited, modules,
  )
}

///|
fn replace_substring_all(source : String, from : String, to : String) -> String {
  if from == "" {
    return source
  }
  let mut out = ""
  let mut first = true
  for piece in source.split(from) {
    if first {
      first = false
    } else {
      out = out + to
    }
    out = out + piece.to_string()
  }
  out
}

///|
fn create_uniform_bind_group_layout_vertex_fragment(
  backend : GpuBackend,
  label : String,
  has_dynamic_offset? : Bool = false,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    has_dynamic_offset~,
  )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build uniform bind group layout")
  }
  builder.finish(backend.device, label~)
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
  let vertex_stride = if position3d { 36UL } else { 32UL }
  let pos_format = if position3d {
    @wgpu.VERTEX_FORMAT_FLOAT32X3
  } else {
    @wgpu.VERTEX_FORMAT_FLOAT32X2
  }
  let uv_offset = if position3d { 12UL } else { 8UL }
  let color_offset = if position3d { 20UL } else { 16UL }
  let set_vertex_layout_err = @wgpu_c.render_pipeline_desc_builder_set_vertex_buffer_layout(
    builder,
    vertex_stride,
    @wgpu.VERTEX_STEP_MODE_VERTEX,
  )
  let pos_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder, pos_format, 0UL, 0U,
  )
  let uv_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X2,
    uv_offset,
    1U,
  )
  let color_err = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X4,
    color_offset,
    2U,
  )
  if set_format_err != 0U ||
    set_blend_err != 0U ||
    set_vertex_layout_err != 0U ||
    pos_err != 0U ||
    uv_err != 0U ||
    color_err != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: failed to configure mesh vertex attributes for pos2+uv2+color4 pipeline",
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
  let last_error = @wgpu_c.render_pipeline_desc_builder_last_error_u32(builder)
  if last_error != 0U || @wgpu_c.render_pipeline_descriptor_ptr_is_null(desc) {
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
