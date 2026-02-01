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
/// - supports textured sprite quads (alpha blending)
/// - supports solid-color mesh draw for rectangle/capsule meshes
///
/// Missing capabilities are tracked in bd and should be reported upstream.

///|
/// Use wgpu_mbt's "alpha blend + arbitrary format" render pipeline descriptor
/// helper (added in wgpu_mbt 0.2.2).

///|
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
  index_count : UInt
  vertex_count : UInt
  vertex_buf : @wgpu.Buffer
  index_buf : @wgpu.Buffer
}

///|
pub struct SpriteBatch {
  texture_id : Int
  first_instance : UInt
  mut instance_count : UInt
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
  assets_base : String
  mut surface : @wgpu.Surface?
  mut surface_format : UInt
  mut configured_width : Int
  mut configured_height : Int
  mut frame : GpuFrameState?
  mut pass_state : GpuPassState?

  // Sprite pipeline (textured quads).
  mut sprite_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bgl_globals : @wgpu.BindGroupLayout?
  mut sprite_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_pipeline : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface_format : UInt
  mut sprite_globals_buf : @wgpu.Buffer?
  mut sprite_instance_buf : @wgpu.Buffer?
  mut sprite_instance_capacity : UInt64
  mut sprite_globals_bg : @wgpu.BindGroup?
  sprite_instance_data : Array[Float]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : UInt

  // Mesh pipeline (solid-color).
  mut mesh_bgl_uniform : @wgpu.BindGroupLayout?
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : UInt
  mut mesh_uniform_buf : @wgpu.Buffer?
  mut mesh_uniform_bg : @wgpu.BindGroup?
  next_id : Ref[Int]
  textures : Ref[Array[GpuTextureInfo]]
  meshes : Ref[Array[GpuMeshInfo]]
}

///|
pub fn GpuBackend::new(assets_base? : String = "") -> GpuBackend {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let queue = device.queue()
  GpuBackend::{
    instance,
    adapter,
    device,
    queue,
    assets_base,
    surface: None,
    surface_format: 0U,
    configured_width: 0,
    configured_height: 0,
    frame: None,
    pass_state: None,
    sprite_bgl_tex: None,
    sprite_bgl_globals: None,
    sprite_pipeline_layout: None,
    sprite_pipeline: None,
    sprite_pipeline_surface: None,
    sprite_pipeline_surface_format: 0U,
    sprite_globals_buf: None,
    sprite_instance_buf: None,
    sprite_instance_capacity: 0UL,
    sprite_globals_bg: None,
    sprite_instance_data: [],
    sprite_batches: [],
    sprite_instance_count: 0U,
    mesh_bgl_uniform: None,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_pipeline_surface: None,
    mesh_pipeline_surface_format: 0U,
    mesh_uniform_buf: None,
    mesh_uniform_bg: None,
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
pub(all) suberror GpuBackendError {
  Fatal(String)
} derive(Show)

///|
fn[T] fatal(message : String) -> T raise GpuBackendError {
  raise GpuBackendError::Fatal(message)
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
fn join_asset_path(base : String, rel : String) -> String {
  fn strip_trailing_slash(s : String) -> String {
    if s.length() == 0 {
      return s
    }
    let last = s.code_unit_at(s.length() - 1)
    if last == '/' {
      try! s[:s.length() - 1].to_string()
    } else {
      s
    }
  }

  @rtcore.join_dir(base, rel) catch {
    _ => strip_trailing_slash(base) + "/" + rel
  }
}

///|
fn load_wgsl_from_assets_required(
  backend : GpuBackend,
  rel : String,
) -> String raise GpuBackendError {
  let base = backend.assets_base.trim().to_string()
  if base == "" {
    fatal("wgpu: assets_base is empty; cannot load shader: " + rel)
  }
  let full_path = join_asset_path(base, rel)
  @fs.read_file_to_string(full_path) catch {
    err =>
      fatal(
        "wgpu: failed to read shader: " + full_path + ": " + err.to_string(),
      )
  }
}

///|
fn ensure_sprite_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.sprite_pipeline_layout is Some(_) {
    return
  }
  // Texture binding group (fragment stage).
  let b0 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok0 = b0.add_sampler(
    0U,
    @wgpu.SHADER_STAGE_FRAGMENT,
    @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
  )
  let ok1 = b0.add_texture(
    1U,
    @wgpu.SHADER_STAGE_FRAGMENT,
    @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
  )
  if !ok0 || !ok1 {
    b0.free()
    return
  }
  let bgl_tex = b0.finish(backend.device, label="mgstudio_sprite_tex")

  // Globals + instances group (vertex stage).
  let b1 = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok2 = b1.add_buffer(
    0U,
    @wgpu.SHADER_STAGE_VERTEX,
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
  )
  let ok3 = b1.add_buffer(
    1U,
    @wgpu.SHADER_STAGE_VERTEX,
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  if !ok2 || !ok3 {
    b1.free()
    fatal("wgpu: failed to build sprite bind group layout")
  }
  let bgl_globals = b1.finish(backend.device, label="mgstudio_sprite_globals")
  let pl = backend.device.create_pipeline_layout_2(bgl_tex, bgl_globals)
  let globals_usage = @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST
  let globals_buf = backend.device.create_buffer(size=32UL, usage=globals_usage)
  let instance_usage = @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
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
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  let format = backend.surface_format
  if format == 0U || format == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM {
    return
  }
  if backend.sprite_pipeline_surface_format == format &&
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
    format,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_sprite_surface")
  backend.sprite_pipeline_surface = Some(pipeline)
  backend.sprite_pipeline_surface_format = format
  sm.release()
}

///|
fn sprite_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface &&
    backend.surface_format != 0U &&
    backend.surface_format != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM {
    ensure_sprite_pipeline_surface(backend)
    backend.sprite_pipeline_surface
  } else {
    ensure_sprite_pipeline_rgba8(backend)
    backend.sprite_pipeline
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
fn ensure_mesh_pipeline(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.mesh_pipeline_layout is None {
    let bgl = backend.device.create_bind_group_layout_uniform_buffer()
    let pl = backend.device.create_pipeline_layout_1(bgl)
    backend.mesh_bgl_uniform = Some(bgl)
    backend.mesh_pipeline_layout = Some(pl)
  }
  if backend.mesh_uniform_buf is None || backend.mesh_uniform_bg is None {
    guard backend.mesh_bgl_uniform is Some(bgl) else { return }
    let ubo_usage = @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST
    let uniform_buf = backend.device.create_buffer(size=80UL, usage=ubo_usage)
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh_uniform_buf = Some(uniform_buf)
    backend.mesh_uniform_bg = Some(uniform_bg)
  }
  if backend.mesh_pipeline is Some(_) {
    return
  }
  guard backend.mesh_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/2d/mesh.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = render_pipeline_descriptor_color_format_alpha_blend_pos2_new(
    pl.raw_handle(),
    sm.raw_handle(),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_rgba8")
  backend.mesh_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_mesh_pipeline_surface(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_mesh_pipeline(backend)
  let format = backend.surface_format
  if format == 0U || format == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM {
    return
  }
  if backend.mesh_pipeline_surface_format == format &&
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
  let desc = render_pipeline_descriptor_color_format_alpha_blend_pos2_new(
    pl.raw_handle(),
    sm.raw_handle(),
    format,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh_surface")
  backend.mesh_pipeline_surface = Some(pipeline)
  backend.mesh_pipeline_surface_format = format
  sm.release()
}

///|
fn mesh_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface &&
    backend.surface_format != 0U &&
    backend.surface_format != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM {
    ensure_mesh_pipeline_surface(backend)
    backend.mesh_pipeline_surface
  } else {
    ensure_mesh_pipeline(backend)
    backend.mesh_pipeline
  }
}

///|
pub fn GpuBackend::create_surface(
  self : GpuBackend,
  window : @win.Window,
) -> Unit {
  if self.surface is Some(_) {
    return
  }
  let surface = self.instance.create_surface_metal_layer()
  window.attach_metal_layer(surface.layer)
  self.surface = Some(surface)
}

///|
pub fn GpuBackend::configure_surface(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  guard self.surface is Some(surface) else { return }
  self.configured_width = width
  self.configured_height = height
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  // Surface textures cannot be used as sampled textures (`texture_binding`).
  // Requesting RESOURCE usage triggers a wgpu-native validation error.
  let usage = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  self.surface_format = surface.configure_default(
    self.adapter,
    self.device,
    w,
    h,
    usage,
  )
  @debug.debug("wgpu: surface_format=" + self.surface_format.to_string())
}

///|
/// Ensure the surface is configured for the latest window size.
///
/// This is a bring-up convenience: the guest does not yet have a resize event
/// path, so the host keeps the surface in sync.
pub fn GpuBackend::ensure_surface_configured(
  self : GpuBackend,
  width : Int,
  height : Int,
) -> Unit {
  if self.surface is None {
    return
  }
  if width == self.configured_width && height == self.configured_height {
    return
  }
  self.configure_surface(width, height)
}

///|
pub fn GpuBackend::begin_frame(self : GpuBackend) -> Unit {
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
pub fn GpuBackend::end_frame(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_sprite_batches(self)
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
fn ensure_fallback_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo raise GpuBackendError {
  if find_texture(backend, id) is Some(t) {
    t
  } else {
    ensure_sprite_resources(backend)
    let bgl_tex = backend.sprite_bgl_tex.unwrap()
    let w = 128U
    let h = 128U
    let usage = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC
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
pub fn GpuBackend::create_texture_rgba8(
  self : GpuBackend,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
  nearest : Bool,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
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
  let expected_len = w.reinterpret_as_int() * h.reinterpret_as_int() * 4
  let data = if pixels_rgba8.length() == expected_len {
    pixels_rgba8
  } else {
    // Defensive fallback: avoid crashing if decode output is malformed.
    Bytes::makei(expected_len, _ => (255).to_byte())
  }
  self.queue.write_texture_rgba8_2d(tex, w, h, data)
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
pub fn GpuBackend::texture_width(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.width
    None => 0
  }
}

///|
pub fn GpuBackend::texture_height(self : GpuBackend, texture_id : Int) -> Int {
  match find_texture(self, texture_id) {
    Some(t) => t.height
    None => 0
  }
}

///|
/// Update a sub-rectangle of an RGBA8 2D texture.
///
/// Note: WGPU requires `bytes_per_row` to be 256-byte aligned, so we may need to
/// pad each row before calling `Queue::write_texture_ptr`.
pub fn GpuBackend::write_texture_region_rgba8(
  self : GpuBackend,
  texture_id : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  match find_texture(self, texture_id) {
    None => ()
    Some(info) => {
      if width <= 0 || height <= 0 {
        return
      }
      let w = width.reinterpret_as_uint()
      let h = height.reinterpret_as_uint()
      let origin_x = if x < 0 { 0U } else { x.reinterpret_as_uint() }
      let origin_y = if y < 0 { 0U } else { y.reinterpret_as_uint() }
      let bytes_per_row = width * 4
      if bytes_per_row <= 0 {
        return
      }
      let mut aligned = bytes_per_row
      if aligned % 256 != 0 {
        aligned = (aligned / 256 + 1) * 256
      }
      let expected = bytes_per_row * height
      let src = if pixels_rgba8.length() == expected {
        pixels_rgba8
      } else {
        // Defensive: malformed input. Fill with transparent pixels.
        Bytes::makei(expected, _ => (0).to_byte())
      }
      let upload = if aligned == bytes_per_row {
        src
      } else {
        Bytes::makei(aligned * height, i => {
          let row = i / aligned
          let col = i % aligned
          if col < bytes_per_row {
            let src_i = row * bytes_per_row + col
            match src.get(src_i) {
              Some(b) => b
              None => (0).to_byte()
            }
          } else {
            (0).to_byte()
          }
        })
      }
      let tex_info = @wgpu_c.texel_copy_texture_info_new(
        info.texture.raw,
        0U,
        origin_x,
        origin_y,
        0U,
      )
      let layout = @wgpu_c.texel_copy_buffer_layout_new(
        0UL,
        aligned.reinterpret_as_uint(),
        h,
      )
      let extent = @wgpu_c.extent3d_new(w, h, 1U)
      self.queue.write_texture_ptr(tex_info, upload, layout, extent)
      @wgpu_c.extent3d_free(extent)
      @wgpu_c.texel_copy_buffer_layout_free(layout)
      @wgpu_c.texel_copy_texture_info_free(tex_info)
    }
  }
}

///|
pub fn GpuBackend::is_texture_loaded(
  self : GpuBackend,
  texture_id : Int,
) -> Bool {
  find_texture(self, texture_id) is Some(_)
}

///|
pub fn GpuBackend::set_texture_sampler(
  self : GpuBackend,
  texture_id : Int,
  sampler_kind : Int,
) -> Unit raise GpuBackendError {
  if self.sprite_bgl_tex is None {
    ensure_sprite_resources(self)
  }
  let bgl_tex = self.sprite_bgl_tex.unwrap()
  let count = self.textures.val.length()
  for i in 0..<count {
    let info = self.textures.val[i]
    if info.id == texture_id {
      let sampler = if sampler_kind == 1 {
        self.device.create_sampler_nearest_clamp()
      } else {
        self.device.create_sampler_linear_clamp()
      }
      let bg = self.device.create_bind_group_sampler_texture_2d(
        bgl_tex,
        sampler,
        info.view,
      )
      self.textures.val[i] = GpuTextureInfo::{
        id: info.id,
        width: info.width,
        height: info.height,
        texture: info.texture,
        view: info.view,
        sampler,
        bind_group: bg,
      }
      break
    }
  }
}

///|
pub fn GpuBackend::create_render_target(
  self : GpuBackend,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int raise GpuBackendError {
  ensure_sprite_resources(self)
  let id = alloc_id(self)
  let w = if width <= 0 { 1U } else { width.reinterpret_as_uint() }
  let h = if height <= 0 { 1U } else { height.reinterpret_as_uint() }
  let usage = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
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
) -> Unit raise GpuBackendError {
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

  // Reset sprite batching state and update sprite globals for this pass.
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  ensure_sprite_resources(self)
  if self.sprite_globals_buf is Some(globals_buf) {
    let safe_scale = if camera_scale == 0.0F { 1.0F } else { camera_scale }
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w / safe_scale } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h / safe_scale } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    // Globals: view(x,y,cos,sin) + ndc_scale(x,y,_,_)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
}

///|
pub fn GpuBackend::end_pass(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
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
    let usage = @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
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

  // Upload instances.
  let bytes = f32le_pack(backend.sprite_instance_data)
  backend.queue.write_buffer(instance_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(1U, globals_bg, [])
  for batch in backend.sprite_batches {
    let tex = ensure_fallback_texture(backend, batch.texture_id)
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.sprite_instance_data.clear()
  backend.sprite_batches.clear()
  backend.sprite_instance_count = 0U
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
  ensure_sprite_resources(self)
  let tex = ensure_fallback_texture(self, texture_id)

  // Match Web runtime's sprite sizing convention (base quad is 128x128).
  let raw_uv_scale_x = uv_max_x - uv_min_x
  let raw_uv_scale_y = uv_max_y - uv_min_y
  let uv_scale_x = if raw_uv_scale_x <= 0.0F { 1.0F } else { raw_uv_scale_x }
  let uv_scale_y = if raw_uv_scale_y <= 0.0F { 1.0F } else { raw_uv_scale_y }
  let tex_w = Float::from_double(tex.width.to_double())
  let tex_h = Float::from_double(tex.height.to_double())
  let region_w = tex_w * uv_scale_x
  let region_h = tex_h * uv_scale_y
  let base_size = 128.0F
  let tex_scale_x = if region_w > 0.0F { region_w / base_size } else { 1.0F }
  let tex_scale_y = if region_h > 0.0F { region_h / base_size } else { 1.0F }
  let sprite_scale_x = scale_x * tex_scale_x
  let sprite_scale_y = scale_y * tex_scale_y
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.sprite_instance_count
  self.sprite_instance_count = first_instance + 1U

  // Instance layout: model(x,y,cos,sin), scale(x,y,_,_), color, uv(min_x,min_y,scale_x,scale_y)
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
  let vb_usage = @wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST
  let vb_bytes = f32le_pack(vertices_xy)
  let vb = self.device.create_buffer_init(usage=vb_usage, vb_bytes)
  let ib_usage = @wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST
  let ib_bytes = u16le_pack(indices_u16)
  let ib = self.device.create_buffer_init(usage=ib_usage, ib_bytes)
  let info = GpuMeshInfo::{
    id,
    index_count: 6U,
    vertex_count: 4U,
    vertex_buf: vb,
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
  let vb_usage = @wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST
  let vb = self.device.create_buffer_init(usage=vb_usage, f32le_pack(verts))
  let ib_usage = @wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let info = GpuMeshInfo::{
    id,
    index_count: inds.length().reinterpret_as_uint(),
    vertex_count: (verts.length() / 2).reinterpret_as_uint(),
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xy(
  self : GpuBackend,
  vertices_xy : Array[Float],
) -> Int {
  let vcount = vertices_xy.length() / 2
  if vcount <= 0 {
    return 0
  }
  // The encoded geometry is expected to be a flat list of triangle vertices.
  // Keep only complete triangles.
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
    vertices_xy
  } else {
    let out : Array[Float] = []
    for i in 0..<(usable_vcount * 2) {
      out.push(vertices_xy[i])
    }
    out
  }
  let vb_usage = @wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = @wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST
  let ib = self.device.create_buffer_init(
    usage=ib_usage,
    u16le_pack(indices_u16),
  )
  let info = GpuMeshInfo::{
    id,
    index_count: indices_u16.length().reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    vertex_buf: vb,
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
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  guard mesh_pipeline_for_current_pass(self) is Some(pipeline) else { return }
  guard self.mesh_uniform_buf is Some(uniform_buf) else { return }
  guard self.mesh_uniform_bg is Some(uniform_bg) else { return }
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
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  ])
  self.queue.write_buffer(uniform_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_bg, [])
  let vb_bytes = (mesh.vertex_count.reinterpret_as_int() * 8).to_uint64()
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
  pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
}
