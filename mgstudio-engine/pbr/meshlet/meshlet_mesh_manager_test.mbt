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
test "pbr/meshlet: mesh manager queues uploads by asset id" {
  let manager = MeshletMeshManager::default()
  let meshlet_mesh = MeshletMesh::new(4, 3)
    .with_vertex_buffers(10, 20, 5, 30)
    .with_bvh_depth(6)

  let queued = manager.queue_upload_if_needed(1, meshlet_mesh)
  debug_inspect(queued.0, content="0")
  debug_inspect(queued.2, content="6")
  debug_inspect(manager.pending_upload_count(), content="1")
  debug_inspect(manager.buffered_asset_count(), content="1")
  perform_pending_meshlet_mesh_writes(manager)
  debug_inspect(manager.committed_mesh_writes(), content="1")
  debug_inspect(manager.pending_upload_count(), content="0")
}

///|
test "pbr/meshlet: mesh manager removes slices from all persistent buffers" {
  let manager = MeshletMeshManager::default()
  let meshlet_mesh = MeshletMesh::new(2, 1)
    .with_vertex_buffers(4, 4, 2, 6)
    .with_bvh_depth(2)
  ignore(manager.queue_upload_if_needed(7, meshlet_mesh))
  perform_pending_meshlet_mesh_writes(manager)
  manager.remove(7)
  inspect(manager.buffered_asset_count(), content="0")
  manager.remove(7)
  inspect(manager.buffered_asset_count(), content="0")
}
