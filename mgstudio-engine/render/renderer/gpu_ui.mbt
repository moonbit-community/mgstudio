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
fn load_ui_node_wgsl(anti_alias : Bool) -> String raise GpuBackendError {
  let modules = copy_registered_wgsl_import_module_paths()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  if anti_alias {
    defines.set("ANTI_ALIAS", true)
  }
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  load_wgsl_preprocessed(
    "", "shaders/bevy/bevy_ui_render/ui.wgsl", defines, value_defines, visited, modules,
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
  ensure_sprite_resources(backend)
  if backend.ui_shadow_instance_buf is Some(_) {
    return
  }
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.ui_shadow_instance_buf = Some(instance_buf)
  backend.ui_shadow_instance_capacity = instance_cap
  backend.ui_shadow_globals_bg = None
  backend.ui_shadow_instance_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_instance_count = 0U
}

///|
fn ensure_ui_shadow_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  if backend.ui_shadow_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/box_shadow.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_box_shadow_rgba8")
  backend.ui_shadow_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_ui_shadow_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_shadow_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_shadow_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_shadow_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/box_shadow.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_box_shadow_surface")
  backend.ui_shadow_pipeline_surface = Some(pipeline)
  backend.ui_shadow_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn ui_shadow_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_shadow_pipeline_surface(backend, format)
      backend.ui_shadow_pipeline_surface
    }
    _ => {
      ensure_ui_shadow_pipeline_rgba8(backend)
      backend.ui_shadow_pipeline
    }
  }
}

///|
fn ensure_ui_shadow_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_shadow_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_shadow_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui box shadow globals bind group")
  }
  let bg = b.finish(
    backend.device,
    layout,
    label="mgstudio_ui_box_shadow_globals",
  )
  backend.ui_shadow_globals_bg = Some(bg)
}

///|
fn ensure_ui_slice_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_slice_instance_buf is Some(_) {
    return
  }
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.ui_slice_instance_buf = Some(instance_buf)
  backend.ui_slice_instance_capacity = instance_cap
  backend.ui_slice_globals_bg = None
  backend.ui_slice_instance_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_instance_count = 0U
}

///|
fn ensure_ui_slice_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  if backend.ui_slice_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/ui_texture_slice.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_texture_slice_rgba8")
  backend.ui_slice_pipeline = Some(pipeline)
  sm.release()
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
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/ui_texture_slice.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_texture_slice_surface")
  backend.ui_slice_pipeline_surface = Some(pipeline)
  backend.ui_slice_pipeline_surface_format = Some(format)
  sm.release()
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
fn ensure_ui_slice_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_slice_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_slice_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui texture slice globals bind group")
  }
  let bg = b.finish(
    backend.device,
    layout,
    label="mgstudio_ui_texture_slice_globals",
  )
  backend.ui_slice_globals_bg = Some(bg)
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
fn flush_ui_shadow_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_shadow_instance_count == 0U {
    return
  }
  guard ui_shadow_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.ui_shadow_instance_data.length()
  if float_count <= 0 {
    backend.ui_shadow_instance_data.clear()
    backend.ui_shadow_batches.clear()
    backend.ui_shadow_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_shadow_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_shadow_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_shadow_instance_buf = Some(new_buf)
    backend.ui_shadow_instance_capacity = new_cap
    backend.ui_shadow_globals_bg = None
  }
  ensure_ui_shadow_globals_bind_group(backend)
  guard backend.ui_shadow_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_shadow_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_shadow_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_shadow_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_shadow_instance_data.clear()
  backend.ui_shadow_batches.clear()
  backend.ui_shadow_instance_count = 0U
}

///|
fn flush_ui_slice_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.ui_slice_instance_count == 0U {
    return
  }
  guard ui_slice_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.ui_slice_instance_data.length()
  if float_count <= 0 {
    backend.ui_slice_instance_data.clear()
    backend.ui_slice_batches.clear()
    backend.ui_slice_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_slice_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_slice_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_slice_instance_buf = Some(new_buf)
    backend.ui_slice_instance_capacity = new_cap
    backend.ui_slice_globals_bg = None
  }
  ensure_ui_slice_globals_bind_group(backend)
  guard backend.ui_slice_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_slice_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_slice_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_slice_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_slice_instance_data.clear()
  backend.ui_slice_batches.clear()
  backend.ui_slice_instance_count = 0U
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
  flush_ui_shadow_batches(self)
  flush_sprite_batches(self)
  flush_ui_batches(self)
  ensure_ui_slice_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }
  let base_size = 128.0F
  let ui_scale_x = scale_x / base_size
  let ui_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_slice_instance_count
  self.ui_slice_instance_count = first_instance + 1U
  self.ui_slice_instance_data.push(x)
  self.ui_slice_instance_data.push(y)
  self.ui_slice_instance_data.push(cosv)
  self.ui_slice_instance_data.push(sinv)
  self.ui_slice_instance_data.push(ui_scale_x)
  self.ui_slice_instance_data.push(ui_scale_y)
  self.ui_slice_instance_data.push(0.0F)
  self.ui_slice_instance_data.push(0.0F)
  self.ui_slice_instance_data.push(color_r)
  self.ui_slice_instance_data.push(color_g)
  self.ui_slice_instance_data.push(color_b)
  self.ui_slice_instance_data.push(color_a)
  self.ui_slice_instance_data.push(texture_slice_l)
  self.ui_slice_instance_data.push(texture_slice_t)
  self.ui_slice_instance_data.push(texture_slice_r)
  self.ui_slice_instance_data.push(texture_slice_b)
  self.ui_slice_instance_data.push(target_slice_l)
  self.ui_slice_instance_data.push(target_slice_t)
  self.ui_slice_instance_data.push(target_slice_r)
  self.ui_slice_instance_data.push(target_slice_b)
  self.ui_slice_instance_data.push(repeat_side_x)
  self.ui_slice_instance_data.push(repeat_side_y)
  self.ui_slice_instance_data.push(repeat_center_x)
  self.ui_slice_instance_data.push(repeat_center_y)
  self.ui_slice_instance_data.push(atlas_l)
  self.ui_slice_instance_data.push(atlas_t)
  self.ui_slice_instance_data.push(atlas_r)
  self.ui_slice_instance_data.push(atlas_b)
  let batch_count = self.ui_slice_batches.length()
  if batch_count > 0 &&
    self.ui_slice_batches[batch_count - 1].texture_id == tex.id {
    self.ui_slice_batches[batch_count - 1].instance_count = self.ui_slice_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_slice_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
      anti_alias: false,
    })
  }
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
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  ensure_ui_shadow_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }
  let base_size = 128.0F
  let shadow_scale_x = scale_x / base_size
  let shadow_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_shadow_instance_count
  self.ui_shadow_instance_count = first_instance + 1U
  let samples_f = Float::from_double(samples.to_double())
  self.ui_shadow_instance_data.push(x)
  self.ui_shadow_instance_data.push(y)
  self.ui_shadow_instance_data.push(cosv)
  self.ui_shadow_instance_data.push(sinv)
  self.ui_shadow_instance_data.push(shadow_scale_x)
  self.ui_shadow_instance_data.push(shadow_scale_y)
  self.ui_shadow_instance_data.push(0.0F)
  self.ui_shadow_instance_data.push(0.0F)
  self.ui_shadow_instance_data.push(color_r)
  self.ui_shadow_instance_data.push(color_g)
  self.ui_shadow_instance_data.push(color_b)
  self.ui_shadow_instance_data.push(color_a)
  self.ui_shadow_instance_data.push(size_x)
  self.ui_shadow_instance_data.push(size_y)
  self.ui_shadow_instance_data.push(blur)
  self.ui_shadow_instance_data.push(samples_f)
  self.ui_shadow_instance_data.push(radius_tl)
  self.ui_shadow_instance_data.push(radius_tr)
  self.ui_shadow_instance_data.push(radius_br)
  self.ui_shadow_instance_data.push(radius_bl)
  let batch_count = self.ui_shadow_batches.length()
  if batch_count > 0 &&
    self.ui_shadow_batches[batch_count - 1].texture_id == tex.id {
    self.ui_shadow_batches[batch_count - 1].instance_count = self.ui_shadow_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_shadow_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
      anti_alias: false,
    })
  }
}
