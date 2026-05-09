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
pub fn conical_frustum(
  radius_top : Float,
  radius_bottom : Float,
  height : Float,
) -> @math.ConicalFrustum {
  @math.ConicalFrustum::new(radius_top, radius_bottom, height)
}

///|
pub(all) struct ConicalFrustumMeshBuilder {
  frustum : @math.ConicalFrustum
  resolution : Int
  segments : Int
}

///|
pub fn ConicalFrustumMeshBuilder::default() -> ConicalFrustumMeshBuilder {
  { frustum: @math.ConicalFrustum::default(), resolution: 32, segments: 1 }
}

///|
pub fn ConicalFrustumMeshBuilder::new(
  radius_top : Float,
  radius_bottom : Float,
  height : Float,
  resolution : Int,
) -> ConicalFrustumMeshBuilder {
  {
    frustum: @math.ConicalFrustum::new(radius_top, radius_bottom, height),
    resolution,
    segments: 1,
  }
}

///|
pub fn ConicalFrustumMeshBuilder::from_frustum(
  frustum : @math.ConicalFrustum,
) -> ConicalFrustumMeshBuilder {
  { frustum, resolution: 32, segments: 1 }
}

///|
pub fn ConicalFrustumMeshBuilder::resolution(
  self : ConicalFrustumMeshBuilder,
  resolution : Int,
) -> ConicalFrustumMeshBuilder {
  { frustum: self.frustum, resolution, segments: self.segments }
}

///|
pub fn ConicalFrustumMeshBuilder::segments(
  self : ConicalFrustumMeshBuilder,
  segments : Int,
) -> ConicalFrustumMeshBuilder {
  { frustum: self.frustum, resolution: self.resolution, segments }
}

///|
pub fn ConicalFrustumMeshBuilder::build(
  self : ConicalFrustumMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  conical_frustum_mesh_with_options(
    self.frustum,
    self.resolution,
    self.segments,
  )
}

///|
pub impl MeshBuilder for ConicalFrustumMeshBuilder with build(self) {
  conical_frustum_mesh_with_options(
    self.frustum,
    self.resolution,
    self.segments,
  )
}

///|
pub impl Meshable for @math.ConicalFrustum with mesh(self) {
  ConicalFrustumMeshBuilder::from_frustum(self).build()
}

///|
pub fn conical_frustum_mesh(
  shape : @math.ConicalFrustum,
) -> @mesh.Mesh3dGeometry {
  conical_frustum_mesh_with_options(shape, 32, 1)
}

///|
pub fn conical_frustum_mesh_with_options(
  shape : @math.ConicalFrustum,
  resolution : Int,
  segments : Int,
) -> @mesh.Mesh3dGeometry {
  let half_height = shape.height / 2.0F
  let num_rings = segments + 1
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let step_theta = 2.0F * @math.pi() / primitive_f32(resolution)
  let step_y = shape.height / primitive_f32(segments)
  let step_radius = (shape.radius_top - shape.radius_bottom) /
    primitive_f32(segments)
  let slope = (shape.radius_bottom - shape.radius_top) / shape.height

  for ring in 0..<num_rings {
    let y = -half_height + primitive_f32(ring) * step_y
    let radius = shape.radius_bottom + primitive_f32(ring) * step_radius
    for segment in 0..<=resolution {
      let theta = primitive_f32(segment) * step_theta
      let sin = @math.sin(theta)
      let cos = @math.cos(theta)
      positions.push(@math.Vec3::new(radius * cos, y, radius * sin))
      normals.push(@math.Vec3::new(cos, slope, sin).normalize())
      uvs.push(
        @math.Vec2::new(
          primitive_f32(segment) / primitive_f32(resolution),
          primitive_f32(ring) / primitive_f32(segments),
        ),
      )
    }
  }

  for i in 0..<segments {
    let ring = i * (resolution + 1)
    let next_ring = (i + 1) * (resolution + 1)
    for j in 0..<resolution {
      indices.push(ring + j)
      indices.push(next_ring + j)
      indices.push(ring + j + 1)
      indices.push(next_ring + j)
      indices.push(next_ring + j + 1)
      indices.push(ring + j + 1)
    }
  }

  conical_frustum_build_cap(
    positions,
    normals,
    uvs,
    indices,
    true,
    half_height,
    shape.radius_top,
    resolution,
    step_theta,
  )
  conical_frustum_build_cap(
    positions,
    normals,
    uvs,
    indices,
    false,
    half_height,
    shape.radius_bottom,
    resolution,
    step_theta,
  )

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn conical_frustum_build_cap(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int],
  top : Bool,
  half_height : Float,
  radius : Float,
  resolution : Int,
  step_theta : Float,
) -> Unit {
  let offset = positions.length()
  let y = if top { half_height } else { -half_height }
  let normal_y = if top { 1.0F } else { -1.0F }
  let winding_0 = if top { 1 } else { 0 }
  let winding_1 = if top { 0 } else { 1 }

  for i in 0..<resolution {
    let theta = primitive_f32(i) * step_theta
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(@math.Vec3::new(cos * radius, y, sin * radius))
    normals.push(@math.Vec3::new(0.0F, normal_y, 0.0F))
    uvs.push(@math.Vec2::new(0.5F * (cos + 1.0F), 1.0F - 0.5F * (sin + 1.0F)))
  }

  for i in 1..<(resolution - 1) {
    indices.push(offset)
    indices.push(offset + i + winding_0)
    indices.push(offset + i + winding_1)
  }
}
