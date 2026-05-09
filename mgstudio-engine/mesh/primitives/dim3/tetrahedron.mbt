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
pub fn tetrahedron(
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
  d : @math.Vec3,
) -> @math.Tetrahedron {
  @math.Tetrahedron::new(a, b, c, d)
}

///|
pub struct TetrahedronMeshBuilder {
  tetrahedron : @math.Tetrahedron
}

///|
pub fn TetrahedronMeshBuilder::default() -> TetrahedronMeshBuilder {
  { tetrahedron: @math.Tetrahedron::default() }
}

///|
pub fn TetrahedronMeshBuilder::new(
  tetrahedron : @math.Tetrahedron,
) -> TetrahedronMeshBuilder {
  { tetrahedron, }
}

///|
pub fn TetrahedronMeshBuilder::build(
  self : TetrahedronMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  tetrahedron_mesh(self.tetrahedron)
}

///|
pub impl MeshBuilder for TetrahedronMeshBuilder with build(self) {
  tetrahedron_mesh(self.tetrahedron)
}

///|
pub fn tetrahedron_mesh(shape : @math.Tetrahedron) -> @mesh.Mesh3dGeometry {
  let reverse_faces = tetrahedron_signed_volume(shape) < 0.0F
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []

  for face in shape.faces() {
    if face.vertices.length() < 3 {
      continue
    }
    let oriented = if reverse_faces {
      @math.Triangle3d::new(
        face.vertices[0],
        face.vertices[2],
        face.vertices[1],
      )
    } else {
      face
    }
    let face_normal = triangle3d_normal_vec(oriented)
    let (uv_a, uv_b, uv_c) = triangle3d_uv_coords(oriented)
    positions.push(oriented.vertices[0])
    positions.push(oriented.vertices[1])
    positions.push(oriented.vertices[2])
    normals.push(face_normal)
    normals.push(face_normal)
    normals.push(face_normal)
    uvs.push(uv_a)
    uvs.push(uv_b)
    uvs.push(uv_c)
  }

  primitive_geometry_with_normals(
    positions,
    normals,
    uvs,
    Some([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
  )
}

///|
fn tetrahedron_signed_volume(shape : @math.Tetrahedron) -> Float {
  if shape.vertices.length() < 4 {
    return 0.0F
  }
  let a = shape.vertices[0]
  let b = shape.vertices[1]
  let c = shape.vertices[2]
  let d = shape.vertices[3]
  b.sub(a).cross(c.sub(a)).dot(d.sub(a)) / 6.0F
}
