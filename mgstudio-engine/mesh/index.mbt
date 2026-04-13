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
// Bevy source: `bevy/crates/bevy_mesh/src/index.rs`.
// Runtime owner split across `mesh/mesh2d.mbt` and `mesh/mesh3d.mbt`.

///|
fn mesh_sequential_indices(count : Int) -> Array[Int] {
  let indices : Array[Int] = []
  for index in 0..<count {
    indices.push(index)
  }
  indices
}

///|
pub fn Mesh2dGeometry::has_indices(self : Mesh2dGeometry) -> Bool {
  match self.indices {
    Some(_) => true
    None => false
  }
}

///|
pub fn Mesh2dGeometry::indices_or_sequential(
  self : Mesh2dGeometry,
) -> Array[Int] {
  match self.indices {
    Some(indices) => indices.copy()
    None => mesh_sequential_indices(self.positions.length())
  }
}

///|
pub fn Mesh3dGeometry::has_indices(self : Mesh3dGeometry) -> Bool {
  match self.indices {
    Some(_) => true
    None => false
  }
}

///|
pub fn Mesh3dGeometry::indices_or_sequential(
  self : Mesh3dGeometry,
) -> Array[Int] {
  match self.indices {
    Some(indices) => indices.copy()
    None => mesh_sequential_indices(self.positions.length())
  }
}
