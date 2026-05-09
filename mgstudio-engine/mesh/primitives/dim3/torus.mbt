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
pub fn torus(major_radius : Float, minor_radius : Float) -> @math.Torus {
  @math.Torus::new(major_radius, minor_radius)
}

///|
pub fn torus_unit() -> @math.Torus {
  torus(1.0, 0.3)
}

///|
pub fn torus_mesh(shape : @math.Torus) -> @mesh.Mesh3dGeometry {
  torus_mesh_with_resolution(shape, 24, 32)
}

///|
pub fn torus_mesh_with_resolution(
  shape : @math.Torus,
  minor_resolution : Int,
  major_resolution : Int,
) -> @mesh.Mesh3dGeometry {
  let minor_resolution = if minor_resolution < 3 { 3 } else { minor_resolution }
  let major_resolution = if major_resolution < 3 { 3 } else { major_resolution }
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let segment_stride = 2.0F * @math.pi() / primitive_f32(major_resolution)
  let side_stride = 2.0F * @math.pi() / primitive_f32(minor_resolution)

  for segment in 0..<=major_resolution {
    let theta = segment_stride * primitive_f32(segment)
    let sin_theta = @math.sin(theta)
    let cos_theta = @math.cos(theta)
    for side in 0..<=minor_resolution {
      let phi = side_stride * primitive_f32(side)
      let sin_phi = @math.sin(phi)
      let cos_phi = @math.cos(phi)
      let radius = shape.major_radius + shape.minor_radius * cos_phi
      let position = @math.Vec3::new(
        cos_theta * radius,
        shape.minor_radius * sin_phi,
        sin_theta * radius,
      )
      let center = @math.Vec3::new(
        shape.major_radius * cos_theta,
        0.0F,
        shape.major_radius * sin_theta,
      )
      positions.push(position)
      normals.push(position.sub(center).normalize())
      uvs.push(
        @math.Vec2::new(
          primitive_f32(segment) / primitive_f32(major_resolution),
          primitive_f32(side) / primitive_f32(minor_resolution),
        ),
      )
    }
  }

  let vertices_per_row = minor_resolution + 1
  for segment in 0..<major_resolution {
    for side in 0..<minor_resolution {
      let lt = side + segment * vertices_per_row
      let rt = side + 1 + segment * vertices_per_row
      let lb = side + (segment + 1) * vertices_per_row
      let rb = side + 1 + (segment + 1) * vertices_per_row
      indices.push(lt)
      indices.push(rt)
      indices.push(lb)
      indices.push(rt)
      indices.push(rb)
      indices.push(lb)
    }
  }

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}
