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
    sorted_cameras_ref.peek().entities.length(),
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
fn render3d_material_shader_paths_for_extracted_mesh(
  extracted_mesh : ExtractedMesh3d,
) -> (String?, String?) {
  (
    extracted_mesh.payload.material_vertex_shader_path,
    extracted_mesh.payload.material_fragment_shader_path,
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
  camera.atmosphere_environment_map_light is Some(_)
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
  bits
}

///|
fn render3d_prewarm_material_pipeline(
  world : @ecs.World,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  mesh : Mesh3dExtractedPayload,
  camera : Camera3dViewPayload,
  view_entity : @core.Entity,
  visible_entity : @core.Entity,
  specialization_tick : @core.Tick,
) -> @material.CachedRenderPipelineId? {
  match world.get_resource(ecs_key_specialized_material_pipeline_cache) {
    Some(cache) =>
      match cache.pipeline_id(view_entity, visible_entity) {
        Some(pipeline_id) => return Some(pipeline_id)
        None => ()
      }
    None => ()
  }
  guard mesh.material_properties.base_specialize is Some(base_specialize) else {
    return None
  }
  guard @sprite.render_mesh_asset_get(mesh.mesh_handle) is Some(mesh_asset) else {
    return None
  }
  let render_mesh = @render_mesh.RenderMesh::from_mesh(
    mesh_asset,
    mesh_runtime_state_value.mesh_vertex_buffer_layouts,
  )
  if world.get_resource(@render_mesh.RenderMeshAssets::resource()) is None {
    world.insert_resource(
      @render_mesh.RenderMeshAssets::resource(),
      @render_mesh.RenderMeshAssets::RenderMeshAssets(),
    )
  }
  match world.get_resource_mut(@render_mesh.RenderMeshAssets::resource()) {
    Some(render_mesh_assets) =>
      render_mesh_assets.modify(fn(assets) {
        assets.insert(mesh.mesh_handle.id(), render_mesh)
      })
    None => ()
  }
  let layout = render_mesh.layout()
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    mesh.material_properties,
    render_mesh,
    view_key_bits=render3d_camera_mesh_pipeline_view_key_bits(camera),
    msaa_samples=render3d_camera_msaa_samples(camera),
    has_previous_skin=camera.motion_vector_prepass_enabled &&
      mesh.has_previous_skin,
    has_previous_morph=camera.motion_vector_prepass_enabled &&
      mesh.previous_morph_weights_index >= 0,
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
        "failed to specialize pbr material pipeline for mesh \{mesh.mesh_handle.id()}: \{err}",
      )
  }
  match world.get_resource_mut(ecs_key_specialized_material_pipeline_cache) {
    Some(cache_ref) =>
      ignore(
        cache_ref.modify(fn(cache) {
          cache.insert(
            view_entity, visible_entity, specialization_tick, pipeline_id,
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
fn render3d_prewarm_mesh_pipelines(
  world : @ecs.World,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let prewarmed_keys : Map[String, Bool] = {}
  let specialization_tick = world.read_change_tick()
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
  for mesh_index in 0..<meshes.length() {
    let extracted_mesh = meshes[mesh_index]
    let mesh = extracted_mesh.payload
    let mut material_pipeline_id : @material.CachedRenderPipelineId? = None
    for camera in cameras {
      let view_pipeline_id = render3d_prewarm_material_pipeline(
        world,
        mesh_runtime_state_value,
        mesh,
        camera.payload,
        camera.entity.main_entity,
        extracted_mesh.entity.main_entity,
        specialization_tick,
      )
      if material_pipeline_id is None {
        material_pipeline_id = view_pipeline_id
      }
    }
    if material_pipeline_id is Some(_) {
      meshes[mesh_index] = ExtractedMesh3d::{
        ..extracted_mesh,
        payload: Mesh3dExtractedPayload::{ ..mesh, material_pipeline_id, },
      }
    }
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
    let (vertex_shader_path, fragment_shader_path) = render3d_material_shader_paths_for_extracted_mesh(
      meshes[mesh_index],
    )
    let vertex_shader_key = match vertex_shader_path {
      Some(path) => path
      None => ""
    }
    let fragment_shader_key = match fragment_shader_path {
      Some(path) => path
      None => ""
    }
    let cull_mode = @pbr_render.render3d_cull_mode_value(mesh.material, 0)
    let prewarm_key = "\{mesh.mesh_topology_kind}|\{cull_mode}|\{vertex_shader_key}|\{fragment_shader_key}"
    if prewarmed_keys.contains(prewarm_key) {
      continue
    }
    prewarmed_keys.set(prewarm_key, true)
    @render.host_gpu_prewarm_mesh3d_pipeline_variants(
      mesh_topology_kind=mesh.mesh_topology_kind,
      cull_mode~,
      vertex_shader_path~,
      fragment_shader_path~,
    )
  }
}

///|
fn render3d_prepare_shader_asset_paths(
  source_world : @ecs.World,
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let prepared_paths : Map[String, Bool] = {}
  for extracted_mesh in meshes {
    let (vertex_shader_path, fragment_shader_path) = render3d_material_shader_paths_for_extracted_mesh(
      extracted_mesh,
    )
    let paths = [vertex_shader_path, fragment_shader_path]
    for shader_path in paths {
      guard shader_path is Some(path) else { continue }
      if prepared_paths.contains(path) {
        continue
      }
      prepared_paths.set(path, true)
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
pub fn render3d_prepare_meshes_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let sorted_cameras_ref = @render.sorted_cameras_ref_or_abort(world)
  let mesh_runtime_state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(
    world,
  )
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let skin_uniforms = @pbr_render.skin_uniforms_mut_or_abort(world)
  if sorted_cameras_ref.peek().entities.length() == 0 {
    render3d_queue_clear_frame(world)
    render_mesh_instances_remove_cpu_building_resource(world)
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
    render_mesh_instances_remove_cpu_building_resource(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
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
    render3d_prewarm_mesh_pipelines(
      world, mesh_runtime_state_value, cameras, meshes,
    )
    if frame_config.gpu_instance_buffer_builder_enabled {
      render_mesh_instances_remove_cpu_building_resource(world)
    } else {
      render_mesh_instances_update_cpu_building_resource(world, meshes)
    }
    meshes
  })
  render3d_prepare_shader_asset_paths(source_world, meshes)
  render3d_queue_store_pending_frame(world, frame_config, cameras, meshes)
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(
    world,
    meshes.length(),
  )
}

///|
pub fn render3d_prepare_bind_groups_system(world : @ecs.World) -> Unit {
  if render3d_queue_frame_snapshot(world) is Some(frame) {
    let prepared_material_bind_groups : Map[String, Bool] = {}
    for camera in frame.cameras {
      render3d_prepare_extracted_camera_view_bind_group(camera)
    }
    for mesh in frame.meshes {
      render3d_prepare_extracted_mesh_material_bind_group(
        mesh, prepared_material_bind_groups,
      )
    }
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
