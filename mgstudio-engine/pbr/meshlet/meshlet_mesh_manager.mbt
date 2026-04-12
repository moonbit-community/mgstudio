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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/meshlet_mesh_manager.rs`.

///|
pub struct MeshletBufferSliceRange {
  start : Int
  end_ : Int
} derive(Eq, Debug)

///|
fn meshlet_buffer_slice_range_new(
  start : Int,
  end_ : Int,
) -> MeshletBufferSliceRange {
  let safe_start = if start < 0 { 0 } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  MeshletBufferSliceRange::{ start: safe_start, end_: safe_end }
}

///|
pub struct MeshletMeshSlices {
  vertex_positions : MeshletBufferSliceRange
  vertex_normals : MeshletBufferSliceRange
  vertex_uvs : MeshletBufferSliceRange
  indices : MeshletBufferSliceRange
  bvh_nodes : MeshletBufferSliceRange
  meshlets : MeshletBufferSliceRange
  meshlet_cull_data : MeshletBufferSliceRange
  aabb : MeshletAabb
  bvh_depth : Int
}

///|
pub struct MeshletMeshManager {
  mut next_offset : Int
  mut pending_mesh_writes : Int
  mut committed_mesh_writes : Int
  pending_upload_asset_ids : Array[Int]
  meshlet_mesh_slices : Map[Int, MeshletMeshSlices]
}

///|
pub fn MeshletMeshManager::default() -> MeshletMeshManager {
  MeshletMeshManager::{
    next_offset: 0,
    pending_mesh_writes: 0,
    committed_mesh_writes: 0,
    pending_upload_asset_ids: [],
    meshlet_mesh_slices: {},
  }
}

///|
fn meshlet_mesh_manager_allocate_slice(
  manager : MeshletMeshManager,
  count : Int,
) -> MeshletBufferSliceRange {
  let safe_count = if count < 0 { 0 } else { count }
  let start = manager.next_offset
  let end_ = start + safe_count
  manager.next_offset = end_
  meshlet_buffer_slice_range_new(start, end_)
}

///|
fn meshlet_mesh_manager_insert_asset_slices(
  manager : MeshletMeshManager,
  asset_id : Int,
  meshlet_mesh : MeshletMesh,
) -> MeshletMeshSlices {
  let slices = MeshletMeshSlices::{
    vertex_positions: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.vertex_position_word_count,
    ),
    vertex_normals: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.vertex_normal_word_count,
    ),
    vertex_uvs: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.vertex_uv_count,
    ),
    indices: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.index_count,
    ),
    bvh_nodes: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.bvh_node_count,
    ),
    meshlets: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.meshlet_count,
    ),
    meshlet_cull_data: meshlet_mesh_manager_allocate_slice(
      manager,
      meshlet_mesh.meshlet_count,
    ),
    aabb: MeshletAabb::default(),
    bvh_depth: meshlet_mesh.bvh_depth,
  }
  manager.meshlet_mesh_slices.set(asset_id, slices)
  manager.pending_upload_asset_ids.push(asset_id)
  manager.pending_mesh_writes = manager.pending_mesh_writes + 1
  slices
}

///|
pub fn MeshletMeshManager::queue_mesh_write(self : MeshletMeshManager) -> Unit {
  self.pending_mesh_writes = self.pending_mesh_writes + 1
}

///|
pub fn MeshletMeshManager::perform_pending_mesh_writes(
  self : MeshletMeshManager,
) -> Int {
  let pending = self.pending_mesh_writes
  self.pending_mesh_writes = 0
  self.committed_mesh_writes = self.committed_mesh_writes + pending
  self.pending_upload_asset_ids.clear()
  pending
}

///|
pub fn MeshletMeshManager::queue_upload_if_needed(
  self : MeshletMeshManager,
  asset_id : Int,
  meshlet_mesh : MeshletMesh,
) -> (Int, MeshletAabb, Int) {
  let safe_asset_id = if asset_id < 0 { 0 } else { asset_id }
  let slices = match self.meshlet_mesh_slices.get(safe_asset_id) {
    Some(slices) => slices
    None =>
      meshlet_mesh_manager_insert_asset_slices(
        self, safe_asset_id, meshlet_mesh,
      )
  }
  (
    slices.bvh_nodes.start,
    slices.aabb,
    if slices.bvh_depth < 0 {
      0
    } else {
      slices.bvh_depth
    },
  )
}

///|
pub fn MeshletMeshManager::remove(
  self : MeshletMeshManager,
  asset_id : Int,
) -> Bool {
  let safe_asset_id = if asset_id < 0 { 0 } else { asset_id }
  let was_present = self.meshlet_mesh_slices.get(safe_asset_id) is Some(_)
  self.meshlet_mesh_slices.remove(safe_asset_id)
  was_present
}

///|
pub fn MeshletMeshManager::buffered_asset_count(
  self : MeshletMeshManager,
) -> Int {
  self.meshlet_mesh_slices.length()
}

///|
pub fn MeshletMeshManager::pending_upload_count(
  self : MeshletMeshManager,
) -> Int {
  self.pending_upload_asset_ids.length()
}

///|
pub fn perform_pending_meshlet_mesh_writes(manager : MeshletMeshManager) -> Int {
  manager.perform_pending_mesh_writes()
}

///|
pub fn MeshletMeshManager::pending_mesh_writes(
  self : MeshletMeshManager,
) -> Int {
  self.pending_mesh_writes
}

///|
pub fn MeshletMeshManager::committed_mesh_writes(
  self : MeshletMeshManager,
) -> Int {
  self.committed_mesh_writes
}

///|
pub fn meshlet_mesh_manager_runtime_available() -> Bool {
  meshlet_runtime_available()
}
