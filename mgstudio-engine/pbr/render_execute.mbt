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
    source_world,
    queued_frame.cameras,
    queued_frame.meshes,
    queued_frame.prepared_camera_queues,
    frame_config.point_light_shadow_map_size,
    frame_config.prepass_enabled,
    frame_config.deferred_lighting_enabled,
    frame_config.default_opaque_renderer_method,
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
fn render3d_sync_extracted_view_components(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  fn target_format_raw_for_camera(camera : Camera3dViewPayload) -> UInt {
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
      render3d_effect_stack_enabled(
        camera.chromatic_aberration,
        camera.vignette,
      ) ||
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
    let target_format_raw = target_format_raw_for_camera(
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
  let draw_material = mesh.payload.material
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
  let key = "\{texture_id}|\{normal_texture_id}|\{emissive_texture_id}|\{metallic_roughness_texture_id}|\{occlusion_texture_id}|\{depth_texture_id}|\{anisotropy_texture_id}|\{specular_tint_texture_id}|\{clearcoat_texture_id}|\{clearcoat_roughness_texture_id}|\{clearcoat_normal_texture_id}"
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
fn render3d_prewarm_material_pipeline(
  world : @ecs.World,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  mesh : Mesh3dExtractedPayload,
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
  guard mesh.material_properties.base_specialize is Some(base_specialize) else {
    return None
  }
  let render_mesh_assets = match
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None => return None
  }
  guard render_mesh_assets.get(render_mesh_queue_data.mesh_asset_id())
    is Some(render_mesh) else {
    return None
  }
  ignore(mesh_runtime_state_value)
  let layout = render_mesh.layout()
  let view_key_bits = render3d_camera_mesh_pipeline_view_key_bits(camera)
  let motion_vector_prepass = (
      view_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
    ) !=
    0UL
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    mesh.material_properties,
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
    visibility_range_dither=mesh.visibility_range is Some(_),
    lightmapped=match mesh.lightmap {
      Some(lightmap) => lightmap.image.id() >= 0
      None => false
    },
    lightmap_bicubic_sampling=match mesh.lightmap {
      Some(lightmap) => lightmap.image.id() >= 0 && lightmap.bicubic_sampling
      None => false
    },
  )
  let pipeline_id = @material.material_specialize_base(
    base_specialize,
    world,
    pipeline_key,
    layout,
    mesh.material_properties,
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
            retained_view_entity, visible_entity, specialization_tick, pipeline_id,
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
fn render3d_mesh_indices_by_main_entity(
  meshes : Array[ExtractedMesh3d],
) -> Map[UInt64, Int] {
  let indices : Map[UInt64, Int] = {}
  for index in 0..<meshes.length() {
    indices.set(meshes[index].entity.main_entity.to_bits(), index)
  }
  indices
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
  guard (try! world.get_by_key(
      shadow_light_entity, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    ))
    is Some(shadow_map_visible_entities) else {
    return []
  }
  guard shadow_map_visible_entities.subview(shadow_visible_retained_view_entity)
    is Some(visible_entities) else {
    return []
  }
  guard visible_entities.get(render3d_mesh_visibility_class())
    is Some(render_visible_mesh_entities) else {
    return []
  }
  let view_pending_shadow_queues = pending_shadow_queues
    .queues()
    .view_or_insert(retained_view_entity)
  dirty_specializations.iter_to_specialize(
    retained_view_entity,
    render_visible_mesh_entities,
    view_pending_shadow_queues.prev_frame(),
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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
fn render3d_enqueue_pending_shadow_material(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Unit {
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
    None =>
      abort(
        "missing PendingShadowQueues resource during pbr shadow specialization",
      )
  }
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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::specialize_shadows`.
pub fn render3d_shadow_specialization_queue_data(
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
        "missing RenderMaterialInstances resource during pbr shadow specialization",
      )
  }
  if render_material_instances.get(visible_entity.id()) is None {
    render3d_enqueue_pending_shadow_material(
      world, retained_view_entity, render_entity, visible_entity,
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
      render3d_enqueue_pending_shadow_material(
        world, retained_view_entity, render_entity, visible_entity,
      )
      return None
    }
  }
  let source_world = @render.render_source_world(world)
  let registry = material_runtime_registry_or_empty(world)
  let material = match
    material_runtime_registry_resolve_material(
      world,
      source_world,
      registry,
      visible_entity.id(),
    ) {
    Some(value) => value
    None => {
      render3d_enqueue_pending_shadow_material(
        world, retained_view_entity, render_entity, visible_entity,
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
) -> Render3dShadowSpecializationWorkItemData? {
  let queue_data = match
    render3d_shadow_specialization_queue_data(
      world, retained_view_entity, render_entity, visible_entity,
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
  let source_world = @render.render_source_world(world)
  let registry = material_runtime_registry_or_empty(world)
  guard material_runtime_registry_resolve_material(
      world,
      source_world,
      registry,
      visible_entity.id(),
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
// Bevy source: `bevy_render/src/mesh/allocator.rs::allocate_and_free_meshes`
// and `RenderAssets<RenderMesh>` preparation before
// `bevy_pbr/src/material.rs::specialize_material_meshes`.
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
  render_mesh_assets.modify(fn(assets) {
    for extracted_mesh in meshes {
      let mesh_handle = extracted_mesh.payload.mesh_handle
      guard @sprite.render_mesh_asset_get(mesh_handle) is Some(source_mesh) else {
        continue
      }
      let render_mesh = @render_mesh.RenderMesh::from_mesh(
        source_mesh,
        mesh_runtime_state_value.mesh_vertex_buffer_layouts,
      )
      assets.insert(mesh_handle.id(), render_mesh)
    }
  })
}

///|
fn render3d_prewarm_mesh_pipelines(
  world : @ecs.World,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
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
  let mesh_indices_by_main_entity = render3d_mesh_indices_by_main_entity(meshes)
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
  let shadow_prewarm_cache = render3d_shadow_material_pipeline_prewarm_cache_new()
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
      guard mesh_indices_by_main_entity.get(main_entity.id().to_bits())
        is Some(mesh_index) else {
        continue
      }
      let extracted_mesh = meshes[mesh_index]
      let mesh = extracted_mesh.payload
      let view_pipeline_id = render3d_prewarm_material_pipeline(
        world,
        mesh_runtime_state_value,
        mesh,
        camera.payload,
        retained_view_entity,
        main_entity.id(),
        mesh_queue_data,
        specialization_tick,
      )
      if view_pipeline_id is Some(_) && mesh.material_pipeline_id is None {
        meshes[mesh_index] = ExtractedMesh3d::{
          ..extracted_mesh,
          payload: Mesh3dExtractedPayload::{
            ..mesh,
            material_pipeline_id: view_pipeline_id,
          },
        }
      }
    }
  }
  for mesh_index in 0..<meshes.length() {
    let mesh = meshes[mesh_index].payload
    if motion_vector_prewarm_needed && mesh.motion_vector_enabled {
      ignore(render3d_prewarm_motion_vector_material_pipeline(world, mesh))
    }
    if !mesh.has_not_shadow_caster {
      ignore(
        render3d_prewarm_shadow_material_pipeline(
          world, mesh, shadow_prewarm_cache,
        ),
      )
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
      world_transform_cache_value,
      frame_config.gpu_instance_buffer_builder_requested,
      frame_config.gpu_culling_supported,
      frame_config.prepass_enabled,
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
  render3d_extract_render_visible_entities(world, source_world)
  let meshes = mesh_runtime_state.modify(fn(mesh_runtime_state_value) {
    let meshes = morph_indices.modify(fn(morph_indices_value) {
      skin_uniforms.modify(fn(skin_uniforms_value) {
        world_transform_cache.modify(fn(world_transform_cache_value) {
          render3d_execute_collect_meshes(
            world, source_world, mesh_runtime_state_value, morph_indices_value, skin_uniforms_value,
            world_transform_cache_value, needs_mesh_previous_transform,
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
  let mesh_runtime_state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
    world,
  )
  match render3d_pending_frame_snapshot(world) {
    Some(frame) =>
      mesh_runtime_state.modify(fn(mesh_runtime_state_value) {
        render3d_prepare_shader_asset_paths(source_world, world)
        render3d_prewarm_mesh_pipelines(
          world,
          mesh_runtime_state_value,
          frame.cameras,
          frame.meshes,
        )
      })
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
      let specialized_material_pipeline_cache = world.get_resource(
        ecs_key_specialized_material_pipeline_cache,
      )
      let visible_main_entity_filters = render3d_visible_main_entity_filters_for_cameras(
        world,
        frame.cameras,
      )
      let prepared_camera_queues = mesh_runtime_state.modify(fn(
        mesh_runtime_state_value,
      ) {
        render3d_prepare_camera_queue_entries(
          mesh_runtime_state_value,
          frame.cameras,
          frame.meshes,
          frame.frame_config.gpu_instance_buffer_builder_enabled,
          frame.frame_config.gpu_culling_supported,
          specialized_material_pipeline_cache~,
          visible_main_entity_filters=Some(visible_main_entity_filters),
        )
      })
      render3d_queue_store_frame(
        world,
        frame.frame_config,
        frame.cameras,
        frame.meshes,
        prepared_camera_queues,
      )
    }
    None =>
      @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
  }
  finish_queue()
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
