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
fn clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
const EFFECT_STACK3D_CHROMATIC_SETTINGS_BUFFER_SIZE : UInt64 = 16UL

///|
const EFFECT_STACK3D_VIGNETTE_SETTINGS_BUFFER_SIZE : UInt64 = 48UL

///|
const FXAA3D_SENSITIVITY_LOW : Int = 0

///|
const FXAA3D_SENSITIVITY_MEDIUM : Int = 1

///|
const FXAA3D_SENSITIVITY_HIGH : Int = 2

///|
const FXAA3D_SENSITIVITY_ULTRA : Int = 3

///|
const FXAA3D_SENSITIVITY_EXTREME : Int = 4

///|
fn clamp_unit(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn fxaa3d_sensitivity_mode_clamped(mode : Int) -> Int {
  if mode < FXAA3D_SENSITIVITY_LOW {
    FXAA3D_SENSITIVITY_LOW
  } else if mode > FXAA3D_SENSITIVITY_EXTREME {
    FXAA3D_SENSITIVITY_EXTREME
  } else {
    mode
  }
}

///|
fn fxaa3d_sensitivity_define_suffix(mode : Int) -> String {
  match fxaa3d_sensitivity_mode_clamped(mode) {
    FXAA3D_SENSITIVITY_LOW => "LOW"
    FXAA3D_SENSITIVITY_MEDIUM => "MEDIUM"
    FXAA3D_SENSITIVITY_HIGH => "HIGH"
    FXAA3D_SENSITIVITY_ULTRA => "ULTRA"
    _ => "EXTREME"
  }
}

///|
fn effect_stack3d_chromatic_uniform_bytes(
  intensity : Float,
  max_samples : Int,
) -> Bytes {
  let safe_intensity = clamp_non_negative(intensity)
  let safe_max_samples = if max_samples <= 0 { 1 } else { max_samples }
  u32le_pack([
    f32_bits(safe_intensity),
    safe_max_samples.reinterpret_as_uint(),
    0U,
    0U,
  ])
}

///|
fn effect_stack3d_vignette_uniform_bytes(
  intensity : Float,
  radius : Float,
  smoothness : Float,
  roundness : Float,
  center_x : Float,
  center_y : Float,
  edge_compensation : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
) -> Bytes {
  let safe_intensity = clamp_non_negative(intensity)
  let safe_radius = clamp_non_negative(radius)
  let safe_smoothness = if smoothness <= 0.0F { 0.0F } else { smoothness }
  let safe_roundness = if roundness <= 0.0001F {
    0.0001F
  } else if roundness >= 1.9999F {
    1.9999F
  } else {
    roundness
  }
  let safe_edge_compensation = clamp_unit(edge_compensation)
  u32le_pack([
    f32_bits(safe_intensity),
    f32_bits(safe_radius),
    f32_bits(safe_smoothness),
    f32_bits(safe_roundness),
    f32_bits(center_x),
    f32_bits(center_y),
    f32_bits(safe_edge_compensation),
    0U,
    f32_bits(color_r),
    f32_bits(color_g),
    f32_bits(color_b),
    f32_bits(color_a),
  ])
}

///|
fn ensure_effect_stack3d_layouts(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.effect_stack3d_bgl is None {
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
    let ok = builder.add_texture(
        0U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(1U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_texture(
        2U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(3U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
      builder.add_buffer(4U, frag, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      builder.add_buffer(5U, frag, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build effect_stack3d bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_effect_stack3d_bgl",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_effect_stack3d_pipeline_layout")
    backend.effect_stack3d_bgl = Some(bgl)
    backend.effect_stack3d_pipeline_layout = Some(pipeline_layout)
  }
  if backend.effect_stack3d_sampler is None {
    backend.effect_stack3d_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
  if backend.effect_stack3d_lut_sampler is None {
    backend.effect_stack3d_lut_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
  if backend.effect_stack3d_chromatic_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.effect_stack3d_chromatic_settings_buf = Some(
      backend.device.create_buffer(
        size=EFFECT_STACK3D_CHROMATIC_SETTINGS_BUFFER_SIZE,
        usage~,
      ),
    )
  }
  if backend.effect_stack3d_vignette_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.effect_stack3d_vignette_settings_buf = Some(
      backend.device.create_buffer(
        size=EFFECT_STACK3D_VIGNETTE_SETTINGS_BUFFER_SIZE,
        usage~,
      ),
    )
  }
}

///|
fn ensure_effect_stack3d_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_effect_stack3d_layouts(backend)
  if backend.effect_stack3d_pipeline is Some(_) {
    return
  }
  guard backend.effect_stack3d_pipeline_layout is Some(pipeline_layout) else {
    return
  }
  let source = load_wgsl_from_assets_required(
    backend, "shaders/bevy/bevy_post_process/effect_stack/post_process.wgsl",
  )
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "fragment_main",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_effect_stack3d_rgba8",
  )
  backend.effect_stack3d_pipeline = Some(pipeline)
}

///|
fn ensure_effect_stack3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_effect_stack3d_pipeline_rgba8(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.effect_stack3d_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.effect_stack3d_pipeline_surface is Some(_) {
    return
  }
  if backend.effect_stack3d_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.effect_stack3d_pipeline_layout is Some(pipeline_layout) else {
    return
  }
  let source = load_wgsl_from_assets_required(
    backend, "shaders/bevy/bevy_post_process/effect_stack/post_process.wgsl",
  )
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    format,
    "fragment_main",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_effect_stack3d_surface",
  )
  backend.effect_stack3d_pipeline_surface = Some(pipeline)
  backend.effect_stack3d_pipeline_surface_format = Some(format)
}

///|
fn effect_stack3d_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_effect_stack3d_pipeline_surface(backend, format)
      return backend.effect_stack3d_pipeline_surface
    }
    _ => ()
  }
  ensure_effect_stack3d_pipeline_rgba8(backend)
  backend.effect_stack3d_pipeline
}

///|
fn ensure_effect_stack3d_default_lut_view(
  backend : GpuBackend,
) -> @wgpu.TextureView raise GpuBackendError {
  if backend.effect_stack3d_default_lut_texture_id > 0 {
    if find_texture(backend, backend.effect_stack3d_default_lut_texture_id)
      is Some(texture) {
      return texture.view
    }
    backend.effect_stack3d_default_lut_texture_id = -1
  }
  let lut_bytes = Bytes::from_array([
    (255).to_byte(),
    (0).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (0).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (255).to_byte(),
  ])
  let texture_id = backend.create_texture_stacked_2d_with_format(
    3,
    1,
    1,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    [lut_bytes],
    false,
  )
  backend.effect_stack3d_default_lut_texture_id = texture_id
  if find_texture(backend, texture_id) is Some(texture) {
    texture.view
  } else {
    fatal(
      "wgpu: effect_stack3d default LUT texture missing after creation (id=\{texture_id})",
    )
  }
}

///|
fn ensure_fxaa3d_layouts(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.fxaa3d_bgl is None {
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
    let ok = builder.add_texture(
        0U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(1U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build fxaa3d bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_fxaa3d_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_fxaa3d_pipeline_layout")
    backend.fxaa3d_bgl = Some(bgl)
    backend.fxaa3d_pipeline_layout = Some(pipeline_layout)
  }
  if backend.fxaa3d_sampler is None {
    backend.fxaa3d_sampler = Some(backend.device.create_sampler_linear_clamp())
  }
}

///|
fn ensure_fxaa3d_pipeline_rgba8(
  backend : GpuBackend,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_fxaa3d_layouts(backend)
  let safe_edge_threshold_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if backend.fxaa3d_pipeline is Some(_) &&
    backend.fxaa3d_pipeline_edge_threshold_mode == safe_edge_threshold_mode &&
    backend.fxaa3d_pipeline_edge_threshold_min_mode ==
    safe_edge_threshold_min_mode {
    return
  }
  if backend.fxaa3d_pipeline is Some(old) {
    old.release()
  }
  guard backend.fxaa3d_pipeline_layout is Some(pipeline_layout) else { return }
  let define_keys = [
    "EDGE_THRESH_" + fxaa3d_sensitivity_define_suffix(safe_edge_threshold_mode),
    "EDGE_THRESH_MIN_" +
    fxaa3d_sensitivity_define_suffix(safe_edge_threshold_min_mode),
  ]
  let source = load_wgsl_with_defines_required(
    backend, "shaders/bevy/bevy_anti_alias/fxaa/fxaa.wgsl", define_keys,
  )
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_fxaa3d_rgba8",
  )
  backend.fxaa3d_pipeline = Some(pipeline)
  backend.fxaa3d_pipeline_edge_threshold_mode = safe_edge_threshold_mode
  backend.fxaa3d_pipeline_edge_threshold_min_mode = safe_edge_threshold_min_mode
}

///|
fn ensure_fxaa3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_fxaa3d_layouts(backend)
  let safe_edge_threshold_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if backend.fxaa3d_pipeline_surface is Some(_) &&
    backend.fxaa3d_pipeline_surface_format is Some(prev_format) &&
    prev_format == format &&
    backend.fxaa3d_pipeline_surface_edge_threshold_mode ==
    safe_edge_threshold_mode &&
    backend.fxaa3d_pipeline_surface_edge_threshold_min_mode ==
    safe_edge_threshold_min_mode {
    return
  }
  if backend.fxaa3d_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.fxaa3d_pipeline_layout is Some(pipeline_layout) else { return }
  let define_keys = [
    "EDGE_THRESH_" + fxaa3d_sensitivity_define_suffix(safe_edge_threshold_mode),
    "EDGE_THRESH_MIN_" +
    fxaa3d_sensitivity_define_suffix(safe_edge_threshold_min_mode),
  ]
  let source = load_wgsl_with_defines_required(
    backend, "shaders/bevy/bevy_anti_alias/fxaa/fxaa.wgsl", define_keys,
  )
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    format,
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_fxaa3d_surface",
  )
  backend.fxaa3d_pipeline_surface = Some(pipeline)
  backend.fxaa3d_pipeline_surface_format = Some(format)
  backend.fxaa3d_pipeline_surface_edge_threshold_mode = safe_edge_threshold_mode
  backend.fxaa3d_pipeline_surface_edge_threshold_min_mode = safe_edge_threshold_min_mode
}

///|
fn fxaa3d_pipeline_for_current_pass(
  backend : GpuBackend,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let safe_edge_threshold_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa3d_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if current_pass_color_format(backend) is Some(format) {
    if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
      ensure_fxaa3d_pipeline_rgba8(
        backend, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
      )
      return backend.fxaa3d_pipeline
    }
    ensure_fxaa3d_pipeline_surface(
      backend, format, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
    )
    return backend.fxaa3d_pipeline_surface
  }
  ensure_fxaa3d_pipeline_rgba8(
    backend, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
  )
  backend.fxaa3d_pipeline
}

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
pub fn GpuBackend::draw_effect_stack3d(
  self : GpuBackend,
  scene_texture_id : Int,
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
) -> Unit raise GpuBackendError {
  view_width |> ignore
  view_height |> ignore
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  guard effect_stack3d_pipeline_for_current_pass(self) is Some(pipeline) else {
    return
  }
  guard self.effect_stack3d_bgl is Some(bind_layout) else { return }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  guard self.effect_stack3d_sampler is Some(source_sampler) else { return }
  guard self.effect_stack3d_lut_sampler is Some(lut_sampler) else { return }
  guard self.effect_stack3d_chromatic_settings_buf
    is Some(chromatic_settings_buf) else {
    return
  }
  guard self.effect_stack3d_vignette_settings_buf is Some(vignette_settings_buf) else {
    return
  }
  let lut_view = ensure_effect_stack3d_default_lut_view(self)
  let chromatic_settings = effect_stack3d_chromatic_uniform_bytes(
    if chromatic_aberration_max_samples > 0 {
      chromatic_aberration_intensity
    } else {
      0.0F
    },
    chromatic_aberration_max_samples,
  )
  let vignette_settings = effect_stack3d_vignette_uniform_bytes(
    vignette_intensity, vignette_radius, vignette_smoothness, vignette_roundness,
    vignette_center_x, vignette_center_y, vignette_edge_compensation, vignette_color_r,
    vignette_color_g, vignette_color_b, vignette_color_a,
  )
  self.queue.write_buffer(chromatic_settings_buf, 0UL, chromatic_settings)
  self.queue.write_buffer(vignette_settings_buf, 0UL, vignette_settings)
  active_pass.end()
  active_pass.release()
  frame.pass = None
  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
    let ok = builder.add_texture_view(0U, scene_texture.view) &&
      builder.add_sampler(1U, source_sampler) &&
      builder.add_texture_view(2U, lut_view) &&
      builder.add_sampler(3U, lut_sampler) &&
      builder.add_buffer(4U, chromatic_settings_buf) &&
      builder.add_buffer(5U, vignette_settings_buf)
    if ok {
      let bind_group = builder.finish(
        self.device,
        bind_layout,
        label="mgstudio_effect_stack3d_bg",
      )
      let render_pass = frame.encoder.begin_render_pass_color_load(dst_view)
      render_pass.set_viewport(
        Float::from_double(pass_state.viewport_x.to_double()),
        Float::from_double(pass_state.viewport_y.to_double()),
        Float::from_double(pass_state.viewport_w.to_double()),
        Float::from_double(pass_state.viewport_h.to_double()),
        pass_state.viewport_depth_min,
        pass_state.viewport_depth_max,
      )
      render_pass.set_scissor_rect(
        pass_state.viewport_x,
        pass_state.viewport_y,
        pass_state.viewport_w,
        pass_state.viewport_h,
      )
      render_pass.set_pipeline(pipeline)
      render_pass.set_bind_group(0U, bind_group, [])
      render_pass.draw(3U, 1U, 0U, 0U)
      render_pass.end()
      render_pass.release()
      bind_group.release()
    } else {
      builder.free()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn GpuBackend::draw_fxaa3d(
  self : GpuBackend,
  scene_texture_id : Int,
  fxaa_enabled : Int,
  fxaa_edge_threshold_mode : Int,
  fxaa_edge_threshold_min_mode : Int,
  view_width : Int,
  view_height : Int,
) -> Unit raise GpuBackendError {
  view_width |> ignore
  view_height |> ignore
  if fxaa_enabled == 0 {
    return
  }
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  guard fxaa3d_pipeline_for_current_pass(
      self, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode,
    )
    is Some(pipeline) else {
    return
  }
  guard self.fxaa3d_bgl is Some(bind_layout) else { return }
  guard self.fxaa3d_sampler is Some(sampler) else { return }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  active_pass.end()
  active_pass.release()
  frame.pass = None
  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
    let ok = builder.add_texture_view(0U, scene_texture.view) &&
      builder.add_sampler(1U, sampler)
    if ok {
      let bind_group = builder.finish(
        self.device,
        bind_layout,
        label="mgstudio_fxaa3d_bg",
      )
      let render_pass = frame.encoder.begin_render_pass_color_load(dst_view)
      render_pass.set_viewport(
        Float::from_double(pass_state.viewport_x.to_double()),
        Float::from_double(pass_state.viewport_y.to_double()),
        Float::from_double(pass_state.viewport_w.to_double()),
        Float::from_double(pass_state.viewport_h.to_double()),
        pass_state.viewport_depth_min,
        pass_state.viewport_depth_max,
      )
      render_pass.set_scissor_rect(
        pass_state.viewport_x,
        pass_state.viewport_y,
        pass_state.viewport_w,
        pass_state.viewport_h,
      )
      render_pass.set_pipeline(pipeline)
      render_pass.set_bind_group(0U, bind_group, [])
      render_pass.draw(3U, 1U, 0U, 0U)
      render_pass.end()
      render_pass.release()
      bind_group.release()
    } else {
      builder.free()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn draw_effect_stack3d(
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
  if ensure_backend() is Some(backend) {
    backend.draw_effect_stack3d(
      scene_texture_id, chromatic_aberration_intensity, chromatic_aberration_max_samples,
      vignette_intensity, vignette_radius, vignette_smoothness, vignette_roundness,
      vignette_center_x, vignette_center_y, vignette_edge_compensation, vignette_color_r,
      vignette_color_g, vignette_color_b, vignette_color_a, view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_effect_stack3d", err)
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
pub fn draw_fxaa3d(
  scene_texture_id~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold_mode~ : Int,
  fxaa_edge_threshold_min_mode~ : Int,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_fxaa3d(
      scene_texture_id, fxaa_enabled, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode,
      view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_fxaa3d", err)
    }
  }
}
