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
fn load_blit_wgsl_required(
  backend : GpuBackend,
) -> String raise GpuBackendError {
  let main_source = load_wgsl_asset_source_required(
    backend, "core_pipeline/blit/blit.wgsl",
  )
  let stripped_main_source = replace_shader_substring_all(
    main_source, "#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput\n",
    "",
  )
  let fullscreen_source = load_wgsl_asset_source_required(
    backend, "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
  )
  let merged_source = merge_fullscreen_postprocess_source(
    stripped_main_source, fullscreen_source,
  )
  preprocess_manual_wgsl_source(backend, merged_source, [], [])
}

///|
fn ensure_blit_layouts(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.blit_bgl is None {
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
      fatal("wgpu: failed to build blit bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_blit_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_blit_pipeline_layout")
    backend.blit_bgl = Some(bgl)
    backend.blit_pipeline_layout = Some(pipeline_layout)
  }
  if backend.blit_sampler is None {
    backend.blit_sampler = Some(backend.device.create_sampler_linear_clamp())
  }
}

///|
fn blit_pipeline_for_format(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_blit_layouts(backend)
  if backend.blit_pipeline is Some(pipeline) &&
    backend.blit_pipeline_format is Some(cached_format) &&
    cached_format.raw == format.raw {
    return Some(pipeline)
  }
  if backend.blit_pipeline is Some(old_pipeline) {
    old_pipeline.release()
  }
  guard backend.blit_pipeline_layout is Some(pipeline_layout) else {
    return None
  }
  let source = load_blit_wgsl_required(backend)
  let pipeline = create_postprocess_pipeline(
    backend,
    pipeline_layout,
    source,
    format,
    "fs_main",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_blit_\{format.raw.to_string()}",
  )
  backend.blit_pipeline = Some(pipeline)
  backend.blit_pipeline_format = Some(format)
  Some(pipeline)
}

///|
pub fn GpuBackend::draw_blit(
  self : GpuBackend,
  scene_texture_id : Int,
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
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  guard blit_pipeline_for_format(self, format) is Some(pipeline) else { return }
  guard self.blit_bgl is Some(bind_layout) else { return }
  guard self.blit_sampler is Some(sampler) else { return }

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
        label="mgstudio_blit_bind_group",
      )
      let pass = frame.encoder.begin_render_pass_color_load(dst_view)
      pass.set_viewport(
        Float::from_double(pass_state.viewport_x.to_double()),
        Float::from_double(pass_state.viewport_y.to_double()),
        Float::from_double(pass_state.viewport_w.to_double()),
        Float::from_double(pass_state.viewport_h.to_double()),
        pass_state.viewport_depth_min,
        pass_state.viewport_depth_max,
      )
      pass.set_scissor_rect(
        pass_state.viewport_x,
        pass_state.viewport_y,
        pass_state.viewport_w,
        pass_state.viewport_h,
      )
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0U, bind_group, [])
      pass.draw(3U, 1U, 0U, 0U)
      pass.end()
      pass.release()
      bind_group.release()
    } else {
      builder.free()
    }
  }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn draw_blit(scene_texture_id~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_blit(scene_texture_id) catch {
      err => debug_runtime_error("draw_blit", err)
    }
  }
}
