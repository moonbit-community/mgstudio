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
const MESH2D_BEVY_VERTEX_STRIDE_BYTES : UInt64 = 36UL

///|
const MESH2D_COLOR_MATERIAL_SHADER_PATH : String = "shaders/bevy/bevy_sprite_render/mesh2d/color_material.wgsl"

///|
const MESH2D_ALPHA_MODE_KIND_OPAQUE : Int = 0

///|
const MESH2D_ALPHA_MODE_KIND_MASK : Int = 1

///|
const MESH2D_ALPHA_MODE_KIND_BLEND : Int = 2

///|
const COLOR_MATERIAL_FLAGS_TEXTURE : UInt = 1U

///|
const COLOR_MATERIAL_FLAGS_ALPHA_MODE_MASK : UInt = 0x40000000U

///|
const COLOR_MATERIAL_FLAGS_ALPHA_MODE_BLEND : UInt = 0x80000000U

///|
priv struct Mesh2dPipelineKey {
  color_format : @wgpu.TextureFormat
  primitive_topology : UInt
  blend_alpha : Bool
  hdr : Bool
  tonemap_in_shader : Bool
  deband_dither : Bool
  may_discard : Bool
}

///|
fn mesh2d_align_up(value : UInt64, alignment : UInt64) -> UInt64 {
  if alignment == 0UL {
    return value
  }
  let remainder = value % alignment
  if remainder == 0UL {
    value
  } else {
    value + alignment - remainder
  }
}

///|
fn mesh2d_pipeline_cache_key(key : Mesh2dPipelineKey) -> String {
  let format_bits = key.color_format.raw.to_string()
  let topology_bits = key.primitive_topology.to_string()
  let blend_bits = if key.blend_alpha { "1" } else { "0" }
  let hdr_bits = if key.hdr { "1" } else { "0" }
  let tonemap_bits = if key.tonemap_in_shader { "1" } else { "0" }
  let deband_bits = if key.deband_dither { "1" } else { "0" }
  let discard_bits = if key.may_discard { "1" } else { "0" }
  format_bits +
  "_" +
  topology_bits +
  "_" +
  blend_bits +
  hdr_bits +
  tonemap_bits +
  deband_bits +
  discard_bits
}

///|
fn mesh2d_pipeline_define_keys(key : Mesh2dPipelineKey) -> Array[String] {
  let defines = ["VERTEX_POSITIONS", "VERTEX_UVS", "VERTEX_COLORS"]
  if key.tonemap_in_shader {
    defines.push("TONEMAP_IN_SHADER")
    defines.push("TONEMAP_METHOD_NONE")
    if key.deband_dither {
      defines.push("DEBAND_DITHER")
    }
  }
  if key.may_discard {
    defines.push("MAY_DISCARD")
  }
  defines
}

///|
fn ensure_mesh2d_instance_uniform_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh2d_mesh_bgl is Some(bgl) else { return None }
  if backend.mesh2d_instance_buf is Some(uniform_buf) &&
    backend.mesh2d_instance_bg is Some(uniform_bg) &&
    backend.mesh2d_instance_capacity >= required_size {
    return Some((uniform_buf, uniform_bg))
  }
  let mut next_capacity = if backend.mesh2d_instance_capacity > 0UL {
    backend.mesh2d_instance_capacity
  } else {
    mesh2d_align_up(
      MESH2D_BEVY_UNIFORM_DYNAMIC_STRIDE_BYTES * 1024UL,
      MESH2D_BEVY_UNIFORM_DYNAMIC_STRIDE_BYTES,
    )
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST)
  let uniform_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    uniform_buf,
    size=MESH2D_BEVY_UNIFORM_STRIDE_BYTES,
  )
  if !ok {
    builder.free()
    return None
  }
  let uniform_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh2d_instance_uniform_bg",
  )
  backend.mesh2d_instance_buf = Some(uniform_buf)
  backend.mesh2d_instance_bg = Some(uniform_bg)
  backend.mesh2d_instance_capacity = next_capacity
  Some((uniform_buf, uniform_bg))
}

///|
fn mesh2d_strip_fragment_entry(source : String) -> String raise GpuBackendError {
  match split_once_text(source, "@fragment\nfn fragment(") {
    Some((prefix, _)) => prefix
    None =>
      fatal(
        "wgpu: failed to strip mesh2d fragment entry from registered source",
      )
  }
}

///|
fn load_wgsl_with_defines_required_mesh2d_color_material(
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  value_defines.set("MATERIAL_BIND_GROUP", 2)
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  let mesh_source = registered_wgsl_source_required(
    "shaders/bevy/bevy_sprite_render/mesh2d/mesh2d.wgsl",
  )
  let material_source = registered_wgsl_source_required(
    MESH2D_COLOR_MATERIAL_SHADER_PATH,
  )
  let combined_source = mesh2d_strip_fragment_entry(mesh_source) +
    "\n" +
    material_source
  preprocess_wgsl_source(
    "", combined_source, defines, value_defines, visited, modules,
  )
}

///|
fn ensure_mesh2d_resources(backend : GpuBackend) -> Unit raise GpuBackendError {
  if backend.mesh_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=true,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_texture(
        2U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_3D,
      ) &&
      view_builder.add_sampler(
        3U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh2d view bind group layout")
    }
    let bgl_view = view_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_view_bind_group_layout",
    )
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      view_stage,
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      has_dynamic_offset=true,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh2d bind group layout")
    }
    let bgl_mesh = mesh_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_mesh_bind_group_layout",
    )
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let material_ok = material_builder.add_buffer(
        0U,
        fragment_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      material_builder.add_texture(
        1U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        2U,
        fragment_stage,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh2d material bind group layout")
    }
    let bgl_material = material_builder.finish(
      backend.device,
      label="mgstudio_mesh2d_material_bind_group_layout",
    )
    let pipeline_layout = create_pipeline_layout_3(
      backend.device,
      bgl_view,
      bgl_mesh,
      bgl_material,
    )
    pipeline_layout.set_label("mgstudio_mesh2d_pipeline_layout")
    let view_buf = backend.device.create_buffer(
      size=MESH2D_BEVY_VIEW_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH2D_BEVY_GLOBALS_BUFFER_SIZE,
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
    let lut_sampler = backend.device.create_sampler_linear_clamp()
    let view_bg_builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let view_bg_ok = view_bg_builder.add_buffer(
        0U,
        view_buf,
        size=MESH2D_BEVY_VIEW_BUFFER_SIZE,
      ) &&
      view_bg_builder.add_buffer(1U, globals_buf) &&
      view_bg_builder.add_texture_view(2U, lut_view) &&
      view_bg_builder.add_sampler(3U, lut_sampler)
    if !view_bg_ok {
      view_bg_builder.free()
      fatal("wgpu: failed to build mesh2d view bind group")
    }
    let view_bg = view_bg_builder.finish(
      backend.device,
      bgl_view,
      label="mgstudio_mesh2d_view_bind_group",
    )
    backend.mesh2d_view_bgl = Some(bgl_view)
    backend.mesh2d_mesh_bgl = Some(bgl_mesh)
    backend.mesh2d_material_bgl = Some(bgl_material)
    backend.mesh_pipeline_layout = Some(pipeline_layout)
    backend.mesh2d_view_buf = Some(view_buf)
    backend.mesh2d_globals_buf = Some(globals_buf)
    backend.mesh2d_lut_texture = Some(lut_texture)
    backend.mesh2d_lut_view = Some(lut_view)
    backend.mesh2d_lut_sampler = Some(lut_sampler)
    backend.mesh2d_view_bg = Some(view_bg)
    backend.mesh2d_instance_buf = None
    backend.mesh2d_instance_bg = None
    backend.mesh2d_instance_capacity = 0UL
    backend.mesh2d_instance_used = 0
    backend.mesh2d_pipeline_cache.clear()
    backend.mesh2d_material_bg_cache.clear()
    if ensure_mesh2d_instance_uniform_binding(
        backend,
        MESH2D_BEVY_UNIFORM_DYNAMIC_STRIDE_BYTES,
      )
      is None {
      fatal("wgpu: failed to initialize mesh2d uniform bind group")
    }
  }
}

///|
fn create_mesh2d_pipeline(
  backend : GpuBackend,
  key : Mesh2dPipelineKey,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  guard backend.mesh_pipeline_layout is Some(layout) else {
    fatal("wgpu: mesh2d bevy pipeline layout is None")
  }
  let wgsl = load_wgsl_with_defines_required_mesh2d_color_material(
    mesh2d_pipeline_define_keys(key),
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout~)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(key.color_format)
    builder.set_topology_u32(key.primitive_topology)
    if key.blend_alpha {
      builder.enable_alpha_blend()
    } else {
      builder.disable_blend()
    }
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=!key.blend_alpha,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    builder.set_vertex_buffer_layout(
      MESH2D_BEVY_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 12UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 20UL, 4U)
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal("wgpu: failed to build mesh2d bevy render pipeline")
    }
  }
  pipeline.set_label(label)
  sm.release()
  pipeline
}

///|
fn mesh2d_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
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
  let target_float_count = (MESH2D_BEVY_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in floats.length()..<target_float_count {
    floats.push(0.0F)
  }
  f32le_pack(floats)
}

///|
fn mesh2d_globals_uniform_bytes() -> Bytes {
  Bytes::makei(MESH2D_BEVY_GLOBALS_BUFFER_SIZE.to_int(), _ => (0).to_byte())
}

///|
fn mesh2d_instance_uniform_bytes(
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  flags : UInt,
  tag : UInt,
) -> Bytes {
  let cosr = cosf(rotation)
  let sinr = sinf(rotation)
  let safe_scale_x = if scale_x == 0.0F { 1.0F } else { scale_x }
  let safe_scale_y = if scale_y == 0.0F { 1.0F } else { scale_y }
  let world_x_axis_x = scale_x * cosr
  let world_x_axis_y = scale_x * sinr
  let world_y_axis_x = -scale_y * sinr
  let world_y_axis_y = scale_y * cosr
  let inverse_transpose_x_axis_x = cosr / safe_scale_x
  let inverse_transpose_x_axis_y = sinr / safe_scale_x
  let inverse_transpose_y_axis_x = -sinr / safe_scale_y
  let inverse_transpose_y_axis_y = cosr / safe_scale_y
  // Matches bevy_math::Affine3Ext::to_transpose + inverse_transpose_3x3 packing.
  let words : Array[UInt] = [
    f32_bits(world_x_axis_x),
    f32_bits(world_y_axis_x),
    f32_bits(0.0F),
    f32_bits(x),
    f32_bits(world_x_axis_y),
    f32_bits(world_y_axis_y),
    f32_bits(0.0F),
    f32_bits(y),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
    f32_bits(0.0F),
    f32_bits(inverse_transpose_x_axis_x),
    f32_bits(inverse_transpose_x_axis_y),
    f32_bits(0.0F),
    f32_bits(inverse_transpose_y_axis_x),
    f32_bits(inverse_transpose_y_axis_y),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
    flags,
    tag,
    0U,
  ]
  u32le_pack(words)
}

///|
fn mesh2d_color_material_flags(texture_id : Int, alpha_mode_kind : Int) -> UInt {
  let mut flags = 0U
  if texture_id >= 0 {
    flags = flags | COLOR_MATERIAL_FLAGS_TEXTURE
  }
  if alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_MASK {
    flags = flags | COLOR_MATERIAL_FLAGS_ALPHA_MODE_MASK
  } else if alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_BLEND {
    flags = flags | COLOR_MATERIAL_FLAGS_ALPHA_MODE_BLEND
  }
  flags
}

///|
fn mesh2d_color_material_uniform_bytes(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
) -> Bytes {
  let flags = mesh2d_color_material_flags(texture_id, alpha_mode_kind)
  let words : Array[UInt] = [
    f32_bits(color_r),
    f32_bits(color_g),
    f32_bits(color_b),
    f32_bits(color_a),
    f32_bits(uv_scale_x),
    f32_bits(0.0F),
    f32_bits(0.0F),
    0U,
    f32_bits(0.0F),
    f32_bits(uv_scale_y),
    f32_bits(0.0F),
    0U,
    f32_bits(uv_offset_x),
    f32_bits(uv_offset_y),
    f32_bits(1.0F),
    0U,
    flags,
    f32_bits(alpha_cutoff),
    0U,
    0U,
  ]
  u32le_pack(words)
}

///|
fn mesh2d_color_material_cache_key(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
) -> String {
  texture_id.to_string() +
  "_" +
  f32_bits(color_r).to_string() +
  "_" +
  f32_bits(color_g).to_string() +
  "_" +
  f32_bits(color_b).to_string() +
  "_" +
  f32_bits(color_a).to_string() +
  "_" +
  f32_bits(uv_offset_x).to_string() +
  "_" +
  f32_bits(uv_offset_y).to_string() +
  "_" +
  f32_bits(uv_scale_x).to_string() +
  "_" +
  f32_bits(uv_scale_y).to_string() +
  "_" +
  alpha_mode_kind.to_string() +
  "_" +
  f32_bits(alpha_cutoff).to_string()
}

///|
fn resolve_mesh2d_material_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo raise GpuBackendError {
  if id < 0 {
    return ensure_default_texture(backend)
  }
  match find_texture(backend, id) {
    Some(texture) => texture
    None => ensure_default_texture(backend)
  }
}

///|
fn mesh2d_color_material_bind_group_for_draw(
  backend : GpuBackend,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
) -> @wgpu.BindGroup? raise GpuBackendError {
  guard backend.mesh2d_material_bgl is Some(bgl_material) else { return None }
  let cache_key = mesh2d_color_material_cache_key(
    color_r, color_g, color_b, color_a, texture_id, uv_offset_x, uv_offset_y, uv_scale_x,
    uv_scale_y, alpha_mode_kind, alpha_cutoff,
  )
  for entry in backend.mesh2d_material_bg_cache {
    if entry.key == cache_key {
      entry.uniform_buf |> ignore
      return Some(entry.bind_group)
    }
  }
  let texture = resolve_mesh2d_material_texture(backend, texture_id)
  let uniform_buf = backend.device.create_buffer_init(
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    mesh2d_color_material_uniform_bytes(
      color_r, color_g, color_b, color_a, texture_id, uv_offset_x, uv_offset_y, uv_scale_x,
      uv_scale_y, alpha_mode_kind, alpha_cutoff,
    ),
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let ok = builder.add_buffer(
      0U,
      uniform_buf,
      size=MESH2D_BEVY_COLOR_MATERIAL_UNIFORM_BUFFER_SIZE,
    ) &&
    builder.add_texture_view(1U, texture.view) &&
    builder.add_sampler(2U, texture.sampler)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    bgl_material,
    label="mgstudio_mesh2d_color_material_bg",
  )
  backend.mesh2d_material_bg_cache.push(Mesh2dMaterialBindGroupCacheEntry::{
    key: cache_key,
    bind_group,
    uniform_buf,
  })
  Some(bind_group)
}

///|
fn mesh2d_pipeline_key_for_format(
  format : @wgpu.TextureFormat,
  primitive_topology : UInt,
  blend_alpha : Bool,
  tonemap_in_shader : Bool,
  deband_dither : Bool,
  may_discard : Bool,
) -> Mesh2dPipelineKey {
  let hdr = format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  Mesh2dPipelineKey::{
    color_format: format,
    primitive_topology,
    blend_alpha,
    hdr,
    tonemap_in_shader,
    deband_dither,
    may_discard,
  }
}

///|
fn mesh2d_pipeline_blend_alpha(alpha_mode_kind : Int) -> Bool {
  alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_BLEND
}

///|
fn mesh2d_pipeline_may_discard(alpha_mode_kind : Int) -> Bool {
  alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_MASK
}

///|
fn mesh2d_get_or_create_pipeline(
  backend : GpuBackend,
  key : Mesh2dPipelineKey,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let cache_key = mesh2d_pipeline_cache_key(key)
  for entry in backend.mesh2d_pipeline_cache {
    if entry.key == cache_key {
      return Some(entry.pipeline)
    }
  }
  let pipeline_label = if key.blend_alpha {
    "mgstudio_mesh2d_transparent_pipeline"
  } else {
    "mgstudio_mesh2d_opaque_pipeline"
  }
  let pipeline = create_mesh2d_pipeline(backend, key, pipeline_label)
  backend.mesh2d_pipeline_cache.push(Mesh2dPipelineCacheEntry::{
    key: cache_key,
    pipeline,
  })
  if key.color_format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    backend.mesh_pipeline = Some(pipeline)
  } else {
    backend.mesh_pipeline_surface = Some(pipeline)
    backend.mesh_pipeline_surface_format = Some(key.color_format)
  }
  Some(pipeline)
}

///|
fn mesh_pipeline_for_draw(
  backend : GpuBackend,
  mesh : GpuMeshInfo,
  alpha_mode_kind : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  mesh2d_get_or_create_pipeline(
    backend,
    mesh2d_pipeline_key_for_format(
      format,
      mesh.primitive_topology,
      mesh2d_pipeline_blend_alpha(alpha_mode_kind),
      false,
      false,
      mesh2d_pipeline_may_discard(alpha_mode_kind),
    ),
  )
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
  let vertices_xyuvrgba : Array[Float] = [
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
  let vertices = mesh2d_interleaved_xyzuv_from_xyuvrgba(vertices_xyuvrgba)
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
    vertex_stride_bytes: MESH2D_BEVY_VERTEX_STRIDE_BYTES,
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
  let verts_xyuvrgba = mesh_interleaved_xyuvrgba_from_xy(verts_xy)
  let verts = mesh2d_interleaved_xyzuv_from_xyuvrgba(verts_xyuvrgba)
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(usage=vb_usage, f32le_pack(verts))
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = self.device.create_buffer_init(usage=ib_usage, u16le_pack(inds))
  let info = GpuMeshInfo::{
    id,
    index_count: inds.length().reinterpret_as_uint(),
    vertex_count: (verts.length() / 9).reinterpret_as_uint(),
    primitive_topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    vertex_stride_bytes: MESH2D_BEVY_VERTEX_STRIDE_BYTES,
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
fn mesh2d_interleaved_xyzuv_from_xyuvrgba(
  vertices_xyuvrgba : Array[Float],
) -> Array[Float] {
  let vcount = vertices_xyuvrgba.length() / 8
  let out : Array[Float] = []
  for i in 0..<vcount {
    let base = i * 8
    out.push(vertices_xyuvrgba[base])
    out.push(vertices_xyuvrgba[base + 1])
    out.push(0.0F)
    out.push(vertices_xyuvrgba[base + 2])
    out.push(vertices_xyuvrgba[base + 3])
    out.push(vertices_xyuvrgba[base + 4])
    out.push(vertices_xyuvrgba[base + 5])
    out.push(vertices_xyuvrgba[base + 6])
    out.push(vertices_xyuvrgba[base + 7])
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
  let mesh2d_vertices = mesh2d_interleaved_xyzuv_from_xyuvrgba(trimmed_vertices)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(mesh2d_vertices),
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
    vertex_stride_bytes: MESH2D_BEVY_VERTEX_STRIDE_BYTES,
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
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
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
  if mesh.vertex_stride_bytes != MESH2D_BEVY_VERTEX_STRIDE_BYTES {
    debug_mesh2d_drop_bad_stride_ref.val = debug_mesh2d_drop_bad_stride_ref.val +
      1
    return
  }
  ensure_mesh2d_resources(self)
  guard mesh_pipeline_for_draw(self, mesh, alpha_mode_kind) is Some(pipeline) else {
    debug_mesh2d_drop_no_pipeline_ref.val = debug_mesh2d_drop_no_pipeline_ref.val +
      1
    return
  }
  let uniform_write_offset = self.mesh2d_instance_used
  let next_instance_used = uniform_write_offset +
    MESH2D_BEVY_UNIFORM_DYNAMIC_STRIDE_BYTES.to_int()
  if next_instance_used < 0 {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  guard ensure_mesh2d_instance_uniform_binding(
      self,
      next_instance_used.to_uint64(),
    )
    is Some((instance_uniform_buf, instance_uniform_bg)) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  self.mesh2d_instance_used = next_instance_used
  let uniform_dynamic_offset = uniform_write_offset.reinterpret_as_uint()
  guard self.mesh2d_view_buf is Some(view_buf) &&
    self.mesh2d_globals_buf is Some(globals_buf) &&
    self.mesh2d_view_bg is Some(view_bg) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  guard mesh2d_color_material_bind_group_for_draw(
      self, color_r, color_g, color_b, color_a, texture_id, uv_offset_x, uv_offset_y,
      uv_scale_x, uv_scale_y, alpha_mode_kind, alpha_cutoff,
    )
    is Some(material_bg) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  self.queue.write_buffer(view_buf, 0UL, mesh2d_view_uniform_bytes(ps))
  self.queue.write_buffer(globals_buf, 0UL, mesh2d_globals_uniform_bytes())
  self.queue.write_buffer(
    instance_uniform_buf,
    uniform_write_offset.to_uint64(),
    mesh2d_instance_uniform_bytes(x, y, rotation, scale_x, scale_y, 0U, 0U),
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [0U])
  pass.set_bind_group(1U, instance_uniform_bg, [uniform_dynamic_offset])
  pass.set_bind_group(2U, material_bg, [])
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
