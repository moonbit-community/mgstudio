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

// Begin-pass entrypoints and saved-pass reopening runtime.

///|
fn render_pass_sparse_prepass_attachment_count(
  base_kind : Int,
  color_attachment_present : Bool,
  secondary_color_attachment_present : Bool,
  deferred_attachment_present : Bool,
  deferred_lighting_pass_id_attachment_present : Bool,
) -> UInt {
  if deferred_attachment_present || deferred_lighting_pass_id_attachment_present {
    4U
  } else if base_kind == PASS_KIND_BASE_MOTION_VECTOR &&
    (color_attachment_present || secondary_color_attachment_present) {
    2U
  } else {
    0U
  }
}

///|
fn mesh3d_scene_depth_attachment_view(
  backend : GpuBackend,
  target_id : Int,
  safe_msaa_sample_count : Int,
  prepass_depth_texture_id : Int,
) -> (@wgpu.TextureView, Bool)? {
  if find_prepass_depth_texture(backend, prepass_depth_texture_id)
    is Some(prepass_depth_texture) {
    if backend.depth_width == prepass_depth_texture.width &&
      backend.depth_height == prepass_depth_texture.height &&
      backend.depth_sample_count == safe_msaa_sample_count {
      match backend.depth_view {
        Some(view_depth_view) => return Some((view_depth_view, true))
        None => ()
      }
    }
  }
  guard ensure_depth_view_for_target(backend, target_id, safe_msaa_sample_count)
    is Some(scene_depth_view) else {
    return None
  }
  Some((scene_depth_view, false))
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
  if !activate_surface_frame_for_target(self, target_id) {
    return
  }
  guard self.frame is Some(frame) else { return }
  render_pass_timing_end_active_pass()
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let effective_clear_enabled = if target_id < 0 &&
    clear_enabled != 0 &&
    self.surface_cleared_this_frame {
    0
  } else {
    clear_enabled
  }
  guard target_view(self, target_id, -1) is Some(view) else { return }
  let vx = if viewport_x < 0 { 0U } else { viewport_x.reinterpret_as_uint() }
  let vy = if viewport_y < 0 { 0U } else { viewport_y.reinterpret_as_uint() }
  let vw = if viewport_w < 0 { 0U } else { viewport_w.reinterpret_as_uint() }
  let vh = if viewport_h < 0 { 0U } else { viewport_h.reinterpret_as_uint() }
  let pass = if effective_clear_enabled == 0 {
    frame.encoder.begin_render_pass_color_load(view)
  } else {
    frame.encoder.begin_render_pass_color_clear(
      view, clear_r, clear_g, clear_b, clear_a,
    )
  }
  if target_id < 0 && effective_clear_enabled != 0 {
    set_active_surface_cleared_state(self, true)
  }
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
  self.pass_has_depth = false
  self.auto_exposure_active_state_buf = None
  let clip_from_world = gpu_clip_matrix_2d(
    Float::from_double(width_logical.to_double()),
    Float::from_double(height_logical.to_double()),
    camera_x,
    camera_y,
    camera_rot,
    camera_scale,
  )
  self.pass_state = Some(GpuPassState::{
    target_id,
    target_layer: -1,
    secondary_target_id: -1,
    prepass_depth_texture_id: -1,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    prepass_deferred_lighting_pass_id_texture_id: -1,
    view_depth_texture_id: -1,
    view_depth_view: None,
    screen_space_reflections: false,
    msaa_sample_count: 1,
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
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world,
    unjittered_clip_from_world: clip_from_world,
    world_from_clip: gpu_clip_matrix_identity(),
    world_from_view: gpu_clip_matrix_identity(),
    view_from_world: gpu_clip_matrix_identity(),
    clip_from_view: clip_from_world,
    view_from_clip: gpu_clip_matrix_identity(),
    previous_clip_from_world: clip_from_world,
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
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.7853981633974483F,
    transmission_blur_taps: 0.0F,
    transmission_steps: 0.0F,
    point_shadow_texture_id: -1,
    point_shadow_enabled: 0.0F,
    point_shadow_depth_bias: 0.0F,
    transmission_source_texture_id: -1,
    environment_diffuse_texture_id: -1,
    environment_specular_texture_id: -1,
    environment_map_intensity: 0.0F,
    environment_map_rotation_x: 0.0F,
    environment_map_rotation_y: 0.0F,
    environment_map_rotation_z: 0.0F,
    environment_map_rotation_w: 1.0F,
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near: 0.1F,
    directional_shadow_texture_id: -1,
    directional_shadow_enabled: 0.0F,
    directional_shadow_depth_bias: 0.0F,
    directional_shadow_normal_bias: 0.0F,
    directional_shadow_soft_size: 0.0F,
    directional_shadow_cascade_count: 0,
    directional_shadow_cascade_overlap: 0.0F,
    directional_shadow_cascade_data: [],
    mesh3d_lights_uniform_bytes: None,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    tonemapping_agx_lut_texture_id: -1,
    tonemapping_tony_lut_texture_id: -1,
    tonemapping_blender_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    deband_dither_enabled: false,
  })
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_vertex_data.clear()
  self.ui_batches.clear()
  self.ui_vertex_count = 0U
  self.ui_shadow_vertex_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_vertex_count = 0U
  self.ui_slice_vertex_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_vertex_count = 0U
  self.mesh3d_motion_vector_pass_view_uniform_bytes = None
  self.mesh3d_motion_vector_pass_previous_view_uniform_bytes = None
  ensure_sprite_resources(self)
  render_pass_timing_begin_active_pass(RENDER_PASS_PHASE_2D)
  if self.sprite_globals_buf is Some(globals_buf) {
    let safe_scale = if camera_scale == 0.0F { 1.0F } else { camera_scale }
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w / safe_scale } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h / safe_scale } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
  mesh2d_sync_view_uniforms_for_current_pass(self)
}

///|
pub fn GpuBackend::begin_pass_with_depth(
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
  if !activate_surface_frame_for_target(self, target_id) {
    return
  }
  guard self.frame is Some(frame) else { return }
  render_pass_timing_end_active_pass()
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let effective_clear_enabled = if target_id < 0 &&
    clear_enabled != 0 &&
    self.surface_cleared_this_frame {
    0
  } else {
    clear_enabled
  }
  guard target_view(self, target_id, -1) is Some(view) else { return }
  guard ensure_depth_view_for_target(self, target_id, 1) is Some(depth_view) else {
    return
  }
  let color_load_op_u32 = if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let depth_load_op_u32 = if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let stencil_load_op_u32 = if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let pass = frame.encoder.begin_render_pass_color_depth_u32(
    view,
    depth_view,
    color_load_op_u32~,
    color_store_op_u32=@wgpu.STORE_OP_STORE,
    color_clear_r_f32=clear_r,
    color_clear_g_f32=clear_g,
    color_clear_b_f32=clear_b,
    color_clear_a_f32=clear_a,
    depth_load_op_u32~,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    depth_read_only=false,
    stencil_load_op_u32~,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    stencil_read_only=true,
  )
  if target_id < 0 && effective_clear_enabled != 0 {
    set_active_surface_cleared_state(self, true)
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
  self.pass_has_depth = true
  self.auto_exposure_active_state_buf = None
  let clip_from_world = gpu_clip_matrix_2d(
    Float::from_double(width_logical.to_double()),
    Float::from_double(height_logical.to_double()),
    camera_x,
    camera_y,
    camera_rot,
    camera_scale,
  )
  self.pass_state = Some(GpuPassState::{
    target_id,
    target_layer: -1,
    secondary_target_id: -1,
    prepass_depth_texture_id: -1,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    prepass_deferred_lighting_pass_id_texture_id: -1,
    view_depth_texture_id: target_id,
    view_depth_view: Some(depth_view),
    screen_space_reflections: false,
    msaa_sample_count: 1,
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
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world,
    unjittered_clip_from_world: clip_from_world,
    world_from_clip: gpu_clip_matrix_identity(),
    world_from_view: gpu_clip_matrix_identity(),
    view_from_world: gpu_clip_matrix_identity(),
    clip_from_view: clip_from_world,
    view_from_clip: gpu_clip_matrix_identity(),
    previous_clip_from_world: clip_from_world,
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
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.7853981633974483F,
    transmission_blur_taps: 0.0F,
    transmission_steps: 0.0F,
    point_shadow_texture_id: -1,
    point_shadow_enabled: 0.0F,
    point_shadow_depth_bias: 0.0F,
    transmission_source_texture_id: -1,
    environment_diffuse_texture_id: -1,
    environment_specular_texture_id: -1,
    environment_map_intensity: 0.0F,
    environment_map_rotation_x: 0.0F,
    environment_map_rotation_y: 0.0F,
    environment_map_rotation_z: 0.0F,
    environment_map_rotation_w: 1.0F,
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near: 0.1F,
    directional_shadow_texture_id: -1,
    directional_shadow_enabled: 0.0F,
    directional_shadow_depth_bias: 0.0F,
    directional_shadow_normal_bias: 0.0F,
    directional_shadow_soft_size: 0.0F,
    directional_shadow_cascade_count: 0,
    directional_shadow_cascade_overlap: 0.0F,
    directional_shadow_cascade_data: [],
    mesh3d_lights_uniform_bytes: None,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    tonemapping_agx_lut_texture_id: -1,
    tonemapping_tony_lut_texture_id: -1,
    tonemapping_blender_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    deband_dither_enabled: false,
  })
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_vertex_data.clear()
  self.ui_batches.clear()
  self.ui_vertex_count = 0U
  self.ui_shadow_vertex_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_vertex_count = 0U
  self.ui_slice_vertex_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_vertex_count = 0U
  self.mesh3d_motion_vector_pass_view_uniform_bytes = None
  self.mesh3d_motion_vector_pass_previous_view_uniform_bytes = None
  ensure_sprite_resources(self)
  render_pass_timing_begin_active_pass(RENDER_PASS_PHASE_2D)
  if self.sprite_globals_buf is Some(globals_buf) {
    let safe_scale = if camera_scale == 0.0F { 1.0F } else { camera_scale }
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w / safe_scale } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h / safe_scale } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
  mesh2d_sync_view_uniforms_for_current_pass(self)
}

///|
pub fn GpuBackend::begin_pass_3d(
  self : GpuBackend,
  target_id : Int,
  target_layer : Int,
  secondary_target_id : Int,
  width_logical : Int,
  height_logical : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_z : Float,
  camera_exposure : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
  clip_from_world_x_axis_x : Float,
  clip_from_world_x_axis_y : Float,
  clip_from_world_x_axis_z : Float,
  clip_from_world_x_axis_w : Float,
  clip_from_world_y_axis_x : Float,
  clip_from_world_y_axis_y : Float,
  clip_from_world_y_axis_z : Float,
  clip_from_world_y_axis_w : Float,
  clip_from_world_z_axis_x : Float,
  clip_from_world_z_axis_y : Float,
  clip_from_world_z_axis_z : Float,
  clip_from_world_z_axis_w : Float,
  clip_from_world_w_axis_x : Float,
  clip_from_world_w_axis_y : Float,
  clip_from_world_w_axis_z : Float,
  clip_from_world_w_axis_w : Float,
  unjittered_clip_from_world_x_axis_x : Float,
  unjittered_clip_from_world_x_axis_y : Float,
  unjittered_clip_from_world_x_axis_z : Float,
  unjittered_clip_from_world_x_axis_w : Float,
  unjittered_clip_from_world_y_axis_x : Float,
  unjittered_clip_from_world_y_axis_y : Float,
  unjittered_clip_from_world_y_axis_z : Float,
  unjittered_clip_from_world_y_axis_w : Float,
  unjittered_clip_from_world_z_axis_x : Float,
  unjittered_clip_from_world_z_axis_y : Float,
  unjittered_clip_from_world_z_axis_z : Float,
  unjittered_clip_from_world_z_axis_w : Float,
  unjittered_clip_from_world_w_axis_x : Float,
  unjittered_clip_from_world_w_axis_y : Float,
  unjittered_clip_from_world_w_axis_z : Float,
  unjittered_clip_from_world_w_axis_w : Float,
  previous_clip_from_world_x_axis_x : Float,
  previous_clip_from_world_x_axis_y : Float,
  previous_clip_from_world_x_axis_z : Float,
  previous_clip_from_world_x_axis_w : Float,
  previous_clip_from_world_y_axis_x : Float,
  previous_clip_from_world_y_axis_y : Float,
  previous_clip_from_world_y_axis_z : Float,
  previous_clip_from_world_y_axis_w : Float,
  previous_clip_from_world_z_axis_x : Float,
  previous_clip_from_world_z_axis_y : Float,
  previous_clip_from_world_z_axis_z : Float,
  previous_clip_from_world_z_axis_w : Float,
  previous_clip_from_world_w_axis_x : Float,
  previous_clip_from_world_w_axis_y : Float,
  previous_clip_from_world_w_axis_z : Float,
  previous_clip_from_world_w_axis_w : Float,
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
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  transmission_source_texture_id : Int,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  environment_map_intensity : Float,
  environment_map_rotation_x : Float,
  environment_map_rotation_y : Float,
  environment_map_rotation_z : Float,
  environment_map_rotation_w : Float,
  point_shadow_near : Float,
  directional_shadow_texture_id : Int,
  directional_shadow_enabled : Float,
  directional_shadow_depth_bias : Float,
  directional_shadow_normal_bias : Float,
  directional_shadow_soft_size : Float,
  directional_shadow_cascade_count : Int,
  directional_shadow_cascade_overlap : Float,
  directional_shadow_cascade_data : Array[Float],
  mesh3d_lights_uniform_bytes : Bytes?,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  tonemapping_agx_lut_texture_id : Int,
  tonemapping_tony_lut_texture_id : Int,
  tonemapping_blender_lut_texture_id : Int,
  pbr_blue_noise_texture_id : Int,
  pbr_area_light_luts_texture_id : Int,
  pbr_dfg_lut_texture_id : Int,
  deband_dither_enabled : Bool,
  prepass_depth_texture_id : Int,
  prepass_normal_texture_id : Int,
  prepass_motion_vector_texture_id : Int,
  prepass_deferred_texture_id : Int,
  prepass_deferred_lighting_pass_id_texture_id : Int,
  screen_space_reflections : Bool,
  msaa_sample_count : Int,
  pass_kind : Int,
  clear_enabled : Int,
) -> Unit raise GpuBackendError {
  let camera_rot = quat_to_z_rotation(
    camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w,
  )
  if !activate_surface_frame_for_target(self, target_id) {
    return
  }
  guard self.frame is Some(frame) else { return }
  render_pass_timing_end_active_pass()
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let base_kind = pass_kind_base_kind(pass_kind)
  let safe_msaa_sample_count = if msaa_sample_count <= 1 {
    1
  } else {
    msaa_sample_count
  }
  let is_shadow_depth_pass = base_kind == PASS_KIND_BASE_POINT_SHADOW ||
    base_kind == PASS_KIND_BASE_DIRECTIONAL_SHADOW
  let is_prepass_depth_pass = base_kind == PASS_KIND_BASE_PREPASS
  let (
    color_view,
    color_resolve_view,
    secondary_color_view,
    secondary_color_resolve_view,
    deferred_color_view,
    deferred_color_resolve_view,
    deferred_lighting_pass_id_color_view,
    deferred_lighting_pass_id_color_resolve_view,
    depth_view,
    depth_attachment_uses_prepass,
  ) = if is_shadow_depth_pass {
    guard target_view(self, target_id, target_layer) is Some(shadow_depth_view) else {
      return
    }
    (None, None, None, None, None, None, None, None, shadow_depth_view, false)
  } else if is_prepass_depth_pass {
    guard find_prepass_depth_texture(self, prepass_depth_texture_id)
      is Some(prepass_depth_texture) else {
      return
    }
    guard ensure_depth_view_for_target(self, target_id, safe_msaa_sample_count)
      is Some(view_depth_view) else {
      return
    }
    let (normal_view, normal_resolve_view) = if prepass_normal_texture_id >= 0 {
      guard target_color_attachment(
          self, prepass_normal_texture_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      guard target_size_for_pass(self, prepass_normal_texture_id)
        is Some((normal_w, normal_h)) else {
        return
      }
      if prepass_depth_texture.width != normal_w ||
        prepass_depth_texture.height != normal_h ||
        prepass_depth_texture.sample_count != safe_msaa_sample_count {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    let (deferred_view, deferred_resolve_view) = if prepass_deferred_texture_id >=
      0 {
      guard target_color_attachment(
          self, prepass_deferred_texture_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      guard target_size_for_pass(self, prepass_deferred_texture_id)
        is Some((deferred_w, deferred_h)) else {
        return
      }
      if prepass_depth_texture.width != deferred_w ||
        prepass_depth_texture.height != deferred_h ||
        prepass_depth_texture.sample_count != safe_msaa_sample_count {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    let (deferred_lighting_view, deferred_lighting_resolve_view) = if prepass_deferred_lighting_pass_id_texture_id >=
      0 {
      guard target_color_attachment(
          self, prepass_deferred_lighting_pass_id_texture_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      guard target_size_for_pass(
          self, prepass_deferred_lighting_pass_id_texture_id,
        )
        is Some((lighting_w, lighting_h)) else {
        return
      }
      if prepass_depth_texture.width != lighting_w ||
        prepass_depth_texture.height != lighting_h ||
        prepass_depth_texture.sample_count != safe_msaa_sample_count {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    (
      normal_view,
      normal_resolve_view,
      None,
      None,
      deferred_view,
      deferred_resolve_view,
      deferred_lighting_view,
      deferred_lighting_resolve_view,
      view_depth_view,
      false,
    )
  } else if base_kind == PASS_KIND_BASE_MOTION_VECTOR &&
    secondary_target_id >= 0 {
    guard find_prepass_depth_texture(self, prepass_depth_texture_id)
      is Some(prepass_depth_texture) else {
      return
    }
    guard ensure_depth_view_for_target(
        self, prepass_depth_texture_id, safe_msaa_sample_count,
      )
      is Some(view_depth_view) else {
      return
    }
    let (primary_view, primary_resolve_view) = if prepass_normal_texture_id >= 0 {
      guard target_color_attachment(
          self, target_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    guard target_color_attachment(
        self, secondary_target_id, target_layer, safe_msaa_sample_count,
      )
      is Some((velocity_view, velocity_resolve_view)) else {
      return
    }
    let size_target_id = if prepass_normal_texture_id >= 0 {
      target_id
    } else {
      secondary_target_id
    }
    guard target_size_for_pass(self, size_target_id)
      is Some((primary_w, primary_h)) else {
      return
    }
    guard target_size_for_pass(self, secondary_target_id)
      is Some((secondary_w, secondary_h)) else {
      return
    }
    if primary_w != secondary_w || primary_h != secondary_h {
      return
    }
    if prepass_depth_texture.width != primary_w ||
      prepass_depth_texture.height != primary_h ||
      prepass_depth_texture.sample_count != safe_msaa_sample_count {
      return
    }
    let (deferred_view, deferred_resolve_view) = if prepass_deferred_texture_id >=
      0 {
      guard target_color_attachment(
          self, prepass_deferred_texture_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    let (deferred_lighting_view, deferred_lighting_resolve_view) = if prepass_deferred_lighting_pass_id_texture_id >=
      0 {
      guard target_color_attachment(
          self, prepass_deferred_lighting_pass_id_texture_id, target_layer, safe_msaa_sample_count,
        )
        is Some((view, resolve_view)) else {
        return
      }
      (Some(view), resolve_view)
    } else {
      (None, None)
    }
    (
      primary_view,
      primary_resolve_view,
      Some(velocity_view),
      velocity_resolve_view,
      deferred_view,
      deferred_resolve_view,
      deferred_lighting_view,
      deferred_lighting_resolve_view,
      view_depth_view,
      false,
    )
  } else {
    guard target_color_attachment(
        self, target_id, target_layer, safe_msaa_sample_count,
      )
      is Some((view, resolve_view)) else {
      return
    }
    guard mesh3d_scene_depth_attachment_view(
        self, target_id, safe_msaa_sample_count, prepass_depth_texture_id,
      )
      is Some((scene_depth_view, uses_prepass_depth)) else {
      return
    }
    (
      Some(view),
      resolve_view,
      None,
      None,
      None,
      None,
      None,
      None,
      scene_depth_view,
      uses_prepass_depth,
    )
  }
  let effective_clear_enabled = if target_id < 0 &&
    clear_enabled != 0 &&
    self.surface_cleared_this_frame {
    0
  } else {
    clear_enabled
  }
  let color_load_op_u32 = if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let depth_load_op_u32 = if depth_attachment_uses_prepass {
    @wgpu.LOAD_OP_LOAD
  } else if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let stencil_load_op_u32 = if effective_clear_enabled == 0 {
    @wgpu.LOAD_OP_LOAD
  } else {
    @wgpu.LOAD_OP_CLEAR
  }
  let vx = if viewport_x < 0 { 0U } else { viewport_x.reinterpret_as_uint() }
  let vy = if viewport_y < 0 { 0U } else { viewport_y.reinterpret_as_uint() }
  let vw = if viewport_w < 0 { 0U } else { viewport_w.reinterpret_as_uint() }
  let vh = if viewport_h < 0 { 0U } else { viewport_h.reinterpret_as_uint() }
  let clip_from_world_matrix = GpuClipMatrix::{
    x_axis_x: clip_from_world_x_axis_x,
    x_axis_y: clip_from_world_x_axis_y,
    x_axis_z: clip_from_world_x_axis_z,
    x_axis_w: clip_from_world_x_axis_w,
    y_axis_x: clip_from_world_y_axis_x,
    y_axis_y: clip_from_world_y_axis_y,
    y_axis_z: clip_from_world_y_axis_z,
    y_axis_w: clip_from_world_y_axis_w,
    z_axis_x: clip_from_world_z_axis_x,
    z_axis_y: clip_from_world_z_axis_y,
    z_axis_z: clip_from_world_z_axis_z,
    z_axis_w: clip_from_world_z_axis_w,
    w_axis_x: clip_from_world_w_axis_x,
    w_axis_y: clip_from_world_w_axis_y,
    w_axis_z: clip_from_world_w_axis_z,
    w_axis_w: clip_from_world_w_axis_w,
  }
  let unjittered_clip_from_world_matrix = GpuClipMatrix::{
    x_axis_x: unjittered_clip_from_world_x_axis_x,
    x_axis_y: unjittered_clip_from_world_x_axis_y,
    x_axis_z: unjittered_clip_from_world_x_axis_z,
    x_axis_w: unjittered_clip_from_world_x_axis_w,
    y_axis_x: unjittered_clip_from_world_y_axis_x,
    y_axis_y: unjittered_clip_from_world_y_axis_y,
    y_axis_z: unjittered_clip_from_world_y_axis_z,
    y_axis_w: unjittered_clip_from_world_y_axis_w,
    z_axis_x: unjittered_clip_from_world_z_axis_x,
    z_axis_y: unjittered_clip_from_world_z_axis_y,
    z_axis_z: unjittered_clip_from_world_z_axis_z,
    z_axis_w: unjittered_clip_from_world_z_axis_w,
    w_axis_x: unjittered_clip_from_world_w_axis_x,
    w_axis_y: unjittered_clip_from_world_w_axis_y,
    w_axis_z: unjittered_clip_from_world_w_axis_z,
    w_axis_w: unjittered_clip_from_world_w_axis_w,
  }
  let view_parts = gpu_clip_matrix_view_parts_3d(
    clip_from_world_matrix, camera_x, camera_y, camera_z, camera_rot_x, camera_rot_y,
    camera_rot_z, camera_rot_w,
  )
  let view_depth_texture_id = if is_shadow_depth_pass {
    target_id
  } else {
    self.depth_target_id
  }
  let pass_state = GpuPassState::{
    target_id,
    target_layer,
    secondary_target_id,
    prepass_depth_texture_id,
    prepass_normal_texture_id,
    prepass_motion_vector_texture_id,
    prepass_deferred_texture_id,
    prepass_deferred_lighting_pass_id_texture_id,
    view_depth_texture_id,
    view_depth_view: Some(depth_view),
    screen_space_reflections,
    msaa_sample_count: safe_msaa_sample_count,
    width_logical: Float::from_double(width_logical.to_double()),
    height_logical: Float::from_double(height_logical.to_double()),
    is_3d: true,
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: 1.0F,
    camera_z,
    camera_exposure,
    camera_rot_x,
    camera_rot_y,
    camera_rot_z,
    camera_rot_w,
    clip_from_world: clip_from_world_matrix,
    unjittered_clip_from_world: unjittered_clip_from_world_matrix,
    world_from_clip: view_parts.0,
    world_from_view: view_parts.1,
    view_from_world: view_parts.2,
    clip_from_view: view_parts.3,
    view_from_clip: view_parts.4,
    previous_clip_from_world: GpuClipMatrix::{
      x_axis_x: previous_clip_from_world_x_axis_x,
      x_axis_y: previous_clip_from_world_x_axis_y,
      x_axis_z: previous_clip_from_world_x_axis_z,
      x_axis_w: previous_clip_from_world_x_axis_w,
      y_axis_x: previous_clip_from_world_y_axis_x,
      y_axis_y: previous_clip_from_world_y_axis_y,
      y_axis_z: previous_clip_from_world_y_axis_z,
      y_axis_w: previous_clip_from_world_y_axis_w,
      z_axis_x: previous_clip_from_world_z_axis_x,
      z_axis_y: previous_clip_from_world_z_axis_y,
      z_axis_z: previous_clip_from_world_z_axis_z,
      z_axis_w: previous_clip_from_world_z_axis_w,
      w_axis_x: previous_clip_from_world_w_axis_x,
      w_axis_y: previous_clip_from_world_w_axis_y,
      w_axis_z: previous_clip_from_world_w_axis_z,
      w_axis_w: previous_clip_from_world_w_axis_w,
    },
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
    transmission_blur_taps,
    transmission_steps,
    point_shadow_texture_id,
    point_shadow_enabled,
    point_shadow_depth_bias,
    transmission_source_texture_id,
    environment_diffuse_texture_id,
    environment_specular_texture_id,
    environment_map_intensity,
    environment_map_rotation_x,
    environment_map_rotation_y,
    environment_map_rotation_z,
    environment_map_rotation_w,
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near,
    directional_shadow_texture_id,
    directional_shadow_enabled,
    directional_shadow_depth_bias,
    directional_shadow_normal_bias,
    directional_shadow_soft_size,
    directional_shadow_cascade_count,
    directional_shadow_cascade_overlap,
    directional_shadow_cascade_data,
    mesh3d_lights_uniform_bytes,
    tonemap_in_shader,
    tonemapping_mode,
    tonemapping_agx_lut_texture_id,
    tonemapping_tony_lut_texture_id,
    tonemapping_blender_lut_texture_id,
    pbr_blue_noise_texture_id,
    pbr_area_light_luts_texture_id,
    pbr_dfg_lut_texture_id,
    deband_dither_enabled,
  }
  self.pass_state = Some(pass_state)
  if directional_shadow_texture_id >= 0 && directional_shadow_cascade_count > 0 {
    @app.timeline_trace_emit_counter_int(
      "render_3d_begin_pass_directional_shadow_resources", 1,
    )
  }
  ensure_mesh3d_view_binding_buffers(self)
  if self.mesh3d_light_probes_buf is Some(light_probes_buf) {
    self.queue.write_buffer(
      light_probes_buf,
      0UL,
      mesh3d_light_probes_uniform_bytes(self, pass_state),
    )
  }
  mesh3d_dispatch_pending_ssao_for_pass(self, pass_state)
  let sparse_prepass_attachment_count = render_pass_sparse_prepass_attachment_count(
    base_kind,
    color_view is Some(_),
    secondary_color_view is Some(_),
    deferred_color_view is Some(_),
    deferred_lighting_pass_id_color_view is Some(_),
  )
  let pass = if sparse_prepass_attachment_count > 0U {
    let builder = @wgpu.RenderPassDescBuilder::new(
      sparse_prepass_attachment_count,
    ) catch {
      _ =>
        fatal("wgpu: failed to create deferred prepass render pass descriptor")
    }
    match color_view {
      Some(view) => {
        builder.set_color_attachment(
          0U,
          view,
          load_op_u32=color_load_op_u32,
          store_op_u32=@wgpu.STORE_OP_STORE,
          clear_r_f32=0.0F,
          clear_g_f32=0.0F,
          clear_b_f32=0.0F,
          clear_a_f32=0.0F,
        ) catch {
          _ => fatal("wgpu: failed to set deferred prepass normal attachment")
        }
        match color_resolve_view {
          Some(resolve_view) =>
            builder.set_color_attachment_resolve_target(0U, resolve_view) catch {
              _ =>
                fatal(
                  "wgpu: failed to set deferred prepass normal resolve attachment",
                )
            }
          None => ()
        }
      }
      None => ()
    }
    match secondary_color_view {
      Some(view) => {
        builder.set_color_attachment(
          1U,
          view,
          load_op_u32=color_load_op_u32,
          store_op_u32=@wgpu.STORE_OP_STORE,
          clear_r_f32=0.0F,
          clear_g_f32=0.0F,
          clear_b_f32=0.0F,
          clear_a_f32=0.0F,
        ) catch {
          _ =>
            fatal(
              "wgpu: failed to set deferred prepass motion-vector attachment",
            )
        }
        match secondary_color_resolve_view {
          Some(resolve_view) =>
            builder.set_color_attachment_resolve_target(1U, resolve_view) catch {
              _ =>
                fatal(
                  "wgpu: failed to set deferred prepass motion-vector resolve attachment",
                )
            }
          None => ()
        }
      }
      None => ()
    }
    match deferred_color_view {
      Some(view) => {
        builder.set_color_attachment(
          2U,
          view,
          load_op_u32=color_load_op_u32,
          store_op_u32=@wgpu.STORE_OP_STORE,
          clear_r_f32=0.0F,
          clear_g_f32=0.0F,
          clear_b_f32=0.0F,
          clear_a_f32=0.0F,
        ) catch {
          _ => fatal("wgpu: failed to set deferred prepass g-buffer attachment")
        }
        match deferred_color_resolve_view {
          Some(resolve_view) =>
            builder.set_color_attachment_resolve_target(2U, resolve_view) catch {
              _ =>
                fatal(
                  "wgpu: failed to set deferred prepass g-buffer resolve attachment",
                )
            }
          None => ()
        }
      }
      None => ()
    }
    match deferred_lighting_pass_id_color_view {
      Some(view) => {
        builder.set_color_attachment(
          3U,
          view,
          load_op_u32=color_load_op_u32,
          store_op_u32=@wgpu.STORE_OP_STORE,
          clear_r_f32=0.0F,
          clear_g_f32=0.0F,
          clear_b_f32=0.0F,
          clear_a_f32=0.0F,
        ) catch {
          _ =>
            fatal(
              "wgpu: failed to set deferred prepass lighting-pass-id attachment",
            )
        }
        match deferred_lighting_pass_id_color_resolve_view {
          Some(resolve_view) =>
            builder.set_color_attachment_resolve_target(3U, resolve_view) catch {
              _ =>
                fatal(
                  "wgpu: failed to set deferred prepass lighting-pass-id resolve attachment",
                )
            }
          None => ()
        }
      }
      None => ()
    }
    builder.set_depth_stencil_attachment(
      depth_view,
      depth_load_op_u32~,
      depth_store_op_u32=@wgpu.STORE_OP_STORE,
      depth_clear_value_f32=0.0F,
      depth_read_only=false,
      stencil_load_op_u32~,
      stencil_store_op_u32=@wgpu.STORE_OP_STORE,
      stencil_clear_value_u32=0U,
      stencil_read_only=true,
    ) catch {
      _ => fatal("wgpu: failed to set deferred prepass depth attachment")
    }
    builder.begin(frame.encoder) catch {
      _ => fatal("wgpu: failed to begin deferred prepass render pass")
    }
  } else {
    match color_view {
      None =>
        command_encoder_begin_render_pass_depth_u32(
          frame.encoder,
          depth_view,
          depth_load_op_u32~,
          depth_store_op_u32=@wgpu.STORE_OP_STORE,
          depth_clear_value_f32=0.0F,
          depth_read_only=false,
          stencil_load_op_u32~,
          stencil_store_op_u32=@wgpu.STORE_OP_STORE,
          stencil_clear_value_u32=0U,
          stencil_read_only=true,
        )
      Some(color0_view) =>
        match secondary_color_view {
          Some(color1_view) =>
            if base_kind == PASS_KIND_BASE_MOTION_VECTOR {
              if prepass_normal_texture_id >= 0 {
                frame.encoder.begin_render_pass_color2_depth_u32(
                  color0_view,
                  color1_view,
                  depth_view,
                  color0_load_op_u32=color_load_op_u32,
                  color0_store_op_u32=@wgpu.STORE_OP_STORE,
                  color0_clear_r_f32=0.0F,
                  color0_clear_g_f32=0.0F,
                  color0_clear_b_f32=0.0F,
                  color0_clear_a_f32=0.0F,
                  color1_load_op_u32=color_load_op_u32,
                  color1_store_op_u32=@wgpu.STORE_OP_STORE,
                  color1_clear_r_f32=0.0F,
                  color1_clear_g_f32=0.0F,
                  color1_clear_b_f32=0.0F,
                  color1_clear_a_f32=0.0F,
                  depth_load_op_u32~,
                  depth_store_op_u32=@wgpu.STORE_OP_STORE,
                  depth_clear_value_f32=0.0F,
                  depth_read_only=false,
                  // Bevy-aligned reverse-Z: clear depth to far plane.
                  stencil_load_op_u32~,
                  stencil_store_op_u32=@wgpu.STORE_OP_STORE,
                  stencil_clear_value_u32=0U,
                  stencil_read_only=true,
                )
              } else {
                frame.encoder.begin_render_pass_color1_depth_u32(
                  color1_view,
                  depth_view,
                  color1_load_op_u32=color_load_op_u32,
                  color1_store_op_u32=@wgpu.STORE_OP_STORE,
                  color1_clear_r_f32=0.0F,
                  color1_clear_g_f32=0.0F,
                  color1_clear_b_f32=0.0F,
                  color1_clear_a_f32=0.0F,
                  depth_load_op_u32~,
                  depth_store_op_u32=@wgpu.STORE_OP_STORE,
                  depth_clear_value_f32=0.0F,
                  depth_read_only=false,
                  // Bevy-aligned reverse-Z: clear depth to far plane.
                  stencil_load_op_u32~,
                  stencil_store_op_u32=@wgpu.STORE_OP_STORE,
                  stencil_clear_value_u32=0U,
                  stencil_read_only=true,
                )
              }
            } else {
              frame.encoder.begin_render_pass_color2_depth_u32(
                color0_view,
                color1_view,
                depth_view,
                color0_load_op_u32=color_load_op_u32,
                color0_store_op_u32=@wgpu.STORE_OP_STORE,
                color0_clear_r_f32=clear_r,
                color0_clear_g_f32=clear_g,
                color0_clear_b_f32=clear_b,
                color0_clear_a_f32=clear_a,
                color1_load_op_u32=color_load_op_u32,
                color1_store_op_u32=@wgpu.STORE_OP_STORE,
                color1_clear_r_f32=0.0F,
                color1_clear_g_f32=0.0F,
                color1_clear_b_f32=0.0F,
                color1_clear_a_f32=0.0F,
                depth_load_op_u32~,
                depth_store_op_u32=@wgpu.STORE_OP_STORE,
                depth_clear_value_f32=0.0F,
                depth_read_only=false,
                // Bevy-aligned reverse-Z: clear depth to far plane.
                stencil_load_op_u32~,
                stencil_store_op_u32=@wgpu.STORE_OP_STORE,
                stencil_clear_value_u32=0U,
                stencil_read_only=true,
              )
            }
          None =>
            match color_resolve_view {
              Some(resolve_view) =>
                command_encoder_begin_render_pass_color_depth_resolve_u32(
                  frame.encoder,
                  color0_view,
                  resolve_view,
                  color_load_op_u32~,
                  color_store_op_u32=@wgpu.STORE_OP_STORE,
                  color_clear_r_f32=clear_r,
                  color_clear_g_f32=clear_g,
                  color_clear_b_f32=clear_b,
                  color_clear_a_f32=clear_a,
                  depth_view,
                  depth_load_op_u32~,
                  depth_store_op_u32=@wgpu.STORE_OP_STORE,
                  depth_clear_value_f32=0.0F,
                  depth_read_only=false,
                  stencil_load_op_u32~,
                  stencil_store_op_u32=@wgpu.STORE_OP_STORE,
                  stencil_clear_value_u32=0U,
                  stencil_read_only=true,
                ) catch {
                  _ =>
                    fatal(
                      "wgpu: failed to begin color/depth render pass with resolve target",
                    )
                }
              None =>
                frame.encoder.begin_render_pass_color_depth_u32(
                  color0_view,
                  depth_view,
                  color_load_op_u32~,
                  color_store_op_u32=@wgpu.STORE_OP_STORE,
                  color_clear_r_f32=clear_r,
                  color_clear_g_f32=clear_g,
                  color_clear_b_f32=clear_b,
                  color_clear_a_f32=clear_a,
                  depth_load_op_u32~,
                  depth_store_op_u32=@wgpu.STORE_OP_STORE,
                  depth_clear_value_f32=0.0F,
                  depth_read_only=false,
                  // Bevy-aligned reverse-Z: clear depth to far plane.
                  stencil_load_op_u32~,
                  stencil_store_op_u32=@wgpu.STORE_OP_STORE,
                  stencil_clear_value_u32=0U,
                  stencil_read_only=true,
                )
            }
        }
    }
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
    0.0F,
    1.0F,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self, target_id, vx, vy, vw, vh,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  frame.pass = Some(pass)
  self.pass_has_depth = true
  if target_id < 0 && effective_clear_enabled != 0 {
    set_active_surface_cleared_state(self, true)
  }
  self.auto_exposure_active_state_buf = None
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_vertex_data.clear()
  self.ui_batches.clear()
  self.ui_vertex_count = 0U
  self.ui_shadow_vertex_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_vertex_count = 0U
  self.ui_slice_vertex_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_vertex_count = 0U
  self.mesh3d_motion_vector_pass_view_uniform_bytes = None
  self.mesh3d_motion_vector_pass_previous_view_uniform_bytes = None
  ensure_sprite_resources(self)
  render_pass_timing_begin_active_pass(
    render_pass_timing_phase_from_3d_pass_kind(pass_kind),
  )
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
pub fn begin_pass_with_depth(
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
    backend.begin_pass_with_depth(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
      viewport_depth_min, viewport_depth_max, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass_with_depth", err)
    }
  }
}

///|
pub fn begin_pass_3d(
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
  directional_shadow_texture_id? : Int = -1,
  directional_shadow_enabled? : Float = 0.0F,
  directional_shadow_depth_bias? : Float = 0.0F,
  directional_shadow_normal_bias? : Float = 0.0F,
  directional_shadow_soft_size? : Float = 0.0F,
  directional_shadow_cascade_count? : Int = 0,
  directional_shadow_cascade_overlap? : Float = 0.0F,
  directional_shadow_cascade_data? : Array[Float] = [],
  mesh3d_lights_uniform_bytes? : Bytes? = None,
  tonemap_in_shader? : Bool = false,
  tonemapping_mode? : Int = 0,
  tonemapping_agx_lut_texture_id? : Int = -1,
  tonemapping_tony_lut_texture_id? : Int = -1,
  tonemapping_blender_lut_texture_id? : Int = -1,
  pbr_blue_noise_texture_id? : Int = -1,
  pbr_area_light_luts_texture_id? : Int = -1,
  pbr_dfg_lut_texture_id? : Int = -1,
  deband_dither_enabled? : Bool = false,
  prepass_depth_texture_id? : Int = -1,
  prepass_normal_texture_id? : Int = -1,
  prepass_motion_vector_texture_id? : Int = -1,
  prepass_deferred_texture_id? : Int = -1,
  prepass_deferred_lighting_pass_id_texture_id? : Int = -1,
  screen_space_reflections? : Bool = false,
  msaa_sample_count? : Int = 1,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.begin_pass_3d(
      target_id, target_layer, secondary_target_id, width, height, clear_r, clear_g,
      clear_b, clear_a, camera_x, camera_y, camera_z, camera_exposure, camera_rot_x,
      camera_rot_y, camera_rot_z, camera_rot_w, clip_from_world_x_axis_x, clip_from_world_x_axis_y,
      clip_from_world_x_axis_z, clip_from_world_x_axis_w, clip_from_world_y_axis_x,
      clip_from_world_y_axis_y, clip_from_world_y_axis_z, clip_from_world_y_axis_w,
      clip_from_world_z_axis_x, clip_from_world_z_axis_y, clip_from_world_z_axis_z,
      clip_from_world_z_axis_w, clip_from_world_w_axis_x, clip_from_world_w_axis_y,
      clip_from_world_w_axis_z, clip_from_world_w_axis_w, unjittered_clip_from_world_x_axis_x,
      unjittered_clip_from_world_x_axis_y, unjittered_clip_from_world_x_axis_z, unjittered_clip_from_world_x_axis_w,
      unjittered_clip_from_world_y_axis_x, unjittered_clip_from_world_y_axis_y, unjittered_clip_from_world_y_axis_z,
      unjittered_clip_from_world_y_axis_w, unjittered_clip_from_world_z_axis_x, unjittered_clip_from_world_z_axis_y,
      unjittered_clip_from_world_z_axis_z, unjittered_clip_from_world_z_axis_w, unjittered_clip_from_world_w_axis_x,
      unjittered_clip_from_world_w_axis_y, unjittered_clip_from_world_w_axis_z, unjittered_clip_from_world_w_axis_w,
      previous_clip_from_world_x_axis_x, previous_clip_from_world_x_axis_y, previous_clip_from_world_x_axis_z,
      previous_clip_from_world_x_axis_w, previous_clip_from_world_y_axis_x, previous_clip_from_world_y_axis_y,
      previous_clip_from_world_y_axis_z, previous_clip_from_world_y_axis_w, previous_clip_from_world_z_axis_x,
      previous_clip_from_world_z_axis_y, previous_clip_from_world_z_axis_z, previous_clip_from_world_z_axis_w,
      previous_clip_from_world_w_axis_x, previous_clip_from_world_w_axis_y, previous_clip_from_world_w_axis_z,
      previous_clip_from_world_w_axis_w, viewport_x, viewport_y, viewport_width,
      viewport_height, ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x,
      directional_dir_y, directional_dir_z, directional_color_r, directional_color_g,
      directional_color_b, directional_illuminance, point_pos_x, point_pos_y, point_pos_z,
      point_color_r, point_color_g, point_color_b, point_intensity, point_range,
      spot_pos_x, spot_pos_y, spot_pos_z, spot_dir_x, spot_dir_y, spot_dir_z, spot_color_r,
      spot_color_g, spot_color_b, spot_intensity, spot_range, spot_inner_angle, spot_outer_angle,
      transmission_blur_taps, transmission_steps, point_shadow_texture_id, point_shadow_enabled,
      point_shadow_depth_bias, transmission_source_texture_id, environment_diffuse_texture_id,
      environment_specular_texture_id, environment_map_intensity, environment_map_rotation_x,
      environment_map_rotation_y, environment_map_rotation_z, environment_map_rotation_w,
      point_shadow_near, directional_shadow_texture_id, directional_shadow_enabled,
      directional_shadow_depth_bias, directional_shadow_normal_bias, directional_shadow_soft_size,
      directional_shadow_cascade_count, directional_shadow_cascade_overlap, directional_shadow_cascade_data,
      mesh3d_lights_uniform_bytes, tonemap_in_shader, tonemapping_mode, tonemapping_agx_lut_texture_id,
      tonemapping_tony_lut_texture_id, tonemapping_blender_lut_texture_id, pbr_blue_noise_texture_id,
      pbr_area_light_luts_texture_id, pbr_dfg_lut_texture_id, deband_dither_enabled,
      prepass_depth_texture_id, prepass_normal_texture_id, prepass_motion_vector_texture_id,
      prepass_deferred_texture_id, prepass_deferred_lighting_pass_id_texture_id,
      screen_space_reflections, msaa_sample_count, pass_kind, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass_3d", err)
    }
  }
}
