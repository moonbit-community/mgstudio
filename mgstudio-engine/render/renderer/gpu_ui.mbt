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
fn ensure_ui_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.ui_instance_buf is Some(_) {
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
  backend.ui_instance_buf = Some(instance_buf)
  backend.ui_instance_capacity = instance_cap
  backend.ui_globals_bg = None
  backend.ui_instance_data.clear()
  backend.ui_batches.clear()
  backend.ui_instance_count = 0U
}

///|
fn ensure_ui_pipeline_rgba8(backend : GpuBackend) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if backend.ui_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/ui.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_rgba8")
  backend.ui_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_ui_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.ui_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.ui_pipeline_surface is Some(_) {
    return
  }
  if backend.ui_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/bevy/mgstudio_runtime/ui/ui.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_ui_surface")
  backend.ui_pipeline_surface = Some(pipeline)
  backend.ui_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn ui_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_ui_pipeline_surface(backend, format)
      backend.ui_pipeline_surface
    }
    _ => {
      ensure_ui_pipeline_rgba8(backend)
      backend.ui_pipeline
    }
  }
}

///|
fn ensure_ui_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.ui_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.ui_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build ui globals bind group")
  }
  let bg = b.finish(backend.device, layout, label="mgstudio_ui_globals")
  backend.ui_globals_bg = Some(bg)
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
  if backend.ui_instance_count == 0U {
    return
  }
  guard ui_pipeline_for_current_pass(backend) is Some(pipeline) else { return }
  let float_count = backend.ui_instance_data.length()
  if float_count <= 0 {
    backend.ui_instance_data.clear()
    backend.ui_batches.clear()
    backend.ui_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.ui_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.ui_instance_buf is Some(old) {
      old.release()
    }
    backend.ui_instance_buf = Some(new_buf)
    backend.ui_instance_capacity = new_cap
    backend.ui_globals_bg = None
  }
  ensure_ui_globals_bind_group(backend)
  guard backend.ui_instance_buf is Some(instance_buf) else { return }
  guard backend.ui_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.ui_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.ui_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_instance_data.clear()
  backend.ui_batches.clear()
  backend.ui_instance_count = 0U
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
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }
  let raw_uv_scale_x = uv_max_x - uv_min_x
  let raw_uv_scale_y = uv_max_y - uv_min_y
  let uv_scale_x = if raw_uv_scale_x <= 0.0F { 1.0F } else { raw_uv_scale_x }
  let uv_scale_y = if raw_uv_scale_y <= 0.0F { 1.0F } else { raw_uv_scale_y }
  let base_size = 128.0F
  let ui_scale_x = scale_x / base_size
  let ui_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_instance_count
  self.ui_instance_count = first_instance + 1U
  let flags_f = Float::from_double(flags.to_double())
  self.ui_instance_data.push(x)
  self.ui_instance_data.push(y)
  self.ui_instance_data.push(cosv)
  self.ui_instance_data.push(sinv)
  self.ui_instance_data.push(ui_scale_x)
  self.ui_instance_data.push(ui_scale_y)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(color_r)
  self.ui_instance_data.push(color_g)
  self.ui_instance_data.push(color_b)
  self.ui_instance_data.push(color_a)
  self.ui_instance_data.push(uv_min_x)
  self.ui_instance_data.push(uv_min_y)
  self.ui_instance_data.push(uv_scale_x)
  self.ui_instance_data.push(uv_scale_y)
  self.ui_instance_data.push(flags_f)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(0.0F)
  self.ui_instance_data.push(radius_tl)
  self.ui_instance_data.push(radius_tr)
  self.ui_instance_data.push(radius_br)
  self.ui_instance_data.push(radius_bl)
  self.ui_instance_data.push(border_left)
  self.ui_instance_data.push(border_top)
  self.ui_instance_data.push(border_right)
  self.ui_instance_data.push(border_bottom)
  let batch_count = self.ui_batches.length()
  if batch_count > 0 && self.ui_batches[batch_count - 1].texture_id == tex.id {
    self.ui_batches[batch_count - 1].instance_count = self.ui_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.ui_batches.push(UiBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
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
    })
  }
}
