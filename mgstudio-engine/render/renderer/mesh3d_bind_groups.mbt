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
fn mesh3d_view_bg_cache_get_or_create(
  backend : GpuBackend,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
  directional_shadow_texture : GpuTextureInfo,
  environment_diffuse_texture : GpuTextureInfo,
  environment_specular_texture : GpuTextureInfo,
) -> (@wgpu.BindGroup, @wgpu.BindGroup) raise GpuBackendError {
  for entry in backend.mesh3d_view_bg_cache {
    if entry.transmission_source_texture_id == transmission_source_texture.id &&
      entry.point_shadow_texture_id == point_shadow_texture.id &&
      entry.directional_shadow_texture_id == directional_shadow_texture.id &&
      entry.environment_diffuse_texture_id == environment_diffuse_texture.id &&
      entry.environment_specular_texture_id == environment_specular_texture.id {
      return (entry.bind_group, entry.binding_arrays_bind_group)
    }
  }
  let layout = match backend.mesh3d_bgl_view {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d view bind group layout")
  }
  let binding_arrays_layout = match backend.mesh3d_bgl_binding_arrays {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d binding-array bind group layout")
  }
  let view_buf = match backend.mesh3d_view_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d view uniform buffer")
  }
  let lights_buf = match backend.mesh3d_lights_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d lights uniform buffer")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let directional_shadow_sample_view = match
    directional_shadow_texture.sample_view {
    Some(view) => view
    None => directional_shadow_texture.view
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(0U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_buffer(1U, lights_buf, size=MESH3D_LIGHTS_BUFFER_SIZE) &&
    builder.add_texture_view(2U, point_shadow_sample_view) &&
    builder.add_sampler(3U, point_shadow_compare_sampler) &&
    builder.add_texture_view(5U, directional_shadow_sample_view) &&
    builder.add_sampler(6U, point_shadow_compare_sampler) &&
    builder.add_texture_view(25U, transmission_source_texture.view) &&
    builder.add_sampler(26U, transmission_source_texture.sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d view bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_view_bg",
  )
  let binding_arrays_builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let binding_arrays_ok = binding_arrays_builder.add_texture_view(
      0U,
      environment_diffuse_texture.view,
    ) &&
    binding_arrays_builder.add_texture_view(
      1U,
      environment_specular_texture.view,
    ) &&
    binding_arrays_builder.add_sampler(2U, environment_diffuse_texture.sampler)
  if !binding_arrays_ok {
    binding_arrays_builder.free()
    fatal("wgpu: failed to build mesh3d binding-array bind group")
  }
  let binding_arrays_bind_group = binding_arrays_builder.finish(
    backend.device,
    binding_arrays_layout,
    label="mgstudio_mesh3d_binding_arrays_bg",
  )
  backend.mesh3d_view_bg_cache.push(Mesh3dViewBindGroupCacheEntry::{
    transmission_source_texture_id: transmission_source_texture.id,
    point_shadow_texture_id: point_shadow_texture.id,
    directional_shadow_texture_id: directional_shadow_texture.id,
    environment_diffuse_texture_id: environment_diffuse_texture.id,
    environment_specular_texture_id: environment_specular_texture.id,
    bind_group,
    binding_arrays_bind_group,
  })
  (bind_group, binding_arrays_bind_group)
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
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
  for entry in backend.mesh3d_material_bg_cache {
    if entry.base_texture_id == base_texture.id &&
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
  let layout = match backend.mesh3d_bgl_material {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d material bind group layout")
  }
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
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_material_bg",
  )
  backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
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
    -1
  } else {
    environment_diffuse_texture_id
  }
  let resolved_environment_specular_texture_id = if environment_specular_texture_id <
    0 {
    -1
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
      self, transmission_source_texture, point_shadow_texture, directional_shadow_texture,
      environment_diffuse_texture, environment_specular_texture,
    ),
  )
}
