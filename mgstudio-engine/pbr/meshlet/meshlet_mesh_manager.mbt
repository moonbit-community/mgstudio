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
  vertex_positions : PersistentGpuBuffer[Int]
  vertex_normals : PersistentGpuBuffer[Int]
  vertex_uvs : PersistentGpuBuffer[Int]
  indices : PersistentGpuBuffer[Int]
  bvh_nodes : PersistentGpuBuffer[BvhNode]
  meshlets : PersistentGpuBuffer[Meshlet]
  meshlet_cull_data : PersistentGpuBuffer[MeshletCullData]
  mut pending_mesh_writes : Int
  mut committed_mesh_writes : Int
  pending_upload_asset_ids : Array[Int]
  meshlet_mesh_slices : Map[Int, MeshletMeshSlices]
}

///|
pub fn MeshletMeshManager::default() -> MeshletMeshManager {
  MeshletMeshManager::{
    vertex_positions: PersistentGpuBuffer::new(label="meshlet_vertex_positions"),
    vertex_normals: PersistentGpuBuffer::new(label="meshlet_vertex_normals"),
    vertex_uvs: PersistentGpuBuffer::new(label="meshlet_vertex_uvs"),
    indices: PersistentGpuBuffer::new(label="meshlet_indices"),
    bvh_nodes: PersistentGpuBuffer::new(label="meshlet_bvh_nodes"),
    meshlets: PersistentGpuBuffer::new(label="meshlets"),
    meshlet_cull_data: PersistentGpuBuffer::new(label="meshlet_cull_data"),
    pending_mesh_writes: 0,
    committed_mesh_writes: 0,
    pending_upload_asset_ids: [],
    meshlet_mesh_slices: {},
  }
}

///|
fn meshlet_empty_words(word_count : Int) -> Array[Int] {
  let safe_count = if word_count < 0 { 0 } else { word_count }
  let values : Array[Int] = []
  for _ in 0..<safe_count {
    values.push(0)
  }
  values
}

///|
fn meshlet_empty_bvh_nodes(node_count : Int) -> Array[BvhNode] {
  let safe_count = if node_count < 0 { 0 } else { node_count }
  let values : Array[BvhNode] = []
  for index in 0..<safe_count {
    values.push(BvhNode::leaf(index))
  }
  values
}

///|
fn meshlet_empty_meshlets(meshlet_count : Int) -> Array[Meshlet] {
  let safe_count = if meshlet_count < 0 { 0 } else { meshlet_count }
  let values : Array[Meshlet] = []
  for _ in 0..<safe_count {
    values.push(Meshlet::new(0, 0, 0, 3, 1))
  }
  values
}

///|
fn meshlet_empty_cull_data(meshlet_count : Int) -> Array[MeshletCullData] {
  let safe_count = if meshlet_count < 0 { 0 } else { meshlet_count }
  let values : Array[MeshletCullData] = []
  for _ in 0..<safe_count {
    values.push(MeshletCullData::default())
  }
  values
}

///|
fn meshlet_slice_from_persistent(
  slice_range : PersistentBufferSliceRange,
) -> MeshletBufferSliceRange {
  meshlet_buffer_slice_range_new(slice_range.start, slice_range.end_)
}

///|
fn meshlet_slice_to_persistent(
  slice_range : MeshletBufferSliceRange,
) -> PersistentBufferSliceRange {
  let safe_start = if slice_range.start < 0 { 0 } else { slice_range.start }
  let safe_end = if slice_range.end_ < safe_start {
    safe_start
  } else {
    slice_range.end_
  }
  PersistentBufferSliceRange::{ start: safe_start, end_: safe_end }
}

///|
fn meshlet_mesh_manager_insert_asset_slices(
  manager : MeshletMeshManager,
  asset_id : Int,
  meshlet_mesh : MeshletMesh,
) -> MeshletMeshSlices {
  let vertex_positions = manager.vertex_positions.queue_write(
    meshlet_empty_words(meshlet_mesh.vertex_position_word_count),
    (),
  )
  let vertex_normals = manager.vertex_normals.queue_write(
    meshlet_empty_words(meshlet_mesh.vertex_normal_word_count),
    (),
  )
  let vertex_uvs = manager.vertex_uvs.queue_write(
    meshlet_empty_words(meshlet_mesh.vertex_uv_count),
    (),
  )
  let indices = manager.indices.queue_write(
    meshlet_empty_words(meshlet_mesh.index_count),
    (),
  )
  let meshlets = manager.meshlets.queue_write(
    meshlet_empty_meshlets(meshlet_mesh.meshlet_count),
    (vertex_positions.start, vertex_normals.start, indices.start),
  )
  let bvh_nodes = manager.bvh_nodes.queue_write(
    meshlet_empty_bvh_nodes(meshlet_mesh.bvh_node_count),
    meshlets.start,
  )
  let meshlet_cull_data = manager.meshlet_cull_data.queue_write(
    meshlet_empty_cull_data(meshlet_mesh.meshlet_count),
    (),
  )
  let slices = MeshletMeshSlices::{
    vertex_positions: meshlet_slice_from_persistent(vertex_positions),
    vertex_normals: meshlet_slice_from_persistent(vertex_normals),
    vertex_uvs: meshlet_slice_from_persistent(vertex_uvs),
    indices: meshlet_slice_from_persistent(indices),
    bvh_nodes: meshlet_slice_from_persistent(bvh_nodes),
    meshlets: meshlet_slice_from_persistent(meshlets),
    meshlet_cull_data: meshlet_slice_from_persistent(meshlet_cull_data),
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
  let pending = self.pending_upload_asset_ids.length()
  ignore(self.vertex_positions.perform_writes())
  ignore(self.vertex_normals.perform_writes())
  ignore(self.vertex_uvs.perform_writes())
  ignore(self.indices.perform_writes())
  ignore(self.bvh_nodes.perform_writes())
  ignore(self.meshlets.perform_writes())
  ignore(self.meshlet_cull_data.perform_writes())
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
) -> Unit {
  let safe_asset_id = if asset_id < 0 { 0 } else { asset_id }
  match self.meshlet_mesh_slices.get(safe_asset_id) {
    Some(slices) => {
      self.vertex_positions.mark_slice_unused(
        meshlet_slice_to_persistent(slices.vertex_positions),
      )
      self.vertex_normals.mark_slice_unused(
        meshlet_slice_to_persistent(slices.vertex_normals),
      )
      self.vertex_uvs.mark_slice_unused(
        meshlet_slice_to_persistent(slices.vertex_uvs),
      )
      self.indices.mark_slice_unused(
        meshlet_slice_to_persistent(slices.indices),
      )
      self.bvh_nodes.mark_slice_unused(
        meshlet_slice_to_persistent(slices.bvh_nodes),
      )
      self.meshlets.mark_slice_unused(
        meshlet_slice_to_persistent(slices.meshlets),
      )
      self.meshlet_cull_data.mark_slice_unused(
        meshlet_slice_to_persistent(slices.meshlet_cull_data),
      )
    }
    None => ()
  }
  self.meshlet_mesh_slices.remove(safe_asset_id)
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
pub fn perform_pending_meshlet_mesh_writes(
  manager : MeshletMeshManager,
) -> Unit {
  ignore(manager.perform_pending_mesh_writes())
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
