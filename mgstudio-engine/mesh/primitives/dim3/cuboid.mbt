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
pub fn cuboid(
  x_length : Float,
  y_length : Float,
  z_length : Float,
) -> @math.Cuboid {
  @math.Cuboid::new(x_length, y_length, z_length)
}

///|
pub struct CuboidMeshBuilder {
  half_size : @math.Vec3
}

///|
pub fn CuboidMeshBuilder::CuboidMeshBuilder() -> CuboidMeshBuilder {
  { half_size: @math.Vec3::splat(0.5F) }
}

///|
pub fn CuboidMeshBuilder::new(
  x_length : Float,
  y_length : Float,
  z_length : Float,
) -> CuboidMeshBuilder {
  CuboidMeshBuilder::from_cuboid(
    @math.Cuboid::new(x_length, y_length, z_length),
  )
}

///|
pub fn CuboidMeshBuilder::from_cuboid(
  cuboid : @math.Cuboid,
) -> CuboidMeshBuilder {
  { half_size: cuboid.half_size }
}

///|
pub fn CuboidMeshBuilder::half_size(self : CuboidMeshBuilder) -> @math.Vec3 {
  self.half_size
}

///|
pub fn CuboidMeshBuilder::build(
  self : CuboidMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  cuboid_mesh({ half_size: self.half_size })
}

///|
pub impl MeshBuilder for CuboidMeshBuilder with fn build(self) {
  cuboid_mesh({ half_size: self.half_size })
}

///|
pub impl Meshable for @math.Cuboid with fn mesh(self) {
  CuboidMeshBuilder::from_cuboid(self).build()
}

///|
pub fn cuboid_mesh(shape : @math.Cuboid) -> @mesh.Mesh3dGeometry {
  let min = shape.half_size.mul_scalar(-1.0F)
  let max = shape.half_size
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, max.z),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, max.z),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, max.z),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, max.z),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, min.z),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, min.z),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, min.z),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, min.z),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, min.z),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, min.z),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, max.z),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, max.z),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, max.z),
    @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, max.z),
    @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, min.z),
    @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, min.z),
    @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, min.z),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, min.z),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, max.y, max.z),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, max.y, max.z),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )

  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, max.z),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, max.z),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(min.x, min.y, min.z),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
  primitive_push_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(max.x, min.y, min.z),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )

  primitive_geometry_with_normals(
    positions,
    normals,
    uvs,
    Some([
      0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 8, 9, 10, 10, 11, 8, 12, 13, 14, 14, 15,
      12, 16, 17, 18, 18, 19, 16, 20, 21, 22, 22, 23, 20,
    ]),
  )
}
