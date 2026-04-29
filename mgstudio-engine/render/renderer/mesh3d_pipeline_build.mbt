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
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
) -> String {
  let surface_bits = match surface_format {
    Some(format) => format.raw.to_string()
    None => "-1"
  }
  let transparent_bits = if transparent { "1" } else { "0" }
  let forward_decal_bits = if forward_decal { "1" } else { "0" }
  "\{surface_bits}|\{topology}|\{transparent_bits}|\{blend_kind}|\{forward_decal_bits}|\{mesh3d_cull_mode_sanitize(cull_mode)}|\{vertex_shader_path}|\{fragment_shader_path}"
}

///|
fn mesh3d_custom_pipeline_cache_get(
  backend : GpuBackend,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? {
  let cache_key = mesh3d_custom_pipeline_cache_key(
    vertex_shader_path, fragment_shader_path, surface_format, topology, transparent,
    blend_kind, forward_decal, cull_mode,
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
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
) -> Bool {
  let cache_key = mesh3d_custom_pipeline_cache_key(
    vertex_shader_path, fragment_shader_path, surface_format, topology, transparent,
    blend_kind, forward_decal, cull_mode,
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
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
  message : String,
) -> Unit {
  if mesh3d_custom_pipeline_cache_get(
      backend, vertex_shader_path, fragment_shader_path, surface_format, topology,
      transparent, blend_kind, forward_decal, cull_mode,
    )
    is Some(_) {
    return
  }
  if mesh3d_custom_pipeline_cache_failed(
      backend, vertex_shader_path, fragment_shader_path, surface_format, topology,
      transparent, blend_kind, forward_decal, cull_mode,
    ) {
    return
  }
  let cache_key = mesh3d_custom_pipeline_cache_key(
    vertex_shader_path, fragment_shader_path, surface_format, topology, transparent,
    blend_kind, forward_decal, cull_mode,
  )
  backend.mesh3d_custom_pipeline_cache[cache_key] = RenderPipelineErr(message)
}

///|
fn load_wgsl_required_mesh3d_forward_decal_pipeline(
  assets_base : String,
  shader_path : String,
  forward_decal : Bool,
) -> String raise GpuBackendError {
  if !forward_decal {
    return load_wgsl_from_assets_base_required(assets_base, shader_path)
  }
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("FORWARD_DECAL", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, shader_path, defines, value_defines, visited, modules,
  )
}

///|
fn mesh3d_forward_shader_defines(
  skinned : Bool,
  forward_decal : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
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
  if forward_decal {
    defines.set("FORWARD_DECAL", true)
  }
  defines
}

///|
fn mesh3d_forward_value_defines() -> @hashmap.HashMap[String, Int] {
  let value_defines = default_wgsl_value_defines()
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  value_defines
}

///|
fn mesh3d_shadow_shader_defines(
  skinned : Bool,
  material_path : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_PIPELINE", true)
  defines.set("DEPTH_PREPASS", true)
  defines.set("VERTEX_POSITIONS", true)
  defines.set("VERTEX_UVS", true)
  defines.set("VERTEX_UVS_A", true)
  defines.set("VERTEX_COLORS", true)
  defines.set("VERTEX_OUTPUT_INSTANCE_INDEX", true)
  if skinned {
    defines.set("SKINNED", true)
  }
  if material_path {
    defines.set("MAY_DISCARD", true)
  }
  defines
}

///|
fn load_wgsl_required_mesh3d_shadow_pipeline(
  assets_base : String,
  skinned : Bool,
  material_path : Bool,
  shader_path : String,
) -> String raise GpuBackendError {
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base,
    shader_path,
    mesh3d_shadow_shader_defines(skinned, material_path),
    mesh3d_forward_value_defines(),
    visited,
    modules,
  )
}

///|
fn load_wgsl_required_mesh3d_forward_pipeline(
  assets_base : String,
  skinned : Bool,
  forward_decal : Bool,
  shader_path : String,
) -> String raise GpuBackendError {
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base,
    shader_path,
    mesh3d_forward_shader_defines(skinned, forward_decal),
    mesh3d_forward_value_defines(),
    visited,
    modules,
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
  skinned : Bool,
  forward_decal : Bool,
  label_prefix : String,
) -> Mesh3dForwardShaderModules raise GpuBackendError {
  let vertex_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    skinned,
    forward_decal,
    MESH3D_FORWARD_VERTEX_SHADER_PATH,
  )
  let fragment_wgsl = load_wgsl_required_mesh3d_forward_pipeline(
    backend.assets_base,
    skinned,
    forward_decal,
    MESH3D_FORWARD_SHADER_PATH,
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
  let message = result.message.trim().to_string()
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
fn mesh3d_create_uniform_buffer_init(
  backend : GpuBackend,
  size : UInt64,
  initial_bytes : Bytes,
) -> @wgpu.Buffer {
  let buffer = mesh3d_create_uniform_buffer(backend, size)
  backend.queue.write_buffer(buffer, 0UL, initial_bytes)
  buffer
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
fn mesh3d_environment_map_identity_uniform_bytes() -> Bytes {
  f32le_pack([
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 1.0F,
  ])
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
  if backend.mesh3d_environment_map_uniform_buf is None {
    backend.mesh3d_environment_map_uniform_buf = Some(
      mesh3d_create_uniform_buffer_init(
        backend,
        MESH3D_ENVIRONMENT_MAP_UNIFORM_BUFFER_SIZE,
        mesh3d_environment_map_identity_uniform_bytes(),
      ),
    )
  }
}

///|
fn mesh3d_custom_pipeline_get_or_create(
  backend : GpuBackend,
  vertex_shader_path : String,
  fragment_shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
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
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
      topology, transparent, blend_kind, forward_decal, cull_mode,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  if mesh3d_custom_pipeline_cache_failed(
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
      topology, transparent, blend_kind, forward_decal, cull_mode,
    ) {
    return None
  }
  ensure_mesh3d_pipeline_layout_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return None }
  let vertex_shader_source = load_wgsl_required_mesh3d_forward_decal_pipeline(
    backend.assets_base,
    resolved_vertex_shader_path,
    forward_decal,
  ) catch {
    Fatal(message) => {
      mesh3d_custom_pipeline_cache_set_failed(
        backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
        topology, transparent, blend_kind, forward_decal, safe_cull_mode, message,
      )
      debug("[renderer] mesh3d custom pipeline failed: \{message}")
      return None
    }
  }
  let fragment_shader_source = load_wgsl_required_mesh3d_forward_decal_pipeline(
    backend.assets_base,
    resolved_fragment_shader_path,
    forward_decal,
  ) catch {
    Fatal(message) => {
      mesh3d_custom_pipeline_cache_set_failed(
        backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
        topology, transparent, blend_kind, forward_decal, safe_cull_mode, message,
      )
      debug("[renderer] mesh3d custom pipeline failed: \{message}")
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
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
      topology, transparent, blend_kind, forward_decal, safe_cull_mode, message,
    )
    debug("[renderer] mesh3d custom pipeline failed: \{message}")
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
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
      topology, transparent, blend_kind, forward_decal, safe_cull_mode, message,
    )
    debug("[renderer] mesh3d custom pipeline failed: \{message}")
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
      @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
    },
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
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format,
      topology, transparent, blend_kind, forward_decal, safe_cull_mode, message,
    )
    debug("[renderer] mesh3d custom pipeline failed: \{message}")
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
    resolved_vertex_shader_path, resolved_fragment_shader_path, surface_format, topology,
    transparent, blend_kind, forward_decal, safe_cull_mode,
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
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=19UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(
        8U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_CLUSTERED_LIGHTS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        9U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_CLUSTERABLE_OBJECT_INDEX_LISTS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        10U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_CLUSTER_OFFSETS_AND_COUNTS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        11U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_GLOBALS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        12U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_FOG_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        13U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_LIGHT_PROBES_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        14U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
        min_binding_size=MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        15U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_SSR_SETTINGS_BUFFER_SIZE,
      ) &&
      view_builder.add_buffer(
        16U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_CONTACT_SHADOWS_SETTINGS_BUFFER_SIZE,
      ) &&
      view_builder.add_texture(
        17U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_buffer(
        18U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_ENVIRONMENT_MAP_UNIFORM_BUFFER_SIZE,
      ) &&
      view_builder.add_texture(
        2U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      view_builder.add_sampler(
        3U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      ) &&
      view_builder.add_texture(
        5U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
      ) &&
      view_builder.add_sampler(
        6U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      ) &&
      view_builder.add_texture(
        25U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        26U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
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
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=17UL)
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
      ) &&
      material_builder.add_texture(
        13U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        14U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        29U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        30U,
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
      max_entries=3UL,
    )
    let binding_arrays_ok = binding_arrays_builder.add_texture(
        0U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      binding_arrays_builder.add_texture(
        1U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      binding_arrays_builder.add_sampler(
        2U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
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
    ensure_mesh3d_skin_buffers(backend, MESH3D_SKINNING_STORAGE_STRIDE_BYTES)
    |> ignore
  }
  ensure_mesh3d_view_binding_buffers(backend)
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
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let color_format = tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32()
  if mesh3d_pipeline_get(
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    ) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let modules = mesh3d_create_forward_shader_modules(
    backend, skinned, forward_decal, "mesh3d rgba8",
  ) catch {
    Fatal(message) => {
      mesh3d_pipeline_set_failed(
        backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
        message,
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
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
    vertex_entry="vertex",
    fragment_entry="fragment",
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
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
      message,
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
    backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    pipeline,
  )
  modules.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
  skinned : Bool,
  forward_decal : Bool,
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
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    )
    is Some(_) {
    return
  }
  if mesh3d_pipeline_failed(
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    ) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let modules = mesh3d_create_forward_shader_modules(
    backend, skinned, forward_decal, "mesh3d surface",
  ) catch {
    Fatal(message) => {
      mesh3d_pipeline_set_failed(
        backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
        message,
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
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
    vertex_entry="vertex",
    fragment_entry="fragment",
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
      backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
      message,
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
    backend, color_format, topology, safe_cull_mode, blend_kind, skinned, forward_decal,
    pipeline,
  )
  modules.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  material_flags : UInt,
  forward_decal : Bool,
  topology : UInt,
  cull_mode : Int,
  vertex_shader_path : String?,
  fragment_shader_path : String?,
  skinned : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_vertex_shader_path = mesh3d_vertex_shader_path_or_default(
    vertex_shader_path,
  )
  let resolved_fragment_shader_path = mesh3d_fragment_shader_path_or_default(
    fragment_shader_path,
  )
  let blend_kind = mesh3d_blend_kind_from_material_flags(
    material_flags, transparent,
  )
  if resolved_vertex_shader_path != MESH3D_FORWARD_VERTEX_SHADER_PATH ||
    resolved_fragment_shader_path != MESH3D_FORWARD_SHADER_PATH {
    let custom_surface_format = match current_pass_color_format(backend) {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) =>
        Some(format)
      _ => None
    }
    return mesh3d_custom_pipeline_get_or_create(
      backend, resolved_vertex_shader_path, resolved_fragment_shader_path, custom_surface_format,
      topology, transparent, blend_kind, forward_decal, cull_mode,
    )
  }
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(
        backend, format, topology, cull_mode, blend_kind, skinned, forward_decal,
      )
      return mesh3d_pipeline_get(
        backend,
        format.to_u32(),
        topology,
        cull_mode,
        blend_kind,
        skinned,
        forward_decal,
      )
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(
    backend, topology, cull_mode, blend_kind, skinned, forward_decal,
  )
  mesh3d_pipeline_get(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32(),
    topology,
    cull_mode,
    blend_kind,
    skinned,
    forward_decal,
  )
}

///|
fn mesh3d_build_shadow_depth_pipeline(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  let pipeline_layout = if material_path {
    backend.mesh3d_shadow_pipeline_layout_material
  } else {
    backend.mesh3d_shadow_pipeline_layout_depth_only
  }
  guard pipeline_layout is Some(pl) else {
    fatal("wgpu: missing mesh3d pipeline layout for shadow depth pipeline")
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  let vertex_wgsl = load_wgsl_required_mesh3d_shadow_pipeline(
    backend.assets_base,
    skinned,
    material_path,
    MESH3D_PREPASS_VERTEX_SHADER_PATH,
  )
  let vertex_sm = backend.device.create_shader_module_wgsl(vertex_wgsl)
  let fragment_sm = if material_path {
    Some(
      backend.device.create_shader_module_wgsl(
        load_wgsl_required_mesh3d_shadow_pipeline(
          backend.assets_base,
          skinned,
          material_path,
          MESH3D_PREPASS_MATERIAL_FRAGMENT_SHADER_PATH,
        ),
      ),
    )
  } else {
    None
  }
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(vertex_sm, layout=pl)
    builder.set_entry_points("vertex", "fragment")
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
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 7U)
    builder.set_topology_u32(topology)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=true,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    let desc = builder.finish_descriptor_ptr()
    render_pipeline_descriptor_set_cull_mode(desc, cull_mode_wgpu)
    match fragment_sm {
      Some(fragment_module) => {
        render_pipeline_descriptor_set_fragment_module(desc, fragment_module)
        render_pipeline_descriptor_set_fragment_target_count_zero(desc)
      }
      None => render_pipeline_descriptor_clear_fragment(desc)
    }
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
  pipeline.set_label(
    "mgstudio_mesh3d_shadow_" +
    shadow_pipeline_suffix +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    skinned_suffix,
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
  cull_mode : Int,
  material_path : Bool,
  skinned : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  if mesh3d_shadow_pipeline_get(
      backend, topology, cull_mode, material_path, skinned,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  let pipeline = mesh3d_build_shadow_depth_pipeline(
    backend, topology, cull_mode, material_path, skinned,
  )
  mesh3d_shadow_pipeline_set(
    backend, topology, cull_mode, material_path, skinned, pipeline,
  )
  Some(pipeline)
}

///|
fn mesh3d_build_motion_vector_pipeline(
  backend : GpuBackend,
  pipeline_layout : @wgpu.PipelineLayout,
  skinned : Bool,
  has_previous_skin : Bool,
  label : String,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let wgsl = load_wgsl_required_mesh3d_motion_vector_prepass(
    backend.assets_base,
    skinned,
    has_previous_skin,
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(
      sm,
      layout=pipeline_layout,
    )
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_count(2U)
    builder.set_color_target_format_at(
      0U,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    )
    builder.set_color_target_format_at(1U, tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT))
    builder.set_color_target_write_mask_at(0U, @wgpu.COLOR_WRITE_MASK_NONE)
    builder.set_color_target_write_mask_at(1U, @wgpu.COLOR_WRITE_MASK_ALL)
    builder.disable_blend()
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
    builder.set_topology_u32(@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=true,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      sm.release()
      fatal(
        "wgpu: failed to build canonical mesh3d motion vector prepass pipeline: \{err.message()}",
      )
    }
  }
  pipeline.set_label(label)
  sm.release()
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
      backend, pipeline_layout, false, false, "mgstudio_motion_vector_prepass",
    ),
  )
  backend.mesh3d_motion_vector_pipeline_skinned = Some(
    mesh3d_build_motion_vector_pipeline(
      backend, pipeline_layout, true, false, "mgstudio_motion_vector_prepass_skinned",
    ),
  )
  backend.mesh3d_motion_vector_pipeline_skinned_prev = Some(
    mesh3d_build_motion_vector_pipeline(
      backend, pipeline_layout, true, true, "mgstudio_motion_vector_prepass_skinned_previous",
    ),
  )
}
