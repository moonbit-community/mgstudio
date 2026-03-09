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
/// Use wgpu_mbt's "alpha blend + arbitrary format" render pipeline descriptor
/// helper (added in wgpu_mbt 0.2.2).
const MESH2D_UNIFORM_BUFFER_SIZE : UInt64 = 80UL

///|
const MESH3D_UNIFORM_BUFFER_SIZE : UInt64 = 512UL

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
  camera_rot_x : Float
  camera_rot_y : Float
  camera_rot_z : Float
  camera_rot_w : Float
  previous_camera_x : Float
  previous_camera_y : Float
  previous_camera_z : Float
  previous_camera_rot_x : Float
  previous_camera_rot_y : Float
  previous_camera_rot_z : Float
  previous_camera_rot_w : Float
  camera_fov_y : Float
  camera_near : Float
  camera_far : Float
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
  sub_camera_view_scale_x : Float
  sub_camera_view_scale_y : Float
  sub_camera_view_bias_x : Float
  sub_camera_view_bias_y : Float
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
priv struct PendingScreenshotCapture {
  id : Int
  width : Int
  height : Int
  format_raw : UInt
  texture : @wgpu.Texture
}

///|
priv struct InflightScreenshotCapture {
  id : Int
  width : Int
  height : Int
  format_raw : UInt
  buffer : @wgpu.Buffer
  byte_len : UInt64
}

///|
pub struct ScreenshotCaptureResult {
  id : Int
  width : Int
  height : Int
  pixels : Bytes
}

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
  mut surface_capture_texture_id : Int
  mut surface_capture_active : Bool
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
  mut sprite_instance_capacity : UInt64
  mut sprite_globals_bg : @wgpu.BindGroup?
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
  mut mesh_bgl_uniform : @wgpu.BindGroupLayout?
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : @wgpu.TextureFormat?
  mesh_uniform_slots : Array[GpuUniformSlot]
  mut mesh_uniform_slot_used : Int
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
  mut bloom2d_intermediate_bgl : @wgpu.BindGroupLayout?
  mut bloom2d_intermediate_pipeline_layout : @wgpu.PipelineLayout?
  mut bloom2d_final_bgl : @wgpu.BindGroupLayout?
  mut bloom2d_final_pipeline_layout : @wgpu.PipelineLayout?
  mut bloom2d_downsample_first_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_no_threshold_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_first_no_threshold_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_downsample_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_upsample_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom2d_upsample_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom2d_final_pipeline : @wgpu.RenderPipeline?
  mut bloom2d_final_pipeline_surface : @wgpu.RenderPipeline?
  mut bloom2d_final_pipeline_surface_format : @wgpu.TextureFormat?
  mut bloom2d_settings_buf : @wgpu.Buffer?
  mut bloom2d_sampler : @wgpu.Sampler?
  mut bloom2d_mip_texture : @wgpu.Texture?
  bloom2d_mip_views : Array[@wgpu.TextureView]
  mut bloom2d_mip_count : Int
  mut bloom2d_mip_width : Int
  mut bloom2d_mip_height : Int
  mesh3d_material_bg_cache : Ref[Array[Mesh3dMaterialBindGroupCacheEntry]]
  sampler_cache : Ref[@hashmap.HashMap[String, @wgpu.Sampler]]
  next_id : Ref[Int]
  mut point_shadow_fallback_texture_id : Int
  mut shadow_color_texture : @wgpu.Texture?
  mut shadow_color_view : @wgpu.TextureView?
  mut shadow_color_width : Int
  mut shadow_color_height : Int
  textures : Ref[Array[GpuTextureInfo]]
  meshes : Ref[Array[GpuMeshInfo]]
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
    surface_capture_texture_id: -1,
    surface_capture_active: false,
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
    sprite_instance_capacity: 0UL,
    sprite_globals_bg: None,
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
    mesh_bgl_uniform: None,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_pipeline_surface: None,
    mesh_pipeline_surface_format: None,
    mesh_uniform_slots: [],
    mesh_uniform_slot_used: 0,
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
    bloom2d_intermediate_bgl: None,
    bloom2d_intermediate_pipeline_layout: None,
    bloom2d_final_bgl: None,
    bloom2d_final_pipeline_layout: None,
    bloom2d_downsample_first_pipeline: None,
    bloom2d_downsample_first_no_threshold_pipeline: None,
    bloom2d_downsample_first_uniform_pipeline: None,
    bloom2d_downsample_first_no_threshold_uniform_pipeline: None,
    bloom2d_downsample_pipeline: None,
    bloom2d_downsample_uniform_pipeline: None,
    bloom2d_upsample_pipeline_energy: None,
    bloom2d_upsample_pipeline_additive: None,
    bloom2d_final_pipeline: None,
    bloom2d_final_pipeline_surface: None,
    bloom2d_final_pipeline_surface_format: None,
    bloom2d_settings_buf: None,
    bloom2d_sampler: None,
    bloom2d_mip_texture: None,
    bloom2d_mip_views: [],
    bloom2d_mip_count: 0,
    bloom2d_mip_width: 0,
    bloom2d_mip_height: 0,
    mesh3d_material_bg_cache: Ref::new([]),
    sampler_cache: Ref::new(@hashmap.HashMap::new()),
    next_id: Ref::new(1),
    point_shadow_fallback_texture_id: -1,
    shadow_color_texture: None,
    shadow_color_view: None,
    shadow_color_width: 0,
    shadow_color_height: 0,
    textures: Ref::new([]),
    meshes: Ref::new([]),
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
fn absf(x : Float) -> Float {
  if x < 0.0F {
    -x
  } else {
    x
  }
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
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
extern "C" fn wgpu_render_pipeline_desc_builder_set_front_face(
  builder : @wgpu_c.OpaquePtr,
  front_face_u32 : UInt,
) -> UInt = "mbt_wgpu_render_pipeline_desc_builder_set_front_face"

///|
extern "C" fn wgpu_render_pipeline_desc_builder_set_cull_mode(
  builder : @wgpu_c.OpaquePtr,
  cull_mode_u32 : UInt,
) -> UInt = "mbt_wgpu_render_pipeline_desc_builder_set_cull_mode"

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
  let id = backend.next_id.val
  backend.next_id.val = id + 1
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
  match backend.sampler_cache.val.get(key) {
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
      backend.sampler_cache.val.set(key, sampler)
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
    text = (try! text[i:n]).to_string()
  }
  while text.length() >= 2 && (try! text[:2].to_string()) == "./" {
    text = try! text[2:text.length()].to_string()
  }
  if text.length() >= 7 && (try! text[:7].to_string()) == "assets/" {
    text = try! text[7:text.length()].to_string()
  }
  text
}

///|
fn is_motion_blur_shader_path(rel : String) -> Bool {
  normalize_shader_rel_path(rel) == "shaders/mgstudio/3d/motion_blur.wgsl"
}

///|
fn starts_with_text(text : String, prefix : String) -> Bool {
  let p = prefix.length()
  if text.length() < p {
    return false
  }
  try! (text[:p].to_string() == prefix)
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
    try! text[:end].to_string()
  }
}

///|
fn parse_wgsl_import_module_path(spec : String) -> String {
  let mut path = spec.trim().to_string()
  for part in path.split(" as ") {
    path = part.to_string().trim().to_string()
    break
  }
  for part in path.split("::{") {
    path = part.to_string().trim().to_string()
    break
  }
  path = trim_trailing_semicolons(path.trim().to_string())
  if path == "" {
    return ""
  }
  let segments_raw = path.split("::")
  let segments : Array[String] = []
  for seg in segments_raw {
    let text = seg.to_string()
    if text != "" {
      segments.push(text)
    }
  }
  if segments.length() == 0 {
    return ""
  }
  let last = segments[segments.length() - 1]
  if last.length() > 0 {
    let first = last.code_unit_at(0).to_int()
    if first >= 65 && first <= 90 {
      segments.pop() |> ignore
    }
  }
  if segments.length() == 0 {
    return ""
  }
  let mut out = segments[0]
  for i in 1..<segments.length() {
    out = out + "::" + segments[i]
  }
  out
}

///|
fn parse_wgsl_import_alias(spec : String, module_path : String) -> String {
  let text = trim_trailing_semicolons(spec.trim().to_string())
  if text == "" {
    return ""
  }
  let mut saw_first = false
  let mut alias_name = ""
  for part in text.split(" as ") {
    if !saw_first {
      saw_first = true
      continue
    }
    alias_name = trim_trailing_semicolons(part.to_string().trim().to_string())
  }
  if alias_name != "" {
    return alias_name
  }
  if module_path == "" {
    return ""
  }
  let mut alias_name = ""
  for seg in module_path.split("::") {
    let s = seg.to_string().trim().to_string()
    if s != "" {
      alias_name = s
    }
  }
  alias_name
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
fn apply_wgsl_ifdefs(
  source : String,
  defines : @hashmap.HashMap[String, Bool],
) -> String {
  let mut out = ""
  let active_stack : Array[Bool] = [true]
  let branch_taken_stack : Array[Bool] = []
  for line_item in source.split("\n") {
    let line = line_item.to_string()
    let trimmed = line.trim().to_string()
    if starts_with_text(trimmed, "#ifdef ") {
      let name = try! trimmed[7:trimmed.length()].to_string().trim().to_string()
      let cond = defines.get(name).unwrap_or(false)
      let parent = active_stack[active_stack.length() - 1]
      active_stack.push(parent && cond)
      branch_taken_stack.push(cond)
      continue
    }
    if starts_with_text(trimmed, "#ifndef ") {
      let name = try! trimmed[8:trimmed.length()].to_string().trim().to_string()
      let cond = !defines.get(name).unwrap_or(false)
      let parent = active_stack[active_stack.length() - 1]
      active_stack.push(parent && cond)
      branch_taken_stack.push(cond)
      continue
    }
    if starts_with_text(trimmed, "#else ifdef ") {
      if branch_taken_stack.length() > 0 {
        let idx = branch_taken_stack.length() - 1
        let name = try! trimmed[13:trimmed.length()]
          .to_string()
          .trim()
          .to_string()
        let cond = !branch_taken_stack[idx] &&
          defines.get(name).unwrap_or(false)
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
        let name = try! trimmed[14:trimmed.length()]
          .to_string()
          .trim()
          .to_string()
        let cond = !branch_taken_stack[idx] &&
          !defines.get(name).unwrap_or(false)
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
    if trimmed == "#else" {
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
    if trimmed == "#endif" {
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
  visited : @hashmap.HashMap[String, Bool],
) -> String raise GpuBackendError {
  let mut merged = ""
  let aliases : Array[String] = []
  for line_item in source.split("\n") {
    let line = line_item.to_string()
    let trimmed = line.trim().to_string()
    if starts_with_text(trimmed, "#define_import_path") {
      continue
    }
    if starts_with_text(trimmed, "#import ") {
      let spec = try! trimmed[8:trimmed.length()].to_string()
      let module_path = parse_wgsl_import_module_path(spec)
      if module_path == "" {
        continue
      }
      let module_alias = parse_wgsl_import_alias(spec, module_path)
        .trim()
        .to_string()
      if module_alias != "" {
        aliases.push(module_alias)
      }
      let module_rel = wgsl_module_path_to_rel_path(module_path)
      let module_source = load_wgsl_preprocessed(
        assets_base, module_rel, defines, visited,
      )
      if module_source != "" {
        merged = merged + module_source
        let merged_len = merged.length()
        if merged_len == 0 || merged.code_unit_at(merged_len - 1).to_int() != 10 {
          merged = merged + "\n"
        }
      }
      continue
    }
    merged = merged + line + "\n"
  }
  let mut out = apply_wgsl_ifdefs(merged, defines)
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
  visited : @hashmap.HashMap[String, Bool],
) -> String raise GpuBackendError {
  let normalized_rel = normalize_shader_rel_path(rel)
  if normalized_rel == "" {
    return ""
  }
  if visited.contains(normalized_rel) {
    return ""
  }
  visited.set(normalized_rel, true)
  let full_path = join_asset_path(assets_base, normalized_rel)
  let source = @fs.read_file_to_string(full_path) catch {
    err =>
      fatal(
        "wgpu: failed to read shader: " + full_path + ": " + err.to_string(),
      )
  }
  preprocess_wgsl_source(assets_base, source, defines, visited)
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
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let source = load_wgsl_preprocessed(base, normalized_rel, defines, visited)
  if is_motion_blur_shader_path(normalized_rel) {
    lower_motion_blur_texture_samples_for_runtime(source)
  } else {
    source
  }
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
fn lower_motion_blur_texture_samples_for_runtime(source : String) -> String {
  let mut out = source
  out = replace_substring_all(
    out, "textureSample(screen_texture, texture_sampler, in.uv)", "textureSampleLevel(screen_texture, texture_sampler, in.uv, 0.0)",
  )
  out = replace_substring_all(
    out, "textureSample(motion_vectors, texture_sampler, in.uv).rg", "textureSampleLevel(motion_vectors, texture_sampler, in.uv, 0.0).rg",
  )
  out = replace_substring_all(
    out, "textureSample(depth, texture_sampler, in.uv)", "textureLoad(depth, frag_coords, 0)",
  )
  out = replace_substring_all(
    out, "textureSample(screen_texture, texture_sampler, sample_uv)", "textureSampleLevel(screen_texture, texture_sampler, sample_uv, 0.0)",
  )
  out = replace_substring_all(
    out, "textureSample(motion_vectors, texture_sampler, sample_uv).rg", "textureSampleLevel(motion_vectors, texture_sampler, sample_uv, 0.0).rg",
  )
  replace_substring_all(
    out, "textureSample(depth, texture_sampler, sample_uv)", "textureLoad(depth, sample_coords, 0)",
  )
}

///|
fn ensure_sprite_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.sprite_pipeline_layout is Some(_) {
    return
  }
  // Texture binding group (fragment stage).
  let b0 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok0 = b0.add_sampler(
    0U,
    ss(@wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
  )
  let ok1 = b0.add_texture(
    1U,
    ss(@wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
  )
  if !ok0 || !ok1 {
    b0.free()
    return
  }
  let bgl_tex = b0.finish(backend.device, label="mgstudio_sprite_tex")

  // Globals + instances group (vertex stage).
  let b1 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok2 = b1.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
  )
  let ok3 = b1.add_buffer(
    1U,
    ss(@wgpu.SHADER_STAGE_VERTEX),
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  if !ok2 || !ok3 {
    b1.free()
    fatal("wgpu: failed to build sprite bind group layout")
  }
  let bgl_globals = b1.finish(backend.device, label="mgstudio_sprite_globals")
  let pl = backend.device.create_pipeline_layout_2(bgl_tex, bgl_globals)
  let globals_usage = bu(
    @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let globals_buf = backend.device.create_buffer(size=32UL, usage=globals_usage)
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.sprite_bgl_tex = Some(bgl_tex)
  backend.sprite_bgl_globals = Some(bgl_globals)
  backend.sprite_pipeline_layout = Some(pl)
  backend.sprite_globals_buf = Some(globals_buf)
  backend.sprite_instance_buf = Some(instance_buf)
  backend.sprite_instance_capacity = instance_cap
  backend.sprite_globals_bg = None
  backend.sprite_instance_data.clear()
  backend.sprite_batches.clear()
  backend.sprite_instance_count = 0U
}

///|
fn create_uniform_bind_group_layout_vertex_fragment(
  backend : GpuBackend,
  label : String,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
  )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build uniform bind group layout")
  }
  builder.finish(backend.device, label~)
}

///|
fn ensure_mesh_uniform_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuUniformSlot? {
  guard backend.mesh_bgl_uniform is Some(bgl) else { return None }
  let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh_uniform_slots.length() <= slot_index {
    let uniform_buf = backend.device.create_buffer(
      size=MESH2D_UNIFORM_BUFFER_SIZE,
      usage=ubo_usage,
    )
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh_uniform_slots.push(GpuUniformSlot::{
      buffer: uniform_buf,
      bind_group: uniform_bg,
    })
  }
  Some(backend.mesh_uniform_slots[slot_index])
}

///|
fn ensure_mesh3d_uniform_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuUniformSlot? {
  guard backend.mesh3d_bgl_uniform is Some(bgl) else { return None }
  let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_uniform_slots.length() <= slot_index {
    let uniform_buf = backend.device.create_buffer(
      size=MESH3D_UNIFORM_BUFFER_SIZE,
      usage=ubo_usage,
    )
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh3d_uniform_slots.push(GpuUniformSlot::{
      buffer: uniform_buf,
      bind_group: uniform_bg,
    })
  }
  Some(backend.mesh3d_uniform_slots[slot_index])
}

///|
fn ensure_sprite_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.sprite_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/sprite.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_sprite_rgba8")
  backend.sprite_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_sprite_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.sprite_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.sprite_pipeline_surface is Some(_) {
    return
  }
  if backend.sprite_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/sprite.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_sprite_surface")
  backend.sprite_pipeline_surface = Some(pipeline)
  backend.sprite_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn sprite_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_sprite_pipeline_surface(backend, format)
      backend.sprite_pipeline_surface
    }
    _ => {
      ensure_sprite_pipeline_rgba8(backend)
      backend.sprite_pipeline
    }
  }
}

///|
fn ensure_sprite_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.sprite_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.sprite_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build sprite globals bind group")
  }
  let bg = b.finish(backend.device, layout, label="mgstudio_sprite_globals")
  backend.sprite_globals_bg = Some(bg)
}

///|
fn ensure_ui_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_instance_buf is Some(_) {
    return
  }
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.ui_instance_buf = Some(instance_buf)
  backend.ui_instance_capacity = instance_cap
  backend.ui_globals_bg = None
  backend.ui_instance_data.clear()
  backend.ui_batches.clear()
  backend.ui_instance_count = 0U
}

///|
fn ensure_ui_pipeline_rgba8(backend : GpuBackend) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if backend.ui_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/ui.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_rgba8")
  backend.ui_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_ui_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/ui.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_surface")
  backend.ui_pipeline_surface = Some(pipeline)
  backend.ui_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn ui_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_pipeline_surface(backend, format)
      backend.ui_pipeline_surface
    }
    _ => {
      ensure_ui_pipeline_rgba8(backend)
      backend.ui_pipeline
    }
  }
}

///|
fn ensure_ui_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui globals bind group")
  }
  let bg = b.finish(backend.device, layout, label="mgstudio_ui_globals")
  backend.ui_globals_bg = Some(bg)
}

///|
fn ensure_ui_shadow_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_shadow_instance_buf is Some(_) {
    return
  }
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.ui_shadow_instance_buf = Some(instance_buf)
  backend.ui_shadow_instance_capacity = instance_cap
  backend.ui_shadow_globals_bg = None
  backend.ui_shadow_instance_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_instance_count = 0U
}

///|
fn ensure_ui_shadow_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  if backend.ui_shadow_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/box_shadow.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_box_shadow_rgba8")
  backend.ui_shadow_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_ui_shadow_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_shadow_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_shadow_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_shadow_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/box_shadow.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_box_shadow_surface")
  backend.ui_shadow_pipeline_surface = Some(pipeline)
  backend.ui_shadow_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn ui_shadow_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_shadow_pipeline_surface(backend, format)
      backend.ui_shadow_pipeline_surface
    }
    _ => {
      ensure_ui_shadow_pipeline_rgba8(backend)
      backend.ui_shadow_pipeline
    }
  }
}

///|
fn ensure_ui_shadow_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_shadow_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_shadow_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui box shadow globals bind group")
  }
  let bg = b.finish(
    backend.device,
    layout,
    label="mgstudio_ui_box_shadow_globals",
  )
  backend.ui_shadow_globals_bg = Some(bg)
}

///|
fn ensure_ui_slice_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_slice_instance_buf is Some(_) {
    return
  }
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.ui_slice_instance_buf = Some(instance_buf)
  backend.ui_slice_instance_capacity = instance_cap
  backend.ui_slice_globals_bg = None
  backend.ui_slice_instance_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_instance_count = 0U
}

///|
fn ensure_ui_slice_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  if backend.ui_slice_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/ui_texture_slice.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_texture_slice_rgba8")
  backend.ui_slice_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_ui_slice_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_slice_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_slice_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_slice_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/ui/ui_texture_slice.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_texture_slice_surface")
  backend.ui_slice_pipeline_surface = Some(pipeline)
  backend.ui_slice_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn ui_slice_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_slice_pipeline_surface(backend, format)
      backend.ui_slice_pipeline_surface
    }
    _ => {
      ensure_ui_slice_pipeline_rgba8(backend)
      backend.ui_slice_pipeline
    }
  }
}

///|
fn ensure_ui_slice_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_slice_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_slice_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui texture slice globals bind group")
  }
  let bg = b.finish(
    backend.device,
    layout,
    label="mgstudio_ui_texture_slice_globals",
  )
  backend.ui_slice_globals_bg = Some(bg)
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
  // Our runtime clip-space winding is flipped relative to Bevy, so CW must be
  // treated as front-facing to keep Face3d front/back culling semantics aligned.
  let set_front_face_ok = wgpu_render_pipeline_desc_builder_set_front_face(
    builder,
    @wgpu.FRONT_FACE_CW,
  )
  let set_cull_mode_ok = wgpu_render_pipeline_desc_builder_set_cull_mode(
    builder, cull_mode,
  )
  if set_topology_err != 0U || set_front_face_ok != 0U || set_cull_mode_ok != 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal("wgpu: failed to configure mesh pipeline primitive state")
  }
  if with_depth {
    let set_depth_err = @wgpu_c.render_pipeline_desc_builder_set_depth_stencil(
      builder,
      @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
      depth_write_enabled,
      @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
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
fn ensure_mesh_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh_pipeline_layout is None {
    guard backend.sprite_bgl_tex is Some(bgl_tex) else {
      @debug.debug(
        "[native_gpu] ensure_mesh_pipeline_rgba8: sprite_bgl_tex is None",
      )
      return
    }
    let bgl = create_uniform_bind_group_layout_vertex_fragment(
      backend, "mgstudio_mesh_uniform_bgl",
    )
    let pl = backend.device.create_pipeline_layout_2(bgl, bgl_tex)
    backend.mesh_bgl_uniform = Some(bgl)
    backend.mesh_pipeline_layout = Some(pl)
  }
  if backend.mesh_pipeline is Some(_) {
    return
  }
  guard backend.mesh_pipeline_layout is Some(pl) else {
    @debug.debug(
      "[native_gpu] ensure_mesh_pipeline_rgba8: mesh_pipeline_layout is None",
    )
    return
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/mesh.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=false,
    position3d=false,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_rgba8")
  backend.mesh_pipeline = Some(pipeline)
  @debug.debug("[native_gpu] ensure_mesh_pipeline_rgba8: pipeline created")
  sm.release()
}

///|
fn ensure_mesh_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh_pipeline_rgba8(backend)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.mesh_pipeline_surface is Some(_) {
    return
  }
  if backend.mesh_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.mesh_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/mesh.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=false,
    position3d=false,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_surface")
  backend.mesh_pipeline_surface = Some(pipeline)
  backend.mesh_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh_pipeline_surface(backend, format)
      return backend.mesh_pipeline_surface
    }
    _ => ()
  }
  ensure_mesh_pipeline_rgba8(backend)
  backend.mesh_pipeline
}

///|
fn mesh3d_pipeline_get_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent
    } else {
      backend.mesh3d_pipeline_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent
  } else {
    backend.mesh3d_pipeline
  }
}

///|
fn mesh3d_pipeline_set_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent = pipeline
  } else {
    backend.mesh3d_pipeline = pipeline
  }
}

///|
fn mesh3d_rgba8_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline = None
  backend.mesh3d_pipeline_transparent = None
  backend.mesh3d_pipeline_line_list = None
  backend.mesh3d_pipeline_line_list_transparent = None
  backend.mesh3d_pipeline_line_strip = None
  backend.mesh3d_pipeline_line_strip_transparent = None
  backend.mesh3d_pipeline_rgba8_cull_mode = -1
}

///|
fn mesh3d_pipeline_get_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent
  } else {
    backend.mesh3d_pipeline_surface
  }
}

///|
fn mesh3d_pipeline_set_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent = pipeline
  } else {
    backend.mesh3d_pipeline_surface = pipeline
  }
}

///|
fn mesh3d_surface_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline_surface is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline_surface = None
  backend.mesh3d_pipeline_surface_transparent = None
  backend.mesh3d_pipeline_surface_line_list = None
  backend.mesh3d_pipeline_surface_line_list_transparent = None
  backend.mesh3d_pipeline_surface_line_strip = None
  backend.mesh3d_pipeline_surface_line_strip_transparent = None
  backend.mesh3d_pipeline_surface_cull_mode = -1
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_rgba8_cull_mode != safe_cull_mode {
    mesh3d_rgba8_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_rgba8_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_layout is None {
    let bgl = create_uniform_bind_group_layout_vertex_fragment(
      backend, "mgstudio_mesh3d_uniform_bgl",
    )
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
    let material_ok = material_builder.add_sampler(
        0U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        2U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        4U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        5U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        6U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        7U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        8U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        9U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        10U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      material_builder.add_sampler(
        11U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh3d material bind group layout")
    }
    let material_bgl = material_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_material_bgl",
    )
    let pl = backend.device.create_pipeline_layout_2(bgl, material_bgl)
    backend.mesh3d_bgl_uniform = Some(bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_pipeline_layout = Some(pl)
    mesh3d_material_cache_clear(backend)
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_rgba8_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_rgba8_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, true, Some(pipeline_transparent))
  sm.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh3d pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) && prev != format {
    mesh3d_surface_pipeline_cache_clear(backend)
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_surface_cull_mode != safe_cull_mode {
    mesh3d_surface_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_surface_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) &&
    prev == format &&
    mesh3d_pipeline_get_surface(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_surface(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_surface(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_surface(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_surface_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_surface_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(
    backend,
    topology,
    true,
    Some(pipeline_transparent),
  )
  backend.mesh3d_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  topology : UInt,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(backend, format, topology, cull_mode)
      return mesh3d_pipeline_get_surface(backend, topology, transparent)
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  mesh3d_pipeline_get_rgba8(backend, topology, transparent)
}

///|
fn ensure_mesh3d_motion_vector_pipeline(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh3d_motion_vector_pipeline_layout is None {
    let bgl = create_uniform_bind_group_layout_vertex_fragment(
      backend, "mgstudio_motion_vector_uniform_bgl",
    )
    let pl = backend.device.create_pipeline_layout_1(bgl)
    backend.mesh3d_motion_vector_bgl_uniform = Some(bgl)
    backend.mesh3d_motion_vector_pipeline_layout = Some(pl)
  }
  if backend.mesh3d_motion_vector_uniform_buf is None ||
    backend.mesh3d_motion_vector_uniform_bg is None {
    guard backend.mesh3d_motion_vector_bgl_uniform is Some(bgl) else { return }
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    let uniform_buf = backend.device.create_buffer(size=256UL, usage~)
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh3d_motion_vector_uniform_buf = Some(uniform_buf)
    backend.mesh3d_motion_vector_uniform_bg = Some(uniform_bg)
  }
  if backend.mesh3d_motion_vector_pipeline is Some(_) {
    return
  }
  guard backend.mesh3d_motion_vector_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/3d/motion_vector.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    alpha_blend=false,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_motion_vector_rgba16f")
  backend.mesh3d_motion_vector_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_motion_blur_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.motion_blur_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.motion_blur_settings_buf = Some(
      backend.device.create_buffer(size=16UL, usage~),
    )
  }
  if backend.motion_blur_globals_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.motion_blur_globals_buf = Some(
      backend.device.create_buffer(size=16UL, usage~),
    )
  }
  if backend.motion_blur_pipeline is Some(_) {
    return
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/3d/motion_blur.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_color_format_entries(
    sm,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    vs_entry="fullscreen_vertex_shader",
    fs_entry="final_fragment",
    alpha_blend=false,
    depth=false,
  )
  pipeline.set_label("mgstudio_motion_blur_rgba8")
  backend.motion_blur_bgl = Some(pipeline.get_bind_group_layout(0U))
  backend.motion_blur_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_motion_blur_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_motion_blur_pipeline_rgba8(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.motion_blur_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.motion_blur_pipeline_surface is Some(_) {
    return
  }
  if backend.motion_blur_pipeline_surface is Some(old) {
    old.release()
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/3d/motion_blur.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_color_format_entries(
    sm,
    format,
    vs_entry="fullscreen_vertex_shader",
    fs_entry="final_fragment",
    alpha_blend=false,
    depth=false,
  )
  pipeline.set_label("mgstudio_motion_blur_surface")
  backend.motion_blur_pipeline_surface = Some(pipeline)
  backend.motion_blur_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn motion_blur_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_motion_blur_pipeline_surface(backend, format)
      return backend.motion_blur_pipeline_surface
    }
    _ => ()
  }
  ensure_motion_blur_pipeline_rgba8(backend)
  backend.motion_blur_pipeline
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn bloom2d_ilog2_floor(value : Int) -> Int {
  let mut v = if value < 1 { 1 } else { value }
  let mut power = 0
  while v > 1 {
    v = v / 2
    power = power + 1
  }
  power
}

///|
fn bloom2d_effective_mip_count(max_mip_dimension : Int) -> Int {
  let safe_dimension = if max_mip_dimension < 4 { 4 } else { max_mip_dimension }
  let ilog2 = bloom2d_ilog2_floor(safe_dimension)
  let count = if ilog2 < 2 { 1 } else { ilog2 - 1 }
  if count < 1 {
    1
  } else {
    count
  }
}

///|
fn bloom2d_mip_dimension(base : Int, mip : Int) -> Int {
  let mut value = if base < 1 { 1 } else { base }
  for _ in 0..<mip {
    value = if value > 1 { value / 2 } else { 1 }
  }
  if value < 1 {
    1
  } else {
    value
  }
}

///|
fn bloom2d_compute_blend_factor(
  intensity : Float,
  low_frequency_boost : Float,
  low_frequency_boost_curvature : Float,
  high_pass_frequency : Float,
  composite_mode : Int,
  mip : Float,
  max_mip : Float,
) -> Float {
  let safe_max_mip = if max_mip <= 0.0F { 1.0F } else { max_mip }
  let mip_ratio = clamp01(mip / safe_max_mip)
  let safe_curvature = if low_frequency_boost_curvature >= 0.999F {
    0.999F
  } else {
    low_frequency_boost_curvature
  }
  let curvature_factor = 1.0F / (1.0F - safe_curvature)
  let one_minus_mip = 1.0F - mip_ratio
  let lf_pow = Float::from_double(
    @coremath.pow(one_minus_mip.to_double(), curvature_factor.to_double()),
  )
  let mut low_freq = (1.0F - lf_pow) * low_frequency_boost
  let safe_high_pass = if high_pass_frequency <= 0.0001F {
    0.0001F
  } else {
    high_pass_frequency
  }
  let high_pass_lq = 1.0F -
    clamp01((mip_ratio - high_pass_frequency) / safe_high_pass)
  let mode_factor = if composite_mode == 0 { 1.0F - intensity } else { 1.0F }
  low_freq = low_freq * mode_factor
  (intensity + low_freq) * high_pass_lq
}

///|
fn bloom2d_uniform_bytes(
  source_width : Float,
  source_height : Float,
  source_viewport_x : Float,
  source_viewport_y : Float,
  source_viewport_width : Float,
  source_viewport_height : Float,
  threshold : Float,
  threshold_softness : Float,
  scale_x : Float,
  scale_y : Float,
  exposure : Float,
  fxaa_enabled : Float,
  fxaa_edge_threshold : Float,
  tonemapping_mode : Float,
  deband_dither_enabled : Float,
  bloom_weight : Float,
  upsample_blend : Float,
  chromatic_aberration : Float,
  vignette : Float,
) -> Bytes {
  let softness = threshold_softness
  let knee = threshold * softness
  let safe_source_width = if source_width > 0.0F { source_width } else { 1.0F }
  let safe_source_height = if source_height > 0.0F {
    source_height
  } else {
    1.0F
  }
  let safe_viewport_width = if source_viewport_width > 0.0F {
    source_viewport_width
  } else {
    safe_source_width
  }
  let safe_viewport_height = if source_viewport_height > 0.0F {
    source_viewport_height
  } else {
    safe_source_height
  }
  let aspect = if safe_viewport_height > 0.0F {
    safe_viewport_width / safe_viewport_height
  } else {
    1.0F
  }
  f32le_pack([
    threshold,
    threshold - knee,
    2.0F * knee,
    0.25F / (knee + 0.00001F),
    source_viewport_x / safe_source_width,
    source_viewport_y / safe_source_height,
    safe_viewport_width / safe_source_width,
    safe_viewport_height / safe_source_height,
    scale_x,
    scale_y,
    aspect,
    exposure,
    tonemapping_mode,
    deband_dither_enabled,
    bloom_weight,
    upsample_blend,
    fxaa_enabled,
    fxaa_edge_threshold,
    chromatic_aberration,
    vignette,
  ])
}

///|
fn load_wgsl_with_defines_required(
  backend : GpuBackend,
  rel : String,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let base = backend.assets_base.trim().to_string()
  if base == "" {
    fatal("wgpu: assets_base is empty; cannot load shader: " + rel)
  }
  let normalized_rel = normalize_shader_rel_path(rel)
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  load_wgsl_preprocessed(base, normalized_rel, defines, visited)
}

///|
fn ensure_bloom2d_layouts(backend : GpuBackend) -> Unit raise GpuBackendError {
  let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  if backend.bloom2d_intermediate_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let ok = builder.add_texture(
        0U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(1U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_buffer(2U, frag, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build bloom intermediate bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_bloom2d_intermediate_bgl",
    )
    let pl = backend.device.create_pipeline_layout_1(bgl)
    pl.set_label("mgstudio_bloom2d_intermediate_pipeline_layout")
    backend.bloom2d_intermediate_bgl = Some(bgl)
    backend.bloom2d_intermediate_pipeline_layout = Some(pl)
  }
  if backend.bloom2d_final_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_texture(
        0U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(1U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_buffer(2U, frag, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        4U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
    if !ok {
      builder.free()
      fatal("wgpu: failed to build bloom final bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_bloom2d_final_bgl")
    let pl = backend.device.create_pipeline_layout_1(bgl)
    pl.set_label("mgstudio_bloom2d_final_pipeline_layout")
    backend.bloom2d_final_bgl = Some(bgl)
    backend.bloom2d_final_pipeline_layout = Some(pl)
  }
}

///|
fn bloom2d_create_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  source : String,
  format : @wgpu.TextureFormat,
  fs_entry : String,
  alpha_blend : Bool,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let sm = backend.device.create_shader_module_wgsl(source)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("fullscreen_vertex_shader", fs_entry)
    builder.set_color_target_format(format)
    if alpha_blend {
      builder.enable_alpha_blend()
    }
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      sm.release()
      fatal("wgpu: failed to build bloom pipeline descriptor: " + err.message())
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn ensure_bloom2d_mip_texture(
  backend : GpuBackend,
  mip_count : Int,
  width : Int,
  height : Int,
) -> Unit {
  let safe_mip_count = if mip_count < 1 { 1 } else { mip_count }
  let safe_width = if width < 1 { 1 } else { width }
  let safe_height = if height < 1 { 1 } else { height }
  if backend.bloom2d_mip_texture is Some(_) &&
    backend.bloom2d_mip_count == safe_mip_count &&
    backend.bloom2d_mip_width == safe_width &&
    backend.bloom2d_mip_height == safe_height &&
    backend.bloom2d_mip_views.length() == safe_mip_count {
    return
  }
  for view in backend.bloom2d_mip_views {
    view.release()
  }
  backend.bloom2d_mip_views.clear()
  if backend.bloom2d_mip_texture is Some(old_tex) {
    old_tex.release()
  }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  let texture = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(usage_bits),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    mip_level_count=safe_mip_count.reinterpret_as_uint(),
  )
  for mip in 0..<safe_mip_count {
    let view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      mip.reinterpret_as_uint(),
      1U,
    )
    view.set_label("mgstudio_bloom2d_mip_\{mip}")
    backend.bloom2d_mip_views.push(view)
  }
  backend.bloom2d_mip_texture = Some(texture)
  backend.bloom2d_mip_count = safe_mip_count
  backend.bloom2d_mip_width = safe_width
  backend.bloom2d_mip_height = safe_height
}

///|
fn create_bloom2d_intermediate_bind_group(
  backend : GpuBackend,
  bind_layout : @wgpu.BindGroupLayout,
  input_view : @wgpu.TextureView,
  sampler : @wgpu.Sampler,
  settings_buf : @wgpu.Buffer,
  label : String,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let ok = builder.add_texture_view(0U, input_view) &&
    builder.add_sampler(1U, sampler) &&
    builder.add_buffer(2U, settings_buf)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(backend.device, bind_layout, label~))
}

///|
fn create_bloom2d_final_bind_group(
  backend : GpuBackend,
  bind_layout : @wgpu.BindGroupLayout,
  input_view : @wgpu.TextureView,
  sampler : @wgpu.Sampler,
  settings_buf : @wgpu.Buffer,
  scene_view : @wgpu.TextureView,
  lut_view : @wgpu.TextureView,
  label : String,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_texture_view(0U, input_view) &&
    builder.add_sampler(1U, sampler) &&
    builder.add_buffer(2U, settings_buf) &&
    builder.add_texture_view(3U, scene_view) &&
    builder.add_texture_view(4U, lut_view)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(backend.device, bind_layout, label~))
}

///|
fn ensure_bloom2d_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.bloom2d_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.bloom2d_settings_buf = Some(
      backend.device.create_buffer(size=80UL, usage~),
    )
  }
  if backend.bloom2d_sampler is None {
    backend.bloom2d_sampler = Some(backend.device.create_sampler_linear_clamp())
  }
  ensure_bloom2d_layouts(backend)
  let mip_format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  if backend.bloom2d_downsample_first_pipeline is None ||
    backend.bloom2d_downsample_first_no_threshold_pipeline is None ||
    backend.bloom2d_downsample_first_uniform_pipeline is None ||
    backend.bloom2d_downsample_first_no_threshold_uniform_pipeline is None ||
    backend.bloom2d_downsample_pipeline is None ||
    backend.bloom2d_downsample_uniform_pipeline is None ||
    backend.bloom2d_upsample_pipeline_energy is None ||
    backend.bloom2d_upsample_pipeline_additive is None {
    guard backend.bloom2d_intermediate_pipeline_layout
      is Some(intermediate_pipeline_layout) else {
      return
    }
    let downsample_first_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "USE_THRESHOLD"],
    )
    let downsample_first_no_threshold_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      ["FIRST_DOWNSAMPLE"],
    )
    let downsample_first_uniform_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "USE_THRESHOLD", "UNIFORM_SCALE"],
    )
    let downsample_first_no_threshold_uniform_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "UNIFORM_SCALE"],
    )
    let downsample_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      [],
    )
    let downsample_uniform_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      ["UNIFORM_SCALE"],
    )
    let upsample_source = load_wgsl_with_defines_required(
      backend,
      "shaders/mgstudio/2d/bloom.wgsl",
      [],
    )
    let downsample_first_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_first_source, mip_format,
      "downsample_first", false, "mgstudio_bloom2d_downsample_first",
    )
    let downsample_first_no_threshold_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_first_no_threshold_source,
      mip_format, "downsample_first", false, "mgstudio_bloom2d_downsample_first_no_threshold",
    )
    let downsample_first_uniform_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_first_uniform_source, mip_format,
      "downsample_first", false, "mgstudio_bloom2d_downsample_first_uniform",
    )
    let downsample_first_no_threshold_uniform_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_first_no_threshold_uniform_source,
      mip_format, "downsample_first", false, "mgstudio_bloom2d_downsample_first_no_threshold_uniform",
    )
    let downsample_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_source, mip_format, "downsample",
      false, "mgstudio_bloom2d_downsample",
    )
    let downsample_uniform_pipeline = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, downsample_uniform_source, mip_format,
      "downsample", false, "mgstudio_bloom2d_downsample_uniform",
    )
    let upsample_pipeline_energy = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, upsample_source, mip_format, "upsample",
      true, "mgstudio_bloom2d_upsample_energy",
    )
    let upsample_pipeline_additive = bloom2d_create_pipeline(
      backend, intermediate_pipeline_layout, upsample_source, mip_format, "upsample",
      true, "mgstudio_bloom2d_upsample_additive",
    )
    backend.bloom2d_downsample_first_pipeline = Some(downsample_first_pipeline)
    backend.bloom2d_downsample_first_no_threshold_pipeline = Some(
      downsample_first_no_threshold_pipeline,
    )
    backend.bloom2d_downsample_first_uniform_pipeline = Some(
      downsample_first_uniform_pipeline,
    )
    backend.bloom2d_downsample_first_no_threshold_uniform_pipeline = Some(
      downsample_first_no_threshold_uniform_pipeline,
    )
    backend.bloom2d_downsample_pipeline = Some(downsample_pipeline)
    backend.bloom2d_downsample_uniform_pipeline = Some(
      downsample_uniform_pipeline,
    )
    backend.bloom2d_upsample_pipeline_energy = Some(upsample_pipeline_energy)
    backend.bloom2d_upsample_pipeline_additive = Some(
      upsample_pipeline_additive,
    )
  }
  if backend.bloom2d_final_pipeline is Some(_) {
    return
  }
  guard backend.bloom2d_final_pipeline_layout is Some(final_pipeline_layout) else {
    return
  }
  let final_source = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/tonemapping.wgsl",
  )
  let final_pipeline = bloom2d_create_pipeline(
    backend,
    final_pipeline_layout,
    final_source,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "final_fragment",
    false,
    "mgstudio_bloom2d_final_rgba8",
  )
  backend.bloom2d_final_pipeline = Some(final_pipeline)
}

///|
fn ensure_bloom2d_pipeline_surface(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_bloom2d_pipeline_rgba8(backend)
  guard backend.surface_format is Some(format) else { return }
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.bloom2d_final_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.bloom2d_final_pipeline_surface is Some(_) {
    return
  }
  if backend.bloom2d_final_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.bloom2d_final_pipeline_layout is Some(final_pipeline_layout) else {
    return
  }
  let final_source = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/tonemapping.wgsl",
  )
  let final_pipeline = bloom2d_create_pipeline(
    backend, final_pipeline_layout, final_source, format, "final_fragment", false,
    "mgstudio_bloom2d_final_surface",
  )
  backend.bloom2d_final_pipeline_surface = Some(final_pipeline)
  backend.bloom2d_final_pipeline_surface_format = Some(format)
}

///|
fn bloom2d_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_bloom2d_pipeline_surface(backend)
        return backend.bloom2d_final_pipeline_surface
      }
      _ => ()
    }
  }
  ensure_bloom2d_pipeline_rgba8(backend)
  backend.bloom2d_final_pipeline
}

///|
fn reopen_saved_pass(
  backend : GpuBackend,
  pass_state : GpuPassState,
) -> Unit raise GpuBackendError {
  let width_logical = pass_state.width_logical.to_double().to_int()
  let height_logical = pass_state.height_logical.to_double().to_int()
  let viewport_x = pass_state.viewport_x.reinterpret_as_int()
  let viewport_y = pass_state.viewport_y.reinterpret_as_int()
  let viewport_w = pass_state.viewport_w.reinterpret_as_int()
  let viewport_h = pass_state.viewport_h.reinterpret_as_int()
  if pass_state.is_3d {
    backend.begin_pass_3d(
      pass_state.target_id,
      pass_state.target_layer,
      width_logical,
      height_logical,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      pass_state.camera_x,
      pass_state.camera_y,
      pass_state.camera_z,
      pass_state.camera_rot_x,
      pass_state.camera_rot_y,
      pass_state.camera_rot_z,
      pass_state.camera_rot_w,
      pass_state.camera_fov_y,
      pass_state.camera_near,
      pass_state.camera_far,
      viewport_x,
      viewport_y,
      viewport_w,
      viewport_h,
      pass_state.ambient_r,
      pass_state.ambient_g,
      pass_state.ambient_b,
      pass_state.ambient_brightness,
      pass_state.directional_dir_x,
      pass_state.directional_dir_y,
      pass_state.directional_dir_z,
      pass_state.directional_color_r,
      pass_state.directional_color_g,
      pass_state.directional_color_b,
      pass_state.directional_illuminance,
      pass_state.point_pos_x,
      pass_state.point_pos_y,
      pass_state.point_pos_z,
      pass_state.point_color_r,
      pass_state.point_color_g,
      pass_state.point_color_b,
      pass_state.point_intensity,
      pass_state.point_range,
      pass_state.spot_pos_x,
      pass_state.spot_pos_y,
      pass_state.spot_pos_z,
      pass_state.spot_dir_x,
      pass_state.spot_dir_y,
      pass_state.spot_dir_z,
      pass_state.spot_color_r,
      pass_state.spot_color_g,
      pass_state.spot_color_b,
      pass_state.spot_intensity,
      pass_state.spot_range,
      pass_state.spot_inner_angle,
      pass_state.spot_outer_angle,
      pass_state.sub_camera_view_scale_x,
      pass_state.sub_camera_view_scale_y,
      pass_state.sub_camera_view_bias_x,
      pass_state.sub_camera_view_bias_y,
      pass_state.previous_camera_x,
      pass_state.previous_camera_y,
      pass_state.previous_camera_z,
      pass_state.previous_camera_rot_x,
      pass_state.previous_camera_rot_y,
      pass_state.previous_camera_rot_z,
      pass_state.previous_camera_rot_w,
      pass_state.pass_kind,
      0,
    )
  } else {
    backend.begin_pass(
      pass_state.target_id,
      width_logical,
      height_logical,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      pass_state.camera_x,
      pass_state.camera_y,
      pass_state.camera_rot,
      pass_state.camera_scale,
      viewport_x,
      viewport_y,
      viewport_w,
      viewport_h,
      pass_state.viewport_depth_min,
      pass_state.viewport_depth_max,
      0,
    )
  }
}

///|
pub fn GpuBackend::create_surface(self : GpuBackend, window : Int) -> Unit {
  if self.surface is Some(_) {
    return
  }
  let surface = self.instance.create_surface_metal_layer()
  @windowing.attach_surface_metal_layer(window, surface)
  self.surface = Some(surface)
}

///|
pub fn GpuBackend::configure_surface(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  guard self.surface is Some(surface) else { return }
  self.configured_width = width
  self.configured_height = height
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  // Surface textures cannot be used as sampled textures (`texture_binding`).
  // Requesting RESOURCE usage triggers a wgpu-native validation error.
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  self.surface_format = Some(
    surface.configure_default(self.adapter, self.device, w, h, usage),
  )
  let fmt_u32 = match self.surface_format {
    Some(f) => f.to_u32()
    None => 0U
  }
  @debug.debug("wgpu: surface_format_u32=" + fmt_u32.to_string())
}

///|
/// Ensure the surface is configured for the latest window size.
///
/// This is a bring-up convenience: the guest does not yet have a resize event
/// path, so the host keeps the surface in sync.
pub fn GpuBackend::ensure_surface_configured(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  if self.surface is None {
    return
  }
  if width == self.configured_width && height == self.configured_height {
    return
  }
  self.configure_surface(width, height)
}

///|
pub fn GpuBackend::begin_frame(self : GpuBackend) -> Unit {
  guard self.surface is Some(surface) else { return }
  if self.frame_count == 4294967295U {
    self.frame_count = 0U
  } else {
    self.frame_count = self.frame_count + 1U
  }
  self.mesh_uniform_slot_used = 0
  self.mesh3d_uniform_slot_used = 0
  let st = surface.get_current_texture()
  let tex = st.take_texture()
  let view = tex.create_view()
  view.set_label("mgstudio_surface_view")
  let encoder = self.device.create_command_encoder()
  self.frame = Some(GpuFrameState::{
    surface_tex: st,
    surface_texture: tex,
    surface_view: view,
    encoder,
    pass: None,
  })
  prepare_surface_capture_frame(self) catch {
    _ => {
      self.surface_capture_active = false
      active_surface_screenshot_capture_ids_ref.val.clear()
    }
  }
}

///|
pub fn GpuBackend::end_frame(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  screenshot_encode_active_surface_captures(self, frame)
  screenshot_present_surface_capture(self)
  screenshot_encode_pending_texture_captures(self, frame)
  let cmd = frame.encoder.finish()
  self.queue.submit_one(cmd)
  screenshot_collect_completed_captures(self)
  cmd.release()
  guard self.surface is Some(surface) else {
    frame.encoder.release()
    frame.surface_texture.release()
    frame.surface_view.release()
    frame.surface_tex.release()
    self.surface_capture_active = false
    active_surface_screenshot_capture_ids_ref.val.clear()
    self.frame = None
    self.pass_state = None
    return
  }
  surface.present() |> ignore
  self.instance.process_events()
  frame.encoder.release()
  frame.surface_texture.release()
  frame.surface_view.release()
  frame.surface_tex.release()
  self.surface_capture_active = false
  active_surface_screenshot_capture_ids_ref.val.clear()
  self.frame = None
  self.pass_state = None
}

///|
fn find_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo? {
  for t in backend.textures.val {
    if t.id == id {
      return Some(t)
    }
  }
  None
}

///|
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_material_bg_cache.val {
    entry.bind_group.release()
  }
  backend.mesh3d_material_bg_cache.val.clear()
}

///|
fn ensure_mesh3d_point_shadow_compare_sampler(
  backend : GpuBackend,
) -> @wgpu.Sampler {
  match backend.mesh3d_point_shadow_compare_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.MIPMAP_FILTER_MODE_NEAREST,
        compare_u32=@wgpu.COMPARE_FUNCTION_LESS_EQUAL,
      )
      backend.mesh3d_point_shadow_compare_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
  base_texture : GpuTextureInfo,
  normal_texture : GpuTextureInfo,
  emissive_texture : GpuTextureInfo,
  metallic_roughness_texture : GpuTextureInfo,
  occlusion_texture : GpuTextureInfo,
  depth_texture : GpuTextureInfo,
  anisotropy_texture : GpuTextureInfo,
  specular_tint_texture : GpuTextureInfo,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  for entry in backend.mesh3d_material_bg_cache.val {
    if entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id &&
      entry.depth_texture_id == depth_texture.id &&
      entry.anisotropy_texture_id == anisotropy_texture.id &&
      entry.specular_tint_texture_id == specular_tint_texture.id &&
      entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id {
      return entry.bind_group
    }
  }
  let layout = match backend.mesh3d_bgl_material {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d material bind group layout")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_sampler(0U, base_texture.sampler) &&
    builder.add_texture_view(1U, base_texture.view) &&
    builder.add_texture_view(2U, normal_texture.view) &&
    builder.add_texture_view(3U, emissive_texture.view) &&
    builder.add_texture_view(4U, metallic_roughness_texture.view) &&
    builder.add_texture_view(5U, occlusion_texture.view) &&
    builder.add_texture_view(6U, depth_texture.view) &&
    builder.add_texture_view(7U, anisotropy_texture.view) &&
    builder.add_texture_view(8U, specular_tint_texture.view) &&
    builder.add_texture_view(9U, transmission_source_texture.view) &&
    builder.add_texture_view(10U, point_shadow_sample_view) &&
    builder.add_sampler(11U, point_shadow_compare_sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d material bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_material_bg",
  )
  backend.mesh3d_material_bg_cache.val.push(Mesh3dMaterialBindGroupCacheEntry::{
    base_texture_id: base_texture.id,
    normal_texture_id: normal_texture.id,
    emissive_texture_id: emissive_texture.id,
    metallic_roughness_texture_id: metallic_roughness_texture.id,
    occlusion_texture_id: occlusion_texture.id,
    depth_texture_id: depth_texture.id,
    anisotropy_texture_id: anisotropy_texture.id,
    specular_tint_texture_id: specular_tint_texture.id,
    transmission_source_texture_id: transmission_source_texture.id,
    point_shadow_texture_id: point_shadow_texture.id,
    bind_group,
  })
  bind_group
}

///|
fn ensure_default_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  let id = -1
  if find_texture(backend, id) is Some(t) {
    t
  } else {
    ensure_sprite_resources(backend)
    let bgl_tex = backend.sprite_bgl_tex.unwrap()
    let w = 128U
    let h = 128U
    let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC
    let usage = @wgpu.TextureUsage::from_u64(usage_bits)
    let tex = backend.device.create_texture_rgba8_2d_with_usage(w, h, usage)
    let view = tex.create_view()
    let sampler = backend.device.create_sampler_linear_clamp()
    let bg = backend.device.create_bind_group_sampler_texture_2d(
      bgl_tex, sampler, view,
    )
    // Fill the texture with white.
    let byte_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
    let data = Bytes::makei(byte_len, _ => (255).to_byte())
    backend.queue.write_texture_rgba8_2d(tex, w, h, data)
    let info = GpuTextureInfo::{
      id,
      width: w.reinterpret_as_int(),
      height: h.reinterpret_as_int(),
      mip_level_count: 1,
      base_mip_level: 0,
      format_raw: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      texture: tex,
      view,
      sample_view: None,
      layer_views: [],
      sampler,
      bind_group: bg,
    }
    backend.textures.val.push(info)
    mesh3d_material_cache_clear(backend)
    info
  }
}

///|
fn resolve_draw_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  if id < 0 {
    Some(ensure_default_texture(backend))
  } else {
    find_texture(backend, id)
  }
}

///|
fn resolve_mesh3d_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  resolve_draw_texture(backend, id)
}

///|
fn ensure_point_shadow_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.point_shadow_fallback_texture_id >= 0 {
    if find_texture(backend, backend.point_shadow_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let created_id = backend.create_point_light_shadow_target(1)
  backend.point_shadow_fallback_texture_id = created_id
  guard find_texture(backend, created_id) is Some(texture) else {
    fatal("wgpu: failed to initialize point shadow fallback texture")
  }
  texture
}

///|
pub fn GpuBackend::create_texture_rgba8(
  self : GpuBackend,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
  nearest : Bool,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_rgba8_2d_with_usage(w, h, usage)
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  let expected_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
  if pixels_rgba8.length() != expected_len {
    fatal(
      "wgpu: invalid RGBA8 texture byte length, expected " +
      expected_len.to_string() +
      ", got " +
      pixels_rgba8.length().to_string(),
    )
  }
  self.queue.write_texture_rgba8_2d(tex, w, h, pixels_rgba8)
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
  }
  self.textures.val.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::create_texture_stacked_2d_with_format(
  self : GpuBackend,
  width : Int,
  height_per_slice : Int,
  slice_count : Int,
  format_raw : UInt,
  levels : Array[Bytes],
  nearest : Bool,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  if levels.length() == 0 {
    fatal("wgpu: no mip levels provided for texture upload")
  }
  guard texture_block_info(format_raw) is Some(block_info) else {
    fatal(
      "wgpu: unsupported texture format for upload: " +
      format_raw.reinterpret_as_int().to_string(),
    )
  }

  let id = alloc_id(self)
  let w = if width <= 0 { 1 } else { width }
  let h_per_slice = if height_per_slice <= 0 { 1 } else { height_per_slice }
  let slices = if slice_count <= 0 { 1 } else { slice_count }
  let total_height = h_per_slice * slices
  if total_height <= 0 {
    fatal("wgpu: stacked texture height overflow")
  }

  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    w.reinterpret_as_uint(),
    total_height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
    mip_level_count=levels.length().reinterpret_as_uint(),
  )
  let view = tex.create_view()
  view.set_label("mgstudio_render_target_\{id}")
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )

  for level_index in 0..<levels.length() {
    let mip_width = {
      let v = w >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_height_per_slice = {
      let v = h_per_slice >> level_index
      if v <= 0 {
        1
      } else {
        v
      }
    }
    let mip_height = mip_height_per_slice * slices
    if mip_height <= 0 {
      fatal("wgpu: stacked mip height overflow")
    }
    guard texture_layout_for_level(block_info, mip_width, mip_height)
      is Some((bytes_per_row, rows_per_image, expected_bytes)) else {
      fatal("wgpu: failed to compute texture upload layout")
    }
    let level_data = levels[level_index]
    if level_data.length() < expected_bytes {
      fatal(
        "wgpu: mip upload size mismatch at level " + level_index.to_string(),
      )
    }
    let upload_data = if level_data.length() == expected_bytes {
      level_data
    } else {
      Bytes::makei(expected_bytes, i => {
        match level_data.get(i) {
          Some(b) => b
          None => (0).to_byte()
        }
      })
    }
    let tex_info = @wgpu_c.texel_copy_texture_info_new(
      tex.raw,
      level_index.reinterpret_as_uint(),
      0U,
      0U,
      0U,
    )
    let layout = @wgpu_c.texel_copy_buffer_layout_new(
      0UL,
      bytes_per_row.reinterpret_as_uint(),
      rows_per_image.reinterpret_as_uint(),
    )
    let extent = @wgpu_c.extent3d_new(
      mip_width.reinterpret_as_uint(),
      mip_height.reinterpret_as_uint(),
      1U,
    )
    self.queue.write_texture_ptr(
      tex_info,
      upload_data,
      layout,
      extent,
      data_size=expected_bytes.to_uint64(),
    )
    @wgpu_c.extent3d_free(extent)
    @wgpu_c.texel_copy_buffer_layout_free(layout)
    @wgpu_c.texel_copy_texture_info_free(tex_info)
  }

  let info = GpuTextureInfo::{
    id,
    width: w,
    height: total_height,
    mip_level_count: levels.length(),
    base_mip_level: 0,
    format_raw,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
  }
  self.textures.val.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::texture_width(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.width
    None => 0
  }
}

///|
pub fn GpuBackend::texture_height(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.height
    None => 0
  }
}

///|
/// Update a sub-rectangle of an RGBA8 2D texture.
///
/// Note: WGPU requires `bytes_per_row` to be 256-byte aligned, so we may need to
/// pad each row before calling `Queue::write_texture_ptr`.
pub fn GpuBackend::write_texture_region_rgba8(
  self : GpuBackend,
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  match find_texture(self, texture_id) {
    None => ()
    Some(info) => {
      if width <= 0 || height <= 0 {
        return
      }
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let origin_x = if x < 0 { 0U } else { x.reinterpret_as_uint() }
      let origin_y = if y < 0 { 0U } else { y.reinterpret_as_uint() }
      let bytes_per_row = width * 4
      if bytes_per_row <= 0 {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let expected = bytes_per_row * height
      if pixels_rgba8.length() != expected {
        return
      }
      let src = pixels_rgba8
      let upload = if aligned == bytes_per_row {
        src
      } else {
        Bytes::makei(aligned * height, i => {
          let row = i / aligned
          let col = i % aligned
          if col < bytes_per_row {
            let src_i = row * bytes_per_row + col
            match src.get(src_i) {
              Some(b) => b
              None => (0).to_byte()
            }
          } else {
            (0).to_byte()
          }
        })
      }
      let tex_info = @wgpu_c.texel_copy_texture_info_new(
        info.texture.raw,
        0U,
        origin_x,
        origin_y,
        0U,
      )
      let layout = @wgpu_c.texel_copy_buffer_layout_new(
        0UL,
        aligned.reinterpret_as_uint(),
        h,
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(tex_info, upload, layout, extent)
      @wgpu_c.extent3d_free(extent)
      @wgpu_c.texel_copy_buffer_layout_free(layout)
      @wgpu_c.texel_copy_texture_info_free(tex_info)
    }
  }
}

///|
pub fn GpuBackend::write_texture_region_rgba8_mip(
  self : GpuBackend,
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  mip_level : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  match find_texture(self, texture_id) {
    None => ()
    Some(info) => {
      if width <= 0 || height <= 0 || mip_level < 0 {
        return
      }
      if mip_level >= info.mip_level_count {
        return
      }
      let target_width = {
        let shifted = info.width >> mip_level
        if shifted <= 0 {
          1
        } else {
          shifted
        }
      }
      let target_height = {
        let shifted = info.height >> mip_level
        if shifted <= 0 {
          1
        } else {
          shifted
        }
      }
      let origin_x_i = if x < 0 { 0 } else { x }
      let origin_y_i = if y < 0 { 0 } else { y }
      if origin_x_i + width > target_width ||
        origin_y_i + height > target_height {
        return
      }
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let bytes_per_row = width * 4
      if bytes_per_row <= 0 {
        return
      }
      let expected = bytes_per_row * height
      if pixels_rgba8.length() != expected {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let upload = if aligned == bytes_per_row {
        pixels_rgba8
      } else {
        Bytes::makei(aligned * height, i => {
          let row = i / aligned
          let col = i % aligned
          if col < bytes_per_row {
            let src_i = row * bytes_per_row + col
            match pixels_rgba8.get(src_i) {
              Some(b) => b
              None => (0).to_byte()
            }
          } else {
            (0).to_byte()
          }
        })
      }
      let absolute_mip = (info.base_mip_level + mip_level).reinterpret_as_uint()
      let tex_info = @wgpu_c.texel_copy_texture_info_new(
        info.texture.raw,
        absolute_mip,
        origin_x_i.reinterpret_as_uint(),
        origin_y_i.reinterpret_as_uint(),
        0U,
      )
      let layout = @wgpu_c.texel_copy_buffer_layout_new(
        0UL,
        aligned.reinterpret_as_uint(),
        h,
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(tex_info, upload, layout, extent)
      @wgpu_c.extent3d_free(extent)
      @wgpu_c.texel_copy_buffer_layout_free(layout)
      @wgpu_c.texel_copy_texture_info_free(tex_info)
      mesh3d_material_cache_clear(self)
    }
  }
}

///|
pub fn GpuBackend::copy_texture_to_texture(
  self : GpuBackend,
  dst_texture_id : Int,
  dst_x : Int,
  dst_y : Int,
  src_texture_id : Int,
) -> Unit {
  guard find_texture(self, src_texture_id) is Some(src) else { return }
  guard find_texture(self, dst_texture_id) is Some(dst) else { return }
  let origin_x = if dst_x < 0 { 0 } else { dst_x }
  let origin_y = if dst_y < 0 { 0 } else { dst_y }
  let max_width = dst.width - origin_x
  let max_height = dst.height - origin_y
  if max_width <= 0 || max_height <= 0 {
    return
  }
  let copy_width = if src.width < max_width { src.width } else { max_width }
  let copy_height = if src.height < max_height {
    src.height
  } else {
    max_height
  }
  if copy_width <= 0 || copy_height <= 0 {
    return
  }
  let encoder = self.device.create_command_encoder()
  encoder.copy_texture_to_texture_rgba8_mip_layer(
    src.texture,
    src.base_mip_level.reinterpret_as_uint(),
    0U,
    dst.texture,
    dst.base_mip_level.reinterpret_as_uint(),
    0U,
    copy_width.reinterpret_as_uint(),
    copy_height.reinterpret_as_uint(),
  )
  let command_buffer = encoder.finish()
  self.queue.submit_one(command_buffer)
  command_buffer.release()
  encoder.release()
}

///|
pub fn GpuBackend::create_texture_mip_view(
  self : GpuBackend,
  texture_id : Int,
  mip_level : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  guard find_texture(self, texture_id) is Some(source) else { return -1 }
  if mip_level < 0 || mip_level >= source.mip_level_count {
    return -1
  }
  let absolute_mip = source.base_mip_level + mip_level
  let width = {
    let shifted = source.width >> mip_level
    if shifted <= 0 {
      1
    } else {
      shifted
    }
  }
  let height = {
    let shifted = source.height >> mip_level
    if shifted <= 0 {
      1
    } else {
      shifted
    }
  }
  let view = source.texture.create_view_u32(
    tf(source.format_raw),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(source.format_raw),
    0U,
    1U,
    absolute_mip.reinterpret_as_uint(),
    1U,
  )
  let bind_group = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    source.sampler,
    view,
  )
  let id = alloc_id(self)
  let info = GpuTextureInfo::{
    id,
    width,
    height,
    mip_level_count: 1,
    base_mip_level: absolute_mip,
    format_raw: source.format_raw,
    texture: source.texture,
    view,
    sample_view: None,
    layer_views: [],
    sampler: source.sampler,
    bind_group,
  }
  self.textures.val.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
pub fn GpuBackend::is_texture_loaded(
  self : GpuBackend,
  texture_id : Int,
) -> Bool {
  find_texture(self, texture_id) is Some(_)
}

///|
pub fn GpuBackend::supported_compressed_image_formats_mask(
  self : GpuBackend,
) -> Int {
  let mut gpu_feature_mask = 0
  if self.device.supported_features_contains_u32(0x00000007U) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_ASTC_LDR
  }
  if self.device.supported_features_contains_u32(0x00000004U) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_BC
  }
  if self.device.supported_features_contains_u32(0x00000006U) {
    gpu_feature_mask = gpu_feature_mask + COMPRESSED_IMAGE_FORMAT_ETC2
  }
  let runtime_decoder_mask = COMPRESSED_IMAGE_FORMAT_ASTC_LDR |
    COMPRESSED_IMAGE_FORMAT_BC |
    COMPRESSED_IMAGE_FORMAT_ETC2
  gpu_feature_mask & runtime_decoder_mask
}

///|
pub fn GpuBackend::set_texture_sampler(
  self : GpuBackend,
  texture_id : Int,
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
) -> Unit raise GpuBackendError {
  if self.sprite_bgl_tex is None {
    ensure_sprite_resources(self)
  }
  let bgl_tex = self.sprite_bgl_tex.unwrap()
  let count = self.textures.val.length()
  for i in 0..<count {
    let info = self.textures.val[i]
    if info.id == texture_id {
      let sampler = gpu_sampler_get_or_create(
        self, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
        mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
      )
      let bg = self.device.create_bind_group_sampler_texture_2d(
        bgl_tex,
        sampler,
        info.view,
      )
      self.textures.val[i] = GpuTextureInfo::{
        id: info.id,
        width: info.width,
        height: info.height,
        mip_level_count: info.mip_level_count,
        base_mip_level: info.base_mip_level,
        format_raw: info.format_raw,
        texture: info.texture,
        view: info.view,
        sample_view: info.sample_view,
        layer_views: info.layer_views,
        sampler,
        bind_group: bg,
      }
      mesh3d_material_cache_clear(self)
      break
    }
  }
}

///|
pub fn GpuBackend::create_render_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
}

///|
pub fn GpuBackend::create_render_target_rgba16f(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  self.create_render_target_with_format(
    width,
    height,
    nearest,
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
  )
}

///|
pub fn GpuBackend::create_point_light_shadow_target(
  self : GpuBackend,
  size : Int,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let default_texture = ensure_default_texture(self)
  let id = alloc_id(self)
  let safe_size = if size <= 0 { 1U } else { size.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    safe_size,
    safe_size,
    6U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
  )
  // Render passes attach one depth face at a time as 2D targets.
  let face0_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    1U,
    0U,
    1U,
  )
  let layer_views : Array[@wgpu.TextureView] = []
  for face in 0..<6 {
    layer_views.push(
      tex.create_view_u32(
        tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
        face.reinterpret_as_uint(),
        1U,
        0U,
        1U,
      ),
    )
  }
  // Sampling uses cubemap semantics aligned with Bevy face selection order.
  let cube_view = tex.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    6U,
    0U,
    1U,
  )
  let info = GpuTextureInfo::{
    id,
    width: safe_size.reinterpret_as_int(),
    height: safe_size.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw: @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    texture: tex,
    view: face0_view,
    sample_view: Some(cube_view),
    layer_views,
    sampler: default_texture.sampler,
    bind_group: default_texture.bind_group,
  }
  self.textures.val.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
fn GpuBackend::create_render_target_with_format(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
  format_raw : UInt,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  let tex = self.device.create_texture_u32(
    w,
    h,
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
  )
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw,
    texture: tex,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group: bg,
  }
  self.textures.val.push(info)
  mesh3d_material_cache_clear(self)
  id
}

///|
fn release_texture_resources(info : GpuTextureInfo) -> Unit {
  info.bind_group.release()
  info.sampler.release()
  for layer_view in info.layer_views {
    layer_view.release()
  }
  if info.sample_view is Some(sample_view) {
    sample_view.release()
  }
  info.view.release()
  info.texture.release()
}

///|
fn replace_texture_info(
  backend : GpuBackend,
  replacement : GpuTextureInfo,
) -> Unit {
  for i in 0..<backend.textures.val.length() {
    if backend.textures.val[i].id == replacement.id {
      release_texture_resources(backend.textures.val[i])
      backend.textures.val[i] = replacement
      return
    }
  }
  backend.textures.val.push(replacement)
}

///|
fn ensure_surface_capture_texture(
  backend : GpuBackend,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if backend.surface_capture_texture_id >= 0 {
    if find_texture(backend, backend.surface_capture_texture_id)
      is Some(existing) {
      if existing.width == safe_width &&
        existing.height == safe_height &&
        existing.format_raw == format_raw {
        return existing.id
      }
    }
  }
  let texture_id = if backend.surface_capture_texture_id >= 0 {
    backend.surface_capture_texture_id
  } else {
    let allocated_id = alloc_id(backend)
    backend.surface_capture_texture_id = allocated_id
    allocated_id
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST,
  )
  let texture = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(format_raw),
  )
  let view = texture.create_view()
  let sampler = backend.device.create_sampler_linear_clamp()
  let bind_group = backend.device.create_bind_group_sampler_texture_2d(
    backend.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  replace_texture_info(backend, GpuTextureInfo::{
    id: texture_id,
    width: safe_width,
    height: safe_height,
    mip_level_count: 1,
    base_mip_level: 0,
    format_raw,
    texture,
    view,
    sample_view: None,
    layer_views: [],
    sampler,
    bind_group,
  })
  mesh3d_material_cache_clear(backend)
  texture_id
}

///|
fn surface_capture_texture_info(backend : GpuBackend) -> GpuTextureInfo? {
  if backend.surface_capture_texture_id < 0 {
    None
  } else {
    find_texture(backend, backend.surface_capture_texture_id)
  }
}

///|
fn prepare_surface_capture_frame(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  backend.surface_capture_active = false
  active_surface_screenshot_capture_ids_ref.val.clear()
  if pending_surface_screenshot_capture_ids_ref.val.length() == 0 {
    return
  }
  guard backend.surface_format is Some(surface_format) else { return }
  let width = if backend.configured_width <= 0 {
    1
  } else {
    backend.configured_width
  }
  let height = if backend.configured_height <= 0 {
    1
  } else {
    backend.configured_height
  }
  if ensure_surface_capture_texture(backend, width, height, surface_format.raw) <=
    0 {
    return
  }
  active_surface_screenshot_capture_ids_ref.val = pending_surface_screenshot_capture_ids_ref.val
  pending_surface_screenshot_capture_ids_ref.val = []
  backend.surface_capture_active = true
}

///|
fn target_view(
  backend : GpuBackend,
  target_id : Int,
  target_layer : Int,
) -> @wgpu.TextureView? {
  if target_id == -1 {
    match backend.frame {
      Some(frame) => {
        if backend.surface_capture_active {
          if surface_capture_texture_info(backend)
            is Some(surface_capture_texture) {
            return Some(surface_capture_texture.view)
          }
        }
        Some(frame.surface_view)
      }
      None => None
    }
  } else {
    match find_texture(backend, target_id) {
      Some(texture) =>
        if target_layer >= 0 && target_layer < texture.layer_views.length() {
          Some(texture.layer_views[target_layer])
        } else {
          Some(texture.view)
        }
      None => None
    }
  }
}

///|
fn current_pass_color_format(backend : GpuBackend) -> @wgpu.TextureFormat? {
  match backend.pass_state {
    Some(pass_state) =>
      if pass_kind_base_kind(pass_state.pass_kind) ==
        PASS_KIND_BASE_POINT_SHADOW {
        Some(tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM))
      } else if pass_state.target_id == -1 {
        backend.surface_format
      } else {
        match find_texture(backend, pass_state.target_id) {
          Some(texture) => Some(tf(texture.format_raw))
          None => None
        }
      }
    None => None
  }
}

///|
fn target_size_for_pass(backend : GpuBackend, target_id : Int) -> (Int, Int)? {
  if target_id == -1 {
    Some((backend.configured_width, backend.configured_height))
  } else {
    match find_texture(backend, target_id) {
      Some(info) => Some((info.width, info.height))
      None => None
    }
  }
}

///|
fn clamp_scissor_to_target(
  backend : GpuBackend,
  target_id : Int,
  x : UInt,
  y : UInt,
  width : UInt,
  height : UInt,
) -> (UInt, UInt, UInt, UInt) {
  guard target_size_for_pass(backend, target_id)
    is Some((target_w_i, target_h_i)) else {
    return (0U, 0U, 1U, 1U)
  }
  let target_w = if target_w_i <= 0 {
    1U
  } else {
    target_w_i.reinterpret_as_uint()
  }
  let target_h = if target_h_i <= 0 {
    1U
  } else {
    target_h_i.reinterpret_as_uint()
  }

  let sx = if x >= target_w { target_w - 1U } else { x }
  let sy = if y >= target_h { target_h - 1U } else { y }
  let max_w = target_w - sx
  let max_h = target_h - sy
  let sw = if width == 0U { 1U } else if width > max_w { max_w } else { width }
  let sh = if height == 0U {
    1U
  } else if height > max_h {
    max_h
  } else {
    height
  }
  (sx, sy, sw, sh)
}

///|
fn ensure_depth_view_for_target(
  backend : GpuBackend,
  target_id : Int,
) -> @wgpu.TextureView? {
  guard target_size_for_pass(backend, target_id) is Some((raw_w, raw_h)) else {
    return None
  }
  let width = if raw_w <= 0 { 1 } else { raw_w }
  let height = if raw_h <= 0 { 1 } else { raw_h }
  if backend.depth_target_id == target_id &&
    backend.depth_width == width &&
    backend.depth_height == height {
    if backend.depth_view is Some(view) {
      return Some(view)
    }
  }
  if backend.depth_view is Some(old_view) {
    old_view.release()
  }
  if backend.depth_texture is Some(old_tex) {
    old_tex.release()
  }
  let depth_tex = backend.device.create_texture_u32(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
  )
  let depth_view = depth_tex.create_view()
  backend.depth_texture = Some(depth_tex)
  backend.depth_view = Some(depth_view)
  backend.depth_target_id = target_id
  backend.depth_width = width
  backend.depth_height = height
  Some(depth_view)
}

///|
fn ensure_shadow_color_view(
  backend : GpuBackend,
  width : Int,
  height : Int,
) -> @wgpu.TextureView {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  if backend.shadow_color_width == safe_width &&
    backend.shadow_color_height == safe_height {
    if backend.shadow_color_view is Some(view) {
      return view
    }
  }
  if backend.shadow_color_view is Some(old_view) {
    old_view.release()
  }
  if backend.shadow_color_texture is Some(old_tex) {
    old_tex.release()
  }
  let tex = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
  )
  let view = tex.create_view()
  backend.shadow_color_texture = Some(tex)
  backend.shadow_color_view = Some(view)
  backend.shadow_color_width = safe_width
  backend.shadow_color_height = safe_height
  view
}

///|
pub fn GpuBackend::begin_pass(
  self : GpuBackend,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_rot : Float,
  camera_scale : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_w : Int,
  viewport_h : Int,
  viewport_depth_min : Float,
  viewport_depth_max : Float,
  clear_enabled : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  guard target_view(self, target_id, -1) is Some(view) else { return }
  let pass = if clear_enabled == 0 {
    frame.encoder.begin_render_pass_color_load(view)
  } else {
    frame.encoder.begin_render_pass_color_clear(
      view, clear_r, clear_g, clear_b, clear_a,
    )
  }
  let vx = if viewport_x < 0 { 0U } else { viewport_x.reinterpret_as_uint() }
  let vy = if viewport_y < 0 { 0U } else { viewport_y.reinterpret_as_uint() }
  let vw = if viewport_w < 0 { 0U } else { viewport_w.reinterpret_as_uint() }
  let vh = if viewport_h < 0 { 0U } else { viewport_h.reinterpret_as_uint() }
  pass.set_viewport(
    Float::from_double(vx.to_double()),
    Float::from_double(vy.to_double()),
    Float::from_double(vw.to_double()),
    Float::from_double(vh.to_double()),
    viewport_depth_min,
    viewport_depth_max,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self, target_id, vx, vy, vw, vh,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  frame.pass = Some(pass)
  self.pass_state = Some(GpuPassState::{
    target_id,
    target_layer: -1,
    width_logical: Float::from_double(width_logical.to_double()),
    height_logical: Float::from_double(height_logical.to_double()),
    is_3d: false,
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: if camera_scale == 0.0F {
      1.0F
    } else {
      camera_scale
    },
    camera_z: 0.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    previous_camera_x: camera_x,
    previous_camera_y: camera_y,
    previous_camera_z: 0.0F,
    previous_camera_rot_x: 0.0F,
    previous_camera_rot_y: 0.0F,
    previous_camera_rot_z: 0.0F,
    previous_camera_rot_w: 1.0F,
    camera_fov_y: PI * 0.5F,
    camera_near: 0.1F,
    camera_far: 1000.0F,
    pass_kind: 0,
    viewport_x: vx,
    viewport_y: vy,
    viewport_w: vw,
    viewport_h: vh,
    viewport_depth_min,
    viewport_depth_max,
    ambient_r: 1.0F,
    ambient_g: 1.0F,
    ambient_b: 1.0F,
    ambient_brightness: 0.0F,
    directional_dir_x: 0.0F,
    directional_dir_y: -1.0F,
    directional_dir_z: 0.0F,
    directional_color_r: 1.0F,
    directional_color_g: 1.0F,
    directional_color_b: 1.0F,
    directional_illuminance: 0.0F,
    point_pos_x: 0.0F,
    point_pos_y: 0.0F,
    point_pos_z: 0.0F,
    point_color_r: 1.0F,
    point_color_g: 1.0F,
    point_color_b: 1.0F,
    point_intensity: 0.0F,
    point_range: 1.0F,
    spot_pos_x: 0.0F,
    spot_pos_y: 0.0F,
    spot_pos_z: 0.0F,
    spot_dir_x: 0.0F,
    spot_dir_y: -1.0F,
    spot_dir_z: 0.0F,
    spot_color_r: 1.0F,
    spot_color_g: 1.0F,
    spot_color_b: 1.0F,
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
    sub_camera_view_scale_x: 1.0F,
    sub_camera_view_scale_y: 1.0F,
    sub_camera_view_bias_x: 0.0F,
    sub_camera_view_bias_y: 0.0F,
  })

  // Reset sprite batching state and update sprite globals for this pass.
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_instance_data.clear()
  self.ui_batches.clear()
  self.ui_instance_count = 0U
  self.ui_shadow_instance_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_instance_count = 0U
  self.ui_slice_instance_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_instance_count = 0U
  ensure_sprite_resources(self)
  if self.sprite_globals_buf is Some(globals_buf) {
    let safe_scale = if camera_scale == 0.0F { 1.0F } else { camera_scale }
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w / safe_scale } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h / safe_scale } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    // Globals: view(x,y,cos,sin) + ndc_scale(x,y,_,_)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
}

///|
pub fn GpuBackend::begin_pass_3d(
  self : GpuBackend,
  target_id : Int,
  target_layer : Int,
  width_logical : Int,
  height_logical : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_z : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
  camera_fov_y : Float,
  camera_near : Float,
  camera_far : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_w : Int,
  viewport_h : Int,
  ambient_r : Float,
  ambient_g : Float,
  ambient_b : Float,
  ambient_brightness : Float,
  directional_dir_x : Float,
  directional_dir_y : Float,
  directional_dir_z : Float,
  directional_color_r : Float,
  directional_color_g : Float,
  directional_color_b : Float,
  directional_illuminance : Float,
  point_pos_x : Float,
  point_pos_y : Float,
  point_pos_z : Float,
  point_color_r : Float,
  point_color_g : Float,
  point_color_b : Float,
  point_intensity : Float,
  point_range : Float,
  spot_pos_x : Float,
  spot_pos_y : Float,
  spot_pos_z : Float,
  spot_dir_x : Float,
  spot_dir_y : Float,
  spot_dir_z : Float,
  spot_color_r : Float,
  spot_color_g : Float,
  spot_color_b : Float,
  spot_intensity : Float,
  spot_range : Float,
  spot_inner_angle : Float,
  spot_outer_angle : Float,
  sub_camera_view_scale_x : Float,
  sub_camera_view_scale_y : Float,
  sub_camera_view_bias_x : Float,
  sub_camera_view_bias_y : Float,
  previous_camera_x : Float,
  previous_camera_y : Float,
  previous_camera_z : Float,
  previous_camera_rot_x : Float,
  previous_camera_rot_y : Float,
  previous_camera_rot_z : Float,
  previous_camera_rot_w : Float,
  pass_kind : Int,
  clear_enabled : Int,
) -> Unit raise GpuBackendError {
  let camera_rot = quat_to_z_rotation(
    camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w,
  )
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let base_kind = pass_kind_base_kind(pass_kind)
  let (color_view, depth_view) = if base_kind == PASS_KIND_BASE_POINT_SHADOW {
    guard target_view(self, target_id, target_layer) is Some(shadow_depth_view) else {
      return
    }
    guard target_size_for_pass(self, target_id)
      is Some((target_width, target_height)) else {
      return
    }
    (
      ensure_shadow_color_view(self, target_width, target_height),
      shadow_depth_view,
    )
  } else {
    guard target_view(self, target_id, target_layer) is Some(view) else {
      return
    }
    guard ensure_depth_view_for_target(self, target_id)
      is Some(scene_depth_view) else {
      return
    }
    (view, scene_depth_view)
  }
  let color_load_op_u32 = if clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let depth_load_op_u32 = if clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let stencil_load_op_u32 = if clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let pass = frame.encoder.begin_render_pass_color_depth_u32(
    color_view,
    depth_view,
    color_load_op_u32~,
    color_store_op_u32=@wgpu.STORE_OP_STORE,
    color_clear_r_f32=clear_r,
    color_clear_g_f32=clear_g,
    color_clear_b_f32=clear_b,
    color_clear_a_f32=clear_a,
    depth_load_op_u32~,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=1.0F,
    depth_read_only=false,
    stencil_load_op_u32~,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    stencil_read_only=true,
  )
  let vx = if viewport_x < 0 { 0U } else { viewport_x.reinterpret_as_uint() }
  let vy = if viewport_y < 0 { 0U } else { viewport_y.reinterpret_as_uint() }
  let vw = if viewport_w < 0 { 0U } else { viewport_w.reinterpret_as_uint() }
  let vh = if viewport_h < 0 { 0U } else { viewport_h.reinterpret_as_uint() }
  pass.set_viewport(
    Float::from_double(vx.to_double()),
    Float::from_double(vy.to_double()),
    Float::from_double(vw.to_double()),
    Float::from_double(vh.to_double()),
    0.0F,
    1.0F,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self, target_id, vx, vy, vw, vh,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  frame.pass = Some(pass)
  self.pass_state = Some(GpuPassState::{
    target_id,
    target_layer,
    width_logical: Float::from_double(width_logical.to_double()),
    height_logical: Float::from_double(height_logical.to_double()),
    is_3d: true,
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: 1.0F,
    camera_z,
    camera_rot_x,
    camera_rot_y,
    camera_rot_z,
    camera_rot_w,
    previous_camera_x,
    previous_camera_y,
    previous_camera_z,
    previous_camera_rot_x,
    previous_camera_rot_y,
    previous_camera_rot_z,
    previous_camera_rot_w,
    camera_fov_y,
    camera_near,
    camera_far,
    pass_kind,
    viewport_x: vx,
    viewport_y: vy,
    viewport_w: vw,
    viewport_h: vh,
    viewport_depth_min: 0.0F,
    viewport_depth_max: 1.0F,
    ambient_r,
    ambient_g,
    ambient_b,
    ambient_brightness,
    directional_dir_x,
    directional_dir_y,
    directional_dir_z,
    directional_color_r,
    directional_color_g,
    directional_color_b,
    directional_illuminance,
    point_pos_x,
    point_pos_y,
    point_pos_z,
    point_color_r,
    point_color_g,
    point_color_b,
    point_intensity,
    point_range,
    spot_pos_x,
    spot_pos_y,
    spot_pos_z,
    spot_dir_x,
    spot_dir_y,
    spot_dir_z,
    spot_color_r,
    spot_color_g,
    spot_color_b,
    spot_intensity,
    spot_range,
    spot_inner_angle,
    spot_outer_angle,
    sub_camera_view_scale_x,
    sub_camera_view_scale_y,
    sub_camera_view_bias_x,
    sub_camera_view_bias_y,
  })
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_instance_data.clear()
  self.ui_batches.clear()
  self.ui_instance_count = 0U
  self.ui_shadow_instance_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_instance_count = 0U
  self.ui_slice_instance_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_instance_count = 0U
  ensure_sprite_resources(self)
  if self.sprite_globals_buf is Some(globals_buf) {
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
}

///|
pub fn GpuBackend::set_scissor(
  self : GpuBackend,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  let sx = if x < 0 { 0U } else { x.reinterpret_as_uint() }
  let sy = if y < 0 { 0U } else { y.reinterpret_as_uint() }
  let sw = if width < 0 { 0U } else { width.reinterpret_as_uint() }
  let sh = if height < 0 { 0U } else { height.reinterpret_as_uint() }
  let target_id = match self.pass_state {
    Some(ps) => ps.target_id
    None => -1
  }
  let (clamped_x, clamped_y, clamped_w, clamped_h) = clamp_scissor_to_target(
    self, target_id, sx, sy, sw, sh,
  )
  pass.set_scissor_rect(clamped_x, clamped_y, clamped_w, clamped_h)
}

///|
pub fn GpuBackend::clear_scissor(
  self : GpuBackend,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self,
    pass_state.target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
}

///|
pub fn GpuBackend::end_pass(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
}

///|
fn flush_ui_shadow_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_shadow_instance_count == 0U {
    return
  }
  guard ui_shadow_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.ui_shadow_instance_data.length()
  if float_count <= 0 {
    backend.ui_shadow_instance_data.clear()
    backend.ui_shadow_batches.clear()
    backend.ui_shadow_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_shadow_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_shadow_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_shadow_instance_buf = Some(new_buf)
    backend.ui_shadow_instance_capacity = new_cap
    backend.ui_shadow_globals_bg = None
  }
  ensure_ui_shadow_globals_bind_group(backend)
  guard backend.ui_shadow_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_shadow_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_shadow_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_shadow_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_shadow_instance_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_instance_count = 0U
}

///|
fn flush_ui_slice_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_slice_instance_count == 0U {
    return
  }
  guard ui_slice_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.ui_slice_instance_data.length()
  if float_count <= 0 {
    backend.ui_slice_instance_data.clear()
    backend.ui_slice_batches.clear()
    backend.ui_slice_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_slice_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_slice_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_slice_instance_buf = Some(new_buf)
    backend.ui_slice_instance_capacity = new_cap
    backend.ui_slice_globals_bg = None
  }
  ensure_ui_slice_globals_bind_group(backend)
  guard backend.ui_slice_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_slice_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_slice_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_slice_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_slice_instance_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_instance_count = 0U
}

///|
fn flush_ui_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_instance_count == 0U {
    return
  }
  guard ui_pipeline_for_current_pass(backend) is Some(pipeline) else { return }
  let float_count = backend.ui_instance_data.length()
  if float_count <= 0 {
    backend.ui_instance_data.clear()
    backend.ui_batches.clear()
    backend.ui_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_instance_buf = Some(new_buf)
    backend.ui_instance_capacity = new_cap
    backend.ui_globals_bg = None
  }
  ensure_ui_globals_bind_group(backend)
  guard backend.ui_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_instance_data.clear()
  backend.ui_batches.clear()
  backend.ui_instance_count = 0U
}

///|
fn flush_sprite_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.sprite_instance_count == 0U {
    return
  }
  guard sprite_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.sprite_instance_data.length()
  if float_count <= 0 {
    backend.sprite_instance_data.clear()
    backend.sprite_batches.clear()
    backend.sprite_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.sprite_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.sprite_instance_buf is Some(old) {
      old.release()
    }
    backend.sprite_instance_buf = Some(new_buf)
    backend.sprite_instance_capacity = new_cap
    backend.sprite_globals_bg = None
  }
  ensure_sprite_globals_bind_group(backend)
  guard backend.sprite_instance_buf is Some(instance_buf) else { return }
  guard backend.sprite_globals_bg is Some(globals_bg) else { return }

  // Upload instances.
  let bytes = f32le_pack(backend.sprite_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.sprite_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.sprite_instance_data.clear()
  backend.sprite_batches.clear()
  backend.sprite_instance_count = 0U
}

///|
pub fn GpuBackend::draw_sprite_uv(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  ensure_sprite_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }

  // Match Web runtime's sprite sizing convention (base quad is 128x128).
  let raw_uv_scale_x = uv_max_x - uv_min_x
  let raw_uv_scale_y = uv_max_y - uv_min_y
  let uv_scale_x = if raw_uv_scale_x <= 0.0F { 1.0F } else { raw_uv_scale_x }
  let uv_scale_y = if raw_uv_scale_y <= 0.0F { 1.0F } else { raw_uv_scale_y }
  let tex_w = Float::from_double(tex.width.to_double())
  let tex_h = Float::from_double(tex.height.to_double())
  let region_w = tex_w * uv_scale_x
  let region_h = tex_h * uv_scale_y
  let base_size = 128.0F
  let tex_scale_x = if region_w > 0.0F { region_w / base_size } else { 1.0F }
  let tex_scale_y = if region_h > 0.0F { region_h / base_size } else { 1.0F }
  let sprite_scale_x = scale_x * tex_scale_x
  let sprite_scale_y = scale_y * tex_scale_y
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.sprite_instance_count
  self.sprite_instance_count = first_instance + 1U

  // Instance layout: model(x,y,cos,sin), scale(x,y,_,_), color, uv(min_x,min_y,scale_x,scale_y)
  self.sprite_instance_data.push(x)
  self.sprite_instance_data.push(y)
  self.sprite_instance_data.push(cosv)
  self.sprite_instance_data.push(sinv)
  self.sprite_instance_data.push(sprite_scale_x)
  self.sprite_instance_data.push(sprite_scale_y)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(color_r)
  self.sprite_instance_data.push(color_g)
  self.sprite_instance_data.push(color_b)
  self.sprite_instance_data.push(color_a)
  self.sprite_instance_data.push(uv_min_x)
  self.sprite_instance_data.push(uv_min_y)
  self.sprite_instance_data.push(uv_scale_x)
  self.sprite_instance_data.push(uv_scale_y)
  let batch_count = self.sprite_batches.length()
  if batch_count > 0 &&
    self.sprite_batches[batch_count - 1].texture_id == tex.id {
    self.sprite_batches[batch_count - 1].instance_count = self.sprite_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.sprite_batches.push(SpriteBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
}

///|
pub fn GpuBackend::draw_ui_rect(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_sprite_batches(self)
  ensure_ui_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }

  // UI sizing convention:
  // - Engine passes `scale_x/scale_y` in logical pixels (final rect size).
  // - Vertex shader uses a 128x128 base quad, so convert pixels -> quad scale.
  let raw_uv_scale_x = uv_max_x - uv_min_x
  let raw_uv_scale_y = uv_max_y - uv_min_y
  let uv_scale_x = if raw_uv_scale_x <= 0.0F { 1.0F } else { raw_uv_scale_x }
  let uv_scale_y = if raw_uv_scale_y <= 0.0F { 1.0F } else { raw_uv_scale_y }
  let base_size = 128.0F
  let ui_scale_x = scale_x / base_size
  let ui_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_instance_count
  self.ui_instance_count = first_instance + 1U
  let flags_f = Float::from_double(flags.to_double())

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_)
  // - color
  // - uv(min_x,min_y,scale_x,scale_y)
  // - flags(f32,0,0,0)
  // - radius(tl,tr,br,bl)
  // - border(left,top,right,bottom)
  self.ui_instance_data.push(x)
  self.ui_instance_data.push(y)
  self.ui_instance_data.push(cosv)
  self.ui_instance_data.push(sinv)
  self.ui_instance_data.push(ui_scale_x)
  self.ui_instance_data.push(ui_scale_y)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(color_r)
  self.ui_instance_data.push(color_g)
  self.ui_instance_data.push(color_b)
  self.ui_instance_data.push(color_a)
  self.ui_instance_data.push(uv_min_x)
  self.ui_instance_data.push(uv_min_y)
  self.ui_instance_data.push(uv_scale_x)
  self.ui_instance_data.push(uv_scale_y)
  self.ui_instance_data.push(flags_f)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(radius_tl)
  self.ui_instance_data.push(radius_tr)
  self.ui_instance_data.push(radius_br)
  self.ui_instance_data.push(radius_bl)
  self.ui_instance_data.push(border_left)
  self.ui_instance_data.push(border_top)
  self.ui_instance_data.push(border_right)
  self.ui_instance_data.push(border_bottom)
  let batch_count = self.ui_batches.length()
  if batch_count > 0 && self.ui_batches[batch_count - 1].texture_id == tex.id {
    self.ui_batches[batch_count - 1].instance_count = self.ui_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
}

///|
pub fn GpuBackend::draw_ui_texture_slice(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_ui_shadow_batches(self)
  flush_sprite_batches(self)
  flush_ui_batches(self)
  ensure_ui_slice_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }

  // Geometry is a 128x128 base quad; engine passes final bounds in logical pixels.
  let base_size = 128.0F
  let ui_scale_x = scale_x / base_size
  let ui_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_slice_instance_count
  self.ui_slice_instance_count = first_instance + 1U

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_)
  // - color
  // - texture_slices(l,t,r,b)
  // - target_slices(l,t,r,b)
  // - repeat(side_x,side_y,center_x,center_y)
  // - atlas_rect(l,t,r,b)
  self.ui_slice_instance_data.push(x)
  self.ui_slice_instance_data.push(y)
  self.ui_slice_instance_data.push(cosv)
  self.ui_slice_instance_data.push(sinv)
  self.ui_slice_instance_data.push(ui_scale_x)
  self.ui_slice_instance_data.push(ui_scale_y)
  self.ui_slice_instance_data.push(0.0F)
  self.ui_slice_instance_data.push(0.0F)
  self.ui_slice_instance_data.push(color_r)
  self.ui_slice_instance_data.push(color_g)
  self.ui_slice_instance_data.push(color_b)
  self.ui_slice_instance_data.push(color_a)
  self.ui_slice_instance_data.push(texture_slice_l)
  self.ui_slice_instance_data.push(texture_slice_t)
  self.ui_slice_instance_data.push(texture_slice_r)
  self.ui_slice_instance_data.push(texture_slice_b)
  self.ui_slice_instance_data.push(target_slice_l)
  self.ui_slice_instance_data.push(target_slice_t)
  self.ui_slice_instance_data.push(target_slice_r)
  self.ui_slice_instance_data.push(target_slice_b)
  self.ui_slice_instance_data.push(repeat_side_x)
  self.ui_slice_instance_data.push(repeat_side_y)
  self.ui_slice_instance_data.push(repeat_center_x)
  self.ui_slice_instance_data.push(repeat_center_y)
  self.ui_slice_instance_data.push(atlas_l)
  self.ui_slice_instance_data.push(atlas_t)
  self.ui_slice_instance_data.push(atlas_r)
  self.ui_slice_instance_data.push(atlas_b)
  let batch_count = self.ui_slice_batches.length()
  if batch_count > 0 &&
    self.ui_slice_batches[batch_count - 1].texture_id == tex.id {
    self.ui_slice_batches[batch_count - 1].instance_count = self.ui_slice_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_slice_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
}

///|
pub fn GpuBackend::draw_ui_box_shadow(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  samples : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  ensure_ui_shadow_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }

  // Geometry is a 128x128 base quad; engine passes final bounds in world units.
  let base_size = 128.0F
  let shadow_scale_x = scale_x / base_size
  let shadow_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_shadow_instance_count
  self.ui_shadow_instance_count = first_instance + 1U
  let samples_f = Float::from_double(samples.to_double())

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_) where x/y represent bounds / 128
  // - color
  // - size(x,y,blur,samples)
  // - radius(tl,tr,br,bl)
  self.ui_shadow_instance_data.push(x)
  self.ui_shadow_instance_data.push(y)
  self.ui_shadow_instance_data.push(cosv)
  self.ui_shadow_instance_data.push(sinv)
  self.ui_shadow_instance_data.push(shadow_scale_x)
  self.ui_shadow_instance_data.push(shadow_scale_y)
  self.ui_shadow_instance_data.push(0.0F)
  self.ui_shadow_instance_data.push(0.0F)
  self.ui_shadow_instance_data.push(color_r)
  self.ui_shadow_instance_data.push(color_g)
  self.ui_shadow_instance_data.push(color_b)
  self.ui_shadow_instance_data.push(color_a)
  self.ui_shadow_instance_data.push(size_x)
  self.ui_shadow_instance_data.push(size_y)
  self.ui_shadow_instance_data.push(blur)
  self.ui_shadow_instance_data.push(samples_f)
  self.ui_shadow_instance_data.push(radius_tl)
  self.ui_shadow_instance_data.push(radius_tr)
  self.ui_shadow_instance_data.push(radius_br)
  self.ui_shadow_instance_data.push(radius_bl)
  let batch_count = self.ui_shadow_batches.length()
  if batch_count > 0 &&
    self.ui_shadow_batches[batch_count - 1].texture_id == tex.id {
    self.ui_shadow_batches[batch_count - 1].instance_count = self.ui_shadow_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_shadow_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
}

///|
pub fn GpuBackend::create_mesh_rectangle(
  self : GpuBackend,
  width : Float,
  height : Float,
) -> Int {
  let id = alloc_id(self)
  let hw = width * 0.5F
  let hh = height * 0.5F
  let vertices : Array[Float] = [
    -hw,
    -hh,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    -hh,
    1.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    hh,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    -hw,
    hh,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
  ]
  let indices_u16 : Array[Int] = [0, 1, 2, 0, 2, 3]
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb_bytes = f32le_pack(vertices)
  let vb = self.device.create_buffer_init(usage=vb_usage, vb_bytes)
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib_bytes = u16le_pack(indices_u16)
  let ib = self.device.create_buffer_init(usage=ib_usage, ib_bytes)
  let info = GpuMeshInfo::{
    id,
    index_count: 6U,
    vertex_count: 4U,
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_capsule(
  self : GpuBackend,
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int {
  let id = alloc_id(self)
  // Simple triangulated capsule: rectangle body + two semicircle fans.
  let segs = if segments < 4 { 4 } else { segments }
  let verts_xy : Array[Float] = []
  let inds : Array[Int] = []

  // Base rectangle vertices (4).
  let hw = half_length
  let hh = radius
  let base0 = 0
  verts_xy.push(-hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(hh)
  verts_xy.push(-hw)
  verts_xy.push(hh)
  inds.push(base0 + 0)
  inds.push(base0 + 1)
  inds.push(base0 + 2)
  inds.push(base0 + 0)
  inds.push(base0 + 2)
  inds.push(base0 + 3)

  // Left semicircle.
  let center_l = verts_xy.length() / 2
  verts_xy.push(-hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t + 0.5F) // from 90deg to 270deg
    verts_xy.push(-hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_l)
    inds.push(center_l + 1 + i)
    inds.push(center_l + 1 + i + 1)
  }

  // Right semicircle.
  let center_r = verts_xy.length() / 2
  verts_xy.push(hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t - 0.5F) // from -90deg to 90deg
    verts_xy.push(hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_r)
    inds.push(center_r + 1 + i)
    inds.push(center_r + 1 + i + 1)
  }
  let verts = mesh_interleaved_xyuvrgba_from_xy(verts_xy)
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(usage=vb_usage, f32le_pack(verts))
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let info = GpuMeshInfo::{
    id,
    index_count: inds.length().reinterpret_as_uint(),
    vertex_count: (verts.length() / 8).reinterpret_as_uint(),
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xy(
  self : GpuBackend,
  vertices_xy : Array[Float],
) -> Int {
  let vertices = mesh_interleaved_xyuvrgba_from_xy(vertices_xy)
  self.create_mesh_triangles_xyuvrgba(vertices)
}

///|
fn mesh_interleaved_xyuvrgba_from_xy(
  vertices_xy : Array[Float],
) -> Array[Float] {
  let vcount = vertices_xy.length() / 2
  if vcount <= 0 {
    return []
  }
  let mut min_x = vertices_xy[0]
  let mut max_x = vertices_xy[0]
  let mut min_y = vertices_xy[1]
  let mut max_y = vertices_xy[1]
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    if x < min_x {
      min_x = x
    }
    if x > max_x {
      max_x = x
    }
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
  }
  let width = if max_x - min_x == 0.0F { 1.0F } else { max_x - min_x }
  let height = if max_y - min_y == 0.0F { 1.0F } else { max_y - min_y }
  let out : Array[Float] = []
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    out.push(x)
    out.push(y)
    out.push((x - min_x) / width)
    out.push((y - min_y) / height)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
  }
  out
}

///|
pub fn GpuBackend::create_mesh_triangles_xyuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  let vcount = vertices.length() / 8
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = vcount - vcount % 3
  if usable_vcount <= 0 || usable_vcount > 65535 {
    return 0
  }
  let indices_u16 : Array[Int] = []
  for i in 0..<usable_vcount {
    indices_u16.push(i)
  }
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    vertices
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 8) {
      out.push(vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(
    usage=ib_usage,
    u16le_pack(indices_u16),
  )
  let info = GpuMeshInfo::{
    id,
    index_count: indices_u16.length().reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh3d_xyzuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Int {
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = vertices.length() / 9
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 || usable_vcount > 65535 {
    return 0
  }
  let indices_u16 : Array[Int] = []
  for i in 0..<usable_vcount {
    indices_u16.push(i)
  }
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    vertices
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 9) {
      out.push(vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(
    usage=ib_usage,
    u16le_pack(indices_u16),
  )
  let info = GpuMeshInfo::{
    id,
    index_count: indices_u16.length().reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology,
    vertex_stride_bytes: 36UL,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xyzuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  self.create_mesh3d_xyzuvrgba(vertices, 0)
}

///|
fn find_mesh(backend : GpuBackend, id : Int) -> GpuMeshInfo? {
  for m in backend.meshes.val {
    if m.id == id {
      return Some(m)
    }
  }
  None
}

///|
pub fn GpuBackend::draw_mesh(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    debug_mesh2d_drop_no_frame_ref.val = debug_mesh2d_drop_no_frame_ref.val + 1
    return
  }
  guard frame.pass is Some(pass) else {
    debug_mesh2d_drop_no_pass_ref.val = debug_mesh2d_drop_no_pass_ref.val + 1
    return
  }
  guard self.pass_state is Some(ps) else {
    debug_mesh2d_drop_no_pass_state_ref.val = debug_mesh2d_drop_no_pass_state_ref.val +
      1
    return
  }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else {
    debug_mesh2d_drop_missing_mesh_ref.val = debug_mesh2d_drop_missing_mesh_ref.val +
      1
    return
  }
  if mesh.vertex_stride_bytes != 32UL {
    debug_mesh2d_drop_bad_stride_ref.val = debug_mesh2d_drop_bad_stride_ref.val +
      1
    return
  }
  guard mesh_pipeline_for_current_pass(self) is Some(pipeline) else {
    debug_mesh2d_drop_no_pipeline_ref.val = debug_mesh2d_drop_no_pipeline_ref.val +
      1
    return
  }
  let mesh_uniform_slot_index = self.mesh_uniform_slot_used
  guard ensure_mesh_uniform_slot(self, mesh_uniform_slot_index)
    is Some(uniform_slot) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  self.mesh_uniform_slot_used = mesh_uniform_slot_index + 1
  let resolved_texture_id = if texture_id < 0 { -1 } else { texture_id }
  guard resolve_draw_texture(self, resolved_texture_id) is Some(texture) else {
    debug_mesh2d_drop_no_texture_ref.val = debug_mesh2d_drop_no_texture_ref.val +
      1
    return
  }
  let textured = texture_id >= 0
  let safe_scale = ps.camera_scale
  let scale_x_base = if ps.width_logical > 0.0F {
    2.0F / ps.width_logical / safe_scale
  } else {
    0.0F
  }
  let scale_y_base = if ps.height_logical > 0.0F {
    2.0F / ps.height_logical / safe_scale
  } else {
    0.0F
  }
  let cosr = cosf(rotation)
  let sinr = sinf(rotation)
  let cam_cos = cosf(-ps.camera_rot)
  let cam_sin = sinf(-ps.camera_rot)
  let uv_offset_x_value = if textured { uv_offset_x } else { 0.0F }
  let uv_offset_y_value = if textured { uv_offset_y } else { 0.0F }
  let uv_scale_x_value = if textured { uv_scale_x } else { -1.0F }
  let uv_scale_y_value = if textured { uv_scale_y } else { -1.0F }
  let bytes = f32le_pack([
    x,
    y,
    cosr,
    sinr,
    ps.camera_x,
    ps.camera_y,
    cam_cos,
    cam_sin,
    scale_x_base,
    scale_y_base,
    scale_x,
    scale_y,
    color_r,
    color_g,
    color_b,
    color_a,
    uv_offset_x_value,
    uv_offset_y_value,
    uv_scale_x_value,
    uv_scale_y_value,
  ])
  self.queue.write_buffer(uniform_slot.buffer, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_slot.bind_group, [])
  pass.set_bind_group(1U, texture.bind_group, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
  pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  debug_mesh2d_executed_draw_calls_ref.val = debug_mesh2d_executed_draw_calls_ref.val +
    1
  current_frame_mesh2d_executed_draw_calls_ref.val = current_frame_mesh2d_executed_draw_calls_ref.val +
    1
  pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
}

///|
pub fn GpuBackend::draw_motion_blur(
  self : GpuBackend,
  scene_texture_id : Int,
  velocity_texture_id : Int,
  shutter_angle : Float,
  samples : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard motion_blur_pipeline_for_current_pass(self) is Some(pipeline) else {
    return
  }
  guard self.motion_blur_settings_buf is Some(settings_buf) else { return }
  guard self.motion_blur_globals_buf is Some(globals_buf) else { return }
  if scene_texture_id < 0 || velocity_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  guard find_texture(self, velocity_texture_id) is Some(velocity_texture) else {
    return
  }
  guard self.depth_view is Some(depth_view) else { return }
  let clamped_samples = if samples < 0 {
    0
  } else if samples > 64 {
    64
  } else {
    samples
  }
  let settings_bytes = u32le_pack([
    f32_bits(shutter_angle),
    clamped_samples.reinterpret_as_uint(),
    0U,
    0U,
  ])
  self.queue.write_buffer(settings_buf, 0UL, settings_bytes)
  let globals_bytes = u32le_pack([
    f32_bits(0.0F),
    f32_bits(0.0F),
    self.frame_count,
    0U,
  ])
  self.queue.write_buffer(globals_buf, 0UL, globals_bytes)

  let material_bgl = pipeline.get_bind_group_layout(0U)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let ok = builder.add_texture_view(0U, scene_texture.view) &&
    builder.add_texture_view(1U, velocity_texture.view) &&
    builder.add_texture_view(2U, depth_view) &&
    builder.add_sampler(3U, scene_texture.sampler) &&
    builder.add_buffer(4U, settings_buf) &&
    builder.add_buffer(5U, globals_buf)
  if !ok {
    builder.free()
    material_bgl.release()
    return
  }
  let material_bg = builder.finish(
    self.device,
    material_bgl,
    label="mgstudio_motion_blur_bg",
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, material_bg, [])
  pass.draw(3U, 1U, 0U, 0U)
  material_bg.release()
  material_bgl.release()
}

///|
pub fn GpuBackend::draw_bloom2d(
  self : GpuBackend,
  scene_texture_id : Int,
  enabled : Int,
  intensity : Float,
  low_frequency_boost : Float,
  low_frequency_boost_curvature : Float,
  high_pass_frequency : Float,
  threshold : Float,
  threshold_softness : Float,
  composite_mode : Int,
  max_mip_dimension : Int,
  scale_x : Float,
  scale_y : Float,
  exposure : Float,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  fxaa_enabled : Int,
  fxaa_edge_threshold : Float,
  chromatic_aberration : Float,
  vignette : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  guard bloom2d_pipeline_for_current_pass(self) is Some(final_pipeline) else {
    return
  }
  guard self.bloom2d_final_bgl is Some(final_bind_layout) else { return }
  guard self.bloom2d_settings_buf is Some(settings_buf) else { return }
  guard self.bloom2d_sampler is Some(bloom_sampler) else { return }
  if scene_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  let selected_lut_texture_id = if tonemapping_mode == 4 {
    agx_lut_texture_id
  } else if tonemapping_mode == 6 {
    tony_lut_texture_id
  } else if tonemapping_mode == 7 {
    blender_lut_texture_id
  } else {
    -1
  }
  let selected_lut_view = if selected_lut_texture_id >= 0 {
    if find_texture(self, selected_lut_texture_id) is Some(lut_texture) {
      lut_texture.view
    } else {
      scene_texture.view
    }
  } else {
    scene_texture.view
  }
  let low_frequency_boost_value = if low_frequency_boost < 0.0F {
    0.0F
  } else if low_frequency_boost > 1.0F {
    1.0F
  } else {
    low_frequency_boost
  }
  let low_frequency_boost_curvature_value = if low_frequency_boost_curvature <
    0.0F {
    0.0F
  } else if low_frequency_boost_curvature > 1.0F {
    1.0F
  } else {
    low_frequency_boost_curvature
  }
  let high_pass_frequency_value = if high_pass_frequency < 0.0F {
    0.0F
  } else if high_pass_frequency > 1.0F {
    1.0F
  } else {
    high_pass_frequency
  }
  let intensity_value = if intensity < 0.0F { 0.0F } else { intensity }
  let threshold_value = if threshold < 0.0F { 0.0F } else { threshold }
  let threshold_softness_value = if threshold_softness < 0.0F {
    0.0F
  } else if threshold_softness > 1.0F {
    1.0F
  } else {
    threshold_softness
  }
  let scale_x_value = if scale_x < 0.0F { 0.0F } else { scale_x }
  let scale_y_value = if scale_y < 0.0F { 0.0F } else { scale_y }
  let exposure_value = if exposure < 0.0F { 0.0F } else { exposure }
  let tonemapping_mode_value = Float::from_int(
    if tonemapping_mode < 0 {
      0
    } else if tonemapping_mode > 7 {
      7
    } else {
      tonemapping_mode
    },
  )
  let deband_dither_enabled_value = if deband_dither_enabled == 0 {
    0.0F
  } else {
    1.0F
  }
  let fxaa_enabled_value = if fxaa_enabled == 0 { 0.0F } else { 1.0F }
  let fxaa_edge_threshold_value = if fxaa_enabled_value > 0.0F {
    if fxaa_edge_threshold < 0.01F {
      0.01F
    } else if fxaa_edge_threshold > 0.333F {
      0.333F
    } else {
      fxaa_edge_threshold
    }
  } else {
    0.0F
  }
  let chromatic_aberration_value = if chromatic_aberration < 0.0F {
    0.0F
  } else {
    chromatic_aberration
  }
  let vignette_value = if vignette < 0.0F { 0.0F } else { vignette }
  let use_uniform_scale = scale_x_value == 1.0F && scale_y_value == 1.0F
  let use_prefilter = threshold_value > 0.0F
  let bloom_enabled = enabled != 0
  let bloom_weight = if bloom_enabled { intensity_value } else { 0.0F }
  let safe_scene_width = if scene_texture.width > 0 {
    scene_texture.width
  } else {
    1
  }
  let safe_scene_height = if scene_texture.height > 0 {
    scene_texture.height
  } else {
    1
  }
  let viewport_width = if pass_state.viewport_w > 0U {
    pass_state.viewport_w.reinterpret_as_int()
  } else if view_width > 0 {
    view_width
  } else {
    safe_scene_width
  }
  let viewport_height = if pass_state.viewport_h > 0U {
    pass_state.viewport_h.reinterpret_as_int()
  } else if view_height > 0 {
    view_height
  } else {
    safe_scene_height
  }
  let safe_viewport_width = if viewport_width > 0 { viewport_width } else { 1 }
  let safe_viewport_height = if viewport_height > 0 {
    viewport_height
  } else {
    1
  }
  let source_viewport_width = {
    let raw = if view_width > 0 { view_width } else { safe_scene_width }
    if raw > safe_scene_width {
      safe_scene_width
    } else {
      raw
    }
  }
  let source_viewport_height = {
    let raw = if view_height > 0 { view_height } else { safe_scene_height }
    if raw > safe_scene_height {
      safe_scene_height
    } else {
      raw
    }
  }
  let safe_max_mip_dimension = if max_mip_dimension < 4 {
    4
  } else {
    max_mip_dimension
  }
  let mip_count = bloom2d_effective_mip_count(safe_max_mip_dimension)
  let downsample_first_pipeline : @wgpu.RenderPipeline? = if use_uniform_scale {
    if use_prefilter {
      self.bloom2d_downsample_first_uniform_pipeline
    } else {
      self.bloom2d_downsample_first_no_threshold_uniform_pipeline
    }
  } else if use_prefilter {
    self.bloom2d_downsample_first_pipeline
  } else {
    self.bloom2d_downsample_first_no_threshold_pipeline
  }
  let downsample_pipeline : @wgpu.RenderPipeline? = if use_uniform_scale {
    self.bloom2d_downsample_uniform_pipeline
  } else {
    self.bloom2d_downsample_pipeline
  }
  let upsample_pipeline : @wgpu.RenderPipeline? = if composite_mode == 0 {
    self.bloom2d_upsample_pipeline_energy
  } else {
    self.bloom2d_upsample_pipeline_additive
  }
  let intermediate_bind_layout = self.bloom2d_intermediate_bgl

  active_pass.end()
  active_pass.release()
  frame.pass = None

  let mut bloom_ready = bloom_enabled &&
    intensity_value > 0.0F &&
    downsample_first_pipeline is Some(_) &&
    downsample_pipeline is Some(_) &&
    upsample_pipeline is Some(_)
  let mut bloom_width = 1
  let mut bloom_height = 1
  let mut max_mip_f = 1.0F
  if bloom_ready {
    let mip_height_ratio = safe_max_mip_dimension.to_double() /
      safe_viewport_height.to_double()
    let bloom_width_est = safe_viewport_width.to_double() * mip_height_ratio +
      0.5
    let bloom_height_est = safe_viewport_height.to_double() * mip_height_ratio +
      0.5
    bloom_width = {
      let raw = bloom_width_est.to_int()
      if raw < 1 {
        1
      } else {
        raw
      }
    }
    bloom_height = {
      let raw = bloom_height_est.to_int()
      if raw < 1 {
        1
      } else {
        raw
      }
    }
    ensure_bloom2d_mip_texture(self, mip_count, bloom_width, bloom_height)
    if self.bloom2d_mip_views.length() < mip_count {
      bloom_ready = false
    } else {
      let bloom_uniform = bloom2d_uniform_bytes(
        Float::from_double(safe_scene_width.to_double()),
        Float::from_double(safe_scene_height.to_double()),
        0.0F,
        0.0F,
        Float::from_double(source_viewport_width.to_double()),
        Float::from_double(source_viewport_height.to_double()),
        threshold_value,
        threshold_softness_value,
        scale_x_value,
        scale_y_value,
        exposure_value,
        fxaa_enabled_value,
        fxaa_edge_threshold_value,
        tonemapping_mode_value,
        deband_dither_enabled_value,
        bloom_weight,
        0.0F,
        chromatic_aberration_value,
        vignette_value,
      )
      self.queue.write_buffer(settings_buf, 0UL, bloom_uniform)
      if intermediate_bind_layout is Some(bind_layout) &&
        create_bloom2d_intermediate_bind_group(
          self,
          bind_layout,
          scene_texture.view,
          bloom_sampler,
          settings_buf,
          "mgstudio_bloom2d_downsample_first_bg",
        )
        is Some(first_bg) {
        let first_pass = frame.encoder.begin_render_pass_color_clear(
          self.bloom2d_mip_views[0],
          0.0F,
          0.0F,
          0.0F,
          1.0F,
        )
        let mut mip_size_w = bloom_width
        let mut mip_size_h = bloom_height
        first_pass.set_viewport(
          0.0F,
          0.0F,
          Float::from_double(mip_size_w.to_double()),
          Float::from_double(mip_size_h.to_double()),
          0.0F,
          1.0F,
        )
        first_pass.set_scissor_rect(
          0U,
          0U,
          mip_size_w.reinterpret_as_uint(),
          mip_size_h.reinterpret_as_uint(),
        )
        first_pass.set_pipeline(downsample_first_pipeline.unwrap())
        first_pass.set_bind_group(0U, first_bg, [])
        first_pass.draw(3U, 1U, 0U, 0U)
        first_pass.end()
        first_pass.release()
        first_bg.release()

        for mip in 1..<mip_count {
          if !bloom_ready {
            break
          }
          if intermediate_bind_layout is Some(bind_layout) &&
            create_bloom2d_intermediate_bind_group(
              self,
              bind_layout,
              self.bloom2d_mip_views[mip - 1],
              bloom_sampler,
              settings_buf,
              "mgstudio_bloom2d_downsample_bg",
            )
            is Some(downsample_bg) {
            mip_size_w = if mip_size_w > 1 { mip_size_w / 2 } else { 1 }
            mip_size_h = if mip_size_h > 1 { mip_size_h / 2 } else { 1 }
            let pass = frame.encoder.begin_render_pass_color_clear(
              self.bloom2d_mip_views[mip],
              0.0F,
              0.0F,
              0.0F,
              1.0F,
            )
            pass.set_viewport(
              0.0F,
              0.0F,
              Float::from_double(mip_size_w.to_double()),
              Float::from_double(mip_size_h.to_double()),
              0.0F,
              1.0F,
            )
            pass.set_scissor_rect(
              0U,
              0U,
              mip_size_w.reinterpret_as_uint(),
              mip_size_h.reinterpret_as_uint(),
            )
            pass.set_pipeline(downsample_pipeline.unwrap())
            pass.set_bind_group(0U, downsample_bg, [])
            pass.draw(3U, 1U, 0U, 0U)
            pass.end()
            pass.release()
            downsample_bg.release()
          } else {
            bloom_ready = false
          }
        }

        let max_mip = if mip_count > 1 { mip_count - 1 } else { 1 }
        max_mip_f = Float::from_double(max_mip.to_double())
        let mut upsample_mip = mip_count - 1
        while bloom_ready && upsample_mip >= 1 {
          let blend = bloom2d_compute_blend_factor(
            intensity_value,
            low_frequency_boost_value,
            low_frequency_boost_curvature_value,
            high_pass_frequency_value,
            composite_mode,
            Float::from_double(upsample_mip.to_double()),
            max_mip_f,
          )
          let upsample_uniform = bloom2d_uniform_bytes(
            Float::from_double(safe_scene_width.to_double()),
            Float::from_double(safe_scene_height.to_double()),
            0.0F,
            0.0F,
            Float::from_double(source_viewport_width.to_double()),
            Float::from_double(source_viewport_height.to_double()),
            threshold_value,
            threshold_softness_value,
            scale_x_value,
            scale_y_value,
            exposure_value,
            fxaa_enabled_value,
            fxaa_edge_threshold_value,
            tonemapping_mode_value,
            deband_dither_enabled_value,
            bloom_weight,
            blend,
            chromatic_aberration_value,
            vignette_value,
          )
          self.queue.write_buffer(settings_buf, 0UL, upsample_uniform)
          if intermediate_bind_layout is Some(bind_layout) &&
            create_bloom2d_intermediate_bind_group(
              self,
              bind_layout,
              self.bloom2d_mip_views[upsample_mip],
              bloom_sampler,
              settings_buf,
              "mgstudio_bloom2d_upsample_bg",
            )
            is Some(upsample_bg) {
            let size_w = bloom2d_mip_dimension(bloom_width, upsample_mip - 1)
            let size_h = bloom2d_mip_dimension(bloom_height, upsample_mip - 1)
            let pass = frame.encoder.begin_render_pass_color_load(
              self.bloom2d_mip_views[upsample_mip - 1],
            )
            pass.set_viewport(
              0.0F,
              0.0F,
              Float::from_double(size_w.to_double()),
              Float::from_double(size_h.to_double()),
              0.0F,
              1.0F,
            )
            pass.set_scissor_rect(
              0U,
              0U,
              size_w.reinterpret_as_uint(),
              size_h.reinterpret_as_uint(),
            )
            pass.set_pipeline(upsample_pipeline.unwrap())
            pass.set_bind_group(0U, upsample_bg, [])
            pass.draw(3U, 1U, 0U, 0U)
            pass.end()
            pass.release()
            upsample_bg.release()
          } else {
            bloom_ready = false
          }
          upsample_mip = upsample_mip - 1
        }
      } else {
        bloom_ready = false
      }
    }
  }

  let final_bloom_weight = if bloom_ready {
    bloom2d_compute_blend_factor(
      intensity_value, low_frequency_boost_value, low_frequency_boost_curvature_value,
      high_pass_frequency_value, composite_mode, 0.0F, max_mip_f,
    )
  } else {
    0.0F
  }
  let final_uniform = bloom2d_uniform_bytes(
    Float::from_double(safe_scene_width.to_double()),
    Float::from_double(safe_scene_height.to_double()),
    0.0F,
    0.0F,
    Float::from_double(source_viewport_width.to_double()),
    Float::from_double(source_viewport_height.to_double()),
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    exposure_value,
    fxaa_enabled_value,
    fxaa_edge_threshold_value,
    tonemapping_mode_value,
    deband_dither_enabled_value,
    final_bloom_weight,
    0.0F,
    chromatic_aberration_value,
    vignette_value,
  )
  self.queue.write_buffer(settings_buf, 0UL, final_uniform)

  let hdr_view = if bloom_ready {
    self.bloom2d_mip_views[0]
  } else {
    scene_texture.view
  }
  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    if create_bloom2d_final_bind_group(
        self,
        final_bind_layout,
        hdr_view,
        bloom_sampler,
        settings_buf,
        scene_texture.view,
        selected_lut_view,
        "mgstudio_bloom2d_final_bg",
      )
      is Some(final_bg) {
      let final_pass = frame.encoder.begin_render_pass_color_load(dst_view)
      final_pass.set_viewport(
        Float::from_double(pass_state.viewport_x.to_double()),
        Float::from_double(pass_state.viewport_y.to_double()),
        Float::from_double(pass_state.viewport_w.to_double()),
        Float::from_double(pass_state.viewport_h.to_double()),
        pass_state.viewport_depth_min,
        pass_state.viewport_depth_max,
      )
      final_pass.set_scissor_rect(
        pass_state.viewport_x,
        pass_state.viewport_y,
        pass_state.viewport_w,
        pass_state.viewport_h,
      )
      final_pass.set_pipeline(final_pipeline)
      final_pass.set_bind_group(0U, final_bg, [])
      final_pass.draw(3U, 1U, 0U, 0U)
      final_pass.end()
      final_pass.release()
      final_bg.release()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn GpuBackend::draw_mesh3d(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  previous_x : Float,
  previous_y : Float,
  previous_z : Float,
  previous_rotation_x : Float,
  previous_rotation_y : Float,
  previous_rotation_z : Float,
  previous_rotation_w : Float,
  previous_scale_x : Float,
  previous_scale_y : Float,
  previous_scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  uv_transform_mode : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  unlit : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_texture_id : Int,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_texture_id : Int,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  if mesh.vertex_stride_bytes != 36UL {
    return
  }
  let transparent = color_a < 0.999F
  let pass_kind_raw = ps.pass_kind
  if !pass_kind_decal_enabled(pass_kind_raw) && mesh3d_draw_is_decal(cull_mode) {
    return
  }
  if !pass_kind_fog_enabled(pass_kind_raw) && mesh3d_draw_is_fog(cull_mode) {
    return
  }
  if !pass_kind_postprocess_enabled(pass_kind_raw) &&
    mesh3d_draw_is_postprocess_proxy(cull_mode) {
    return
  }
  let pass_kind = pass_kind_base_kind(pass_kind_raw)
  if pass_kind == PASS_KIND_BASE_MOTION_VECTOR {
    if mesh.primitive_topology != MESH3D_TOPOLOGY_TRIANGLE_LIST {
      return
    }
    if transparent {
      return
    }
    ensure_mesh3d_motion_vector_pipeline(self)
    guard self.mesh3d_motion_vector_pipeline is Some(pipeline) else { return }
    guard self.mesh3d_motion_vector_uniform_buf is Some(uniform_buf) else {
      return
    }
    guard self.mesh3d_motion_vector_uniform_bg is Some(uniform_bg) else {
      return
    }
    let aspect_ratio = if ps.height_logical > 0.0F {
      ps.width_logical / ps.height_logical
    } else {
      1.0F
    }
    let bytes = f32le_pack([
      x,
      y,
      z,
      1.0F,
      rotation_x,
      rotation_y,
      rotation_z,
      rotation_w,
      scale_x,
      scale_y,
      scale_z,
      1.0F,
      previous_x,
      previous_y,
      previous_z,
      1.0F,
      previous_rotation_x,
      previous_rotation_y,
      previous_rotation_z,
      previous_rotation_w,
      previous_scale_x,
      previous_scale_y,
      previous_scale_z,
      1.0F,
      ps.camera_x,
      ps.camera_y,
      ps.camera_z,
      1.0F,
      ps.camera_rot_x,
      ps.camera_rot_y,
      ps.camera_rot_z,
      ps.camera_rot_w,
      ps.previous_camera_x,
      ps.previous_camera_y,
      ps.previous_camera_z,
      1.0F,
      ps.previous_camera_rot_x,
      ps.previous_camera_rot_y,
      ps.previous_camera_rot_z,
      ps.previous_camera_rot_w,
      ps.camera_fov_y,
      aspect_ratio,
      ps.camera_near,
      ps.camera_far,
      ps.sub_camera_view_scale_x,
      ps.sub_camera_view_scale_y,
      ps.sub_camera_view_bias_x,
      ps.sub_camera_view_bias_y,
    ])
    self.queue.write_buffer(uniform_buf, 0UL, bytes)
    pass.set_pipeline(pipeline)
    pass.set_bind_group(0U, uniform_bg, [])
    let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
      mesh.vertex_stride_bytes
    pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
    let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
    return
  }
  guard mesh3d_pipeline_for_current_pass(
      self,
      transparent,
      mesh.primitive_topology,
      cull_mode,
    )
    is Some(pipeline) else {
    return
  }
  let mesh3d_uniform_slot_index = self.mesh3d_uniform_slot_used
  guard ensure_mesh3d_uniform_slot(self, mesh3d_uniform_slot_index)
    is Some(uniform_slot) else {
    return
  }
  self.mesh3d_uniform_slot_used = mesh3d_uniform_slot_index + 1
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    -1
  } else {
    normal_texture_id
  }
  let resolved_emissive_texture_id = if emissive_texture_id < 0 {
    -1
  } else {
    emissive_texture_id
  }
  let resolved_metallic_roughness_texture_id = if metallic_roughness_texture_id <
    0 {
    -1
  } else {
    metallic_roughness_texture_id
  }
  let resolved_occlusion_texture_id = if occlusion_texture_id < 0 {
    -1
  } else {
    occlusion_texture_id
  }
  let resolved_depth_texture_id = if depth_texture_id < 0 {
    -1
  } else {
    depth_texture_id
  }
  let resolved_anisotropy_texture_id = if anisotropy_texture_id < 0 {
    -1
  } else {
    anisotropy_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  let resolved_transmission_source_texture_id = if transmission_source_texture_id <
    0 {
    -1
  } else {
    transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    point_shadow_texture_id
  }
  guard resolve_mesh3d_texture(self, resolved_base_texture_id)
    is Some(base_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_emissive_texture_id)
    is Some(emissive_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_metallic_roughness_texture_id)
    is Some(metallic_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_occlusion_texture_id)
    is Some(occlusion_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_depth_texture_id)
    is Some(depth_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_anisotropy_texture_id)
    is Some(anisotropy_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  let textured = texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let emissive_textured = emissive_texture_id >= 0
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let occlusion_textured = occlusion_texture_id >= 0
  let depth_textured = depth_texture_id >= 0
  let anisotropy_textured = anisotropy_texture_id >= 0
  let specular_tint_textured = specular_tint_texture_id >= 0
  let transmission_source_textured = transmission_source_texture_id >= 0
  let point_shadow_textured = point_shadow_texture_id >= 0
  let aspect_ratio = if ps.height_logical > 0.0F {
    ps.width_logical / ps.height_logical
  } else {
    1.0F
  }
  let uv_transform_a_value = uv_transform_a
  let uv_transform_b_value = uv_transform_b
  let uv_transform_c_value = uv_transform_c
  let uv_transform_d_value = uv_transform_d
  let uv_transform_tx_value = uv_transform_tx
  let uv_transform_ty_value = uv_transform_ty
  let uv_transform_mode_value = if uv_transform_mode < 0.0F {
    -1.0F
  } else if textured ||
    normal_textured ||
    emissive_textured ||
    metallic_roughness_textured ||
    occlusion_textured ||
    depth_textured ||
    anisotropy_textured ||
    specular_tint_textured {
    1.0F
  } else {
    0.0F
  }
  let bytes = f32le_pack([
    x,
    y,
    z,
    1.0F,
    rotation_x,
    rotation_y,
    rotation_z,
    rotation_w,
    scale_x,
    scale_y,
    scale_z,
    1.0F,
    ps.camera_x,
    ps.camera_y,
    ps.camera_z,
    1.0F,
    ps.camera_rot_x,
    ps.camera_rot_y,
    ps.camera_rot_z,
    ps.camera_rot_w,
    ps.camera_fov_y,
    aspect_ratio,
    ps.camera_near,
    ps.camera_far,
    ps.sub_camera_view_scale_x,
    ps.sub_camera_view_scale_y,
    ps.sub_camera_view_bias_x,
    ps.sub_camera_view_bias_y,
    color_r,
    color_g,
    color_b,
    color_a,
    uv_transform_a_value,
    uv_transform_b_value,
    uv_transform_c_value,
    uv_transform_tx_value,
    uv_transform_d_value,
    uv_transform_ty_value,
    uv_transform_mode_value,
    0.0F,
    ps.ambient_r,
    ps.ambient_g,
    ps.ambient_b,
    ps.ambient_brightness,
    ps.directional_dir_x,
    ps.directional_dir_y,
    ps.directional_dir_z,
    ps.directional_illuminance,
    ps.directional_color_r,
    ps.directional_color_g,
    ps.directional_color_b,
    1.0F,
    ps.point_pos_x,
    ps.point_pos_y,
    ps.point_pos_z,
    ps.point_range,
    ps.point_color_r,
    ps.point_color_g,
    ps.point_color_b,
    ps.point_intensity,
    ps.spot_pos_x,
    ps.spot_pos_y,
    ps.spot_pos_z,
    ps.spot_range,
    ps.spot_dir_x,
    ps.spot_dir_y,
    ps.spot_dir_z,
    ps.spot_inner_angle,
    ps.spot_color_r,
    ps.spot_color_g,
    ps.spot_color_b,
    ps.spot_intensity,
    ps.spot_outer_angle,
    if transmission_source_textured {
      transmission_blur_taps
    } else {
      0.0F
    },
    if transmission_source_textured {
      transmission_steps
    } else {
      0.0F
    },
    0.0F,
    emissive_r,
    emissive_g,
    emissive_b,
    unlit,
    metallic,
    roughness,
    reflectance,
    if normal_textured {
      1.0F
    } else {
      0.0F
    },
    if textured {
      1.0F
    } else {
      0.0F
    },
    if emissive_textured {
      1.0F
    } else {
      0.0F
    },
    if metallic_roughness_textured {
      1.0F
    } else {
      0.0F
    },
    if occlusion_textured {
      1.0F
    } else {
      0.0F
    },
    parallax_depth_scale,
    max_parallax_layer_count,
    max_relief_mapping_search_steps,
    if depth_textured {
      1.0F
    } else {
      0.0F
    },
    anisotropy_strength,
    cosf(anisotropy_rotation),
    sinf(anisotropy_rotation),
    if anisotropy_textured {
      1.0F
    } else {
      0.0F
    },
    specular_tint_r,
    specular_tint_g,
    specular_tint_b,
    if specular_tint_textured {
      1.0F
    } else {
      0.0F
    },
    diffuse_transmission,
    specular_transmission,
    thickness,
    ior,
    if point_shadow_textured {
      point_shadow_enabled
    } else {
      0.0F
    },
    if point_shadow_textured {
      point_shadow_depth_bias
    } else {
      0.0F
    },
    Float::from_int(mesh3d_cull_mode_sanitize(cull_mode)),
    0.0F,
  ])
  self.queue.write_buffer(uniform_slot.buffer, 0UL, bytes)
  let material_bg = mesh3d_material_cache_get_or_create(
    self, base_texture, normal_texture, emissive_texture, metallic_roughness_texture,
    occlusion_texture, depth_texture, anisotropy_texture, specular_tint_texture,
    transmission_source_texture, point_shadow_texture,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_slot.bind_group, [])
  pass.set_bind_group(1U, material_bg, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  debug_mesh3d_executed_draw_calls_ref.val = debug_mesh3d_executed_draw_calls_ref.val +
    1
  current_frame_mesh3d_executed_draw_calls_ref.val = current_frame_mesh3d_executed_draw_calls_ref.val +
    1
  if mesh.primitive_topology == MESH3D_TOPOLOGY_LINE_STRIP {
    pass.draw(mesh.vertex_count, 1U, 0U, 0U)
  } else {
    let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
  }
}

///|
pub type NativeGpuDevice = Int

///|
pub type NativeGpuQueue = Int

///|
pub type NativeGpuSurface = Int

///|
pub type NativeGpuFrame = Int

///|
pub struct RenderDiagnosticsSnapshot {
  mesh2d_draw_calls : Int
  mesh2d_executed_draw_calls : Int
  mesh3d_draw_calls : Int
  mesh3d_executed_draw_calls : Int
}

///|
pub fn RenderDiagnosticsSnapshot::default() -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: 0,
    mesh2d_executed_draw_calls: 0,
    mesh3d_draw_calls: 0,
    mesh3d_executed_draw_calls: 0,
  }
}

///|
pub fn RenderDiagnosticsSnapshot::new(
  mesh2d_draw_calls : Int,
  mesh2d_executed_draw_calls : Int,
  mesh3d_draw_calls : Int,
  mesh3d_executed_draw_calls : Int,
) -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls,
    mesh2d_executed_draw_calls,
    mesh3d_draw_calls,
    mesh3d_executed_draw_calls,
  }
}

///|
priv struct SurfaceBinding {
  id : NativeGpuSurface
  window : Int
}

///|
const PRIMARY_DEVICE_ID : NativeGpuDevice = 1

///|
const PRIMARY_QUEUE_ID : NativeGpuQueue = 2

///|
const DEFAULT_ASSETS_DIR : String = "./assets"

///|
let backend_ref : Ref[GpuBackend?] = Ref::new(None)

///|
let surfaces_ref : Ref[Array[SurfaceBinding]] = Ref::new([])

///|
let next_surface_id_ref : Ref[Int] = Ref::new(1)

///|
let next_frame_id_ref : Ref[Int] = Ref::new(1)

///|
let next_screenshot_capture_id_ref : Ref[Int] = Ref::new(1)

///|
let pending_screenshot_captures_ref : Ref[Array[PendingScreenshotCapture]] = Ref::new([],
)

///|
let pending_surface_screenshot_capture_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let active_surface_screenshot_capture_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let inflight_screenshot_captures_ref : Ref[Array[InflightScreenshotCapture]] = Ref::new([],
)

///|
let completed_screenshot_captures_ref : Ref[Array[ScreenshotCaptureResult]] = Ref::new([],
)

///|
let gizmo_line_mesh_id_ref : Ref[Int] = Ref::new(0)

///|
let debug_frame_counter_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let last_frame_render_diagnostics_snapshot_ref : Ref[RenderDiagnosticsSnapshot] = Ref::new(
  RenderDiagnosticsSnapshot::default(),
)

///|
let debug_mesh2d_drop_no_frame_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_state_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_missing_mesh_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_bad_stride_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pipeline_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_buf_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_bg_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_texture_ref : Ref[Int] = Ref::new(0)

///|
fn next_surface_id() -> NativeGpuSurface {
  let id = next_surface_id_ref.val
  next_surface_id_ref.val = next_surface_id_ref.val + 1
  id
}

///|
fn next_frame_id() -> NativeGpuFrame {
  let id = next_frame_id_ref.val
  next_frame_id_ref.val = next_frame_id_ref.val + 1
  id
}

///|
fn next_screenshot_capture_id() -> Int {
  let id = next_screenshot_capture_id_ref.val
  next_screenshot_capture_id_ref.val = next_screenshot_capture_id_ref.val + 1
  id
}

///|
fn screenshot_capture_bytes_per_pixel(format_raw : UInt) -> Int? {
  if format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB ||
    format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM ||
    format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
    return Some(4)
  }
  None
}

///|
fn screenshot_capture_row_bytes(width : Int, bytes_per_pixel : Int) -> Int {
  let unpadded = width * bytes_per_pixel
  let remainder = unpadded % 256
  if remainder == 0 {
    unpadded
  } else {
    unpadded + (256 - remainder)
  }
}

///|
fn screenshot_capture_pixels_rgba8(
  format_raw : UInt,
  width : Int,
  height : Int,
  bytes : Bytes,
) -> Bytes? {
  let compact_len = width * height * 4
  let row_bytes = screenshot_capture_row_bytes(width, 4)
  let expected_len = row_bytes * height
  if bytes.length() != compact_len && bytes.length() != expected_len {
    return None
  }
  if bytes.length() == compact_len &&
    (
      format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM ||
      format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
    ) {
    return Some(bytes)
  }
  if format_raw != @wgpu.TEXTURE_FORMAT_BGRA8_UNORM &&
    format_raw != @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB &&
    format_raw != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM &&
    format_raw != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB {
    return None
  }
  let out : Array[Byte] = []
  for y in 0..<height {
    let row_start = y * row_bytes
    for x in 0..<width {
      let base = row_start + x * 4
      if format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM ||
        format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
        out.push(bytes[base + 2])
        out.push(bytes[base + 1])
        out.push(bytes[base])
        out.push(bytes[base + 3])
      } else {
        out.push(bytes[base])
        out.push(bytes[base + 1])
        out.push(bytes[base + 2])
        out.push(bytes[base + 3])
      }
    }
  }
  Some(Bytes::from_array(out))
}

///|
fn screenshot_enqueue_texture_capture(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Int {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(_) else {
    return 0
  }
  guard backend.frame is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_screenshot_captures_ref.val.push(PendingScreenshotCapture::{
    id: capture_id,
    width,
    height,
    format_raw,
    texture,
  })
  capture_id
}

///|
fn screenshot_read_texture_sync(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> ScreenshotCaptureResult? {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(bytes_per_pixel) else {
    return None
  }
  let byte_len = (screenshot_capture_row_bytes(width, bytes_per_pixel) * height).to_uint64()
  let usage = @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let buffer = backend.device.create_buffer(size=byte_len, usage~)
  let encoder = backend.device.create_command_encoder()
  encoder.copy_texture_to_buffer_bytes_per_pixel(
    texture,
    buffer,
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    bytes_per_pixel.reinterpret_as_uint(),
  )
  let cmd = encoder.finish()
  backend.queue.submit_one(cmd)
  let bytes = buffer.readback(backend.instance, 0UL, byte_len)
  guard screenshot_capture_pixels_rgba8(format_raw, width, height, bytes)
    is Some(pixels) else {
    buffer.release()
    cmd.release()
    encoder.release()
    return None
  }
  buffer.release()
  cmd.release()
  encoder.release()
  Some(ScreenshotCaptureResult::{ id: 0, width, height, pixels })
}

///|
fn screenshot_enqueue_copy_to_buffer(
  backend : GpuBackend,
  frame : GpuFrameState,
  capture_id : Int,
  texture : @wgpu.Texture,
  width : Int,
  height : Int,
  format_raw : UInt,
) -> Unit {
  guard screenshot_capture_bytes_per_pixel(format_raw) is Some(bytes_per_pixel) else {
    return
  }
  let byte_len = (screenshot_capture_row_bytes(width, bytes_per_pixel) * height).to_uint64()
  let usage = @wgpu.BufferUsage::from_u64(
    @wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let buffer = backend.device.create_buffer(size=byte_len, usage~)
  frame.encoder.copy_texture_to_buffer_bytes_per_pixel(
    texture,
    buffer,
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    bytes_per_pixel.reinterpret_as_uint(),
  )
  inflight_screenshot_captures_ref.val.push(InflightScreenshotCapture::{
    id: capture_id,
    width,
    height,
    format_raw,
    buffer,
    byte_len,
  })
}

///|
fn screenshot_encode_pending_texture_captures(
  backend : GpuBackend,
  frame : GpuFrameState,
) -> Unit {
  let pending = pending_screenshot_captures_ref.val
  pending_screenshot_captures_ref.val = []
  for capture in pending {
    screenshot_enqueue_copy_to_buffer(
      backend,
      frame,
      capture.id,
      capture.texture,
      capture.width,
      capture.height,
      capture.format_raw,
    )
  }
}

///|
fn screenshot_encode_active_surface_captures(
  backend : GpuBackend,
  frame : GpuFrameState,
) -> Unit {
  if !backend.surface_capture_active {
    return
  }
  guard surface_capture_texture_info(backend) is Some(surface_capture_texture) else {
    return
  }
  let active_capture_ids = active_surface_screenshot_capture_ids_ref.val
  active_surface_screenshot_capture_ids_ref.val = []
  for capture_id in active_capture_ids {
    screenshot_enqueue_copy_to_buffer(
      backend,
      frame,
      capture_id,
      surface_capture_texture.texture,
      surface_capture_texture.width,
      surface_capture_texture.height,
      surface_capture_texture.format_raw,
    )
  }
}

///|
fn screenshot_present_surface_capture(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if !backend.surface_capture_active {
    return
  }
  guard surface_capture_texture_info(backend) is Some(surface_capture_texture) else {
    backend.surface_capture_active = false
    return
  }
  let width = if backend.configured_width <= 0 {
    1
  } else {
    backend.configured_width
  }
  let height = if backend.configured_height <= 0 {
    1
  } else {
    backend.configured_height
  }
  backend.surface_capture_active = false
  backend.begin_pass(
    -1, width, height, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0, 0, width,
    height, 0.0F, 1.0F, 1,
  )
  backend.draw_sprite_uv(
    surface_capture_texture.id,
    0.0F,
    0.0F,
    0.0F,
    Float::from_double(width.to_double()) / 128.0F,
    Float::from_double(height.to_double()) / 128.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  )
  backend.end_pass()
}

///|
fn screenshot_collect_completed_captures(backend : GpuBackend) -> Unit {
  let inflight = inflight_screenshot_captures_ref.val
  inflight_screenshot_captures_ref.val = []
  for capture in inflight {
    let bytes = capture.buffer.readback(backend.instance, 0UL, capture.byte_len)
    capture.buffer.release()
    if screenshot_capture_pixels_rgba8(
        capture.format_raw,
        capture.width,
        capture.height,
        bytes,
      )
      is Some(pixels) {
      completed_screenshot_captures_ref.val.push(ScreenshotCaptureResult::{
        id: capture.id,
        width: capture.width,
        height: capture.height,
        pixels,
      })
    }
  }
}

///|
fn env_or_default(key : String, default_value : String) -> String {
  match @sys.get_env_var(key) {
    Some(value) if value != "" => value
    _ => default_value
  }
}

///|
fn debug_runtime_error(context : String, err : GpuBackendError) -> Unit {
  @debug.debug("[native_gpu] " + context + ": " + err.to_string())
}

///|
fn ensure_backend() -> GpuBackend? {
  if backend_ref.val is Some(backend) {
    return Some(backend)
  }
  let assets_base = env_or_default("MGSTUDIO_ASSETS_DIR", DEFAULT_ASSETS_DIR)
  let backend = GpuBackend::new(assets_base~) catch { _ => return None }
  backend_ref.val = Some(backend)
  Some(backend)
}

///|
fn parse_f32_csv(csv : String) -> Array[Float]? {
  let trimmed = csv.trim().to_string()
  if trimmed == "" {
    return Some([])
  }
  let values : Array[Float] = []
  for part in csv.split(",") {
    let token = part.to_string().trim().to_string()
    if token == "" {
      continue
    }
    let parsed = @strconv.parse_double(token) catch { _ => return None }
    values.push(Float::from_double(parsed))
  }
  Some(values)
}

///|
pub fn request_device() -> NativeGpuDevice {
  if ensure_backend() is Some(_) {
    PRIMARY_DEVICE_ID
  } else {
    0
  }
}

///|
pub fn get_queue(device : NativeGpuDevice) -> NativeGpuQueue {
  if device == PRIMARY_DEVICE_ID && ensure_backend() is Some(_) {
    PRIMARY_QUEUE_ID
  } else {
    0
  }
}

///|
pub fn create_surface(window : Int) -> NativeGpuSurface {
  let surface_id = next_surface_id()
  surfaces_ref.val.push(SurfaceBinding::{ id: surface_id, window })
  if ensure_backend() is Some(backend) {
    backend.create_surface(window) catch {
      err => debug_runtime_error("create_surface", err)
    }
  }
  surface_id
}

///|
pub fn configure_surface(
  device~ : NativeGpuDevice,
  surface~ : NativeGpuSurface,
  width~ : Int,
  height~ : Int,
) -> Unit {
  device |> ignore
  if surface > 0 {
    let _ = surfaces_ref.val.length()
  }
  if ensure_backend() is Some(backend) {
    backend.configure_surface(width, height) catch {
      err => debug_runtime_error("configure_surface", err)
    }
  }
}

///|
pub fn begin_frame(surface : NativeGpuSurface) -> NativeGpuFrame {
  surface |> ignore
  current_frame_mesh2d_draw_calls_ref.val = 0
  current_frame_mesh2d_executed_draw_calls_ref.val = 0
  current_frame_mesh3d_draw_calls_ref.val = 0
  current_frame_mesh3d_executed_draw_calls_ref.val = 0
  if ensure_backend() is Some(backend) {
    try {
      backend.begin_frame()
      return next_frame_id()
    } catch {
      err => debug_runtime_error("begin_frame", err)
    }
  }
  0
}

///|
pub fn end_frame(frame : NativeGpuFrame) -> Unit {
  frame |> ignore
  if ensure_backend() is Some(backend) {
    backend.end_frame() catch {
      err => debug_runtime_error("end_frame", err)
    }
  }
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: current_frame_mesh2d_draw_calls_ref.val,
    mesh2d_executed_draw_calls: current_frame_mesh2d_executed_draw_calls_ref.val,
    mesh3d_draw_calls: current_frame_mesh3d_draw_calls_ref.val,
    mesh3d_executed_draw_calls: current_frame_mesh3d_executed_draw_calls_ref.val,
  }
  debug_frame_counter_ref.val = debug_frame_counter_ref.val + 1
  if debug_frame_counter_ref.val % 60 == 0 {
    @debug.debug(
      "[native_gpu] draw stats(60f): mesh2d=" +
      debug_mesh2d_draw_calls_ref.val.to_string() +
      ", mesh2d_invalid_id=" +
      debug_mesh2d_invalid_id_calls_ref.val.to_string() +
      ", mesh2d_executed=" +
      debug_mesh2d_executed_draw_calls_ref.val.to_string() +
      ", mesh2d_drop(no_frame/no_pass/no_state/missing/stride/pipeline/ubo/bg/tex)=" +
      debug_mesh2d_drop_no_frame_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pass_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pass_state_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_missing_mesh_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_bad_stride_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pipeline_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_uniform_buf_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_uniform_bg_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_texture_ref.val.to_string() +
      ", mesh3d=" +
      debug_mesh3d_draw_calls_ref.val.to_string() +
      ", mesh3d_invalid_id=" +
      debug_mesh3d_invalid_id_calls_ref.val.to_string() +
      ", mesh3d_executed=" +
      debug_mesh3d_executed_draw_calls_ref.val.to_string(),
    )
    debug_mesh2d_draw_calls_ref.val = 0
    debug_mesh3d_draw_calls_ref.val = 0
    debug_mesh2d_invalid_id_calls_ref.val = 0
    debug_mesh3d_invalid_id_calls_ref.val = 0
    debug_mesh2d_executed_draw_calls_ref.val = 0
    debug_mesh3d_executed_draw_calls_ref.val = 0
    debug_mesh2d_drop_no_frame_ref.val = 0
    debug_mesh2d_drop_no_pass_ref.val = 0
    debug_mesh2d_drop_no_pass_state_ref.val = 0
    debug_mesh2d_drop_missing_mesh_ref.val = 0
    debug_mesh2d_drop_bad_stride_ref.val = 0
    debug_mesh2d_drop_no_pipeline_ref.val = 0
    debug_mesh2d_drop_no_uniform_buf_ref.val = 0
    debug_mesh2d_drop_no_uniform_bg_ref.val = 0
    debug_mesh2d_drop_no_texture_ref.val = 0
  }
}

///|
pub fn begin_pass(
  target_id~ : Int,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_rotation~ : Float,
  camera_scale~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  viewport_depth_min~ : Float,
  viewport_depth_max~ : Float,
  clear_enabled~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.begin_pass(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
      viewport_depth_min, viewport_depth_max, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass", err)
    }
  }
}

///|
pub fn begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_z~ : Float,
  camera_rot_x~ : Float,
  camera_rot_y~ : Float,
  camera_rot_z~ : Float,
  camera_rot_w~ : Float,
  camera_fov_y~ : Float,
  camera_near~ : Float,
  camera_far~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  ambient_r~ : Float,
  ambient_g~ : Float,
  ambient_b~ : Float,
  ambient_brightness~ : Float,
  directional_dir_x~ : Float,
  directional_dir_y~ : Float,
  directional_dir_z~ : Float,
  directional_color_r~ : Float,
  directional_color_g~ : Float,
  directional_color_b~ : Float,
  directional_illuminance~ : Float,
  point_pos_x~ : Float,
  point_pos_y~ : Float,
  point_pos_z~ : Float,
  point_color_r~ : Float,
  point_color_g~ : Float,
  point_color_b~ : Float,
  point_intensity~ : Float,
  point_range~ : Float,
  spot_pos_x~ : Float,
  spot_pos_y~ : Float,
  spot_pos_z~ : Float,
  spot_dir_x~ : Float,
  spot_dir_y~ : Float,
  spot_dir_z~ : Float,
  spot_color_r~ : Float,
  spot_color_g~ : Float,
  spot_color_b~ : Float,
  spot_intensity~ : Float,
  spot_range~ : Float,
  spot_inner_angle~ : Float,
  spot_outer_angle~ : Float,
  sub_camera_view_scale_x~ : Float,
  sub_camera_view_scale_y~ : Float,
  sub_camera_view_bias_x~ : Float,
  sub_camera_view_bias_y~ : Float,
  previous_camera_x~ : Float,
  previous_camera_y~ : Float,
  previous_camera_z~ : Float,
  previous_camera_rot_x~ : Float,
  previous_camera_rot_y~ : Float,
  previous_camera_rot_z~ : Float,
  previous_camera_rot_w~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.begin_pass_3d(
      target_id, target_layer, width, height, clear_r, clear_g, clear_b, clear_a,
      camera_x, camera_y, camera_z, camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w,
      camera_fov_y, camera_near, camera_far, viewport_x, viewport_y, viewport_width,
      viewport_height, ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x,
      directional_dir_y, directional_dir_z, directional_color_r, directional_color_g,
      directional_color_b, directional_illuminance, point_pos_x, point_pos_y, point_pos_z,
      point_color_r, point_color_g, point_color_b, point_intensity, point_range,
      spot_pos_x, spot_pos_y, spot_pos_z, spot_dir_x, spot_dir_y, spot_dir_z, spot_color_r,
      spot_color_g, spot_color_b, spot_intensity, spot_range, spot_inner_angle, spot_outer_angle,
      sub_camera_view_scale_x, sub_camera_view_scale_y, sub_camera_view_bias_x, sub_camera_view_bias_y,
      previous_camera_x, previous_camera_y, previous_camera_z, previous_camera_rot_x,
      previous_camera_rot_y, previous_camera_rot_z, previous_camera_rot_w, pass_kind,
      clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass_3d", err)
    }
  }
}

///|
pub fn set_scissor(x~ : Int, y~ : Int, width~ : Int, height~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_scissor(x, y, width, height) catch {
      _ => ()
    }
  }
}

///|
pub fn clear_scissor() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.clear_scissor() catch {
      _ => ()
    }
  }
}

///|
pub fn draw_sprite(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
) -> Unit {
  draw_sprite_uv(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    uv_min_x=0.0F,
    uv_min_y=0.0F,
    uv_max_x=1.0F,
    uv_max_y=1.0F,
  )
}

///|
pub fn draw_sprite_uv(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  uv_min_x~ : Float,
  uv_min_y~ : Float,
  uv_max_x~ : Float,
  uv_max_y~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_sprite_uv(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      uv_min_x, uv_min_y, uv_max_x, uv_max_y,
    ) catch {
      err => debug_runtime_error("draw_sprite_uv", err)
    }
  }
}

///|
pub fn draw_ui_rect(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  uv_min_x~ : Float,
  uv_min_y~ : Float,
  uv_max_x~ : Float,
  uv_max_y~ : Float,
  flags~ : Int,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  border_left~ : Float,
  border_top~ : Float,
  border_right~ : Float,
  border_bottom~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_rect(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      uv_min_x, uv_min_y, uv_max_x, uv_max_y, flags, radius_tl, radius_tr, radius_br,
      radius_bl, border_left, border_top, border_right, border_bottom,
    ) catch {
      err => debug_runtime_error("draw_ui_rect", err)
    }
  }
}

///|
pub fn draw_ui_box_shadow(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  size_x~ : Float,
  size_y~ : Float,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  blur~ : Float,
  samples~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_box_shadow(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      size_x, size_y, radius_tl, radius_tr, radius_br, radius_bl, blur, samples,
    ) catch {
      err => debug_runtime_error("draw_ui_box_shadow", err)
    }
  }
}

///|
pub fn draw_ui_texture_slice(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_slice_l~ : Float,
  texture_slice_t~ : Float,
  texture_slice_r~ : Float,
  texture_slice_b~ : Float,
  target_slice_l~ : Float,
  target_slice_t~ : Float,
  target_slice_r~ : Float,
  target_slice_b~ : Float,
  repeat_side_x~ : Float,
  repeat_side_y~ : Float,
  repeat_center_x~ : Float,
  repeat_center_y~ : Float,
  atlas_l~ : Float,
  atlas_t~ : Float,
  atlas_r~ : Float,
  atlas_b~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_texture_slice(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      texture_slice_l, texture_slice_t, texture_slice_r, texture_slice_b, target_slice_l,
      target_slice_t, target_slice_r, target_slice_b, repeat_side_x, repeat_side_y,
      repeat_center_x, repeat_center_y, atlas_l, atlas_t, atlas_r, atlas_b,
    ) catch {
      err => debug_runtime_error("draw_ui_texture_slice", err)
    }
  }
}

///|
pub fn draw_mesh(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
) -> Unit {
  debug_mesh2d_draw_calls_ref.val = debug_mesh2d_draw_calls_ref.val + 1
  current_frame_mesh2d_draw_calls_ref.val = current_frame_mesh2d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh2d_invalid_id_calls_ref.val = debug_mesh2d_invalid_id_calls_ref.val +
      1
  }
  if ensure_backend() is Some(backend) {
    backend.draw_mesh(
      mesh_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      texture_id, uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
    ) catch {
      err => debug_runtime_error("draw_mesh", err)
    }
  }
}

///|
pub fn draw_mesh3d(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  z~ : Float,
  rotation_x~ : Float,
  rotation_y~ : Float,
  rotation_z~ : Float,
  rotation_w~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  scale_z~ : Float,
  previous_x~ : Float,
  previous_y~ : Float,
  previous_z~ : Float,
  previous_rotation_x~ : Float,
  previous_rotation_y~ : Float,
  previous_rotation_z~ : Float,
  previous_rotation_w~ : Float,
  previous_scale_x~ : Float,
  previous_scale_y~ : Float,
  previous_scale_z~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_transform_a~ : Float,
  uv_transform_b~ : Float,
  uv_transform_c~ : Float,
  uv_transform_d~ : Float,
  uv_transform_tx~ : Float,
  uv_transform_ty~ : Float,
  uv_transform_mode~ : Float,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  emissive_r~ : Float,
  emissive_g~ : Float,
  emissive_b~ : Float,
  unlit~ : Float,
  metallic~ : Float,
  roughness~ : Float,
  reflectance~ : Float,
  parallax_depth_scale~ : Float,
  max_parallax_layer_count~ : Float,
  max_relief_mapping_search_steps~ : Float,
  anisotropy_texture_id~ : Int,
  anisotropy_strength~ : Float,
  anisotropy_rotation~ : Float,
  specular_tint_texture_id~ : Int,
  specular_tint_r~ : Float,
  specular_tint_g~ : Float,
  specular_tint_b~ : Float,
  diffuse_transmission~ : Float,
  specular_transmission~ : Float,
  thickness~ : Float,
  ior~ : Float,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  cull_mode~ : Int,
) -> Unit {
  debug_mesh3d_draw_calls_ref.val = debug_mesh3d_draw_calls_ref.val + 1
  current_frame_mesh3d_draw_calls_ref.val = current_frame_mesh3d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh3d_invalid_id_calls_ref.val = debug_mesh3d_invalid_id_calls_ref.val +
      1
  }
  if ensure_backend() is Some(backend) {
    backend.draw_mesh3d(
      mesh_id, x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x,
      scale_y, scale_z, previous_x, previous_y, previous_z, previous_rotation_x,
      previous_rotation_y, previous_rotation_z, previous_rotation_w, previous_scale_x,
      previous_scale_y, previous_scale_z, color_r, color_g, color_b, color_a, texture_id,
      uv_transform_a, uv_transform_b, uv_transform_c, uv_transform_d, uv_transform_tx,
      uv_transform_ty, uv_transform_mode, normal_texture_id, emissive_texture_id,
      metallic_roughness_texture_id, occlusion_texture_id, depth_texture_id, emissive_r,
      emissive_g, emissive_b, unlit, metallic, roughness, reflectance, parallax_depth_scale,
      max_parallax_layer_count, max_relief_mapping_search_steps, anisotropy_texture_id,
      anisotropy_strength, anisotropy_rotation, specular_tint_texture_id, specular_tint_r,
      specular_tint_g, specular_tint_b, diffuse_transmission, specular_transmission,
      thickness, ior, transmission_source_texture_id, transmission_blur_taps, transmission_steps,
      point_shadow_texture_id, point_shadow_enabled, point_shadow_depth_bias, cull_mode,
    ) catch {
      err => debug_runtime_error("draw_mesh3d", err)
    }
  }
}

///|
pub fn draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  shutter_angle~ : Float,
  samples~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_motion_blur(
      scene_texture_id, velocity_texture_id, shutter_angle, samples,
    ) catch {
      err => debug_runtime_error("draw_motion_blur", err)
    }
  }
}

///|
pub fn render_diagnostics_snapshot() -> RenderDiagnosticsSnapshot {
  last_frame_render_diagnostics_snapshot_ref.val
}

///|
pub fn screenshot_capture_surface_request() -> Int {
  guard ensure_backend() is Some(_) else { return 0 }
  let capture_id = next_screenshot_capture_id()
  pending_surface_screenshot_capture_ids_ref.val.push(capture_id)
  capture_id
}

///|
pub fn screenshot_capture_texture_request(texture_id~ : Int) -> Int {
  guard ensure_backend() is Some(backend) else { return 0 }
  guard find_texture(backend, texture_id) is Some(texture) else { return 0 }
  screenshot_enqueue_texture_capture(
    backend,
    texture.texture,
    texture.width,
    texture.height,
    texture.format_raw,
  )
}

///|
pub fn screenshot_take_capture_result(
  capture_id : Int,
) -> ScreenshotCaptureResult? {
  for i in 0..<completed_screenshot_captures_ref.val.length() {
    let capture = completed_screenshot_captures_ref.val[i]
    if capture.id == capture_id {
      completed_screenshot_captures_ref.val.remove(i) |> ignore
      return Some(capture)
    }
  }
  None
}

///|
pub fn screenshot_capture_texture_sync(
  texture_id~ : Int,
) -> ScreenshotCaptureResult? {
  guard ensure_backend() is Some(backend) else { return None }
  guard find_texture(backend, texture_id) is Some(texture) else { return None }
  screenshot_read_texture_sync(
    backend,
    texture.texture,
    texture.width,
    texture.height,
    texture.format_raw,
  )
}

///|
pub fn draw_bloom2d(
  scene_texture_id~ : Int,
  enabled~ : Int,
  intensity~ : Float,
  low_frequency_boost~ : Float,
  low_frequency_boost_curvature~ : Float,
  high_pass_frequency~ : Float,
  threshold~ : Float,
  threshold_softness~ : Float,
  composite_mode~ : Int,
  max_mip_dimension~ : Int,
  scale_x~ : Float,
  scale_y~ : Float,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold~ : Float,
  fxaa_edge_threshold_min~ : Float,
  chromatic_aberration_intensity~ : Float,
  chromatic_aberration_max_samples~ : Int,
  vignette_intensity~ : Float,
  vignette_radius~ : Float,
  vignette_smoothness~ : Float,
  vignette_roundness~ : Float,
  vignette_center_x~ : Float,
  vignette_center_y~ : Float,
  vignette_edge_compensation~ : Float,
  vignette_color_r~ : Float,
  vignette_color_g~ : Float,
  vignette_color_b~ : Float,
  vignette_color_a~ : Float,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
) -> Unit {
  let fxaa_edge_threshold_value = if fxaa_edge_threshold <
    fxaa_edge_threshold_min {
    fxaa_edge_threshold_min
  } else {
    fxaa_edge_threshold
  }
  let chromatic_aberration_value = chromatic_aberration_intensity
  let vignette_value = vignette_intensity
  chromatic_aberration_max_samples |> ignore
  vignette_radius |> ignore
  vignette_smoothness |> ignore
  vignette_roundness |> ignore
  vignette_center_x |> ignore
  vignette_center_y |> ignore
  vignette_edge_compensation |> ignore
  vignette_color_r |> ignore
  vignette_color_g |> ignore
  vignette_color_b |> ignore
  vignette_color_a |> ignore
  if ensure_backend() is Some(backend) {
    backend.draw_bloom2d(
      scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
      high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
      scale_x, scale_y, exposure, tonemapping_mode, deband_dither_enabled, view_width,
      view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
      fxaa_enabled, fxaa_edge_threshold_value, chromatic_aberration_value, vignette_value,
    ) catch {
      err => debug_runtime_error("draw_bloom2d", err)
    }
  }
}

///|
pub fn draw_gizmo_line(
  start_x~ : Float,
  start_y~ : Float,
  start_r~ : Float,
  start_g~ : Float,
  start_b~ : Float,
  start_a~ : Float,
  end_x~ : Float,
  end_y~ : Float,
  end_r~ : Float,
  end_g~ : Float,
  end_b~ : Float,
  end_a~ : Float,
  line_width~ : Float,
  style_kind~ : Int,
  gap_scale~ : Float,
  line_scale~ : Float,
) -> Unit {
  let line_width_value = if line_width < 1.0F { 1.0F } else { line_width }
  style_kind |> ignore
  gap_scale |> ignore
  line_scale |> ignore
  let dx = end_x - start_x
  let dy = end_y - start_y
  let length = Float::sqrt(dx * dx + dy * dy)
  if length <= 0.0F {
    return
  }
  let center_x = (start_x + end_x) * 0.5F
  let center_y = (start_y + end_y) * 0.5F
  let rotation = atan2f(dy, dx)
  let color_r = (start_r + end_r) * 0.5F
  let color_g = (start_g + end_g) * 0.5F
  let color_b = (start_b + end_b) * 0.5F
  let color_a = (start_a + end_a) * 0.5F
  if ensure_backend() is Some(backend) {
    try {
      let mesh_id = if gizmo_line_mesh_id_ref.val > 0 {
        gizmo_line_mesh_id_ref.val
      } else {
        let created = backend.create_mesh_rectangle(1.0F, 1.0F)
        if created > 0 {
          gizmo_line_mesh_id_ref.val = created
        }
        created
      }
      if mesh_id > 0 {
        backend.draw_mesh(
          mesh_id, center_x, center_y, rotation, length, line_width_value, color_r,
          color_g, color_b, color_a, -1, 0.0F, 0.0F, 1.0F, 1.0F,
        )
      }
    } catch {
      err => debug_runtime_error("draw_gizmo_line", err)
    }
  }
}

///|
pub fn end_pass() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.end_pass() catch {
      err => debug_runtime_error("end_pass", err)
    }
  }
}

///|
pub fn create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_rgba16f(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_point_light_shadow_target(size~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_point_light_shadow_target(size)
    } catch {
      _ => ()
    }
  }
  0
}

///|
fn mip_dim(base : Int, level : Int) -> Int {
  let shifted = base >> level
  if shifted <= 0 {
    1
  } else {
    shifted
  }
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let safe_mips = if mip_level_count <= 0 { 1 } else { mip_level_count }
  if ensure_backend() is Some(backend) {
    try {
      if safe_mips == 1 {
        let bytes = Bytes::makei(safe_width * safe_height * 4, _ => {
          (0).to_byte()
        })
        return backend.create_texture_rgba8(
          safe_width, safe_height, bytes, nearest,
        )
      }
      let levels : Array[Bytes] = []
      for level in 0..<safe_mips {
        let level_width = mip_dim(safe_width, level)
        let level_height = mip_dim(safe_height, level)
        levels.push(
          Bytes::makei(level_width * level_height * 4, _ => (0).to_byte()),
        )
      }
      return backend.create_texture_stacked_2d_with_format(
        safe_width,
        safe_height,
        1,
        @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
        levels,
        nearest,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_write_texture_region_rgba8(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8(
      texture_id, x, y, width, height, pixels_rgba8,
    )
  }
}

///|
pub fn asset_write_texture_region_rgba8_mip(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8_mip(
      texture_id, x, y, width, height, mip_level, pixels_rgba8,
    )
  }
}

///|
pub fn asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_mip_view(texture_id, mip_level)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_texture_width(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_width(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_texture_height(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_height(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_is_texture_loaded(texture_id~ : Int) -> Bool {
  if ensure_backend() is Some(backend) {
    backend.is_texture_loaded(texture_id)
  } else {
    false
  }
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  if ensure_backend() is Some(backend) {
    backend.supported_compressed_image_formats_mask()
  } else {
    0
  }
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.copy_texture_to_texture(
      dst_texture_id, dst_x, dst_y, src_texture_id,
    )
  }
}

///|
pub fn asset_set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_texture_sampler(
      texture_id, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
      mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
    ) catch {
      err => {
        let error_message = match err {
          Fatal(message) => message
        }
        abort(
          "wgpu: failed to set texture sampler for texture " +
          texture_id.to_string() +
          ": " +
          error_message,
        )
      }
    }
  }
}

///|
pub fn create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_mesh_capsule(radius, half_length, segments)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_mesh_rectangle(width, height)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xy_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      try {
        let mesh_id = backend.create_mesh_triangles_xy(vertices)
        if mesh_id <= 0 {
          @debug.debug(
            "[native_gpu] create_mesh_triangles failed: parsed_values=" +
            vertices.length().to_string(),
          )
        }
        return mesh_id
      } catch {
        err => debug_runtime_error("create_mesh_triangles", err)
      }
    }
  } else {
    @debug.debug(
      "[native_gpu] create_mesh_triangles parse failed: csv_len=" +
      vertices_xy_csv.length().to_string(),
    )
  }
  0
}

///|
pub fn create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xyuvrgba_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      try {
        let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
        if mesh_id <= 0 {
          @debug.debug(
            "[native_gpu] create_mesh_triangles_xyuvrgba failed: parsed_values=" +
            vertices.length().to_string(),
          )
        }
        return mesh_id
      } catch {
        err => debug_runtime_error("create_mesh_triangles_xyuvrgba", err)
      }
    }
  } else {
    @debug.debug(
      "[native_gpu] create_mesh_triangles_xyuvrgba parse failed: csv_len=" +
      vertices_xyuvrgba_csv.length().to_string(),
    )
  }
  0
}

///|
pub fn create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  if parse_f32_csv(vertices_xyzuvrgba_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      try {
        let mesh_id = backend.create_mesh3d_xyzuvrgba(
          vertices, primitive_topology,
        )
        if mesh_id <= 0 {
          @debug.debug(
            "[native_gpu] create_mesh3d failed: parsed_values=" +
            vertices.length().to_string() +
            ", topology=" +
            primitive_topology.to_string(),
          )
        }
        return mesh_id
      } catch {
        err => debug_runtime_error("create_mesh3d", err)
      }
    }
  } else {
    @debug.debug(
      "[native_gpu] create_mesh3d parse failed: csv_len=" +
      vertices_xyzuvrgba_csv.length().to_string() +
      ", topology=" +
      primitive_topology.to_string(),
    )
  }
  0
}

///|
pub fn debug_string(value~ : String) -> Unit {
  @debug.debug(value)
}
