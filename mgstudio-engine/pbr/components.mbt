// Copyright 2026 International Digital Economy Academy
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
pub type Mesh3d = @mesh.Mesh3d

///|
pub type Mesh = @mesh.Mesh

///|
pub type Mesh3dGeometry = @mesh.Mesh3dGeometry

///|
fn mesh3d_append_triangle(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
) -> Unit {
  positions.push(a)
  positions.push(b)
  positions.push(c)
  uvs.push(@math.Vec2::new(0.5F, 0.0F))
  uvs.push(@math.Vec2::new(0.0F, 1.0F))
  uvs.push(@math.Vec2::new(1.0F, 1.0F))
}

///|
pub fn mesh3d_geometry_cuboid(
  width : Float,
  height : Float,
  depth : Float,
) -> Mesh3dGeometry {
  mesh3d_geometry_primitive_cuboid(@math.Cuboid::new(width, height, depth))
}

///|
pub fn mesh3d_geometry_plane(
  width : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_plane_subdivisions(width, depth, 0)
}

///|
pub fn mesh3d_geometry_tetrahedron(edge : Float) -> @mesh.Mesh3dGeometry {
  let safe_edge = if edge <= 0.0F { 1.0F } else { edge }
  let h = safe_edge * 0.5F
  let v0 = @math.Vec3::new(0.0F, h, 0.0F)
  let v1 = @math.Vec3::new(-h, -h, h)
  let v2 = @math.Vec3::new(h, -h, h)
  let v3 = @math.Vec3::new(0.0F, -h, -h)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  mesh3d_append_triangle(positions, uvs, v0, v1, v2)
  mesh3d_append_triangle(positions, uvs, v0, v2, v3)
  mesh3d_append_triangle(positions, uvs, v0, v3, v1)
  mesh3d_append_triangle(positions, uvs, v1, v3, v2)
  @mesh.Mesh3dGeometry::new(positions, uvs, None)
}

///|
fn mesh3d_triangle_uvs(
  triangle : @math.Triangle3d,
) -> (@math.Vec2, @math.Vec2, @math.Vec2) {
  if triangle.vertices.length() < 3 {
    return (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  }
  let a = triangle.vertices[0]
  let b = triangle.vertices[1]
  let c = triangle.vertices[2]
  let ab = @math.Vec3::new(b.x - a.x, b.y - a.y, b.z - a.z)
  let main_length = @math.sqrt(ab.x * ab.x + ab.y * ab.y + ab.z * ab.z)
  if main_length <= 0.000001F {
    return (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  }
  let x_dir = ab.normalize_or_zero()
  let y_vec = @math.Vec3::new(c.x - a.x, c.y - a.y, c.z - a.z)
  let offset = (y_vec.x * x_dir.x + y_vec.y * x_dir.y + y_vec.z * x_dir.z) /
    main_length
  if offset < 0.0F {
    let total_length = 1.0F - offset
    return (
      @math.Vec2::new(offset.abs() / total_length, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  }
  if offset > 1.0F {
    return (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F / offset, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    )
  }
  (
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(offset, 1.0F),
  )
}

///|
pub fn mesh3d_geometry_triangle(
  triangle : @math.Triangle3d,
) -> @mesh.Mesh3dGeometry {
  if triangle.vertices.length() < 3 {
    return @mesh.Mesh3dGeometry::new([], [], None)
  }
  let a = triangle.vertices[0]
  let b = triangle.vertices[1]
  let c = triangle.vertices[2]
  let (uv_a, uv_b, uv_c) = mesh3d_triangle_uvs(triangle)
  let positions : Array[@math.Vec3] = [a, b, c]
  let uvs : Array[@math.Vec2] = [uv_a, uv_b, uv_c]
  @mesh.Mesh3dGeometry::new(positions, uvs, Some([0, 1, 2]))
}

///|
fn mesh3d_tetrahedron_signed_volume(tetrahedron : @math.Tetrahedron) -> Float {
  if tetrahedron.vertices.length() < 4 {
    return 0.0F
  }
  let a = tetrahedron.vertices[0]
  let b = tetrahedron.vertices[1]
  let c = tetrahedron.vertices[2]
  let d = tetrahedron.vertices[3]
  let ab = @math.Vec3::new(b.x - a.x, b.y - a.y, b.z - a.z)
  let ac = @math.Vec3::new(c.x - a.x, c.y - a.y, c.z - a.z)
  let ad = @math.Vec3::new(d.x - a.x, d.y - a.y, d.z - a.z)
  let cross = ab.cross(ac)
  (cross.x * ad.x + cross.y * ad.y + cross.z * ad.z) / 6.0F
}

///|
pub fn mesh3d_geometry_tetrahedron_shape(
  tetrahedron : @math.Tetrahedron,
) -> @mesh.Mesh3dGeometry {
  let reverse_faces = mesh3d_tetrahedron_signed_volume(tetrahedron) < 0.0F
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for face in tetrahedron.faces() {
    if face.vertices.length() < 3 {
      continue
    }
    let face_vertices = if reverse_faces {
      [face.vertices[0], face.vertices[2], face.vertices[1]]
    } else {
      [face.vertices[0], face.vertices[1], face.vertices[2]]
    }
    let oriented_face = @math.Triangle3d::new(
      face_vertices[0],
      face_vertices[1],
      face_vertices[2],
    )
    let (uv_a, uv_b, uv_c) = mesh3d_triangle_uvs(oriented_face)
    positions.push(face_vertices[0])
    positions.push(face_vertices[1])
    positions.push(face_vertices[2])
    uvs.push(uv_a)
    uvs.push(uv_b)
    uvs.push(uv_c)
  }
  @mesh.Mesh3dGeometry::new(positions, uvs, None)
}

///|
pub fn mesh3d_geometry_uv_sphere(
  radius : Float,
  sectors : Int,
  stacks : Int,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_primitive_uv_sphere(radius, sectors, stacks)
}

///|
pub fn mesh3d_geometry_cylinder(cylinder : @math.Cylinder) -> Mesh3dGeometry {
  mesh3d_geometry_primitive_cylinder(cylinder)
}

///|
pub fn mesh3d_geometry_capsule(capsule : @math.Capsule3d) -> Mesh3dGeometry {
  mesh3d_geometry_primitive_capsule(capsule)
}

///|
pub fn mesh3d_geometry_sphere(radius : Float) -> Mesh3dGeometry {
  mesh3d_geometry_icosphere(radius, 5)
}

///|
pub fn mesh3d_geometry_circle(radius : Float) -> Mesh3dGeometry {
  @mesh.Mesh3dGeometry::circle(radius, 32)
}

///|
pub fn mesh3d_geometry_rectangle(
  width : Float,
  height : Float,
) -> Mesh3dGeometry {
  @mesh.Mesh3dGeometry::rectangle(width, height)
}

///|
pub fn mesh3d_geometry_icosphere(
  radius : Float,
  subdivisions : Int,
) -> Mesh3dGeometry {
  mesh3d_geometry_primitive_icosphere(radius, subdivisions)
}

///|
pub(open) trait IntoPbrMeshAsset {
  into_pbr_mesh_asset(Self) -> @mesh.Mesh
}

///|
pub fn[S : IntoPbrMeshAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_pbr_mesh_asset())
}

///|
pub impl IntoPbrMeshAsset for Mesh3dGeometry with into_pbr_mesh_asset(self) {
  self.to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cuboid with into_pbr_mesh_asset(self) {
  mesh3d_geometry_primitive_cuboid(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Plane3d with into_pbr_mesh_asset(self) {
  let half_size = self.half_size()
  mesh3d_geometry_plane(half_size.x * 2.0F, half_size.y * 2.0F).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Sphere with into_pbr_mesh_asset(self) {
  mesh3d_geometry_sphere(self.diameter() * 0.5F).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cylinder with into_pbr_mesh_asset(self) {
  mesh3d_geometry_cylinder(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Capsule3d with into_pbr_mesh_asset(self) {
  mesh3d_geometry_capsule(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Triangle3d with into_pbr_mesh_asset(self) {
  mesh3d_geometry_triangle(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Tetrahedron with into_pbr_mesh_asset(self) {
  mesh3d_geometry_tetrahedron_shape(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cone with into_pbr_mesh_asset(self) {
  mesh3d_geometry_cone(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.ConicalFrustum with into_pbr_mesh_asset(
  self,
) {
  mesh3d_geometry_conical_frustum(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Torus with into_pbr_mesh_asset(self) {
  mesh3d_geometry_torus(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Segment3d with into_pbr_mesh_asset(self) {
  mesh3d_geometry_segment3d(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Polyline3d with into_pbr_mesh_asset(self) {
  mesh3d_geometry_polyline3d(self).to_mesh()
}
