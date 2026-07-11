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
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::PhaseItemExtraIndex`.
pub(all) enum PhaseItemExtraIndex {
  None
  DynamicOffset(Int)
  IndirectParametersIndex(Int, Int, Int?)
} derive(Eq, Debug)

///|
pub fn PhaseItemExtraIndex::none() -> PhaseItemExtraIndex {
  PhaseItemExtraIndex::None
}

///|
pub fn PhaseItemExtraIndex::dynamic_offset(offset : Int) -> PhaseItemExtraIndex {
  DynamicOffset(offset)
}

///|
pub fn PhaseItemExtraIndex::maybe_dynamic_offset(
  dynamic_offset : Int?,
) -> PhaseItemExtraIndex {
  match dynamic_offset {
    Some(offset) => DynamicOffset(offset)
    None => PhaseItemExtraIndex::None
  }
}

///|
pub fn PhaseItemExtraIndex::indirect_parameters_index(
  range_start : Int,
  range_end : Int,
  batch_set_index? : Int? = None,
) -> PhaseItemExtraIndex {
  IndirectParametersIndex(range_start, range_end, batch_set_index)
}

///|
pub fn PhaseItemExtraIndex::maybe_indirect_parameters_index(
  indirect_parameters_index : Int?,
) -> PhaseItemExtraIndex {
  match indirect_parameters_index {
    Some(index) => IndirectParametersIndex(index, index + 1, None)
    None => PhaseItemExtraIndex::None
  }
}

///|
pub fn PhaseItemExtraIndex::indirect_parameters_range(
  self : PhaseItemExtraIndex,
) -> (Int, Int, Int?)? {
  match self {
    IndirectParametersIndex(range_start, range_end, batch_set_index) =>
      Some((range_start, range_end, batch_set_index))
    _ => None
  }
}

///|
// MoonBit representation of the `Range<u32>` stored by Bevy phase items.
pub struct PhaseItemBatchRange {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn PhaseItemBatchRange::new(start : Int, end : Int) -> PhaseItemBatchRange {
  if start < 0 || end < 0 {
    abort("phase item batch range bounds must be non-negative")
  }
  PhaseItemBatchRange::{ start, end }
}

///|
pub fn PhaseItemBatchRange::start(self : PhaseItemBatchRange) -> Int {
  self.start
}

///|
pub fn PhaseItemBatchRange::end(self : PhaseItemBatchRange) -> Int {
  self.end
}

///|
pub fn PhaseItemBatchRange::count(self : PhaseItemBatchRange) -> Int {
  if self.end <= self.start {
    0
  } else {
    self.end - self.start
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhaseType`.
pub(all) enum BinnedRenderPhaseType {
  MultidrawableMesh
  BatchableMesh
  UnbatchableMesh
  NonMesh
} derive(Eq, Debug)

///|
pub fn BinnedRenderPhaseType::mesh(
  batchable : Bool,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> BinnedRenderPhaseType {
  match (batchable, gpu_preprocessing_support.is_culling_supported()) {
    (true, true) => MultidrawableMesh
    (true, false) => BatchableMesh
    (false, _) => UnbatchableMesh
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::InputUniformIndex`.
pub(all) struct InputUniformIndex(UInt) derive(Default, Eq, Debug)

///|
pub fn InputUniformIndex::new(index : UInt) -> InputUniformIndex {
  InputUniformIndex(index)
}

///|
pub fn InputUniformIndex::value(self : InputUniformIndex) -> UInt {
  let InputUniformIndex(index) = self
  index
}

///|
pub fn InputUniformIndex::to_int(self : InputUniformIndex) -> Int {
  self.value().reinterpret_as_int()
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderBin`.
struct RenderBinEntities {
  entries : Array[(@render_sync_world.MainEntity, InputUniformIndex)]
  indices : Map[@render_sync_world.MainEntity, Int]
} derive(Default)

///|
fn RenderBinEntities::insert(
  self : RenderBinEntities,
  entity : @render_sync_world.MainEntity,
  uniform_index : InputUniformIndex,
) -> Unit {
  match self.indices.get(entity) {
    Some(index) => self.entries[index] = (entity, uniform_index)
    None => {
      self.indices.set(entity, self.entries.length())
      self.entries.push((entity, uniform_index))
    }
  }
}

///|
fn RenderBinEntities::swap_remove(
  self : RenderBinEntities,
  entity_to_remove : @render_sync_world.MainEntity,
) -> Unit {
  guard self.indices.get(entity_to_remove) is Some(index) else { return }
  self.indices.remove(entity_to_remove)
  let last_index = self.entries.length() - 1
  if index != last_index {
    let last_entry = self.entries[last_index]
    self.entries[index] = last_entry
    self.indices.set(last_entry.0, index)
  }
  self.entries.pop() |> ignore
}

///|
fn RenderBinEntities::is_empty(self : RenderBinEntities) -> Bool {
  self.entries.length() == 0
}

///|
fn RenderBinEntities::entries(
  self : RenderBinEntities,
) -> ArrayView[(@render_sync_world.MainEntity, InputUniformIndex)] {
  self.entries[:]
}

///|
pub struct RenderBin {
  entities : RenderBinEntities
} derive(Default)

///|
#warnings("-unused_value")
fn RenderBin::from_entity(
  entity : @render_sync_world.MainEntity,
  uniform_index : InputUniformIndex,
) -> RenderBin {
  let entities = RenderBinEntities::default()
  entities.insert(entity, uniform_index)
  RenderBin::{ entities, }
}

///|
#warnings("-unused_value")
fn RenderBin::insert(
  self : RenderBin,
  entity : @render_sync_world.MainEntity,
  uniform_index : InputUniformIndex,
) -> Unit {
  self.entities.insert(entity, uniform_index)
}

///|
#warnings("-unused_value")
fn RenderBin::remove(
  self : RenderBin,
  entity_to_remove : @render_sync_world.MainEntity,
) -> Unit {
  self.entities.swap_remove(entity_to_remove)
}

///|
#warnings("-unused_value")
fn RenderBin::is_empty(self : RenderBin) -> Bool {
  self.entities.is_empty()
}

///|
pub fn RenderBin::entities(
  self : RenderBin,
) -> ArrayView[(@render_sync_world.MainEntity, InputUniformIndex)] {
  self.entities.entries()
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderBinnedMeshInstanceIndex`.
pub(all) struct RenderBinnedMeshInstanceIndex(UInt) derive(Eq, Debug)

///|
pub fn RenderBinnedMeshInstanceIndex::new(
  index : UInt,
) -> RenderBinnedMeshInstanceIndex {
  RenderBinnedMeshInstanceIndex(index)
}

///|
pub fn RenderBinnedMeshInstanceIndex::value(
  self : RenderBinnedMeshInstanceIndex,
) -> UInt {
  let RenderBinnedMeshInstanceIndex(index) = self
  index
}

///|
pub fn RenderBinnedMeshInstanceIndex::to_int(
  self : RenderBinnedMeshInstanceIndex,
) -> Int {
  self.value().reinterpret_as_int()
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderBinIndex`.
pub(all) struct RenderBinIndex(UInt) derive(Default, Eq, Debug)

///|
pub fn RenderBinIndex::new(index : UInt) -> RenderBinIndex {
  RenderBinIndex(index)
}

///|
pub fn RenderBinIndex::value(self : RenderBinIndex) -> UInt {
  let RenderBinIndex(index) = self
  index
}

///|
pub fn RenderBinIndex::to_int(self : RenderBinIndex) -> Int {
  self.value().reinterpret_as_int()
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::GpuRenderBinnedMeshInstance`.
pub struct GpuRenderBinnedMeshInstance {
  input_uniform_index : UInt
  bin_index : UInt
} derive(Default)

///|
pub fn GpuRenderBinnedMeshInstance::new(
  input_uniform_index : InputUniformIndex,
  bin_index : RenderBinIndex,
) -> GpuRenderBinnedMeshInstance {
  GpuRenderBinnedMeshInstance::{
    input_uniform_index: input_uniform_index.value(),
    bin_index: bin_index.value(),
  }
}

///|
pub fn GpuRenderBinnedMeshInstance::input_uniform_index(
  self : GpuRenderBinnedMeshInstance,
) -> UInt {
  self.input_uniform_index
}

///|
pub fn GpuRenderBinnedMeshInstance::bin_index(
  self : GpuRenderBinnedMeshInstance,
) -> UInt {
  self.bin_index
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::CpuRenderBinnedMeshInstance`.
pub struct CpuRenderBinnedMeshInstance {
  main_entity : @render_sync_world.MainEntity
  bin_index : RenderBinIndex
}

///|
pub fn CpuRenderBinnedMeshInstance::default() -> CpuRenderBinnedMeshInstance {
  CpuRenderBinnedMeshInstance::{
    main_entity: @render_sync_world.MainEntity::new(@core.Entity::placeholder()),
    bin_index: RenderBinIndex::default(),
  }
}

///|
pub fn CpuRenderBinnedMeshInstance::new(
  main_entity : @render_sync_world.MainEntity,
  bin_index : RenderBinIndex,
) -> CpuRenderBinnedMeshInstance {
  CpuRenderBinnedMeshInstance::{ main_entity, bin_index }
}

///|
pub fn CpuRenderBinnedMeshInstance::main_entity(
  self : CpuRenderBinnedMeshInstance,
) -> @render_sync_world.MainEntity {
  self.main_entity
}

///|
pub fn CpuRenderBinnedMeshInstance::bin_index(
  self : CpuRenderBinnedMeshInstance,
) -> RenderBinIndex {
  self.bin_index
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderMultidrawableBin`.
pub struct RenderMultidrawableBin {
  entity_to_binned_mesh_instance_index : Map[
    @render_sync_world.MainEntity,
    RenderBinnedMeshInstanceIndex,
  ]
} derive(Default)

///|
pub fn RenderMultidrawableBin::new() -> RenderMultidrawableBin {
  RenderMultidrawableBin::default()
}

///|
pub fn RenderMultidrawableBin::is_empty(self : RenderMultidrawableBin) -> Bool {
  self.entity_to_binned_mesh_instance_index.is_empty()
}

///|
pub fn RenderMultidrawableBin::entity_count(
  self : RenderMultidrawableBin,
) -> Int {
  self.entity_to_binned_mesh_instance_index.length()
}

///|
pub fn RenderMultidrawableBin::binned_mesh_instance_index(
  self : RenderMultidrawableBin,
  main_entity : @render_sync_world.MainEntity,
) -> RenderBinnedMeshInstanceIndex? {
  self.entity_to_binned_mesh_instance_index.get(main_entity)
}

///|
pub fn RenderMultidrawableBin::insert(
  self : RenderMultidrawableBin,
  main_entity : @render_sync_world.MainEntity,
  binned_mesh_instance_index : RenderBinnedMeshInstanceIndex,
) -> Unit {
  self.entity_to_binned_mesh_instance_index.set(
    main_entity, binned_mesh_instance_index,
  )
}

///|
pub fn RenderMultidrawableBin::remove(
  self : RenderMultidrawableBin,
  main_entity : @render_sync_world.MainEntity,
) -> RenderBinnedMeshInstanceIndex? {
  guard self.entity_to_binned_mesh_instance_index.get(main_entity)
    is Some(index) else {
    return None
  }
  self.entity_to_binned_mesh_instance_index.remove(main_entity)
  Some(index)
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::UnbatchableBinnedEntityIndices`.
pub(all) struct UnbatchableBinnedEntityIndices {
  instance_index : Int
  extra_index : PhaseItemExtraIndex
} derive(Eq, Debug)

///|
pub fn UnbatchableBinnedEntityIndices::new(
  instance_index : Int,
  extra_index : PhaseItemExtraIndex,
) -> UnbatchableBinnedEntityIndices {
  if instance_index < 0 {
    abort("unbatchable binned entity instance index must be non-negative")
  }
  UnbatchableBinnedEntityIndices::{ instance_index, extra_index }
}

///|
pub fn UnbatchableBinnedEntityIndices::instance_index(
  self : UnbatchableBinnedEntityIndices,
) -> Int {
  self.instance_index
}

///|
pub fn UnbatchableBinnedEntityIndices::extra_index(
  self : UnbatchableBinnedEntityIndices,
) -> PhaseItemExtraIndex {
  self.extra_index
}

///|
// MoonBit uses a mutable wrapper around Bevy's enum so `add` and `clear` can
// preserve the same sparse-to-dense state transitions through a shared value.
pub(all) enum UnbatchableBinnedEntityIndexSetKind {
  NoEntities
  Sparse(PhaseItemBatchRange, Int?)
  Dense(Array[UnbatchableBinnedEntityIndices])
} derive(Debug)

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::UnbatchableBinnedEntityIndexSet`.
pub(all) struct UnbatchableBinnedEntityIndexSet {
  mut kind : UnbatchableBinnedEntityIndexSetKind
}

///|
pub fn UnbatchableBinnedEntityIndexSet::new() -> UnbatchableBinnedEntityIndexSet {
  UnbatchableBinnedEntityIndexSet::{
    kind: UnbatchableBinnedEntityIndexSetKind::NoEntities,
  }
}

///|
pub fn UnbatchableBinnedEntityIndexSet::len(
  self : UnbatchableBinnedEntityIndexSet,
) -> Int {
  match self.kind {
    NoEntities => 0
    Sparse(instance_range, _) => instance_range.count()
    Dense(indices) => indices.length()
  }
}

///|
pub fn UnbatchableBinnedEntityIndexSet::kind(
  self : UnbatchableBinnedEntityIndexSet,
) -> UnbatchableBinnedEntityIndexSetKind {
  self.kind
}

///|
pub fn UnbatchableBinnedEntityIndexSet::indices_for_entity_index(
  self : UnbatchableBinnedEntityIndexSet,
  entity_index : Int,
) -> UnbatchableBinnedEntityIndices? {
  if entity_index < 0 {
    return None
  }
  match self.kind {
    NoEntities => None
    Sparse(instance_range, _) if entity_index >= instance_range.count() => None
    Sparse(instance_range, None) =>
      Some(
        UnbatchableBinnedEntityIndices::new(
          instance_range.start() + entity_index,
          PhaseItemExtraIndex::None,
        ),
      )
    Sparse(instance_range, Some(first_indirect_parameters_index)) => {
      let indirect_parameters_index = first_indirect_parameters_index +
        entity_index
      Some(
        UnbatchableBinnedEntityIndices::new(
          instance_range.start() + entity_index,
          PhaseItemExtraIndex::indirect_parameters_index(
            indirect_parameters_index,
            indirect_parameters_index + 1,
          ),
        ),
      )
    }
    Dense(indices) =>
      if entity_index < indices.length() {
        Some(indices[entity_index])
      } else {
        None
      }
  }
}

///|
fn unbatchable_indices_can_extend_sparse(
  instance_range : PhaseItemBatchRange,
  first_indirect_parameters_index : Int?,
  indices : UnbatchableBinnedEntityIndices,
) -> Bool {
  if instance_range.end() != indices.instance_index() {
    return false
  }
  match first_indirect_parameters_index {
    None => indices.extra_index() == PhaseItemExtraIndex::None
    Some(first_index) =>
      match indices.extra_index() {
        IndirectParametersIndex(range_start, _, _) =>
          first_index + instance_range.count() == range_start
        DynamicOffset(_) | PhaseItemExtraIndex::None => false
      }
  }
}

///|
fn UnbatchableBinnedEntityIndexSet::demote_sparse_to_dense_with(
  self : UnbatchableBinnedEntityIndexSet,
  indices : UnbatchableBinnedEntityIndices,
) -> Unit {
  @app.log_warn(
    "Unbatchable binned entity index set was demoted from sparse to dense. This is a bug in the renderer. Please report it.",
  )
  let dense : Array[UnbatchableBinnedEntityIndices] = []
  let count = self.len()
  for entity_index in 0..<count {
    match self.indices_for_entity_index(entity_index) {
      Some(existing) => dense.push(existing)
      None => ()
    }
  }
  dense.push(indices)
  self.kind = UnbatchableBinnedEntityIndexSetKind::Dense(dense)
}

///|
pub fn UnbatchableBinnedEntityIndexSet::add(
  self : UnbatchableBinnedEntityIndexSet,
  indices : UnbatchableBinnedEntityIndices,
) -> Unit {
  match self.kind {
    NoEntities =>
      match indices.extra_index() {
        DynamicOffset(_) =>
          self.kind = UnbatchableBinnedEntityIndexSetKind::Dense([indices])
        PhaseItemExtraIndex::None =>
          self.kind = UnbatchableBinnedEntityIndexSetKind::Sparse(
            PhaseItemBatchRange::new(
              indices.instance_index(),
              indices.instance_index() + 1,
            ),
            None,
          )
        IndirectParametersIndex(range_start, _, _) =>
          self.kind = UnbatchableBinnedEntityIndexSetKind::Sparse(
            PhaseItemBatchRange::new(
              indices.instance_index(),
              indices.instance_index() + 1,
            ),
            Some(range_start),
          )
      }
    Sparse(instance_range, first_indirect_parameters_index) =>
      if unbatchable_indices_can_extend_sparse(
          instance_range, first_indirect_parameters_index, indices,
        ) {
        self.kind = UnbatchableBinnedEntityIndexSetKind::Sparse(
          PhaseItemBatchRange::new(
            instance_range.start(),
            instance_range.end() + 1,
          ),
          first_indirect_parameters_index,
        )
      } else {
        self.demote_sparse_to_dense_with(indices)
      }
    Dense(existing) => existing.push(indices)
  }
}

///|
pub fn UnbatchableBinnedEntityIndexSet::clear(
  self : UnbatchableBinnedEntityIndexSet,
) -> Unit {
  match self.kind {
    Dense(indices) => indices.clear()
    Sparse(_, _) => self.kind = UnbatchableBinnedEntityIndexSetKind::NoEntities
    NoEntities => ()
  }
}
