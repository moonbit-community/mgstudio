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
  None
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
    None => None
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
    None => None
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
  { start, end }
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
  { entities, }
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
  {
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
  {
    main_entity: @render_sync_world.MainEntity::new(@core.Entity::placeholder()),
    bin_index: RenderBinIndex::default(),
  }
}

///|
pub fn CpuRenderBinnedMeshInstance::new(
  main_entity : @render_sync_world.MainEntity,
  bin_index : RenderBinIndex,
) -> CpuRenderBinnedMeshInstance {
  { main_entity, bin_index }
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
fn RenderMultidrawableBin::representative_entity(
  self : RenderMultidrawableBin,
) -> @render_sync_world.MainEntity? {
  for main_entity, _index in self.entity_to_binned_mesh_instance_index {
    return Some(main_entity)
  }
  None
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderMultidrawableBatchSetGpuBuffers`.
pub struct RenderMultidrawableBatchSetGpuBuffers {
  render_binned_mesh_instance_buffer : Array[GpuRenderBinnedMeshInstance]
  bin_index_to_indirect_parameters_offset_buffer : Array[UInt]
}

///|
fn RenderMultidrawableBatchSetGpuBuffers::new() -> RenderMultidrawableBatchSetGpuBuffers {
  {
    render_binned_mesh_instance_buffer: [],
    bin_index_to_indirect_parameters_offset_buffer: [],
  }
}

///|
fn RenderMultidrawableBatchSetGpuBuffers::insert(
  self : RenderMultidrawableBatchSetGpuBuffers,
  bin : RenderMultidrawableBin,
  cpu_binned_mesh_instance_buffer : Array[CpuRenderBinnedMeshInstance],
  main_entity : @render_sync_world.MainEntity,
  input_uniform_index : InputUniformIndex,
  bin_index : RenderBinIndex,
) -> Unit {
  let gpu_render_bin_entry = GpuRenderBinnedMeshInstance::new(
    input_uniform_index, bin_index,
  )
  let render_binned_mesh_instance_buffer_index = match
    bin.binned_mesh_instance_index(main_entity) {
    Some(index) => index
    None => {
      let index = RenderBinnedMeshInstanceIndex::new(
        self.render_binned_mesh_instance_buffer.length().reinterpret_as_uint(),
      )
      self.render_binned_mesh_instance_buffer.push(
        GpuRenderBinnedMeshInstance::default(),
      )
      cpu_binned_mesh_instance_buffer.push(
        CpuRenderBinnedMeshInstance::default(),
      )
      bin.insert(main_entity, index)
      index
    }
  }
  let buffer_index = render_binned_mesh_instance_buffer_index.to_int()
  self.render_binned_mesh_instance_buffer[buffer_index] = gpu_render_bin_entry
  cpu_binned_mesh_instance_buffer[buffer_index] = CpuRenderBinnedMeshInstance::new(
    main_entity, bin_index,
  )
  if self.render_binned_mesh_instance_buffer.length() !=
    cpu_binned_mesh_instance_buffer.length() {
    abort("GPU and CPU binned mesh instance buffers must remain parallel")
  }
}

///|
fn RenderMultidrawableBatchSetGpuBuffers::remove(
  self : RenderMultidrawableBatchSetGpuBuffers,
  bin : RenderMultidrawableBin,
  cpu_binned_mesh_instance_buffer : Array[CpuRenderBinnedMeshInstance],
  entity_to_remove : @render_sync_world.MainEntity,
) -> (RenderBinnedMeshInstanceIndex, CpuRenderBinnedMeshInstance)? {
  let old_index = match bin.remove(entity_to_remove) {
    Some(index) => index
    None => abort("Entity not in bin")
  }
  let old_buffer_index = old_index.to_int()
  let last_index = cpu_binned_mesh_instance_buffer.length() - 1
  if old_buffer_index != last_index {
    cpu_binned_mesh_instance_buffer[old_buffer_index] = cpu_binned_mesh_instance_buffer[last_index]
    self.render_binned_mesh_instance_buffer[old_buffer_index] = self.render_binned_mesh_instance_buffer[last_index]
  }
  ignore(cpu_binned_mesh_instance_buffer.pop())
  ignore(self.render_binned_mesh_instance_buffer.pop())
  if self.render_binned_mesh_instance_buffer.length() !=
    cpu_binned_mesh_instance_buffer.length() {
    abort("GPU and CPU binned mesh instance buffers must remain parallel")
  }
  if old_buffer_index < cpu_binned_mesh_instance_buffer.length() {
    Some((old_index, cpu_binned_mesh_instance_buffer[old_buffer_index]))
  } else {
    None
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::RenderMultidrawableBatchSet`.
// MoonBit uses the phase item's bin-key type directly because associated types
// are represented at the package seam by a generic type parameter.
pub struct RenderMultidrawableBatchSet[K] {
  gpu_buffers : RenderMultidrawableBatchSetGpuBuffers
  bin_key_to_bin_index : Map[K, RenderBinIndex]
  bins : Array[RenderMultidrawableBin?]
  bin_free_list : Array[RenderBinIndex]
  indirect_parameters_offset_to_bin_index : Array[RenderBinIndex]
  render_binned_mesh_instances_cpu : Array[CpuRenderBinnedMeshInstance]
}

///|
pub fn[K : Hash + Eq] RenderMultidrawableBatchSet::new() -> RenderMultidrawableBatchSet[
  K,
] {
  {
    gpu_buffers: RenderMultidrawableBatchSetGpuBuffers::new(),
    bin_key_to_bin_index: Map([]),
    bins: [],
    bin_free_list: [],
    indirect_parameters_offset_to_bin_index: [],
    render_binned_mesh_instances_cpu: [],
  }
}

///|
pub fn[K] RenderMultidrawableBatchSet::representative_entity(
  self : RenderMultidrawableBatchSet[K],
) -> @render_sync_world.MainEntity? {
  guard self.representative_entry() is Some((_bin_key, bin_index)) else {
    return None
  }
  let bin = match self.bin(bin_index) {
    Some(value) => value
    None => abort("Bin should be present")
  }
  bin.representative_entity()
}

///|
pub fn[K] RenderMultidrawableBatchSet::representative_entry(
  self : RenderMultidrawableBatchSet[K],
) -> (K, RenderBinIndex)? {
  for bin_key, bin_index in self.bin_key_to_bin_index {
    return Some((bin_key, bin_index))
  }
  None
}

///|
pub fn[K] RenderMultidrawableBatchSet::bin(
  self : RenderMultidrawableBatchSet[K],
  bin_index : RenderBinIndex,
) -> RenderMultidrawableBin? {
  let raw_bin_index = bin_index.to_int()
  if raw_bin_index < 0 || raw_bin_index >= self.bins.length() {
    return None
  }
  self.bins[raw_bin_index]
}

///|
pub fn[K : Hash + Eq] RenderMultidrawableBatchSet::insert(
  self : RenderMultidrawableBatchSet[K],
  bin_key : K,
  main_entity : @render_sync_world.MainEntity,
  input_uniform_index : InputUniformIndex,
) -> Unit {
  let bin_index = match self.bin_key_to_bin_index.get(bin_key) {
    Some(index) => index
    None => {
      let index = match self.bin_free_list.pop() {
        Some(free_index) => free_index
        None => RenderBinIndex::new(self.bins.length().reinterpret_as_uint())
      }
      let raw_index = index.to_int()
      if raw_index == self.bins.length() {
        self.bins.push(Some(RenderMultidrawableBin::new()))
      } else {
        if self.bins[raw_index] is Some(_) {
          abort("Reused bin index must refer to an empty slot")
        }
        self.bins[raw_index] = Some(RenderMultidrawableBin::new())
      }
      self.bin_key_to_bin_index.set(bin_key, index)
      self.allocate_indirect_parameters(index)
      index
    }
  }
  let bin = match self.bin(bin_index) {
    Some(value) => value
    None => abort("Bin not present")
  }
  self.gpu_buffers.insert(
    bin,
    self.render_binned_mesh_instances_cpu,
    main_entity,
    input_uniform_index,
    bin_index,
  )
}

///|
pub fn[K : Hash + Eq] RenderMultidrawableBatchSet::remove(
  self : RenderMultidrawableBatchSet[K],
  main_entity : @render_sync_world.MainEntity,
  bin_key : K,
) -> Unit {
  let bin_index = match self.bin_key_to_bin_index.get(bin_key) {
    Some(value) => value
    None => abort("Bin key not present")
  }
  let bin = match self.bin(bin_index) {
    Some(value) => value
    None => abort("Bin not present")
  }
  match
    self.gpu_buffers.remove(
      bin,
      self.render_binned_mesh_instances_cpu,
      main_entity,
    ) {
    Some((old_index, displaced_entity_indices)) => {
      let displaced_bin = match self.bin(displaced_entity_indices.bin_index()) {
        Some(value) => value
        None => abort("Bin not present")
      }
      displaced_bin.insert(displaced_entity_indices.main_entity(), old_index)
    }
    None => ()
  }
  self.remove_bin_if_empty(bin_key, bin_index)
}

///|
fn[K] RenderMultidrawableBatchSet::allocate_indirect_parameters(
  self : RenderMultidrawableBatchSet[K],
  bin_index : RenderBinIndex,
) -> Unit {
  let indirect_parameters_offset = self.indirect_parameters_offset_to_bin_index.length()
  self.indirect_parameters_offset_to_bin_index.push(bin_index)
  let raw_bin_index = bin_index.to_int()
  if raw_bin_index ==
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer.length() {
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer.push(
      indirect_parameters_offset.reinterpret_as_uint(),
    )
  } else {
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[raw_bin_index] = indirect_parameters_offset.reinterpret_as_uint()
  }
}

///|
fn[K : Hash + Eq] RenderMultidrawableBatchSet::remove_bin_if_empty(
  self : RenderMultidrawableBatchSet[K],
  bin_key : K,
  bin_index : RenderBinIndex,
) -> Unit {
  let bin = match self.bin(bin_index) {
    Some(value) => value
    None => abort("Bin not present")
  }
  if !bin.is_empty() {
    return
  }
  self.bin_key_to_bin_index.remove(bin_key)
  self.bin_free_list.push(bin_index)
  let raw_bin_index = bin_index.to_int()
  self.bins[raw_bin_index] = None
  let indirect_parameters_offset = match
    self.indirect_parameters_offset_for_bin(bin_index) {
    Some(value) => value
    None => abort("Indirect parameters offset not present")
  }
  self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[raw_bin_index] = 0xFFFFFFFFU
  let raw_indirect_parameters_offset = indirect_parameters_offset.reinterpret_as_int()
  let last_index = self.indirect_parameters_offset_to_bin_index.length() - 1
  let removed_bin_index = self.indirect_parameters_offset_to_bin_index[raw_indirect_parameters_offset]
  if raw_indirect_parameters_offset != last_index {
    self.indirect_parameters_offset_to_bin_index[raw_indirect_parameters_offset] = self.indirect_parameters_offset_to_bin_index[last_index]
  }
  ignore(self.indirect_parameters_offset_to_bin_index.pop())
  if removed_bin_index != bin_index {
    abort("Removed indirect parameters must belong to the removed bin")
  }
  if raw_indirect_parameters_offset <
    self.indirect_parameters_offset_to_bin_index.length() {
    let displaced_bin_index = self.indirect_parameters_offset_to_bin_index[raw_indirect_parameters_offset]
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[displaced_bin_index.to_int()] = indirect_parameters_offset
  }
}

///|
pub fn[K] RenderMultidrawableBatchSet::is_empty(
  self : RenderMultidrawableBatchSet[K],
) -> Bool {
  self.bin_free_list.length() == self.bins.length()
}

///|
pub fn[K] RenderMultidrawableBatchSet::bin_count(
  self : RenderMultidrawableBatchSet[K],
) -> Int {
  self.bin_key_to_bin_index.length()
}

///|
pub fn[K : Hash + Eq] RenderMultidrawableBatchSet::bin_index(
  self : RenderMultidrawableBatchSet[K],
  bin_key : K,
) -> RenderBinIndex? {
  self.bin_key_to_bin_index.get(bin_key)
}

///|
pub fn[K] RenderMultidrawableBatchSet::indirect_parameters_offset_for_bin(
  self : RenderMultidrawableBatchSet[K],
  bin_index : RenderBinIndex,
) -> UInt? {
  let raw_bin_index = bin_index.to_int()
  if raw_bin_index < 0 ||
    raw_bin_index >=
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer.length() {
    return None
  }
  Some(
    self.gpu_buffers.bin_index_to_indirect_parameters_offset_buffer[raw_bin_index],
  )
}

///|
pub fn[K] RenderMultidrawableBatchSet::render_binned_mesh_instance_len(
  self : RenderMultidrawableBatchSet[K],
) -> Int {
  self.gpu_buffers.render_binned_mesh_instance_buffer.length()
}

///|
pub fn[K] RenderMultidrawableBatchSet::cpu_instance_count(
  self : RenderMultidrawableBatchSet[K],
) -> Int {
  self.render_binned_mesh_instances_cpu.length()
}

///|
pub fn[K] RenderMultidrawableBatchSet::cpu_instance_at(
  self : RenderMultidrawableBatchSet[K],
  index : Int,
) -> CpuRenderBinnedMeshInstance? {
  if index < 0 || index >= self.render_binned_mesh_instances_cpu.length() {
    return None
  }
  Some(self.render_binned_mesh_instances_cpu[index])
}

///|
pub fn[K] RenderMultidrawableBatchSet::gpu_instance_at(
  self : RenderMultidrawableBatchSet[K],
  index : RenderBinnedMeshInstanceIndex,
) -> GpuRenderBinnedMeshInstance? {
  let raw_index = index.to_int()
  if raw_index < 0 ||
    raw_index >= self.gpu_buffers.render_binned_mesh_instance_buffer.length() {
    return None
  }
  Some(self.gpu_buffers.render_binned_mesh_instance_buffer[raw_index])
}

///|
pub fn[K] RenderMultidrawableBatchSet::indirect_parameter_count(
  self : RenderMultidrawableBatchSet[K],
) -> Int {
  self.indirect_parameters_offset_to_bin_index.length()
}

///|
pub fn[K] RenderMultidrawableBatchSet::for_each_bin_index(
  self : RenderMultidrawableBatchSet[K],
  visit : (K, RenderBinIndex) -> Unit,
) -> Unit {
  for bin_key, bin_index in self.bin_key_to_bin_index {
    visit(bin_key, bin_index)
  }
}

///|
pub fn[K] RenderMultidrawableBatchSet::for_each_cpu_instance(
  self : RenderMultidrawableBatchSet[K],
  visit : (CpuRenderBinnedMeshInstance) -> Unit,
) -> Unit {
  for instance in self.render_binned_mesh_instances_cpu {
    visit(instance)
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::CachedBinnedEntity`.
// MoonBit represents `BinnedPhaseItem` associated types as explicit generic
// batch-set and bin-key parameters at the package seam.
pub struct CachedBinnedEntity[BatchSetKey, BinKey] {
  cached_bin_key : CachedBinKey[BatchSetKey, BinKey]?
}

///|
pub fn[BatchSetKey, BinKey] CachedBinnedEntity::new(
  cached_bin_key : CachedBinKey[BatchSetKey, BinKey]?,
) -> CachedBinnedEntity[BatchSetKey, BinKey] {
  { cached_bin_key, }
}

///|
pub fn[BatchSetKey, BinKey] CachedBinnedEntity::cached_bin_key(
  self : CachedBinnedEntity[BatchSetKey, BinKey],
) -> CachedBinKey[BatchSetKey, BinKey]? {
  self.cached_bin_key
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_phase/mod.rs::CachedBinKey`.
pub struct CachedBinKey[BatchSetKey, BinKey] {
  batch_set_key : BatchSetKey
  bin_key : BinKey
  phase_type : BinnedRenderPhaseType
}

///|
pub fn[BatchSetKey, BinKey] CachedBinKey::new(
  batch_set_key : BatchSetKey,
  bin_key : BinKey,
  phase_type : BinnedRenderPhaseType,
) -> CachedBinKey[BatchSetKey, BinKey] {
  { batch_set_key, bin_key, phase_type }
}

///|
pub fn[BatchSetKey, BinKey] CachedBinKey::batch_set_key(
  self : CachedBinKey[BatchSetKey, BinKey],
) -> BatchSetKey {
  self.batch_set_key
}

///|
pub fn[BatchSetKey, BinKey] CachedBinKey::bin_key(
  self : CachedBinKey[BatchSetKey, BinKey],
) -> BinKey {
  self.bin_key
}

///|
pub fn[BatchSetKey, BinKey] CachedBinKey::phase_type(
  self : CachedBinKey[BatchSetKey, BinKey],
) -> BinnedRenderPhaseType {
  self.phase_type
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhaseBatch`.
pub struct BinnedRenderPhaseBatch {
  representative_entity : (@core.Entity, @render_sync_world.MainEntity)
  instance_range : PhaseItemBatchRange
  extra_index : PhaseItemExtraIndex
}

///|
pub fn BinnedRenderPhaseBatch::new(
  representative_entity : (@core.Entity, @render_sync_world.MainEntity),
  instance_range : PhaseItemBatchRange,
  extra_index : PhaseItemExtraIndex,
) -> BinnedRenderPhaseBatch {
  { representative_entity, instance_range, extra_index }
}

///|
pub fn BinnedRenderPhaseBatch::representative_entity(
  self : BinnedRenderPhaseBatch,
) -> (@core.Entity, @render_sync_world.MainEntity) {
  self.representative_entity
}

///|
pub fn BinnedRenderPhaseBatch::instance_range(
  self : BinnedRenderPhaseBatch,
) -> PhaseItemBatchRange {
  self.instance_range
}

///|
pub fn BinnedRenderPhaseBatch::extra_index(
  self : BinnedRenderPhaseBatch,
) -> PhaseItemExtraIndex {
  self.extra_index
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhaseBatchSet`.
pub struct BinnedRenderPhaseBatchSet[BK] {
  first_batch : BinnedRenderPhaseBatch
  bin_key : BK
  batch_count : Int
  index : Int
  first_work_item_index : Int
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::new(
  first_batch : BinnedRenderPhaseBatch,
  bin_key : BK,
  batch_count : Int,
  index : Int,
  first_work_item_index : Int,
) -> BinnedRenderPhaseBatchSet[BK] {
  { first_batch, bin_key, batch_count, index, first_work_item_index }
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::first_batch(
  self : BinnedRenderPhaseBatchSet[BK],
) -> BinnedRenderPhaseBatch {
  self.first_batch
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::bin_key(
  self : BinnedRenderPhaseBatchSet[BK],
) -> BK {
  self.bin_key
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::batch_count(
  self : BinnedRenderPhaseBatchSet[BK],
) -> Int {
  self.batch_count
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::index(
  self : BinnedRenderPhaseBatchSet[BK],
) -> Int {
  self.index
}

///|
pub fn[BK] BinnedRenderPhaseBatchSet::first_work_item_index(
  self : BinnedRenderPhaseBatchSet[BK],
) -> Int {
  self.first_work_item_index
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhaseBatchSets`.
pub(all) enum BinnedRenderPhaseBatchSets[BK] {
  DynamicUniforms(Array[Array[BinnedRenderPhaseBatch]])
  Direct(Array[BinnedRenderPhaseBatch])
  MultidrawIndirect(Array[BinnedRenderPhaseBatchSet[BK]])
}

///|
#warnings("-unused_value")
fn[BK] BinnedRenderPhaseBatchSets::clear(
  self : BinnedRenderPhaseBatchSets[BK],
) -> Unit {
  match self {
    DynamicUniforms(batch_sets) => batch_sets.clear()
    Direct(batches) => batches.clear()
    MultidrawIndirect(batch_sets) => batch_sets.clear()
  }
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
  { instance_index, extra_index }
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
  { kind: NoEntities }
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
          None,
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
    None => indices.extra_index() == None
    Some(first_index) =>
      match indices.extra_index() {
        IndirectParametersIndex(range_start, _, _) =>
          first_index + instance_range.count() == range_start
        DynamicOffset(_) | None => false
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
  self.kind = Dense(dense)
}

///|
pub fn UnbatchableBinnedEntityIndexSet::add(
  self : UnbatchableBinnedEntityIndexSet,
  indices : UnbatchableBinnedEntityIndices,
) -> Unit {
  match self.kind {
    NoEntities =>
      match indices.extra_index() {
        DynamicOffset(_) => self.kind = Dense([indices])
        None =>
          self.kind = Sparse(
            PhaseItemBatchRange::new(
              indices.instance_index(),
              indices.instance_index() + 1,
            ),
            None,
          )
        IndirectParametersIndex(range_start, _, _) =>
          self.kind = Sparse(
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
        self.kind = Sparse(
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
    Sparse(_, _) => self.kind = NoEntities
    NoEntities => ()
  }
}

///|
struct BinnedRenderPhaseEntities {
  entries : Array[(@render_sync_world.MainEntity, @core.Entity)]
  indices : Map[@render_sync_world.MainEntity, Int]
}

///|
fn BinnedRenderPhaseEntities::new() -> BinnedRenderPhaseEntities {
  { entries: [], indices: Map([]) }
}

///|
fn BinnedRenderPhaseEntities::insert(
  self : BinnedRenderPhaseEntities,
  main_entity : @render_sync_world.MainEntity,
  entity : @core.Entity,
) -> Unit {
  match self.indices.get(main_entity) {
    Some(index) => self.entries[index] = (main_entity, entity)
    None => {
      self.indices.set(main_entity, self.entries.length())
      self.entries.push((main_entity, entity))
    }
  }
}

///|
fn BinnedRenderPhaseEntities::remove(
  self : BinnedRenderPhaseEntities,
  main_entity : @render_sync_world.MainEntity,
) -> Unit {
  guard self.indices.get(main_entity) is Some(index) else { return }
  self.indices.remove(main_entity)
  let last_index = self.entries.length() - 1
  if index != last_index {
    let displaced = self.entries[last_index]
    self.entries[index] = displaced
    self.indices.set(displaced.0, index)
  }
  self.entries.pop() |> ignore
}

///|
fn BinnedRenderPhaseEntities::is_empty(
  self : BinnedRenderPhaseEntities,
) -> Bool {
  self.entries.is_empty()
}

///|
fn BinnedRenderPhaseEntities::entries(
  self : BinnedRenderPhaseEntities,
) -> ArrayView[(@render_sync_world.MainEntity, @core.Entity)] {
  self.entries[:]
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::UnbatchableBinnedEntities`.
pub struct UnbatchableBinnedEntities {
  entities : BinnedRenderPhaseEntities
  buffer_indices : UnbatchableBinnedEntityIndexSet
}

///|
fn UnbatchableBinnedEntities::new(
  main_entity : @render_sync_world.MainEntity,
  entity : @core.Entity,
) -> UnbatchableBinnedEntities {
  let entities = BinnedRenderPhaseEntities::new()
  entities.insert(main_entity, entity)
  { entities, buffer_indices: UnbatchableBinnedEntityIndexSet::new() }
}

///|
pub fn UnbatchableBinnedEntities::entities(
  self : UnbatchableBinnedEntities,
) -> ArrayView[(@render_sync_world.MainEntity, @core.Entity)] {
  self.entities.entries()
}

///|
pub fn UnbatchableBinnedEntities::buffer_indices(
  self : UnbatchableBinnedEntities,
) -> UnbatchableBinnedEntityIndexSet {
  self.buffer_indices
}

///|
fn UnbatchableBinnedEntities::insert(
  self : UnbatchableBinnedEntities,
  main_entity : @render_sync_world.MainEntity,
  entity : @core.Entity,
) -> Unit {
  self.entities.insert(main_entity, entity)
}

///|
fn UnbatchableBinnedEntities::remove(
  self : UnbatchableBinnedEntities,
  main_entity : @render_sync_world.MainEntity,
) -> Unit {
  self.entities.remove(main_entity)
}

///|
fn UnbatchableBinnedEntities::is_empty(
  self : UnbatchableBinnedEntities,
) -> Bool {
  self.entities.is_empty()
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::NonMeshEntities`.
pub struct NonMeshEntities {
  entities : BinnedRenderPhaseEntities
}

///|
fn NonMeshEntities::new(
  main_entity : @render_sync_world.MainEntity,
  entity : @core.Entity,
) -> NonMeshEntities {
  let entities = BinnedRenderPhaseEntities::new()
  entities.insert(main_entity, entity)
  { entities, }
}

///|
pub fn NonMeshEntities::entities(
  self : NonMeshEntities,
) -> ArrayView[(@render_sync_world.MainEntity, @core.Entity)] {
  self.entities.entries()
}

///|
fn NonMeshEntities::insert(
  self : NonMeshEntities,
  main_entity : @render_sync_world.MainEntity,
  entity : @core.Entity,
) -> Unit {
  self.entities.insert(main_entity, entity)
}

///|
fn NonMeshEntities::remove(
  self : NonMeshEntities,
  main_entity : @render_sync_world.MainEntity,
) -> Unit {
  self.entities.remove(main_entity)
}

///|
fn NonMeshEntities::is_empty(self : NonMeshEntities) -> Bool {
  self.entities.is_empty()
}

///|
pub struct BinnedRenderPhaseMultidrawableEntry[BatchSetKey, BinKey] {
  batch_set_key : BatchSetKey
  batch_set : RenderMultidrawableBatchSet[BinKey]
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseMultidrawableEntry::batch_set_key(
  self : BinnedRenderPhaseMultidrawableEntry[BatchSetKey, BinKey],
) -> BatchSetKey {
  self.batch_set_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseMultidrawableEntry::batch_set(
  self : BinnedRenderPhaseMultidrawableEntry[BatchSetKey, BinKey],
) -> RenderMultidrawableBatchSet[BinKey] {
  self.batch_set
}

///|
pub struct BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey] {
  batch_set_key : BatchSetKey
  bin_key : BinKey
  bin : RenderBin
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseBatchableEntry::batch_set_key(
  self : BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey],
) -> BatchSetKey {
  self.batch_set_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseBatchableEntry::bin_key(
  self : BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey],
) -> BinKey {
  self.bin_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseBatchableEntry::bin(
  self : BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey],
) -> RenderBin {
  self.bin
}

///|
pub struct BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey] {
  batch_set_key : BatchSetKey
  bin_key : BinKey
  entities : UnbatchableBinnedEntities
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseUnbatchableEntry::batch_set_key(
  self : BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey],
) -> BatchSetKey {
  self.batch_set_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseUnbatchableEntry::bin_key(
  self : BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey],
) -> BinKey {
  self.bin_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseUnbatchableEntry::entities(
  self : BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey],
) -> UnbatchableBinnedEntities {
  self.entities
}

///|
pub struct BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey] {
  batch_set_key : BatchSetKey
  bin_key : BinKey
  entities : NonMeshEntities
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseNonMeshEntry::batch_set_key(
  self : BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey],
) -> BatchSetKey {
  self.batch_set_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseNonMeshEntry::bin_key(
  self : BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey],
) -> BinKey {
  self.bin_key
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhaseNonMeshEntry::entities(
  self : BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey],
) -> NonMeshEntities {
  self.entities
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhase`.
// MoonBit represents `BinnedPhaseItem` associated types as explicit generic
// batch-set and bin-key parameters. Arrays retain the insertion order supplied
// by Bevy's `IndexMap` while the entry types retain the same key ownership.
pub struct BinnedRenderPhase[BatchSetKey, BinKey] {
  multidrawable_meshes : Array[
    BinnedRenderPhaseMultidrawableEntry[BatchSetKey, BinKey],
  ]
  batchable_meshes : Array[BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey]]
  unbatchable_meshes : Array[
    BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey],
  ]
  non_mesh_items : Array[BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey]]
  batch_sets : BinnedRenderPhaseBatchSets[BinKey]
  cached_entity_bin_keys : Map[
    @render_sync_world.MainEntity,
    CachedBinnedEntity[BatchSetKey, BinKey],
  ]
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::new(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> BinnedRenderPhase[BatchSetKey, BinKey] {
  {
    multidrawable_meshes: [],
    batchable_meshes: [],
    unbatchable_meshes: [],
    non_mesh_items: [],
    batch_sets: match gpu_preprocessing_mode {
      Culling => MultidrawIndirect([])
      PreprocessingOnly => Direct([])
      None => DynamicUniforms([])
    },
    cached_entity_bin_keys: Map([]),
    gpu_preprocessing_mode,
  }
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::gpu_preprocessing_mode(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> @render_batching.GpuPreprocessingMode {
  self.gpu_preprocessing_mode
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::multidrawable_meshes(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> ArrayView[BinnedRenderPhaseMultidrawableEntry[BatchSetKey, BinKey]] {
  self.multidrawable_meshes[:]
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::batchable_meshes(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> ArrayView[BinnedRenderPhaseBatchableEntry[BatchSetKey, BinKey]] {
  self.batchable_meshes[:]
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::unbatchable_meshes(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> ArrayView[BinnedRenderPhaseUnbatchableEntry[BatchSetKey, BinKey]] {
  self.unbatchable_meshes[:]
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::non_mesh_items(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> ArrayView[BinnedRenderPhaseNonMeshEntry[BatchSetKey, BinKey]] {
  self.non_mesh_items[:]
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::batch_sets(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> BinnedRenderPhaseBatchSets[BinKey] {
  self.batch_sets
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::update_cache(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  main_entity : @render_sync_world.MainEntity,
  cached_bin_key : CachedBinKey[BatchSetKey, BinKey]?,
) -> Unit {
  self.cached_entity_bin_keys.set(
    main_entity,
    CachedBinnedEntity::new(cached_bin_key),
  )
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::cached_bin_key(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  main_entity : @render_sync_world.MainEntity,
) -> CachedBinKey[BatchSetKey, BinKey]? {
  match self.cached_entity_bin_keys.get(main_entity) {
    Some(cached_entity) => cached_entity.cached_bin_key()
    None => None
  }
}

///|
fn[BatchSetKey : Eq, BinKey] BinnedRenderPhase::find_multidrawable(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batch_set_key : BatchSetKey,
) -> Int {
  for index in 0..<self.multidrawable_meshes.length() {
    if self.multidrawable_meshes[index].batch_set_key == batch_set_key {
      return index
    }
  }
  -1
}

///|
fn[BatchSetKey : Eq, BinKey : Eq] BinnedRenderPhase::find_batchable(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batch_set_key : BatchSetKey,
  bin_key : BinKey,
) -> Int {
  for index in 0..<self.batchable_meshes.length() {
    let entry = self.batchable_meshes[index]
    if entry.batch_set_key == batch_set_key && entry.bin_key == bin_key {
      return index
    }
  }
  -1
}

///|
fn[BatchSetKey : Eq, BinKey : Eq] BinnedRenderPhase::find_unbatchable(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batch_set_key : BatchSetKey,
  bin_key : BinKey,
) -> Int {
  for index in 0..<self.unbatchable_meshes.length() {
    let entry = self.unbatchable_meshes[index]
    if entry.batch_set_key == batch_set_key && entry.bin_key == bin_key {
      return index
    }
  }
  -1
}

///|
fn[BatchSetKey : Eq, BinKey : Eq] BinnedRenderPhase::find_non_mesh(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batch_set_key : BatchSetKey,
  bin_key : BinKey,
) -> Int {
  for index in 0..<self.non_mesh_items.length() {
    let entry = self.non_mesh_items[index]
    if entry.batch_set_key == batch_set_key && entry.bin_key == bin_key {
      return index
    }
  }
  -1
}

///|
pub fn[BatchSetKey : Eq, BinKey : Eq + Hash] BinnedRenderPhase::add(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batch_set_key : BatchSetKey,
  bin_key : BinKey,
  representative_entity : (@core.Entity, @render_sync_world.MainEntity),
  input_uniform_index : InputUniformIndex,
  phase_type : BinnedRenderPhaseType,
) -> Unit {
  let effective_phase_type = if self.gpu_preprocessing_mode == PreprocessingOnly &&
    phase_type == MultidrawableMesh {
    BatchableMesh
  } else {
    phase_type
  }
  match effective_phase_type {
    MultidrawableMesh => {
      let index = self.find_multidrawable(batch_set_key)
      if index >= 0 {
        self.multidrawable_meshes[index].batch_set.insert(
          bin_key,
          representative_entity.1,
          input_uniform_index,
        )
      } else {
        let batch_set : RenderMultidrawableBatchSet[BinKey] = RenderMultidrawableBatchSet::new()
        batch_set.insert(bin_key, representative_entity.1, input_uniform_index)
        self.multidrawable_meshes.push({ batch_set_key, batch_set })
      }
    }
    BatchableMesh => {
      let index = self.find_batchable(batch_set_key, bin_key)
      if index >= 0 {
        self.batchable_meshes[index].bin.insert(
          representative_entity.1,
          input_uniform_index,
        )
      } else {
        self.batchable_meshes.push({
          batch_set_key,
          bin_key,
          bin: RenderBin::from_entity(
            representative_entity.1,
            input_uniform_index,
          ),
        })
      }
    }
    UnbatchableMesh => {
      let index = self.find_unbatchable(batch_set_key, bin_key)
      if index >= 0 {
        self.unbatchable_meshes[index].entities.insert(
          representative_entity.1,
          representative_entity.0,
        )
      } else {
        self.unbatchable_meshes.push({
          batch_set_key,
          bin_key,
          entities: UnbatchableBinnedEntities::new(
            representative_entity.1,
            representative_entity.0,
          ),
        })
      }
    }
    NonMesh => {
      let index = self.find_non_mesh(batch_set_key, bin_key)
      if index >= 0 {
        self.non_mesh_items[index].entities.insert(
          representative_entity.1,
          representative_entity.0,
        )
      } else {
        self.non_mesh_items.push({
          batch_set_key,
          bin_key,
          entities: NonMeshEntities::new(
            representative_entity.1,
            representative_entity.0,
          ),
        })
      }
    }
  }
  self.update_cache(
    representative_entity.1,
    Some(CachedBinKey::new(batch_set_key, bin_key, effective_phase_type)),
  )
}

///|
fn[T] binned_render_phase_swap_remove(array : Array[T], index : Int) -> Unit {
  let last_index = array.length() - 1
  if index != last_index {
    array[index] = array[last_index]
  }
  array.pop() |> ignore
}

///|
pub fn[BatchSetKey : Eq, BinKey : Eq + Hash] BinnedRenderPhase::remove(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  main_entity : @render_sync_world.MainEntity,
) -> Unit {
  let cached = match self.cached_entity_bin_keys.get(main_entity) {
    Some(value) => value
    None => return
  }
  self.cached_entity_bin_keys.remove(main_entity)
  guard cached.cached_bin_key() is Some(cached_bin_key) else { return }
  match cached_bin_key.phase_type() {
    MultidrawableMesh => {
      let index = self.find_multidrawable(cached_bin_key.batch_set_key())
      if index >= 0 {
        let entry = self.multidrawable_meshes[index]
        entry.batch_set.remove(main_entity, cached_bin_key.bin_key())
        if entry.batch_set.is_empty() {
          binned_render_phase_swap_remove(self.multidrawable_meshes, index)
        }
      }
    }
    BatchableMesh => {
      let index = self.find_batchable(
        cached_bin_key.batch_set_key(),
        cached_bin_key.bin_key(),
      )
      if index >= 0 {
        let entry = self.batchable_meshes[index]
        entry.bin.remove(main_entity)
        if entry.bin.is_empty() {
          binned_render_phase_swap_remove(self.batchable_meshes, index)
        }
      }
    }
    UnbatchableMesh => {
      let index = self.find_unbatchable(
        cached_bin_key.batch_set_key(),
        cached_bin_key.bin_key(),
      )
      if index >= 0 {
        let entry = self.unbatchable_meshes[index]
        entry.entities.remove(main_entity)
        if entry.entities.is_empty() {
          binned_render_phase_swap_remove(self.unbatchable_meshes, index)
        }
      }
    }
    NonMesh => {
      let index = self.find_non_mesh(
        cached_bin_key.batch_set_key(),
        cached_bin_key.bin_key(),
      )
      if index >= 0 {
        let entry = self.non_mesh_items[index]
        entry.entities.remove(main_entity)
        if entry.entities.is_empty() {
          binned_render_phase_swap_remove(self.non_mesh_items, index)
        }
      }
    }
  }
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::is_empty(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> Bool {
  self.multidrawable_meshes.is_empty() &&
  self.batchable_meshes.is_empty() &&
  self.unbatchable_meshes.is_empty() &&
  self.non_mesh_items.is_empty()
}

///|
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::prepare_for_new_frame(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
) -> Unit {
  self.batch_sets.clear()
  for entry in self.unbatchable_meshes {
    entry.entities.buffer_indices.clear()
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/no_gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::prepare_cpu_buffers(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  batched_instance_buffer : @render_batching.BatchedInstanceBuffer[Unit],
  get_binned_index : (@render_sync_world.MainEntity) -> InputUniformIndex?,
) -> Unit {
  guard self.batch_sets is DynamicUniforms(batch_sets) else {
    abort("CPU binned phase preparation requires dynamic-uniform batch sets")
  }
  for entry in self.batchable_meshes {
    let batches : Array[BinnedRenderPhaseBatch] = []
    let mut representative : @render_sync_world.MainEntity? = None
    let start = batched_instance_buffer.len()
    for entity_and_input_uniform_index in entry.bin.entities() {
      let main_entity = entity_and_input_uniform_index.0
      guard get_binned_index(main_entity) is Some(_) else { continue }
      if representative is None {
        representative = Some(main_entity)
      }
      batched_instance_buffer.push(())
    }
    if representative is Some(representative_entity) {
      batches.push(
        BinnedRenderPhaseBatch::new(
          (@core.Entity::placeholder(), representative_entity),
          PhaseItemBatchRange::new(start, batched_instance_buffer.len()),
          PhaseItemExtraIndex::none(),
        ),
      )
    }
    batch_sets.push(batches)
  }
  for entry in self.unbatchable_meshes {
    let entities = entry.entities.entities()
    for entity_pair in entities {
      let main_entity = entity_pair.0
      guard get_binned_index(main_entity) is Some(_) else { continue }
      let output_index = batched_instance_buffer.len()
      batched_instance_buffer.push(())
      entry.entities.buffer_indices.add(
        UnbatchableBinnedEntityIndices::new(
          output_index,
          PhaseItemExtraIndex::none(),
        ),
      )
    }
  }
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs::batch_and_prepare_binned_render_phase`.
// The callback parameters are MoonBit's explicit representation of Bevy's
// `GetFullBatchData::get_binned_index` and `BinnedPhaseItem::BatchSetKey::indexed`.
pub fn[BatchSetKey, BinKey] BinnedRenderPhase::prepare_gpu_buffers(
  self : BinnedRenderPhase[BatchSetKey, BinKey],
  retained_view_key : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
  phase_batched_instance_buffers : @render_batching.PhaseBatchedInstanceBuffers[
    Unit,
  ],
  phase_indirect_parameters_buffers : @render_batching.PhaseIndirectParametersBuffers,
  get_binned_index : (@render_sync_world.MainEntity) -> InputUniformIndex?,
  batch_set_key_indexed : (BatchSetKey) -> Bool,
) -> Unit {
  let work_item_buffer = @render_batching.get_or_create_work_item_buffer(
    phase_batched_instance_buffers.buffers.work_item_buffers,
    retained_view_key,
    no_indirect_drawing,
    enable_gpu_occlusion_culling,
  )
  @render_batching.init_work_item_buffers(
    work_item_buffer,
    phase_batched_instance_buffers.buffers.late_indexed_indirect_parameters_buffer,
    phase_batched_instance_buffers.buffers.late_non_indexed_indirect_parameters_buffer,
  )

  // Prepare unbatchables first. CPU-authored work items must precede the
  // multidraw work items authored by the bin-unpacking compute shader.
  for entry in self.unbatchable_meshes {
    let indexed = batch_set_key_indexed(entry.batch_set_key)
    let mut indirect_parameters_index : Int? = if no_indirect_drawing {
      None
    } else {
      Some(
        phase_indirect_parameters_buffers.buffers.allocate(
          indexed,
          entry.entities.entities().length(),
        ),
      )
    }
    for entity_pair in entry.entities.entities() {
      let main_entity = entity_pair.0
      guard get_binned_index(main_entity) is Some(input_uniform_index) else {
        continue
      }
      let output_index = phase_batched_instance_buffers.buffers.data_buffer.len()
      phase_batched_instance_buffers.buffers.data_buffer.push(())
      if no_indirect_drawing {
        work_item_buffer.push(
          indexed,
          @render_batching.PreprocessWorkItem::new(
            input_uniform_index.to_int(),
            output_index,
          ),
        )
        entry.entities.buffer_indices.add(
          UnbatchableBinnedEntityIndices::new(
            output_index,
            PhaseItemExtraIndex::none(),
          ),
        )
      } else {
        let index = indirect_parameters_index.unwrap()
        phase_indirect_parameters_buffers.buffers.set_cpu_metadata(
          indexed,
          index,
          @render_batching.IndirectParametersCpuMetadata::new(output_index, -1),
        )
        work_item_buffer.push(
          indexed,
          @render_batching.PreprocessWorkItem::new(
            input_uniform_index.to_int(),
            index,
          ),
        )
        entry.entities.buffer_indices.add(
          UnbatchableBinnedEntityIndices::new(
            index,
            PhaseItemExtraIndex::indirect_parameters_index(index, index + 1),
          ),
        )
        phase_indirect_parameters_buffers.buffers.add_batch_set(indexed, index)
        indirect_parameters_index = Some(index + 1)
      }
    }
  }

  // Prepare batchable bins.
  for entry in self.batchable_meshes {
    let indexed = batch_set_key_indexed(entry.batch_set_key)
    let entities = entry.bin.entities()
    if entities.length() == 0 {
      continue
    }
    let output_start = phase_batched_instance_buffers.buffers.data_buffer.len()
    let indirect_parameters_index : Int? = if no_indirect_drawing {
      None
    } else {
      let index = phase_indirect_parameters_buffers.buffers.allocate(indexed, 1)
      let batch_set_index = phase_indirect_parameters_buffers.buffers
        .get_next_batch_set_index(indexed)
        .unwrap()
      phase_indirect_parameters_buffers.buffers.set_cpu_metadata(
        indexed,
        index,
        @render_batching.IndirectParametersCpuMetadata::new(
          output_start, batch_set_index,
        ),
      )
      Some(index)
    }
    let mut output_end = output_start
    for entity_and_input_uniform_index in entities {
      let input_uniform_index = entity_and_input_uniform_index.1
      phase_batched_instance_buffers.buffers.data_buffer.push(())
      work_item_buffer.push(
        indexed,
        @render_batching.PreprocessWorkItem::new(
          input_uniform_index.to_int(),
          match indirect_parameters_index {
            Some(index) => index
            None => output_end
          },
        ),
      )
      output_end += 1
    }
    let representative = entities[0].0
    let batch = BinnedRenderPhaseBatch::new(
      (@core.Entity::placeholder(), representative),
      PhaseItemBatchRange::new(output_start, output_end),
      PhaseItemExtraIndex::maybe_indirect_parameters_index(
        indirect_parameters_index,
      ),
    )
    match self.batch_sets {
      DynamicUniforms(_) =>
        abort("GPU binned phase preparation cannot use dynamic-uniform batches")
      Direct(batches) => batches.push(batch)
      MultidrawIndirect(batch_sets) => {
        let batch_set_index = phase_indirect_parameters_buffers.buffers.batch_set_count(
          indexed,
        )
        batch_sets.push(
          BinnedRenderPhaseBatchSet::new(
            batch,
            entry.bin_key,
            1,
            batch_set_index,
            0,
          ),
        )
      }
    }
  }

  // Prepare multidrawable batch sets. As in Bevy, these reserve work items
  // for the GPU bin-unpacking step instead of authoring them on the CPU.
  guard self.batch_sets is MultidrawIndirect(batch_sets) else { return }
  for entry in self.multidrawable_meshes {
    let indexed = batch_set_key_indexed(entry.batch_set_key)
    let batch_set = entry.batch_set
    guard batch_set.representative_entry()
      is Some((first_bin_key, first_bin_index)) else {
      continue
    }
    let first_bin = match batch_set.bin(first_bin_index) {
      Some(value) => value
      None => abort("At least one bin must be present in each batch set")
    }
    let representative = batch_set
      .representative_entity()
      .unwrap_or(
        @render_sync_world.MainEntity::new(@core.Entity::placeholder()),
      )
    let output_start = phase_batched_instance_buffers.buffers.data_buffer.len()
    let first_work_item_index = if indexed {
      work_item_buffer.indexed_len()
    } else {
      work_item_buffer.non_indexed_len()
    }
    let batch_set_index = phase_indirect_parameters_buffers.buffers.batch_set_count(
      indexed,
    )
    let bin_count = batch_set.bin_count()
    let indirect_parameters_base = phase_indirect_parameters_buffers.buffers.allocate(
      indexed, bin_count,
    )
    let cpu_metadata_offset = phase_indirect_parameters_buffers.buffers.cpu_metadata_len(
        indexed,
      ) -
      bin_count
    let work_item_count = Ref(0)
    batch_set.for_each_bin_index(fn(_bin_key, bin_index) {
      let bin = match batch_set.bin(bin_index) {
        Some(value) => value
        None => abort("Bin not present")
      }
      let indirect_parameters_offset = batch_set
        .indirect_parameters_offset_for_bin(bin_index)
        .unwrap()
        .reinterpret_as_int()
      phase_indirect_parameters_buffers.buffers.set_cpu_metadata(
        indexed,
        cpu_metadata_offset + indirect_parameters_offset,
        @render_batching.IndirectParametersCpuMetadata::new(
          phase_batched_instance_buffers.buffers.data_buffer.len(),
          batch_set_index,
        ),
      )
      let bin_entity_count = bin.entity_count()
      work_item_buffer.push_multiple_uninit(indexed, bin_entity_count)
      for _ in 0..<bin_entity_count {
        phase_batched_instance_buffers.buffers.data_buffer.push(())
      }
      work_item_count.val += bin_entity_count
    })
    phase_indirect_parameters_buffers.buffers.add_batch_set(
      indexed, indirect_parameters_base,
    )
    work_item_buffer.push_multiple_late_uninit(indexed, work_item_count.val)
    batch_sets.push(
      BinnedRenderPhaseBatchSet::new(
        BinnedRenderPhaseBatch::new(
          (@core.Entity::placeholder(), representative),
          PhaseItemBatchRange::new(
            output_start,
            output_start + first_bin.entity_count(),
          ),
          PhaseItemExtraIndex::indirect_parameters_index(
            indirect_parameters_base,
            indirect_parameters_base + 1,
          ),
        ),
        first_bin_key,
        bin_count,
        batch_set_index,
        first_work_item_index,
      ),
    )
  }
}
