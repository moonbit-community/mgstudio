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
pub fn GpuBackend::draw_tonemapping2d(
  self : GpuBackend,
  scene_texture_id : Int,
  exposure : Float,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  if scene_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  let format = match current_pass_color_format(self) {
    Some(format) => format
    _ => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let deband_dither = deband_dither_enabled != 0
  guard tonemapping_pipeline_for_format(
      self, format, tonemapping_mode, deband_dither,
    )
    is Some(final_pipeline) else {
    return
  }
  guard self.tonemapping_bgl is Some(final_bind_layout) else { return }
  guard self.tonemapping_view_buf is Some(view_buf) else { return }
  guard self.tonemapping_sampler is Some(tonemapping_sampler) else { return }
  let selected_lut_view = tonemapping_selected_lut_view(
    self, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  let exposure_value = if exposure < 0.0F { 0.0F } else { exposure }
  view_width |> ignore
  view_height |> ignore
  if self.auto_exposure_active_state_buf is None {
    tonemapping_write_view_uniform(
      self, pass_state, exposure_value, color_grading_balance_x_axis_x, color_grading_balance_x_axis_y,
      color_grading_balance_x_axis_z, color_grading_balance_y_axis_x, color_grading_balance_y_axis_y,
      color_grading_balance_y_axis_z, color_grading_balance_z_axis_x, color_grading_balance_z_axis_y,
      color_grading_balance_z_axis_z, color_grading_saturation_shadows, color_grading_saturation_midtones,
      color_grading_saturation_highlights, color_grading_contrast_shadows, color_grading_contrast_midtones,
      color_grading_contrast_highlights, color_grading_gamma_shadows, color_grading_gamma_midtones,
      color_grading_gamma_highlights, color_grading_gain_shadows, color_grading_gain_midtones,
      color_grading_gain_highlights, color_grading_lift_shadows, color_grading_lift_midtones,
      color_grading_lift_highlights, color_grading_midtones_start, color_grading_midtones_end,
      color_grading_exposure, color_grading_hue, color_grading_post_saturation,
    )
  }

  active_pass.end()
  active_pass.release()
  frame.pass = None

  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE) &&
      builder.add_texture_view(1U, scene_texture.view) &&
      builder.add_sampler(2U, tonemapping_sampler) &&
      builder.add_texture_view(3U, selected_lut_view) &&
      builder.add_sampler(4U, tonemapping_sampler)
    if ok {
      let final_bg = builder.finish(
        self.device,
        final_bind_layout,
        label="mgstudio_tonemapping_bind_group",
      )
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
      final_pass.set_bind_group(0U, final_bg, [0U])
      final_pass.draw(3U, 1U, 0U, 0U)
      final_pass.end()
      final_pass.release()
      final_bg.release()
    } else {
      builder.free()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn draw_tonemapping2d(
  scene_texture_id~ : Int,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
  color_grading_balance_x_axis_x~ : Float,
  color_grading_balance_x_axis_y~ : Float,
  color_grading_balance_x_axis_z~ : Float,
  color_grading_balance_y_axis_x~ : Float,
  color_grading_balance_y_axis_y~ : Float,
  color_grading_balance_y_axis_z~ : Float,
  color_grading_balance_z_axis_x~ : Float,
  color_grading_balance_z_axis_y~ : Float,
  color_grading_balance_z_axis_z~ : Float,
  color_grading_saturation_shadows~ : Float,
  color_grading_saturation_midtones~ : Float,
  color_grading_saturation_highlights~ : Float,
  color_grading_contrast_shadows~ : Float,
  color_grading_contrast_midtones~ : Float,
  color_grading_contrast_highlights~ : Float,
  color_grading_gamma_shadows~ : Float,
  color_grading_gamma_midtones~ : Float,
  color_grading_gamma_highlights~ : Float,
  color_grading_gain_shadows~ : Float,
  color_grading_gain_midtones~ : Float,
  color_grading_gain_highlights~ : Float,
  color_grading_lift_shadows~ : Float,
  color_grading_lift_midtones~ : Float,
  color_grading_lift_highlights~ : Float,
  color_grading_midtones_start~ : Float,
  color_grading_midtones_end~ : Float,
  color_grading_exposure~ : Float,
  color_grading_hue~ : Float,
  color_grading_post_saturation~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_tonemapping2d(
      scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
      view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
      color_grading_balance_x_axis_x, color_grading_balance_x_axis_y, color_grading_balance_x_axis_z,
      color_grading_balance_y_axis_x, color_grading_balance_y_axis_y, color_grading_balance_y_axis_z,
      color_grading_balance_z_axis_x, color_grading_balance_z_axis_y, color_grading_balance_z_axis_z,
      color_grading_saturation_shadows, color_grading_saturation_midtones, color_grading_saturation_highlights,
      color_grading_contrast_shadows, color_grading_contrast_midtones, color_grading_contrast_highlights,
      color_grading_gamma_shadows, color_grading_gamma_midtones, color_grading_gamma_highlights,
      color_grading_gain_shadows, color_grading_gain_midtones, color_grading_gain_highlights,
      color_grading_lift_shadows, color_grading_lift_midtones, color_grading_lift_highlights,
      color_grading_midtones_start, color_grading_midtones_end, color_grading_exposure,
      color_grading_hue, color_grading_post_saturation,
    ) catch {
      err => debug_runtime_error("draw_tonemapping2d", err)
    }
  }
}

///|
fn GpuBackend::draw_tonemapping3d_fullscreen(
  self : GpuBackend,
  scene_texture_id : Int,
  exposure : Float,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  if scene_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  let format = match current_pass_color_format(self) {
    Some(format) => format
    _ => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let deband_dither = deband_dither_enabled != 0
  guard tonemapping_pipeline_for_format(
      self, format, tonemapping_mode, deband_dither,
    )
    is Some(final_pipeline) else {
    return
  }
  guard self.tonemapping_bgl is Some(final_bind_layout) else { return }
  guard self.tonemapping_view_buf is Some(view_buf) else { return }
  guard self.tonemapping_sampler is Some(tonemapping_sampler) else { return }
  let selected_lut_view = tonemapping_selected_lut_view(
    self, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  let exposure_value = clamp_non_negative(exposure)
  view_width |> ignore
  view_height |> ignore
  tonemapping_write_view_uniform(
    self, pass_state, exposure_value, color_grading_balance_x_axis_x, color_grading_balance_x_axis_y,
    color_grading_balance_x_axis_z, color_grading_balance_y_axis_x, color_grading_balance_y_axis_y,
    color_grading_balance_y_axis_z, color_grading_balance_z_axis_x, color_grading_balance_z_axis_y,
    color_grading_balance_z_axis_z, color_grading_saturation_shadows, color_grading_saturation_midtones,
    color_grading_saturation_highlights, color_grading_contrast_shadows, color_grading_contrast_midtones,
    color_grading_contrast_highlights, color_grading_gamma_shadows, color_grading_gamma_midtones,
    color_grading_gamma_highlights, color_grading_gain_shadows, color_grading_gain_midtones,
    color_grading_gain_highlights, color_grading_lift_shadows, color_grading_lift_midtones,
    color_grading_lift_highlights, color_grading_midtones_start, color_grading_midtones_end,
    color_grading_exposure, color_grading_hue, color_grading_post_saturation,
  )

  active_pass.end()
  active_pass.release()
  frame.pass = None

  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE) &&
      builder.add_texture_view(1U, scene_texture.view) &&
      builder.add_sampler(2U, tonemapping_sampler) &&
      builder.add_texture_view(3U, selected_lut_view) &&
      builder.add_sampler(4U, tonemapping_sampler)
    if ok {
      let final_bg = builder.finish(
        self.device,
        final_bind_layout,
        label="mgstudio_tonemapping_bind_group",
      )
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
      final_pass.set_bind_group(0U, final_bg, [0U])
      final_pass.draw(3U, 1U, 0U, 0U)
      final_pass.end()
      final_pass.release()
      final_bg.release()
    } else {
      builder.free()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn GpuBackend::draw_tonemapping3d(
  self : GpuBackend,
  scene_texture_id : Int,
  exposure : Float,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
) -> Unit raise GpuBackendError {
  self.draw_tonemapping3d_fullscreen(
    scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
    view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
    color_grading_balance_x_axis_x, color_grading_balance_x_axis_y, color_grading_balance_x_axis_z,
    color_grading_balance_y_axis_x, color_grading_balance_y_axis_y, color_grading_balance_y_axis_z,
    color_grading_balance_z_axis_x, color_grading_balance_z_axis_y, color_grading_balance_z_axis_z,
    color_grading_saturation_shadows, color_grading_saturation_midtones, color_grading_saturation_highlights,
    color_grading_contrast_shadows, color_grading_contrast_midtones, color_grading_contrast_highlights,
    color_grading_gamma_shadows, color_grading_gamma_midtones, color_grading_gamma_highlights,
    color_grading_gain_shadows, color_grading_gain_midtones, color_grading_gain_highlights,
    color_grading_lift_shadows, color_grading_lift_midtones, color_grading_lift_highlights,
    color_grading_midtones_start, color_grading_midtones_end, color_grading_exposure,
    color_grading_hue, color_grading_post_saturation,
  )
}

///|
pub fn draw_tonemapping3d(
  scene_texture_id~ : Int,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
  color_grading_balance_x_axis_x~ : Float,
  color_grading_balance_x_axis_y~ : Float,
  color_grading_balance_x_axis_z~ : Float,
  color_grading_balance_y_axis_x~ : Float,
  color_grading_balance_y_axis_y~ : Float,
  color_grading_balance_y_axis_z~ : Float,
  color_grading_balance_z_axis_x~ : Float,
  color_grading_balance_z_axis_y~ : Float,
  color_grading_balance_z_axis_z~ : Float,
  color_grading_saturation_shadows~ : Float,
  color_grading_saturation_midtones~ : Float,
  color_grading_saturation_highlights~ : Float,
  color_grading_contrast_shadows~ : Float,
  color_grading_contrast_midtones~ : Float,
  color_grading_contrast_highlights~ : Float,
  color_grading_gamma_shadows~ : Float,
  color_grading_gamma_midtones~ : Float,
  color_grading_gamma_highlights~ : Float,
  color_grading_gain_shadows~ : Float,
  color_grading_gain_midtones~ : Float,
  color_grading_gain_highlights~ : Float,
  color_grading_lift_shadows~ : Float,
  color_grading_lift_midtones~ : Float,
  color_grading_lift_highlights~ : Float,
  color_grading_midtones_start~ : Float,
  color_grading_midtones_end~ : Float,
  color_grading_exposure~ : Float,
  color_grading_hue~ : Float,
  color_grading_post_saturation~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_tonemapping3d(
      scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
      view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
      color_grading_balance_x_axis_x, color_grading_balance_x_axis_y, color_grading_balance_x_axis_z,
      color_grading_balance_y_axis_x, color_grading_balance_y_axis_y, color_grading_balance_y_axis_z,
      color_grading_balance_z_axis_x, color_grading_balance_z_axis_y, color_grading_balance_z_axis_z,
      color_grading_saturation_shadows, color_grading_saturation_midtones, color_grading_saturation_highlights,
      color_grading_contrast_shadows, color_grading_contrast_midtones, color_grading_contrast_highlights,
      color_grading_gamma_shadows, color_grading_gamma_midtones, color_grading_gamma_highlights,
      color_grading_gain_shadows, color_grading_gain_midtones, color_grading_gain_highlights,
      color_grading_lift_shadows, color_grading_lift_midtones, color_grading_lift_highlights,
      color_grading_midtones_start, color_grading_midtones_end, color_grading_exposure,
      color_grading_hue, color_grading_post_saturation,
    ) catch {
      err => debug_runtime_error("draw_tonemapping3d", err)
    }
  }
}

///|
fn gpu_clip_matrix_words(matrix : GpuClipMatrix) -> Array[UInt] {
  [
    f32_bits(matrix.x_axis_x),
    f32_bits(matrix.x_axis_y),
    f32_bits(matrix.x_axis_z),
    f32_bits(matrix.x_axis_w),
    f32_bits(matrix.y_axis_x),
    f32_bits(matrix.y_axis_y),
    f32_bits(matrix.y_axis_z),
    f32_bits(matrix.y_axis_w),
    f32_bits(matrix.z_axis_x),
    f32_bits(matrix.z_axis_y),
    f32_bits(matrix.z_axis_z),
    f32_bits(matrix.z_axis_w),
    f32_bits(matrix.w_axis_x),
    f32_bits(matrix.w_axis_y),
    f32_bits(matrix.w_axis_z),
    f32_bits(matrix.w_axis_w),
  ]
}

///|
fn tonemapping_view_uniform_bytes_full(
  pass_state : GpuPassState,
  exposure : Float,
  frame_count : UInt,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
) -> Bytes {
  let viewport_x = Float::from_double(pass_state.viewport_x.to_double())
  let viewport_y = Float::from_double(pass_state.viewport_y.to_double())
  let viewport_w = Float::from_double(pass_state.viewport_w.to_double())
  let viewport_h = Float::from_double(pass_state.viewport_h.to_double())
  let identity = gpu_clip_matrix_identity()
  let words : Array[UInt] = []
  for word in gpu_clip_matrix_words(pass_state.clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.unjittered_clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  words.push(f32_bits(pass_state.camera_x))
  words.push(f32_bits(pass_state.camera_y))
  words.push(f32_bits(pass_state.camera_z))
  words.push(f32_bits(exposure))
  words.push(f32_bits(viewport_x))
  words.push(f32_bits(viewport_y))
  words.push(f32_bits(viewport_w))
  words.push(f32_bits(viewport_h))
  words.push(f32_bits(viewport_x))
  words.push(f32_bits(viewport_y))
  words.push(f32_bits(viewport_w))
  words.push(f32_bits(viewport_h))
  for _ in 0..<24 {
    words.push(0U)
  }
  words.push(f32_bits(color_grading_balance_x_axis_x))
  words.push(f32_bits(color_grading_balance_x_axis_y))
  words.push(f32_bits(color_grading_balance_x_axis_z))
  words.push(0U)
  words.push(f32_bits(color_grading_balance_y_axis_x))
  words.push(f32_bits(color_grading_balance_y_axis_y))
  words.push(f32_bits(color_grading_balance_y_axis_z))
  words.push(0U)
  words.push(f32_bits(color_grading_balance_z_axis_x))
  words.push(f32_bits(color_grading_balance_z_axis_y))
  words.push(f32_bits(color_grading_balance_z_axis_z))
  words.push(0U)
  words.push(f32_bits(color_grading_saturation_shadows))
  words.push(f32_bits(color_grading_saturation_midtones))
  words.push(f32_bits(color_grading_saturation_highlights))
  words.push(0U)
  words.push(f32_bits(color_grading_contrast_shadows))
  words.push(f32_bits(color_grading_contrast_midtones))
  words.push(f32_bits(color_grading_contrast_highlights))
  words.push(0U)
  words.push(f32_bits(color_grading_gamma_shadows))
  words.push(f32_bits(color_grading_gamma_midtones))
  words.push(f32_bits(color_grading_gamma_highlights))
  words.push(0U)
  words.push(f32_bits(color_grading_gain_shadows))
  words.push(f32_bits(color_grading_gain_midtones))
  words.push(f32_bits(color_grading_gain_highlights))
  words.push(0U)
  words.push(f32_bits(color_grading_lift_shadows))
  words.push(f32_bits(color_grading_lift_midtones))
  words.push(f32_bits(color_grading_lift_highlights))
  words.push(0U)
  words.push(f32_bits(color_grading_midtones_start))
  words.push(f32_bits(color_grading_midtones_end))
  words.push(f32_bits(color_grading_exposure))
  words.push(f32_bits(color_grading_hue))
  words.push(f32_bits(color_grading_post_saturation))
  words.push(0U)
  words.push(0U)
  words.push(0U)
  words.push(f32_bits(0.0F))
  words.push(frame_count)
  let target_word_count = (MESH2D_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in words.length()..<target_word_count {
    words.push(0U)
  }
  u32le_pack(words)
}

///|
fn tonemapping_write_view_uniform(
  backend : GpuBackend,
  pass_state : GpuPassState,
  exposure : Float,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
) -> Unit {
  guard backend.tonemapping_view_buf is Some(view_buf) else { return }
  let view_uniform = tonemapping_view_uniform_bytes_full(
    pass_state,
    exposure,
    backend.frame_count,
    color_grading_balance_x_axis_x,
    color_grading_balance_x_axis_y,
    color_grading_balance_x_axis_z,
    color_grading_balance_y_axis_x,
    color_grading_balance_y_axis_y,
    color_grading_balance_y_axis_z,
    color_grading_balance_z_axis_x,
    color_grading_balance_z_axis_y,
    color_grading_balance_z_axis_z,
    color_grading_saturation_shadows,
    color_grading_saturation_midtones,
    color_grading_saturation_highlights,
    color_grading_contrast_shadows,
    color_grading_contrast_midtones,
    color_grading_contrast_highlights,
    color_grading_gamma_shadows,
    color_grading_gamma_midtones,
    color_grading_gamma_highlights,
    color_grading_gain_shadows,
    color_grading_gain_midtones,
    color_grading_gain_highlights,
    color_grading_lift_shadows,
    color_grading_lift_midtones,
    color_grading_lift_highlights,
    color_grading_midtones_start,
    color_grading_midtones_end,
    color_grading_exposure,
    color_grading_hue,
    color_grading_post_saturation,
  )
  backend.queue.write_buffer(view_buf, 0UL, view_uniform)
}

///|
fn tonemapping_mode_clamped(tonemapping_mode : Int) -> Int {
  if tonemapping_mode < 0 {
    0
  } else if tonemapping_mode > 7 {
    7
  } else {
    tonemapping_mode
  }
}

///|
fn tonemapping_method_define(tonemapping_mode : Int) -> String {
  match tonemapping_mode_clamped(tonemapping_mode) {
    0 => "TONEMAP_METHOD_NONE"
    1 => "TONEMAP_METHOD_REINHARD"
    2 => "TONEMAP_METHOD_REINHARD_LUMINANCE"
    3 => "TONEMAP_METHOD_ACES_FITTED"
    4 => "TONEMAP_METHOD_AGX"
    5 => "TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM"
    6 => "TONEMAP_METHOD_TONY_MC_MAPFACE"
    _ => "TONEMAP_METHOD_BLENDER_FILMIC"
  }
}

///|
fn tonemapping_pipeline_define_keys(
  tonemapping_mode : Int,
  deband_dither : Bool,
) -> Array[String] {
  let defines = [tonemapping_method_define(tonemapping_mode)]
  if deband_dither {
    defines.push("DEBAND_DITHER")
  }
  defines
}

///|
fn tonemapping_pipeline_cache_key(
  format : @wgpu.TextureFormat,
  tonemapping_mode : Int,
  deband_dither : Bool,
) -> String {
  let deband_bits = if deband_dither { "1" } else { "0" }
  format.raw.to_string() +
  "_\{tonemapping_mode_clamped(tonemapping_mode).to_string()}_\{deband_bits}"
}

///|
fn tonemapping_shader_text(lines : Array[String]) -> String {
  let mut out = ""
  for i in 0..<lines.length() {
    out = out + lines[i]
    if i + 1 < lines.length() {
      out = "\{out}\n"
    }
  }
  "\{out}\n"
}

///|
fn strip_tonemapping_main_imports(source : String) -> String {
  let render_import = tonemapping_shader_text([
    "#import bevy_render::{", "    view::View,", "    maths::powsafe,", "}",
  ])
  let pipeline_import = tonemapping_shader_text([
    "#import bevy_core_pipeline::{", "    fullscreen_vertex_shader::FullscreenVertexOutput,",
    "    tonemapping::{tone_mapping, screen_space_dither},", "}",
  ])
  replace_shader_substring_all(
    replace_shader_substring_all(
      replace_shader_substring_all(source, "#define TONEMAPPING_PASS\n", ""),
      render_import,
      "",
    ),
    pipeline_import,
    "",
  )
}

///|
fn rewrite_tonemapping_shared_branches(source : String) -> String {
  let sample_current_lut_original = tonemapping_shader_text([
    "#ifdef TONEMAP_METHOD_AGX", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else ifdef TONEMAP_METHOD_TONY_MC_MAPFACE", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else ifdef TONEMAP_METHOD_BLENDER_FILMIC", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else", "    return vec3(1.0, 0.0, 1.0);", " #endif",
  ])
  let sample_current_lut_rewritten = tonemapping_shader_text([
    "#ifdef TONEMAP_METHOD_AGX", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else", "#ifdef TONEMAP_METHOD_TONY_MC_MAPFACE", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else", "#ifdef TONEMAP_METHOD_BLENDER_FILMIC", "    return textureSampleLevel(dt_lut_texture, dt_lut_sampler, p, 0.0).rgb;",
    "#else", "    return vec3(1.0, 0.0, 1.0);", "#endif", "#endif", "#endif",
  ])
  let tone_mapping_original = tonemapping_shader_text([
    "#ifdef TONEMAP_METHOD_NONE", "    color = color;", "#else ifdef TONEMAP_METHOD_REINHARD",
    "    color = tonemapping_reinhard(color.rgb);", "#else ifdef TONEMAP_METHOD_REINHARD_LUMINANCE",
    "    color = tonemapping_reinhard_luminance(color.rgb);", "#else ifdef TONEMAP_METHOD_ACES_FITTED",
    "    color = ACESFitted(color.rgb);", "#else ifdef TONEMAP_METHOD_AGX", "    color = applyAgXLog(color);",
    "    color = applyLUT3D(color, 32.0);", "#else ifdef TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM",
    "    color = somewhat_boring_display_transform(color.rgb);", "#else ifdef TONEMAP_METHOD_TONY_MC_MAPFACE",
    "    color = sample_tony_mc_mapface_lut(color);", "#else ifdef TONEMAP_METHOD_BLENDER_FILMIC",
    "    color = sample_blender_filmic_lut(color.rgb);", "#endif",
  ])
  let tone_mapping_rewritten = tonemapping_shader_text([
    "#ifdef TONEMAP_METHOD_NONE", "    color = color;", "#else", "#ifdef TONEMAP_METHOD_REINHARD",
    "    color = tonemapping_reinhard(color.rgb);", "#else", "#ifdef TONEMAP_METHOD_REINHARD_LUMINANCE",
    "    color = tonemapping_reinhard_luminance(color.rgb);", "#else", "#ifdef TONEMAP_METHOD_ACES_FITTED",
    "    color = ACESFitted(color.rgb);", "#else", "#ifdef TONEMAP_METHOD_AGX", "    color = applyAgXLog(color);",
    "    color = applyLUT3D(color, 32.0);", "#else", "#ifdef TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM",
    "    color = somewhat_boring_display_transform(color.rgb);", "#else", "#ifdef TONEMAP_METHOD_TONY_MC_MAPFACE",
    "    color = sample_tony_mc_mapface_lut(color);", "#else", "#ifdef TONEMAP_METHOD_BLENDER_FILMIC",
    "    color = sample_blender_filmic_lut(color.rgb);", "#endif", "#endif", "#endif",
    "#endif", "#endif", "#endif", "#endif",
  ])
  replace_shader_substring_all(
    replace_shader_substring_all(
      source, sample_current_lut_original, sample_current_lut_rewritten,
    ),
    tone_mapping_original,
    tone_mapping_rewritten,
  )
}

///|
fn strip_tonemapping_shared_imports(source : String) -> String {
  let render_import = tonemapping_shader_text([
    "#import bevy_render::{", "    view::ColorGrading,", "    color_operations::{hsv_to_rgb, rgb_to_hsv},",
    "    maths::{PI_2, powsafe},", "}",
  ])
  let lut_import = tonemapping_shader_text([
    "#import bevy_core_pipeline::tonemapping_lut_bindings::{", "    dt_lut_texture,",
    "    dt_lut_sampler,", "}",
  ])
  let stripped = replace_shader_substring_all(
    replace_shader_substring_all(source, render_import, ""),
    lut_import,
    "",
  )
  rewrite_tonemapping_shared_branches(stripped)
}

///|
fn strip_tonemapping_color_operations_imports(source : String) -> String {
  replace_shader_substring_all(
    source, "#import bevy_render::maths::FRAC_PI_3\n", "",
  )
}

///|
fn load_fullscreen_tonemapping_wgsl_with_defines_required(
  backend : GpuBackend,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let fullscreen_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
  let view_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_render/view/view.wgsl",
  )
  let maths_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_render/maths.wgsl",
  )
  let color_operations_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_render/color_operations.wgsl",
  )
  let tonemapping_shared_source = strip_tonemapping_shared_imports(
    load_wgsl_asset_source_required(
      backend, "shaders/bevy_core_pipeline/tonemapping/tonemapping_shared.wgsl",
    ),
  )
  let main_source = strip_tonemapping_main_imports(
    load_wgsl_asset_source_required(
      backend, "shaders/bevy_core_pipeline/tonemapping/tonemapping.wgsl",
    ),
  )
  let merged_source = merge_fullscreen_postprocess_source(
    "\{maths_source}\n\{strip_tonemapping_color_operations_imports(color_operations_source)}\n\{view_source}\n\{tonemapping_shared_source}\n\{main_source}",
    fullscreen_source,
  )
  preprocess_manual_wgsl_source(backend, merged_source, define_keys, [
    ("TONEMAPPING_LUT_TEXTURE_BINDING_INDEX", 3),
    ("TONEMAPPING_LUT_SAMPLER_BINDING_INDEX", 4),
  ])
}

///|
fn ensure_tonemapping_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  if backend.tonemapping_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        frag,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=true,
      ) &&
      builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(2U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      ) &&
      builder.add_sampler(4U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build tonemapping bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_tonemapping_bind_group_layout",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_tonemapping_pipeline_layout")
    backend.tonemapping_bgl = Some(bgl)
    backend.tonemapping_pipeline_layout = Some(pipeline_layout)
  }
  if backend.tonemapping_view_buf is None {
    let usage = bu(
      @wgpu.BUFFER_USAGE_UNIFORM |
      @wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_COPY_DST,
    )
    backend.tonemapping_view_buf = Some(
      backend.device.create_buffer(size=MESH2D_VIEW_BUFFER_SIZE, usage~),
    )
  }
  if backend.tonemapping_sampler is None {
    backend.tonemapping_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
}

///|
fn tonemapping_pipeline_for_format(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  tonemapping_mode : Int,
  deband_dither : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_tonemapping_resources(backend)
  let key = tonemapping_pipeline_cache_key(
    format, tonemapping_mode, deband_dither,
  )
  for entry in backend.tonemapping_pipeline_cache {
    if entry.key == key {
      return Some(entry.pipeline)
    }
  }
  guard backend.tonemapping_pipeline_layout is Some(pipeline_layout) else {
    return None
  }
  let source = load_fullscreen_tonemapping_wgsl_with_defines_required(
    backend,
    tonemapping_pipeline_define_keys(tonemapping_mode, deband_dither),
  )
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    format,
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_tonemapping_\{key}",
  )
  backend.tonemapping_pipeline_cache.push(TonemappingPipelineCacheEntry::{
    key,
    pipeline,
  })
  Some(pipeline)
}

///|
fn ensure_tonemapping_fallback_lut_view(
  backend : GpuBackend,
) -> @wgpu.TextureView raise GpuBackendError {
  if backend.tonemapping_fallback_lut_texture_id > 0 {
    if find_texture(backend, backend.tonemapping_fallback_lut_texture_id)
      is Some(texture) {
      return texture.view
    }
    backend.tonemapping_fallback_lut_texture_id = -1
  }
  let bytes = Bytes::makei(4, _ => (255).to_byte())
  let texture_id = backend.create_texture_3d_with_format(
    1,
    1,
    1,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    [bytes],
  )
  backend.tonemapping_fallback_lut_texture_id = texture_id
  if find_texture(backend, texture_id) is Some(texture) {
    texture.view
  } else {
    fatal(
      "wgpu: tonemapping fallback LUT texture missing after creation (id=\{texture_id})",
    )
  }
}

///|
fn tonemapping_selected_lut_view(
  backend : GpuBackend,
  tonemapping_mode : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
) -> @wgpu.TextureView raise GpuBackendError {
  let selected_lut_texture_id = if tonemapping_mode == 4 {
    agx_lut_texture_id
  } else if tonemapping_mode == 6 {
    tony_lut_texture_id
  } else if tonemapping_mode == 7 {
    blender_lut_texture_id
  } else {
    -1
  }
  if selected_lut_texture_id >= 0 {
    if find_texture(backend, selected_lut_texture_id) is Some(lut_texture) {
      return lut_texture.view
    }
  }
  if agx_lut_texture_id >= 0 {
    if find_texture(backend, agx_lut_texture_id) is Some(lut_texture) {
      return lut_texture.view
    }
  }
  if tony_lut_texture_id >= 0 {
    if find_texture(backend, tony_lut_texture_id) is Some(lut_texture) {
      return lut_texture.view
    }
  }
  if blender_lut_texture_id >= 0 {
    if find_texture(backend, blender_lut_texture_id) is Some(lut_texture) {
      return lut_texture.view
    }
  }
  ensure_tonemapping_fallback_lut_view(backend)
}
