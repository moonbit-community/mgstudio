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
priv struct Render3dExecuteCameraQueueBuildResult {
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d
  opaque_alpha_draw_item_indices : Array[Int]
  indexed_indirect_parameter_indices : Array[Int]
  non_indexed_indirect_parameter_indices : Array[Int]
}

///|
fn render3d_execute_camera_queue_build(
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  meshes : Array[ExtractedMesh3d],
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  camera_pass_projection : Render3dPassProjection,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> Render3dExecuteCameraQueueBuildResult {
  let trace_camera_queue_build_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_build",
  )
  let trace_camera_queue_entry_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_entry",
  )
  let camera_indirect_enabled = @pbr_render.render3d_camera_indirect_enabled(
    gpu_instance_buffer_builder_enabled,
    gpu_culling_supported,
    camera.no_indirect_drawing,
  )
  let draw_queue_entry = render3d_make_fallback_gpu_preprocess_queue_entry(
    render3d_queue_mesh_phase_items(
      meshes,
      camera.layers,
      camera.transform,
      camera_frustum_planes,
      phase_state_ref.val.mesh_preprocess_static_cache,
      camera_indirect_enabled,
    ),
    meshes,
    phase_state_ref.val.mesh_preprocess_static_cache,
    camera_indirect_enabled,
    camera_indirect_enabled && camera.gpu_occlusion_culling_enabled,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_entry",
    trace_camera_queue_entry_start_us,
  )
  let draw_items = draw_queue_entry.draw_items
  let trace_camera_queue_indices_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_indices",
  )
  let opaque_alpha_draw_item_indices = render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
    draw_items,
    draw_queue_entry.phase_ranges,
    draw_queue_entry.work_item_buffers,
  )
  let (
    indexed_indirect_parameter_indices,
    non_indexed_indirect_parameter_indices,
  ) = render3d_gpu_preprocess_indirect_parameter_index_maps(
    draw_items,
    draw_queue_entry.work_item_buffers,
  )
  let needs_gpu_preprocess = match draw_queue_entry.work_item_buffers {
    Indirect(_, _, _) => true
    _ => false
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_indices",
    trace_camera_queue_indices_start_us,
  )
  if needs_gpu_preprocess {
    let trace_camera_queue_upload_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_upload",
    )
    @render.host_gpu_upload_mesh3d_preprocess_camera_payload(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      payload=render3d_host_preprocess_camera_payload(
        draw_queue_entry, camera, camera_pass_projection, viewport_x, viewport_y,
        viewport_width, viewport_height, camera_exposure_value,
      ),
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_upload",
      trace_camera_queue_upload_start_us,
    )
    let trace_camera_queue_preprocess_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_preprocess",
    )
    if camera.gpu_occlusion_culling_enabled {
      let trace_camera_preprocess_dispatch_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_preprocess_dispatch",
      )
      @render.host_gpu_preprocess_mesh3d(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
        phase_kind=@render.MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION,
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_preprocess_dispatch",
        trace_camera_preprocess_dispatch_start_us,
      )
      let trace_camera_build_indirect_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_build_indirect",
      )
      @render.host_gpu_build_mesh3d_indirect_parameters(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
        phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_EARLY,
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_build_indirect",
        trace_camera_build_indirect_start_us,
      )
    } else {
      let trace_camera_preprocess_dispatch_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_preprocess_dispatch",
      )
      @render.host_gpu_preprocess_mesh3d(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_preprocess_dispatch",
        trace_camera_preprocess_dispatch_start_us,
      )
      let trace_camera_build_indirect_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_build_indirect",
      )
      @render.host_gpu_build_mesh3d_indirect_parameters(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_build_indirect",
        trace_camera_build_indirect_start_us,
      )
    }
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_preprocess",
      trace_camera_queue_preprocess_start_us,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_queue_build",
    trace_camera_queue_build_start_us,
  )
  Render3dExecuteCameraQueueBuildResult::{
    draw_queue_entry,
    opaque_alpha_draw_item_indices,
    indexed_indirect_parameter_indices,
    non_indexed_indirect_parameter_indices,
  }
}
