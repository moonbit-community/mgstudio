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
// Bevy source: `bevy/crates/bevy_render/src/slab_allocator.rs`.

///|
pub struct SlabAllocatorSettings {
  min_slab_size : Int
  max_slab_size : Int
  large_threshold : Int
  growth_factor : Float
}

///|
pub fn SlabAllocatorSettings::new(
  min_slab_size~ : Int,
  max_slab_size~ : Int,
  large_threshold~ : Int,
  growth_factor~ : Float,
) -> SlabAllocatorSettings {
  if min_slab_size <= 0 || max_slab_size <= 0 || large_threshold <= 0 {
    abort("slab allocator sizes must be positive")
  }
  if growth_factor <= 1.0F {
    abort("slab allocator growth factor must be greater than 1")
  }
  SlabAllocatorSettings::{
    min_slab_size,
    max_slab_size,
    large_threshold,
    growth_factor,
  }
}

///|
pub fn SlabAllocatorSettings::SlabAllocatorSettings() -> SlabAllocatorSettings {
  SlabAllocatorSettings::new(
    min_slab_size=1024 * 1024,
    max_slab_size=1024 * 1024 * 512,
    large_threshold=1024 * 1024 * 256,
    growth_factor=1.5F,
  )
}

///|
pub impl Default for SlabAllocatorSettings with default() {
  SlabAllocatorSettings::SlabAllocatorSettings()
}

///|
pub fn SlabAllocatorSettings::min_slab_size(
  self : SlabAllocatorSettings,
) -> Int {
  self.min_slab_size
}

///|
pub fn SlabAllocatorSettings::max_slab_size(
  self : SlabAllocatorSettings,
) -> Int {
  self.max_slab_size
}

///|
pub fn SlabAllocatorSettings::large_threshold(
  self : SlabAllocatorSettings,
) -> Int {
  self.large_threshold
}

///|
pub fn SlabAllocatorSettings::growth_factor(
  self : SlabAllocatorSettings,
) -> Float {
  self.growth_factor
}

///|
pub(all) enum SlabKind {
  General
  LargeObject
} derive(Eq, Debug)

///|
pub(all) enum SlabGrowthKind {
  NoGrowthNeeded
  NeededGrowth
  CantGrow
} derive(Eq, Debug)

///|
pub struct SlabItemLayoutInfo {
  size : Int
  elements_per_slot : Int
  buffer_usages : UInt
} derive(Eq, Debug)

///|
pub fn SlabItemLayoutInfo::new(
  size~ : Int,
  elements_per_slot~ : Int,
  buffer_usages? : UInt = 0U,
) -> SlabItemLayoutInfo {
  if size <= 0 {
    abort("slab item layout size must be positive")
  }
  if elements_per_slot <= 0 {
    abort("slab item layout elements_per_slot must be positive")
  }
  SlabItemLayoutInfo::{ size, elements_per_slot, buffer_usages }
}

///|
pub fn SlabItemLayoutInfo::size(self : SlabItemLayoutInfo) -> Int {
  self.size
}

///|
pub fn SlabItemLayoutInfo::elements_per_slot(self : SlabItemLayoutInfo) -> Int {
  self.elements_per_slot
}

///|
pub fn SlabItemLayoutInfo::buffer_usages(self : SlabItemLayoutInfo) -> UInt {
  self.buffer_usages
}

///|
pub fn SlabItemLayoutInfo::slot_size(self : SlabItemLayoutInfo) -> Int {
  self.size * self.elements_per_slot
}

///|
pub struct SlabAllocationShape {
  element_count : Int
  slot_count : Int
  padding : Int
} derive(Eq, Debug)

///|
pub fn SlabAllocationShape::element_count(self : SlabAllocationShape) -> Int {
  self.element_count
}

///|
pub fn SlabAllocationShape::slot_count(self : SlabAllocationShape) -> Int {
  self.slot_count
}

///|
pub fn SlabAllocationShape::padding(self : SlabAllocationShape) -> Int {
  self.padding
}

///|
pub fn slab_allocator_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("slab allocator divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}

///|
pub fn slab_allocator_allocation_shape(
  data_byte_len : Int,
  layout : SlabItemLayoutInfo,
) -> SlabAllocationShape {
  let element_count = slab_allocator_div_ceil(data_byte_len, layout.size)
  let slot_count = slab_allocator_div_ceil(
    element_count,
    layout.elements_per_slot,
  )
  let padding = slot_count * layout.elements_per_slot - element_count
  SlabAllocationShape::{ element_count, slot_count, padding }
}

///|
pub fn slab_allocator_should_allocate_large(
  data_byte_len : Int,
  layout : SlabItemLayoutInfo,
  settings? : SlabAllocatorSettings = SlabAllocatorSettings::SlabAllocatorSettings(),
) -> Bool {
  let shape = slab_allocator_allocation_shape(data_byte_len, layout)
  shape.slot_count * layout.slot_size() >=
  settings.large_threshold.min(settings.max_slab_size)
}

///|
pub struct SlabGrowth {
  kind : SlabGrowthKind
  old_slot_capacity : Int
  current_slot_capacity : Int
} derive(Eq, Debug)

///|
pub fn SlabGrowth::kind(self : SlabGrowth) -> SlabGrowthKind {
  self.kind
}

///|
pub fn SlabGrowth::old_slot_capacity(self : SlabGrowth) -> Int {
  self.old_slot_capacity
}

///|
pub fn SlabGrowth::current_slot_capacity(self : SlabGrowth) -> Int {
  self.current_slot_capacity
}

///|
fn slab_allocator_min_allocator_size(slot_count : Int) -> Int {
  if slot_count <= 0 {
    1
  } else {
    slot_count
  }
}

///|
pub fn slab_allocator_initial_general_slab_slot_capacity(
  layout : SlabItemLayoutInfo,
  data_slot_count : Int,
  settings? : SlabAllocatorSettings = SlabAllocatorSettings::SlabAllocatorSettings(),
) -> Int {
  slab_allocator_div_ceil(settings.min_slab_size, layout.slot_size()).max(
    slab_allocator_min_allocator_size(data_slot_count),
  )
}

///|
pub fn slab_allocator_growth_capacity(
  current_slot_capacity : Int,
  settings : SlabAllocatorSettings,
  layout : SlabItemLayoutInfo,
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
pub fn slab_allocator_grow_general_slab_if_necessary(
  current_slot_capacity : Int,
  new_size_in_slots : Int,
  layout : SlabItemLayoutInfo,
  settings? : SlabAllocatorSettings = SlabAllocatorSettings::SlabAllocatorSettings(),
) -> SlabGrowth {
  let initial_slot_capacity = current_slot_capacity
  if current_slot_capacity >= new_size_in_slots {
    return SlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: initial_slot_capacity,
      current_slot_capacity,
    }
  }
  let mut capacity = current_slot_capacity
  while capacity < new_size_in_slots {
    let next_capacity = slab_allocator_growth_capacity(
      capacity, settings, layout,
    )
    if next_capacity == capacity {
      return SlabGrowth::{
        kind: CantGrow,
        old_slot_capacity: initial_slot_capacity,
        current_slot_capacity: capacity,
      }
    }
    capacity = next_capacity
  }
  SlabGrowth::{
    kind: NeededGrowth,
    old_slot_capacity: initial_slot_capacity,
    current_slot_capacity: capacity,
  }
}

///|
pub struct SlabAllocationPlan {
  slab_id : Int
  kind : SlabKind
  layout : SlabItemLayoutInfo
  offset : Int
  slot_count : Int
  padding : Int
  current_slot_capacity : Int
  growth : SlabGrowth
} derive(Eq, Debug)

///|
pub fn SlabAllocationPlan::slab_id(self : SlabAllocationPlan) -> Int {
  self.slab_id
}

///|
pub fn SlabAllocationPlan::kind(self : SlabAllocationPlan) -> SlabKind {
  self.kind
}

///|
pub fn SlabAllocationPlan::slot_count(self : SlabAllocationPlan) -> Int {
  self.slot_count
}

///|
pub fn SlabAllocationPlan::padding(self : SlabAllocationPlan) -> Int {
  self.padding
}

///|
pub fn SlabAllocationPlan::current_slot_capacity(
  self : SlabAllocationPlan,
) -> Int {
  self.current_slot_capacity
}

///|
pub fn SlabAllocationPlan::growth(self : SlabAllocationPlan) -> SlabGrowth {
  self.growth
}

///|
pub fn slab_allocator_plan_new_general_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : SlabItemLayoutInfo,
  settings? : SlabAllocatorSettings = SlabAllocatorSettings::SlabAllocatorSettings(),
) -> SlabAllocationPlan {
  let shape = slab_allocator_allocation_shape(data_byte_len, layout)
  let current_slot_capacity = slab_allocator_initial_general_slab_slot_capacity(
    layout,
    shape.slot_count,
    settings~,
  )
  SlabAllocationPlan::{
    slab_id,
    kind: General,
    layout,
    offset: 0,
    slot_count: shape.slot_count,
    padding: shape.padding,
    current_slot_capacity,
    growth: SlabGrowth::{
      kind: NeededGrowth,
      old_slot_capacity: 0,
      current_slot_capacity,
    },
  }
}

///|
pub fn slab_allocator_plan_large_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : SlabItemLayoutInfo,
) -> SlabAllocationPlan {
  let shape = slab_allocator_allocation_shape(data_byte_len, layout)
  SlabAllocationPlan::{
    slab_id,
    kind: LargeObject,
    layout,
    offset: 0,
    slot_count: shape.slot_count,
    padding: shape.padding,
    current_slot_capacity: shape.slot_count,
    growth: SlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: shape.slot_count,
      current_slot_capacity: shape.slot_count,
    },
  }
}
