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
pub fn Mesh::as_2d_geometry(self : Mesh) -> Mesh2dGeometry? {
  match self.geometry {
    MeshGeometry::Geometry2d(geometry2d) => Some(geometry2d)
    MeshGeometry::Geometry3d(_) => None
  }
}

///|
pub fn Mesh::with_2d_geometry(
  self : Mesh,
  geometry2d : Mesh2dGeometry,
) -> Mesh? {
  match self.geometry {
    MeshGeometry::Geometry2d(_) =>
      Some(Mesh::{
        geometry: MeshGeometry::Geometry2d(geometry2d),
        skinned_mesh_bounds: self.skinned_mesh_bounds,
      })
    MeshGeometry::Geometry3d(_) => None
  }
}

///|
pub fn Mesh::as_3d_geometry(self : Mesh) -> Mesh3dGeometry? {
  match self.geometry {
    MeshGeometry::Geometry3d(geometry3d) => Some(geometry3d)
    MeshGeometry::Geometry2d(_) => None
  }
}

///|
pub fn Mesh::with_3d_geometry(
  self : Mesh,
  geometry3d : Mesh3dGeometry,
) -> Mesh? {
  match self.geometry {
    MeshGeometry::Geometry3d(_) =>
      Some(Mesh::{
        geometry: MeshGeometry::Geometry3d(geometry3d),
        skinned_mesh_bounds: self.skinned_mesh_bounds,
      })
    MeshGeometry::Geometry2d(_) => None
  }
}

///|
pub fn Mesh::vertex_count(self : Mesh) -> Int {
  match self.geometry {
    MeshGeometry::Geometry2d(geometry2d) => geometry2d.vertex_count()
    MeshGeometry::Geometry3d(geometry3d) => geometry3d.vertex_count()
  }
}

///|
pub fn Mesh::indexed(self : Mesh) -> Bool {
  match self.geometry {
    MeshGeometry::Geometry2d(geometry2d) => geometry2d.has_indices()
    MeshGeometry::Geometry3d(geometry3d) => geometry3d.has_indices()
  }
}

///|
pub fn Mesh::skinned_mesh_bounds(self : Mesh) -> SkinnedMeshBounds? {
  self.skinned_mesh_bounds
}

///|
pub fn Mesh::set_skinned_mesh_bounds(
  self : Mesh,
  skinned_mesh_bounds : SkinnedMeshBounds?,
) -> Unit {
  self.skinned_mesh_bounds = skinned_mesh_bounds
}

///|
pub fn Mesh::with_skinned_mesh_bounds(
  self : Mesh,
  skinned_mesh_bounds : SkinnedMeshBounds?,
) -> Mesh {
  self.set_skinned_mesh_bounds(skinned_mesh_bounds)
  self
}

///|
pub fn Mesh::generate_skinned_mesh_bounds(
  self : Mesh,
) -> Result[Unit, SkinnedMeshBoundsError] {
  match SkinnedMeshBounds::from_mesh(self) {
    Ok(bounds) => {
      self.skinned_mesh_bounds = Some(bounds)
      Ok(())
    }
    Err(error) => Err(error)
  }
}

///|
pub fn Mesh::with_generated_skinned_mesh_bounds(
  self : Mesh,
) -> Result[Mesh, SkinnedMeshBoundsError] {
  match self.generate_skinned_mesh_bounds() {
    Ok(_) => Ok(self)
    Err(error) => Err(error)
  }
}
