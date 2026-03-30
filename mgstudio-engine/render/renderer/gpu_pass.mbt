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
      pass_state.secondary_target_id,
      width_logical,
      height_logical,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      pass_state.camera_x,
      pass_state.camera_y,
      pass_state.camera_z,
      pass_state.camera_exposure,
      pass_state.camera_rot_x,
      pass_state.camera_rot_y,
      pass_state.camera_rot_z,
      pass_state.camera_rot_w,
      pass_state.clip_from_world.x_axis_x,
      pass_state.clip_from_world.x_axis_y,
      pass_state.clip_from_world.x_axis_z,
      pass_state.clip_from_world.x_axis_w,
      pass_state.clip_from_world.y_axis_x,
      pass_state.clip_from_world.y_axis_y,
      pass_state.clip_from_world.y_axis_z,
      pass_state.clip_from_world.y_axis_w,
      pass_state.clip_from_world.z_axis_x,
      pass_state.clip_from_world.z_axis_y,
      pass_state.clip_from_world.z_axis_z,
      pass_state.clip_from_world.z_axis_w,
      pass_state.clip_from_world.w_axis_x,
      pass_state.clip_from_world.w_axis_y,
      pass_state.clip_from_world.w_axis_z,
      pass_state.clip_from_world.w_axis_w,
      pass_state.unjittered_clip_from_world.x_axis_x,
      pass_state.unjittered_clip_from_world.x_axis_y,
      pass_state.unjittered_clip_from_world.x_axis_z,
      pass_state.unjittered_clip_from_world.x_axis_w,
      pass_state.unjittered_clip_from_world.y_axis_x,
      pass_state.unjittered_clip_from_world.y_axis_y,
      pass_state.unjittered_clip_from_world.y_axis_z,
      pass_state.unjittered_clip_from_world.y_axis_w,
      pass_state.unjittered_clip_from_world.z_axis_x,
      pass_state.unjittered_clip_from_world.z_axis_y,
      pass_state.unjittered_clip_from_world.z_axis_z,
      pass_state.unjittered_clip_from_world.z_axis_w,
      pass_state.unjittered_clip_from_world.w_axis_x,
      pass_state.unjittered_clip_from_world.w_axis_y,
      pass_state.unjittered_clip_from_world.w_axis_z,
      pass_state.unjittered_clip_from_world.w_axis_w,
      pass_state.previous_clip_from_world.x_axis_x,
      pass_state.previous_clip_from_world.x_axis_y,
      pass_state.previous_clip_from_world.x_axis_z,
      pass_state.previous_clip_from_world.x_axis_w,
      pass_state.previous_clip_from_world.y_axis_x,
      pass_state.previous_clip_from_world.y_axis_y,
      pass_state.previous_clip_from_world.y_axis_z,
      pass_state.previous_clip_from_world.y_axis_w,
      pass_state.previous_clip_from_world.z_axis_x,
      pass_state.previous_clip_from_world.z_axis_y,
      pass_state.previous_clip_from_world.z_axis_z,
      pass_state.previous_clip_from_world.z_axis_w,
      pass_state.previous_clip_from_world.w_axis_x,
      pass_state.previous_clip_from_world.w_axis_y,
      pass_state.previous_clip_from_world.w_axis_z,
      pass_state.previous_clip_from_world.w_axis_w,
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
      pass_state.point_shadow_near,
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
  render_diagnostics_end_active_pass_timing()
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
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
    point_shadow_near: 0.1F,
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
  ensure_sprite_resources(self)
  render_diagnostics_begin_active_pass_timing(RENDER_PASS_PHASE_2D)
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
  render_diagnostics_end_active_pass_timing()
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
  guard ensure_depth_view_for_target(self, target_id) is Some(depth_view) else {
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
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
    point_shadow_near: 0.1F,
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
  ensure_sprite_resources(self)
  render_diagnostics_begin_active_pass_timing(RENDER_PASS_PHASE_2D)
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
  point_shadow_near : Float,
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
  render_diagnostics_end_active_pass_timing()
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let base_kind = pass_kind_base_kind(pass_kind)
  let (color_view, secondary_color_view, depth_view) = if base_kind ==
    PASS_KIND_BASE_POINT_SHADOW {
    guard target_view(self, target_id, target_layer) is Some(shadow_depth_view) else {
      return
    }
    guard target_size_for_pass(self, target_id)
      is Some((target_width, target_height)) else {
      return
    }
    (
      ensure_shadow_color_view(self, target_width, target_height),
      None,
      shadow_depth_view,
    )
  } else if base_kind == PASS_KIND_BASE_MOTION_VECTOR &&
    secondary_target_id >= 0 {
    guard target_view(self, target_id, target_layer) is Some(primary_view) else {
      return
    }
    guard target_view(self, secondary_target_id, target_layer)
      is Some(velocity_view) else {
      return
    }
    guard target_size_for_pass(self, target_id) is Some((primary_w, primary_h)) else {
      return
    }
    guard target_size_for_pass(self, secondary_target_id)
      is Some((secondary_w, secondary_h)) else {
      return
    }
    if primary_w != secondary_w || primary_h != secondary_h {
      return
    }
    guard ensure_depth_view_for_target(self, target_id)
      is Some(scene_depth_view) else {
      return
    }
    (primary_view, Some(velocity_view), scene_depth_view)
  } else {
    guard target_view(self, target_id, target_layer) is Some(view) else {
      return
    }
    guard ensure_depth_view_for_target(self, target_id)
      is Some(scene_depth_view) else {
      return
    }
    (view, None, scene_depth_view)
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
  let pass = match secondary_color_view {
    Some(color1_view) =>
      frame.encoder.begin_render_pass_color2_depth_u32(
        color_view,
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
    None =>
      frame.encoder.begin_render_pass_color_depth_u32(
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
        depth_clear_value_f32=0.0F,
        depth_read_only=false,
        // Bevy-aligned reverse-Z: clear depth to far plane.
        stencil_load_op_u32~,
        stencil_store_op_u32=@wgpu.STORE_OP_STORE,
        stencil_clear_value_u32=0U,
        stencil_read_only=true,
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
  self.pass_state = Some(GpuPassState::{
    target_id,
    target_layer,
    secondary_target_id,
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
    clip_from_world: GpuClipMatrix::{
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
    },
    unjittered_clip_from_world: GpuClipMatrix::{
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
    },
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
    point_shadow_near,
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
  ensure_sprite_resources(self)
  render_diagnostics_begin_active_pass_timing(
    render_diagnostics_pass_phase_from_3d_pass_kind(pass_kind),
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
pub fn GpuBackend::set_scissor(
  self : GpuBackend,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  flush_mesh2d_batches(self)
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
  flush_mesh2d_batches(self)
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
    flush_mesh2d_batches(self)
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    render_diagnostics_end_active_pass_timing()
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
  self.pass_has_depth = false
}
