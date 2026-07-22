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
test "render3d: bindless allocator grows across slabs" {
  let allocator = MaterialBindGroupBindlessAllocator::with_slab_capacity(2)
  let first = allocator.allocate(1001)
  let second = allocator.allocate(1002)
  let third = allocator.allocate(1003)

  debug_inspect(first.group().to_int(), content="0")
  debug_inspect(second.slot().to_int(), content="1")
  debug_inspect(third.group().to_int(), content="1")
  debug_inspect(third.slot().to_int(), content="0")
  debug_inspect(allocator.len(), content="3")
  debug_inspect(allocator.slab_count(), content="2")

  allocator.free(first)
  debug_inspect(allocator.len(), content="2")
  let reused = allocator.allocate(1004)
  debug_inspect(
    (reused.group().to_int(), reused.slot().to_int()),
    content="(0, 0)",
  )
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
test "render3d: material allocator allocates bindless material bindings only" {
  let bindless = MaterialBindGroupAllocator::Bindless(
    MaterialBindGroupBindlessAllocator::with_slab_capacity(2),
  )
  match bindless.allocate_bindless_material(10) {
    Some(binding) => {
      debug_inspect(binding.group().to_int(), content="0")
      debug_inspect(binding.slot().to_int(), content="0")
    }
    None => abort("expected bindless material binding")
  }
  match bindless.allocate_bindless_material(11) {
    Some(binding) => debug_inspect(binding.slot().to_int(), content="1")
    None => abort("expected second bindless material binding")
  }
  match bindless.allocate_bindless_material(12) {
    Some(binding) => {
      debug_inspect(binding.group().to_int(), content="1")
      debug_inspect(binding.slot().to_int(), content="0")
    }
    None => abort("expected allocation in a second bindless slab")
  }

  let non_bindless = MaterialBindGroupAllocator::default_non_bindless()
  debug_inspect(
    non_bindless.allocate_bindless_material(13) is None,
    content="true",
  )
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
  debug_inspect(standard_material_bindless_slot_count(), content="Some(31)")
  debug_inspect(layout.label(), content="\"StandardMaterial\"")
  debug_inspect(layout.entries().length(), content="15")
}

///|
test "render3d: standard material layout derives optional texture feature gates" {
  let no_optional = standard_material_bind_group_layout_descriptor(
    features=StandardMaterialTextureFeatureSet(),
  )
  debug_inspect(no_optional.entries().length(), content="13")
  inspect(no_optional.entries()[12].binding(), content="12")

  let default_features = standard_material_bind_group_layout_descriptor()
  debug_inspect(default_features.entries().length(), content="15")
  inspect(default_features.entries()[13].binding(), content="13")
  inspect(default_features.entries()[14].binding(), content="14")

  let all_optional = standard_material_bind_group_layout_descriptor(
    features=StandardMaterialTextureFeatureSet(
      pbr_transmission_textures=true,
      pbr_multi_layer_material_textures=true,
      pbr_anisotropy_texture=true,
      pbr_specular_textures=true,
    ),
  )
  debug_inspect(all_optional.entries().length(), content="31")
  inspect(all_optional.entries()[15].binding(), content="15")
  inspect(all_optional.entries()[21].binding(), content="21")
  inspect(all_optional.entries()[27].binding(), content="27")
  inspect(all_optional.entries()[30].binding(), content="30")
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
    Some(Bindless(allocator)) => {
      debug_inspect(true, content="true")
      for material_id in 0..<8 {
        ignore(allocator.allocate(material_id))
      }
      let ninth = allocator.allocate(8)
      debug_inspect(
        (ninth.group().to_int(), ninth.slot().to_int()),
        content="(1, 0)",
      )
    }
    _ => debug_inspect(false, content="true")
  }

  let non_bindless_allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  let non_bindless_plan = non_bindless_allocators.install_standard_material(
    true,
    Some(1),
  )
  debug_inspect(non_bindless_plan.uses_bindless_resources(), content="false")
  match non_bindless_allocators.get("StandardMaterial") {
    Some(NonBindless(_)) => debug_inspect(true, content="true")
    _ => debug_inspect(false, content="true")
  }
}
