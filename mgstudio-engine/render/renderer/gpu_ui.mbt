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
const UI_VIEW_BUFFER_SIZE : UInt64 = 1024UL

///|
const UI_VERTEX_STRIDE_BYTES : UInt64 = 88UL

///|
const UI_DRAW_FLAG_ANTIALIAS : Int = 4

///|
const UI_GLOBALS_BUFFER_SIZE : UInt64 = 16UL

///|
const UI_TEXTURE_SLICE_VERTEX_STRIDE_BYTES : UInt64 = 100UL

///|
const UI_BOX_SHADOW_VERTEX_STRIDE_BYTES : UInt64 = 72UL

///|
fn ui_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  let words : Array[UInt] = [
    f32_bits(pass_state.clip_from_world.x_axis_x),
    f32_bits(pass_state.clip_from_world.x_axis_y),
    f32_bits(pass_state.clip_from_world.x_axis_z),
    f32_bits(pass_state.clip_from_world.x_axis_w),
    f32_bits(pass_state.clip_from_world.y_axis_x),
    f32_bits(pass_state.clip_from_world.y_axis_y),
    f32_bits(pass_state.clip_from_world.y_axis_z),
    f32_bits(pass_state.clip_from_world.y_axis_w),
    f32_bits(pass_state.clip_from_world.z_axis_x),
    f32_bits(pass_state.clip_from_world.z_axis_y),
    f32_bits(pass_state.clip_from_world.z_axis_z),
    f32_bits(pass_state.clip_from_world.z_axis_w),
    f32_bits(pass_state.clip_from_world.w_axis_x),
    f32_bits(pass_state.clip_from_world.w_axis_y),
    f32_bits(pass_state.clip_from_world.w_axis_z),
    f32_bits(pass_state.clip_from_world.w_axis_w),
  ]
  let target_word_count = (UI_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in words.length()..<target_word_count {
    words.push(0U)
  }
  u32le_pack(words)
}

///|
fn ui_globals_uniform_bytes() -> Bytes {
  u32le_pack([0U, 0U, 0U, 0U])
}

///|
fn load_ui_node_wgsl(anti_alias : Bool) -> String raise GpuBackendError {
  let modules = copy_registered_wgsl_import_module_paths()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  if anti_alias {
    defines.set("ANTI_ALIAS", true)
  }
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  load_wgsl_preprocessed(
    "", "shaders/bevy_ui_render/ui.wgsl", defines, value_defines, visited, modules,
  )
}

///|
fn create_ui_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  anti_alias : Bool,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  guard backend.ui_pipeline_layout is Some(layout) else {
    fatal("wgpu: ui pipeline layout is None")
  }
  let wgsl = load_ui_node_wgsl(anti_alias)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(format)
    builder.enable_alpha_blend()
    builder.set_vertex_buffer_layout(
      UI_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 20UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_UINT32, 36UL, 3U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 40UL, 4U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 56UL, 5U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 72UL, 6U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 80UL, 7U)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build ui render pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn ui_box_shadow_sample_count(samples : Int) -> Int {
  if samples < 1 {
    1
  } else if samples > 64 {
    64
  } else {
    samples
  }
}

///|
fn load_ui_box_shadow_wgsl(samples : Int) -> String raise GpuBackendError {
  let modules = copy_registered_wgsl_import_module_paths()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  value_defines.set("SHADOW_SAMPLES", ui_box_shadow_sample_count(samples))
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  load_wgsl_preprocessed(
    "", "shaders/bevy_ui_render/box_shadow.wgsl", defines, value_defines, visited,
    modules,
  )
}

///|
fn create_ui_shadow_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  samples : Int,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  guard backend.ui_shadow_pipeline_layout is Some(layout) else {
    fatal("wgpu: ui box shadow pipeline layout is None")
  }
  let wgsl = load_ui_box_shadow_wgsl(samples)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(format)
    builder.enable_alpha_blend()
    builder.set_vertex_buffer_layout(
      UI_BOX_SHADOW_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 20UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 36UL, 3U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 44UL, 4U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32, 60UL, 5U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 64UL, 6U)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build ui box shadow pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn load_ui_texture_slice_wgsl() -> String raise GpuBackendError {
  let modules = copy_registered_wgsl_import_module_paths()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  load_wgsl_preprocessed(
    "", "shaders/bevy_ui_render/ui_texture_slice.wgsl", defines, value_defines, visited,
    modules,
  )
}

///|
fn create_ui_slice_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  guard backend.ui_slice_pipeline_layout is Some(layout) else {
    fatal("wgpu: ui texture slice pipeline layout is None")
  }
  let wgsl = load_ui_texture_slice_wgsl()
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(format)
    builder.enable_alpha_blend()
    builder.set_vertex_buffer_layout(
      UI_TEXTURE_SLICE_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 20UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 36UL, 3U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 52UL, 4U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 68UL, 5U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 84UL, 6U)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build ui texture slice pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn ensure_ui_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_view_bgl is None {
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let ok = view_builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    )
    if !ok {
      view_builder.free()
      fatal("wgpu: failed to build ui view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_ui_view_bind_group_layout",
    )
    guard backend.sprite_texture_bgl is Some(texture_bgl) else { return }
    let pipeline_layout = backend.device.create_pipeline_layout_2(
      view_bgl, texture_bgl,
    )
    pipeline_layout.set_label("mgstudio_ui_pipeline_layout")
    backend.ui_view_bgl = Some(view_bgl)
    backend.ui_pipeline_layout = Some(pipeline_layout)
  }
  if backend.ui_view_buf is None {
    backend.ui_view_buf = Some(
      backend.device.create_buffer(
        size=UI_VIEW_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.ui_view_bg = None
  }
  if backend.ui_view_bg is None {
    guard backend.ui_view_bgl is Some(layout) else { return }
    guard backend.ui_view_buf is Some(view_buf) else { return }
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(0U, view_buf, size=UI_VIEW_BUFFER_SIZE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build ui view bind group")
    }
    backend.ui_view_bg = Some(
      builder.finish(
        backend.device,
        layout,
        label="mgstudio_ui_view_bind_group",
      ),
    )
  }
  if backend.ui_vertex_buf is Some(_) {
    return
  }
  let vertex_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vertex_cap = 65536UL
  let vertex_buf = backend.device.create_buffer(
    size=vertex_cap,
    usage=vertex_usage,
  )
  backend.ui_vertex_buf = Some(vertex_buf)
  backend.ui_vertex_capacity = vertex_cap
  backend.ui_vertex_data.clear()
  backend.ui_batches.clear()
  backend.ui_vertex_count = 0U
}

///|
fn ensure_ui_pipeline_rgba8(
  backend : GpuBackend,
  anti_alias : Bool,
) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if anti_alias && backend.ui_pipeline_anti_alias is Some(_) {
    return
  }
  if !anti_alias && backend.ui_pipeline is Some(_) {
    return
  }
  let pipeline = create_ui_pipeline(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    anti_alias,
    if anti_alias {
      "mgstudio_ui_rgba8_anti_alias"
    } else {
      "mgstudio_ui_rgba8"
    },
  )
  if anti_alias {
    backend.ui_pipeline_anti_alias = Some(pipeline)
  } else {
    backend.ui_pipeline = Some(pipeline)
  }
}

///|
fn ensure_ui_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  anti_alias : Bool,
) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  let cached_for_format = if anti_alias {
    backend.ui_pipeline_surface_anti_alias is Some(_)
  } else {
    backend.ui_pipeline_surface is Some(_)
  }
  if backend.ui_pipeline_surface_format is Some(prev) &&
    prev == format &&
    cached_for_format {
    return
  }
  let label = if anti_alias {
    "mgstudio_ui_surface_anti_alias"
  } else {
    "mgstudio_ui_surface"
  }
  if anti_alias {
    if backend.ui_pipeline_surface_anti_alias is Some(old) {
      old.release()
    }
  } else if backend.ui_pipeline_surface is Some(old) {
    old.release()
  }
  let pipeline = create_ui_pipeline(backend, format, anti_alias, label)
  if anti_alias {
    backend.ui_pipeline_surface_anti_alias = Some(pipeline)
  } else {
    backend.ui_pipeline_surface = Some(pipeline)
  }
  backend.ui_pipeline_surface_format = Some(format)
}

///|
fn ui_pipeline_for_current_pass(
  backend : GpuBackend,
  anti_alias : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_pipeline_surface(backend, format, anti_alias)
      if anti_alias {
        backend.ui_pipeline_surface_anti_alias
      } else {
        backend.ui_pipeline_surface
      }
    }
    _ => {
      ensure_ui_pipeline_rgba8(backend, anti_alias)
      if anti_alias {
        backend.ui_pipeline_anti_alias
      } else {
        backend.ui_pipeline
      }
    }
  }
}

///|
fn ensure_ui_shadow_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_shadow_view_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    )
    if !ok {
      builder.free()
      fatal("wgpu: failed to build ui box shadow view bind group layout")
    }
    let view_bgl = builder.finish(
      backend.device,
      label="mgstudio_ui_box_shadow_view_bind_group_layout",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_1(view_bgl)
    pipeline_layout.set_label("mgstudio_ui_box_shadow_pipeline_layout")
    backend.ui_shadow_view_bgl = Some(view_bgl)
    backend.ui_shadow_pipeline_layout = Some(pipeline_layout)
  }
  if backend.ui_shadow_view_buf is None {
    backend.ui_shadow_view_buf = Some(
      backend.device.create_buffer(
        size=UI_VIEW_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.ui_shadow_view_bg = None
  }
  if backend.ui_shadow_view_bg is None {
    guard backend.ui_shadow_view_bgl is Some(layout) else { return }
    guard backend.ui_shadow_view_buf is Some(view_buf) else { return }
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(0U, view_buf, size=UI_VIEW_BUFFER_SIZE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build ui box shadow view bind group")
    }
    backend.ui_shadow_view_bg = Some(
      builder.finish(
        backend.device,
        layout,
        label="mgstudio_ui_box_shadow_view_bind_group",
      ),
    )
  }
  if backend.ui_shadow_vertex_buf is Some(_) {
    return
  }
  let vertex_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vertex_cap = 65536UL
  let vertex_buf = backend.device.create_buffer(
    size=vertex_cap,
    usage=vertex_usage,
  )
  backend.ui_shadow_vertex_buf = Some(vertex_buf)
  backend.ui_shadow_vertex_capacity = vertex_cap
  backend.ui_shadow_vertex_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_vertex_count = 0U
}

///|
fn ui_shadow_pipeline_for_current_pass(
  backend : GpuBackend,
  samples : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  let format = match current_pass_color_format(backend) {
    Some(value) => value
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let effective_samples = ui_box_shadow_sample_count(samples)
  for entry in backend.ui_shadow_pipeline_cache {
    if entry.format == format && entry.samples == effective_samples {
      return Some(entry.pipeline)
    }
  }
  let label = "mgstudio_ui_box_shadow_\{format.to_u32().reinterpret_as_int().to_string()}_\{effective_samples.to_string()}"
  let pipeline = create_ui_shadow_pipeline(
    backend, format, effective_samples, label,
  )
  backend.ui_shadow_pipeline_cache.push(UiShadowPipelineCacheEntry::{
    format,
    samples: effective_samples,
    pipeline,
  })
  Some(pipeline)
}

///|
fn ensure_ui_slice_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_slice_view_bgl is None {
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
    let view_ok = view_builder.add_buffer(
        0U,
        ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_buffer(
        1U,
        ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build ui texture slice view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_ui_texture_slice_view_bind_group_layout",
    )
    guard backend.sprite_texture_bgl is Some(texture_bgl) else { return }
    let pipeline_layout = backend.device.create_pipeline_layout_2(
      view_bgl, texture_bgl,
    )
    pipeline_layout.set_label("mgstudio_ui_texture_slice_pipeline_layout")
    backend.ui_slice_view_bgl = Some(view_bgl)
    backend.ui_slice_pipeline_layout = Some(pipeline_layout)
  }
  if backend.ui_slice_view_buf is None {
    backend.ui_slice_view_buf = Some(
      backend.device.create_buffer(
        size=UI_VIEW_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.ui_slice_view_bg = None
  }
  if backend.ui_slice_globals_buf is None {
    backend.ui_slice_globals_buf = Some(
      backend.device.create_buffer(
        size=UI_GLOBALS_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.ui_slice_view_bg = None
  }
  if backend.ui_slice_view_bg is None {
    guard backend.ui_slice_view_bgl is Some(layout) else { return }
    guard backend.ui_slice_view_buf is Some(view_buf) else { return }
    guard backend.ui_slice_globals_buf is Some(globals_buf) else { return }
    let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
    let ok = builder.add_buffer(0U, view_buf, size=UI_VIEW_BUFFER_SIZE) &&
      builder.add_buffer(1U, globals_buf, size=UI_GLOBALS_BUFFER_SIZE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build ui texture slice view bind group")
    }
    backend.ui_slice_view_bg = Some(
      builder.finish(
        backend.device,
        layout,
        label="mgstudio_ui_texture_slice_view_bind_group",
      ),
    )
  }
  if backend.ui_slice_vertex_buf is Some(_) {
    return
  }
  let vertex_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vertex_cap = 65536UL
  let vertex_buf = backend.device.create_buffer(
    size=vertex_cap,
    usage=vertex_usage,
  )
  backend.ui_slice_vertex_buf = Some(vertex_buf)
  backend.ui_slice_vertex_capacity = vertex_cap
  backend.ui_slice_vertex_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_vertex_count = 0U
}

///|
fn ensure_ui_slice_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  if backend.ui_slice_pipeline is Some(_) {
    return
  }
  let pipeline = create_ui_slice_pipeline(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    "mgstudio_ui_texture_slice_rgba8",
  )
  backend.ui_slice_pipeline = Some(pipeline)
}

///|
fn ensure_ui_slice_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_slice_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_slice_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_slice_pipeline_surface is Some(old) {
    old.release()
  }
  let pipeline = create_ui_slice_pipeline(
    backend, format, "mgstudio_ui_texture_slice_surface",
  )
  backend.ui_slice_pipeline_surface = Some(pipeline)
  backend.ui_slice_pipeline_surface_format = Some(format)
}

///|
fn ui_slice_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_slice_pipeline_surface(backend, format)
      backend.ui_slice_pipeline_surface
    }
    _ => {
      ensure_ui_slice_pipeline_rgba8(backend)
      backend.ui_slice_pipeline
    }
  }
}

///|
fn ui_push_vertex(
  words : Array[UInt],
  center_x : Float,
  center_y : Float,
  cosv : Float,
  sinv : Float,
  local_x : Float,
  local_y : Float,
  uv_x : Float,
  uv_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
  size_x : Float,
  size_y : Float,
) -> Unit {
  let rotated_x = local_x * cosv - local_y * sinv
  let rotated_y = local_x * sinv + local_y * cosv
  words.push(f32_bits(center_x + rotated_x))
  words.push(f32_bits(center_y + rotated_y))
  words.push(f32_bits(0.0F))
  words.push(f32_bits(uv_x))
  words.push(f32_bits(uv_y))
  words.push(f32_bits(color_r))
  words.push(f32_bits(color_g))
  words.push(f32_bits(color_b))
  words.push(f32_bits(color_a))
  words.push(flags.reinterpret_as_uint())
  words.push(f32_bits(radius_tl))
  words.push(f32_bits(radius_tr))
  words.push(f32_bits(radius_br))
  words.push(f32_bits(radius_bl))
  words.push(f32_bits(border_left))
  words.push(f32_bits(border_top))
  words.push(f32_bits(border_right))
  words.push(f32_bits(border_bottom))
  words.push(f32_bits(size_x))
  words.push(f32_bits(size_y))
  words.push(f32_bits(local_x))
  words.push(f32_bits(-local_y))
}

///|
fn ui_enqueue_rect(
  backend : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
) -> Unit raise GpuBackendError {
  guard resolve_draw_texture(backend, texture_id) is Some(tex) else { return }
  let anti_alias = (flags & UI_DRAW_FLAG_ANTIALIAS) != 0
  let shader_flags = flags - (flags & UI_DRAW_FLAG_ANTIALIAS)
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let half_width = scale_x * 0.5F
  let half_height = scale_y * 0.5F
  let size_x = half_width.abs() * 2.0F
  let size_y = half_height.abs() * 2.0F
  let first_vertex = backend.ui_vertex_count
  backend.ui_vertex_count = first_vertex + 6U
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    uv_min_x,
    uv_min_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    -half_height,
    uv_min_x,
    uv_max_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    uv_max_x,
    uv_max_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    uv_min_x,
    uv_min_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    uv_max_x,
    uv_max_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  ui_push_vertex(
    backend.ui_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    half_height,
    uv_max_x,
    uv_min_y,
    color_r,
    color_g,
    color_b,
    color_a,
    shader_flags,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    border_left,
    border_top,
    border_right,
    border_bottom,
    size_x,
    size_y,
  )
  let batch_count = backend.ui_batches.length()
  if batch_count > 0 &&
    backend.ui_batches[batch_count - 1].texture_id == tex.id &&
    backend.ui_batches[batch_count - 1].anti_alias == anti_alias {
    backend.ui_batches[batch_count - 1].instance_count = backend.ui_batches[batch_count -
      1].instance_count +
      6U
  } else {
    backend.ui_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance: first_vertex,
      instance_count: 6U,
      anti_alias,
    })
  }
}

///|
fn ui_slice_push_vertex(
  words : Array[UInt],
  center_x : Float,
  center_y : Float,
  cosv : Float,
  sinv : Float,
  local_x : Float,
  local_y : Float,
  uv_x : Float,
  uv_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit {
  let rotated_x = local_x * cosv - local_y * sinv
  let rotated_y = local_x * sinv + local_y * cosv
  words.push(f32_bits(center_x + rotated_x))
  words.push(f32_bits(center_y + rotated_y))
  words.push(f32_bits(0.0F))
  words.push(f32_bits(uv_x))
  words.push(f32_bits(uv_y))
  words.push(f32_bits(color_r))
  words.push(f32_bits(color_g))
  words.push(f32_bits(color_b))
  words.push(f32_bits(color_a))
  words.push(f32_bits(texture_slice_l))
  words.push(f32_bits(texture_slice_t))
  words.push(f32_bits(texture_slice_r))
  words.push(f32_bits(texture_slice_b))
  words.push(f32_bits(target_slice_l))
  words.push(f32_bits(target_slice_t))
  words.push(f32_bits(target_slice_r))
  words.push(f32_bits(target_slice_b))
  words.push(f32_bits(repeat_side_x))
  words.push(f32_bits(repeat_side_y))
  words.push(f32_bits(repeat_center_x))
  words.push(f32_bits(repeat_center_y))
  words.push(f32_bits(atlas_l))
  words.push(f32_bits(atlas_t))
  words.push(f32_bits(atlas_r))
  words.push(f32_bits(atlas_b))
}

///|
fn ui_enqueue_texture_slice(
  backend : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit raise GpuBackendError {
  guard resolve_draw_texture(backend, texture_id) is Some(tex) else { return }
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let half_width = scale_x * 0.5F
  let half_height = scale_y * 0.5F
  let first_vertex = backend.ui_slice_vertex_count
  backend.ui_slice_vertex_count = first_vertex + 6U
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    0.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    -half_height,
    0.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    1.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    0.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    1.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  ui_slice_push_vertex(
    backend.ui_slice_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    half_height,
    1.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_slice_l,
    texture_slice_t,
    texture_slice_r,
    texture_slice_b,
    target_slice_l,
    target_slice_t,
    target_slice_r,
    target_slice_b,
    repeat_side_x,
    repeat_side_y,
    repeat_center_x,
    repeat_center_y,
    atlas_l,
    atlas_t,
    atlas_r,
    atlas_b,
  )
  let batch_count = backend.ui_slice_batches.length()
  if batch_count > 0 &&
    backend.ui_slice_batches[batch_count - 1].texture_id == tex.id {
    backend.ui_slice_batches[batch_count - 1].instance_count = backend.ui_slice_batches[batch_count -
      1].instance_count +
      6U
  } else {
    backend.ui_slice_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance: first_vertex,
      instance_count: 6U,
      anti_alias: false,
    })
  }
}

///|
fn ui_shadow_push_vertex(
  words : Array[UInt],
  center_x : Float,
  center_y : Float,
  cosv : Float,
  sinv : Float,
  local_x : Float,
  local_y : Float,
  uv_x : Float,
  uv_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  bounds_x : Float,
  bounds_y : Float,
) -> Unit {
  let rotated_x = local_x * cosv - local_y * sinv
  let rotated_y = local_x * sinv + local_y * cosv
  words.push(f32_bits(center_x + rotated_x))
  words.push(f32_bits(center_y + rotated_y))
  words.push(f32_bits(0.0F))
  words.push(f32_bits(uv_x))
  words.push(f32_bits(uv_y))
  words.push(f32_bits(color_r))
  words.push(f32_bits(color_g))
  words.push(f32_bits(color_b))
  words.push(f32_bits(color_a))
  words.push(f32_bits(size_x))
  words.push(f32_bits(size_y))
  words.push(f32_bits(radius_tl))
  words.push(f32_bits(radius_tr))
  words.push(f32_bits(radius_br))
  words.push(f32_bits(radius_bl))
  words.push(f32_bits(blur))
  words.push(f32_bits(bounds_x))
  words.push(f32_bits(bounds_y))
}

///|
fn ui_enqueue_box_shadow(
  backend : GpuBackend,
  x : Float,
  y : Float,
  rotation : Float,
  bounds_x : Float,
  bounds_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  samples : Int,
) -> Unit {
  let effective_samples = ui_box_shadow_sample_count(samples)
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let half_width = bounds_x * 0.5F
  let half_height = bounds_y * 0.5F
  let first_vertex = backend.ui_shadow_vertex_count
  backend.ui_shadow_vertex_count = first_vertex + 6U
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    0.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    -half_height,
    0.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    1.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    -half_width,
    half_height,
    0.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    -half_height,
    1.0F,
    1.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  ui_shadow_push_vertex(
    backend.ui_shadow_vertex_data,
    x,
    y,
    cosv,
    sinv,
    half_width,
    half_height,
    1.0F,
    0.0F,
    color_r,
    color_g,
    color_b,
    color_a,
    size_x,
    size_y,
    radius_tl,
    radius_tr,
    radius_br,
    radius_bl,
    blur,
    bounds_x,
    bounds_y,
  )
  let batch_count = backend.ui_shadow_batches.length()
  if batch_count > 0 &&
    backend.ui_shadow_batches[batch_count - 1].samples == effective_samples {
    backend.ui_shadow_batches[batch_count - 1].instance_count = backend.ui_shadow_batches[batch_count -
      1].instance_count +
      6U
  } else {
    backend.ui_shadow_batches.push(UiShadowBatch::{
      first_instance: first_vertex,
      instance_count: 6U,
      samples: effective_samples,
    })
  }
}

///|
fn flush_ui_shadow_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_shadow_vertex_count == 0U {
    return
  }
  guard backend.pass_state is Some(pass_state) else { return }
  let word_count = backend.ui_shadow_vertex_data.length()
  if word_count <= 0 {
    backend.ui_shadow_vertex_data.clear()
    backend.ui_shadow_batches.clear()
    backend.ui_shadow_vertex_count = 0U
    return
  }
  let required_bytes = (word_count * 4).to_uint64()
  if required_bytes > backend.ui_shadow_vertex_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_shadow_vertex_buf is Some(old) {
      old.release()
    }
    backend.ui_shadow_vertex_buf = Some(new_buf)
    backend.ui_shadow_vertex_capacity = new_cap
  }
  guard backend.ui_shadow_vertex_buf is Some(vertex_buf) else { return }
  guard backend.ui_shadow_view_buf is Some(view_buf) else { return }
  guard backend.ui_shadow_view_bg is Some(view_bg) else { return }
  let bytes = u32le_pack(backend.ui_shadow_vertex_data)
  backend.queue.write_buffer(vertex_buf, 0UL, bytes)
  backend.queue.write_buffer(view_buf, 0UL, ui_view_uniform_bytes(pass_state))
  pass.set_vertex_buffer(0U, vertex_buf, 0UL, required_bytes)
  pass.set_bind_group(0U, view_bg, [])
  for batch in backend.ui_shadow_batches {
    guard ui_shadow_pipeline_for_current_pass(backend, batch.samples)
      is Some(pipeline) else {
      continue
    }
    pass.set_pipeline(pipeline)
    pass.draw(batch.instance_count, 1U, batch.first_instance, 0U)
  }
  backend.ui_shadow_vertex_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_vertex_count = 0U
}

///|
fn flush_ui_slice_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_slice_vertex_count == 0U {
    return
  }
  guard ui_slice_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  guard backend.pass_state is Some(pass_state) else { return }
  let word_count = backend.ui_slice_vertex_data.length()
  if word_count <= 0 {
    backend.ui_slice_vertex_data.clear()
    backend.ui_slice_batches.clear()
    backend.ui_slice_vertex_count = 0U
    return
  }
  let required_bytes = (word_count * 4).to_uint64()
  if required_bytes > backend.ui_slice_vertex_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_slice_vertex_buf is Some(old) {
      old.release()
    }
    backend.ui_slice_vertex_buf = Some(new_buf)
    backend.ui_slice_vertex_capacity = new_cap
  }
  guard backend.ui_slice_vertex_buf is Some(vertex_buf) else { return }
  guard backend.ui_slice_view_buf is Some(view_buf) else { return }
  guard backend.ui_slice_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_slice_view_bg is Some(view_bg) else { return }
  let bytes = u32le_pack(backend.ui_slice_vertex_data)
  backend.queue.write_buffer(vertex_buf, 0UL, bytes)
  backend.queue.write_buffer(view_buf, 0UL, ui_view_uniform_bytes(pass_state))
  backend.queue.write_buffer(globals_buf, 0UL, ui_globals_uniform_bytes())
  pass.set_pipeline(pipeline)
  pass.set_vertex_buffer(0U, vertex_buf, 0UL, required_bytes)
  pass.set_bind_group(0U, view_bg, [])
  for batch in backend.ui_slice_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(1U, tex.bind_group, [])
    pass.draw(batch.instance_count, 1U, batch.first_instance, 0U)
  }
  backend.ui_slice_vertex_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_vertex_count = 0U
}

///|
fn flush_ui_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_vertex_count == 0U {
    return
  }
  guard backend.pass_state is Some(pass_state) else { return }
  let word_count = backend.ui_vertex_data.length()
  if word_count <= 0 {
    backend.ui_vertex_data.clear()
    backend.ui_batches.clear()
    backend.ui_vertex_count = 0U
    return
  }
  let required_bytes = (word_count * 4).to_uint64()
  if required_bytes > backend.ui_vertex_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_vertex_buf is Some(old) {
      old.release()
    }
    backend.ui_vertex_buf = Some(new_buf)
    backend.ui_vertex_capacity = new_cap
  }
  guard backend.ui_vertex_buf is Some(vertex_buf) else { return }
  guard backend.ui_view_buf is Some(view_buf) else { return }
  guard backend.ui_view_bg is Some(view_bg) else { return }
  let bytes = u32le_pack(backend.ui_vertex_data)
  backend.queue.write_buffer(vertex_buf, 0UL, bytes)
  backend.queue.write_buffer(view_buf, 0UL, ui_view_uniform_bytes(pass_state))
  pass.set_vertex_buffer(0U, vertex_buf, 0UL, required_bytes)
  pass.set_bind_group(0U, view_bg, [])
  for batch in backend.ui_batches {
    guard ui_pipeline_for_current_pass(backend, batch.anti_alias)
      is Some(pipeline) else {
      continue
    }
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_pipeline(pipeline)
    pass.set_bind_group(1U, tex.bind_group, [])
    pass.draw(batch.instance_count, 1U, batch.first_instance, 0U)
  }
  backend.ui_vertex_data.clear()
  backend.ui_batches.clear()
  backend.ui_vertex_count = 0U
}

///|
pub fn GpuBackend::draw_ui_rect(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_sprite_batches(self)
  ensure_ui_resources(self)
  ui_enqueue_rect(
    self, texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b,
    color_a, uv_min_x, uv_min_y, uv_max_x, uv_max_y, flags, radius_tl, radius_tr,
    radius_br, radius_bl, border_left, border_top, border_right, border_bottom,
  )
}

///|
pub fn GpuBackend::draw_ui_texture_slice(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_sprite_batches(self)
  flush_ui_batches(self)
  ensure_ui_slice_resources(self)
  ui_enqueue_texture_slice(
    self, texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b,
    color_a, texture_slice_l, texture_slice_t, texture_slice_r, texture_slice_b,
    target_slice_l, target_slice_t, target_slice_r, target_slice_b, repeat_side_x,
    repeat_side_y, repeat_center_x, repeat_center_y, atlas_l, atlas_t, atlas_r, atlas_b,
  )
}

///|
pub fn GpuBackend::draw_ui_box_shadow(
  self : GpuBackend,
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  samples : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  texture_id |> ignore
  flush_mesh2d_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  ensure_ui_shadow_resources(self)
  ui_enqueue_box_shadow(
    self, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a, size_x,
    size_y, radius_tl, radius_tr, radius_br, radius_bl, blur, samples,
  )
}

///|
pub fn draw_ui_rect(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  uv_min_x~ : Float,
  uv_min_y~ : Float,
  uv_max_x~ : Float,
  uv_max_y~ : Float,
  flags~ : Int,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  border_left~ : Float,
  border_top~ : Float,
  border_right~ : Float,
  border_bottom~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_rect(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      uv_min_x, uv_min_y, uv_max_x, uv_max_y, flags, radius_tl, radius_tr, radius_br,
      radius_bl, border_left, border_top, border_right, border_bottom,
    ) catch {
      err => debug_runtime_error("draw_ui_rect", err)
    }
  }
}

///|
pub fn draw_ui_box_shadow(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  size_x~ : Float,
  size_y~ : Float,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  blur~ : Float,
  samples~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_box_shadow(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      size_x, size_y, radius_tl, radius_tr, radius_br, radius_bl, blur, samples,
    ) catch {
      err => debug_runtime_error("draw_ui_box_shadow", err)
    }
  }
}

///|
pub fn draw_ui_texture_slice(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_slice_l~ : Float,
  texture_slice_t~ : Float,
  texture_slice_r~ : Float,
  texture_slice_b~ : Float,
  target_slice_l~ : Float,
  target_slice_t~ : Float,
  target_slice_r~ : Float,
  target_slice_b~ : Float,
  repeat_side_x~ : Float,
  repeat_side_y~ : Float,
  repeat_center_x~ : Float,
  repeat_center_y~ : Float,
  atlas_l~ : Float,
  atlas_t~ : Float,
  atlas_r~ : Float,
  atlas_b~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_ui_texture_slice(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      texture_slice_l, texture_slice_t, texture_slice_r, texture_slice_b, target_slice_l,
      target_slice_t, target_slice_r, target_slice_b, repeat_side_x, repeat_side_y,
      repeat_center_x, repeat_center_y, atlas_l, atlas_t, atlas_r, atlas_b,
    ) catch {
      err => debug_runtime_error("draw_ui_texture_slice", err)
    }
  }
}
