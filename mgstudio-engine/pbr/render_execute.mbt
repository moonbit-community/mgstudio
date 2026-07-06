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
fn render3d_execute_impl(world : @ecs.World) -> Unit {
  let execute_start = @time.host_time_now()
  let execute_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d",
  )
  fn finish_execute() -> Unit {
    @pbr_render.render3d_set_diagnostic_execute_cpu_ms(
      world,
      (@time.host_time_now() - execute_start) * 1000.0F,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d",
      execute_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  render3d_light_probes_buffer_clear(source_world)
  let sorted_cameras_ref = @render.sorted_cameras_ref_or_abort(world)
  guard render3d_queue_take_frame(world) is Some(queued_frame) else {
    @render.sorted_cameras_clear(sorted_cameras_ref)
    finish_execute()
    return
  }
  let frame_config = queued_frame.frame_config
  render3d_execute_render_cameras(
    world,
    queued_frame.cameras,
    queued_frame.meshes,
    queued_frame.prepared_camera_queues,
    queued_frame.camera_execution_plans,
    frame_config.wireframe_config,
    frame_config.delta_seconds,
  )
  @render.sorted_cameras_clear(sorted_cameras_ref)
  finish_execute()
}

///|
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let sorted_cameras_ref = @render.sorted_cameras_ref_or_abort(world)
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let morph_uniforms = @pbr_render.morph_uniforms_mut_or_abort(world)
  let skin_uniforms = @pbr_render.skin_uniforms_mut_or_abort(world)
  let world_transform_cache = @pbr_render.render3d_world_transform_cache_mut(
    world,
  )
  world_transform_cache.modify(fn(world_transform_cache_value) {
    @pbr_render.render3d_world_transform_cache_begin_frame(
      world_transform_cache_value,
    )
  })
  let cameras_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_cameras",
  )
  render3d_refresh_sorted_cameras(source_world, sorted_cameras_ref)
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_cameras",
    cameras_trace_start_us,
  )
  let morphs_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_morphs",
  )
  morph_indices.modify(fn(morph_indices_value) {
    morph_uniforms.modify(fn(morph_uniforms_value) {
      render3d_extract_morphs(
        source_world, morph_indices_value, morph_uniforms_value,
      )
    })
  })
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_morphs",
    morphs_trace_start_us,
  )
  let skins_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_skins",
  )
  skin_uniforms.modify(fn(skin_uniforms_value) {
    world_transform_cache.modify(fn(world_transform_cache_value) {
      @pbr_render.render3d_extract_skin_bindings(
        source_world, skin_uniforms_value, world_transform_cache_value,
      )
    })
  })
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "extract_3d_skins",
    skins_trace_start_us,
  )
  @pbr_render.render3d_set_diagnostic_prepared_camera_count(
    world,
    sorted_cameras_ref.peek().len(),
  )
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
}

///|
pub fn render3d_prepare_morphs_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let morph_uniforms = @pbr_render.morph_uniforms_mut_or_abort(world)
  morph_indices.modify(fn(morph_indices_value) {
    morph_uniforms.modify(fn(morph_uniforms_value) {
      render3d_prepare_morphs(
        source_world, morph_indices_value, morph_uniforms_value,
      )
    })
  })
}

///|
pub fn render3d_prepare_skin_bindings_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let skin_uniforms = @pbr_render.skin_uniforms_mut_or_abort(world)
  let world_transform_cache = @pbr_render.render3d_world_transform_cache_mut(
    world,
  )
  skin_uniforms.modify(fn(skin_uniforms_value) {
    world_transform_cache.modify(fn(world_transform_cache_value) {
      @pbr_render.render3d_prepare_skin_bindings_upload(
        source_world, skin_uniforms_value, world_transform_cache_value,
      )
    })
  })
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  render3d_prepare_morphs_system(world)
  render3d_prepare_skin_bindings_system(world)
}

///|
fn render3d_preprocess_camera_upload_state_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn render3d_preprocess_retained_camera_keys(
  queued_frame : Render3dQueuedFrame?,
) -> Array[UInt64] {
  let retained : Array[UInt64] = []
  if queued_frame is Some(frame) {
    for extracted_camera in frame.cameras {
      retained.push(
        render3d_preprocess_camera_upload_state_key(
          extracted_camera.entity.main_entity,
        ),
      )
    }
  }
  retained
}

///|
fn render3d_camera_target_format_raw(camera : Camera3dViewPayload) -> UInt {
  let motion_blur_active = match camera.motion_blur {
    Some(motion_blur) =>
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    None => false
  }
  let bloom_enabled = camera.bloom is Some(_)
  let tonemap_postprocess_enabled = render3d_tonemapping_stage_enabled(
      camera.tonemapping,
      camera.deband_dither,
      camera.hdr_enabled,
      camera.color_grading,
    ) ||
    render3d_effect_stack_enabled(camera.chromatic_aberration, camera.vignette) ||
    render3d_custom_post_process_enabled(camera.custom_post_process3d) ||
    render3d_fxaa_enabled(camera.fxaa) ||
    render3d_cas_enabled(camera.contrast_adaptive_sharpening)
  let auto_exposure_enabled = camera.auto_exposure is Some(_)
  if camera.hdr_enabled ||
    motion_blur_active ||
    bloom_enabled ||
    tonemap_postprocess_enabled ||
    auto_exposure_enabled {
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT
  } else {
    @render_view.extracted_view_target_format_raw()
  }
}

///|
fn render3d_sync_extracted_view_components(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  for extracted_camera in cameras {
    let render_entity = extracted_camera.entity.render_entity
    if !world.is_alive(render_entity) {
      continue
    }
    let camera = extracted_camera.payload.camera
    let target_size = extracted_camera.payload.target_size
    let (viewport_x, viewport_y, viewport_w, viewport_h) = match
      camera.viewport {
      Some(viewport) => {
        let position = viewport.physical_position()
        let size = viewport.physical_size()
        (position.x, position.y, size.x, size.y)
      }
      None => (0, 0, target_size.x, target_size.y)
    }
    let target_format_raw = render3d_camera_target_format_raw(
      extracted_camera.payload,
    )
    try! world.set_by_key(
      render_entity,
      @render_view.ExtractedView::component(),
      @render_view.ExtractedView::new(
        @render_view.RetainedViewEntity::new(
          extracted_camera.entity.main_entity,
        ),
        target_format_raw~,
        viewport_x~,
        viewport_y~,
        viewport_z=viewport_w,
        viewport_w=viewport_h,
        invert_culling=extracted_camera.payload.invert_culling,
      ),
    )
    try! world.set_by_key(
      render_entity,
      @render_view.Msaa::component(),
      extracted_camera.payload.msaa.unwrap_or(@render_view.Msaa::default()),
    )
  }
}

///|
pub fn render3d_prepare_resources_cleanup_system(world : @ecs.World) -> Unit {
  @render.host_gpu_delete_old_mesh3d_preprocess_work_item_buffers(
    retained_camera_keys=render3d_preprocess_retained_camera_keys(
      render3d_queue_frame_snapshot(world),
    ),
  )
}

///|
pub fn render3d_prepare_resources_flush_system(world : @ecs.World) -> Unit {
  match render3d_queue_frame_snapshot(world) {
    Some(frame) =>
      render3d_for_each_prepared_camera(frame, fn(
        camera_entity,
        camera_payload,
        prepared_queue,
      ) {
        render3d_upload_camera_queue_entry(
          camera_entity, camera_payload, prepared_queue,
        )
      })
    None => ()
  }
}

///|
fn render3d_prepare_extracted_mesh_material_bind_group(
  mesh : ExtractedMesh3d,
  prepared_material_bind_groups : Map[String, Bool],
) -> Unit {
  guard mesh.payload.material_draw_data.standard_material()
    is Some(draw_material) else {
    let key = "-1|-1|-1|-1|-1|-1|-1|-1|-1|-1|-1|-1"
    if prepared_material_bind_groups.contains(key) {
      return
    }
    prepared_material_bind_groups.set(key, true)
    @render.host_gpu_prepare_mesh3d_material_bind_group(
      texture_id=-1,
      normal_texture_id=-1,
      emissive_texture_id=-1,
      metallic_roughness_texture_id=-1,
      occlusion_texture_id=-1,
      depth_texture_id=-1,
      anisotropy_texture_id=-1,
      specular_tint_texture_id=-1,
    )
    return
  }
  let mut texture_id = match draw_material.base_color_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut normal_texture_id = match draw_material.normal_map_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut emissive_texture_id = match draw_material.emissive_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut metallic_roughness_texture_id = match
    draw_material.metallic_roughness_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let occlusion_texture_id = match draw_material.occlusion_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let depth_texture_id = match draw_material.depth_map {
    Some(texture) => texture.id()
    None => -1
  }
  let anisotropy_texture_id = match draw_material.anisotropy_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let specular_texture_id = match draw_material.specular_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let specular_tint_texture_id = match draw_material.specular_tint_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_texture_id = match draw_material.clearcoat_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_roughness_texture_id = match
    draw_material.clearcoat_roughness_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_normal_texture_id = match
    draw_material.clearcoat_normal_texture {
    Some(texture) => texture.id()
    None => -1
  }
  if mesh.payload.clustered_decal is Some(clustered_decal) {
    if clustered_decal.base_color_texture is Some(texture) {
      texture_id = texture.id()
    }
    if clustered_decal.normal_map_texture is Some(texture) {
      normal_texture_id = texture.id()
    }
    if clustered_decal.metallic_roughness_texture is Some(texture) {
      metallic_roughness_texture_id = texture.id()
    }
    if clustered_decal.emissive_texture is Some(texture) {
      emissive_texture_id = texture.id()
    }
  }
  let key = "\{texture_id}|\{normal_texture_id}|\{emissive_texture_id}|\{metallic_roughness_texture_id}|\{occlusion_texture_id}|\{depth_texture_id}|\{anisotropy_texture_id}|\{specular_texture_id}|\{specular_tint_texture_id}|\{clearcoat_texture_id}|\{clearcoat_roughness_texture_id}|\{clearcoat_normal_texture_id}"
  if prepared_material_bind_groups.contains(key) {
    return
  }
  prepared_material_bind_groups.set(key, true)
  @render.host_gpu_prepare_mesh3d_material_bind_group(
    texture_id~,
    normal_texture_id~,
    emissive_texture_id~,
    metallic_roughness_texture_id~,
    occlusion_texture_id~,
    depth_texture_id~,
    anisotropy_texture_id~,
    specular_texture_id~,
    specular_tint_texture_id~,
    clearcoat_texture_id~,
    clearcoat_roughness_texture_id~,
    clearcoat_normal_texture_id~,
  )
}

///|
fn render3d_prepare_extracted_camera_view_bind_group(
  camera : ExtractedCamera3d,
) -> Unit {
  let environment_map_state = render3d_camera_environment_map_state(camera)
  @render.host_gpu_prepare_mesh3d_clustered_decals(decal_words=[], texture_ids=[])
  @render.host_gpu_prepare_mesh3d_view_bind_group(
    transmission_source_texture_id=-1,
    point_shadow_texture_id=-1,
    environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
    environment_specular_texture_id=environment_map_state.specular_texture_id,
  )
}

///|
fn render3d_camera_msaa_samples(camera : Camera3dViewPayload) -> Int {
  match camera.msaa {
    Some(msaa) => msaa.samples()
    None => Msaa::default().samples()
  }
}

///|
fn render3d_camera_has_environment_map(camera : Camera3dViewPayload) -> Bool {
  camera.environment_map_light is Some(_) ||
  camera.generated_environment_map_light is Some(_) ||
  camera.atmosphere_environment_map_light is Some(_) ||
  camera.has_environment_light_probes
}

///|
fn render3d_camera_mesh_pipeline_view_key_bits(
  camera : Camera3dViewPayload,
) -> UInt64 {
  let mut bits = mesh_pipeline_key_msaa_bits(
      render3d_camera_msaa_samples(camera),
    ) |
    mesh_pipeline_key_target_format_bits(
      render3d_camera_target_format_raw(camera),
    )
  if camera.depth_prepass_enabled {
    bits = bits | MESH_PIPELINE_KEY_DEPTH_PREPASS
  }
  if camera.normal_prepass_enabled {
    bits = bits | MESH_PIPELINE_KEY_NORMAL_PREPASS
  }
  if camera.motion_vector_prepass_enabled {
    bits = bits | MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
  }
  if camera.deferred_prepass_enabled {
    bits = bits | MESH_PIPELINE_KEY_DEFERRED_PREPASS
  }
  if camera.temporal_jitter is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_TEMPORAL_JITTER
  }
  if render3d_camera_has_environment_map(camera) {
    bits = bits | MESH_PIPELINE_KEY_ENVIRONMENT_MAP
  }
  if camera.irradiance_volume is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_IRRADIANCE_VOLUME
  }
  if camera.screen_space_reflections is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_SCREEN_SPACE_REFLECTIONS
  }
  if camera.oit_settings is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_OIT_ENABLED
  }
  if camera.atmosphere is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_ATMOSPHERE
  }
  if camera.contact_shadows is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_CONTACT_SHADOWS
  }
  if camera.invert_culling {
    bits = bits | MESH_PIPELINE_KEY_INVERT_CULLING
  }
  bits = bits | mesh_pipeline_key_projection_bits(camera.projection)
  bits = bits |
    mesh_pipeline_key_shadow_filter_method_bits(
      match camera.shadow_filtering_method {
        Some(filter_method) => filter_method
        None => ShadowFilteringMethod::default()
      },
    )
  if !camera.hdr_enabled {
    if camera.tonemapping is Some(tonemapping) {
      bits = bits | MESH_PIPELINE_KEY_TONEMAP_IN_SHADER
      bits = bits | mesh_pipeline_key_tonemapping_bits(tonemapping)
    }
    if camera.deband_dither is Some(Enabled) {
      bits = bits | MESH_PIPELINE_KEY_DEBAND_DITHER
    }
  }
  if camera.screen_space_ambient_occlusion is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_SCREEN_SPACE_AMBIENT_OCCLUSION
  }
  if camera.distance_fog is Some(_) {
    bits = bits | MESH_PIPELINE_KEY_DISTANCE_FOG
  }
  if camera.screen_space_transmission is Some(transmission) {
    bits = bits |
      mesh_pipeline_key_screen_space_transmission_bits(transmission.quality)
  }
  bits
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh.rs::ViewKeyCache`.
priv struct Render3dViewSpecializationKey {
  view_key_bits : UInt64
  binding_arrays_are_usable : Bool
  clustered_decals_are_usable : Bool
} derive(Eq)

///|
fn Render3dViewSpecializationKey::new(
  camera : Camera3dViewPayload,
  binding_arrays_are_usable : Bool,
  clustered_decals_are_usable : Bool,
) -> Render3dViewSpecializationKey {
  Render3dViewSpecializationKey::{
    view_key_bits: render3d_camera_mesh_pipeline_view_key_bits(camera),
    binding_arrays_are_usable,
    clustered_decals_are_usable,
  }
}

///|
priv struct Render3dViewKeyCache {
  keys : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    Render3dViewSpecializationKey,
  ]
}

///|
fn Render3dViewKeyCache::Render3dViewKeyCache() -> Render3dViewKeyCache {
  Render3dViewKeyCache::{ keys: @hashmap.HashMap([]) }
}

///|
let ecs_key_render3d_view_key_cache : @ecs.ResourceKey[Render3dViewKeyCache] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewKeyCache",
)

///|
impl @app.Resource for Render3dViewKeyCache with fn resource() {
  ecs_key_render3d_view_key_cache
}

///|
fn render3d_view_key_cache_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dViewKeyCache] {
  if world.get_resource(Render3dViewKeyCache::resource()) is None {
    world.insert_resource(
      Render3dViewKeyCache::resource(),
      Render3dViewKeyCache::Render3dViewKeyCache(),
    )
  }
  match world.get_resource_mut(Render3dViewKeyCache::resource()) {
    Some(value) => value
    None => abort("missing Render3dViewKeyCache resource")
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh.rs::check_views_need_specialization`.
fn render3d_check_views_need_specialization(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  binding_arrays_are_usable : Bool,
  clustered_decals_are_usable : Bool,
) -> Unit {
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtySpecializations resource during pbr view specialization check",
      )
  }
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  render3d_view_key_cache_mut_or_init(world).modify(fn(view_key_cache) {
    for camera in cameras {
      let retained_view_entity = @render_view.RetainedViewEntity::new(
        camera.entity.main_entity,
      )
      live_views.add(retained_view_entity)
      let view_key = Render3dViewSpecializationKey::new(
        camera.payload,
        binding_arrays_are_usable,
        clustered_decals_are_usable,
      )
      match view_key_cache.keys.get(retained_view_entity) {
        Some(current_key) =>
          if current_key != view_key {
            view_key_cache.keys.set(retained_view_entity, view_key)
            dirty_specializations.insert_view(retained_view_entity)
          }
        None => {
          view_key_cache.keys.set(retained_view_entity, view_key)
          dirty_specializations.insert_view(retained_view_entity)
        }
      }
    }
    let stale_views : Array[@render_view.RetainedViewEntity] = []
    for view, _key in view_key_cache.keys {
      if !live_views.contains(view) {
        stale_views.push(view)
      }
    }
    for view in stale_views {
      view_key_cache.keys.remove(view)
    }
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::SpecializationWorkItem`.
priv struct Render3dMaterialSpecializationWorkItemData {
  visible_entity : @core.Entity
  retained_view_entity : @render_view.RetainedViewEntity
  mesh_key : @material.ErasedMeshPipelineKey
  layout : @mesh.MeshVertexBufferLayoutRef
  properties : @material.MaterialProperties
  material_type_tag : String
}

///|
fn render3d_material_specialization_work_item_data(
  world : @ecs.World,
  resolved_material : Render3dResolvedMaterial,
  camera : Camera3dViewPayload,
  retained_view_entity : @render_view.RetainedViewEntity,
  visible_entity : @core.Entity,
  render_mesh_queue_data : RenderMeshQueueData,
) -> Render3dMaterialSpecializationWorkItemData? {
  let material_properties = resolved_material.material_properties()
  let render_mesh_assets = match
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None => return None
  }
  guard render_mesh_assets.get(render_mesh_queue_data.mesh_asset_id())
    is Some(render_mesh) else {
    return None
  }
  let view_key_bits = render3d_camera_mesh_pipeline_view_key_bits(camera)
  let motion_vector_prepass = (
      view_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
    ) !=
    0UL
  let lightmapped = render3d_material_specialization_lightmapped(
    world, visible_entity,
  )
  let lightmap_bicubic_sampling = render3d_material_specialization_lightmap_bicubic_sampling(
    world, visible_entity,
  )
  let visibility_range_dither = render3d_material_specialization_visibility_range_dither(
    world, visible_entity,
  )
  let mesh_key = material_mesh_pipeline_key_for_render_mesh(
    material_properties,
    render_mesh,
    view_key_bits~,
    msaa_samples=render3d_camera_msaa_samples(camera),
    has_previous_skin=motion_vector_prepass &&
      render_mesh_queue_data
      .flags()
      .contains(RenderMeshInstanceFlags::has_previous_skin()),
    has_previous_morph=motion_vector_prepass &&
      render_mesh_queue_data
      .flags()
      .contains(RenderMeshInstanceFlags::has_previous_morph()),
    visibility_range_dither~,
    lightmapped~,
    lightmap_bicubic_sampling~,
  )
  Some(Render3dMaterialSpecializationWorkItemData::{
    visible_entity,
    retained_view_entity,
    mesh_key,
    layout: render_mesh.layout(),
    properties: material_properties,
    material_type_tag: resolved_material.material_type_tag(),
  })
}

///|
fn render3d_prewarm_material_pipeline(
  world : @ecs.World,
  resolved_material : Render3dResolvedMaterial,
  camera : Camera3dViewPayload,
  retained_view_entity : @render_view.RetainedViewEntity,
  visible_entity : @core.Entity,
  render_mesh_queue_data : RenderMeshQueueData,
  specialization_tick : @core.Tick,
) -> @material.CachedRenderPipelineId? {
  match world.get_resource(ecs_key_specialized_material_pipeline_cache) {
    Some(cache) =>
      match cache.pipeline_id(retained_view_entity, visible_entity) {
        Some(pipeline_id) => return Some(pipeline_id)
        None => ()
      }
    None => ()
  }
  guard render3d_material_specialization_work_item_data(
      world, resolved_material, camera, retained_view_entity, visible_entity, render_mesh_queue_data,
    )
    is Some(item) else {
    return None
  }
  guard item.properties.base_specialize is Some(base_specialize) else {
    return None
  }
  let pipeline_key = @material.ErasedMaterialPipelineKey::new(
    item.mesh_key,
    item.properties.material_key,
    item.material_type_tag,
  )
  let pipeline_id = @material.material_specialize_base(
    base_specialize,
    world,
    pipeline_key,
    item.layout,
    item.properties,
  ) catch {
    err =>
      abort(
        "failed to specialize pbr material pipeline for mesh \{render_mesh_queue_data.mesh_asset_id()}: \{err}",
      )
  }
  match world.get_resource_mut(ecs_key_specialized_material_pipeline_cache) {
    Some(cache_ref) =>
      ignore(
        cache_ref.modify(fn(cache) {
          cache.insert(
            item.retained_view_entity,
            item.visible_entity,
            specialization_tick,
            pipeline_id,
          )
        }),
      )
    None =>
      abort(
        "missing SpecializedMaterialPipelineCache resource during pbr material pipeline specialization",
      )
  }
  Some(pipeline_id)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_material_specialization_lightmapped(
  world : @ecs.World,
  visible_entity : @core.Entity,
) -> Bool {
  match world.get_resource(@lightmap.RenderLightmaps::resource()) {
    Some(render_lightmaps) => render_lightmaps.get(visible_entity) is Some(_)
    None => false
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_material_specialization_lightmap_bicubic_sampling(
  world : @ecs.World,
  visible_entity : @core.Entity,
) -> Bool {
  match world.get_resource(@lightmap.RenderLightmaps::resource()) {
    Some(render_lightmaps) =>
      match render_lightmaps.get(visible_entity) {
        Some(render_lightmap) => render_lightmap.bicubic_sampling()
        None => false
      }
    None => false
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_material_specialization_visibility_range_dither(
  world : @ecs.World,
  visible_entity : @core.Entity,
) -> Bool {
  match
    world.get_resource(@render_visibility.RenderVisibilityRanges::resource()) {
    Some(render_visibility_ranges) =>
      render_visibility_ranges.entity_has_crossfading_visibility_ranges(
        visible_entity.id,
      )
    None => false
  }
}

///|
fn render3d_mesh_visibility_class() -> String {
  ecs_key_mesh3d.id().to_string()
}

///|
fn render3d_main_entity_compare(
  left : @render.MainEntity,
  right : @render.MainEntity,
) -> Int {
  let left_bits = left.id().to_bits()
  let right_bits = right.id().to_bits()
  if left_bits < right_bits {
    -1
  } else if left_bits > right_bits {
    1
  } else {
    0
  }
}

///|
fn render3d_visible_pair_compare(
  left : (@core.Entity, @render.MainEntity),
  right : (@core.Entity, @render.MainEntity),
) -> Int {
  render3d_main_entity_compare(left.1, right.1)
}

///|
fn render3d_extract_visible_mesh_pairs(
  source_world : @ecs.World,
  visible_entities : @camera_camera.VisibleEntities,
) -> Array[(@core.Entity, @render.MainEntity)] {
  let pairs : Array[(@core.Entity, @render.MainEntity)] = []
  for main_entity in visible_entities.get(@mesh.ecs_key_mesh3d.id()) {
    pairs.push(
      (
        phase_entity_ref3d_for_world_main(source_world, main_entity).render_entity,
        @render.MainEntity::new(main_entity),
      ),
    )
  }
  pairs.sort_by(render3d_visible_pair_compare)
  pairs
}

///|
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/mod.rs`.
fn render3d_extract_render_visible_entities(
  world : @ecs.World,
  source_world : @ecs.World,
) -> Unit {
  let live_render_views : Map[UInt64, Bool] = {}
  let mesh_visibility_class = render3d_mesh_visibility_class()
  let extracted_views : Array[
    (@core.Entity, @camera_camera.Camera, @camera_camera.VisibleEntities),
  ] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[Camera3d],
        @ecs.Optional[@camera_camera.Camera],
        @ecs.Read[@camera_camera.VisibleEntities],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! camera_query.view(fn(_query_entity, data) {
    let (main_view_entity, (_camera3d, camera_opt, visible_entities)) = data
    let camera = match camera_opt.value() {
      Some(value) => value
      None => @camera_camera.Camera::Camera()
    }
    extracted_views.push((main_view_entity, camera, visible_entities.value()))
  })
  for extracted_view in extracted_views {
    let (main_view_entity, camera, visible_entities) = extracted_view
    let render_view_entity = phase_entity_ref3d_for_world_main(
        source_world, main_view_entity,
      ).render_entity
    if !camera.is_active {
      if world.is_alive(render_view_entity) {
        ignore(
          world.remove_by_key(
            render_view_entity, @render_visibility.ecs_key_render_visible_entities,
          ) catch {
            _ => false
          },
        )
      }
      continue
    }
    guard world.is_alive(render_view_entity) else { continue }
    live_render_views.set(render_view_entity.to_bits(), true)
    let render_visible_entities = match
      (try! world.get_by_key(
        render_view_entity, @render_visibility.ecs_key_render_visible_entities,
      )) {
      Some(value) => value
      None => @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
    }
    let render_visible_mesh_entities = render_visible_entities.class_or_insert(
      mesh_visibility_class,
    )
    render_visible_mesh_entities.prepare_for_new_frame()
    render_visible_mesh_entities.update_cpu_culled_entities(
      render3d_extract_visible_mesh_pairs(source_world, visible_entities),
    )
    render_visible_mesh_entities.sort_added_entities()
    try! world.set_by_key(
      render_view_entity, @render_visibility.ecs_key_render_visible_entities, render_visible_entities,
    )
  }
  let stale_query : @ecs.Query[
    (@core.Entity, @ecs.Read[@render_visibility.RenderVisibleEntities]),
    @ecs.All,
  ] = @ecs.query(world)
  let stale_entities : Array[@core.Entity] = []
  try! stale_query.view(fn(_query_entity, data) {
    let (render_view_entity, _visible_entities) = data
    if !live_render_views.get(render_view_entity.to_bits()).unwrap_or(false) {
      stale_entities.push(render_view_entity)
    }
  })
  for entity in stale_entities {
    ignore(
      world.remove_by_key(
        entity, @render_visibility.ecs_key_render_visible_entities,
      ) catch {
        _ => false
      },
    )
  }
}

///|
fn render3d_retained_view_entities(
  cameras : Array[ExtractedCamera3d],
) -> @hashset.HashSet[@render_view.RetainedViewEntity] {
  let retained_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  for camera in cameras {
    retained_views.add(
      @render_view.RetainedViewEntity::new(camera.entity.main_entity),
    )
  }
  retained_views
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_apply_dirty_material_specialization_cache(
  world : @ecs.World,
  retained_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None => return
  }
  match world.get_resource_mut(ecs_key_specialized_material_pipeline_cache) {
    Some(cache_ref) =>
      cache_ref.modify(fn(cache) {
        for retained_view_entity in retained_views.iter() {
          cache.apply_dirty_specializations_for_view(
            dirty_specializations, retained_view_entity,
          )
        }
        cache.expire_stale_views(retained_views)
      })
    None => ()
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_prepare_pending_mesh_material_queues(
  world : @ecs.World,
  retained_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let pending_queues = match
    world.get_resource_mut(PendingMeshMaterialQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingMeshMaterialQueues resource during pbr material specialization",
      )
  }
  pending_queues.modify(fn(queues) {
    for retained_view_entity in retained_views.iter() {
      ignore(queues.prepare_for_new_frame(retained_view_entity))
    }
    queues.expire_stale_views(retained_views)
  })
}

///|
fn render3d_material_specialization_candidates(
  world : @ecs.World,
  render_view_entity : @core.Entity,
  retained_view_entity : @render_view.RetainedViewEntity,
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_queues : PendingMeshMaterialQueues,
) -> Array[(@core.Entity, @render.MainEntity)] {
  guard (try! world.get_by_key(
      render_view_entity, @render_visibility.ecs_key_render_visible_entities,
    ))
    is Some(visible_entities) else {
    return []
  }
  guard visible_entities.get(render3d_mesh_visibility_class())
    is Some(render_visible_mesh_entities) else {
    return []
  }
  let view_pending_mesh_material_queues = pending_queues
    .queues()
    .view_or_insert(retained_view_entity)
  dirty_specializations.iter_to_specialize(
    retained_view_entity,
    render_visible_mesh_entities,
    view_pending_mesh_material_queues.prev_frame(),
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_candidates(
  world : @ecs.World,
  shadow_light_entity : @core.Entity,
  shadow_visible_retained_view_entity : @render_view.RetainedViewEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_shadow_queues : @pbr_render.PendingShadowQueues,
) -> Array[(@core.Entity, @render.MainEntity)] {
  let shadow_map_visible_entities = match
    (try! world.get_by_key(
      shadow_light_entity, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    )) {
    Some(value) => value
    None => abort("failed to get shadow light visible entities")
  }
  let visible_entities = match
    shadow_map_visible_entities.subview(shadow_visible_retained_view_entity) {
    Some(value) => value
    None => abort("failed to get shadow light visible entities for view")
  }
  guard visible_entities.get(render3d_mesh_visibility_class())
    is Some(render_visible_mesh_entities) else {
    return []
  }
  let view_pending_shadow_queues = match
    pending_shadow_queues.queues().get(retained_view_entity) {
    Some(queues) => queues
    None =>
      abort("missing view PendingShadowQueues during pbr shadow specialization")
  }
  dirty_specializations.iter_to_specialize(
    retained_view_entity,
    render_visible_mesh_entities,
    view_pending_shadow_queues.prev_frame(),
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::get_shadow_map_visible_entities`.
pub fn render3d_shadow_specialization_candidates_for_light(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_shadow_queues : @pbr_render.PendingShadowQueues,
) -> Array[(@core.Entity, @render.MainEntity)] {
  render3d_shadow_specialization_candidates(
    world,
    light_entity.shadow_map_visible_entity(),
    light_entity.shadow_map_visible_retained_view(retained_view_entity),
    retained_view_entity,
    dirty_specializations,
    pending_shadow_queues,
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_enqueue_pending_mesh_material(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Unit {
  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
    None =>
      abort(
        "missing PendingMeshMaterialQueues resource during pbr material specialization",
      )
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
fn render3d_enqueue_view_pending_shadow_material(
  view_pending_shadow_queues : @render.ViewPendingQueues,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Unit {
  view_pending_shadow_queues.push_current(render_entity, visible_entity)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
fn render3d_shadow_specialization_alpha_may_discard(
  alpha_mode : @material.AlphaMode3d,
) -> Bool {
  match alpha_mode {
    Mask(_) | Blend | Premultiplied | Add | AlphaToCoverage => true
    _ => false
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
fn render3d_shadow_specialization_mesh_key(
  light_key : @material.ErasedMeshPipelineKey,
  render_mesh : @render_mesh.RenderMesh,
  material_properties : @material.MaterialProperties,
  render_lightmaps : @lightmap.RenderLightmaps?,
  visible_entity : @render.MainEntity,
) -> @material.ErasedMeshPipelineKey {
  let mut mesh_key_bits = light_key.bits() | render_mesh.key_bits().bits()
  if render_lightmaps is Some(lightmaps) &&
    lightmaps.get(visible_entity.id()) is Some(_) {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_LIGHTMAPPED
  }
  if render3d_shadow_specialization_alpha_may_discard(
      material_properties.alpha_mode,
    ) {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_MAY_DISCARD
  }
  @material.ErasedMeshPipelineKey::new(mesh_key_bits, light_key.type_tag())
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::ShadowSpecializationWorkItem`.
pub struct Render3dShadowSpecializationWorkItemData {
  queue_data : RenderMeshQueueData
  visible_entity : @render.MainEntity
  retained_view_entity : @render_view.RetainedViewEntity
  mesh_key : @material.ErasedMeshPipelineKey
  layout : @mesh.MeshVertexBufferLayoutRef
  properties : @material.MaterialProperties
  material_type_tag : String
}

///|
pub fn Render3dShadowSpecializationWorkItemData::queue_data(
  self : Render3dShadowSpecializationWorkItemData,
) -> RenderMeshQueueData {
  self.queue_data
}

///|
pub fn Render3dShadowSpecializationWorkItemData::mesh_key(
  self : Render3dShadowSpecializationWorkItemData,
) -> @material.ErasedMeshPipelineKey {
  self.mesh_key
}

///|
pub fn Render3dShadowSpecializationWorkItemData::layout(
  self : Render3dShadowSpecializationWorkItemData,
) -> @mesh.MeshVertexBufferLayoutRef {
  self.layout
}

///|
pub fn Render3dShadowSpecializationWorkItemData::properties(
  self : Render3dShadowSpecializationWorkItemData,
) -> @material.MaterialProperties {
  self.properties
}

///|
pub fn Render3dShadowSpecializationWorkItemData::visible_entity(
  self : Render3dShadowSpecializationWorkItemData,
) -> @render.MainEntity {
  self.visible_entity
}

///|
pub fn Render3dShadowSpecializationWorkItemData::retained_view_entity(
  self : Render3dShadowSpecializationWorkItemData,
) -> @render_view.RetainedViewEntity {
  self.retained_view_entity
}

///|
pub fn Render3dShadowSpecializationWorkItemData::material_type_tag(
  self : Render3dShadowSpecializationWorkItemData,
) -> String {
  self.material_type_tag
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_apply_work_item(
  world : @ecs.World,
  item : Render3dShadowSpecializationWorkItemData,
  depth_clip_control_supported : Bool,
) -> Bool {
  guard item.properties.prepass_specialize is Some(prepass_specialize) else {
    return false
  }
  let key = @material.ErasedMaterialPipelineKey::new(
    item.mesh_key,
    item.properties.material_key,
    item.material_type_tag,
  )
  let emulate_unclipped_depth = @pbr_render.light_mesh_pipeline_key_contains_unclipped_depth_ortho(
      item.mesh_key,
    ) &&
    !depth_clip_control_supported
  let is_depth_only_opaque = (
      item.mesh_key.bits() &
      (MESH_PIPELINE_KEY_MAY_DISCARD | MESH_PIPELINE_KEY_PREPASS_READS_MATERIAL)
    ) ==
    0UL &&
    !emulate_unclipped_depth
  let draw_function_label = if is_depth_only_opaque {
    SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL
  } else {
    SHADOWS_DRAW_FUNCTION_LABEL
  }
  guard item.properties.get_draw_function(draw_function_label)
    is Some(draw_function) else {
    return false
  }
  let pipeline_id = @material.material_specialize_prepass(
    prepass_specialize,
    world,
    key,
    item.layout,
    item.properties,
  ) catch {
    _ => return false
  }
  match
    world.get_resource_mut(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) => {
      cache.modify(fn(value) {
        value.insert(
          item.retained_view_entity,
          item.visible_entity,
          pipeline_id,
          draw_function,
        )
      })
      true
    }
    None =>
      abort(
        "missing SpecializedShadowMaterialPipelineCache resource during pbr shadow specialization",
      )
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_apply_work_items(
  world : @ecs.World,
  work_items : Array[Render3dShadowSpecializationWorkItemData],
  all_shadow_views : @hashset.HashSet[@render_view.RetainedViewEntity],
  depth_clip_control_supported : Bool,
) -> Int {
  let mut specialized_count = 0
  for item in work_items {
    if render3d_shadow_specialization_apply_work_item(
        world, item, depth_clip_control_supported,
      ) {
      specialized_count += 1
    }
  }
  work_items.clear()
  match
    world.get_resource_mut(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) =>
      cache.modify(fn(value) { value.expire_stale_views(all_shadow_views) })
    None =>
      abort(
        "missing SpecializedShadowMaterialPipelineCache resource during pbr shadow specialization",
      )
  }
  specialized_count
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::Shadow`.
pub struct Render3dQueuedShadowPhaseItemData {
  render_entity : @core.Entity
  visible_entity : @render.MainEntity
  pipeline_id : @material.CachedRenderPipelineId
  draw_function : @material.DrawFunctionId
  material_bind_group_index : Int?
  mesh_asset_id : Int
  current_uniform_index : UInt
  should_batch : Bool
  slabs : @render_mesh.MeshSlabs
}

///|
pub fn Render3dQueuedShadowPhaseItemData::render_entity(
  self : Render3dQueuedShadowPhaseItemData,
) -> @core.Entity {
  self.render_entity
}

///|
pub fn Render3dQueuedShadowPhaseItemData::visible_entity(
  self : Render3dQueuedShadowPhaseItemData,
) -> @render.MainEntity {
  self.visible_entity
}

///|
pub fn Render3dQueuedShadowPhaseItemData::pipeline_id(
  self : Render3dQueuedShadowPhaseItemData,
) -> @material.CachedRenderPipelineId {
  self.pipeline_id
}

///|
pub fn Render3dQueuedShadowPhaseItemData::draw_function(
  self : Render3dQueuedShadowPhaseItemData,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn Render3dQueuedShadowPhaseItemData::material_bind_group_index(
  self : Render3dQueuedShadowPhaseItemData,
) -> Int? {
  self.material_bind_group_index
}

///|
pub fn Render3dQueuedShadowPhaseItemData::mesh_asset_id(
  self : Render3dQueuedShadowPhaseItemData,
) -> Int {
  self.mesh_asset_id
}

///|
pub fn Render3dQueuedShadowPhaseItemData::current_uniform_index(
  self : Render3dQueuedShadowPhaseItemData,
) -> UInt {
  self.current_uniform_index
}

///|
pub fn Render3dQueuedShadowPhaseItemData::should_batch(
  self : Render3dQueuedShadowPhaseItemData,
) -> Bool {
  self.should_batch
}

///|
pub fn Render3dQueuedShadowPhaseItemData::slabs(
  self : Render3dQueuedShadowPhaseItemData,
) -> @render_mesh.MeshSlabs {
  self.slabs
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::ShadowBatchSetKey`.
pub struct Render3dShadowBatchSetKeyData {
  pipeline_id : @material.CachedRenderPipelineId
  draw_function : @material.DrawFunctionId
  material_bind_group_index : Int?
  slabs : @render_mesh.MeshSlabs
}

///|
pub fn Render3dShadowBatchSetKeyData::new(
  pipeline_id : @material.CachedRenderPipelineId,
  draw_function : @material.DrawFunctionId,
  material_bind_group_index : Int?,
  slabs : @render_mesh.MeshSlabs,
) -> Render3dShadowBatchSetKeyData {
  Render3dShadowBatchSetKeyData::{
    pipeline_id,
    draw_function,
    material_bind_group_index,
    slabs,
  }
}

///|
pub fn Render3dShadowBatchSetKeyData::pipeline_id(
  self : Render3dShadowBatchSetKeyData,
) -> @material.CachedRenderPipelineId {
  self.pipeline_id
}

///|
pub fn Render3dShadowBatchSetKeyData::draw_function(
  self : Render3dShadowBatchSetKeyData,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn Render3dShadowBatchSetKeyData::material_bind_group_index(
  self : Render3dShadowBatchSetKeyData,
) -> Int? {
  self.material_bind_group_index
}

///|
pub fn Render3dShadowBatchSetKeyData::slabs(
  self : Render3dShadowBatchSetKeyData,
) -> @render_mesh.MeshSlabs {
  self.slabs
}

///|
pub fn Render3dShadowBatchSetKeyData::indexed(
  self : Render3dShadowBatchSetKeyData,
) -> Bool {
  self.slabs.index_slab_id() is Some(_)
}

///|
fn render3d_shadow_mesh_slabs_eq(
  lhs : @render_mesh.MeshSlabs,
  rhs : @render_mesh.MeshSlabs,
) -> Bool {
  lhs.vertex_slab_id() == rhs.vertex_slab_id() &&
  lhs.index_slab_id() == rhs.index_slab_id() &&
  lhs.morph_target_slab_id() == rhs.morph_target_slab_id()
}

///|
fn render3d_shadow_batch_set_key_eq(
  lhs : Render3dShadowBatchSetKeyData,
  rhs : Render3dShadowBatchSetKeyData,
) -> Bool {
  lhs.pipeline_id().id() == rhs.pipeline_id().id() &&
  lhs.draw_function().id() == rhs.draw_function().id() &&
  lhs.material_bind_group_index() == rhs.material_bind_group_index() &&
  render3d_shadow_mesh_slabs_eq(lhs.slabs(), rhs.slabs())
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::ShadowBinKey`.
pub struct Render3dShadowBinKeyData {
  mesh_asset_id : Int
}

///|
pub fn Render3dShadowBinKeyData::new(
  mesh_asset_id : Int,
) -> Render3dShadowBinKeyData {
  Render3dShadowBinKeyData::{ mesh_asset_id, }
}

///|
pub fn Render3dShadowBinKeyData::mesh_asset_id(
  self : Render3dShadowBinKeyData,
) -> Int {
  self.mesh_asset_id
}

///|
fn render3d_shadow_bin_key_eq(
  lhs : Render3dShadowBinKeyData,
  rhs : Render3dShadowBinKeyData,
) -> Bool {
  lhs.mesh_asset_id() == rhs.mesh_asset_id()
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::BinnedPhaseItem for Shadow`.
pub fn Render3dQueuedShadowPhaseItemData::batch_set_key(
  self : Render3dQueuedShadowPhaseItemData,
) -> Render3dShadowBatchSetKeyData {
  Render3dShadowBatchSetKeyData::new(
    self.pipeline_id,
    self.draw_function,
    self.material_bind_group_index,
    self.slabs,
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::BinnedPhaseItem for Shadow`.
pub fn Render3dQueuedShadowPhaseItemData::bin_key(
  self : Render3dQueuedShadowPhaseItemData,
) -> Render3dShadowBinKeyData {
  Render3dShadowBinKeyData::new(self.mesh_asset_id)
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::PhaseItemExtraIndex`.
pub(all) enum Render3dShadowPhaseItemExtraIndex {
  NoExtraIndex
  DynamicOffset(Int)
  IndirectParametersIndex(Int, Int, Int?)
} derive(Eq, Debug)

///|
pub fn Render3dShadowPhaseItemExtraIndex::none() -> Render3dShadowPhaseItemExtraIndex {
  NoExtraIndex
}

///|
pub fn Render3dShadowPhaseItemExtraIndex::dynamic_offset(
  offset : Int,
) -> Render3dShadowPhaseItemExtraIndex {
  DynamicOffset(offset)
}

///|
pub fn Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
  range_start : Int,
  range_end : Int,
  batch_set_index? : Int? = None,
) -> Render3dShadowPhaseItemExtraIndex {
  IndirectParametersIndex(range_start, range_end, batch_set_index)
}

///|
pub fn Render3dShadowPhaseItemExtraIndex::indirect_parameters_range(
  self : Render3dShadowPhaseItemExtraIndex,
) -> (Int, Int, Int?)? {
  match self {
    IndirectParametersIndex(range_start, range_end, batch_set_index) =>
      Some((range_start, range_end, batch_set_index))
    _ => None
  }
}

///|
pub(all) struct Render3dShadowUnbatchableBinnedEntityIndices {
  instance_index : Int
  extra_index : Render3dShadowPhaseItemExtraIndex
} derive(Eq, Debug)

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndices::new(
  instance_index : Int,
  extra_index : Render3dShadowPhaseItemExtraIndex,
) -> Render3dShadowUnbatchableBinnedEntityIndices {
  Render3dShadowUnbatchableBinnedEntityIndices::{ instance_index, extra_index }
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndices::instance_index(
  self : Render3dShadowUnbatchableBinnedEntityIndices,
) -> Int {
  self.instance_index
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndices::extra_index(
  self : Render3dShadowUnbatchableBinnedEntityIndices,
) -> Render3dShadowPhaseItemExtraIndex {
  self.extra_index
}

///|
pub(all) enum Render3dShadowUnbatchableBinnedEntityIndexSetKind {
  NoUnbatchableBinnedEntities
  SparseUnbatchableBinnedEntityIndices(Render3dShadowBatchRange, Int?)
  DenseUnbatchableBinnedEntityIndices(
    Array[Render3dShadowUnbatchableBinnedEntityIndices]
  )
} derive(Debug)

///|
pub(all) struct Render3dShadowUnbatchableBinnedEntityIndexSet {
  mut kind : Render3dShadowUnbatchableBinnedEntityIndexSetKind
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::Render3dShadowUnbatchableBinnedEntityIndexSet() -> Render3dShadowUnbatchableBinnedEntityIndexSet {
  Render3dShadowUnbatchableBinnedEntityIndexSet::{
    kind: NoUnbatchableBinnedEntities,
  }
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::len(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
) -> Int {
  match self.kind {
    NoUnbatchableBinnedEntities => 0
    SparseUnbatchableBinnedEntityIndices(range, _) => range.count()
    DenseUnbatchableBinnedEntityIndices(indices) => indices.length()
  }
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::kind(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
) -> Render3dShadowUnbatchableBinnedEntityIndexSetKind {
  self.kind
}

///|
fn render3d_shadow_unbatchable_indices_from_sparse(
  range : Render3dShadowBatchRange,
  first_indirect_parameters_index : Int?,
  entity_index : Int,
) -> Render3dShadowUnbatchableBinnedEntityIndices? {
  if entity_index < 0 || entity_index >= range.count() {
    return None
  }
  let instance_index = range.start() + entity_index
  let extra_index = match first_indirect_parameters_index {
    Some(first_index) =>
      Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
        first_index + entity_index,
        first_index + entity_index + 1,
      )
    None => Render3dShadowPhaseItemExtraIndex::none()
  }
  Some(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      instance_index, extra_index,
    ),
  )
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::indices_for_entity_index(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
  entity_index : Int,
) -> Render3dShadowUnbatchableBinnedEntityIndices? {
  match self.kind {
    NoUnbatchableBinnedEntities => None
    SparseUnbatchableBinnedEntityIndices(range, first_indirect_parameters_index) =>
      render3d_shadow_unbatchable_indices_from_sparse(
        range, first_indirect_parameters_index, entity_index,
      )
    DenseUnbatchableBinnedEntityIndices(indices) =>
      if entity_index >= 0 && entity_index < indices.length() {
        Some(indices[entity_index])
      } else {
        None
      }
  }
}

///|
fn render3d_shadow_unbatchable_indices_can_extend_sparse(
  range : Render3dShadowBatchRange,
  first_indirect_parameters_index : Int?,
  indices : Render3dShadowUnbatchableBinnedEntityIndices,
) -> Bool {
  if range.end() != indices.instance_index() {
    return false
  }
  match first_indirect_parameters_index {
    None => indices.extra_index() == Render3dShadowPhaseItemExtraIndex::none()
    Some(first_index) =>
      match indices.extra_index().indirect_parameters_range() {
        Some((range_start, _, _)) => first_index + range.count() == range_start
        None => false
      }
  }
}

///|
fn Render3dShadowUnbatchableBinnedEntityIndexSet::demote_sparse_to_dense_with(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
  indices : Render3dShadowUnbatchableBinnedEntityIndices,
) -> Unit {
  let dense : Array[Render3dShadowUnbatchableBinnedEntityIndices] = []
  let count = self.len()
  for entity_index in 0..<count {
    match self.indices_for_entity_index(entity_index) {
      Some(existing) => dense.push(existing)
      None => ()
    }
  }
  dense.push(indices)
  self.kind = DenseUnbatchableBinnedEntityIndices(dense)
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::add(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
  indices : Render3dShadowUnbatchableBinnedEntityIndices,
) -> Unit {
  match self.kind {
    NoUnbatchableBinnedEntities =>
      match indices.extra_index() {
        DynamicOffset(_) =>
          self.kind = DenseUnbatchableBinnedEntityIndices([indices])
        NoExtraIndex =>
          self.kind = SparseUnbatchableBinnedEntityIndices(
            Render3dShadowBatchRange::new(
              indices.instance_index(),
              indices.instance_index() + 1,
            ),
            None,
          )
        IndirectParametersIndex(range_start, _, _) =>
          self.kind = SparseUnbatchableBinnedEntityIndices(
            Render3dShadowBatchRange::new(
              indices.instance_index(),
              indices.instance_index() + 1,
            ),
            Some(range_start),
          )
      }
    SparseUnbatchableBinnedEntityIndices(range, first_indirect_parameters_index) =>
      if render3d_shadow_unbatchable_indices_can_extend_sparse(
          range, first_indirect_parameters_index, indices,
        ) {
        self.kind = SparseUnbatchableBinnedEntityIndices(
          Render3dShadowBatchRange::new(range.start(), range.end() + 1),
          first_indirect_parameters_index,
        )
      } else {
        self.demote_sparse_to_dense_with(indices)
      }
    DenseUnbatchableBinnedEntityIndices(existing) => existing.push(indices)
  }
}

///|
pub fn Render3dShadowUnbatchableBinnedEntityIndexSet::clear(
  self : Render3dShadowUnbatchableBinnedEntityIndexSet,
) -> Unit {
  match self.kind {
    DenseUnbatchableBinnedEntityIndices(indices) => indices.clear()
    SparseUnbatchableBinnedEntityIndices(_, _) =>
      self.kind = NoUnbatchableBinnedEntities
    NoUnbatchableBinnedEntities => ()
  }
}

///|
pub(all) struct Render3dShadowMultidrawableBin {
  entity_to_binned_mesh_instance_index : Map[UInt64, Int]
}

///|
pub fn Render3dShadowMultidrawableBin::Render3dShadowMultidrawableBin() -> Render3dShadowMultidrawableBin {
  Render3dShadowMultidrawableBin::{ entity_to_binned_mesh_instance_index: {} }
}

///|
pub fn Render3dShadowMultidrawableBin::is_empty(
  self : Render3dShadowMultidrawableBin,
) -> Bool {
  self.entity_to_binned_mesh_instance_index.length() == 0
}

///|
pub fn Render3dShadowMultidrawableBin::entity_count(
  self : Render3dShadowMultidrawableBin,
) -> Int {
  self.entity_to_binned_mesh_instance_index.length()
}

///|
pub fn Render3dShadowMultidrawableBin::binned_mesh_instance_index(
  self : Render3dShadowMultidrawableBin,
  main_entity : @render.MainEntity,
) -> Int? {
  self.entity_to_binned_mesh_instance_index.get(main_entity.id().to_bits())
}

///|
pub(all) struct Render3dShadowGpuRenderBinnedMeshInstance {
  input_uniform_index : UInt
  bin_index : Int
} derive(Eq, Debug)

///|
pub fn Render3dShadowGpuRenderBinnedMeshInstance::new(
  input_uniform_index : UInt,
  bin_index : Int,
) -> Render3dShadowGpuRenderBinnedMeshInstance {
  Render3dShadowGpuRenderBinnedMeshInstance::{ input_uniform_index, bin_index }
}

///|
pub fn Render3dShadowGpuRenderBinnedMeshInstance::input_uniform_index(
  self : Render3dShadowGpuRenderBinnedMeshInstance,
) -> UInt {
  self.input_uniform_index
}

///|
pub fn Render3dShadowGpuRenderBinnedMeshInstance::bin_index(
  self : Render3dShadowGpuRenderBinnedMeshInstance,
) -> Int {
  self.bin_index
}

///|
pub(all) struct Render3dShadowCpuRenderBinnedMeshInstance {
  main_entity : @render.MainEntity
  bin_index : Int
} derive(Eq, Debug)

///|
pub fn Render3dShadowCpuRenderBinnedMeshInstance::new(
  main_entity : @render.MainEntity,
  bin_index : Int,
) -> Render3dShadowCpuRenderBinnedMeshInstance {
  Render3dShadowCpuRenderBinnedMeshInstance::{ main_entity, bin_index }
}

///|
pub fn Render3dShadowCpuRenderBinnedMeshInstance::main_entity(
  self : Render3dShadowCpuRenderBinnedMeshInstance,
) -> @render.MainEntity {
  self.main_entity
}

///|
pub fn Render3dShadowCpuRenderBinnedMeshInstance::bin_index(
  self : Render3dShadowCpuRenderBinnedMeshInstance,
) -> Int {
  self.bin_index
}

///|
pub(all) struct Render3dShadowBinnedRenderPhaseBatchData {
  representative_entity : (@core.Entity, @render.MainEntity)
  instance_range : Render3dShadowBatchRange
  extra_index : Render3dShadowPhaseItemExtraIndex
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchData::new(
  representative_entity : (@core.Entity, @render.MainEntity),
  instance_range : Render3dShadowBatchRange,
  extra_index : Render3dShadowPhaseItemExtraIndex,
) -> Render3dShadowBinnedRenderPhaseBatchData {
  Render3dShadowBinnedRenderPhaseBatchData::{
    representative_entity,
    instance_range,
    extra_index,
  }
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchData::representative_entity(
  self : Render3dShadowBinnedRenderPhaseBatchData,
) -> (@core.Entity, @render.MainEntity) {
  self.representative_entity
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchData::instance_range(
  self : Render3dShadowBinnedRenderPhaseBatchData,
) -> Render3dShadowBatchRange {
  self.instance_range
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchData::extra_index(
  self : Render3dShadowBinnedRenderPhaseBatchData,
) -> Render3dShadowPhaseItemExtraIndex {
  self.extra_index
}

///|
pub(all) struct Render3dShadowBinnedRenderPhaseBatchSetData {
  first_batch : Render3dShadowBinnedRenderPhaseBatchData
  bin_key : Render3dShadowBinKeyData
  batch_count : Int
  index : Int
  first_work_item_index : Int
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::new(
  first_batch : Render3dShadowBinnedRenderPhaseBatchData,
  bin_key : Render3dShadowBinKeyData,
  batch_count : Int,
  index : Int,
  first_work_item_index : Int,
) -> Render3dShadowBinnedRenderPhaseBatchSetData {
  Render3dShadowBinnedRenderPhaseBatchSetData::{
    first_batch,
    bin_key,
    batch_count,
    index,
    first_work_item_index,
  }
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::first_batch(
  self : Render3dShadowBinnedRenderPhaseBatchSetData,
) -> Render3dShadowBinnedRenderPhaseBatchData {
  self.first_batch
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::bin_key(
  self : Render3dShadowBinnedRenderPhaseBatchSetData,
) -> Render3dShadowBinKeyData {
  self.bin_key
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::batch_count(
  self : Render3dShadowBinnedRenderPhaseBatchSetData,
) -> Int {
  self.batch_count
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::index(
  self : Render3dShadowBinnedRenderPhaseBatchSetData,
) -> Int {
  self.index
}

///|
pub fn Render3dShadowBinnedRenderPhaseBatchSetData::first_work_item_index(
  self : Render3dShadowBinnedRenderPhaseBatchSetData,
) -> Int {
  self.first_work_item_index
}

///|
pub(all) struct Render3dShadowMultidrawableBatchSetGpuBuffers {
  render_binned_mesh_instance_buffer : Array[
    Render3dShadowGpuRenderBinnedMeshInstance,
  ]
  bin_index_to_indirect_parameters_offset_buffer : Array[Int]
}

///|
pub fn Render3dShadowMultidrawableBatchSetGpuBuffers::Render3dShadowMultidrawableBatchSetGpuBuffers() -> Render3dShadowMultidrawableBatchSetGpuBuffers {
  Render3dShadowMultidrawableBatchSetGpuBuffers::{
    render_binned_mesh_instance_buffer: [],
    bin_index_to_indirect_parameters_offset_buffer: [],
  }
}

///|
pub fn Render3dShadowMultidrawableBatchSetGpuBuffers::render_binned_mesh_instance_len(
  self : Render3dShadowMultidrawableBatchSetGpuBuffers,
) -> Int {
  self.render_binned_mesh_instance_buffer.length()
}

///|
pub fn Render3dShadowMultidrawableBatchSetGpuBuffers::indirect_parameters_offset_for_bin(
  self : Render3dShadowMultidrawableBatchSetGpuBuffers,
  bin_index : Int,
) -> Int? {
  if bin_index < 0 ||
    bin_index >= self.bin_index_to_indirect_parameters_offset_buffer.length() {
    return None
  }
  Some(self.bin_index_to_indirect_parameters_offset_buffer[bin_index])
}

///|
fn Render3dShadowMultidrawableBatchSetGpuBuffers::insert(
  self : Render3dShadowMultidrawableBatchSetGpuBuffers,
  bin : Render3dShadowMultidrawableBin,
  cpu_binned_mesh_instance_buffer : Array[
    Render3dShadowCpuRenderBinnedMeshInstance,
  ],
  main_entity : @render.MainEntity,
  input_uniform_index : UInt,
  bin_index : Int,
) -> Unit {
  let gpu_render_bin_entry = Render3dShadowGpuRenderBinnedMeshInstance::new(
    input_uniform_index, bin_index,
  )
  let key = main_entity.id().to_bits()
  let render_binned_mesh_instance_buffer_index = match
    bin.entity_to_binned_mesh_instance_index.get(key) {
    Some(index) => index
    None => {
      let index = self.render_binned_mesh_instance_buffer.length()
      self.render_binned_mesh_instance_buffer.push(gpu_render_bin_entry)
      cpu_binned_mesh_instance_buffer.push(
        Render3dShadowCpuRenderBinnedMeshInstance::new(main_entity, bin_index),
      )
      bin.entity_to_binned_mesh_instance_index.set(key, index)
      index
    }
  }
  self.render_binned_mesh_instance_buffer[render_binned_mesh_instance_buffer_index] = gpu_render_bin_entry
  cpu_binned_mesh_instance_buffer[render_binned_mesh_instance_buffer_index] = Render3dShadowCpuRenderBinnedMeshInstance::new(
    main_entity, bin_index,
  )
}

///|
fn Render3dShadowMultidrawableBatchSetGpuBuffers::remove(
  self : Render3dShadowMultidrawableBatchSetGpuBuffers,
  bin : Render3dShadowMultidrawableBin,
  cpu_binned_mesh_instance_buffer : Array[
    Render3dShadowCpuRenderBinnedMeshInstance,
  ],
  entity_to_remove : @render.MainEntity,
) -> (Int, Render3dShadowCpuRenderBinnedMeshInstance)? {
  let key = entity_to_remove.id().to_bits()
  guard bin.entity_to_binned_mesh_instance_index.get(key) is Some(old_index) else {
    return None
  }
  bin.entity_to_binned_mesh_instance_index.remove(key)
  let last_index = cpu_binned_mesh_instance_buffer.length() - 1
  if old_index != last_index {
    let moved_cpu = cpu_binned_mesh_instance_buffer[last_index]
    let moved_gpu = self.render_binned_mesh_instance_buffer[last_index]
    cpu_binned_mesh_instance_buffer[old_index] = moved_cpu
    self.render_binned_mesh_instance_buffer[old_index] = moved_gpu
  }
  ignore(cpu_binned_mesh_instance_buffer.pop())
  ignore(self.render_binned_mesh_instance_buffer.pop())
  if old_index < cpu_binned_mesh_instance_buffer.length() {
    Some((old_index, cpu_binned_mesh_instance_buffer[old_index]))
  } else {
    None
  }
}

///|
pub(all) struct Render3dShadowMultidrawableBatchSetData {
  gpu_buffers : Render3dShadowMultidrawableBatchSetGpuBuffers
  bin_key_to_bin_index : Map[Int, Int]
  mut bins : Array[Render3dShadowMultidrawableBin?]
  mut bin_free_list : Array[Int]
  mut indirect_parameters_offset_to_bin_index : Array[Int]
  render_binned_mesh_instances_cpu : Array[
    Render3dShadowCpuRenderBinnedMeshInstance,
  ]
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::Render3dShadowMultidrawableBatchSetData() -> Render3dShadowMultidrawableBatchSetData {
  Render3dShadowMultidrawableBatchSetData::{
    gpu_buffers: Render3dShadowMultidrawableBatchSetGpuBuffers::Render3dShadowMultidrawableBatchSetGpuBuffers(),
    bin_key_to_bin_index: {},
    bins: [],
    bin_free_list: [],
    indirect_parameters_offset_to_bin_index: [],
    render_binned_mesh_instances_cpu: [],
  }
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::bin_count(
  self : Render3dShadowMultidrawableBatchSetData,
) -> Int {
  self.bin_key_to_bin_index.length()
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::cpu_instance_count(
  self : Render3dShadowMultidrawableBatchSetData,
) -> Int {
  self.render_binned_mesh_instances_cpu.length()
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::indirect_parameter_count(
  self : Render3dShadowMultidrawableBatchSetData,
) -> Int {
  self.indirect_parameters_offset_to_bin_index.length()
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::bin_index(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_key : Render3dShadowBinKeyData,
) -> Int? {
  self.bin_key_to_bin_index.get(bin_key.mesh_asset_id())
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::indirect_parameters_offset_for_bin(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_index : Int,
) -> Int? {
  self.gpu_buffers.indirect_parameters_offset_for_bin(bin_index)
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::cpu_instance_at(
  self : Render3dShadowMultidrawableBatchSetData,
  index : Int,
) -> Render3dShadowCpuRenderBinnedMeshInstance? {
  if index < 0 || index >= self.render_binned_mesh_instances_cpu.length() {
    return None
  }
  Some(self.render_binned_mesh_instances_cpu[index])
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::binned_render_phase_batch_sets(
  self : Render3dShadowMultidrawableBatchSetData,
) -> Array[Render3dShadowBinnedRenderPhaseBatchSetData] {
  let result : Array[Render3dShadowBinnedRenderPhaseBatchSetData] = []
  let mut batch_set_index = 0
  for bin_key_id, bin_index in self.bin_key_to_bin_index {
    guard self.bin(bin_index) is Some(bin) else { continue }
    if bin.is_empty() {
      continue
    }
    guard self.gpu_buffers.indirect_parameters_offset_for_bin(bin_index)
      is Some(indirect_parameters_offset) else {
      continue
    }
    let mut representative_main : @render.MainEntity? = None
    let mut min_input_uniform_index = 0
    let mut max_input_uniform_index = 0
    let mut bin_instance_count = 0
    for instance in self.render_binned_mesh_instances_cpu {
      if instance.bin_index() == bin_index {
        let input_uniform_index = match
          bin.binned_mesh_instance_index(instance.main_entity()) {
          Some(buffer_index) =>
            self.gpu_buffers.render_binned_mesh_instance_buffer[buffer_index]
            .input_uniform_index()
            .reinterpret_as_int()
          None => continue
        }
        if representative_main is None {
          representative_main = Some(instance.main_entity())
          min_input_uniform_index = input_uniform_index
          max_input_uniform_index = input_uniform_index
        } else {
          if input_uniform_index < min_input_uniform_index {
            min_input_uniform_index = input_uniform_index
          }
          if input_uniform_index > max_input_uniform_index {
            max_input_uniform_index = input_uniform_index
          }
        }
        bin_instance_count += 1
      }
    }
    match representative_main {
      Some(main_entity) =>
        result.push(
          Render3dShadowBinnedRenderPhaseBatchSetData::new(
            Render3dShadowBinnedRenderPhaseBatchData::new(
              (main_entity.id(), main_entity),
              Render3dShadowBatchRange::new(
                min_input_uniform_index,
                max_input_uniform_index + 1,
              ),
              Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
                indirect_parameters_offset,
                indirect_parameters_offset + 1,
              ),
            ),
            Render3dShadowBinKeyData::new(bin_key_id),
            bin_instance_count,
            batch_set_index,
            0,
          ),
        )
      None => ()
    }
    batch_set_index += 1
  }
  result
}

///|
fn Render3dShadowMultidrawableBatchSetData::allocate_indirect_parameters(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_index : Int,
) -> Unit {
  let indirect_parameters_offset = self.indirect_parameters_offset_to_bin_index.length()
  self.indirect_parameters_offset_to_bin_index.push(bin_index)
  if bin_index ==
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer.length() {
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer.push(
      indirect_parameters_offset,
    )
  } else {
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[bin_index] = indirect_parameters_offset
  }
}

///|
fn Render3dShadowMultidrawableBatchSetData::bin(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_index : Int,
) -> Render3dShadowMultidrawableBin? {
  if bin_index < 0 || bin_index >= self.bins.length() {
    return None
  }
  self.bins[bin_index]
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::insert(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_key : Render3dShadowBinKeyData,
  main_entity : @render.MainEntity,
  input_uniform_index : UInt,
) -> Unit {
  let bin_key_id = bin_key.mesh_asset_id()
  let bin_index = match self.bin_key_to_bin_index.get(bin_key_id) {
    Some(index) => index
    None => {
      let index = match self.bin_free_list.pop() {
        Some(free_index) => free_index
        None => self.bins.length()
      }
      let bin = Render3dShadowMultidrawableBin::Render3dShadowMultidrawableBin()
      if index == self.bins.length() {
        self.bins.push(Some(bin))
      } else {
        self.bins[index] = Some(bin)
      }
      self.bin_key_to_bin_index.set(bin_key_id, index)
      self.allocate_indirect_parameters(index)
      index
    }
  }
  guard self.bin(bin_index) is Some(bin) else { return }
  self.gpu_buffers.insert(
    bin,
    self.render_binned_mesh_instances_cpu,
    main_entity,
    input_uniform_index,
    bin_index,
  )
}

///|
fn Render3dShadowMultidrawableBatchSetData::remove_bin_if_empty(
  self : Render3dShadowMultidrawableBatchSetData,
  bin_key : Render3dShadowBinKeyData,
  bin_index : Int,
) -> Unit {
  guard self.bin(bin_index) is Some(bin) else { return }
  if !bin.is_empty() {
    return
  }
  self.bin_key_to_bin_index.remove(bin_key.mesh_asset_id())
  self.bin_free_list.push(bin_index)
  self.bins[bin_index] = None
  guard self.gpu_buffers.indirect_parameters_offset_for_bin(bin_index)
    is Some(indirect_parameters_offset) else {
    return
  }
  self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[bin_index] = -1
  let last_index = self.indirect_parameters_offset_to_bin_index.length() - 1
  if indirect_parameters_offset != last_index {
    let displaced_bin_index = self.indirect_parameters_offset_to_bin_index[last_index]
    self.indirect_parameters_offset_to_bin_index[indirect_parameters_offset] = displaced_bin_index
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[displaced_bin_index] = indirect_parameters_offset
  }
  ignore(self.indirect_parameters_offset_to_bin_index.pop())
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::remove(
  self : Render3dShadowMultidrawableBatchSetData,
  main_entity : @render.MainEntity,
  bin_key : Render3dShadowBinKeyData,
) -> Unit {
  guard self.bin_key_to_bin_index.get(bin_key.mesh_asset_id())
    is Some(bin_index) else {
    return
  }
  guard self.bin(bin_index) is Some(bin) else { return }
  match
    self.gpu_buffers.remove(
      bin,
      self.render_binned_mesh_instances_cpu,
      main_entity,
    ) {
    Some((old_index, displaced_entity_indices)) =>
      match self.bin(displaced_entity_indices.bin_index()) {
        Some(displaced_bin) =>
          displaced_bin.entity_to_binned_mesh_instance_index.set(
            displaced_entity_indices.main_entity().id().to_bits(),
            old_index,
          )
        None => ()
      }
    None => ()
  }
  self.remove_bin_if_empty(bin_key, bin_index)
}

///|
fn Render3dShadowMultidrawableBatchSetData::remove_entity(
  self : Render3dShadowMultidrawableBatchSetData,
  main_entity : @render.MainEntity,
) -> Unit {
  let mut found_bin_key_id = -1
  for bin_key_id, bin_index in self.bin_key_to_bin_index {
    match self.bin(bin_index) {
      Some(bin) =>
        if bin.binned_mesh_instance_index(main_entity) is Some(_) {
          found_bin_key_id = bin_key_id
          break
        }
      None => ()
    }
  }
  if found_bin_key_id >= 0 {
    self.remove(main_entity, Render3dShadowBinKeyData::new(found_bin_key_id))
  }
}

///|
pub fn Render3dShadowMultidrawableBatchSetData::is_empty(
  self : Render3dShadowMultidrawableBatchSetData,
) -> Bool {
  self.bin_free_list.length() == self.bins.length()
}

///|
priv struct Render3dShadowMultidrawableBatchSetPreparer {
  mut indirect_parameters_index : Int
  mut batch_set_index : Int
  mut work_item_count : Int
}

///|
fn Render3dShadowMultidrawableBatchSetPreparer::new(
  initial_indirect_parameters_index : Int,
  initial_batch_set_index : Int,
) -> Render3dShadowMultidrawableBatchSetPreparer {
  Render3dShadowMultidrawableBatchSetPreparer::{
    indirect_parameters_index: initial_indirect_parameters_index,
    batch_set_index: initial_batch_set_index,
    work_item_count: 0,
  }
}

///|
fn Render3dShadowMultidrawableBatchSetData::representative_entity_for_bin(
  self : Render3dShadowMultidrawableBatchSetData,
  bin : Render3dShadowMultidrawableBin,
) -> @render.MainEntity? {
  for instance in self.render_binned_mesh_instances_cpu {
    if bin.binned_mesh_instance_index(instance.main_entity()) is Some(_) {
      return Some(instance.main_entity())
    }
  }
  None
}

///|
fn Render3dShadowMultidrawableBatchSetData::prepare_multidrawable_binned_batch_set(
  self : Render3dShadowMultidrawableBatchSetData,
  indexed : Bool,
  preparer : Render3dShadowMultidrawableBatchSetPreparer,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  work_item_buffer : @render_batching.PreprocessWorkItemBuffers,
) -> Render3dShadowBinnedRenderPhaseBatchSetData? {
  let current_indexed_batch_set_index = preparer.batch_set_index
  let current_output_index = phase_batched_instance_buffers.buffers.data_buffer.len()
  let first_work_item_index = if indexed {
    work_item_buffer.indexed_len()
  } else {
    work_item_buffer.non_indexed_len()
  }
  let indirect_parameters_base = preparer.indirect_parameters_index
  let mut first_bin_key_id = -1
  let mut first_bin_index = -1
  for bin_key_id, bin_index in self.bin_key_to_bin_index {
    first_bin_key_id = bin_key_id
    first_bin_index = bin_index
    break
  }
  if first_bin_index < 0 {
    return None
  }
  guard self.bin(first_bin_index) is Some(first_bin) else { return None }
  let first_bin_len = first_bin.entity_count()
  let first_bin_entity = match self.representative_entity_for_bin(first_bin) {
    Some(entity) => entity
    None => @render.MainEntity::new(@core.Entity::placeholder())
  }
  let cpu_metadata_offset = phase_indirect_parameters_buffers.buffers.cpu_metadata_len(
    indexed,
  )
  let bin_count = self.bin_count()
  ignore(phase_indirect_parameters_buffers.buffers.allocate(indexed, bin_count))
  for bin_index in self.bin_key_to_bin_index.values() {
    guard self.bin(bin_index) is Some(bin) else { continue }
    guard self.indirect_parameters_offset_for_bin(bin_index)
      is Some(indirect_parameters_offset) else {
      continue
    }
    phase_indirect_parameters_buffers.buffers.set_cpu_metadata(
      indexed,
      cpu_metadata_offset + indirect_parameters_offset,
      @render_batching.IndirectParametersCpuMetadata::new(
        phase_batched_instance_buffers.buffers.data_buffer.len(),
        preparer.batch_set_index,
      ),
    )
    let bin_entity_count = bin.entity_count()
    work_item_buffer.push_multiple_uninit(indexed, bin_entity_count)
    for _ in 0..<bin_entity_count {
      phase_batched_instance_buffers.buffers.data_buffer.push(())
    }
    preparer.work_item_count += bin_entity_count
  }
  phase_indirect_parameters_buffers.buffers.add_batch_set(
    indexed, indirect_parameters_base,
  )
  preparer.indirect_parameters_index += bin_count
  preparer.batch_set_index += 1
  Some(
    Render3dShadowBinnedRenderPhaseBatchSetData::new(
      Render3dShadowBinnedRenderPhaseBatchData::new(
        (first_bin_entity.id(), first_bin_entity),
        Render3dShadowBatchRange::new(
          current_output_index,
          current_output_index + first_bin_len,
        ),
        Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
          indirect_parameters_base,
          indirect_parameters_base + 1,
        ),
      ),
      Render3dShadowBinKeyData::new(first_bin_key_id),
      preparer.indirect_parameters_index - indirect_parameters_base,
      current_indexed_batch_set_index,
      first_work_item_index,
    ),
  )
}

///|
pub(all) struct Render3dShadowMultidrawableBatchSetEntry {
  batch_set_key : Render3dShadowBatchSetKeyData
  batch_set : Render3dShadowMultidrawableBatchSetData
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::new(
  batch_set_key : Render3dShadowBatchSetKeyData,
) -> Render3dShadowMultidrawableBatchSetEntry {
  Render3dShadowMultidrawableBatchSetEntry::{
    batch_set_key,
    batch_set: Render3dShadowMultidrawableBatchSetData::Render3dShadowMultidrawableBatchSetData(),
  }
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::matches(
  self : Render3dShadowMultidrawableBatchSetEntry,
  batch_set_key : Render3dShadowBatchSetKeyData,
) -> Bool {
  render3d_shadow_batch_set_key_eq(self.batch_set_key, batch_set_key)
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::insert(
  self : Render3dShadowMultidrawableBatchSetEntry,
  bin_key : Render3dShadowBinKeyData,
  main_entity : @render.MainEntity,
  input_uniform_index : UInt,
) -> Unit {
  self.batch_set.insert(bin_key, main_entity, input_uniform_index)
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::remove_entity(
  self : Render3dShadowMultidrawableBatchSetEntry,
  main_entity : @render.MainEntity,
) -> Unit {
  self.batch_set.remove_entity(main_entity)
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::is_empty(
  self : Render3dShadowMultidrawableBatchSetEntry,
) -> Bool {
  self.batch_set.is_empty()
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::cpu_instance_count(
  self : Render3dShadowMultidrawableBatchSetEntry,
) -> Int {
  self.batch_set.cpu_instance_count()
}

///|
fn Render3dShadowMultidrawableBatchSetEntry::items(
  self : Render3dShadowMultidrawableBatchSetEntry,
  multi_draw_indirect_count_supported : Bool,
) -> Array[Render3dShadowPhaseItemData] {
  let items : Array[Render3dShadowPhaseItemData] = []
  for batch_set in self.batch_set.binned_render_phase_batch_sets() {
    let batch = batch_set.first_batch()
    let batch_set_index = if multi_draw_indirect_count_supported {
      Some(batch_set.index())
    } else {
      None
    }
    let extra_index = match batch.extra_index() {
      NoExtraIndex => Render3dShadowPhaseItemExtraIndex::none()
      DynamicOffset(offset) =>
        Render3dShadowPhaseItemExtraIndex::dynamic_offset(offset)
      IndirectParametersIndex(range_start, _, _) =>
        Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
          range_start,
          range_start + batch_set.batch_count(),
          batch_set_index~,
        )
    }
    let representative_entity = batch.representative_entity()
    items.push(
      Render3dShadowPhaseItemData::new(
        self.batch_set_key,
        batch_set.bin_key(),
        representative_entity.0,
        representative_entity.1,
        batch.instance_range(),
        extra_index,
      ),
    )
  }
  items
}

///|
pub(all) struct Render3dShadowUnbatchableBinnedEntities {
  batch_set_key : Render3dShadowBatchSetKeyData
  bin_key : Render3dShadowBinKeyData
  mut entities : Array[(@render.MainEntity, @core.Entity)]
  buffer_indices : Render3dShadowUnbatchableBinnedEntityIndexSet
}

///|
fn Render3dShadowUnbatchableBinnedEntities::new(
  batch_set_key : Render3dShadowBatchSetKeyData,
  bin_key : Render3dShadowBinKeyData,
) -> Render3dShadowUnbatchableBinnedEntities {
  Render3dShadowUnbatchableBinnedEntities::{
    batch_set_key,
    bin_key,
    entities: [],
    buffer_indices: Render3dShadowUnbatchableBinnedEntityIndexSet::Render3dShadowUnbatchableBinnedEntityIndexSet(),
  }
}

///|
fn Render3dShadowUnbatchableBinnedEntities::matches(
  self : Render3dShadowUnbatchableBinnedEntities,
  batch_set_key : Render3dShadowBatchSetKeyData,
  bin_key : Render3dShadowBinKeyData,
) -> Bool {
  render3d_shadow_batch_set_key_eq(self.batch_set_key, batch_set_key) &&
  render3d_shadow_bin_key_eq(self.bin_key, bin_key)
}

///|
fn Render3dShadowUnbatchableBinnedEntities::insert(
  self : Render3dShadowUnbatchableBinnedEntities,
  main_entity : @render.MainEntity,
  render_entity : @core.Entity,
  input_uniform_index : UInt,
) -> Unit {
  self.entities.push((main_entity, render_entity))
  self.buffer_indices.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      input_uniform_index.reinterpret_as_int(),
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
}

///|
fn Render3dShadowUnbatchableBinnedEntities::remove(
  self : Render3dShadowUnbatchableBinnedEntities,
  main_entity : @render.MainEntity,
) -> Unit {
  let retained : Array[(@render.MainEntity, @core.Entity)] = []
  let retained_indices = Render3dShadowUnbatchableBinnedEntityIndexSet::Render3dShadowUnbatchableBinnedEntityIndexSet()
  for entity_index in 0..<self.entities.length() {
    let entry = self.entities[entity_index]
    let (entry_main_entity, _render_entity) = entry
    if entry_main_entity != main_entity {
      retained.push(entry)
      match self.buffer_indices.indices_for_entity_index(entity_index) {
        Some(indices) => retained_indices.add(indices)
        None => ()
      }
    }
  }
  self.entities = retained
  self.buffer_indices.clear()
  for entity_index in 0..<retained_indices.len() {
    match retained_indices.indices_for_entity_index(entity_index) {
      Some(indices) => self.buffer_indices.add(indices)
      None => ()
    }
  }
}

///|
fn Render3dShadowUnbatchableBinnedEntities::is_empty(
  self : Render3dShadowUnbatchableBinnedEntities,
) -> Bool {
  self.entities.length() == 0
}

///|
fn Render3dShadowUnbatchableBinnedEntities::clear_buffer_indices(
  self : Render3dShadowUnbatchableBinnedEntities,
) -> Unit {
  self.buffer_indices.clear()
}

///|
fn Render3dShadowUnbatchableBinnedEntities::items(
  self : Render3dShadowUnbatchableBinnedEntities,
) -> Array[Render3dShadowPhaseItemData] {
  let items : Array[Render3dShadowPhaseItemData] = []
  for entity_index in 0..<self.entities.length() {
    match self.buffer_indices.indices_for_entity_index(entity_index) {
      Some(indices) => {
        let (main_entity, render_entity) = self.entities[entity_index]
        let instance_index = indices.instance_index()
        items.push(
          Render3dShadowPhaseItemData::new(
            self.batch_set_key,
            self.bin_key,
            render_entity,
            main_entity,
            Render3dShadowBatchRange::new(instance_index, instance_index + 1),
            indices.extra_index(),
          ),
        )
      }
      None => ()
    }
  }
  items
}

///|
fn Render3dShadowUnbatchableBinnedEntities::prepare_phase_buffers(
  self : Render3dShadowUnbatchableBinnedEntities,
  no_indirect_drawing : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  work_item_buffer : @render_batching.PreprocessWorkItemBuffers,
) -> Unit {
  let indexed = self.batch_set_key.indexed()
  let mut indirect_parameters_index = if no_indirect_drawing {
    None
  } else {
    Some(
      phase_indirect_parameters_buffers.buffers.allocate(
        indexed,
        self.entities.length(),
      ),
    )
  }
  let prepared_indices = Render3dShadowUnbatchableBinnedEntityIndexSet::Render3dShadowUnbatchableBinnedEntityIndexSet()
  for entity_index in 0..<self.entities.length() {
    guard self.buffer_indices.indices_for_entity_index(entity_index)
      is Some(existing_indices) else {
      continue
    }
    let input_index = existing_indices.instance_index()
    let output_index = phase_batched_instance_buffers.buffers.data_buffer.len()
    phase_batched_instance_buffers.buffers.data_buffer.push(())
    match indirect_parameters_index {
      Some(index) => {
        work_item_buffer.push(
          indexed,
          @render_batching.PreprocessWorkItem::new(input_index, index),
        )
        prepared_indices.add(
          Render3dShadowUnbatchableBinnedEntityIndices::new(
            index,
            Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
              index,
              index + 1,
            ),
          ),
        )
        phase_indirect_parameters_buffers.buffers.add_batch_set(indexed, index)
        indirect_parameters_index = Some(index + 1)
      }
      None => {
        work_item_buffer.push(
          indexed,
          @render_batching.PreprocessWorkItem::new(input_index, output_index),
        )
        prepared_indices.add(
          Render3dShadowUnbatchableBinnedEntityIndices::new(
            output_index,
            Render3dShadowPhaseItemExtraIndex::none(),
          ),
        )
      }
    }
  }
  self.buffer_indices.clear()
  for entity_index in 0..<prepared_indices.len() {
    match prepared_indices.indices_for_entity_index(entity_index) {
      Some(indices) => self.buffer_indices.add(indices)
      None => ()
    }
  }
}

///|
pub struct Render3dShadowBatchRange {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn Render3dShadowBatchRange::new(
  start : Int,
  end : Int,
) -> Render3dShadowBatchRange {
  let safe_start = if start < 0 { 0 } else { start }
  let safe_end = if end < safe_start { safe_start } else { end }
  Render3dShadowBatchRange::{ start: safe_start, end: safe_end }
}

///|
pub fn Render3dShadowBatchRange::start(self : Render3dShadowBatchRange) -> Int {
  self.start
}

///|
pub fn Render3dShadowBatchRange::end(self : Render3dShadowBatchRange) -> Int {
  self.end
}

///|
pub fn Render3dShadowBatchRange::count(self : Render3dShadowBatchRange) -> Int {
  self.end - self.start
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::Shadow`.
pub struct Render3dShadowPhaseItemData {
  batch_set_key : Render3dShadowBatchSetKeyData
  bin_key : Render3dShadowBinKeyData
  render_entity : @core.Entity
  main_entity : @render.MainEntity
  batch_range : Render3dShadowBatchRange
  extra_index : Render3dShadowPhaseItemExtraIndex
}

///|
pub fn Render3dShadowPhaseItemData::new(
  batch_set_key : Render3dShadowBatchSetKeyData,
  bin_key : Render3dShadowBinKeyData,
  render_entity : @core.Entity,
  main_entity : @render.MainEntity,
  batch_range : Render3dShadowBatchRange,
  extra_index : Render3dShadowPhaseItemExtraIndex,
) -> Render3dShadowPhaseItemData {
  Render3dShadowPhaseItemData::{
    batch_set_key,
    bin_key,
    render_entity,
    main_entity,
    batch_range,
    extra_index,
  }
}

///|
pub fn Render3dShadowPhaseItemData::entity(
  self : Render3dShadowPhaseItemData,
) -> @core.Entity {
  self.render_entity
}

///|
pub fn Render3dShadowPhaseItemData::main_entity(
  self : Render3dShadowPhaseItemData,
) -> @render.MainEntity {
  self.main_entity
}

///|
pub fn Render3dShadowPhaseItemData::draw_function(
  self : Render3dShadowPhaseItemData,
) -> @material.DrawFunctionId {
  self.batch_set_key.draw_function()
}

///|
pub fn Render3dShadowPhaseItemData::cached_pipeline(
  self : Render3dShadowPhaseItemData,
) -> @material.CachedRenderPipelineId {
  self.batch_set_key.pipeline_id()
}

///|
pub fn Render3dShadowPhaseItemData::batch_range(
  self : Render3dShadowPhaseItemData,
) -> Render3dShadowBatchRange {
  self.batch_range
}

///|
pub fn Render3dShadowPhaseItemData::extra_index(
  self : Render3dShadowPhaseItemData,
) -> Render3dShadowPhaseItemExtraIndex {
  self.extra_index
}

///|
pub fn Render3dShadowPhaseItemData::batch_set_key(
  self : Render3dShadowPhaseItemData,
) -> Render3dShadowBatchSetKeyData {
  self.batch_set_key
}

///|
pub fn Render3dShadowPhaseItemData::bin_key(
  self : Render3dShadowPhaseItemData,
) -> Render3dShadowBinKeyData {
  self.bin_key
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhaseType`.
pub(all) enum Render3dShadowBinnedRenderPhaseType {
  MultidrawableMesh
  BatchableMesh
  UnbatchableMesh
  NonMesh
} derive(Eq, Debug)

///|
pub fn Render3dShadowBinnedRenderPhaseType::mesh(
  batchable : Bool,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Render3dShadowBinnedRenderPhaseType {
  match (batchable, gpu_preprocessing_support.is_culling_supported()) {
    (true, true) => MultidrawableMesh
    (true, false) => BatchableMesh
    (false, _) => UnbatchableMesh
  }
}

///|
fn render3d_shadow_effective_phase_type(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
  phase_type : Render3dShadowBinnedRenderPhaseType,
) -> Render3dShadowBinnedRenderPhaseType {
  if gpu_preprocessing_mode ==
    @render_batching.GpuPreprocessingMode::PreprocessingOnly &&
    phase_type == MultidrawableMesh {
    BatchableMesh
  } else {
    phase_type
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhase<Shadow>`.
pub struct Render3dShadowViewPhaseData {
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode
  mut items : Array[Render3dShadowPhaseItemData]
  mut multidrawable_meshes : Array[Render3dShadowMultidrawableBatchSetEntry]
  mut unbatchable_meshes : Array[Render3dShadowUnbatchableBinnedEntities]
  input_uniform_indices : Map[UInt64, UInt]
  phase_types : Map[UInt64, Render3dShadowBinnedRenderPhaseType]
}

///|
pub fn Render3dShadowViewPhaseData::new(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Render3dShadowViewPhaseData {
  Render3dShadowViewPhaseData::{
    gpu_preprocessing_mode,
    items: [],
    multidrawable_meshes: [],
    unbatchable_meshes: [],
    input_uniform_indices: {},
    phase_types: {},
  }
}

///|
pub fn Render3dShadowViewPhaseData::len(
  self : Render3dShadowViewPhaseData,
) -> Int {
  let mut count = self.items.length()
  for entry in self.multidrawable_meshes {
    count += entry.cpu_instance_count()
  }
  for entities in self.unbatchable_meshes {
    count += entities.buffer_indices.len()
  }
  count
}

///|
pub fn Render3dShadowViewPhaseData::multidrawable_batch_set_count(
  self : Render3dShadowViewPhaseData,
) -> Int {
  self.multidrawable_meshes.length()
}

///|
pub fn Render3dShadowViewPhaseData::multidrawable_cpu_instance_count(
  self : Render3dShadowViewPhaseData,
) -> Int {
  let mut count = 0
  for entry in self.multidrawable_meshes {
    count += entry.cpu_instance_count()
  }
  count
}

///|
pub fn Render3dShadowViewPhaseData::items(
  self : Render3dShadowViewPhaseData,
) -> Array[Render3dShadowPhaseItemData] {
  let result : Array[Render3dShadowPhaseItemData] = []
  for item in self.items {
    result.push(item)
  }
  for entities in self.unbatchable_meshes {
    for item in entities.items() {
      result.push(item)
    }
  }
  result
}

///|
pub fn Render3dShadowViewPhaseData::multidrawable_items(
  self : Render3dShadowViewPhaseData,
  multi_draw_indirect_count_supported : Bool,
) -> Array[Render3dShadowPhaseItemData] {
  let result : Array[Render3dShadowPhaseItemData] = []
  for entry in self.multidrawable_meshes {
    for item in entry.items(multi_draw_indirect_count_supported) {
      result.push(item)
    }
  }
  result
}

///|
pub fn Render3dShadowViewPhaseData::render_items(
  self : Render3dShadowViewPhaseData,
  multi_draw_indirect_count_supported : Bool,
) -> Array[Render3dShadowPhaseItemData] {
  let result = self.items()
  for item in self.multidrawable_items(multi_draw_indirect_count_supported) {
    result.push(item)
  }
  result
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`
// batchable-mesh branch for `Shadow`.
pub fn Render3dShadowViewPhaseData::prepare_batchable_phase_buffers(
  self : Render3dShadowViewPhaseData,
  retained_view_key : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Unit {
  let work_item_buffer = @render_batching.get_or_create_work_item_buffer(
    phase_batched_instance_buffers.buffers.work_item_buffers,
    retained_view_key,
    no_indirect_drawing,
    enable_gpu_occlusion_culling,
  )
  @render_batching.init_work_item_buffers(
    work_item_buffer,
    phase_batched_instance_buffers.buffers.late_indexed_indirect_parameters_buffer,
    phase_batched_instance_buffers.buffers.late_non_indexed_indirect_parameters_buffer,
  )
  self.prepare_batchable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
}

///|
fn Render3dShadowViewPhaseData::prepare_batchable_phase_buffers_with_work_item_buffer(
  self : Render3dShadowViewPhaseData,
  no_indirect_drawing : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  work_item_buffer : @render_batching.PreprocessWorkItemBuffers,
) -> Unit {
  for item_index in 0..<self.items.length() {
    let item = self.items[item_index]
    let indexed = item.batch_set_key().indexed()
    let output_start = phase_batched_instance_buffers.buffers.data_buffer.len()
    let indirect_parameters_index = if no_indirect_drawing {
      None
    } else {
      Some(phase_indirect_parameters_buffers.buffers.allocate(indexed, 1))
    }
    let mut output_end = output_start
    for input_index in item.batch_range().start()..<item.batch_range().end() {
      phase_batched_instance_buffers.buffers.data_buffer.push(())
      let output_or_indirect_parameters_index = match
        indirect_parameters_index {
        Some(index) => index
        None => output_end
      }
      work_item_buffer.push(
        indexed,
        @render_batching.PreprocessWorkItem::new(
          input_index, output_or_indirect_parameters_index,
        ),
      )
      output_end += 1
    }
    let extra_index = match indirect_parameters_index {
      Some(index) => {
        phase_indirect_parameters_buffers.buffers.add_batch_set(indexed, index)
        Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(
          index,
          index + 1,
        )
      }
      None => Render3dShadowPhaseItemExtraIndex::none()
    }
    self.items[item_index] = Render3dShadowPhaseItemData::{
      ..item,
      batch_range: Render3dShadowBatchRange::new(output_start, output_end),
      extra_index,
    }
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`
// unbatchable-mesh branch for `Shadow`.
pub fn Render3dShadowViewPhaseData::prepare_unbatchable_phase_buffers(
  self : Render3dShadowViewPhaseData,
  retained_view_key : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Unit {
  let work_item_buffer = @render_batching.get_or_create_work_item_buffer(
    phase_batched_instance_buffers.buffers.work_item_buffers,
    retained_view_key,
    no_indirect_drawing,
    enable_gpu_occlusion_culling,
  )
  @render_batching.init_work_item_buffers(
    work_item_buffer,
    phase_batched_instance_buffers.buffers.late_indexed_indirect_parameters_buffer,
    phase_batched_instance_buffers.buffers.late_non_indexed_indirect_parameters_buffer,
  )
  self.prepare_unbatchable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
}

///|
fn Render3dShadowViewPhaseData::prepare_unbatchable_phase_buffers_with_work_item_buffer(
  self : Render3dShadowViewPhaseData,
  no_indirect_drawing : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  work_item_buffer : @render_batching.PreprocessWorkItemBuffers,
) -> Unit {
  for entities in self.unbatchable_meshes {
    entities.prepare_phase_buffers(
      no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
      work_item_buffer,
    )
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`
// multidrawable-mesh branch for `Shadow`.
pub fn Render3dShadowViewPhaseData::prepare_multidrawable_phase_buffers(
  self : Render3dShadowViewPhaseData,
  retained_view_key : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Array[Render3dShadowBinnedRenderPhaseBatchSetData] {
  let work_item_buffer = @render_batching.get_or_create_work_item_buffer(
    phase_batched_instance_buffers.buffers.work_item_buffers,
    retained_view_key,
    no_indirect_drawing,
    enable_gpu_occlusion_culling,
  )
  @render_batching.init_work_item_buffers(
    work_item_buffer,
    phase_batched_instance_buffers.buffers.late_indexed_indirect_parameters_buffer,
    phase_batched_instance_buffers.buffers.late_non_indexed_indirect_parameters_buffer,
  )
  self.prepare_multidrawable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
}

///|
fn Render3dShadowViewPhaseData::prepare_multidrawable_phase_buffers_with_work_item_buffer(
  self : Render3dShadowViewPhaseData,
  no_indirect_drawing : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  work_item_buffer : @render_batching.PreprocessWorkItemBuffers,
) -> Array[Render3dShadowBinnedRenderPhaseBatchSetData] {
  let batch_sets : Array[Render3dShadowBinnedRenderPhaseBatchSetData] = []
  if no_indirect_drawing {
    return batch_sets
  }
  let indexed_preparer = Render3dShadowMultidrawableBatchSetPreparer::new(
    phase_indirect_parameters_buffers.buffers.batch_count(true),
    phase_indirect_parameters_buffers.buffers.batch_set_count(true),
  )
  let non_indexed_preparer = Render3dShadowMultidrawableBatchSetPreparer::new(
    phase_indirect_parameters_buffers.buffers.batch_count(false),
    phase_indirect_parameters_buffers.buffers.batch_set_count(false),
  )
  for entry in self.multidrawable_meshes {
    let indexed = entry.batch_set_key.indexed()
    let preparer = if indexed { indexed_preparer } else { non_indexed_preparer }
    match
      entry.batch_set.prepare_multidrawable_binned_batch_set(
        indexed, preparer, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
        work_item_buffer,
      ) {
      Some(batch_set) => batch_sets.push(batch_set)
      None => ()
    }
  }
  work_item_buffer.push_multiple_late_uninit(
    true,
    indexed_preparer.work_item_count,
  )
  work_item_buffer.push_multiple_late_uninit(
    false,
    non_indexed_preparer.work_item_count,
  )
  batch_sets
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
pub fn Render3dShadowViewPhaseData::prepare_phase_buffers(
  self : Render3dShadowViewPhaseData,
  retained_view_key : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Array[Render3dShadowBinnedRenderPhaseBatchSetData] {
  let work_item_buffer = @render_batching.get_or_create_work_item_buffer(
    phase_batched_instance_buffers.buffers.work_item_buffers,
    retained_view_key,
    no_indirect_drawing,
    enable_gpu_occlusion_culling,
  )
  @render_batching.init_work_item_buffers(
    work_item_buffer,
    phase_batched_instance_buffers.buffers.late_indexed_indirect_parameters_buffer,
    phase_batched_instance_buffers.buffers.late_non_indexed_indirect_parameters_buffer,
  )
  self.prepare_unbatchable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
  self.prepare_batchable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
  self.prepare_multidrawable_phase_buffers_with_work_item_buffer(
    no_indirect_drawing, phase_batched_instance_buffers, phase_indirect_parameters_buffers,
    work_item_buffer,
  )
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhase::prepare_for_new_frame`.
pub fn Render3dShadowViewPhaseData::prepare_for_new_frame(
  self : Render3dShadowViewPhaseData,
) -> Unit {
  for entities in self.unbatchable_meshes {
    entities.clear_buffer_indices()
  }
}

///|
fn render3d_shadow_batchable_item_can_extend(
  item : Render3dShadowPhaseItemData,
  batch_set_key : Render3dShadowBatchSetKeyData,
  bin_key : Render3dShadowBinKeyData,
  input_uniform_index : Int,
) -> Bool {
  render3d_shadow_batch_set_key_eq(item.batch_set_key(), batch_set_key) &&
  render3d_shadow_bin_key_eq(item.bin_key(), bin_key) &&
  item.batch_range().end() == input_uniform_index &&
  item.extra_index() == Render3dShadowPhaseItemExtraIndex::none()
}

///|
pub fn Render3dShadowViewPhaseData::add(
  self : Render3dShadowViewPhaseData,
  batch_set_key : Render3dShadowBatchSetKeyData,
  bin_key : Render3dShadowBinKeyData,
  representative_entity : (@core.Entity, @render.MainEntity),
  input_uniform_index : UInt,
  phase_type : Render3dShadowBinnedRenderPhaseType,
) -> Unit {
  let effective_phase_type = render3d_shadow_effective_phase_type(
    self.gpu_preprocessing_mode,
    phase_type,
  )
  let input_uniform_index_int = input_uniform_index.reinterpret_as_int()
  if effective_phase_type == MultidrawableMesh {
    let mut batch_set_index = -1
    for index in 0..<self.multidrawable_meshes.length() {
      if self.multidrawable_meshes[index].matches(batch_set_key) {
        batch_set_index = index
        break
      }
    }
    if batch_set_index < 0 {
      self.multidrawable_meshes.push(
        Render3dShadowMultidrawableBatchSetEntry::new(batch_set_key),
      )
      batch_set_index = self.multidrawable_meshes.length() - 1
    }
    self.multidrawable_meshes[batch_set_index].insert(
      bin_key,
      representative_entity.1,
      input_uniform_index,
    )
    let key = representative_entity.1.id().to_bits()
    self.input_uniform_indices.set(key, input_uniform_index)
    self.phase_types.set(key, effective_phase_type)
    return
  }
  if effective_phase_type == UnbatchableMesh {
    let mut unbatchable_index = -1
    for index in 0..<self.unbatchable_meshes.length() {
      if self.unbatchable_meshes[index].matches(batch_set_key, bin_key) {
        unbatchable_index = index
        break
      }
    }
    if unbatchable_index < 0 {
      self.unbatchable_meshes.push(
        Render3dShadowUnbatchableBinnedEntities::new(batch_set_key, bin_key),
      )
      unbatchable_index = self.unbatchable_meshes.length() - 1
    }
    self.unbatchable_meshes[unbatchable_index].insert(
      representative_entity.1,
      representative_entity.0,
      input_uniform_index,
    )
    let key = representative_entity.1.id().to_bits()
    self.input_uniform_indices.set(key, input_uniform_index)
    self.phase_types.set(key, effective_phase_type)
    return
  }
  if effective_phase_type == BatchableMesh && self.items.length() > 0 {
    let last_index = self.items.length() - 1
    let last_item = self.items[last_index]
    if render3d_shadow_batchable_item_can_extend(
        last_item, batch_set_key, bin_key, input_uniform_index_int,
      ) {
      self.items[last_index] = Render3dShadowPhaseItemData::{
        ..last_item,
        batch_range: Render3dShadowBatchRange::new(
          last_item.batch_range().start(),
          input_uniform_index_int + 1,
        ),
      }
      let key = representative_entity.1.id().to_bits()
      self.input_uniform_indices.set(key, input_uniform_index)
      self.phase_types.set(key, effective_phase_type)
      return
    }
  }
  self.items.push(
    Render3dShadowPhaseItemData::new(
      batch_set_key,
      bin_key,
      representative_entity.0,
      representative_entity.1,
      Render3dShadowBatchRange::new(
        input_uniform_index_int,
        input_uniform_index_int + 1,
      ),
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
  let key = representative_entity.1.id().to_bits()
  self.input_uniform_indices.set(key, input_uniform_index)
  self.phase_types.set(key, effective_phase_type)
}

///|
pub fn Render3dShadowViewPhaseData::remove(
  self : Render3dShadowViewPhaseData,
  main_entity : @render.MainEntity,
) -> Unit {
  let key = main_entity.id().to_bits()
  if !self.phase_types.contains(key) {
    return
  }
  let retained : Array[Render3dShadowPhaseItemData] = []
  for item in self.items {
    if item.main_entity() != main_entity {
      retained.push(item)
    }
  }
  self.items = retained
  let retained_multidrawable : Array[Render3dShadowMultidrawableBatchSetEntry] = []
  for entry in self.multidrawable_meshes {
    entry.remove_entity(main_entity)
    if !entry.is_empty() {
      retained_multidrawable.push(entry)
    }
  }
  self.multidrawable_meshes = retained_multidrawable
  let retained_unbatchable : Array[Render3dShadowUnbatchableBinnedEntities] = []
  for entities in self.unbatchable_meshes {
    entities.remove(main_entity)
    if !entities.is_empty() {
      retained_unbatchable.push(entities)
    }
  }
  self.unbatchable_meshes = retained_unbatchable
  self.input_uniform_indices.remove(key)
  self.phase_types.remove(key)
}

///|
pub fn Render3dShadowViewPhaseData::input_uniform_index(
  self : Render3dShadowViewPhaseData,
  main_entity : @render.MainEntity,
) -> UInt? {
  self.input_uniform_indices.get(main_entity.id().to_bits())
}

///|
pub fn Render3dShadowViewPhaseData::phase_type(
  self : Render3dShadowViewPhaseData,
  main_entity : @render.MainEntity,
) -> Render3dShadowBinnedRenderPhaseType? {
  self.phase_types.get(main_entity.id().to_bits())
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn Render3dShadowViewPhaseData::apply_queue(
  self : Render3dShadowViewPhaseData,
  queued : Render3dQueuedShadowPhaseData,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Unit {
  for main_entity in queued.dequeued() {
    self.remove(main_entity)
  }
  for item in queued.items() {
    self.add(
      item.batch_set_key(),
      item.bin_key(),
      (item.render_entity(), item.visible_entity()),
      item.current_uniform_index(),
      Render3dShadowBinnedRenderPhaseType::mesh(
        item.should_batch(),
        gpu_preprocessing_support,
      ),
    )
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::ViewBinnedRenderPhases<Shadow>`.
pub struct Render3dShadowPhasesData {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    Render3dShadowViewPhaseData,
  ]
}

///|
pub fn Render3dShadowPhasesData::Render3dShadowPhasesData() -> Render3dShadowPhasesData {
  Render3dShadowPhasesData::{ views: @hashmap.HashMap([]) }
}

///|
pub fn Render3dShadowPhasesData::len(self : Render3dShadowPhasesData) -> Int {
  self.views.length()
}

///|
pub fn Render3dShadowPhasesData::get(
  self : Render3dShadowPhasesData,
  view : @render_view.RetainedViewEntity,
) -> Render3dShadowViewPhaseData? {
  self.views.get(view)
}

///|
pub fn Render3dShadowPhasesData::view_or_insert(
  self : Render3dShadowPhasesData,
  view : @render_view.RetainedViewEntity,
  gpu_preprocessing_mode? : @render_batching.GpuPreprocessingMode = @render_batching.GpuPreprocessingMode::None,
) -> Render3dShadowViewPhaseData {
  match self.views.get(view) {
    Some(phase) => phase
    None => {
      let phase = Render3dShadowViewPhaseData::new(gpu_preprocessing_mode)
      self.views.set(view, phase)
      phase
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::ViewBinnedRenderPhases::prepare_for_new_frame`.
pub fn Render3dShadowPhasesData::prepare_for_new_frame(
  self : Render3dShadowPhasesData,
  view : @render_view.RetainedViewEntity,
  gpu_preprocessing_mode? : @render_batching.GpuPreprocessingMode = @render_batching.GpuPreprocessingMode::None,
) -> Render3dShadowViewPhaseData {
  let phase = self.view_or_insert(view, gpu_preprocessing_mode~)
  phase.prepare_for_new_frame()
  phase
}

///|
pub fn Render3dShadowPhasesData::remove(
  self : Render3dShadowPhasesData,
  view : @render_view.RetainedViewEntity,
) -> Unit {
  self.views.remove(view)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.
pub fn Render3dShadowPhasesData::retain(
  self : Render3dShadowPhasesData,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale : Array[@render_view.RetainedViewEntity] = []
  for view, _phase in self.views {
    if !live_views.contains(view) {
      stale.push(view)
    }
  }
  for view in stale {
    self.views.remove(view)
  }
}

///|
pub fn Render3dShadowPhasesData::apply_queue(
  self : Render3dShadowPhasesData,
  view : @render_view.RetainedViewEntity,
  queued : Render3dQueuedShadowPhaseData,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Render3dShadowViewPhaseData? {
  match self.views.get(view) {
    Some(phase) => {
      phase.apply_queue(queued, gpu_preprocessing_support)
      Some(phase)
    }
    None => None
  }
}

///|
fn render3d_shadow_phase_retained_view_key(
  view : @render_view.RetainedViewEntity,
) -> String {
  view.main_entity().to_bits().to_string() +
  ":" +
  view.auxiliary_entity().to_bits().to_string() +
  ":" +
  view.subview_index().to_string()
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
pub fn Render3dShadowPhasesData::prepare_phase_buffers(
  self : Render3dShadowPhasesData,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
) -> Array[Render3dShadowBinnedRenderPhaseBatchSetData] {
  let batch_sets : Array[Render3dShadowBinnedRenderPhaseBatchSetData] = []
  for view, phase in self.views {
    let prepared_batch_sets = phase.prepare_phase_buffers(
      render3d_shadow_phase_retained_view_key(view),
      no_indirect_drawing,
      enable_gpu_occlusion_culling,
      phase_batched_instance_buffers,
      phase_indirect_parameters_buffers,
    )
    for batch_set in prepared_batch_sets {
      batch_sets.push(batch_set)
    }
  }
  batch_sets
}

///|
let ecs_key_render3d_shadow_phases_data : @ecs.ResourceKey[
  Render3dShadowPhasesData,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewBinnedRenderPhases<Shadow>",
)

///|
pub impl @app.Resource for Render3dShadowPhasesData with fn resource() {
  ecs_key_render3d_shadow_phases_data
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhasePlugin<Shadow>::build`.
pub struct Render3dShadowPhaseBatchedInstanceBuffers {
  buffers : @render_batching.PhaseBatchedInstanceBuffers[Unit]
}

///|
pub fn Render3dShadowPhaseBatchedInstanceBuffers::Render3dShadowPhaseBatchedInstanceBuffers() -> Render3dShadowPhaseBatchedInstanceBuffers {
  Render3dShadowPhaseBatchedInstanceBuffers::{
    buffers: @render_batching.PhaseBatchedInstanceBuffers::new(),
  }
}

///|
let ecs_key_render3d_shadow_phase_batched_instance_buffers : @ecs.ResourceKey[
  Render3dShadowPhaseBatchedInstanceBuffers,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PhaseBatchedInstanceBuffers<Shadow>",
)

///|
pub impl @app.Resource for Render3dShadowPhaseBatchedInstanceBuffers with fn resource() {
  ecs_key_render3d_shadow_phase_batched_instance_buffers
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhasePlugin<Shadow>::build`.
pub struct Render3dShadowPhaseIndirectParametersBuffers {
  buffers : @render_batching.PhaseIndirectParametersBuffers
}

///|
pub fn Render3dShadowPhaseIndirectParametersBuffers::Render3dShadowPhaseIndirectParametersBuffers() -> Render3dShadowPhaseIndirectParametersBuffers {
  Render3dShadowPhaseIndirectParametersBuffers::{
    buffers: @render_batching.PhaseIndirectParametersBuffers::new(false),
  }
}

///|
let ecs_key_render3d_shadow_phase_indirect_parameters_buffers : @ecs.ResourceKey[
  Render3dShadowPhaseIndirectParametersBuffers,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PhaseIndirectParametersBuffers<Shadow>",
)

///|
pub impl @app.Resource for Render3dShadowPhaseIndirectParametersBuffers with fn resource() {
  ecs_key_render3d_shadow_phase_indirect_parameters_buffers
}

///|
pub fn render3d_prepare_shadow_phase_buffers_system(world : @ecs.World) -> Unit {
  let gpu_preprocessing_support = match
    world.get_resource(@render_batching.GpuPreprocessingSupport::resource()) {
    Some(value) => value
    None => return
  }
  let shadow_phases_ref = match
    world.get_resource_mut(Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None => return
  }
  let phase_instances_ref = match
    world.get_resource_mut(
      Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let phase_indirect_ref = match
    world.get_resource_mut(
      Render3dShadowPhaseIndirectParametersBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let enable_gpu_occlusion_culling = gpu_preprocessing_support.is_culling_supported()
  shadow_phases_ref.modify(fn(shadow_phases) {
    phase_instances_ref.modify(fn(phase_instances) {
      phase_indirect_ref.modify(fn(phase_indirect) {
        ignore(
          shadow_phases.prepare_phase_buffers(
            false,
            enable_gpu_occlusion_culling,
            phase_instances.buffers,
            phase_indirect.buffers,
          ),
        )
      })
    })
  })
}

///|
pub fn render3d_collect_shadow_phase_buffers_system(world : @ecs.World) -> Unit {
  let phase_instances_ref = match
    world.get_resource_mut(
      Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let phase_indirect_ref = match
    world.get_resource_mut(
      Render3dShadowPhaseIndirectParametersBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let batched_instances_ref = match
    world.get_resource_mut(
      RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let indirect_buffers_ref = match
    world.get_resource_mut(
      @render_batching.IndirectParametersBuffers::resource(),
    ) {
    Some(value) => value
    None => return
  }
  let indirect_settings = match
    world.get_resource(
      @render_batching.IndirectParametersBuffersSettings::resource(),
    ) {
    Some(value) => value
    None =>
      @render_batching.IndirectParametersBuffersSettings::IndirectParametersBuffersSettings()
  }
  phase_instances_ref.modify(fn(phase_instances) {
    phase_indirect_ref.modify(fn(phase_indirect) {
      batched_instances_ref.modify(fn(batched_instances) {
        indirect_buffers_ref.modify(fn(indirect_buffers) {
          @render_batching.collect_buffers_for_phase(
            "mgstudio_pbr::Shadow",
            phase_instances.buffers,
            phase_indirect.buffers,
            batched_instances.buffers,
            indirect_buffers,
            indirect_settings,
          )
        })
      })
    })
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.
pub fn render3d_prepare_shadow_phase_views(
  world : @ecs.World,
  extracted_retained_view : @render_view.RetainedViewEntity,
  light_entities : Array[Render3dLightEntity],
  gpu_preprocessing_mode? : @render_batching.GpuPreprocessingMode = @render_batching.GpuPreprocessingMode::None,
) -> @hashset.HashSet[@render_view.RetainedViewEntity] {
  let live_shadow_mapping_lights : @hashset.HashSet[
    @render_view.RetainedViewEntity,
  ] = @hashset.HashSet([])
  let shadow_render_phases = match
    world.get_resource_mut(Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing ViewBinnedRenderPhases<Shadow> resource during pbr shadow phase preparation",
      )
  }
  shadow_render_phases.modify(fn(phases) {
    for light_entity in light_entities {
      let retained_view_entity = light_entity.shadow_phase_retained_view(
        extracted_retained_view,
      )
      ignore(
        phases.prepare_for_new_frame(
          retained_view_entity,
          gpu_preprocessing_mode~,
        ),
      )
      live_shadow_mapping_lights.add(retained_view_entity)
    }
    phases.retain(live_shadow_mapping_lights)
  })
  live_shadow_mapping_lights
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub struct Render3dQueuedShadowPhaseData {
  dequeued : Array[@render.MainEntity]
  items : Array[Render3dQueuedShadowPhaseItemData]
}

///|
pub fn Render3dQueuedShadowPhaseData::Render3dQueuedShadowPhaseData() -> Render3dQueuedShadowPhaseData {
  Render3dQueuedShadowPhaseData::{ dequeued: [], items: [] }
}

///|
pub fn Render3dQueuedShadowPhaseData::dequeued(
  self : Render3dQueuedShadowPhaseData,
) -> Array[@render.MainEntity] {
  self.dequeued
}

///|
pub fn Render3dQueuedShadowPhaseData::items(
  self : Render3dQueuedShadowPhaseData,
) -> Array[Render3dQueuedShadowPhaseItemData] {
  self.items
}

///|
fn render3d_shadow_queue_material_bind_group_index(
  world : @ecs.World,
  view_pending_shadow_queues : @render.ViewPendingQueues,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  material_instance : RenderMaterialInstance,
  material : Render3dResolvedMaterial,
  draw_function : @material.DrawFunctionId,
) -> Int?? {
  let depth_only_draw_function = material
    .material_properties()
    .get_draw_function(SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
  if depth_only_draw_function is Some(depth_only) &&
    depth_only.id() == draw_function.id() {
    return Some(None)
  }
  guard world.get_resource(RenderMaterialBindings::resource()) is Some(bindings) else {
    render3d_enqueue_view_pending_shadow_material(
      view_pending_shadow_queues, render_entity, visible_entity,
    )
    return None
  }
  match bindings.get(material_instance.asset_id()) {
    Some(binding) => Some(Some(binding.group().to_int()))
    None => {
      render3d_enqueue_view_pending_shadow_material(
        view_pending_shadow_queues, render_entity, visible_entity,
      )
      None
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`
// resolves `RenderMaterialInstances` through the prepared render material.
fn render3d_shadow_resolve_material(
  world : @ecs.World,
  visible_entity : @render.MainEntity,
  render_material_instances : RenderMaterialInstances,
) -> Render3dResolvedMaterial? {
  let source_world = @render.render_source_world(world)
  let material_slots = render_material3d_resolved_slots_or_empty(world)
  match material_slots.get(visible_entity.id()) {
    Some(Resolved(material)) => return Some(material)
    Some(Pending) => return None
    None => ()
  }
  match render_material_instances.get(visible_entity.id()) {
    Some(material_instance) =>
      return render3d_shadow_resolve_standard_material(
        world,
        source_world,
        material_instance.asset_id(),
      )
    None => return None
  }
}

///|
fn render3d_shadow_resolve_standard_material(
  world : @ecs.World,
  source_world : @ecs.World,
  material_id : Int,
) -> Render3dResolvedMaterial? {
  let material_handle : @asset.Handle[StandardMaterial] = @asset.Handle::new(
    material_id,
  )
  let material_assets_key : @ecs.ResourceKey[@asset.Assets[StandardMaterial]] = @asset.assets_resource_key()
  guard source_world.get_resource(material_assets_key) is Some(material_assets) else {
    return None
  }
  guard material_assets.get(material_handle) is Some(material) else {
    return None
  }
  let default_opaque_renderer_method = match
    world.get_resource(ecs_key_default_opaque_renderer_method) {
    Some(resource) => resource.renderer_method()
    None => OpaqueRendererMethod::Forward
  }
  let properties = render3d_material_properties_for_standard_material(
    material,
    None,
    default_opaque_renderer_method,
    pbr_prepass_enabled(source_world),
    standard_material_texture_features=pbr_render_world_standard_material_texture_features(
      world,
    ),
  )
  Some(
    Render3dResolvedMaterial::new(
      MaterialDrawData3d::Standard(material),
      properties,
      @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      "StandardMaterial",
    ),
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn render3d_queue_shadow_phase_data_for_visible_entities(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  visible_entities : @render_visibility.RenderVisibleEntities,
  view_render_layers : @camera_render_layers.RenderLayers?,
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_shadow_queues : @pbr_render.PendingShadowQueues,
) -> Render3dQueuedShadowPhaseData {
  let result = Render3dQueuedShadowPhaseData::Render3dQueuedShadowPhaseData()
  let view_cache = match
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) =>
      match cache.get(retained_view_entity) {
        Some(value) => value
        None => return result
      }
    None => return result
  }
  let view_pending_shadow_queues = match
    pending_shadow_queues.queues().get(retained_view_entity) {
    Some(queues) => queues
    None =>
      abort(
        "View pending shadow queues should have been created in pbr.render3d.specialize_shadows",
      )
  }
  guard visible_entities.get(render3d_mesh_visibility_class())
    is Some(render_visible_mesh_entities) else {
    return result
  }
  let dequeued = dirty_specializations.iter_to_dequeue(
    retained_view_entity, render_visible_mesh_entities,
  )
  let result = Render3dQueuedShadowPhaseData::{ dequeued, items: [] }
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort("missing RenderMeshInstances resource during pbr shadow queueing")
  }
  let render_material_instances = match
    world.get_resource(ecs_key_render_material_instances) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMaterialInstances resource during pbr shadow queueing",
      )
  }
  let mesh_allocator = match
    world.get_resource(@render_mesh.MeshAllocator::resource()) {
    Some(value) => value
    None => abort("missing MeshAllocator resource during pbr shadow queueing")
  }
  let resolved_view_layers = view_render_layers.unwrap_or(
    @camera_render_layers.RenderLayers::RenderLayers(),
  )
  let candidates = dirty_specializations.iter_to_queue(
    retained_view_entity,
    render_visible_mesh_entities,
    view_pending_shadow_queues.prev_frame(),
  )
  for candidate in candidates {
    let (render_entity, main_entity) = candidate
    guard view_cache.get(main_entity) is Some(cache_entry) else { continue }
    let (pipeline_id, draw_function) = cache_entry
    let mesh_instance = match
      render_mesh_instances.render_mesh_queue_data(main_entity) {
      Some(value) => value
      None => {
        render3d_enqueue_view_pending_shadow_material(
          view_pending_shadow_queues, render_entity, main_entity,
        )
        continue
      }
    }
    if !mesh_instance.flags().contains(RenderMeshInstanceFlags::shadow_caster()) {
      continue
    }
    let mesh_layers = mesh_instance
      .render_layers()
      .unwrap_or(@camera_render_layers.RenderLayers::RenderLayers())
    if !resolved_view_layers.intersects(mesh_layers) {
      continue
    }
    let material_instance = match
      render_material_instances.get(main_entity.id()) {
      Some(value) => value
      None => continue
    }
    let material = match
      render3d_shadow_resolve_material(
        world, main_entity, render_material_instances,
      ) {
      Some(value) => value
      None => {
        render3d_enqueue_view_pending_shadow_material(
          view_pending_shadow_queues, render_entity, main_entity,
        )
        continue
      }
    }
    let material_bind_group_index = match
      render3d_shadow_queue_material_bind_group_index(
        world, view_pending_shadow_queues, render_entity, main_entity, material_instance,
        material, draw_function,
      ) {
      Some(value) => value
      None => continue
    }
    guard mesh_allocator.mesh_slabs(mesh_instance.mesh_asset_id())
      is Some(slabs) else {
      continue
    }
    result.items.push(Render3dQueuedShadowPhaseItemData::{
      render_entity,
      visible_entity: main_entity,
      pipeline_id,
      draw_function,
      material_bind_group_index,
      mesh_asset_id: mesh_instance.mesh_asset_id(),
      current_uniform_index: mesh_instance.current_uniform_index(),
      should_batch: mesh_instance.should_batch(),
      slabs,
    })
  }
  result
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn render3d_apply_queued_shadow_phase_data(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  queued : Render3dQueuedShadowPhaseData,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Bool {
  let shadow_render_phases = match
    world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing ViewBinnedRenderPhases<Shadow> resource during pbr shadow queueing",
      )
  }
  shadow_render_phases.apply_queue(
    retained_view_entity, queued, gpu_preprocessing_support,
  )
  is Some(_)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn render3d_queue_shadow_phase_data_for_light(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  view_render_layers : @camera_render_layers.RenderLayers?,
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_shadow_queues : @pbr_render.PendingShadowQueues,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Bool {
  guard world.get_resource(Render3dShadowPhasesData::resource()) is Some(phases) &&
    phases.get(retained_view_entity) is Some(_) else {
    return false
  }
  let shadow_map_visible_entities = match
    (try! world.get_by_key(
      light_entity.shadow_map_visible_entity(),
      @render_visibility.ecs_key_render_shadow_map_visible_entities,
    )) {
    Some(value) => value
    None => abort("failed to get shadow light visible entities")
  }
  let visible_entities = match
    shadow_map_visible_entities.subview(
      light_entity.shadow_map_visible_retained_view(retained_view_entity),
    ) {
    Some(value) => value
    None => abort("failed to get shadow light visible entities for view")
  }
  let queued = render3d_queue_shadow_phase_data_for_visible_entities(
    world, retained_view_entity, visible_entities, view_render_layers, dirty_specializations,
    pending_shadow_queues,
  )
  let applied = render3d_apply_queued_shadow_phase_data(
    world, retained_view_entity, queued, gpu_preprocessing_support,
  )
  applied
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`
// outer per-shadow-view loop.
pub struct Render3dQueuedShadowPhaseView {
  light_entity : Render3dLightEntity
  retained_view_entity : @render_view.RetainedViewEntity
  view_render_layers : @camera_render_layers.RenderLayers?
}

///|
pub fn Render3dQueuedShadowPhaseView::new(
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  view_render_layers? : @camera_render_layers.RenderLayers? = None,
) -> Render3dQueuedShadowPhaseView {
  Render3dQueuedShadowPhaseView::{
    light_entity,
    retained_view_entity,
    view_render_layers,
  }
}

///|
pub fn Render3dQueuedShadowPhaseView::light_entity(
  self : Render3dQueuedShadowPhaseView,
) -> Render3dLightEntity {
  self.light_entity
}

///|
pub fn Render3dQueuedShadowPhaseView::retained_view_entity(
  self : Render3dQueuedShadowPhaseView,
) -> @render_view.RetainedViewEntity {
  self.retained_view_entity
}

///|
pub fn Render3dQueuedShadowPhaseView::view_render_layers(
  self : Render3dQueuedShadowPhaseView,
) -> @camera_render_layers.RenderLayers? {
  self.view_render_layers
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn render3d_queue_shadow_phase_data_for_views(
  world : @ecs.World,
  views : Array[Render3dQueuedShadowPhaseView],
  dirty_specializations : @render_visibility.DirtySpecializations,
  pending_shadow_queues : @pbr_render.PendingShadowQueues,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Int {
  let mut queued_count = 0
  for view in views {
    if render3d_queue_shadow_phase_data_for_light(
        world,
        view.light_entity,
        view.retained_view_entity,
        view.view_render_layers,
        dirty_specializations,
        pending_shadow_queues,
        gpu_preprocessing_support,
      ) {
      queued_count += 1
    }
  }
  queued_count
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_material_specialization_queue_data(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let render_material_instances = match
    world.get_resource(ecs_key_render_material_instances) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMaterialInstances resource during pbr material specialization",
      )
  }
  if render_material_instances.get(visible_entity.id()) is None {
    render3d_enqueue_pending_mesh_material(
      world, retained_view_entity, render_entity, visible_entity,
    )
    return None
  }
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshInstances resource during pbr material specialization",
      )
  }
  match render_mesh_instances.render_mesh_queue_data(visible_entity) {
    Some(value) => Some(value)
    None => {
      render3d_enqueue_pending_mesh_material(
        world, retained_view_entity, render_entity, visible_entity,
      )
      None
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::specialize_material_meshes`.
fn render3d_material_specialization_resolved_material(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Render3dResolvedMaterial? {
  let material_slots = render_material3d_resolved_slots_or_empty(world)
  match material_slots.get(visible_entity.id()) {
    Some(Resolved(material)) => Some(material)
    Some(Pending) | None => {
      render3d_enqueue_pending_mesh_material(
        world, retained_view_entity, render_entity, visible_entity,
      )
      None
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_queue_data(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  view_pending_shadow_queues : @render.ViewPendingQueues,
) -> RenderMeshQueueData? {
  ignore(retained_view_entity)
  let render_material_instances = match
    world.get_resource(ecs_key_render_material_instances) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMaterialInstances resource during pbr shadow specialization",
      )
  }
  if render_material_instances.get(visible_entity.id()) is None {
    render3d_enqueue_view_pending_shadow_material(
      view_pending_shadow_queues, render_entity, visible_entity,
    )
    return None
  }
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshInstances resource during pbr shadow specialization",
      )
  }
  let mesh_instance = match
    render_mesh_instances.render_mesh_queue_data(visible_entity) {
    Some(value) => value
    None => {
      render3d_enqueue_view_pending_shadow_material(
        view_pending_shadow_queues, render_entity, visible_entity,
      )
      return None
    }
  }
  let material = match
    render3d_shadow_resolve_material(
      world, visible_entity, render_material_instances,
    ) {
    Some(value) => value
    None => {
      render3d_enqueue_view_pending_shadow_material(
        view_pending_shadow_queues, render_entity, visible_entity,
      )
      return None
    }
  }
  if !material.material_properties().shadows_enabled {
    return None
  }
  if !mesh_instance.flags().contains(RenderMeshInstanceFlags::shadow_caster()) {
    return None
  }
  guard world.get_resource(@render_mesh.RenderMeshAssets::resource())
    is Some(render_meshes) else {
    return None
  }
  guard render_meshes.get(mesh_instance.mesh_asset_id()) is Some(_) else {
    return None
  }
  Some(mesh_instance)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_work_item_data(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  light_key : @material.ErasedMeshPipelineKey,
  view_pending_shadow_queues : @render.ViewPendingQueues,
) -> Render3dShadowSpecializationWorkItemData? {
  let queue_data = match
    render3d_shadow_specialization_queue_data(
      world, retained_view_entity, render_entity, visible_entity, view_pending_shadow_queues,
    ) {
    Some(value) => value
    None => return None
  }
  guard world.get_resource(@render_mesh.RenderMeshAssets::resource())
    is Some(render_meshes) else {
    return None
  }
  guard render_meshes.get(queue_data.mesh_asset_id()) is Some(render_mesh) else {
    return None
  }
  let render_material_instances = match
    world.get_resource(ecs_key_render_material_instances) {
    Some(value) => value
    None => return None
  }
  guard render3d_shadow_resolve_material(
      world, visible_entity, render_material_instances,
    )
    is Some(material) else {
    return None
  }
  let render_lightmaps = world.get_resource(
    @lightmap.RenderLightmaps::resource(),
  )
  let properties = material.material_properties()
  let mesh_key = render3d_shadow_specialization_mesh_key(
    light_key, render_mesh, properties, render_lightmaps, visible_entity,
  )
  Some(Render3dShadowSpecializationWorkItemData::{
    queue_data,
    visible_entity,
    retained_view_entity,
    mesh_key,
    layout: render_mesh.layout(),
    properties,
    material_type_tag: material.material_type_tag(),
  })
}

///|
// Temporary producer adapter for the remaining legacy `ExtractedMesh3d` array.
// The `RenderMesh` preparation owner itself lives in `render/mesh`.
fn render3d_extracted_render_mesh_assets_from_extracted_meshes(
  meshes : Array[ExtractedMesh3d],
) -> Array[@render_mesh.ExtractedRenderMeshAsset] {
  let extracted_assets : Array[@render_mesh.ExtractedRenderMeshAsset] = []
  let seen_mesh_assets : Map[Int, Unit] = {}
  for extracted_mesh in meshes {
    let mesh_handle = extracted_mesh.payload.mesh_handle
    if seen_mesh_assets.contains(mesh_handle.id()) {
      continue
    }
    guard @sprite.render_mesh_asset_get(mesh_handle) is Some(source_mesh) else {
      continue
    }
    seen_mesh_assets.set(mesh_handle.id(), ())
    extracted_assets.push(
      @render_mesh.ExtractedRenderMeshAsset::new(mesh_handle.id(), source_mesh),
    )
  }
  extracted_assets
}

///|
// Bevy source: `bevy_render/src/render_asset.rs::prepare_assets<RenderMesh>`.
fn render3d_prepare_render_mesh_assets_from_extracted_meshes(
  world : @ecs.World,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let render_mesh_assets = match
    world.get_resource_mut(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshAssets resource during pbr render mesh asset preparation",
      )
  }
  let mesh_allocator = match
    world.get_resource_mut(@render_mesh.MeshAllocator::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing MeshAllocator resource during pbr render mesh asset preparation",
      )
  }
  let mesh_allocator_settings = world
    .get_resource(@render_mesh.MeshAllocatorSettings::resource())
    .unwrap_or(@render_mesh.MeshAllocatorSettings::MeshAllocatorSettings())
  let extracted_assets = render3d_extracted_render_mesh_assets_from_extracted_meshes(
    meshes,
  )
  let prepared_assets = @render_mesh.prepare_render_mesh_assets(
    extracted_assets,
    mesh_runtime_state_value.mesh_vertex_buffer_layouts,
  )
  mesh_allocator.modify(fn(allocator) {
    for prepared_asset in prepared_assets {
      if allocator.mesh_slabs(prepared_asset.mesh_asset_id()) is Some(_) {
        continue
      }
      let render_mesh = prepared_asset.render_mesh()
      let vertex_stride = render_mesh
        .host_vertex_buffer_layout(
          mesh_runtime_state_value.mesh_vertex_buffer_layouts,
        )
        .layout()
        .layout()
        .array_stride()
      ignore(
        allocator.allocate_render_mesh(
          prepared_asset.mesh_asset_id(),
          render_mesh,
          vertex_stride,
          settings=mesh_allocator_settings,
        ),
      )
    }
  })
  render_mesh_assets.modify(fn(assets) {
    assets.insert_prepared_assets(prepared_assets)
  })
}

///|
fn render3d_prewarm_mesh_pipelines(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  let specialization_tick = world.read_change_tick()
  let retained_views = render3d_retained_view_entities(cameras)
  render3d_apply_dirty_material_specialization_cache(world, retained_views)
  render3d_prepare_pending_mesh_material_queues(world, retained_views)
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtySpecializations resource during pbr material specialization",
      )
  }
  let pending_queues = match
    world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingMeshMaterialQueues resource during pbr material specialization",
      )
  }
  for camera in cameras {
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    let candidates = render3d_material_specialization_candidates(
      world,
      camera.entity.render_entity,
      retained_view_entity,
      dirty_specializations,
      pending_queues,
    )
    for candidate in candidates {
      let (_render_entity, main_entity) = candidate
      let mesh_queue_data = match
        render3d_material_specialization_queue_data(
          world, retained_view_entity, _render_entity, main_entity,
        ) {
        Some(value) => value
        None => continue
      }
      let resolved_material = match
        render3d_material_specialization_resolved_material(
          world, retained_view_entity, _render_entity, main_entity,
        ) {
        Some(value) => value
        None => continue
      }
      ignore(
        render3d_prewarm_material_pipeline(
          world,
          resolved_material,
          camera.payload,
          retained_view_entity,
          main_entity.id(),
          mesh_queue_data,
          specialization_tick,
        ),
      )
    }
  }
}

///|
fn render3d_prewarm_motion_vector_material_pipelines(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let mut motion_vector_prewarm_needed = false
  for camera in cameras {
    if camera.payload.motion_vector_prepass_enabled {
      motion_vector_prewarm_needed = true
      break
    }
    match camera.payload.motion_blur {
      Some(motion_blur) =>
        if motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F {
          motion_vector_prewarm_needed = true
          break
        }
      None => ()
    }
  }
  for mesh_index in 0..<meshes.length() {
    let mesh = meshes[mesh_index].payload
    if motion_vector_prewarm_needed && mesh.motion_vector_enabled {
      ignore(render3d_prewarm_motion_vector_material_pipeline(world, mesh))
    }
  }
}

///|
fn render3d_prepare_shader_asset_paths(
  source_world : @ecs.World,
  world : @ecs.World,
) -> Unit {
  guard world.get_resource(ecs_key_render_material_shader_paths)
    is Some(shader_paths) else {
    return
  }
  for path in shader_paths.paths() {
    if @shader.shader_path_is_wesl(path) {
      @shader_runtime_render.shader_register_wesl_runtime_source(
        source_world,
        path,
        [],
      ) catch {
        err =>
          abort(
            "failed to compile render3d wesl material shader: \{path}: \{err.message()}",
          )
      }
    } else {
      @shader_runtime_render.shader_register_wgsl_runtime_source(
        source_world, path,
      )
    }
  }
}

///|
fn render3d_for_each_prepared_camera(
  frame : Render3dQueuedFrame,
  f : (@core.Entity, Camera3dViewPayload, Render3dPreparedCameraQueue) -> Unit,
) -> Unit {
  for camera_index in 0..<frame.prepared_camera_count {
    let extracted_camera = frame.cameras[camera_index]
    match frame.prepared_camera_queues[camera_index] {
      Some(prepared_queue) =>
        f(
          extracted_camera.entity.main_entity,
          extracted_camera.payload,
          prepared_queue,
        )
      None => ()
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::queue_material_meshes`
// consumes `RenderVisibleEntities<Mesh3d>` instead of scanning every extracted
// mesh for every view.
fn render3d_visible_main_entity_filter_for_camera(
  world : @ecs.World,
  camera : ExtractedCamera3d,
) -> Map[UInt64, Bool] {
  let visible : Map[UInt64, Bool] = {}
  guard (try! world.get_by_key(
      camera.entity.render_entity,
      @render_visibility.ecs_key_render_visible_entities,
    ))
    is Some(render_visible_entities) else {
    return visible
  }
  guard render_visible_entities.get(render3d_mesh_visibility_class())
    is Some(render_visible_mesh_entities) else {
    return visible
  }
  for pair in render_visible_mesh_entities.iter_visible() {
    let (_render_entity, main_entity) = pair
    visible.set(main_entity.id().to_bits(), true)
  }
  visible
}

///|
fn render3d_visible_main_entity_filters_for_cameras(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Array[Map[UInt64, Bool]] {
  let filters : Array[Map[UInt64, Bool]] = []
  for camera in cameras {
    filters.push(render3d_visible_main_entity_filter_for_camera(world, camera))
  }
  filters
}

///|
pub fn render3d_prepare_meshes_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let sorted_cameras_ref = @render.sorted_cameras_ref_or_abort(world)
  let mesh_runtime_state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
    world,
  )
  let binding_arrays_are_usable = @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=(@pbr_light_probe.STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS +
    @pbr_light_probe.MAX_VIEW_LIGHT_PROBES).reinterpret_as_uint(),
    required_binding_array_sampler_elements_per_shader_stage=@pbr_render.RENDER3D_LIGHTMAPS_PER_SLAB.reinterpret_as_uint(),
  )
  let clustered_decals_are_usable = @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
  let mesh_runtime_state_value = mesh_runtime_state.peek()
  if mesh_runtime_state_value.binding_arrays_are_usable !=
    binding_arrays_are_usable ||
    mesh_runtime_state_value.clustered_decals_are_usable !=
    clustered_decals_are_usable {
    mesh_runtime_state.set(
      mesh_runtime_state_value.with_pipeline_capabilities(
        binding_arrays_are_usable, clustered_decals_are_usable,
      ),
    )
    match world.get_resource_mut(ecs_key_specialized_material_pipeline_cache) {
      Some(cache) => cache.modify(fn(value) { value.clear() })
      None => ()
    }
  }
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let skin_uniforms = @pbr_render.skin_uniforms_mut_or_abort(world)
  if sorted_cameras_ref.peek().is_empty() {
    render3d_queue_clear_frame(world)
    render_mesh_instances_clear_resource(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  let world_transform_cache = @pbr_render.render3d_world_transform_cache_mut(
    world,
  )
  let frame_config = render3d_execute_frame_config(source_world)
  let cameras = world_transform_cache.modify(fn(world_transform_cache_value) {
    render3d_execute_collect_cameras(
      source_world,
      world,
      world_transform_cache_value,
      frame_config.gpu_instance_buffer_builder_requested,
      frame_config.gpu_culling_supported,
      frame_config.prepass_enabled,
      frame_config.default_opaque_renderer_method,
    )
  })
  let needs_mesh_previous_transform = render3d_set_mesh_motion_vector_flags(
    cameras,
  )
  if cameras.length() == 0 {
    @render.sorted_cameras_clear(sorted_cameras_ref)
    render3d_queue_clear_frame(world)
    render_mesh_instances_clear_resource(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  render3d_sync_extracted_view_components(world, cameras)
  render3d_check_views_need_specialization(
    world, cameras, binding_arrays_are_usable, clustered_decals_are_usable,
  )
  render3d_extract_render_visible_entities(world, source_world)
  let meshes = mesh_runtime_state.modify(fn(mesh_runtime_state_value) {
    let meshes = morph_indices.modify(fn(morph_indices_value) {
      skin_uniforms.modify(fn(skin_uniforms_value) {
        world_transform_cache.modify(fn(world_transform_cache_value) {
          render3d_execute_collect_meshes(
            world,
            source_world,
            mesh_runtime_state_value,
            morph_indices_value,
            skin_uniforms_value,
            world_transform_cache_value,
            needs_mesh_previous_transform,
            frame_config.default_opaque_renderer_method,
            frame_config.prepass_enabled,
          )
        })
      })
    })
    render3d_prepare_render_mesh_assets_from_extracted_meshes(
      world, mesh_runtime_state_value, meshes,
    )
    if frame_config.gpu_instance_buffer_builder_enabled {
      render_mesh_instances_extract_gpu_building_resource(
        world,
        source_world,
        frame_config.gpu_culling_supported,
      )
    } else {
      render_mesh_instances_update_cpu_building_resource(world, source_world)
    }
    render_mesh_instances_set_mesh_motion_vector_flags(world)
    meshes
  })
  render3d_queue_store_pending_frame(world, frame_config, cameras, meshes)
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(
    world,
    meshes.length(),
  )
}

///|
pub fn render3d_specialize_material_meshes_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  match render3d_pending_frame_snapshot(world) {
    Some(frame) => {
      render3d_prepare_shader_asset_paths(source_world, world)
      render3d_prewarm_mesh_pipelines(world, frame.cameras)
      render3d_prewarm_motion_vector_material_pipelines(
        world,
        frame.cameras,
        frame.meshes,
      )
    }
    None => ()
  }
}

///|
pub fn render3d_prepare_bind_groups_system(world : @ecs.World) -> Unit {
  if render3d_queue_frame_snapshot(world) is Some(frame) {
    let prepared_material_bind_groups : Map[String, Bool] = {}
    let material_instances = world.get_resource(
      ecs_key_render_material_instances,
    )
    let render_material_bindings = world.get_resource(
      RenderMaterialBindings::resource(),
    )
    let material_bind_group_allocators = world.get_resource(
      ecs_key_material_bind_group_allocators,
    )
    for camera in frame.cameras {
      render3d_prepare_extracted_camera_view_bind_group(camera)
    }
    prepare_render_material_bindings(
      material_instances, render_material_bindings, material_bind_group_allocators,
    )
    for mesh in frame.meshes {
      render3d_prepare_extracted_mesh_material_bind_group(
        mesh, prepared_material_bind_groups,
      )
    }
    render_mesh_instances_collect_gpu_building_resource(world)
  }
  ignore(@pbr_render.render3d_mesh_layouts())
}

///|
pub fn render3d_queue_meshes_system(world : @ecs.World) -> Unit {
  let queue_start = @time.host_time_now()
  let queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d",
  )
  fn finish_queue() -> Unit {
    @pbr_render.render3d_set_diagnostic_queue_cpu_ms(
      world,
      (@time.host_time_now() - queue_start) * 1000.0F,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "queue_3d",
      queue_trace_start_us,
    )
  }
  match render3d_queue_take_pending_frame(world) {
    Some(frame) => {
      let mesh_runtime_state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
        world,
      )
      let specialized_material_pipeline_cache = match
        world.get_resource(ecs_key_specialized_material_pipeline_cache) {
        Some(cache) => cache
        None =>
          abort(
            "missing SpecializedMaterialPipelineCache resource during pbr queue_meshes",
          )
      }
      let visible_main_entity_filters = render3d_visible_main_entity_filters_for_cameras(
        world,
        frame.cameras,
      )
      let material_slots = render_material3d_resolved_slots_or_empty(world)
      let pending_mesh_material_queues = match
        world.get_resource(PendingMeshMaterialQueues::resource()) {
        Some(value) => value
        None =>
          abort(
            "missing PendingMeshMaterialQueues resource during pbr queue_meshes",
          )
      }
      let render_mesh_instances = match
        world.get_resource(RenderMeshInstances::resource()) {
        Some(value) => value
        None =>
          abort("missing RenderMeshInstances resource during pbr queue_meshes")
      }
      let prepared_camera_queues = mesh_runtime_state.modify(fn(
        mesh_runtime_state_value,
      ) {
        render3d_prepare_camera_queue_entries(
          mesh_runtime_state_value,
          frame.cameras,
          frame.meshes,
          render_mesh_instances,
          material_slots,
          pending_mesh_material_queues,
          frame.frame_config.gpu_instance_buffer_builder_enabled,
          frame.frame_config.gpu_culling_supported,
          specialized_material_pipeline_cache~,
          visible_main_entity_filters=Some(visible_main_entity_filters),
        )
      })
      let shadow_execution_data = match
        render3d_queue_take_shadow_execution_data(world) {
        Some(value) => value
        None =>
          abort(
            "missing render3d shadow execution data before pbr queue_meshes",
          )
      }
      render3d_queue_store_frame(
        world,
        frame.frame_config,
        frame.cameras,
        frame.meshes,
        prepared_camera_queues,
        shadow_execution_data.camera_execution_plans,
        shadow_execution_data.queued_shadow_phase_views,
      )
    }
    None =>
      @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
  }
  finish_queue()
}

///|
// Bevy source:
// `bevy/crates/bevy_pbr/src/render/light.rs::check_views_lights_need_specialization`.
pub fn render3d_check_views_lights_need_specialization_system(
  world : @ecs.World,
) -> Unit {
  guard render3d_pending_frame_snapshot(world) is Some(frame) else { return }
  let lighting = render3d_lighting_with_clusterable_indices(
    world,
    @pbr_render.render3d_collect_lighting(world),
  )
  ignore(
    render3d_prepare_shadow_phase_views_for_cameras(
      world,
      frame.cameras,
      lighting,
      frame.frame_config.point_light_shadow_map_size,
    ),
  )
  let views = render3d_shadow_phase_queued_views_for_cameras(
    world,
    frame.cameras,
    lighting,
    frame.frame_config.point_light_shadow_map_size,
  )
  let shadow_render_phases = match
    world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing ViewBinnedRenderPhases<Shadow> resource during pbr shadow specialization check",
      )
  }
  let light_key_cache = match
    world.get_resource(@pbr_render.LightKeyCache::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing LightKeyCache resource during pbr shadow specialization check",
      )
  }
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtySpecializations resource during pbr shadow specialization check",
      )
  }
  for view in views {
    let retained_view_entity = view.retained_view_entity()
    @pbr_render.check_view_light_needs_specialization(
      light_key_cache,
      dirty_specializations,
      retained_view_entity,
      shadow_render_phases.get(retained_view_entity) is Some(_),
      render3d_light_entity_is_directional(view.light_entity()),
    )
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_specialize_shadows_system(world : @ecs.World) -> Unit {
  guard render3d_pending_frame_snapshot(world) is Some(frame) else { return }
  let (camera_execution_plans, queued_shadow_phase_views) = render3d_prepare_camera_execution_plans_for_pending_frame(
    world,
    frame.cameras,
    frame.meshes,
    frame.frame_config,
  )
  ignore(
    render3d_specialize_shadow_phase_views(world, queued_shadow_phase_views),
  )
  render3d_queue_store_shadow_execution_data(
    world, camera_execution_plans, queued_shadow_phase_views,
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::queue_shadows`.
pub fn render3d_queue_shadows_system(world : @ecs.World) -> Unit {
  guard render3d_queue_frame_snapshot(world) is Some(frame) else { return }
  ignore(
    render3d_queue_shadow_phase_views(world, frame.queued_shadow_phase_views),
  )
}

///|
pub fn render3d_queue_sweep_system(world : @ecs.World) -> Unit {
  let mesh_runtime_state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
    world,
  )
  mesh_runtime_state.modify(fn(mesh_runtime_state_value) {
    @pbr_render.render3d_sweep_mesh_runtime_caches(mesh_runtime_state_value)
  })
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  render3d_execute_impl(world)
}
