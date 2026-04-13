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
  extracted_camera : ExtractedCamera3d,
  meshes : Array[ExtractedMesh3d],
  point_light_shadow_map_size : Int,
  prepass_enabled : Bool,
  deferred_lighting_enabled : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  wireframe_config : WireframeConfig?,
  lighting : Render3dLightingState,
  delta_seconds : Float,
  cleared_targets_this_frame : Array[Int],
  next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry],
  prepared_camera_queue : Render3dPreparedCameraQueue?,
) -> Unit {
  let camera_entity = extracted_camera.entity.main_entity
  let camera = extracted_camera.payload
  guard prepared_camera_queue is Some(prepared_queue) else { return }
  @render.host_gpu_set_active_surface_target(camera.target_id)
  let viewport_state = prepared_queue.viewport_state
  let viewport_x = viewport_state.viewport_x
  let viewport_y = viewport_state.viewport_y
  let viewport_width = viewport_state.viewport_width
  let viewport_height = viewport_state.viewport_height
  let viewport_depth_min = viewport_state.viewport_depth_min
  let viewport_depth_max = viewport_state.viewport_depth_max
  let view_width = viewport_state.view_width
  let view_height = viewport_state.view_height
  let view_width_logical = viewport_state.view_width_logical
  let view_height_logical = viewport_state.view_height_logical
  let temporal_aa_enabled = camera.temporal_anti_aliasing is Some(_)
  let camera_pass_projection = prepared_queue.camera_pass_projection
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
  let pass_config = render3d_execute_camera_pass_config(
    camera, camera_deferred_mode, deferred_lighting_enabled, prepass_enabled, temporal_aa_enabled,
    pass_lighting,
  )
  let camera_deferred_enabled = pass_config.camera_deferred_enabled
  let camera_forward_decal_enabled = pass_config.camera_forward_decal_enabled
  let camera_clustered_decal_enabled = pass_config.camera_clustered_decal_enabled
  let effective_exposure = pass_config.effective_exposure
  let camera_exposure_value = pass_config.camera_exposure_value
  let distance_fog = pass_config.distance_fog
  let clear_enabled = pass_config.clear_enabled
  let clear_color = pass_config.clear_color
  let motion_blur_active = pass_config.motion_blur_active
  let transmission_blur_taps = pass_config.transmission_blur_taps
  let transmission_steps = pass_config.transmission_steps
  let transmission_enabled = pass_config.transmission_enabled
  let bloom_enabled = pass_config.bloom_enabled
  let tonemap_postprocess_enabled = pass_config.tonemap_postprocess_enabled
  let effect_stack_postprocess_enabled = pass_config.effect_stack_postprocess_enabled
  let custom_post_process_enabled = pass_config.custom_post_process_enabled
  let tonemapping_stage_enabled = pass_config.tonemapping_stage_enabled
  let fxaa_postprocess_enabled = pass_config.fxaa_postprocess_enabled
  let auto_exposure_enabled = pass_config.auto_exposure_enabled
  let motion_vector_prepass_enabled = pass_config.motion_vector_prepass_enabled
  let fog_enabled = pass_config.fog_enabled
  let scene_pass_kind = pass_config.scene_pass_kind
  let motion_vector_pass_kind = pass_config.motion_vector_pass_kind
  let point_shadow_pass_kind = pass_config.point_shadow_pass_kind
  let mut scene_target_id = camera.target_id
  let mut velocity_target_id = -1
  let mut point_shadow_texture_id = -1
  let mut point_shadow_enabled = 0.0F
  let mut point_shadow_depth_bias = 0.0F
  let point_shadow_near = pass_config.point_shadow_near
  let draw_queue_entry = prepared_queue.draw_queue_entry
  let opaque_alpha_draw_item_indices = prepared_queue.opaque_alpha_draw_item_indices
  let indexed_indirect_parameter_indices = prepared_queue.indexed_indirect_parameter_indices
  let non_indexed_indirect_parameter_indices = prepared_queue.non_indexed_indirect_parameter_indices
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
