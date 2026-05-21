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
test "render slab allocator: computes Bevy slot padding and large threshold" {
  let layout = SlabItemLayoutInfo::new(size=12, elements_per_slot=2)
  let shape = slab_allocator_allocation_shape(25, layout)
  debug_inspect(shape.element_count(), content="3")
  debug_inspect(shape.slot_count(), content="2")
  debug_inspect(shape.padding(), content="1")
  let settings = SlabAllocatorSettings::new(
    min_slab_size=64,
    max_slab_size=256,
    large_threshold=96,
    growth_factor=2.0F,
  )
  debug_inspect(
    slab_allocator_should_allocate_large(96, layout, settings~),
    content="true",
  )
}

///|
test "render slab allocator: grows by configured factor up to max slots" {
  let layout = SlabItemLayoutInfo::new(size=8, elements_per_slot=1)
  let settings = SlabAllocatorSettings::new(
    min_slab_size=16,
    max_slab_size=80,
    large_threshold=64,
    growth_factor=2.0F,
  )
  let growth = slab_allocator_grow_general_slab_if_necessary(
    2,
    7,
    layout,
    settings~,
  )
  debug_inspect(growth.kind(), content="NeededGrowth")
  debug_inspect(growth.current_slot_capacity(), content="8")
}
