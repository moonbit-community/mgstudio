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
