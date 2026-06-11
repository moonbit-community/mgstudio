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
