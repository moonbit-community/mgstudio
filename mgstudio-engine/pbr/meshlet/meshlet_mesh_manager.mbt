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
pub struct MeshletMeshManager {
  mut pending_mesh_writes : Int
  mut committed_mesh_writes : Int
}

///|
pub fn MeshletMeshManager::default() -> MeshletMeshManager {
  MeshletMeshManager::{ pending_mesh_writes: 0, committed_mesh_writes: 0 }
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
  pending
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
