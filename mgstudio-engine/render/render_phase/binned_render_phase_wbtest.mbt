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
test "render_phase: phase item extra indices preserve direct and indirect forms" {
  debug_inspect(PhaseItemExtraIndex::none(), content="None")
  debug_inspect(
    PhaseItemExtraIndex::dynamic_offset(64),
    content="DynamicOffset(64)",
  )
  debug_inspect(
    PhaseItemExtraIndex::maybe_dynamic_offset(Some(65)),
    content="DynamicOffset(65)",
  )
  debug_inspect(PhaseItemExtraIndex::maybe_dynamic_offset(None), content="None")
  let indirect = PhaseItemExtraIndex::indirect_parameters_index(
    7,
    10,
    batch_set_index=Some(3),
  )
  debug_inspect(indirect, content="IndirectParametersIndex(7, 10, Some(3))")
  debug_inspect(
    indirect.indirect_parameters_range(),
    content="Some((7, 10, Some(3)))",
  )
  debug_inspect(
    PhaseItemExtraIndex::maybe_indirect_parameters_index(Some(11)),
    content="IndirectParametersIndex(11, 12, None)",
  )
}

///|
test "render_phase: phase item batch range preserves valid u32-like bounds" {
  let range = PhaseItemBatchRange::new(4, 9)
  debug_inspect(range, content="{ start: 4, end: 9 }")
  inspect(range.count(), content="5")
  let empty = PhaseItemBatchRange::new(9, 4)
  debug_inspect(empty, content="{ start: 9, end: 4 }")
  inspect(empty.count(), content="0")
}

///|
test "render_phase: binned mesh type follows Bevy preprocessing support" {
  let none = @render_batching.GpuPreprocessingSupport::with_max_supported_mode(
    @render_batching.GpuPreprocessingMode::None,
  )
  let preprocessing = @render_batching.GpuPreprocessingSupport::with_max_supported_mode(
    @render_batching.GpuPreprocessingMode::PreprocessingOnly,
  )
  let culling = @render_batching.GpuPreprocessingSupport::with_max_supported_mode(
    @render_batching.GpuPreprocessingMode::Culling,
  )
  debug_inspect(
    BinnedRenderPhaseType::mesh(true, none),
    content="BatchableMesh",
  )
  debug_inspect(
    BinnedRenderPhaseType::mesh(true, preprocessing),
    content="BatchableMesh",
  )
  debug_inspect(
    BinnedRenderPhaseType::mesh(true, culling),
    content="MultidrawableMesh",
  )
  debug_inspect(
    BinnedRenderPhaseType::mesh(false, culling),
    content="UnbatchableMesh",
  )
}

///|
test "render_phase: input uniform index preserves the Bevy nominal boundary" {
  let index = InputUniformIndex::new(17U)
  inspect(index.value(), content="17")
  inspect(index.to_int(), content="17")
  debug_inspect(InputUniformIndex::default(), content="InputUniformIndex(0)")
}

///|
test "render_phase: RenderBin retains MainEntity input indices" {
  debug_inspect(RenderBin::default().is_empty(), content="true")
  let first = @render_sync_world.MainEntity::new(@core.Entity::new(1, 1))
  let second = @render_sync_world.MainEntity::new(@core.Entity::new(2, 1))
  let third = @render_sync_world.MainEntity::new(@core.Entity::new(3, 1))
  let bin = RenderBin::from_entity(first, InputUniformIndex::new(7U))
  bin.insert(second, InputUniformIndex::new(9U))
  bin.insert(third, InputUniformIndex::new(11U))
  bin.insert(first, InputUniformIndex::new(8U))
  inspect(bin.entities().length(), content="3")
  debug_inspect(bin.entities()[0].0 == first, content="true")
  debug_inspect(
    bin.entities()[0].1 == InputUniformIndex::new(8U),
    content="true",
  )
  debug_inspect(bin.entities()[1].0 == second, content="true")
  debug_inspect(
    bin.entities()[1].1 == InputUniformIndex::new(9U),
    content="true",
  )
  debug_inspect(bin.entities()[2].0 == third, content="true")
  debug_inspect(
    bin.entities()[2].1 == InputUniformIndex::new(11U),
    content="true",
  )
  bin.remove(first)
  inspect(bin.entities().length(), content="2")
  debug_inspect(bin.entities()[0].0 == third, content="true")
  debug_inspect(bin.entities()[1].0 == second, content="true")
  bin.remove(first)
  inspect(bin.entities().length(), content="2")
  bin.remove(second)
  bin.remove(third)
  debug_inspect(bin.is_empty(), content="true")
}

///|
test "render_phase: unbatchable indices preserve Bevy sparse and dense transitions" {
  let sparse = UnbatchableBinnedEntityIndexSet::new()
  sparse.add(UnbatchableBinnedEntityIndices::new(4, PhaseItemExtraIndex::None))
  sparse.add(UnbatchableBinnedEntityIndices::new(5, PhaseItemExtraIndex::None))
  debug_inspect(sparse.len(), content="2")
  debug_inspect(
    sparse
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.instance_index() }),
    content="Some(5)",
  )

  let indirect = UnbatchableBinnedEntityIndexSet::new()
  indirect.add(
    UnbatchableBinnedEntityIndices::new(
      8,
      PhaseItemExtraIndex::indirect_parameters_index(20, 21),
    ),
  )
  indirect.add(
    UnbatchableBinnedEntityIndices::new(
      9,
      PhaseItemExtraIndex::indirect_parameters_index(21, 22),
    ),
  )
  debug_inspect(
    indirect
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.extra_index() }),
    content="Some(IndirectParametersIndex(21, 22, None))",
  )

  let dense = UnbatchableBinnedEntityIndexSet::new()
  dense.add(UnbatchableBinnedEntityIndices::new(10, PhaseItemExtraIndex::None))
  dense.add(UnbatchableBinnedEntityIndices::new(12, PhaseItemExtraIndex::None))
  debug_inspect(
    dense
    .indices_for_entity_index(1)
    .map(fn(indices) { indices.instance_index() }),
    content="Some(12)",
  )
  dense.clear()
  debug_inspect(dense.len(), content="0")
}
