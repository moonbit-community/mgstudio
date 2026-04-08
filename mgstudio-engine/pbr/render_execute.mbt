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
  let frame_config = render3d_execute_frame_config(source_world)
  let (cameras, needs_mesh_previous_transform) = render3d_execute_collect_cameras(
    source_world,
    world_transform_cache_ref,
    frame_config.gpu_instance_buffer_builder_requested,
    frame_config.gpu_culling_supported,
    frame_config.prepass_enabled,
  )
  if cameras.length() == 0 {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    finish_execute()
    return
  }
  let meshes = render3d_execute_collect_meshes(
    source_world, phase_state_ref, world_transform_cache_ref, needs_mesh_previous_transform,
  )
  render3d_execute_render_cameras(
    world,
    source_world,
    phase_state_ref,
    cameras,
    meshes,
    frame_config.point_light_shadow_map_size,
    frame_config.gpu_instance_buffer_builder_enabled,
    frame_config.gpu_culling_supported,
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
