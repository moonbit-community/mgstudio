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
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_view_bg_cache {
    entry.bind_group.release()
  }
  backend.mesh3d_view_bg_cache.clear()
  for entry in backend.mesh3d_material_bg_cache {
    entry.bind_group.release()
    entry.material_uniform_buffer.release()
  }
  backend.mesh3d_material_bg_cache.clear()
}

///|
fn ensure_mesh3d_point_shadow_compare_sampler(
  backend : GpuBackend,
) -> @wgpu.Sampler {
  match backend.mesh3d_point_shadow_compare_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.MIPMAP_FILTER_MODE_NEAREST,
        compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      )
      backend.mesh3d_point_shadow_compare_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_layout_binding_count(
  entry : @render_resource.BindGroupLayoutEntry,
) -> Int {
  if entry.count() > 1 {
    entry.count()
  } else {
    1
  }
}

///|
fn mesh3d_repeated_texture_views(
  view : @wgpu.TextureView,
  count : Int,
) -> Array[@wgpu.TextureView] {
  let views : Array[@wgpu.TextureView] = []
  for _ in 0..<count {
    views.push(view)
  }
  views
}

///|
fn mesh3d_repeated_samplers(
  sampler : @wgpu.Sampler,
  count : Int,
) -> Array[@wgpu.Sampler] {
  let samplers : Array[@wgpu.Sampler] = []
  for _ in 0..<count {
    samplers.push(sampler)
  }
  samplers
}

///|
fn mesh3d_add_texture_view_for_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  binding : UInt,
  view : @wgpu.TextureView,
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  let count = mesh3d_layout_binding_count(entry)
  if count > 1 {
    builder.add_texture_view_array(
      binding,
      mesh3d_repeated_texture_views(view, count),
    )
  } else {
    builder.add_texture_view(binding, view)
  }
}

///|
fn mesh3d_add_sampler_for_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  binding : UInt,
  sampler : @wgpu.Sampler,
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  let count = mesh3d_layout_binding_count(entry)
  if count > 1 {
    builder.add_sampler_array(binding, mesh3d_repeated_samplers(sampler, count))
  } else {
    builder.add_sampler(binding, sampler)
  }
}

///|
fn mesh3d_finish_bind_group_checked(
  backend : GpuBackend,
  builder : @wgpu.BindGroupBuilder,
  layout : @wgpu.BindGroupLayout,
  label : String,
  error_message : String,
) -> @wgpu.BindGroup raise GpuBackendError {
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let bind_group = builder.finish(backend.device, layout, label~)
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(result, error_message)
    bind_group.release()
    fatal(message)
  }
  bind_group
}

///|
fn mesh3d_add_view_bind_group_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  entry : @render_resource.BindGroupLayoutEntry,
  view_buf : @wgpu.Buffer,
  lights_buf : @wgpu.Buffer,
  clustered_lights_buf : @wgpu.Buffer,
  clusterable_object_index_lists_buf : @wgpu.Buffer,
  cluster_offsets_and_counts_buf : @wgpu.Buffer,
  globals_buf : @wgpu.Buffer,
  fog_buf : @wgpu.Buffer,
  light_probes_buf : @wgpu.Buffer,
  visibility_ranges_buf : @wgpu.Buffer,
  ssr_settings_buf : @wgpu.Buffer,
  contact_shadows_settings_buf : @wgpu.Buffer,
  point_shadow_sample_view : @wgpu.TextureView,
  point_shadow_compare_sampler : @wgpu.Sampler,
  directional_shadow_sample_view : @wgpu.TextureView,
  transmission_source_texture : GpuTextureInfo,
  dt_lut_sample_view : @wgpu.TextureView,
  dt_lut_sampler : @wgpu.Sampler,
) -> Bool {
  if entry.binding() < 0 {
    return false
  }
  let binding = entry.binding().reinterpret_as_uint()
  match entry.binding() {
    0 => builder.add_buffer(binding, view_buf, size=MESH3D_VIEW_BUFFER_SIZE)
    1 => builder.add_buffer(binding, lights_buf, size=MESH3D_LIGHTS_BUFFER_SIZE)
    2 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, point_shadow_sample_view, entry,
      )
    3 => builder.add_sampler(binding, point_shadow_compare_sampler)
    5 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, directional_shadow_sample_view, entry,
      )
    6 => builder.add_sampler(binding, point_shadow_compare_sampler)
    8 =>
      builder.add_buffer(
        binding,
        clustered_lights_buf,
        size=MESH3D_CLUSTERED_LIGHTS_BUFFER_SIZE,
      )
    9 =>
      builder.add_buffer(
        binding,
        clusterable_object_index_lists_buf,
        size=MESH3D_CLUSTERABLE_OBJECT_INDEX_LISTS_BUFFER_SIZE,
      )
    10 =>
      builder.add_buffer(
        binding,
        cluster_offsets_and_counts_buf,
        size=MESH3D_CLUSTER_OFFSETS_AND_COUNTS_BUFFER_SIZE,
      )
    11 =>
      builder.add_buffer(binding, globals_buf, size=MESH3D_GLOBALS_BUFFER_SIZE)
    12 =>
      builder.add_buffer(
        binding,
        light_probes_buf,
        size=MESH3D_LIGHT_PROBES_BUFFER_SIZE,
      )
    13 => builder.add_buffer(binding, fog_buf, size=MESH3D_FOG_BUFFER_SIZE)
    14 =>
      builder.add_buffer(
        binding,
        visibility_ranges_buf,
        size=MESH3D_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    15 =>
      builder.add_buffer(
        binding,
        ssr_settings_buf,
        size=MESH3D_SSR_SETTINGS_BUFFER_SIZE,
      )
    16 =>
      builder.add_buffer(
        binding,
        contact_shadows_settings_buf,
        size=MESH3D_CONTACT_SHADOWS_SETTINGS_BUFFER_SIZE,
      )
    18 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, dt_lut_sample_view, entry,
      )
    19 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, dt_lut_sampler, entry,
      )
    24 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder,
        binding,
        transmission_source_texture.view,
        entry,
      )
    25 =>
      mesh3d_add_sampler_for_layout_entry(
        builder,
        binding,
        transmission_source_texture.sampler,
        entry,
      )
    _ => false
  }
}

///|
fn mesh3d_build_view_bind_group_from_descriptor(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  view_buf : @wgpu.Buffer,
  lights_buf : @wgpu.Buffer,
  clustered_lights_buf : @wgpu.Buffer,
  clusterable_object_index_lists_buf : @wgpu.Buffer,
  cluster_offsets_and_counts_buf : @wgpu.Buffer,
  globals_buf : @wgpu.Buffer,
  fog_buf : @wgpu.Buffer,
  light_probes_buf : @wgpu.Buffer,
  visibility_ranges_buf : @wgpu.Buffer,
  ssr_settings_buf : @wgpu.Buffer,
  contact_shadows_settings_buf : @wgpu.Buffer,
  point_shadow_sample_view : @wgpu.TextureView,
  point_shadow_compare_sampler : @wgpu.Sampler,
  directional_shadow_sample_view : @wgpu.TextureView,
  transmission_source_texture : GpuTextureInfo,
  dt_lut_sample_view : @wgpu.TextureView,
  dt_lut_sampler : @wgpu.Sampler,
  error_message : String,
) -> @wgpu.BindGroup raise GpuBackendError {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=entries.length().to_uint64(),
  )
  for entry in entries {
    if !mesh3d_add_view_bind_group_layout_entry(
        builder, entry, view_buf, lights_buf, clustered_lights_buf, clusterable_object_index_lists_buf,
        cluster_offsets_and_counts_buf, globals_buf, fog_buf, light_probes_buf, visibility_ranges_buf,
        ssr_settings_buf, contact_shadows_settings_buf, point_shadow_sample_view,
        point_shadow_compare_sampler, directional_shadow_sample_view, transmission_source_texture,
        dt_lut_sample_view, dt_lut_sampler,
      ) {
      builder.free()
      fatal(
        error_message + ": unsupported binding " + entry.binding().to_string(),
      )
    }
  }
  mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_mesh3d_view_bg", error_message,
  )
}

///|
fn mesh3d_add_binding_array_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  entry : @render_resource.BindGroupLayoutEntry,
  environment_diffuse_sample_view : @wgpu.TextureView,
  environment_specular_sample_view : @wgpu.TextureView,
  environment_sampler : @wgpu.Sampler,
) -> Bool {
  if entry.binding() < 0 {
    return false
  }
  let binding = entry.binding().reinterpret_as_uint()
  match entry.binding() {
    0 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, environment_diffuse_sample_view, entry,
      )
    1 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, environment_specular_sample_view, entry,
      )
    2 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, environment_sampler, entry,
      )
    _ => false
  }
}

///|
fn mesh3d_build_binding_arrays_bind_group_from_descriptor(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  environment_diffuse_sample_view : @wgpu.TextureView,
  environment_specular_sample_view : @wgpu.TextureView,
  environment_sampler : @wgpu.Sampler,
  error_message : String,
) -> @wgpu.BindGroup raise GpuBackendError {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=entries.length().to_uint64(),
  )
  for entry in entries {
    if !mesh3d_add_binding_array_layout_entry(
        builder, entry, environment_diffuse_sample_view, environment_specular_sample_view,
        environment_sampler,
      ) {
      builder.free()
      fatal(
        error_message + ": unsupported binding " + entry.binding().to_string(),
      )
    }
  }
  mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_mesh3d_binding_arrays_bg", error_message,
  )
}

///|
fn mesh3d_view_bg_cache_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  tonemap_in_shader : Bool,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
  directional_shadow_texture : GpuTextureInfo,
  environment_diffuse_texture : GpuTextureInfo,
  environment_specular_texture : GpuTextureInfo,
  tonemapping_mode : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
) -> (@wgpu.BindGroup, @wgpu.BindGroup) raise GpuBackendError {
  let dt_lut_texture = tonemapping_selected_lut_texture(
    backend, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  for entry in backend.mesh3d_view_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id &&
      entry.directional_shadow_texture_id == directional_shadow_texture.id &&
      entry.environment_diffuse_texture_id == environment_diffuse_texture.id &&
      entry.environment_specular_texture_id == environment_specular_texture.id &&
      entry.tonemapping_lut_texture_id == dt_lut_texture.id {
      return (entry.bind_group, entry.binding_arrays_bind_group)
    }
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key=mesh3d_default_mesh_view_layout_key(
      tonemap_in_shader~,
    ),
  )
  let layout = layout_entry.view_bind_group_layout
  let layout_descriptor = layout_entry.view_bind_group_layout_descriptor
  let binding_arrays_layout = layout_entry.binding_arrays_bind_group_layout
  let binding_arrays_layout_descriptor = layout_entry.binding_arrays_bind_group_layout_descriptor
  let view_buf = match backend.mesh3d_view_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d view uniform buffer")
  }
  let lights_buf = match backend.mesh3d_lights_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d lights uniform buffer")
  }
  let clustered_lights_buf = match backend.mesh3d_clustered_lights_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d clustered lights buffer")
  }
  let clusterable_object_index_lists_buf = match
    backend.mesh3d_clusterable_object_index_lists_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d clusterable object index lists buffer")
  }
  let cluster_offsets_and_counts_buf = match
    backend.mesh3d_cluster_offsets_and_counts_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d cluster offsets and counts buffer")
  }
  let globals_buf = match backend.mesh3d_globals_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d globals buffer")
  }
  let fog_buf = match backend.mesh3d_fog_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d fog buffer")
  }
  let light_probes_buf = match backend.mesh3d_light_probes_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d light probes buffer")
  }
  let visibility_ranges_buf = match backend.mesh3d_visibility_ranges_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d visibility ranges buffer")
  }
  let ssr_settings_buf = match backend.mesh3d_ssr_settings_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d ssr settings buffer")
  }
  let contact_shadows_settings_buf = match
    backend.mesh3d_contact_shadows_settings_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d contact shadows settings buffer")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let dt_lut_sample_view = match dt_lut_texture.sample_view {
    Some(view) => view
    None => dt_lut_texture.view
  }
  let directional_shadow_sample_view = match
    directional_shadow_texture.sample_view {
    Some(view) => view
    None => directional_shadow_texture.view
  }
  let fallback_environment_texture = ensure_environment_map_fallback_texture(
    backend,
  )
  let fallback_environment_sample_view = match
    fallback_environment_texture.sample_view {
    Some(view) => view
    None => fallback_environment_texture.view
  }
  let environment_diffuse_sample_view = match
    environment_diffuse_texture.sample_view {
    Some(view) => view
    None => fallback_environment_sample_view
  }
  let environment_specular_sample_view = match
    environment_specular_texture.sample_view {
    Some(view) => view
    None => fallback_environment_sample_view
  }
  let bind_group = mesh3d_build_view_bind_group_from_descriptor(
    backend,
    layout,
    layout_descriptor,
    view_buf,
    lights_buf,
    clustered_lights_buf,
    clusterable_object_index_lists_buf,
    cluster_offsets_and_counts_buf,
    globals_buf,
    fog_buf,
    light_probes_buf,
    visibility_ranges_buf,
    ssr_settings_buf,
    contact_shadows_settings_buf,
    point_shadow_sample_view,
    point_shadow_compare_sampler,
    directional_shadow_sample_view,
    transmission_source_texture,
    dt_lut_sample_view,
    dt_lut_texture.sampler,
    "wgpu: failed to build mesh3d view bind group",
  )
  let binding_arrays_bind_group = mesh3d_build_binding_arrays_bind_group_from_descriptor(
    backend,
    binding_arrays_layout,
    binding_arrays_layout_descriptor,
    environment_diffuse_sample_view,
    environment_specular_sample_view,
    environment_diffuse_texture.sampler,
    "wgpu: failed to build mesh3d binding-array bind group",
  )
  backend.mesh3d_view_bg_cache.push(Mesh3dViewBindGroupCacheEntry::{
    material_pipeline_id,
    tonemap_in_shader,
    transmission_source_texture_id: transmission_source_texture.id,
    point_shadow_texture_id: point_shadow_texture.id,
    directional_shadow_texture_id: directional_shadow_texture.id,
    environment_diffuse_texture_id: environment_diffuse_texture.id,
    environment_specular_texture_id: environment_specular_texture.id,
    tonemapping_lut_texture_id: dt_lut_texture.id,
    bind_group,
    binding_arrays_bind_group,
  })
  (bind_group, binding_arrays_bind_group)
}

///|
fn mesh3d_frame_view_bg_cache_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  tonemap_in_shader : Bool,
  uniforms : Mesh3dPassUniformState,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
  directional_shadow_texture : GpuTextureInfo,
  environment_diffuse_texture : GpuTextureInfo,
  environment_specular_texture : GpuTextureInfo,
  tonemapping_mode : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
) -> (@wgpu.BindGroup, @wgpu.BindGroup) raise GpuBackendError {
  let dt_lut_texture = tonemapping_selected_lut_texture(
    backend, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  for entry in backend.mesh3d_frame_view_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.frame_count == uniforms.frame_count &&
      entry.camera_key_hi == uniforms.camera_key_hi &&
      entry.camera_key_lo == uniforms.camera_key_lo &&
      entry.pass_kind == uniforms.pass_kind &&
      entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id &&
      entry.directional_shadow_texture_id == directional_shadow_texture.id &&
      entry.environment_diffuse_texture_id == environment_diffuse_texture.id &&
      entry.environment_specular_texture_id == environment_specular_texture.id &&
      entry.tonemapping_lut_texture_id == dt_lut_texture.id {
      return (entry.bind_group, entry.binding_arrays_bind_group)
    }
  }
  guard backend.frame is Some(frame) else {
    fatal("wgpu: missing active frame for mesh3d view bind group")
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key=mesh3d_default_mesh_view_layout_key(
      tonemap_in_shader~,
    ),
  )
  let layout = layout_entry.view_bind_group_layout
  let layout_descriptor = layout_entry.view_bind_group_layout_descriptor
  let binding_arrays_layout = layout_entry.binding_arrays_bind_group_layout
  let binding_arrays_layout_descriptor = layout_entry.binding_arrays_bind_group_layout_descriptor
  let clustered_lights_buf = match backend.mesh3d_clustered_lights_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d clustered lights buffer")
  }
  let clusterable_object_index_lists_buf = match
    backend.mesh3d_clusterable_object_index_lists_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d clusterable object index lists buffer")
  }
  let cluster_offsets_and_counts_buf = match
    backend.mesh3d_cluster_offsets_and_counts_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d cluster offsets and counts buffer")
  }
  let globals_buf = match backend.mesh3d_globals_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d globals buffer")
  }
  let fog_buf = match backend.mesh3d_fog_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d fog buffer")
  }
  let light_probes_buf = match backend.mesh3d_light_probes_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d light probes buffer")
  }
  let visibility_ranges_buf = match backend.mesh3d_visibility_ranges_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d visibility ranges buffer")
  }
  let ssr_settings_buf = match backend.mesh3d_ssr_settings_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d ssr settings buffer")
  }
  let contact_shadows_settings_buf = match
    backend.mesh3d_contact_shadows_settings_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d contact shadows settings buffer")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let dt_lut_sample_view = match dt_lut_texture.sample_view {
    Some(view) => view
    None => dt_lut_texture.view
  }
  let directional_shadow_sample_view = match
    directional_shadow_texture.sample_view {
    Some(view) => view
    None => directional_shadow_texture.view
  }
  let fallback_environment_texture = ensure_environment_map_fallback_texture(
    backend,
  )
  let fallback_environment_sample_view = match
    fallback_environment_texture.sample_view {
    Some(view) => view
    None => fallback_environment_texture.view
  }
  let environment_diffuse_sample_view = match
    environment_diffuse_texture.sample_view {
    Some(view) => view
    None => fallback_environment_sample_view
  }
  let environment_specular_sample_view = match
    environment_specular_texture.sample_view {
    Some(view) => view
    None => fallback_environment_sample_view
  }
  let bind_group = mesh3d_build_view_bind_group_from_descriptor(
    backend,
    layout,
    layout_descriptor,
    uniforms.view_buffer,
    uniforms.lights_buffer,
    clustered_lights_buf,
    clusterable_object_index_lists_buf,
    cluster_offsets_and_counts_buf,
    globals_buf,
    fog_buf,
    light_probes_buf,
    visibility_ranges_buf,
    ssr_settings_buf,
    contact_shadows_settings_buf,
    point_shadow_sample_view,
    point_shadow_compare_sampler,
    directional_shadow_sample_view,
    transmission_source_texture,
    dt_lut_sample_view,
    dt_lut_texture.sampler,
    "wgpu: failed to build mesh3d frame view bind group",
  )
  let binding_arrays_bind_group = mesh3d_build_binding_arrays_bind_group_from_descriptor(
    backend,
    binding_arrays_layout,
    binding_arrays_layout_descriptor,
    environment_diffuse_sample_view,
    environment_specular_sample_view,
    environment_diffuse_texture.sampler,
    "wgpu: failed to build mesh3d frame binding-array bind group",
  )
  frame.transient_bind_groups.push(bind_group)
  frame.transient_bind_groups.push(binding_arrays_bind_group)
  backend.mesh3d_frame_view_bg_cache.push(Mesh3dFrameViewBindGroupCacheEntry::{
    material_pipeline_id,
    tonemap_in_shader,
    frame_count: uniforms.frame_count,
    camera_key_hi: uniforms.camera_key_hi,
    camera_key_lo: uniforms.camera_key_lo,
    pass_kind: uniforms.pass_kind,
    transmission_source_texture_id: transmission_source_texture.id,
    point_shadow_texture_id: point_shadow_texture.id,
    directional_shadow_texture_id: directional_shadow_texture.id,
    environment_diffuse_texture_id: environment_diffuse_texture.id,
    environment_specular_texture_id: environment_specular_texture.id,
    tonemapping_lut_texture_id: dt_lut_texture.id,
    bind_group,
    binding_arrays_bind_group,
  })
  (bind_group, binding_arrays_bind_group)
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
  material_descriptor : @render_resource.RenderPipelineDescriptor?,
  base_texture : GpuTextureInfo,
  normal_texture : GpuTextureInfo,
  emissive_texture : GpuTextureInfo,
  metallic_roughness_texture : GpuTextureInfo,
  occlusion_texture : GpuTextureInfo,
  depth_texture : GpuTextureInfo,
  anisotropy_texture : GpuTextureInfo,
  specular_tint_texture : GpuTextureInfo,
  material_uniform_bytes : Bytes,
) -> @wgpu.BindGroup raise GpuBackendError {
  if mesh3d_descriptor_material_layout(material_descriptor) is None {
    let empty_bytes = Bytes::new(0)
    for entry in backend.mesh3d_material_bg_cache {
      if entry.material_pipeline_id == material_pipeline_id &&
        entry.base_texture_id == -2 &&
        entry.normal_texture_id == -2 &&
        entry.emissive_texture_id == -2 &&
        entry.metallic_roughness_texture_id == -2 &&
        entry.occlusion_texture_id == -2 &&
        entry.depth_texture_id == -2 &&
        entry.anisotropy_texture_id == -2 &&
        entry.specular_tint_texture_id == -2 &&
        entry.material_uniform_bytes == empty_bytes {
        return entry.bind_group
      }
    }
    let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
      backend, material_pipeline_id, material_descriptor,
    )
    let material_uniform_buf = backend.device.create_buffer(
      size=4UL,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
    )
    let bind_group = mesh3d_create_empty_bind_group(
      backend,
      layout_entry.material_bind_group_layout,
      "mgstudio_mesh3d_empty_material_bg",
    )
    backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
      material_pipeline_id,
      base_texture_id: -2,
      normal_texture_id: -2,
      emissive_texture_id: -2,
      metallic_roughness_texture_id: -2,
      occlusion_texture_id: -2,
      depth_texture_id: -2,
      anisotropy_texture_id: -2,
      specular_tint_texture_id: -2,
      material_uniform_bytes: empty_bytes,
      material_uniform_buffer: material_uniform_buf,
      bind_group,
    })
    return bind_group
  }
  for entry in backend.mesh3d_material_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id &&
      entry.depth_texture_id == depth_texture.id &&
      entry.anisotropy_texture_id == anisotropy_texture.id &&
      entry.specular_tint_texture_id == specular_tint_texture.id &&
      entry.material_uniform_bytes == material_uniform_bytes {
      return entry.bind_group
    }
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend, material_pipeline_id, material_descriptor,
  )
  let layout = layout_entry.material_bind_group_layout
  let material_uniform_buf = backend.device.create_buffer(
    size=MESH3D_STANDARD_MATERIAL_UNIFORM_SIZE,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  backend.queue.write_buffer(material_uniform_buf, 0UL, material_uniform_bytes)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=17UL)
  let ok = builder.add_buffer(
      0U,
      material_uniform_buf,
      size=MESH3D_STANDARD_MATERIAL_UNIFORM_SIZE,
    ) &&
    builder.add_texture_view(1U, base_texture.view) &&
    builder.add_sampler(2U, base_texture.sampler) &&
    builder.add_texture_view(3U, emissive_texture.view) &&
    builder.add_sampler(4U, emissive_texture.sampler) &&
    builder.add_texture_view(5U, metallic_roughness_texture.view) &&
    builder.add_sampler(6U, metallic_roughness_texture.sampler) &&
    builder.add_texture_view(7U, occlusion_texture.view) &&
    builder.add_sampler(8U, occlusion_texture.sampler) &&
    builder.add_texture_view(9U, normal_texture.view) &&
    builder.add_sampler(10U, normal_texture.sampler) &&
    builder.add_texture_view(11U, depth_texture.view) &&
    builder.add_sampler(12U, depth_texture.sampler) &&
    builder.add_texture_view(13U, anisotropy_texture.view) &&
    builder.add_sampler(14U, anisotropy_texture.sampler) &&
    builder.add_texture_view(29U, specular_tint_texture.view) &&
    builder.add_sampler(30U, specular_tint_texture.sampler)
  if !ok {
    builder.free()
    material_uniform_buf.release()
    fatal("wgpu: failed to build mesh3d material bind group")
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_mesh3d_material_bg", "wgpu: failed to build mesh3d material bind group",
  )
  backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
    material_pipeline_id,
    base_texture_id: base_texture.id,
    normal_texture_id: normal_texture.id,
    emissive_texture_id: emissive_texture.id,
    metallic_roughness_texture_id: metallic_roughness_texture.id,
    occlusion_texture_id: occlusion_texture.id,
    depth_texture_id: depth_texture.id,
    anisotropy_texture_id: anisotropy_texture.id,
    specular_tint_texture_id: specular_tint_texture.id,
    material_uniform_bytes,
    material_uniform_buffer: material_uniform_buf,
    bind_group,
  })
  bind_group
}

///|
fn resolve_mesh3d_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  if id < 0 {
    return Some(ensure_default_texture(backend))
  }
  match find_texture(backend, id) {
    Some(texture) => Some(texture)
    None => Some(ensure_default_texture(backend))
  }
}

///|
fn ensure_point_shadow_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.point_shadow_fallback_texture_id >= 0 {
    if find_texture(backend, backend.point_shadow_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let created_id = backend.create_point_light_shadow_target(1)
  backend.point_shadow_fallback_texture_id = created_id
  guard find_texture(backend, created_id) is Some(texture) else {
    fatal("wgpu: failed to initialize point shadow fallback texture")
  }
  texture
}

///|
fn ensure_directional_shadow_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.directional_shadow_fallback_texture_id >= 0 {
    if find_texture(backend, backend.directional_shadow_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let created_id = backend.create_directional_light_shadow_target(1, 1)
  backend.directional_shadow_fallback_texture_id = created_id
  guard find_texture(backend, created_id) is Some(texture) else {
    fatal("wgpu: failed to initialize directional shadow fallback texture")
  }
  texture
}

///|
pub fn GpuBackend::prepare_mesh3d_material_bind_group(
  self : GpuBackend,
  texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(self)
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
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
  let resolved_depth_texture_id = if depth_texture_id < 0 {
    -1
  } else {
    depth_texture_id
  }
  let resolved_anisotropy_texture_id = if anisotropy_texture_id < 0 {
    -1
  } else {
    anisotropy_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  guard resolve_mesh3d_texture(self, resolved_base_texture_id)
    is Some(base_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_emissive_texture_id)
    is Some(emissive_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_metallic_roughness_texture_id)
    is Some(metallic_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_occlusion_texture_id)
    is Some(occlusion_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_depth_texture_id)
    is Some(depth_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_anisotropy_texture_id)
    is Some(anisotropy_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  ignore(
    mesh3d_material_cache_get_or_create(
      self,
      MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
      None,
      base_texture,
      normal_texture,
      emissive_texture,
      metallic_roughness_texture,
      occlusion_texture,
      depth_texture,
      anisotropy_texture,
      specular_tint_texture,
      mesh3d_standard_material_default_uniform_bytes(),
    ),
  )
}

///|
pub fn GpuBackend::prepare_mesh3d_view_bind_group(
  self : GpuBackend,
  transmission_source_texture_id : Int,
  point_shadow_texture_id : Int,
  directional_shadow_texture_id : Int,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(self)
  let resolved_transmission_source_texture_id = if transmission_source_texture_id <
    0 {
    -1
  } else {
    transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    point_shadow_texture_id
  }
  let resolved_directional_shadow_texture_id = if directional_shadow_texture_id <
    0 {
    ensure_directional_shadow_fallback_texture(self).id
  } else {
    directional_shadow_texture_id
  }
  let resolved_environment_diffuse_texture_id = if environment_diffuse_texture_id <
    0 {
    ensure_environment_map_fallback_texture(self).id
  } else {
    environment_diffuse_texture_id
  }
  let resolved_environment_specular_texture_id = if environment_specular_texture_id <
    0 {
    ensure_environment_map_fallback_texture(self).id
  } else {
    environment_specular_texture_id
  }
  guard resolve_mesh3d_texture(self, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_specular_texture_id)
    is Some(environment_specular_texture) else {
    return
  }
  ignore(
    mesh3d_view_bg_cache_get_or_create(
      self,
      MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
      None,
      false,
      transmission_source_texture,
      point_shadow_texture,
      directional_shadow_texture,
      environment_diffuse_texture,
      environment_specular_texture,
      0,
      -1,
      -1,
      -1,
    ),
  )
}
