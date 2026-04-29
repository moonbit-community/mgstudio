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
const CAS_UNIFORM_BUFFER_SIZE : UInt64 = 16UL

///|
fn cas_uniform_bytes(sharpness : Float) -> Bytes {
  u32le_pack([f32_bits(sharpness), 0U, 0U, 0U])
}

///|
fn cas_sharpness_clamped(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn ensure_cas_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.cas_bgl is None {
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
      fatal("wgpu: failed to build CAS bind group layout")
    }
    let bgl = builder.finish(backend.device, label="mgstudio_cas_bgl")
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_cas_pipeline_layout")
    backend.cas_bgl = Some(bgl)
    backend.cas_pipeline_layout = Some(pipeline_layout)
  }
  if backend.cas_sampler is None {
    backend.cas_sampler = Some(backend.device.create_sampler_nearest_clamp())
  }
  if backend.cas_uniform_buf is None {
    let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.cas_uniform_buf = Some(
      backend.device.create_buffer(size=CAS_UNIFORM_BUFFER_SIZE, usage~),
    )
  }
}

///|
fn cas_pipeline_cache_get(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  denoise : Bool,
) -> @wgpu.RenderPipeline? {
  for entry in backend.cas_pipeline_cache {
    if entry.surface_format.raw == format.raw && entry.denoise == denoise {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn cas_pipeline_get_or_create(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  denoise : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  if cas_pipeline_cache_get(backend, format, denoise) is Some(pipeline) {
    return Some(pipeline)
  }
  ensure_cas_resources(backend)
  guard backend.cas_pipeline_layout is Some(pipeline_layout) else {
    return None
  }
  let sources = load_fullscreen_postprocess_wgsl_modules_with_defines_required(
    backend,
    "anti_alias/contrast_adaptive_sharpening/robust_contrast_adaptive_sharpening.wgsl",
    if denoise {
      ["RCAS_DENOISE"]
    } else {
      []
    },
  )
  let label_suffix = if denoise { "denoise" } else { "plain" }
  let pipeline = create_postprocess_pipeline_split_modules(
    backend,
    pipeline_layout,
    sources.vertex_source,
    sources.fragment_source,
    format,
    "fragment",
    POSTPROCESS_BLEND_MODE_NONE,
    "mgstudio_cas_\{format.raw.to_string()}_\{label_suffix}",
  )
  backend.cas_pipeline_cache.push(CasPipelineCacheEntry::{
    surface_format: format,
    denoise,
    pipeline,
  })
  Some(pipeline)
}

///|
pub fn GpuBackend::draw_contrast_adaptive_sharpening(
  self : GpuBackend,
  scene_texture_id : Int,
  sharpness : Float,
  denoise : Bool,
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
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  let format = match current_pass_color_format(self) {
    Some(format) => format
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  guard cas_pipeline_get_or_create(self, format, denoise) is Some(pipeline) else {
    return
  }
  guard self.cas_bgl is Some(bind_layout) else { return }
  guard self.cas_sampler is Some(sampler) else { return }
  guard self.cas_uniform_buf is Some(uniform_buf) else { return }
  self.queue.write_buffer(
    uniform_buf,
    0UL,
    cas_uniform_bytes(cas_sharpness_clamped(sharpness)),
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
        label="mgstudio_cas_bind_group",
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
pub fn draw_contrast_adaptive_sharpening(
  scene_texture_id~ : Int,
  sharpness~ : Float,
  denoise~ : Bool,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_contrast_adaptive_sharpening(
      scene_texture_id, sharpness, denoise, view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_contrast_adaptive_sharpening", err)
    }
  }
}
