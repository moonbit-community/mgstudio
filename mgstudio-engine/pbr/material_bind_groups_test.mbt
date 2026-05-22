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
  let allocator = MaterialBindGroupNonBindlessAllocator::MaterialBindGroupNonBindlessAllocator()
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
  let allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  allocators.insert(
    "StandardMaterial",
    MaterialBindGroupAllocator::default_bindless(),
  )
  debug_inspect(allocators.contains("StandardMaterial"), content="true")
  debug_inspect(allocators.get("StandardMaterial") is Some(_), content="true")
  debug_inspect(allocators.get("Missing") is None, content="true")
  debug_inspect(allocators.len(), content="1")
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

  let non_bindless = MaterialBindGroupNonBindlessAllocator::MaterialBindGroupNonBindlessAllocator()
  ignore(non_bindless.allocate(7))
  ignore(non_bindless.allocate(8))
  let non_bindless_alloc = MaterialBindGroupAllocator::NonBindless(non_bindless)
  debug_inspect(non_bindless_alloc.slab_count(), content="2")
  debug_inspect(non_bindless_alloc.slabs_size(), content="2")
  debug_inspect(non_bindless_alloc.allocations(), content="2")
}

///|
test "render3d: material uses bindless resources follows bevy support and slot rule" {
  debug_inspect(material_uses_bindless_resources(true, Some(2)), content="true")
  debug_inspect(
    material_uses_bindless_resources(false, Some(2)),
    content="false",
  )
  debug_inspect(
    material_uses_bindless_resources(true, Some(1)),
    content="false",
  )
  debug_inspect(material_uses_bindless_resources(true, None), content="false")
}

///|
test "render3d: standard material allocator install plan carries layout descriptor" {
  let plan = standard_material_bind_group_allocator_install_plan(true, Some(4))
  let layout = plan.layout_descriptor()
  debug_inspect(plan.material_label(), content="\"StandardMaterial\"")
  debug_inspect(plan.uses_bindless_resources(), content="true")
  debug_inspect(layout.label(), content="\"StandardMaterial\"")
  debug_inspect(layout.entries().length(), content="17")
}

///|
test "render3d: standard material allocator install chooses bindless mode from bevy rule" {
  let bindless_allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  let bindless_plan = bindless_allocators.install_standard_material(
    true,
    Some(8),
  )
  debug_inspect(bindless_plan.uses_bindless_resources(), content="true")
  debug_inspect(bindless_allocators.len(), content="1")
  match bindless_allocators.get("StandardMaterial") {
    Some(MaterialBindGroupAllocator::Bindless(_)) =>
      debug_inspect(true, content="true")
    _ => debug_inspect(false, content="true")
  }

  let non_bindless_allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  let non_bindless_plan = non_bindless_allocators.install_standard_material(
    true,
    Some(1),
  )
  debug_inspect(non_bindless_plan.uses_bindless_resources(), content="false")
  match non_bindless_allocators.get("StandardMaterial") {
    Some(MaterialBindGroupAllocator::NonBindless(_)) =>
      debug_inspect(true, content="true")
    _ => debug_inspect(false, content="true")
  }
}
