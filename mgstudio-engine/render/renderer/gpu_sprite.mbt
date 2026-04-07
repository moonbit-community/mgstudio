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
const SPRITE_VIEW_BUFFER_SIZE : UInt64 = 1024UL

///|
const SPRITE_INSTANCE_STRIDE_BYTES : UInt64 = 80UL

///|
fn ensure_sprite_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.sprite_pipeline_layout is None {
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
      fatal(
        "wgpu: failed to build sprite compatibility texture bind group layout",
      )
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
      fatal(
        "wgpu: failed to build sprite compatibility globals bind group layout",
      )
    }
    let bgl_globals = b1.finish(backend.device, label="mgstudio_sprite_globals")
    let pl = backend.device.create_pipeline_layout_2(bgl_tex, bgl_globals)
    let globals_usage = bu(
      @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let globals_buf = backend.device.create_buffer(
      size=32UL,
      usage=globals_usage,
    )
    backend.sprite_bgl_tex = Some(bgl_tex)
    backend.sprite_bgl_globals = Some(bgl_globals)
    backend.sprite_pipeline_layout = Some(pl)
    backend.sprite_globals_buf = Some(globals_buf)
    backend.sprite_globals_bg = None
  }
  if backend.sprite_instance_buf is None {
    let instance_usage = bu(
      @wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_VERTEX |
      @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let instance_cap = 65536UL
    let instance_buf = backend.device.create_buffer(
      size=instance_cap,
      usage=instance_usage,
    )
    backend.sprite_instance_buf = Some(instance_buf)
    backend.sprite_instance_capacity = instance_cap
    backend.sprite_instance_data.clear()
    backend.sprite_batches.clear()
    backend.sprite_instance_count = 0U
  }
  if backend.sprite_index_buf is None {
    let index_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
    // Match Bevy sprite index pattern: [2, 0, 1, 1, 3, 2].
    let index_buf = backend.device.create_buffer_init(
      usage=index_usage,
      u32le_pack([2U, 0U, 1U, 1U, 3U, 2U]),
    )
    backend.sprite_index_buf = Some(index_buf)
  }
  if backend.sprite_render_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_texture(
        1U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      ) &&
      view_builder.add_sampler(
        2U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build sprite view bind group layout")
    }
    let bgl_view = view_builder.finish(
      backend.device,
      label="mgstudio_sprite_view_bind_group_layout",
    )
    let tex_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
    let tex_ok = tex_builder.add_texture(
        0U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      tex_builder.add_sampler(
        1U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !tex_ok {
      tex_builder.free()
      fatal("wgpu: failed to build sprite texture bind group layout")
    }
    let bgl_tex = tex_builder.finish(
      backend.device,
      label="mgstudio_sprite_texture_bind_group_layout",
    )
    let pipeline_layout = backend.device.create_pipeline_layout_2(
      bgl_view, bgl_tex,
    )
    pipeline_layout.set_label("mgstudio_sprite_pipeline_layout")
    let view_buf = backend.device.create_buffer(
      size=SPRITE_VIEW_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    let lut_texture = backend.device.create_texture_u32(
      1U,
      1U,
      1U,
      @wgpu.TextureUsage::from_u64(
        @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_COPY_DST,
      ),
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_3D),
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    )
    let lut_view = lut_texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
      @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      1U,
    )
    lut_view.set_label("mgstudio_sprite_lut_view")
    let lut_sampler = backend.device.create_sampler_linear_clamp()
    let view_bg_builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
    let view_bg_ok = view_bg_builder.add_buffer(0U, view_buf) &&
      view_bg_builder.add_texture_view(1U, lut_view) &&
      view_bg_builder.add_sampler(2U, lut_sampler)
    if !view_bg_ok {
      view_bg_builder.free()
      fatal("wgpu: failed to build sprite view bind group")
    }
    let view_bg = view_bg_builder.finish(
      backend.device,
      bgl_view,
      label="mgstudio_sprite_view_bind_group",
    )
    backend.sprite_view_bgl = Some(bgl_view)
    backend.sprite_texture_bgl = Some(bgl_tex)
    backend.sprite_render_pipeline_layout = Some(pipeline_layout)
    backend.sprite_view_buf = Some(view_buf)
    backend.sprite_lut_texture = Some(lut_texture)
    backend.sprite_lut_view = Some(lut_view)
    backend.sprite_lut_sampler = Some(lut_sampler)
    backend.sprite_view_bg = Some(view_bg)
  }
}

///|
fn create_sprite_render_pipeline(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  with_depth : Bool,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  guard backend.sprite_render_pipeline_layout is Some(layout) else {
    fatal("wgpu: sprite pipeline layout is None")
  }
  let modules = copy_registered_wgsl_import_module_paths()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let wgsl = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/render/sprite.wgsl", defines, value_defines,
    visited, modules,
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(format)
    builder.enable_alpha_blend()
    if with_depth {
      builder.set_depth_stencil(
        tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
        depth_write_enabled=false,
        depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      )
    }
    builder.set_vertex_buffer_layout(
      SPRITE_INSTANCE_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_INSTANCE,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 16UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 48UL, 3U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 64UL, 4U)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build sprite render pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn ensure_sprite_pipeline_rgba8(
  backend : GpuBackend,
  with_depth : Bool,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if with_depth && backend.sprite_pipeline_depth is Some(_) {
    return
  }
  if !with_depth && backend.sprite_pipeline is Some(_) {
    return
  }
  let pipeline = create_sprite_render_pipeline(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    with_depth,
    if with_depth {
      "mgstudio_sprite_rgba8_depth"
    } else {
      "mgstudio_sprite_rgba8"
    },
  )
  if with_depth {
    backend.sprite_pipeline_depth = Some(pipeline)
  } else {
    backend.sprite_pipeline = Some(pipeline)
  }
}

///|
fn ensure_sprite_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  with_depth : Bool,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if with_depth &&
    backend.sprite_pipeline_depth_surface_format is Some(prev) &&
    prev == format &&
    backend.sprite_pipeline_depth_surface is Some(_) {
    return
  }
  if !with_depth &&
    backend.sprite_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.sprite_pipeline_surface is Some(_) {
    return
  }
  if with_depth {
    if backend.sprite_pipeline_depth_surface is Some(old) {
      old.release()
    }
  } else if backend.sprite_pipeline_surface is Some(old) {
    old.release()
  }
  let pipeline = create_sprite_render_pipeline(
    backend,
    format,
    with_depth,
    if with_depth {
      "mgstudio_sprite_surface_depth"
    } else {
      "mgstudio_sprite_surface"
    },
  )
  if with_depth {
    backend.sprite_pipeline_depth_surface = Some(pipeline)
    backend.sprite_pipeline_depth_surface_format = Some(format)
  } else {
    backend.sprite_pipeline_surface = Some(pipeline)
    backend.sprite_pipeline_surface_format = Some(format)
  }
}

///|
fn sprite_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let with_depth = backend.pass_has_depth
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_sprite_pipeline_surface(backend, format, with_depth)
      if with_depth {
        backend.sprite_pipeline_depth_surface
      } else {
        backend.sprite_pipeline_surface
      }
    }
    _ => {
      ensure_sprite_pipeline_rgba8(backend, with_depth)
      if with_depth {
        backend.sprite_pipeline_depth
      } else {
        backend.sprite_pipeline
      }
    }
  }
}

///|
fn sprite_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  let safe_width = if pass_state.width_logical <= 0.0F {
    1.0F
  } else {
    pass_state.width_logical
  }
  let safe_height = if pass_state.height_logical <= 0.0F {
    1.0F
  } else {
    pass_state.height_logical
  }
  let safe_camera_scale = if pass_state.camera_scale == 0.0F {
    1.0F
  } else {
    pass_state.camera_scale
  }
  let cam_cos = cosf(pass_state.camera_rot)
  let cam_sin = sinf(pass_state.camera_rot)
  let ndc_scale_x = 2.0F / safe_width / safe_camera_scale
  let ndc_scale_y = 2.0F / safe_height / safe_camera_scale
  let clip_x_axis_x = cam_cos * ndc_scale_x
  let clip_x_axis_y = cam_sin * ndc_scale_y
  let clip_y_axis_x = -cam_sin * ndc_scale_x
  let clip_y_axis_y = cam_cos * ndc_scale_y
  let clip_w_axis_x = (
      -pass_state.camera_x * cam_cos + pass_state.camera_y * cam_sin
    ) *
    ndc_scale_x
  let clip_w_axis_y = (
      -pass_state.camera_x * cam_sin - pass_state.camera_y * cam_cos
    ) *
    ndc_scale_y
  let floats : Array[Float] = [
    clip_x_axis_x, clip_x_axis_y, 0.0F, 0.0F, clip_y_axis_x, clip_y_axis_y, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, clip_w_axis_x, clip_w_axis_y, 0.0F, 1.0F,
  ]
  let target_float_count = (SPRITE_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in floats.length()..<target_float_count {
    floats.push(0.0F)
  }
  f32le_pack(floats)
}

///|
fn create_sprite_texture_bind_group(
  backend : GpuBackend,
  texture : GpuTextureInfo,
) -> @wgpu.BindGroup? {
  guard backend.sprite_texture_bgl is Some(layout) else { return None }
  let b = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok0 = b.add_texture_view(0U, texture.view)
  let ok1 = b.add_sampler(1U, texture.sampler)
  if !ok0 || !ok1 {
    b.free()
    return None
  }
  Some(
    b.finish(backend.device, layout, label="mgstudio_sprite_texture_bind_group"),
  )
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
    let usage = bu(
      @wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_VERTEX |
      @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let new_buf = backend.device.create_buffer(size=new_cap, usage~)
    if backend.sprite_instance_buf is Some(old) {
      old.release()
    }
    backend.sprite_instance_buf = Some(new_buf)
    backend.sprite_instance_capacity = new_cap
  }
  guard backend.pass_state is Some(pass_state) else { return }
  guard backend.sprite_view_buf is Some(view_buf) else { return }
  guard backend.sprite_view_bg is Some(view_bg) else { return }
  guard backend.sprite_instance_buf is Some(instance_buf) else { return }
  guard backend.sprite_index_buf is Some(index_buf) else { return }
  backend.queue.write_buffer(
    view_buf,
    0UL,
    sprite_view_uniform_bytes(pass_state),
  )
  let bytes = f32le_pack(backend.sprite_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [])
  pass.set_index_buffer_u32(index_buf, 0UL, 24UL)
  pass.set_vertex_buffer(0U, instance_buf, 0UL, required_bytes)
  for batch in backend.sprite_batches {
    guard resolve_draw_texture(backend, batch.texture_id) is Some(tex) else {
      continue
    }
    guard create_sprite_texture_bind_group(backend, tex) is Some(tex_bg) else {
      continue
    }
    pass.set_bind_group(1U, tex_bg, [])
    pass.draw_indexed(6U, batch.instance_count, 0U, 0, batch.first_instance)
    tex_bg.release()
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
  flush_mesh2d_batches(self)
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
  let width = base_size * sprite_scale_x
  let height = base_size * sprite_scale_y
  let axis_x_x = cosv * width
  let axis_x_y = sinv * width
  let axis_y_x = sinv * height
  let axis_y_y = -cosv * height
  let translation_x = x - 0.5F * axis_x_x - 0.5F * axis_y_x
  let translation_y = y - 0.5F * axis_x_y - 0.5F * axis_y_y
  let first_instance = self.sprite_instance_count
  self.sprite_instance_count = first_instance + 1U
  // i_model_transpose_col0
  self.sprite_instance_data.push(axis_x_x)
  self.sprite_instance_data.push(axis_y_x)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(translation_x)
  // i_model_transpose_col1
  self.sprite_instance_data.push(axis_x_y)
  self.sprite_instance_data.push(axis_y_y)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(translation_y)
  // i_model_transpose_col2
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(0.0F)
  self.sprite_instance_data.push(1.0F)
  self.sprite_instance_data.push(0.0F)
  // i_color
  self.sprite_instance_data.push(color_r)
  self.sprite_instance_data.push(color_g)
  self.sprite_instance_data.push(color_b)
  self.sprite_instance_data.push(color_a)
  // i_uv_offset_scale
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

///|
pub fn GpuBackend::draw_sprite_uv_slices(
  self : GpuBackend,
  texture_id : Int,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  slices_xy_uv : Array[Float],
) -> Unit raise GpuBackendError {
  guard self.frame is Some(_) else { return }
  guard self.pass_state is Some(_) else { return }
  if slices_xy_uv.length() < 6 {
    return
  }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  ensure_sprite_resources(self)
  guard resolve_draw_texture(self, texture_id) is Some(tex) else { return }
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let base_size = 128.0F
  let mut i = 0
  let batch_first_instance = self.sprite_instance_count
  let mut batch_instance_count = 0U
  while i + 5 < slices_xy_uv.length() {
    let x = slices_xy_uv[i]
    let y = slices_xy_uv[i + 1]
    let uv_min_x = slices_xy_uv[i + 2]
    let uv_min_y = slices_xy_uv[i + 3]
    let uv_max_x = slices_xy_uv[i + 4]
    let uv_max_y = slices_xy_uv[i + 5]
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
    let tex_scale_x = if region_w > 0.0F { region_w / base_size } else { 1.0F }
    let tex_scale_y = if region_h > 0.0F { region_h / base_size } else { 1.0F }
    let sprite_scale_x = scale_x * tex_scale_x
    let sprite_scale_y = scale_y * tex_scale_y
    let width = base_size * sprite_scale_x
    let height = base_size * sprite_scale_y
    let axis_x_x = cosv * width
    let axis_x_y = sinv * width
    let axis_y_x = sinv * height
    let axis_y_y = -cosv * height
    let translation_x = x - 0.5F * axis_x_x - 0.5F * axis_y_x
    let translation_y = y - 0.5F * axis_x_y - 0.5F * axis_y_y
    // i_model_transpose_col0
    self.sprite_instance_data.push(axis_x_x)
    self.sprite_instance_data.push(axis_y_x)
    self.sprite_instance_data.push(0.0F)
    self.sprite_instance_data.push(translation_x)
    // i_model_transpose_col1
    self.sprite_instance_data.push(axis_x_y)
    self.sprite_instance_data.push(axis_y_y)
    self.sprite_instance_data.push(0.0F)
    self.sprite_instance_data.push(translation_y)
    // i_model_transpose_col2
    self.sprite_instance_data.push(0.0F)
    self.sprite_instance_data.push(0.0F)
    self.sprite_instance_data.push(1.0F)
    self.sprite_instance_data.push(0.0F)
    // i_color
    self.sprite_instance_data.push(color_r)
    self.sprite_instance_data.push(color_g)
    self.sprite_instance_data.push(color_b)
    self.sprite_instance_data.push(color_a)
    // i_uv_offset_scale
    self.sprite_instance_data.push(uv_min_x)
    self.sprite_instance_data.push(uv_min_y)
    self.sprite_instance_data.push(uv_scale_x)
    self.sprite_instance_data.push(uv_scale_y)
    self.sprite_instance_count = self.sprite_instance_count + 1U
    batch_instance_count = batch_instance_count + 1U
    i = i + 6
  }
  if batch_instance_count == 0U {
    return
  }
  let batch_count = self.sprite_batches.length()
  if batch_count > 0 &&
    self.sprite_batches[batch_count - 1].texture_id == tex.id {
    self.sprite_batches[batch_count - 1].instance_count = self.sprite_batches[batch_count -
      1].instance_count +
      batch_instance_count
  } else {
    self.sprite_batches.push(SpriteBatch::{
      texture_id: tex.id,
      first_instance: batch_first_instance,
      instance_count: batch_instance_count,
    })
  }
}
