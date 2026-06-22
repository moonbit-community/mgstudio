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
fn mesh3d_vertex_shader_path_or_default(shader_path : String?) -> String {
  match shader_path {
    Some(path) =>
      if path == "" {
        MESH3D_FORWARD_VERTEX_SHADER_PATH
      } else {
        path
      }
    None => MESH3D_FORWARD_VERTEX_SHADER_PATH
  }
}

///|
fn mesh3d_fragment_shader_path_or_default(shader_path : String?) -> String {
  match shader_path {
    Some(path) => if path == "" { MESH3D_FORWARD_SHADER_PATH } else { path }
    None => MESH3D_FORWARD_SHADER_PATH
  }
}

///|
fn mesh3d_custom_pipeline_cache_key(
  material_pipeline_id : UInt64,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  msaa_sample_count : Int,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
) -> String {
  let surface_bits = match surface_format {
    Some(format) => format.raw.to_string()
    None => "-1"
  }
  let transparent_bits = if transparent { "1" } else { "0" }
  let forward_decal_bits = if forward_decal { "1" } else { "0" }
  let skinned_bits = if skinned { "1" } else { "0" }
  let tonemap_bits = if tonemap_in_shader { "1" } else { "0" }
  let deband_bits = if deband_dither_enabled { "1" } else { "0" }
  "\{material_pipeline_id.to_string()}|\{surface_bits}|\{msaa_sample_count}|\{topology}|\{transparent_bits}|\{blend_kind}|\{forward_decal_bits}|\{mesh3d_cull_mode_sanitize(cull_mode)}|\{skinned_bits}|\{tonemap_bits}|\{tonemapping_mode}|\{deband_bits}|\{shadow_filter_method}|\{vertex_shader_path}|\{fragment_shader_path}"
}

///|
fn mesh3d_custom_pipeline_cache_get(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  msaa_sample_count : Int,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
) -> @wgpu.RenderPipeline? {
  let cache_key = mesh3d_custom_pipeline_cache_key(
    material_pipeline_id, vertex_shader_path, fragment_shader_path, surface_format,
    msaa_sample_count, topology, transparent, blend_kind, forward_decal, cull_mode,
    skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled, shadow_filter_method,
  )
  match backend.mesh3d_custom_pipeline_cache.get(cache_key) {
    Some(state) =>
      match state {
        RenderPipelineOk(pipeline) => Some(pipeline)
        RenderPipelineErr(message) => {
          ignore(message)
          None
        }
      }
    None => None
  }
}

///|
fn mesh3d_custom_pipeline_cache_failed(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  msaa_sample_count : Int,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
) -> Bool {
  let cache_key = mesh3d_custom_pipeline_cache_key(
    material_pipeline_id, vertex_shader_path, fragment_shader_path, surface_format,
    msaa_sample_count, topology, transparent, blend_kind, forward_decal, cull_mode,
    skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled, shadow_filter_method,
  )
  match backend.mesh3d_custom_pipeline_cache.get(cache_key) {
    Some(state) =>
      match state {
        RenderPipelineOk(_) => false
        RenderPipelineErr(message) => {
          ignore(message)
          true
        }
      }
    None => false
  }
}

///|
fn mesh3d_custom_pipeline_cache_set_failed(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  msaa_sample_count : Int,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  message : String,
) -> Unit {
  if mesh3d_custom_pipeline_cache_get(
      backend, material_pipeline_id, vertex_shader_path, fragment_shader_path, surface_format,
      msaa_sample_count, topology, transparent, blend_kind, forward_decal, cull_mode,
      skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled, shadow_filter_method,
    )
    is Some(_) {
    return
  }
  if mesh3d_custom_pipeline_cache_failed(
      backend, material_pipeline_id, vertex_shader_path, fragment_shader_path, surface_format,
      msaa_sample_count, topology, transparent, blend_kind, forward_decal, cull_mode,
      skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled, shadow_filter_method,
    ) {
    return
  }
  let cache_key = mesh3d_custom_pipeline_cache_key(
    material_pipeline_id, vertex_shader_path, fragment_shader_path, surface_format,
    msaa_sample_count, topology, transparent, blend_kind, forward_decal, cull_mode,
    skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled, shadow_filter_method,
  )
  backend.mesh3d_custom_pipeline_cache[cache_key] = RenderPipelineErr(message)
}

///|
fn load_wgsl_required_mesh3d_custom_pipeline(
  assets_base : String,
  descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  shader_path : String,
) -> String raise GpuBackendError {
  load_wgsl_required_mesh3d_forward_pipeline(
    assets_base, descriptor, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
    shadow_filter_method, shader_path,
  )
}

///|
fn mesh3d_forward_shader_defines(
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("VERTEX_POSITIONS", true)
  defines.set("VERTEX_NORMALS", true)
  defines.set("VERTEX_UVS", true)
  defines.set("VERTEX_UVS_A", true)
  defines.set("VERTEX_COLORS", true)
  defines.set("VERTEX_OUTPUT_INSTANCE_INDEX", true)
  defines.set("MAY_DISCARD", true)
  if skinned {
    defines.set("SKINNED", true)
  }
  if lightmapped {
    defines.set("LIGHTMAP", true)
  }
  match shadow_filter_method {
    0 => defines.set("SHADOW_FILTER_METHOD_HARDWARE_2X2", true)
    2 => defines.set("SHADOW_FILTER_METHOD_TEMPORAL", true)
    _ => defines.set("SHADOW_FILTER_METHOD_GAUSSIAN", true)
  }
  if tonemap_in_shader {
    defines.set("TONEMAP_IN_SHADER", true)
    defines.set(tonemapping_method_define(tonemapping_mode), true)
    if deband_dither_enabled {
      defines.set("DEBAND_DITHER", true)
    }
  }
  defines
}

///|
fn mesh3d_forward_shader_defines_from_descriptor(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> @hashmap.HashMap[String, Bool] {
  guard descriptor is Some(desc) else {
    return mesh3d_forward_shader_defines(
      skinned,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    )
  }
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let apply_defs = fn(shader_defs : Array[@render_resource.ShaderDefVal]) {
    for shader_def in shader_defs {
      match shader_def {
        Flag(name) => defines.set(name, true)
        Bool(name, value) => defines.set(name, value)
        Int(_, _) | UInt(_, _) | String(_, _) => ()
      }
    }
  }
  apply_defs(desc.vertex.shader_defs)
  match desc.fragment {
    Some(fragment) => apply_defs(fragment.shader_defs)
    None => ()
  }
  if skinned {
    defines.set("SKINNED", true)
  }
  if lightmapped {
    defines.set("LIGHTMAP", true)
  }
  match shadow_filter_method {
    0 => defines.set("SHADOW_FILTER_METHOD_HARDWARE_2X2", true)
    2 => defines.set("SHADOW_FILTER_METHOD_TEMPORAL", true)
    _ => defines.set("SHADOW_FILTER_METHOD_GAUSSIAN", true)
  }
  if tonemap_in_shader {
    defines.set("TONEMAP_IN_SHADER", true)
    defines.set(tonemapping_method_define(tonemapping_mode), true)
    if deband_dither_enabled {
      defines.set("DEBAND_DITHER", true)
    }
  }
  defines
}

///|
fn mesh3d_forward_value_defines(
  descriptor? : @render_resource.RenderPipelineDescriptor? = None,
) -> @hashmap.HashMap[String, @wgsl_common.ShaderDefValue] {
  let value_defines = default_wgsl_value_defines()
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  value_defines.set("TONEMAPPING_LUT_TEXTURE_BINDING_INDEX", wgsl_def_int(18))
  value_defines.set("TONEMAPPING_LUT_SAMPLER_BINDING_INDEX", wgsl_def_int(19))
  let apply_defs = fn(shader_defs : Array[@render_resource.ShaderDefVal]) {
    for shader_def in shader_defs {
      match shader_def {
        Int(name, value) =>
          value_defines.set(name, @wgsl_common.ShaderDefValue::Int(value))
        UInt(name, value) =>
          value_defines.set(name, @wgsl_common.ShaderDefValue::UInt(value))
        String(name, value) =>
          value_defines.set(name, @wgsl_common.ShaderDefValue::Raw(value))
        Bool(_, _) | Flag(_) => ()
      }
    }
  }
  match descriptor {
    Some(desc) => {
      apply_defs(desc.vertex.shader_defs)
      match desc.fragment {
        Some(fragment) => apply_defs(fragment.shader_defs)
        None => ()
      }
    }
    None => ()
  }
  value_defines
}

///|
fn mesh3d_shadow_shader_defines(
  skinned : Bool,
  material_path : Bool,
  directional_light : Bool,
  emulate_unclipped_depth : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("PREPASS_PIPELINE", true)
  defines.set("DEPTH_PREPASS", true)
  if directional_light {
    defines.set("VIEW_PROJECTION_ORTHOGRAPHIC", true)
  } else {
    defines.set("VIEW_PROJECTION_PERSPECTIVE", true)
  }
  defines.set("VERTEX_POSITIONS", true)
  defines.set("VERTEX_UVS", true)
  defines.set("VERTEX_UVS_A", true)
  defines.set("VERTEX_COLORS", true)
  defines.set("VERTEX_OUTPUT_INSTANCE_INDEX", true)
  if skinned {
    defines.set("SKINNED", true)
  }
  if emulate_unclipped_depth {
    defines.set("UNCLIPPED_DEPTH_ORTHO_EMULATION", true)
    defines.set("PREPASS_FRAGMENT", true)
  }
  if material_path {
    defines.set("MAY_DISCARD", true)
  }
  defines
}

///|
fn mesh3d_shadow_shader_defines_from_descriptor(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  material_path : Bool,
  directional_light : Bool,
  emulate_unclipped_depth : Bool,
) -> @hashmap.HashMap[String, Bool] {
  guard descriptor is Some(desc) else {
    return mesh3d_shadow_shader_defines(
      skinned, material_path, directional_light, emulate_unclipped_depth,
    )
  }
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let apply_defs = fn(shader_defs : Array[@render_resource.ShaderDefVal]) {
    for shader_def in shader_defs {
      match shader_def {
        Flag(name) => defines.set(name, true)
        Bool(name, value) => defines.set(name, value)
        Int(_, _) | UInt(_, _) | String(_, _) => ()
      }
    }
  }
  apply_defs(desc.vertex.shader_defs)
  match desc.fragment {
    Some(fragment) => apply_defs(fragment.shader_defs)
    None => ()
  }
  if directional_light {
    defines.set("VIEW_PROJECTION_ORTHOGRAPHIC", true)
  } else {
    defines.set("VIEW_PROJECTION_PERSPECTIVE", true)
  }
  if skinned {
    defines.set("SKINNED", true)
  }
  if emulate_unclipped_depth {
    defines.set("UNCLIPPED_DEPTH_ORTHO_EMULATION", true)
    defines.set("PREPASS_FRAGMENT", true)
  }
  if material_path {
    defines.set("MAY_DISCARD", true)
  }
  defines
}

///|
fn mesh3d_shadow_depth_supports_native_unclipped_depth(
  backend : GpuBackend,
  directional_light : Bool,
) -> Bool {
  directional_light &&
  backend.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_DEPTH_CLIP_CONTROL,
  )
}

///|
fn mesh3d_shadow_depth_should_emulate_unclipped_depth(
  backend : GpuBackend,
  directional_light : Bool,
) -> Bool {
  directional_light &&
  !mesh3d_shadow_depth_supports_native_unclipped_depth(
    backend, directional_light,
  )
}

///|
fn load_wgsl_required_mesh3d_shadow_pipeline(
  assets_base : String,
  descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  material_path : Bool,
  directional_light : Bool,
  emulate_unclipped_depth : Bool,
  shader_path : String,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    shader_path,
    mesh3d_shadow_shader_defines_from_descriptor(
      descriptor, skinned, material_path, directional_light, emulate_unclipped_depth,
    ),
    mesh3d_forward_value_defines(descriptor~),
  )
}

///|
fn load_wgsl_required_mesh3d_forward_pipeline(
  assets_base : String,
  descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  shader_path : String,
  lightmapped? : Bool = false,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    shader_path,
    mesh3d_forward_shader_defines_from_descriptor(
      descriptor,
      skinned,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    ),
    mesh3d_forward_value_defines(descriptor~),
  )
}

///|
priv struct Mesh3dForwardShaderModules {
  vertex : @wgpu.ShaderModule
  fragment : @wgpu.ShaderModule
}

///|
fn Mesh3dForwardShaderModules::release(
  self : Mesh3dForwardShaderModules,
) -> Unit {
  self.vertex.release()
  self.fragment.release()
}

///|
fn mesh3d_create_forward_shader_module(
  backend : GpuBackend,
  wgsl : String,
  failure_label : String,
) -> @wgpu.ShaderModule raise GpuBackendError {
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let shader_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if shader_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(shader_result, failure_label)
    shader.release()
    fatal(message)
  }
  shader
}

///|
fn mesh3d_create_forward_shader_modules(
  backend : GpuBackend,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  label_prefix : String,
  lightmapped? : Bool = false,
) -> Mesh3dForwardShaderModules raise GpuBackendError {
  let vertex_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    MESH3D_FORWARD_VERTEX_SHADER_PATH,
    lightmapped~,
  )
  let fragment_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    MESH3D_FORWARD_SHADER_PATH,
    lightmapped~,
  )
  let vertex = mesh3d_create_forward_shader_module(
    backend,
    vertex_wgsl,
    "wgpu: failed to create \{label_prefix} vertex shader module",
  )
  let fragment = mesh3d_create_forward_shader_module(
    backend,
    fragment_wgsl,
    "wgpu: failed to create \{label_prefix} fragment shader module",
  ) catch {
    err => {
      vertex.release()
      raise err
    }
  }
  Mesh3dForwardShaderModules::{ vertex, fragment }
}

///|
fn mesh3d_error_scope_message(
  result : @wgpu.ErrorScopeResult,
  fallback : String,
) -> String {
  let message = result.message.trim().to_owned()
  if message == "" {
    fallback
  } else {
    "\{fallback}: \{message}"
  }
}

///|
fn mesh3d_blend_kind_from_material_flags(
  material_flags : UInt,
  transparent : Bool,
) -> Int {
  if !transparent {
    return MESH3D_PIPELINE_BLEND_OPAQUE
  }
  let alpha_mode = material_flags & MESH3D_SHADOW_ALPHA_MODE_RESERVED_BITS
  if alpha_mode == MESH3D_SHADOW_ALPHA_MODE_PREMULTIPLIED ||
    alpha_mode == MESH3D_SHADOW_ALPHA_MODE_ADD {
    MESH3D_PIPELINE_BLEND_PREMULTIPLIED_ALPHA
  } else if alpha_mode == MESH3D_SHADOW_ALPHA_MODE_MULTIPLY {
    MESH3D_PIPELINE_BLEND_MULTIPLY
  } else {
    MESH3D_PIPELINE_BLEND_ALPHA
  }
}

///|
fn mesh3d_descriptor_vertex_shader_path(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> String? {
  match descriptor {
    Some(desc) => desc.vertex.shader
    None => None
  }
}

///|
fn mesh3d_descriptor_fragment_shader_path(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> String? {
  match descriptor {
    Some(desc) =>
      match desc.fragment {
        Some(fragment) => fragment.shader
        None => None
      }
    None => None
  }
}

///|
fn mesh3d_descriptor_vertex_buffer_layout(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> @mesh.VertexBufferLayout? {
  match descriptor {
    Some(desc) if desc.vertex.buffers.length() > 0 =>
      Some(desc.vertex.buffers[0])
    _ => None
  }
}

///|
fn mesh3d_descriptor_vertex_buffer_layouts(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> Array[@mesh.VertexBufferLayout] {
  match descriptor {
    Some(desc) => desc.vertex.buffers
    None => []
  }
}

///|
fn mesh3d_descriptor_depth_write_enabled(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  fallback : Bool,
) -> Bool {
  match descriptor {
    Some(desc) =>
      match desc.depth_stencil {
        Some(depth_stencil) => depth_stencil.depth_write_enabled
        None => fallback
      }
    None => fallback
  }
}

///|
fn mesh3d_descriptor_depth_compare(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> UInt {
  match descriptor {
    Some(desc) =>
      match desc.depth_stencil {
        Some(depth_stencil) => depth_stencil.depth_compare
        None => @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
      }
    None => @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
  }
}

///|
fn mesh3d_descriptor_depth_format(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> UInt {
  match descriptor {
    Some(desc) =>
      match desc.depth_stencil {
        Some(depth_stencil) => depth_stencil.format
        None => @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT
      }
    None => @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT
  }
}

///|
fn mesh3d_descriptor_shader_bool_defines(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  fallback : @hashmap.HashMap[String, Bool],
) -> @hashmap.HashMap[String, Bool] {
  guard descriptor is Some(desc) else { return fallback }
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let apply_defs = fn(shader_defs : Array[@render_resource.ShaderDefVal]) {
    for shader_def in shader_defs {
      match shader_def {
        Flag(name) => defines.set(name, true)
        Bool(name, value) => defines.set(name, value)
        Int(_, _) | UInt(_, _) | String(_, _) => ()
      }
    }
  }
  apply_defs(desc.vertex.shader_defs)
  match desc.fragment {
    Some(fragment) => apply_defs(fragment.shader_defs)
    None => ()
  }
  defines
}

///|
fn mesh3d_descriptor_fragment_targets(
  builder : @wgpu.RenderPipelineDescBuilder,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
) -> Unit raise @wgpu.RenderPipelineDescError {
  let targets = match material_descriptor {
    Some(desc) =>
      match desc.fragment {
        Some(fragment) => fragment.targets
        None => []
      }
    None =>
      [
        None,
        Some(
          @render_resource.ColorTargetState::new(
            @wgpu.TEXTURE_FORMAT_RG16_FLOAT,
            @wgpu.COLOR_WRITE_MASK_ALL,
          ),
        ),
      ]
  }
  if targets.length() == 0 {
    builder.set_color_target_count(0U)
    return
  }
  builder.set_color_target_count(targets.length().reinterpret_as_uint())
  for index in 0..<targets.length() {
    let index_u = index.reinterpret_as_uint()
    match targets[index] {
      Some(target) => {
        builder.set_color_target_format_at(index_u, tf(target.format))
        builder.set_color_target_write_mask_at(index_u, target.write_mask)
      }
      None => builder.set_color_target_unused_at(index_u)
    }
  }
}

///|
fn mesh3d_pipeline_blend_suffix(blend_kind : Int) -> String {
  if blend_kind == MESH3D_PIPELINE_BLEND_PREMULTIPLIED_ALPHA {
    "premultiplied"
  } else if blend_kind == MESH3D_PIPELINE_BLEND_MULTIPLY {
    "multiply"
  } else if blend_kind == MESH3D_PIPELINE_BLEND_ALPHA {
    "alpha"
  } else {
    "opaque"
  }
}

///|
fn mesh3d_create_uniform_buffer(
  backend : GpuBackend,
  size : UInt64,
) -> @wgpu.Buffer {
  backend.device.create_buffer(
    size~,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
}

///|
fn mesh3d_create_storage_buffer(
  backend : GpuBackend,
  size : UInt64,
) -> @wgpu.Buffer {
  backend.device.create_buffer(
    size~,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
  )
}

///|
fn ensure_mesh3d_view_binding_buffers(backend : GpuBackend) -> Unit {
  if backend.mesh3d_view_buf is None {
    backend.mesh3d_view_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_VIEW_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_lights_buf is None {
    backend.mesh3d_lights_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_LIGHTS_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_clustered_lights_buf is None {
    backend.mesh3d_clustered_lights_buf = Some(
      mesh3d_create_storage_buffer(backend, MESH3D_CLUSTERED_LIGHTS_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_clusterable_object_index_lists_buf is None {
    backend.mesh3d_clusterable_object_index_lists_buf = Some(
      mesh3d_create_storage_buffer(
        backend,
        MESH3D_CLUSTERABLE_OBJECT_INDEX_LISTS_BUFFER_SIZE,
      ),
    )
  }
  if backend.mesh3d_cluster_offsets_and_counts_buf is None {
    backend.mesh3d_cluster_offsets_and_counts_buf = Some(
      mesh3d_create_storage_buffer(
        backend,
        MESH3D_CLUSTER_OFFSETS_AND_COUNTS_BUFFER_SIZE,
      ),
    )
  }
  if backend.mesh3d_globals_buf is None {
    backend.mesh3d_globals_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_GLOBALS_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_fog_buf is None {
    backend.mesh3d_fog_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_FOG_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_light_probes_buf is None {
    backend.mesh3d_light_probes_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_LIGHT_PROBES_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_visibility_ranges_buf is None {
    backend.mesh3d_visibility_ranges_buf = Some(
      mesh3d_create_storage_buffer(
        backend,
        MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
      ),
    )
  }
  if backend.mesh3d_ssr_settings_buf is None {
    backend.mesh3d_ssr_settings_buf = Some(
      mesh3d_create_uniform_buffer(backend, MESH3D_SSR_SETTINGS_BUFFER_SIZE),
    )
  }
  if backend.mesh3d_contact_shadows_settings_buf is None {
    backend.mesh3d_contact_shadows_settings_buf = Some(
      mesh3d_create_uniform_buffer(
        backend,
        MESH3D_CONTACT_SHADOWS_SETTINGS_BUFFER_SIZE,
      ),
    )
  }
}

///|
fn mesh3d_custom_pipeline_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  msaa_sample_count : Int,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_vertex_shader_path = mesh3d_vertex_shader_path_or_default(
    Some(vertex_shader_path),
  )
  let resolved_fragment_shader_path = mesh3d_fragment_shader_path_or_default(
    Some(fragment_shader_path),
  )
  if resolved_vertex_shader_path == MESH3D_FORWARD_VERTEX_SHADER_PATH &&
    resolved_fragment_shader_path == MESH3D_FORWARD_SHADER_PATH &&
    !forward_decal {
    return None
  }
  if mesh3d_custom_pipeline_cache_get(
      backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
      surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
      cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  if mesh3d_custom_pipeline_cache_failed(
      backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
      surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
      cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method,
    ) {
    return None
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key=mesh3d_default_mesh_view_layout_key(
      tonemap_in_shader~,
    ),
  )
  let pl = layout_entry.pipeline_layout
  let vertex_shader_source = load_wgsl_required_mesh3d_custom_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    resolved_vertex_shader_path,
  ) catch {
    ShaderNotReady(_) => return None
    Fatal(message) => {
      mesh3d_custom_pipeline_cache_set_failed(
        backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
        surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
        safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
        shadow_filter_method, message,
      )
      debug(
        "[renderer] mesh3d custom pipeline failed while loading vertex shader \{resolved_vertex_shader_path} / fragment shader \{resolved_fragment_shader_path}: \{message}",
      )
      return None
    }
  }
  let fragment_shader_source = load_wgsl_required_mesh3d_custom_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    resolved_fragment_shader_path,
  ) catch {
    ShaderNotReady(_) => return None
    Fatal(message) => {
      mesh3d_custom_pipeline_cache_set_failed(
        backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
        surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
        safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
        shadow_filter_method, message,
      )
      debug(
        "[renderer] mesh3d custom pipeline failed while loading fragment shader \{resolved_fragment_shader_path} / vertex shader \{resolved_vertex_shader_path}: \{message}",
      )
      return None
    }
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let vertex_shader_module = backend.device.create_shader_module_wgsl(
    vertex_shader_source,
  )
  let vertex_shader_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if vertex_shader_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      vertex_shader_result, "wgpu: failed to create mesh3d custom vertex shader module",
    )
    vertex_shader_module.release()
    mesh3d_custom_pipeline_cache_set_failed(
      backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
      surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
      safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method, message,
    )
    debug(
      "[renderer] mesh3d custom pipeline failed while creating vertex shader module \{resolved_vertex_shader_path}: \{message}",
    )
    return None
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let fragment_shader_module = backend.device.create_shader_module_wgsl(
    fragment_shader_source,
  )
  let fragment_shader_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if fragment_shader_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      fragment_shader_result, "wgpu: failed to create mesh3d custom fragment shader module",
    )
    vertex_shader_module.release()
    fragment_shader_module.release()
    mesh3d_custom_pipeline_cache_set_failed(
      backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
      surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
      safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method, message,
    )
    debug(
      "[renderer] mesh3d custom pipeline failed while creating fragment shader module \{resolved_fragment_shader_path}: \{message}",
    )
    return None
  }
  let color_format = match surface_format {
    Some(format) => format.to_u32()
    None => @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
  }
  let descriptor = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    vertex_shader_module,
    color_format,
    fragment_shader=fragment_shader_module,
    with_depth=true,
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
    depth_compare_u32=if forward_decal {
      @wgpu.COMPARE_FUNCTION_ALWAYS
    } else {
      mesh3d_descriptor_depth_compare(material_descriptor)
    },
    vertex_entry=match material_descriptor {
      Some(desc) =>
        match desc.vertex.entry_point {
          Some(entry) => entry
          None => "vertex"
        }
      None => "vertex"
    },
    fragment_entry=match material_descriptor {
      Some(desc) =>
        match desc.fragment {
          Some(fragment) =>
            match fragment.entry_point {
              Some(entry) => entry
              None => "fragment"
            }
          None => "fragment"
        }
      None => "fragment"
    },
    vertex_buffer_layouts=mesh3d_descriptor_vertex_buffer_layouts(
      material_descriptor,
    ),
    sample_count=msaa_sample_count,
  )
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = backend.device.create_render_pipeline_ptr(descriptor)
  let pipeline_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  @wgpu_c.render_pipeline_descriptor_free(descriptor)
  if pipeline_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      pipeline_result, "wgpu: failed to create mesh3d custom pipeline",
    )
    pipeline.release()
    vertex_shader_module.release()
    fragment_shader_module.release()
    mesh3d_custom_pipeline_cache_set_failed(
      backend, material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
      surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
      safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
      shadow_filter_method, message,
    )
    debug(
      "[renderer] mesh3d custom pipeline failed while creating render pipeline \{resolved_vertex_shader_path} / \{resolved_fragment_shader_path}: \{message}",
    )
    return None
  }
  let label_prefix = if surface_format is Some(_) {
    "mgstudio_mesh3d_custom_surface_"
  } else {
    "mgstudio_mesh3d_custom_rgba8_"
  }
  let transparent_suffix = if transparent { "1" } else { "0" }
  let forward_decal_suffix = if forward_decal { "1" } else { "0" }
  pipeline.set_label(
    label_prefix +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    "_transparent_" +
    transparent_suffix +
    "_forward_decal_" +
    forward_decal_suffix +
    "_vertex_" +
    resolved_vertex_shader_path +
    "_fragment_" +
    resolved_fragment_shader_path,
  )
  let cache_key = mesh3d_custom_pipeline_cache_key(
    material_pipeline_id, resolved_vertex_shader_path, resolved_fragment_shader_path,
    surface_format, msaa_sample_count, topology, transparent, blend_kind, forward_decal,
    safe_cull_mode, skinned, tonemap_in_shader, tonemapping_mode, deband_dither_enabled,
    shadow_filter_method,
  )
  backend.mesh3d_custom_pipeline_cache[cache_key] = RenderPipelineOk(pipeline)
  vertex_shader_module.release()
  fragment_shader_module.release()
  Some(pipeline)
}

///|
fn ensure_mesh3d_pipeline_layout_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  if backend.mesh3d_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let mesh_view_layout = mesh3d_default_mesh_view_layout()
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(
      max_entries=mesh_view_layout.main_entries.length().to_uint64(),
    )
    let view_ok = mesh3d_add_mesh_view_layout_entries(
      view_builder,
      mesh_view_layout.main_entries,
    )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_view_bgl",
    )
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let material_uniform_stage = ss(
      @wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT,
    )
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=13UL)
    let material_ok = material_builder.add_buffer(
        0U,
        material_uniform_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_STANDARD_MATERIAL_UNIFORM_SIZE,
      ) &&
      material_builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        2U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        4U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        5U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        6U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        7U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        8U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        9U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        10U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        11U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        12U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh3d material bind group layout")
    }
    let material_bgl = material_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_material_bgl",
    )
    let binding_arrays_builder = @wgpu.BindGroupLayoutBuilder::new(
      max_entries=mesh_view_layout.binding_array_entries.length().to_uint64(),
    )
    let binding_arrays_ok = mesh3d_add_mesh_view_layout_entries(
      binding_arrays_builder,
      mesh_view_layout.binding_array_entries,
    )
    if !binding_arrays_ok {
      binding_arrays_builder.free()
      fatal("wgpu: failed to build mesh3d binding-array bind group layout")
    }
    let binding_arrays_bgl = binding_arrays_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_binding_arrays_bgl",
    )
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
    let mesh_ok = mesh_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      ) &&
      mesh_builder.add_buffer(
        1U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=64UL,
      )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d draw bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_draw_bgl",
    )
    let pl = create_pipeline_layout_4(
      backend.device,
      view_bgl,
      binding_arrays_bgl,
      mesh_bgl,
      material_bgl,
    )
    backend.mesh3d_bgl_view = Some(view_bgl)
    backend.mesh3d_bgl_binding_arrays = Some(binding_arrays_bgl)
    backend.mesh3d_bgl_draw = Some(mesh_bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_bgl_skin = None
    backend.mesh3d_pipeline_layout = Some(pl)
    ensure_mesh3d_view_binding_buffers(backend)
    backend.mesh3d_binding_arrays_bg = None
    mesh3d_material_cache_clear(backend)
    mesh3d_custom_pipeline_cache_clear(backend)
    mesh3d_pipeline_cache_clear(backend)
    mesh3d_volumetric_fog_pipeline_cache_clear(backend)
    ensure_mesh3d_skin_buffers(backend, MESH3D_SKINNING_STORAGE_STRIDE_BYTES)
    |> ignore
  }
  ensure_mesh3d_view_binding_buffers(backend)
}

///|
fn mesh3d_volumetric_fog_color_format_for_target(
  backend : GpuBackend,
  target_id : Int,
) -> UInt? {
  if target_id < 0 {
    match surface_target_format(backend, target_id) {
      Some(format) => Some(format.to_u32())
      None => None
    }
  } else {
    match find_texture(backend, target_id) {
      Some(texture) => Some(texture.format.to_u32())
      None => None
    }
  }
}

///|
fn mesh3d_volumetric_fog_shader_defines(
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("SHADOW_FILTER_METHOD_HARDWARE_2X2", true)
  if msaa_sample_count > 1 {
    defines.set("MULTISAMPLED", true)
  }
  if atmosphere {
    defines.set("ATMOSPHERE", true)
  }
  if has_density_texture {
    defines.set("DENSITY_TEXTURE", true)
  }
  defines
}

///|
fn mesh3d_volumetric_fog_bind_group_layout_index(
  msaa_sample_count : Int,
  has_density_texture : Bool,
) -> Int {
  let mut bits = 0
  if msaa_sample_count > 1 {
    bits = bits | 1
  }
  if has_density_texture {
    bits = bits | 2
  }
  bits
}

///|
fn mesh3d_volumetric_fog_pipeline_label(
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
) -> String {
  let msaa_suffix = if msaa_sample_count > 1 { "msaa" } else { "single" }
  let density_suffix = if has_density_texture {
    "textured"
  } else {
    "textureless"
  }
  let atmosphere_suffix = if atmosphere {
    "atmosphere"
  } else {
    "no_atmosphere"
  }
  "mgstudio_volumetric_fog_" +
  msaa_suffix +
  "_" +
  density_suffix +
  "_" +
  atmosphere_suffix
}

///|
fn mesh3d_build_volumetric_fog_pipeline(
  backend : GpuBackend,
  color_format : UInt,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  mesh_pipeline_view_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
  vertex_stride_bytes : UInt64,
) -> Int? raise GpuBackendError {
  let view_layout_key_bits = mesh_pipeline_view_key.bits()
  if mesh3d_volumetric_fog_pipeline_available_id_get(
      backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
      view_layout_key_bits, vertex_stride_bytes,
    )
    is Some(pipeline_id) {
    return Some(pipeline_id)
  }
  if mesh3d_volumetric_fog_pipeline_failed(
      backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
      view_layout_key_bits, vertex_stride_bytes,
    ) {
    return None
  }
  ensure_mesh3d_pipeline_layout_resources(backend)
  ensure_mesh3d_volumetric_fog_bind_group_layouts(backend)
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    None,
    default_view_layout_key=mesh_pipeline_view_key,
  )
  let view_bgl = layout_entry.view_bind_group_layout
  let layout_index = mesh3d_volumetric_fog_bind_group_layout_index(
    msaa_sample_count, has_density_texture,
  )
  guard layout_index >= 0 &&
    layout_index < backend.mesh3d_volumetric_fog_bgls.length() else {
    return None
  }
  let volumetric_bgl = backend.mesh3d_volumetric_fog_bgls[layout_index]
  let shader_source = load_wgsl_preprocessed(
    backend.assets_base,
    MESH3D_VOLUMETRIC_FOG_SHADER_PATH,
    mesh3d_volumetric_fog_shader_defines(
      msaa_sample_count, has_density_texture, atmosphere,
    ),
    default_wgsl_value_defines(),
  ) catch {
    ShaderNotReady(_) => return None
    Fatal(message) => {
      ignore(
        mesh3d_volumetric_fog_pipeline_set_failed(
          backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
          view_layout_key_bits, vertex_stride_bytes, message,
        ),
      )
      debug("[renderer] volumetric fog pipeline failed: \{message}")
      return None
    }
  }
  let shader = mesh3d_create_forward_shader_module(
    backend, shader_source, "wgpu: failed to create volumetric fog shader module",
  ) catch {
    ShaderNotReady(_) => return None
    Fatal(message) => {
      ignore(
        mesh3d_volumetric_fog_pipeline_set_failed(
          backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
          view_layout_key_bits, vertex_stride_bytes, message,
        ),
      )
      debug("[renderer] volumetric fog pipeline failed: \{message}")
      return None
    }
  }
  let pipeline_layout = backend.device.create_pipeline_layout_2(
    view_bgl, volumetric_bgl,
  )
  let label = mesh3d_volumetric_fog_pipeline_label(
    msaa_sample_count, has_density_texture, atmosphere,
  )
  pipeline_layout.set_label(label + "_layout")
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      shader,
      layout=pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_fragment_module(shader)
    builder.set_color_target_format(tf(color_format))
    builder.set_blend_components(
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
      @wgpu.BLEND_FACTOR_ZERO,
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_OPERATION_ADD,
    )
    builder.set_vertex_buffer_layout(
      vertex_stride_bytes,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.set_topology_u32(@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    builder.set_cull_mode_u32(@wgpu.CULL_MODE_BACK)
    builder.set_multisample(msaa_sample_count.reinterpret_as_uint())
    backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
    let created = builder.create_pipeline(backend.device)
    let result = backend.device.pop_error_scope_sync_result(backend.instance)
    if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
      let message = mesh3d_error_scope_message(
        result, "wgpu: failed to create volumetric fog pipeline",
      )
      created.release()
      builder.free()
      ignore(
        mesh3d_volumetric_fog_pipeline_set_failed(
          backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
          view_layout_key_bits, vertex_stride_bytes, message,
        ),
      )
      debug("[renderer] volumetric fog pipeline failed: \{message}")
      shader.release()
      pipeline_layout.release()
      return None
    }
    builder.free()
    created
  } catch {
    err => {
      let message = "wgpu: failed to build volumetric fog pipeline: \{err.message()}"
      ignore(
        mesh3d_volumetric_fog_pipeline_set_failed(
          backend, color_format, msaa_sample_count, has_density_texture, atmosphere,
          view_layout_key_bits, vertex_stride_bytes, message,
        ),
      )
      debug("[renderer] volumetric fog pipeline failed: \{message}")
      shader.release()
      pipeline_layout.release()
      return None
    }
  }
  pipeline.set_label(label)
  let pipeline_id = mesh3d_volumetric_fog_pipeline_set(
    backend, color_format, msaa_sample_count, has_density_texture, atmosphere, view_layout_key_bits,
    vertex_stride_bytes, pipeline_layout, pipeline,
  )
  shader.release()
  Some(pipeline_id)
}

///|
pub fn GpuBackend::prepare_mesh3d_volumetric_fog_pipeline(
  self : GpuBackend,
  target_id : Int,
  msaa_sample_count : Int,
  has_density_texture : Bool,
  atmosphere : Bool,
  hull_mesh_id : Int,
) -> Int? raise GpuBackendError {
  guard mesh3d_volumetric_fog_color_format_for_target(self, target_id)
    is Some(color_format) else {
    return None
  }
  guard find_mesh(self, hull_mesh_id) is Some(hull_mesh) else { return None }
  let mesh_pipeline_view_key = match self.pass_state {
    Some(pass_state) =>
      mesh3d_pass_mesh_view_layout_key(pass_state, atmosphere~)
    None =>
      @mesh_view_layout.mesh_view_layout_key(
        msaa_sample_count > 1,
        false,
        false,
        false,
        false,
        false,
        atmosphere,
        false,
      )
  }
  match
    mesh3d_build_volumetric_fog_pipeline(
      self,
      color_format,
      msaa_sample_count,
      has_density_texture,
      atmosphere,
      mesh_pipeline_view_key,
      hull_mesh.vertex_stride_bytes,
    ) {
    Some(pipeline_id) => Some(pipeline_id)
    None =>
      mesh3d_volumetric_fog_pipeline_id_get(
        self,
        color_format,
        msaa_sample_count,
        has_density_texture,
        atmosphere,
        mesh_pipeline_view_key.bits(),
        hull_mesh.vertex_stride_bytes,
      )
  }
}

///|
fn mesh3d_create_empty_bind_group_layout(
  backend : GpuBackend,
  label : String,
) -> @wgpu.BindGroupLayout {
  let layout = backend.device.create_bind_group_layout_empty()
  layout.set_label(label)
  layout
}

///|
fn mesh3d_create_empty_bind_group(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  label : String,
) -> @wgpu.BindGroup {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=0UL)
  builder.finish(backend.device, layout, label~)
}

///|
fn mesh3d_default_draw_bind_group_layout_descriptor(
  lightmapped? : Bool = false,
) -> @render_resource.BindGroupLayoutDescriptor {
  let view_stage = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let entries = [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      view_stage,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      1,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
      ),
    ),
  ]
  if lightmapped {
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        4,
        @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
        @render_resource.BindingType::TextureBinding(
          @render_resource.TextureSampleType::Float(true),
          @render_resource.TextureViewDimension::D2,
          false,
        ),
      ),
    )
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        5,
        @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
        @render_resource.BindingType::SamplerBinding(
          @render_resource.SamplerBindingType::Filtering,
        ),
      ),
    )
  }
  @render_resource.BindGroupLayoutDescriptor::new(
    if lightmapped {
      "lightmapped_mesh_layout"
    } else {
      "mesh_layout"
    },
    entries,
  )
}

///|
fn mesh3d_buffer_binding_type_to_wgpu(
  kind : @render_resource.BufferBindingType,
) -> UInt {
  match kind {
    Uniform => @wgpu.BUFFER_BINDING_TYPE_UNIFORM
    Storage(read_only) =>
      if read_only {
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE
      } else {
        @wgpu.BUFFER_BINDING_TYPE_STORAGE
      }
  }
}

///|
fn mesh3d_texture_sample_type_to_wgpu(
  kind : @render_resource.TextureSampleType,
) -> UInt {
  match kind {
    Float(filterable) =>
      if filterable {
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT
      } else {
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT
      }
    Depth => @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH
    SInt => @wgpu.TEXTURE_SAMPLE_TYPE_SINT
    UInt => @wgpu.TEXTURE_SAMPLE_TYPE_UINT
  }
}

///|
fn mesh3d_texture_view_dimension_to_wgpu(
  dimension : @render_resource.TextureViewDimension,
) -> UInt {
  match dimension {
    D1 => @wgpu.TEXTURE_VIEW_DIMENSION_1D
    D2 => @wgpu.TEXTURE_VIEW_DIMENSION_2D
    D2Array => @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY
    Cube => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE
    CubeArray => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE_ARRAY
    D3 => @wgpu.TEXTURE_VIEW_DIMENSION_3D
  }
}

///|
fn mesh3d_sampler_binding_type_to_wgpu(
  kind : @render_resource.SamplerBindingType,
) -> UInt {
  match kind {
    Filtering => @wgpu.SAMPLER_BINDING_TYPE_FILTERING
    NonFiltering => @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING
    Comparison => @wgpu.SAMPLER_BINDING_TYPE_COMPARISON
  }
}

///|
fn mesh3d_storage_texture_access_to_wgpu(
  access : @render_resource.StorageTextureAccess,
) -> UInt {
  match access {
    WriteOnly => @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY
    ReadOnly => @wgpu.STORAGE_TEXTURE_ACCESS_READ_ONLY
    ReadWrite => @wgpu.STORAGE_TEXTURE_ACCESS_READ_WRITE
  }
}

///|
fn mesh3d_add_render_resource_layout_entry(
  builder : @wgpu.BindGroupLayoutBuilder,
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  if entry.binding() < 0 {
    return false
  }
  let binding = entry.binding().reinterpret_as_uint()
  let visibility = ss(entry.visibility().to_uint64())
  let count = if entry.count() > 1 {
    entry.count().reinterpret_as_uint()
  } else {
    1U
  }
  match entry.kind() {
    Buffer =>
      builder.add_buffer(
        binding,
        visibility,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=0UL,
      )
    Texture =>
      builder.add_texture(
        binding,
        visibility,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        count~,
      )
    Sampler =>
      builder.add_sampler(
        binding,
        visibility,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
        count~,
      )
    StorageTexture =>
      builder.add_storage_texture(
        binding,
        visibility,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
    External => false
    BufferBinding(buffer_kind, has_dynamic_offset, min_binding_size) =>
      builder.add_buffer(
        binding,
        visibility,
        mesh3d_buffer_binding_type_to_wgpu(buffer_kind),
        has_dynamic_offset~,
        min_binding_size~,
      )
    TextureBinding(sample_type, view_dimension, multisampled) =>
      builder.add_texture(
        binding,
        visibility,
        mesh3d_texture_sample_type_to_wgpu(sample_type),
        mesh3d_texture_view_dimension_to_wgpu(view_dimension),
        multisampled~,
        count~,
      )
    SamplerBinding(sampler_type) =>
      builder.add_sampler(
        binding,
        visibility,
        mesh3d_sampler_binding_type_to_wgpu(sampler_type),
        count~,
      )
    StorageTextureBinding(access, format, view_dimension) =>
      builder.add_storage_texture(
        binding,
        visibility,
        mesh3d_storage_texture_access_to_wgpu(access),
        tf(format),
        mesh3d_texture_view_dimension_to_wgpu(view_dimension),
      )
  }
}

///|
fn mesh3d_create_bind_group_layout_from_descriptor(
  backend : GpuBackend,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  label_suffix : String,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupLayoutBuilder::new(
    max_entries=entries.length().to_uint64(),
  )
  for entry in entries {
    if !mesh3d_add_render_resource_layout_entry(builder, entry) {
      builder.free()
      fatal(
        "wgpu: unsupported mesh3d bind group layout descriptor entry in " +
        descriptor.label(),
      )
    }
  }
  builder.finish(
    backend.device,
    label="mgstudio_mesh3d_descriptor_bgl_" +
      label_suffix +
      "_" +
      descriptor.label(),
  )
}

///|
fn mesh3d_descriptor_material_layout(
  descriptor : @render_resource.RenderPipelineDescriptor?,
) -> @render_resource.BindGroupLayoutDescriptor? {
  mesh3d_descriptor_bind_group_layout(descriptor, 3)
}

///|
fn mesh3d_descriptor_bind_group_layout_exact(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  index : Int,
) -> @render_resource.BindGroupLayoutDescriptor? {
  guard descriptor is Some(descriptor0) else { return None }
  if index < 0 || descriptor0.layout.length() <= index {
    return None
  }
  Some(descriptor0.layout[index])
}

///|
fn mesh3d_descriptor_bind_group_layout(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  index : Int,
) -> @render_resource.BindGroupLayoutDescriptor? {
  guard descriptor is Some(descriptor0) else { return None }
  if index < 0 || descriptor0.layout.length() <= index {
    return None
  }
  let layout = descriptor0.layout[index]
  if layout.entries().length() == 0 {
    return None
  }
  Some(layout)
}

///|
fn mesh3d_bind_group_layout_descriptor_view_dynamic_offsets(
  layout : @render_resource.BindGroupLayoutDescriptor,
  light_probes_uniform_offset~ : UInt,
) -> Array[UInt] {
  let offsets : Array[UInt] = []
  for entry in layout.entries() {
    match entry.kind() {
      BufferBinding(_, has_dynamic_offset, _) =>
        if has_dynamic_offset {
          if entry.binding() == 12 {
            offsets.push(light_probes_uniform_offset)
          } else {
            offsets.push(0U)
          }
        }
      _ => ()
    }
  }
  offsets
}

///|
fn mesh3d_descriptor_view_bind_group_dynamic_offsets(
  descriptor : @render_resource.RenderPipelineDescriptor?,
  index : Int,
  light_probes_uniform_offset~ : UInt,
) -> Array[UInt] {
  guard mesh3d_descriptor_bind_group_layout(descriptor, index) is Some(layout) else {
    if descriptor is None && index == 0 {
      return mesh3d_bind_group_layout_descriptor_view_dynamic_offsets(
        mesh3d_default_mesh_view_layout().main_bind_group_layout_descriptor(),
        light_probes_uniform_offset~,
      )
    }
    return []
  }
  mesh3d_bind_group_layout_descriptor_view_dynamic_offsets(
    layout,
    light_probes_uniform_offset~,
  )
}

///|
fn mesh3d_material_pipeline_layout_cache_get(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  view_layout_key_bits : UInt,
  draw_layout_lightmapped : Bool,
) -> Mesh3dMaterialPipelineLayoutCacheEntry? {
  for entry in backend.mesh3d_material_pipeline_layout_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.view_layout_key_bits == view_layout_key_bits &&
      entry.draw_layout_lightmapped == draw_layout_lightmapped {
      return Some(entry)
    }
  }
  None
}

///|
fn mesh3d_material_pipeline_layout_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  default_view_layout_key? : @mesh_view_layout.MeshPipelineViewLayoutKey = @mesh_view_layout.MeshPipelineViewLayoutKey::MeshPipelineViewLayoutKey(),
  default_lightmapped? : Bool = false,
) -> Mesh3dMaterialPipelineLayoutCacheEntry raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(backend)
  let view_layout_key_bits = default_view_layout_key.bits()
  if material_pipeline_id == MESH3D_DEFAULT_MATERIAL_PIPELINE_ID {
    if view_layout_key_bits != 0U || default_lightmapped {
      if mesh3d_material_pipeline_layout_cache_get(
          backend, material_pipeline_id, view_layout_key_bits, default_lightmapped,
        )
        is Some(entry) {
        return entry
      }
      let draw_layout_descriptor = mesh3d_default_draw_bind_group_layout_descriptor(
        lightmapped=default_lightmapped,
      )
      let draw_bgl = if default_lightmapped {
        mesh3d_create_bind_group_layout_from_descriptor(
          backend, draw_layout_descriptor, "default_draw_lightmapped",
        )
      } else {
        guard backend.mesh3d_bgl_draw is Some(base_draw_bgl) else {
          fatal("wgpu: missing mesh3d draw bind group layout")
        }
        base_draw_bgl
      }
      guard backend.mesh3d_bgl_material is Some(material_bgl) else {
        fatal("wgpu: missing mesh3d material bind group layout")
      }
      let mesh_view_layout = @mesh_view_layout.render3d_mesh_pipeline_view_layout(
        true,
        true,
        default_view_layout_key,
        clustered_decals_usable=mesh3d_clustered_decals_are_usable(),
        irradiance_volumes_usable=false,
        oit_supported=false,
      )
      let view_bgl = mesh3d_create_bind_group_layout_from_descriptor(
        backend,
        mesh_view_layout.main_bind_group_layout_descriptor(),
        "default_view_" + view_layout_key_bits.to_string(),
      )
      let binding_arrays_bgl = mesh3d_create_bind_group_layout_from_descriptor(
        backend,
        mesh_view_layout.binding_array_bind_group_layout_descriptor(),
        "default_binding_arrays_" + view_layout_key_bits.to_string(),
      )
      let pipeline_layout = create_pipeline_layout_4(
        backend.device,
        view_bgl,
        binding_arrays_bgl,
        draw_bgl,
        material_bgl,
      )
      let entry = {
        material_pipeline_id,
        view_layout_key_bits,
        draw_layout_lightmapped: default_lightmapped,
        view_bind_group_layout_descriptor: mesh_view_layout.main_bind_group_layout_descriptor(),
        view_bind_group_layout: view_bgl,
        binding_arrays_bind_group_layout_descriptor: mesh_view_layout.binding_array_bind_group_layout_descriptor(),
        binding_arrays_bind_group_layout: binding_arrays_bgl,
        draw_bind_group_layout_descriptor: draw_layout_descriptor,
        draw_bind_group_layout: draw_bgl,
        material_bind_group_layout: material_bgl,
        pipeline_layout,
      }
      backend.mesh3d_material_pipeline_layout_cache.push(entry)
      return entry
    }
    guard backend.mesh3d_bgl_view is Some(view_bgl) else {
      fatal("wgpu: missing mesh3d view bind group layout")
    }
    guard backend.mesh3d_bgl_binding_arrays is Some(binding_arrays_bgl) else {
      fatal("wgpu: missing mesh3d binding-array bind group layout")
    }
    guard backend.mesh3d_bgl_draw is Some(draw_bgl) else {
      fatal("wgpu: missing mesh3d draw bind group layout")
    }
    guard backend.mesh3d_bgl_material is Some(material_bgl) else {
      fatal("wgpu: missing mesh3d material bind group layout")
    }
    guard backend.mesh3d_pipeline_layout is Some(pipeline_layout) else {
      fatal("wgpu: missing mesh3d pipeline layout")
    }
    let mesh_view_layout = mesh3d_default_mesh_view_layout()
    return {
      material_pipeline_id,
      view_layout_key_bits,
      draw_layout_lightmapped: false,
      view_bind_group_layout_descriptor: mesh_view_layout.main_bind_group_layout_descriptor(),
      view_bind_group_layout: view_bgl,
      binding_arrays_bind_group_layout_descriptor: mesh_view_layout.binding_array_bind_group_layout_descriptor(),
      binding_arrays_bind_group_layout: binding_arrays_bgl,
      draw_bind_group_layout_descriptor: mesh3d_default_draw_bind_group_layout_descriptor(),
      draw_bind_group_layout: draw_bgl,
      material_bind_group_layout: material_bgl,
      pipeline_layout,
    }
  }
  if mesh3d_material_pipeline_layout_cache_get(
      backend, material_pipeline_id, 0U, false,
    )
    is Some(entry) {
    return entry
  }
  guard mesh3d_descriptor_bind_group_layout(material_descriptor, 0)
    is Some(view_layout_descriptor) else {
    fatal("wgpu: material pipeline descriptor is missing group 0 view layout")
  }
  guard mesh3d_descriptor_bind_group_layout_exact(material_descriptor, 1)
    is Some(binding_arrays_layout_descriptor) else {
    fatal(
      "wgpu: material pipeline descriptor is missing group 1 binding-array layout",
    )
  }
  guard mesh3d_descriptor_bind_group_layout(material_descriptor, 2)
    is Some(draw_layout_descriptor) else {
    fatal("wgpu: material pipeline descriptor is missing group 2 draw layout")
  }
  let label_suffix = material_pipeline_id.to_string()
  let view_bgl = mesh3d_create_bind_group_layout_from_descriptor(
    backend,
    view_layout_descriptor,
    label_suffix + "_view",
  )
  let binding_arrays_bgl = mesh3d_create_bind_group_layout_from_descriptor(
    backend,
    binding_arrays_layout_descriptor,
    label_suffix + "_binding_arrays",
  )
  let draw_bgl = mesh3d_create_bind_group_layout_from_descriptor(
    backend,
    draw_layout_descriptor,
    label_suffix + "_draw",
  )
  let material_bgl = match
    mesh3d_descriptor_material_layout(material_descriptor) {
    Some(material_layout_descriptor) =>
      mesh3d_create_bind_group_layout_from_descriptor(
        backend,
        material_layout_descriptor,
        label_suffix + "_material",
      )
    None =>
      mesh3d_create_empty_bind_group_layout(
        backend,
        "mgstudio_mesh3d_empty_material_bgl_" + label_suffix,
      )
  }
  let pipeline_layout = create_pipeline_layout_4(
    backend.device,
    view_bgl,
    binding_arrays_bgl,
    draw_bgl,
    material_bgl,
  )
  let entry = {
    material_pipeline_id,
    view_layout_key_bits: 0U,
    draw_layout_lightmapped: false,
    view_bind_group_layout_descriptor: view_layout_descriptor,
    view_bind_group_layout: view_bgl,
    binding_arrays_bind_group_layout_descriptor: binding_arrays_layout_descriptor,
    binding_arrays_bind_group_layout: binding_arrays_bgl,
    draw_bind_group_layout_descriptor: draw_layout_descriptor,
    draw_bind_group_layout: draw_bgl,
    material_bind_group_layout: material_bgl,
    pipeline_layout,
  }
  backend.mesh3d_material_pipeline_layout_cache.push(entry)
  entry
}

///|
fn ensure_mesh3d_shadow_pipeline_layout_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(backend)
  if backend.mesh3d_shadow_pipeline_layout_depth_only is None ||
    backend.mesh3d_shadow_pipeline_layout_material is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_VIEW_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        1U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_GLOBALS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        14U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d shadow view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_shadow_view_bgl",
    )
    let empty_bgl = mesh3d_create_empty_bind_group_layout(
      backend, "mgstudio_mesh3d_shadow_empty_bgl",
    )
    guard backend.mesh3d_bgl_draw is Some(mesh_bgl) else {
      fatal("wgpu: missing mesh3d draw bind group layout for shadows")
    }
    guard backend.mesh3d_bgl_material is Some(material_bgl) else {
      fatal("wgpu: missing mesh3d material bind group layout for shadows")
    }
    let depth_only_layout = create_pipeline_layout_4(
      backend.device,
      view_bgl,
      empty_bgl,
      mesh_bgl,
      empty_bgl,
    )
    let material_layout = create_pipeline_layout_4(
      backend.device,
      view_bgl,
      empty_bgl,
      mesh_bgl,
      material_bgl,
    )
    backend.mesh3d_shadow_bgl_view = Some(view_bgl)
    backend.mesh3d_shadow_bgl_empty = Some(empty_bgl)
    backend.mesh3d_shadow_pipeline_layout_depth_only = Some(depth_only_layout)
    backend.mesh3d_shadow_pipeline_layout_material = Some(material_layout)
    backend.mesh3d_shadow_view_bg = None
    backend.mesh3d_shadow_empty_bg = None
  }
  if backend.mesh3d_shadow_view_bg is None ||
    backend.mesh3d_shadow_empty_bg is None {
    ensure_mesh3d_view_binding_buffers(backend)
    guard backend.mesh3d_shadow_bgl_view is Some(view_bgl) else { return }
    guard backend.mesh3d_shadow_bgl_empty is Some(empty_bgl) else { return }
    guard backend.mesh3d_view_buf is Some(view_buf) else { return }
    guard backend.mesh3d_globals_buf is Some(globals_buf) else { return }
    guard backend.mesh3d_visibility_ranges_buf is Some(visibility_ranges_buf) else {
      return
    }
    let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
      builder.add_buffer(1U, globals_buf, size=MESH3D_GLOBALS_BUFFER_SIZE) &&
      builder.add_buffer(
        14U,
        visibility_ranges_buf,
        size=MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    if !ok {
      builder.free()
      return
    }
    backend.mesh3d_shadow_view_bg = Some(
      builder.finish(
        backend.device,
        view_bgl,
        label="mgstudio_mesh3d_shadow_view_bg",
      ),
    )
    backend.mesh3d_shadow_empty_bg = Some(
      mesh3d_create_empty_bind_group(
        backend, empty_bgl, "mgstudio_mesh3d_shadow_empty_bg",
      ),
    )
  }
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let color_format = tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32()
  if mesh3d_pipeline_get(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    ) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key=mesh3d_default_mesh_view_layout_key(
      tonemap_in_shader~,
    ),
    default_lightmapped=lightmapped,
  )
  let pl = layout_entry.pipeline_layout
  let modules = mesh3d_create_forward_shader_modules(
    backend,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    "mesh3d rgba8",
    lightmapped~,
  ) catch {
    ShaderNotReady(_) => return
    Fatal(message) => {
      mesh3d_pipeline_set_failed(
        backend,
        color_format,
        msaa_sample_count,
        topology,
        material_pipeline_id,
        safe_cull_mode,
        blend_kind,
        skinned,
        forward_decal,
        tonemap_in_shader,
        tonemapping_mode,
        deband_dither_enabled,
        shadow_filter_method,
        message,
        lightmapped~,
      )
      debug("[renderer] mesh3d pipeline failed: \{message}")
      return
    }
  }
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    modules.vertex,
    color_format,
    fragment_shader=modules.fragment,
    with_depth=true,
    depth_write_enabled=mesh3d_descriptor_depth_write_enabled(
      material_descriptor,
      !transparent,
    ),
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
    depth_compare_u32=mesh3d_descriptor_depth_compare(material_descriptor),
    vertex_entry="vertex",
    fragment_entry="fragment",
    vertex_buffer_layout=mesh3d_descriptor_vertex_buffer_layout(
      material_descriptor,
    ),
    sample_count=msaa_sample_count,
  )
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  let pipeline_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc)
  let blend_suffix = mesh3d_pipeline_blend_suffix(blend_kind)
  let skinned_suffix = if skinned { "_skinned" } else { "_unskinned" }
  if pipeline_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      pipeline_result,
      "wgpu: failed to create mesh3d rgba8 pipeline: " +
      blend_suffix +
      skinned_suffix,
    )
    pipeline.release()
    modules.release()
    mesh3d_pipeline_set_failed(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      message,
      lightmapped~,
    )
    debug("[renderer] mesh3d pipeline failed: \{message}")
    return
  }
  pipeline.set_label(
    "mgstudio_mesh3d_rgba8_" +
    blend_suffix +
    "_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    skinned_suffix,
  )
  mesh3d_pipeline_set(
    backend,
    color_format,
    msaa_sample_count,
    topology,
    material_pipeline_id,
    safe_cull_mode,
    blend_kind,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    pipeline,
    lightmapped~,
  )
  modules.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  msaa_sample_count : Int,
  topology : UInt,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh3d pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh3d_pipeline_layout_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let color_format = format.to_u32()
  if mesh3d_pipeline_get(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      lightmapped~,
    ) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key=mesh3d_default_mesh_view_layout_key(
      tonemap_in_shader~,
    ),
    default_lightmapped=lightmapped,
  )
  let pl = layout_entry.pipeline_layout
  let modules = mesh3d_create_forward_shader_modules(
    backend,
    material_descriptor,
    skinned,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    "mesh3d surface",
    lightmapped~,
  ) catch {
    ShaderNotReady(_) => return
    Fatal(message) => {
      mesh3d_pipeline_set_failed(
        backend,
        color_format,
        msaa_sample_count,
        topology,
        material_pipeline_id,
        safe_cull_mode,
        blend_kind,
        skinned,
        forward_decal,
        tonemap_in_shader,
        tonemapping_mode,
        deband_dither_enabled,
        shadow_filter_method,
        message,
        lightmapped~,
      )
      debug("[renderer] mesh3d pipeline failed: \{message}")
      return
    }
  }
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    modules.vertex,
    color_format,
    fragment_shader=modules.fragment,
    with_depth=true,
    depth_write_enabled=mesh3d_descriptor_depth_write_enabled(
      material_descriptor,
      !transparent,
    ),
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
    depth_compare_u32=mesh3d_descriptor_depth_compare(material_descriptor),
    vertex_entry="vertex",
    fragment_entry="fragment",
    vertex_buffer_layout=mesh3d_descriptor_vertex_buffer_layout(
      material_descriptor,
    ),
    sample_count=msaa_sample_count,
  )
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  let pipeline_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc)
  let blend_suffix = mesh3d_pipeline_blend_suffix(blend_kind)
  let skinned_suffix = if skinned { "_skinned" } else { "_unskinned" }
  if pipeline_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      pipeline_result,
      "wgpu: failed to create mesh3d surface pipeline: " +
      blend_suffix +
      skinned_suffix,
    )
    pipeline.release()
    modules.release()
    mesh3d_pipeline_set_failed(
      backend,
      color_format,
      msaa_sample_count,
      topology,
      material_pipeline_id,
      safe_cull_mode,
      blend_kind,
      skinned,
      forward_decal,
      tonemap_in_shader,
      tonemapping_mode,
      deband_dither_enabled,
      shadow_filter_method,
      message,
      lightmapped~,
    )
    debug("[renderer] mesh3d pipeline failed: \{message}")
    return
  }
  pipeline.set_label(
    "mgstudio_mesh3d_surface_" +
    blend_suffix +
    "_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    skinned_suffix,
  )
  mesh3d_pipeline_set(
    backend,
    color_format,
    msaa_sample_count,
    topology,
    material_pipeline_id,
    safe_cull_mode,
    blend_kind,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    pipeline,
    lightmapped~,
  )
  modules.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  material_flags : UInt,
  material_pipeline_id : UInt64,
  forward_decal : Bool,
  topology : UInt,
  cull_mode : Int,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  skinned : Bool,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  lightmapped? : Bool = false,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    backend, material_pipeline_id,
  )
  let effective_vertex_shader_path = match vertex_shader_path {
    Some(path) => Some(path)
    None => mesh3d_descriptor_vertex_shader_path(material_descriptor)
  }
  let resolved_vertex_shader_path = mesh3d_vertex_shader_path_or_default(
    effective_vertex_shader_path,
  )
  let effective_fragment_shader_path = match fragment_shader_path {
    Some(path) => Some(path)
    None => mesh3d_descriptor_fragment_shader_path(material_descriptor)
  }
  let resolved_fragment_shader_path = mesh3d_fragment_shader_path_or_default(
    effective_fragment_shader_path,
  )
  let blend_kind = mesh3d_blend_kind_from_material_flags(
    material_flags, transparent,
  )
  let msaa_sample_count = match backend.pass_state {
    Some(pass_state) => pass_state.msaa_sample_count
    None => 1
  }
  if resolved_vertex_shader_path != MESH3D_FORWARD_VERTEX_SHADER_PATH ||
    resolved_fragment_shader_path != MESH3D_FORWARD_SHADER_PATH {
    let custom_surface_format = match current_pass_color_format(backend) {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) =>
        Some(format)
      _ => None
    }
    return mesh3d_custom_pipeline_get_or_create(
      backend, material_pipeline_id, material_descriptor, resolved_vertex_shader_path,
      resolved_fragment_shader_path, custom_surface_format, msaa_sample_count, topology,
      transparent, blend_kind, forward_decal, cull_mode, skinned, tonemap_in_shader,
      tonemapping_mode, deband_dither_enabled, shadow_filter_method,
    )
  }
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(
        backend,
        format,
        msaa_sample_count,
        topology,
        material_pipeline_id,
        material_descriptor,
        cull_mode,
        blend_kind,
        skinned,
        forward_decal,
        tonemap_in_shader,
        tonemapping_mode,
        deband_dither_enabled,
        shadow_filter_method,
        lightmapped~,
      )
      return mesh3d_pipeline_get(
        backend,
        format.to_u32(),
        msaa_sample_count,
        topology,
        material_pipeline_id,
        cull_mode,
        blend_kind,
        skinned,
        forward_decal,
        tonemap_in_shader,
        tonemapping_mode,
        deband_dither_enabled,
        shadow_filter_method,
        lightmapped~,
      )
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(
    backend,
    msaa_sample_count,
    topology,
    material_pipeline_id,
    material_descriptor,
    cull_mode,
    blend_kind,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    lightmapped~,
  )
  mesh3d_pipeline_get(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32(),
    msaa_sample_count,
    topology,
    material_pipeline_id,
    cull_mode,
    blend_kind,
    skinned,
    forward_decal,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither_enabled,
    shadow_filter_method,
    lightmapped~,
  )
}

///|
fn mesh3d_build_shadow_depth_pipeline(
  backend : GpuBackend,
  topology : UInt,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
  directional_light : Bool,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  let native_unclipped_depth = mesh3d_shadow_depth_supports_native_unclipped_depth(
    backend, directional_light,
  )
  let emulate_unclipped_depth = mesh3d_shadow_depth_should_emulate_unclipped_depth(
    backend, directional_light,
  )
  let effective_material_path = material_path || emulate_unclipped_depth
  let pipeline_layout = if effective_material_path &&
    material_pipeline_id != MESH3D_DEFAULT_MATERIAL_PIPELINE_ID {
    guard backend.mesh3d_shadow_bgl_view is Some(view_bgl) else {
      fatal("wgpu: missing mesh3d shadow view bind group layout")
    }
    guard backend.mesh3d_shadow_bgl_empty is Some(empty_bgl) else {
      fatal("wgpu: missing mesh3d shadow empty bind group layout")
    }
    let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
      backend, material_pipeline_id, material_descriptor,
    )
    Some(
      create_pipeline_layout_4(
        backend.device,
        view_bgl,
        empty_bgl,
        layout_entry.draw_bind_group_layout,
        layout_entry.material_bind_group_layout,
      ),
    )
  } else if material_pipeline_id != MESH3D_DEFAULT_MATERIAL_PIPELINE_ID {
    guard backend.mesh3d_shadow_bgl_view is Some(view_bgl) else {
      fatal("wgpu: missing mesh3d shadow view bind group layout")
    }
    guard backend.mesh3d_shadow_bgl_empty is Some(empty_bgl) else {
      fatal("wgpu: missing mesh3d shadow empty bind group layout")
    }
    let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
      backend, material_pipeline_id, material_descriptor,
    )
    Some(
      create_pipeline_layout_4(
        backend.device,
        view_bgl,
        empty_bgl,
        layout_entry.draw_bind_group_layout,
        empty_bgl,
      ),
    )
  } else if effective_material_path {
    backend.mesh3d_shadow_pipeline_layout_material
  } else {
    backend.mesh3d_shadow_pipeline_layout_depth_only
  }
  guard pipeline_layout is Some(pl) else {
    fatal("wgpu: missing mesh3d pipeline layout for shadow depth pipeline")
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  let vertex_shader_path = match
    mesh3d_descriptor_vertex_shader_path(material_descriptor) {
    Some(path) =>
      if path == "" {
        MESH3D_PREPASS_VERTEX_SHADER_PATH
      } else {
        path
      }
    None => MESH3D_PREPASS_VERTEX_SHADER_PATH
  }
  let fragment_shader_path = match
    mesh3d_descriptor_fragment_shader_path(material_descriptor) {
    Some(path) =>
      if path == "" {
        MESH3D_PREPASS_MATERIAL_FRAGMENT_SHADER_PATH
      } else {
        path
      }
    None => MESH3D_PREPASS_MATERIAL_FRAGMENT_SHADER_PATH
  }
  let vertex_wgsl = load_wgsl_required_mesh3d_shadow_pipeline(
    backend.assets_base,
    material_descriptor,
    skinned,
    material_path,
    directional_light,
    emulate_unclipped_depth,
    vertex_shader_path,
  )
  let vertex_sm = backend.device.create_shader_module_wgsl(vertex_wgsl)
  let fragment_sm = if effective_material_path {
    Some(
      backend.device.create_shader_module_wgsl(
        load_wgsl_required_mesh3d_shadow_pipeline(
          backend.assets_base,
          material_descriptor,
          skinned,
          material_path,
          directional_light,
          emulate_unclipped_depth,
          fragment_shader_path,
        ),
      ),
    )
  } else {
    None
  }
  let descriptor_vertex_layout = mesh3d_descriptor_vertex_buffer_layout(
    material_descriptor,
  )
  if material_descriptor is Some(_) && descriptor_vertex_layout is None {
    fatal(
      "wgpu: material prepass descriptor is missing a valid vertex buffer layout",
    )
  }
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(vertex_sm, layout=pl)
    builder.set_entry_points("vertex", "fragment")
    match descriptor_vertex_layout {
      Some(layout) => {
        builder.set_vertex_buffer_layout(
          layout.array_stride.to_uint64(),
          mesh_vertex_step_mode_to_wgpu(layout.step_mode),
        )
        for attribute in layout.attributes {
          builder.add_vertex_attribute(
            mesh_vertex_format_to_wgpu(attribute.format),
            attribute.offset.to_uint64(),
            attribute.shader_location.reinterpret_as_uint(),
          )
        }
      }
      None => {
        builder.set_vertex_buffer_layout(
          MESH3D_VERTEX_STRIDE_BYTES,
          @wgpu.VERTEX_STEP_MODE_VERTEX,
        )
        builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
        builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 1U)
        if skinned {
          builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_UINT32X4, 48UL, 5U)
        }
        if skinned {
          builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 64UL, 6U)
        }
        builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 7U)
      }
    }
    builder.set_topology_u32(topology)
    builder.set_depth_stencil(
      tf(mesh3d_descriptor_depth_format(material_descriptor)),
      depth_write_enabled=true,
      depth_compare_u32=mesh3d_descriptor_depth_compare(material_descriptor),
    )
    builder.set_cull_mode_u32(cull_mode_wgpu)
    if native_unclipped_depth {
      builder.set_unclipped_depth(true)
    }
    match fragment_sm {
      Some(fragment_module) => {
        builder.set_fragment_module(fragment_module)
        builder.set_color_target_count(0U)
      }
      None => builder.clear_fragment()
    }
    let desc = builder.finish_descriptor_ptr()
    let pipeline = backend.device.create_render_pipeline_ptr(desc)
    @wgpu_c.render_pipeline_descriptor_free(desc)
    builder.free()
    pipeline
  } catch {
    err => {
      vertex_sm.release()
      match fragment_sm {
        Some(fragment_module) => fragment_module.release()
        None => ()
      }
      fatal(
        "wgpu: failed to build canonical mesh3d shadow depth pipeline: \{err.message()}",
      )
    }
  }
  let shadow_pipeline_suffix = if material_path {
    "material_"
  } else {
    "depth_only_"
  }
  let skinned_suffix = if skinned { "_skinned" } else { "_unskinned" }
  let light_suffix = if directional_light { "_directional" } else { "_point" }
  pipeline.set_label(
    "mgstudio_mesh3d_shadow_" +
    shadow_pipeline_suffix +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    skinned_suffix +
    light_suffix,
  )
  vertex_sm.release()
  match fragment_sm {
    Some(fragment_module) => fragment_module.release()
    None => ()
  }
  pipeline
}

///|
fn mesh3d_shadow_depth_pipeline_for_current_pass(
  backend : GpuBackend,
  topology : UInt,
  material_pipeline_id : UInt64,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
  directional_light : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  let material_descriptor = mesh3d_material_pipeline_descriptor_find(
    backend, material_pipeline_id,
  )
  let emulate_unclipped_depth = mesh3d_shadow_depth_should_emulate_unclipped_depth(
    backend, directional_light,
  )
  let shadow_pipeline_material_id = mesh3d_shadow_pipeline_material_id(
    material_pipeline_id, material_path, emulate_unclipped_depth,
  )
  if mesh3d_shadow_pipeline_get(
      backend, topology, shadow_pipeline_material_id, cull_mode, material_path, skinned,
      directional_light,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  let pipeline = mesh3d_build_shadow_depth_pipeline(
    backend, topology, shadow_pipeline_material_id, material_descriptor, cull_mode,
    material_path, skinned, directional_light,
  )
  mesh3d_shadow_pipeline_set(
    backend, topology, shadow_pipeline_material_id, cull_mode, material_path, skinned,
    directional_light, pipeline,
  )
  Some(pipeline)
}

///|
fn mesh3d_shadow_pipeline_material_id(
  material_pipeline_id : UInt64,
  material_path : Bool,
  emulate_unclipped_depth : Bool,
) -> UInt64 {
  if material_pipeline_id != MESH3D_DEFAULT_MATERIAL_PIPELINE_ID ||
    material_path ||
    emulate_unclipped_depth {
    material_pipeline_id
  } else {
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID
  }
}

///|
fn mesh3d_build_motion_vector_pipeline(
  backend : GpuBackend,
  pipeline_layout : @wgpu.PipelineLayout,
  topology : UInt,
  msaa_sample_count : Int,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  cull_mode : Int,
  skinned : Bool,
  has_previous_skin : Bool,
  morphed : Bool,
  has_previous_morph : Bool,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let fallback_wgsl = fn() raise GpuBackendError {
    load_wgsl_required_mesh3d_motion_vector_prepass(
      backend.assets_base,
      skinned,
      has_previous_skin,
      morphed,
      has_previous_morph,
    )
  }
  let vertex_shader_path = match
    mesh3d_descriptor_vertex_shader_path(material_descriptor) {
    Some(path) =>
      if path == "" {
        MESH3D_PREPASS_VERTEX_SHADER_PATH
      } else {
        path
      }
    None => MESH3D_PREPASS_VERTEX_SHADER_PATH
  }
  let fragment_shader_path = mesh3d_descriptor_fragment_shader_path(
    material_descriptor,
  )
  let fallback_defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  fallback_defines.set("PREPASS_FRAGMENT", true)
  fallback_defines.set("MOTION_VECTOR_PREPASS", true)
  if skinned {
    fallback_defines.set("SKINNED", true)
    if has_previous_skin {
      fallback_defines.set("HAS_PREVIOUS_SKIN", true)
    }
  }
  if morphed {
    fallback_defines.set("MORPH_TARGETS", true)
    if has_previous_morph {
      fallback_defines.set("HAS_PREVIOUS_MORPH", true)
    }
  }
  let defines = mesh3d_descriptor_shader_bool_defines(
    material_descriptor, fallback_defines,
  )
  let value_defines = mesh3d_forward_value_defines(
    descriptor=material_descriptor,
  )
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  let vertex_wgsl = if material_descriptor is Some(_) {
    load_wgsl_preprocessed(
      backend.assets_base,
      vertex_shader_path,
      defines,
      value_defines,
    )
  } else {
    fallback_wgsl()
  }
  let vertex_sm = backend.device.create_shader_module_wgsl(vertex_wgsl)
  let fragment_sm = match fragment_shader_path {
    Some(path) =>
      Some(
        backend.device.create_shader_module_wgsl(
          load_wgsl_preprocessed(
            backend.assets_base,
            if path == "" {
              MESH3D_PREPASS_VERTEX_SHADER_PATH
            } else {
              path
            },
            defines,
            value_defines,
          ),
        ),
      )
    None =>
      if material_descriptor is Some(_) {
        None
      } else {
        Some(backend.device.create_shader_module_wgsl(fallback_wgsl()))
      }
  }
  let descriptor_vertex_layout = mesh3d_descriptor_vertex_buffer_layout(
    material_descriptor,
  )
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      vertex_sm,
      layout=pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    match fragment_sm {
      Some(fragment_module) => {
        builder.set_fragment_module(fragment_module)
        mesh3d_descriptor_fragment_targets(builder, material_descriptor)
      }
      None => builder.clear_fragment()
    }
    builder.disable_blend()
    match descriptor_vertex_layout {
      Some(layout) => {
        builder.set_vertex_buffer_layout(
          layout.array_stride.to_uint64(),
          mesh_vertex_step_mode_to_wgpu(layout.step_mode),
        )
        for attribute in layout.attributes {
          builder.add_vertex_attribute(
            mesh_vertex_format_to_wgpu(attribute.format),
            attribute.offset.to_uint64(),
            attribute.shader_location.reinterpret_as_uint(),
          )
        }
      }
      None => {
        builder.set_vertex_buffer_layout(
          MESH3D_VERTEX_STRIDE_BYTES,
          @wgpu.VERTEX_STEP_MODE_VERTEX,
        )
        builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
        builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 1U)
        if skinned {
          builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_UINT32X4, 48UL, 5U)
          builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 64UL, 6U)
        }
      }
    }
    builder.set_topology_u32(topology)
    builder.set_multisample(msaa_sample_count.reinterpret_as_uint())
    builder.set_depth_stencil(
      tf(mesh3d_descriptor_depth_format(material_descriptor)),
      depth_write_enabled=mesh3d_descriptor_depth_write_enabled(
        material_descriptor, true,
      ),
      depth_compare_u32=mesh3d_descriptor_depth_compare(material_descriptor),
    )
    builder.set_cull_mode_u32(mesh3d_cull_mode_wgpu(cull_mode))
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      vertex_sm.release()
      match fragment_sm {
        Some(fragment_module) => fragment_module.release()
        None => ()
      }
      fatal(
        "wgpu: failed to build canonical mesh3d motion vector prepass pipeline",
      )
    }
  }
  pipeline.set_label(label)
  vertex_sm.release()
  match fragment_sm {
    Some(fragment_module) => fragment_module.release()
    None => ()
  }
  pipeline
}

///|
fn ensure_mesh3d_motion_vector_pipeline(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.mesh3d_motion_vector_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(2U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(
        14U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_STORAGE,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_view_bgl",
    )
    let empty_bgl = backend.device.create_bind_group_layout_uniform_buffer()
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
    let mesh_ok = mesh_builder.add_buffer(
        0U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_PREPASS_MESH_BUFFER_SIZE,
      ) &&
      mesh_builder.add_buffer(
        1U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
      ) &&
      mesh_builder.add_buffer(
        6U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
      )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector mesh bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_mesh_bgl",
    )
    let pl = create_pipeline_layout_3(
      backend.device,
      view_bgl,
      empty_bgl,
      mesh_bgl,
    )
    backend.mesh3d_motion_vector_bgl_view = Some(view_bgl)
    backend.mesh3d_motion_vector_bgl_empty = Some(empty_bgl)
    backend.mesh3d_motion_vector_bgl_mesh = Some(mesh_bgl)
    backend.mesh3d_motion_vector_pipeline_layout = Some(pl)
  }
  if backend.mesh3d_motion_vector_view_buf is None ||
    backend.mesh3d_motion_vector_globals_buf is None ||
    backend.mesh3d_motion_vector_previous_view_buf is None ||
    backend.mesh3d_motion_vector_visibility_ranges_buf is None ||
    backend.mesh3d_motion_vector_view_bg is None ||
    backend.mesh3d_motion_vector_empty_bg is None {
    guard backend.mesh3d_motion_vector_bgl_view is Some(view_bgl) else {
      return
    }
    guard backend.mesh3d_motion_vector_bgl_empty is Some(empty_bgl) else {
      return
    }
    let uniform_usage = bu(
      @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let storage_usage = bu(
      @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let view_buf = backend.device.create_buffer(
      size=MESH2D_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let previous_view_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let visibility_ranges_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      usage=storage_usage,
    )
    backend.queue.write_buffer(
      globals_buf,
      0UL,
      mesh3d_motion_vector_globals_uniform_bytes(),
    )
    backend.queue.write_buffer(
      visibility_ranges_buf,
      0UL,
      mesh3d_motion_vector_visibility_ranges_bytes(),
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE) &&
      builder.add_buffer(
        1U,
        globals_buf,
        size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        previous_view_buf,
        size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        14U,
        visibility_ranges_buf,
        size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    if !ok {
      builder.free()
      return
    }
    let view_bg = builder.finish(
      backend.device,
      view_bgl,
      label="mgstudio_motion_vector_view_bg",
    )
    let empty_bg = backend.device.create_bind_group_uniform_buffer(
      empty_bgl, globals_buf,
    )
    backend.mesh3d_motion_vector_view_buf = Some(view_buf)
    backend.mesh3d_motion_vector_globals_buf = Some(globals_buf)
    backend.mesh3d_motion_vector_previous_view_buf = Some(previous_view_buf)
    backend.mesh3d_motion_vector_visibility_ranges_buf = Some(
      visibility_ranges_buf,
    )
    backend.mesh3d_motion_vector_view_bg = Some(view_bg)
    backend.mesh3d_motion_vector_empty_bg = Some(empty_bg)
  }
  if backend.mesh3d_motion_vector_pipeline is Some(_) &&
    backend.mesh3d_motion_vector_pipeline_skinned is Some(_) &&
    backend.mesh3d_motion_vector_pipeline_skinned_prev is Some(_) {
    return
  }
  guard backend.mesh3d_motion_vector_pipeline_layout is Some(pipeline_layout) else {
    return
  }
  backend.mesh3d_motion_vector_pipeline = Some(
    mesh3d_build_motion_vector_pipeline(
      backend,
      pipeline_layout,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      1,
      None,
      2,
      false,
      false,
      false,
      false,
      "mgstudio_motion_vector_prepass",
    ),
  )
  backend.mesh3d_motion_vector_pipeline_skinned = Some(
    mesh3d_build_motion_vector_pipeline(
      backend,
      pipeline_layout,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      1,
      None,
      2,
      true,
      false,
      false,
      false,
      "mgstudio_motion_vector_prepass_skinned",
    ),
  )
  backend.mesh3d_motion_vector_pipeline_skinned_prev = Some(
    mesh3d_build_motion_vector_pipeline(
      backend,
      pipeline_layout,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      1,
      None,
      2,
      true,
      true,
      false,
      false,
      "mgstudio_motion_vector_prepass_skinned_previous",
    ),
  )
}

///|
fn mesh3d_motion_vector_pipeline_entry_get_or_create(
  backend : GpuBackend,
  topology : UInt,
  msaa_sample_count : Int,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  cull_mode : Int,
  skinned : Bool,
  has_previous_skin : Bool,
  morphed : Bool,
  has_previous_morph : Bool,
) -> Mesh3dMotionVectorPipelineCacheEntry? raise GpuBackendError {
  ensure_mesh3d_motion_vector_pipeline(backend)
  if mesh3d_motion_vector_pipeline_get(
      backend, topology, material_pipeline_id, msaa_sample_count, cull_mode, skinned,
      has_previous_skin, morphed, has_previous_morph,
    )
    is Some(entry) {
    return Some(entry)
  }
  let (mesh_layout_descriptor, mesh_bgl, pipeline_layout) = match
    material_descriptor {
    Some(_) => {
      let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
        backend, material_pipeline_id, material_descriptor,
      )
      (
        layout_entry.draw_bind_group_layout_descriptor,
        layout_entry.draw_bind_group_layout,
        layout_entry.pipeline_layout,
      )
    }
    None => {
      guard backend.mesh3d_motion_vector_bgl_view is Some(view_bgl) else {
        return None
      }
      guard backend.mesh3d_motion_vector_bgl_empty is Some(empty_bgl) else {
        return None
      }
      let mesh_layout_descriptor = mesh3d_motion_vector_mesh_layout_descriptor(
        skinned, has_previous_skin, morphed, has_previous_morph,
      )
      let layout_mask = mesh3d_motion_vector_mesh_layout_mask(
        skinned, has_previous_skin, morphed, has_previous_morph,
      )
      let mesh_bgl = mesh3d_create_bind_group_layout_from_descriptor(
        backend,
        mesh_layout_descriptor,
        "motion_vector_\{layout_mask}",
      )
      let pipeline_layout = create_pipeline_layout_3(
        backend.device,
        view_bgl,
        empty_bgl,
        mesh_bgl,
      )
      (mesh_layout_descriptor, mesh_bgl, pipeline_layout)
    }
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let layout_mask = mesh3d_motion_vector_mesh_layout_mask(
    skinned, has_previous_skin, morphed, has_previous_morph,
  )
  let label = "mgstudio_motion_vector_prepass_layout_\{layout_mask}"
  let pipeline = mesh3d_build_motion_vector_pipeline(
    backend, pipeline_layout, topology, msaa_sample_count, material_descriptor, safe_cull_mode,
    skinned, has_previous_skin, morphed, has_previous_morph, label,
  )
  let entry = Mesh3dMotionVectorPipelineCacheEntry::{
    topology,
    material_pipeline_id,
    msaa_sample_count,
    cull_mode: safe_cull_mode,
    skinned,
    has_previous_skin,
    morphed,
    has_previous_morph,
    mesh_bind_group_layout_descriptor: mesh_layout_descriptor,
    mesh_bind_group_layout: mesh_bgl,
    pipeline,
  }
  mesh3d_motion_vector_pipeline_set(backend, entry)
  Some(entry)
}
