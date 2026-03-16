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
fn GpuBackend::draw_postprocess3d_fullscreen(
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
  guard tonemapping2d_pipeline_for_format(
      self, format, tonemapping_mode, deband_dither,
    )
    is Some(final_pipeline) else {
    return
  }
  guard self.tonemapping2d_bgl is Some(final_bind_layout) else { return }
  guard self.tonemapping2d_view_buf is Some(view_buf) else { return }
  guard self.tonemapping2d_sampler is Some(tonemapping_sampler) else { return }
  let selected_lut_view = tonemapping_selected_lut_view(
    self, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  let exposure_value = clamp_non_negative(exposure)
  fxaa_enabled |> ignore
  fxaa_edge_threshold |> ignore
  chromatic_aberration |> ignore
  vignette |> ignore
  view_width |> ignore
  view_height |> ignore
  let view_uniform = tonemapping_view_uniform_bytes_full(
    pass_state,
    exposure_value,
    self.frame_count,
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
  self.queue.write_buffer(view_buf, 0UL, view_uniform)

  active_pass.end()
  active_pass.release()
  frame.pass = None

  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_BEVY_VIEW_BUFFER_SIZE) &&
      builder.add_texture_view(1U, scene_texture.view) &&
      builder.add_sampler(2U, tonemapping_sampler) &&
      builder.add_texture_view(3U, selected_lut_view) &&
      builder.add_sampler(4U, tonemapping_sampler)
    if ok {
      let final_bg = builder.finish(
        self.device,
        final_bind_layout,
        label="mgstudio_postprocess3d_tonemapping_bg",
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
  fxaa_enabled : Int,
  fxaa_edge_threshold : Float,
  fxaa_edge_threshold_min : Float,
  chromatic_aberration_intensity : Float,
  chromatic_aberration_max_samples : Int,
  vignette_intensity : Float,
  vignette_radius : Float,
  vignette_smoothness : Float,
  vignette_roundness : Float,
  vignette_center_x : Float,
  vignette_center_y : Float,
  vignette_edge_compensation : Float,
  vignette_color_r : Float,
  vignette_color_g : Float,
  vignette_color_b : Float,
  vignette_color_a : Float,
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
  fxaa_enabled |> ignore
  fxaa_edge_threshold |> ignore
  fxaa_edge_threshold_min |> ignore
  chromatic_aberration_intensity |> ignore
  chromatic_aberration_max_samples |> ignore
  vignette_intensity |> ignore
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
  self.draw_postprocess3d_fullscreen(
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
    color_grading_hue, color_grading_post_saturation, 0, 0.0F, 0.0F, 0.0F,
  )
}

///|
pub fn draw_tonemapping3d(
  scene_texture_id~ : Int,
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
      scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, fxaa_enabled,
      fxaa_edge_threshold, fxaa_edge_threshold_min, chromatic_aberration_intensity,
      chromatic_aberration_max_samples, vignette_intensity, vignette_radius, vignette_smoothness,
      vignette_roundness, vignette_center_x, vignette_center_y, vignette_edge_compensation,
      vignette_color_r, vignette_color_g, vignette_color_b, vignette_color_a, view_width,
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
