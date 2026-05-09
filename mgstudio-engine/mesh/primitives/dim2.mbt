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
fn primitive2d_f32(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn primitive2d_geometry_with_normals(
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
fn primitive2d_normal_z(count : Int, z : Float) -> Array[@math.Vec3] {
  let normals : Array[@math.Vec3] = []
  for _ in 0..<count {
    normals.push(@math.Vec3::new(0.0F, 0.0F, z))
  }
  normals
}

///|
pub fn circle(radius : Float) -> @math.Circle {
  @math.Circle::new(radius)
}

///|
pub fn circle_mesh(radius : Float, segments : Int) -> @mesh.Mesh3dGeometry {
  ellipse_mesh(@math.Ellipse::new(radius, radius).with_vertices(segments))
}

///|
pub fn circle_line_strip_mesh(
  radius : Float,
  segments : Int,
) -> @mesh.Mesh3dGeometry {
  let resolution = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(@math.Vec3::new(cos * radius, sin * radius, 0.0F))
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
    indices.push(i)
    indices.push((i + 1) % resolution)
  }
  @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    Some(indices),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
pub fn rectangle(width : Float, height : Float) -> @math.Rectangle {
  @math.Rectangle::new(width, height)
}

///|
pub fn rectangle_mesh(width : Float, height : Float) -> @mesh.Mesh3dGeometry {
  rectangle_shape_mesh(@math.Rectangle::new(width, height))
}

///|
fn rectangle_shape_mesh(shape : @math.Rectangle) -> @mesh.Mesh3dGeometry {
  let hw = shape.half_size.x
  let hh = shape.half_size.y
  primitive2d_geometry_with_normals(
    [
      @math.Vec3::new(hw, hh, 0.0F),
      @math.Vec3::new(-hw, hh, 0.0F),
      @math.Vec3::new(-hw, -hh, 0.0F),
      @math.Vec3::new(hw, -hh, 0.0F),
    ],
    primitive2d_normal_z(4, 1.0F),
    [
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ],
    Some([0, 1, 2, 0, 2, 3]),
  )
}

///|
fn ellipse_mesh(shape : @math.Ellipse) -> @mesh.Mesh3dGeometry {
  let resolution = if shape.vertices < 3 { 3 } else { shape.vertices }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * shape.half_size.x, sin * shape.half_size.y, 0.0F),
    )
    uvs.push(@math.Vec2::new(0.5F * (cos + 1.0F), 1.0F - 0.5F * (sin + 1.0F)))
  }
  for i in 1..<(resolution - 1) {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(resolution, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
fn annulus_mesh(shape : @math.Annulus) -> @mesh.Mesh3dGeometry {
  let resolution = if shape.vertices < 3 { 3 } else { shape.vertices }
  let vertex_count = (resolution + 1) * 2
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<=resolution {
    let theta = start_angle + primitive2d_f32(i % resolution) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * shape.inner_radius, sin * shape.inner_radius, 0.0F),
    )
    positions.push(
      @math.Vec3::new(cos * shape.outer_radius, sin * shape.outer_radius, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(0.0F, primitive2d_f32(i) / primitive2d_f32(resolution)),
    )
    uvs.push(
      @math.Vec2::new(1.0F, primitive2d_f32(i) / primitive2d_f32(resolution)),
    )
  }
  for i in 0..<resolution {
    let inner_vertex = 2 * i
    let outer_vertex = 2 * i + 1
    let next_inner = inner_vertex + 2
    let next_outer = outer_vertex + 2
    indices.push(inner_vertex)
    indices.push(outer_vertex)
    indices.push(next_outer)
    indices.push(next_outer)
    indices.push(next_inner)
    indices.push(inner_vertex)
  }
  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(vertex_count, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
fn regular_polygon_mesh(shape : @math.RegularPolygon) -> @mesh.Mesh3dGeometry {
  ellipse_mesh(
    @math.Ellipse::new(shape.radius, shape.radius).with_vertices(shape.sides),
  )
}

///|
fn triangle2d_signed_area(shape : @math.Triangle2d) -> Float {
  let ab = shape.b.sub(shape.a)
  let ac = shape.c.sub(shape.a)
  ab.perp_dot(ac) * 0.5F
}

///|
fn triangle2d_mesh(shape : @math.Triangle2d) -> @mesh.Mesh3dGeometry {
  let vertices_3d = [
    @math.Vec3::new(shape.a.x, shape.a.y, 0.0F),
    @math.Vec3::new(shape.b.x, shape.b.y, 0.0F),
    @math.Vec3::new(shape.c.x, shape.c.y, 0.0F),
  ]
  let uvs = triangle2d_uvs(shape)
  let indices = if triangle2d_signed_area(shape) >= 0.0F {
    [0, 1, 2]
  } else {
    [2, 1, 0]
  }
  primitive2d_geometry_with_normals(
    vertices_3d,
    primitive2d_normal_z(3, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
fn triangle2d_uvs(shape : @math.Triangle2d) -> Array[@math.Vec2] {
  let a = @math.Vec3::new(shape.a.x, shape.a.y, 0.0F)
  let b = @math.Vec3::new(shape.b.x, shape.b.y, 0.0F)
  let c = @math.Vec3::new(shape.c.x, shape.c.y, 0.0F)
  let main_length = a.distance(b)
  if main_length <= 0.000001F {
    return [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ]
  }
  let x = b.sub(a).normalize_or_zero()
  let y = c.sub(a)
  let y_proj = x.mul_scalar(y.dot(x))
  let offset = y_proj.dot(x) / main_length
  if offset < 0.0F {
    let total_length = 1.0F - offset
    [
      @math.Vec2::new(offset.abs() / total_length, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ]
  } else if offset > 1.0F {
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F / offset, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ]
  } else {
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(offset, 1.0F),
    ]
  }
}

///|
fn capsule2d_mesh_with_resolution(
  shape : @math.Capsule2d,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  let resolution = if resolution < 2 { 2 } else { resolution }
  let vertex_count = 2 * resolution
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let radius = shape.radius
  let step = 2.0F * @math.pi() / primitive2d_f32(vertex_count)
  let start_angle = if vertex_count % 2 == 0 { step / 2.0F } else { 0.0F }
  let radius_frac = shape.radius / (shape.half_length + shape.radius)

  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * radius, sin * radius + shape.half_length, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(
        0.5F * (cos + 1.0F),
        radius_frac * (1.0F - 0.5F * (sin + 1.0F)),
      ),
    )
  }
  for i in 1..<(resolution - 1) {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  indices.push(0)
  indices.push(resolution - 1)
  indices.push(resolution)

  for i in resolution..<vertex_count {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * radius, sin * radius - shape.half_length, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(
        0.5F * (cos + 1.0F),
        1.0F - radius_frac * 0.5F * (sin + 1.0F),
      ),
    )
  }
  for i in 1..<(resolution - 1) {
    indices.push(resolution)
    indices.push(resolution + i)
    indices.push(resolution + i + 1)
  }
  indices.push(resolution)
  indices.push(vertex_count - 1)
  indices.push(0)

  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(vertex_count, 1.0F),
    uvs,
    Some(indices),
  )
}
