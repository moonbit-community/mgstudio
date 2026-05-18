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
// Bevy source: `bevy/crates/bevy_render/src/mesh/allocator.rs`.

///|
pub const MESH_ALLOCATOR_COPY_BUFFER_ALIGNMENT : Int = 4

///|
pub(all) enum MeshAllocatorElementClass {
  Vertex
  Index
} derive(Eq, Debug)

///|
pub(all) enum MeshAllocatorSlabKind {
  General
  LargeObject
} derive(Eq, Debug)

///|
pub(all) enum MeshAllocatorSlabGrowthKind {
  NoGrowthNeeded
  NeededGrowth
  CantGrow
} derive(Eq, Debug)

///|
pub struct MeshAllocatorSettings {
  min_slab_size : Int
  max_slab_size : Int
  large_threshold : Int
  growth_factor : Float
}

///|
pub fn MeshAllocatorSettings::new(
  min_slab_size~ : Int,
  max_slab_size~ : Int,
  large_threshold~ : Int,
  growth_factor~ : Float,
) -> MeshAllocatorSettings {
  MeshAllocatorSettings::{
    min_slab_size,
    max_slab_size,
    large_threshold,
    growth_factor,
  }
}

///|
pub fn MeshAllocatorSettings::default() -> MeshAllocatorSettings {
  MeshAllocatorSettings::new(
    min_slab_size=1024 * 1024,
    max_slab_size=1024 * 1024 * 512,
    large_threshold=1024 * 1024 * 256,
    growth_factor=1.5F,
  )
}

///|
pub impl Default for MeshAllocatorSettings with default() {
  MeshAllocatorSettings::default()
}

///|
pub fn MeshAllocatorSettings::min_slab_size(
  self : MeshAllocatorSettings,
) -> Int {
  self.min_slab_size
}

///|
pub fn MeshAllocatorSettings::max_slab_size(
  self : MeshAllocatorSettings,
) -> Int {
  self.max_slab_size
}

///|
pub fn MeshAllocatorSettings::large_threshold(
  self : MeshAllocatorSettings,
) -> Int {
  self.large_threshold
}

///|
pub fn MeshAllocatorSettings::growth_factor(
  self : MeshAllocatorSettings,
) -> Float {
  self.growth_factor
}

///|
pub struct MeshAllocatorElementLayout {
  class : MeshAllocatorElementClass
  size : Int
  elements_per_slot : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorElementLayout::new(
  class : MeshAllocatorElementClass,
  size : Int,
) -> MeshAllocatorElementLayout {
  if size <= 0 {
    abort("mesh allocator element size must be positive")
  }
  let elements_per_slot = match size % MESH_ALLOCATOR_COPY_BUFFER_ALIGNMENT {
    0 => 1
    1 => 4
    2 => 2
    _ => 4
  }
  MeshAllocatorElementLayout::{ class, size, elements_per_slot }
}

///|
pub fn MeshAllocatorElementLayout::vertex(
  vertex_stride : Int,
) -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Vertex, vertex_stride)
}

///|
pub fn MeshAllocatorElementLayout::index_u16() -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Index, 2)
}

///|
pub fn MeshAllocatorElementLayout::index_u32() -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Index, 4)
}

///|
pub fn MeshAllocatorElementLayout::class(
  self : MeshAllocatorElementLayout,
) -> MeshAllocatorElementClass {
  self.class
}

///|
pub fn MeshAllocatorElementLayout::size(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.size
}

///|
pub fn MeshAllocatorElementLayout::elements_per_slot(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.elements_per_slot
}

///|
pub fn MeshAllocatorElementLayout::slot_size(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.size * self.elements_per_slot
}

///|
pub struct MeshAllocatorSlabGrowth {
  kind : MeshAllocatorSlabGrowthKind
  old_slot_capacity : Int
  current_slot_capacity : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlabGrowth::kind(
  self : MeshAllocatorSlabGrowth,
) -> MeshAllocatorSlabGrowthKind {
  self.kind
}

///|
pub fn MeshAllocatorSlabGrowth::old_slot_capacity(
  self : MeshAllocatorSlabGrowth,
) -> Int {
  self.old_slot_capacity
}

///|
pub fn MeshAllocatorSlabGrowth::current_slot_capacity(
  self : MeshAllocatorSlabGrowth,
) -> Int {
  self.current_slot_capacity
}

///|
pub struct MeshAllocatorSlabPlan {
  slab_id : Int
  kind : MeshAllocatorSlabKind
  layout : MeshAllocatorElementLayout
  offset : Int
  slot_count : Int
  current_slot_capacity : Int
  growth : MeshAllocatorSlabGrowth
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlabPlan::slab_id(self : MeshAllocatorSlabPlan) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorSlabPlan::kind(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorSlabKind {
  self.kind
}

///|
pub fn MeshAllocatorSlabPlan::layout(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorElementLayout {
  self.layout
}

///|
pub fn MeshAllocatorSlabPlan::offset(self : MeshAllocatorSlabPlan) -> Int {
  self.offset
}

///|
pub fn MeshAllocatorSlabPlan::slot_count(self : MeshAllocatorSlabPlan) -> Int {
  self.slot_count
}

///|
pub fn MeshAllocatorSlabPlan::current_slot_capacity(
  self : MeshAllocatorSlabPlan,
) -> Int {
  self.current_slot_capacity
}

///|
pub fn MeshAllocatorSlabPlan::growth(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorSlabGrowth {
  self.growth
}

///|
fn mesh_allocator_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("mesh allocator divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}

///|
fn mesh_allocator_min_allocator_size(slot_count : Int) -> Int {
  if slot_count <= 0 {
    1
  } else {
    slot_count
  }
}

///|
fn mesh_allocator_initial_general_slab_slot_capacity(
  layout : MeshAllocatorElementLayout,
  data_slot_count : Int,
  settings : MeshAllocatorSettings,
) -> Int {
  mesh_allocator_div_ceil(settings.min_slab_size, layout.slot_size()).max(
    mesh_allocator_min_allocator_size(data_slot_count),
  )
}

///|
fn mesh_allocator_max_general_slab_slot_capacity(
  layout : MeshAllocatorElementLayout,
  data_slot_count : Int,
  settings : MeshAllocatorSettings,
) -> Int {
  mesh_allocator_div_ceil(settings.max_slab_size, layout.slot_size()).max(
    mesh_allocator_min_allocator_size(data_slot_count),
  )
}

///|
fn mesh_allocator_growth_capacity(
  current_slot_capacity : Int,
  settings : MeshAllocatorSettings,
  layout : MeshAllocatorElementLayout,
) -> Int {
  let grown = @float.ceil(
      Float::from_int(current_slot_capacity) * settings.growth_factor,
    )
    .to_double()
    .to_int()
  let max_slots = settings.max_slab_size / layout.slot_size()
  grown.min(max_slots)
}

///|
pub fn mesh_allocator_grow_general_slab_if_necessary(
  current_slot_capacity : Int,
  new_size_in_slots : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::default(),
) -> MeshAllocatorSlabGrowth {
  let initial_slot_capacity = current_slot_capacity
  if current_slot_capacity >= new_size_in_slots {
    return MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: initial_slot_capacity,
      current_slot_capacity,
    }
  }
  let mut capacity = current_slot_capacity
  while capacity < new_size_in_slots {
    let next_capacity = mesh_allocator_growth_capacity(
      capacity, settings, layout,
    )
    if next_capacity == capacity {
      return MeshAllocatorSlabGrowth::{
        kind: CantGrow,
        old_slot_capacity: initial_slot_capacity,
        current_slot_capacity: capacity,
      }
    }
    capacity = next_capacity
  }
  MeshAllocatorSlabGrowth::{
    kind: NeededGrowth,
    old_slot_capacity: initial_slot_capacity,
    current_slot_capacity: capacity,
  }
}

///|
pub fn mesh_allocator_plan_new_general_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::default(),
) -> MeshAllocatorSlabPlan {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  let current_slot_capacity = mesh_allocator_initial_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  ignore(
    mesh_allocator_max_general_slab_slot_capacity(
      layout, data_slot_count, settings,
    ),
  )
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: General,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity,
    growth: MeshAllocatorSlabGrowth::{
      kind: NeededGrowth,
      old_slot_capacity: 0,
      current_slot_capacity,
    },
  }
}

///|
pub fn mesh_allocator_plan_large_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
) -> MeshAllocatorSlabPlan {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: LargeObject,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: data_slot_count,
    growth: MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: data_slot_count,
      current_slot_capacity: data_slot_count,
    },
  }
}

///|
pub fn mesh_allocator_should_allocate_large(
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::default(),
) -> Bool {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  data_slot_count * layout.slot_size() >=
  settings.large_threshold.min(settings.max_slab_size)
}

///|
pub(all) enum MeshAllocatorAllocationResidency {
  Pending
  Resident
} derive(Eq, Debug)

///|
pub struct MeshAllocatorSlice {
  slab_id : Int
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlice::slab_id(self : MeshAllocatorSlice) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorSlice::start(self : MeshAllocatorSlice) -> Int {
  self.start
}

///|
pub fn MeshAllocatorSlice::end(self : MeshAllocatorSlice) -> Int {
  self.end
}

///|
pub(all) struct MeshAllocatorSlabAllocation {
  mesh_id : Int
  offset : Int
  slot_count : Int
  residency : MeshAllocatorAllocationResidency
}

///|
pub(all) struct MeshAllocatorFreeRange {
  offset : Int
  slot_count : Int
}

///|
pub(all) struct MeshAllocatorSlabState {
  id : Int
  kind : MeshAllocatorSlabKind
  layout : MeshAllocatorElementLayout
  mut current_slot_capacity : Int
  max_slot_capacity : Int
  allocations : Array[MeshAllocatorSlabAllocation]
  free_ranges : Array[MeshAllocatorFreeRange]
}

///|
pub(all) struct MeshAllocatorMeshSlabEntry {
  mesh_id : Int
  slab_id : Int
}

///|
pub struct MeshAllocator {
  slabs : Array[MeshAllocatorSlabState]
  mesh_id_to_vertex_slab : Array[MeshAllocatorMeshSlabEntry]
  mesh_id_to_index_slab : Array[MeshAllocatorMeshSlabEntry]
  mut next_slab_id : Int
  general_vertex_slabs_supported : Bool
}

///|
pub fn MeshAllocator::new(
  general_vertex_slabs_supported? : Bool = true,
) -> MeshAllocator {
  MeshAllocator::{
    slabs: [],
    mesh_id_to_vertex_slab: [],
    mesh_id_to_index_slab: [],
    next_slab_id: 0,
    general_vertex_slabs_supported,
  }
}

///|
pub impl Default for MeshAllocator with default() {
  MeshAllocator::new()
}

///|
fn mesh_allocator_layout_eq(
  left : MeshAllocatorElementLayout,
  right : MeshAllocatorElementLayout,
) -> Bool {
  left.class == right.class &&
  left.size == right.size &&
  left.elements_per_slot == right.elements_per_slot
}

///|
fn mesh_allocator_data_slot_count(
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
) -> Int {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  mesh_allocator_div_ceil(data_element_count, layout.elements_per_slot())
}

///|
fn MeshAllocator::allocate_slab_id(self : MeshAllocator) -> Int {
  let slab_id = self.next_slab_id
  self.next_slab_id = self.next_slab_id + 1
  slab_id
}

///|
fn mesh_allocator_find_slab_index(
  slabs : Array[MeshAllocatorSlabState],
  slab_id : Int,
) -> Int? {
  for index in 0..<slabs.length() {
    if slabs[index].id == slab_id {
      return Some(index)
    }
  }
  None
}

///|
fn mesh_allocator_find_map_index(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  for index in 0..<entries.length() {
    if entries[index].mesh_id == mesh_id {
      return Some(index)
    }
  }
  None
}

///|
fn mesh_allocator_record_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
  slab_id : Int,
) -> Unit {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) =>
      entries[index] = MeshAllocatorMeshSlabEntry::{ mesh_id, slab_id }
    None => entries.push(MeshAllocatorMeshSlabEntry::{ mesh_id, slab_id })
  }
}

///|
fn mesh_allocator_remove_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) => {
      let entry = entries[index]
      ignore(entries.remove(index))
      Some(entry.slab_id)
    }
    None => None
  }
}

///|
fn mesh_allocator_lookup_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) => Some(entries[index].slab_id)
    None => None
  }
}

///|
fn MeshAllocator::record_allocation(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
  element_class : MeshAllocatorElementClass,
) -> Unit {
  match element_class {
    Vertex =>
      mesh_allocator_record_map(self.mesh_id_to_vertex_slab, mesh_id, slab_id)
    Index =>
      mesh_allocator_record_map(self.mesh_id_to_index_slab, mesh_id, slab_id)
  }
}

///|
fn mesh_allocator_merge_free_ranges(
  free_ranges : Array[MeshAllocatorFreeRange],
) -> Unit {
  free_ranges.sort_by(fn(left, right) {
    if left.offset < right.offset {
      -1
    } else if left.offset > right.offset {
      1
    } else {
      0
    }
  })
  let mut index = 0
  while index + 1 < free_ranges.length() {
    let current = free_ranges[index]
    let next = free_ranges[index + 1]
    if current.offset + current.slot_count >= next.offset {
      let merged_end = (current.offset + current.slot_count).max(
        next.offset + next.slot_count,
      )
      free_ranges[index] = MeshAllocatorFreeRange::{
        offset: current.offset,
        slot_count: merged_end - current.offset,
      }
      ignore(free_ranges.remove(index + 1))
    } else {
      index = index + 1
    }
  }
}

///|
fn MeshAllocatorSlabState::is_empty(self : MeshAllocatorSlabState) -> Bool {
  self.allocations.is_empty()
}

///|
fn MeshAllocatorSlabState::buffer_size(self : MeshAllocatorSlabState) -> Int {
  self.current_slot_capacity * self.layout.slot_size()
}

///|
fn MeshAllocatorSlabState::try_allocate_free_range(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
  data_slot_count : Int,
) -> MeshAllocatorSlabAllocation? {
  for range_index in 0..<self.free_ranges.length() {
    let free_range = self.free_ranges[range_index]
    if free_range.slot_count >= data_slot_count {
      let allocation = MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: free_range.offset,
        slot_count: data_slot_count,
        residency: Pending,
      }
      if free_range.slot_count == data_slot_count {
        ignore(self.free_ranges.remove(range_index))
      } else {
        self.free_ranges[range_index] = MeshAllocatorFreeRange::{
          offset: free_range.offset + data_slot_count,
          slot_count: free_range.slot_count - data_slot_count,
        }
      }
      self.allocations.push(allocation)
      return Some(allocation)
    }
  }
  None
}

///|
fn MeshAllocatorSlabState::grow_if_necessary(
  self : MeshAllocatorSlabState,
  new_size_in_slots : Int,
  settings : MeshAllocatorSettings,
) -> MeshAllocatorSlabGrowth {
  let growth = mesh_allocator_grow_general_slab_if_necessary(
    self.current_slot_capacity,
    new_size_in_slots,
    self.layout,
    settings~,
  )
  if growth.kind == NeededGrowth {
    self.current_slot_capacity = growth.current_slot_capacity
  }
  growth
}

///|
fn MeshAllocatorSlabState::remove_allocation(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> Bool {
  for index in 0..<self.allocations.length() {
    let allocation = self.allocations[index]
    if allocation.mesh_id == mesh_id {
      self.free_ranges.push(MeshAllocatorFreeRange::{
        offset: allocation.offset,
        slot_count: allocation.slot_count,
      })
      ignore(self.allocations.remove(index))
      mesh_allocator_merge_free_ranges(self.free_ranges)
      return true
    }
  }
  false
}

///|
fn MeshAllocatorSlabState::mark_resident(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> Bool {
  for index in 0..<self.allocations.length() {
    let allocation = self.allocations[index]
    if allocation.mesh_id == mesh_id {
      self.allocations[index] = MeshAllocatorSlabAllocation::{
        ..allocation,
        residency: Resident,
      }
      return true
    }
  }
  false
}

///|
fn MeshAllocatorSlabState::slice_for_mesh(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  for allocation in self.allocations {
    if allocation.mesh_id == mesh_id {
      return Some(MeshAllocatorSlice::{
        slab_id: self.id,
        start: allocation.offset * self.layout.elements_per_slot,
        end: (allocation.offset + allocation.slot_count) *
        self.layout.elements_per_slot,
      })
    }
  }
  None
}

///|
fn MeshAllocator::allocate_large(
  self : MeshAllocator,
  mesh_id : Int,
  data_slot_count : Int,
  layout : MeshAllocatorElementLayout,
) -> MeshAllocatorSlabPlan {
  let slab_id = self.allocate_slab_id()
  self.record_allocation(mesh_id, slab_id, layout.class)
  self.slabs.push(MeshAllocatorSlabState::{
    id: slab_id,
    kind: LargeObject,
    layout,
    current_slot_capacity: data_slot_count,
    max_slot_capacity: data_slot_count,
    allocations: [
      MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: 0,
        slot_count: data_slot_count,
        residency: Pending,
      },
    ],
    free_ranges: [],
  })
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: LargeObject,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: data_slot_count,
    growth: MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: data_slot_count,
      current_slot_capacity: data_slot_count,
    },
  }
}

///|
fn MeshAllocator::allocate_general(
  self : MeshAllocator,
  mesh_id : Int,
  data_slot_count : Int,
  layout : MeshAllocatorElementLayout,
  settings : MeshAllocatorSettings,
) -> MeshAllocatorSlabPlan {
  for slab_index in 0..<self.slabs.length() {
    let slab = self.slabs[slab_index]
    if slab.kind == General && mesh_allocator_layout_eq(slab.layout, layout) {
      match slab.try_allocate_free_range(mesh_id, data_slot_count) {
        Some(allocation) => {
          let growth = slab.grow_if_necessary(
            allocation.offset + data_slot_count,
            settings,
          )
          if growth.kind == CantGrow {
            ignore(slab.remove_allocation(mesh_id))
            continue
          }
          self.record_allocation(mesh_id, slab.id, layout.class)
          return MeshAllocatorSlabPlan::{
            slab_id: slab.id,
            kind: General,
            layout,
            offset: allocation.offset,
            slot_count: data_slot_count,
            current_slot_capacity: slab.current_slot_capacity,
            growth,
          }
        }
        None => ()
      }
    }
  }
  let slab_id = self.allocate_slab_id()
  let initial_slot_capacity = mesh_allocator_initial_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  let max_slot_capacity = mesh_allocator_max_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  let free_ranges = if max_slot_capacity > data_slot_count {
    [
      MeshAllocatorFreeRange::{
        offset: data_slot_count,
        slot_count: max_slot_capacity - data_slot_count,
      },
    ]
  } else {
    []
  }
  self.slabs.push(MeshAllocatorSlabState::{
    id: slab_id,
    kind: General,
    layout,
    current_slot_capacity: initial_slot_capacity,
    max_slot_capacity,
    allocations: [
      MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: 0,
        slot_count: data_slot_count,
        residency: Pending,
      },
    ],
    free_ranges,
  })
  self.record_allocation(mesh_id, slab_id, layout.class)
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: General,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: initial_slot_capacity,
    growth: MeshAllocatorSlabGrowth::{
      kind: NeededGrowth,
      old_slot_capacity: 0,
      current_slot_capacity: initial_slot_capacity,
    },
  }
}

///|
pub fn MeshAllocator::allocate(
  self : MeshAllocator,
  mesh_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::default(),
) -> MeshAllocatorSlabPlan? {
  if data_byte_len <= 0 {
    return None
  }
  let data_slot_count = mesh_allocator_data_slot_count(data_byte_len, layout)
  if layout.class == Vertex && !self.general_vertex_slabs_supported {
    return Some(self.allocate_large(mesh_id, data_slot_count, layout))
  }
  if data_slot_count * layout.slot_size() >=
    settings.large_threshold.min(settings.max_slab_size) {
    Some(self.allocate_large(mesh_id, data_slot_count, layout))
  } else {
    Some(self.allocate_general(mesh_id, data_slot_count, layout, settings))
  }
}

///|
pub fn MeshAllocator::mesh_slabs(
  self : MeshAllocator,
  mesh_id : Int,
) -> (Int?, Int?) {
  (
    mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id),
    mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id),
  )
}

///|
pub fn MeshAllocator::mesh_vertex_slice(
  self : MeshAllocator,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id) {
    Some(slab_id) => self.mesh_slice_in_slab(mesh_id, slab_id)
    None => None
  }
}

///|
pub fn MeshAllocator::mesh_index_slice(
  self : MeshAllocator,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id) {
    Some(slab_id) => self.mesh_slice_in_slab(mesh_id, slab_id)
    None => None
  }
}

///|
pub fn MeshAllocator::mesh_slice_in_slab(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_find_slab_index(self.slabs, slab_id) {
    Some(index) => self.slabs[index].slice_for_mesh(mesh_id)
    None => None
  }
}

///|
pub fn MeshAllocator::slab_count(self : MeshAllocator) -> Int {
  self.slabs.length()
}

///|
pub fn MeshAllocator::slabs_size(self : MeshAllocator) -> Int {
  let mut size = 0
  for slab in self.slabs {
    size = size + slab.buffer_size()
  }
  size
}

///|
pub fn MeshAllocator::allocations(self : MeshAllocator) -> Int {
  self.mesh_id_to_index_slab.length()
}

///|
pub fn MeshAllocator::mark_resident(
  self : MeshAllocator,
  mesh_id : Int,
  element_class : MeshAllocatorElementClass,
) -> Bool {
  let slab_id = match element_class {
    Vertex => mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id)
    Index => mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id)
  }
  match slab_id {
    Some(slab_id) =>
      match mesh_allocator_find_slab_index(self.slabs, slab_id) {
        Some(index) => self.slabs[index].mark_resident(mesh_id)
        None => false
      }
    None => false
  }
}

///|
pub fn MeshAllocator::free_mesh(self : MeshAllocator, mesh_id : Int) -> Unit {
  let vertex_slab_id = mesh_allocator_remove_map(
    self.mesh_id_to_vertex_slab,
    mesh_id,
  )
  let index_slab_id = mesh_allocator_remove_map(
    self.mesh_id_to_index_slab,
    mesh_id,
  )
  match vertex_slab_id {
    Some(slab_id) => self.free_allocation_in_slab(mesh_id, slab_id)
    None => ()
  }
  match index_slab_id {
    Some(slab_id) => self.free_allocation_in_slab(mesh_id, slab_id)
    None => ()
  }
  self.remove_empty_slabs()
}

///|
pub fn MeshAllocator::free_meshes(
  self : MeshAllocator,
  removed : Array[Int],
  modified : Array[Int],
) -> Unit {
  for mesh_id in removed {
    self.free_mesh(mesh_id)
  }
  for mesh_id in modified {
    self.free_mesh(mesh_id)
  }
}

///|
fn MeshAllocator::free_allocation_in_slab(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
) -> Unit {
  match mesh_allocator_find_slab_index(self.slabs, slab_id) {
    Some(index) => ignore(self.slabs[index].remove_allocation(mesh_id))
    None => ()
  }
}

///|
fn MeshAllocator::remove_empty_slabs(self : MeshAllocator) -> Unit {
  let mut index = 0
  while index < self.slabs.length() {
    if self.slabs[index].is_empty() {
      ignore(self.slabs.remove(index))
    } else {
      index = index + 1
    }
  }
}

///|
pub fn mesh_allocator_create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  @renderer.create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology~)
}

///|
pub fn mesh_allocator_create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  @renderer.create_mesh3d_xyznuvrgba(vertices_xyznuvrgba~, primitive_topology~)
}

///|
pub fn mesh_allocator_update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  @renderer.update_mesh3d_xyznuvrgba(
    mesh_id~,
    vertices_xyznuvrgba~,
    primitive_topology~,
  )
}
