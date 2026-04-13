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
test "pbr diagnostic: snapshot can be read" {
  let world = @ecs.World::new()
  let snapshot = render3d_diagnostics_snapshot(world)
  inspect(snapshot.prepared_camera_count >= 0, content="true")
  inspect(snapshot.queued_visible_mesh_count >= 0, content="true")
}

///|
test "pbr diagnostic: allocator snapshot and paths align" {
  let allocators = MaterialBindGroupAllocators::default()
  let bindless = MaterialBindGroupBindlessAllocator::with_slab_capacity(4)
  ignore(bindless.allocate(1001))
  ignore(bindless.allocate(1002))
  allocators.insert("StandardMaterial", MaterialBindGroupAllocator::Bindless(bindless))

  inspect(
    render3d_material_allocator_slabs_path("StandardMaterial"),
    content="material_allocator_slabs/StandardMaterial",
  )
  inspect(
    render3d_material_allocator_slabs_size_path("StandardMaterial"),
    content="material_allocator_slabs_size/StandardMaterial",
  )
  inspect(
    render3d_material_allocator_allocations_path("StandardMaterial"),
    content="material_allocator_allocations/StandardMaterial",
  )

  let snapshot = match render3d_material_allocator_snapshot_for_key(
    allocators,
    "StandardMaterial",
  ) {
    Some(value) => value
    None => abort("missing allocator snapshot")
  }
  inspect(snapshot.slabs, content="1")
  inspect(snapshot.slabs_size, content="4")
  inspect(snapshot.allocations, content="2")
}
