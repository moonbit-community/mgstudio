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
    render3d_execute_camera(
      world, phase_state_ref, extracted_camera, meshes, point_light_shadow_map_size,
      gpu_instance_buffer_builder_enabled, gpu_culling_supported, prepass_enabled,
      deferred_lighting_enabled, default_opaque_renderer_method, wireframe_config,
      lighting, delta_seconds, cleared_targets_this_frame, next_camera_motion_blur_history,
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
