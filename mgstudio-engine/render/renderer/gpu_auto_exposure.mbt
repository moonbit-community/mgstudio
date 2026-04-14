// Copyright 2026 International Digital Economy Academy
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
const AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT : UInt64 = 64UL

///|
const AUTO_EXPOSURE_SETTINGS_BUFFER_SIZE : UInt64 = 48UL

///|
const AUTO_EXPOSURE_CURVE_EXTENTS_BUFFER_SIZE : UInt64 = 16UL

///|
const AUTO_EXPOSURE_CURVE_LUT_WIDTH : Int = 256

///|
struct GpuAutoExposureViewState {
  key_hi : Int
  key_lo : Int
  state_buf : @wgpu.Buffer
}

///|
fn ensure_auto_exposure_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.auto_exposure_compute_bgl is None {
    let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=9UL)
    let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      builder.add_texture(
        2U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        3U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        4U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_1D,
      ) &&
      builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(7U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build auto exposure compute bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_auto_exposure_compute_bgl",
    )
    let pl = backend.device.create_pipeline_layout_1(bgl)
    pl.set_label("mgstudio_auto_exposure_compute_pipeline_layout")
    backend.auto_exposure_compute_bgl = Some(bgl)
    backend.auto_exposure_compute_pipeline_layout = Some(pl)
  }
  if backend.auto_exposure_globals_buf is None {
    backend.auto_exposure_globals_buf = Some(
      backend.device.create_buffer(
        size=16UL,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
  if backend.auto_exposure_settings_buf is None {
    backend.auto_exposure_settings_buf = Some(
      backend.device.create_buffer(
        size=AUTO_EXPOSURE_SETTINGS_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
  if backend.auto_exposure_curve_extents_buf is None {
    backend.auto_exposure_curve_extents_buf = Some(
      backend.device.create_buffer(
        size=AUTO_EXPOSURE_CURVE_EXTENTS_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
  if backend.auto_exposure_histogram_buf is None {
    backend.auto_exposure_histogram_buf = Some(
      backend.device.create_buffer(
        size=AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT * 4UL,
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.queue.write_buffer(
      backend.auto_exposure_histogram_buf.unwrap(),
      0UL,
      Bytes::makei(AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT.to_int() * 4, _ => 0),
    )
  }
  if backend.auto_exposure_curve_texture is None ||
    backend.auto_exposure_curve_view is None {
    let texture = backend.device.create_texture_u32(
      AUTO_EXPOSURE_CURVE_LUT_WIDTH.reinterpret_as_uint(),
      1U,
      1U,
      @wgpu.TextureUsage::from_u64(
        @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_COPY_DST,
      ),
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_1D),
      tf(@wgpu.TEXTURE_FORMAT_R8_UNORM),
    )
    let view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_R8_UNORM),
      @wgpu.TEXTURE_VIEW_DIMENSION_1D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      1U,
    )
    view.set_label("mgstudio_auto_exposure_curve_view")
    backend.auto_exposure_curve_texture = Some(texture)
    backend.auto_exposure_curve_view = Some(view)
  }
  if backend.auto_exposure_histogram_pipeline is None {
    guard backend.auto_exposure_compute_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_from_assets_required(
      backend, "post_process/auto_exposure/auto_exposure.wgsl",
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "compute_histogram",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create auto exposure histogram pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_auto_exposure_histogram")
    backend.auto_exposure_histogram_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.auto_exposure_average_pipeline is None {
    guard backend.auto_exposure_compute_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_from_assets_required(
      backend, "post_process/auto_exposure/auto_exposure.wgsl",
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "compute_average",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create auto exposure average pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_auto_exposure_average")
    backend.auto_exposure_average_pipeline = Some(pipeline)
    shader.release()
  }
}

///|
fn auto_exposure_settings_bytes(
  min_ev100 : Float,
  max_ev100 : Float,
  low_percent : Float,
  high_percent : Float,
  speed_brighten : Float,
  speed_darken : Float,
  exponential_transition_distance : Float,
  delta_time : Float,
) -> Bytes {
  let safe_min = if min_ev100 < max_ev100 { min_ev100 } else { max_ev100 }
  let safe_max = if max_ev100 > safe_min { max_ev100 } else { safe_min + 0.01F }
  let log_range = safe_max - safe_min
  let safe_low = if low_percent < 0.0F {
    0.0F
  } else if low_percent > 1.0F {
    1.0F
  } else {
    low_percent
  }
  let safe_high = if high_percent < safe_low {
    safe_low
  } else if high_percent > 1.0F {
    1.0F
  } else {
    high_percent
  }
  f32le_pack([
    safe_min,
    1.0F / log_range,
    log_range,
    safe_low,
    safe_high,
    if speed_brighten < 0.0F {
      0.0F
    } else {
      speed_brighten
    },
    if speed_darken < 0.0F {
      0.0F
    } else {
      speed_darken
    },
    if exponential_transition_distance <= 0.0F {
      0.0001F
    } else {
      exponential_transition_distance
    },
    if delta_time < 0.0F {
      0.0F
    } else {
      delta_time
    },
    0.0F,
    0.0F,
    0.0F,
  ])
}

///|
fn auto_exposure_globals_bytes(frame_count : UInt, delta_time : Float) -> Bytes {
  u32le_pack([
    f32_bits(0.0F),
    f32_bits(if delta_time < 0.0F { 0.0F } else { delta_time }),
    frame_count,
    0U,
  ])
}

///|
fn auto_exposure_curve_extents_bytes(
  min_log_lum : Float,
  max_log_lum : Float,
  min_compensation : Float,
  max_compensation : Float,
) -> Bytes {
  let log_range = max_log_lum - min_log_lum
  f32le_pack([
    min_log_lum,
    if log_range <= 0.0F {
      0.0F
    } else {
      1.0F / log_range
    },
    min_compensation,
    max_compensation - min_compensation,
  ])
}

///|
fn auto_exposure_upload_curve_lut(
  backend : GpuBackend,
  lut : Bytes,
) -> Unit raise GpuBackendError {
  ensure_auto_exposure_resources(backend)
  guard backend.auto_exposure_curve_texture is Some(texture) else { return }
  let upload = if lut.length() == AUTO_EXPOSURE_CURVE_LUT_WIDTH {
    lut
  } else {
    Bytes::makei(AUTO_EXPOSURE_CURVE_LUT_WIDTH, index => {
      match lut.get(index) {
        Some(value) => value
        None => 0
      }
    })
  }
  let tex_info = @wgpu_c.texel_copy_texture_info_new(
    texture.raw_handle(),
    0U,
    0U,
    0U,
    0U,
  )
  let layout = @wgpu_c.texel_copy_buffer_layout_new(
    0UL,
    AUTO_EXPOSURE_CURVE_LUT_WIDTH.reinterpret_as_uint(),
    1U,
  )
  let extent = @wgpu_c.extent3d_new(
    AUTO_EXPOSURE_CURVE_LUT_WIDTH.reinterpret_as_uint(),
    1U,
    1U,
  )
  backend.queue.write_texture_ptr(
    tex_info,
    upload,
    layout,
    extent,
    data_size=AUTO_EXPOSURE_CURVE_LUT_WIDTH.to_uint64(),
  )
  @wgpu_c.extent3d_free(extent)
  @wgpu_c.texel_copy_buffer_layout_free(layout)
  @wgpu_c.texel_copy_texture_info_free(tex_info)
}

///|
fn auto_exposure_view_state_buffer(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
  min_ev100 : Float,
  max_ev100 : Float,
) -> @wgpu.Buffer {
  for entry in backend.auto_exposure_view_states {
    if entry.key_hi == key_hi && entry.key_lo == key_lo {
      return entry.state_buf
    }
  }
  let safe_min = if min_ev100 < max_ev100 { min_ev100 } else { max_ev100 }
  let safe_max = if max_ev100 > safe_min { max_ev100 } else { safe_min + 0.01F }
  let initial_state = if 0.0F < safe_min {
    safe_min
  } else if 0.0F > safe_max {
    safe_max
  } else {
    0.0F
  }
  let state_buf = backend.device.create_buffer(
    size=4UL,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  backend.queue.write_buffer(state_buf, 0UL, f32le_pack([initial_state]))
  backend.auto_exposure_view_states.push(GpuAutoExposureViewState::{
    key_hi,
    key_lo,
    state_buf,
  })
  state_buf
}

///|
fn auto_exposure_find_view_state_buffer(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> @wgpu.Buffer? {
  for entry in backend.auto_exposure_view_states {
    if entry.key_hi == key_hi && entry.key_lo == key_lo {
      return Some(entry.state_buf)
    }
  }
  None
}

///|
fn create_auto_exposure_bind_group(
  backend : GpuBackend,
  scene_view : @wgpu.TextureView,
  mask_view : @wgpu.TextureView,
  state_buf : @wgpu.Buffer,
  view_buf : @wgpu.Buffer,
) -> @wgpu.BindGroup? {
  guard backend.auto_exposure_compute_bgl is Some(layout) else { return None }
  guard backend.auto_exposure_globals_buf is Some(globals_buf) else {
    return None
  }
  guard backend.auto_exposure_settings_buf is Some(settings_buf) else {
    return None
  }
  guard backend.auto_exposure_curve_extents_buf is Some(curve_extents_buf) else {
    return None
  }
  guard backend.auto_exposure_histogram_buf is Some(histogram_buf) else {
    return None
  }
  guard backend.auto_exposure_curve_view is Some(curve_view) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
  let ok = builder.add_buffer(0U, globals_buf) &&
    builder.add_buffer(1U, settings_buf) &&
    builder.add_texture_view(2U, scene_view) &&
    builder.add_texture_view(3U, mask_view) &&
    builder.add_texture_view(4U, curve_view) &&
    builder.add_buffer(5U, curve_extents_buf) &&
    builder.add_buffer(6U, histogram_buf) &&
    builder.add_buffer(7U, state_buf) &&
    builder.add_buffer(8U, view_buf)
  if !ok {
    builder.free()
    return None
  }
  Some(
    builder.finish(backend.device, layout, label="mgstudio_auto_exposure_bg"),
  )
}

///|
pub fn GpuBackend::apply_auto_exposure(
  self : GpuBackend,
  view_key_hi : Int,
  view_key_lo : Int,
  scene_texture_id : Int,
  min_ev100 : Float,
  max_ev100 : Float,
  low_percent : Float,
  high_percent : Float,
  speed_brighten : Float,
  speed_darken : Float,
  exponential_transition_distance : Float,
  delta_time : Float,
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
  metering_mask_texture_id : Int,
  compensation_curve_lut : Bytes,
  compensation_curve_min_log_lum : Float,
  compensation_curve_max_log_lum : Float,
  compensation_curve_min_compensation : Float,
  compensation_curve_max_compensation : Float,
  view_width : Int,
  view_height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  if scene_texture_id < 0 {
    self.auto_exposure_active_state_buf = None
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    self.auto_exposure_active_state_buf = None
    return
  }
  ensure_auto_exposure_resources(self)
  guard self.auto_exposure_histogram_pipeline is Some(histogram_pipeline) else {
    return
  }
  guard self.auto_exposure_average_pipeline is Some(average_pipeline) else {
    return
  }
  guard self.auto_exposure_globals_buf is Some(globals_buf) else { return }
  guard self.auto_exposure_settings_buf is Some(settings_buf) else { return }
  guard self.auto_exposure_curve_extents_buf is Some(curve_extents_buf) else {
    return
  }
  guard self.tonemapping_view_buf is Some(view_buf) else { return }
  let mask_view = if metering_mask_texture_id >= 0 {
    match find_texture(self, metering_mask_texture_id) {
      Some(mask_texture) => mask_texture.view
      None => ensure_default_texture(self).view
    }
  } else {
    ensure_default_texture(self).view
  }
  let state_buf = auto_exposure_view_state_buffer(
    self, view_key_hi, view_key_lo, min_ev100, max_ev100,
  )
  self.queue.write_buffer(
    globals_buf,
    0UL,
    auto_exposure_globals_bytes(self.frame_count, delta_time),
  )
  tonemapping_write_view_uniform(
    self, pass_state, 1.0F, color_grading_balance_x_axis_x, color_grading_balance_x_axis_y,
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
  self.queue.write_buffer(
    settings_buf,
    0UL,
    auto_exposure_settings_bytes(
      min_ev100, max_ev100, low_percent, high_percent, speed_brighten, speed_darken,
      exponential_transition_distance, delta_time,
    ),
  )
  self.queue.write_buffer(
    curve_extents_buf,
    0UL,
    auto_exposure_curve_extents_bytes(
      compensation_curve_min_log_lum, compensation_curve_max_log_lum, compensation_curve_min_compensation,
      compensation_curve_max_compensation,
    ),
  )
  auto_exposure_upload_curve_lut(self, compensation_curve_lut)
  guard create_auto_exposure_bind_group(
      self,
      scene_texture.view,
      mask_view,
      state_buf,
      view_buf,
    )
    is Some(bind_group) else {
    return
  }

  active_pass.end()
  active_pass.release()
  frame.pass = None

  let dispatch_width = {
    let width = if pass_state.viewport_w > 0U {
      pass_state.viewport_w.reinterpret_as_int()
    } else if view_width > 0 {
      view_width
    } else {
      scene_texture.width
    }
    if width <= 0 {
      1U
    } else {
      ((width + 15) / 16).reinterpret_as_uint()
    }
  }
  let dispatch_height = {
    let height = if pass_state.viewport_h > 0U {
      pass_state.viewport_h.reinterpret_as_int()
    } else if view_height > 0 {
      view_height
    } else {
      scene_texture.height
    }
    if height <= 0 {
      1U
    } else {
      ((height + 15) / 16).reinterpret_as_uint()
    }
  }

  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(histogram_pipeline)
  compute_pass.set_bind_group0(bind_group)
  compute_pass.dispatch_workgroups(dispatch_width, dispatch_height, 1U)
  compute_pass.set_pipeline(average_pipeline)
  compute_pass.set_bind_group0(bind_group)
  compute_pass.dispatch_workgroups(1U, 1U, 1U)
  compute_pass.end()
  compute_pass.release()
  bind_group.release()
  reopen_saved_pass(self, pass_state)
  self.auto_exposure_active_state_buf = Some(state_buf)
}

///|
pub fn GpuBackend::activate_auto_exposure_view_state(
  self : GpuBackend,
  view_key_hi : Int,
  view_key_lo : Int,
) -> Unit {
  self.auto_exposure_active_state_buf = auto_exposure_find_view_state_buffer(
    self, view_key_hi, view_key_lo,
  )
}

///|
pub fn apply_auto_exposure(
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
  metering_mask_texture_id~ : Int,
  compensation_curve_lut~ : Bytes,
  compensation_curve_min_log_lum~ : Float,
  compensation_curve_max_log_lum~ : Float,
  compensation_curve_min_compensation~ : Float,
  compensation_curve_max_compensation~ : Float,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.apply_auto_exposure(
      view_key_hi, view_key_lo, scene_texture_id, min_ev100, max_ev100, low_percent,
      high_percent, speed_brighten, speed_darken, exponential_transition_distance,
      delta_time, color_grading_balance_x_axis_x, color_grading_balance_x_axis_y,
      color_grading_balance_x_axis_z, color_grading_balance_y_axis_x, color_grading_balance_y_axis_y,
      color_grading_balance_y_axis_z, color_grading_balance_z_axis_x, color_grading_balance_z_axis_y,
      color_grading_balance_z_axis_z, color_grading_saturation_shadows, color_grading_saturation_midtones,
      color_grading_saturation_highlights, color_grading_contrast_shadows, color_grading_contrast_midtones,
      color_grading_contrast_highlights, color_grading_gamma_shadows, color_grading_gamma_midtones,
      color_grading_gamma_highlights, color_grading_gain_shadows, color_grading_gain_midtones,
      color_grading_gain_highlights, color_grading_lift_shadows, color_grading_lift_midtones,
      color_grading_lift_highlights, color_grading_midtones_start, color_grading_midtones_end,
      color_grading_exposure, color_grading_hue, color_grading_post_saturation, metering_mask_texture_id,
      compensation_curve_lut, compensation_curve_min_log_lum, compensation_curve_max_log_lum,
      compensation_curve_min_compensation, compensation_curve_max_compensation, view_width,
      view_height,
    ) catch {
      err => debug_runtime_error("apply_auto_exposure", err)
    }
  }
}

///|
pub fn activate_auto_exposure_view_state(
  view_key_hi~ : Int,
  view_key_lo~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.activate_auto_exposure_view_state(view_key_hi, view_key_lo)
  }
}
