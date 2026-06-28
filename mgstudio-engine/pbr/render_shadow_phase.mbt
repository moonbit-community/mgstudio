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
priv struct Render3dShadowPhaseView {
  shadow_view : Render3dShadowView
}

///|
priv struct Render3dShadowPhaseExecutionView {
  phase_view : Render3dShadowPhaseView
  pass_kind : Int
  point_shadow_near : Float
}

///|
priv struct Render3dResolvedShadowPhaseItem {
  item : Render3dShadowPhaseItemData
  extracted_indices : Array[Int]
}

///|
fn render3d_light_entity_is_directional(
  light_entity : Render3dLightEntity,
) -> Bool {
  match light_entity {
    Directional(..) => true
    _ => false
  }
}

///|
fn render3d_shadow_gpu_preprocessing_support(
  world : @ecs.World,
) -> @render_batching.GpuPreprocessingSupport {
  match
    world.get_resource(@render_batching.GpuPreprocessingSupport::resource()) {
    Some(value) => value
    None => @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport()
  }
}

///|
fn render3d_specialize_shadow_phase_for_light(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Bool {
  let shadow_phase_exists = match
    world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) => phases.get(retained_view_entity) is Some(_)
    None => false
  }
  if !shadow_phase_exists {
    return false
  }
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtySpecializations resource during pbr shadow specialization",
      )
  }
  let light_key_cache = match
    world.get_resource(@pbr_render.LightKeyCache::resource()) {
    Some(value) => value
    None =>
      abort("missing LightKeyCache resource during pbr shadow specialization")
  }
  let light_key = match light_key_cache.get(retained_view_entity) {
    Some(value) => value
    None => return false
  }
  match
    world.get_resource_mut(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache_ref) =>
      cache_ref.modify(fn(cache) {
        cache.apply_dirty_specializations_for_view(
          dirty_specializations, retained_view_entity,
        )
      })
    None =>
      abort(
        "missing SpecializedShadowMaterialPipelineCache resource during pbr shadow specialization",
      )
  }
  let pending_shadow_queues = match
    world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingShadowQueues resource during pbr shadow specialization",
      )
  }
  let view_pending_shadow_queues = pending_shadow_queues
    .queues()
    .prepare_for_new_frame(retained_view_entity)
  let candidates = render3d_shadow_specialization_candidates_for_light(
    world, light_entity, retained_view_entity, dirty_specializations, pending_shadow_queues,
  )
  for candidate in candidates {
    let (render_entity, visible_entity) = candidate
    match
      render3d_shadow_specialization_work_item_data(
        world, retained_view_entity, render_entity, visible_entity, light_key, view_pending_shadow_queues,
      ) {
      Some(work_item) =>
        ignore(
          render3d_shadow_specialization_apply_work_item(
            world, work_item, false,
          ),
        )
      None => ()
    }
  }
  true
}

///|
fn render3d_queue_shadow_phase_for_light(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  view_render_layers : @camera_render_layers.RenderLayers?,
) -> Bool {
  guard world.get_resource(Render3dShadowPhasesData::resource()) is Some(phases) &&
    phases.get(retained_view_entity) is Some(_) else {
    return false
  }
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort("missing DirtySpecializations resource during pbr shadow queueing")
  }
  let pending_shadow_queues = match
    world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(value) => value
    None =>
      abort("missing PendingShadowQueues resource during pbr shadow queueing")
  }
  render3d_queue_shadow_phase_data_for_light(
    world,
    light_entity,
    retained_view_entity,
    view_render_layers,
    dirty_specializations,
    pending_shadow_queues,
    render3d_shadow_gpu_preprocessing_support(world),
  )
}

///|
fn render3d_specialize_shadow_phase_views(
  world : @ecs.World,
  views : Array[Render3dQueuedShadowPhaseView],
) -> Int {
  let all_shadow_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  let mut specialized_count = 0
  for view in views {
    all_shadow_views.add(view.retained_view_entity())
    if render3d_specialize_shadow_phase_for_light(
        world,
        view.light_entity(),
        view.retained_view_entity(),
      ) {
      specialized_count += 1
    }
  }
  match world.get_resource_mut(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues_ref) =>
      queues_ref.modify(fn(queues) {
        queues.queues().expire_stale_views(all_shadow_views)
      })
    None =>
      abort(
        "missing PendingShadowQueues resource during pbr shadow specialization",
      )
  }
  match
    world.get_resource_mut(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache_ref) =>
      cache_ref.modify(fn(cache) { cache.expire_stale_views(all_shadow_views) })
    None =>
      abort(
        "missing SpecializedShadowMaterialPipelineCache resource during pbr shadow specialization",
      )
  }
  specialized_count
}

///|
fn render3d_queue_shadow_phase_views(
  world : @ecs.World,
  views : Array[Render3dQueuedShadowPhaseView],
) -> Int {
  let mut queued_count = 0
  for view in views {
    if render3d_queue_shadow_phase_for_light(
        world,
        view.light_entity(),
        view.retained_view_entity(),
        view.view_render_layers(),
      ) {
      queued_count += 1
    }
  }
  queued_count
}

///|
fn render3d_shadow_phase_items_for_view(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Array[Render3dShadowPhaseItemData] {
  match world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) =>
      match phases.get(retained_view_entity) {
        Some(phase) => phase.render_items(false)
        None => []
      }
    None => []
  }
}

///|
fn render3d_shadow_resolve_phase_items(
  meshes : Array[ExtractedMesh3d],
  render_mesh_instances : RenderMeshInstances,
  items : Array[Render3dShadowPhaseItemData],
) -> Array[Render3dResolvedShadowPhaseItem] {
  let mesh_indices_by_main_entity : Map[UInt64, Int] = {}
  let mesh_indices_by_uniform_index : Map[Int, Int] = {}
  for index in 0..<meshes.length() {
    let main_entity = @render.MainEntity::new(meshes[index].entity.main_entity)
    let main_bits = main_entity.id().to_bits()
    mesh_indices_by_main_entity.set(main_bits, index)
    match render_mesh_instances.render_mesh_queue_data(main_entity) {
      Some(queue_data) =>
        mesh_indices_by_uniform_index.set(
          queue_data.current_uniform_index().reinterpret_as_int(),
          index,
        )
      None => ()
    }
  }
  let resolved : Array[Render3dResolvedShadowPhaseItem] = []
  for item in items {
    let extracted_indices : Array[Int] = []
    let batch_range = item.batch_range()
    for uniform_index in batch_range.start()..<batch_range.end() {
      match mesh_indices_by_uniform_index.get(uniform_index) {
        Some(extracted_index) => extracted_indices.push(extracted_index)
        None => ()
      }
    }
    if extracted_indices.length() == 0 {
      match mesh_indices_by_main_entity.get(item.main_entity().id().to_bits()) {
        Some(extracted_index) => extracted_indices.push(extracted_index)
        None => ()
      }
    }
    if extracted_indices.length() > 0 {
      resolved.push(Render3dResolvedShadowPhaseItem::{ item, extracted_indices })
    }
  }
  resolved
}

///|
fn render3d_resolved_shadow_phase_draw_count(
  items : Array[Render3dResolvedShadowPhaseItem],
) -> Int {
  let mut count = 0
  for item in items {
    count += item.extracted_indices.length()
  }
  count
}

///|
fn render3d_shadow_material_bind_group_data(
  phase_item : Render3dShadowPhaseItemData,
  shadow_mesh : Mesh3dExtractedPayload,
) -> @render_resource.MaterialBindGroupResolvedData {
  match phase_item.batch_set_key().material_bind_group_index() {
    Some(_) => shadow_mesh.material_bind_group_data
    None =>
      @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData()
  }
}

///|
fn render3d_shadow_visible_extracted_indices(
  meshes : Array[ExtractedMesh3d],
  camera_layers : @camera_render_layers.RenderLayers,
  shadow_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
) -> Array[Int] {
  let visible : Array[Int] = []
  for extracted_index in 0..<meshes.length() {
    let mesh = meshes[extracted_index].payload
    if mesh.mesh_id <= 0 {
      continue
    }
    if !camera_layers.matches(mesh.layers) {
      continue
    }
    if !render3d_should_apply_cpu_frustum_culling_flags(
        mesh.has_no_frustum_culling,
        false,
        mesh.has_no_cpu_culling,
      ) {
      visible.push(extracted_index)
      continue
    }
    if render3d_mesh_frustum_visible(mesh, shadow_frustum_planes) {
      visible.push(extracted_index)
    }
  }
  visible
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::get_shadow_map_visible_entities`.
fn render3d_shadow_visible_entity_pairs(
  meshes : Array[ExtractedMesh3d],
  visible_indices : Array[Int],
) -> Array[(@core.Entity, @render.MainEntity)] {
  let pairs : Array[(@core.Entity, @render.MainEntity)] = []
  for extracted_index in visible_indices {
    if extracted_index < 0 || extracted_index >= meshes.length() {
      continue
    }
    let mesh = meshes[extracted_index]
    pairs.push(
      (
        mesh.entity.render_entity,
        @render.MainEntity::new(mesh.entity.main_entity),
      ),
    )
  }
  pairs
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::get_shadow_map_visible_entities`.
fn render3d_update_shadow_map_visible_entities(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  shadow_phase_retained_view : @render_view.RetainedViewEntity,
  meshes : Array[ExtractedMesh3d],
  visible_indices : Array[Int],
) -> Unit {
  let visible_key = light_entity.shadow_map_visible_retained_view(
    shadow_phase_retained_view,
  )
  let owner = light_entity.shadow_map_visible_entity()
  let shadow_map_visible_entities = match
    (try! world.get_by_key(
      owner, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    )) {
    Some(value) => value
    None =>
      @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities()
  }
  let visible_entities = shadow_map_visible_entities.subview_or_insert(
    visible_key,
  )
  let visible_meshes = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_meshes.prepare_for_new_frame()
  visible_meshes.update_cpu_culled_entities(
    render3d_shadow_visible_entity_pairs(meshes, visible_indices),
  )
  visible_meshes.sort_added_entities()
  try! world.set_by_key(
    owner, @render_visibility.ecs_key_render_shadow_map_visible_entities, shadow_map_visible_entities,
  )
}

///|
fn render3d_update_shadow_phase_visible_view(
  world : @ecs.World,
  light_entity : Render3dLightEntity,
  retained_view_entity : @render_view.RetainedViewEntity,
  meshes : Array[ExtractedMesh3d],
  camera_layers : @camera_render_layers.RenderLayers,
  shadow_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
) -> Render3dQueuedShadowPhaseView {
  let visible_indices = render3d_shadow_visible_extracted_indices(
    meshes, camera_layers, shadow_frustum_planes,
  )
  render3d_update_shadow_map_visible_entities(
    world, light_entity, retained_view_entity, meshes, visible_indices,
  )
  Render3dQueuedShadowPhaseView::new(
    light_entity,
    retained_view_entity,
    view_render_layers=Some(camera_layers),
  )
}

///|
fn render3d_execute_shadow_phase_view(
  world : @ecs.World,
  camera_entity : @core.Entity,
  pass_lighting : Render3dLightingState,
  pass_kind : Int,
  point_shadow_near : Float,
  meshes : Array[ExtractedMesh3d],
  phase_view : Render3dShadowPhaseView,
) -> Unit {
  let retained_view_entity = phase_view.shadow_view.light_entity.shadow_phase_retained_view(
    @render_view.RetainedViewEntity::new(camera_entity),
  )
  let phase_items = render3d_shadow_phase_items_for_view(
    world, retained_view_entity,
  )
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => return
  }
  let resolved_phase_items = render3d_shadow_resolve_phase_items(
    meshes, render_mesh_instances, phase_items,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_shadow_phase_items",
    resolved_phase_items.length(),
  )
  render3d_shadow_view_begin_pass(
    phase_view.shadow_view,
    pass_lighting,
    pass_kind,
    point_shadow_near,
  )
  let (shadow_view_key_hi, shadow_view_key_lo) = render3d_shadow_view_cache_key(
    camera_entity,
    phase_view.shadow_view.light_entity,
  )
  let shadow_phase = render3d_mesh_gpu_binned_phase_new()
  let draw_count = render3d_resolved_shadow_phase_draw_count(
    resolved_phase_items,
  )
  let draw_storage_base = @render.host_gpu_reserve_mesh3d_draw_storage(
    count=draw_count,
  )
  if draw_storage_base < 0 && draw_count > 0 {
    @render.host_gpu_end_pass()
    return
  }
  let mut draw_storage_offset = 0
  for resolved_phase_item in resolved_phase_items {
    let phase_item = resolved_phase_item.item
    let extracted_shadow_mesh = meshes[resolved_phase_item.extracted_indices[0]]
    let shadow_mesh = extracted_shadow_mesh.payload
    let material_bind_group_data = render3d_shadow_material_bind_group_data(
      phase_item, shadow_mesh,
    )
    let draw_storage_index = draw_storage_base + draw_storage_offset
    let batch_payload = @pbr_render.render3d_build_mesh_gpu_draw_payload(
      shadow_mesh.mesh_id,
      shadow_view_key_hi,
      shadow_view_key_lo,
      draw_storage_index,
      MESH3D_DRAW_INDIRECT_KIND_NONE,
      -1,
      shadow_mesh.material,
      shadow_mesh.transform,
      shadow_mesh.transform,
      1.0F,
      1.0F,
      1.0F,
      1.0F,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      0.5F,
      0.5F,
      0.0F,
      0.0F,
      0.0F,
      1.5F,
      -1,
      0.0F,
      0.0F,
      -1,
      0.0F,
      0.0F,
      -1,
      -1,
      0.0F,
      @math.Quat::identity(),
      @color.Color::white(),
      0.0F,
      0.0F,
      render3d_mesh_flags(extracted_shadow_mesh),
      0,
      material_pipeline_id=Some(phase_item.cached_pipeline()),
      material_extension_bind_group_data=material_bind_group_data,
      skinning_key_hi=shadow_mesh.skinning_key_hi,
      skinning_key_lo=if shadow_mesh.skinning_key_hi >= 0 { 0 } else { -1 },
      morph_weights_index=shadow_mesh.morph_weights_index,
      previous_morph_weights_index=shadow_mesh.previous_morph_weights_index,
      morph_targets_texture_id=shadow_mesh.morph_targets_texture_id,
      world_from_local=Some(shadow_mesh.world_from_local),
      previous_world_from_local=Some(shadow_mesh.previous_world_from_local),
    )
    for extracted_index in resolved_phase_item.extracted_indices {
      let extracted_batch_mesh = meshes[extracted_index]
      let batch_mesh = extracted_batch_mesh.payload
      let batch_material_bind_group_data = render3d_shadow_material_bind_group_data(
        phase_item, batch_mesh,
      )
      let batch_draw_storage_index = draw_storage_base + draw_storage_offset
      render3d_mesh_gpu_binned_phase_push(shadow_phase, @pbr_render.MeshGpuDrawPayload3d::{
        ..batch_payload,
        draw_storage_index: batch_draw_storage_index,
        transform: batch_mesh.transform,
        previous_transform: batch_mesh.previous_transform,
        world_from_local: batch_mesh.world_from_local,
        previous_world_from_local: batch_mesh.previous_world_from_local,
        material_extension_bind_group_data: batch_material_bind_group_data,
        mesh_flags: render3d_mesh_flags(extracted_batch_mesh),
        skinning_key_hi: batch_mesh.skinning_key_hi,
        skinning_key_lo: if batch_mesh.skinning_key_hi >= 0 {
          0
        } else {
          -1
        },
        morph_weights_index: batch_mesh.morph_weights_index,
        previous_morph_weights_index: batch_mesh.previous_morph_weights_index,
        morph_targets_texture_id: batch_mesh.morph_targets_texture_id,
      })
      draw_storage_offset += 1
    }
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_shadow_binned_batches",
    render3d_mesh_gpu_binned_phase_batch_count(shadow_phase),
  )
  @render.host_gpu_prepare_mesh3d_main_pass_draw_batch(
    preprocess_camera_key_hi=shadow_view_key_hi,
    preprocess_camera_key_lo=shadow_view_key_lo,
    pass_kind~,
    entries=render3d_mesh_gpu_binned_phase_entries(shadow_phase),
  )
  render3d_draw_mesh_gpu_binned_phase(shadow_phase)
  @render.host_gpu_end_pass()
}

///|
fn render3d_execute_shadow_phase_views(
  world : @ecs.World,
  camera_entity : @core.Entity,
  pass_lighting : Render3dLightingState,
  meshes : Array[ExtractedMesh3d],
  phase_views : Array[Render3dShadowPhaseExecutionView],
) -> Unit {
  for phase_view in phase_views {
    render3d_execute_shadow_phase_view(
      world,
      camera_entity,
      pass_lighting,
      phase_view.pass_kind,
      phase_view.point_shadow_near,
      meshes,
      phase_view.phase_view,
    )
  }
}
