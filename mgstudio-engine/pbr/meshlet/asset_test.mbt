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
test "pbr/meshlet: meshlet asset metadata is bevy-shaped" {
  let meshlet_mesh = MeshletMesh::new(3, 2)
    .with_vertex_buffers(64, 64, 32, 96)
    .with_bvh_depth(4)
  debug_inspect(meshlet_mesh.meshlet_count, content="3")
  debug_inspect(meshlet_mesh.vertex_count_estimate(), content="32")
  debug_inspect(meshlet_mesh.is_empty(), content="false")
  debug_inspect(meshlet_mesh_asset_magic() > 0, content="true")
  debug_inspect(meshlet_mesh_asset_version_matches(3), content="true")
}

///|
test "pbr/meshlet: save/load error debug helper keeps exact reason" {
  let message = meshlet_mesh_save_or_load_error_debug_message(WrongVersion(2))
  debug_inspect(message, content="\"wrong version: 2\"")
}
