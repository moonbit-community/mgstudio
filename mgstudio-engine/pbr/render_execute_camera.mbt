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
fn render3d_execute_camera(
  world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  extracted_camera : ExtractedCamera3d,
  meshes : Array[ExtractedMesh3d],
  point_light_shadow_map_size : Int,
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  prepass_enabled : Bool,
  deferred_lighting_enabled : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  wireframe_config : WireframeConfig?,
  lighting : Render3dLightingState,
  delta_seconds : Float,
  cleared_targets_this_frame : Array[Int],
  next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry],
) -> Unit {
  let camera_entity = extracted_camera.entity.main_entity
  let camera = extracted_camera.payload
  @render.host_gpu_set_active_surface_target(camera.target_id)
  let target_width = camera.target_size.x
  let target_height = camera.target_size.y
  if target_width <= 0 || target_height <= 0 {
    return
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
      return
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
    return
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
    indexed_indirect_parameter_indices, non_indexed_indirect_parameter_indices, motion_vector_prepass_enabled,
    motion_blur_active, scene_target_id, velocity_target_id, view_width, view_height,
    view_width_logical, view_height_logical, viewport_x, viewport_y, viewport_width,
    viewport_height, camera_pass_projection, pass_lighting, camera_exposure_value,
    point_shadow_near, motion_vector_pass_kind,
  )
  scene_target_id = scene_target_id_next
  velocity_target_id = velocity_target_id_next
  let (
    point_shadow_texture_id_value,
    point_shadow_enabled_value,
    point_shadow_depth_bias_value,
  ) = render3d_execute_camera_point_shadow_pass(
    pass_lighting, point_light_shadow_map_size, camera_entity, draw_queue_entry,
    meshes, opaque_alpha_draw_item_indices, indexed_indirect_parameter_indices, non_indexed_indirect_parameter_indices,
    point_shadow_pass_kind,
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
