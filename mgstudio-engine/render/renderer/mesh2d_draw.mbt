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
const MESH2D_VERTEX_STRIDE_BYTES : UInt64 = 36UL

///|
const MESH2D_DEFAULT_VERTEX_SHADER_PATH : String = "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"

///|
const MESH2D_COLOR_MATERIAL_SHADER_PATH : String = "shaders/bevy_sprite_render/mesh2d/color_material.wgsl"

///|
const MESH2D_WIREFRAME_SHADER_PATH : String = "shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl"

///|
const MESH2D_ALPHA_MODE_KIND_OPAQUE : Int = 0

///|
const MESH2D_ALPHA_MODE_KIND_MASK : Int = 1

///|
const MESH2D_ALPHA_MODE_KIND_BLEND : Int = 2

///|
const MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE : Int = 128

///|
const MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64 : UInt64 = 128UL

///|
priv struct Mesh2dPipelineKey {
  color_format : @wgpu.TextureFormat
  primitive_topology : UInt
  blend_alpha : Bool
  hdr : Bool
  tonemap_in_shader : Bool
  deband_dither : Bool
  may_discard : Bool
  wireframe : Bool
  material_layout_key : String
  vertex_shader_path : String
  fragment_shader_path : String
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
  let wireframe_bits = if key.wireframe { "1" } else { "0" }
  "\{format_bits}_\{topology_bits}_\{blend_bits}\{hdr_bits}\{tonemap_bits}\{deband_bits}\{discard_bits}\{wireframe_bits}_\{key.material_layout_key}_\{key.vertex_shader_path}_\{key.fragment_shader_path}"
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
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES * 1024UL,
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
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
    size=MESH2D_UNIFORM_STRIDE_BYTES * MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64,
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
fn mesh2d_vertex_shader_path_or_default(path : String?) -> String {
  match path {
    Some(value) => value
    None => MESH2D_DEFAULT_VERTEX_SHADER_PATH
  }
}

///|
fn mesh2d_fragment_shader_path_or_default(path : String?) -> String {
  match path {
    Some(value) => value
    None => MESH2D_COLOR_MATERIAL_SHADER_PATH
  }
}

///|
fn host_material2d_binding_layout_kind_key(
  value : HostMaterial2dBindingValue,
) -> Int {
  match value {
    Uniform(_) => 1
    Texture(_) => 2
    Sampler(_) => 3
  }
}

///|
fn host_material2d_layout_signature(
  bind_group : HostMaterial2dBindGroup,
) -> Array[(UInt, Int)] {
  let signature : Array[(UInt, Int)] = []
  for binding in bind_group.bindings {
    signature.push(
      (binding.binding, host_material2d_binding_layout_kind_key(binding.value)),
    )
  }
  signature
}

///|
fn host_material2d_layout_signature_eq(
  lhs : Array[(UInt, Int)],
  rhs : Array[(UInt, Int)],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn host_material2d_layout_signature_key(
  signature : Array[(UInt, Int)],
) -> String {
  let mut data = ""
  for i in 0..<signature.length() {
    let binding = signature[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.0.to_string()}:\{binding.1.to_string()}"
  }
  data
}

///|
fn host_material2d_bind_group_layout_key(
  bind_group : HostMaterial2dBindGroup,
) -> String {
  host_material2d_layout_signature_key(
    host_material2d_layout_signature(bind_group),
  )
}

///|
fn mesh2d_cache_hash_mix(hash : UInt64, word : UInt64) -> UInt64 {
  hash * 11400714819323198485UL + word + 0x9E3779B97F4A7C15UL
}

///|
fn host_material2d_layout_signature_hash(
  signature : Array[(UInt, Int)],
) -> UInt64 {
  let mut hash = 1469598103934665603UL
  for entry in signature {
    let (binding, kind) = entry
    hash = mesh2d_cache_hash_mix(hash, binding.to_uint64())
    hash = mesh2d_cache_hash_mix(hash, kind.reinterpret_as_uint().to_uint64())
  }
  hash
}

///|
fn host_material2d_bind_group_hash(
  bind_group : HostMaterial2dBindGroup,
) -> UInt64 {
  let mut hash = 1469598103934665603UL
  for binding in bind_group.bindings {
    hash = mesh2d_cache_hash_mix(hash, binding.binding.to_uint64())
    match binding.value {
      Uniform(bytes) => {
        hash = mesh2d_cache_hash_mix(hash, 1UL)
        hash = mesh2d_cache_hash_mix(hash, bytes.length().to_uint64())
        for byte in bytes {
          hash = mesh2d_cache_hash_mix(hash, byte.to_uint64())
        }
      }
      Texture(texture_id) => {
        hash = mesh2d_cache_hash_mix(hash, 2UL)
        hash = mesh2d_cache_hash_mix(
          hash,
          texture_id.reinterpret_as_uint().to_uint64(),
        )
      }
      Sampler(texture_id) => {
        hash = mesh2d_cache_hash_mix(hash, 3UL)
        hash = mesh2d_cache_hash_mix(
          hash,
          texture_id.reinterpret_as_uint().to_uint64(),
        )
      }
    }
  }
  hash
}

///|
fn bytes_eq(lhs : Bytes, rhs : Bytes) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn host_material2d_binding_value_eq(
  lhs : HostMaterial2dBindingValue,
  rhs : HostMaterial2dBindingValue,
) -> Bool {
  match (lhs, rhs) {
    (Uniform(lhs), Uniform(rhs)) => bytes_eq(lhs, rhs)
    (Texture(lhs), Texture(rhs)) => lhs == rhs
    (Sampler(lhs), Sampler(rhs)) => lhs == rhs
    _ => false
  }
}

///|
fn host_material2d_bind_group_key_eq(
  cached : Array[HostMaterial2dBinding],
  bind_group : HostMaterial2dBindGroup,
) -> Bool {
  if cached.length() != bind_group.bindings.length() {
    return false
  }
  for i in 0..<cached.length() {
    let lhs = cached[i]
    let rhs = bind_group.bindings[i]
    if lhs.binding != rhs.binding ||
      !host_material2d_binding_value_eq(lhs.value, rhs.value) {
      return false
    }
  }
  true
}

///|
fn host_material2d_bind_group_cache_key(
  bind_group : HostMaterial2dBindGroup,
) -> Array[HostMaterial2dBinding] {
  let cloned : Array[HostMaterial2dBinding] = []
  for binding in bind_group.bindings {
    let cloned_value = match binding.value {
      Uniform(bytes) => Uniform(bytes)
      Texture(texture_id) => Texture(texture_id)
      Sampler(texture_id) => Sampler(texture_id)
    }
    cloned.push(HostMaterial2dBinding::{
      binding: binding.binding,
      value: cloned_value,
    })
  }
  cloned
}

///|
fn host_material2d_default_layout_signature() -> Array[(UInt, Int)] {
  [(0U, 1), (1U, 2), (2U, 3)]
}

///|
fn load_wgsl_with_defines_required_mesh2d_material(
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  define_keys : Array[String],
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for key in define_keys {
    defines.set(key, true)
  }
  let value_defines = default_wgsl_value_defines()
  value_defines.set("MATERIAL_BIND_GROUP", 2)
  value_defines.set(
    "PER_OBJECT_BUFFER_BATCH_SIZE",
    MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE,
  )
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  let mesh_source = registered_wgsl_source_required(
    mesh2d_vertex_shader_path_or_default(vertex_shader_path),
  )
  let material_source = registered_wgsl_source_required(
    mesh2d_fragment_shader_path_or_default(fragment_shader_path),
  )
  let combined_source = "\{mesh2d_strip_fragment_entry(mesh_source)}\n\{material_source}"
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
      size=MESH2D_VIEW_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH2D_GLOBALS_BUFFER_SIZE,
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
        size=MESH2D_VIEW_BUFFER_SIZE,
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
    mesh2d_reset_pending_batch(backend)
    backend.mesh2d_pipeline_cache.clear()
    backend.mesh2d_pipeline_cache_index.clear()
    backend.mesh2d_material_layout_cache.clear()
    backend.mesh2d_material_layout_cache_index.clear()
    backend.mesh2d_material_bg_cache.clear()
    backend.mesh2d_material_bg_cache_index.clear()
    if ensure_mesh2d_instance_uniform_binding(
        backend,
        MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
      )
      is None {
      fatal("wgpu: failed to initialize mesh2d uniform bind group")
    }
  }
}

///|
fn mesh2d_material_layout_from_cache(
  backend : GpuBackend,
  layout_key : Array[(UInt, Int)],
) -> (@wgpu.BindGroupLayout, @wgpu.PipelineLayout)? {
  if host_material2d_layout_signature_eq(
      layout_key,
      host_material2d_default_layout_signature(),
    ) {
    guard backend.mesh2d_material_bgl is Some(material_bgl) else { return None }
    guard backend.mesh_pipeline_layout is Some(pipeline_layout) else {
      return None
    }
    return Some((material_bgl, pipeline_layout))
  }
  let signature_hash = host_material2d_layout_signature_hash(layout_key)
  match backend.mesh2d_material_layout_cache_index.get(signature_hash) {
    Some(indices) =>
      for index in indices {
        if index < 0 || index >= backend.mesh2d_material_layout_cache.length() {
          continue
        }
        let entry = backend.mesh2d_material_layout_cache[index]
        if host_material2d_layout_signature_eq(entry.key, layout_key) {
          return Some((entry.bind_group_layout, entry.pipeline_layout))
        }
      }
    None => ()
  }
  None
}

///|
fn mesh2d_material_layout_cache_insert_index(
  backend : GpuBackend,
  layout_signature : Array[(UInt, Int)],
  cache_index : Int,
) -> Unit {
  let signature_hash = host_material2d_layout_signature_hash(layout_signature)
  match backend.mesh2d_material_layout_cache_index.get(signature_hash) {
    Some(indices) => {
      indices.push(cache_index)
      backend.mesh2d_material_layout_cache_index.set(signature_hash, indices)
    }
    None =>
      backend.mesh2d_material_layout_cache_index.set(signature_hash, [
        cache_index,
      ])
  }
}

///|
fn mesh2d_material_layout_for_bind_group(
  backend : GpuBackend,
  bind_group : HostMaterial2dBindGroup,
) -> (@wgpu.BindGroupLayout, @wgpu.PipelineLayout)? {
  let layout_signature = host_material2d_layout_signature(bind_group)
  let layout_key_string = host_material2d_layout_signature_key(layout_signature)
  if mesh2d_material_layout_from_cache(backend, layout_signature)
    is Some(layout_info) {
    return Some(layout_info)
  }
  guard backend.mesh2d_view_bgl is Some(view_bgl) else { return None }
  guard backend.mesh2d_mesh_bgl is Some(mesh_bgl) else { return None }
  let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(
    max_entries=bind_group.bindings.length().to_uint64(),
  )
  let mut ok = true
  for binding in bind_group.bindings {
    let binding_index = binding.binding
    match binding.value {
      Uniform(bytes) =>
        ok = ok &&
          builder.add_buffer(
            binding_index,
            fragment_stage,
            @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
            min_binding_size=bytes.length().to_uint64(),
          )
      Texture(_) =>
        ok = ok &&
          builder.add_texture(
            binding_index,
            fragment_stage,
            @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
            @wgpu.TEXTURE_VIEW_DIMENSION_2D,
          )
      Sampler(_) =>
        ok = ok &&
          builder.add_sampler(
            binding_index,
            fragment_stage,
            @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
          )
    }
  }
  if !ok {
    builder.free()
    return None
  }
  let material_bgl = if bind_group.bindings.length() == 0 {
    builder.free()
    backend.device.create_bind_group_layout_empty()
  } else {
    builder.finish(
      backend.device,
      label="mgstudio_mesh2d_material_bind_group_layout_\{layout_key_string}",
    )
  }
  let pipeline_layout = create_pipeline_layout_3(
    backend.device,
    view_bgl,
    mesh_bgl,
    material_bgl,
  )
  pipeline_layout.set_label(
    "mgstudio_mesh2d_pipeline_layout_\{layout_key_string}",
  )
  backend.mesh2d_material_layout_cache.push(Mesh2dMaterialLayoutCacheEntry::{
    key: layout_signature,
    bind_group_layout: material_bgl,
    pipeline_layout,
  })
  mesh2d_material_layout_cache_insert_index(
    backend,
    layout_signature,
    backend.mesh2d_material_layout_cache.length() - 1,
  )
  Some((material_bgl, pipeline_layout))
}

///|
fn create_mesh2d_pipeline(
  backend : GpuBackend,
  key : Mesh2dPipelineKey,
  material_pipeline_layout : @wgpu.PipelineLayout,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let wgsl = load_wgsl_with_defines_required_mesh2d_material(
    Some(key.vertex_shader_path),
    Some(key.fragment_shader_path),
    mesh2d_pipeline_define_keys(key),
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      sm,
      layout=material_pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(key.color_format)
    builder.set_topology_u32(key.primitive_topology)
    if key.wireframe {
      builder.set_polygon_mode_u32(@wgpu.POLYGON_MODE_LINE)
    }
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
      MESH2D_VERTEX_STRIDE_BYTES,
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
  let target_float_count = (MESH2D_VIEW_BUFFER_SIZE / 4UL).to_int()
  for _ in floats.length()..<target_float_count {
    floats.push(0.0F)
  }
  f32le_pack(floats)
}

///|
fn mesh2d_globals_uniform_bytes() -> Bytes {
  Bytes::makei(MESH2D_GLOBALS_BUFFER_SIZE.to_int(), _ => (0).to_byte())
}

///|
fn mesh2d_sync_view_uniforms_for_current_pass(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  guard backend.pass_state is Some(pass_state) else { return }
  ensure_mesh2d_resources(backend)
  guard backend.mesh2d_view_buf is Some(view_buf) &&
    backend.mesh2d_globals_buf is Some(globals_buf) else {
    return
  }
  backend.queue.write_buffer(
    view_buf,
    0UL,
    mesh2d_view_uniform_bytes(pass_state),
  )
  backend.queue.write_buffer(globals_buf, 0UL, mesh2d_globals_uniform_bytes())
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
fn mesh2d_material_bind_group_cache_insert_index(
  backend : GpuBackend,
  bind_group_hash : UInt64,
  cache_index : Int,
) -> Unit {
  match backend.mesh2d_material_bg_cache_index.get(bind_group_hash) {
    Some(indices) => {
      indices.push(cache_index)
      backend.mesh2d_material_bg_cache_index.set(bind_group_hash, indices)
    }
    None =>
      backend.mesh2d_material_bg_cache_index.set(bind_group_hash, [cache_index])
  }
}

///|
fn mesh2d_material_bind_group_for_draw(
  backend : GpuBackend,
  bind_group : HostMaterial2dBindGroup,
) -> (@wgpu.BindGroupLayout, @wgpu.BindGroup)? raise GpuBackendError {
  guard mesh2d_material_layout_for_bind_group(backend, bind_group)
    is Some((material_bgl, _)) else {
    return None
  }
  let cache_key = host_material2d_bind_group_cache_key(bind_group)
  let bind_group_hash = host_material2d_bind_group_hash(bind_group)
  match backend.mesh2d_material_bg_cache_index.get(bind_group_hash) {
    Some(indices) =>
      for index in indices {
        if index < 0 || index >= backend.mesh2d_material_bg_cache.length() {
          continue
        }
        let entry = backend.mesh2d_material_bg_cache[index]
        if host_material2d_bind_group_key_eq(entry.key, bind_group) {
          for uniform_buffer in entry.uniform_buffers {
            uniform_buffer |> ignore
          }
          return Some((material_bgl, entry.bind_group))
        }
      }
    None => ()
  }
  let uniform_buffers : Array[@wgpu.Buffer] = []
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=bind_group.bindings.length().to_uint64(),
  )
  let mut ok = true
  for binding in bind_group.bindings {
    match binding.value {
      Uniform(bytes) => {
        let uniform_buffer = backend.device.create_buffer_init(
          usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
          bytes,
        )
        uniform_buffers.push(uniform_buffer)
        ok = ok &&
          builder.add_buffer(
            binding.binding,
            uniform_buffer,
            size=bytes.length().to_uint64(),
          )
      }
      Texture(texture_id) => {
        let texture = resolve_mesh2d_material_texture(backend, texture_id)
        ok = ok && builder.add_texture_view(binding.binding, texture.view)
      }
      Sampler(texture_id) => {
        let texture = resolve_mesh2d_material_texture(backend, texture_id)
        ok = ok && builder.add_sampler(binding.binding, texture.sampler)
      }
    }
  }
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    material_bgl,
    label="mgstudio_mesh2d_material_bg",
  )
  backend.mesh2d_material_bg_cache.push(Mesh2dMaterialBindGroupCacheEntry::{
    key: cache_key,
    bind_group,
    uniform_buffers,
  })
  mesh2d_material_bind_group_cache_insert_index(
    backend,
    bind_group_hash,
    backend.mesh2d_material_bg_cache.length() - 1,
  )
  Some((material_bgl, bind_group))
}

///|
fn mesh2d_pipeline_key_for_format(
  format : @wgpu.TextureFormat,
  primitive_topology : UInt,
  blend_alpha : Bool,
  tonemap_in_shader : Bool,
  deband_dither : Bool,
  may_discard : Bool,
  wireframe : Bool,
  material_layout_key : String,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
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
    wireframe,
    material_layout_key,
    vertex_shader_path: mesh2d_vertex_shader_path_or_default(vertex_shader_path),
    fragment_shader_path: mesh2d_fragment_shader_path_or_default(
      fragment_shader_path,
    ),
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
  material_pipeline_layout : @wgpu.PipelineLayout,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let cache_key = mesh2d_pipeline_cache_key(key)
  match backend.mesh2d_pipeline_cache_index.get(cache_key) {
    Some(index) =>
      if index >= 0 && index < backend.mesh2d_pipeline_cache.length() {
        let entry = backend.mesh2d_pipeline_cache[index]
        if entry.key == cache_key {
          return Some(entry.pipeline)
        }
      }
    None => ()
  }
  let pipeline_label = if key.blend_alpha {
    "mgstudio_mesh2d_transparent_pipeline"
  } else if key.wireframe {
    "mgstudio_mesh2d_wireframe_pipeline"
  } else {
    "mgstudio_mesh2d_opaque_pipeline"
  }
  let pipeline = create_mesh2d_pipeline(
    backend, key, material_pipeline_layout, pipeline_label,
  )
  backend.mesh2d_pipeline_cache.push(Mesh2dPipelineCacheEntry::{
    key: cache_key,
    pipeline,
  })
  backend.mesh2d_pipeline_cache_index.set(
    cache_key,
    backend.mesh2d_pipeline_cache.length() - 1,
  )
  let uses_default_shaders = key.vertex_shader_path ==
    MESH2D_DEFAULT_VERTEX_SHADER_PATH &&
    key.fragment_shader_path == MESH2D_COLOR_MATERIAL_SHADER_PATH
  if uses_default_shaders &&
    key.color_format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    backend.mesh_pipeline = Some(pipeline)
  } else if uses_default_shaders {
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
  material_bind_group : HostMaterial2dBindGroup,
  wireframe : Bool,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  let material_layout_key = host_material2d_bind_group_layout_key(
    material_bind_group,
  )
  guard mesh2d_material_layout_for_bind_group(backend, material_bind_group)
    is Some((_, material_pipeline_layout)) else {
    return None
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
      wireframe,
      material_layout_key,
      vertex_shader_path,
      fragment_shader_path,
    ),
    material_pipeline_layout,
  )
}

///|
fn mesh2d_reset_pending_batch(backend : GpuBackend) -> Unit {
  backend.mesh2d_batch_active = false
  backend.mesh2d_batch_mesh_id = -1
  backend.mesh2d_batch_alpha_mode_kind = MESH2D_ALPHA_MODE_KIND_OPAQUE
  backend.mesh2d_batch_wireframe = false
  backend.mesh2d_batch_vertex_shader_path = ""
  backend.mesh2d_batch_fragment_shader_path = ""
  backend.mesh2d_batch_material_hash = 0UL
  backend.mesh2d_batch_material_key.clear()
  backend.mesh2d_batch_uniform_base_offset = 0
  backend.mesh2d_batch_instance_count = 0U
  backend.mesh2d_batch_pipeline = None
  backend.mesh2d_batch_material_bg = None
}

///|
fn mesh2d_pending_batch_matches(
  backend : GpuBackend,
  mesh_id : Int,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  material_bind_group_hash : UInt64,
  wireframe : Bool,
  vertex_shader_path : String,
  fragment_shader_path : String,
) -> Bool {
  backend.mesh2d_batch_active &&
  backend.mesh2d_batch_mesh_id == mesh_id &&
  backend.mesh2d_batch_alpha_mode_kind == alpha_mode_kind &&
  backend.mesh2d_batch_wireframe == wireframe &&
  backend.mesh2d_batch_vertex_shader_path == vertex_shader_path &&
  backend.mesh2d_batch_fragment_shader_path == fragment_shader_path &&
  backend.mesh2d_batch_material_hash == material_bind_group_hash &&
  host_material2d_bind_group_key_eq(
    backend.mesh2d_batch_material_key,
    material_bind_group,
  )
}

///|
fn flush_mesh2d_batches(backend : GpuBackend) -> Unit {
  if !backend.mesh2d_batch_active {
    return
  }
  if backend.mesh2d_batch_instance_count == 0U {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.frame is Some(frame) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard frame.pass is Some(pass) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_batch_pipeline is Some(pipeline) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_batch_material_bg is Some(material_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_view_bg is Some(view_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard backend.mesh2d_instance_bg is Some(instance_uniform_bg) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  guard find_mesh(backend, backend.mesh2d_batch_mesh_id) is Some(mesh) else {
    mesh2d_reset_pending_batch(backend)
    return
  }
  if mesh.vertex_stride_bytes != MESH2D_VERTEX_STRIDE_BYTES {
    mesh2d_reset_pending_batch(backend)
    return
  }
  let uniform_dynamic_offset = backend.mesh2d_batch_uniform_base_offset.reinterpret_as_uint()
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
  pass.draw_indexed(
    mesh.index_count,
    backend.mesh2d_batch_instance_count,
    0U,
    0,
    0U,
  )
  mesh2d_reset_pending_batch(backend)
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
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
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
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
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
    vertex_stride_bytes: MESH2D_VERTEX_STRIDE_BYTES,
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
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit raise GpuBackendError {
  let material_bind_group = host_material2d_color_material_bind_group(
    color_r, color_g, color_b, color_a, alpha_mode_kind, alpha_cutoff, texture_id,
    uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
  )
  self.draw_mesh_material(
    mesh_id,
    x,
    y,
    rotation,
    scale_x,
    scale_y,
    alpha_mode_kind,
    material_bind_group,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
fn GpuBackend::draw_mesh_material_with_options(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  wireframe? : Bool = false,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else {
    debug_mesh2d_drop_no_frame_ref.val = debug_mesh2d_drop_no_frame_ref.val + 1
    return
  }
  guard frame.pass is Some(_) else {
    debug_mesh2d_drop_no_pass_ref.val = debug_mesh2d_drop_no_pass_ref.val + 1
    return
  }
  guard self.pass_state is Some(_) else {
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
  if mesh.vertex_stride_bytes != MESH2D_VERTEX_STRIDE_BYTES {
    debug_mesh2d_drop_bad_stride_ref.val = debug_mesh2d_drop_bad_stride_ref.val +
      1
    return
  }
  ensure_mesh2d_resources(self)
  let resolved_vertex_shader_path = mesh2d_vertex_shader_path_or_default(
    vertex_shader_path,
  )
  let resolved_fragment_shader_path = mesh2d_fragment_shader_path_or_default(
    fragment_shader_path,
  )
  guard mesh_pipeline_for_draw(
      self,
      mesh,
      alpha_mode_kind,
      material_bind_group,
      wireframe,
      Some(resolved_vertex_shader_path),
      Some(resolved_fragment_shader_path),
    )
    is Some(pipeline) else {
    debug_mesh2d_drop_no_pipeline_ref.val = debug_mesh2d_drop_no_pipeline_ref.val +
      1
    return
  }
  guard mesh2d_material_bind_group_for_draw(self, material_bind_group)
    is Some((_, material_bg)) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    return
  }
  let material_bind_group_hash = host_material2d_bind_group_hash(
    material_bind_group,
  )
  if self.mesh2d_batch_active &&
    self.mesh2d_batch_instance_count.reinterpret_as_int() >=
    MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE {
    flush_mesh2d_batches(self)
  }
  if !mesh2d_pending_batch_matches(
      self, mesh_id, alpha_mode_kind, material_bind_group, material_bind_group_hash,
      wireframe, resolved_vertex_shader_path, resolved_fragment_shader_path,
    ) {
    flush_mesh2d_batches(self)
    self.mesh2d_batch_active = true
    self.mesh2d_batch_mesh_id = mesh_id
    self.mesh2d_batch_alpha_mode_kind = alpha_mode_kind
    self.mesh2d_batch_wireframe = wireframe
    self.mesh2d_batch_vertex_shader_path = resolved_vertex_shader_path
    self.mesh2d_batch_fragment_shader_path = resolved_fragment_shader_path
    self.mesh2d_batch_material_hash = material_bind_group_hash
    self.mesh2d_batch_material_key = host_material2d_bind_group_cache_key(
      material_bind_group,
    )
    self.mesh2d_batch_instance_count = 0U
    self.mesh2d_batch_pipeline = Some(pipeline)
    self.mesh2d_batch_material_bg = Some(material_bg)
    self.mesh2d_batch_uniform_base_offset = mesh2d_align_up(
      self.mesh2d_instance_used.to_uint64(),
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
    ).to_int()
  }
  let uniform_write_offset = self.mesh2d_batch_uniform_base_offset +
    self.mesh2d_batch_instance_count.reinterpret_as_int() *
    MESH2D_UNIFORM_STRIDE_BYTES.to_int()
  let next_instance_used = uniform_write_offset +
    MESH2D_UNIFORM_STRIDE_BYTES.to_int()
  let required_binding_end = self.mesh2d_batch_uniform_base_offset.to_uint64() +
    MESH2D_UNIFORM_STRIDE_BYTES * MESH2D_PER_OBJECT_BUFFER_BATCH_SIZE_U64
  if next_instance_used < 0 {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    mesh2d_reset_pending_batch(self)
    return
  }
  let required_capacity = {
    let next_used_u64 = next_instance_used.to_uint64()
    if next_used_u64 > required_binding_end {
      next_used_u64
    } else {
      required_binding_end
    }
  }
  guard ensure_mesh2d_instance_uniform_binding(self, required_capacity)
    is Some((instance_uniform_buf, _)) else {
    debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
      1
    mesh2d_reset_pending_batch(self)
    return
  }
  if next_instance_used > self.mesh2d_instance_used {
    self.mesh2d_instance_used = next_instance_used
  }
  self.queue.write_buffer(
    instance_uniform_buf,
    uniform_write_offset.to_uint64(),
    mesh2d_instance_uniform_bytes(x, y, rotation, scale_x, scale_y, 0U, 0U),
  )
  self.mesh2d_batch_instance_count = self.mesh2d_batch_instance_count + 1U
}

///|
pub fn GpuBackend::draw_mesh_material(
  self : GpuBackend,
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  alpha_mode_kind : Int,
  material_bind_group : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit raise GpuBackendError {
  self.draw_mesh_material_with_options(
    mesh_id,
    x,
    y,
    rotation,
    scale_x,
    scale_y,
    alpha_mode_kind,
    material_bind_group,
    vertex_shader_path~,
    fragment_shader_path~,
    wireframe=false,
  )
}

///|
