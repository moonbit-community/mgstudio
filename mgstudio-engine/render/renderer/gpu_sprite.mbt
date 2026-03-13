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
fn ensure_sprite_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.sprite_pipeline_layout is Some(_) {
    return
  }
  let b0 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok0 = b0.add_sampler(
    0U,
    ss(@wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
  )
  let ok1 = b0.add_texture(
    1U,
    ss(@wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
  )
  if !ok0 || !ok1 {
    b0.free()
    return
  }
  let bgl_tex = b0.finish(backend.device, label="mgstudio_sprite_tex")
  let b1 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok2 = b1.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
  )
  let ok3 = b1.add_buffer(
    1U,
    ss(@wgpu.SHADER_STAGE_VERTEX),
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  if !ok2 || !ok3 {
    b1.free()
    fatal("wgpu: failed to build sprite bind group layout")
  }
  let bgl_globals = b1.finish(backend.device, label="mgstudio_sprite_globals")
  let pl = backend.device.create_pipeline_layout_2(bgl_tex, bgl_globals)
  let globals_usage = bu(
    @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let globals_buf = backend.device.create_buffer(size=32UL, usage=globals_usage)
  let instance_usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let instance_cap = 65536UL
  let instance_buf = backend.device.create_buffer(
    size=instance_cap,
    usage=instance_usage,
  )
  backend.sprite_bgl_tex = Some(bgl_tex)
  backend.sprite_bgl_globals = Some(bgl_globals)
  backend.sprite_pipeline_layout = Some(pl)
  backend.sprite_globals_buf = Some(globals_buf)
  backend.sprite_instance_buf = Some(instance_buf)
  backend.sprite_instance_capacity = instance_cap
  backend.sprite_globals_bg = None
  backend.sprite_instance_data.clear()
  backend.sprite_batches.clear()
  backend.sprite_instance_count = 0U
}

///|
fn ensure_sprite_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.sprite_pipeline is Some(_) {
    return
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/sprite.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_sprite_rgba8")
  backend.sprite_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_sprite_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.sprite_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.sprite_pipeline_surface is Some(_) {
    return
  }
  if backend.sprite_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.sprite_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/sprite.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = @wgpu_c.render_pipeline_descriptor_color_format_alpha_blend_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format.to_u32(),
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_sprite_surface")
  backend.sprite_pipeline_surface = Some(pipeline)
  backend.sprite_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn sprite_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_sprite_pipeline_surface(backend, format)
      backend.sprite_pipeline_surface
    }
    _ => {
      ensure_sprite_pipeline_rgba8(backend)
      backend.sprite_pipeline
    }
  }
}

///|
fn ensure_sprite_globals_bind_group(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.sprite_globals_bg is Some(_) {
    return
  }
  guard backend.sprite_bgl_globals is Some(layout) else { return }
  guard backend.sprite_globals_buf is Some(globals_buf) else { return }
  guard backend.sprite_instance_buf is Some(instance_buf) else { return }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_buffer(0U, globals_buf)
  let ok1 = b.add_buffer(1U, instance_buf)
  if !ok0 || !ok1 {
    b.free()
    fatal("wgpu: failed to build sprite globals bind group")
  }
  let bg = b.finish(backend.device, layout, label="mgstudio_sprite_globals")
  backend.sprite_globals_bg = Some(bg)
}

///|
fn flush_sprite_batches(backend : GpuBackend) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  if backend.sprite_instance_count == 0U {
    return
  }
  guard sprite_pipeline_for_current_pass(backend) is Some(pipeline) else {
    return
  }
  let float_count = backend.sprite_instance_data.length()
  if float_count <= 0 {
    backend.sprite_instance_data.clear()
    backend.sprite_batches.clear()
    backend.sprite_instance_count = 0U
    return
  }
  let required_bytes = (float_count * 4).to_uint64()
  if required_bytes > backend.sprite_instance_capacity {
    let new_cap = if required_bytes < 256UL { 256UL } else { required_bytes }
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.sprite_instance_buf is Some(old) {
      old.release()
    }
    backend.sprite_instance_buf = Some(new_buf)
    backend.sprite_instance_capacity = new_cap
    backend.sprite_globals_bg = None
  }
  ensure_sprite_globals_bind_group(backend)
  guard backend.sprite_instance_buf is Some(instance_buf) else { return }
  guard backend.sprite_globals_bg is Some(globals_bg) else { return }
  let bytes = f32le_pack(backend.sprite_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.sprite_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.sprite_instance_data.clear()
  backend.sprite_batches.clear()
  backend.sprite_instance_count = 0U
}

///|
fn sprite_uv_axis_metrics(
  uv_min : Float,
  uv_max : Float,
  texture_extent : Int,
) -> (Float, Float) {
  let raw_uv_scale = uv_max - uv_min
  let abs_uv_scale = if raw_uv_scale < 0.0F {
    -raw_uv_scale
  } else {
    raw_uv_scale
  }
  let safe_abs_uv_scale = if abs_uv_scale <= 0.0F { 1.0F } else { abs_uv_scale }
  let signed_uv_scale = if abs_uv_scale <= 0.0F { 1.0F } else { raw_uv_scale }
  let texture_extent_f = Float::from_double(texture_extent.to_double())
  (signed_uv_scale, texture_extent_f * safe_abs_uv_scale)
}

///|
pub fn GpuBackend::draw_sprite_uv(
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
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  ensure_sprite_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }
  let (uv_scale_x, region_w) = sprite_uv_axis_metrics(
    uv_min_x,
    uv_max_x,
    tex.width,
  )
  let (uv_scale_y, region_h) = sprite_uv_axis_metrics(
    uv_min_y,
    uv_max_y,
    tex.height,
  )
  let base_size = 128.0F
  let tex_scale_x = if region_w > 0.0F { region_w / base_size } else { 1.0F }
  let tex_scale_y = if region_h > 0.0F { region_h / base_size } else { 1.0F }
  let sprite_scale_x = scale_x * tex_scale_x
  let sprite_scale_y = scale_y * tex_scale_y
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.sprite_instance_count
  self.sprite_instance_count = first_instance + 1U
  self.sprite_instance_data.push(x)
  self.sprite_instance_data.push(y)
  self.sprite_instance_data.push(cosv)
  self.sprite_instance_data.push(sinv)
  self.sprite_instance_data.push(sprite_scale_x)
  self.sprite_instance_data.push(sprite_scale_y)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(color_r)
  self.sprite_instance_data.push(color_g)
  self.sprite_instance_data.push(color_b)
  self.sprite_instance_data.push(color_a)
  self.sprite_instance_data.push(uv_min_x)
  self.sprite_instance_data.push(uv_min_y)
  self.sprite_instance_data.push(uv_scale_x)
  self.sprite_instance_data.push(uv_scale_y)
  let batch_count = self.sprite_batches.length()
  if batch_count > 0 &&
    self.sprite_batches[batch_count - 1].texture_id == tex.id {
    self.sprite_batches[batch_count - 1].instance_count = self.sprite_batches[batch_count -
      1].instance_count +
      1U
  } else {
    self.sprite_batches.push(SpriteBatch::{
      texture_id: tex.id,
      first_instance,
      instance_count: 1U,
    })
  }
}
