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
const EFFECT_STACK_CHROMATIC_SETTINGS_BUFFER_SIZE : UInt64 = 16UL

///|
const EFFECT_STACK_VIGNETTE_SETTINGS_BUFFER_SIZE : UInt64 = 48UL

///|
fn load_effect_stack_wgsl_required(
  backend : GpuBackend,
) -> FullscreenPostprocessWgslSources raise GpuBackendError {
  load_fullscreen_postprocess_wgsl_modules_with_defines_required(
    backend,
    "post_process/effect_stack/post_process.wgsl",
    [],
  )
}

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
fn effect_stack_chromatic_uniform_bytes(
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
fn effect_stack_vignette_uniform_bytes(
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
fn ensure_effect_stack_layouts(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.effect_stack_bgl is None {
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
      fatal("wgpu: failed to build effect_stack bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_effect_stack_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_effect_stack_pipeline_layout")
    backend.effect_stack_bgl = Some(bgl)
    backend.effect_stack_pipeline_layout = Some(pipeline_layout)
  }
  if backend.effect_stack_sampler is None {
    backend.effect_stack_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
  if backend.effect_stack_lut_sampler is None {
    backend.effect_stack_lut_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
  if backend.effect_stack_chromatic_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.effect_stack_chromatic_settings_buf = Some(
      backend.device.create_buffer(
        size=EFFECT_STACK_CHROMATIC_SETTINGS_BUFFER_SIZE,
        usage~,
      ),
    )
  }
  if backend.effect_stack_vignette_settings_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.effect_stack_vignette_settings_buf = Some(
      backend.device.create_buffer(
        size=EFFECT_STACK_VIGNETTE_SETTINGS_BUFFER_SIZE,
        usage~,
      ),
    )
  }
}

///|
fn ensure_effect_stack_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_effect_stack_layouts(backend)
  if backend.effect_stack_pipeline is Some(_) {
    return
  }
  guard backend.effect_stack_pipeline_layout is Some(pipeline_layout) else {
    return
  }
  let sources = load_effect_stack_wgsl_required(backend)
  let pipeline = create_postprocess_pipeline_split_modules(
    backend,
    pipeline_layout,
    sources.vertex_source,
    sources.fragment_source,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "fragment_main",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_effect_stack_rgba8",
  )
  backend.effect_stack_pipeline = Some(pipeline)
}

///|
fn ensure_effect_stack_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_effect_stack_pipeline_rgba8(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.effect_stack_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.effect_stack_pipeline_surface is Some(_) {
    return
  }
  if backend.effect_stack_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.effect_stack_pipeline_layout is Some(pipeline_layout) else {
    return
  }
  let sources = load_effect_stack_wgsl_required(backend)
  let pipeline = create_postprocess_pipeline_split_modules(
    backend,
    pipeline_layout,
    sources.vertex_source,
    sources.fragment_source,
    format,
    "fragment_main",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_effect_stack_surface",
  )
  backend.effect_stack_pipeline_surface = Some(pipeline)
  backend.effect_stack_pipeline_surface_format = Some(format)
}

///|
fn effect_stack_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_effect_stack_pipeline_surface(backend, format)
      return backend.effect_stack_pipeline_surface
    }
    _ => ()
  }
  ensure_effect_stack_pipeline_rgba8(backend)
  backend.effect_stack_pipeline
}

///|
fn ensure_effect_stack_default_lut_view(
  backend : GpuBackend,
) -> @wgpu.TextureView raise GpuBackendError {
  if backend.effect_stack_default_lut_texture_id > 0 {
    if find_texture(backend, backend.effect_stack_default_lut_texture_id)
      is Some(texture) {
      return texture.view
    }
    backend.effect_stack_default_lut_texture_id = -1
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
  backend.effect_stack_default_lut_texture_id = texture_id
  if find_texture(backend, texture_id) is Some(texture) {
    texture.view
  } else {
    fatal(
      "wgpu: effect_stack default LUT texture missing after creation (id=\{texture_id})",
    )
  }
}

///|
pub fn GpuBackend::draw_effect_stack(
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
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  guard effect_stack_pipeline_for_current_pass(self) is Some(pipeline) else {
    return
  }
  guard self.effect_stack_bgl is Some(bind_layout) else { return }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  guard self.effect_stack_sampler is Some(source_sampler) else { return }
  guard self.effect_stack_lut_sampler is Some(lut_sampler) else { return }
  guard self.effect_stack_chromatic_settings_buf is Some(chromatic_settings_buf) else {
    return
  }
  guard self.effect_stack_vignette_settings_buf is Some(vignette_settings_buf) else {
    return
  }
  let lut_view = ensure_effect_stack_default_lut_view(self)
  let chromatic_settings = effect_stack_chromatic_uniform_bytes(
    if chromatic_aberration_max_samples > 0 {
      chromatic_aberration_intensity
    } else {
      0.0F
    },
    chromatic_aberration_max_samples,
  )
  let vignette_settings = effect_stack_vignette_uniform_bytes(
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
        label="mgstudio_effect_stack_bg",
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
pub fn draw_effect_stack(
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
    backend.draw_effect_stack(
      scene_texture_id, chromatic_aberration_intensity, chromatic_aberration_max_samples,
      vignette_intensity, vignette_radius, vignette_smoothness, vignette_roundness,
      vignette_center_x, vignette_center_y, vignette_edge_compensation, vignette_color_r,
      vignette_color_g, vignette_color_b, vignette_color_a, view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_effect_stack", err)
    }
  }
}
