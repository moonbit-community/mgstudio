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
  let source_viewport_x = Float::from_double(pass_state.viewport_x.to_double())
  let source_viewport_y = Float::from_double(pass_state.viewport_y.to_double())
  let source_viewport_width = Float::from_double(
    pass_state.viewport_w.to_double(),
  )
  let source_viewport_height = Float::from_double(
    pass_state.viewport_h.to_double(),
  )
  let selected_lut_view = bloom2d_selected_lut_view(
    self, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
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
  view_width |> ignore
  view_height |> ignore

  active_pass.end()
  active_pass.release()
  frame.pass = None

  let final_uniform = bloom2d_uniform_bytes(
    Float::from_double(safe_scene_width.to_double()),
    Float::from_double(safe_scene_height.to_double()),
    source_viewport_x,
    source_viewport_y,
    source_viewport_width,
    source_viewport_height,
    0.0F, // threshold
    0.0F, // threshold_softness
    1.0F, // scale_x
    1.0F, // scale_y
    exposure_value,
    0.0F, // fxaa_enabled
    0.125F, // fxaa_edge_threshold
    tonemapping_mode_value,
    deband_dither_enabled_value,
    0.0F, // bloom_weight
    0.0F, // upsample_blend
    0.0F, // chromatic_aberration
    0.0F, // vignette
    1.0F, // color_grading_balance_x_axis_x
    0.0F, // color_grading_balance_x_axis_y
    0.0F, // color_grading_balance_x_axis_z
    0.0F, // color_grading_balance_y_axis_x
    1.0F, // color_grading_balance_y_axis_y
    0.0F, // color_grading_balance_y_axis_z
    0.0F, // color_grading_balance_z_axis_x
    0.0F, // color_grading_balance_z_axis_y
    1.0F, // color_grading_balance_z_axis_z
    1.0F, // color_grading_saturation_shadows
    1.0F, // color_grading_saturation_midtones
    1.0F, // color_grading_saturation_highlights
    1.0F, // color_grading_contrast_shadows
    1.0F, // color_grading_contrast_midtones
    1.0F, // color_grading_contrast_highlights
    1.0F, // color_grading_gamma_shadows
    1.0F, // color_grading_gamma_midtones
    1.0F, // color_grading_gamma_highlights
    1.0F, // color_grading_gain_shadows
    1.0F, // color_grading_gain_midtones
    1.0F, // color_grading_gain_highlights
    0.0F, // color_grading_lift_shadows
    0.0F, // color_grading_lift_midtones
    0.0F, // color_grading_lift_highlights
    0.2F, // color_grading_midtones_start
    0.7F, // color_grading_midtones_end
    0.0F, // color_grading_exposure
    0.0F, // color_grading_hue
    1.0F, // color_grading_post_saturation
  )
  self.queue.write_buffer(settings_buf, 0UL, final_uniform)
  let auto_exposure_state_buf = bloom2d_auto_exposure_state_buffer(self)
  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    if create_bloom2d_final_bind_group(
        self,
        final_bind_layout,
        scene_texture.view,
        bloom_sampler,
        settings_buf,
        scene_texture.view,
        selected_lut_view,
        auto_exposure_state_buf,
        "mgstudio_tonemapping2d_final_bg",
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
  let source_viewport_x = Float::from_double(pass_state.viewport_x.to_double())
  let source_viewport_y = Float::from_double(pass_state.viewport_y.to_double())
  let source_viewport_width = Float::from_double(
    pass_state.viewport_w.to_double(),
  )
  let source_viewport_height = Float::from_double(
    pass_state.viewport_h.to_double(),
  )
  let selected_lut_view = bloom2d_selected_lut_view(
    self, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
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
        source_viewport_x,
        source_viewport_y,
        source_viewport_width,
        source_viewport_height,
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
            source_viewport_x,
            source_viewport_y,
            source_viewport_width,
            source_viewport_height,
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
    source_viewport_x,
    source_viewport_y,
    source_viewport_width,
    source_viewport_height,
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
  self.queue.write_buffer(settings_buf, 0UL, final_uniform)
  let auto_exposure_state_buf = bloom2d_auto_exposure_state_buffer(self)

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
        auto_exposure_state_buf,
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
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_tonemapping2d(
      scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
      view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
    ) catch {
      err => debug_runtime_error("draw_tonemapping2d", err)
    }
  }
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
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(base)
  load_wgsl_preprocessed(
    base, normalized_rel, defines, value_defines, visited, modules,
  )
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
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
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
        @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      ) &&
      builder.add_buffer(5U, frag, @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE)
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
const BLOOM2D_BLEND_MODE_NONE : Int = 0

///|
const BLOOM2D_BLEND_MODE_CONSTANT_ENERGY : Int = 2

///|
const BLOOM2D_BLEND_MODE_CONSTANT_ADDITIVE : Int = 3

///|
fn bloom2d_builder_set_blend_mode(
  builder : @wgpu.RenderPipelineDescBuilder,
  blend_mode : Int,
) -> Unit raise GpuBackendError {
  if blend_mode == BLOOM2D_BLEND_MODE_NONE {
    return
  }
  let (color_src, color_dst) = if blend_mode ==
    BLOOM2D_BLEND_MODE_CONSTANT_ENERGY {
    (@wgpu.BLEND_FACTOR_CONSTANT, @wgpu.BLEND_FACTOR_ONE_MINUS_CONSTANT)
  } else if blend_mode == BLOOM2D_BLEND_MODE_CONSTANT_ADDITIVE {
    (@wgpu.BLEND_FACTOR_CONSTANT, @wgpu.BLEND_FACTOR_ONE)
  } else {
    fatal("wgpu: unsupported bloom blend mode: " + blend_mode.to_string())
  }
  builder.set_blend_components(
    color_src,
    color_dst,
    @wgpu.BLEND_OPERATION_ADD,
    @wgpu.BLEND_FACTOR_ZERO,
    @wgpu.BLEND_FACTOR_ONE,
    @wgpu.BLEND_OPERATION_ADD,
  ) catch {
    err => {
      err |> ignore
      fatal("wgpu: failed to configure bloom custom blend state")
    }
  }
}

///|
fn bloom2d_create_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  source : String,
  format : @wgpu.TextureFormat,
  fs_entry : String,
  blend_mode : Int,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let sm = backend.device.create_shader_module_wgsl(source)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("fullscreen_vertex_shader", fs_entry)
    builder.set_color_target_format(format)
    bloom2d_builder_set_blend_mode(builder, blend_mode)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build bloom pipeline descriptor")
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
  auto_exposure_state_buf : @wgpu.Buffer,
  label : String,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let debug_postprocess = match @sys.get_env_var("MGSTUDIO_POSTPROCESS_DEBUG") {
    Some(raw) => raw.trim().to_string() == "1"
    _ => false
  }
  let ok0 = builder.add_texture_view(0U, input_view)
  let ok1 = builder.add_sampler(1U, sampler)
  let ok2 = builder.add_buffer(2U, settings_buf)
  let ok3 = builder.add_texture_view(3U, scene_view)
  let ok4 = builder.add_texture_view(4U, lut_view)
  let ok5 = builder.add_buffer(5U, auto_exposure_state_buf)
  if !ok0 || !ok1 || !ok2 || !ok3 || !ok4 || !ok5 {
    if debug_postprocess {
      let failed_index = if !ok0 {
        0
      } else if !ok1 {
        1
      } else if !ok2 {
        2
      } else if !ok3 {
        3
      } else if !ok4 {
        4
      } else {
        5
      }
      println(
        "[postprocess] final bind group build failed: label=\{label}, failed_binding=\{failed_index}",
      )
    }
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
      backend,
      intermediate_pipeline_layout,
      downsample_first_source,
      mip_format,
      "downsample_first",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first",
    )
    let downsample_first_no_threshold_pipeline = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_no_threshold_source,
      mip_format,
      "downsample_first",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_no_threshold",
    )
    let downsample_first_uniform_pipeline = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_uniform_source,
      mip_format,
      "downsample_first",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_uniform",
    )
    let downsample_first_no_threshold_uniform_pipeline = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_first_no_threshold_uniform_source,
      mip_format,
      "downsample_first",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_first_no_threshold_uniform",
    )
    let downsample_pipeline = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_source,
      mip_format,
      "downsample",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample",
    )
    let downsample_uniform_pipeline = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      downsample_uniform_source,
      mip_format,
      "downsample",
      BLOOM2D_BLEND_MODE_NONE,
      "mgstudio_bloom2d_downsample_uniform",
    )
    let upsample_pipeline_energy = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      upsample_source,
      mip_format,
      "upsample",
      BLOOM2D_BLEND_MODE_CONSTANT_ENERGY,
      "mgstudio_bloom2d_upsample_energy",
    )
    let upsample_pipeline_additive = bloom2d_create_pipeline(
      backend,
      intermediate_pipeline_layout,
      upsample_source,
      mip_format,
      "upsample",
      BLOOM2D_BLEND_MODE_CONSTANT_ADDITIVE,
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
    BLOOM2D_BLEND_MODE_NONE,
    "mgstudio_bloom2d_final_rgba8",
  )
  backend.bloom2d_final_pipeline = Some(final_pipeline)
}

///|
fn ensure_bloom2d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_bloom2d_pipeline_rgba8(backend)
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
    backend,
    final_pipeline_layout,
    final_source,
    format,
    "final_fragment",
    BLOOM2D_BLEND_MODE_NONE,
    "mgstudio_bloom2d_final_surface",
  )
  backend.bloom2d_final_pipeline_surface = Some(final_pipeline)
  backend.bloom2d_final_pipeline_surface_format = Some(format)
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
  let upsample_source = load_wgsl_with_defines_required(
    backend,
    "shaders/mgstudio/2d/bloom.wgsl",
    [],
  )
  let energy_pipeline = bloom2d_create_pipeline(
    backend,
    intermediate_pipeline_layout,
    upsample_source,
    format,
    "upsample",
    BLOOM2D_BLEND_MODE_CONSTANT_ENERGY,
    "mgstudio_bloom2d_upsample_final_energy",
  )
  let additive_pipeline = bloom2d_create_pipeline(
    backend,
    intermediate_pipeline_layout,
    upsample_source,
    format,
    "upsample",
    BLOOM2D_BLEND_MODE_CONSTANT_ADDITIVE,
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

///|
fn bloom2d_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_bloom2d_pipeline_surface(backend, format)
      return backend.bloom2d_final_pipeline_surface
    }
    _ => ()
  }
  ensure_bloom2d_pipeline_rgba8(backend)
  backend.bloom2d_final_pipeline
}

///|
fn ensure_bloom2d_fallback_lut_view(
  backend : GpuBackend,
) -> @wgpu.TextureView raise GpuBackendError {
  if backend.bloom2d_fallback_lut_texture_id > 0 {
    if find_texture(backend, backend.bloom2d_fallback_lut_texture_id)
      is Some(texture) {
      return texture.view
    }
    backend.bloom2d_fallback_lut_texture_id = -1
  }
  let bytes = Bytes::makei(4, _ => (255).to_byte())
  let texture_id = backend.create_texture_3d_with_format(
    1,
    1,
    1,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    [bytes],
  )
  backend.bloom2d_fallback_lut_texture_id = texture_id
  if find_texture(backend, texture_id) is Some(texture) {
    texture.view
  } else {
    fatal(
      "wgpu: bloom2d fallback LUT texture missing after creation (id=\{texture_id})",
    )
  }
}

///|
fn bloom2d_selected_lut_view(
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
  ensure_bloom2d_fallback_lut_view(backend)
}

///|
fn find_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo? {
  for t in backend.textures {
    if t.id == id {
      return Some(t)
    }
  }
  None
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
    backend.textures.push(info)
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
fn gpu_mesh_bind_index_buffer(
  pass : @wgpu.RenderPass,
  mesh : GpuMeshInfo,
) -> Unit {
  let index_bytes = mesh.index_count.reinterpret_as_int().to_uint64() *
    mesh.index_stride_bytes
  if mesh.uses_u32_indices {
    pass.set_index_buffer_u32(mesh.index_buf, 0UL, index_bytes)
  } else {
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  }
}

///|
fn find_mesh(backend : GpuBackend, id : Int) -> GpuMeshInfo? {
  for m in backend.meshes {
    if m.id == id {
      return Some(m)
    }
  }
  None
}

///|
