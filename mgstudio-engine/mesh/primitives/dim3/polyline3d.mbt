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
pub fn polyline3d(vertices : Array[@math.Vec3]) -> @math.Polyline3d {
  @math.Polyline3d::new(vertices)
}

///|
pub struct Polyline3dMeshBuilder {
  polyline : @math.Polyline3d
}

///|
pub fn Polyline3dMeshBuilder::Polyline3dMeshBuilder() -> Polyline3dMeshBuilder {
  { polyline: Polyline3d() }
}

///|
pub fn Polyline3dMeshBuilder::new(
  polyline : @math.Polyline3d,
) -> Polyline3dMeshBuilder {
  { polyline, }
}

///|
pub fn Polyline3dMeshBuilder::build(
  self : Polyline3dMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  polyline3d_line_list(self.polyline)
}

///|
pub impl MeshBuilder for Polyline3dMeshBuilder with fn build(self) {
  polyline3d_line_list(self.polyline)
}

///|
pub impl Meshable for @math.Polyline3d with fn mesh(self) {
  Polyline3dMeshBuilder::new(self).build()
}

///|
pub fn polyline3d_line_list(shape : @math.Polyline3d) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for vertex in shape.vertices {
    positions.push(vertex)
  }
  let indices : Array[Int] = []
  if positions.length() >= 2 {
    for index in 0..<(positions.length() - 1) {
      indices.push(index)
      indices.push(index + 1)
    }
  }
  @mesh.Mesh3dGeometry::new_with_positions_and_topology(
    positions,
    Some(indices),
    LineList,
  )
}
