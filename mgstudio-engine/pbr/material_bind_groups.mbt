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
// Bevy source: `bevy/crates/bevy_pbr/src/material_bind_groups.rs`.

///|
pub struct MaterialBindGroupIndex {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupIndex::new(value : Int) -> MaterialBindGroupIndex {
  MaterialBindGroupIndex::{ value: if value < 0 { 0 } else { value } }
}

///|
pub fn MaterialBindGroupIndex::to_int(self : MaterialBindGroupIndex) -> Int {
  self.value
}

///|
pub struct MaterialBindGroupSlot {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupSlot::new(value : Int) -> MaterialBindGroupSlot {
  MaterialBindGroupSlot::{ value: if value < 0 { 0 } else { value } }
}

///|
pub fn MaterialBindGroupSlot::to_int(self : MaterialBindGroupSlot) -> Int {
  self.value
}

///|
pub struct MaterialBindingId {
  group : MaterialBindGroupIndex
  slot : MaterialBindGroupSlot
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindingId::default() -> MaterialBindingId {
  MaterialBindingId::{
    group: MaterialBindGroupIndex::new(0),
    slot: MaterialBindGroupSlot::new(0),
  }
}

///|
pub fn MaterialBindingId::new(
  group : MaterialBindGroupIndex,
  slot : MaterialBindGroupSlot,
) -> MaterialBindingId {
  MaterialBindingId::{ group, slot }
}

///|
pub fn MaterialBindingId::group(
  self : MaterialBindingId,
) -> MaterialBindGroupIndex {
  self.group
}

///|
pub fn MaterialBindingId::slot(
  self : MaterialBindingId,
) -> MaterialBindGroupSlot {
  self.slot
}

///|
pub struct MaterialBindGroupEntry {
  material_id : Int
  binding_id : MaterialBindingId
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupEntry::new(
  material_id : Int,
  binding_id : MaterialBindingId,
) -> MaterialBindGroupEntry {
  MaterialBindGroupEntry::{ material_id, binding_id }
}

///|
pub fn MaterialBindGroupEntry::material_id(
  self : MaterialBindGroupEntry,
) -> Int {
  self.material_id
}

///|
pub fn MaterialBindGroupEntry::binding_id(
  self : MaterialBindGroupEntry,
) -> MaterialBindingId {
  self.binding_id
}

///|
pub struct MaterialNonBindlessAllocatedBindGroup {
  bind_group_id : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialNonBindlessAllocatedBindGroup::new(
  bind_group_id : Int,
) -> MaterialNonBindlessAllocatedBindGroup {
  MaterialNonBindlessAllocatedBindGroup::{ bind_group_id, }
}

///|
pub fn MaterialNonBindlessAllocatedBindGroup::bind_group_id(
  self : MaterialNonBindlessAllocatedBindGroup,
) -> Int {
  self.bind_group_id
}

///|
pub struct MaterialBindGroupNonBindlessAllocator {
  bind_groups : Array[MaterialNonBindlessAllocatedBindGroup?]
  free_indices : Array[Int]
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::default() -> MaterialBindGroupNonBindlessAllocator {
  MaterialBindGroupNonBindlessAllocator::{ bind_groups: [], free_indices: [] }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::allocate(
  self : MaterialBindGroupNonBindlessAllocator,
  bind_group_id : Int,
) -> MaterialBindingId {
  match self.free_indices.pop() {
    Some(index) => {
      self.bind_groups[index] = Some(
        MaterialNonBindlessAllocatedBindGroup::new(bind_group_id),
      )
      MaterialBindingId::new(
        MaterialBindGroupIndex::new(index),
        MaterialBindGroupSlot::new(0),
      )
    }
    None => {
      let index = self.bind_groups.length()
      self.bind_groups.push(
        Some(MaterialNonBindlessAllocatedBindGroup::new(bind_group_id)),
      )
      MaterialBindingId::new(
        MaterialBindGroupIndex::new(index),
        MaterialBindGroupSlot::new(0),
      )
    }
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::free(
  self : MaterialBindGroupNonBindlessAllocator,
  binding_id : MaterialBindingId,
) -> Unit {
  let index = binding_id.group().to_int()
  if index < 0 || index >= self.bind_groups.length() {
    return
  }
  if self.bind_groups[index] is Some(_) {
    self.bind_groups[index] = None
    self.free_indices.push(index)
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::get(
  self : MaterialBindGroupNonBindlessAllocator,
  index : MaterialBindGroupIndex,
) -> MaterialNonBindlessAllocatedBindGroup? {
  let raw_index = index.to_int()
  if raw_index < 0 || raw_index >= self.bind_groups.length() {
    None
  } else {
    self.bind_groups[raw_index]
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::len(
  self : MaterialBindGroupNonBindlessAllocator,
) -> Int {
  self.bind_groups.fold(init=0, fn(acc, entry) {
    if entry is Some(_) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
pub struct MaterialBindGroupBindlessAllocator {
  slab_capacity : Int
  slots : Array[Int?]
  free_slots : Array[Int]
}

///|
pub fn MaterialBindGroupBindlessAllocator::default() -> MaterialBindGroupBindlessAllocator {
  MaterialBindGroupBindlessAllocator::with_slab_capacity(256)
}

///|
pub fn MaterialBindGroupBindlessAllocator::with_slab_capacity(
  slab_capacity : Int,
) -> MaterialBindGroupBindlessAllocator {
  let capacity = if slab_capacity <= 0 { 1 } else { slab_capacity }
  MaterialBindGroupBindlessAllocator::{
    slab_capacity: capacity,
    slots: [],
    free_slots: [],
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::allocate(
  self : MaterialBindGroupBindlessAllocator,
  material_id : Int,
) -> MaterialBindingId? {
  match self.free_slots.pop() {
    Some(slot) => {
      self.slots[slot] = Some(material_id)
      Some(
        MaterialBindingId::new(
          MaterialBindGroupIndex::new(0),
          MaterialBindGroupSlot::new(slot),
        ),
      )
    }
    None =>
      if self.slots.length() >= self.slab_capacity {
        None
      } else {
        let slot = self.slots.length()
        self.slots.push(Some(material_id))
        Some(
          MaterialBindingId::new(
            MaterialBindGroupIndex::new(0),
            MaterialBindGroupSlot::new(slot),
          ),
        )
      }
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::free(
  self : MaterialBindGroupBindlessAllocator,
  binding_id : MaterialBindingId,
) -> Unit {
  let slot = binding_id.slot().to_int()
  if slot < 0 || slot >= self.slots.length() {
    return
  }
  if self.slots[slot] is Some(_) {
    self.slots[slot] = None
    self.free_slots.push(slot)
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::len(
  self : MaterialBindGroupBindlessAllocator,
) -> Int {
  self.slots.fold(init=0, fn(acc, entry) {
    if entry is Some(_) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
pub(all) enum MaterialBindGroupAllocator {
  Bindless(MaterialBindGroupBindlessAllocator)
  NonBindless(MaterialBindGroupNonBindlessAllocator)
}

///|
pub fn MaterialBindGroupAllocator::default_bindless() -> MaterialBindGroupAllocator {
  MaterialBindGroupAllocator::Bindless(
    MaterialBindGroupBindlessAllocator::default(),
  )
}

///|
pub fn MaterialBindGroupAllocator::default_non_bindless() -> MaterialBindGroupAllocator {
  MaterialBindGroupAllocator::NonBindless(
    MaterialBindGroupNonBindlessAllocator::default(),
  )
}

///|
pub struct MaterialBindGroupAllocators {
  allocators : Map[String, MaterialBindGroupAllocator]
}

///|
pub fn MaterialBindGroupAllocators::default() -> MaterialBindGroupAllocators {
  MaterialBindGroupAllocators::{ allocators: {} }
}

///|
pub fn MaterialBindGroupAllocators::insert(
  self : MaterialBindGroupAllocators,
  key : String,
  allocator : MaterialBindGroupAllocator,
) -> Unit {
  self.allocators.set(key, allocator)
}

///|
pub fn MaterialBindGroupAllocators::get(
  self : MaterialBindGroupAllocators,
  key : String,
) -> MaterialBindGroupAllocator? {
  self.allocators.get(key)
}

///|
pub fn MaterialBindGroupAllocators::contains(
  self : MaterialBindGroupAllocators,
  key : String,
) -> Bool {
  self.allocators.contains(key)
}

///|
pub struct MaterialBindGroups {
  entries : Array[MaterialBindGroupEntry]
}

///|
pub fn MaterialBindGroups::default() -> MaterialBindGroups {
  MaterialBindGroups::{ entries: [] }
}

///|
pub fn MaterialBindGroups::push(
  self : MaterialBindGroups,
  entry : MaterialBindGroupEntry,
) -> Unit {
  self.entries.push(entry)
}

///|
pub fn MaterialBindGroups::entry_count(self : MaterialBindGroups) -> Int {
  self.entries.length()
}
