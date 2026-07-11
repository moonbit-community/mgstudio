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
fn wireframe_render_command_test_item(
  main_entity : @render.MainEntity,
) -> Wireframe3d {
  wireframe_render_command_test_item_with_extra_index(
    main_entity,
    WireframePhaseItemExtraIndex::dynamic_offset(0),
  )
}

///|
fn wireframe_render_command_test_item_with_extra_index(
  main_entity : @render.MainEntity,
  extra_index : WireframePhaseItemExtraIndex,
) -> Wireframe3d {
  wireframe_render_command_test_item_with_draw_function(
    main_entity,
    @material.DrawFunctionId::new(0U),
    extra_index,
  )
}

///|
fn wireframe_render_command_test_item_with_draw_function(
  main_entity : @render.MainEntity,
  draw_function : @material.DrawFunctionId,
  extra_index : WireframePhaseItemExtraIndex,
) -> Wireframe3d {
  Wireframe3d::new(
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(3UL),
      7,
      draw_function,
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    @core.Entity::new(20, 1),
    main_entity,
    Wireframe3dBatchRange::new(0, 1),
    extra_index,
  )
}

///|
fn wireframe_render_command_test_assets(
  main_entity : @render.MainEntity,
) -> (RenderWireframeInstances, RenderWireframeAssets) {
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 7)
  let assets = RenderWireframeAssets::RenderWireframeAssets()
  assets.insert(
    7,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(
        @color.Color::new(0.2F, 0.4F, 0.6F, 1.0F),
        2.0F,
        Triangles,
      ),
    ),
  )
  (instances, assets)
}

///|
fn wireframe_render_command_test_mesh_state(
  main_entity : @render.MainEntity,
  mesh_id : Int,
) -> (
  RenderMeshInstances,
  @render_mesh.RenderMeshAssets,
  @render_mesh.MeshAllocator,
) {
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(mesh_id, 0U, true),
  )
  let render_meshes = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=8,
    indexed=true,
    index_count=6,
  )
  render_meshes.insert(mesh_id, render_mesh)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(mesh_allocator.allocate_render_mesh(mesh_id, render_mesh, 80))
  (render_mesh_instances, render_meshes, mesh_allocator)
}

///|
test "pbr: thin wireframe immediates carry only material color" {
  let material = RenderWireframeMaterial::from_material(
    WireframeMaterial::new(
      @color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      7.0F,
      Quads,
    ),
  )
  let immediates = Wireframe3dThinImmediates::from_material(material)

  debug_inspect(immediates.float_count(), content="4")
  debug_inspect(immediates.color().r, content="0.25")
  debug_inspect(immediates.color().g, content="0.5")
  debug_inspect(immediates.color().b, content="0.75")
  let bytes = immediates.bytes()
  debug_inspect(bytes.length(), content="16")
  debug_inspect(bytes[12], content="0x00")
  debug_inspect(bytes[13], content="0x00")
  debug_inspect(bytes[14], content="0x80")
  debug_inspect(bytes[15], content="0x3f")
}

///|
test "pbr: wide wireframe immediates follow Bevy smoothing rule" {
  let thin_line = Wireframe3dWideImmediates::from_material(
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
    ),
  )
  let thick_line = Wireframe3dWideImmediates::from_material(
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 2.0F, Triangles),
    ),
  )

  debug_inspect(thin_line.float_count(), content="8")
  debug_inspect(thin_line.line_width(), content="1")
  debug_inspect(thin_line.smoothing(), content="0.5")
  debug_inspect(thick_line.line_width(), content="2")
  debug_inspect(thick_line.smoothing(), content="1")
  let bytes = thick_line.bytes()
  debug_inspect(bytes.length(), content="32")
  debug_inspect(bytes[28], content="0x00")
  debug_inspect(bytes[29], content="0x00")
  debug_inspect(bytes[30], content="0x00")
  debug_inspect(bytes[31], content="0x00")
}

///|
test "pbr: wireframe immediate commands resolve material by phase item" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item(main_entity)
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 7)
  let assets = RenderWireframeAssets::RenderWireframeAssets()
  assets.insert(
    7,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(
        @color.Color::new(0.2F, 0.4F, 0.6F, 1.0F),
        2.0F,
        Triangles,
      ),
    ),
  )

  let thin = set_wireframe_3d_thin_immediates(item, instances, assets)
  let wide = set_wireframe_3d_wide_immediates(item, instances, assets)

  debug_inspect(thin.color().r, content="0.20000000298023224")
  debug_inspect(wide.line_width(), content="2")
  debug_inspect(wide.smoothing(), content="1")
}

///|
test "pbr: wireframe immediate commands fail when material is missing" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item(main_entity)
  let missing_instance = Some(
    set_wireframe_3d_thin_immediates(
      item,
      RenderWireframeInstances::RenderWireframeInstances(),
      RenderWireframeAssets::RenderWireframeAssets(),
    ),
  ) catch {
    error => {
      debug_inspect(
        error is WireframeRenderCommandError::NoWireframeMaterialFoundForEntity,
        content="true",
      )
      None
    }
  }
  debug_inspect(missing_instance is None, content="true")
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 7)
  let missing_asset = Some(
    set_wireframe_3d_wide_immediates(
      item,
      instances,
      RenderWireframeAssets::RenderWireframeAssets(),
    ),
  ) catch {
    error => {
      debug_inspect(
        error is WireframeRenderCommandError::NoWireframeMaterialFoundForEntity,
        content="true",
      )
      None
    }
  }
  debug_inspect(missing_asset is None, content="true")
}

///|
test "pbr: wireframe vertex pull params preserve Bevy field order" {
  let params = WireframeVertexPullParams::new(3U, 8U, 1U)

  debug_inspect(
    params,
    content="{ index_offset: 3, vertex_stride_u32s: 8, position_offset_u32s: 1 }",
  )
  debug_inspect(params.index_offset(), content="3")
  debug_inspect(params.vertex_stride_u32s(), content="8")
  debug_inspect(params.position_offset_u32s(), content="1")
}

///|
test "pbr: wide wireframe bind group command returns dynamic offset" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item(main_entity)
  let render_mesh_instances = RenderMeshInstances::new()
  let bind_groups = WireframeWideBindGroups::WireframeWideBindGroups()
  debug_inspect(
    set_wireframe_3d_wide_bind_group_dynamic_offset(
      item, render_mesh_instances, bind_groups,
    ),
    content="None",
  )
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(13, 0U, true),
  )
  debug_inspect(
    set_wireframe_3d_wide_bind_group_dynamic_offset(
      item, render_mesh_instances, bind_groups,
    ),
    content="None",
  )
  ignore(bind_groups.push(13, WireframeVertexPullParams::new(0U, 20U, 0U)))
  debug_inspect(
    set_wireframe_3d_wide_bind_group_dynamic_offset(
      item, render_mesh_instances, bind_groups,
    ),
    content="Some(0)",
  )
}

///|
test "pbr: pulled wireframe direct draw range follows Bevy skip rules" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item(main_entity)
  let render_mesh_instances = RenderMeshInstances::new()
  let render_meshes = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  debug_inspect(
    draw_wireframe_mesh_pulled_direct_range(
      item, render_mesh_instances, render_meshes, mesh_allocator,
    ),
    content="None",
  )
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(13, 0U, true),
  )
  debug_inspect(
    draw_wireframe_mesh_pulled_direct_range(
      item, render_mesh_instances, render_meshes, mesh_allocator,
    ),
    content="None",
  )
  let indexed_mesh = @render_mesh.RenderMesh::new(
    vertex_count=8,
    indexed=true,
    index_count=6,
  )
  render_meshes.insert(13, indexed_mesh)
  debug_inspect(
    draw_wireframe_mesh_pulled_direct_range(
      item, render_mesh_instances, render_meshes, mesh_allocator,
    ),
    content="None",
  )
  ignore(mesh_allocator.allocate_render_mesh(13, indexed_mesh, 80))
  let indexed_range = draw_wireframe_mesh_pulled_direct_range(
    item, render_mesh_instances, render_meshes, mesh_allocator,
  ).unwrap()
  debug_inspect(indexed_range.first_vertex(), content="0")
  debug_inspect(indexed_range.vertex_end(), content="6")
  debug_inspect(indexed_range.batch_start(), content="0")
  debug_inspect(indexed_range.batch_end(), content="1")
}

///|
test "pbr: pulled wireframe direct draw range uses vertex count for non-indexed mesh" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item(main_entity)
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(17, 0U, true),
  )
  let render_mesh = @render_mesh.RenderMesh::new(vertex_count=5)
  let render_meshes = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_meshes.insert(17, render_mesh)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(mesh_allocator.allocate_render_mesh(17, render_mesh, 80))

  let range = draw_wireframe_mesh_pulled_direct_range(
    item, render_mesh_instances, render_meshes, mesh_allocator,
  ).unwrap()

  debug_inspect(range.first_vertex(), content="0")
  debug_inspect(range.vertex_end(), content="5")
}

///|
test "pbr: pulled wireframe indirect plan follows Bevy offsets" {
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let direct_item = wireframe_render_command_test_item(main_entity)
  debug_inspect(
    draw_wireframe_mesh_pulled_indirect_plan(direct_item),
    content="None",
  )
  let indirect_item = wireframe_render_command_test_item_with_extra_index(
    main_entity,
    WireframePhaseItemExtraIndex::indirect_parameters_index(2, 5),
  )
  let indirect_plan = draw_wireframe_mesh_pulled_indirect_plan(indirect_item).unwrap()
  debug_inspect(indirect_plan.indirect_parameters_offset(), content="32")
  debug_inspect(indirect_plan.indirect_parameters_count(), content="3")
  debug_inspect(indirect_plan.batch_set_count_offset(), content="None")
  let counted_item = wireframe_render_command_test_item_with_extra_index(
    main_entity,
    WireframePhaseItemExtraIndex::indirect_parameters_index(
      2,
      5,
      batch_set_index=Some(4),
    ),
  )
  let counted_plan = draw_wireframe_mesh_pulled_indirect_plan(counted_item).unwrap()
  debug_inspect(counted_plan.indirect_parameters_offset(), content="32")
  debug_inspect(counted_plan.indirect_parameters_count(), content="3")
  debug_inspect(counted_plan.batch_set_count_offset(), content="Some(32)")
}

///|
test "pbr: wireframe render command decision plans thin command tuple" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item_with_draw_function(
    main_entity,
    draw_functions.thin(),
    WireframePhaseItemExtraIndex::dynamic_offset(0),
  )
  let (instances, assets) = wireframe_render_command_test_assets(main_entity)
  let decision = wireframe_3d_render_command_decision(
    item,
    draw_functions,
    instances,
    assets,
    RenderMeshInstances::new(),
    @render_mesh.RenderMeshAssets::RenderMeshAssets(),
    @render_mesh.MeshAllocator::new(),
    WireframeWideBindGroups::WireframeWideBindGroups(),
  )

  guard decision is Planned(plan) else {
    abort("expected planned thin command")
  }
  debug_inspect(plan.kind() == Thin, content="true")
  debug_inspect(plan.pipeline().id(), content="3")
  debug_inspect(plan.thin_immediates() is Some(_), content="true")
  debug_inspect(plan.wide_immediates() is None, content="true")
}

///|
test "pbr: wireframe render command decision skips wide command without bind group" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item_with_draw_function(
    main_entity,
    draw_functions.wide(),
    WireframePhaseItemExtraIndex::dynamic_offset(0),
  )
  let (instances, assets) = wireframe_render_command_test_assets(main_entity)
  let (render_mesh_instances, render_meshes, mesh_allocator) = wireframe_render_command_test_mesh_state(
    main_entity, 13,
  )
  let decision = wireframe_3d_render_command_decision(
    item,
    draw_functions,
    instances,
    assets,
    render_mesh_instances,
    render_meshes,
    mesh_allocator,
    WireframeWideBindGroups::WireframeWideBindGroups(),
  )

  debug_inspect(decision is Skipped, content="true")
}

///|
test "pbr: wireframe render command decision plans wide pulled direct draw" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item_with_draw_function(
    main_entity,
    draw_functions.wide(),
    WireframePhaseItemExtraIndex::dynamic_offset(0),
  )
  let (instances, assets) = wireframe_render_command_test_assets(main_entity)
  let (render_mesh_instances, render_meshes, mesh_allocator) = wireframe_render_command_test_mesh_state(
    main_entity, 13,
  )
  let bind_groups = WireframeWideBindGroups::WireframeWideBindGroups()
  ignore(bind_groups.push(13, WireframeVertexPullParams::new(0U, 20U, 0U)))
  let decision = wireframe_3d_render_command_decision(
    item, draw_functions, instances, assets, render_mesh_instances, render_meshes,
    mesh_allocator, bind_groups,
  )

  guard decision is Planned(plan) else {
    abort("expected planned wide command")
  }
  debug_inspect(plan.kind() == Wide, content="true")
  debug_inspect(plan.wide_immediates().unwrap().line_width(), content="2")
  debug_inspect(plan.wide_bind_group_dynamic_offset(), content="Some(0)")
  debug_inspect(plan.wide_direct_range().unwrap().vertex_end(), content="6")
  debug_inspect(plan.wide_indirect_plan() is None, content="true")
}

///|
test "pbr: wireframe phase render command plans preserve item order and skips" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let phase = Wireframe3dViewPhase::new(
    @render_batching.GpuPreprocessingMode::None,
  )
  phase.add(
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(3UL),
      7,
      draw_functions.thin(),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (@core.Entity::new(20, 1), main_entity),
    0U,
    WireframeBinnedRenderPhaseType::mesh(
      true,
      @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
    ),
  )
  phase.add(
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(4UL),
      7,
      draw_functions.wide(),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (@core.Entity::new(21, 1), main_entity),
    1U,
    WireframeBinnedRenderPhaseType::mesh(
      true,
      @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
    ),
  )
  let (instances, assets) = wireframe_render_command_test_assets(main_entity)
  let (render_mesh_instances, render_meshes, mesh_allocator) = wireframe_render_command_test_mesh_state(
    main_entity, 13,
  )
  phase.prepare_cpu_buffers(render_mesh_instances)
  let plans = wireframe_3d_phase_render_command_plans(
    phase,
    draw_functions,
    instances,
    assets,
    render_mesh_instances,
    render_meshes,
    mesh_allocator,
    WireframeWideBindGroups::WireframeWideBindGroups(),
  )

  debug_inspect(plans.length(), content="1")
  debug_inspect(plans[0].kind() == Thin, content="true")
}

///|
test "pbr: wireframe render command decision fails unknown draw function" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let main_entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let item = wireframe_render_command_test_item_with_draw_function(
    main_entity,
    @material.DrawFunctionId::new(99U),
    WireframePhaseItemExtraIndex::dynamic_offset(0),
  )
  let (instances, assets) = wireframe_render_command_test_assets(main_entity)
  let ok = Some(
    wireframe_3d_render_command_decision(
      item,
      draw_functions,
      instances,
      assets,
      RenderMeshInstances::new(),
      @render_mesh.RenderMeshAssets::RenderMeshAssets(),
      @render_mesh.MeshAllocator::new(),
      WireframeWideBindGroups::WireframeWideBindGroups(),
    ),
  ) catch {
    error => {
      debug_inspect(
        error is WireframeRenderCommandError::UnknownWireframeDrawFunction,
        content="true",
      )
      None
    }
  }
  debug_inspect(ok is None, content="true")
}
