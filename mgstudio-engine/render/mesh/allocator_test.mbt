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
test "render mesh allocator: element layouts preserve bevy copy alignment slots" {
  let vertex_32 = MeshAllocatorElementLayout::vertex(32)
  inspect(vertex_32.class() is Vertex, content="true")
  inspect(vertex_32.elements_per_slot(), content="1")
  inspect(vertex_32.slot_size(), content="32")
  let index_u16 = MeshAllocatorElementLayout::index_u16()
  inspect(index_u16.class() is Index, content="true")
  inspect(index_u16.elements_per_slot(), content="2")
  inspect(index_u16.slot_size(), content="4")
  let packed_3 = MeshAllocatorElementLayout::new(Vertex, 3)
  inspect(packed_3.elements_per_slot(), content="4")
  inspect(packed_3.slot_size(), content="12")
  let packed_5 = MeshAllocatorElementLayout::new(Vertex, 5)
  inspect(packed_5.elements_per_slot(), content="4")
  inspect(packed_5.slot_size(), content="20")
}

///|
test "render mesh allocator: default settings preserve bevy slab thresholds" {
  let settings = MeshAllocatorSettings::default()
  inspect(settings.min_slab_size(), content="1048576")
  inspect(settings.max_slab_size(), content="536870912")
  inspect(settings.large_threshold(), content="268435456")
  inspect(settings.growth_factor(), content="1.5")
}

///|
test "render mesh allocator: new general slab starts at min slab capacity" {
  let plan = mesh_allocator_plan_new_general_slab(
    7,
    96,
    MeshAllocatorElementLayout::vertex(32),
  )
  inspect(plan.slab_id(), content="7")
  inspect(plan.kind() is General, content="true")
  inspect(plan.offset(), content="0")
  inspect(plan.slot_count(), content="3")
  inspect(plan.current_slot_capacity(), content="32768")
  inspect(plan.growth().kind() is NeededGrowth, content="true")
  inspect(plan.growth().old_slot_capacity(), content="0")
}

///|
test "render mesh allocator: growth follows bevy factor until capacity fits" {
  let layout = MeshAllocatorElementLayout::vertex(32)
  let settings = MeshAllocatorSettings::new(
    min_slab_size=32,
    max_slab_size=32 * 16,
    large_threshold=32 * 128,
    growth_factor=1.5F,
  )
  let no_growth = mesh_allocator_grow_general_slab_if_necessary(
    4,
    4,
    layout,
    settings~,
  )
  inspect(no_growth.kind() is NoGrowthNeeded, content="true")
  inspect(no_growth.current_slot_capacity(), content="4")
  let grown = mesh_allocator_grow_general_slab_if_necessary(
    4,
    8,
    layout,
    settings~,
  )
  inspect(grown.kind() is NeededGrowth, content="true")
  inspect(grown.old_slot_capacity(), content="4")
  inspect(grown.current_slot_capacity(), content="9")
  let full = mesh_allocator_grow_general_slab_if_necessary(
    16,
    17,
    layout,
    settings~,
  )
  inspect(full.kind() is CantGrow, content="true")
  inspect(full.current_slot_capacity(), content="16")
}

///|
test "render mesh allocator: large-object decision uses min threshold max slab" {
  let layout = MeshAllocatorElementLayout::vertex(32)
  let settings = MeshAllocatorSettings::new(
    min_slab_size=64,
    max_slab_size=512,
    large_threshold=256,
    growth_factor=1.5F,
  )
  inspect(
    mesh_allocator_should_allocate_large(224, layout, settings~),
    content="false",
  )
  inspect(
    mesh_allocator_should_allocate_large(256, layout, settings~),
    content="true",
  )
  let large = mesh_allocator_plan_large_slab(3, 256, layout)
  inspect(large.kind() is LargeObject, content="true")
  inspect(large.slot_count(), content="8")
  inspect(large.current_slot_capacity(), content="8")
}
