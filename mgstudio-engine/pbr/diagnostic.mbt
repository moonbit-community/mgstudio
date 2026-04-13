// Copyright 2025 International Digital Economy Academy
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
pub fn render3d_diagnostic_queued_visible_mesh_count(world : @ecs.World) -> Int {
  @pbr_render.render3d_diagnostic_queued_visible_mesh_count(world)
}

///|
pub fn render3d_diagnostic_prepared_camera_count(world : @ecs.World) -> Int {
  @pbr_render.render3d_diagnostic_prepared_camera_count(world)
}

///|
pub fn render3d_diagnostic_queue_cpu_ms(world : @ecs.World) -> Float {
  @pbr_render.render3d_diagnostic_queue_cpu_ms(world)
}

///|
pub fn render3d_diagnostic_execute_cpu_ms(world : @ecs.World) -> Float {
  @pbr_render.render3d_diagnostic_execute_cpu_ms(world)
}

///|
pub fn render3d_prepared_camera_count(world : @ecs.World) -> Int? {
  @pbr_render.render3d_prepared_camera_count(world)
}

///|
pub fn render3d_queued_visible_mesh_count(world : @ecs.World) -> Int? {
  @pbr_render.render3d_queued_visible_mesh_count(world)
}

///|
pub struct Render3dDiagnosticsSnapshot {
  prepared_camera_count : Int
  queued_visible_mesh_count : Int
  queue_cpu_ms : Float
  execute_cpu_ms : Float
}

///|
pub fn Render3dDiagnosticsSnapshot::default() -> Render3dDiagnosticsSnapshot {
  Render3dDiagnosticsSnapshot::{
    prepared_camera_count: 0,
    queued_visible_mesh_count: 0,
    queue_cpu_ms: 0.0F,
    execute_cpu_ms: 0.0F,
  }
}

///|
pub fn render3d_diagnostics_snapshot(
  world : @ecs.World,
) -> Render3dDiagnosticsSnapshot {
  Render3dDiagnosticsSnapshot::{
    prepared_camera_count: render3d_diagnostic_prepared_camera_count(world),
    queued_visible_mesh_count: render3d_diagnostic_queued_visible_mesh_count(
      world,
    ),
    queue_cpu_ms: render3d_diagnostic_queue_cpu_ms(world),
    execute_cpu_ms: render3d_diagnostic_execute_cpu_ms(world),
  }
}

///|
pub struct MaterialAllocatorDiagnosticsSnapshot {
  slabs : Int
  slabs_size : Int
  allocations : UInt
}

///|
pub fn MaterialAllocatorDiagnosticsSnapshot::default() -> MaterialAllocatorDiagnosticsSnapshot {
  MaterialAllocatorDiagnosticsSnapshot::{
    slabs: 0,
    slabs_size: 0,
    allocations: 0U,
  }
}

///|
pub fn render3d_material_allocator_slabs_path(material_name : String) -> String {
  "material_allocator_slabs/\{material_name}"
}

///|
pub fn render3d_material_allocator_slabs_size_path(
  material_name : String,
) -> String {
  "material_allocator_slabs_size/\{material_name}"
}

///|
pub fn render3d_material_allocator_allocations_path(
  material_name : String,
) -> String {
  "material_allocator_allocations/\{material_name}"
}

///|
pub fn render3d_material_allocator_snapshot_for_key(
  allocators : MaterialBindGroupAllocators,
  material_name : String,
) -> MaterialAllocatorDiagnosticsSnapshot? {
  match allocators.get(material_name) {
    Some(allocator) =>
      Some(MaterialAllocatorDiagnosticsSnapshot::{
        slabs: allocator.slab_count(),
        slabs_size: allocator.slabs_size(),
        allocations: allocator.allocations(),
      })
    None => None
  }
}
