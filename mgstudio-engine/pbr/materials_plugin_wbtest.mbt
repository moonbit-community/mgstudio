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
extend ShadowReadinessNoShadowMaterial with @asset.Asset::{asset_debug_name}

///|
fn material_test_insert_gpu_preprocessing_support(world : @ecs.World) -> Unit {
  world.insert_resource(
    @render_batching.GpuPreprocessingSupport::resource(),
    @render_batching.GpuPreprocessingSupport::with_max_supported_mode(Culling),
  )
}

///|
test "render3d: materials startup initializes bevy material render resources" {
  let world = @ecs.World::new()
  defer world.close()

  init_materials_resources(world)

  debug_inspect(
    world.get_resource(ecs_key_entity_specialization_ticks) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_specialized_material_pipeline_cache) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@render_visibility.DirtySpecializations::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.LightKeyCache::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_render_material_instances) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_material_bind_group_allocators) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(PendingMeshMaterialQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.PendingShadowQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(Render3dShadowPhasesData::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    get_default_opaque_renderer_method_resource(world).is_present(),
    content="true",
  )
}

///|
test "render3d: materials startup preserves existing material render resources" {
  let world = @ecs.World::new()
  defer world.close()
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let entity = @core.Entity::new(12, 0)
  entity_ticks.insert(entity, EntitySpecializationTickPair::new(5, 6))
  world.insert_resource(ecs_key_entity_specialization_ticks, entity_ticks)

  init_materials_resources(world)

  match world.get_resource(ecs_key_entity_specialization_ticks) {
    Some(ticks) =>
      debug_inspect(
        ticks.get(entity).map(fn(pair) { pair.system_tick() }),
        content="Some(5)",
      )
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: materials startup preserves pending queue resources" {
  let world = @ecs.World::new()
  defer world.close()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(10, 1))
  let main_entity = @render.MainEntity::new(@core.Entity::new(11, 1))
  let mesh_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  mesh_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(1, 1),
    @render.MainEntity::new(@core.Entity::new(2, 1)),
  )
  let shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  shadow_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(3, 1),
    @render.MainEntity::new(@core.Entity::new(4, 1)),
  )
  world.insert_resource(PendingMeshMaterialQueues::resource(), mesh_queues)
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    shadow_queues,
  )
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  shadow_phases
  .view_or_insert(view)
  .add(
    Render3dShadowBatchSetKeyData::new(
      @material.CachedRenderPipelineId::new(901UL),
      @material.DrawFunctionId::new(9U),
      None,
      @render_mesh.MeshSlabs::new(4),
    ),
    Render3dShadowBinKeyData::new(5),
    (@core.Entity::new(12, 1), main_entity),
    7U,
    Render3dShadowBinnedRenderPhaseType::mesh(true, GpuPreprocessingSupport()),
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)

  init_materials_resources(world)

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) => {
      debug_inspect(phases.len(), content="1")
      match phases.get(view) {
        Some(phase) => {
          debug_inspect(phase.len(), content="1")
          debug_inspect(
            phase.input_uniform_index(main_entity),
            content="Some(InputUniformIndex(7))",
          )
        }
        None => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: batchable shadow phase merges contiguous Bevy batch ranges" {
  let phase = Render3dShadowViewPhaseData::new(None)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(901UL),
    @material.DrawFunctionId::new(9U),
    Some(4),
    @render_mesh.MeshSlabs::new(7, index_slab_id=Some(8)),
  )
  let bin = Render3dShadowBinKeyData::new(77)
  let first_main = @render.MainEntity::new(@core.Entity::new(31, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(32, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(41, 1), first_main),
    14U,
    BatchableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(42, 1), second_main),
    15U,
    BatchableMesh,
  )
  debug_inspect(phase.len(), content="1")
  let item = phase.items()[0]
  inspect(item.batch_range().start(), content="14")
  inspect(item.batch_range().end(), content="16")
  debug_inspect(item.extra_index(), content="None")
  debug_inspect(
    phase.input_uniform_index(first_main),
    content="Some(InputUniformIndex(14))",
  )
  debug_inspect(
    phase.input_uniform_index(second_main),
    content="Some(InputUniformIndex(15))",
  )
  let phase_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let phase_indirect = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  phase.prepare_batchable_phase_buffers(
    "shadow-resolve-view", true, false, phase_instances, phase_indirect,
  )
  inspect(phase.items()[0].batch_range().start(), content="0")
  inspect(phase.items()[0].batch_range().end(), content="2")
  let meshes = [
    ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(first_main.id()),
      payload: material_test_extracted_mesh_payload(77, MaterialProperties()),
    },
    {
      entity: phase_entity_ref3d_for_main(second_main.id()),
      payload: material_test_extracted_mesh_payload(77, MaterialProperties()),
    },
  ]
  let resolved = render3d_shadow_resolve_phase_items(meshes, phase)
  debug_inspect(resolved.length(), content="2")
  debug_inspect(
    render3d_resolved_shadow_phase_draw_count(resolved),
    content="2",
  )
  debug_inspect(resolved[0].extracted_indices.length(), content="1")
  debug_inspect(resolved[1].extracted_indices.length(), content="1")
}

///|
test "render3d: shadow phase resolve keeps Bevy mesh bins isolated" {
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(902UL),
    @material.DrawFunctionId::new(10U),
    Some(5),
    @render_mesh.MeshSlabs::new(17, index_slab_id=Some(18)),
  )
  let first_main = @render.MainEntity::new(@core.Entity::new(51, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(52, 1))
  let phase = Render3dShadowViewPhaseData::new(None)
  phase.add(
    key,
    Render3dShadowBinKeyData::new(77),
    (@core.Entity::new(61, 1), first_main),
    14U,
    BatchableMesh,
  )
  let meshes = [
    ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(first_main.id()),
      payload: material_test_extracted_mesh_payload(77, MaterialProperties()),
    },
    {
      entity: phase_entity_ref3d_for_main(second_main.id()),
      payload: material_test_extracted_mesh_payload(78, MaterialProperties()),
    },
  ]
  let resolved = render3d_shadow_resolve_phase_items(meshes, phase)
  debug_inspect(resolved.length(), content="1")
  debug_inspect(
    render3d_resolved_shadow_phase_draw_count(resolved),
    content="1",
  )
  debug_inspect(resolved[0].extracted_indices.length(), content="1")
  inspect(resolved[0].extracted_indices[0], content="0")
}

///|
test "render3d: batchable shadow phase prepares Bevy work item buffers" {
  let phase = Render3dShadowViewPhaseData::new(None)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(905UL),
    @material.DrawFunctionId::new(13U),
    Some(10),
    @render_mesh.MeshSlabs::new(41, index_slab_id=Some(42)),
  )
  let bin = Render3dShadowBinKeyData::new(808)
  let first_main = @render.MainEntity::new(@core.Entity::new(121, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(122, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(131, 1), first_main),
    70U,
    BatchableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(132, 1), second_main),
    71U,
    BatchableMesh,
  )
  let direct_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let direct_indirect = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  phase.prepare_batchable_phase_buffers(
    "shadow-view", true, false, direct_instances, direct_indirect,
  )
  debug_inspect(direct_instances.buffers.data_buffer.len(), content="2")
  let direct_work_items = direct_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(direct_work_items.direct_len(), content="2")
  inspect(phase.items()[0].batch_range().start(), content="0")
  inspect(phase.items()[0].batch_range().end(), content="2")
  debug_inspect(phase.items()[0].extra_index(), content="None")

  let indirect_phase = Render3dShadowViewPhaseData::new(None)
  indirect_phase.add(
    key,
    bin,
    (@core.Entity::new(133, 1), first_main),
    80U,
    BatchableMesh,
  )
  indirect_phase.add(
    key,
    bin,
    (@core.Entity::new(134, 1), second_main),
    81U,
    BatchableMesh,
  )
  let indirect_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let indirect_parameters = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  indirect_phase.prepare_batchable_phase_buffers(
    "shadow-view", false, false, indirect_instances, indirect_parameters,
  )
  let indirect_work_items = indirect_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(indirect_work_items.indexed_len(), content="2")
  debug_inspect(indirect_parameters.buffers.batch_count(true), content="1")
  debug_inspect(indirect_parameters.buffers.batch_set_count(true), content="1")
  inspect(indirect_phase.items()[0].batch_range().start(), content="0")
  inspect(indirect_phase.items()[0].batch_range().end(), content="2")
  debug_inspect(
    indirect_phase.items()[0].extra_index(),
    content="IndirectParametersIndex(0, 1, None)",
  )
}

///|
test "render3d: shadow unbatchable index set mirrors Bevy sparse and dense states" {
  let sparse = Render3dShadowUnbatchableBinnedEntityIndexSet::new()
  sparse.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      4,
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
  sparse.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      5,
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
  debug_inspect(sparse.len(), content="2")
  debug_inspect(
    sparse
    .indices_for_entity_index(0)
    .map(fn(indices) { indices.instance_index() }),
    content="Some(4)",
  )
  debug_inspect(
    sparse
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.extra_index() }),
    content="Some(None)",
  )
  sparse.clear()
  debug_inspect(sparse.len(), content="0")

  let indirect = Render3dShadowUnbatchableBinnedEntityIndexSet::new()
  indirect.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      8,
      Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(20, 21),
    ),
  )
  indirect.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      9,
      Render3dShadowPhaseItemExtraIndex::indirect_parameters_index(21, 22),
    ),
  )
  debug_inspect(indirect.len(), content="2")
  debug_inspect(
    indirect
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.extra_index() }),
    content="Some(IndirectParametersIndex(21, 22, None))",
  )

  let dense = Render3dShadowUnbatchableBinnedEntityIndexSet::new()
  dense.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      10,
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
  dense.add(
    Render3dShadowUnbatchableBinnedEntityIndices::new(
      12,
      Render3dShadowPhaseItemExtraIndex::none(),
    ),
  )
  debug_inspect(dense.len(), content="2")
  debug_inspect(
    dense
    .indices_for_entity_index(0)
    .map(fn(indices) { indices.instance_index() }),
    content="Some(10)",
  )
  debug_inspect(
    dense
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.instance_index() }),
    content="Some(12)",
  )
}

///|
test "render3d: shadow view phase stores unbatchable meshes separately" {
  let phase = Render3dShadowViewPhaseData::new(None)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(902UL),
    @material.DrawFunctionId::new(10U),
    None,
    @render_mesh.MeshSlabs::new(11, index_slab_id=Some(12)),
  )
  let bin = Render3dShadowBinKeyData::new(88)
  let first_main = @render.MainEntity::new(@core.Entity::new(51, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(52, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(61, 1), first_main),
    30U,
    UnbatchableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(62, 1), second_main),
    31U,
    UnbatchableMesh,
  )
  debug_inspect(phase.len(), content="2")
  debug_inspect(phase.phase_type(first_main), content="Some(UnbatchableMesh)")
  let items = phase.items()
  debug_inspect(items.length(), content="2")
  inspect(items[0].batch_range().start(), content="30")
  inspect(items[0].batch_range().end(), content="31")
  inspect(items[1].batch_range().start(), content="31")
  inspect(items[1].batch_range().end(), content="32")
  phase.remove(first_main)
  debug_inspect(phase.len(), content="1")
  debug_inspect(phase.input_uniform_index(first_main), content="None")
  debug_inspect(
    phase.input_uniform_index(second_main),
    content="Some(InputUniformIndex(31))",
  )
  debug_inspect(
    phase.items()[0].main_entity(),
    content="{ entity: { id: 52, generation: 1 } }",
  )
  phase.prepare_for_new_frame()
  debug_inspect(phase.len(), content="0")
  debug_inspect(phase.items().length(), content="0")
  debug_inspect(
    phase.input_uniform_index(second_main),
    content="Some(InputUniformIndex(31))",
  )
  debug_inspect(phase.phase_type(second_main), content="Some(UnbatchableMesh)")
}

///|
test "render3d: unbatchable shadow phase prepares Bevy work item buffers" {
  let phase = Render3dShadowViewPhaseData::new(None)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(906UL),
    @material.DrawFunctionId::new(14U),
    None,
    @render_mesh.MeshSlabs::new(51, index_slab_id=Some(52)),
  )
  let bin = Render3dShadowBinKeyData::new(909)
  let first_main = @render.MainEntity::new(@core.Entity::new(141, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(142, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(151, 1), first_main),
    90U,
    UnbatchableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(152, 1), second_main),
    92U,
    UnbatchableMesh,
  )
  let direct_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let direct_indirect = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  phase.prepare_unbatchable_phase_buffers(
    "shadow-view", true, false, direct_instances, direct_indirect,
  )
  let direct_work_items = direct_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(direct_work_items.direct_len(), content="2")
  let direct_items = phase.items()
  inspect(direct_items[0].batch_range().start(), content="0")
  inspect(direct_items[1].batch_range().start(), content="1")
  debug_inspect(direct_items[0].extra_index(), content="None")

  let indirect_phase = Render3dShadowViewPhaseData::new(None)
  indirect_phase.add(
    key,
    bin,
    (@core.Entity::new(153, 1), first_main),
    100U,
    UnbatchableMesh,
  )
  indirect_phase.add(
    key,
    bin,
    (@core.Entity::new(154, 1), second_main),
    101U,
    UnbatchableMesh,
  )
  let indirect_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let indirect_parameters = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  indirect_phase.prepare_unbatchable_phase_buffers(
    "shadow-view", false, false, indirect_instances, indirect_parameters,
  )
  let indirect_work_items = indirect_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(indirect_work_items.indexed_len(), content="2")
  debug_inspect(indirect_parameters.buffers.batch_count(true), content="2")
  debug_inspect(indirect_parameters.buffers.batch_set_count(true), content="2")
  let indirect_items = indirect_phase.items()
  debug_inspect(
    indirect_items[0].extra_index(),
    content="IndirectParametersIndex(0, 1, None)",
  )
  debug_inspect(
    indirect_items[1].extra_index(),
    content="IndirectParametersIndex(1, 2, None)",
  )
}

///|
test "render3d: shadow multidraw batch set mirrors Bevy packed bin offsets" {
  let batch_set : Render3dShadowMultidrawableBatchSetData = @render_phase.RenderMultidrawableBatchSet::new()
  let first_bin = Render3dShadowBinKeyData::new(101)
  let second_bin = Render3dShadowBinKeyData::new(202)
  let first = @render.MainEntity::new(@core.Entity::new(71, 1))
  let second = @render.MainEntity::new(@core.Entity::new(72, 1))
  let third = @render.MainEntity::new(@core.Entity::new(73, 1))
  let bin_zero = @render_phase.RenderBinIndex::new(0U)
  let bin_one = @render_phase.RenderBinIndex::new(1U)
  batch_set.insert(first_bin, first, @render_phase.InputUniformIndex::new(10U))
  batch_set.insert(
    second_bin,
    second,
    @render_phase.InputUniformIndex::new(20U),
  )
  batch_set.insert(second_bin, third, @render_phase.InputUniformIndex::new(21U))
  debug_inspect(batch_set.bin_count(), content="2")
  debug_inspect(batch_set.cpu_instance_count(), content="3")
  debug_inspect(batch_set.indirect_parameter_count(), content="2")
  debug_inspect(
    batch_set.bin_index(first_bin),
    content="Some(RenderBinIndex(0))",
  )
  debug_inspect(
    batch_set.bin_index(second_bin),
    content="Some(RenderBinIndex(1))",
  )
  debug_inspect(
    batch_set.indirect_parameters_offset_for_bin(bin_zero),
    content="Some(0)",
  )
  debug_inspect(
    batch_set.indirect_parameters_offset_for_bin(bin_one),
    content="Some(1)",
  )
  batch_set.remove(second, second_bin)
  debug_inspect(batch_set.bin_count(), content="2")
  debug_inspect(batch_set.cpu_instance_count(), content="2")
  debug_inspect(
    batch_set.cpu_instance_at(1).map(fn(instance) { instance.main_entity() }),
    content="Some({ entity: { id: 73, generation: 1 } })",
  )
  batch_set.remove(first, first_bin)
  debug_inspect(batch_set.bin_count(), content="1")
  debug_inspect(batch_set.bin_index(first_bin), content="None")
  debug_inspect(
    batch_set.bin_index(second_bin),
    content="Some(RenderBinIndex(1))",
  )
  debug_inspect(
    batch_set.indirect_parameters_offset_for_bin(bin_one),
    content="Some(0)",
  )
  debug_inspect(batch_set.indirect_parameter_count(), content="1")
  let fourth = @render.MainEntity::new(@core.Entity::new(74, 1))
  let reused_bin = Render3dShadowBinKeyData::new(303)
  batch_set.insert(
    reused_bin,
    fourth,
    @render_phase.InputUniformIndex::new(30U),
  )
  debug_inspect(
    batch_set.bin_index(reused_bin),
    content="Some(RenderBinIndex(0))",
  )
  debug_inspect(
    batch_set.indirect_parameters_offset_for_bin(bin_zero),
    content="Some(1)",
  )
  debug_inspect(batch_set.indirect_parameter_count(), content="2")
}

///|
test "panic render3d: shadow multidraw removal rejects a missing bin key" {
  let batch_set : Render3dShadowMultidrawableBatchSetData = @render_phase.RenderMultidrawableBatchSet::new()
  batch_set.remove(
    @render.MainEntity::new(@core.Entity::new(75, 1)),
    Render3dShadowBinKeyData::new(404),
  )
}

///|
test "panic render3d: shadow multidraw removal rejects a missing entity" {
  let batch_set : Render3dShadowMultidrawableBatchSetData = @render_phase.RenderMultidrawableBatchSet::new()
  let bin = Render3dShadowBinKeyData::new(405)
  batch_set.insert(
    bin,
    @render.MainEntity::new(@core.Entity::new(76, 1)),
    @render_phase.InputUniformIndex::new(31U),
  )
  batch_set.remove(@render.MainEntity::new(@core.Entity::new(77, 1)), bin)
}

///|
test "render3d: shadow view phase routes multidrawable meshes to batch sets" {
  let phase = Render3dShadowViewPhaseData::new(Culling)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(903UL),
    @material.DrawFunctionId::new(11U),
    Some(5),
    @render_mesh.MeshSlabs::new(21, index_slab_id=Some(22)),
  )
  let first_bin = Render3dShadowBinKeyData::new(404)
  let second_bin = Render3dShadowBinKeyData::new(505)
  let first_main = @render.MainEntity::new(@core.Entity::new(81, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(82, 1))
  phase.add(
    key,
    first_bin,
    (@core.Entity::new(91, 1), first_main),
    40U,
    MultidrawableMesh,
  )
  phase.add(
    key,
    second_bin,
    (@core.Entity::new(92, 1), second_main),
    41U,
    MultidrawableMesh,
  )
  debug_inspect(phase.len(), content="2")
  debug_inspect(phase.items().length(), content="0")
  debug_inspect(phase.multidrawable_batch_set_count(), content="1")
  debug_inspect(phase.multidrawable_cpu_instance_count(), content="2")
  debug_inspect(phase.phase_type(first_main), content="Some(MultidrawableMesh)")
  phase.remove(first_main)
  debug_inspect(phase.len(), content="1")
  debug_inspect(phase.multidrawable_batch_set_count(), content="1")
  debug_inspect(phase.multidrawable_cpu_instance_count(), content="1")
  debug_inspect(phase.input_uniform_index(first_main), content="None")
  debug_inspect(
    phase.input_uniform_index(second_main),
    content="Some(InputUniformIndex(41))",
  )
  phase.prepare_for_new_frame()
  debug_inspect(phase.len(), content="1")
  debug_inspect(phase.multidrawable_batch_set_count(), content="1")

  let preprocessing_only_phase = Render3dShadowViewPhaseData::new(
    PreprocessingOnly,
  )
  preprocessing_only_phase.add(
    key,
    first_bin,
    (@core.Entity::new(93, 1), first_main),
    50U,
    MultidrawableMesh,
  )
  debug_inspect(
    preprocessing_only_phase.multidrawable_batch_set_count(),
    content="0",
  )
  debug_inspect(preprocessing_only_phase.items().length(), content="1")
  debug_inspect(
    preprocessing_only_phase.phase_type(first_main),
    content="Some(BatchableMesh)",
  )
}

///|
test "render3d: shadow view phase removes only the cached multidraw bin" {
  let phase = Render3dShadowViewPhaseData::new(Culling)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(913UL),
    @material.DrawFunctionId::new(19U),
    Some(9),
    @render_mesh.MeshSlabs::new(71, index_slab_id=Some(72)),
  )
  let retained_main = @render.MainEntity::new(@core.Entity::new(181, 1))
  let removed_main = @render.MainEntity::new(@core.Entity::new(182, 1))
  phase.add(
    key,
    Render3dShadowBinKeyData::new(701),
    (@core.Entity::new(191, 1), retained_main),
    120U,
    MultidrawableMesh,
  )
  phase.add(
    key,
    Render3dShadowBinKeyData::new(702),
    (@core.Entity::new(192, 1), removed_main),
    121U,
    MultidrawableMesh,
  )

  phase.remove(removed_main)

  debug_inspect(phase.multidrawable_batch_set_count(), content="1")
  debug_inspect(phase.multidrawable_cpu_instance_count(), content="1")
  debug_inspect(phase.phase_type(removed_main), content="None")
  debug_inspect(
    phase.input_uniform_index(retained_main),
    content="Some(InputUniformIndex(120))",
  )
  debug_inspect(
    phase.phase_type(retained_main),
    content="Some(MultidrawableMesh)",
  )
}

///|
test "render3d: shadow multidraw batch sets materialize Bevy indirect phase items" {
  let phase = Render3dShadowViewPhaseData::new(Culling)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(904UL),
    @material.DrawFunctionId::new(12U),
    Some(6),
    @render_mesh.MeshSlabs::new(31, index_slab_id=Some(32)),
  )
  let bin = Render3dShadowBinKeyData::new(606)
  let first_main = @render.MainEntity::new(@core.Entity::new(101, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(102, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(111, 1), first_main),
    60U,
    MultidrawableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(112, 1), second_main),
    61U,
    MultidrawableMesh,
  )
  let items_without_count = phase.multidrawable_items(false)
  debug_inspect(items_without_count.length(), content="1")
  let item_without_count = items_without_count[0]
  inspect(item_without_count.batch_range().start(), content="60")
  inspect(item_without_count.batch_range().end(), content="62")
  debug_inspect(
    item_without_count.extra_index(),
    content="IndirectParametersIndex(0, 2, None)",
  )
  inspect(item_without_count.batch_set_key().pipeline_id().id(), content="904")
  inspect(item_without_count.bin_key().mesh_asset_id(), content="606")
  let items_with_count = phase.multidrawable_items(true)
  debug_inspect(items_with_count.length(), content="1")
  debug_inspect(
    items_with_count[0].extra_index(),
    content="IndirectParametersIndex(0, 2, Some(0))",
  )
}

///|
test "render3d: multidrawable shadow phase prepares Bevy indirect buffers" {
  let phase = Render3dShadowViewPhaseData::new(Culling)
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(906UL),
    @material.DrawFunctionId::new(14U),
    Some(7),
    @render_mesh.MeshSlabs::new(33, index_slab_id=Some(34)),
  )
  let bin = Render3dShadowBinKeyData::new(707)
  let first_main = @render.MainEntity::new(@core.Entity::new(141, 1))
  let second_main = @render.MainEntity::new(@core.Entity::new(142, 1))
  phase.add(
    key,
    bin,
    (@core.Entity::new(151, 1), first_main),
    90U,
    MultidrawableMesh,
  )
  phase.add(
    key,
    bin,
    (@core.Entity::new(152, 1), second_main),
    91U,
    MultidrawableMesh,
  )
  let phase_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let indirect_parameters = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  let batch_sets = phase.prepare_multidrawable_phase_buffers(
    "shadow-view", false, true, phase_instances, indirect_parameters,
  )
  let work_items = phase_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(batch_sets.length(), content="1")
  debug_inspect(phase_instances.buffers.data_buffer.len(), content="2")
  debug_inspect(work_items.indexed_len(), content="2")
  debug_inspect(work_items.non_indexed_len(), content="0")
  debug_inspect(work_items.late_indexed_len(), content="2")
  debug_inspect(indirect_parameters.buffers.batch_count(true), content="1")
  debug_inspect(indirect_parameters.buffers.batch_set_count(true), content="1")
  debug_inspect(indirect_parameters.buffers.cpu_metadata_len(true), content="1")
  debug_inspect(indirect_parameters.buffers.gpu_metadata_len(true), content="1")
  debug_inspect(
    indirect_parameters.buffers
    .cpu_metadata_at(true, 0)
    .unwrap()
    .base_output_index(),
    content="0",
  )
  debug_inspect(
    indirect_parameters.buffers
    .cpu_metadata_at(true, 0)
    .unwrap()
    .batch_set_index(),
    content="0",
  )
  inspect(batch_sets[0].first_batch().instance_range().start(), content="0")
  inspect(batch_sets[0].first_batch().instance_range().end(), content="2")
  debug_inspect(batch_sets[0].first_work_item_index(), content="0")
  debug_inspect(batch_sets[0].batch_count(), content="1")
  debug_inspect(
    batch_sets[0].first_batch().extra_index(),
    content="IndirectParametersIndex(0, 1, None)",
  )
}

///|
test "render3d: shadow phase prepares all binned mesh classes with one work buffer" {
  let phase = Render3dShadowViewPhaseData::new(Culling)
  let unbatchable_key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(910UL),
    @material.DrawFunctionId::new(18U),
    Some(9),
    @render_mesh.MeshSlabs::new(40, index_slab_id=Some(41)),
  )
  let batchable_key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(911UL),
    @material.DrawFunctionId::new(19U),
    Some(10),
    @render_mesh.MeshSlabs::new(42, index_slab_id=Some(43)),
  )
  let multidraw_key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(912UL),
    @material.DrawFunctionId::new(20U),
    Some(11),
    @render_mesh.MeshSlabs::new(44, index_slab_id=Some(45)),
  )
  phase.add(
    unbatchable_key,
    Render3dShadowBinKeyData::new(710),
    (
      @core.Entity::new(161, 1),
      @render.MainEntity::new(@core.Entity::new(151, 1)),
    ),
    10U,
    UnbatchableMesh,
  )
  phase.add(
    batchable_key,
    Render3dShadowBinKeyData::new(711),
    (
      @core.Entity::new(162, 1),
      @render.MainEntity::new(@core.Entity::new(152, 1)),
    ),
    20U,
    BatchableMesh,
  )
  phase.add(
    batchable_key,
    Render3dShadowBinKeyData::new(711),
    (
      @core.Entity::new(163, 1),
      @render.MainEntity::new(@core.Entity::new(153, 1)),
    ),
    21U,
    BatchableMesh,
  )
  phase.add(
    multidraw_key,
    Render3dShadowBinKeyData::new(712),
    (
      @core.Entity::new(164, 1),
      @render.MainEntity::new(@core.Entity::new(154, 1)),
    ),
    30U,
    MultidrawableMesh,
  )
  phase.add(
    multidraw_key,
    Render3dShadowBinKeyData::new(712),
    (
      @core.Entity::new(165, 1),
      @render.MainEntity::new(@core.Entity::new(155, 1)),
    ),
    31U,
    MultidrawableMesh,
  )
  let phase_instances : @render_batching.PhaseBatchedInstanceBuffers[Unit] = @render_batching.PhaseBatchedInstanceBuffers::new()
  let indirect_parameters = @render_batching.PhaseIndirectParametersBuffers::new(
    false,
  )
  let multidraw_batch_sets = phase.prepare_phase_buffers(
    "shadow-view", false, true, phase_instances, indirect_parameters,
  )
  let work_items = phase_instances.buffers.work_item_buffers
    .get("shadow-view")
    .unwrap()
  debug_inspect(phase_instances.buffers.data_buffer.len(), content="5")
  debug_inspect(work_items.indexed_len(), content="5")
  debug_inspect(work_items.late_indexed_len(), content="5")
  debug_inspect(indirect_parameters.buffers.batch_count(true), content="3")
  debug_inspect(indirect_parameters.buffers.batch_set_count(true), content="3")
  debug_inspect(multidraw_batch_sets.length(), content="1")
  debug_inspect(phase.items().length(), content="2")
  debug_inspect(phase.multidrawable_items(false).length(), content="1")
}

///|
test "render3d: shadow phase buffer prepare system consumes phase resource" {
  let world = @ecs.World::new()
  defer world.close()
  let phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(301, 1),
  )
  let phase = phases.prepare_for_new_frame(
    retained_view,
    gpu_preprocessing_mode=Culling,
  )
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(913UL),
    @material.DrawFunctionId::new(21U),
    Some(12),
    @render_mesh.MeshSlabs::new(46, index_slab_id=Some(47)),
  )
  phase.add(
    key,
    Render3dShadowBinKeyData::new(713),
    (
      @core.Entity::new(166, 1),
      @render.MainEntity::new(@core.Entity::new(156, 1)),
    ),
    40U,
    BatchableMesh,
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), phases)
  world.insert_resource(
    Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    Render3dShadowPhaseBatchedInstanceBuffers(),
  )
  world.insert_resource(
    Render3dShadowPhaseIndirectParametersBuffers::resource(),
    Render3dShadowPhaseIndirectParametersBuffers(),
  )
  world.insert_resource(
    @render_batching.GpuPreprocessingSupport::resource(),
    @render_batching.GpuPreprocessingSupport::with_max_supported_mode(Culling),
  )
  render3d_prepare_shadow_phase_buffers_system(world)
  let phase_instances = world
    .get_resource(Render3dShadowPhaseBatchedInstanceBuffers::resource())
    .unwrap()
  let phase_indirect = world
    .get_resource(Render3dShadowPhaseIndirectParametersBuffers::resource())
    .unwrap()
  debug_inspect(phase_instances.buffers.buffers.data_buffer.len(), content="1")
  debug_inspect(phase_indirect.buffers.buffers.batch_count(true), content="1")
  debug_inspect(
    phase_indirect.buffers.buffers.batch_set_count(true),
    content="1",
  )
}

///|
test "render3d: shadow phase buffers collect into global preprocessing tables" {
  let world = @ecs.World::new()
  defer world.close()
  let phase_instances = Render3dShadowPhaseBatchedInstanceBuffers::Render3dShadowPhaseBatchedInstanceBuffers()
  phase_instances.buffers.buffers.data_buffer.push(())
  let phase_indirect = Render3dShadowPhaseIndirectParametersBuffers::Render3dShadowPhaseIndirectParametersBuffers()
  ignore(phase_indirect.buffers.buffers.allocate(true, 2))
  phase_indirect.buffers.buffers.add_batch_set(true, 0)
  world.insert_resource(
    Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    phase_instances,
  )
  world.insert_resource(
    Render3dShadowPhaseIndirectParametersBuffers::resource(),
    phase_indirect,
  )
  world.insert_resource(
    RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
    RenderMeshInstanceGpuBatchedInstanceBuffers(),
  )
  world.insert_resource(
    @render_batching.IndirectParametersBuffers::resource(),
    IndirectParametersBuffers(),
  )
  world.insert_resource(
    @render_batching.IndirectParametersBuffersSettings::resource(),
    IndirectParametersBuffersSettings(),
  )
  render3d_collect_shadow_phase_buffers_system(world)
  let global_instances = world
    .get_resource(RenderMeshInstanceGpuBatchedInstanceBuffers::resource())
    .unwrap()
  let global_indirect = world
    .get_resource(@render_batching.IndirectParametersBuffers::resource())
    .unwrap()
  let retained_phase_instances = global_instances.buffers.phase_instance_buffers
    .get("mgstudio_pbr::Shadow")
    .unwrap()
  debug_inspect(retained_phase_instances.buffers.data_buffer.len(), content="1")
  debug_inspect(global_indirect.phase_count(), content="1")
  debug_inspect(
    global_indirect.get("mgstudio_pbr::Shadow").unwrap().batch_count(true),
    content="2",
  )
  debug_inspect(
    global_indirect.get("mgstudio_pbr::Shadow").unwrap().batch_set_count(true),
    content="1",
  )
  let refreshed_phase_instances = world
    .get_resource(Render3dShadowPhaseBatchedInstanceBuffers::resource())
    .unwrap()
  debug_inspect(
    refreshed_phase_instances.buffers.buffers.data_buffer.len(),
    content="0",
  )
}

///|
test "render3d: shadow phase prepare and collect bridge fills global preprocessing tables" {
  let world = @ecs.World::new()
  defer world.close()
  let phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(302, 1),
  )
  let phase = phases.prepare_for_new_frame(
    retained_view,
    gpu_preprocessing_mode=Culling,
  )
  let key = Render3dShadowBatchSetKeyData::new(
    @material.CachedRenderPipelineId::new(914UL),
    @material.DrawFunctionId::new(22U),
    Some(13),
    @render_mesh.MeshSlabs::new(48, index_slab_id=Some(49)),
  )
  phase.add(
    key,
    Render3dShadowBinKeyData::new(714),
    (
      @core.Entity::new(167, 1),
      @render.MainEntity::new(@core.Entity::new(157, 1)),
    ),
    41U,
    BatchableMesh,
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), phases)
  world.insert_resource(
    Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    Render3dShadowPhaseBatchedInstanceBuffers(),
  )
  world.insert_resource(
    Render3dShadowPhaseIndirectParametersBuffers::resource(),
    Render3dShadowPhaseIndirectParametersBuffers(),
  )
  world.insert_resource(
    @render_batching.GpuPreprocessingSupport::resource(),
    @render_batching.GpuPreprocessingSupport::with_max_supported_mode(Culling),
  )
  world.insert_resource(
    RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
    RenderMeshInstanceGpuBatchedInstanceBuffers(),
  )
  world.insert_resource(
    @render_batching.IndirectParametersBuffers::resource(),
    IndirectParametersBuffers(),
  )
  world.insert_resource(
    @render_batching.IndirectParametersBuffersSettings::resource(),
    IndirectParametersBuffersSettings(),
  )
  render3d_prepare_shadow_phase_buffers_system(world)
  render3d_collect_shadow_phase_buffers_system(world)
  let global_instances = world
    .get_resource(RenderMeshInstanceGpuBatchedInstanceBuffers::resource())
    .unwrap()
  let global_indirect = world
    .get_resource(@render_batching.IndirectParametersBuffers::resource())
    .unwrap()
  debug_inspect(
    global_instances.buffers.phase_instance_buffers
    .get("mgstudio_pbr::Shadow")
    .unwrap().buffers.data_buffer.len(),
    content="1",
  )
  debug_inspect(global_indirect.phase_count(), content="1")
  debug_inspect(
    global_indirect.get("mgstudio_pbr::Shadow").unwrap().batch_count(true),
    content="1",
  )
  let phase_instances = world
    .get_resource(Render3dShadowPhaseBatchedInstanceBuffers::resource())
    .unwrap()
  debug_inspect(phase_instances.buffers.buffers.data_buffer.len(), content="0")
}

///|
test "render3d: shadow phase preparation mirrors Bevy retained light views" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = @core.Entity::new(201, 1)
  let extracted_retained_view = @render_view.RetainedViewEntity::new(
    camera,
    auxiliary_entity=Some(@core.Entity::new(202, 1)),
    subview_index=9,
  )
  let directional = Render3dLightEntity::Directional(
    light_entity=@core.Entity::new(210, 1),
    main_entity=@core.Entity::new(210, 1),
    cascade_index=2,
  )
  let point = Render3dLightEntity::Point(
    light_entity=@core.Entity::new(211, 1),
    main_entity=@core.Entity::new(211, 1),
    face_index=5,
  )
  let spot = Render3dLightEntity::Spot(
    light_entity=@core.Entity::new(212, 1),
    main_entity=@core.Entity::new(212, 1),
  )
  let directional_view = directional.shadow_phase_retained_view(
    extracted_retained_view,
  )
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(299, 1),
  )
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  shadow_phases
  .prepare_for_new_frame(directional_view)
  .add(
    Render3dShadowBatchSetKeyData::new(
      @material.CachedRenderPipelineId::new(77UL),
      @material.DrawFunctionId::new(7U),
      None,
      @render_mesh.MeshSlabs::new(4),
    ),
    Render3dShadowBinKeyData::new(5),
    (
      @core.Entity::new(213, 1),
      @render.MainEntity::new(@core.Entity::new(214, 1)),
    ),
    8U,
    Render3dShadowBinnedRenderPhaseType::mesh(true, GpuPreprocessingSupport()),
  )
  ignore(shadow_phases.prepare_for_new_frame(stale_view))
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)
  material_test_insert_gpu_preprocessing_support(world)
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  pending_shadow_queues
  .queues()
  .push_current(
    directional_view,
    @core.Entity::new(215, 1),
    @render.MainEntity::new(@core.Entity::new(216, 1)),
  )
  pending_shadow_queues
  .queues()
  .push_current(
    stale_view,
    @core.Entity::new(217, 1),
    @render.MainEntity::new(@core.Entity::new(218, 1)),
  )
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )

  let live_views = render3d_prepare_shadow_phase_views(
    world,
    extracted_retained_view,
    [directional, point, spot],
  )

  debug_inspect(live_views.length(), content="3")
  debug_inspect(live_views.contains(directional_view), content="true")
  debug_inspect(
    live_views.contains(
      point.shadow_phase_retained_view(extracted_retained_view),
    ),
    content="true",
  )
  debug_inspect(
    live_views.contains(
      spot.shadow_phase_retained_view(extracted_retained_view),
    ),
    content="true",
  )
  match world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) => {
      debug_inspect(phases.len(), content="3")
      debug_inspect(phases.get(stale_view) is None, content="true")
      match phases.get(directional_view) {
        Some(phase) => debug_inspect(phase.len(), content="1")
        None => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) => {
      debug_inspect(
        queues.queues().contains_view(directional_view),
        content="true",
      )
      debug_inspect(queues.queues().prev_len(directional_view), content="0")
      debug_inspect(queues.queues().current_len(directional_view), content="1")
      debug_inspect(queues.queues().contains_view(stale_view), content="true")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: camera shadow phase preparation retains all Bevy light views once" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_a = @core.Entity::new(301, 1)
  let camera_b = @core.Entity::new(302, 1)
  let directional_light = @core.Entity::new(310, 1)
  let point_light = @core.Entity::new(311, 1)
  let spot_light = @core.Entity::new(312, 1)
  let cascades = @light.Cascades::Cascades()
  for camera in [camera_a, camera_b] {
    cascades.set(camera, [
      @light.Cascade::new(
        @math.Mat4::identity(),
        @math.Mat4::identity(),
        @math.Mat4::identity(),
        0.25F,
      ),
    ])
  }
  let lighting = Render3dLightingState::{
    ..@pbr_render.render3d_default_lighting_state(),
    directional_lights: [
      {
        render_entity: directional_light,
        light: @pbr_render.render3d_extracted_directional_light_for_shadow(
          directional_light,
          @transform.Transform::identity(),
          cascades,
          [42.0F],
          RenderLayers(),
          false,
        ),
      },
    ],
    point_entity: Some(point_light),
    point_render_entity: Some(point_light),
    point_range: 12.0F,
    point_shadow_maps_enabled: true,
    spot_entity: Some(spot_light),
    spot_render_entity: Some(spot_light),
    spot_range: 12.0F,
    spot_shadow_maps_enabled: true,
  }
  let cameras = [
    ExtractedCamera3d::{
      entity: phase_entity_ref3d_for_main(camera_a),
      payload: material_test_camera_payload(),
    },
    {
      entity: phase_entity_ref3d_for_main(camera_b),
      payload: material_test_camera_payload(),
    },
  ]
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(399, 1),
  )
  ignore(shadow_phases.prepare_for_new_frame(stale_view))
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)
  material_test_insert_gpu_preprocessing_support(world)
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  let point_face_zero_view = Render3dLightEntity::Point(
    light_entity=point_light,
    main_entity=point_light,
    face_index=0,
  ).shadow_phase_retained_view(@render_view.RetainedViewEntity::new(camera_a))
  pending_shadow_queues
  .queues()
  .push_current(
    point_face_zero_view,
    @core.Entity::new(313, 1),
    @render.MainEntity::new(@core.Entity::new(314, 1)),
  )
  pending_shadow_queues
  .queues()
  .push_current(
    stale_view,
    @core.Entity::new(315, 1),
    @render.MainEntity::new(@core.Entity::new(316, 1)),
  )
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )

  let live_views = render3d_prepare_shadow_phase_views_for_cameras(
    world, cameras, lighting, 1024,
  )

  let directional_a = Render3dLightEntity::Directional(
    light_entity=directional_light,
    main_entity=directional_light,
    cascade_index=0,
  ).shadow_phase_retained_view(@render_view.RetainedViewEntity::new(camera_a))
  let directional_b = Render3dLightEntity::Directional(
    light_entity=directional_light,
    main_entity=directional_light,
    cascade_index=0,
  ).shadow_phase_retained_view(@render_view.RetainedViewEntity::new(camera_b))
  debug_inspect(live_views.length(), content="9")
  debug_inspect(live_views.contains(directional_a), content="true")
  debug_inspect(live_views.contains(directional_b), content="true")
  debug_inspect(live_views.contains(point_face_zero_view), content="true")
  match world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) => {
      debug_inspect(phases.len(), content="9")
      debug_inspect(phases.get(stale_view) is None, content="true")
      debug_inspect(phases.get(directional_a) is Some(_), content="true")
      debug_inspect(phases.get(directional_b) is Some(_), content="true")
    }
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) => {
      debug_inspect(queues.queues().prev_len(point_face_zero_view), content="0")
      debug_inspect(
        queues.queues().current_len(point_face_zero_view),
        content="1",
      )
      debug_inspect(queues.queues().contains_view(stale_view), content="true")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: shadow visible indices mirror Bevy CPU visibility filters" {
  let material_properties = @material.MaterialProperties::MaterialProperties()
  let camera_layers = @camera_render_layers.RenderLayers::layer(1)
  let normal_mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d(
      @core.Entity::new(2101, 1),
      @core.Entity::new(2201, 1),
    ),
    payload: {
      ..material_test_extracted_mesh_payload(2101, material_properties),
      layers: @camera_render_layers.RenderLayers::layer(1),
      has_no_frustum_culling: true,
    },
  }
  let non_shadow_caster = ExtractedMesh3d::{
    entity: phase_entity_ref3d(
      @core.Entity::new(2102, 1),
      @core.Entity::new(2202, 1),
    ),
    payload: {
      ..material_test_extracted_mesh_payload(2102, material_properties),
      layers: @camera_render_layers.RenderLayers::layer(1),
      has_not_shadow_caster: true,
      has_no_frustum_culling: true,
    },
  }
  let no_cpu_culling_mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d(
      @core.Entity::new(2103, 1),
      @core.Entity::new(2203, 1),
    ),
    payload: {
      ..material_test_extracted_mesh_payload(2103, material_properties),
      layers: @camera_render_layers.RenderLayers::layer(1),
      has_no_cpu_culling: true,
      has_no_frustum_culling: true,
    },
  }
  let wrong_layer_mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d(
      @core.Entity::new(2104, 1),
      @core.Entity::new(2204, 1),
    ),
    payload: {
      ..material_test_extracted_mesh_payload(2104, material_properties),
      layers: @camera_render_layers.RenderLayers::layer(2),
      has_no_frustum_culling: true,
    },
  }
  let second_visible_mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d(
      @core.Entity::new(2105, 1),
      @core.Entity::new(2205, 1),
    ),
    payload: {
      ..material_test_extracted_mesh_payload(0, material_properties),
      layers: @camera_render_layers.RenderLayers::layer(1),
      has_no_frustum_culling: true,
    },
  }
  let visible = render3d_shadow_visible_extracted_indices(
    [
      normal_mesh, non_shadow_caster, no_cpu_culling_mesh, wrong_layer_mesh, second_visible_mesh,
    ],
    camera_layers,
    [],
  )
  debug_inspect(visible.length(), content="2")
  debug_inspect(visible[0], content="0")
  debug_inspect(visible[1], content="4")
}

///|
test "render3d: shadow visible indices populate Bevy shadow map visibility" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = @core.Entity::new(401, 1)
  let point_light = world.spawn_empty()
  let point_light_main = world.spawn_empty()
  let light_entity = Render3dLightEntity::Point(
    light_entity=point_light,
    main_entity=point_light_main,
    face_index=2,
  )
  let camera_retained_view = @render_view.RetainedViewEntity::new(camera)
  let shadow_phase_view = light_entity.shadow_phase_retained_view(
    camera_retained_view,
  )
  let visible_retained_view = light_entity.shadow_map_visible_retained_view(
    shadow_phase_view,
  )
  let material_properties = @material.MaterialProperties::MaterialProperties()
  let first_main = @core.Entity::new(402, 1)
  let first_render = @core.Entity::new(403, 1)
  let second_main = @core.Entity::new(404, 1)
  let second_render = @core.Entity::new(405, 1)
  let meshes = [
    ExtractedMesh3d::{
      entity: phase_entity_ref3d(first_main, first_render),
      payload: material_test_extracted_mesh_payload(901, material_properties),
    },
    {
      entity: phase_entity_ref3d(second_main, second_render),
      payload: material_test_extracted_mesh_payload(902, material_properties),
    },
  ]

  render3d_update_shadow_map_visible_entities(
    world,
    light_entity,
    shadow_phase_view,
    meshes,
    [1, -1, 0, 99],
  )

  match
    (try! world.get_by_key(
      point_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    )) {
    Some(shadow_visible) =>
      match shadow_visible.subview(visible_retained_view) {
        Some(visible_entities) =>
          match visible_entities.get(render3d_mesh_visibility_class()) {
            Some(mesh_visible) => {
              inspect(
                visible_retained_view.main_entity().id,
                content=point_light_main.id.to_string(),
              )
              inspect(
                light_entity.shadow_map_visible_entity().id,
                content=point_light.id.to_string(),
              )
              debug_inspect(mesh_visible.added_entities().length(), content="2")
              inspect(
                mesh_visible.added_entities()[0].0.id,
                content=first_render.id.to_string(),
              )
              inspect(
                mesh_visible.added_entities()[1].0.id,
                content=second_render.id.to_string(),
              )
              render3d_update_shadow_map_visible_entities(
                world,
                light_entity,
                shadow_phase_view,
                meshes,
                [0],
              )
              match
                (try! world.get_by_key(
                  point_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
                )) {
                Some(updated_shadow_visible) =>
                  match updated_shadow_visible.subview(visible_retained_view) {
                    Some(updated_visible_entities) =>
                      match
                        updated_visible_entities.get(
                          render3d_mesh_visibility_class(),
                        ) {
                        Some(updated_mesh_visible) => {
                          debug_inspect(
                            updated_mesh_visible.added_entities().length(),
                            content="0",
                          )
                          debug_inspect(
                            updated_mesh_visible.removed_entities().length(),
                            content="1",
                          )
                          inspect(
                            updated_mesh_visible.removed_entities()[0].0.id,
                            content=second_render.id.to_string(),
                          )
                        }
                        None => debug_inspect(false, content="true")
                      }
                    None => debug_inspect(false, content="true")
                  }
                None => debug_inspect(false, content="true")
              }
            }
            None => debug_inspect(false, content="true")
          }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }
  debug_inspect(
    (try! world.get_by_key(
      point_light_main, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    ))
    is None,
    content="true",
  )
}

///|
test "render3d: pending mesh material queues prepare live views and expire stale views" {
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(30, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(31, 1),
  )
  let queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  queues
  .queues()
  .push_current(
    live_view,
    @core.Entity::new(32, 1),
    @render.MainEntity::new(@core.Entity::new(33, 1)),
  )
  queues
  .queues()
  .push_current(
    stale_view,
    @core.Entity::new(34, 1),
    @render.MainEntity::new(@core.Entity::new(35, 1)),
  )

  ignore(queues.prepare_for_new_frame(live_view))
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = HashSet([])
  live_views.add(live_view)
  queues.expire_stale_views(live_views)

  debug_inspect(queues.current_len(live_view), content="0")
  debug_inspect(queues.prev_len(live_view), content="1")
  debug_inspect(queues.current_len(stale_view), content="0")
  debug_inspect(queues.prev_len(stale_view), content="0")
  debug_inspect(queues.view_len(), content="1")
}

///|
fn material_test_pair_contains(
  pairs : Array[(@core.Entity, @render.MainEntity)],
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Bool {
  for pair in pairs {
    if pair.0 == render_entity && pair.1 == @render.MainEntity::new(main_entity) {
      return true
    }
  }
  false
}

///|
fn material_test_base_specialize(
  _world : @ecs.World,
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  @material.CachedRenderPipelineId::new(901UL)
}

///|
fn material_test_resource_key_base_specialize(
  _world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  let bits = key.mesh_key().bits()
  if (bits & MESH_PIPELINE_KEY_LIGHTMAPPED) != 0UL &&
    (bits & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING) != 0UL &&
    (bits & MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER) != 0UL {
    @material.CachedRenderPipelineId::new(902UL)
  } else {
    @material.CachedRenderPipelineId::new(901UL)
  }
}

///|
fn material_test_type_tag_base_specialize(
  _world : @ecs.World,
  key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  if key.type_tag() == "mgstudio_pbr_test::CustomResolvedMaterial" {
    @material.CachedRenderPipelineId::new(903UL)
  } else {
    @material.CachedRenderPipelineId::new(901UL)
  }
}

///|
fn material_test_camera_payload() -> Camera3dViewPayload {
  {
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    camera: Camera(),
    depth_texture_usages: Camera3dDepthTextureUsage(),
    depth_load_op: Camera3dDepthLoadOp::default(),
    projection: Projection::default(),
    sub_camera_view: None,
    oit_settings: None,
    screen_space_transmission: None,
    bloom: None,
    tonemapping: None,
    deband_dither: None,
    chromatic_aberration: None,
    contrast_adaptive_sharpening: None,
    custom_post_process3d: None,
    vignette: None,
    motion_blur: None,
    exposure: None,
    color_grading: None,
    environment_map_light: None,
    generated_environment_map_light: None,
    atmosphere_environment_map_light: None,
    has_environment_light_probes: false,
    irradiance_volume: None,
    screen_space_ambient_occlusion: None,
    screen_space_reflections: None,
    contact_shadows: None,
    depth_prepass_enabled: false,
    normal_prepass_enabled: false,
    deferred_prepass_enabled: false,
    no_indirect_drawing: false,
    gpu_occlusion_culling_enabled: false,
    hdr_enabled: false,
    fxaa: None,
    temporal_jitter: None,
    temporal_anti_aliasing: None,
    shadow_filtering_method: None,
    motion_vector_prepass_enabled: false,
    msaa: None,
    transform: Transform(),
    previous_transform: Transform(),
    previous_clip_from_world: None,
    target_id: 0,
    target_size: @math.IVec2::new(1280, 720),
    scale_factor: 1.0F,
    layers: RenderLayers(),
    invert_culling: false,
  }
}

///|
fn material_test_extracted_mesh_payload(
  mesh_id : Int,
  material_properties : @material.MaterialProperties,
) -> Mesh3dExtractedPayload {
  let transform = @transform.Transform::identity()
  let world_from_local = @math.Affine3::identity()
  {
    mesh_handle: @asset.Handle::new(mesh_id),
    world_from_local,
    previous_world_from_local: world_from_local,
    transform,
    previous_transform: transform,
    aabb: None,
    material_draw_data: Standard(StandardMaterial()),
    material_extension: None,
    material_properties,
    material_bind_group_data: MaterialBindGroupResolvedData(),
    lightmap: None,
    is_forward_decal: false,
    forward_decal_material_ext: None,
    clustered_decal: None,
    has_not_shadow_caster: false,
    has_not_shadow_receiver: false,
    has_transmitted_shadow_receiver: false,
    has_no_frustum_culling: false,
    has_no_cpu_culling: false,
    layers: RenderLayers(),
    skinning_key_hi: -1,
    has_previous_skin: false,
    morph_weights_index: -1,
    previous_morph_weights_index: -1,
    morph_targets_texture_id: -1,
    instance_vertex_buffer_id: -1,
  }
}

///|
test "render3d: extract render visible entities mirrors camera visible Mesh3d pairs" {
  let world = @ecs.World::new()
  defer world.close()
  let main_camera = world.spawn()
  let render_camera = world.spawn()
  let main_mesh = world.spawn()
  let render_mesh = world.spawn()
  try! world.set_by_key(main_camera, ecs_key_camera3d, Camera3d())
  try! world.set_by_key(main_camera, @camera_camera.ecs_key_camera, Camera())
  try! world.set_by_key(
    main_camera,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_camera),
  )
  try! world.set_by_key(
    main_mesh,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_mesh),
  )
  let visible = @camera_camera.VisibleEntities::VisibleEntities()
  visible.push(main_mesh, @mesh.ecs_key_mesh3d.id())
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, visible,
  )

  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="1")
          debug_inspect(mesh_visible.added_entities().length(), content="1")
          debug_inspect(mesh_visible.removed_entities().length(), content="0")
          debug_inspect(
            mesh_visible.entity_pair_is_visible(
              render_mesh,
              @render.MainEntity::new(main_mesh),
            ),
            content="true",
          )
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }

  let no_visible_meshes = @camera_camera.VisibleEntities::VisibleEntities()
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, no_visible_meshes,
  )
  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="0")
          debug_inspect(mesh_visible.added_entities().length(), content="0")
          debug_inspect(mesh_visible.removed_entities().length(), content="1")
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization candidates come from visible dirty and pending meshes" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = @core.Entity::new(41, 1)
  let render_view = world.spawn()
  let unchanged_main = @core.Entity::new(42, 1)
  let unchanged_render = @core.Entity::new(43, 1)
  let changed_main = @core.Entity::new(44, 1)
  let changed_render = @core.Entity::new(45, 1)
  let pending_main = @core.Entity::new(46, 1)
  let pending_render = @core.Entity::new(47, 1)
  let added_main = @core.Entity::new(48, 1)
  let added_render = @core.Entity::new(49, 1)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
  ])
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
    (added_render, @render.MainEntity::new(added_main)),
  ])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(@render.MainEntity::new(changed_main))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  pending_queues
  .queues()
  .push_current(
    retained_view,
    pending_render,
    @render.MainEntity::new(pending_main),
  )
  ignore(pending_queues.prepare_for_new_frame(retained_view))

  let candidates = render3d_material_specialization_candidates(
    world, render_view, retained_view, dirty_specializations, pending_queues,
  )

  debug_inspect(candidates.length(), content="3")
  debug_inspect(
    material_test_pair_contains(candidates, added_render, added_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, changed_render, changed_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, pending_render, pending_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, unchanged_render, unchanged_main),
    content="false",
  )
}

///|
test "render3d: view key cache marks material views dirty when pipeline capabilities change" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = @core.Entity::new(410, 1)
  let render_view = world.spawn()
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    DirtySpecializations(),
  )
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d(main_view, render_view),
    payload: material_test_camera_payload(),
  }

  render3d_check_views_need_specialization(world, [camera], false, true)
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  let view_key_cache = world.get_resource(ViewKeyCache::resource()).unwrap()
  debug_inspect(view_key_cache.len(), content="1")
  debug_inspect(
    view_key_cache.get(retained_view).unwrap().bits() ==
    render3d_camera_mesh_pipeline_view_key_bits(camera.payload),
    content="true",
  )
  let dirty = world
    .get_resource(@render_visibility.DirtySpecializations::resource())
    .unwrap()
  debug_inspect(
    dirty.must_wipe_specializations_for_view(retained_view),
    content="true",
  )

  dirty.clear()
  render3d_check_views_need_specialization(world, [camera], false, true)
  debug_inspect(
    dirty.must_wipe_specializations_for_view(retained_view),
    content="false",
  )

  render3d_check_views_need_specialization(world, [camera], true, true)
  debug_inspect(
    dirty.must_wipe_specializations_for_view(retained_view),
    content="true",
  )
}

///|
test "render3d: shadow specialization candidates come from visible dirty and pending meshes" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = @core.Entity::new(451, 1)
  let shadow_light = world.spawn()
  let camera_retained_view = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(460, 1)),
    subview_index=7,
  )
  let light_entity = Render3dLightEntity::Spot(
    light_entity=shadow_light,
    main_entity=shadow_light,
  )
  let retained_view = light_entity.shadow_phase_retained_view(
    camera_retained_view,
  )
  let shadow_visible_view = light_entity.shadow_map_visible_retained_view(
    retained_view,
  )
  let unchanged_main = @core.Entity::new(452, 1)
  let unchanged_render = @core.Entity::new(453, 1)
  let changed_main = @core.Entity::new(454, 1)
  let changed_render = @core.Entity::new(455, 1)
  let pending_main = @core.Entity::new(456, 1)
  let pending_render = @core.Entity::new(457, 1)
  let added_main = @core.Entity::new(458, 1)
  let added_render = @core.Entity::new(459, 1)
  let shadow_map_visible_entities = @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities()
  let visible_entities = shadow_map_visible_entities.subview_or_insert(
    shadow_visible_view,
  )
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
  ])
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
    (added_render, @render.MainEntity::new(added_main)),
  ])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    shadow_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    shadow_map_visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(@render.MainEntity::new(changed_main))
  let pending_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  pending_queues
  .queues()
  .push_current(
    retained_view,
    pending_render,
    @render.MainEntity::new(pending_main),
  )
  ignore(pending_queues.queues().prepare_for_new_frame(retained_view))

  let candidates = render3d_shadow_specialization_candidates_for_light(
    world, light_entity, retained_view, dirty_specializations, pending_queues,
  )

  debug_inspect(candidates.length(), content="3")
  debug_inspect(
    material_test_pair_contains(candidates, added_render, added_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, changed_render, changed_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, pending_render, pending_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, unchanged_render, unchanged_main),
    content="false",
  )
}

///|
test "render3d: shadow specialization skips cached entities before readiness checks" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(461, 1),
  )
  let shadow_light = world.spawn()
  let light_entity = Render3dLightEntity::Spot(
    light_entity=shadow_light,
    main_entity=shadow_light,
  )
  let retained_view = light_entity.shadow_phase_retained_view(
    camera_retained_view,
  )
  let render_entity = @core.Entity::new(462, 1)
  let visible_entity = @render.MainEntity::new(@core.Entity::new(463, 1))
  let shadow_map_visible_entities = @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities()
  let visible_entities = shadow_map_visible_entities.subview_or_insert(
    light_entity.shadow_map_visible_retained_view(retained_view),
  )
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([(render_entity, visible_entity)])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    shadow_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    shadow_map_visible_entities,
  )
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    DirtySpecializations(),
  )
  let light_key_cache = @pbr_render.LightKeyCache::LightKeyCache()
  light_key_cache.insert(
    retained_view,
    @material.ErasedMeshPipelineKey::new(137438953476UL, "MeshPipelineKey"),
  )
  world.insert_resource(@pbr_render.LightKeyCache::resource(), light_key_cache)
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    retained_view,
    visible_entity,
    @material.CachedRenderPipelineId::new(321UL),
    @material.DrawFunctionId::new(44U),
  )
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  ignore(
    shadow_phases.prepare_for_new_frame(
      retained_view,
      gpu_preprocessing_mode=PreprocessingOnly,
    ),
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)

  let work_items : Array[Render3dShadowSpecializationWorkItemData] = []
  let specialized = render3d_specialize_shadow_phase_for_light(
    world, light_entity, retained_view, work_items,
  )

  debug_inspect(specialized, content="true")
  debug_inspect(work_items.length(), content="0")
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(retained_view), content="0")
    None => debug_inspect(false, content="true")
  }
  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(cache) else {
    abort("missing shadow cache")
  }
  inspect(
    cache.pipeline_id(retained_view, visible_entity).unwrap().id(),
    content="321",
  )
}

///|
test "render3d: shadow depth clip control support mirrors render device features" {
  let empty_world = @ecs.World::new()
  defer empty_world.close()
  debug_inspect(
    render3d_shadow_depth_clip_control_supported(empty_world),
    content="false",
  )
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let requested_features : Array[UInt] = []
  if adapter.supports_known_rust_features_u64(@wgpu.FEATURES_DEPTH_CLIP_CONTROL) {
    requested_features.push(@wgpu.FEATURE_NAME_DEPTH_CLIP_CONTROL)
  }
  let device = adapter.request_device_sync_with_features_and_limits(
    instance, requested_features,
  )
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(@render.render_device_resource_key, render_device)
  let expected = render_device.supports_rust_features_u64(
    @wgpu.FEATURES_DEPTH_CLIP_CONTROL,
  )
  debug_inspect(
    render3d_shadow_depth_clip_control_supported(world) == expected,
    content="true",
  )
}

///|
test "render3d: missing material specialization mesh returns to pending queue" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(50, 1),
  )
  let render_entity = @core.Entity::new(51, 1)
  let main_entity = @render.MainEntity::new(@core.Entity::new(52, 1))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  ignore(pending_queues.prepare_for_new_frame(retained_view))
  world.insert_resource(PendingMeshMaterialQueues::resource(), pending_queues)

  render3d_enqueue_pending_mesh_material(
    world, retained_view, render_entity, main_entity,
  )

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) => {
      debug_inspect(queues.current_len(retained_view), content="1")
      debug_inspect(queues.prev_len(retained_view), content="0")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization readiness follows Bevy resources" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(53, 1),
  )
  let render_entity = @core.Entity::new(54, 1)
  let missing_material = @render.MainEntity::new(@core.Entity::new(55, 1))
  let missing_mesh = @render.MainEntity::new(@core.Entity::new(56, 1))
  let ready = @render.MainEntity::new(@core.Entity::new(57, 1))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  ignore(pending_queues.prepare_for_new_frame(retained_view))
  world.insert_resource(PendingMeshMaterialQueues::resource(), pending_queues)
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    missing_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(560)),
  )
  material_instances.extract_mesh_material(
    ready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(570)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_instances = RenderMeshInstances::new()
  let ready_flags = RenderMeshInstanceFlags::has_previous_skin().or(
    RenderMeshInstanceFlags::has_previous_morph(),
  )
  mesh_instances.insert(
    ready,
    RenderMeshQueueData::new(570, 0U, true, flags=ready_flags),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)

  let missing_material_ready = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, missing_material,
  )
  let missing_mesh_ready = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, missing_mesh,
  )
  let ready_value = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, ready,
  ).unwrap()

  debug_inspect(missing_material_ready is None, content="true")
  debug_inspect(missing_mesh_ready is None, content="true")
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::has_previous_morph()),
    content="true",
  )
  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.current_len(retained_view), content="2")
    None => debug_inspect(false, content="true")
  }
}

///|
struct ShadowReadinessNoShadowMaterial {}

///|
#warnings("-unnecessary_annotation")
fn ShadowReadinessNoShadowMaterial::ShadowReadinessNoShadowMaterial() -> ShadowReadinessNoShadowMaterial {
  ShadowReadinessNoShadowMaterial::{  }
}

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_debug_name() {
  "mgstudio_pbr_test::ShadowReadinessNoShadowMaterial"
}

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_as_image(
  _self,
) {
  None
}

///|
let shadow_readiness_no_shadow_material_asset_keys : @asset.AssetResourceKeys[
  ShadowReadinessNoShadowMaterial,
] = @asset.register_asset_resource_keys(
  ShadowReadinessNoShadowMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_resource_keys() {
  shadow_readiness_no_shadow_material_asset_keys
}

///|
let shadow_readiness_no_shadow_material_keys : MaterialKeys[
  ShadowReadinessNoShadowMaterial,
] = register_material_keys(ShadowReadinessNoShadowMaterial::asset_debug_name())

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_debug_name() {
  "mgstudio_pbr_test::ShadowReadinessNoShadowMaterial"
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_keys() {
  shadow_readiness_no_shadow_material_keys
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn prepass_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn deferred_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn register_shader_sources() {
  material_default_register_shader_sources()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn alpha_mode(self) {
  ignore(self)
  material_default_alpha_mode()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn opaque_render_method(
  self,
) {
  ignore(self)
  material_default_opaque_render_method()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn depth_bias(self) {
  ignore(self)
  material_default_depth_bias()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn reads_view_transmission_texture(
  self,
) {
  ignore(self)
  material_default_reads_view_transmission_texture()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn draw_data(self) {
  ignore(self)
  material_default_draw_data()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_extension_metadata(
  self,
) {
  ignore(self)
  None
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn enable_prepass() {
  material_default_enable_prepass()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn enable_shadows() {
  false
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bindless_supported(
  render_device,
) {
  material_default_bindless_supported(render_device)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bindless_slot_count() {
  material_default_bindless_slot_count()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bind_group(
  self,
  context,
) {
  ignore(context)
  ignore(self)
  MaterialBindGroup()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bind_group_layout_descriptor(
  self,
  context,
) {
  material_default_bind_group_layout_descriptor(self, context~)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bind_group_data(self) {
  material_default_bind_group_data(self)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn renderer_extra_bind_group_data(
  self,
  context,
) {
  material_default_renderer_extra_bind_group_data(self, context)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_key(self) {
  material_default_material_key(self)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  material_default_specialize(descriptor, layout, key)
}

///|
test "render3d: shadow specialization readiness follows Bevy pending queue rules" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial()
    },
  )
  let no_shadow_plugin : MaterialPlugin[ShadowReadinessNoShadowMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ShadowReadinessNoShadowMaterial()
    },
  )
  let lifecycle_world_2571_0 = @ecs.World::new()
  defer lifecycle_world_2571_0.close()
  let app = @app.App::new(lifecycle_world_2571_0)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
    .add_plugins(no_shadow_plugin)
  let world = app.sub_app(RenderApp).world()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(58, 1),
  )
  let render_entity = @core.Entity::new(59, 1)
  let missing_material = @render.MainEntity::new(world.spawn_empty())
  let missing_mesh = @render.MainEntity::new(world.spawn_empty())
  let missing_prepared = @render.MainEntity::new(world.spawn_empty())
  let no_shadows = @render.MainEntity::new(world.spawn_empty())
  let missing_render_mesh = @render.MainEntity::new(world.spawn_empty())
  let ready = @render.MainEntity::new(world.spawn_empty())
  let standard_ready = @render.MainEntity::new(world.spawn_empty())
  let non_shadow_caster = @render.MainEntity::new(world.spawn_empty())
  let source_world = @render.render_source_world(world)
  let standard_material_handle = {
    let key : @ecs.ResourceKey[@asset.Assets[StandardMaterial]] = @asset.assets_resource_key()
    if source_world.get_resource(key) is None {
      source_world.insert_resource(key, @asset.Assets::new())
    }
    match source_world.get_resource_mut(key) {
      Some(assets) =>
        assets.modify(fn(store) {
          store.add(StandardMaterial::from_color(@color.Color::white()))
        })
      None => abort("missing StandardMaterial assets resource")
    }
  }
  let shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  let view_pending_shadow_queues = shadow_queues
    .queues()
    .prepare_for_new_frame(retained_view)
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    shadow_queues,
  )
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let no_shadow_material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ShadowReadinessNoShadowMaterial],
  ] = MeshMaterial3dTyped::component()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let no_shadow_prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ShadowReadinessNoShadowMaterial]],
  ] = @render.RenderAssets::resource()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let pipeline = material_pipeline_from_material_hooks(probe)
  let no_shadow_probe : @asset.Handle[ShadowReadinessNoShadowMaterial] = @asset.Handle::new(
    0,
  )
  let no_shadow_pipeline = material_pipeline_from_material_hooks(
    no_shadow_probe,
  )
  let prepared_assets = match world.get_resource_mut(prepared_assets_key) {
    Some(value) => value
    None => abort("missing PreparedMaterial render assets")
  }
  let no_shadow_prepared_assets = match
    world.get_resource_mut(no_shadow_prepared_assets_key) {
    Some(value) => value
    None => abort("missing no-shadow PreparedMaterial render assets")
  }
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    missing_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(610)),
  )
  material_instances.extract_mesh_material(
    missing_prepared.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(620)),
  )
  material_instances.extract_mesh_material(
    no_shadows.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(630)),
  )
  material_instances.extract_mesh_material(
    missing_render_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(635)),
  )
  material_instances.extract_mesh_material(
    ready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(640)),
  )
  material_instances.extract_mesh_material(
    standard_ready.id(),
    true,
    MeshMaterial3d::new(standard_material_handle),
  )
  material_instances.extract_mesh_material(
    non_shadow_caster.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(650)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  try! world.set_by_key(
    missing_prepared.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(620)),
  )
  try! world.set_by_key(
    no_shadows.id(),
    no_shadow_material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(630)),
  )
  try! world.set_by_key(
    ready.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(640)),
  )
  try! world.set_by_key(
    missing_render_mesh.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(635)),
  )
  try! world.set_by_key(
    non_shadow_caster.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(650)),
  )
  prepared_assets.modify(fn(value) {
    value.insert(
      635,
      PreparedMaterial::from_material(
        @asset.Handle::new(635),
        ParityCustomMaterial(),
        pipeline,
        Forward,
      ),
    )
    value.insert(
      640,
      PreparedMaterial::from_material(
        @asset.Handle::new(640),
        ParityCustomMaterial(),
        pipeline,
        Forward,
      ),
    )
    value.insert(
      650,
      PreparedMaterial::from_material(
        @asset.Handle::new(650),
        ParityCustomMaterial(),
        pipeline,
        Forward,
      ),
    )
  })
  no_shadow_prepared_assets.modify(fn(value) {
    value.insert(
      630,
      PreparedMaterial::from_material(
        @asset.Handle::new(630),
        ShadowReadinessNoShadowMaterial(),
        no_shadow_pipeline,
        Forward,
      ),
    )
  })
  let resolved_slots = RenderMaterial3dResolvedSlots::new()
  resolved_slots.set_resolved(
    no_shadows.id(),
    PreparedMaterial::from_material(
      @asset.Handle::new(630),
      ShadowReadinessNoShadowMaterial::ShadowReadinessNoShadowMaterial(),
      no_shadow_pipeline,
      Forward,
    ).resolved_material(),
  )
  resolved_slots.set_resolved(
    missing_render_mesh.id(),
    PreparedMaterial::from_material(
      @asset.Handle::new(635),
      ParityCustomMaterial::ParityCustomMaterial(),
      pipeline,
      Forward,
    ).resolved_material(),
  )
  resolved_slots.set_resolved(
    ready.id(),
    PreparedMaterial::from_material(
      @asset.Handle::new(640),
      ParityCustomMaterial::ParityCustomMaterial(),
      pipeline,
      Forward,
    ).resolved_material(),
  )
  resolved_slots.set_resolved(
    non_shadow_caster.id(),
    PreparedMaterial::from_material(
      @asset.Handle::new(650),
      ParityCustomMaterial::ParityCustomMaterial(),
      pipeline,
      Forward,
    ).resolved_material(),
  )
  world.insert_resource(
    RenderMaterial3dResolvedSlots::resource(),
    resolved_slots,
  )
  let mesh_instances = RenderMeshInstances::new()
  let ready_flags = RenderMeshInstanceFlags::shadow_caster()
  mesh_instances.insert(
    missing_prepared,
    RenderMeshQueueData::new(620, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    no_shadows,
    RenderMeshQueueData::new(630, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    missing_render_mesh,
    RenderMeshQueueData::new(635, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    ready,
    RenderMeshQueueData::new(640, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    standard_ready,
    RenderMeshQueueData::new(
      standard_material_handle.id(),
      0U,
      true,
      flags=ready_flags,
    ),
  )
  mesh_instances.insert(
    non_shadow_caster,
    RenderMeshQueueData::new(650, 0U, true),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    640,
    @render_mesh.RenderMesh::new(
      vertex_count=3,
      key_bits=@mesh.BaseMeshPipelineKey::new(32UL),
    ),
  )
  render_mesh_assets.insert(
    standard_material_handle.id(),
    @render_mesh.RenderMesh::new(
      vertex_count=3,
      key_bits=@mesh.BaseMeshPipelineKey::new(64UL),
    ),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )

  let missing_material_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_material, view_pending_shadow_queues,
  )
  let missing_mesh_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_mesh, view_pending_shadow_queues,
  )
  let missing_prepared_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_prepared, view_pending_shadow_queues,
  )
  let no_shadows_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, no_shadows, view_pending_shadow_queues,
  )
  let missing_render_mesh_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_render_mesh, view_pending_shadow_queues,
  )
  let ready_value = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, ready, view_pending_shadow_queues,
  ).unwrap()
  let ready_work_item = render3d_shadow_specialization_work_item_data(
    world,
    retained_view,
    render_entity,
    ready,
    @material.ErasedMeshPipelineKey::new(8UL, "MeshPipelineKey"),
    view_pending_shadow_queues,
  ).unwrap()
  let standard_ready_value = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, standard_ready, view_pending_shadow_queues,
  ).unwrap()
  let standard_ready_work_item = render3d_shadow_specialization_work_item_data(
    world,
    retained_view,
    render_entity,
    standard_ready,
    @material.ErasedMeshPipelineKey::new(8UL, "MeshPipelineKey"),
    view_pending_shadow_queues,
  ).unwrap()
  let non_shadow_caster_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, non_shadow_caster, view_pending_shadow_queues,
  )

  debug_inspect(missing_material_ready is None, content="true")
  debug_inspect(missing_mesh_ready is None, content="true")
  debug_inspect(missing_prepared_ready is None, content="true")
  debug_inspect(no_shadows_ready is None, content="true")
  debug_inspect(missing_render_mesh_ready is None, content="true")
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  inspect(ready_work_item.mesh_key().bits(), content="40")
  debug_inspect(ready_work_item.properties().shadows_enabled, content="true")
  debug_inspect(
    standard_ready_value
    .flags()
    .contains(RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  inspect(standard_ready_work_item.mesh_key().bits(), content="72")
  inspect(
    standard_ready_work_item.material_type_tag(),
    content="StandardMaterial",
  )
  debug_inspect(
    standard_ready_work_item.properties().shadows_enabled,
    content="true",
  )
  debug_inspect(non_shadow_caster_ready is None, content="true")
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(retained_view), content="3")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: shadow specialization mesh key mirrors Bevy work item assembly" {
  let visible_entity = @render.MainEntity::new(@core.Entity::new(71, 1))
  let light_key = @material.ErasedMeshPipelineKey::new(8UL, "MeshPipelineKey")
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=3,
    key_bits=@mesh.BaseMeshPipelineKey::new(32UL),
  )
  let opaque_properties = @material.MaterialProperties::MaterialProperties()
  let opaque_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    opaque_properties,
    None,
    visible_entity,
  )
  inspect(opaque_key.bits(), content="40")

  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  ignore(
    render_lightmaps.insert_lightmap(
      visible_entity.id(),
      @lightmap.Lightmap::new(@asset.Handle::new(5)),
    ),
  )
  let blend_properties = @material.MaterialProperties::MaterialProperties().with_alpha_mode(
    Blend,
  )
  let blend_lightmapped_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    blend_properties,
    Some(render_lightmaps),
    visible_entity,
  )
  inspect(blend_lightmapped_key.bits(), content="4200")

  let multiply_properties = @material.MaterialProperties::MaterialProperties().with_alpha_mode(
    Multiply,
  )
  let multiply_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    multiply_properties,
    None,
    visible_entity,
  )
  inspect(multiply_key.bits() & MESH_PIPELINE_KEY_MAY_DISCARD, content="0")
}

///|
test "render3d: shadow specialization work item selects Bevy draw function" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(73, 1),
  )
  let visible_entity = @render.MainEntity::new(@core.Entity::new(74, 1))
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    SpecializedShadowMaterialPipelineCache(),
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(19UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(11U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(12U),
    )
  let item = Render3dShadowSpecializationWorkItemData::{
    queue_data: RenderMeshQueueData::new(80, 0U, false),
    visible_entity,
    retained_view_entity: retained_view,
    mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
    layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
    properties,
    material_type_tag: "TestMaterial",
  }
  let specialized = render3d_shadow_specialization_apply_work_item(
    world, item, false,
  )
  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(cache) else {
    abort("missing shadow cache")
  }
  guard cache.get(retained_view) is Some(view_cache) else {
    abort("missing retained view shadow cache")
  }
  guard view_cache.get(visible_entity) is Some(entry) else {
    abort("missing visible entity shadow cache")
  }
  let (pipeline_id, draw_function) = entry
  debug_inspect(specialized, content="true")
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="12")
}

///|
test "render3d: shadow specialization uses material draw when prepass reads material" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(75, 1),
  )
  let visible_entity = @render.MainEntity::new(@core.Entity::new(76, 1))
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    SpecializedShadowMaterialPipelineCache(),
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(23UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(21U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(22U),
    )
  let item = Render3dShadowSpecializationWorkItemData::{
    queue_data: RenderMeshQueueData::new(81, 0U, false),
    visible_entity,
    retained_view_entity: retained_view,
    mesh_key: @material.ErasedMeshPipelineKey::new(
      4UL | MESH_PIPELINE_KEY_PREPASS_READS_MATERIAL,
      "MeshPipelineKey",
    ),
    layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
    properties,
    material_type_tag: "TestMaterial",
  }
  let specialized = render3d_shadow_specialization_apply_work_item(
    world, item, true,
  )
  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(cache) else {
    abort("missing shadow cache")
  }
  guard cache.get(retained_view) is Some(view_cache) else {
    abort("missing retained view shadow cache")
  }
  guard view_cache.get(visible_entity) is Some(entry) else {
    abort("missing visible entity shadow cache")
  }
  let (pipeline_id, draw_function) = entry
  debug_inspect(specialized, content="true")
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="21")
}

///|
test "render3d: shadow specialization drains work items and expires stale views" {
  let world = @ecs.World::new()
  defer world.close()
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(77, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(78, 1),
  )
  let live_entity = @render.MainEntity::new(@core.Entity::new(79, 1))
  let stale_entity = @render.MainEntity::new(@core.Entity::new(80, 1))
  let cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  cache.insert(
    stale_view,
    stale_entity,
    @material.CachedRenderPipelineId::new(700UL),
    @material.DrawFunctionId::new(70U),
  )
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    cache,
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(29UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(31U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(32U),
    )
  let skipped_properties = @material.MaterialProperties::MaterialProperties()
    .with_material_key(@material.ErasedMaterialKey::new(30UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(33U),
    )
  let work_items = [
    Render3dShadowSpecializationWorkItemData::{
      queue_data: RenderMeshQueueData::new(82, 0U, false),
      visible_entity: live_entity,
      retained_view_entity: live_view,
      mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
      layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
      properties,
      material_type_tag: "TestMaterial",
    },
    {
      queue_data: RenderMeshQueueData::new(83, 0U, false),
      visible_entity: stale_entity,
      retained_view_entity: live_view,
      mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
      layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
      properties: skipped_properties,
      material_type_tag: "TestMaterial",
    },
  ]
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = HashSet([])
  live_views.add(live_view)
  let count = render3d_shadow_specialization_apply_work_items(
    world, work_items, live_views, false,
  )

  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(updated_cache) else {
    abort("missing shadow cache")
  }
  debug_inspect(count, content="1")
  debug_inspect(work_items.length(), content="0")
  debug_inspect(updated_cache.get(stale_view) is None, content="true")
  guard updated_cache.get(live_view) is Some(view_cache) else {
    abort("missing live shadow cache")
  }
  guard view_cache.get(live_entity) is Some(entry) else {
    abort("missing live shadow cache entry")
  }
  let (pipeline_id, draw_function) = entry
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="32")
  debug_inspect(view_cache.get(stale_entity) is None, content="true")
}

///|
test "render3d: queue shadows checks cache and pending queues before empty visible class" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(85, 1),
  )
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.view_or_insert(retained_view) |> ignore
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  ignore(pending_shadow_queues.queues().prepare_for_new_frame(retained_view))
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()

  let queued = render3d_queue_shadow_phase_data_for_visible_entities(
    world,
    retained_view,
    visible_entities,
    None,
    DirtySpecializations(),
    pending_shadow_queues,
  )

  debug_inspect(queued.dequeued().length(), content="0")
  debug_inspect(queued.items().length(), content="0")
  debug_inspect(
    pending_shadow_queues.queues().contains_view(retained_view),
    content="true",
  )
}

///|
test "render3d: queue shadows mirrors Bevy cache layers bindings and pending rules" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial()
    },
  )
  let lifecycle_world_3198_0 = @ecs.World::new()
  defer lifecycle_world_3198_0.close()
  let app = @app.App::new(lifecycle_world_3198_0)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let world = app.sub_app(RenderApp).world()
  let camera_retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(90, 1),
  )
  let shadow_light = world.spawn()
  let spot_light_entity = Render3dLightEntity::Spot(
    light_entity=shadow_light,
    main_entity=shadow_light,
  )
  let retained_view = spot_light_entity.shadow_phase_retained_view(
    camera_retained_view,
  )
  let depth_render = @core.Entity::new(91, 1)
  let material_render = @core.Entity::new(92, 1)
  let layer_render = @core.Entity::new(93, 1)
  let missing_mesh_render = @core.Entity::new(94, 1)
  let missing_binding_render = @core.Entity::new(95, 1)
  let cache_miss_render = @core.Entity::new(96, 1)
  let depth_main = @render.MainEntity::new(world.spawn_empty())
  let material_main = @render.MainEntity::new(world.spawn_empty())
  let layer_main = @render.MainEntity::new(world.spawn_empty())
  let missing_mesh_main = @render.MainEntity::new(world.spawn_empty())
  let missing_binding_main = @render.MainEntity::new(world.spawn_empty())
  let cache_miss_main = @render.MainEntity::new(world.spawn_empty())
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_meshes = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_meshes.prepare_for_new_frame()
  visible_meshes.update_cpu_culled_entities([
    (depth_render, depth_main),
    (material_render, material_main),
    (layer_render, layer_main),
    (missing_mesh_render, missing_mesh_main),
    (missing_binding_render, missing_binding_main),
    (cache_miss_render, cache_miss_main),
  ])
  visible_meshes.sort_added_entities()
  let shadow_map_visible_entities = @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities()
  let shadow_visible_entities = shadow_map_visible_entities.subview_or_insert(
    spot_light_entity.shadow_map_visible_retained_view(retained_view),
  )
  let shadow_visible_meshes = shadow_visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  shadow_visible_meshes.prepare_for_new_frame()
  shadow_visible_meshes.update_cpu_culled_entities([
    (depth_render, depth_main),
    (material_render, material_main),
    (layer_render, layer_main),
    (missing_mesh_render, missing_mesh_main),
    (missing_binding_render, missing_binding_main),
    (cache_miss_render, cache_miss_main),
  ])
  shadow_visible_meshes.sort_added_entities()
  try! world.set_by_key(
    shadow_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    shadow_map_visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_view(retained_view)
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  ignore(pending_shadow_queues.queues().prepare_for_new_frame(retained_view))
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let draw_function_ids = pbr_material_register_draw_functions(DrawFunctions())
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let pipeline = material_pipeline_from_material_hooks(probe)
  let prepared_depth_base = PreparedMaterial::from_material(
    @asset.Handle::new(701),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
    Forward,
  )
  let prepared_depth = PreparedMaterial::{
    ..prepared_depth_base,
    properties: pbr_material_apply_draw_functions(
      prepared_depth_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_material_base = PreparedMaterial::from_material(
    @asset.Handle::new(702),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
    Forward,
  )
  let prepared_material = PreparedMaterial::{
    ..prepared_material_base,
    properties: pbr_material_apply_draw_functions(
      prepared_material_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_layer_base = PreparedMaterial::from_material(
    @asset.Handle::new(703),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
    Forward,
  )
  let prepared_layer = PreparedMaterial::{
    ..prepared_layer_base,
    properties: pbr_material_apply_draw_functions(
      prepared_layer_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_missing_binding_base = PreparedMaterial::from_material(
    @asset.Handle::new(704),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
    Forward,
  )
  let prepared_missing_binding = PreparedMaterial::{
    ..prepared_missing_binding_base,
    properties: pbr_material_apply_draw_functions(
      prepared_missing_binding_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_cache_miss_base = PreparedMaterial::from_material(
    @asset.Handle::new(705),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
    Forward,
  )
  let prepared_cache_miss = PreparedMaterial::{
    ..prepared_cache_miss_base,
    properties: pbr_material_apply_draw_functions(
      prepared_cache_miss_base.properties(),
      draw_function_ids,
    ),
  }
  let depth_draw = prepared_depth
    .properties()
    .get_draw_function(SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
    .unwrap()
  let material_draw = prepared_material
    .properties()
    .get_draw_function(SHADOWS_DRAW_FUNCTION_LABEL)
    .unwrap()
  let prepared_assets = match world.get_resource_mut(prepared_assets_key) {
    Some(value) => value
    None => abort("missing PreparedMaterial render assets")
  }
  prepared_assets.modify(fn(value) {
    value.insert(701, prepared_depth)
    value.insert(702, prepared_material)
    value.insert(703, prepared_layer)
    value.insert(704, prepared_missing_binding)
    value.insert(705, prepared_cache_miss)
  })
  let resolved_slots = RenderMaterial3dResolvedSlots::new()
  resolved_slots.set_resolved(
    depth_main.id(),
    prepared_depth.resolved_material(),
  )
  resolved_slots.set_resolved(
    material_main.id(),
    prepared_material.resolved_material(),
  )
  resolved_slots.set_resolved(
    layer_main.id(),
    prepared_layer.resolved_material(),
  )
  resolved_slots.set_resolved(
    missing_binding_main.id(),
    prepared_missing_binding.resolved_material(),
  )
  resolved_slots.set_resolved(
    cache_miss_main.id(),
    prepared_cache_miss.resolved_material(),
  )
  world.insert_resource(
    RenderMaterial3dResolvedSlots::resource(),
    resolved_slots,
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    depth_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(701)),
  )
  material_instances.extract_mesh_material(
    material_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(702)),
  )
  material_instances.extract_mesh_material(
    layer_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(703)),
  )
  material_instances.extract_mesh_material(
    missing_binding_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(704)),
  )
  material_instances.extract_mesh_material(
    cache_miss_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(705)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  for
    entry in [
      (depth_main, 701),
      (material_main, 702),
      (layer_main, 703),
      (missing_binding_main, 704),
      (cache_miss_main, 705),
    ] {
    let (main_entity, material_id) = entry
    try! world.set_by_key(
      main_entity.id(),
      material_key,
      MeshMaterial3dTyped::new(@asset.Handle::new(material_id)),
    )
  }
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    retained_view,
    depth_main,
    @material.CachedRenderPipelineId::new(801UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    material_main,
    @material.CachedRenderPipelineId::new(802UL),
    material_draw,
  )
  shadow_cache.insert(
    retained_view,
    layer_main,
    @material.CachedRenderPipelineId::new(803UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    missing_mesh_main,
    @material.CachedRenderPipelineId::new(804UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    missing_binding_main,
    @material.CachedRenderPipelineId::new(805UL),
    material_draw,
  )
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )
  let mesh_instances = RenderMeshInstances::new(
    use_gpu_instance_buffer_builder=true,
  )
  let shadow_flags = RenderMeshInstanceFlags::shadow_caster()
  let visible_layer = @camera_render_layers.RenderLayers::layer(1)
  mesh_instances.insert(
    depth_main,
    RenderMeshQueueData::new(
      701,
      11U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  mesh_instances.insert(
    material_main,
    RenderMeshQueueData::new(
      702,
      12U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  mesh_instances.insert(
    layer_main,
    RenderMeshQueueData::new(
      703,
      13U,
      true,
      flags=shadow_flags,
      render_layers=Some(@camera_render_layers.RenderLayers::layer(2)),
    ),
  )
  mesh_instances.insert(
    missing_binding_main,
    RenderMeshQueueData::new(
      704,
      14U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  material_bindings.set(
    702,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(7),
      MaterialBindGroupSlot::new(3),
    ),
  )
  world.insert_resource(RenderMaterialBindings::resource(), material_bindings)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  for mesh_id in [701, 702, 703, 704, 705] {
    ignore(
      mesh_allocator.allocate(
        mesh_id,
        96,
        @render_mesh.MeshAllocatorElementLayout::vertex(32),
      ),
    )
  }
  world.insert_resource(@render_mesh.MeshAllocator::resource(), mesh_allocator)

  let queued = render3d_queue_shadow_phase_data_for_visible_entities(
    world,
    retained_view,
    visible_entities,
    Some(@camera_render_layers.RenderLayers::layer(1)),
    dirty_specializations,
    pending_shadow_queues,
  )

  debug_inspect(queued.dequeued().length(), content="6")
  debug_inspect(queued.items().length(), content="2")
  debug_inspect(
    pending_shadow_queues.queues().current_len(retained_view),
    content="2",
  )
  let first = queued.items()[0]
  let second = queued.items()[1]
  inspect(first.pipeline_id().id(), content="801")
  debug_inspect(first.material_bind_group_index(), content="None")
  inspect(first.current_uniform_index().to_int(), content="11")
  let first_batch_key = first.batch_set_key()
  let first_bin_key = first.bin_key()
  inspect(first_batch_key.pipeline_id().id(), content="801")
  inspect(first_batch_key.draw_function().id(), content="10")
  debug_inspect(first_batch_key.material_bind_group_index(), content="None")
  debug_inspect(first_batch_key.indexed(), content="false")
  inspect(first_bin_key.mesh_asset_id(), content="701")
  inspect(second.pipeline_id().id(), content="802")
  debug_inspect(second.material_bind_group_index(), content="Some(7)")
  inspect(second.current_uniform_index().to_int(), content="12")
  let second_batch_key = second.batch_set_key()
  let second_bin_key = second.bin_key()
  inspect(second_batch_key.pipeline_id().id(), content="802")
  inspect(second_batch_key.draw_function().id(), content="9")
  debug_inspect(second_batch_key.material_bind_group_index(), content="Some(7)")
  debug_inspect(second_batch_key.indexed(), content="false")
  inspect(second_bin_key.mesh_asset_id(), content="702")
  debug_inspect(first.should_batch(), content="true")
  let culling_shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  ignore(
    culling_shadow_phases.prepare_for_new_frame(
      retained_view,
      gpu_preprocessing_mode=Culling,
    ),
  )
  ignore(
    culling_shadow_phases.apply_queue(
      retained_view,
      queued,
      @render_batching.GpuPreprocessingSupport::with_max_supported_mode(Culling),
    ),
  )
  let culling_shadow_phase = match culling_shadow_phases.get(retained_view) {
    Some(phase) => phase
    None => abort("missing culling retained shadow phase in test")
  }
  debug_inspect(culling_shadow_phase.items().length(), content="0")
  debug_inspect(culling_shadow_phase.render_items(false).length(), content="2")
  debug_inspect(
    culling_shadow_phase.multidrawable_batch_set_count(),
    content="2",
  )
  debug_inspect(
    culling_shadow_phase.phase_type(depth_main),
    content="Some(MultidrawableMesh)",
  )
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  let shadow_phase = shadow_phases.prepare_for_new_frame(retained_view)
  shadow_phase.add(
    Render3dShadowBatchSetKeyData::new(
      @material.CachedRenderPipelineId::new(999UL),
      depth_draw,
      None,
      first.slabs(),
    ),
    Render3dShadowBinKeyData::new(705),
    (cache_miss_render, cache_miss_main),
    99U,
    Render3dShadowBinnedRenderPhaseType::mesh(true, GpuPreprocessingSupport()),
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)
  debug_inspect(
    render3d_queue_shadow_phase_data_for_views(
      world,
      [
        Render3dQueuedShadowPhaseView::new(
          spot_light_entity,
          retained_view,
          view_render_layers=Some(@camera_render_layers.RenderLayers::layer(1)),
        ),
      ],
      dirty_specializations,
      pending_shadow_queues,
      GpuPreprocessingSupport(),
    ),
    content="1",
  )
  let shadow_phase = match
    world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) =>
      match phases.get(retained_view) {
        Some(phase) => phase
        None => abort("missing retained shadow phase in test")
      }
    None => abort("missing shadow phases resource in test")
  }
  debug_inspect(shadow_phase.len(), content="2")
  debug_inspect(
    shadow_phase.input_uniform_index(depth_main),
    content="Some(InputUniformIndex(11))",
  )
  debug_inspect(
    shadow_phase.input_uniform_index(material_main),
    content="Some(InputUniformIndex(12))",
  )
  debug_inspect(
    shadow_phase.input_uniform_index(cache_miss_main),
    content="None",
  )
  debug_inspect(
    shadow_phase.phase_type(depth_main),
    content="Some(BatchableMesh)",
  )
  let shadow_phase_items = shadow_phase.items()
  inspect(shadow_phase_items[0].cached_pipeline().id(), content="801")
  inspect(shadow_phase_items[0].batch_range().start(), content="11")
  inspect(shadow_phase_items[0].batch_range().end(), content="12")
  inspect(shadow_phase_items[1].cached_pipeline().id(), content="802")
  inspect(shadow_phase_items[1].batch_range().start(), content="12")
  inspect(shadow_phase_items[1].batch_range().end(), content="13")
  let nonempty_material_bind_group_data = @render_resource.MaterialBindGroupResolvedData::new([
      @render_resource.MaterialBindGroupResolvedEntry::uniform(
        3,
        Bytes::makei(4, i => (i + 1).to_byte()),
      ),
    ],
  )
  let material_shadow_mesh = Mesh3dExtractedPayload::{
    ..material_test_extracted_mesh_payload(702, MaterialProperties()),
    material_bind_group_data: nonempty_material_bind_group_data,
  }
  debug_inspect(
    render3d_shadow_material_bind_group_data(
      shadow_phase_items[0],
      material_shadow_mesh,
    ).is_empty(),
    content="true",
  )
  debug_inspect(
    render3d_shadow_material_bind_group_data(
      shadow_phase_items[1],
      material_shadow_mesh,
    ).equals(nonempty_material_bind_group_data),
    content="true",
  )
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(retained_view), content="2")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: queue shadows skips missing shadow phase before pending queue lookup" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial()
    },
  )
  let lifecycle_world_3708_0 = @ecs.World::new()
  defer lifecycle_world_3708_0.close()
  let app = @app.App::new(lifecycle_world_3708_0)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let world = app.sub_app(RenderApp).world()
  let light = world.spawn_empty()
  let light_entity = Render3dLightEntity::Spot(
    light_entity=light,
    main_entity=light,
  )
  let retained_view = light_entity.shadow_phase_retained_view(
    @render_view.RetainedViewEntity::new(@core.Entity::new(501, 1)),
  )
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )
  world.insert_resource(
    Render3dShadowPhasesData::resource(),
    Render3dShadowPhasesData(),
  )
  debug_inspect(
    render3d_queue_shadow_phase_data_for_views(
      world,
      [Render3dQueuedShadowPhaseView::new(light_entity, retained_view)],
      DirtySpecializations(),
      pending_shadow_queues,
      GpuPreprocessingSupport(),
    ),
    content="0",
  )
  debug_inspect(
    pending_shadow_queues.queues().contains_view(retained_view),
    content="false",
  )
}

///|
test "render3d: missing prepared render mesh does not return to pending queue" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = @core.Entity::new(61, 1)
  let render_view = world.spawn()
  let render_entity = @core.Entity::new(62, 1)
  let visible_entity = @render.MainEntity::new(@core.Entity::new(63, 1))
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([(render_entity, visible_entity)])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(visible_entity)
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    dirty_specializations,
  )
  world.insert_resource(
    PendingMeshMaterialQueues::resource(),
    PendingMeshMaterialQueues(),
  )
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache(),
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    visible_entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(630)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_instances = RenderMeshInstances::new()
  mesh_instances.insert(visible_entity, RenderMeshQueueData::new(630, 0U, true))
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_base_specialize),
  )
  let material_payload = material_test_extracted_mesh_payload(
    630, material_properties,
  )
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(
    visible_entity.id(),
    Render3dResolvedMaterial::new(
      material_payload.material_draw_data,
      material_payload.material_properties,
      material_payload.material_bind_group_data,
      "StandardMaterial",
    ),
  )
  world.insert_resource(
    RenderMaterial3dResolvedSlots::resource(),
    material_slots,
  )
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d(main_view, render_view),
    payload: material_test_camera_payload(),
  }

  render3d_prewarm_mesh_pipelines(world, [camera])

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.current_len(retained_view), content="0")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization reads resolved material slots without extracted meshes" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = @core.Entity::new(610, 1)
  let render_view = world.spawn()
  let render_entity = @core.Entity::new(611, 1)
  let visible_entity = @render.MainEntity::new(@core.Entity::new(612, 1))
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([(render_entity, visible_entity)])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(visible_entity)
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    dirty_specializations,
  )
  world.insert_resource(
    PendingMeshMaterialQueues::resource(),
    PendingMeshMaterialQueues(),
  )
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache(),
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    visible_entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(6120)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_instances = RenderMeshInstances::new()
  mesh_instances.insert(
    visible_entity,
    RenderMeshQueueData::new(6120, 0U, true),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(6120, @render_mesh.RenderMesh::new(vertex_count=3))
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_base_specialize),
  )
  let material_payload = material_test_extracted_mesh_payload(
    9999, material_properties,
  )
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(
    visible_entity.id(),
    Render3dResolvedMaterial::new(
      material_payload.material_draw_data,
      material_payload.material_properties,
      material_payload.material_bind_group_data,
      "StandardMaterial",
    ),
  )
  world.insert_resource(
    RenderMaterial3dResolvedSlots::resource(),
    material_slots,
  )
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d(main_view, render_view),
    payload: material_test_camera_payload(),
  }

  render3d_prewarm_mesh_pipelines(world, [camera])

  let pipeline_id = match
    world.get_resource(ecs_key_specialized_material_pipeline_cache) {
    Some(cache) => cache.pipeline_id(retained_view, visible_entity.id())
    None => abort("missing SpecializedMaterialPipelineCache")
  }
  debug_inspect(pipeline_id.map(fn(value) { value.id() }), content="Some(901)")
  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.current_len(retained_view), content="0")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization reads prepared RenderMeshAssets only" {
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache(),
  )
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_base_specialize),
  )
  let extracted_payload_mesh_id = 581
  let render_mesh_asset_id = 580
  let mesh = material_test_extracted_mesh_payload(
    extracted_payload_mesh_id, material_properties,
  )
  let resolved_material = Render3dResolvedMaterial::new(
    mesh.material_draw_data,
    mesh.material_properties,
    mesh.material_bind_group_data,
    "StandardMaterial",
  )
  let queue_data = RenderMeshQueueData::new(render_mesh_asset_id, 0U, true)
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(58, 1),
  )

  let missing_render_mesh = render3d_prewarm_material_pipeline(
    world,
    resolved_material,
    material_test_camera_payload(),
    retained_view,
    @core.Entity::new(59, 1),
    queue_data,
    1,
  )

  debug_inspect(missing_render_mesh is None, content="true")
  debug_inspect(
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) is None,
    content="true",
  )

  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    render_mesh_asset_id,
    @render_mesh.RenderMesh::new(vertex_count=3),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )
  let prepared_render_mesh = render3d_prewarm_material_pipeline(
    world,
    resolved_material,
    material_test_camera_payload(),
    retained_view,
    @core.Entity::new(59, 1),
    queue_data,
    2,
  )

  debug_inspect(
    prepared_render_mesh.map(fn(value) { value.id() }),
    content="Some(901)",
  )
}

///|
test "render3d: material specialization key consumes render resources" {
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache(),
  )
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_resource_key_base_specialize),
  )
  let render_mesh_asset_id = 592
  let mesh = material_test_extracted_mesh_payload(591, material_properties)
  let resolved_material = Render3dResolvedMaterial::new(
    mesh.material_draw_data,
    mesh.material_properties,
    mesh.material_bind_group_data,
    "StandardMaterial",
  )
  let queue_data = RenderMeshQueueData::new(render_mesh_asset_id, 0U, true)
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(5920, 1),
  )
  let visible_entity = @core.Entity::new(5921, 1)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    render_mesh_asset_id,
    @render_mesh.RenderMesh::new(vertex_count=3),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )
  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  ignore(
    render_lightmaps.insert_lightmap(
      visible_entity,
      @lightmap.Lightmap::new(@asset.Handle::new(9)).with_bicubic_sampling(true),
    ),
  )
  world.insert_resource(@lightmap.RenderLightmaps::resource(), render_lightmaps)
  let render_visibility_ranges = @render_visibility.RenderVisibilityRanges::RenderVisibilityRanges()
  render_visibility_ranges.insert(
    visible_entity.id,
    @visibility.VisibilityRange::new(0.0F, 1.0F, 10.0F, 11.0F, false),
  )
  world.insert_resource(
    @render_visibility.RenderVisibilityRanges::resource(),
    render_visibility_ranges,
  )

  let pipeline_id = render3d_prewarm_material_pipeline(
    world,
    resolved_material,
    material_test_camera_payload(),
    retained_view,
    visible_entity,
    queue_data,
    1,
  )

  debug_inspect(pipeline_id.map(fn(value) { value.id() }), content="Some(902)")
}

///|
test "render3d: material specialization key preserves resolved material type" {
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache(),
  )
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_type_tag_base_specialize),
  )
  let render_mesh_asset_id = 593
  let mesh = material_test_extracted_mesh_payload(594, material_properties)
  let resolved_material = Render3dResolvedMaterial::new(
    mesh.material_draw_data,
    mesh.material_properties,
    mesh.material_bind_group_data,
    "mgstudio_pbr_test::CustomResolvedMaterial",
  )
  let queue_data = RenderMeshQueueData::new(render_mesh_asset_id, 0U, true)
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(5930, 1),
  )
  let visible_entity = @core.Entity::new(5931, 1)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    render_mesh_asset_id,
    @render_mesh.RenderMesh::new(vertex_count=3),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )

  let pipeline_id = render3d_prewarm_material_pipeline(
    world,
    resolved_material,
    material_test_camera_payload(),
    retained_view,
    visible_entity,
    queue_data,
    1,
  )

  debug_inspect(pipeline_id.map(fn(value) { value.id() }), content="Some(903)")
}

///|
test "render3d: materials startup preserves shadow specialization caches" {
  let world = @ecs.World::new()
  defer world.close()
  let view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 1),
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )
  let main_entity = @render.MainEntity::new(@core.Entity::new(11, 1))
  let light_key_cache = @pbr_render.LightKeyCache::LightKeyCache()
  light_key_cache.insert(
    view,
    @material.ErasedMeshPipelineKey::new(13UL, "MeshPipelineKey"),
  )
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    view,
    main_entity,
    @material.CachedRenderPipelineId::new(21UL),
    @material.DrawFunctionId::new(5U),
  )
  world.insert_resource(@pbr_render.LightKeyCache::resource(), light_key_cache)
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )

  init_materials_resources(world)

  match world.get_resource(@pbr_render.LightKeyCache::resource()) {
    Some(cache) =>
      debug_inspect(
        cache.get(view).map(fn(key) { key.bits() }),
        content="Some(13)",
      )
    None => debug_inspect(false, content="true")
  }
  match
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) =>
      debug_inspect(
        cache.pipeline_id(view, main_entity).map(fn(value) { value.id() }),
        content="Some(21)",
      )
    None => debug_inspect(false, content="true")
  }
}
