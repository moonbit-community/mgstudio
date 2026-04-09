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
// Bevy source: `bevy/crates/bevy_mesh/src/conversions.rs`.
// Runtime owner split out of `mesh/mesh.mbt`.

///|
pub(open) trait IntoMeshAsset {
  into_mesh_asset(Self) -> Mesh
}

///|
pub fn Mesh::from_2d_geometry(geometry2d : Mesh2dGeometry) -> Mesh {
  Mesh::{ geometry: MeshGeometry::Geometry2d(geometry2d) }
}

///|
pub fn Mesh2dGeometry::to_mesh(self : Mesh2dGeometry) -> Mesh {
  Mesh::from_2d_geometry(self)
}

///|
pub impl IntoMeshAsset for Mesh2dGeometry with into_mesh_asset(self) {
  self.to_mesh()
}

///|
pub fn Mesh::from_3d_geometry(geometry3d : Mesh3dGeometry) -> Mesh {
  Mesh::{ geometry: MeshGeometry::Geometry3d(geometry3d) }
}

///|
pub fn Mesh3dGeometry::to_mesh(self : Mesh3dGeometry) -> Mesh {
  Mesh::from_3d_geometry(self)
}

///|
pub impl IntoMeshAsset for Mesh3dGeometry with into_mesh_asset(self) {
  self.to_mesh()
}

///|
pub fn[S : IntoMeshAsset] add(
  assets : @asset.Assets[Mesh],
  value : S,
) -> @asset.Handle[Mesh] {
  assets.add(value.into_mesh_asset())
}
