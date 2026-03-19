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
pub type HostGpuDevice = Int

///|
pub type HostGpuQueue = Int

///|
pub type HostGpuSurface = Int

///|
pub type HostGpuFrame = Int

///|
pub type HostMaterial2dBindingValue = @renderer.HostMaterial2dBindingValue

///|
pub type HostMaterial2dBinding = @renderer.HostMaterial2dBinding

///|
pub type HostMaterial2dBindGroup = @renderer.HostMaterial2dBindGroup

///|
pub(all) enum HostGpuPresentMode {
  AutoVsync
  AutoNoVsync
  Fifo
  FifoRelaxed
  Immediate
  Mailbox
} derive(Eq, Show)

///|
pub fn HostGpuPresentMode::default() -> HostGpuPresentMode {
  AutoVsync
}

///|
pub(all) enum HostGpuCompositeAlphaMode {
  Auto
  Opaque
  PreMultiplied
  PostMultiplied
  Inherit
} derive(Eq, Show)

///|
pub fn HostGpuCompositeAlphaMode::default() -> HostGpuCompositeAlphaMode {
  Auto
}

///|
pub const HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY : Int = @renderer.SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY

///|
fn host_gpu_present_mode_kind(mode : HostGpuPresentMode) -> Int {
  match mode {
    AutoVsync => @renderer.SURFACE_PRESENT_MODE_AUTO_VSYNC
    AutoNoVsync => @renderer.SURFACE_PRESENT_MODE_AUTO_NO_VSYNC
    Fifo => @renderer.SURFACE_PRESENT_MODE_FIFO
    FifoRelaxed => @renderer.SURFACE_PRESENT_MODE_FIFO_RELAXED
    Immediate => @renderer.SURFACE_PRESENT_MODE_IMMEDIATE
    Mailbox => @renderer.SURFACE_PRESENT_MODE_MAILBOX
  }
}

///|
fn host_gpu_composite_alpha_mode_kind(mode : HostGpuCompositeAlphaMode) -> Int {
  match mode {
    Auto => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_AUTO
    Opaque => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE
    PreMultiplied => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED
    PostMultiplied => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED
    Inherit => @renderer.SURFACE_COMPOSITE_ALPHA_MODE_INHERIT
  }
}

///|
pub(all) struct HostColorGrading {
  balance_x_axis_x : Float
  balance_x_axis_y : Float
  balance_x_axis_z : Float
  balance_y_axis_x : Float
  balance_y_axis_y : Float
  balance_y_axis_z : Float
  balance_z_axis_x : Float
  balance_z_axis_y : Float
  balance_z_axis_z : Float
  saturation_shadows : Float
  saturation_midtones : Float
  saturation_highlights : Float
  contrast_shadows : Float
  contrast_midtones : Float
  contrast_highlights : Float
  gamma_shadows : Float
  gamma_midtones : Float
  gamma_highlights : Float
  gain_shadows : Float
  gain_midtones : Float
  gain_highlights : Float
  lift_shadows : Float
  lift_midtones : Float
  lift_highlights : Float
  midtones_start : Float
  midtones_end : Float
  exposure : Float
  hue : Float
  post_saturation : Float
}

///|
pub fn HostColorGrading::default() -> HostColorGrading {
  HostColorGrading::{
    balance_x_axis_x: 1.0F,
    balance_x_axis_y: 0.0F,
    balance_x_axis_z: 0.0F,
    balance_y_axis_x: 0.0F,
    balance_y_axis_y: 1.0F,
    balance_y_axis_z: 0.0F,
    balance_z_axis_x: 0.0F,
    balance_z_axis_y: 0.0F,
    balance_z_axis_z: 1.0F,
    saturation_shadows: 1.0F,
    saturation_midtones: 1.0F,
    saturation_highlights: 1.0F,
    contrast_shadows: 1.0F,
    contrast_midtones: 1.0F,
    contrast_highlights: 1.0F,
    gamma_shadows: 1.0F,
    gamma_midtones: 1.0F,
    gamma_highlights: 1.0F,
    gain_shadows: 1.0F,
    gain_midtones: 1.0F,
    gain_highlights: 1.0F,
    lift_shadows: 0.0F,
    lift_midtones: 0.0F,
    lift_highlights: 0.0F,
    midtones_start: 0.2F,
    midtones_end: 0.7F,
    exposure: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
  }
}

///|
const HOST_COLOR_GRADING_D65_X : Float = 0.31272F

///|
const HOST_COLOR_GRADING_D65_Y : Float = 0.32903F

///|
const HOST_COLOR_GRADING_D65_LMS_X : Float = 0.975538F

///|
const HOST_COLOR_GRADING_D65_LMS_Y : Float = 1.01648F

///|
const HOST_COLOR_GRADING_D65_LMS_Z : Float = 1.08475F

///|
fn host_color_grading_mat3_mul_vec3(
  x_axis : @math.Vec3,
  y_axis : @math.Vec3,
  z_axis : @math.Vec3,
  value : @math.Vec3,
) -> @math.Vec3 {
  x_axis
  .mul_scalar(value.x)
  .add(y_axis.mul_scalar(value.y))
  .add(z_axis.mul_scalar(value.z))
}

///|
pub fn host_color_grading_from_post_process(
  color_grading : @post_process.ColorGrading?,
) -> HostColorGrading {
  let grading = match color_grading {
    Some(value) => value
    None => @post_process.ColorGrading::default()
  }
  let white_point_x = HOST_COLOR_GRADING_D65_X - grading.global.temperature
  let white_point_y = HOST_COLOR_GRADING_D65_Y + grading.global.tint
  let white_point_lms = @math.Vec3::new(
    0.701634F + (-0.051461F + 0.452749F * white_point_x) / white_point_y,
    1.15856F + (0.045854F - 0.296122F * white_point_x) / white_point_y,
    -0.904175F + (0.953127F - 0.955206F * white_point_x) / white_point_y,
  )
  let white_point_adjustment = @math.Vec3::new(
    HOST_COLOR_GRADING_D65_LMS_X / white_point_lms.x,
    HOST_COLOR_GRADING_D65_LMS_Y / white_point_lms.y,
    HOST_COLOR_GRADING_D65_LMS_Z / white_point_lms.z,
  )
  let rgb_to_lms_x_axis = @math.Vec3::new(0.311692F, 0.0905138F, 0.00764433F)
  let rgb_to_lms_y_axis = @math.Vec3::new(0.652085F, 0.901341F, 0.0486554F)
  let rgb_to_lms_z_axis = @math.Vec3::new(0.0362225F, 0.00814478F, 0.943700F)
  let lms_to_rgb_x_axis = @math.Vec3::new(4.06305F, -0.40791F, -0.0118812F)
  let lms_to_rgb_y_axis = @math.Vec3::new(-2.93241F, 1.40437F, -0.0486532F)
  let lms_to_rgb_z_axis = @math.Vec3::new(-0.130646F, 0.00353630F, 1.0605344F)
  let scaled_rgb_to_lms_x_axis = @math.Vec3::new(
    rgb_to_lms_x_axis.x * white_point_adjustment.x,
    rgb_to_lms_x_axis.y * white_point_adjustment.y,
    rgb_to_lms_x_axis.z * white_point_adjustment.z,
  )
  let scaled_rgb_to_lms_y_axis = @math.Vec3::new(
    rgb_to_lms_y_axis.x * white_point_adjustment.x,
    rgb_to_lms_y_axis.y * white_point_adjustment.y,
    rgb_to_lms_y_axis.z * white_point_adjustment.z,
  )
  let scaled_rgb_to_lms_z_axis = @math.Vec3::new(
    rgb_to_lms_z_axis.x * white_point_adjustment.x,
    rgb_to_lms_z_axis.y * white_point_adjustment.y,
    rgb_to_lms_z_axis.z * white_point_adjustment.z,
  )
  let balance_x_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_x_axis,
  )
  let balance_y_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_y_axis,
  )
  let balance_z_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_z_axis,
  )
  let midtones_range = grading.global.midtones_range
  HostColorGrading::{
    balance_x_axis_x: balance_x_axis.x,
    balance_x_axis_y: balance_x_axis.y,
    balance_x_axis_z: balance_x_axis.z,
    balance_y_axis_x: balance_y_axis.x,
    balance_y_axis_y: balance_y_axis.y,
    balance_y_axis_z: balance_y_axis.z,
    balance_z_axis_x: balance_z_axis.x,
    balance_z_axis_y: balance_z_axis.y,
    balance_z_axis_z: balance_z_axis.z,
    saturation_shadows: grading.shadows.saturation,
    saturation_midtones: grading.midtones.saturation,
    saturation_highlights: grading.highlights.saturation,
    contrast_shadows: grading.shadows.contrast,
    contrast_midtones: grading.midtones.contrast,
    contrast_highlights: grading.highlights.contrast,
    gamma_shadows: grading.shadows.gamma,
    gamma_midtones: grading.midtones.gamma,
    gamma_highlights: grading.highlights.gamma,
    gain_shadows: grading.shadows.gain,
    gain_midtones: grading.midtones.gain,
    gain_highlights: grading.highlights.gain,
    lift_shadows: grading.shadows.lift,
    lift_midtones: grading.midtones.lift,
    lift_highlights: grading.highlights.lift,
    midtones_start: midtones_range.start,
    midtones_end: midtones_range.end_,
    exposure: grading.global.exposure,
    hue: grading.global.hue,
    post_saturation: grading.global.post_saturation,
  }
}

///|
pub(all) struct HostMesh3dPreprocessShaderWorkItem {
  input_index : Int
  output_or_indirect_parameters_index : Int
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
pub fn host_gpu_request_device() -> HostGpuDevice {
  @renderer.request_device()
}

///|
pub fn host_gpu_get_queue(device : HostGpuDevice) -> HostGpuQueue {
  @renderer.get_queue(device)
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  @renderer.register_wgsl_source(rel_path, source)
}

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  @renderer.clear_registered_wgsl_source_registry()
}

///|
pub fn host_gpu_create_surface(window : Int) -> HostGpuSurface {
  @renderer.create_surface(window)
}

///|
pub fn host_gpu_surface_target_id(surface : HostGpuSurface) -> Int {
  @renderer.surface_target_id(surface)
}

///|
pub fn host_gpu_surface_target_id_for_window(window : Int) -> Int {
  @renderer.surface_target_id_for_window(window)
}

///|
pub fn host_gpu_configure_surface(
  device~ : HostGpuDevice,
  surface~ : HostGpuSurface,
  width~ : Int,
  height~ : Int,
  present_mode? : HostGpuPresentMode = HostGpuPresentMode::default(),
  composite_alpha_mode? : HostGpuCompositeAlphaMode = HostGpuCompositeAlphaMode::default(),
  desired_maximum_frame_latency? : Int = HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  @renderer.configure_surface(
    device~,
    surface~,
    width~,
    height~,
    present_mode_kind=host_gpu_present_mode_kind(present_mode),
    composite_alpha_mode_kind=host_gpu_composite_alpha_mode_kind(
      composite_alpha_mode,
    ),
    desired_maximum_frame_latency~,
  )
}

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame {
  @renderer.begin_frame(surface)
}

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit {
  @renderer.end_frame(frame)
}

///|
pub fn host_gpu_set_active_surface_target(target_id : Int) -> Unit {
  @renderer.set_active_surface_target(target_id)
}

///|
pub fn host_gpu_set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  @renderer.set_mesh3d_gpu_instance_builder_enabled(enabled)
}

///|
fn host_mesh3d_preprocess_shader_work_item_to_renderer(
  item : HostMesh3dPreprocessShaderWorkItem,
) -> @renderer.HostMesh3dPreprocessShaderWorkItem {
  @renderer.HostMesh3dPreprocessShaderWorkItem::{
    input_index: item.input_index,
    output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
  }
}

///|
fn host_mesh3d_preprocess_cpu_metadata_to_renderer(
  metadata : HostMesh3dPreprocessIndirectParametersCpuMetadata,
) -> @renderer.HostMesh3dPreprocessIndirectParametersCpuMetadata {
  @renderer.HostMesh3dPreprocessIndirectParametersCpuMetadata::{
    base_output_index: metadata.base_output_index,
    batch_set_index: metadata.batch_set_index,
  }
}

///|
fn host_mesh3d_preprocess_gpu_metadata_to_renderer(
  metadata : HostMesh3dPreprocessIndirectParametersGpuMetadata,
) -> @renderer.HostMesh3dPreprocessIndirectParametersGpuMetadata {
  @renderer.HostMesh3dPreprocessIndirectParametersGpuMetadata::{
    mesh_index: metadata.mesh_index,
    early_instance_count: metadata.early_instance_count,
    late_instance_count: metadata.late_instance_count,
  }
}

///|
fn host_mesh3d_preprocess_batch_set_to_renderer(
  batch_set : HostMesh3dPreprocessIndirectBatchSet,
) -> @renderer.HostMesh3dPreprocessIndirectBatchSet {
  @renderer.HostMesh3dPreprocessIndirectBatchSet::{
    indirect_parameters_count: batch_set.indirect_parameters_count,
    indirect_parameters_base: batch_set.indirect_parameters_base,
  }
}

///|
pub fn host_gpu_upload_mesh3d_preprocess_camera_payload(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  payload~ : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  let direct_work_items : Array[@renderer.HostMesh3dPreprocessShaderWorkItem] = []
  for item in payload.direct_work_items {
    direct_work_items.push(
      host_mesh3d_preprocess_shader_work_item_to_renderer(item),
    )
  }
  let indexed_work_items : Array[@renderer.HostMesh3dPreprocessShaderWorkItem] = []
  for item in payload.indexed_work_items {
    indexed_work_items.push(
      host_mesh3d_preprocess_shader_work_item_to_renderer(item),
    )
  }
  let non_indexed_work_items : Array[
    @renderer.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  for item in payload.non_indexed_work_items {
    non_indexed_work_items.push(
      host_mesh3d_preprocess_shader_work_item_to_renderer(item),
    )
  }
  let late_indexed_work_items : Array[
    @renderer.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  for item in payload.late_indexed_work_items {
    late_indexed_work_items.push(
      host_mesh3d_preprocess_shader_work_item_to_renderer(item),
    )
  }
  let late_non_indexed_work_items : Array[
    @renderer.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  for item in payload.late_non_indexed_work_items {
    late_non_indexed_work_items.push(
      host_mesh3d_preprocess_shader_work_item_to_renderer(item),
    )
  }
  let indexed_cpu_metadata : Array[
    @renderer.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for metadata in payload.indexed_cpu_metadata {
    indexed_cpu_metadata.push(
      host_mesh3d_preprocess_cpu_metadata_to_renderer(metadata),
    )
  }
  let indexed_gpu_metadata : Array[
    @renderer.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for metadata in payload.indexed_gpu_metadata {
    indexed_gpu_metadata.push(
      host_mesh3d_preprocess_gpu_metadata_to_renderer(metadata),
    )
  }
  let indexed_batch_sets : Array[@renderer.HostMesh3dPreprocessIndirectBatchSet] = []
  for batch_set in payload.indexed_batch_sets {
    indexed_batch_sets.push(
      host_mesh3d_preprocess_batch_set_to_renderer(batch_set),
    )
  }
  let non_indexed_cpu_metadata : Array[
    @renderer.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for metadata in payload.non_indexed_cpu_metadata {
    non_indexed_cpu_metadata.push(
      host_mesh3d_preprocess_cpu_metadata_to_renderer(metadata),
    )
  }
  let non_indexed_gpu_metadata : Array[
    @renderer.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for metadata in payload.non_indexed_gpu_metadata {
    non_indexed_gpu_metadata.push(
      host_mesh3d_preprocess_gpu_metadata_to_renderer(metadata),
    )
  }
  let non_indexed_batch_sets : Array[
    @renderer.HostMesh3dPreprocessIndirectBatchSet,
  ] = []
  for batch_set in payload.non_indexed_batch_sets {
    non_indexed_batch_sets.push(
      host_mesh3d_preprocess_batch_set_to_renderer(batch_set),
    )
  }
  let dispatch_metadata = @renderer.HostMesh3dPreprocessDispatchMetadata::{
    direct_workgroup_count: payload.dispatch_metadata.direct_workgroup_count,
    indexed_workgroup_count: payload.dispatch_metadata.indexed_workgroup_count,
    non_indexed_workgroup_count: payload.dispatch_metadata.non_indexed_workgroup_count,
    late_indexed_workgroup_count: payload.dispatch_metadata.late_indexed_workgroup_count,
    late_non_indexed_workgroup_count: payload.dispatch_metadata.late_non_indexed_workgroup_count,
  }
  @renderer.upload_mesh3d_preprocess_camera_payload(
    camera_key_hi~,
    camera_key_lo~,
    payload=@renderer.HostMesh3dPreprocessCameraPayload::{
      direct_work_items,
      indexed_work_items,
      non_indexed_work_items,
      late_indexed_work_items,
      late_non_indexed_work_items,
      indexed_cpu_metadata,
      indexed_gpu_metadata,
      indexed_batch_sets,
      non_indexed_cpu_metadata,
      non_indexed_gpu_metadata,
      non_indexed_batch_sets,
      dispatch_metadata,
    },
  )
}

///|
pub fn host_gpu_begin_pass(
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
  @renderer.begin_pass(
    target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_rotation~,
    camera_scale~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_begin_pass_with_depth(
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
  @renderer.begin_pass_with_depth(
    target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_rotation~,
    camera_scale~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  secondary_target_id? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_z~ : Float,
  camera_exposure~ : Float,
  camera_rot_x~ : Float,
  camera_rot_y~ : Float,
  camera_rot_z~ : Float,
  camera_rot_w~ : Float,
  clip_from_world_x_axis_x~ : Float,
  clip_from_world_x_axis_y~ : Float,
  clip_from_world_x_axis_z~ : Float,
  clip_from_world_x_axis_w~ : Float,
  clip_from_world_y_axis_x~ : Float,
  clip_from_world_y_axis_y~ : Float,
  clip_from_world_y_axis_z~ : Float,
  clip_from_world_y_axis_w~ : Float,
  clip_from_world_z_axis_x~ : Float,
  clip_from_world_z_axis_y~ : Float,
  clip_from_world_z_axis_z~ : Float,
  clip_from_world_z_axis_w~ : Float,
  clip_from_world_w_axis_x~ : Float,
  clip_from_world_w_axis_y~ : Float,
  clip_from_world_w_axis_z~ : Float,
  clip_from_world_w_axis_w~ : Float,
  unjittered_clip_from_world_x_axis_x~ : Float,
  unjittered_clip_from_world_x_axis_y~ : Float,
  unjittered_clip_from_world_x_axis_z~ : Float,
  unjittered_clip_from_world_x_axis_w~ : Float,
  unjittered_clip_from_world_y_axis_x~ : Float,
  unjittered_clip_from_world_y_axis_y~ : Float,
  unjittered_clip_from_world_y_axis_z~ : Float,
  unjittered_clip_from_world_y_axis_w~ : Float,
  unjittered_clip_from_world_z_axis_x~ : Float,
  unjittered_clip_from_world_z_axis_y~ : Float,
  unjittered_clip_from_world_z_axis_z~ : Float,
  unjittered_clip_from_world_z_axis_w~ : Float,
  unjittered_clip_from_world_w_axis_x~ : Float,
  unjittered_clip_from_world_w_axis_y~ : Float,
  unjittered_clip_from_world_w_axis_z~ : Float,
  unjittered_clip_from_world_w_axis_w~ : Float,
  previous_clip_from_world_x_axis_x~ : Float,
  previous_clip_from_world_x_axis_y~ : Float,
  previous_clip_from_world_x_axis_z~ : Float,
  previous_clip_from_world_x_axis_w~ : Float,
  previous_clip_from_world_y_axis_x~ : Float,
  previous_clip_from_world_y_axis_y~ : Float,
  previous_clip_from_world_y_axis_z~ : Float,
  previous_clip_from_world_y_axis_w~ : Float,
  previous_clip_from_world_z_axis_x~ : Float,
  previous_clip_from_world_z_axis_y~ : Float,
  previous_clip_from_world_z_axis_z~ : Float,
  previous_clip_from_world_z_axis_w~ : Float,
  previous_clip_from_world_w_axis_x~ : Float,
  previous_clip_from_world_w_axis_y~ : Float,
  previous_clip_from_world_w_axis_z~ : Float,
  previous_clip_from_world_w_axis_w~ : Float,
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
  point_shadow_near~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  @renderer.begin_pass_3d(
    target_id~,
    target_layer~,
    secondary_target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_z~,
    camera_exposure~,
    camera_rot_x~,
    camera_rot_y~,
    camera_rot_z~,
    camera_rot_w~,
    clip_from_world_x_axis_x~,
    clip_from_world_x_axis_y~,
    clip_from_world_x_axis_z~,
    clip_from_world_x_axis_w~,
    clip_from_world_y_axis_x~,
    clip_from_world_y_axis_y~,
    clip_from_world_y_axis_z~,
    clip_from_world_y_axis_w~,
    clip_from_world_z_axis_x~,
    clip_from_world_z_axis_y~,
    clip_from_world_z_axis_z~,
    clip_from_world_z_axis_w~,
    clip_from_world_w_axis_x~,
    clip_from_world_w_axis_y~,
    clip_from_world_w_axis_z~,
    clip_from_world_w_axis_w~,
    unjittered_clip_from_world_x_axis_x~,
    unjittered_clip_from_world_x_axis_y~,
    unjittered_clip_from_world_x_axis_z~,
    unjittered_clip_from_world_x_axis_w~,
    unjittered_clip_from_world_y_axis_x~,
    unjittered_clip_from_world_y_axis_y~,
    unjittered_clip_from_world_y_axis_z~,
    unjittered_clip_from_world_y_axis_w~,
    unjittered_clip_from_world_z_axis_x~,
    unjittered_clip_from_world_z_axis_y~,
    unjittered_clip_from_world_z_axis_z~,
    unjittered_clip_from_world_z_axis_w~,
    unjittered_clip_from_world_w_axis_x~,
    unjittered_clip_from_world_w_axis_y~,
    unjittered_clip_from_world_w_axis_z~,
    unjittered_clip_from_world_w_axis_w~,
    previous_clip_from_world_x_axis_x~,
    previous_clip_from_world_x_axis_y~,
    previous_clip_from_world_x_axis_z~,
    previous_clip_from_world_x_axis_w~,
    previous_clip_from_world_y_axis_x~,
    previous_clip_from_world_y_axis_y~,
    previous_clip_from_world_y_axis_z~,
    previous_clip_from_world_y_axis_w~,
    previous_clip_from_world_z_axis_x~,
    previous_clip_from_world_z_axis_y~,
    previous_clip_from_world_z_axis_z~,
    previous_clip_from_world_z_axis_w~,
    previous_clip_from_world_w_axis_x~,
    previous_clip_from_world_w_axis_y~,
    previous_clip_from_world_w_axis_z~,
    previous_clip_from_world_w_axis_w~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    ambient_r~,
    ambient_g~,
    ambient_b~,
    ambient_brightness~,
    directional_dir_x~,
    directional_dir_y~,
    directional_dir_z~,
    directional_color_r~,
    directional_color_g~,
    directional_color_b~,
    directional_illuminance~,
    point_pos_x~,
    point_pos_y~,
    point_pos_z~,
    point_color_r~,
    point_color_g~,
    point_color_b~,
    point_intensity~,
    point_range~,
    spot_pos_x~,
    spot_pos_y~,
    spot_pos_z~,
    spot_dir_x~,
    spot_dir_y~,
    spot_dir_z~,
    spot_color_r~,
    spot_color_g~,
    spot_color_b~,
    spot_intensity~,
    spot_range~,
    spot_inner_angle~,
    spot_outer_angle~,
    point_shadow_near~,
    pass_kind~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_set_scissor(
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @renderer.set_scissor(x~, y~, width~, height~)
}

///|
pub fn host_gpu_clear_scissor() -> Unit {
  @renderer.clear_scissor()
}

///|
pub fn host_gpu_draw_sprite(
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
  @renderer.draw_sprite(
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
  )
}

///|
pub fn host_gpu_draw_sprite_uv(
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
  @renderer.draw_sprite_uv(
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
    uv_min_x~,
    uv_min_y~,
    uv_max_x~,
    uv_max_y~,
  )
}

///|
/// Draw a UI rectangle (background or border) using the dedicated UI pipeline.
///
/// Parameters intentionally mirror `gpu_draw_sprite_uv` plus UI-specific fields:
/// - `flags`: bitset defined by the engine-side UI extraction. This follows the
///   Bevy UI shader contract for `TEXTURED` and per-edge `BORDER_*` bits, plus
///   a local transport bit for `ANTI_ALIAS` pipeline selection.
/// - `radius_*`: corner radii in logical pixels (top-left, top-right, bottom-right, bottom-left).
/// - `border_*`: border thickness in logical pixels (left, top, right, bottom).
pub fn host_gpu_draw_ui_rect(
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
  @renderer.draw_ui_rect(
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
    uv_min_x~,
    uv_min_y~,
    uv_max_x~,
    uv_max_y~,
    flags~,
    radius_tl~,
    radius_tr~,
    radius_br~,
    radius_bl~,
    border_left~,
    border_top~,
    border_right~,
    border_bottom~,
  )
}

///|
/// Draw a UI box shadow using the dedicated box-shadow pipeline.
///
/// Parameters:
/// - `x/y/rotation`: world-space transform for the shadow quad (centered).
/// - `scale_x/scale_y`: quad bounds (shadow size + 6*blur) in world units.
/// - `size_x/size_y`: inner shadow size (node size + spread) in world units.
/// - `radius_*`: corner radii (top-left, top-right, bottom-right, bottom-left) in world units.
/// - `blur`: blur radius in world units.
/// - `samples`: integration steps for the gaussian approximation (>= 1 recommended).
pub fn host_gpu_draw_ui_box_shadow(
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
  @renderer.draw_ui_box_shadow(
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
    size_x~,
    size_y~,
    radius_tl~,
    radius_tr~,
    radius_br~,
    radius_bl~,
    blur~,
    samples~,
  )
}

///|
/// Draw a UI texture slice (9-slice / tiled) using the Bevy-aligned texture
/// slicing shader.
///
/// Parameters:
/// - `scale_x/scale_y`: quad bounds in world units.
/// - `texture_slices`: normalized texture slice dividing lines (left, top, right, bottom).
/// - `target_slices`: normalized target slice dividing lines (left, top, right, bottom).
/// - `repeat`: repeat factors (side_x, side_y, center_x, center_y).
/// - `atlas_rect`: normalized atlas rect (left, top, right, bottom).
pub fn host_gpu_draw_ui_texture_slice(
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
  @renderer.draw_ui_texture_slice(
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
    texture_slice_l~,
    texture_slice_t~,
    texture_slice_r~,
    texture_slice_b~,
    target_slice_l~,
    target_slice_t~,
    target_slice_r~,
    target_slice_b~,
    repeat_side_x~,
    repeat_side_y~,
    repeat_center_x~,
    repeat_center_y~,
    atlas_l~,
    atlas_t~,
    atlas_r~,
    atlas_b~,
  )
}

///|
pub fn host_gpu_draw_mesh(
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
  alpha_mode_kind~ : Int,
  alpha_cutoff~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit {
  @renderer.draw_mesh(
    mesh_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    alpha_mode_kind~,
    alpha_cutoff~,
    texture_id~,
    uv_offset_x~,
    uv_offset_y~,
    uv_scale_x~,
    uv_scale_y~,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
pub fn host_gpu_draw_mesh_material(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  alpha_mode_kind~ : Int,
  material_bind_group~ : @renderer.HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit {
  @renderer.draw_mesh_material(
    mesh_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    alpha_mode_kind~,
    material_bind_group~,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
pub fn host_gpu_draw_mesh3d(
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
  alpha_cutoff~ : Float,
  material_flags~ : UInt,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  cull_mode~ : Int,
) -> Unit {
  @renderer.draw_mesh3d(
    mesh_id~,
    x~,
    y~,
    z~,
    rotation_x~,
    rotation_y~,
    rotation_z~,
    rotation_w~,
    scale_x~,
    scale_y~,
    scale_z~,
    previous_x~,
    previous_y~,
    previous_z~,
    previous_rotation_x~,
    previous_rotation_y~,
    previous_rotation_z~,
    previous_rotation_w~,
    previous_scale_x~,
    previous_scale_y~,
    previous_scale_z~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    texture_id~,
    uv_transform_a~,
    uv_transform_b~,
    uv_transform_c~,
    uv_transform_d~,
    uv_transform_tx~,
    uv_transform_ty~,
    uv_transform_mode~,
    normal_texture_id~,
    emissive_texture_id~,
    metallic_roughness_texture_id~,
    occlusion_texture_id~,
    depth_texture_id~,
    emissive_r~,
    emissive_g~,
    emissive_b~,
    metallic~,
    roughness~,
    reflectance~,
    parallax_depth_scale~,
    max_parallax_layer_count~,
    max_relief_mapping_search_steps~,
    anisotropy_texture_id~,
    anisotropy_strength~,
    anisotropy_rotation~,
    specular_tint_texture_id~,
    specular_tint_r~,
    specular_tint_g~,
    specular_tint_b~,
    diffuse_transmission~,
    specular_transmission~,
    thickness~,
    ior~,
    alpha_cutoff~,
    material_flags~,
    transmission_source_texture_id~,
    transmission_blur_taps~,
    transmission_steps~,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    cull_mode~,
  )
}

///|
pub fn host_gpu_draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  shutter_angle~ : Float,
  samples~ : Int,
) -> Unit {
  @renderer.draw_motion_blur(
    scene_texture_id~,
    velocity_texture_id~,
    shutter_angle~,
    samples~,
  )
}

///|
pub fn host_gpu_apply_auto_exposure(
  view_key_hi~ : Int,
  view_key_lo~ : Int,
  scene_texture_id~ : Int,
  min_ev100~ : Float,
  max_ev100~ : Float,
  low_percent~ : Float,
  high_percent~ : Float,
  speed_brighten~ : Float,
  speed_darken~ : Float,
  exponential_transition_distance~ : Float,
  delta_time~ : Float,
  color_grading~ : HostColorGrading,
  metering_mask_texture_id~ : Int,
  compensation_curve_lut~ : Bytes,
  compensation_curve_min_log_lum~ : Float,
  compensation_curve_max_log_lum~ : Float,
  compensation_curve_min_compensation~ : Float,
  compensation_curve_max_compensation~ : Float,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  @renderer.apply_auto_exposure(
    view_key_hi~,
    view_key_lo~,
    scene_texture_id~,
    min_ev100~,
    max_ev100~,
    low_percent~,
    high_percent~,
    speed_brighten~,
    speed_darken~,
    exponential_transition_distance~,
    delta_time~,
    color_grading_balance_x_axis_x=color_grading.balance_x_axis_x,
    color_grading_balance_x_axis_y=color_grading.balance_x_axis_y,
    color_grading_balance_x_axis_z=color_grading.balance_x_axis_z,
    color_grading_balance_y_axis_x=color_grading.balance_y_axis_x,
    color_grading_balance_y_axis_y=color_grading.balance_y_axis_y,
    color_grading_balance_y_axis_z=color_grading.balance_y_axis_z,
    color_grading_balance_z_axis_x=color_grading.balance_z_axis_x,
    color_grading_balance_z_axis_y=color_grading.balance_z_axis_y,
    color_grading_balance_z_axis_z=color_grading.balance_z_axis_z,
    color_grading_saturation_shadows=color_grading.saturation_shadows,
    color_grading_saturation_midtones=color_grading.saturation_midtones,
    color_grading_saturation_highlights=color_grading.saturation_highlights,
    color_grading_contrast_shadows=color_grading.contrast_shadows,
    color_grading_contrast_midtones=color_grading.contrast_midtones,
    color_grading_contrast_highlights=color_grading.contrast_highlights,
    color_grading_gamma_shadows=color_grading.gamma_shadows,
    color_grading_gamma_midtones=color_grading.gamma_midtones,
    color_grading_gamma_highlights=color_grading.gamma_highlights,
    color_grading_gain_shadows=color_grading.gain_shadows,
    color_grading_gain_midtones=color_grading.gain_midtones,
    color_grading_gain_highlights=color_grading.gain_highlights,
    color_grading_lift_shadows=color_grading.lift_shadows,
    color_grading_lift_midtones=color_grading.lift_midtones,
    color_grading_lift_highlights=color_grading.lift_highlights,
    color_grading_midtones_start=color_grading.midtones_start,
    color_grading_midtones_end=color_grading.midtones_end,
    color_grading_exposure=color_grading.exposure,
    color_grading_hue=color_grading.hue,
    color_grading_post_saturation=color_grading.post_saturation,
    metering_mask_texture_id~,
    compensation_curve_lut~,
    compensation_curve_min_log_lum~,
    compensation_curve_max_log_lum~,
    compensation_curve_min_compensation~,
    compensation_curve_max_compensation~,
    view_width~,
    view_height~,
  )
}

///|
pub fn host_gpu_apply_bloom(
  scene_texture_id~ : Int,
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
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  @renderer.apply_bloom(
    scene_texture_id~,
    intensity~,
    low_frequency_boost~,
    low_frequency_boost_curvature~,
    high_pass_frequency~,
    threshold~,
    threshold_softness~,
    composite_mode~,
    max_mip_dimension~,
    scale_x~,
    scale_y~,
    view_width~,
    view_height~,
  )
}

///|
pub fn host_gpu_draw_tonemapping2d(
  scene_texture_id~ : Int,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
  color_grading~ : HostColorGrading,
) -> Unit {
  @renderer.draw_tonemapping2d(
    scene_texture_id~,
    exposure~,
    tonemapping_mode~,
    deband_dither_enabled~,
    view_width~,
    view_height~,
    agx_lut_texture_id~,
    tony_lut_texture_id~,
    blender_lut_texture_id~,
    color_grading_balance_x_axis_x=color_grading.balance_x_axis_x,
    color_grading_balance_x_axis_y=color_grading.balance_x_axis_y,
    color_grading_balance_x_axis_z=color_grading.balance_x_axis_z,
    color_grading_balance_y_axis_x=color_grading.balance_y_axis_x,
    color_grading_balance_y_axis_y=color_grading.balance_y_axis_y,
    color_grading_balance_y_axis_z=color_grading.balance_y_axis_z,
    color_grading_balance_z_axis_x=color_grading.balance_z_axis_x,
    color_grading_balance_z_axis_y=color_grading.balance_z_axis_y,
    color_grading_balance_z_axis_z=color_grading.balance_z_axis_z,
    color_grading_saturation_shadows=color_grading.saturation_shadows,
    color_grading_saturation_midtones=color_grading.saturation_midtones,
    color_grading_saturation_highlights=color_grading.saturation_highlights,
    color_grading_contrast_shadows=color_grading.contrast_shadows,
    color_grading_contrast_midtones=color_grading.contrast_midtones,
    color_grading_contrast_highlights=color_grading.contrast_highlights,
    color_grading_gamma_shadows=color_grading.gamma_shadows,
    color_grading_gamma_midtones=color_grading.gamma_midtones,
    color_grading_gamma_highlights=color_grading.gamma_highlights,
    color_grading_gain_shadows=color_grading.gain_shadows,
    color_grading_gain_midtones=color_grading.gain_midtones,
    color_grading_gain_highlights=color_grading.gain_highlights,
    color_grading_lift_shadows=color_grading.lift_shadows,
    color_grading_lift_midtones=color_grading.lift_midtones,
    color_grading_lift_highlights=color_grading.lift_highlights,
    color_grading_midtones_start=color_grading.midtones_start,
    color_grading_midtones_end=color_grading.midtones_end,
    color_grading_exposure=color_grading.exposure,
    color_grading_hue=color_grading.hue,
    color_grading_post_saturation=color_grading.post_saturation,
  )
}

///|
pub fn host_gpu_draw_tonemapping3d(
  scene_texture_id~ : Int,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
  color_grading~ : HostColorGrading,
) -> Unit {
  @renderer.draw_tonemapping3d(
    scene_texture_id~,
    exposure~,
    tonemapping_mode~,
    deband_dither_enabled~,
    view_width~,
    view_height~,
    agx_lut_texture_id~,
    tony_lut_texture_id~,
    blender_lut_texture_id~,
    color_grading_balance_x_axis_x=color_grading.balance_x_axis_x,
    color_grading_balance_x_axis_y=color_grading.balance_x_axis_y,
    color_grading_balance_x_axis_z=color_grading.balance_x_axis_z,
    color_grading_balance_y_axis_x=color_grading.balance_y_axis_x,
    color_grading_balance_y_axis_y=color_grading.balance_y_axis_y,
    color_grading_balance_y_axis_z=color_grading.balance_y_axis_z,
    color_grading_balance_z_axis_x=color_grading.balance_z_axis_x,
    color_grading_balance_z_axis_y=color_grading.balance_z_axis_y,
    color_grading_balance_z_axis_z=color_grading.balance_z_axis_z,
    color_grading_saturation_shadows=color_grading.saturation_shadows,
    color_grading_saturation_midtones=color_grading.saturation_midtones,
    color_grading_saturation_highlights=color_grading.saturation_highlights,
    color_grading_contrast_shadows=color_grading.contrast_shadows,
    color_grading_contrast_midtones=color_grading.contrast_midtones,
    color_grading_contrast_highlights=color_grading.contrast_highlights,
    color_grading_gamma_shadows=color_grading.gamma_shadows,
    color_grading_gamma_midtones=color_grading.gamma_midtones,
    color_grading_gamma_highlights=color_grading.gamma_highlights,
    color_grading_gain_shadows=color_grading.gain_shadows,
    color_grading_gain_midtones=color_grading.gain_midtones,
    color_grading_gain_highlights=color_grading.gain_highlights,
    color_grading_lift_shadows=color_grading.lift_shadows,
    color_grading_lift_midtones=color_grading.lift_midtones,
    color_grading_lift_highlights=color_grading.lift_highlights,
    color_grading_midtones_start=color_grading.midtones_start,
    color_grading_midtones_end=color_grading.midtones_end,
    color_grading_exposure=color_grading.exposure,
    color_grading_hue=color_grading.hue,
    color_grading_post_saturation=color_grading.post_saturation,
  )
}

///|
pub fn host_gpu_draw_effect_stack(
  scene_texture_id~ : Int,
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
) -> Unit {
  @renderer.draw_effect_stack(
    scene_texture_id~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width~,
    view_height~,
  )
}

///|
pub fn host_gpu_draw_fxaa(
  scene_texture_id~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold_mode~ : Int,
  fxaa_edge_threshold_min_mode~ : Int,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  @renderer.draw_fxaa(
    scene_texture_id~,
    fxaa_enabled~,
    fxaa_edge_threshold_mode~,
    fxaa_edge_threshold_min_mode~,
    view_width~,
    view_height~,
  )
}

///|
pub fn host_gpu_draw_gizmo_line(
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
  @renderer.draw_gizmo_line(
    start_x~,
    start_y~,
    start_r~,
    start_g~,
    start_b~,
    start_a~,
    end_x~,
    end_y~,
    end_r~,
    end_g~,
    end_b~,
    end_a~,
    line_width~,
    style_kind~,
    gap_scale~,
    line_scale~,
  )
}

///|
pub fn host_gpu_end_pass() -> Unit {
  @renderer.end_pass()
}

///|
pub fn host_gpu_create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.create_render_target(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.create_render_target_rgba16f(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_render_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.create_render_target_rg16f(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_point_light_shadow_target(size~ : Int) -> Int {
  @renderer.create_point_light_shadow_target(size~)
}

///|
pub fn host_gpu_create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  @renderer.create_mesh_capsule(radius~, half_length~, segments~)
}

///|
pub fn host_gpu_create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  @renderer.create_mesh_rectangle(width~, height~)
}

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  @renderer.create_mesh_triangles(vertices_xy_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles_xyuvrgba(
  vertices_xyuvrgba_csv~ : String,
) -> Int {
  @renderer.create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles3d(
  vertices_xyzuvrgba_csv~ : String,
) -> Int {
  host_gpu_create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology=0)
}

///|
pub fn host_gpu_create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  @renderer.create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology~)
}

///|
pub fn host_debug_string(value~ : String) -> Unit {
  @renderer.debug_string(value~)
}

///|
pub fn render_diagnostics_snapshot() -> @renderer.RenderDiagnosticsSnapshot {
  @renderer.render_diagnostics_snapshot()
}

///|
pub fn render_diagnostics_commit_current_frame_snapshot() -> Unit {
  @renderer.render_diagnostics_commit_current_frame_snapshot()
}

///|
pub fn render_diagnostics_reset_current_frame_counters() -> Unit {
  @renderer.render_diagnostics_reset_current_frame_counters()
}

///|
pub fn screenshot_capture_surface_request() -> Int {
  @renderer.screenshot_capture_surface_request()
}

///|
pub fn screenshot_capture_surface_target_request(target_id~ : Int) -> Int {
  @renderer.screenshot_capture_surface_target_request(target_id~)
}

///|
pub fn screenshot_capture_texture_request(texture_id~ : Int) -> Int {
  @renderer.screenshot_capture_texture_request(texture_id~)
}

///|
pub fn screenshot_take_capture_result(
  capture_id : Int,
) -> @renderer.ScreenshotCaptureResult? {
  @renderer.screenshot_take_capture_result(capture_id)
}

///|
pub fn screenshot_capture_texture_sync(
  texture_id~ : Int,
) -> @renderer.ScreenshotCaptureResult? {
  @renderer.screenshot_capture_texture_sync(texture_id~)
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  @renderer.asset_create_texture_empty(
    width~,
    height~,
    mip_level_count~,
    nearest~,
  )
}

///|
pub fn asset_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format_raw~ : Int,
  pixels~ : Bytes,
) -> Int {
  @renderer.asset_create_texture_3d_with_format(
    width~,
    height~,
    depth~,
    format_raw~,
    pixels~,
  )
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
  @renderer.asset_write_texture_region_rgba8(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    pixels_rgba8~,
  )
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
  @renderer.asset_write_texture_region_rgba8_mip(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    mip_level~,
    pixels_rgba8~,
  )
}

///|
pub fn asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  @renderer.asset_create_texture_mip_view(texture_id~, mip_level~)
}

///|
pub fn asset_texture_width(texture_id~ : Int) -> Int {
  @renderer.asset_texture_width(texture_id~)
}

///|
pub fn asset_texture_height(texture_id~ : Int) -> Int {
  @renderer.asset_texture_height(texture_id~)
}

///|
pub fn asset_is_texture_loaded(texture_id~ : Int) -> Bool {
  @renderer.asset_is_texture_loaded(texture_id~)
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  @renderer.asset_supported_compressed_image_formats()
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  @renderer.asset_copy_texture_to_texture(
    dst_texture_id~,
    dst_x~,
    dst_y~,
    src_texture_id~,
  )
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
  @renderer.asset_set_texture_sampler(
    texture_id~,
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
}
