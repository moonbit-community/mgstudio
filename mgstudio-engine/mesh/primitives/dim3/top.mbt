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

// `Milky2018/mgstudio/mesh` runtime owners.

///|
pub using @math {type Capsule3d}

///|
pub using @math {type Cone}

///|
pub using @math {type ConicalFrustum}

///|
pub using @math {type Cuboid}

///|
pub using @math {type Cylinder}

///|
pub using @math {type Plane3d}

///|
pub using @math {type Polyline3d}

///|
pub using @math {type Segment3d}

///|
pub using @math {type Sphere}

///|
pub using @math {type Tetrahedron}

///|
pub using @math {type Torus}

///|
pub using @math {type Triangle3d}

///|
pub using @mesh {type Mesh3dGeometry}

///|
pub using @mesh {type Mesh3dPrimitiveTopology}

///|
fn primitive_f32(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn primitive_geometry_with_normals(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new(positions, uvs, indices).with_custom_attribute_vec3(
    @mesh.MESH3D_ATTRIBUTE_NORMAL_NAME,
    normals,
  )
}

///|
fn primitive_geometry_with_normals_and_topology(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
  topology : @mesh.Mesh3dPrimitiveTopology,
) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new_with_topology(positions, uvs, indices, topology).with_custom_attribute_vec3(
    @mesh.MESH3D_ATTRIBUTE_NORMAL_NAME,
    normals,
  )
}

///|
fn primitive_zero_uvs(count : Int) -> Array[@math.Vec2] {
  let uvs : Array[@math.Vec2] = []
  for _ in 0..<count {
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  uvs
}

///|
fn primitive_push_vertex(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  position : @math.Vec3,
  normal : @math.Vec3,
  uv : @math.Vec2,
) -> Unit {
  positions.push(position)
  normals.push(normal)
  uvs.push(uv)
}
