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
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  guard render3d_queue_take_frame(world) is Some(queued_frame) else {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
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
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  phase_state_ref.val.prepared_camera_order.clear()
  finish_execute()
}

///|
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  @pbr_render.render3d_world_transform_cache_begin_frame(
    world_transform_cache_ref,
  )
  render3d_refresh_prepared_camera_order_if_needed(
    source_world, phase_state_ref,
  )
  render3d_extract_morphs(source_world, phase_state_ref)
  @pbr_render.render3d_extract_skin_bindings(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
  @pbr_render.render3d_set_diagnostic_prepared_camera_count(
    world,
    phase_state_ref.val.prepared_camera_order.length(),
  )
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
}

///|
pub fn render3d_prepare_morphs_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  render3d_prepare_morphs(source_world, phase_state_ref)
}

///|
pub fn render3d_prepare_skin_bindings_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  @pbr_render.render3d_prepare_skin_bindings_upload(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  render3d_prepare_morphs_system(world)
  render3d_prepare_skin_bindings_system(world)
}

///|
pub fn render3d_prepare_resources_flush_system(world : @ecs.World) -> Unit {
  ignore(world)
}

///|
fn render3d_prepare_extracted_mesh_material_bind_group(
  mesh : ExtractedMesh3d,
) -> Unit {
  let mut draw_material = mesh.payload.material
  if mesh.payload.lightmap is Some(lightmap) && lightmap.image.id() > 0 {
    draw_material = draw_material.with_base_color_texture(Some(lightmap.image))
  }
  let mut texture_id = match draw_material.base_color_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut normal_texture_id = match
    (draw_material.normal_map_texture, draw_material.clearcoat_normal_texture) {
    (Some(texture), _) => texture.id()
    (None, Some(texture)) => texture.id()
    (None, None) => -1
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
  @render.host_gpu_prepare_mesh3d_material_bind_group(
    texture_id~,
    normal_texture_id~,
    emissive_texture_id~,
    metallic_roughness_texture_id~,
    occlusion_texture_id~,
    depth_texture_id~,
    anisotropy_texture_id~,
    specular_tint_texture_id~,
  )
}

///|
fn render3d_prepare_extracted_camera_view_bind_group(
  camera : ExtractedCamera3d,
) -> Unit {
  let environment_map_state = render3d_camera_environment_map_state(camera)
  @render.host_gpu_prepare_mesh3d_view_bind_group(
    transmission_source_texture_id=-1,
    point_shadow_texture_id=-1,
    environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
    environment_specular_texture_id=environment_map_state.specular_texture_id,
  )
}

///|
fn render3d_prewarm_mesh_pipelines(meshes : Array[ExtractedMesh3d]) -> Unit {
  let prewarmed_keys : Map[String, Bool] = {}
  for extracted_mesh in meshes {
    let mesh = extracted_mesh.payload
    let shader_path = match mesh.material_extension {
      Some(extension) => extension.shader_path
      None => None
    }
    let shader_key = match shader_path {
      Some(path) => path
      None => ""
    }
    let cull_mode = @pbr_render.render3d_cull_mode_value(mesh.material, 0)
    let prewarm_key = "\{mesh.mesh_topology_kind}|\{cull_mode}|\{mesh.is_forward_decal}|\{shader_key}"
    if prewarmed_keys.contains(prewarm_key) {
      continue
    }
    prewarmed_keys.set(prewarm_key, true)
    @render.host_gpu_prewarm_mesh3d_pipeline_variants(
      mesh_topology_kind=mesh.mesh_topology_kind,
      cull_mode~,
      shader_path~,
      forward_decal=mesh.is_forward_decal,
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
    let mesh = extracted_mesh.payload
    let shader_path = match mesh.material_extension {
      Some(extension) => extension.shader_path
      None => None
    }
    guard shader_path is Some(path) else { continue }
    if prepared_paths.contains(path) {
      continue
    }
    prepared_paths.set(path, true)
    if @shader.shader_path_is_wesl(path) {
      @shader.shader_register_wesl_runtime_source(source_world, path, []) catch {
        err =>
          abort(
            "failed to compile render3d wesl material shader: \{path}: \{err.message()}",
          )
      }
    } else {
      @shader.shader_register_wgsl_runtime_source(source_world, path)
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
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  if phase_state_ref.val.prepared_camera_order.length() == 0 {
    render3d_queue_clear_frame(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  let frame_config = render3d_execute_frame_config(source_world)
  let cameras = render3d_execute_collect_cameras(
    source_world,
    world_transform_cache_ref,
    frame_config.gpu_instance_buffer_builder_requested,
    frame_config.gpu_culling_supported,
    frame_config.prepass_enabled,
  )
  let needs_mesh_previous_transform = render3d_set_mesh_motion_vector_flags(
    cameras,
  )
  if cameras.length() == 0 {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    render3d_queue_clear_frame(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  let meshes = render3d_execute_collect_meshes(
    world, source_world, phase_state_ref, world_transform_cache_ref, needs_mesh_previous_transform,
  )
  render3d_extract_material_instances(world, meshes)
  render3d_prepare_shader_asset_paths(source_world, meshes)
  render3d_prewarm_mesh_pipelines(meshes)
  let prepared_camera_queues = render3d_prepare_camera_queue_entries(
    phase_state_ref,
    cameras,
    meshes,
    frame_config.gpu_instance_buffer_builder_enabled,
    frame_config.gpu_culling_supported,
  )
  render3d_queue_store_frame(
    world, frame_config, cameras, meshes, prepared_camera_queues,
  )
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(
    world,
    meshes.length(),
  )
}

///|
pub fn render3d_prepare_bind_groups_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  @pbr_prepass.prepass_update_pipeline_state(source_world)
  if render3d_queue_frame_snapshot(world) is Some(frame) {
    for camera in frame.cameras {
      render3d_prepare_extracted_camera_view_bind_group(camera)
    }
    for mesh in frame.meshes {
      render3d_prepare_extracted_mesh_material_bind_group(mesh)
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
        render3d_dispatch_camera_queue_entry(
          camera_entity, camera_payload, prepared_queue,
        )
      })
    None =>
      @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
  }
  finish_queue()
}

///|
pub fn render3d_queue_sweep_system(world : @ecs.World) -> Unit {
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  @pbr_render.render3d_sweep_mesh_runtime_caches(phase_state_ref)
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  render3d_execute_impl(world)
}
