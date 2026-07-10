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
    None => Exposure::Exposure().exposure()
  }
}

///|
fn render3d_build_camera_queue_entry(
  view_entity : @core.Entity,
  camera : Camera3dViewPayload,
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  maybe_mesh_culling_data_buffer : MeshCullingDataBuffer?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
  retained_phase_items? : Array[MeshPhaseItem3d]? = None,
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
  let phase_items = match retained_phase_items {
    Some(items) => items
    None =>
      render3d_queue_mesh_phase_items(
        meshes,
        render_mesh_instances,
        render_mesh_assets,
        maybe_batched_instance_buffers,
        mesh_allocator,
        render_material_instances,
        render_material_bindings,
        material_slots,
        pending_mesh_material_queues,
        camera.transform,
        camera_indirect_enabled,
        retained_view_entity=@render_view.RetainedViewEntity::new(view_entity),
        specialized_material_pipeline_cache~,
        visible_mesh_entities~,
      )
  }
  let draw_queue_entry = render3d_build_gpu_preprocess_queue_entry(
    phase_items,
    maybe_batched_instance_buffers,
    maybe_mesh_culling_data_buffer,
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
    draw_queue_entry.indirect_metadata,
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
fn render3d_resolve_prepass_phase_draw_items(
  phase_items : Array[MeshPhaseItem3d],
  main_draw_items : Array[MeshPhaseItem3d],
  opaque_alpha_draw_item_indices : Array[Int],
) -> Array[Render3dPrepassPhaseDrawItem3d] {
  let main_draw_item_indices : Map[UInt64, Int] = Map([])
  for draw_item_index in opaque_alpha_draw_item_indices {
    let draw_item = main_draw_items[draw_item_index]
    main_draw_item_indices.set(
      draw_item.entity.main_entity.to_bits(),
      draw_item_index,
    )
  }
  let resolved : Array[Render3dPrepassPhaseDrawItem3d] = []
  for phase_item in phase_items {
    guard main_draw_item_indices.get(phase_item.entity.main_entity.to_bits())
      is Some(preprocess_draw_item_index) else {
      abort(
        "Retained prepass phase entity is missing its main-pass GPU preprocess output",
      )
    }
    resolved.push(Render3dPrepassPhaseDrawItem3d::{
      phase_item,
      preprocess_draw_item_index,
    })
  }
  resolved
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
  extracted_camera : ExtractedCamera3d,
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  maybe_mesh_culling_data_buffer : MeshCullingDataBuffer?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
  retained_phase_items? : Array[MeshPhaseItem3d]? = None,
  prepass_phase_items? : Array[MeshPhaseItem3d] = [],
  deferred_prepass_phase_items? : Array[MeshPhaseItem3d] = [],
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
  let queue_build_result = render3d_build_camera_queue_entry(
    extracted_camera.entity.main_entity,
    camera,
    meshes,
    render_mesh_instances,
    render_mesh_assets,
    maybe_batched_instance_buffers,
    maybe_mesh_culling_data_buffer,
    mesh_allocator,
    render_material_instances,
    render_material_bindings,
    material_slots,
    pending_mesh_material_queues,
    gpu_instance_buffer_builder_enabled,
    gpu_culling_supported,
    specialized_material_pipeline_cache~,
    visible_mesh_entities~,
    retained_phase_items~,
  )
  let prepass_draw_items = render3d_resolve_prepass_phase_draw_items(
    prepass_phase_items,
    queue_build_result.draw_queue_entry.draw_items,
    queue_build_result.opaque_alpha_draw_item_indices,
  )
  let deferred_prepass_draw_items = render3d_resolve_prepass_phase_draw_items(
    deferred_prepass_phase_items,
    queue_build_result.draw_queue_entry.draw_items,
    queue_build_result.opaque_alpha_draw_item_indices,
  )
  Some(Render3dPreparedCameraQueue::{
    draw_queue_entry: queue_build_result.draw_queue_entry,
    prepass_draw_items,
    deferred_prepass_draw_items,
    indexed_indirect_parameter_indices: queue_build_result.indexed_indirect_parameter_indices,
    non_indexed_indirect_parameter_indices: queue_build_result.non_indexed_indirect_parameter_indices,
    camera_pass_projection,
    viewport_state,
    camera_exposure_value: render3d_camera_exposure_value_for_preprocess(camera),
  })
}

///|
fn render3d_prepare_camera_queue_entries(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  maybe_mesh_culling_data_buffer : MeshCullingDataBuffer?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  dirty_specializations : @render_visibility.DirtySpecializations,
  gpu_instance_buffer_builder_enabled : Bool,
  gpu_culling_supported : Bool,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entity_classes? : Array[
    @render_visibility.RenderVisibleEntitiesClass?,
  ]? = None,
) -> Array[Render3dPreparedCameraQueue?] {
  let prepared : Array[Render3dPreparedCameraQueue?] = []
  for camera_index in 0..<cameras.length() {
    let camera = cameras[camera_index]
    let visible_mesh_entities = match visible_mesh_entity_classes {
      Some(filters) =>
        if camera_index < filters.length() {
          filters[camera_index]
        } else {
          None
        }
      None => None
    }
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    let (dequeued, queue_candidates) = match visible_mesh_entities {
      Some(visible) => {
        let view_pending_queues = match
          pending_mesh_material_queues.queues().get(retained_view_entity) {
          Some(queues) => queues
          None =>
            abort(
              "View pending mesh material queues should have been created in pbr material specialization",
            )
        }
        (
          dirty_specializations.iter_to_dequeue(retained_view_entity, visible),
          dirty_specializations.iter_to_queue(
            retained_view_entity,
            visible,
            view_pending_queues.prev_frame(),
          ),
        )
      }
      None => ([], [])
    }
    queue_candidates.sort_by(render3d_visible_pair_compare)
    let candidate_entities = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
    candidate_entities.update_cpu_culled_entities(queue_candidates)
    let camera_indirect_enabled = @pbr_render.render3d_camera_indirect_enabled(
      gpu_instance_buffer_builder_enabled,
      gpu_culling_supported,
      camera.payload.no_indirect_drawing,
    )
    let queued_items = render3d_queue_mesh_phase_items(
      meshes,
      render_mesh_instances,
      render_mesh_assets,
      maybe_batched_instance_buffers,
      mesh_allocator,
      render_material_instances,
      render_material_bindings,
      material_slots,
      pending_mesh_material_queues,
      camera.payload.transform,
      camera_indirect_enabled,
      retained_view_entity~,
      specialized_material_pipeline_cache~,
      visible_mesh_entities=Some(candidate_entities),
    )
    let retained_phase_items = render3d_apply_main_view_phase_queue(
      world,
      camera.entity.main_entity,
      meshes,
      dequeued,
      queued_items,
    )
    let (prepass_phase_items, deferred_prepass_phase_items) = render3d_retained_prepass_phase_items(
      world, retained_view_entity,
    )
    prepared.push(
      render3d_prepare_camera_queue_entry(
        camera,
        meshes,
        render_mesh_instances,
        render_mesh_assets,
        maybe_batched_instance_buffers,
        maybe_mesh_culling_data_buffer,
        mesh_allocator,
        render_material_instances,
        render_material_bindings,
        material_slots,
        pending_mesh_material_queues,
        gpu_instance_buffer_builder_enabled,
        gpu_culling_supported,
        specialized_material_pipeline_cache~,
        retained_phase_items=Some(retained_phase_items),
        prepass_phase_items~,
        deferred_prepass_phase_items~,
      ),
    )
  }
  prepared
}
