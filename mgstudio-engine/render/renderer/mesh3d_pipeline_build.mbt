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
fn mesh3d_shader_path_or_default(shader_path : String?) -> String {
  match shader_path {
    Some(path) => if path == "" { MESH3D_FORWARD_SHADER_PATH } else { path }
    None => MESH3D_FORWARD_SHADER_PATH
  }
}

///|
fn mesh3d_custom_pipeline_cache_get(
  backend : GpuBackend,
  shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_custom_pipeline_cache {
    if entry.shader_path != shader_path {
      continue
    }
    if entry.topology != topology ||
      entry.transparent != transparent ||
      entry.blend_kind != blend_kind ||
      entry.forward_decal != forward_decal ||
      entry.cull_mode != safe_cull_mode {
      continue
    }
    if entry.surface_format == surface_format {
      return Some(entry.pipeline)
    }
  }
  None
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
fn mesh3d_custom_pipeline_get_or_create(
  backend : GpuBackend,
  shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  blend_kind : Int,
  forward_decal : Bool,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_shader_path = mesh3d_shader_path_or_default(Some(shader_path))
  if resolved_shader_path == MESH3D_FORWARD_SHADER_PATH && !forward_decal {
    return None
  }
  if mesh3d_custom_pipeline_cache_get(
      backend, resolved_shader_path, surface_format, topology, transparent, blend_kind,
      forward_decal, cull_mode,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode, blend_kind)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return None }
  let shader_source = load_wgsl_required_mesh3d_forward_decal_pipeline(
    backend.assets_base,
    resolved_shader_path,
    forward_decal,
  )
  let shader_module = backend.device.create_shader_module_wgsl(shader_source)
  let color_format = match surface_format {
    Some(format) => format.to_u32()
    None => @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
  }
  let descriptor = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    shader_module,
    color_format,
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
  let pipeline = backend.device.create_render_pipeline_ptr(descriptor)
  @wgpu_c.render_pipeline_descriptor_free(descriptor)
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
    "_shader_" +
    resolved_shader_path,
  )
  backend.mesh3d_custom_pipeline_cache.push(Mesh3dCustomPipelineCacheEntry::{
    shader_path: resolved_shader_path,
    surface_format,
    topology,
    transparent,
    blend_kind,
    forward_decal,
    cull_mode: safe_cull_mode,
    pipeline,
  })
  shader_module.release()
  Some(pipeline)
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=11UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_texture(
        1U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        2U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      view_builder.add_texture(
        3U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      view_builder.add_sampler(
        4U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      ) &&
      view_builder.add_texture(
        5U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        6U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      view_builder.add_texture(
        7U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        8U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      view_builder.add_texture(
        9U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
      ) &&
      view_builder.add_sampler(
        10U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
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
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=16UL)
    let material_ok = material_builder.add_texture(
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
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      view_stage,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      min_binding_size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d draw bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_draw_bgl",
    )
    let skin_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let skin_ok = skin_builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX),
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      min_binding_size=64UL,
    )
    if !skin_ok {
      skin_builder.free()
      fatal("wgpu: failed to build mesh3d skin bind group layout")
    }
    let skin_bgl = skin_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_skin_bgl",
    )
    let pl = create_pipeline_layout_4(
      backend.device,
      view_bgl,
      material_bgl,
      mesh_bgl,
      skin_bgl,
    )
    backend.mesh3d_bgl_view = Some(view_bgl)
    backend.mesh3d_bgl_draw = Some(mesh_bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_bgl_skin = Some(skin_bgl)
    backend.mesh3d_pipeline_layout = Some(pl)
    if backend.mesh3d_view_buf is None {
      backend.mesh3d_view_buf = Some(
        backend.device.create_buffer(
          size=MESH3D_VIEW_BUFFER_SIZE,
          usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
        ),
      )
    }
    mesh3d_material_cache_clear(backend)
    mesh3d_custom_pipeline_cache_clear(backend)
    mesh3d_pipeline_cache_clear(backend)
    ensure_mesh3d_skin_current_binding(backend) |> ignore
  }
  if backend.mesh3d_view_buf is None {
    backend.mesh3d_view_buf = Some(
      backend.device.create_buffer(
        size=MESH3D_VIEW_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
  let color_format = tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32()
  if mesh3d_pipeline_get(
      backend, color_format, topology, safe_cull_mode, blend_kind,
    )
    is Some(_) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    color_format,
    with_depth=true,
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  let blend_suffix = mesh3d_pipeline_blend_suffix(blend_kind)
  pipeline.set_label(
    "mgstudio_mesh3d_rgba8_" +
    blend_suffix +
    "_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set(
    backend, color_format, topology, safe_cull_mode, blend_kind, pipeline,
  )
  sm.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  cull_mode : Int,
  blend_kind : Int,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh3d pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode, blend_kind)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let color_format = format.to_u32()
  if mesh3d_pipeline_get(
      backend, color_format, topology, safe_cull_mode, blend_kind,
    )
    is Some(_) {
    return
  }
  let transparent = blend_kind != MESH3D_PIPELINE_BLEND_OPAQUE
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    color_format,
    with_depth=true,
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    alpha_blend=transparent,
    blend_kind~,
  )
  let pipeline = backend.device.create_render_pipeline_ptr(desc)
  @wgpu_c.render_pipeline_descriptor_free(desc)
  let blend_suffix = mesh3d_pipeline_blend_suffix(blend_kind)
  pipeline.set_label(
    "mgstudio_mesh3d_surface_" +
    blend_suffix +
    "_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set(
    backend, color_format, topology, safe_cull_mode, blend_kind, pipeline,
  )
  sm.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  material_flags : UInt,
  forward_decal : Bool,
  topology : UInt,
  cull_mode : Int,
  shader_path : String?,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_shader_path = mesh3d_shader_path_or_default(shader_path)
  let blend_kind = mesh3d_blend_kind_from_material_flags(
    material_flags, transparent,
  )
  if resolved_shader_path != MESH3D_FORWARD_SHADER_PATH || forward_decal {
    let custom_surface_format = match current_pass_color_format(backend) {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) =>
        Some(format)
      _ => None
    }
    return mesh3d_custom_pipeline_get_or_create(
      backend, resolved_shader_path, custom_surface_format, topology, transparent,
      blend_kind, forward_decal, cull_mode,
    )
  }
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(
        backend, format, topology, cull_mode, blend_kind,
      )
      return mesh3d_pipeline_get(
        backend,
        format.to_u32(),
        topology,
        cull_mode,
        blend_kind,
      )
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode, blend_kind)
  mesh3d_pipeline_get(
    backend,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM).to_u32(),
    topology,
    cull_mode,
    blend_kind,
  )
}

///|
fn mesh3d_build_shadow_depth_pipeline(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  ensure_mesh3d_pipeline_rgba8(
    backend,
    topology,
    cull_mode,
    MESH3D_PIPELINE_BLEND_OPAQUE,
  )
  guard backend.mesh3d_pipeline_layout is Some(pl) else {
    fatal("wgpu: missing mesh3d pipeline layout for shadow depth pipeline")
  }
  let wgsl_source = if material_path {
    mesh3d_shadow_depth_wgsl_source
  } else {
    mesh3d_shadow_depth_only_wgsl_source
  }
  let sm = backend.device.create_shader_module_wgsl(wgsl_source)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout=pl)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_count(1U)
    builder.set_color_target_format_at(0U, tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM))
    builder.set_color_target_write_mask_at(0U, @wgpu.COLOR_WRITE_MASK_NONE)
    builder.disable_blend()
    builder.set_vertex_buffer_layout(
      MESH3D_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 3U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 48UL, 4U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 64UL, 5U)
    builder.set_topology_u32(topology)
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
        "wgpu: failed to build canonical mesh3d shadow depth pipeline: \{err.message()}",
      )
    }
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let shadow_pipeline_suffix = if material_path {
    "material_"
  } else {
    "depth_only_"
  }
  pipeline.set_label(
    "mgstudio_mesh3d_shadow_" +
    shadow_pipeline_suffix +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  sm.release()
  pipeline
}

///|
fn mesh3d_shadow_depth_pipeline_for_current_pass(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
  material_path : Bool,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  if mesh3d_shadow_pipeline_get(backend, topology, cull_mode, material_path)
    is Some(pipeline) {
    return Some(pipeline)
  }
  let pipeline = mesh3d_build_shadow_depth_pipeline(
    backend, topology, cull_mode, material_path,
  )
  mesh3d_shadow_pipeline_set(
    backend, topology, cull_mode, material_path, pipeline,
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
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 3U)
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
