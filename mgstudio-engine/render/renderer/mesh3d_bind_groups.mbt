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
fn mesh3d_retire_or_release_bind_group(
  backend : GpuBackend,
  bind_group : @wgpu.BindGroup,
) -> Unit {
  if backend.frame is Some(_) {
    backend.frame_retired_bind_groups.push(bind_group)
  } else {
    bind_group.release()
  }
}

///|
fn mesh3d_retire_or_release_buffer(
  backend : GpuBackend,
  buffer : @wgpu.Buffer,
) -> Unit {
  if backend.frame is Some(_) {
    backend.frame_retired_buffers.push(buffer)
  } else {
    buffer.release()
  }
}

///|
fn mesh3d_bind_group_layout_has_binding(
  layout : @render_resource.BindGroupLayoutDescriptor,
  binding : Int,
) -> Bool {
  for entry in layout.entries() {
    if entry.binding() == binding {
      return true
    }
  }
  false
}

///|
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  mesh3d_view_bind_group_cache_clear(backend)
  for entry in backend.mesh3d_material_bg_cache {
    mesh3d_retire_or_release_bind_group(backend, entry.bind_group)
    mesh3d_retire_or_release_buffer(backend, entry.material_uniform_buffer)
    match entry.forward_decal_uniform_buffer {
      Some(buffer) => mesh3d_retire_or_release_buffer(backend, buffer)
      None => ()
    }
    for buffer in entry.material_extension_uniform_buffers {
      mesh3d_retire_or_release_buffer(backend, buffer)
    }
  }
  backend.mesh3d_material_bg_cache.clear()
}

///|
fn mesh3d_view_bind_group_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_view_bg_cache {
    mesh3d_retire_or_release_bind_group(backend, entry.bind_group)
    mesh3d_retire_or_release_bind_group(
      backend,
      entry.binding_arrays_bind_group,
    )
  }
  backend.mesh3d_view_bg_cache.clear()
  backend.mesh3d_frame_view_bg_cache.clear()
}

///|
fn mesh3d_extension_bind_group_data_empty() -> @render_resource.MaterialBindGroupResolvedData {
  @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData()
}

///|
fn mesh3d_extension_bind_group_data_matches(
  left : @render_resource.MaterialBindGroupResolvedData,
  right : @render_resource.MaterialBindGroupResolvedData,
) -> Bool {
  left.equals(right)
}

///|
fn mesh3d_add_material_extension_bindings(
  backend : GpuBackend,
  builder : @wgpu.BindGroupBuilder,
  material_extension_bind_group_data : @render_resource.MaterialBindGroupResolvedData,
  uniform_buffers : Array[@wgpu.Buffer],
) -> Bool raise GpuBackendError {
  let mut ok = true
  for entry in material_extension_bind_group_data.entries() {
    if ok {
      let binding = entry.binding().reinterpret_as_uint()
      match entry.resource() {
        @render_resource.MaterialBindGroupResolvedResource::Texture(texture_id) => {
          guard resolve_mesh3d_texture(backend, texture_id) is Some(texture) else {
            return false
          }
          ok = builder.add_texture_view(binding, texture.view)
        }
        @render_resource.MaterialBindGroupResolvedResource::Sampler(texture_id) => {
          guard resolve_mesh3d_texture(backend, texture_id) is Some(texture) else {
            return false
          }
          ok = builder.add_sampler(binding, texture.sampler)
        }
        @render_resource.MaterialBindGroupResolvedResource::Uniform(bytes) => {
          let size = bytes.length().to_uint64()
          let buffer = backend.device.create_buffer(
            size~,
            usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
          )
          backend.queue.write_buffer(buffer, 0UL, bytes)
          uniform_buffers.push(buffer)
          ok = builder.add_buffer(binding, buffer, size~)
        }
      }
    }
  }
  ok
}

///|
fn mesh3d_material_layout_is_standard_compatible(
  layout : @render_resource.BindGroupLayoutDescriptor,
) -> Bool {
  mesh3d_bind_group_layout_has_binding(layout, 0) &&
  mesh3d_bind_group_layout_has_binding(layout, 1) &&
  mesh3d_bind_group_layout_has_binding(layout, 2) &&
  mesh3d_bind_group_layout_has_binding(layout, 3)
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
fn mesh3d_texture_ids_signature(texture_ids : Array[Int]) -> String {
  let parts : Array[String] = []
  for id in texture_ids {
    parts.push(id.to_string())
  }
  parts.join(":")
}

///|
fn mesh3d_environment_texture_ids_signature(
  diffuse_texture_ids : Array[Int],
  specular_texture_ids : Array[Int],
) -> String {
  mesh3d_texture_ids_signature(diffuse_texture_ids) +
  "|" +
  mesh3d_texture_ids_signature(specular_texture_ids)
}

///|
fn mesh3d_pass_environment_texture_ids(
  backend : GpuBackend,
  environment_diffuse_texture : GpuTextureInfo,
  environment_specular_texture : GpuTextureInfo,
  fallback_environment_texture : GpuTextureInfo,
) -> (Array[Int], Array[Int], String) {
  let diffuse_source : Array[Int] = []
  let specular_source : Array[Int] = []
  if backend.pass_state is Some(pass_state) &&
    (
      pass_state.environment_diffuse_texture_ids.length() > 0 ||
      pass_state.environment_specular_texture_ids.length() > 0
    ) {
    for id in pass_state.environment_diffuse_texture_ids {
      diffuse_source.push(id)
    }
    for id in pass_state.environment_specular_texture_ids {
      specular_source.push(id)
    }
  }
  if diffuse_source.length() == 0 && specular_source.length() == 0 {
    diffuse_source.push(environment_diffuse_texture.id)
    specular_source.push(environment_specular_texture.id)
  }
  let diffuse_ids : Array[Int] = []
  let specular_ids : Array[Int] = []
  let target_len = if diffuse_source.length() > specular_source.length() {
    diffuse_source.length()
  } else {
    specular_source.length()
  }
  for i in 0..<target_len {
    let diffuse_id = if i < diffuse_source.length() {
      diffuse_source[i]
    } else {
      fallback_environment_texture.id
    }
    let specular_id = if i < specular_source.length() {
      specular_source[i]
    } else {
      fallback_environment_texture.id
    }
    diffuse_ids.push(diffuse_id)
    specular_ids.push(specular_id)
  }
  (
    diffuse_ids,
    specular_ids,
    mesh3d_environment_texture_ids_signature(diffuse_ids, specular_ids),
  )
}

///|
fn mesh3d_environment_texture_views(
  backend : GpuBackend,
  texture_ids : Array[Int],
  fallback_environment_texture : GpuTextureInfo,
) -> Array[@wgpu.TextureView] raise GpuBackendError {
  let fallback_view = match fallback_environment_texture.sample_view {
    Some(view) => view
    None => fallback_environment_texture.view
  }
  let views : Array[@wgpu.TextureView] = []
  for texture_id in texture_ids {
    let texture = match resolve_mesh3d_texture(backend, texture_id) {
      Some(value) => value
      None => fallback_environment_texture
    }
    views.push(
      match texture.sample_view {
        Some(view) => view
        None => fallback_view
      },
    )
  }
  if views.length() == 0 {
    views.push(fallback_view)
  }
  views
}

///|
fn mesh3d_pass_irradiance_volume_texture_ids(
  backend : GpuBackend,
  fallback_irradiance_volume_texture : GpuTextureInfo,
) -> (Array[Int], String) {
  let source : Array[Int] = []
  if backend.pass_state is Some(pass_state) &&
    pass_state.irradiance_volume_texture_ids.length() > 0 {
    for id in pass_state.irradiance_volume_texture_ids {
      source.push(id)
    }
  }
  if source.length() == 0 {
    source.push(fallback_irradiance_volume_texture.id)
  }
  let texture_ids : Array[Int] = []
  for texture_id in source {
    texture_ids.push(texture_id)
  }
  (texture_ids, mesh3d_texture_ids_signature(texture_ids))
}

///|
fn mesh3d_irradiance_volume_texture_views(
  backend : GpuBackend,
  texture_ids : Array[Int],
  fallback_irradiance_volume_texture : GpuTextureInfo,
) -> Array[@wgpu.TextureView] raise GpuBackendError {
  let views : Array[@wgpu.TextureView] = []
  for texture_id in texture_ids {
    let texture = match resolve_mesh3d_texture(backend, texture_id) {
      Some(value) => value
      None => fallback_irradiance_volume_texture
    }
    views.push(texture.view)
  }
  if views.length() == 0 {
    views.push(fallback_irradiance_volume_texture.view)
  }
  views
}

///|
fn mesh3d_add_texture_views_for_layout_entry(
  builder : @wgpu.BindGroupBuilder,
  binding : UInt,
  views : Array[@wgpu.TextureView],
  entry : @render_resource.BindGroupLayoutEntry,
) -> Bool {
  if entry.count() > 1 {
    let texture_views : Array[@wgpu.TextureView] = []
    for i in 0..<entry.count() {
      if i < views.length() {
        texture_views.push(views[i])
      } else {
        texture_views.push(views[views.length() - 1])
      }
    }
    builder.add_texture_view_array(binding, texture_views)
  } else {
    builder.add_texture_view(binding, views[0])
  }
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
  depth_prepass_view : @wgpu.TextureView?,
  normal_prepass_view : @wgpu.TextureView?,
  motion_vector_prepass_view : @wgpu.TextureView?,
  deferred_prepass_view : @wgpu.TextureView?,
  ssao_view : @wgpu.TextureView?,
  transmission_source_texture : GpuTextureInfo,
  dt_lut_sample_view : @wgpu.TextureView,
  dt_lut_sampler : @wgpu.Sampler,
  atmosphere_transmittance_view : @wgpu.TextureView?,
  atmosphere_transmittance_sampler : @wgpu.Sampler?,
  atmosphere_buffer : @wgpu.Buffer?,
  pbr_blue_noise_texture : GpuTextureInfo?,
  pbr_area_light_luts_texture : GpuTextureInfo?,
  pbr_dfg_lut_texture : GpuTextureInfo?,
) -> Bool raise GpuBackendError {
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
    17 =>
      match ssao_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => fatal("wgpu: missing screen space ambient occlusion texture")
      }
    18 =>
      mesh3d_add_texture_view_for_layout_entry(
        builder, binding, dt_lut_sample_view, entry,
      )
    19 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, dt_lut_sampler, entry,
      )
    20 =>
      match depth_prepass_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => false
      }
    21 =>
      match normal_prepass_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => false
      }
    22 =>
      match motion_vector_prepass_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => false
      }
    23 =>
      match deferred_prepass_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => false
      }
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
    31 =>
      match atmosphere_transmittance_view {
        Some(view) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder, binding, view, entry,
          )
        None => fatal("wgpu: missing atmosphere transmittance texture")
      }
    32 =>
      match atmosphere_transmittance_sampler {
        Some(sampler) =>
          mesh3d_add_sampler_for_layout_entry(builder, binding, sampler, entry)
        None => fatal("wgpu: missing atmosphere transmittance sampler")
      }
    33 =>
      match atmosphere_buffer {
        Some(buffer) =>
          builder.add_buffer(
            binding,
            buffer,
            size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
          )
        None => fatal("wgpu: missing atmosphere storage buffer")
      }
    34 =>
      match pbr_blue_noise_texture {
        Some(texture) =>
          match texture.sample_view {
            Some(view) =>
              mesh3d_add_texture_view_for_layout_entry(
                builder, binding, view, entry,
              )
            None => fatal("wgpu: missing PBR blue noise texture array view")
          }
        None => fatal("wgpu: missing PBR blue noise texture")
      }
    35 =>
      match pbr_area_light_luts_texture {
        Some(texture) =>
          match texture.sample_view {
            Some(view) =>
              mesh3d_add_texture_view_for_layout_entry(
                builder, binding, view, entry,
              )
            None => fatal("wgpu: missing PBR area light LUT texture array view")
          }
        None => fatal("wgpu: missing PBR area light LUT texture")
      }
    36 =>
      match pbr_area_light_luts_texture {
        Some(texture) =>
          mesh3d_add_sampler_for_layout_entry(
            builder,
            binding,
            texture.sampler,
            entry,
          )
        None => fatal("wgpu: missing PBR area light LUT sampler")
      }
    37 =>
      match pbr_dfg_lut_texture {
        Some(texture) =>
          mesh3d_add_texture_view_for_layout_entry(
            builder,
            binding,
            texture.view,
            entry,
          )
        None => fatal("wgpu: missing PBR DFG LUT texture")
      }
    38 =>
      match pbr_dfg_lut_texture {
        Some(texture) =>
          mesh3d_add_sampler_for_layout_entry(
            builder,
            binding,
            texture.sampler,
            entry,
          )
        None => fatal("wgpu: missing PBR DFG LUT sampler")
      }
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
  depth_prepass_view : @wgpu.TextureView?,
  normal_prepass_view : @wgpu.TextureView?,
  motion_vector_prepass_view : @wgpu.TextureView?,
  deferred_prepass_view : @wgpu.TextureView?,
  ssao_view : @wgpu.TextureView?,
  transmission_source_texture : GpuTextureInfo,
  dt_lut_sample_view : @wgpu.TextureView,
  dt_lut_sampler : @wgpu.Sampler,
  atmosphere_transmittance_view : @wgpu.TextureView?,
  atmosphere_transmittance_sampler : @wgpu.Sampler?,
  atmosphere_buffer : @wgpu.Buffer?,
  pbr_blue_noise_texture : GpuTextureInfo?,
  pbr_area_light_luts_texture : GpuTextureInfo?,
  pbr_dfg_lut_texture : GpuTextureInfo?,
  error_message : String,
) -> @wgpu.BindGroup raise GpuBackendError {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=mesh3d_bind_group_layout_descriptor_capacity(descriptor),
  )
  for entry in entries {
    if !mesh3d_add_view_bind_group_layout_entry(
        builder, entry, view_buf, lights_buf, clustered_lights_buf, clusterable_object_index_lists_buf,
        cluster_offsets_and_counts_buf, globals_buf, fog_buf, light_probes_buf, visibility_ranges_buf,
        ssr_settings_buf, contact_shadows_settings_buf, point_shadow_sample_view,
        point_shadow_compare_sampler, directional_shadow_sample_view, depth_prepass_view,
        normal_prepass_view, motion_vector_prepass_view, deferred_prepass_view, ssao_view,
        transmission_source_texture, dt_lut_sample_view, dt_lut_sampler, atmosphere_transmittance_view,
        atmosphere_transmittance_sampler, atmosphere_buffer, pbr_blue_noise_texture,
        pbr_area_light_luts_texture, pbr_dfg_lut_texture,
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
  environment_diffuse_sample_views : Array[@wgpu.TextureView],
  environment_specular_sample_views : Array[@wgpu.TextureView],
  environment_sampler : @wgpu.Sampler,
  irradiance_volume_texture_views : Array[@wgpu.TextureView],
  irradiance_volume_sampler : @wgpu.Sampler,
  clustered_decals_buf : @wgpu.Buffer,
  clustered_decal_texture_views : Array[@wgpu.TextureView],
  clustered_decal_sampler : @wgpu.Sampler,
) -> Bool {
  if entry.binding() < 0 {
    return false
  }
  let binding = entry.binding().reinterpret_as_uint()
  match entry.binding() {
    0 =>
      mesh3d_add_texture_views_for_layout_entry(
        builder, binding, environment_diffuse_sample_views, entry,
      )
    1 =>
      mesh3d_add_texture_views_for_layout_entry(
        builder, binding, environment_specular_sample_views, entry,
      )
    2 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, environment_sampler, entry,
      )
    3 =>
      mesh3d_add_texture_views_for_layout_entry(
        builder, binding, irradiance_volume_texture_views, entry,
      )
    4 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, irradiance_volume_sampler, entry,
      )
    5 => builder.add_buffer(binding, clustered_decals_buf)
    6 =>
      if clustered_decal_texture_views.length() > 1 {
        builder.add_texture_view_array(binding, clustered_decal_texture_views)
      } else if clustered_decal_texture_views.length() == 1 {
        builder.add_texture_view(binding, clustered_decal_texture_views[0])
      } else {
        false
      }
    7 =>
      mesh3d_add_sampler_for_layout_entry(
        builder, binding, clustered_decal_sampler, entry,
      )
    _ => false
  }
}

///|
fn mesh3d_build_binding_arrays_bind_group_from_descriptor(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  environment_diffuse_sample_views : Array[@wgpu.TextureView],
  environment_specular_sample_views : Array[@wgpu.TextureView],
  environment_sampler : @wgpu.Sampler,
  irradiance_volume_texture_views : Array[@wgpu.TextureView],
  irradiance_volume_sampler : @wgpu.Sampler,
  clustered_decals_buf : @wgpu.Buffer,
  clustered_decal_texture_views : Array[@wgpu.TextureView],
  clustered_decal_sampler : @wgpu.Sampler,
  error_message : String,
) -> @wgpu.BindGroup raise GpuBackendError {
  let entries = descriptor.entries()
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=mesh3d_bind_group_layout_descriptor_capacity(descriptor),
  )
  for entry in entries {
    if !mesh3d_add_binding_array_layout_entry(
        builder, entry, environment_diffuse_sample_views, environment_specular_sample_views,
        environment_sampler, irradiance_volume_texture_views, irradiance_volume_sampler,
        clustered_decals_buf, clustered_decal_texture_views, clustered_decal_sampler,
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
fn mesh3d_prepass_texture_view_for_id(
  backend : GpuBackend,
  texture_id : Int,
) -> @wgpu.TextureView? {
  if texture_id < 0 {
    return None
  }
  match find_texture(backend, texture_id) {
    Some(texture) => Some(texture.view)
    None => None
  }
}

///|
fn mesh3d_texture_for_optional_id(
  backend : GpuBackend,
  texture_id : Int,
) -> GpuTextureInfo? {
  if texture_id < 0 {
    return None
  }
  find_texture(backend, texture_id)
}

///|
fn mesh3d_atmosphere_resource_revision(backend : GpuBackend) -> Int {
  match backend.mesh3d_atmosphere_resources {
    Some(resources) => resources.revision
    None => 0
  }
}

///|
fn mesh3d_ssao_resource_revision(backend : GpuBackend) -> Int {
  match backend.mesh3d_ssao_resources {
    Some(resources) => resources.revision
    None => 0
  }
}

///|
fn mesh3d_clustered_decals_default_words() -> Array[UInt] {
  [
    1.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    1.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    1.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    1.0F.reinterpret_as_uint(),
    (-1).reinterpret_as_uint(),
    (-1).reinterpret_as_uint(),
    (-1).reinterpret_as_uint(),
    (-1).reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0.0F.reinterpret_as_uint(),
    0U,
    0U,
    0U,
    0U,
  ]
}

///|
fn ensure_mesh3d_clustered_decals_buffer(backend : GpuBackend) -> @wgpu.Buffer {
  match backend.mesh3d_clustered_decals_buf {
    Some(buffer) => buffer
    None => {
      let bytes = u32le_pack(mesh3d_clustered_decals_default_words())
      let buffer = backend.device.create_buffer(
        size=bytes.length().to_uint64(),
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      )
      backend.queue.write_buffer(buffer, 0UL, bytes)
      backend.mesh3d_clustered_decals_buf = Some(buffer)
      backend.mesh3d_clustered_decals_capacity = bytes.length().to_uint64()
      buffer
    }
  }
}

///|
fn mesh3d_clustered_decal_texture_views(
  backend : GpuBackend,
  fallback_texture : GpuTextureInfo,
  count : Int,
) -> Array[@wgpu.TextureView] raise GpuBackendError {
  let views : Array[@wgpu.TextureView] = []
  for index in 0..<count {
    let texture_id = if index <
      backend.mesh3d_clustered_decal_texture_ids.length() {
      backend.mesh3d_clustered_decal_texture_ids[index]
    } else {
      -1
    }
    let texture = match resolve_mesh3d_texture(backend, texture_id) {
      Some(value) => value
      None => fallback_texture
    }
    views.push(texture.view)
  }
  views
}

///|
fn mesh3d_ssao_resources_keepalive(resources : GpuSsaoResources) -> Unit {
  ignore(resources.preprocessed_depth_texture)
  ignore(resources.preprocessed_depth_view)
  ignore(resources.preprocessed_depth_mip_views)
  ignore(resources.ssao_noisy_texture)
  ignore(resources.ssao_noisy_view)
  ignore(resources.screen_space_ambient_occlusion_texture)
  ignore(resources.screen_space_ambient_occlusion_view)
  ignore(resources.depth_differences_texture)
  ignore(resources.depth_differences_view)
  ignore(resources.thickness_buffer)
}

///|
fn mesh3d_atmosphere_resources_keepalive(
  resources : GpuAtmosphereResources,
) -> Unit {
  ignore(resources.transmittance_texture)
  ignore(resources.multiscattering_texture)
  ignore(resources.multiscattering_view)
  ignore(resources.sky_view_texture)
  ignore(resources.sky_view_view)
  ignore(resources.aerial_view_texture)
  ignore(resources.aerial_view_view)
  ignore(resources.settings_buffer)
  ignore(resources.transmittance_lut_bgl)
  ignore(resources.transmittance_lut_pipeline_layout)
  ignore(resources.transmittance_lut_pipeline)
  ignore(resources.multiscattering_lut_bgl)
  ignore(resources.multiscattering_lut_pipeline_layout)
  ignore(resources.multiscattering_lut_pipeline)
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
  pbr_blue_noise_texture_id? : Int = -1,
  pbr_area_light_luts_texture_id? : Int = -1,
  pbr_dfg_lut_texture_id? : Int = -1,
) -> (@wgpu.BindGroup, @wgpu.BindGroup) raise GpuBackendError {
  let dt_lut_texture = tonemapping_selected_lut_texture(
    backend, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  let atmosphere_revision = mesh3d_atmosphere_resource_revision(backend)
  let ssao_revision = mesh3d_ssao_resource_revision(backend)
  let clustered_decals_revision = backend.mesh3d_clustered_decals_revision
  let fallback_environment_texture = ensure_environment_map_fallback_texture(
    backend,
  )
  let fallback_irradiance_volume_texture = ensure_irradiance_volume_fallback_texture(
    backend,
  )
  let (
    environment_diffuse_texture_ids,
    environment_specular_texture_ids,
    environment_texture_ids_signature,
  ) = mesh3d_pass_environment_texture_ids(
    backend, environment_diffuse_texture, environment_specular_texture, fallback_environment_texture,
  )
  let (irradiance_volume_texture_ids, irradiance_volume_texture_ids_signature) = mesh3d_pass_irradiance_volume_texture_ids(
    backend, fallback_irradiance_volume_texture,
  )
  let pbr_blue_noise_texture = mesh3d_texture_for_optional_id(
    backend, pbr_blue_noise_texture_id,
  )
  let pbr_area_light_luts_texture = mesh3d_texture_for_optional_id(
    backend, pbr_area_light_luts_texture_id,
  )
  let pbr_dfg_lut_texture = mesh3d_texture_for_optional_id(
    backend, pbr_dfg_lut_texture_id,
  )
  for entry in backend.mesh3d_view_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id &&
      entry.directional_shadow_texture_id == directional_shadow_texture.id &&
      entry.environment_diffuse_texture_id == environment_diffuse_texture.id &&
      entry.environment_specular_texture_id == environment_specular_texture.id &&
      entry.environment_texture_ids_signature ==
      environment_texture_ids_signature &&
      entry.irradiance_volume_texture_ids_signature ==
      irradiance_volume_texture_ids_signature &&
      entry.tonemapping_lut_texture_id == dt_lut_texture.id &&
      entry.pbr_blue_noise_texture_id == pbr_blue_noise_texture_id &&
      entry.pbr_area_light_luts_texture_id == pbr_area_light_luts_texture_id &&
      entry.pbr_dfg_lut_texture_id == pbr_dfg_lut_texture_id &&
      entry.atmosphere_resource_revision == atmosphere_revision &&
      entry.ssao_resource_revision == ssao_revision &&
      entry.clustered_decals_revision == clustered_decals_revision {
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
  let (
    atmosphere_transmittance_view,
    atmosphere_transmittance_sampler,
    atmosphere_buffer,
  ) = match backend.mesh3d_atmosphere_resources {
    Some(resources) => {
      mesh3d_atmosphere_resources_keepalive(resources)
      (
        Some(resources.transmittance_view),
        Some(resources.sampler),
        Some(resources.atmosphere_buffer),
      )
    }
    None => (None, None, None)
  }
  let ssao_view = match backend.mesh3d_ssao_resources {
    Some(resources) => {
      mesh3d_ssao_resources_keepalive(resources)
      Some(resources.screen_space_ambient_occlusion_view)
    }
    None => None
  }
  let fallback_decal_texture = ensure_normal_map_fallback_texture(backend)
  let clustered_decals_buf = ensure_mesh3d_clustered_decals_buffer(backend)
  let environment_diffuse_sample_views = mesh3d_environment_texture_views(
    backend, environment_diffuse_texture_ids, fallback_environment_texture,
  )
  let environment_specular_sample_views = mesh3d_environment_texture_views(
    backend, environment_specular_texture_ids, fallback_environment_texture,
  )
  let irradiance_volume_texture_views = mesh3d_irradiance_volume_texture_views(
    backend, irradiance_volume_texture_ids, fallback_irradiance_volume_texture,
  )
  let clustered_decal_texture_views = mesh3d_clustered_decal_texture_views(
    backend, fallback_decal_texture, 8,
  )
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
    None,
    None,
    None,
    None,
    ssao_view,
    transmission_source_texture,
    dt_lut_sample_view,
    dt_lut_texture.sampler,
    atmosphere_transmittance_view,
    atmosphere_transmittance_sampler,
    atmosphere_buffer,
    pbr_blue_noise_texture,
    pbr_area_light_luts_texture,
    pbr_dfg_lut_texture,
    "wgpu: failed to build mesh3d view bind group",
  )
  let binding_arrays_bind_group = mesh3d_build_binding_arrays_bind_group_from_descriptor(
    backend,
    binding_arrays_layout,
    binding_arrays_layout_descriptor,
    environment_diffuse_sample_views,
    environment_specular_sample_views,
    environment_diffuse_texture.sampler,
    irradiance_volume_texture_views,
    fallback_irradiance_volume_texture.sampler,
    clustered_decals_buf,
    clustered_decal_texture_views,
    fallback_decal_texture.sampler,
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
    environment_texture_ids_signature,
    irradiance_volume_texture_ids_signature,
    tonemapping_lut_texture_id: dt_lut_texture.id,
    pbr_blue_noise_texture_id,
    pbr_area_light_luts_texture_id,
    pbr_dfg_lut_texture_id,
    atmosphere_resource_revision: atmosphere_revision,
    ssao_resource_revision: ssao_revision,
    clustered_decals_revision,
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
  prepass_depth_texture_id : Int,
  prepass_normal_texture_id : Int,
  prepass_motion_vector_texture_id : Int,
  prepass_deferred_texture_id : Int,
  tonemapping_mode : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  pbr_blue_noise_texture_id? : Int = -1,
  pbr_area_light_luts_texture_id? : Int = -1,
  pbr_dfg_lut_texture_id? : Int = -1,
  default_view_layout_key? : @mesh_view_layout.MeshPipelineViewLayoutKey = mesh3d_default_mesh_view_layout_key(),
) -> (@wgpu.BindGroup, @wgpu.BindGroup) raise GpuBackendError {
  let default_view_layout_key = if default_view_layout_key.bits() == 0U &&
    tonemap_in_shader {
    mesh3d_default_mesh_view_layout_key(tonemap_in_shader~)
  } else {
    default_view_layout_key
  }
  let view_layout_key_bits = default_view_layout_key.bits()
  let dt_lut_texture = tonemapping_selected_lut_texture(
    backend, tonemapping_mode, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
  let atmosphere_revision = mesh3d_atmosphere_resource_revision(backend)
  let ssao_revision = mesh3d_ssao_resource_revision(backend)
  let clustered_decals_revision = backend.mesh3d_clustered_decals_revision
  let fallback_environment_texture = ensure_environment_map_fallback_texture(
    backend,
  )
  let fallback_irradiance_volume_texture = ensure_irradiance_volume_fallback_texture(
    backend,
  )
  let (
    environment_diffuse_texture_ids,
    environment_specular_texture_ids,
    environment_texture_ids_signature,
  ) = mesh3d_pass_environment_texture_ids(
    backend, environment_diffuse_texture, environment_specular_texture, fallback_environment_texture,
  )
  let (irradiance_volume_texture_ids, irradiance_volume_texture_ids_signature) = mesh3d_pass_irradiance_volume_texture_ids(
    backend, fallback_irradiance_volume_texture,
  )
  let pbr_blue_noise_texture = mesh3d_texture_for_optional_id(
    backend, pbr_blue_noise_texture_id,
  )
  let pbr_area_light_luts_texture = mesh3d_texture_for_optional_id(
    backend, pbr_area_light_luts_texture_id,
  )
  let pbr_dfg_lut_texture = mesh3d_texture_for_optional_id(
    backend, pbr_dfg_lut_texture_id,
  )
  for entry in backend.mesh3d_frame_view_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.view_layout_key_bits == view_layout_key_bits &&
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
      entry.environment_texture_ids_signature ==
      environment_texture_ids_signature &&
      entry.irradiance_volume_texture_ids_signature ==
      irradiance_volume_texture_ids_signature &&
      entry.prepass_depth_texture_id == prepass_depth_texture_id &&
      entry.prepass_normal_texture_id == prepass_normal_texture_id &&
      entry.prepass_motion_vector_texture_id == prepass_motion_vector_texture_id &&
      entry.prepass_deferred_texture_id == prepass_deferred_texture_id &&
      entry.tonemapping_lut_texture_id == dt_lut_texture.id &&
      entry.pbr_blue_noise_texture_id == pbr_blue_noise_texture_id &&
      entry.pbr_area_light_luts_texture_id == pbr_area_light_luts_texture_id &&
      entry.pbr_dfg_lut_texture_id == pbr_dfg_lut_texture_id &&
      entry.atmosphere_resource_revision == atmosphere_revision &&
      entry.ssao_resource_revision == ssao_revision &&
      entry.clustered_decals_revision == clustered_decals_revision {
      return (entry.bind_group, entry.binding_arrays_bind_group)
    }
  }
  guard backend.frame is Some(frame) else {
    fatal("wgpu: missing active frame for mesh3d view bind group")
  }
  let depth_prepass_view = match
    find_prepass_depth_texture(backend, prepass_depth_texture_id) {
    Some(texture) => Some(texture.view)
    None => None
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    material_pipeline_id,
    material_descriptor,
    default_view_layout_key~,
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
  let (
    atmosphere_transmittance_view,
    atmosphere_transmittance_sampler,
    atmosphere_buffer,
  ) = match backend.mesh3d_atmosphere_resources {
    Some(resources) => {
      mesh3d_atmosphere_resources_keepalive(resources)
      (
        Some(resources.transmittance_view),
        Some(resources.sampler),
        Some(resources.atmosphere_buffer),
      )
    }
    None => (None, None, None)
  }
  let ssao_view = match backend.mesh3d_ssao_resources {
    Some(resources) => {
      mesh3d_ssao_resources_keepalive(resources)
      Some(resources.screen_space_ambient_occlusion_view)
    }
    None => None
  }
  let fallback_decal_texture = ensure_normal_map_fallback_texture(backend)
  let clustered_decals_buf = ensure_mesh3d_clustered_decals_buffer(backend)
  let environment_diffuse_sample_views = mesh3d_environment_texture_views(
    backend, environment_diffuse_texture_ids, fallback_environment_texture,
  )
  let environment_specular_sample_views = mesh3d_environment_texture_views(
    backend, environment_specular_texture_ids, fallback_environment_texture,
  )
  let irradiance_volume_texture_views = mesh3d_irradiance_volume_texture_views(
    backend, irradiance_volume_texture_ids, fallback_irradiance_volume_texture,
  )
  let clustered_decal_texture_views = mesh3d_clustered_decal_texture_views(
    backend, fallback_decal_texture, 8,
  )
  let normal_prepass_view = mesh3d_prepass_texture_view_for_id(
    backend, prepass_normal_texture_id,
  )
  let motion_vector_prepass_view = mesh3d_prepass_texture_view_for_id(
    backend, prepass_motion_vector_texture_id,
  )
  let deferred_prepass_view = mesh3d_prepass_texture_view_for_id(
    backend, prepass_deferred_texture_id,
  )
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
    depth_prepass_view,
    normal_prepass_view,
    motion_vector_prepass_view,
    deferred_prepass_view,
    ssao_view,
    transmission_source_texture,
    dt_lut_sample_view,
    dt_lut_texture.sampler,
    atmosphere_transmittance_view,
    atmosphere_transmittance_sampler,
    atmosphere_buffer,
    pbr_blue_noise_texture,
    pbr_area_light_luts_texture,
    pbr_dfg_lut_texture,
    "wgpu: failed to build mesh3d frame view bind group",
  )
  let binding_arrays_bind_group = mesh3d_build_binding_arrays_bind_group_from_descriptor(
    backend,
    binding_arrays_layout,
    binding_arrays_layout_descriptor,
    environment_diffuse_sample_views,
    environment_specular_sample_views,
    environment_diffuse_texture.sampler,
    irradiance_volume_texture_views,
    fallback_irradiance_volume_texture.sampler,
    clustered_decals_buf,
    clustered_decal_texture_views,
    fallback_decal_texture.sampler,
    "wgpu: failed to build mesh3d frame binding-array bind group",
  )
  frame.transient_bind_groups.push(bind_group)
  frame.transient_bind_groups.push(binding_arrays_bind_group)
  backend.mesh3d_frame_view_bg_cache.push(Mesh3dFrameViewBindGroupCacheEntry::{
    material_pipeline_id,
    view_layout_key_bits,
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
    environment_texture_ids_signature,
    irradiance_volume_texture_ids_signature,
    prepass_depth_texture_id,
    prepass_normal_texture_id,
    prepass_motion_vector_texture_id,
    prepass_deferred_texture_id,
    tonemapping_lut_texture_id: dt_lut_texture.id,
    pbr_blue_noise_texture_id,
    pbr_area_light_luts_texture_id,
    pbr_dfg_lut_texture_id,
    atmosphere_resource_revision: atmosphere_revision,
    ssao_resource_revision: ssao_revision,
    clustered_decals_revision,
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
  specular_texture : GpuTextureInfo,
  specular_tint_texture : GpuTextureInfo,
  clearcoat_texture : GpuTextureInfo,
  clearcoat_roughness_texture : GpuTextureInfo,
  clearcoat_normal_texture : GpuTextureInfo,
  material_uniform_bytes : Bytes,
  forward_decal_inv_depth_fade_factor? : Float = 1.0F / 8.0F,
  material_extension_bind_group_data? : @render_resource.MaterialBindGroupResolvedData = @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
) -> @wgpu.BindGroup raise GpuBackendError {
  let material_layout = mesh3d_descriptor_material_layout(material_descriptor)
  let uses_forward_decal_uniform = match material_layout {
    Some(layout) => mesh3d_bind_group_layout_has_binding(layout, 200)
    None => false
  }
  let forward_decal_uniform_bytes = if uses_forward_decal_uniform {
    u32le_pack([f32_bits(forward_decal_inv_depth_fade_factor)])
  } else {
    Bytes::new(0)
  }
  if material_descriptor is Some(_) && material_layout is None {
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
        entry.specular_texture_id == -2 &&
        entry.specular_tint_texture_id == -2 &&
        entry.clearcoat_texture_id == -2 &&
        entry.clearcoat_roughness_texture_id == -2 &&
        entry.clearcoat_normal_texture_id == -2 &&
        entry.material_uniform_bytes == empty_bytes &&
        entry.forward_decal_uniform_bytes == empty_bytes &&
        mesh3d_extension_bind_group_data_matches(
          entry.material_extension_bind_group_data,
          mesh3d_extension_bind_group_data_empty(),
        ) {
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
      specular_texture_id: -2,
      specular_tint_texture_id: -2,
      clearcoat_texture_id: -2,
      clearcoat_roughness_texture_id: -2,
      clearcoat_normal_texture_id: -2,
      material_uniform_bytes: empty_bytes,
      material_uniform_buffer: material_uniform_buf,
      forward_decal_uniform_bytes: empty_bytes,
      forward_decal_uniform_buffer: None,
      material_extension_bind_group_data: mesh3d_extension_bind_group_data_empty(),
      material_extension_uniform_buffers: [],
      bind_group,
    })
    return bind_group
  }
  if material_layout is Some(layout) &&
    !mesh3d_material_layout_is_standard_compatible(layout) {
    let empty_bytes = Bytes::new(0)
    for entry in backend.mesh3d_material_bg_cache {
      if entry.material_pipeline_id == material_pipeline_id &&
        entry.base_texture_id == -3 &&
        entry.normal_texture_id == -3 &&
        entry.emissive_texture_id == -3 &&
        entry.metallic_roughness_texture_id == -3 &&
        entry.occlusion_texture_id == -3 &&
        entry.depth_texture_id == -3 &&
        entry.anisotropy_texture_id == -3 &&
        entry.specular_texture_id == -3 &&
        entry.specular_tint_texture_id == -3 &&
        entry.clearcoat_texture_id == -3 &&
        entry.clearcoat_roughness_texture_id == -3 &&
        entry.clearcoat_normal_texture_id == -3 &&
        entry.material_uniform_bytes == empty_bytes &&
        entry.forward_decal_uniform_bytes == empty_bytes &&
        mesh3d_extension_bind_group_data_matches(
          entry.material_extension_bind_group_data,
          material_extension_bind_group_data,
        ) {
        return entry.bind_group
      }
    }
    let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
      backend, material_pipeline_id, material_descriptor,
    )
    let custom_uniform_buffers : Array[@wgpu.Buffer] = []
    let builder = @wgpu.BindGroupBuilder::new(
      max_entries=mesh3d_bind_group_layout_descriptor_capacity(layout),
    )
    if !mesh3d_add_material_extension_bindings(
        backend, builder, material_extension_bind_group_data, custom_uniform_buffers,
      ) {
      builder.free()
      for buffer in custom_uniform_buffers {
        buffer.release()
      }
      fatal("wgpu: failed to build mesh3d custom material bind group")
    }
    let bind_group = mesh3d_finish_bind_group_checked(
      backend,
      builder,
      layout_entry.material_bind_group_layout,
      "mgstudio_mesh3d_custom_material_bg",
      "wgpu: failed to build mesh3d custom material bind group",
    )
    let material_uniform_buf = backend.device.create_buffer(
      size=4UL,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
    )
    backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
      material_pipeline_id,
      base_texture_id: -3,
      normal_texture_id: -3,
      emissive_texture_id: -3,
      metallic_roughness_texture_id: -3,
      occlusion_texture_id: -3,
      depth_texture_id: -3,
      anisotropy_texture_id: -3,
      specular_texture_id: -3,
      specular_tint_texture_id: -3,
      clearcoat_texture_id: -3,
      clearcoat_roughness_texture_id: -3,
      clearcoat_normal_texture_id: -3,
      material_uniform_bytes: empty_bytes,
      material_uniform_buffer: material_uniform_buf,
      forward_decal_uniform_bytes: empty_bytes,
      forward_decal_uniform_buffer: None,
      material_extension_bind_group_data,
      material_extension_uniform_buffers: custom_uniform_buffers,
      bind_group,
    })
    return bind_group
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend, material_pipeline_id, material_descriptor,
  )
  let layout = layout_entry.material_bind_group_layout
  let has_anisotropy_texture_binding = match material_layout {
    Some(layout) => mesh3d_bind_group_layout_has_binding(layout, 13)
    None => false
  }
  let has_multi_layer_texture_bindings = match material_layout {
    Some(layout) => mesh3d_bind_group_layout_has_binding(layout, 21)
    None => false
  }
  let has_specular_texture_bindings = match material_layout {
    Some(layout) => mesh3d_bind_group_layout_has_binding(layout, 27)
    None => false
  }
  let anisotropy_texture_cache_id = if has_anisotropy_texture_binding {
    anisotropy_texture.id
  } else {
    -2
  }
  let clearcoat_texture_cache_id = if has_multi_layer_texture_bindings {
    clearcoat_texture.id
  } else {
    -2
  }
  let clearcoat_roughness_texture_cache_id = if has_multi_layer_texture_bindings {
    clearcoat_roughness_texture.id
  } else {
    -2
  }
  let clearcoat_normal_texture_cache_id = if has_multi_layer_texture_bindings {
    clearcoat_normal_texture.id
  } else {
    -2
  }
  let specular_texture_cache_id = if has_specular_texture_bindings {
    specular_texture.id
  } else {
    -2
  }
  let specular_tint_texture_cache_id = if has_specular_texture_bindings {
    specular_tint_texture.id
  } else {
    -2
  }
  for entry in backend.mesh3d_material_bg_cache {
    if entry.material_pipeline_id == material_pipeline_id &&
      entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id &&
      entry.depth_texture_id == depth_texture.id &&
      entry.anisotropy_texture_id == anisotropy_texture_cache_id &&
      entry.specular_texture_id == specular_texture_cache_id &&
      entry.specular_tint_texture_id == specular_tint_texture_cache_id &&
      entry.clearcoat_texture_id == clearcoat_texture_cache_id &&
      entry.clearcoat_roughness_texture_id ==
      clearcoat_roughness_texture_cache_id &&
      entry.clearcoat_normal_texture_id == clearcoat_normal_texture_cache_id &&
      entry.material_uniform_bytes == material_uniform_bytes &&
      entry.forward_decal_uniform_bytes == forward_decal_uniform_bytes &&
      mesh3d_extension_bind_group_data_matches(
        entry.material_extension_bind_group_data,
        material_extension_bind_group_data,
      ) {
      return entry.bind_group
    }
  }
  let material_uniform_buf = backend.device.create_buffer(
    size=MESH3D_STANDARD_MATERIAL_UNIFORM_SIZE,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  backend.queue.write_buffer(material_uniform_buf, 0UL, material_uniform_bytes)
  let forward_decal_uniform_buf = if uses_forward_decal_uniform {
    let buffer = backend.device.create_buffer(
      size=4UL,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    backend.queue.write_buffer(buffer, 0UL, forward_decal_uniform_bytes)
    Some(buffer)
  } else {
    None
  }
  let material_extension_uniform_buffers : Array[@wgpu.Buffer] = []
  let builder = @wgpu.BindGroupBuilder::new(
    max_entries=match material_layout {
      Some(layout) => mesh3d_bind_group_layout_descriptor_capacity(layout)
      None => 13UL
    },
  )
  let mut ok = builder.add_buffer(
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
    builder.add_sampler(12U, depth_texture.sampler)
  if ok && has_anisotropy_texture_binding {
    ok = builder.add_texture_view(13U, anisotropy_texture.view) &&
      builder.add_sampler(14U, anisotropy_texture.sampler)
  }
  if ok && has_multi_layer_texture_bindings {
    ok = builder.add_texture_view(21U, clearcoat_texture.view) &&
      builder.add_sampler(22U, clearcoat_texture.sampler) &&
      builder.add_texture_view(23U, clearcoat_roughness_texture.view) &&
      builder.add_sampler(24U, clearcoat_roughness_texture.sampler) &&
      builder.add_texture_view(25U, clearcoat_normal_texture.view) &&
      builder.add_sampler(26U, clearcoat_normal_texture.sampler)
  }
  if ok && has_specular_texture_bindings {
    ok = builder.add_texture_view(27U, specular_texture.view) &&
      builder.add_sampler(28U, specular_texture.sampler) &&
      builder.add_texture_view(29U, specular_tint_texture.view) &&
      builder.add_sampler(30U, specular_tint_texture.sampler)
  }
  ok = if ok && uses_forward_decal_uniform {
    match forward_decal_uniform_buf {
      Some(buffer) => builder.add_buffer(200U, buffer, size=4UL)
      None => false
    }
  } else {
    ok
  }
  ok = if ok {
    mesh3d_add_material_extension_bindings(
      backend, builder, material_extension_bind_group_data, material_extension_uniform_buffers,
    )
  } else {
    ok
  }
  if !ok {
    builder.free()
    material_uniform_buf.release()
    match forward_decal_uniform_buf {
      Some(buffer) => buffer.release()
      None => ()
    }
    for buffer in material_extension_uniform_buffers {
      buffer.release()
    }
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
    anisotropy_texture_id: anisotropy_texture_cache_id,
    specular_texture_id: specular_texture_cache_id,
    specular_tint_texture_id: specular_tint_texture_cache_id,
    clearcoat_texture_id: clearcoat_texture_cache_id,
    clearcoat_roughness_texture_id: clearcoat_roughness_texture_cache_id,
    clearcoat_normal_texture_id: clearcoat_normal_texture_cache_id,
    material_uniform_bytes,
    material_uniform_buffer: material_uniform_buf,
    forward_decal_uniform_bytes,
    forward_decal_uniform_buffer: forward_decal_uniform_buf,
    material_extension_bind_group_data,
    material_extension_uniform_buffers,
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
fn ensure_transmission_source_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.transmission_source_fallback_texture_id >= 0 {
    if find_texture(backend, backend.transmission_source_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  ensure_sprite_resources(backend)
  let w = 1U
  let h = 1U
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_DST |
    @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let tex = backend.device.create_texture_rgba8_2d_with_usage(w, h, usage)
  let view = tex.create_view()
  let sampler = backend.device.create_sampler_linear_clamp()
  let bind_group = create_cached_texture_bind_group(backend, sampler, view)
  backend.queue.write_texture_rgba8_2d(
    tex,
    w,
    h,
    Bytes::makei(4, _ => (0).to_byte()),
  )
  let id = alloc_id(backend)
  let info = GpuTextureInfo::{
    id,
    width: 1,
    height: 1,
    mip_level_count: 1,
    base_mip_level: 0,
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    texture: tex,
    view,
    sample_view: None,
    msaa_texture: None,
    msaa_view: None,
    sample_count: 1,
    layer_views: [],
    sampler,
    bind_group: Some(bind_group),
  }
  backend.textures.push(info)
  backend.transmission_source_fallback_texture_id = id
  mesh3d_material_cache_clear(backend)
  info
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
  specular_texture_id : Int,
  specular_tint_texture_id : Int,
  clearcoat_texture_id : Int,
  clearcoat_roughness_texture_id : Int,
  clearcoat_normal_texture_id : Int,
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
  let resolved_specular_texture_id = if specular_texture_id < 0 {
    -1
  } else {
    specular_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  let resolved_clearcoat_texture_id = if clearcoat_texture_id < 0 {
    -1
  } else {
    clearcoat_texture_id
  }
  let resolved_clearcoat_roughness_texture_id = if clearcoat_roughness_texture_id <
    0 {
    -1
  } else {
    clearcoat_roughness_texture_id
  }
  let resolved_clearcoat_normal_texture_id = if clearcoat_normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
  } else {
    clearcoat_normal_texture_id
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
  guard resolve_mesh3d_texture(self, resolved_specular_texture_id)
    is Some(specular_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_texture_id)
    is Some(clearcoat_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_roughness_texture_id)
    is Some(clearcoat_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_clearcoat_normal_texture_id)
    is Some(clearcoat_normal_texture) else {
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
      specular_texture,
      specular_tint_texture,
      clearcoat_texture,
      clearcoat_roughness_texture,
      clearcoat_normal_texture,
      mesh3d_standard_material_default_uniform_bytes(),
    ),
  )
}

///|
pub fn GpuBackend::prepare_mesh3d_clustered_decals(
  self : GpuBackend,
  decal_words : Array[UInt],
  texture_ids : Array[Int],
) -> Unit {
  let words = if decal_words.length() == 0 {
    mesh3d_clustered_decals_default_words()
  } else {
    decal_words
  }
  let bytes = u32le_pack(words)
  let size = bytes.length().to_uint64()
  let needs_new_buffer = match self.mesh3d_clustered_decals_buf {
    Some(_) => self.mesh3d_clustered_decals_capacity < size
    None => true
  }
  if needs_new_buffer {
    match self.mesh3d_clustered_decals_buf {
      Some(buffer) => mesh3d_retire_or_release_buffer(self, buffer)
      None => ()
    }
    let buffer = self.device.create_buffer(
      size~,
      usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    self.mesh3d_clustered_decals_buf = Some(buffer)
    self.mesh3d_clustered_decals_capacity = size
  }
  guard self.mesh3d_clustered_decals_buf is Some(buffer) else { return }
  self.queue.write_buffer(buffer, 0UL, bytes)
  self.mesh3d_clustered_decal_texture_ids.clear()
  for texture_id in texture_ids {
    self.mesh3d_clustered_decal_texture_ids.push(texture_id)
  }
  self.mesh3d_clustered_decals_revision = self.mesh3d_clustered_decals_revision +
    1
}

///|
fn ensure_mesh3d_light_probes_buffer_capacity(
  backend : GpuBackend,
  required_size : UInt64,
) -> @wgpu.Buffer? {
  let mut target_size = MESH3D_LIGHT_PROBES_BUFFER_SIZE
  while target_size < required_size {
    target_size = target_size * 2UL
  }
  let needs_new_buffer = match backend.mesh3d_light_probes_buf {
    Some(buffer) => buffer.size() < required_size
    None => true
  }
  if needs_new_buffer {
    match backend.mesh3d_light_probes_buf {
      Some(buffer) => mesh3d_retire_or_release_buffer(backend, buffer)
      None => ()
    }
    backend.mesh3d_light_probes_buf = Some(
      backend.device.create_buffer(
        size=target_size,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    mesh3d_view_bind_group_cache_clear(backend)
  }
  backend.mesh3d_light_probes_buf
}

///|
fn ensure_mesh3d_volumetric_fog_buffer_capacity(
  backend : GpuBackend,
  required_size : UInt64,
) -> @wgpu.Buffer? {
  guard required_size > 0UL else { return None }
  let mut target_size = MESH3D_VOLUMETRIC_FOG_BUFFER_SIZE
  while target_size < required_size {
    target_size = target_size * 2UL
  }
  let needs_new_buffer = match backend.mesh3d_volumetric_fog_buf {
    Some(buffer) => buffer.size() < required_size
    None => true
  }
  if needs_new_buffer {
    match backend.mesh3d_volumetric_fog_buf {
      Some(buffer) => mesh3d_retire_or_release_buffer(backend, buffer)
      None => ()
    }
    backend.mesh3d_volumetric_fog_buf = Some(
      backend.device.create_buffer(
        size=target_size,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
    backend.mesh3d_volumetric_fog_capacity = target_size
  }
  backend.mesh3d_volumetric_fog_buf
}

///|
fn ensure_mesh3d_volumetric_fog_bind_group_layouts(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.mesh3d_volumetric_fog_bgls.length() ==
    MESH3D_VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_COUNT {
    return
  }
  backend.mesh3d_volumetric_fog_bgls.clear()
  let uniform_stage = ss(
    @wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT,
  )
  let fragment_stage = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  for bits in 0..<MESH3D_VOLUMETRIC_FOG_BIND_GROUP_LAYOUT_COUNT {
    let multisampled = (bits & 1) != 0
    let density_texture = (bits & 2) != 0
    let max_entries = if density_texture { 4UL } else { 2UL }
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries~)
    let mut ok = builder.add_buffer(
        0U,
        uniform_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=true,
        min_binding_size=MESH3D_VOLUMETRIC_FOG_UNIFORM_SIZE,
      ) &&
      builder.add_texture(
        1U,
        fragment_stage,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        multisampled~,
      )
    if density_texture {
      ok = ok &&
        builder.add_texture(
          2U,
          fragment_stage,
          @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
          @wgpu.TEXTURE_VIEW_DIMENSION_3D,
        ) &&
        builder.add_sampler(
          3U,
          fragment_stage,
          @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
        )
    }
    if !ok {
      builder.free()
      fatal("wgpu: failed to build mesh3d volumetric fog bind group layout")
    }
    backend.mesh3d_volumetric_fog_bgls.push(
      builder.finish(
        backend.device,
        label="mgstudio_mesh3d_volumetric_fog_bgl_" + bits.to_string(),
      ),
    )
  }
}

///|
pub fn GpuBackend::prepare_mesh3d_volumetric_fog_uniforms(
  self : GpuBackend,
  volumetric_fog_uniform_bytes : Bytes,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_volumetric_fog_bind_group_layouts(self)
  let required_size = volumetric_fog_uniform_bytes.length().to_uint64()
  guard ensure_mesh3d_volumetric_fog_buffer_capacity(self, required_size)
    is Some(buffer) else {
    return
  }
  self.queue.write_buffer(buffer, 0UL, volumetric_fog_uniform_bytes)
}

///|
pub fn GpuBackend::prepare_mesh3d_light_probes(
  self : GpuBackend,
  light_probes_uniform_bytes : Bytes,
  uniform_offset : UInt,
  diffuse_texture_ids : Array[Int],
  specular_texture_ids : Array[Int],
  irradiance_volume_texture_ids : Array[Int],
) -> Unit {
  guard self.pass_state is Some(pass_state) else { return }
  self.pass_state = Some(GpuPassState::{
    ..pass_state,
    environment_diffuse_texture_ids: diffuse_texture_ids,
    environment_specular_texture_ids: specular_texture_ids,
    irradiance_volume_texture_ids,
    mesh3d_light_probes_uniform_bytes: Some(light_probes_uniform_bytes),
    light_probes_uniform_offset: uniform_offset,
  })
  let write_offset = uniform_offset.to_uint64()
  let required_size = write_offset +
    light_probes_uniform_bytes.length().to_uint64()
  if ensure_mesh3d_light_probes_buffer_capacity(self, required_size)
    is Some(light_probes_buf) {
    self.queue.write_buffer(
      light_probes_buf, write_offset, light_probes_uniform_bytes,
    )
  }
}

///|
pub fn GpuBackend::prepare_mesh3d_view_bind_group(
  self : GpuBackend,
  transmission_source_texture_id : Int,
  point_shadow_texture_id : Int,
  directional_shadow_texture_id : Int,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  prepass_depth_texture_id : Int,
  prepass_normal_texture_id : Int,
  prepass_motion_vector_texture_id : Int,
  prepass_deferred_texture_id : Int,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_pipeline_layout_resources(self)
  let resolved_transmission_source_texture_id = if transmission_source_texture_id <
    0 {
    ensure_transmission_source_fallback_texture(self).id
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
      prepass_depth_texture_id,
      prepass_normal_texture_id,
      prepass_motion_vector_texture_id,
      prepass_deferred_texture_id,
    ),
  )
}
