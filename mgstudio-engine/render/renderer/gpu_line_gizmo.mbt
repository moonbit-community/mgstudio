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
fn line_gizmo_shader_bool_defines(
  shader_defs : Array[@render_resource.ShaderDefVal],
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  for shader_def in shader_defs {
    match shader_def {
      Flag(name) => defines.set(name, true)
      Bool(name, value) => defines.set(name, value)
      Int(_, _) | UInt(_, _) | String(_, _) => ()
    }
  }
  defines
}

///|
fn line_gizmo_shader_value_defines(
  shader_defs : Array[@render_resource.ShaderDefVal],
) -> @hashmap.HashMap[String, @wgsl_common.ShaderDefValue] {
  let value_defines = default_wgsl_value_defines()
  for shader_def in shader_defs {
    match shader_def {
      Int(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::Int(value))
      UInt(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::UInt(value))
      String(name, value) =>
        value_defines.set(name, @wgsl_common.ShaderDefValue::Raw(value))
      Flag(_) | Bool(_, _) => ()
    }
  }
  value_defines
}

///|
fn line_gizmo_vertex_layouts_cache_key(
  layouts : Array[@mesh.VertexBufferLayout],
) -> String {
  let mut key = ""
  for layout in layouts {
    if key != "" {
      key = key + ";"
    }
    key = key + mesh2d_vertex_layout_cache_key(layout)
  }
  key
}

///|
fn line_gizmo_pipeline_cache_key(
  shader_path : String,
  vertex_entry : String,
  fragment_entry : String,
  shader_defs : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout],
  target_format : @wgpu.TextureFormat,
  msaa_sample_count : Int,
  with_depth : Bool,
  depth_write_enabled : Bool,
  depth_compare : UInt,
) -> String {
  "line-gizmo:\{shader_path}:\{vertex_entry}:\{fragment_entry}:\{mesh2d_shader_defs_cache_key(shader_defs)}:\{line_gizmo_vertex_layouts_cache_key(vertex_buffer_layouts)}:\{target_format.raw.to_string()}:\{msaa_sample_count.to_string()}:\{with_depth.to_string()}:\{depth_write_enabled.to_string()}:\{depth_compare.to_string()}"
}

///|
fn line_gizmo_create_bind_group_layout(
  backend : GpuBackend,
  label : String,
  min_binding_size : UInt64,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    min_binding_size~,
  )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build line gizmo bind group layout")
  }
  builder.finish(backend.device, label~)
}

///|
fn line_gizmo_pipeline_get(
  backend : GpuBackend,
  key : String,
) -> LineGizmoPipelineCacheEntry? {
  for entry in backend.line_gizmo_pipeline_cache {
    if entry.key == key {
      return Some(entry)
    }
  }
  None
}

///|
fn line_gizmo_create_pipeline(
  backend : GpuBackend,
  key : String,
  shader_path : String,
  vertex_entry : String,
  fragment_entry : String,
  shader_defs : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout],
  target_format : @wgpu.TextureFormat,
  msaa_sample_count : Int,
  with_depth : Bool,
  depth_write_enabled : Bool,
  depth_compare : UInt,
) -> LineGizmoPipelineCacheEntry? raise GpuBackendError {
  let view_bgl = line_gizmo_create_bind_group_layout(
    backend,
    "mgstudio_line_gizmo_view_bgl",
    MESH3D_VIEW_BUFFER_SIZE,
  )
  let uniform_bgl = line_gizmo_create_bind_group_layout(
    backend, "mgstudio_line_gizmo_uniform_bgl", 80UL,
  )
  let pipeline_layout = backend.device.create_pipeline_layout_2(
    view_bgl, uniform_bgl,
  )
  pipeline_layout.set_label("mgstudio_line_gizmo_pipeline_layout")
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    shader_path,
    line_gizmo_shader_bool_defines(shader_defs),
    line_gizmo_shader_value_defines(shader_defs),
  )
  let shader_module = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pipeline_layout,
    shader_module,
    target_format.raw,
    with_depth~,
    depth_write_enabled~,
    alpha_blend=true,
    topology=@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    cull_mode=@wgpu.CULL_MODE_NONE,
    depth_compare_u32=depth_compare,
    vertex_entry~,
    fragment_entry~,
    vertex_buffer_layouts~,
    sample_count=msaa_sample_count,
  )
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline_layout.release()
  shader_module.release()
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to create line gizmo pipeline",
    )
    debug("[renderer] line gizmo pipeline failed: \{message}")
    pipeline.release()
    return None
  }
  pipeline.set_label("mgstudio_line_gizmo_pipeline")
  let entry = LineGizmoPipelineCacheEntry::{
    key,
    view_bind_group_layout: view_bgl,
    uniform_bind_group_layout: uniform_bgl,
    pipeline,
  }
  backend.line_gizmo_pipeline_cache.push(entry)
  Some(entry)
}

///|
fn line_gizmo_pipeline_for_draw(
  backend : GpuBackend,
  shader_path : String,
  vertex_entry : String,
  fragment_entry : String,
  shader_defs : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout],
  depth_write_enabled : Bool,
  depth_compare : UInt,
) -> LineGizmoPipelineCacheEntry? raise GpuBackendError {
  guard backend.pass_state is Some(pass_state) else { return None }
  guard current_pass_color_format(backend) is Some(target_format) else {
    return None
  }
  let sample_count = if pass_state.msaa_sample_count <= 1 {
    1
  } else {
    pass_state.msaa_sample_count
  }
  let key = line_gizmo_pipeline_cache_key(
    shader_path,
    vertex_entry,
    fragment_entry,
    shader_defs,
    vertex_buffer_layouts,
    target_format,
    sample_count,
    backend.pass_has_depth,
    depth_write_enabled,
    depth_compare,
  )
  match line_gizmo_pipeline_get(backend, key) {
    Some(entry) => Some(entry)
    None =>
      line_gizmo_create_pipeline(
        backend,
        key,
        shader_path,
        vertex_entry,
        fragment_entry,
        shader_defs,
        vertex_buffer_layouts,
        target_format,
        sample_count,
        backend.pass_has_depth,
        depth_write_enabled,
        depth_compare,
      )
  }
}

///|
fn line_gizmo_draw_buffer(
  kind : Int,
  list_position_buffer : @wgpu.Buffer,
  list_color_buffer : @wgpu.Buffer,
  strip_position_buffer : @wgpu.Buffer,
  strip_color_buffer : @wgpu.Buffer,
) -> @wgpu.Buffer? {
  match kind {
    0 => Some(list_position_buffer)
    1 => Some(list_color_buffer)
    2 => Some(strip_position_buffer)
    3 => Some(strip_color_buffer)
    _ => None
  }
}

///|
fn line_gizmo_bind_group(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  buffer : @wgpu.Buffer,
  label : String,
  size : UInt64,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, buffer, size~)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(backend.device, layout, label~))
}

///|
fn GpuBackend::draw_line_gizmo_phase(
  self : GpuBackend,
  shader_path : String,
  vertex_entry : String,
  fragment_entry : String,
  shader_defs : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts : Array[@mesh.VertexBufferLayout],
  depth_write_enabled : Bool,
  depth_compare : UInt,
  line_uniform_bytes : Bytes,
  list_position_buffer : @wgpu.Buffer,
  list_color_buffer : @wgpu.Buffer,
  strip_position_buffer : @wgpu.Buffer,
  strip_color_buffer : @wgpu.Buffer,
  binding_buffer_kinds : Array[Int],
  binding_slots : Array[UInt],
  binding_offsets : Array[UInt64],
  binding_sizes : Array[UInt64],
  vertex_count : UInt,
  instance_count : UInt,
) -> Bool raise GpuBackendError {
  if vertex_count == 0U || instance_count == 0U {
    return true
  }
  if binding_buffer_kinds.length() != binding_slots.length() ||
    binding_buffer_kinds.length() != binding_offsets.length() ||
    binding_buffer_kinds.length() != binding_sizes.length() {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard frame.pass is Some(pass) else { return false }
  guard self.pass_state is Some(pass_state) else { return false }
  guard line_gizmo_pipeline_for_draw(
      self, shader_path, vertex_entry, fragment_entry, shader_defs, vertex_buffer_layouts,
      depth_write_enabled, depth_compare,
    )
    is Some(pipeline_entry) else {
    return false
  }
  let uniform_usage = bu(
    @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
  )
  let view_buffer = self.device.create_buffer_init(
    usage=uniform_usage,
    mesh3d_view_uniform_bytes(pass_state),
  )
  let uniform_buffer = self.device.create_buffer_init(
    usage=uniform_usage,
    line_uniform_bytes,
  )
  guard line_gizmo_bind_group(
      self,
      pipeline_entry.view_bind_group_layout,
      view_buffer,
      "mgstudio_line_gizmo_view_bg",
      MESH3D_VIEW_BUFFER_SIZE,
    )
    is Some(view_bind_group) else {
    frame.transient_buffers.push(view_buffer)
    frame.transient_buffers.push(uniform_buffer)
    return false
  }
  guard line_gizmo_bind_group(
      self,
      pipeline_entry.uniform_bind_group_layout,
      uniform_buffer,
      "mgstudio_line_gizmo_uniform_bg",
      80UL,
    )
    is Some(uniform_bind_group) else {
    frame.transient_buffers.push(view_buffer)
    frame.transient_buffers.push(uniform_buffer)
    frame.transient_bind_groups.push(view_bind_group)
    return false
  }
  frame.transient_buffers.push(view_buffer)
  frame.transient_buffers.push(uniform_buffer)
  frame.transient_bind_groups.push(view_bind_group)
  frame.transient_bind_groups.push(uniform_bind_group)
  pass.set_pipeline(pipeline_entry.pipeline)
  pass.set_bind_group(0U, view_bind_group, [])
  pass.set_bind_group(1U, uniform_bind_group, [])
  for index in 0..<binding_buffer_kinds.length() {
    guard line_gizmo_draw_buffer(
        binding_buffer_kinds[index],
        list_position_buffer,
        list_color_buffer,
        strip_position_buffer,
        strip_color_buffer,
      )
      is Some(buffer) else {
      return false
    }
    pass.set_vertex_buffer(
      binding_slots[index],
      buffer,
      binding_offsets[index],
      binding_sizes[index],
    )
  }
  pass.draw(vertex_count, instance_count, 0U, 0U)
  true
}

///|
pub fn draw_line_gizmo_phase(
  shader_path~ : String,
  vertex_entry~ : String,
  fragment_entry~ : String,
  shader_defs~ : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts~ : Array[@mesh.VertexBufferLayout],
  depth_write_enabled~ : Bool,
  depth_compare~ : UInt,
  line_uniform_bytes~ : Bytes,
  list_position_buffer~ : @wgpu.Buffer,
  list_color_buffer~ : @wgpu.Buffer,
  strip_position_buffer~ : @wgpu.Buffer,
  strip_color_buffer~ : @wgpu.Buffer,
  binding_buffer_kinds~ : Array[Int],
  binding_slots~ : Array[UInt],
  binding_offsets~ : Array[UInt64],
  binding_sizes~ : Array[UInt64],
  vertex_count~ : UInt,
  instance_count~ : UInt,
) -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.draw_line_gizmo_phase(
      shader_path, vertex_entry, fragment_entry, shader_defs, vertex_buffer_layouts,
      depth_write_enabled, depth_compare, line_uniform_bytes, list_position_buffer,
      list_color_buffer, strip_position_buffer, strip_color_buffer, binding_buffer_kinds,
      binding_slots, binding_offsets, binding_sizes, vertex_count, instance_count,
    ) catch {
      err => {
        debug_runtime_error("draw_line_gizmo_phase", err)
        false
      }
    }
  }
  false
}

///|
fn GpuBackend::retain_queued_line_gizmo_phase(
  self : GpuBackend,
  phase_kind : Int,
) -> Unit {
  let retained : Array[GpuQueuedLineGizmoDraw] = []
  for draw in self.line_gizmo_queued_draws {
    if draw.phase_kind != phase_kind {
      retained.push(draw)
    } else {
      retire_or_release_buffer(draw.list_position_buffer)
      retire_or_release_buffer(draw.list_color_buffer)
      retire_or_release_buffer(draw.strip_position_buffer)
      retire_or_release_buffer(draw.strip_color_buffer)
    }
  }
  self.line_gizmo_queued_draws.clear()
  for draw in retained {
    self.line_gizmo_queued_draws.push(draw)
  }
}

///|
pub fn clear_line_gizmo_phase_draws(phase_kind~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.retain_queued_line_gizmo_phase(phase_kind)
  }
}

///|
pub fn retire_or_release_buffer(buffer : @wgpu.Buffer) -> Unit {
  match ensure_backend() {
    Some(backend) =>
      if backend.frame is Some(_) {
        backend.frame_retired_buffers.push(buffer)
      } else {
        buffer.release()
      }
    None => buffer.release()
  }
}

///|
pub fn queue_line_gizmo_phase_draw(
  phase_kind~ : Int,
  render_layers_mask~ : Int,
  shader_path~ : String,
  vertex_entry~ : String,
  fragment_entry~ : String,
  shader_defs~ : Array[@render_resource.ShaderDefVal],
  vertex_buffer_layouts~ : Array[@mesh.VertexBufferLayout],
  depth_write_enabled~ : Bool,
  depth_compare~ : UInt,
  line_uniform_bytes~ : Bytes,
  list_position_buffer~ : @wgpu.Buffer,
  list_color_buffer~ : @wgpu.Buffer,
  strip_position_buffer~ : @wgpu.Buffer,
  strip_color_buffer~ : @wgpu.Buffer,
  binding_buffer_kinds~ : Array[Int],
  binding_slots~ : Array[UInt],
  binding_offsets~ : Array[UInt64],
  binding_sizes~ : Array[UInt64],
  vertex_count~ : UInt,
  instance_count~ : UInt,
) -> Unit {
  guard ensure_backend() is Some(backend) else { return }
  backend.line_gizmo_queued_draws.push(GpuQueuedLineGizmoDraw::{
    phase_kind,
    render_layers_mask,
    shader_path,
    vertex_entry,
    fragment_entry,
    shader_defs,
    vertex_buffer_layouts,
    depth_write_enabled,
    depth_compare,
    line_uniform_bytes,
    list_position_buffer: list_position_buffer.add_ref(),
    list_color_buffer: list_color_buffer.add_ref(),
    strip_position_buffer: strip_position_buffer.add_ref(),
    strip_color_buffer: strip_color_buffer.add_ref(),
    binding_buffer_kinds,
    binding_slots,
    binding_offsets,
    binding_sizes,
    vertex_count,
    instance_count,
  })
}

///|
pub fn execute_queued_line_gizmo_phase_draws(
  phase_kind~ : Int,
  view_layers_mask~ : Int,
) -> Int {
  guard ensure_backend() is Some(backend) else { return 0 }
  let draws = backend.line_gizmo_queued_draws.copy()
  let mut drawn = 0
  for draw in draws {
    if draw.phase_kind != phase_kind {
      continue
    }
    if (draw.render_layers_mask & view_layers_mask) == 0 {
      continue
    }
    let ok = backend.draw_line_gizmo_phase(
      draw.shader_path,
      draw.vertex_entry,
      draw.fragment_entry,
      draw.shader_defs,
      draw.vertex_buffer_layouts,
      draw.depth_write_enabled,
      draw.depth_compare,
      draw.line_uniform_bytes,
      draw.list_position_buffer,
      draw.list_color_buffer,
      draw.strip_position_buffer,
      draw.strip_color_buffer,
      draw.binding_buffer_kinds,
      draw.binding_slots,
      draw.binding_offsets,
      draw.binding_sizes,
      draw.vertex_count,
      draw.instance_count,
    ) catch {
      err => {
        debug_runtime_error("execute_queued_line_gizmo_phase_draws", err)
        false
      }
    }
    if ok {
      drawn = drawn + 1
    }
  }
  drawn
}

///|
pub fn current_pass_color_format_raw() -> UInt? {
  guard ensure_backend() is Some(backend) else { return None }
  match current_pass_color_format(backend) {
    Some(format) => Some(format.raw)
    None => None
  }
}

///|
pub fn current_pass_msaa_sample_count() -> UInt {
  guard ensure_backend() is Some(backend) else { return 1U }
  match backend.pass_state {
    Some(pass_state) =>
      if pass_state.msaa_sample_count <= 1 {
        1U
      } else {
        pass_state.msaa_sample_count.reinterpret_as_uint()
      }
    None => 1U
  }
}

///|
pub fn current_wgpu_device() -> @wgpu.Device? {
  match ensure_backend() {
    Some(backend) => Some(backend.device)
    None => None
  }
}
