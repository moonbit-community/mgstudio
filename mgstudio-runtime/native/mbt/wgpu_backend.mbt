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
/// Minimal native GPU backend for `mgstudio_host` built on `Milky2018/wgpu_mbt`.
///
/// This is intentionally small and incremental:
/// - supports surface frame begin/end + a single render pass
/// - supports textured sprite quads (no alpha blending yet)
/// - supports solid-color mesh draw for rectangle/capsule meshes
///
/// Missing capabilities are tracked in bd and should be reported upstream.
pub struct GpuTextureInfo {
  id : Int
  width : Int
  height : Int
  texture : @wgpu.Texture
  view : @wgpu.TextureView
  sampler : @wgpu.Sampler
  bind_group : @wgpu.BindGroup
}

///|
pub struct GpuMeshInfo {
  id : Int
  vertices_xy : Array[Float]
  indices_u16 : Array[Int]
  index_count : UInt
  index_buf : @wgpu.Buffer
}

///|
pub struct SpriteUniformPack {
  center_ndc_x : Float
  center_ndc_y : Float
  half_ndc_x : Float
  half_ndc_y : Float
  rot : Float
  uv_min_x : Float
  uv_min_y : Float
  uv_max_x : Float
  uv_max_y : Float
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
}

///|
pub struct GpuPassState {
  target_id : Int
  width_logical : Float
  height_logical : Float
  camera_x : Float
  camera_y : Float
  camera_rot : Float
  camera_scale : Float
  viewport_x : UInt
  viewport_y : UInt
  viewport_w : UInt
  viewport_h : UInt
}

///|
pub struct GpuFrameState {
  surface_tex : @wgpu.SurfaceTexture
  surface_view : @wgpu.TextureView
  encoder : @wgpu.CommandEncoder
  mut pass : @wgpu.RenderPass?
}

///|
pub struct GpuBackend {
  instance : @wgpu.Instance
  adapter : @wgpu.Adapter
  device : @wgpu.Device
  queue : @wgpu.Queue
  mut surface : @wgpu.Surface?
  mut frame : GpuFrameState?
  mut pass_state : GpuPassState?

  // Sprite pipeline (textured quads).
  mut sprite_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bgl_ubo : @wgpu.BindGroupLayout?
  mut sprite_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_pipeline : @wgpu.RenderPipeline?
  mut sprite_uniform_buf : @wgpu.Buffer?
  mut sprite_uniform_bg : @wgpu.BindGroup?

  // Mesh pipeline (solid-color).
  mut mesh_bgl_color : @wgpu.BindGroupLayout?
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_color_buf : @wgpu.Buffer?
  mut mesh_color_bg : @wgpu.BindGroup?
  mut mesh_scratch_vb : @wgpu.Buffer?
  mut mesh_scratch_capacity : UInt64
  next_id : Ref[Int]
  textures : Ref[Array[GpuTextureInfo]]
  meshes : Ref[Array[GpuMeshInfo]]
}

///|
pub fn GpuBackend::new() -> GpuBackend {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let queue = device.queue()
  GpuBackend::{
    instance,
    adapter,
    device,
    queue,
    surface: None,
    frame: None,
    pass_state: None,
    sprite_bgl_tex: None,
    sprite_bgl_ubo: None,
    sprite_pipeline_layout: None,
    sprite_pipeline: None,
    sprite_uniform_buf: None,
    sprite_uniform_bg: None,
    mesh_bgl_color: None,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_color_buf: None,
    mesh_color_bg: None,
    mesh_scratch_vb: None,
    mesh_scratch_capacity: 0UL,
    next_id: Ref::new(1),
    textures: Ref::new([]),
    meshes: Ref::new([]),
  }
}

///|
const PI : Float = 3.141592653589793F

///|
fn cosf(x : Float) -> Float {
  Float::from_double(@coremath.cos(x.to_double()))
}

///|
fn sinf(x : Float) -> Float {
  Float::from_double(@coremath.sin(x.to_double()))
}

///|
fn alloc_id(backend : GpuBackend) -> Int {
  let id = backend.next_id.val
  backend.next_id.val = id + 1
  id
}

///|
fn f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn u16le_pack(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length() * 2, i => {
    let v = xs[i / 2]
    let b = if i % 2 == 0 { v & 0xFF } else { (v >> 8) & 0xFF }
    b.to_byte()
  })
}

///|
fn u32le_pack(xs : Array[UInt]) -> Bytes {
  let n = xs.length()
  Bytes::makei(n * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn f32le_pack(xs : Array[Float]) -> Bytes {
  u32le_pack(xs.map(f32_bits))
}

///|
fn ensure_sprite_pipeline(backend : GpuBackend) -> Unit {
  if backend.sprite_pipeline is Some(_) {
    return
  }
  // Texture binding group.
  let bgl_tex = backend.device.create_bind_group_layout_sampler_texture_2d()
  // Uniform group.
  let bgl_ubo = backend.device.create_bind_group_layout_uniform_buffer()
  let pl = backend.device.create_pipeline_layout_2(bgl_tex, bgl_ubo)
  let wgsl : String =
    #|struct U {
    #|  center: vec2<f32>,
    #|  half_size: vec2<f32>,
    #|  rot: f32,
    #|  _pad0: vec3<f32>,
    #|  uv_min: vec2<f32>,
    #|  uv_max: vec2<f32>,
    #|  color: vec4<f32>,
    #|};
    #|
    #|struct VSOut {
    #|  @builtin(position) pos: vec4<f32>,
    #|  @location(0) uv: vec2<f32>,
    #|  @location(1) color: vec4<f32>,
    #|};
    #|
    #|@group(0) @binding(0) var samp : sampler;
    #|@group(0) @binding(1) var tex : texture_2d<f32>;
    #|@group(1) @binding(0) var<uniform> u : U;
    #|
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) vid: u32) -> VSOut {
    #|  var p = array<vec2<f32>, 6>(
    #|    vec2<f32>(-1.0, -1.0),
    #|    vec2<f32>( 1.0, -1.0),
    #|    vec2<f32>( 1.0,  1.0),
    #|    vec2<f32>(-1.0, -1.0),
    #|    vec2<f32>( 1.0,  1.0),
    #|    vec2<f32>(-1.0,  1.0),
    #|  );
    #|  let base = p[vid];
    #|  let c = cos(u.rot);
    #|  let s = sin(u.rot);
    #|  let off = vec2<f32>(
    #|    base.x * u.half_size.x * c - base.y * u.half_size.y * s,
    #|    base.x * u.half_size.x * s + base.y * u.half_size.y * c,
    #|  );
    #|  var out: VSOut;
    #|  out.pos = vec4<f32>(u.center + off, 0.0, 1.0);
    #|  let t = (base + vec2<f32>(1.0, 1.0)) * 0.5;
    #|  out.uv = mix(u.uv_min, u.uv_max, t);
    #|  out.color = u.color;
    #|  return out;
    #|}
    #|
    #|@fragment
    #|fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
    #|  let texel = textureSample(tex, samp, in.uv);
    #|  return texel * in.color;
    #|}
    #|
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_rgba8_with_layout(pl, sm)
  let ubo_usage = @wgpu.buffer_usage_uniform | @wgpu.buffer_usage_copy_dst
  let ubo = backend.device.create_buffer(size=64UL, usage=ubo_usage)
  let ubo_bg = backend.device.create_bind_group_uniform_buffer(bgl_ubo, ubo)
  backend.sprite_bgl_tex = Some(bgl_tex)
  backend.sprite_bgl_ubo = Some(bgl_ubo)
  backend.sprite_pipeline_layout = Some(pl)
  backend.sprite_pipeline = Some(pipeline)
  backend.sprite_uniform_buf = Some(ubo)
  backend.sprite_uniform_bg = Some(ubo_bg)
  sm.release()
}

///|
fn ensure_mesh_pipeline(backend : GpuBackend) -> Unit {
  if backend.mesh_pipeline is Some(_) {
    return
  }
  let bgl = backend.device.create_bind_group_layout_uniform_buffer()
  let pl = backend.device.create_pipeline_layout_1(bgl)
  let wgsl : String =
    #|struct VSOut { @builtin(position) pos: vec4<f32> };
    #|
    #|@group(0) @binding(0) var<uniform> color : vec4<f32>;
    #|
    #|@vertex
    #|fn vs_main(@location(0) pos: vec2<f32>) -> VSOut {
    #|  var out: VSOut;
    #|  out.pos = vec4<f32>(pos, 0.0, 1.0);
    #|  return out;
    #|}
    #|
    #|@fragment
    #|fn fs_main() -> @location(0) vec4<f32> {
    #|  return color;
    #|}
    #|
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_render_pipeline_rgba8_pos2_with_layout(
    pl, sm,
  )
  let ubo_usage = @wgpu.buffer_usage_uniform | @wgpu.buffer_usage_copy_dst
  let color_buf = backend.device.create_buffer(size=16UL, usage=ubo_usage)
  let color_bg = backend.device.create_bind_group_uniform_buffer(bgl, color_buf)
  let vb_usage = @wgpu.buffer_usage_vertex | @wgpu.buffer_usage_copy_dst
  let scratch = backend.device.create_buffer(size=64UL, usage=vb_usage)
  backend.mesh_bgl_color = Some(bgl)
  backend.mesh_pipeline_layout = Some(pl)
  backend.mesh_pipeline = Some(pipeline)
  backend.mesh_color_buf = Some(color_buf)
  backend.mesh_color_bg = Some(color_bg)
  backend.mesh_scratch_vb = Some(scratch)
  backend.mesh_scratch_capacity = 64UL
  sm.release()
}

///|
pub fn GpuBackend::create_surface(self : GpuBackend) -> Unit {
  if self.surface is Some(_) {
    return
  }
  self.surface = Some(self.instance.create_surface_metal_layer())
}

///|
pub fn GpuBackend::configure_surface(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  self.create_surface()
  guard self.surface is Some(surface) else { return }
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  // Surface textures cannot be used as sampled textures (`texture_binding`).
  // Requesting RESOURCE usage triggers a wgpu-native validation error.
  let usage = @wgpu.texture_usage_render_attachment |
    @wgpu.texture_usage_copy_src
  surface.configure_default(self.adapter, self.device, w, h, usage) |> ignore
}

///|
pub fn GpuBackend::begin_frame(self : GpuBackend) -> Unit {
  self.create_surface()
  guard self.surface is Some(surface) else { return }
  let st = surface.get_current_texture()
  let tex = st.take_texture()
  let view = tex.create_view()
  let encoder = self.device.create_command_encoder()
  self.frame = Some(GpuFrameState::{
    surface_tex: st,
    surface_view: view,
    encoder,
    pass: None,
  })
}

///|
pub fn GpuBackend::end_frame(self : GpuBackend) -> Unit {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  let cmd = frame.encoder.finish()
  self.queue.submit_one(cmd)
  cmd.release()
  frame.encoder.release()
  frame.surface_view.release()
  frame.surface_tex.release()
  guard self.surface is Some(surface) else { return }
  surface.present() |> ignore
  self.instance.process_events()
  self.frame = None
  self.pass_state = None
}

///|
fn find_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo? {
  for t in backend.textures.val {
    if t.id == id {
      return Some(t)
    }
  }
  None
}

///|
fn ensure_fallback_texture(backend : GpuBackend, id : Int) -> GpuTextureInfo {
  if find_texture(backend, id) is Some(t) {
    t
  } else {
    ensure_sprite_pipeline(backend)
    let bgl_tex = backend.sprite_bgl_tex.unwrap()
    let w = 128U
    let h = 128U
    let usage = @wgpu.texture_usage_texture_binding |
      @wgpu.texture_usage_copy_dst |
      @wgpu.texture_usage_copy_src
    let tex = backend.device.create_texture_rgba8_2d_with_usage(w, h, usage)
    let view = tex.create_view()
    let sampler = backend.device.create_sampler_linear_clamp()
    let bg = backend.device.create_bind_group_sampler_texture_2d(
      bgl_tex, sampler, view,
    )
    // Fill the texture with white.
    let byte_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
    let data = Bytes::makei(byte_len, _ => (255).to_byte())
    backend.queue.write_texture_rgba8_2d(tex, w, h, data)
    let info = GpuTextureInfo::{
      id,
      width: w.reinterpret_as_int(),
      height: h.reinterpret_as_int(),
      texture: tex,
      view,
      sampler,
      bind_group: bg,
    }
    backend.textures.val.push(info)
    info
  }
}

///|
pub fn GpuBackend::create_render_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int {
  ensure_sprite_pipeline(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage = @wgpu.texture_usage_render_attachment |
    @wgpu.texture_usage_texture_binding |
    @wgpu.texture_usage_copy_src |
    @wgpu.texture_usage_copy_dst
  let tex = self.device.create_texture_rgba8_2d_with_usage(w, h, usage)
  let view = tex.create_view()
  let sampler = if nearest {
    self.device.create_sampler_nearest_clamp()
  } else {
    self.device.create_sampler_linear_clamp()
  }
  let bg = self.device.create_bind_group_sampler_texture_2d(
    self.sprite_bgl_tex.unwrap(),
    sampler,
    view,
  )
  let info = GpuTextureInfo::{
    id,
    width: w.reinterpret_as_int(),
    height: h.reinterpret_as_int(),
    texture: tex,
    view,
    sampler,
    bind_group: bg,
  }
  self.textures.val.push(info)
  id
}

///|
fn target_view(backend : GpuBackend, target_id : Int) -> @wgpu.TextureView? {
  if target_id == -1 {
    match backend.frame {
      Some(frame) => Some(frame.surface_view)
      None => None
    }
  } else {
    find_texture(backend, target_id).map(fn(t) { t.view })
  }
}

///|
pub fn GpuBackend::begin_pass(
  self : GpuBackend,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_rot : Float,
  camera_scale : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_w : Int,
  viewport_h : Int,
) -> Unit {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  guard target_view(self, target_id) is Some(view) else { return }
  let pass = frame.encoder.begin_render_pass_color_clear(
    view, clear_r, clear_g, clear_b, clear_a,
  )
  let vx = if viewport_x < 0 { 0U } else { viewport_x.reinterpret_as_uint() }
  let vy = if viewport_y < 0 { 0U } else { viewport_y.reinterpret_as_uint() }
  let vw = if viewport_w < 0 { 0U } else { viewport_w.reinterpret_as_uint() }
  let vh = if viewport_h < 0 { 0U } else { viewport_h.reinterpret_as_uint() }
  pass.set_viewport(
    Float::from_double(vx.to_double()),
    Float::from_double(vy.to_double()),
    Float::from_double(vw.to_double()),
    Float::from_double(vh.to_double()),
    0.0F,
    1.0F,
  )
  pass.set_scissor_rect(vx, vy, vw, vh)
  frame.pass = Some(pass)
  self.pass_state = Some(GpuPassState::{
    target_id,
    width_logical: Float::from_double(width_logical.to_double()),
    height_logical: Float::from_double(height_logical.to_double()),
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: if camera_scale == 0.0F {
      1.0F
    } else {
      camera_scale
    },
    viewport_x: vx,
    viewport_y: vy,
    viewport_w: vw,
    viewport_h: vh,
  })
}

///|
pub fn GpuBackend::end_pass(self : GpuBackend) -> Unit {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
}

///|
fn pack_sprite_uniform(pack : SpriteUniformPack) -> Bytes {
  let floats : Array[Float] = [
    pack.center_ndc_x,
    pack.center_ndc_y,
    pack.half_ndc_x,
    pack.half_ndc_y,
    pack.rot,
    0.0F,
    0.0F,
    0.0F,
    pack.uv_min_x,
    pack.uv_min_y,
    pack.uv_max_x,
    pack.uv_max_y,
    pack.color_r,
    pack.color_g,
    pack.color_b,
    pack.color_a,
  ]
  f32le_pack(floats)
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
) -> Unit {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  ensure_sprite_pipeline(self)
  let tex = ensure_fallback_texture(self, texture_id)
  let half_w = ps.width_logical / 2.0F
  let half_h = ps.height_logical / 2.0F
  if half_w == 0.0F || half_h == 0.0F {
    return
  }
  let dx = x - ps.camera_x
  let dy = y - ps.camera_y
  let cosc = cosf(ps.camera_rot)
  let sinc = sinf(ps.camera_rot)
  // Rotate by -camera_rot.
  let rx = dx * cosc + dy * sinc
  let ry = -dx * sinc + dy * cosc
  let inv_scale = 1.0F / ps.camera_scale
  let view_x = rx * inv_scale
  let view_y = ry * inv_scale
  let center_ndc_x = view_x / half_w
  let center_ndc_y = view_y / half_h
  let sprite_w = Float::from_double(tex.width.to_double())
  let sprite_h = Float::from_double(tex.height.to_double())
  let half_ndc_x = sprite_w * scale_x * 0.5F * inv_scale / half_w
  let half_ndc_y = sprite_h * scale_y * 0.5F * inv_scale / half_h
  let pack = SpriteUniformPack::{
    center_ndc_x,
    center_ndc_y,
    half_ndc_x,
    half_ndc_y,
    rot: rotation - ps.camera_rot,
    uv_min_x,
    uv_min_y,
    uv_max_x,
    uv_max_y,
    color_r,
    color_g,
    color_b,
    color_a,
  }
  let bytes = pack_sprite_uniform(pack)
  self.queue.write_buffer(self.sprite_uniform_buf.unwrap(), 0UL, bytes)
  pass.set_pipeline(self.sprite_pipeline.unwrap())
  pass.set_bind_group(0U, tex.bind_group, [])
  pass.set_bind_group(1U, self.sprite_uniform_bg.unwrap(), [])
  pass.draw(6U, 1U, 0U, 0U)
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
  let vertices_xy : Array[Float] = [-hw, -hh, hw, -hh, hw, hh, -hw, hh]
  let indices_u16 : Array[Int] = [0, 1, 2, 0, 2, 3]
  let ib_usage = @wgpu.buffer_usage_index | @wgpu.buffer_usage_copy_dst
  let bytes = u16le_pack(indices_u16)
  let ib = self.device.create_buffer_init(usage=ib_usage, bytes)
  let info = GpuMeshInfo::{
    id,
    vertices_xy,
    indices_u16,
    index_count: 6U,
    index_buf: ib,
  }
  self.meshes.val.push(info)
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
  let verts : Array[Float] = []
  let inds : Array[Int] = []

  // Base rectangle vertices (4).
  let hw = half_length
  let hh = radius
  let base0 = 0
  verts.push(-hw)
  verts.push(-hh)
  verts.push(hw)
  verts.push(-hh)
  verts.push(hw)
  verts.push(hh)
  verts.push(-hw)
  verts.push(hh)
  inds.push(base0 + 0)
  inds.push(base0 + 1)
  inds.push(base0 + 2)
  inds.push(base0 + 0)
  inds.push(base0 + 2)
  inds.push(base0 + 3)

  // Left semicircle.
  let center_l = verts.length() / 2
  verts.push(-hw)
  verts.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t + 0.5F) // from 90deg to 270deg
    verts.push(-hw + cosf(ang) * radius)
    verts.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_l)
    inds.push(center_l + 1 + i)
    inds.push(center_l + 1 + i + 1)
  }

  // Right semicircle.
  let center_r = verts.length() / 2
  verts.push(hw)
  verts.push(0.0F)
  for i in 0..<(segs + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segs.to_double())
    let ang = PI * (t - 0.5F) // from -90deg to 90deg
    verts.push(hw + cosf(ang) * radius)
    verts.push(sinf(ang) * radius)
  }
  for i in 0..<segs {
    inds.push(center_r)
    inds.push(center_r + 1 + i)
    inds.push(center_r + 1 + i + 1)
  }
  let ib_usage = @wgpu.buffer_usage_index | @wgpu.buffer_usage_copy_dst
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let info = GpuMeshInfo::{
    id,
    vertices_xy: verts,
    indices_u16: inds,
    index_count: inds.length().reinterpret_as_uint(),
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
fn find_mesh(backend : GpuBackend, id : Int) -> GpuMeshInfo? {
  for m in backend.meshes.val {
    if m.id == id {
      return Some(m)
    }
  }
  None
}

///|
fn ensure_mesh_scratch(backend : GpuBackend, needed : UInt64) -> Unit {
  ensure_mesh_pipeline(backend)
  if backend.mesh_scratch_capacity >= needed {
    return
  }
  let new_cap = if needed < backend.mesh_scratch_capacity * 2UL {
    backend.mesh_scratch_capacity * 2UL
  } else {
    needed
  }
  let vb_usage = @wgpu.buffer_usage_vertex | @wgpu.buffer_usage_copy_dst
  let buf = backend.device.create_buffer(size=new_cap, usage=vb_usage)
  if backend.mesh_scratch_vb is Some(old) {
    old.release()
  }
  backend.mesh_scratch_vb = Some(buf)
  backend.mesh_scratch_capacity = new_cap
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
) -> Unit {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  ensure_mesh_pipeline(self)
  let half_w = ps.width_logical / 2.0F
  let half_h = ps.height_logical / 2.0F
  if half_w == 0.0F || half_h == 0.0F {
    return
  }

  // Update mesh color uniform.
  let color_bytes = f32le_pack([color_r, color_g, color_b, color_a])
  self.queue.write_buffer(self.mesh_color_buf.unwrap(), 0UL, color_bytes)

  // Transform each vertex into NDC and upload to scratch buffer.
  let cosr = cosf(rotation)
  let sinr = sinf(rotation)
  let cosc = cosf(ps.camera_rot)
  let sinc = sinf(ps.camera_rot)
  let inv_cam = 1.0F / ps.camera_scale
  let verts_ndc : Array[Float] = []
  let count = mesh.vertices_xy.length() / 2
  for i in 0..<count {
    let lx = mesh.vertices_xy[i * 2] * scale_x
    let ly = mesh.vertices_xy[i * 2 + 1] * scale_y
    // Model rotation + translation (world).
    let wx = x + lx * cosr - ly * sinr
    let wy = y + lx * sinr + ly * cosr
    // Camera inverse.
    let dx = wx - ps.camera_x
    let dy = wy - ps.camera_y
    let rx = dx * cosc + dy * sinc
    let ry = -dx * sinc + dy * cosc
    let vx = rx * inv_cam
    let vy = ry * inv_cam
    verts_ndc.push(vx / half_w)
    verts_ndc.push(vy / half_h)
  }
  let bytes = f32le_pack(verts_ndc)
  let needed = bytes.length().to_uint64()
  ensure_mesh_scratch(self, needed)
  self.queue.write_buffer(self.mesh_scratch_vb.unwrap(), 0UL, bytes)
  pass.set_pipeline(self.mesh_pipeline.unwrap())
  pass.set_bind_group(0U, self.mesh_color_bg.unwrap(), [])
  pass.set_vertex_buffer(0U, self.mesh_scratch_vb.unwrap(), 0UL, needed)
  let index_bytes = (mesh.indices_u16.length() * 2).to_uint64()
  pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  pass.draw_indexed(
    mesh.indices_u16.length().reinterpret_as_uint(),
    1U,
    0U,
    0,
    0U,
  )
}
