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
// Bevy source: `bevy/crates/bevy_mesh/src/morph.rs`.
// Runtime owner split out of `mesh/mesh.mbt`.

///|
pub fn Mesh::morph_target_names(self : Mesh) -> Array[String]? {
  match self.geometry {
    MeshGeometry::Geometry2d(_) => None
    MeshGeometry::Geometry3d(geometry3d) => geometry3d.morph_target_names()
  }
}

///|
pub fn Mesh::custom_attribute_vec3(
  self : Mesh,
  name : String,
) -> Array[@math.Vec3]? {
  match self.geometry {
    MeshGeometry::Geometry2d(_) => None
    MeshGeometry::Geometry3d(geometry3d) =>
      geometry3d.custom_attribute_vec3(name)
  }
}
