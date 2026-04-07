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
fn render3d_runtime_config_or_default(
  world : @ecs.World,
) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_plugin_runtime_config()
  }
}

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
fn render3d_mesh_draw_flags(mesh : ExtractedMesh3d) -> Int {
  let mut flags = 0
  if mesh.payload.is_forward_decal || mesh.payload.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  if !deferred_lighting_enabled {
    return OpaqueRendererMethod::Forward
  }
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_execute_impl(world : @ecs.World) -> Unit {
  let execute_start = @time.host_time_now()
  let execute_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d",
  )
  fn finish_execute() -> Unit {
    render3d_diagnostic_execute_cpu_ms_ref.val = (
        @time.host_time_now() - execute_start
      ) *
      1000.0F
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d",
      execute_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref()
  let runtime_config = render3d_runtime_config_or_default(source_world)
  let gpu_instance_buffer_builder_requested = @pbr_render.render3d_use_gpu_instance_buffer_builder(
    runtime_config.use_gpu_instance_buffer_builder,
  )
  let prepass_enabled = standard_material_prepass_enabled(source_world)
  let deferred_lighting_enabled = runtime_config.add_default_deferred_lighting_plugin &&
    deferred_pbr_lighting_enabled(source_world)
  let gpu_culling_supported = @pbr_render.render3d_gpu_culling_supported()
  let gpu_instance_buffer_builder_enabled = gpu_instance_buffer_builder_requested &&
    gpu_culling_supported
  @render.host_gpu_set_mesh3d_gpu_instance_builder_enabled(
    gpu_instance_buffer_builder_enabled,
  )
  let delta_seconds = @pbr_render.render3d_default_time_or_default(source_world).delta_seconds()
  let mut default_opaque_renderer_method = if (try! source_world.get_resource(
      ecs_key_default_opaque_renderer_method,
    ))
    is Some(default_method) {
    default_method.renderer_method()
  } else {
    OpaqueRendererMethod::Forward
  }
  if !deferred_lighting_enabled &&
    default_opaque_renderer_method is OpaqueRendererMethod::Deferred {
    default_opaque_renderer_method = OpaqueRendererMethod::Forward
  }
  let point_light_shadow_map_size = if (try! source_world.get_resource(
      ecs_key_point_light_shadow_map,
    ))
    is Some(shadow_map) {
    if shadow_map.size <= 0 {
      1
    } else {
      shadow_map.size
    }
  } else {
    PointLightShadowMap::default().size
  }
  let (cameras, needs_mesh_previous_transform) = render3d_execute_collect_cameras(
    source_world, world_transform_cache_ref, gpu_instance_buffer_builder_requested,
    gpu_culling_supported, prepass_enabled,
  )
  if cameras.length() == 0 {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    finish_execute()
    return
  }
  let wireframe_config = if (try! source_world.get_resource(
      ecs_key_wireframe_config,
    ))
    is Some(config) {
    Some(config)
  } else {
    None
  }
  let meshes = render3d_execute_collect_meshes(
    source_world, phase_state_ref, world_transform_cache_ref, needs_mesh_previous_transform,
  )
  let trace_render_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
  )
  let lighting = render3d_collect_lighting(source_world)
  let camera_phase_items = match
    render3d_prepared_camera_phase_items(world, cameras) {
    Some(items) => items
    None => render3d_queue_camera_phase_items(cameras)
  }
  let cleared_targets_this_frame : Array[Int] = []
  let next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry] = []
  for camera_phase_item in camera_phase_items {
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    let camera_entity = extracted_camera.entity.main_entity
    let camera = extracted_camera.payload
    @render.host_gpu_set_active_surface_target(camera.target_id)
    let target_width = camera.target_size.x
    let target_height = camera.target_size.y
    if target_width <= 0 || target_height <= 0 {
      continue
    }
    let mut viewport_x = 0
    let mut viewport_y = 0
    let mut viewport_width = target_width
    let mut viewport_height = target_height
    let mut viewport_depth_min = 0.0F
    let mut viewport_depth_max = 1.0F
    let mut view_width = target_width
    let mut view_height = target_height
    if camera.camera.viewport is Some(viewport) {
      viewport_x = viewport.physical_position.x
      viewport_y = viewport.physical_position.y
      viewport_width = viewport.physical_size.x
      viewport_height = viewport.physical_size.y
      if viewport_width <= 0 || viewport_height <= 0 {
        continue
      }
      viewport_depth_min = viewport.depth_min
      viewport_depth_max = viewport.depth_max
      view_width = viewport_width
      view_height = viewport_height
    }
    // Render target textures and viewport dimensions are in physical pixels.
    // Do not divide by window scale factor here; doing so halves render size on
    // high-DPI displays and breaks camera framing/post-process alignment.
    camera.scale_factor |> ignore
    let view_width_logical = view_width
    let view_height_logical = view_height
    if view_width_logical <= 0 || view_height_logical <= 0 {
      continue
    }
    let temporal_aa_enabled = camera.temporal_anti_aliasing is Some(_)
    let camera_pass_projection = render3d_camera_pass_projection(
      camera.projection,
      camera.sub_camera_view,
      camera.temporal_jitter,
      view_width,
      view_height,
    )
    let camera_frustum_planes = render3d_host_preprocess_view_frustum_planes(
      camera.projection,
      camera.transform,
    )
    let camera_near = camera_pass_projection.camera_near
    let camera_far = camera_pass_projection.camera_far
    let current_clip_from_world = @pbr_render.render3d_pass_projection_clip_from_world(
      camera_pass_projection,
      camera.transform,
    )
    next_camera_motion_blur_history.push({
      entity: camera_entity,
      transform: camera.transform,
      clip_from_world: current_clip_from_world,
    })
    let pass_lighting = render3d_camera_apply_environment_map_lighting(
      lighting, extracted_camera,
    )
    let environment_map_state = render3d_camera_environment_map_state(
      extracted_camera,
    )
    let camera_deferred_mode = render3d_camera_deferred_mode(
      camera.camera3d.deferred_config,
      default_opaque_renderer_method,
      deferred_lighting_enabled,
    )
    let camera_deferred_enabled = deferred_lighting_enabled &&
      prepass_enabled &&
      (
        camera.deferred_prepass_enabled ||
        camera.camera3d.deferred_config.requires_deferred_prepass ||
        camera_deferred_mode is OpaqueRendererMethod::Deferred
      )
    let camera_msaa_allows_forward_decals = match camera.msaa {
      Some(msaa) => msaa is Msaa::Off
      None => true
    }
    let camera_forward_decal_enabled = render3d_decal_mode_allows_forward(
        camera.camera3d.decal_config.mode,
      ) &&
      camera_msaa_allows_forward_decals &&
      (
        !camera.camera3d.decal_config.requires_depth_prepass ||
        camera.depth_prepass_enabled
      )
    let camera_clustered_decal_enabled = render3d_decal_mode_allows_clustered(
        camera.camera3d.decal_config.mode,
      ) &&
      (
        !camera.camera3d.decal_config.clustered_requires_deferred_prepass ||
        camera_deferred_enabled
      )
    let effective_exposure = camera.exposure
    let camera_exposure_value = match effective_exposure {
      Some(value) => value.exposure()
      None => Exposure::default().exposure()
    }
    let camera_base_fog = match camera.camera3d.distance_fog {
      Some(value) => value
      None =>
        DistanceFog::new(
          @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
          FogFalloff3d::linear(0.0F, 0.0F),
        )
    }
    let distance_fog = render3d_camera_distance_fog(
      camera_base_fog,
      camera.camera3d.volumetric_fog,
      camera.camera3d.atmosphere,
      camera.camera3d.atmosphere_settings,
    )
    let (clear_enabled, resolved_clear_color) = camera.camera.clear_color.resolve()
    let clear_color = resolved_clear_color
    let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    } else {
      false
    }
    let transmission_blur_taps = if camera.screen_space_transmission
      is Some(transmission) &&
      transmission.steps > 0 {
      screen_space_transmission_blur_taps(transmission.quality)
    } else {
      0
    }
    let transmission_steps = if camera.screen_space_transmission
      is Some(transmission) {
      transmission.steps
    } else {
      0
    }
    let transmission_enabled = transmission_blur_taps > 0
    let bloom_enabled = camera.bloom is Some(_)
    let tonemapping_stage_enabled = render3d_tonemapping_stage_enabled(
      camera.tonemapping,
      camera.deband_dither,
      camera.hdr_enabled,
      camera.color_grading,
    )
    let effect_stack_postprocess_enabled = render3d_effect_stack_enabled(
      camera.chromatic_aberration,
      camera.vignette,
    )
    let custom_post_process_enabled = render3d_custom_post_process_enabled(
      camera.custom_post_process3d,
    )
    let fxaa_postprocess_enabled = render3d_fxaa_enabled(camera.fxaa)
    let tonemap_postprocess_enabled = tonemapping_stage_enabled ||
      effect_stack_postprocess_enabled ||
      custom_post_process_enabled ||
      fxaa_postprocess_enabled
    let auto_exposure_enabled = camera.camera3d.auto_exposure is Some(_)
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        motion_blur_active ||
        camera.motion_vector_prepass_enabled ||
        temporal_aa_enabled ||
        camera.gpu_occlusion_culling_enabled
      )
    let fog_enabled = render3d_distance_fog_enabled(distance_fog)
    let decal_enabled = camera_forward_decal_enabled ||
      camera_clustered_decal_enabled
    let postprocess_enabled = motion_blur_active ||
      bloom_enabled ||
      tonemap_postprocess_enabled ||
      auto_exposure_enabled
    let scene_pass_kind = @pbr_render.render3d_pass_kind_encode(
      @pbr_render.RENDER3D_PASS_KIND_BASE_SCENE,
      postprocess_enabled,
      fog_enabled,
      decal_enabled,
    )
    let motion_vector_pass_kind = @pbr_render.render3d_pass_kind_encode(
      @pbr_render.RENDER3D_PASS_KIND_BASE_MOTION_VECTOR,
      false,
      false,
      false,
    )
    let point_shadow_pass_kind = @pbr_render.render3d_pass_kind_encode(
      @pbr_render.RENDER3D_PASS_KIND_BASE_POINT_SHADOW,
      false,
      false,
      false,
    )
    let mut scene_target_id = camera.target_id
    let mut velocity_target_id = -1
    let mut point_shadow_texture_id = -1
    let mut point_shadow_enabled = 0.0F
    let mut point_shadow_depth_bias = 0.0F
    let point_shadow_near = if pass_lighting.point_shadow_map_near_z > 0.0001F {
      pass_lighting.point_shadow_map_near_z
    } else {
      0.0001F
    }
    let queue_build_result = render3d_execute_camera_queue_build(
      phase_state_ref, camera_entity, camera, camera_frustum_planes, meshes, gpu_instance_buffer_builder_enabled,
      gpu_culling_supported, camera_pass_projection, viewport_x, viewport_y, viewport_width,
      viewport_height, camera_exposure_value,
    )
    let draw_queue_entry = queue_build_result.draw_queue_entry
    let opaque_alpha_draw_item_indices = queue_build_result.opaque_alpha_draw_item_indices
    let indexed_indirect_parameter_indices = queue_build_result.indexed_indirect_parameter_indices
    let non_indexed_indirect_parameter_indices = queue_build_result.non_indexed_indirect_parameter_indices
    let (scene_target_id_next, velocity_target_id_next) = render3d_execute_camera_motion_vector_pass(
      camera_entity, camera, draw_queue_entry, meshes, opaque_alpha_draw_item_indices,
      indexed_indirect_parameter_indices, non_indexed_indirect_parameter_indices,
      motion_vector_prepass_enabled, motion_blur_active, scene_target_id, velocity_target_id,
      view_width, view_height, view_width_logical, view_height_logical, viewport_x,
      viewport_y, viewport_width, viewport_height, camera_pass_projection, pass_lighting,
      camera_exposure_value, point_shadow_near, motion_vector_pass_kind,
    )
    scene_target_id = scene_target_id_next
    velocity_target_id = velocity_target_id_next
    let (
      point_shadow_texture_id_value,
      point_shadow_enabled_value,
      point_shadow_depth_bias_value,
    ) = render3d_execute_camera_point_shadow_pass(
      pass_lighting, point_light_shadow_map_size, camera_entity, draw_queue_entry,
      meshes, opaque_alpha_draw_item_indices, indexed_indirect_parameter_indices,
      non_indexed_indirect_parameter_indices, point_shadow_pass_kind,
    )
    point_shadow_texture_id = point_shadow_texture_id_value
    point_shadow_enabled = point_shadow_enabled_value
    point_shadow_depth_bias = point_shadow_depth_bias_value
    if !motion_blur_active &&
      (
        transmission_enabled ||
        bloom_enabled ||
        tonemap_postprocess_enabled ||
        auto_exposure_enabled
      ) &&
      (
        camera.target_id < 0 ||
        bloom_enabled ||
        tonemap_postprocess_enabled ||
        auto_exposure_enabled
      ) {
      let (scene_id, _velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera_entity, view_width, view_height,
      )
      scene_target_id = scene_id
    }
    let trace_camera_main_pass_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_main_pass",
    )
    render3d_execute_camera_main_pass(
      world, camera_entity, extracted_camera, camera, draw_queue_entry, meshes, indexed_indirect_parameter_indices,
      non_indexed_indirect_parameter_indices, scene_target_id, view_width, view_height,
      view_width_logical, view_height_logical, clear_color, viewport_x, viewport_y,
      viewport_width, viewport_height, camera_pass_projection, pass_lighting, camera_exposure_value,
      point_shadow_texture_id, point_shadow_enabled, point_shadow_depth_bias, environment_map_state,
      point_shadow_near, scene_pass_kind, clear_enabled, cleared_targets_this_frame,
      camera_forward_decal_enabled, camera_clustered_decal_enabled, camera_deferred_enabled,
      default_opaque_renderer_method, camera_near, camera_far, distance_fog, fog_enabled,
      transmission_enabled, transmission_steps, transmission_blur_taps, wireframe_config,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_main_pass",
      trace_camera_main_pass_start_us,
    )
    let trace_camera_postprocess_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_postprocess",
    )
    render3d_execute_camera_postprocess(
      world, camera_entity, camera, scene_target_id, velocity_target_id, motion_blur_active,
      bloom_enabled, tonemap_postprocess_enabled, auto_exposure_enabled, effect_stack_postprocess_enabled,
      custom_post_process_enabled, tonemapping_stage_enabled, fxaa_postprocess_enabled,
      effective_exposure, view_width, view_height, view_width_logical, view_height_logical,
      clear_color, viewport_x, viewport_y, viewport_width, viewport_height, viewport_depth_min,
      viewport_depth_max, clear_enabled, delta_seconds, cleared_targets_this_frame,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_postprocess",
      trace_camera_postprocess_start_us,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
    trace_render_cameras_start_us,
  )
  camera_motion_blur_history_sync(next_camera_motion_blur_history)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  phase_state_ref.val.prepared_camera_order.clear()
  finish_execute()
}
