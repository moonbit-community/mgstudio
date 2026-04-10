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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/from_mesh.rs`.

///|
pub(all) enum MeshToMeshletMeshConversionError {
  RuntimeUnavailable
  MissingPositions
  UnsupportedTopology
  TooManyVertices
}

///|
pub fn meshlet_can_convert_from_mesh(
  vertex_count : Int,
  triangle_count : Int,
) -> Bool {
  meshlet_runtime_available() && vertex_count > 0 && triangle_count > 0
}

///|
pub fn meshlet_from_mesh_runtime_available() -> Bool {
  meshlet_runtime_available()
}

///|
pub fn meshlet_conversion_error_when_unavailable() -> MeshToMeshletMeshConversionError {
  MeshToMeshletMeshConversionError::RuntimeUnavailable
}
