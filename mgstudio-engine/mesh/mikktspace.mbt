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
// Bevy source: `bevy/crates/bevy_mesh/src/mikktspace.rs`.
// Runtime owner split out of `mesh/mesh.mbt`.

///|
pub(all) enum MeshGenerateTangentsError {
  Not3dGeometry
  GeometryError(Mesh3dGenerateTangentsError)
} derive(Eq, Show)

///|
pub fn Mesh::generate_tangents(self : Mesh) -> MeshGenerateTangentsError? {
  match self.geometry {
    MeshGeometry::Geometry2d(_) =>
      Some(MeshGenerateTangentsError::Not3dGeometry)
    MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.generate_tangents() {
        Some(err) => Some(MeshGenerateTangentsError::GeometryError(err))
        None => None
      }
  }
}
