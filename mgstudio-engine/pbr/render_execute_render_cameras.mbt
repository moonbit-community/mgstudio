// Copyright 2026 International Digital Economy Academy
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
fn render3d_execute_render_cameras(
  world : @ecs.World,
  source_world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  point_light_shadow_map_size : Int,
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  prepass_enabled : Bool,
  deferred_lighting_enabled : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  wireframe_config : WireframeConfig?,
  delta_seconds : Float,
) -> Unit {
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
}
