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
pub type HostMaterial2dBindingValue = @renderer.HostMaterial2dBindingValue

///|
pub type HostMaterial2dBinding = @renderer.HostMaterial2dBinding

///|
pub type HostMaterial2dBindGroup = @renderer.HostMaterial2dBindGroup

///|
pub type HostMesh3dPreprocessShaderWorkItem = @renderer.HostMesh3dPreprocessShaderWorkItem

///|
pub type HostMesh3dPreprocessMeshInput = @renderer.HostMesh3dPreprocessMeshInput

///|
pub fn host_gpu_prepare_mesh3d_skin_binding(
  key_hi~ : Int,
  key_lo~ : Int,
  skinning_matrices~ : Array[Float],
) -> Unit {
  @render_mesh.host_gpu_prepare_mesh3d_skin_binding(
    key_hi~,
    key_lo~,
    skinning_matrices~,
  )
}

///|
pub type HostGpuClipMatrix = @renderer.GpuClipMatrix

///|
pub type HostMesh3dPreprocessFrustumPlane = @renderer.HostMesh3dPreprocessFrustumPlane

///|
pub type HostMesh3dPreprocessView = @renderer.HostMesh3dPreprocessView

///|
pub type HostMesh3dPreprocessPreviousView = @renderer.HostMesh3dPreprocessPreviousView

///|
pub type HostMesh3dPreprocessMeshCullingData = @renderer.HostMesh3dPreprocessMeshCullingData

///|
pub type HostMesh3dPreprocessIndirectParametersCpuMetadata = @renderer.HostMesh3dPreprocessIndirectParametersCpuMetadata

///|
pub type HostMesh3dPreprocessIndirectParametersGpuMetadata = @renderer.HostMesh3dPreprocessIndirectParametersGpuMetadata

///|
pub type HostMesh3dPreprocessIndirectBatchSet = @renderer.HostMesh3dPreprocessIndirectBatchSet

///|
pub type HostMesh3dPreprocessDispatchMetadata = @renderer.HostMesh3dPreprocessDispatchMetadata

///|
pub type HostMesh3dPreprocessCameraPayload = @renderer.HostMesh3dPreprocessCameraPayload

///|
pub const MESH3D_PREPROCESS_PHASE_MAIN : Int = @renderer.MESH3D_PREPROCESS_PHASE_MAIN

///|
pub const MESH3D_PREPROCESS_INPUT_FLAG_NO_FRUSTUM_CULLING : UInt = 1U << 28

///|
pub const MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION : Int = @renderer.MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION

///|
pub const MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION : Int = @renderer.MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_MAIN : Int = @renderer.MESH3D_BUILD_INDIRECT_PHASE_MAIN

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_EARLY : Int = @renderer.MESH3D_BUILD_INDIRECT_PHASE_EARLY

///|
pub fn host_gpu_request_device() -> HostGpuDevice {
  @renderer.host_gpu_request_device()
}

///|
pub fn host_gpu_get_queue(device : HostGpuDevice) -> HostGpuQueue {
  @renderer.host_gpu_get_queue(device)
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  @renderer.host_gpu_register_wgsl_source(rel_path, source)
}

///|
pub fn host_gpu_clip_matrix(
  x_axis_x : Float,
  x_axis_y : Float,
  x_axis_z : Float,
  x_axis_w : Float,
  y_axis_x : Float,
  y_axis_y : Float,
  y_axis_z : Float,
  y_axis_w : Float,
  z_axis_x : Float,
  z_axis_y : Float,
  z_axis_z : Float,
  z_axis_w : Float,
  w_axis_x : Float,
  w_axis_y : Float,
  w_axis_z : Float,
  w_axis_w : Float,
) -> HostGpuClipMatrix {
  @renderer.host_gpu_clip_matrix(
    x_axis_x, x_axis_y, x_axis_z, x_axis_w, y_axis_x, y_axis_y, y_axis_z, y_axis_w,
    z_axis_x, z_axis_y, z_axis_z, z_axis_w, w_axis_x, w_axis_y, w_axis_z, w_axis_w,
  )
}

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  @renderer.host_gpu_clear_registered_wgsl_source_registry()
}

///|
pub fn host_gpu_upload_mesh3d_preprocess_camera_payload(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  payload~ : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  @renderer.host_gpu_upload_mesh3d_preprocess_camera_payload(
    camera_key_hi~,
    camera_key_lo~,
    payload~,
  )
}

///|
pub fn host_gpu_build_mesh3d_indirect_parameters(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_BUILD_INDIRECT_PHASE_MAIN,
) -> Unit {
  @renderer.host_gpu_build_mesh3d_indirect_parameters(
    camera_key_hi~,
    camera_key_lo~,
    phase_kind~,
  )
}

///|
pub fn host_gpu_preprocess_mesh3d(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_PREPROCESS_PHASE_MAIN,
) -> Unit {
  @renderer.host_gpu_preprocess_mesh3d(
    camera_key_hi~,
    camera_key_lo~,
    phase_kind~,
  )
}

///|
pub fn host_gpu_downsample_mesh3d_depth_pyramid(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  @renderer.host_gpu_downsample_mesh3d_depth_pyramid(
    camera_key_hi~,
    camera_key_lo~,
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
  @render_phase_api.host_gpu_begin_pass(
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
  @render_phase_api.host_gpu_begin_pass_with_depth(
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
  transmission_blur_taps? : Float = 0.0F,
  transmission_steps? : Float = 0.0F,
  point_shadow_texture_id? : Int = -1,
  point_shadow_enabled? : Float = 0.0F,
  point_shadow_depth_bias? : Float = 0.0F,
  transmission_source_texture_id? : Int = -1,
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation_x? : Float = 0.0F,
  environment_map_rotation_y? : Float = 0.0F,
  environment_map_rotation_z? : Float = 0.0F,
  environment_map_rotation_w? : Float = 1.0F,
  point_shadow_near~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  @render_phase_api.host_gpu_begin_pass_3d(
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
    transmission_blur_taps~,
    transmission_steps~,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    transmission_source_texture_id~,
    environment_diffuse_texture_id~,
    environment_specular_texture_id~,
    environment_map_intensity~,
    environment_map_rotation_x~,
    environment_map_rotation_y~,
    environment_map_rotation_z~,
    environment_map_rotation_w~,
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
pub fn host_gpu_draw_sprite_uv_slices(
  texture_id~ : Int,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  slices_xy_uv~ : Array[Float],
) -> Unit {
  @renderer.draw_sprite_uv_slices(
    texture_id~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    slices_xy_uv~,
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
pub fn host_gpu_draw_mesh_wireframe(
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
) -> Unit {
  @renderer.draw_mesh_wireframe(
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
  )
}

///|
pub fn host_gpu_draw_mesh3d(
  mesh_id~ : Int,
  preprocess_camera_key_hi? : Int = 0,
  preprocess_camera_key_lo? : Int = 0,
  draw_storage_index? : Int = -1,
  indirect_kind? : Int = 0,
  indirect_parameters_index? : Int = -1,
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
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation_x? : Float = 0.0F,
  environment_map_rotation_y? : Float = 0.0F,
  environment_map_rotation_z? : Float = 0.0F,
  environment_map_rotation_w? : Float = 1.0F,
  cull_mode~ : Int,
  shader_path? : String? = None,
  skinning_key_hi? : Int = -1,
  skinning_key_lo? : Int = -1,
  skinning_matrices? : Array[Float]? = None,
) -> Unit {
  @renderer.draw_mesh3d(
    mesh_id~,
    preprocess_camera_key_hi~,
    preprocess_camera_key_lo~,
    draw_storage_index~,
    indirect_kind~,
    indirect_parameters_index~,
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
    environment_diffuse_texture_id~,
    environment_specular_texture_id~,
    environment_map_intensity~,
    environment_map_rotation_x~,
    environment_map_rotation_y~,
    environment_map_rotation_z~,
    environment_map_rotation_w~,
    cull_mode~,
    shader_path~,
    skinning_key_hi~,
    skinning_key_lo~,
    skinning_matrices~,
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
pub fn host_gpu_activate_auto_exposure_view_state(
  view_key_hi~ : Int,
  view_key_lo~ : Int,
) -> Unit {
  @renderer.activate_auto_exposure_view_state(view_key_hi~, view_key_lo~)
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
pub fn host_gpu_draw_blit(scene_texture_id~ : Int) -> Unit {
  @renderer.draw_blit(scene_texture_id~)
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
pub fn host_gpu_draw_custom_postprocess3d(
  scene_texture_id~ : Int,
  shader_path~ : String,
  fragment_entry~ : String,
  uniform_x~ : Float,
  uniform_y~ : Float,
  uniform_z~ : Float,
  uniform_w~ : Float,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  @renderer.draw_custom_postprocess3d(
    scene_texture_id~,
    shader_path~,
    fragment_entry~,
    uniform_x~,
    uniform_y~,
    uniform_z~,
    uniform_w~,
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
  @render_phase_api.host_gpu_end_pass()
}

///|
pub fn host_gpu_create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  @render_mesh.host_gpu_create_mesh_capsule(radius~, half_length~, segments~)
}

///|
pub fn host_gpu_create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  @render_mesh.host_gpu_create_mesh_rectangle(width~, height~)
}

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  @render_mesh.host_gpu_create_mesh_triangles(vertices_xy_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles_xyuvrgba(
  vertices_xyuvrgba_csv~ : String,
) -> Int {
  @render_mesh.host_gpu_create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles3d(
  vertices_xyzuvrgba_csv~ : String,
) -> Int {
  @render_mesh.host_gpu_create_mesh_triangles3d(vertices_xyzuvrgba_csv~)
}

///|
pub fn host_gpu_create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  @render_mesh.host_gpu_create_mesh3d(
    vertices_xyzuvrgba_csv~,
    primitive_topology~,
  )
}

///|
pub fn host_gpu_create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  @render_mesh.host_gpu_create_mesh3d_xyznuvrgba(
    vertices_xyznuvrgba~,
    primitive_topology~,
  )
}

///|
pub fn host_gpu_update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  @render_mesh.host_gpu_update_mesh3d_xyznuvrgba(
    mesh_id~,
    vertices_xyznuvrgba~,
    primitive_topology~,
  )
}

///|
pub fn host_debug_string(value~ : String) -> Unit {
  @renderer.host_debug_string(value~)
}

///|
pub fn render_diagnostics_snapshot() -> @render_diagnostic.RenderDiagnosticsSnapshot {
  @render_diagnostic.render_diagnostics_snapshot()
}

///|
pub fn render_diagnostics_commit_current_frame_snapshot() -> Unit {
  @render_diagnostic.render_diagnostics_commit_current_frame_snapshot()
}

///|
pub fn render_diagnostics_reset_current_frame_counters() -> Unit {
  @render_diagnostic.render_diagnostics_reset_current_frame_counters()
}
