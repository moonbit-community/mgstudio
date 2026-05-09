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
pub enum CylinderAnchor {
  MidPoint
  Top
  Bottom
} derive(Eq, Debug)

///|
pub impl Default for CylinderAnchor with default() {
  MidPoint
}

///|
pub fn cylinder(radius : Float, height : Float) -> @math.Cylinder {
  @math.Cylinder::new(radius, height)
}

///|
pub fn cylinder_unit() -> @math.Cylinder {
  cylinder(0.5, 1.0)
}

///|
pub(all) struct CylinderMeshBuilder {
  cylinder : @math.Cylinder
  resolution : Int
  segments : Int
  caps : Bool
  anchor : CylinderAnchor
}

///|
pub fn CylinderMeshBuilder::default() -> CylinderMeshBuilder {
  {
    cylinder: @math.Cylinder::default(),
    resolution: 32,
    segments: 1,
    caps: true,
    anchor: CylinderAnchor::default(),
  }
}

///|
pub fn CylinderMeshBuilder::new(
  radius : Float,
  height : Float,
  resolution : Int,
) -> CylinderMeshBuilder {
  {
    cylinder: @math.Cylinder::new(radius, height),
    resolution,
    segments: 1,
    caps: true,
    anchor: CylinderAnchor::default(),
  }
}

///|
pub fn CylinderMeshBuilder::from_cylinder(
  cylinder : @math.Cylinder,
) -> CylinderMeshBuilder {
  {
    cylinder,
    resolution: 32,
    segments: 1,
    caps: true,
    anchor: CylinderAnchor::default(),
  }
}

///|
pub fn CylinderMeshBuilder::resolution(
  self : CylinderMeshBuilder,
  resolution : Int,
) -> CylinderMeshBuilder {
  {
    cylinder: self.cylinder,
    resolution,
    segments: self.segments,
    caps: self.caps,
    anchor: self.anchor,
  }
}

///|
pub fn CylinderMeshBuilder::segments(
  self : CylinderMeshBuilder,
  segments : Int,
) -> CylinderMeshBuilder {
  {
    cylinder: self.cylinder,
    resolution: self.resolution,
    segments,
    caps: self.caps,
    anchor: self.anchor,
  }
}

///|
pub fn CylinderMeshBuilder::without_caps(
  self : CylinderMeshBuilder,
) -> CylinderMeshBuilder {
  {
    cylinder: self.cylinder,
    resolution: self.resolution,
    segments: self.segments,
    caps: false,
    anchor: self.anchor,
  }
}

///|
pub fn CylinderMeshBuilder::anchor(
  self : CylinderMeshBuilder,
  anchor : CylinderAnchor,
) -> CylinderMeshBuilder {
  {
    cylinder: self.cylinder,
    resolution: self.resolution,
    segments: self.segments,
    caps: self.caps,
    anchor,
  }
}

///|
pub fn CylinderMeshBuilder::build(
  self : CylinderMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  cylinder_mesh_with_anchor(
    self.cylinder,
    self.resolution,
    self.segments,
    self.caps,
    self.anchor,
  )
}

///|
pub impl MeshBuilder for CylinderMeshBuilder with build(self) {
  cylinder_mesh_with_anchor(
    self.cylinder,
    self.resolution,
    self.segments,
    self.caps,
    self.anchor,
  )
}

///|
pub impl Meshable for @math.Cylinder with mesh(self) {
  CylinderMeshBuilder::from_cylinder(self).build()
}

///|
pub fn cylinder_mesh(shape : @math.Cylinder) -> @mesh.Mesh3dGeometry {
  cylinder_mesh_with_options(shape, 32, 1, true)
}

///|
pub fn cylinder_mesh_with_options(
  shape : @math.Cylinder,
  resolution : Int,
  segments : Int,
  caps : Bool,
) -> @mesh.Mesh3dGeometry {
  cylinder_mesh_with_anchor(shape, resolution, segments, caps, MidPoint)
}

///|
pub fn cylinder_mesh_with_anchor(
  shape : @math.Cylinder,
  resolution : Int,
  segments : Int,
  caps : Bool,
  anchor : CylinderAnchor,
) -> @mesh.Mesh3dGeometry {
  let num_rings = segments + 1
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let radius = shape.radius
  let half_height = shape.half_height
  let step_theta = 2.0F * @math.pi() / primitive_f32(resolution)
  let step_y = 2.0F * half_height / primitive_f32(segments)

  for ring in 0..<num_rings {
    let y = -half_height + primitive_f32(ring) * step_y
    for segment in 0..<=resolution {
      let theta = primitive_f32(segment) * step_theta
      let sin = @math.sin(theta)
      let cos = @math.cos(theta)
      positions.push(@math.Vec3::new(radius * cos, y, radius * sin))
      normals.push(@math.Vec3::new(cos, 0.0F, sin))
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

  if caps {
    cylinder_build_cap(
      positions, normals, uvs, indices, true, half_height, radius, resolution, step_theta,
    )
    cylinder_build_cap(
      positions, normals, uvs, indices, false, half_height, radius, resolution, step_theta,
    )
  }

  match anchor {
    Top =>
      for position in positions {
        position.y = position.y - shape.half_height
      }
    Bottom =>
      for position in positions {
        position.y = position.y + shape.half_height
      }
    MidPoint => ()
  }

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn cylinder_mesh_with_top_anchor(
  shape : @math.Cylinder,
  resolution : Int,
  segments : Int,
  caps : Bool,
) -> @mesh.Mesh3dGeometry {
  cylinder_mesh_with_anchor(shape, resolution, segments, caps, Top)
}

///|
pub fn cylinder_mesh_with_bottom_anchor(
  shape : @math.Cylinder,
  resolution : Int,
  segments : Int,
  caps : Bool,
) -> @mesh.Mesh3dGeometry {
  cylinder_mesh_with_anchor(shape, resolution, segments, caps, Bottom)
}

///|
fn cylinder_build_cap(
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
