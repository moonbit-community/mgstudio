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
/// 2D post-processing entry points (bloom / tonemapping) split from gpu.mbt for module boundary alignment.
pub fn GpuBackend::apply_bloom2d(
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
  view_width : Int,
  view_height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  guard self.bloom2d_intermediate_bgl is Some(intermediate_bind_layout) else {
    return
  }
  guard self.bloom2d_settings_buf is Some(settings_buf) else { return }
  guard self.bloom2d_sampler is Some(bloom_sampler) else { return }
  if scene_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  guard bloom2d_final_composite_pipeline_for_scene_texture(
      self, scene_texture_id, composite_mode,
    )
    is Some(final_pipeline) else {
    return
  }
  let source_viewport_x = Float::from_double(pass_state.viewport_x.to_double())
  let source_viewport_y = Float::from_double(pass_state.viewport_y.to_double())
  let source_viewport_width = Float::from_double(
    pass_state.viewport_w.to_double(),
  )
  let source_viewport_height = Float::from_double(
    pass_state.viewport_h.to_double(),
  )
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
  let use_uniform_scale = scale_x_value == 1.0F && scale_y_value == 1.0F
  let use_prefilter = threshold_value > 0.0F
  let bloom_enabled = enabled != 0
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
        source_viewport_x,
        source_viewport_y,
        source_viewport_width,
        source_viewport_height,
        threshold_value,
        threshold_softness_value,
        scale_x_value,
        scale_y_value,
        1.0F,
        0.0F,
        0.125F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        1.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        1.0F,
        0.0F,
        0.0F,
        1.0F,
        0.0F,
        1.0F,
        1.0F,
        1.0F,
        1.0F,
        1.0F,
        1.0F,
        1.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        1.0F,
        0.0F,
        1.0F,
        0.0F,
        1.0F,
      )
      self.queue.write_buffer(settings_buf, 0UL, bloom_uniform)
      if create_bloom2d_intermediate_bind_group(
          self,
          intermediate_bind_layout,
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
          if create_bloom2d_intermediate_bind_group(
              self,
              intermediate_bind_layout,
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
            source_viewport_x,
            source_viewport_y,
            source_viewport_width,
            source_viewport_height,
            threshold_value,
            threshold_softness_value,
            scale_x_value,
            scale_y_value,
            1.0F,
            0.0F,
            0.125F,
            0.0F,
            0.0F,
            0.0F,
            blend,
            0.0F,
            1.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            1.0F,
            0.0F,
            0.0F,
            1.0F,
            0.0F,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            0.0F,
            1.0F,
            0.0F,
            1.0F,
            0.0F,
            1.0F,
          )
          self.queue.write_buffer(settings_buf, 0UL, upsample_uniform)
          if create_bloom2d_intermediate_bind_group(
              self,
              intermediate_bind_layout,
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
            pass.set_blend_constant_rgba(
              blend.to_double(),
              blend.to_double(),
              blend.to_double(),
              1.0,
            )
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

  if bloom_ready &&
    create_bloom2d_intermediate_bind_group(
      self,
      intermediate_bind_layout,
      self.bloom2d_mip_views[0],
      bloom_sampler,
      settings_buf,
      "mgstudio_bloom2d_upsample_final_bg",
    )
    is Some(final_bg) {
    let final_blend = bloom2d_compute_blend_factor(
      intensity_value, low_frequency_boost_value, low_frequency_boost_curvature_value,
      high_pass_frequency_value, composite_mode, 0.0F, max_mip_f,
    )
    let final_uniform = bloom2d_uniform_bytes(
      Float::from_double(safe_scene_width.to_double()),
      Float::from_double(safe_scene_height.to_double()),
      source_viewport_x,
      source_viewport_y,
      source_viewport_width,
      source_viewport_height,
      0.0F,
      0.0F,
      1.0F,
      1.0F,
      1.0F,
      0.0F,
      0.125F,
      0.0F,
      0.0F,
      0.0F,
      final_blend,
      0.0F,
      1.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      1.0F,
      0.0F,
      0.0F,
      1.0F,
      0.0F,
      1.0F,
      1.0F,
      1.0F,
      1.0F,
      1.0F,
      1.0F,
      1.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      0.0F,
      1.0F,
      0.0F,
      1.0F,
      0.0F,
      1.0F,
    )
    self.queue.write_buffer(settings_buf, 0UL, final_uniform)
    let final_pass = frame.encoder.begin_render_pass_color_load(
      scene_texture.view,
    )
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
    final_pass.set_blend_constant_rgba(
      final_blend.to_double(),
      final_blend.to_double(),
      final_blend.to_double(),
      1.0,
    )
    final_pass.draw(3U, 1U, 0U, 0U)
    final_pass.end()
    final_pass.release()
    final_bg.release()
  }
  reopen_saved_pass(self, pass_state)
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
  color_grading_balance_x_axis_x |> ignore
  color_grading_balance_x_axis_y |> ignore
  color_grading_balance_x_axis_z |> ignore
  color_grading_balance_y_axis_x |> ignore
  color_grading_balance_y_axis_y |> ignore
  color_grading_balance_y_axis_z |> ignore
  color_grading_balance_z_axis_x |> ignore
  color_grading_balance_z_axis_y |> ignore
  color_grading_balance_z_axis_z |> ignore
  color_grading_saturation_shadows |> ignore
  color_grading_saturation_midtones |> ignore
  color_grading_saturation_highlights |> ignore
  color_grading_contrast_shadows |> ignore
  color_grading_contrast_midtones |> ignore
  color_grading_contrast_highlights |> ignore
  color_grading_gamma_shadows |> ignore
  color_grading_gamma_midtones |> ignore
  color_grading_gamma_highlights |> ignore
  color_grading_gain_shadows |> ignore
  color_grading_gain_midtones |> ignore
  color_grading_gain_highlights |> ignore
  color_grading_lift_shadows |> ignore
  color_grading_lift_midtones |> ignore
  color_grading_lift_highlights |> ignore
  color_grading_midtones_start |> ignore
  color_grading_midtones_end |> ignore
  color_grading_exposure |> ignore
  color_grading_hue |> ignore
  color_grading_post_saturation |> ignore
  fxaa_enabled |> ignore
  fxaa_edge_threshold |> ignore
  chromatic_aberration |> ignore
  vignette |> ignore
  self.apply_bloom2d(
    scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
    high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
    scale_x, scale_y, view_width, view_height,
  )
  self.draw_tonemapping2d(
    scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
    view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
}

///|
pub fn apply_bloom2d(
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
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.apply_bloom2d(
      scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
      high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
      scale_x, scale_y, view_width, view_height,
    ) catch {
      err => debug_runtime_error("apply_bloom2d", err)
    }
  }
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
      color_grading_balance_x_axis_x, color_grading_balance_x_axis_y, color_grading_balance_x_axis_z,
      color_grading_balance_y_axis_x, color_grading_balance_y_axis_y, color_grading_balance_y_axis_z,
      color_grading_balance_z_axis_x, color_grading_balance_z_axis_y, color_grading_balance_z_axis_z,
      color_grading_saturation_shadows, color_grading_saturation_midtones, color_grading_saturation_highlights,
      color_grading_contrast_shadows, color_grading_contrast_midtones, color_grading_contrast_highlights,
      color_grading_gamma_shadows, color_grading_gamma_midtones, color_grading_gamma_highlights,
      color_grading_gain_shadows, color_grading_gain_midtones, color_grading_gain_highlights,
      color_grading_lift_shadows, color_grading_lift_midtones, color_grading_lift_highlights,
      color_grading_midtones_start, color_grading_midtones_end, color_grading_exposure,
      color_grading_hue, color_grading_post_saturation, fxaa_enabled, fxaa_edge_threshold_value,
      chromatic_aberration_value, vignette_value,
    ) catch {
      err => debug_runtime_error("draw_bloom2d", err)
    }
  }
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
  let mip_ratio = mip / safe_max_mip
  let lf_pow = Float::from_double(
    @coremath.pow(
      (1.0F - mip_ratio).to_double(),
      (1.0F / (1.0F - low_frequency_boost_curvature)).to_double(),
    ),
  )
  let mut low_freq = (1.0F - lf_pow) * low_frequency_boost
  let high_pass_lq = 1.0F -
    clamp01((mip_ratio - high_pass_frequency) / high_pass_frequency)
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
    color_grading_balance_x_axis_x,
    color_grading_balance_x_axis_y,
    color_grading_balance_x_axis_z,
    0.0F,
    color_grading_balance_y_axis_x,
    color_grading_balance_y_axis_y,
    color_grading_balance_y_axis_z,
    0.0F,
    color_grading_balance_z_axis_x,
    color_grading_balance_z_axis_y,
    color_grading_balance_z_axis_z,
    0.0F,
    color_grading_saturation_shadows,
    color_grading_saturation_midtones,
    color_grading_saturation_highlights,
    0.0F,
    color_grading_contrast_shadows,
    color_grading_contrast_midtones,
    color_grading_contrast_highlights,
    0.0F,
    color_grading_gamma_shadows,
    color_grading_gamma_midtones,
    color_grading_gamma_highlights,
    0.0F,
    color_grading_gain_shadows,
    color_grading_gain_midtones,
    color_grading_gain_highlights,
    0.0F,
    color_grading_lift_shadows,
    color_grading_lift_midtones,
    color_grading_lift_highlights,
    0.0F,
    color_grading_midtones_start,
    color_grading_midtones_end,
    color_grading_exposure,
    color_grading_hue,
    color_grading_post_saturation,
    0.0F,
    0.0F,
    0.0F,
  ])
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
fn ensure_bloom2d_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.bloom2d_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.bloom2d_settings_buf = Some(
      backend.device.create_buffer(size=BLOOM2D_UNIFORM_BUFFER_SIZE, usage~),
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
    let downsample_first_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "USE_THRESHOLD"],
    )
    let downsample_first_no_threshold_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      ["FIRST_DOWNSAMPLE"],
    )
    let downsample_first_uniform_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "USE_THRESHOLD", "UNIFORM_SCALE"],
    )
    let downsample_first_no_threshold_uniform_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      ["FIRST_DOWNSAMPLE", "UNIFORM_SCALE"],
    )
    let downsample_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      [],
    )
    let downsample_uniform_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      ["UNIFORM_SCALE"],
    )
    let upsample_source = load_fullscreen_postprocess_wgsl_with_defines_required(
      "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
      [],
    )
    let downsample_first_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_source,
      mip_format,
      "downsample_first",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first",
    )
    let downsample_first_no_threshold_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_no_threshold_source,
      mip_format,
      "downsample_first",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_no_threshold",
    )
    let downsample_first_uniform_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_uniform_source,
      mip_format,
      "downsample_first",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_uniform",
    )
    let downsample_first_no_threshold_uniform_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_no_threshold_uniform_source,
      mip_format,
      "downsample_first",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_no_threshold_uniform",
    )
    let downsample_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_source,
      mip_format,
      "downsample",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample",
    )
    let downsample_uniform_pipeline = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_uniform_source,
      mip_format,
      "downsample",
      POSTPROCESS_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_uniform",
    )
    let upsample_pipeline_energy = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      upsample_source,
      mip_format,
      "upsample",
      POSTPROCESS_BLEND_MODE_CONSTANT_ENERGY,
      "mgstudio_bloom2d_upsample_energy",
    )
    let upsample_pipeline_additive = create_postprocess_pipeline(
      backend,
      intermediate_pipeline_layout,
      upsample_source,
      mip_format,
      "upsample",
      POSTPROCESS_BLEND_MODE_CONSTANT_ADDITIVE,
      "mgstudio_bloom2d_upsample_additive",
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
}

///|
fn ensure_bloom2d_final_composite_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_bloom2d_pipeline_rgba8(backend)
  if backend.bloom2d_upsample_final_pipeline_format is Some(prev) &&
    prev == format &&
    backend.bloom2d_upsample_final_pipeline_energy is Some(_) &&
    backend.bloom2d_upsample_final_pipeline_additive is Some(_) {
    return
  }
  if backend.bloom2d_upsample_final_pipeline_energy is Some(old) {
    old.release()
  }
  if backend.bloom2d_upsample_final_pipeline_additive is Some(old) {
    old.release()
  }
  guard backend.bloom2d_intermediate_pipeline_layout
    is Some(intermediate_pipeline_layout) else {
    return
  }
  let upsample_source = load_fullscreen_postprocess_wgsl_with_defines_required(
    "shaders/bevy/bevy_post_process/bloom/bloom.wgsl",
    [],
  )
  let energy_pipeline = create_postprocess_pipeline(
    backend,
    intermediate_pipeline_layout,
    upsample_source,
    format,
    "upsample",
    POSTPROCESS_BLEND_MODE_CONSTANT_ENERGY,
    "mgstudio_bloom2d_upsample_final_energy",
  )
  let additive_pipeline = create_postprocess_pipeline(
    backend,
    intermediate_pipeline_layout,
    upsample_source,
    format,
    "upsample",
    POSTPROCESS_BLEND_MODE_CONSTANT_ADDITIVE,
    "mgstudio_bloom2d_upsample_final_additive",
  )
  backend.bloom2d_upsample_final_pipeline_energy = Some(energy_pipeline)
  backend.bloom2d_upsample_final_pipeline_additive = Some(additive_pipeline)
  backend.bloom2d_upsample_final_pipeline_format = Some(format)
}

///|
fn bloom2d_final_composite_pipeline_for_scene_texture(
  backend : GpuBackend,
  scene_texture_id : Int,
  composite_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  guard find_texture(backend, scene_texture_id) is Some(scene_texture) else {
    return None
  }
  bloom2d_final_composite_pipeline_for_format(
    backend,
    composite_mode,
    tf(scene_texture.format_raw),
  )
}

///|
fn bloom2d_final_composite_pipeline_for_format(
  backend : GpuBackend,
  composite_mode : Int,
  format : @wgpu.TextureFormat,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_bloom2d_final_composite_pipeline(backend, format)
  if composite_mode == 0 {
    backend.bloom2d_upsample_final_pipeline_energy
  } else {
    backend.bloom2d_upsample_final_pipeline_additive
  }
}
