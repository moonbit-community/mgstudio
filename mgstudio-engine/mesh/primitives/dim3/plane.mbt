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
pub fn plane3d(normal : @math.Vec3, half_size : @math.Vec2) -> @math.Plane3d {
  @math.Plane3d::new(normal, half_size)
}

///|
pub fn plane3d_unit() -> @math.Plane3d {
  plane3d(@math.Vec3::new(0.0, 1.0, 0.0), @math.Vec2::new(0.5, 0.5))
}

///|
pub(all) struct PlaneMeshBuilder {
  plane : @math.Plane3d
  subdivisions : Int
}

///|
pub fn PlaneMeshBuilder::PlaneMeshBuilder() -> PlaneMeshBuilder {
  { plane: @math.Plane3d::Plane3d(), subdivisions: 0 }
}

///|
pub fn PlaneMeshBuilder::new(
  normal : @math.Dir3,
  size : @math.Vec2,
) -> PlaneMeshBuilder {
  {
    plane: @math.Plane3d::new(normal.as_vec3(), size.mul_scalar(0.5F)),
    subdivisions: 0,
  }
}

///|
pub fn PlaneMeshBuilder::from_size(size : @math.Vec2) -> PlaneMeshBuilder {
  {
    plane: @math.Plane3d::new(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      size.mul_scalar(0.5F),
    ),
    subdivisions: 0,
  }
}

///|
pub fn PlaneMeshBuilder::from_length(length : Float) -> PlaneMeshBuilder {
  PlaneMeshBuilder::from_size(@math.Vec2::new(length, length))
}

///|
pub fn PlaneMeshBuilder::normal(
  self : PlaneMeshBuilder,
  normal : @math.Dir3,
) -> PlaneMeshBuilder {
  {
    plane: @math.Plane3d::new(normal.as_vec3(), self.plane.half_size()),
    subdivisions: self.subdivisions,
  }
}

///|
pub fn PlaneMeshBuilder::size(
  self : PlaneMeshBuilder,
  width : Float,
  height : Float,
) -> PlaneMeshBuilder {
  {
    plane: @math.Plane3d::new(
      self.plane.normal().as_vec3(),
      @math.Vec2::new(width * 0.5F, height * 0.5F),
    ),
    subdivisions: self.subdivisions,
  }
}

///|
pub fn PlaneMeshBuilder::subdivisions(
  self : PlaneMeshBuilder,
  subdivisions : Int,
) -> PlaneMeshBuilder {
  { plane: self.plane, subdivisions }
}

///|
pub fn PlaneMeshBuilder::build(self : PlaneMeshBuilder) -> @mesh.Mesh3dGeometry {
  plane3d_mesh(self.plane, self.subdivisions)
}

///|
pub impl MeshBuilder for PlaneMeshBuilder with build(self) {
  plane3d_mesh(self.plane, self.subdivisions)
}

///|
pub impl Meshable for @math.Plane3d with mesh(self) {
  PlaneMeshBuilder::{ plane: self, subdivisions: 0 }.build()
}

///|
pub fn plane3d_mesh(
  plane : @math.Plane3d,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry {
  let safe_subdivisions = if subdivisions < 0 { 0 } else { subdivisions }
  let z_vertex_count = safe_subdivisions + 2
  let x_vertex_count = safe_subdivisions + 2
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let normal = plane.normal().as_vec3()
  let rotation = @math.Quat::from_rotation_arc(
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    normal,
  )
  let half_size = plane.half_size()
  let size_x = half_size.x * 2.0F
  let size_y = half_size.y * 2.0F

  for z in 0..<z_vertex_count {
    for x in 0..<x_vertex_count {
      let tx = primitive_f32(x) / primitive_f32(x_vertex_count - 1)
      let tz = primitive_f32(z) / primitive_f32(z_vertex_count - 1)
      positions.push(
        rotation.mul_vec3(
          @math.Vec3::new((-0.5F + tx) * size_x, 0.0F, (-0.5F + tz) * size_y),
        ),
      )
      normals.push(normal)
      uvs.push(@math.Vec2::new(tx, tz))
    }
  }

  for z in 0..<(z_vertex_count - 1) {
    for x in 0..<(x_vertex_count - 1) {
      let quad = z * x_vertex_count + x
      indices.push(quad + x_vertex_count + 1)
      indices.push(quad + 1)
      indices.push(quad + x_vertex_count)
      indices.push(quad)
      indices.push(quad + x_vertex_count)
      indices.push(quad + 1)
    }
  }

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn plane3d_mesh_from_size(
  width : Float,
  depth : Float,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry {
  let plane = @math.Plane3d::new(
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec2::new(width * 0.5F, depth * 0.5F),
  )
  plane3d_mesh(plane, subdivisions)
}
