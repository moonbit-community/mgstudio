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
pub(all) enum MeshGeometry {
  Geometry2d(Mesh2dGeometry)
  Geometry3d(Mesh3dGeometry)
}

///|
pub struct Mesh {
  geometry : MeshGeometry
}

///|
pub fn Mesh::from_2d_geometry(geometry2d : Mesh2dGeometry) -> Mesh {
  Mesh::{ geometry: MeshGeometry::Geometry2d(geometry2d) }
}

///|
pub fn Mesh::from_3d_geometry(geometry3d : Mesh3dGeometry) -> Mesh {
  Mesh::{ geometry: MeshGeometry::Geometry3d(geometry3d) }
}
