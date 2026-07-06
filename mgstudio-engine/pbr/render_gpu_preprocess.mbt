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
// Bevy source:
// `bevy/crates/bevy_camera/src/visibility/mod.rs::check_visibility`.
// CPU frustum culling is applied only when all three opt-out flags are false:
// `!no_frustum_culling && !no_cpu_culling_camera && !no_cpu_culling_entity`.
pub fn render3d_should_apply_cpu_frustum_culling_flags(
  has_no_frustum_culling : Bool,
  camera_has_no_cpu_culling : Bool,
  entity_has_no_cpu_culling : Bool,
) -> Bool {
  !has_no_frustum_culling &&
  !camera_has_no_cpu_culling &&
  !entity_has_no_cpu_culling
}

///|
fn render3d_mesh_pipeline_id_for_view(
  mesh : ExtractedMesh3d,
  retained_view_entity : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache : SpecializedMaterialPipelineCache,
) -> @material.CachedRenderPipelineId? {
  specialized_material_pipeline_cache.pipeline_id(
    retained_view_entity,
    mesh.entity.main_entity,
  )
}

///|
test "render3d gpu preprocess: view cache miss does not fall back to extracted pipeline id" {
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(61, 0))
  let entity = @core.Entity::new(62, 0)
  let cached_pipeline = @material.CachedRenderPipelineId::new(92UL)
  let transform = @transform.Transform::identity()
  let world_from_local = @math.Affine3::identity()
  let mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(entity),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(17),
      mesh_id: 17,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material_draw_data: MaterialDrawData3d::Standard(
        @material.StandardMaterial::StandardMaterial(),
      ),
      material_extension: None,
      material_properties: @material.MaterialProperties::MaterialProperties(),
      material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_wireframe: false,
      wireframe_asset_id: None,
      wireframe_material: None,
      wireframe_color: None,
      wireframe_line_width: None,
      wireframe_topology: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
      motion_vector_enabled: false,
    },
  }
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()

  debug_inspect(
    render3d_mesh_pipeline_id_for_view(mesh, view, cache).map(fn(value) {
      value.id()
    }),
    content="None",
  )

  cache.insert(view, entity, 1, cached_pipeline)
  debug_inspect(
    render3d_mesh_pipeline_id_for_view(mesh, view, cache).map(fn(value) {
      value.id()
    }),
    content="Some(92)",
  )
}

///|
fn render3d_traced_mesh_pipeline_id_for_view(
  mesh : ExtractedMesh3d,
  retained_view_entity : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache : SpecializedMaterialPipelineCache,
) -> @material.CachedRenderPipelineId? {
  let trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_pipeline_lookup",
  )
  let pipeline_id = render3d_mesh_pipeline_id_for_view(
    mesh, retained_view_entity, specialized_material_pipeline_cache,
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_pipeline_lookup",
    trace_start_us,
  )
  pipeline_id
}

///|
fn render3d_queue_mesh_phase_items_cpu_builder(
  meshes : Array[ExtractedMesh3d],
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  layers : @camera_render_layers.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  camera_has_no_cpu_culling : Bool,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_main_entities? : Map[UInt64, Bool]? = None,
) -> Array[MeshPhaseItem3d] {
  let items : Array[MeshPhaseItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    match visible_main_entities {
      Some(visible) =>
        if !visible.get(mesh.entity.main_entity.to_bits()).unwrap_or(false) {
          continue
        }
      None => ()
    }
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.world_from_local.translation,
        payload.aabb_center_world,
      ) {
      continue
    }
    let should_apply_cpu_frustum_culling = render3d_should_apply_cpu_frustum_culling_flags(
      payload.has_no_frustum_culling,
      camera_has_no_cpu_culling,
      payload.has_no_cpu_culling,
    )
    if should_apply_cpu_frustum_culling &&
      !render3d_mesh_frustum_visible(payload, camera_frustum_planes) {
      continue
    }
    guard render3d_queue_resolved_material_for_mesh(
        material_slots, pending_mesh_material_queues, retained_view_entity, mesh,
      )
      is Some(material) else {
      continue
    }
    let material_properties = material.material_properties()
    let alpha = material.material_draw_data().draw_alpha_source()
    guard render3d_mesh_phase_kind(material_properties, alpha) is Some(phase) else {
      continue
    }
    let pipeline_id = render3d_traced_mesh_pipeline_id_for_view(
      mesh, retained_view_entity, specialized_material_pipeline_cache,
    )
    guard pipeline_id is Some(pipeline_id) else { continue }
    items.push(MeshPhaseItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      pipeline_id,
      distance: render3d_material_phase_distance(
        payload, material_properties, camera_transform,
      ),
    })
  }
  items.sort_by(fn(a, b) {
    let phase_cmp = @pbr_render.cmp_int(a.phase, b.phase)
    if phase_cmp != 0 {
      return phase_cmp
    }
    if a.phase == RENDER3D_PHASE_TRANSMISSIVE ||
      a.phase == RENDER3D_PHASE_TRANSPARENT {
      let depth_cmp = @pbr_render.cmp_float(b.distance, a.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    } else {
      let depth_cmp = @pbr_render.cmp_float(a.distance, b.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
priv struct GpuPreprocessWorkItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  phase : Int
  pipeline_id : @material.CachedRenderPipelineId
  distance : Float
}

///|
fn render3d_collect_meshes_for_gpu_building(
  meshes : Array[ExtractedMesh3d],
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  layers : @camera_render_layers.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  camera_has_no_cpu_culling : Bool,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_main_entities? : Map[UInt64, Bool]? = None,
) -> Array[GpuPreprocessWorkItem3d] {
  let work_items : Array[GpuPreprocessWorkItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    match visible_main_entities {
      Some(visible) =>
        if !visible.get(mesh.entity.main_entity.to_bits()).unwrap_or(false) {
          continue
        }
      None => ()
    }
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.world_from_local.translation,
        payload.aabb_center_world,
      ) {
      continue
    }
    let should_apply_cpu_frustum_culling = render3d_should_apply_cpu_frustum_culling_flags(
      payload.has_no_frustum_culling,
      camera_has_no_cpu_culling,
      payload.has_no_cpu_culling,
    )
    if should_apply_cpu_frustum_culling &&
      !render3d_mesh_frustum_visible(payload, camera_frustum_planes) {
      continue
    }
    guard render3d_queue_resolved_material_for_mesh(
        material_slots, pending_mesh_material_queues, retained_view_entity, mesh,
      )
      is Some(material) else {
      continue
    }
    let material_properties = material.material_properties()
    let alpha = material.material_draw_data().draw_alpha_source()
    guard render3d_mesh_phase_kind(material_properties, alpha) is Some(phase) else {
      continue
    }
    let pipeline_id = render3d_traced_mesh_pipeline_id_for_view(
      mesh, retained_view_entity, specialized_material_pipeline_cache,
    )
    guard pipeline_id is Some(pipeline_id) else { continue }
    work_items.push(GpuPreprocessWorkItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      pipeline_id,
      distance: render3d_material_phase_distance(
        payload, material_properties, camera_transform,
      ),
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
      phase: work_item.phase,
      pipeline_id: work_item.pipeline_id,
      distance: work_item.distance,
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
  extracted_mesh : ExtractedMesh3d,
) -> Bool {
  extracted_mesh.payload.mesh_id > 0
}

///|
priv struct Render3dGpuPreprocessPhaseBuffers {
  work_item_buffers : @render_batching.PreprocessWorkItemBuffers
  indirect_parameters_buffers : @render_batching.UntypedPhaseIndirectParametersBuffers
}

///|
fn render3d_build_gpu_preprocess_phase_buffers_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
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
    if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
      draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    if draw_item.extracted_index < 0 ||
      draw_item.extracted_index >= meshes.length() {
      continue
    }
    let extracted_mesh = meshes[draw_item.extracted_index]
    if !render3d_mesh_preprocess_indirect_eligible(extracted_mesh) {
      continue
    }
    let indexed = extracted_mesh.payload.mesh_is_indexed
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
      @render_batching.PreprocessWorkItem::new(i, indirect_parameters_index),
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
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessResolvedCameraQueueEntry3d {
  let phase_buffers = render3d_build_gpu_preprocess_phase_buffers_from_draw_items(
    draw_items, meshes, indirect_enabled, gpu_occlusion_culling_enabled,
  )
  render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
    draw_items,
    meshes,
    mesh_preprocess_static_cache,
    phase_buffers.work_item_buffers,
    phase_buffers.indirect_parameters_buffers,
  )
}

///|
fn render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
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
  for draw_item in draw_items {
    mesh_culling_data.push(
      render3d_host_preprocess_mesh_culling_data(
        draw_item, meshes, mesh_preprocess_static_cache,
      ),
    )
    mesh_inputs.push(
      render3d_host_preprocess_mesh_input(
        draw_item, meshes, mesh_preprocess_static_cache,
      ),
    )
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
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> @render.HostMesh3dPreprocessMeshCullingData {
  match
    render3d_mesh_preprocess_static_for_draw_item(
      draw_item, meshes, mesh_preprocess_static_cache,
    ) {
    Some(metadata) => {
      if !metadata.has_local_aabb {
        return @render.HostMesh3dPreprocessMeshCullingData::{
          aabb_center_x: 0.0F,
          aabb_center_y: 0.0F,
          aabb_center_z: 0.0F,
          aabb_half_extents_x: 1.0F / 0.0F,
          aabb_half_extents_y: 1.0F / 0.0F,
          aabb_half_extents_z: 1.0F / 0.0F,
        }
      }
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: metadata.aabb_center.x,
        aabb_center_y: metadata.aabb_center.y,
        aabb_center_z: metadata.aabb_center.z,
        aabb_half_extents_x: metadata.aabb_half_extents.x,
        aabb_half_extents_y: metadata.aabb_half_extents.y,
        aabb_half_extents_z: metadata.aabb_half_extents.z,
      }
    }
    None =>
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: 0.0F,
        aabb_center_y: 0.0F,
        aabb_center_z: 0.0F,
        aabb_half_extents_x: 1.0F / 0.0F,
        aabb_half_extents_y: 1.0F / 0.0F,
        aabb_half_extents_z: 1.0F / 0.0F,
      }
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
    let metadata = match mesh.payload.mesh_preprocess_static {
      Some(static_metadata) => static_metadata
      None =>
        render3d_mesh_preprocess_static(
          mesh.payload.mesh_handle,
          mesh.payload.mesh_id,
        )
    }
    cache.set(mesh_handle_id, metadata)
  }
}

///|
fn render3d_mesh_preprocess_static_for_draw_item(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> MeshPreprocessStatic3d? {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return None
  }
  let mesh_handle = meshes[draw_item.extracted_index].payload.mesh_handle
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return None
  }
  match mesh_preprocess_static_cache.get(mesh_handle_id) {
    Some(metadata) => Some(metadata)
    None =>
      Some(
        render3d_mesh_preprocess_static(
          mesh_handle,
          meshes[draw_item.extracted_index].payload.mesh_id,
        ),
      )
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
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> @render.HostMesh3dPreprocessMeshInput {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return @render.HostMesh3dPreprocessMeshInput::{
      translation_x: 0.0F,
      translation_y: 0.0F,
      translation_z: 0.0F,
      rotation_x: 0.0F,
      rotation_y: 0.0F,
      rotation_z: 0.0F,
      rotation_w: 1.0F,
      scale_x: 1.0F,
      scale_y: 1.0F,
      scale_z: 1.0F,
      previous_translation_x: 0.0F,
      previous_translation_y: 0.0F,
      previous_translation_z: 0.0F,
      previous_rotation_x: 0.0F,
      previous_rotation_y: 0.0F,
      previous_rotation_z: 0.0F,
      previous_rotation_w: 1.0F,
      previous_scale_x: 1.0F,
      previous_scale_y: 1.0F,
      previous_scale_z: 1.0F,
      world_from_local_x_axis_x: 1.0F,
      world_from_local_x_axis_y: 0.0F,
      world_from_local_x_axis_z: 0.0F,
      world_from_local_y_axis_x: 0.0F,
      world_from_local_y_axis_y: 1.0F,
      world_from_local_y_axis_z: 0.0F,
      world_from_local_z_axis_x: 0.0F,
      world_from_local_z_axis_y: 0.0F,
      world_from_local_z_axis_z: 1.0F,
      world_from_local_translation_x: 0.0F,
      world_from_local_translation_y: 0.0F,
      world_from_local_translation_z: 0.0F,
      previous_world_from_local_x_axis_x: 1.0F,
      previous_world_from_local_x_axis_y: 0.0F,
      previous_world_from_local_x_axis_z: 0.0F,
      previous_world_from_local_y_axis_x: 0.0F,
      previous_world_from_local_y_axis_y: 1.0F,
      previous_world_from_local_y_axis_z: 0.0F,
      previous_world_from_local_z_axis_x: 0.0F,
      previous_world_from_local_z_axis_y: 0.0F,
      previous_world_from_local_z_axis_z: 1.0F,
      previous_world_from_local_translation_x: 0.0F,
      previous_world_from_local_translation_y: 0.0F,
      previous_world_from_local_translation_z: 0.0F,
      flags: 0U,
      first_vertex_index: 0,
      first_index_index: 0,
      index_count: 0,
      tag: 0,
    }
  }
  let extracted_mesh = meshes[draw_item.extracted_index]
  let mesh = extracted_mesh.payload
  let metadata = match
    render3d_mesh_preprocess_static_for_draw_item(
      draw_item, meshes, mesh_preprocess_static_cache,
    ) {
    Some(value) => value
    None =>
      MeshPreprocessStatic3d::{
        topology_kind: 0,
        is_indexed: false,
        first_vertex_index: 0,
        first_index_index: 0,
        index_count: 0,
        has_local_aabb: false,
        aabb_center: @math.Vec3::new(0.0F, 0.0F, 0.0F),
        aabb_half_extents: @math.Vec3::new(0.0F, 0.0F, 0.0F),
      }
  }
  ignore(metadata.has_local_aabb)
  let flags = render3d_mesh_flags(extracted_mesh)
  @render.HostMesh3dPreprocessMeshInput::{
    translation_x: mesh.transform.translation.x,
    translation_y: mesh.transform.translation.y,
    translation_z: mesh.transform.translation.z,
    rotation_x: mesh.transform.rotation.x,
    rotation_y: mesh.transform.rotation.y,
    rotation_z: mesh.transform.rotation.z,
    rotation_w: mesh.transform.rotation.w,
    scale_x: mesh.transform.scale.x,
    scale_y: mesh.transform.scale.y,
    scale_z: mesh.transform.scale.z,
    previous_translation_x: mesh.previous_transform.translation.x,
    previous_translation_y: mesh.previous_transform.translation.y,
    previous_translation_z: mesh.previous_transform.translation.z,
    previous_rotation_x: mesh.previous_transform.rotation.x,
    previous_rotation_y: mesh.previous_transform.rotation.y,
    previous_rotation_z: mesh.previous_transform.rotation.z,
    previous_rotation_w: mesh.previous_transform.rotation.w,
    previous_scale_x: mesh.previous_transform.scale.x,
    previous_scale_y: mesh.previous_transform.scale.y,
    previous_scale_z: mesh.previous_transform.scale.z,
    world_from_local_x_axis_x: mesh.world_from_local.matrix3.x_axis.x,
    world_from_local_x_axis_y: mesh.world_from_local.matrix3.x_axis.y,
    world_from_local_x_axis_z: mesh.world_from_local.matrix3.x_axis.z,
    world_from_local_y_axis_x: mesh.world_from_local.matrix3.y_axis.x,
    world_from_local_y_axis_y: mesh.world_from_local.matrix3.y_axis.y,
    world_from_local_y_axis_z: mesh.world_from_local.matrix3.y_axis.z,
    world_from_local_z_axis_x: mesh.world_from_local.matrix3.z_axis.x,
    world_from_local_z_axis_y: mesh.world_from_local.matrix3.z_axis.y,
    world_from_local_z_axis_z: mesh.world_from_local.matrix3.z_axis.z,
    world_from_local_translation_x: mesh.world_from_local.translation.x,
    world_from_local_translation_y: mesh.world_from_local.translation.y,
    world_from_local_translation_z: mesh.world_from_local.translation.z,
    previous_world_from_local_x_axis_x: mesh.previous_world_from_local.matrix3.x_axis.x,
    previous_world_from_local_x_axis_y: mesh.previous_world_from_local.matrix3.x_axis.y,
    previous_world_from_local_x_axis_z: mesh.previous_world_from_local.matrix3.x_axis.z,
    previous_world_from_local_y_axis_x: mesh.previous_world_from_local.matrix3.y_axis.x,
    previous_world_from_local_y_axis_y: mesh.previous_world_from_local.matrix3.y_axis.y,
    previous_world_from_local_y_axis_z: mesh.previous_world_from_local.matrix3.y_axis.z,
    previous_world_from_local_z_axis_x: mesh.previous_world_from_local.matrix3.z_axis.x,
    previous_world_from_local_z_axis_y: mesh.previous_world_from_local.matrix3.z_axis.y,
    previous_world_from_local_z_axis_z: mesh.previous_world_from_local.matrix3.z_axis.z,
    previous_world_from_local_translation_x: mesh.previous_world_from_local.translation.x,
    previous_world_from_local_translation_y: mesh.previous_world_from_local.translation.y,
    previous_world_from_local_translation_z: mesh.previous_world_from_local.translation.z,
    flags,
    first_vertex_index: metadata.first_vertex_index,
    first_index_index: metadata.first_index_index,
    index_count: metadata.index_count,
    tag: draw_item.extracted_index,
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
) -> (Array[Int], Array[Int]) {
  let indexed : Array[Int] = []
  let non_indexed : Array[Int] = []
  for _ in draw_items {
    indexed.push(-1)
    non_indexed.push(-1)
  }
  match work_item_buffers {
    Direct(_) => ()
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        if item.input_index >= 0 && item.input_index < indexed.length() {
          indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
      for item in non_indexed_items {
        if item.input_index >= 0 && item.input_index < non_indexed.length() {
          non_indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
    }
  }
  (indexed, non_indexed)
}

///|
fn render3d_queue_mesh_phase_items_gpu_builder(
  meshes : Array[ExtractedMesh3d],
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  layers : @camera_render_layers.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  camera_has_no_cpu_culling : Bool,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_main_entities? : Map[UInt64, Bool]? = None,
) -> Array[MeshPhaseItem3d] {
  // Keep the same high-level architecture as Bevy's GPU preprocessing path:
  // collect mesh work items, then write batched instance work payloads.
  let work_items = render3d_collect_meshes_for_gpu_building(
    meshes,
    material_slots,
    pending_mesh_material_queues,
    layers,
    camera_transform,
    camera_frustum_planes,
    camera_has_no_cpu_culling,
    retained_view_entity~,
    specialized_material_pipeline_cache~,
    visible_main_entities~,
  )
  render3d_write_batched_instance_buffers(work_items)
}

///|
fn render3d_queue_mesh_phase_items(
  meshes : Array[ExtractedMesh3d],
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  layers : @camera_render_layers.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  camera_has_no_cpu_culling : Bool,
  use_gpu_instance_buffer_builder : Bool,
  retained_view_entity~ : @render_view.RetainedViewEntity,
  specialized_material_pipeline_cache~ : SpecializedMaterialPipelineCache,
  visible_main_entities? : Map[UInt64, Bool]? = None,
) -> Array[MeshPhaseItem3d] {
  if use_gpu_instance_buffer_builder {
    return render3d_queue_mesh_phase_items_gpu_builder(
      meshes,
      material_slots,
      pending_mesh_material_queues,
      layers,
      camera_transform,
      camera_frustum_planes,
      camera_has_no_cpu_culling,
      retained_view_entity~,
      specialized_material_pipeline_cache~,
      visible_main_entities~,
    )
  }
  render3d_queue_mesh_phase_items_cpu_builder(
    meshes,
    material_slots,
    pending_mesh_material_queues,
    layers,
    camera_transform,
    camera_frustum_planes,
    camera_has_no_cpu_culling,
    retained_view_entity~,
    specialized_material_pipeline_cache~,
    visible_main_entities~,
  )
}
