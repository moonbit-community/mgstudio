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

// Bevy-aligned `pbr/render/mesh` container.

///|
pub struct Render3dMeshRuntimeState {
  mesh_upload_cache : Map[Int, Int]
  morph_target_texture_cache : Map[Int, Int]
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d]
  mesh_vertex_buffer_layouts : @mesh.MeshVertexBufferLayouts
  binding_arrays_are_usable : Bool
  clustered_decals_are_usable : Bool
  specialized_material_pipelines : @material.SpecializedMeshPipelines
  specialized_prepass_material_pipelines : @material.SpecializedMeshPipelines
}

///|
pub fn Render3dMeshRuntimeState::new() -> Render3dMeshRuntimeState {
  Render3dMeshRuntimeState::{
    mesh_upload_cache: {},
    morph_target_texture_cache: {},
    mesh_preprocess_static_cache: {},
    mesh_vertex_buffer_layouts: @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts(),
    binding_arrays_are_usable: false,
    clustered_decals_are_usable: true,
    specialized_material_pipelines: @material.SpecializedMeshPipelines::new(),
    specialized_prepass_material_pipelines: @material.SpecializedMeshPipelines::new(),
  }
}

///|
pub fn Render3dMeshRuntimeState::with_binding_arrays_are_usable(
  self : Render3dMeshRuntimeState,
  binding_arrays_are_usable : Bool,
) -> Render3dMeshRuntimeState {
  Render3dMeshRuntimeState::{ ..self, binding_arrays_are_usable, }
}

///|
pub let render3d_mesh_runtime_state_key : @ecs.ResourceKey[
  Render3dMeshRuntimeState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::Render3dMeshRuntimeState")

///|
pub impl @app.Resource for Render3dMeshRuntimeState with fn resource() {
  render3d_mesh_runtime_state_key
}

///|
pub fn ensure_render3d_mesh_runtime_state_resource(world : @ecs.World) -> Unit {
  if world.get_resource(Render3dMeshRuntimeState::resource()) is None {
    world.insert_resource(
      Render3dMeshRuntimeState::resource(),
      Render3dMeshRuntimeState::new(),
    )
  }
}

///|
pub fn render3d_mesh_runtime_state_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dMeshRuntimeState] {
  ensure_render3d_mesh_runtime_state_resource(world)
  match world.get_resource_mut(Render3dMeshRuntimeState::resource()) {
    Some(state) => state
    None => abort("Missing Render3dMeshRuntimeState resource in render world")
  }
}

///|
pub fn render3d_upload_mesh_handle_cached(
  mesh_runtime_state_value : Render3dMeshRuntimeState,
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int {
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return -1
  }
  match mesh_runtime_state_value.mesh_upload_cache.get(mesh_handle_id) {
    Some(mesh_id) =>
      if mesh_id > 0 && @render_gpu.host_gpu_mesh_info(mesh_id) is Some(_) {
        mesh_id
      } else {
        mesh_runtime_state_value.mesh_preprocess_static_cache.remove(
          mesh_handle_id,
        )
        let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
          mesh_handle,
        )
        mesh_runtime_state_value.mesh_upload_cache.set(
          mesh_handle_id, uploaded_mesh_id,
        )
        uploaded_mesh_id
      }
    None => {
      let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
        mesh_handle,
      )
      mesh_runtime_state_value.mesh_upload_cache.set(
        mesh_handle_id, uploaded_mesh_id,
      )
      uploaded_mesh_id
    }
  }
}

///|
pub struct Render3dMeshUploadCacheState {
  clear_count : Int
}

///|
pub fn Render3dMeshUploadCacheState::Render3dMeshUploadCacheState() -> Render3dMeshUploadCacheState {
  Render3dMeshUploadCacheState::{ clear_count: 0 }
}

///|
pub fn render3d_mesh_upload_cache_state_after_clear(
  state : Render3dMeshUploadCacheState,
) -> Render3dMeshUploadCacheState {
  Render3dMeshUploadCacheState::{ clear_count: state.clear_count + 1 }
}

///|
pub fn render3d_clear_mesh_upload_cache(
  mesh_runtime_state_value : Render3dMeshRuntimeState,
) -> Unit {
  mesh_runtime_state_value.mesh_upload_cache.clear()
}

///|
fn render3d_mesh_handle_alive(mesh_handle_id : Int) -> Bool {
  if mesh_handle_id < 0 {
    return false
  }
  @sprite.render_mesh_asset_get(@asset.Handle::new(mesh_handle_id)) is Some(_)
}

///|
pub fn render3d_sweep_mesh_runtime_caches(
  mesh_runtime_state_value : Render3dMeshRuntimeState,
) -> Unit {
  let stale_upload_cache_keys : Array[Int] = []
  for entry in mesh_runtime_state_value.mesh_upload_cache.iter() {
    let (mesh_handle_id, _mesh_id) = entry
    if !render3d_mesh_handle_alive(mesh_handle_id) {
      stale_upload_cache_keys.push(mesh_handle_id)
      ignore(@sprite.render2d_delete_uploaded_mesh_handle_id(mesh_handle_id))
    }
  }
  for mesh_handle_id in stale_upload_cache_keys {
    mesh_runtime_state_value.mesh_upload_cache.remove(mesh_handle_id)
  }
  let stale_morph_target_texture_keys : Array[Int] = []
  for entry in mesh_runtime_state_value.morph_target_texture_cache.iter() {
    let (mesh_handle_id, _texture_id) = entry
    if !render3d_mesh_handle_alive(mesh_handle_id) {
      stale_morph_target_texture_keys.push(mesh_handle_id)
    }
  }
  for mesh_handle_id in stale_morph_target_texture_keys {
    mesh_runtime_state_value.morph_target_texture_cache.remove(mesh_handle_id)
  }
  let stale_preprocess_cache_keys : Array[Int] = []
  for entry in mesh_runtime_state_value.mesh_preprocess_static_cache.iter() {
    let (mesh_handle_id, _metadata) = entry
    if !render3d_mesh_handle_alive(mesh_handle_id) {
      stale_preprocess_cache_keys.push(mesh_handle_id)
    }
  }
  for mesh_handle_id in stale_preprocess_cache_keys {
    mesh_runtime_state_value.mesh_preprocess_static_cache.remove(mesh_handle_id)
  }
}

///|
pub(all) struct MeshGpuDrawPayload3d {
  mesh_id : Int
  preprocess_camera_key_hi : Int
  preprocess_camera_key_lo : Int
  draw_storage_index : Int
  indirect_kind : Int
  indirect_parameters_index : Int
  indirect_draw_count : Int
  world_from_local : @math.Affine3
  previous_world_from_local : @math.Affine3
  transform : @transform.Transform
  previous_transform : @transform.Transform
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
  texture_id : Int
  uv_transform : @transform.Affine2
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  emissive : @color.Color
  emissive_exposure_weight : Float
  metallic : Float
  anisotropy_texture_id : Int
  anisotropy_rotation : Float
  specular_tint_texture_id : Int
  clearcoat_texture_id : Int
  clearcoat_roughness_texture_id : Int
  clearcoat_normal_texture_id : Int
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  surface_roughness : Float
  reflectance : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  attenuation_color : @color.Color
  attenuation_distance : Float
  clearcoat : Float
  clearcoat_perceptual_roughness : Float
  alpha_cutoff : Float
  material_flags : UInt
  forward_decal_inv_depth_fade_factor : Float
  lightmap_exposure : Float
  lightmap_texture_id : Int
  lightmap_uv_min_x : Float
  lightmap_uv_min_y : Float
  lightmap_uv_max_x : Float
  lightmap_uv_max_y : Float
  deferred_lighting_pass_id : Int
  transmission_source_texture_id : Int
  transmission_blur_taps : Float
  transmission_steps : Float
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  environment_map_intensity : Float
  environment_map_rotation : @math.Quat
  specular_tint : @color.Color
  anisotropy_strength : Float
  max_relief_mapping_search_steps : Float
  mesh_flags : UInt
  cull_mode : Int
  vertex_shader_path : String?
  fragment_shader_path : String?
  material_extension_bind_group_data : @render_resource.MaterialBindGroupResolvedData
  material_pipeline_id : @material.CachedRenderPipelineId?
  skinning_key_hi : Int
  skinning_key_lo : Int
  morph_weights_index : Int
  previous_morph_weights_index : Int
  morph_targets_texture_id : Int
}

///|
fn render3d_transform_affine(transform : @transform.Transform) -> @math.Affine3 {
  @math.Affine3::from_scale_rotation_translation(
    transform.scale,
    transform.rotation,
    transform.translation,
  )
}

///|
fn render3d_affine3_transpose_values(affine : @math.Affine3) -> Array[Float] {
  [
    affine.matrix3.x_axis.x,
    affine.matrix3.y_axis.x,
    affine.matrix3.z_axis.x,
    affine.translation.x,
    affine.matrix3.x_axis.y,
    affine.matrix3.y_axis.y,
    affine.matrix3.z_axis.y,
    affine.translation.y,
    affine.matrix3.x_axis.z,
    affine.matrix3.y_axis.z,
    affine.matrix3.z_axis.z,
    affine.translation.z,
  ]
}

///|
pub fn render3d_resolve_material_extension_bind_group_data(
  extension : @material.ExtendedMaterialMetadata3d?,
) -> @render_resource.MaterialBindGroupResolvedData {
  guard extension is Some(extension0) else {
    return @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData()
  }
  let entries : Array[@render_resource.MaterialBindGroupResolvedEntry] = []
  for binding in extension0.extension_bind_group_bindings() {
    match binding.resource() {
      @material.MaterialExtensionBindingResource3d::Texture(image) =>
        entries.push(
          @render_resource.MaterialBindGroupResolvedEntry::texture(
            binding.binding(),
            image.id(),
          ),
        )
      @material.MaterialExtensionBindingResource3d::Sampler(image) =>
        entries.push(
          @render_resource.MaterialBindGroupResolvedEntry::sampler(
            binding.binding(),
            image.id(),
          ),
        )
      @material.MaterialExtensionBindingResource3d::Uniform(bytes) =>
        entries.push(
          @render_resource.MaterialBindGroupResolvedEntry::uniform(
            binding.binding(),
            bytes,
          ),
        )
    }
  }
  @render_resource.MaterialBindGroupResolvedData::new(entries)
}

///|
pub fn render3d_build_mesh_gpu_draw_payload(
  mesh_id : Int,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
  material : @material.StandardMaterial,
  transform : @transform.Transform,
  previous_transform : @transform.Transform,
  draw_color_r : Float,
  draw_color_g : Float,
  draw_color_b : Float,
  draw_alpha : Float,
  texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
  clearcoat_texture_id : Int,
  clearcoat_roughness_texture_id : Int,
  clearcoat_normal_texture_id : Int,
  draw_surface_roughness : Float,
  draw_reflectance : Float,
  draw_diffuse_transmission : Float,
  draw_specular_transmission : Float,
  draw_thickness : Float,
  draw_ior : Float,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  environment_map_intensity : Float,
  environment_map_rotation : @math.Quat,
  specular_tint : @color.Color,
  anisotropy_strength : Float,
  max_relief_mapping_search_steps : Float,
  mesh_flags : UInt,
  draw_flags : Int,
  forward_decal? : Bool = false,
  forward_decal_inv_depth_fade_factor? : Float = 1.0F / 8.0F,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  material_extension_bind_group_data? : @render_resource.MaterialBindGroupResolvedData = @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
  material_pipeline_id? : @material.CachedRenderPipelineId? = None,
  skinning_key_hi? : Int = -1,
  skinning_key_lo? : Int = -1,
  morph_weights_index? : Int = -1,
  previous_morph_weights_index? : Int = -1,
  morph_targets_texture_id? : Int = -1,
  lightmap_texture_id? : Int = -1,
  lightmap_uv_min_x? : Float = 0.0F,
  lightmap_uv_min_y? : Float = 0.0F,
  lightmap_uv_max_x? : Float = 0.0F,
  lightmap_uv_max_y? : Float = 0.0F,
  world_from_local? : @math.Affine3? = None,
  previous_world_from_local? : @math.Affine3? = None,
) -> MeshGpuDrawPayload3d {
  let material_flags = render3d_standard_material_flags(
    material,
    texture_id,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    anisotropy_texture_id,
    specular_tint_texture_id,
    forward_decal~,
  )
  let resolved_world_from_local = match world_from_local {
    Some(affine) => affine
    None => render3d_transform_affine(transform)
  }
  let resolved_previous_world_from_local = match previous_world_from_local {
    Some(affine) => affine
    None => render3d_transform_affine(previous_transform)
  }
  MeshGpuDrawPayload3d::{
    mesh_id,
    preprocess_camera_key_hi,
    preprocess_camera_key_lo,
    draw_storage_index,
    indirect_kind,
    indirect_parameters_index,
    indirect_draw_count: 1,
    world_from_local: resolved_world_from_local,
    previous_world_from_local: resolved_previous_world_from_local,
    transform,
    previous_transform,
    color_r: draw_color_r,
    color_g: draw_color_g,
    color_b: draw_color_b,
    color_a: draw_alpha,
    texture_id,
    uv_transform: material.uv_transform,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    emissive: material.emissive,
    emissive_exposure_weight: material.emissive_exposure_weight,
    metallic: material.metallic,
    anisotropy_texture_id,
    anisotropy_rotation: material.anisotropy_rotation,
    specular_tint_texture_id,
    clearcoat_texture_id,
    clearcoat_roughness_texture_id,
    clearcoat_normal_texture_id,
    parallax_depth_scale: material.parallax_depth_scale,
    max_parallax_layer_count: material.max_parallax_layer_count,
    surface_roughness: draw_surface_roughness,
    reflectance: draw_reflectance,
    diffuse_transmission: draw_diffuse_transmission,
    specular_transmission: draw_specular_transmission,
    thickness: draw_thickness,
    ior: draw_ior,
    attenuation_color: material.attenuation_color,
    attenuation_distance: material.attenuation_distance,
    clearcoat: material.clearcoat,
    clearcoat_perceptual_roughness: material.clearcoat_perceptual_roughness,
    alpha_cutoff: render3d_standard_material_alpha_cutoff(material.alpha_mode),
    material_flags,
    forward_decal_inv_depth_fade_factor,
    lightmap_exposure: material.lightmap_exposure,
    lightmap_texture_id,
    lightmap_uv_min_x,
    lightmap_uv_min_y,
    lightmap_uv_max_x,
    lightmap_uv_max_y,
    deferred_lighting_pass_id: material.deferred_lighting_pass_id,
    transmission_source_texture_id,
    transmission_blur_taps,
    transmission_steps,
    point_shadow_texture_id,
    point_shadow_enabled,
    point_shadow_depth_bias,
    environment_diffuse_texture_id,
    environment_specular_texture_id,
    environment_map_intensity,
    environment_map_rotation,
    specular_tint,
    anisotropy_strength,
    max_relief_mapping_search_steps,
    mesh_flags,
    cull_mode: render3d_cull_mode_value(material, draw_flags),
    vertex_shader_path,
    fragment_shader_path,
    material_extension_bind_group_data,
    material_pipeline_id,
    skinning_key_hi,
    skinning_key_lo,
    morph_weights_index,
    previous_morph_weights_index,
    morph_targets_texture_id,
  }
}

///|
pub fn render3d_host_main_pass_draw_entry(
  payload : MeshGpuDrawPayload3d,
) -> @render_gpu.HostMesh3dMainPassDrawEntry {
  let first_vertex_index = match
    @render_gpu.host_gpu_mesh_info(payload.mesh_id) {
    Some(mesh_info) => mesh_info.vertex_start().reinterpret_as_uint()
    None => 0U
  }
  @render_gpu.host_mesh3d_main_pass_draw_entry(
    draw_storage_index=payload.draw_storage_index,
    x=payload.transform.translation.x,
    y=payload.transform.translation.y,
    z=payload.transform.translation.z,
    rotation_x=payload.transform.rotation.x,
    rotation_y=payload.transform.rotation.y,
    rotation_z=payload.transform.rotation.z,
    rotation_w=payload.transform.rotation.w,
    scale_x=payload.transform.scale.x,
    scale_y=payload.transform.scale.y,
    scale_z=payload.transform.scale.z,
    world_from_local=Some(
      render3d_affine3_transpose_values(payload.world_from_local),
    ),
    color_r=payload.color_r,
    color_g=payload.color_g,
    color_b=payload.color_b,
    color_a=payload.color_a,
    texture_id=payload.texture_id,
    uv_transform_a=payload.uv_transform.a,
    uv_transform_b=payload.uv_transform.b,
    uv_transform_c=payload.uv_transform.c,
    uv_transform_d=payload.uv_transform.d,
    uv_transform_tx=payload.uv_transform.tx,
    uv_transform_ty=payload.uv_transform.ty,
    uv_transform_mode=1.0F,
    normal_texture_id=payload.normal_texture_id,
    emissive_texture_id=payload.emissive_texture_id,
    metallic_roughness_texture_id=payload.metallic_roughness_texture_id,
    occlusion_texture_id=payload.occlusion_texture_id,
    depth_texture_id=payload.depth_texture_id,
    emissive_r=payload.emissive.r,
    emissive_g=payload.emissive.g,
    emissive_b=payload.emissive.b,
    emissive_exposure_weight=payload.emissive_exposure_weight,
    metallic=payload.metallic,
    roughness=payload.surface_roughness,
    reflectance=payload.reflectance,
    parallax_depth_scale=payload.parallax_depth_scale,
    max_parallax_layer_count=payload.max_parallax_layer_count,
    max_relief_mapping_search_steps=payload.max_relief_mapping_search_steps,
    anisotropy_texture_id=payload.anisotropy_texture_id,
    anisotropy_strength=payload.anisotropy_strength,
    anisotropy_rotation=payload.anisotropy_rotation,
    specular_tint_texture_id=payload.specular_tint_texture_id,
    clearcoat_texture_id=payload.clearcoat_texture_id,
    clearcoat_roughness_texture_id=payload.clearcoat_roughness_texture_id,
    clearcoat_normal_texture_id=payload.clearcoat_normal_texture_id,
    specular_tint_r=payload.specular_tint.r,
    specular_tint_g=payload.specular_tint.g,
    specular_tint_b=payload.specular_tint.b,
    diffuse_transmission=payload.diffuse_transmission,
    specular_transmission=payload.specular_transmission,
    thickness=payload.thickness,
    ior=payload.ior,
    attenuation_color_r=payload.attenuation_color.r,
    attenuation_color_g=payload.attenuation_color.g,
    attenuation_color_b=payload.attenuation_color.b,
    attenuation_distance=payload.attenuation_distance,
    clearcoat=payload.clearcoat,
    clearcoat_perceptual_roughness=payload.clearcoat_perceptual_roughness,
    alpha_cutoff=payload.alpha_cutoff,
    material_flags=payload.material_flags,
    lightmap_exposure=payload.lightmap_exposure,
    lightmap_texture_id=payload.lightmap_texture_id,
    lightmap_uv_min_x=payload.lightmap_uv_min_x,
    lightmap_uv_min_y=payload.lightmap_uv_min_y,
    lightmap_uv_max_x=payload.lightmap_uv_max_x,
    lightmap_uv_max_y=payload.lightmap_uv_max_y,
    deferred_lighting_pass_id=payload.deferred_lighting_pass_id,
    point_shadow_texture_id=payload.point_shadow_texture_id,
    point_shadow_enabled=payload.point_shadow_enabled,
    point_shadow_depth_bias=payload.point_shadow_depth_bias,
    mesh_flags=payload.mesh_flags,
    skinning_key_hi=payload.skinning_key_hi,
    morph_weights_index=payload.morph_weights_index,
    previous_morph_weights_index=payload.previous_morph_weights_index,
    morph_targets_texture_id=payload.morph_targets_texture_id,
    first_vertex_index~,
  )
}

///|
pub fn render3d_draw_mesh_gpu_payload(payload : MeshGpuDrawPayload3d) -> Unit {
  @app.timeline_trace_emit_counter_int("render_3d_draw_mesh_commands", 1)
  @render_gpu.host_gpu_draw_mesh3d(
    mesh_id=payload.mesh_id,
    preprocess_camera_key_hi=payload.preprocess_camera_key_hi,
    preprocess_camera_key_lo=payload.preprocess_camera_key_lo,
    draw_storage_index=payload.draw_storage_index,
    indirect_kind=payload.indirect_kind,
    indirect_parameters_index=payload.indirect_parameters_index,
    indirect_draw_count=payload.indirect_draw_count,
    x=payload.transform.translation.x,
    y=payload.transform.translation.y,
    z=payload.transform.translation.z,
    rotation_x=payload.transform.rotation.x,
    rotation_y=payload.transform.rotation.y,
    rotation_z=payload.transform.rotation.z,
    rotation_w=payload.transform.rotation.w,
    scale_x=payload.transform.scale.x,
    scale_y=payload.transform.scale.y,
    scale_z=payload.transform.scale.z,
    previous_x=payload.previous_transform.translation.x,
    previous_y=payload.previous_transform.translation.y,
    previous_z=payload.previous_transform.translation.z,
    previous_rotation_x=payload.previous_transform.rotation.x,
    previous_rotation_y=payload.previous_transform.rotation.y,
    previous_rotation_z=payload.previous_transform.rotation.z,
    previous_rotation_w=payload.previous_transform.rotation.w,
    previous_scale_x=payload.previous_transform.scale.x,
    previous_scale_y=payload.previous_transform.scale.y,
    previous_scale_z=payload.previous_transform.scale.z,
    world_from_local=Some(
      render3d_affine3_transpose_values(payload.world_from_local),
    ),
    previous_world_from_local=Some(
      render3d_affine3_transpose_values(payload.previous_world_from_local),
    ),
    color_r=payload.color_r,
    color_g=payload.color_g,
    color_b=payload.color_b,
    color_a=payload.color_a,
    texture_id=payload.texture_id,
    uv_transform_a=payload.uv_transform.a,
    uv_transform_b=payload.uv_transform.b,
    uv_transform_c=payload.uv_transform.c,
    uv_transform_d=payload.uv_transform.d,
    uv_transform_tx=payload.uv_transform.tx,
    uv_transform_ty=payload.uv_transform.ty,
    uv_transform_mode=1.0F,
    normal_texture_id=payload.normal_texture_id,
    emissive_texture_id=payload.emissive_texture_id,
    metallic_roughness_texture_id=payload.metallic_roughness_texture_id,
    occlusion_texture_id=payload.occlusion_texture_id,
    depth_texture_id=payload.depth_texture_id,
    emissive_r=payload.emissive.r,
    emissive_g=payload.emissive.g,
    emissive_b=payload.emissive.b,
    metallic=payload.metallic,
    roughness=payload.surface_roughness,
    reflectance=payload.reflectance,
    parallax_depth_scale=payload.parallax_depth_scale,
    max_parallax_layer_count=payload.max_parallax_layer_count,
    max_relief_mapping_search_steps=payload.max_relief_mapping_search_steps,
    anisotropy_texture_id=payload.anisotropy_texture_id,
    anisotropy_strength=payload.anisotropy_strength,
    anisotropy_rotation=payload.anisotropy_rotation,
    specular_tint_texture_id=payload.specular_tint_texture_id,
    specular_tint_r=payload.specular_tint.r,
    specular_tint_g=payload.specular_tint.g,
    specular_tint_b=payload.specular_tint.b,
    diffuse_transmission=payload.diffuse_transmission,
    specular_transmission=payload.specular_transmission,
    thickness=payload.thickness,
    ior=payload.ior,
    attenuation_color_r=payload.attenuation_color.r,
    attenuation_color_g=payload.attenuation_color.g,
    attenuation_color_b=payload.attenuation_color.b,
    attenuation_distance=payload.attenuation_distance,
    clearcoat=payload.clearcoat,
    clearcoat_perceptual_roughness=payload.clearcoat_perceptual_roughness,
    alpha_cutoff=payload.alpha_cutoff,
    material_flags=payload.material_flags,
    forward_decal_inv_depth_fade_factor=payload.forward_decal_inv_depth_fade_factor,
    material_pipeline_id=match payload.material_pipeline_id {
      Some(id) => id.id()
      None => @material.CachedRenderPipelineId::invalid().id()
    },
    lightmap_exposure=payload.lightmap_exposure,
    lightmap_texture_id=payload.lightmap_texture_id,
    lightmap_uv_min_x=payload.lightmap_uv_min_x,
    lightmap_uv_min_y=payload.lightmap_uv_min_y,
    lightmap_uv_max_x=payload.lightmap_uv_max_x,
    lightmap_uv_max_y=payload.lightmap_uv_max_y,
    deferred_lighting_pass_id=payload.deferred_lighting_pass_id,
    transmission_source_texture_id=payload.transmission_source_texture_id,
    transmission_blur_taps=payload.transmission_blur_taps,
    transmission_steps=payload.transmission_steps,
    point_shadow_texture_id=payload.point_shadow_texture_id,
    point_shadow_enabled=payload.point_shadow_enabled,
    point_shadow_depth_bias=payload.point_shadow_depth_bias,
    mesh_flags=payload.mesh_flags,
    environment_diffuse_texture_id=payload.environment_diffuse_texture_id,
    environment_specular_texture_id=payload.environment_specular_texture_id,
    environment_map_intensity=payload.environment_map_intensity,
    environment_map_rotation_x=payload.environment_map_rotation.x,
    environment_map_rotation_y=payload.environment_map_rotation.y,
    environment_map_rotation_z=payload.environment_map_rotation.z,
    environment_map_rotation_w=payload.environment_map_rotation.w,
    cull_mode=payload.cull_mode,
    vertex_shader_path=payload.vertex_shader_path,
    fragment_shader_path=payload.fragment_shader_path,
    material_extension_bind_group_data=payload.material_extension_bind_group_data,
    skinning_key_hi=payload.skinning_key_hi,
    skinning_key_lo=payload.skinning_key_lo,
    morph_weights_index=payload.morph_weights_index,
    previous_morph_weights_index=payload.previous_morph_weights_index,
    morph_targets_texture_id=payload.morph_targets_texture_id,
  )
}
