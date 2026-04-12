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
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref()
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
  render3d_diagnostic_prepared_camera_count_ref.val = phase_state_ref.val.prepared_camera_order.length()
  render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref()
  render3d_prepare_morphs(source_world, phase_state_ref)
  @pbr_render.render3d_prepare_skin_bindings_upload(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
pub fn render3d_queue_system(world : @ecs.World) -> Unit {
  let queue_start = @time.host_time_now()
  let queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d",
  )
  fn finish_queue() -> Unit {
    render3d_diagnostic_queue_cpu_ms_ref.val = (
        @time.host_time_now() - queue_start
      ) *
      1000.0F
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "queue_3d",
      queue_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  if phase_state_ref.val.prepared_camera_order.length() == 0 {
    render3d_queue_clear_frame(world)
    render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
    finish_queue()
    return
  }
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
    render3d_queue_clear_frame(world)
    render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
    finish_queue()
    return
  }
  let meshes = render3d_execute_collect_meshes(
    source_world, phase_state_ref, world_transform_cache_ref, needs_mesh_previous_transform,
  )
  render3d_queue_store_frame(world, frame_config, cameras, meshes)
  render3d_diagnostic_queued_visible_mesh_count_ref.val = meshes.length()
  finish_queue()
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  render3d_execute_impl(world)
}
