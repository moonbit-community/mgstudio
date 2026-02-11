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
/// Minimal native GPU backend for engine platform APIs built on `Milky2018/wgpu_mbt`.
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
  vertex_stride_bytes : UInt64
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
pub struct UiBatch {
  texture_id : Int
  first_instance : UInt
  mut instance_count : UInt
}

///|
pub struct Mesh3dMaterialBindGroupCacheEntry {
  base_texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  bind_group : @wgpu.BindGroup
}

///|
pub struct GpuPassState {
  target_id : Int
  width_logical : Float
  height_logical : Float
  is_3d : Bool
  camera_x : Float
  camera_y : Float
  camera_rot : Float
  camera_scale : Float
  camera_z : Float
  camera_rot_x : Float
  camera_rot_y : Float
  camera_rot_z : Float
  camera_rot_w : Float
  camera_fov_y : Float
  camera_near : Float
  camera_far : Float
  viewport_x : UInt
  viewport_y : UInt
  viewport_w : UInt
  viewport_h : UInt
  ambient_r : Float
  ambient_g : Float
  ambient_b : Float
  ambient_brightness : Float
  directional_dir_x : Float
  directional_dir_y : Float
  directional_dir_z : Float
  directional_color_r : Float
  directional_color_g : Float
  directional_color_b : Float
  directional_illuminance : Float
  point_pos_x : Float
  point_pos_y : Float
  point_pos_z : Float
  point_color_r : Float
  point_color_g : Float
  point_color_b : Float
  point_intensity : Float
  point_range : Float
  spot_pos_x : Float
  spot_pos_y : Float
  spot_pos_z : Float
  spot_dir_x : Float
  spot_dir_y : Float
  spot_dir_z : Float
  spot_color_r : Float
  spot_color_g : Float
  spot_color_b : Float
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
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
  mut surface_format : @wgpu.TextureFormat?
  mut configured_width : Int
  mut configured_height : Int
  mut frame : GpuFrameState?
  mut pass_state : GpuPassState?
  mut depth_texture : @wgpu.Texture?
  mut depth_view : @wgpu.TextureView?
  mut depth_target_id : Int
  mut depth_width : Int
  mut depth_height : Int

  // Sprite pipeline (textured quads).
  mut sprite_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bgl_globals : @wgpu.BindGroupLayout?
  mut sprite_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_pipeline : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface_format : @wgpu.TextureFormat?
  mut sprite_globals_buf : @wgpu.Buffer?
  mut sprite_instance_buf : @wgpu.Buffer?
  mut sprite_instance_capacity : UInt64
  mut sprite_globals_bg : @wgpu.BindGroup?
  sprite_instance_data : Array[Float]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : UInt

  // UI pipeline (rounded rect + border, Bevy-aligned).
  mut ui_pipeline : @wgpu.RenderPipeline?
  mut ui_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_instance_buf : @wgpu.Buffer?
  mut ui_instance_capacity : UInt64
  mut ui_globals_bg : @wgpu.BindGroup?
  ui_instance_data : Array[Float]
  ui_batches : Array[UiBatch]
  mut ui_instance_count : UInt

  // UI box shadow pipeline (Bevy-aligned).
  mut ui_shadow_pipeline : @wgpu.RenderPipeline?
  mut ui_shadow_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_shadow_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_shadow_instance_buf : @wgpu.Buffer?
  mut ui_shadow_instance_capacity : UInt64
  mut ui_shadow_globals_bg : @wgpu.BindGroup?
  ui_shadow_instance_data : Array[Float]
  ui_shadow_batches : Array[UiBatch]
  mut ui_shadow_instance_count : UInt

  // UI texture slice pipeline (Bevy-aligned).
  mut ui_slice_pipeline : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_slice_instance_buf : @wgpu.Buffer?
  mut ui_slice_instance_capacity : UInt64
  mut ui_slice_globals_bg : @wgpu.BindGroup?
  ui_slice_instance_data : Array[Float]
  ui_slice_batches : Array[UiBatch]
  mut ui_slice_instance_count : UInt

  // Mesh pipeline (solid-color).
  mut mesh_bgl_uniform : @wgpu.BindGroupLayout?
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh_uniform_buf : @wgpu.Buffer?
  mut mesh_uniform_bg : @wgpu.BindGroup?
  mut mesh3d_bgl_uniform : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_material : @wgpu.BindGroupLayout?
  mut mesh3d_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_pipeline : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh3d_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh3d_uniform_buf : @wgpu.Buffer?
  mut mesh3d_uniform_bg : @wgpu.BindGroup?
  mesh3d_material_bg_cache : Ref[Array[Mesh3dMaterialBindGroupCacheEntry]]
  next_id : Ref[Int]
  textures : Ref[Array[GpuTextureInfo]]
  meshes : Ref[Array[GpuMeshInfo]]
}

///|
pub fn GpuBackend::new(
  assets_base? : String = "",
) -> GpuBackend raise GpuBackendError {
  let instance = @wgpu.Instance::create() catch {
    err => fatal("wgpu: Instance::create failed: " + err.message())
  }
  let adapter = instance.request_adapter_sync() catch {
    err =>
      fatal("wgpu: Instance::request_adapter_sync failed: " + err.message())
  }
  let device = adapter.request_device_sync(instance) catch {
    err => fatal("wgpu: Adapter::request_device_sync failed: " + err.message())
  }
  let queue = device.queue()
  GpuBackend::{
    instance,
    adapter,
    device,
    queue,
    assets_base,
    surface: None,
    surface_format: None,
    configured_width: 0,
    configured_height: 0,
    frame: None,
    pass_state: None,
    depth_texture: None,
    depth_view: None,
    depth_target_id: -2,
    depth_width: 0,
    depth_height: 0,
    sprite_bgl_tex: None,
    sprite_bgl_globals: None,
    sprite_pipeline_layout: None,
    sprite_pipeline: None,
    sprite_pipeline_surface: None,
    sprite_pipeline_surface_format: None,
    sprite_globals_buf: None,
    sprite_instance_buf: None,
    sprite_instance_capacity: 0UL,
    sprite_globals_bg: None,
    sprite_instance_data: [],
    sprite_batches: [],
    sprite_instance_count: 0U,
    ui_pipeline: None,
    ui_pipeline_surface: None,
    ui_pipeline_surface_format: None,
    ui_instance_buf: None,
    ui_instance_capacity: 0UL,
    ui_globals_bg: None,
    ui_instance_data: [],
    ui_batches: [],
    ui_instance_count: 0U,
    ui_shadow_pipeline: None,
    ui_shadow_pipeline_surface: None,
    ui_shadow_pipeline_surface_format: None,
    ui_shadow_instance_buf: None,
    ui_shadow_instance_capacity: 0UL,
    ui_shadow_globals_bg: None,
    ui_shadow_instance_data: [],
    ui_shadow_batches: [],
    ui_shadow_instance_count: 0U,
    ui_slice_pipeline: None,
    ui_slice_pipeline_surface: None,
    ui_slice_pipeline_surface_format: None,
    ui_slice_instance_buf: None,
    ui_slice_instance_capacity: 0UL,
    ui_slice_globals_bg: None,
    ui_slice_instance_data: [],
    ui_slice_batches: [],
    ui_slice_instance_count: 0U,
    mesh_bgl_uniform: None,
    mesh_pipeline_layout: None,
    mesh_pipeline: None,
    mesh_pipeline_surface: None,
    mesh_pipeline_surface_format: None,
    mesh_uniform_buf: None,
    mesh_uniform_bg: None,
    mesh3d_bgl_uniform: None,
    mesh3d_bgl_material: None,
    mesh3d_pipeline_layout: None,
    mesh3d_pipeline: None,
    mesh3d_pipeline_surface: None,
    mesh3d_pipeline_surface_format: None,
    mesh3d_uniform_buf: None,
    mesh3d_uniform_bg: None,
    mesh3d_material_bg_cache: Ref::new([]),
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
fn atan2f(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
fn quat_to_z_rotation(x : Float, y : Float, z : Float, w : Float) -> Float {
  let siny_cosp = 2.0F * (w * z + x * y)
  let cosy_cosp = 1.0F - 2.0F * (y * y + z * z)
  atan2f(siny_cosp, cosy_cosp)
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
fn ss(raw : UInt64) -> @wgpu.ShaderStage {
  @wgpu.ShaderStage::from_u64(raw)
}

///|
fn bu(raw : UInt64) -> @wgpu.BufferUsage {
  @wgpu.BufferUsage::from_u64(raw)
}

///|
fn tf(raw : UInt) -> @wgpu.TextureFormat {
  @wgpu.TextureFormat::from_u32(raw)
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

  // Globals + instances group (vertex stage).
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
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  guard backend.surface_format is Some(format) else { return }
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
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_sprite_pipeline_surface(backend)
        backend.sprite_pipeline_surface
      }
      _ => {
        ensure_sprite_pipeline_rgba8(backend)
        backend.sprite_pipeline
      }
    }
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
    backend, "shaders/mgstudio/ui/ui.wgsl",
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
) -> Unit raise GpuBackendError {
  ensure_ui_resources(backend)
  guard backend.surface_format is Some(format) else { return }
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
    backend, "shaders/mgstudio/ui/ui.wgsl",
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
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_ui_pipeline_surface(backend)
        backend.ui_pipeline_surface
      }
      _ => {
        ensure_ui_pipeline_rgba8(backend)
        backend.ui_pipeline
      }
    }
  } else {
    ensure_ui_pipeline_rgba8(backend)
    backend.ui_pipeline
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
    backend, "shaders/mgstudio/ui/box_shadow.wgsl",
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
) -> Unit raise GpuBackendError {
  ensure_ui_shadow_resources(backend)
  guard backend.surface_format is Some(format) else { return }
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
    backend, "shaders/mgstudio/ui/box_shadow.wgsl",
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
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_ui_shadow_pipeline_surface(backend)
        backend.ui_shadow_pipeline_surface
      }
      _ => {
        ensure_ui_shadow_pipeline_rgba8(backend)
        backend.ui_shadow_pipeline
      }
    }
  } else {
    ensure_ui_shadow_pipeline_rgba8(backend)
    backend.ui_shadow_pipeline
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
    backend, "shaders/mgstudio/ui/ui_texture_slice.wgsl",
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
) -> Unit raise GpuBackendError {
  ensure_ui_slice_resources(backend)
  guard backend.surface_format is Some(format) else { return }
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
    backend, "shaders/mgstudio/ui/ui_texture_slice.wgsl",
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
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_ui_slice_pipeline_surface(backend)
        backend.ui_slice_pipeline_surface
      }
      _ => {
        ensure_ui_slice_pipeline_rgba8(backend)
        backend.ui_slice_pipeline
      }
    }
  } else {
    ensure_ui_slice_pipeline_rgba8(backend)
    backend.ui_slice_pipeline
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
fn mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
  layout : @wgpu.PipelineLayout,
  shader : @wgpu.ShaderModule,
  format : UInt,
  with_depth? : Bool = false,
  position3d? : Bool = false,
) -> @wgpu_c.WGPURenderPipelineDescriptorPtr raise GpuBackendError {
  let builder = @wgpu_c.render_pipeline_desc_builder_new(
    layout.raw_handle(),
    shader.raw_handle(),
  )
  let set_format_ok = @wgpu_c.render_pipeline_desc_builder_set_color_target_format(
    builder, format,
  )
  let set_blend_ok = @wgpu_c.render_pipeline_desc_builder_enable_alpha_blend(
    builder,
  )
  let vertex_stride = if position3d { 36UL } else { 32UL }
  let pos_format = if position3d {
    @wgpu.VERTEX_FORMAT_FLOAT32X3
  } else {
    @wgpu.VERTEX_FORMAT_FLOAT32X2
  }
  let uv_offset = if position3d { 12UL } else { 8UL }
  let color_offset = if position3d { 20UL } else { 16UL }
  let set_vertex_layout_ok = @wgpu_c.render_pipeline_desc_builder_set_vertex_buffer_layout(
    builder,
    vertex_stride,
    @wgpu.VERTEX_STEP_MODE_VERTEX,
  )
  let pos_ok = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder, pos_format, 0UL, 0U,
  )
  let uv_ok = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X2,
    uv_offset,
    1U,
  )
  let color_ok = @wgpu_c.render_pipeline_desc_builder_add_vertex_attribute(
    builder,
    @wgpu.VERTEX_FORMAT_FLOAT32X4,
    color_offset,
    2U,
  )
  if set_format_ok == 0U ||
    set_blend_ok == 0U ||
    set_vertex_layout_ok == 0U ||
    pos_ok == 0U ||
    uv_ok == 0U ||
    color_ok == 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal(
      "wgpu: failed to configure mesh vertex attributes for pos2+uv2+color4 pipeline",
    )
  }
  let set_topology_ok = @wgpu_c.render_pipeline_desc_builder_set_topology(
    builder,
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
  )
  if set_topology_ok == 0U {
    @wgpu_c.render_pipeline_desc_builder_free(builder)
    fatal("wgpu: failed to configure mesh pipeline topology")
  }
  if with_depth {
    let set_depth_ok = @wgpu_c.render_pipeline_desc_builder_set_depth_stencil(
      builder,
      @wgpu.TEXTURE_FORMAT_DEPTH24_PLUS,
      true,
      @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
    )
    if set_depth_ok == 0U {
      @wgpu_c.render_pipeline_desc_builder_free(builder)
      fatal("wgpu: failed to configure mesh pipeline depth-stencil state")
    }
  }
  @wgpu_c.render_pipeline_desc_builder_finish(builder)
}

///|
fn ensure_mesh_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh_pipeline_layout is None {
    guard backend.sprite_bgl_tex is Some(bgl_tex) else { return }
    let bgl = backend.device.create_bind_group_layout_uniform_buffer()
    let pl = backend.device.create_pipeline_layout_2(bgl, bgl_tex)
    backend.mesh_bgl_uniform = Some(bgl)
    backend.mesh_pipeline_layout = Some(pl)
  }
  if backend.mesh_uniform_buf is None || backend.mesh_uniform_bg is None {
    guard backend.mesh_bgl_uniform is Some(bgl) else { return }
    let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
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
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    position3d=true,
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
  ensure_sprite_resources(backend)
  guard backend.surface_format is Some(format) else { return }
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
    with_depth=true,
    position3d=true,
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
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_mesh_pipeline_surface(backend)
        return backend.mesh_pipeline_surface
      }
      _ => ()
    }
  }
  ensure_mesh_pipeline_rgba8(backend)
  backend.mesh_pipeline
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh3d_pipeline_layout is None {
    let bgl = backend.device.create_bind_group_layout_uniform_buffer()
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
    let material_ok = material_builder.add_sampler(
        0U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        2U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        4U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_texture(
        5U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh3d material bind group layout")
    }
    let material_bgl = material_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_material_bgl",
    )
    let pl = backend.device.create_pipeline_layout_2(bgl, material_bgl)
    backend.mesh3d_bgl_uniform = Some(bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_pipeline_layout = Some(pl)
    mesh3d_material_cache_clear(backend)
  }
  if backend.mesh3d_uniform_buf is None || backend.mesh3d_uniform_bg is None {
    guard backend.mesh3d_bgl_uniform is Some(bgl) else { return }
    let ubo_usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
    let uniform_buf = backend.device.create_buffer(size=512UL, usage=ubo_usage)
    let uniform_bg = backend.device.create_bind_group_uniform_buffer(
      bgl, uniform_buf,
    )
    backend.mesh3d_uniform_buf = Some(uniform_buf)
    backend.mesh3d_uniform_bg = Some(uniform_bg)
  }
  if backend.mesh3d_pipeline is Some(_) {
    return
  }
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/3d/mesh3d.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    position3d=true,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh3d_rgba8")
  backend.mesh3d_pipeline = Some(pipeline)
  sm.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  guard backend.surface_format is Some(format) else { return }
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) &&
    prev == format &&
    backend.mesh3d_pipeline_surface is Some(_) {
    return
  }
  if backend.mesh3d_pipeline_surface is Some(old) {
    old.release()
  }
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(
    backend, "shaders/mgstudio/3d/mesh3d.wgsl",
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    position3d=true,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  pipeline.set_label("mgstudio_mesh3d_surface")
  backend.mesh3d_pipeline_surface = Some(pipeline)
  backend.mesh3d_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let target_is_surface = match backend.pass_state {
    Some(ps) => ps.target_id == -1
    None => false
  }
  if target_is_surface {
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        ensure_mesh3d_pipeline_surface(backend)
        return backend.mesh3d_pipeline_surface
      }
      _ => ()
    }
  }
  ensure_mesh3d_pipeline_rgba8(backend)
  backend.mesh3d_pipeline
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
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
  self.surface_format = Some(
    surface.configure_default(self.adapter, self.device, w, h, usage),
  )
  let fmt_u32 = match self.surface_format {
    Some(f) => f.to_u32()
    None => 0U
  }
  @debug.debug("wgpu: surface_format_u32=" + fmt_u32.to_string())
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
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  let cmd = frame.encoder.finish()
  self.queue.submit_one(cmd)
  cmd.release()
  guard self.surface is Some(surface) else {
    frame.encoder.release()
    frame.surface_view.release()
    frame.surface_tex.release()
    self.frame = None
    self.pass_state = None
    return
  }
  surface.present() |> ignore
  self.instance.process_events()
  frame.encoder.release()
  frame.surface_view.release()
  frame.surface_tex.release()
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
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_material_bg_cache.val {
    entry.bind_group.release()
  }
  backend.mesh3d_material_bg_cache.val.clear()
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
  base_texture : GpuTextureInfo,
  normal_texture : GpuTextureInfo,
  emissive_texture : GpuTextureInfo,
  metallic_roughness_texture : GpuTextureInfo,
  occlusion_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  for entry in backend.mesh3d_material_bg_cache.val {
    if entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id {
      return entry.bind_group
    }
  }
  let layout = match backend.mesh3d_bgl_material {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d material bind group layout")
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let ok = builder.add_sampler(0U, base_texture.sampler) &&
    builder.add_texture_view(1U, base_texture.view) &&
    builder.add_texture_view(2U, normal_texture.view) &&
    builder.add_texture_view(3U, emissive_texture.view) &&
    builder.add_texture_view(4U, metallic_roughness_texture.view) &&
    builder.add_texture_view(5U, occlusion_texture.view)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d material bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_material_bg",
  )
  backend.mesh3d_material_bg_cache.val.push(Mesh3dMaterialBindGroupCacheEntry::{
    base_texture_id: base_texture.id,
    normal_texture_id: normal_texture.id,
    emissive_texture_id: emissive_texture.id,
    metallic_roughness_texture_id: metallic_roughness_texture.id,
    occlusion_texture_id: occlusion_texture.id,
    bind_group,
  })
  bind_group
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
    let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST |
      @wgpu.TEXTURE_USAGE_COPY_SRC
    let usage = @wgpu.TextureUsage::from_u64(usage_bits)
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
    mesh3d_material_cache_clear(backend)
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
  let usage_bits = @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
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
  mesh3d_material_cache_clear(self)
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
      let sampler = match sampler_kind {
        1 => self.device.create_sampler_nearest_clamp()
        2 => self.device.create_sampler_linear_repeat()
        3 => self.device.create_sampler_nearest_repeat()
        _ => self.device.create_sampler_linear_clamp()
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
      mesh3d_material_cache_clear(self)
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
  let usage_bits = @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
  let usage = @wgpu.TextureUsage::from_u64(usage_bits)
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
  mesh3d_material_cache_clear(self)
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
fn target_size_for_pass(backend : GpuBackend, target_id : Int) -> (Int, Int)? {
  if target_id == -1 {
    Some((backend.configured_width, backend.configured_height))
  } else {
    match find_texture(backend, target_id) {
      Some(info) => Some((info.width, info.height))
      None => None
    }
  }
}

///|
fn ensure_depth_view_for_target(
  backend : GpuBackend,
  target_id : Int,
) -> @wgpu.TextureView? {
  guard target_size_for_pass(backend, target_id) is Some((raw_w, raw_h)) else {
    return None
  }
  let width = if raw_w <= 0 { 1 } else { raw_w }
  let height = if raw_h <= 0 { 1 } else { raw_h }
  if backend.depth_target_id == target_id &&
    backend.depth_width == width &&
    backend.depth_height == height {
    if backend.depth_view is Some(view) {
      return Some(view)
    }
  }
  if backend.depth_view is Some(old_view) {
    old_view.release()
  }
  if backend.depth_texture is Some(old_tex) {
    old_tex.release()
  }
  let depth_tex = backend.device.create_texture_depth24plus_2d(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
  )
  let depth_view = depth_tex.create_view()
  backend.depth_texture = Some(depth_tex)
  backend.depth_view = Some(depth_view)
  backend.depth_target_id = target_id
  backend.depth_width = width
  backend.depth_height = height
  Some(depth_view)
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
    is_3d: false,
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: if camera_scale == 0.0F {
      1.0F
    } else {
      camera_scale
    },
    camera_z: 0.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    camera_fov_y: PI * 0.5F,
    camera_near: 0.1F,
    camera_far: 1000.0F,
    viewport_x: vx,
    viewport_y: vy,
    viewport_w: vw,
    viewport_h: vh,
    ambient_r: 1.0F,
    ambient_g: 1.0F,
    ambient_b: 1.0F,
    ambient_brightness: 0.0F,
    directional_dir_x: 0.0F,
    directional_dir_y: -1.0F,
    directional_dir_z: 0.0F,
    directional_color_r: 1.0F,
    directional_color_g: 1.0F,
    directional_color_b: 1.0F,
    directional_illuminance: 0.0F,
    point_pos_x: 0.0F,
    point_pos_y: 0.0F,
    point_pos_z: 0.0F,
    point_color_r: 1.0F,
    point_color_g: 1.0F,
    point_color_b: 1.0F,
    point_intensity: 0.0F,
    point_range: 1.0F,
    spot_pos_x: 0.0F,
    spot_pos_y: 0.0F,
    spot_pos_z: 0.0F,
    spot_dir_x: 0.0F,
    spot_dir_y: -1.0F,
    spot_dir_z: 0.0F,
    spot_color_r: 1.0F,
    spot_color_g: 1.0F,
    spot_color_b: 1.0F,
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
  })

  // Reset sprite batching state and update sprite globals for this pass.
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_instance_data.clear()
  self.ui_batches.clear()
  self.ui_instance_count = 0U
  self.ui_shadow_instance_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_instance_count = 0U
  self.ui_slice_instance_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_instance_count = 0U
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
pub fn GpuBackend::begin_pass_3d(
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
  camera_z : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
  camera_fov_y : Float,
  camera_near : Float,
  camera_far : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_w : Int,
  viewport_h : Int,
  ambient_r : Float,
  ambient_g : Float,
  ambient_b : Float,
  ambient_brightness : Float,
  directional_dir_x : Float,
  directional_dir_y : Float,
  directional_dir_z : Float,
  directional_color_r : Float,
  directional_color_g : Float,
  directional_color_b : Float,
  directional_illuminance : Float,
  point_pos_x : Float,
  point_pos_y : Float,
  point_pos_z : Float,
  point_color_r : Float,
  point_color_g : Float,
  point_color_b : Float,
  point_intensity : Float,
  point_range : Float,
  spot_pos_x : Float,
  spot_pos_y : Float,
  spot_pos_z : Float,
  spot_dir_x : Float,
  spot_dir_y : Float,
  spot_dir_z : Float,
  spot_color_r : Float,
  spot_color_g : Float,
  spot_color_b : Float,
  spot_intensity : Float,
  spot_range : Float,
  spot_inner_angle : Float,
  spot_outer_angle : Float,
) -> Unit raise GpuBackendError {
  let camera_rot = quat_to_z_rotation(
    camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w,
  )
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    pass.end()
    pass.release()
    frame.pass = None
  }
  guard target_view(self, target_id) is Some(view) else { return }
  guard ensure_depth_view_for_target(self, target_id) is Some(depth_view) else {
    return
  }
  let pass = frame.encoder.begin_render_pass_color_depth_u32(
    view,
    depth_view,
    color_load_op_u32=@wgpu.LOAD_OP_CLEAR,
    color_store_op_u32=@wgpu.STORE_OP_STORE,
    color_clear_r_f32=clear_r,
    color_clear_g_f32=clear_g,
    color_clear_b_f32=clear_b,
    color_clear_a_f32=clear_a,
    depth_load_op_u32=@wgpu.LOAD_OP_CLEAR,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=1.0F,
    depth_read_only=false,
    stencil_load_op_u32=@wgpu.LOAD_OP_CLEAR,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    stencil_read_only=true,
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
    is_3d: true,
    camera_x,
    camera_y,
    camera_rot,
    camera_scale: 1.0F,
    camera_z,
    camera_rot_x,
    camera_rot_y,
    camera_rot_z,
    camera_rot_w,
    camera_fov_y,
    camera_near,
    camera_far,
    viewport_x: vx,
    viewport_y: vy,
    viewport_w: vw,
    viewport_h: vh,
    ambient_r,
    ambient_g,
    ambient_b,
    ambient_brightness,
    directional_dir_x,
    directional_dir_y,
    directional_dir_z,
    directional_color_r,
    directional_color_g,
    directional_color_b,
    directional_illuminance,
    point_pos_x,
    point_pos_y,
    point_pos_z,
    point_color_r,
    point_color_g,
    point_color_b,
    point_intensity,
    point_range,
    spot_pos_x,
    spot_pos_y,
    spot_pos_z,
    spot_dir_x,
    spot_dir_y,
    spot_dir_z,
    spot_color_r,
    spot_color_g,
    spot_color_b,
    spot_intensity,
    spot_range,
    spot_inner_angle,
    spot_outer_angle,
  })
  self.sprite_instance_data.clear()
  self.sprite_batches.clear()
  self.sprite_instance_count = 0U
  self.ui_instance_data.clear()
  self.ui_batches.clear()
  self.ui_instance_count = 0U
  self.ui_shadow_instance_data.clear()
  self.ui_shadow_batches.clear()
  self.ui_shadow_instance_count = 0U
  self.ui_slice_instance_data.clear()
  self.ui_slice_batches.clear()
  self.ui_slice_instance_count = 0U
  ensure_sprite_resources(self)
  if self.sprite_globals_buf is Some(globals_buf) {
    let w = Float::from_double(width_logical.to_double())
    let h = Float::from_double(height_logical.to_double())
    let scale_x_base = if w > 0.0F { 2.0F / w } else { 0.0F }
    let scale_y_base = if h > 0.0F { 2.0F / h } else { 0.0F }
    let cam_cos = cosf(-camera_rot)
    let cam_sin = sinf(-camera_rot)
    let bytes = f32le_pack([
      camera_x, camera_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0F, 0.0F,
    ])
    self.queue.write_buffer(globals_buf, 0UL, bytes)
  }
}

///|
pub fn GpuBackend::set_scissor(
  self : GpuBackend,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  let sx = if x < 0 { 0U } else { x.reinterpret_as_uint() }
  let sy = if y < 0 { 0U } else { y.reinterpret_as_uint() }
  let sw = if width < 0 { 0U } else { width.reinterpret_as_uint() }
  let sh = if height < 0 { 0U } else { height.reinterpret_as_uint() }
  pass.set_scissor_rect(sx, sy, sw, sh)
}

///|
pub fn GpuBackend::clear_scissor(
  self : GpuBackend,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  pass.set_scissor_rect(
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
}

///|
pub fn GpuBackend::end_pass(self : GpuBackend) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_ui_shadow_batches(self)
    flush_ui_slice_batches(self)
    flush_ui_batches(self)
    flush_sprite_batches(self)
    pass.end()
    pass.release()
    frame.pass = None
  }
  self.pass_state = None
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
    let tex = ensure_fallback_texture(backend, batch.texture_id)
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
    let tex = ensure_fallback_texture(backend, batch.texture_id)
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
    let tex = ensure_fallback_texture(backend, batch.texture_id)
    pass.set_bind_group(0U, tex.bind_group, [])
    pass.draw(6U, batch.instance_count, 0U, batch.first_instance)
  }
  backend.ui_instance_data.clear()
  backend.ui_batches.clear()
  backend.ui_instance_count = 0U
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
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
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
  let tex = ensure_fallback_texture(self, texture_id)

  // UI sizing convention:
  // - Engine passes `scale_x/scale_y` in logical pixels (final rect size).
  // - Vertex shader uses a 128x128 base quad, so convert pixels -> quad scale.
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

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_)
  // - color
  // - uv(min_x,min_y,scale_x,scale_y)
  // - flags(f32,0,0,0)
  // - radius(tl,tr,br,bl)
  // - border(left,top,right,bottom)
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
  let tex = ensure_fallback_texture(self, texture_id)

  // Geometry is a 128x128 base quad; engine passes final bounds in logical pixels.
  let base_size = 128.0F
  let ui_scale_x = scale_x / base_size
  let ui_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_slice_instance_count
  self.ui_slice_instance_count = first_instance + 1U

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_)
  // - color
  // - texture_slices(l,t,r,b)
  // - target_slices(l,t,r,b)
  // - repeat(side_x,side_y,center_x,center_y)
  // - atlas_rect(l,t,r,b)
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
  let tex = ensure_fallback_texture(self, texture_id)

  // Geometry is a 128x128 base quad; engine passes final bounds in world units.
  let base_size = 128.0F
  let shadow_scale_x = scale_x / base_size
  let shadow_scale_y = scale_y / base_size
  let cosv = cosf(rotation)
  let sinv = sinf(rotation)
  let first_instance = self.ui_shadow_instance_count
  self.ui_shadow_instance_count = first_instance + 1U
  let samples_f = Float::from_double(samples.to_double())

  // Instance layout:
  // - model(x,y,cos,sin)
  // - scale(x,y,_,_) where x/y represent bounds / 128
  // - color
  // - size(x,y,blur,samples)
  // - radius(tl,tr,br,bl)
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
    vertex_stride_bytes: 32UL,
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
    vertex_stride_bytes: 32UL,
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
    vertex_stride_bytes: 32UL,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.val.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xyzuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  let vcount = vertices.length() / 9
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
    for i in 0..<(usable_vcount * 9) {
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
    vertex_stride_bytes: 36UL,
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
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  if mesh.vertex_stride_bytes != 32UL {
    return
  }
  guard mesh_pipeline_for_current_pass(self) is Some(pipeline) else { return }
  guard self.mesh_uniform_buf is Some(uniform_buf) else { return }
  guard self.mesh_uniform_bg is Some(uniform_bg) else { return }
  let resolved_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let texture = ensure_fallback_texture(self, resolved_texture_id)
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
  self.queue.write_buffer(uniform_buf, 0UL, bytes)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_bg, [])
  pass.set_bind_group(1U, texture.bind_group, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
  pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
}

///|
pub fn GpuBackend::draw_mesh3d(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  unlit : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  if mesh.vertex_stride_bytes != 36UL {
    return
  }
  guard mesh3d_pipeline_for_current_pass(self) is Some(pipeline) else { return }
  guard self.mesh3d_uniform_buf is Some(uniform_buf) else { return }
  guard self.mesh3d_uniform_bg is Some(uniform_bg) else { return }
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    -1
  } else {
    normal_texture_id
  }
  let resolved_emissive_texture_id = if emissive_texture_id < 0 {
    -1
  } else {
    emissive_texture_id
  }
  let resolved_metallic_roughness_texture_id = if metallic_roughness_texture_id <
    0 {
    -1
  } else {
    metallic_roughness_texture_id
  }
  let resolved_occlusion_texture_id = if occlusion_texture_id < 0 {
    -1
  } else {
    occlusion_texture_id
  }
  let base_texture = ensure_fallback_texture(self, resolved_base_texture_id)
  let normal_texture = ensure_fallback_texture(self, resolved_normal_texture_id)
  let emissive_texture = ensure_fallback_texture(
    self, resolved_emissive_texture_id,
  )
  let metallic_roughness_texture = ensure_fallback_texture(
    self, resolved_metallic_roughness_texture_id,
  )
  let occlusion_texture = ensure_fallback_texture(
    self, resolved_occlusion_texture_id,
  )
  let textured = texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let emissive_textured = emissive_texture_id >= 0
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let occlusion_textured = occlusion_texture_id >= 0
  let aspect_ratio = if ps.height_logical > 0.0F {
    ps.width_logical / ps.height_logical
  } else {
    1.0F
  }
  let uv_offset_x_value = if textured { uv_offset_x } else { 0.0F }
  let uv_offset_y_value = if textured { uv_offset_y } else { 0.0F }
  let uv_scale_x_value = if textured { uv_scale_x } else { -1.0F }
  let uv_scale_y_value = if textured { uv_scale_y } else { -1.0F }
  let bytes = f32le_pack([
    x,
    y,
    z,
    1.0F,
    rotation_x,
    rotation_y,
    rotation_z,
    rotation_w,
    scale_x,
    scale_y,
    scale_z,
    1.0F,
    ps.camera_x,
    ps.camera_y,
    ps.camera_z,
    1.0F,
    ps.camera_rot_x,
    ps.camera_rot_y,
    ps.camera_rot_z,
    ps.camera_rot_w,
    ps.camera_fov_y,
    aspect_ratio,
    ps.camera_near,
    ps.camera_far,
    color_r,
    color_g,
    color_b,
    color_a,
    uv_offset_x_value,
    uv_offset_y_value,
    uv_scale_x_value,
    uv_scale_y_value,
    ps.ambient_r,
    ps.ambient_g,
    ps.ambient_b,
    ps.ambient_brightness,
    ps.directional_dir_x,
    ps.directional_dir_y,
    ps.directional_dir_z,
    ps.directional_illuminance,
    ps.directional_color_r,
    ps.directional_color_g,
    ps.directional_color_b,
    1.0F,
    ps.point_pos_x,
    ps.point_pos_y,
    ps.point_pos_z,
    ps.point_range,
    ps.point_color_r,
    ps.point_color_g,
    ps.point_color_b,
    ps.point_intensity,
    ps.spot_pos_x,
    ps.spot_pos_y,
    ps.spot_pos_z,
    ps.spot_range,
    ps.spot_dir_x,
    ps.spot_dir_y,
    ps.spot_dir_z,
    ps.spot_inner_angle,
    ps.spot_color_r,
    ps.spot_color_g,
    ps.spot_color_b,
    ps.spot_intensity,
    ps.spot_outer_angle,
    0.0F,
    0.0F,
    0.0F,
    emissive_r,
    emissive_g,
    emissive_b,
    unlit,
    metallic,
    roughness,
    reflectance,
    if normal_textured {
      1.0F
    } else {
      0.0F
    },
    if textured {
      1.0F
    } else {
      0.0F
    },
    if emissive_textured {
      1.0F
    } else {
      0.0F
    },
    if metallic_roughness_textured {
      1.0F
    } else {
      0.0F
    },
    if occlusion_textured {
      1.0F
    } else {
      0.0F
    },
  ])
  self.queue.write_buffer(uniform_buf, 0UL, bytes)
  let material_bg = mesh3d_material_cache_get_or_create(
    self, base_texture, normal_texture, emissive_texture, metallic_roughness_texture,
    occlusion_texture,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, uniform_bg, [])
  pass.set_bind_group(1U, material_bg, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  let index_bytes = (mesh.index_count.reinterpret_as_int() * 2).to_uint64()
  pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  pass.draw_indexed(mesh.index_count, 1U, 0U, 0, 0U)
}
