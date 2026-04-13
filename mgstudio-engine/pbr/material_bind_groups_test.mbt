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
test "render3d: non-bindless allocator reuses freed indices" {
  let allocator = MaterialBindGroupNonBindlessAllocator::default()
  let first = allocator.allocate(11)
  let second = allocator.allocate(22)
  debug_inspect(first.group().to_int(), content="0")
  debug_inspect(second.group().to_int(), content="1")
  debug_inspect(allocator.len(), content="2")

  allocator.free(first)
  debug_inspect(allocator.len(), content="1")

  let third = allocator.allocate(33)
  debug_inspect(third.group().to_int(), content="0")
  debug_inspect(allocator.len(), content="2")
}

///|
test "render3d: bindless allocator respects slab capacity" {
  let allocator = MaterialBindGroupBindlessAllocator::with_slab_capacity(2)
  let first = allocator.allocate(1001)
  let second = allocator.allocate(1002)
  let third = allocator.allocate(1003)

  debug_inspect(first is Some(_), content="true")
  debug_inspect(second is Some(_), content="true")
  debug_inspect(third is None, content="true")
  debug_inspect(allocator.len(), content="2")

  match first {
    Some(binding) => allocator.free(binding)
    None => ()
  }
  debug_inspect(allocator.len(), content="1")
  debug_inspect(allocator.allocate(1004) is Some(_), content="true")
}

///|
test "render3d: allocator registry stores by key" {
  let allocators = MaterialBindGroupAllocators::default()
  allocators.insert(
    "StandardMaterial",
    MaterialBindGroupAllocator::default_bindless(),
  )
  debug_inspect(allocators.contains("StandardMaterial"), content="true")
  debug_inspect(allocators.get("StandardMaterial") is Some(_), content="true")
  debug_inspect(allocators.get("Missing") is None, content="true")
}

///|
test "render3d: allocator exposes slab and allocation counters" {
  let bindless = MaterialBindGroupBindlessAllocator::with_slab_capacity(4)
  ignore(bindless.allocate(1))
  ignore(bindless.allocate(2))
  let bindless_alloc = MaterialBindGroupAllocator::Bindless(bindless)
  debug_inspect(bindless_alloc.slab_count(), content="1")
  debug_inspect(bindless_alloc.slabs_size(), content="4")
  debug_inspect(bindless_alloc.allocations(), content="2")

  let non_bindless = MaterialBindGroupNonBindlessAllocator::default()
  ignore(non_bindless.allocate(7))
  ignore(non_bindless.allocate(8))
  let non_bindless_alloc = MaterialBindGroupAllocator::NonBindless(non_bindless)
  debug_inspect(non_bindless_alloc.slab_count(), content="2")
  debug_inspect(non_bindless_alloc.slabs_size(), content="2")
  debug_inspect(non_bindless_alloc.allocations(), content="2")
}
