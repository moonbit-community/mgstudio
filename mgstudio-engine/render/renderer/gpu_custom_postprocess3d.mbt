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
const CUSTOM_POSTPROCESS3D_UNIFORM_BUFFER_SIZE : UInt64 = 16UL

///|
fn custom_postprocess3d_uniform_bytes(
  uniform_x : Float,
  uniform_y : Float,
  uniform_z : Float,
  uniform_w : Float,
) -> Bytes {
  u32le_pack([
    f32_bits(uniform_x),
    f32_bits(uniform_y),
    f32_bits(uniform_z),
    f32_bits(uniform_w),
  ])
}

///|
fn load_custom_postprocess3d_wgsl_required(
  backend : GpuBackend,
  shader_path : String,
) -> FullscreenPostprocessWgslSources raise GpuBackendError {
  load_fullscreen_postprocess_wgsl_modules_with_defines_required(
    backend,
    shader_path,
    [],
  )
}

///|
fn custom_postprocess3d_pipeline_cache_get(
  backend : GpuBackend,
  shader_path : String,
  fragment_entry : String,
  format : @wgpu.TextureFormat,
) -> @wgpu.RenderPipeline? {
  for entry in backend.custom_postprocess3d_pipeline_cache {
    if entry.shader_path == shader_path &&
      entry.fragment_entry == fragment_entry &&
      entry.surface_format.raw == format.raw {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn ensure_custom_postprocess3d_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.custom_postprocess3d_bgl is None {
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
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
      fatal("wgpu: failed to build custom postprocess bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_custom_postprocess3d_bgl",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_custom_postprocess3d_pipeline_layout")
    backend.custom_postprocess3d_bgl = Some(bgl)
    backend.custom_postprocess3d_pipeline_layout = Some(pipeline_layout)
  }
  if backend.custom_postprocess3d_sampler is None {
    backend.custom_postprocess3d_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
  if backend.custom_postprocess3d_uniform_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.custom_postprocess3d_uniform_buf = Some(
      backend.device.create_buffer(
        size=CUSTOM_POSTPROCESS3D_UNIFORM_BUFFER_SIZE,
        usage~,
      ),
    )
  }
}

///|
fn custom_postprocess3d_pipeline_get_or_create(
  backend : GpuBackend,
  shader_path : String,
  fragment_entry : String,
  format : @wgpu.TextureFormat,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  if custom_postprocess3d_pipeline_cache_get(
      backend, shader_path, fragment_entry, format,
    )
    is Some(cached_pipeline) {
    return Some(cached_pipeline)
  }
  ensure_custom_postprocess3d_resources(backend)
  guard backend.custom_postprocess3d_pipeline_layout is Some(pipeline_layout) else {
    return None
  }
  let sources = load_custom_postprocess3d_wgsl_required(backend, shader_path)
  let pipeline = create_postprocess_pipeline_split_modules(
    backend,
    pipeline_layout,
    sources.vertex_source,
    sources.fragment_source,
    format,
    fragment_entry,
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_custom_postprocess3d_\{shader_path}_\{fragment_entry}_\{format.raw.to_string()}",
  )
  backend.custom_postprocess3d_pipeline_cache.push(CustomPostProcessPipelineCacheEntry::{
    shader_path,
    fragment_entry,
    surface_format: format,
    pipeline,
  })
  Some(pipeline)
}

///|
pub fn GpuBackend::draw_custom_postprocess3d(
  self : GpuBackend,
  scene_texture_id : Int,
  shader_path : String,
  fragment_entry : String,
  uniform_x : Float,
  uniform_y : Float,
  uniform_z : Float,
  uniform_w : Float,
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
  if scene_texture_id < 0 {
    return
  }
  let resolved_shader_path = normalize_shader_rel_path(
    shader_path.trim().to_owned(),
  )
  if resolved_shader_path == "" {
    return
  }
  let resolved_fragment_entry = if fragment_entry.trim().to_owned() == "" {
    "fragment_main"
  } else {
    fragment_entry.trim().to_owned()
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  let format = match current_pass_color_format(self) {
    Some(format) => format
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  guard custom_postprocess3d_pipeline_get_or_create(
      self, resolved_shader_path, resolved_fragment_entry, format,
    )
    is Some(pipeline) else {
    return
  }
  guard self.custom_postprocess3d_bgl is Some(bind_layout) else { return }
  guard self.custom_postprocess3d_sampler is Some(sampler) else { return }
  guard self.custom_postprocess3d_uniform_buf is Some(uniform_buf) else {
    return
  }
  self.queue.write_buffer(
    uniform_buf,
    0UL,
    custom_postprocess3d_uniform_bytes(
      uniform_x, uniform_y, uniform_z, uniform_w,
    ),
  )

  active_pass.end()
  active_pass.release()
  frame.pass = None

  if target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) {
    let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
    let ok = builder.add_texture_view(0U, scene_texture.view) &&
      builder.add_sampler(1U, sampler) &&
      builder.add_buffer(2U, uniform_buf)
    if ok {
      let bind_group = builder.finish(
        self.device,
        bind_layout,
        label="mgstudio_custom_postprocess3d_bind_group",
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
pub fn draw_custom_postprocess3d(
  scene_texture_id~ : Int,
  shader_path~ : String,
  fragment_entry~ : String,
  uniform_x~ : Float,
  uniform_y~ : Float,
  uniform_z~ : Float,
  uniform_w~ : Float,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_custom_postprocess3d(
      scene_texture_id, shader_path, fragment_entry, uniform_x, uniform_y, uniform_z,
      uniform_w, view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_custom_postprocess3d", err)
    }
  }
}
