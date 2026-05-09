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
pub fn triangle3d(
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
) -> @math.Triangle3d {
  @math.Triangle3d::new(a, b, c)
}

///|
pub fn triangle3d_mesh(shape : @math.Triangle3d) -> @mesh.Mesh3dGeometry {
  if shape.vertices.length() < 3 {
    return @mesh.Mesh3dGeometry::new([], [], None)
  }
  let a = shape.vertices[0]
  let b = shape.vertices[1]
  let c = shape.vertices[2]
  let (uv_a, uv_b, uv_c) = triangle3d_uv_coords(shape)
  let normal = triangle3d_normal_vec(shape)
  primitive_geometry_with_normals(
    [a, b, c],
    [normal, normal, normal],
    [uv_a, uv_b, uv_c],
    Some([0, 1, 2]),
  )
}

///|
fn triangle3d_normal_vec(shape : @math.Triangle3d) -> @math.Vec3 {
  if shape.vertices.length() < 3 {
    return @math.Vec3::zero()
  }
  let a = shape.vertices[0]
  let b = shape.vertices[1]
  let c = shape.vertices[2]
  b.sub(a).cross(c.sub(a)).normalize_or_zero()
}

///|
fn triangle3d_uv_coords(
  shape : @math.Triangle3d,
) -> (@math.Vec2, @math.Vec2, @math.Vec2) {
  if shape.vertices.length() < 3 {
    return (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  }
  let a = shape.vertices[0]
  let b = shape.vertices[1]
  let c = shape.vertices[2]
  let main_length = a.distance(b)
  if main_length <= 0.000001F {
    return (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  }
  let x = b.sub(a).normalize_or_zero()
  let y = c.sub(a)
  let y_proj = x.mul_scalar(y.dot(x))
  let offset = y_proj.dot(x) / main_length
  if offset < 0.0F {
    let total_length = 1.0F - offset
    (
      @math.Vec2::new(offset.abs() / total_length, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    )
  } else if offset > 1.0F {
    (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F / offset, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    )
  } else {
    (
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(offset, 1.0F),
    )
  }
}
