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
fn render3d_absf(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn render3d_mesh_frustum_visible(
  payload : Mesh3dExtractedPayload,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
) -> Bool {
  guard payload.aabb is Some(aabb) else { return true }
  let center_world = payload.world_from_local.transform_point3(aabb.center())
  let matrix3 = payload.world_from_local.matrix3
  let half_size = aabb.half_size()
  for plane in camera_frustum_planes {
    let signed_distance = plane.normal_x * center_world.x +
      plane.normal_y * center_world.y +
      plane.normal_z * center_world.z +
      plane.distance
    // Bevy `mesh_preprocess.wgsl::view_frustum_intersects_obb` computes an
    // OBB radius by projecting each world-space model axis onto the plane.
    let relative_radius = render3d_absf(
        plane.normal_x * matrix3.x_axis.x +
        plane.normal_y * matrix3.x_axis.y +
        plane.normal_z * matrix3.x_axis.z,
      ) *
      half_size.x +
      render3d_absf(
        plane.normal_x * matrix3.y_axis.x +
        plane.normal_y * matrix3.y_axis.y +
        plane.normal_z * matrix3.y_axis.z,
      ) *
      half_size.y +
      render3d_absf(
        plane.normal_x * matrix3.z_axis.x +
        plane.normal_y * matrix3.z_axis.y +
        plane.normal_z * matrix3.z_axis.z,
      ) *
      half_size.z
    if signed_distance < 0.0F - relative_radius {
      return false
    }
  }
  true
}

///|
fn render3d_mesh_pipeline_id_for_view(
  visible_entity : @render.MainEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache : SpecializedMaterialPipelineCache,
) -> @material.CachedRenderPipelineId? {
  specialized_material_pipeline_cache.pipeline_id(
    retained_view_entity,
    visible_entity.id(),
  )
}

///|
test "render3d gpu preprocess: view cache miss does not fall back to extracted pipeline id" {
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(61, 0))
  let entity = @core.Entity::new(62, 0)
  let visible_entity = @render.MainEntity::new(entity)
  let cached_pipeline = @material.CachedRenderPipelineId::new(92UL)
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()

  debug_inspect(
    render3d_mesh_pipeline_id_for_view(visible_entity, view, cache).map(fn(
      value,
    ) {
      value.id()
    }),
    content="None",
  )

  cache.insert(view, entity, 1, cached_pipeline)
  debug_inspect(
    render3d_mesh_pipeline_id_for_view(visible_entity, view, cache).map(fn(
      value,
    ) {
      value.id()
    }),
    content="Some(92)",
  )
}

///|
fn render3d_traced_mesh_pipeline_id_for_view(
  visible_entity : @render.MainEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache : SpecializedMaterialPipelineCache,
) -> @material.CachedRenderPipelineId? {
  let trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_pipeline_lookup",
  )
  let pipeline_id = render3d_mesh_pipeline_id_for_view(
    visible_entity, retained_view_entity, specialized_material_pipeline_cache,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_pipeline_lookup",
    trace_start_us,
  )
  pipeline_id
}

///|
priv struct QueuedMaterialMesh3d {
  phase : Int
  draw_function : @material.DrawFunctionId
  pipeline_id : @material.CachedRenderPipelineId
  distance : Float
  mesh_asset_id : Int
  current_uniform_index : UInt
  slabs : @render_mesh.MeshSlabs
  material_bind_group_index : Int
  material_bind_group_slot : Int
}

///|
fn render3d_queue_material_mesh_candidate(
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  camera_transform : @transform.Transform,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
) -> QueuedMaterialMesh3d? {
  guard render3d_traced_mesh_pipeline_id_for_view(
      visible_entity, retained_view_entity, specialized_material_pipeline_cache,
    )
    is Some(pipeline_id) else {
    return None
  }
  guard render3d_queue_material_instance_for_mesh(
      render_material_instances, pending_mesh_material_queues, retained_view_entity,
      render_entity, visible_entity,
    )
    is Some(material_instance) else {
    return None
  }
  guard render3d_queue_mesh_instance_for_mesh(
      render_mesh_instances, pending_mesh_material_queues, retained_view_entity,
      render_entity, visible_entity,
    )
    is Some(mesh_instance) else {
    return None
  }
  guard render3d_queue_resolved_material_for_mesh(
      material_slots, pending_mesh_material_queues, retained_view_entity, render_entity,
      visible_entity,
    )
    is Some(material) else {
    return None
  }
  guard render3d_queue_material_binding_for_instance(
      render_material_bindings, pending_mesh_material_queues, retained_view_entity,
      render_entity, visible_entity, material_instance,
    )
    is Some(material_binding) else {
    return None
  }
  guard render3d_queue_mesh_slabs_for_instance(mesh_allocator, mesh_instance)
    is Some(mesh_slabs) else {
    return None
  }
  let material_properties = material.material_properties()
  let phase = render3d_mesh_phase_kind(material_properties)
  guard render3d_main_pass_draw_function(material_properties)
    is Some(draw_function) else {
    return None
  }
  Some(QueuedMaterialMesh3d::{
    phase,
    draw_function,
    pipeline_id,
    distance: render3d_material_phase_distance(
      visible_entity, mesh_instance, render_mesh_instances, render_mesh_assets, maybe_batched_instance_buffers,
      material_properties, camera_transform,
    ),
    mesh_asset_id: mesh_instance.mesh_asset_id(),
    current_uniform_index: mesh_instance.current_uniform_index(),
    slabs: mesh_slabs,
    material_bind_group_index: material_binding.group().to_int(),
    material_bind_group_slot: material_binding.slot().to_int(),
  })
}

///|
fn render3d_queue_mesh_candidate_indices(
  meshes : Array[ExtractedMesh3d],
  visible_mesh_entities : @render_visibility.RenderVisibleEntitiesClass?,
) -> Array[Int] {
  match visible_mesh_entities {
    None => Array::makei(meshes.length(), fn(index) { index })
    Some(visible) => {
      let extracted_index_by_main_entity : Map[UInt64, Int] = Map([])
      for index in 0..<meshes.length() {
        extracted_index_by_main_entity.set(
          meshes[index].entity.main_entity.to_bits(),
          index,
        )
      }
      let indices : Array[Int] = []
      for pair in visible.iter_visible() {
        guard extracted_index_by_main_entity.get(pair.1.id().to_bits())
          is Some(index) else {
          continue
        }
        if meshes[index].entity.render_entity == pair.0 {
          indices.push(index)
        }
      }
      indices
    }
  }
}

///|
fn render3d_queue_mesh_phase_items_cpu_builder(
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  camera_transform : @transform.Transform,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
) -> Array[MeshPhaseItem3d] {
  let items : Array[MeshPhaseItem3d] = []
  for i in render3d_queue_mesh_candidate_indices(meshes, visible_mesh_entities) {
    let mesh = meshes[i]
    guard render3d_queue_material_mesh_candidate(
        mesh.entity.render_entity,
        @render.MainEntity::new(mesh.entity.main_entity),
        render_mesh_instances,
        render_mesh_assets,
        maybe_batched_instance_buffers,
        mesh_allocator,
        render_material_instances,
        render_material_bindings,
        material_slots,
        pending_mesh_material_queues,
        camera_transform,
        retained_view_entity~,
        specialized_material_pipeline_cache~,
      )
      is Some(candidate) else {
      continue
    }
    items.push(MeshPhaseItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      current_uniform_index: candidate.current_uniform_index,
      phase: candidate.phase,
      draw_function: candidate.draw_function,
      pipeline_id: candidate.pipeline_id,
      distance: candidate.distance,
      mesh_asset_id: candidate.mesh_asset_id,
      slabs: candidate.slabs,
      material_bind_group_index: candidate.material_bind_group_index,
      material_bind_group_slot: candidate.material_bind_group_slot,
    })
  }
  render3d_sort_mesh_phase_items(items)
}

///|
priv struct GpuPreprocessWorkItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  current_uniform_index : UInt
  phase : Int
  draw_function : @material.DrawFunctionId
  pipeline_id : @material.CachedRenderPipelineId
  distance : Float
  mesh_asset_id : Int
  slabs : @render_mesh.MeshSlabs
  material_bind_group_index : Int
  material_bind_group_slot : Int
}

///|
fn render3d_collect_meshes_for_gpu_building(
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  camera_transform : @transform.Transform,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
) -> Array[GpuPreprocessWorkItem3d] {
  let work_items : Array[GpuPreprocessWorkItem3d] = []
  for i in render3d_queue_mesh_candidate_indices(meshes, visible_mesh_entities) {
    let mesh = meshes[i]
    guard render3d_queue_material_mesh_candidate(
        mesh.entity.render_entity,
        @render.MainEntity::new(mesh.entity.main_entity),
        render_mesh_instances,
        render_mesh_assets,
        maybe_batched_instance_buffers,
        mesh_allocator,
        render_material_instances,
        render_material_bindings,
        material_slots,
        pending_mesh_material_queues,
        camera_transform,
        retained_view_entity~,
        specialized_material_pipeline_cache~,
      )
      is Some(candidate) else {
      continue
    }
    work_items.push(GpuPreprocessWorkItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      current_uniform_index: candidate.current_uniform_index,
      phase: candidate.phase,
      draw_function: candidate.draw_function,
      pipeline_id: candidate.pipeline_id,
      distance: candidate.distance,
      mesh_asset_id: candidate.mesh_asset_id,
      slabs: candidate.slabs,
      material_bind_group_index: candidate.material_bind_group_index,
      material_bind_group_slot: candidate.material_bind_group_slot,
    })
  }
  work_items
}

///|
fn render3d_sort_gpu_preprocess_work_items(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[GpuPreprocessWorkItem3d] {
  let opaque_items : Array[GpuPreprocessWorkItem3d] = []
  let alpha_mask_items : Array[GpuPreprocessWorkItem3d] = []
  let transmissive_items : Array[GpuPreprocessWorkItem3d] = []
  let transparent_items : Array[GpuPreprocessWorkItem3d] = []
  for work_item in work_items {
    if work_item.phase == RENDER3D_PHASE_OPAQUE {
      opaque_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_ALPHA_MASK {
      alpha_mask_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_TRANSMISSIVE {
      transmissive_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_items.push(work_item)
    }
  }
  let sort_back_to_front = fn(
    a : GpuPreprocessWorkItem3d,
    b : GpuPreprocessWorkItem3d,
  ) -> Int {
    let depth_cmp = @pbr_render.cmp_float(b.distance, a.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  }
  transmissive_items.sort_by(sort_back_to_front)
  transparent_items.sort_by(sort_back_to_front)
  let sorted : Array[GpuPreprocessWorkItem3d] = []
  for item in opaque_items {
    sorted.push(item)
  }
  for item in alpha_mask_items {
    sorted.push(item)
  }
  for item in transmissive_items {
    sorted.push(item)
  }
  for item in transparent_items {
    sorted.push(item)
  }
  sorted
}

///|
fn render3d_write_batched_instance_buffers(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[MeshPhaseItem3d] {
  let phase_items : Array[MeshPhaseItem3d] = []
  for work_item in render3d_sort_gpu_preprocess_work_items(work_items) {
    phase_items.push(MeshPhaseItem3d::{
      entity: work_item.entity,
      extracted_index: work_item.extracted_index,
      current_uniform_index: work_item.current_uniform_index,
      phase: work_item.phase,
      draw_function: work_item.draw_function,
      pipeline_id: work_item.pipeline_id,
      distance: work_item.distance,
      mesh_asset_id: work_item.mesh_asset_id,
      slabs: work_item.slabs,
      material_bind_group_index: work_item.material_bind_group_index,
      material_bind_group_slot: work_item.material_bind_group_slot,
    })
  }
  phase_items
}

///|
fn render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
) -> Array[GpuPreprocessPhaseRange3d] {
  let phase_ranges : Array[GpuPreprocessPhaseRange3d] = []
  if draw_items.length() == 0 {
    return phase_ranges
  }
  let mut current_phase = draw_items[0].phase
  let mut range_start = 0
  for i in 1..<draw_items.length() {
    if draw_items[i].phase == current_phase {
      continue
    }
    phase_ranges.push(GpuPreprocessPhaseRange3d::{
      phase: current_phase,
      start: range_start,
      end: i,
    })
    current_phase = draw_items[i].phase
    range_start = i
  }
  phase_ranges.push(GpuPreprocessPhaseRange3d::{
    phase: current_phase,
    start: range_start,
    end: draw_items.length(),
  })
  phase_ranges
}

///|
fn render3d_gpu_preprocess_shader_work_item_from_batching(
  item : @render_batching.PreprocessWorkItem,
) -> GpuPreprocessShaderWorkItem3d {
  GpuPreprocessShaderWorkItem3d::{
    input_index: item.input_index(),
    output_or_indirect_parameters_index: item.output_or_indirect_parameters_index(),
  }
}

///|
pub fn render3d_build_gpu_preprocess_work_item_buffers_from_phase(
  work_item_buffers : @render_batching.PreprocessWorkItemBuffers,
) -> GpuPreprocessWorkItemBuffers3d {
  if work_item_buffers.is_direct() {
    let direct_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
    for item in work_item_buffers.direct_items() {
      direct_work_items.push(
        render3d_gpu_preprocess_shader_work_item_from_batching(item),
      )
    }
    return GpuPreprocessWorkItemBuffers3d::Direct(direct_work_items)
  }
  let indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  for item in work_item_buffers.indexed_items() {
    indexed_work_items.push(
      render3d_gpu_preprocess_shader_work_item_from_batching(item),
    )
  }
  let non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  for item in work_item_buffers.non_indexed_items() {
    non_indexed_work_items.push(
      render3d_gpu_preprocess_shader_work_item_from_batching(item),
    )
  }
  let late_indexed_items = work_item_buffers.late_indexed_items()
  let late_non_indexed_items = work_item_buffers.late_non_indexed_items()
  GpuPreprocessWorkItemBuffers3d::Indirect(
    indexed_work_items,
    non_indexed_work_items,
    render3d_build_gpu_occlusion_culling_work_item_buffers(
      indexed_work_items,
      non_indexed_work_items,
      late_indexed_items.length() > 0 || late_non_indexed_items.length() > 0,
    ),
  )
}

///|
fn render3d_build_gpu_preprocess_indirect_mesh_class_metadata_from_phase(
  phase_indirect_parameters_buffers : @render_batching.UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
) -> GpuPreprocessIndirectMeshClassMetadata3d {
  let indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ] = []
  for index in 0..<phase_indirect_parameters_buffers.cpu_metadata_len(indexed) {
    match phase_indirect_parameters_buffers.cpu_metadata_at(indexed, index) {
      Some(metadata) =>
        indirect_parameters_cpu_metadata.push(GpuPreprocessIndirectParametersCpuMetadata3d::{
          base_output_index: metadata.base_output_index(),
          batch_set_index: metadata.batch_set_index(),
        })
      None => ()
    }
  }
  let indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ] = []
  for _ in 0..<phase_indirect_parameters_buffers.gpu_metadata_len(indexed) {
    indirect_parameters_gpu_metadata.push(GpuPreprocessIndirectParametersGpuMetadata3d::{
      mesh_index: 0,
      early_instance_count: 0,
      late_instance_count: 0,
    })
  }
  let indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d] = []
  for index in 0..<phase_indirect_parameters_buffers.batch_set_count(indexed) {
    match phase_indirect_parameters_buffers.batch_set_at(indexed, index) {
      Some(batch_set) =>
        indirect_batch_sets.push(GpuPreprocessIndirectBatchSet3d::{
          indirect_parameters_count: batch_set.indirect_parameters_count(),
          indirect_parameters_base: batch_set.indirect_parameters_base(),
        })
      None => ()
    }
  }
  GpuPreprocessIndirectMeshClassMetadata3d::{
    indirect_parameters_cpu_metadata,
    indirect_parameters_gpu_metadata,
    indirect_batch_sets,
  }
}

///|
pub fn render3d_build_gpu_preprocess_indirect_metadata_from_phase(
  phase_indirect_parameters_buffers : @render_batching.UntypedPhaseIndirectParametersBuffers,
) -> GpuPreprocessIndirectMetadata3d {
  GpuPreprocessIndirectMetadata3d::{
    indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata_from_phase(
      phase_indirect_parameters_buffers, true,
    ),
    non_indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata_from_phase(
      phase_indirect_parameters_buffers, false,
    ),
  }
}

///|
fn render3d_gpu_preprocess_workgroup_count(item_count : Int) -> Int {
  if item_count <= 0 {
    return 0
  }
  let quotient = item_count / RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE
  if item_count % RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE == 0 {
    quotient
  } else {
    quotient + 1
  }
}

///|
fn render3d_build_gpu_preprocess_dispatch_metadata(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> GpuPreprocessDispatchMetadata3d {
  match work_item_buffers {
    Direct(items) =>
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          items.length(),
        ),
        indexed_workgroup_count: 0,
        non_indexed_workgroup_count: 0,
        late_indexed_workgroup_count: 0,
        late_non_indexed_workgroup_count: 0,
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      let late_indexed_item_count = match gpu_occlusion_culling {
        Some(_culling_buffers) => indexed_items.length()
        None => 0
      }
      let late_non_indexed_item_count = match gpu_occlusion_culling {
        Some(_culling_buffers) => non_indexed_items.length()
        None => 0
      }
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: 0,
        indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          indexed_items.length(),
        ),
        non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          non_indexed_items.length(),
        ),
        late_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_indexed_item_count,
        ),
        late_non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_non_indexed_item_count,
        ),
      }
    }
  }
}

///|
fn render3d_build_gpu_occlusion_culling_work_item_buffers(
  indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  enabled : Bool,
) -> GpuOcclusionCullingWorkItemBuffers3d? {
  if !enabled {
    return None
  }
  ignore(indexed_work_items)
  ignore(non_indexed_work_items)
  Some(GpuOcclusionCullingWorkItemBuffers3d::{ enabled: true })
}

///|
fn render3d_mesh_preprocess_indirect_eligible(
  draw_item : MeshPhaseItem3d,
) -> Bool {
  draw_item.mesh_asset_id > 0
}

///|
priv struct Render3dGpuPreprocessPhaseBuffers {
  work_item_buffers : @render_batching.PreprocessWorkItemBuffers
  indirect_parameters_buffers : @render_batching.UntypedPhaseIndirectParametersBuffers
}

///|
fn render3d_build_gpu_preprocess_phase_buffers_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> Render3dGpuPreprocessPhaseBuffers {
  let indirect_parameters_buffers = @render_batching.UntypedPhaseIndirectParametersBuffers::new(
    false,
  )
  if !indirect_enabled {
    let work_item_buffers = @render_batching.preprocess_work_item_buffers_direct()
    for i in 0..<draw_items.length() {
      work_item_buffers.push(
        false,
        @render_batching.PreprocessWorkItem::new(i, i),
      )
    }
    return Render3dGpuPreprocessPhaseBuffers::{
      work_item_buffers,
      indirect_parameters_buffers,
    }
  }
  let work_item_buffers = @render_batching.preprocess_work_item_buffers_indirect(
    gpu_occlusion_culling_enabled,
  )
  let mut has_indexed_items = false
  let mut has_non_indexed_items = false
  for i in 0..<draw_items.length() {
    let draw_item = draw_items[i]
    if !render3d_mesh_preprocess_indirect_eligible(draw_item) {
      continue
    }
    let indexed = draw_item.slabs.index_slab_id() is Some(_)
    let indirect_parameters_index = indirect_parameters_buffers.allocate(
      indexed, 1,
    )
    indirect_parameters_buffers.set_cpu_metadata(
      indexed,
      indirect_parameters_index,
      @render_batching.IndirectParametersCpuMetadata::new(i, -1),
    )
    work_item_buffers.push(
      indexed,
      @render_batching.PreprocessWorkItem::new(
        draw_item.current_uniform_index.reinterpret_as_int(),
        indirect_parameters_index,
      ),
    )
    if indexed {
      has_indexed_items = true
    } else {
      has_non_indexed_items = true
    }
  }
  if has_indexed_items {
    indirect_parameters_buffers.add_batch_set(true, 0)
  }
  if has_non_indexed_items {
    indirect_parameters_buffers.add_batch_set(false, 0)
  }
  Render3dGpuPreprocessPhaseBuffers::{
    work_item_buffers,
    indirect_parameters_buffers,
  }
}

///|
fn render3d_build_gpu_preprocess_queue_entry(
  draw_items : Array[MeshPhaseItem3d],
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  maybe_mesh_culling_data_buffer : MeshCullingDataBuffer?,
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessResolvedCameraQueueEntry3d {
  let phase_buffers = render3d_build_gpu_preprocess_phase_buffers_from_draw_items(
    draw_items, indirect_enabled, gpu_occlusion_culling_enabled,
  )
  render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
    draw_items,
    maybe_batched_instance_buffers,
    maybe_mesh_culling_data_buffer,
    phase_buffers.work_item_buffers,
    phase_buffers.indirect_parameters_buffers,
  )
}

///|
fn render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
  draw_items : Array[MeshPhaseItem3d],
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  maybe_mesh_culling_data_buffer : MeshCullingDataBuffer?,
  work_item_buffers : @render_batching.PreprocessWorkItemBuffers,
  phase_indirect_parameters_buffers : @render_batching.UntypedPhaseIndirectParametersBuffers,
) -> GpuPreprocessResolvedCameraQueueEntry3d {
  let phase_ranges = render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
    draw_items,
  )
  let resolved_work_item_buffers = render3d_build_gpu_preprocess_work_item_buffers_from_phase(
    work_item_buffers,
  )
  let indirect_metadata = render3d_build_gpu_preprocess_indirect_metadata_from_phase(
    phase_indirect_parameters_buffers,
  )
  let dispatch_metadata = render3d_build_gpu_preprocess_dispatch_metadata(
    resolved_work_item_buffers,
  )
  let mesh_culling_data : Array[@render.HostMesh3dPreprocessMeshCullingData] = []
  let mesh_inputs : Array[@render.HostMesh3dPreprocessMeshInput] = []
  match resolved_work_item_buffers {
    Direct(_) => ()
    Indirect(_, _, _) => {
      guard maybe_batched_instance_buffers is Some(batched_instance_buffers) else {
        abort("Missing BatchedInstanceBuffers during pbr GPU preprocessing")
      }
      guard maybe_mesh_culling_data_buffer is Some(mesh_culling_data_buffer) else {
        abort("Missing MeshCullingDataBuffer during pbr GPU preprocessing")
      }
      for input_index in 0..<batched_instance_buffers.current_input_len() {
        mesh_culling_data.push(
          render3d_host_preprocess_mesh_culling_data(
            input_index.reinterpret_as_uint(),
            mesh_culling_data_buffer,
          ),
        )
        mesh_inputs.push(
          render3d_host_preprocess_mesh_input(
            input_index.reinterpret_as_uint(),
            batched_instance_buffers,
          ),
        )
      }
    }
  }
  GpuPreprocessResolvedCameraQueueEntry3d::{
    draw_items,
    phase_ranges,
    indirect_metadata,
    dispatch_metadata,
    work_item_buffers: resolved_work_item_buffers,
    mesh_culling_data,
    mesh_inputs,
  }
}

///|
fn render3d_gpu_preprocess_opaque_alpha_end_index(
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
) -> Int {
  let mut opaque_alpha_end = 0
  for phase_range in phase_ranges {
    if phase_range.start < 0 {
      continue
    }
    if phase_range.phase != RENDER3D_PHASE_OPAQUE &&
      phase_range.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    if phase_range.end > opaque_alpha_end {
      opaque_alpha_end = phase_range.end
    }
  }
  opaque_alpha_end
}

///|
fn render3d_host_preprocess_shader_work_item(
  item : GpuPreprocessShaderWorkItem3d,
) -> @render.HostMesh3dPreprocessShaderWorkItem {
  @render.HostMesh3dPreprocessShaderWorkItem::{
    input_index: item.input_index,
    output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
  }
}

///|
fn render3d_host_preprocess_cpu_metadata(
  metadata : GpuPreprocessIndirectParametersCpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersCpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersCpuMetadata::{
    base_output_index: metadata.base_output_index,
    batch_set_index: metadata.batch_set_index,
  }
}

///|
fn render3d_host_preprocess_gpu_metadata(
  metadata : GpuPreprocessIndirectParametersGpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersGpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersGpuMetadata::{
    mesh_index: metadata.mesh_index,
    early_instance_count: metadata.early_instance_count,
    late_instance_count: metadata.late_instance_count,
  }
}

///|
fn render3d_host_preprocess_batch_set(
  batch_set : GpuPreprocessIndirectBatchSet3d,
) -> @render.HostMesh3dPreprocessIndirectBatchSet {
  @render.HostMesh3dPreprocessIndirectBatchSet::{
    indirect_parameters_count: batch_set.indirect_parameters_count,
    indirect_parameters_base: batch_set.indirect_parameters_base,
  }
}

///|
fn render3d_host_preprocess_frustum_planes_from_half_spaces(
  half_spaces : Array[HalfSpace],
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  let planes : Array[@render.HostMesh3dPreprocessFrustumPlane] = []
  for half_space in half_spaces {
    let normal_d = half_space.normal_d()
    planes.push(@render.HostMesh3dPreprocessFrustumPlane::{
      normal_x: normal_d.x,
      normal_y: normal_d.y,
      normal_z: normal_d.z,
      distance: normal_d.w,
    })
  }
  planes
}

///|
fn render3d_host_preprocess_view_frustum_planes_from_clip_from_world(
  clip_from_world : @pbr_render.ProjectionMatrix3d,
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  let frustum = @pbr_render.render3d_frustum_from_view_frustum(
    @pbr_render.ViewFrustum::from_clip_from_world(clip_from_world),
  )
  render3d_host_preprocess_frustum_planes_from_half_spaces(frustum.half_spaces)
}

///|
fn render3d_host_preprocess_view_frustum_planes(
  projection : Projection,
  camera_transform : @transform.Transform,
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  render3d_host_preprocess_frustum_planes_from_half_spaces(
    projection.compute_frustum(camera_transform).half_spaces,
  )
}

///|
fn render3d_host_preprocess_view(
  projection : Projection,
  pass_projection : @pbr_render.Render3dPassProjection,
  camera_transform : @transform.Transform,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessView {
  let clip_from_world = @pbr_render.render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
  let unjittered_clip_from_world = @pbr_render.render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
  let view_from_world = @pbr_render.render3d_view_from_world_matrix(
    camera_transform,
  )
  let world_from_view = render3d_world_from_view_matrix(camera_transform)
  let world_from_clip = match
    @pbr_render.render3d_projection_matrix_inverse(clip_from_world) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let view_from_clip = match
    @pbr_render.render3d_projection_matrix_inverse(
      pass_projection.clip_from_view,
    ) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessView::{
    clip_from_world: render3d_host_gpu_clip_matrix(clip_from_world),
    unjittered_clip_from_world: render3d_host_gpu_clip_matrix(
      unjittered_clip_from_world,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(world_from_clip),
    world_from_view: render3d_host_gpu_clip_matrix(world_from_view),
    view_from_world: render3d_host_gpu_clip_matrix(view_from_world),
    clip_from_view: render3d_host_gpu_clip_matrix(
      pass_projection.clip_from_view,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(view_from_clip),
    world_position_x: camera_transform.translation.x,
    world_position_y: camera_transform.translation.y,
    world_position_z: camera_transform.translation.z,
    exposure: camera_exposure_value,
    viewport_x: Float::from_double(viewport_x.to_double()),
    viewport_y: Float::from_double(viewport_y.to_double()),
    viewport_width: Float::from_double(viewport_width.to_double()),
    viewport_height: Float::from_double(viewport_height.to_double()),
    main_pass_viewport_x: Float::from_double(viewport_x.to_double()),
    main_pass_viewport_y: Float::from_double(viewport_y.to_double()),
    main_pass_viewport_width: Float::from_double(viewport_width.to_double()),
    main_pass_viewport_height: Float::from_double(viewport_height.to_double()),
    frustum_planes: render3d_host_preprocess_view_frustum_planes(
      projection, camera_transform,
    ),
    mip_bias: 0.0F,
  }
}

///|
fn render3d_projection_matrix_identity() -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn render3d_host_preprocess_previous_view(
  pass_projection : @pbr_render.Render3dPassProjection,
  previous_transform : @transform.Transform,
  previous_clip_from_world : ProjectionMatrix3d?,
) -> @render.HostMesh3dPreprocessPreviousView {
  let resolved_previous_view_from_world = @pbr_render.render3d_view_from_world_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_world = match previous_clip_from_world {
    Some(value) => value
    None =>
      @pbr_render.render3d_pass_projection_clip_from_world(
        pass_projection, previous_transform,
      )
  }
  let resolved_previous_world_from_clip = match
    @pbr_render.render3d_projection_matrix_inverse(
      resolved_previous_clip_from_world,
    ) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let resolved_previous_world_from_view = render3d_world_from_view_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_view = resolved_previous_clip_from_world.mul(
    resolved_previous_world_from_view,
  )
  let resolved_previous_view_from_clip = match
    @pbr_render.render3d_projection_matrix_inverse(
      resolved_previous_clip_from_view,
    ) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessPreviousView::{
    view_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_world,
    ),
    clip_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_world,
    ),
    clip_from_view: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_view,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_world_from_clip,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_clip,
    ),
  }
}

///|
fn render3d_host_preprocess_mesh_culling_data(
  input_index : UInt,
  mesh_culling_data_buffer : MeshCullingDataBuffer,
) -> @render.HostMesh3dPreprocessMeshCullingData {
  guard mesh_culling_data_buffer.get(input_index) is Some(culling_data) else {
    abort("Missing MeshCullingData for queued pbr GPU mesh instance")
  }
  let center = culling_data.aabb_center()
  let half_extents = culling_data.aabb_half_extents()
  @render.HostMesh3dPreprocessMeshCullingData::{
    aabb_center_x: center.x,
    aabb_center_y: center.y,
    aabb_center_z: center.z,
    aabb_half_extents_x: half_extents.x,
    aabb_half_extents_y: half_extents.y,
    aabb_half_extents_z: half_extents.z,
  }
}

///|
fn render3d_mesh_handle_preprocess_counts(
  mesh_handle : @asset.Handle[@mesh.Mesh],
  mesh_id : Int,
) -> (Bool, Int, Int, Int) {
  match @render.host_gpu_mesh_info(mesh_id) {
    Some(info) =>
      return (
        info.index_count() > 0,
        info.vertex_start(),
        info.index_start(),
        if info.index_count() > 0 {
          info.index_count()
        } else {
          info.vertex_count()
        },
      )
    None => ()
  }
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          let is_indexed = geometry3d.indices is Some(_)
          let first_vertex_index = 0
          let first_index_index = 0
          let index_count = match geometry3d.indices {
            Some(indices) => indices.length()
            None => geometry3d.positions.length()
          }
          (is_indexed, first_vertex_index, first_index_index, index_count)
        }
        _ => (false, 0, 0, 0)
      }
    None => (false, 0, 0, 0)
  }
}

///|
fn render3d_mesh_handle_topology_kind(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.as_3d_geometry() {
        Some(geometry) => geometry.primitive_topology().to_int()
        None => 0
      }
    None => 0
  }
}

///|
fn render3d_mesh_handle_local_aabb(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> (@math.Vec3, @math.Vec3)? {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          guard geometry3d.positions.length() > 0 else { return None }
          let mut min_x = geometry3d.positions[0].x
          let mut min_y = geometry3d.positions[0].y
          let mut min_z = geometry3d.positions[0].z
          let mut max_x = geometry3d.positions[0].x
          let mut max_y = geometry3d.positions[0].y
          let mut max_z = geometry3d.positions[0].z
          for i in 1..<geometry3d.positions.length() {
            let p = geometry3d.positions[i]
            min_x = @pbr_render.minf(min_x, p.x)
            min_y = @pbr_render.minf(min_y, p.y)
            min_z = @pbr_render.minf(min_z, p.z)
            max_x = @pbr_render.maxf(max_x, p.x)
            max_y = @pbr_render.maxf(max_y, p.y)
            max_z = @pbr_render.maxf(max_z, p.z)
          }
          Some(
            (
              @math.Vec3::new(min_x, min_y, min_z),
              @math.Vec3::new(max_x, max_y, max_z),
            ),
          )
        }
        _ => None
      }
    None => None
  }
}

///|
fn render3d_mesh_preprocess_static(
  mesh_handle : @asset.Handle[@mesh.Mesh],
  mesh_id : Int,
) -> MeshPreprocessStatic3d {
  let topology_kind = render3d_mesh_handle_topology_kind(mesh_handle)
  let (is_indexed, first_vertex_index, first_index_index, index_count) = render3d_mesh_handle_preprocess_counts(
    mesh_handle, mesh_id,
  )
  let (has_local_aabb, aabb_center, aabb_half_extents) = match
    render3d_mesh_handle_local_aabb(mesh_handle) {
    Some((min_corner, max_corner)) =>
      (
        true,
        @math.Vec3::new(
          (min_corner.x + max_corner.x) * 0.5F,
          (min_corner.y + max_corner.y) * 0.5F,
          (min_corner.z + max_corner.z) * 0.5F,
        ),
        @math.Vec3::new(
          (max_corner.x - min_corner.x) * 0.5F,
          (max_corner.y - min_corner.y) * 0.5F,
          (max_corner.z - min_corner.z) * 0.5F,
        ),
      )
    None =>
      (
        false,
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
      )
  }
  MeshPreprocessStatic3d::{
    topology_kind,
    is_indexed,
    first_vertex_index,
    first_index_index,
    index_count,
    has_local_aabb,
    aabb_center,
    aabb_half_extents,
  }
}

///|
fn render3d_update_mesh_preprocess_static_cache(
  cache : Map[Int, MeshPreprocessStatic3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  for mesh in meshes {
    let mesh_handle_id = mesh.payload.mesh_handle.id()
    if mesh_handle_id < 0 {
      continue
    }
    if cache.get(mesh_handle_id) is Some(_) {
      continue
    }
    guard mesh.payload.mesh_preprocess_static is Some(metadata) else {
      continue
    }
    cache.set(mesh_handle_id, metadata)
  }
}

///|
fn render3d_mesh_preprocess_static_cached(
  mesh_handle : @asset.Handle[@mesh.Mesh],
  mesh_id : Int,
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> MeshPreprocessStatic3d {
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return render3d_mesh_preprocess_static(mesh_handle, mesh_id)
  }
  match mesh_preprocess_static_cache.get(mesh_handle_id) {
    Some(metadata) => metadata
    None => {
      let metadata = render3d_mesh_preprocess_static(mesh_handle, mesh_id)
      mesh_preprocess_static_cache.set(mesh_handle_id, metadata)
      metadata
    }
  }
}

///|
fn render3d_host_gpu_clip_matrix(
  matrix : ProjectionMatrix3d,
) -> @render.HostGpuClipMatrix {
  @render.host_gpu_clip_matrix(
    matrix.x_axis.x,
    matrix.x_axis.y,
    matrix.x_axis.z,
    matrix.x_axis.w,
    matrix.y_axis.x,
    matrix.y_axis.y,
    matrix.y_axis.z,
    matrix.y_axis.w,
    matrix.z_axis.x,
    matrix.z_axis.y,
    matrix.z_axis.z,
    matrix.z_axis.w,
    matrix.w_axis.x,
    matrix.w_axis.y,
    matrix.w_axis.z,
    matrix.w_axis.w,
  )
}

///|
fn render3d_world_from_view_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let x_axis = @pbr_render.quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(transform.scale.x, 0.0F, 0.0F),
  )
  let y_axis = @pbr_render.quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, transform.scale.y, 0.0F),
  )
  let z_axis = @pbr_render.quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, 0.0F, transform.scale.z),
  )
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(
      transform.translation.x,
      transform.translation.y,
      transform.translation.z,
      1.0F,
    ),
  )
}

///|
fn render3d_host_preprocess_mesh_input(
  input_index : UInt,
  batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers,
) -> @render.HostMesh3dPreprocessMeshInput {
  guard batched_instance_buffers.buffers.current_input_buffer.get(
      input_index.reinterpret_as_int(),
    )
    is Some(mesh_input) else {
    abort("Missing MeshInputUniform for queued pbr GPU mesh instance")
  }
  let previous_mesh_input = if mesh_input.previous_input_index() ==
    mesh_input_uniform_invalid_index() {
    mesh_input
  } else {
    match
      batched_instance_buffers.buffers.previous_input_buffer.get(
        mesh_input.previous_input_index().reinterpret_as_int(),
      ) {
      Some(value) => value
      None =>
        abort(
          "Missing previous MeshInputUniform for queued pbr GPU mesh instance",
        )
    }
  }
  let world_from_local = mesh_input.world_from_local
  let previous_world_from_local = previous_mesh_input.world_from_local
  let (scale, rotation, translation) = world_from_local.to_scale_rotation_translation()
  let (previous_scale, previous_rotation, previous_translation) = previous_world_from_local.to_scale_rotation_translation()
  @render.HostMesh3dPreprocessMeshInput::{
    translation_x: translation.x,
    translation_y: translation.y,
    translation_z: translation.z,
    rotation_x: rotation.x,
    rotation_y: rotation.y,
    rotation_z: rotation.z,
    rotation_w: rotation.w,
    scale_x: scale.x,
    scale_y: scale.y,
    scale_z: scale.z,
    previous_translation_x: previous_translation.x,
    previous_translation_y: previous_translation.y,
    previous_translation_z: previous_translation.z,
    previous_rotation_x: previous_rotation.x,
    previous_rotation_y: previous_rotation.y,
    previous_rotation_z: previous_rotation.z,
    previous_rotation_w: previous_rotation.w,
    previous_scale_x: previous_scale.x,
    previous_scale_y: previous_scale.y,
    previous_scale_z: previous_scale.z,
    world_from_local_x_axis_x: world_from_local.matrix3.x_axis.x,
    world_from_local_x_axis_y: world_from_local.matrix3.x_axis.y,
    world_from_local_x_axis_z: world_from_local.matrix3.x_axis.z,
    world_from_local_y_axis_x: world_from_local.matrix3.y_axis.x,
    world_from_local_y_axis_y: world_from_local.matrix3.y_axis.y,
    world_from_local_y_axis_z: world_from_local.matrix3.y_axis.z,
    world_from_local_z_axis_x: world_from_local.matrix3.z_axis.x,
    world_from_local_z_axis_y: world_from_local.matrix3.z_axis.y,
    world_from_local_z_axis_z: world_from_local.matrix3.z_axis.z,
    world_from_local_translation_x: world_from_local.translation.x,
    world_from_local_translation_y: world_from_local.translation.y,
    world_from_local_translation_z: world_from_local.translation.z,
    previous_world_from_local_x_axis_x: previous_world_from_local.matrix3.x_axis.x,
    previous_world_from_local_x_axis_y: previous_world_from_local.matrix3.x_axis.y,
    previous_world_from_local_x_axis_z: previous_world_from_local.matrix3.x_axis.z,
    previous_world_from_local_y_axis_x: previous_world_from_local.matrix3.y_axis.x,
    previous_world_from_local_y_axis_y: previous_world_from_local.matrix3.y_axis.y,
    previous_world_from_local_y_axis_z: previous_world_from_local.matrix3.y_axis.z,
    previous_world_from_local_z_axis_x: previous_world_from_local.matrix3.z_axis.x,
    previous_world_from_local_z_axis_y: previous_world_from_local.matrix3.z_axis.y,
    previous_world_from_local_z_axis_z: previous_world_from_local.matrix3.z_axis.z,
    previous_world_from_local_translation_x: previous_world_from_local.translation.x,
    previous_world_from_local_translation_y: previous_world_from_local.translation.y,
    previous_world_from_local_translation_z: previous_world_from_local.translation.z,
    flags: mesh_input.flags,
    first_vertex_index: mesh_input.first_vertex_index.reinterpret_as_int(),
    first_index_index: mesh_input.first_index_index.reinterpret_as_int(),
    index_count: mesh_input.index_count.reinterpret_as_int(),
    tag: mesh_input.tag().reinterpret_as_int(),
  }
}

///|
fn render3d_host_preprocess_camera_payload(
  queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  camera : Camera3dViewPayload,
  pass_projection : @pbr_render.Render3dPassProjection,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessCameraPayload {
  let view = render3d_host_preprocess_view(
    camera.projection,
    pass_projection,
    camera.transform,
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
    camera_exposure_value,
  )
  let previous_view = render3d_host_preprocess_previous_view(
    pass_projection,
    camera.previous_transform,
    camera.previous_clip_from_world,
  )
  let mesh_culling_data = queue_entry.mesh_culling_data
  let mesh_inputs = queue_entry.mesh_inputs
  let direct_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let non_indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let late_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  let late_non_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  match queue_entry.work_item_buffers {
    Direct(items) =>
      for item in items {
        direct_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      for item in indexed_items {
        indexed_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
      for item in non_indexed_items {
        non_indexed_work_items.push(
          render3d_host_preprocess_shader_work_item(item),
        )
      }
      if gpu_occlusion_culling is Some(culling) {
        if culling.enabled {
          for item in indexed_items {
            late_indexed_work_items.push(
              render3d_host_preprocess_shader_work_item(item),
            )
          }
          for item in non_indexed_items {
            late_non_indexed_work_items.push(
              render3d_host_preprocess_shader_work_item(item),
            )
          }
        }
      }
    }
  }
  let indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata {
    indexed_cpu_metadata.push(render3d_host_preprocess_cpu_metadata(metadata))
  }
  let indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_gpu_metadata {
    indexed_gpu_metadata.push(render3d_host_preprocess_gpu_metadata(metadata))
  }
  let indexed_batch_sets : Array[@render.HostMesh3dPreprocessIndirectBatchSet] = []
  for batch_set in queue_entry.indirect_metadata.indexed.indirect_batch_sets {
    indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let non_indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_cpu_metadata {
    non_indexed_cpu_metadata.push(
      render3d_host_preprocess_cpu_metadata(metadata),
    )
  }
  let non_indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_gpu_metadata {
    non_indexed_gpu_metadata.push(
      render3d_host_preprocess_gpu_metadata(metadata),
    )
  }
  let non_indexed_batch_sets : Array[
    @render.HostMesh3dPreprocessIndirectBatchSet,
  ] = []
  for batch_set in queue_entry.indirect_metadata.non_indexed.indirect_batch_sets {
    non_indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let dispatch_metadata = @render.HostMesh3dPreprocessDispatchMetadata::{
    direct_workgroup_count: queue_entry.dispatch_metadata.direct_workgroup_count,
    indexed_workgroup_count: queue_entry.dispatch_metadata.indexed_workgroup_count,
    non_indexed_workgroup_count: queue_entry.dispatch_metadata.non_indexed_workgroup_count,
    late_indexed_workgroup_count: queue_entry.dispatch_metadata.late_indexed_workgroup_count,
    late_non_indexed_workgroup_count: queue_entry.dispatch_metadata.late_non_indexed_workgroup_count,
  }
  @render.HostMesh3dPreprocessCameraPayload::{
    view,
    previous_view,
    mesh_culling_data,
    mesh_inputs,
    direct_work_items,
    indexed_work_items,
    non_indexed_work_items,
    late_indexed_work_items,
    late_non_indexed_work_items,
    indexed_cpu_metadata,
    indexed_gpu_metadata,
    indexed_batch_sets,
    non_indexed_cpu_metadata,
    non_indexed_gpu_metadata,
    non_indexed_batch_sets,
    dispatch_metadata,
  }
}

///|
fn render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
  draw_items : Array[MeshPhaseItem3d],
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> Array[Int] {
  let opaque_alpha_end_index_raw = render3d_gpu_preprocess_opaque_alpha_end_index(
    phase_ranges,
  )
  let opaque_alpha_end_index = if opaque_alpha_end_index_raw >
    draw_items.length() {
    draw_items.length()
  } else {
    opaque_alpha_end_index_raw
  }
  let indices : Array[Int] = []
  let included : Array[Bool] = []
  for _ in draw_items {
    included.push(false)
  }
  let push_if_valid = fn(index : Int) {
    if index < 0 || index >= opaque_alpha_end_index {
      return
    }
    if draw_items[index].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[index].phase == RENDER3D_PHASE_ALPHA_MASK {
      if included[index] {
        return
      }
      included[index] = true
      indices.push(index)
    }
  }
  match work_item_buffers {
    Direct(items) =>
      for item in items {
        push_if_valid(item.output_or_indirect_parameters_index)
      }
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        push_if_valid(item.input_index)
      }
      for item in non_indexed_items {
        push_if_valid(item.input_index)
      }
    }
  }
  for i in 0..<opaque_alpha_end_index {
    if draw_items[i].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[i].phase == RENDER3D_PHASE_ALPHA_MASK {
      if included[i] {
        continue
      }
      included[i] = true
      indices.push(i)
    }
  }
  indices
}

///|
fn render3d_gpu_preprocess_indirect_parameter_index_maps(
  draw_items : Array[MeshPhaseItem3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
  indirect_metadata : GpuPreprocessIndirectMetadata3d,
) -> (Array[Int], Array[Int]) {
  let indexed : Array[Int] = []
  let non_indexed : Array[Int] = []
  for _ in draw_items {
    indexed.push(-1)
    non_indexed.push(-1)
  }
  match work_item_buffers {
    Direct(_) => ()
    Indirect(_, _, _) => {
      for
        indirect_parameters_index in 0..<indirect_metadata.indexed.indirect_parameters_cpu_metadata.length() {
        let metadata = indirect_metadata.indexed.indirect_parameters_cpu_metadata[indirect_parameters_index]
        if metadata.base_output_index >= 0 &&
          metadata.base_output_index < indexed.length() {
          indexed[metadata.base_output_index] = indirect_parameters_index
        }
      }
      for
        indirect_parameters_index in 0..<indirect_metadata.non_indexed.indirect_parameters_cpu_metadata.length() {
        let metadata = indirect_metadata.non_indexed.indirect_parameters_cpu_metadata[indirect_parameters_index]
        if metadata.base_output_index >= 0 &&
          metadata.base_output_index < non_indexed.length() {
          non_indexed[metadata.base_output_index] = indirect_parameters_index
        }
      }
    }
  }
  (indexed, non_indexed)
}

///|
fn render3d_queue_mesh_phase_items_gpu_builder(
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  camera_transform : @transform.Transform,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
) -> Array[MeshPhaseItem3d] {
  // Keep the same high-level architecture as Bevy's GPU preprocessing path:
  // collect mesh work items, then write batched instance work payloads.
  let work_items = render3d_collect_meshes_for_gpu_building(
    meshes,
    render_mesh_instances,
    render_mesh_assets,
    maybe_batched_instance_buffers,
    mesh_allocator,
    render_material_instances,
    render_material_bindings,
    material_slots,
    pending_mesh_material_queues,
    camera_transform,
    retained_view_entity~,
    specialized_material_pipeline_cache~,
    visible_mesh_entities~,
  )
  render3d_write_batched_instance_buffers(work_items)
}

///|
fn render3d_queue_mesh_phase_items(
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  mesh_allocator : @render_mesh.MeshAllocator,
  render_material_instances : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  camera_transform : @transform.Transform,
  use_gpu_instance_buffer_builder : Bool,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_mesh_entities? : @render_visibility.RenderVisibleEntitiesClass? = None,
) -> Array[MeshPhaseItem3d] {
  if use_gpu_instance_buffer_builder {
    return render3d_queue_mesh_phase_items_gpu_builder(
      meshes,
      render_mesh_instances,
      render_mesh_assets,
      maybe_batched_instance_buffers,
      mesh_allocator,
      render_material_instances,
      render_material_bindings,
      material_slots,
      pending_mesh_material_queues,
      camera_transform,
      retained_view_entity~,
      specialized_material_pipeline_cache~,
      visible_mesh_entities~,
    )
  }
  render3d_queue_mesh_phase_items_cpu_builder(
    meshes,
    render_mesh_instances,
    render_mesh_assets,
    maybe_batched_instance_buffers,
    mesh_allocator,
    render_material_instances,
    render_material_bindings,
    material_slots,
    pending_mesh_material_queues,
    camera_transform,
    retained_view_entity~,
    specialized_material_pipeline_cache~,
    visible_mesh_entities~,
  )
}
