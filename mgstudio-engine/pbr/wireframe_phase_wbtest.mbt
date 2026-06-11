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
test "pbr: Wireframe3d phase item exposes Bevy phase identity fields" {
  let draw_functions = @material.DrawFunctions::new()
  let draw = draw_functions.register("Wireframe3dThinDrawFunction")
  let batch_set = Wireframe3dBatchSetKey::new(
    @material.CachedRenderPipelineId::new(9UL),
    17,
    draw,
    WireframeMeshSlabs::new(2, index_slab_id=Some(3)),
  )
  let bin = Wireframe3dBinKey::new(31)
  let render_entity = @core.Entity::new(4, 1)
  let main_entity = @core.Entity::new(5, 1)
  let item = Wireframe3d::new(
    batch_set,
    bin,
    render_entity,
    main_entity,
    Wireframe3dBatchRange::new(7, 11),
    WireframePhaseItemExtraIndex::dynamic_offset(64),
  )

  debug_inspect(item.entity() == render_entity, content="true")
  debug_inspect(item.main_entity() == main_entity, content="true")
  debug_inspect(item.draw_function().id(), content="0")
  debug_inspect(item.cached_pipeline().id(), content="9")
  debug_inspect(item.batch_range().count(), content="4")
  debug_inspect(item.extra_index(), content="DynamicOffset(64)")
  debug_inspect(item.batch_set_key().indexed(), content="true")
  debug_inspect(item.bin_key().asset_id(), content="31")
}

///|
test "pbr: Wireframe3d batch set key models wide non-indexed path" {
  let draw_functions = @material.DrawFunctions::new()
  let draw = draw_functions.register("Wireframe3dWideDrawFunction")
  let wide = Wireframe3dBatchSetKey::new(
    @material.CachedRenderPipelineId::new(12UL),
    44,
    draw,
    WireframeMeshSlabs::new(5, index_slab_id=None, morph_target_slab_id=Some(8)),
    mesh_asset_id=Some(99),
  )

  debug_inspect(wide.indexed(), content="false")
  debug_inspect(wide.asset_id(), content="44")
  debug_inspect(wide.mesh_asset_id(), content="Some(99)")
  debug_inspect(wide.slabs().vertex_slab_id(), content="5")
  debug_inspect(wide.slabs().index_slab_id(), content="None")
  debug_inspect(wide.slabs().morph_target_slab_id(), content="Some(8)")
}

///|
test "pbr: WireframePipelineKey follows Bevy wide quads line-mode rules" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(7UL, "MeshPipelineKey")
  let thin = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
      ),
    ),
  )
  let quads = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 1.0F, Quads),
      ),
    ),
  )
  let thick = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 3.0F, Triangles),
      ),
    ),
  )

  debug_inspect(thin.wide(), content="false")
  debug_inspect(thin.quads(), content="false")
  debug_inspect(thin.line_mode(), content="false")
  debug_inspect(quads.wide(), content="true")
  debug_inspect(quads.quads(), content="true")
  debug_inspect(quads.line_mode(), content="true")
  debug_inspect(thick.wide(), content="true")
  debug_inspect(thick.quads(), content="false")
  debug_inspect(thick.line_mode(), content="false")
}

///|
test "pbr: SpecializedWireframePipelineCache stores per-view and wide pipelines" {
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let view = @core.Entity::new(10, 1)
  let entity = @core.Entity::new(11, 1)
  let pipeline = @material.CachedRenderPipelineId::new(77UL)
  cache.insert(view, entity, pipeline)

  debug_inspect(cache.len(), content="1")
  debug_inspect(
    cache.pipeline_id(view, entity).map(fn(id) { id.id() }),
    content="Some(77)",
  )
  debug_inspect(cache.remove_entity_from_all_views(entity), content="1")
  debug_inspect(cache.pipeline_id(view, entity) is None, content="true")

  let wide_key = WireframeWidePipelineCacheKey::new(
    @material.ErasedMeshPipelineKey::new(3UL, "MeshPipelineKey"),
    "pos_norm_uv",
    true,
    true,
  )
  cache.insert_wide_pipeline(
    wide_key,
    @material.CachedRenderPipelineId::new(88UL),
  )
  debug_inspect(cache.wide_len(), content="1")
  debug_inspect(
    cache.wide_pipeline_id(wide_key).map(fn(id) { id.id() }),
    content="Some(88)",
  )
}

///|
test "pbr: PendingWireframeQueues moves current frame into previous frame" {
  let queues = PendingWireframeQueues::PendingWireframeQueues()
  queues.push_current(@core.Entity::new(1, 1), @core.Entity::new(2, 1))
  queues.push_current(@core.Entity::new(3, 1), @core.Entity::new(4, 1))
  debug_inspect(queues.current_len(), content="2")
  debug_inspect(queues.previous_len(), content="0")

  queues.prepare_for_new_frame()

  debug_inspect(queues.current_len(), content="0")
  debug_inspect(queues.previous_len(), content="2")
}

///|
test "pbr: render wireframe instance resources track Bevy render asset ids" {
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = @core.Entity::new(7, 1)
  instances.insert(entity, 42)
  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.get(entity), content="Some(42)")
  debug_inspect(instances.remove(entity), content="true")
  debug_inspect(instances.get(entity), content="None")
  instances.insert(entity, 77)
  instances.clear()
  debug_inspect(instances.len(), content="0")
  debug_inspect(instances.get(entity), content="None")
}

///|
test "pbr: extract_wireframe_materials mirrors visible Mesh3dWireframe changes" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let visible_entity = source_world.spawn()
  let hidden_entity = source_world.spawn()
  instances.insert(hidden_entity, 99)
  try! source_world.set_by_key(
    visible_entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    visible_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(42)),
  )
  try! source_world.set_by_key(
    hidden_entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  try! source_world.set_by_key(
    hidden_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(13)),
  )

  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )

  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.get(visible_entity), content="Some(42)")
  debug_inspect(instances.get(hidden_entity), content="None")
}

///|
test "pbr: extract_wireframe_materials removes stale removed components" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = source_world.spawn()
  try! source_world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(7)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )
  debug_inspect(instances.get(entity), content="Some(7)")

  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  try! (source_world.remove_by_key(entity, ecs_key_mesh3d_wireframe) |> ignore)
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(instances.get(entity), content="None")
}

///|
test "pbr: extract_wireframe_materials preserves same-frame readded material" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = source_world.spawn()
  try! source_world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(3)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )
  debug_inspect(instances.get(entity), content="Some(3)")

  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  try! (source_world.remove_by_key(entity, ecs_key_mesh3d_wireframe) |> ignore)
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(11)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(instances.get(entity), content="Some(11)")
}

///|
test "pbr: wireframe specialization check collects changed source entities" {
  let world = @ecs.World::new()
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  let mesh_entity = world.spawn()
  let material_entity = world.spawn()
  let width_entity = world.spawn()
  let topology_entity = world.spawn()
  try! world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    material_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(2)),
  )
  try! world.set_by_key(
    width_entity,
    ecs_key_wireframe_line_width,
    WireframeLineWidth::new(3.0F),
  )
  try! world.set_by_key(topology_entity, ecs_key_wireframe_topology, Quads)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(0, 1),
  )

  debug_inspect(needs.changed_len(), content="4")
  debug_inspect(needs.changed_contains(mesh_entity), content="true")
  debug_inspect(needs.changed_contains(material_entity), content="true")
  debug_inspect(needs.changed_contains(width_entity), content="true")
  debug_inspect(needs.changed_contains(topology_entity), content="true")
  debug_inspect(needs.removed_len(), content="0")
}

///|
test "pbr: wireframe specialization check collects removed source entities" {
  let world = @ecs.World::new()
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  let mesh_entity = world.spawn()
  let material_entity = world.spawn()
  try! world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    material_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(2)),
  )
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  try! (world.remove_by_key(mesh_entity, ecs_key_mesh3d) |> ignore)
  try! (world.remove_by_key(material_entity, ecs_key_mesh3d_wireframe) |> ignore)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="0")
  debug_inspect(needs.removed_len(), content="2")
  debug_inspect(needs.removed_contains(mesh_entity), content="true")
  debug_inspect(needs.removed_contains(material_entity), content="true")
}

///|
test "pbr: dirty wireframe specializations mirror Bevy dirty tables" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let changed_entity = @core.Entity::new(1, 1)
  let removed_entity = @core.Entity::new(2, 1)
  dirty.insert_changed(changed_entity)
  dirty.insert_removed(removed_entity)
  debug_inspect(dirty.changed_len(), content="1")
  debug_inspect(dirty.removed_len(), content="1")
  debug_inspect(dirty.changed_contains(changed_entity), content="true")
  debug_inspect(dirty.removed_contains(removed_entity), content="true")

  dirty.clear()

  debug_inspect(dirty.changed_len(), content="0")
  debug_inspect(dirty.removed_len(), content="0")
}

///|
test "pbr: dirty wireframe specializations expose Bevy despecialize helpers" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let changed_entity = @core.Entity::new(1, 1)
  let removed_entity = @core.Entity::new(2, 1)
  let view = @core.Entity::new(3, 1)
  dirty.insert_changed(changed_entity)
  dirty.insert_removed(removed_entity)
  dirty.insert_view(view)

  let to_despecialize = dirty.to_despecialize()

  debug_inspect(to_despecialize.length(), content="2")
  debug_inspect(to_despecialize.contains(changed_entity), content="true")
  debug_inspect(to_despecialize.contains(removed_entity), content="true")
  debug_inspect(dirty.views_len(), content="1")
  debug_inspect(dirty.must_wipe_specializations_for_view(view), content="true")
  debug_inspect(
    dirty.must_wipe_specializations_for_view(@core.Entity::new(4, 1)),
    content="false",
  )

  dirty.clear()

  debug_inspect(dirty.views_len(), content="0")
  debug_inspect(to_despecialize.length(), content="2")
  debug_inspect(dirty.to_despecialize().length(), content="0")
}

///|
test "pbr: wireframe dirty extraction writes changed and removed render tables" {
  let world = @ecs.World::new()
  let changed_entity = @core.Entity::new(3, 1)
  let removed_entity = @core.Entity::new(4, 1)
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  needs.changed.push(changed_entity)
  needs.removed.push(removed_entity)
  world.insert_resource(
    WireframeEntitiesNeedingSpecialization::resource(),
    needs,
  )
  world.insert_resource(
    DirtyWireframeSpecializations::resource(),
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
  )

  extract_wireframe_entities_needing_specialization_system(world)
  extract_wireframe_entities_that_need_specializations_removed_system(world)

  let dirty = match
    world.get_resource(DirtyWireframeSpecializations::resource()) {
    Some(value) => value
    None => abort("missing DirtyWireframeSpecializations")
  }
  debug_inspect(dirty.changed_len(), content="1")
  debug_inspect(dirty.removed_len(), content="1")
  debug_inspect(dirty.changed_contains(changed_entity), content="true")
  debug_inspect(dirty.removed_contains(removed_entity), content="true")
}

///|
test "pbr: wireframe 3d phases prepare and retain views" {
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  let live_view = @core.Entity::new(10, 1)
  let stale_view = @core.Entity::new(11, 1)
  phases.prepare_for_new_frame(
    live_view,
    @render_batching.GpuPreprocessingMode::None,
  )
  phases.prepare_for_new_frame(
    stale_view,
    @render_batching.GpuPreprocessingMode::Culling,
  )
  let live : Map[UInt64, Bool] = {}
  live.set(live_view.to_bits(), true)

  phases.retain_live_views(live)

  debug_inspect(phases.len(), content="1")
  debug_inspect(phases.contains(live_view), content="true")
  debug_inspect(phases.contains(stale_view), content="false")
  debug_inspect(
    phases.phase(live_view).map(fn(phase) { phase.gpu_preprocessing_mode() }),
    content="Some(None)",
  )
}

///|
test "pbr: extract_wireframe_3d_camera prepares active camera phases" {
  let world = @ecs.World::new()
  let active_camera = world.spawn()
  let inactive_camera = world.spawn()
  let stale_view = @core.Entity::new(12, 1)
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  phases.prepare_for_new_frame(
    stale_view,
    @render_batching.GpuPreprocessingMode::Culling,
  )
  world.insert_resource(Wireframe3dPhases::resource(), phases)
  try! world.set_by_key(active_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    active_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(inactive_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    inactive_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )

  extract_wireframe_3d_camera_system(world)

  let phases = match world.get_resource(Wireframe3dPhases::resource()) {
    Some(value) => value
    None => abort("missing Wireframe3dPhases")
  }
  debug_inspect(phases.len(), content="1")
  debug_inspect(phases.contains(active_camera), content="true")
  debug_inspect(phases.contains(inactive_camera), content="false")
  debug_inspect(phases.contains(stale_view), content="false")
}

///|
test "pbr: wireframe wide bind groups keep vertex pull params by mesh asset" {
  let bind_groups = WireframeWideBindGroups::WireframeWideBindGroups()
  let offset = bind_groups.push(13, WireframeVertexPullParams::new(1U, 8U, 3U))
  debug_inspect(offset, content="0")
  debug_inspect(bind_groups.len(), content="1")
  debug_inspect(bind_groups.dynamic_offset(13), content="Some(0)")
  debug_inspect(
    bind_groups.params(0),
    content="Some({ index_offset: 1, vertex_stride_u32s: 8, position_offset_u32s: 3 })",
  )
  bind_groups.clear()
  debug_inspect(bind_groups.len(), content="0")
}

///|
test "pbr: wireframe draw function resource registers thin and wide commands" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  debug_inspect(draw_functions.len(), content="2")
  debug_inspect(draw_functions.thin().id(), content="0")
  debug_inspect(draw_functions.wide().id(), content="1")
}
