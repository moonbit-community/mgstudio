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
fn ensure_mesh_uniform_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuUniformSlot? {
  guard backend.mesh_bgl_uniform is Some(bgl) else { return None }
  let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh_uniform_slots.length() <= slot_index {
    let uniform_buf = backend.device.create_buffer(
      size=MESH2D_UNIFORM_BUFFER_SIZE,
      usage=ubo_usage,
    )
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh_uniform_slots.push(GpuUniformSlot::{
      buffer: uniform_buf,
      bind_group: uniform_bg,
    })
  }
  Some(backend.mesh_uniform_slots[slot_index])
}

///|
fn ensure_mesh_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh_pipeline_layout is None {
    guard backend.sprite_bgl_tex is Some(bgl_tex) else {
      @debug.debug(
        "[native_gpu] ensure_mesh_pipeline_rgba8: sprite_bgl_tex is None",
      )
      return
    }
    let bgl = create_uniform_bind_group_layout_vertex_fragment(
      backend, "mgstudio_mesh_uniform_bgl",
    )
    let pl = backend.device.create_pipeline_layout_2(bgl, bgl_tex)
    backend.mesh_bgl_uniform = Some(bgl)
    backend.mesh_pipeline_layout = Some(pl)
  }
  if backend.mesh_pipeline is Some(_) {
    return
  }
  guard backend.mesh_pipeline_layout is Some(pl) else {
    @debug.debug(
      "[native_gpu] ensure_mesh_pipeline_rgba8: mesh_pipeline_layout is None",
    )
    return
  }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/mesh.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=false,
    position3d=false,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_rgba8")
  backend.mesh_pipeline = Some(pipeline)
  @debug.debug("[native_gpu] ensure_mesh_pipeline_rgba8: pipeline created")
  sm.release()
}

///|
fn ensure_mesh_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh_pipeline_rgba8(backend)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.mesh_pipeline_surface is Some(_) {
    return
  }
  if backend.mesh_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.mesh_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/mesh.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=false,
    position3d=false,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_surface")
  backend.mesh_pipeline_surface = Some(pipeline)
  backend.mesh_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh_pipeline_surface(backend, format)
      return backend.mesh_pipeline_surface
    }
    _ => ()
  }
  ensure_mesh_pipeline_rgba8(backend)
  backend.mesh_pipeline
}

///|
pub fn GpuBackend::create_mesh_rectangle(
  self : GpuBackend,
  width : Float,
  height : Float,
) -> Int {
  let id = alloc_id(self)
  let hw = width * 0.5F
  let hh = height * 0.5F
  let vertices : Array[Float] = [
    -hw,
    -hh,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    -hh,
    1.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    hw,
    hh,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    -hw,
    hh,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
  ]
  let indices_u16 : Array[Int] = [0, 1, 2, 0, 2, 3]
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb_bytes = f32le_pack(vertices)
  let vb = self.device.create_buffer_init(usage=vb_usage, vb_bytes)
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib_bytes = u16le_pack(indices_u16)
  let ib = self.device.create_buffer_init(usage=ib_usage, ib_bytes)
  let info = GpuMeshInfo::{
    id,
    index_count: 6U,
    vertex_count: 4U,
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_capsule(
  self : GpuBackend,
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int {
  let id = alloc_id(self)
  // Simple triangulated capsule: rectangle body + two semicircle fans.
  let segs = if segments < 4 { 4 } else { segments }
  let verts_xy : Array[Float] = []
  let inds : Array[Int] = []

  // Base rectangle vertices (4).
  let hw = half_length
  let hh = radius
  let base0 = 0
  verts_xy.push(-hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(-hh)
  verts_xy.push(hw)
  verts_xy.push(hh)
  verts_xy.push(-hw)
  verts_xy.push(hh)
  inds.push(base0 + 0)
  inds.push(base0 + 1)
  inds.push(base0 + 2)
  inds.push(base0 + 0)
  inds.push(base0 + 2)
  inds.push(base0 + 3)

  // Left semicircle.
  let center_l = verts_xy.length() / 2
  verts_xy.push(-hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t + 0.5F) // from 90deg to 270deg
    verts_xy.push(-hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_l)
    inds.push(center_l + 1 + i)
    inds.push(center_l + 1 + i + 1)
  }

  // Right semicircle.
  let center_r = verts_xy.length() / 2
  verts_xy.push(hw)
  verts_xy.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t - 0.5F) // from -90deg to 90deg
    verts_xy.push(hw + cosf(ang) * radius)
    verts_xy.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_r)
    inds.push(center_r + 1 + i)
    inds.push(center_r + 1 + i + 1)
  }
  let verts = mesh_interleaved_xyuvrgba_from_xy(verts_xy)
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(usage=vb_usage, f32le_pack(verts))
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let info = GpuMeshInfo::{
    id,
    index_count: inds.length().reinterpret_as_uint(),
    vertex_count: (verts.length() / 8).reinterpret_as_uint(),
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xy(
  self : GpuBackend,
  vertices_xy : Array[Float],
) -> Int {
  let vertices = mesh_interleaved_xyuvrgba_from_xy(vertices_xy)
  self.create_mesh_triangles_xyuvrgba(vertices)
}

///|
fn mesh_interleaved_xyuvrgba_from_xy(
  vertices_xy : Array[Float],
) -> Array[Float] {
  let vcount = vertices_xy.length() / 2
  if vcount <= 0 {
    return []
  }
  let mut min_x = vertices_xy[0]
  let mut max_x = vertices_xy[0]
  let mut min_y = vertices_xy[1]
  let mut max_y = vertices_xy[1]
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    if x < min_x {
      min_x = x
    }
    if x > max_x {
      max_x = x
    }
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
  }
  let width = if max_x - min_x == 0.0F { 1.0F } else { max_x - min_x }
  let height = if max_y - min_y == 0.0F { 1.0F } else { max_y - min_y }
  let out : Array[Float] = []
  for i in 0..<vcount {
    let x = vertices_xy[i * 2]
    let y = vertices_xy[i * 2 + 1]
    out.push(x)
    out.push(y)
    out.push((x - min_x) / width)
    out.push((y - min_y) / height)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
    out.push(1.0F)
  }
  out
}

///|
pub fn GpuBackend::create_mesh_triangles_xyuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  let vcount = vertices.length() / 8
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = vcount - vcount % 3
  if usable_vcount <= 0 || usable_vcount > 65535 {
    return 0
  }
  let indices_u16 : Array[Int] = []
  for i in 0..<usable_vcount {
    indices_u16.push(i)
  }
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    vertices
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 8) {
      out.push(vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(
    usage=ib_usage,
    u16le_pack(indices_u16),
  )
  let info = GpuMeshInfo::{
    id,
    index_count: indices_u16.length().reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: 32UL,
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::draw_mesh(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    debug_mesh2d_drop_no_frame_ref.val = debug_mesh2d_drop_no_frame_ref.val + 1
    return
  }
  guard frame.pass is Some(pass) else {
    debug_mesh2d_drop_no_pass_ref.val = debug_mesh2d_drop_no_pass_ref.val + 1
    return
  }
  guard self.pass_state is Some(ps) else {
    debug_mesh2d_drop_no_pass_state_ref.val = debug_mesh2d_drop_no_pass_state_ref.val +
      1
    return
  }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else {
    debug_mesh2d_drop_missing_mesh_ref.val = debug_mesh2d_drop_missing_mesh_ref.val +
      1
    return
  }
  if mesh.vertex_stride_bytes != 32UL {
    debug_mesh2d_drop_bad_stride_ref.val = debug_mesh2d_drop_bad_stride_ref.val +
      1
    return
  }
  guard mesh_pipeline_for_current_pass(self) is Some(pipeline) else {
    debug_mesh2d_drop_no_pipeline_ref.val = debug_mesh2d_drop_no_pipeline_ref.val +
      1
    return
  }
  let mesh_uniform_slot_index = self.mesh_uniform_slot_used
  guard ensure_mesh_uniform_slot(self, mesh_uniform_slot_index)
    is Some(uniform_slot) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  self.mesh_uniform_slot_used = mesh_uniform_slot_index + 1
  let resolved_texture_id = if texture_id < 0 { -1 } else { texture_id }
  guard resolve_draw_texture(self, resolved_texture_id) is Some(texture) else {
    debug_mesh2d_drop_no_texture_ref.val = debug_mesh2d_drop_no_texture_ref.val +
      1
    return
  }
  let textured = texture_id >= 0
  let safe_scale = ps.camera_scale
  let scale_x_base = if ps.width_logical > 0.0F {
    2.0F / ps.width_logical / safe_scale
  } else {
    0.0F
  }
  let scale_y_base = if ps.height_logical > 0.0F {
    2.0F / ps.height_logical / safe_scale
  } else {
    0.0F
  }
  let cosr = cosf(rotation)
  let sinr = sinf(rotation)
  let cam_cos = cosf(-ps.camera_rot)
  let cam_sin = sinf(-ps.camera_rot)
  let uv_offset_x_value = if textured { uv_offset_x } else { 0.0F }
  let uv_offset_y_value = if textured { uv_offset_y } else { 0.0F }
  let uv_scale_x_value = if textured { uv_scale_x } else { -1.0F }
  let uv_scale_y_value = if textured { uv_scale_y } else { -1.0F }
  let bytes = f32le_pack([
    x,
    y,
    cosr,
    sinr,
    ps.camera_x,
    ps.camera_y,
    cam_cos,
    cam_sin,
    scale_x_base,
    scale_y_base,
    scale_x,
    scale_y,
    color_r,
    color_g,
    color_b,
    color_a,
    uv_offset_x_value,
    uv_offset_y_value,
    uv_scale_x_value,
    uv_scale_y_value,
  ])
  self.queue.write_buffer(uniform_slot.buffer, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_slot.bind_group, [])
  pass.set_bind_group(1U, texture.bind_group, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  gpu_mesh_bind_index_buffer(pass, mesh)
  debug_mesh2d_executed_draw_calls_ref.val = debug_mesh2d_executed_draw_calls_ref.val +
    1
  current_frame_mesh2d_executed_draw_calls_ref.val = current_frame_mesh2d_executed_draw_calls_ref.val +
    1
  pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
}

///|
