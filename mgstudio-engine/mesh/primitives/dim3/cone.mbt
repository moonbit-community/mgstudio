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
pub enum ConeAnchor {
  MidPoint
  Tip
  Base
} derive(Eq, Debug)

///|
pub fn cone(radius : Float, height : Float) -> @math.Cone {
  @math.Cone::new(radius, height)
}

///|
pub fn cone_unit() -> @math.Cone {
  cone(0.5, 1.0)
}

///|
pub fn cone_mesh(shape : @math.Cone) -> @mesh.Mesh3dGeometry {
  cone_mesh_with_resolution(shape, 32)
}

///|
pub fn cone_mesh_with_resolution(
  shape : @math.Cone,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  cone_mesh_with_anchor(shape, resolution, MidPoint)
}

///|
pub fn cone_mesh_with_anchor(
  shape : @math.Cone,
  resolution : Int,
  anchor : ConeAnchor,
) -> @mesh.Mesh3dGeometry {
  let resolution = if resolution < 3 { 3 } else { resolution }
  let half_height = shape.height / 2.0F
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  positions.push(@math.Vec3::new(0.0F, half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, 0.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))

  let normal_slope = shape.radius / shape.height
  let normalization_factor = 1.0F /
    @math.sqrt(1.0F + normal_slope * normal_slope)
  let step_theta = 2.0F * @math.pi() / primitive_f32(resolution)

  for segment in 0..<resolution {
    let theta = primitive_f32(segment) * step_theta
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    let normal = @math.Vec3::new(cos, normal_slope, sin).mul_scalar(
      normalization_factor,
    )
    positions.push(
      @math.Vec3::new(shape.radius * cos, -half_height, shape.radius * sin),
    )
    normals.push(normal)
    uvs.push(@math.Vec2::new(0.5F + cos * 0.5F, 0.5F + sin * 0.5F))
  }

  for j in 1..<resolution {
    indices.push(0)
    indices.push(j + 1)
    indices.push(j)
  }
  indices.push(0)
  indices.push(1)
  indices.push(resolution)

  let index_offset = positions.length()
  for i in 0..<resolution {
    let theta = primitive_f32(i) * step_theta
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * shape.radius, -half_height, sin * shape.radius),
    )
    normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
    uvs.push(@math.Vec2::new(0.5F * (cos + 1.0F), 1.0F - 0.5F * (sin + 1.0F)))
  }

  for i in 1..<(resolution - 1) {
    indices.push(index_offset)
    indices.push(index_offset + i)
    indices.push(index_offset + i + 1)
  }

  match anchor {
    Tip =>
      for position in positions {
        position.y = position.y - half_height
      }
    Base =>
      for position in positions {
        position.y = position.y + half_height
      }
    MidPoint => ()
  }

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn cone_mesh_with_tip_anchor(
  shape : @math.Cone,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  cone_mesh_with_anchor(shape, resolution, Tip)
}

///|
pub fn cone_mesh_with_base_anchor(
  shape : @math.Cone,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  cone_mesh_with_anchor(shape, resolution, Base)
}
