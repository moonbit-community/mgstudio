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
fn render3d_camera_queue_needs_gpu_preprocess(
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
) -> Bool {
  match draw_queue_entry.work_item_buffers {
    Indirect(_, _, _) => true
    _ => false
  }
}

///|
fn render3d_camera_exposure_value_for_preprocess(
  camera : Camera3dViewPayload,
) -> Float {
  match camera.exposure {
    Some(value) => value.exposure()
    None => Exposure::default().exposure()
  }
}

///|
fn render3d_build_camera_queue_entry(
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  camera : Camera3dViewPayload,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  meshes : Array[ExtractedMesh3d],
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
) -> Render3dExecuteCameraQueueBuildResult {
  let trace_camera_queue_build_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_build",
  )
  let trace_camera_queue_entry_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_entry",
  )
  let camera_indirect_enabled = @pbr_render.render3d_camera_indirect_enabled(
    gpu_instance_buffer_builder_enabled,
    gpu_culling_supported,
    camera.no_indirect_drawing,
  )
  let draw_queue_entry = render3d_build_gpu_preprocess_queue_entry(
    render3d_queue_mesh_phase_items(
      meshes,
      camera.layers,
      camera.transform,
      camera_frustum_planes,
      mesh_runtime_state_ref.val.mesh_preprocess_static_cache,
      camera.has_no_cpu_culling,
      camera_indirect_enabled,
    ),
    meshes,
    mesh_runtime_state_ref.val.mesh_preprocess_static_cache,
    camera_indirect_enabled,
    camera_indirect_enabled && camera.gpu_occlusion_culling_enabled,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_entry",
    trace_camera_queue_entry_start_us,
  )
  let draw_items = draw_queue_entry.draw_items
  let trace_camera_queue_indices_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_indices",
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
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_indices",
    trace_camera_queue_indices_start_us,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_build",
    trace_camera_queue_build_start_us,
  )
  Render3dExecuteCameraQueueBuildResult::{
    draw_queue_entry,
    opaque_alpha_draw_item_indices,
    indexed_indirect_parameter_indices,
    non_indexed_indirect_parameter_indices,
  }
}

///|
fn render3d_upload_camera_queue_entry(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  prepared_queue : Render3dPreparedCameraQueue,
) -> Unit {
  if !render3d_camera_queue_needs_gpu_preprocess(
      prepared_queue.draw_queue_entry,
    ) {
    return
  }
  let trace_camera_queue_upload_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_upload",
  )
  @render.host_gpu_upload_mesh3d_preprocess_camera_payload(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    payload=render3d_host_preprocess_camera_payload(
      prepared_queue.draw_queue_entry,
      camera,
      prepared_queue.camera_pass_projection,
      prepared_queue.viewport_state.viewport_x,
      prepared_queue.viewport_state.viewport_y,
      prepared_queue.viewport_state.viewport_width,
      prepared_queue.viewport_state.viewport_height,
      prepared_queue.camera_exposure_value,
    ),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_camera_queue_upload",
    trace_camera_queue_upload_start_us,
  )
}

///|
fn render3d_dispatch_camera_preprocess_early(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  prepared_queue : Render3dPreparedCameraQueue,
) -> Unit {
  if !render3d_camera_queue_needs_gpu_preprocess(
      prepared_queue.draw_queue_entry,
    ) {
    return
  }
  let trace_camera_queue_preprocess_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_early",
  )
  if camera.gpu_occlusion_culling_enabled {
    @render.host_gpu_preprocess_mesh3d(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      phase_kind=@render.MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION,
    )
    @render.host_gpu_build_mesh3d_indirect_parameters(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_EARLY,
    )
  } else {
    @render.host_gpu_preprocess_mesh3d(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
    )
    @render.host_gpu_build_mesh3d_indirect_parameters(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_early",
    trace_camera_queue_preprocess_start_us,
  )
}

///|
fn render3d_dispatch_camera_preprocess_late(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  prepared_queue : Render3dPreparedCameraQueue,
) -> Unit {
  if !render3d_camera_queue_needs_gpu_preprocess(
      prepared_queue.draw_queue_entry,
    ) ||
    !camera.gpu_occlusion_culling_enabled {
    return
  }
  let trace_camera_queue_preprocess_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_late",
  )
  @render.host_gpu_downsample_mesh3d_depth_pyramid(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
  )
  @render.host_gpu_preprocess_mesh3d(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    phase_kind=@render.MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION,
  )
  @render.host_gpu_build_mesh3d_indirect_parameters(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_LATE,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_late",
    trace_camera_queue_preprocess_start_us,
  )
}

///|
fn render3d_dispatch_camera_preprocess_main(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  prepared_queue : Render3dPreparedCameraQueue,
) -> Unit {
  if !render3d_camera_queue_needs_gpu_preprocess(
      prepared_queue.draw_queue_entry,
    ) ||
    !camera.gpu_occlusion_culling_enabled {
    return
  }
  let trace_camera_queue_preprocess_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_main",
  )
  @render.host_gpu_build_mesh3d_indirect_parameters(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_OCCLUSION_MAIN,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_preprocess_main",
    trace_camera_queue_preprocess_start_us,
  )
}

///|
fn render3d_prepare_camera_queue_entry(
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  extracted_camera : ExtractedCamera3d,
  meshes : Array[ExtractedMesh3d],
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
) -> Render3dPreparedCameraQueue? {
  let camera = extracted_camera.payload
  guard render3d_execute_camera_viewport_state(camera) is Some(viewport_state) else {
    return None
  }
  let camera_pass_projection = render3d_camera_pass_projection(
    camera.projection,
    camera.sub_camera_view,
    camera.temporal_jitter,
    viewport_state.view_width,
    viewport_state.view_height,
  )
  let camera_frustum_planes = render3d_host_preprocess_view_frustum_planes(
    camera.projection,
    camera.transform,
  )
  let queue_build_result = render3d_build_camera_queue_entry(
    mesh_runtime_state_ref, camera, camera_frustum_planes, meshes, gpu_instance_buffer_builder_enabled,
    gpu_culling_supported,
  )
  Some(Render3dPreparedCameraQueue::{
    draw_queue_entry: queue_build_result.draw_queue_entry,
    opaque_alpha_draw_item_indices: queue_build_result.opaque_alpha_draw_item_indices,
    indexed_indirect_parameter_indices: queue_build_result.indexed_indirect_parameter_indices,
    non_indexed_indirect_parameter_indices: queue_build_result.non_indexed_indirect_parameter_indices,
    camera_pass_projection,
    viewport_state,
    camera_exposure_value: render3d_camera_exposure_value_for_preprocess(camera),
  })
}

///|
fn render3d_prepare_camera_queue_entries(
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
) -> Array[Render3dPreparedCameraQueue?] {
  let prepared : Array[Render3dPreparedCameraQueue?] = []
  for camera in cameras {
    prepared.push(
      render3d_prepare_camera_queue_entry(
        mesh_runtime_state_ref, camera, meshes, gpu_instance_buffer_builder_enabled,
        gpu_culling_supported,
      ),
    )
  }
  prepared
}
