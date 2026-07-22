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
const MESHLET_U32_BYTE_SIZE : Int = 4

///|
const MESHLET_U8_BYTE_SIZE : Int = 1

///|
const MESHLET_VEC2_BYTE_SIZE : Int = 8

///|
const MESHLET_BVH_NODE_BYTE_SIZE : Int = 400

///|
const MESHLET_MESHLET_BYTE_SIZE : Int = 32

///|
const MESHLET_CULL_DATA_BYTE_SIZE : Int = 48

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
  { start: safe_start, end_: safe_end }
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
  vertex_uvs : PersistentGpuBuffer[MeshletVertexUv]
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
pub fn MeshletMeshManager::MeshletMeshManager() -> MeshletMeshManager {
  {
    vertex_positions: PersistentGpuBuffer::new(
      label="meshlet_vertex_positions",
      element_byte_size=MESHLET_U32_BYTE_SIZE,
    ),
    vertex_normals: PersistentGpuBuffer::new(
      label="meshlet_vertex_normals",
      element_byte_size=MESHLET_U32_BYTE_SIZE,
    ),
    vertex_uvs: PersistentGpuBuffer::new(
      label="meshlet_vertex_uvs",
      element_byte_size=MESHLET_VEC2_BYTE_SIZE,
    ),
    indices: PersistentGpuBuffer::new(
      label="meshlet_indices",
      element_byte_size=MESHLET_U8_BYTE_SIZE,
    ),
    bvh_nodes: PersistentGpuBuffer::new(
      label="meshlet_bvh_nodes",
      element_byte_size=MESHLET_BVH_NODE_BYTE_SIZE,
    ),
    meshlets: PersistentGpuBuffer::new(
      label="meshlets",
      element_byte_size=MESHLET_MESHLET_BYTE_SIZE,
    ),
    meshlet_cull_data: PersistentGpuBuffer::new(
      label="meshlet_cull_data",
      element_byte_size=MESHLET_CULL_DATA_BYTE_SIZE,
    ),
    pending_mesh_writes: 0,
    committed_mesh_writes: 0,
    pending_upload_asset_ids: [],
    meshlet_mesh_slices: Map([]),
  }
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
  { start: safe_start, end_: safe_end }
}

///|
fn meshlet_mesh_manager_insert_asset_slices(
  manager : MeshletMeshManager,
  asset_id : Int,
  meshlet_mesh : MeshletMesh,
) -> MeshletMeshSlices {
  let vertex_positions = manager.vertex_positions.queue_write(
    meshlet_mesh.vertex_positions,
    (),
  )
  let vertex_normals = manager.vertex_normals.queue_write(
    meshlet_mesh.vertex_normals,
    (),
  )
  let vertex_uvs = manager.vertex_uvs.queue_write(meshlet_mesh.vertex_uvs, ())
  let indices = manager.indices.queue_write(meshlet_mesh.indices, ())
  let meshlets = manager.meshlets.queue_write(
    meshlet_mesh.meshlets,
    (vertex_positions.start, vertex_normals.start, indices.start),
  )
  let bvh_nodes = manager.bvh_nodes.queue_write(
    meshlet_mesh.bvh,
    meshlets.start / MESHLET_MESHLET_BYTE_SIZE,
  )
  let meshlet_cull_data = manager.meshlet_cull_data.queue_write(
    meshlet_mesh.meshlet_cull_data,
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
    aabb: meshlet_mesh.aabb,
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
fn meshlet_push_u32_values(out : Array[Byte], values : Array[Int]) -> Unit {
  for value in values {
    meshlet_push_u32_le(out, value.reinterpret_as_uint())
  }
}

///|
fn meshlet_push_u8_values(out : Array[Byte], values : Array[Int]) -> Unit {
  for value in values {
    meshlet_push_u8(out, value)
  }
}

///|
fn meshlet_push_uv_values(
  out : Array[Byte],
  values : Array[MeshletVertexUv],
) -> Unit {
  for value in values {
    meshlet_push_f32_le(out, value.x)
    meshlet_push_f32_le(out, value.y)
  }
}

///|
fn meshlet_push_bvh_values(out : Array[Byte], values : Array[BvhNode]) -> Unit {
  for value in values {
    meshlet_push_bvh_node(out, value)
  }
}

///|
fn meshlet_push_meshlet_values(
  out : Array[Byte],
  values : Array[Meshlet],
) -> Unit {
  for value in values {
    meshlet_push_meshlet(out, value)
  }
}

///|
fn meshlet_push_cull_data_values(
  out : Array[Byte],
  values : Array[MeshletCullData],
) -> Unit {
  for value in values {
    meshlet_push_cull_data(out, value)
  }
}

///|
priv struct MeshletGpuBufferPayload {
  vertex_positions : Bytes
  vertex_normals : Bytes
  vertex_uvs : Bytes
  indices : Bytes
  bvh_nodes : Bytes
  meshlets : Bytes
  cull_data : Bytes
  instance_uniforms : Bytes
  instance_aabbs : Bytes
  instance_material_ids : Bytes
  instance_bvh_root_nodes : Bytes
}

///|
fn MeshletGpuBufferPayload::byte_count(self : MeshletGpuBufferPayload) -> Int {
  self.vertex_positions.length() +
  self.vertex_normals.length() +
  self.vertex_uvs.length() +
  self.indices.length() +
  self.bvh_nodes.length() +
  self.meshlets.length() +
  self.cull_data.length() +
  self.instance_uniforms.length() +
  self.instance_aabbs.length() +
  self.instance_material_ids.length() +
  self.instance_bvh_root_nodes.length()
}

///|
fn MeshletMeshManager::gpu_buffer_payload(
  self : MeshletMeshManager,
  instance_manager : InstanceManager,
) -> MeshletGpuBufferPayload {
  let vertex_positions : Array[Byte] = []
  let vertex_normals : Array[Byte] = []
  let vertex_uvs : Array[Byte] = []
  let indices : Array[Byte] = []
  let bvh_nodes : Array[Byte] = []
  let meshlets : Array[Byte] = []
  let cull_data : Array[Byte] = []
  meshlet_push_u32_values(vertex_positions, self.vertex_positions.snapshot())
  meshlet_push_u32_values(vertex_normals, self.vertex_normals.snapshot())
  meshlet_push_uv_values(vertex_uvs, self.vertex_uvs.snapshot())
  meshlet_push_u8_values(indices, self.indices.snapshot())
  meshlet_push_bvh_values(bvh_nodes, self.bvh_nodes.snapshot())
  meshlet_push_meshlet_values(meshlets, self.meshlets.snapshot())
  meshlet_push_cull_data_values(cull_data, self.meshlet_cull_data.snapshot())
  let instance_payload = instance_manager.gpu_buffer_payload()
  {
    vertex_positions: Bytes::from_array(vertex_positions),
    vertex_normals: Bytes::from_array(vertex_normals),
    vertex_uvs: Bytes::from_array(vertex_uvs),
    indices: Bytes::from_array(indices),
    bvh_nodes: Bytes::from_array(bvh_nodes),
    meshlets: Bytes::from_array(meshlets),
    cull_data: Bytes::from_array(cull_data),
    instance_uniforms: instance_payload.instance_uniforms,
    instance_aabbs: instance_payload.instance_aabbs,
    instance_material_ids: instance_payload.instance_material_ids,
    instance_bvh_root_nodes: instance_payload.instance_bvh_root_nodes,
  }
}

///|
fn upload_meshlet_mesh_manager_to_renderer(
  manager : MeshletMeshManager,
  instance_manager : InstanceManager,
) -> Int {
  let payload = manager.gpu_buffer_payload(instance_manager)
  @renderer.prepare_meshlet_storage_buffers(
    vertex_positions=payload.vertex_positions,
    vertex_normals=payload.vertex_normals,
    vertex_uvs=payload.vertex_uvs,
    indices=payload.indices,
    bvh_nodes=payload.bvh_nodes,
    meshlets=payload.meshlets,
    cull_data=payload.cull_data,
    instance_uniforms=payload.instance_uniforms,
    instance_aabbs=payload.instance_aabbs,
    instance_material_ids=payload.instance_material_ids,
    instance_bvh_root_nodes=payload.instance_bvh_root_nodes,
  )
  payload.byte_count()
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
    slices.bvh_nodes.start / MESHLET_BVH_NODE_BYTE_SIZE,
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
