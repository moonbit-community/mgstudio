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
const FXAA_SENSITIVITY_LOW : Int = 0

///|
const FXAA_SENSITIVITY_MEDIUM : Int = 1

///|
const FXAA_SENSITIVITY_HIGH : Int = 2

///|
const FXAA_SENSITIVITY_ULTRA : Int = 3

///|
const FXAA_SENSITIVITY_EXTREME : Int = 4

///|
fn fxaa_sensitivity_mode_clamped(mode : Int) -> Int {
  if mode < FXAA_SENSITIVITY_LOW {
    FXAA_SENSITIVITY_LOW
  } else if mode > FXAA_SENSITIVITY_EXTREME {
    FXAA_SENSITIVITY_EXTREME
  } else {
    mode
  }
}

///|
fn fxaa_sensitivity_define_suffix(mode : Int) -> String {
  match fxaa_sensitivity_mode_clamped(mode) {
    FXAA_SENSITIVITY_LOW => "LOW"
    FXAA_SENSITIVITY_MEDIUM => "MEDIUM"
    FXAA_SENSITIVITY_HIGH => "HIGH"
    FXAA_SENSITIVITY_ULTRA => "ULTRA"
    _ => "EXTREME"
  }
}

///|
fn load_fxaa_wgsl_with_defines_required(
  backend : GpuBackend,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let main_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_anti_alias/fxaa/fxaa.wgsl",
  )
  let stripped_main_source = replace_shader_substring_all(
    main_source, "#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput\n",
    "",
  )
  let fullscreen_source = load_wgsl_asset_source_required(
    backend, "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
  let merged_source = merge_fullscreen_postprocess_source(
    stripped_main_source, fullscreen_source,
  )
  preprocess_manual_wgsl_source(backend, merged_source, define_keys, [])
}

///|
fn ensure_fxaa_layouts(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.fxaa_bgl is None {
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
      fatal("wgpu: failed to build fxaa bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_fxaa_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_fxaa_pipeline_layout")
    backend.fxaa_bgl = Some(bgl)
    backend.fxaa_pipeline_layout = Some(pipeline_layout)
  }
  if backend.fxaa_sampler is None {
    backend.fxaa_sampler = Some(backend.device.create_sampler_linear_clamp())
  }
}

///|
fn ensure_fxaa_pipeline_rgba8(
  backend : GpuBackend,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_fxaa_layouts(backend)
  let safe_edge_threshold_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if backend.fxaa_pipeline is Some(_) &&
    backend.fxaa_pipeline_edge_threshold_mode == safe_edge_threshold_mode &&
    backend.fxaa_pipeline_edge_threshold_min_mode ==
    safe_edge_threshold_min_mode {
    return
  }
  if backend.fxaa_pipeline is Some(old) {
    old.release()
  }
  guard backend.fxaa_pipeline_layout is Some(pipeline_layout) else { return }
  let define_keys = [
    "EDGE_THRESH_" + fxaa_sensitivity_define_suffix(safe_edge_threshold_mode),
    "EDGE_THRESH_MIN_" +
    fxaa_sensitivity_define_suffix(safe_edge_threshold_min_mode),
  ]
  let source = load_fxaa_wgsl_with_defines_required(backend, define_keys)
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_fxaa_rgba8",
  )
  backend.fxaa_pipeline = Some(pipeline)
  backend.fxaa_pipeline_edge_threshold_mode = safe_edge_threshold_mode
  backend.fxaa_pipeline_edge_threshold_min_mode = safe_edge_threshold_min_mode
}

///|
fn ensure_fxaa_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_fxaa_layouts(backend)
  let safe_edge_threshold_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if backend.fxaa_pipeline_surface is Some(_) &&
    backend.fxaa_pipeline_surface_format is Some(prev_format) &&
    prev_format == format &&
    backend.fxaa_pipeline_surface_edge_threshold_mode ==
    safe_edge_threshold_mode &&
    backend.fxaa_pipeline_surface_edge_threshold_min_mode ==
    safe_edge_threshold_min_mode {
    return
  }
  if backend.fxaa_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.fxaa_pipeline_layout is Some(pipeline_layout) else { return }
  let define_keys = [
    "EDGE_THRESH_" + fxaa_sensitivity_define_suffix(safe_edge_threshold_mode),
    "EDGE_THRESH_MIN_" +
    fxaa_sensitivity_define_suffix(safe_edge_threshold_min_mode),
  ]
  let source = load_fxaa_wgsl_with_defines_required(backend, define_keys)
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    format,
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_fxaa_surface",
  )
  backend.fxaa_pipeline_surface = Some(pipeline)
  backend.fxaa_pipeline_surface_format = Some(format)
  backend.fxaa_pipeline_surface_edge_threshold_mode = safe_edge_threshold_mode
  backend.fxaa_pipeline_surface_edge_threshold_min_mode = safe_edge_threshold_min_mode
}

///|
fn fxaa_pipeline_for_current_pass(
  backend : GpuBackend,
  edge_threshold_mode : Int,
  edge_threshold_min_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let safe_edge_threshold_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_mode,
  )
  let safe_edge_threshold_min_mode = fxaa_sensitivity_mode_clamped(
    edge_threshold_min_mode,
  )
  if current_pass_color_format(backend) is Some(format) {
    if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
      ensure_fxaa_pipeline_rgba8(
        backend, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
      )
      return backend.fxaa_pipeline
    }
    ensure_fxaa_pipeline_surface(
      backend, format, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
    )
    return backend.fxaa_pipeline_surface
  }
  ensure_fxaa_pipeline_rgba8(
    backend, safe_edge_threshold_mode, safe_edge_threshold_min_mode,
  )
  backend.fxaa_pipeline
}

///|
pub fn GpuBackend::draw_fxaa(
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
  guard fxaa_pipeline_for_current_pass(
      self, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode,
    )
    is Some(pipeline) else {
    return
  }
  guard self.fxaa_bgl is Some(bind_layout) else { return }
  guard self.fxaa_sampler is Some(sampler) else { return }
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
        label="mgstudio_fxaa_bg",
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
pub fn draw_fxaa(
  scene_texture_id~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold_mode~ : Int,
  fxaa_edge_threshold_min_mode~ : Int,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_fxaa(
      scene_texture_id, fxaa_enabled, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode,
      view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_fxaa", err)
    }
  }
}
