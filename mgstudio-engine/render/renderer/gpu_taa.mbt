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
// Bevy source: `bevy/crates/bevy_anti_alias/src/taa/mod.rs`.

///|
fn taa_create_history_texture(
  backend : GpuBackend,
  width : Int,
  height : Int,
  format : @wgpu.TextureFormat,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let texture = backend.device.create_texture_u32(
    w,
    h,
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    sample_count=1U,
  )
  texture.set_label(label)
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    texture_view_aspect_for_format(format),
    0U,
    1U,
    0U,
    1U,
  )
  view.set_label("\{label}_view")
  (texture, view)
}

///|
fn taa_history_matches(
  history : GpuTaaHistoryTextures,
  camera_key_hi : Int,
  camera_key_lo : Int,
  width : Int,
  height : Int,
  format : @wgpu.TextureFormat,
) -> Bool {
  history.camera_key_hi == camera_key_hi &&
  history.camera_key_lo == camera_key_lo &&
  history.width == width &&
  history.height == height &&
  history.format == format
}

///|
fn GpuBackend::taa_history_get_or_create(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  width : Int,
  height : Int,
  format : @wgpu.TextureFormat,
) -> (GpuTaaHistoryTextures, Bool) {
  for history in self.taa_history_textures {
    if taa_history_matches(
        history, camera_key_hi, camera_key_lo, width, height, format,
      ) {
      return (history, false)
    }
  }
  let (texture_0, view_0) = taa_create_history_texture(
    self, width, height, format, "mgstudio_taa_history_1_texture",
  )
  let (texture_1, view_1) = taa_create_history_texture(
    self, width, height, format, "mgstudio_taa_history_2_texture",
  )
  let history = GpuTaaHistoryTextures::{
    camera_key_hi,
    camera_key_lo,
    width,
    height,
    format,
    texture_0,
    view_0,
    texture_1,
    view_1,
    next_write_index: 0,
  }
  self.taa_history_textures.push(history)
  (history, true)
}

///|
fn ensure_taa_layouts(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.taa_bgl is None {
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
    let ok = builder.add_texture(
        0U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        2U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(4U, frag, @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING) &&
      builder.add_sampler(5U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build TAA bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_taa_bind_group_layout",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
    pipeline_layout.set_label("mgstudio_taa_pipeline_layout")
    backend.taa_bgl = Some(bgl)
    backend.taa_pipeline_layout = Some(pipeline_layout)
  }
  if backend.taa_nearest_sampler is None {
    backend.taa_nearest_sampler = Some(
      backend.device.create_sampler_nearest_clamp(),
    )
  }
  if backend.taa_linear_sampler is None {
    backend.taa_linear_sampler = Some(
      backend.device.create_sampler_linear_clamp(),
    )
  }
}

///|
fn taa_pipeline_cache_get(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  tonemap : Bool,
  reset : Bool,
) -> GpuTaaPipelineCacheEntry? {
  for entry in backend.taa_pipeline_cache {
    if entry.format == format &&
      entry.tonemap == tonemap &&
      entry.reset == reset {
      return Some(entry)
    }
  }
  None
}

///|
fn taa_pipeline_get_or_create(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  tonemap : Bool,
  reset : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_taa_layouts(backend)
  match taa_pipeline_cache_get(backend, format, tonemap, reset) {
    Some(entry) => return Some(entry.pipeline)
    None => ()
  }
  guard backend.taa_pipeline_layout is Some(pipeline_layout) else {
    return None
  }
  let define_keys : Array[String] = []
  if tonemap {
    define_keys.push("TONEMAP")
  }
  if reset {
    define_keys.push("RESET")
  }
  let sources = load_fullscreen_postprocess_wgsl_modules_with_defines_required(
    backend, "anti_alias/taa/taa.wgsl", define_keys,
  )
  let vertex_sm = create_postprocess_shader_module(
    backend,
    sources.vertex_source,
    "mgstudio_taa postprocess vertex",
  )
  let fragment_sm = create_postprocess_shader_module(
    backend,
    sources.fragment_source,
    "mgstudio_taa postprocess fragment",
  ) catch {
    err => {
      vertex_sm.release()
      raise err
    }
  }
  let builder = @wgpu.RenderPipelineDescBuilder::new(
    vertex_sm,
    layout=pipeline_layout,
  ) catch {
    err => {
      err |> ignore
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build TAA pipeline descriptor")
    }
  }
  try {
    builder.set_entry_points("fullscreen_vertex_shader", "taa")
    builder.set_color_target_count(2U)
    builder.set_color_target_format_at(0U, format)
    builder.set_color_target_format_at(1U, format)
  } catch {
    err => {
      err |> ignore
      builder.free()
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to configure TAA pipeline descriptor")
    }
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = try {
    builder.set_vertex_module(vertex_sm)
    builder.set_fragment_module(fragment_sm)
    let desc = builder.finish_descriptor_ptr()
    let pipeline = backend.device.create_render_pipeline_ptr(desc)
    @wgpu_c.render_pipeline_descriptor_free(desc)
    builder.free()
    pipeline
  } catch {
    err => {
      err |> ignore
      ignore(backend.device.pop_error_scope_sync_result(backend.instance))
      builder.free()
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to build TAA pipeline descriptor")
    }
  }
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to create TAA pipeline",
    )
    pipeline.release()
    vertex_sm.release()
    fragment_sm.release()
    fatal(message)
  }
  pipeline.set_label("mgstudio_taa_pipeline")
  vertex_sm.release()
  fragment_sm.release()
  backend.taa_pipeline_cache.push({ format, tonemap, reset, pipeline })
  Some(pipeline)
}

///|
pub fn GpuBackend::draw_taa(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  scene_texture_id : Int,
  motion_vector_texture_id : Int,
  depth_texture_id : Int,
  reset : Bool,
  tonemap : Bool,
  view_width : Int,
  view_height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(active_pass) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard self.pass_state is Some(pass_state) else { return }
  if scene_texture_id < 0 ||
    motion_vector_texture_id < 0 ||
    depth_texture_id < 0 {
    return
  }
  guard find_texture(self, scene_texture_id) is Some(scene_texture) else {
    return
  }
  guard find_texture(self, motion_vector_texture_id)
    is Some(motion_vector_texture) else {
    return
  }
  guard find_prepass_depth_texture(self, depth_texture_id)
    is Some(depth_texture) else {
    return
  }
  let format = scene_texture.format
  guard taa_pipeline_get_or_create(self, format, tonemap, reset)
    is Some(pipeline) else {
    return
  }
  guard self.taa_bgl is Some(bind_layout) else { return }
  guard self.taa_nearest_sampler is Some(nearest_sampler) else { return }
  guard self.taa_linear_sampler is Some(linear_sampler) else { return }
  let (history, history_created) = self.taa_history_get_or_create(
    camera_key_hi, camera_key_lo, view_width, view_height, format,
  )
  let effective_reset = reset || history_created
  let write_is_zero = history.next_write_index == 0
  let history_write_view = if write_is_zero {
    history.view_0
  } else {
    history.view_1
  }
  let history_read_view = if write_is_zero {
    history.view_1
  } else {
    history.view_0
  }
  ignore(history.texture_0)
  ignore(history.texture_1)
  let pipeline = if effective_reset == reset {
    pipeline
  } else {
    match taa_pipeline_get_or_create(self, format, tonemap, effective_reset) {
      Some(reset_pipeline) => reset_pipeline
      None => pipeline
    }
  }
  active_pass.end()
  active_pass.release()
  frame.pass = None
  guard target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(dst_view) else {
    reopen_saved_pass(self, pass_state)
    return
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let ok = builder.add_texture_view(0U, scene_texture.view) &&
    builder.add_texture_view(1U, history_read_view) &&
    builder.add_texture_view(2U, motion_vector_texture.view) &&
    builder.add_texture_view(3U, depth_texture.view) &&
    builder.add_sampler(4U, nearest_sampler) &&
    builder.add_sampler(5U, linear_sampler)
  if !ok {
    builder.free()
    reopen_saved_pass(self, pass_state)
    return
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    self, builder, bind_layout, "mgstudio_taa_bind_group", "wgpu: failed to build TAA bind group",
  )
  let pass = frame.encoder.begin_render_pass_color2(
    dst_view, history_write_view,
  )
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
  history.next_write_index = if write_is_zero { 1 } else { 0 }
  reopen_saved_pass(self, pass_state)
}

///|
pub fn draw_taa(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  scene_texture_id~ : Int,
  motion_vector_texture_id~ : Int,
  depth_texture_id~ : Int,
  reset~ : Bool,
  tonemap~ : Bool,
  view_width~ : Int,
  view_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_taa(
      camera_key_hi, camera_key_lo, scene_texture_id, motion_vector_texture_id, depth_texture_id,
      reset, tonemap, view_width, view_height,
    ) catch {
      err => debug_runtime_error("draw_taa", err)
    }
  }
}
