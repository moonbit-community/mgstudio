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
priv struct IcoEdge {
  points : Array[Int]
  mut done : Bool
}

///|
fn IcoEdge::new() -> IcoEdge {
  { points: [], done: true }
}

///|
priv enum IcoTriangleContents {
  IcoNone
  IcoOne(Int)
  IcoThree(Int, Int, Int)
  IcoSix(Int, Int, Int, Int, Int, Int)
  IcoMore(Int, Int, Int, Array[Int], Int, IcoTriangleContents)
}

///|
priv struct IcoTriangle {
  a : Int
  b : Int
  c : Int
  ab_edge : Int
  bc_edge : Int
  ca_edge : Int
  mut ab_forward : Bool
  mut bc_forward : Bool
  mut ca_forward : Bool
  mut contents : IcoTriangleContents
}

///|
fn IcoTriangle::new(
  a : Int,
  b : Int,
  c : Int,
  ab_edge : Int,
  bc_edge : Int,
  ca_edge : Int,
) -> IcoTriangle {
  {
    a,
    b,
    c,
    ab_edge,
    bc_edge,
    ca_edge,
    ab_forward: false,
    bc_forward: false,
    ca_forward: false,
    contents: IcoNone,
  }
}

///|
priv struct IcoSlice {
  values : Array[Int]
  start : Int
  length : Int
  forward : Bool
}

///|
fn IcoSlice::full(values : Array[Int], forward : Bool) -> IcoSlice {
  { values, start: 0, length: values.length(), forward }
}

///|
fn IcoSlice::segment(
  values : Array[Int],
  start : Int,
  length : Int,
) -> IcoSlice {
  { values, start, length, forward: true }
}

///|
fn IcoSlice::get(self : IcoSlice, index : Int) -> Int {
  if self.forward {
    self.values[self.start + index]
  } else {
    self.values[self.start + self.length - 1 - index]
  }
}

///|
fn ico_initial_points() -> Array[@math.Vec3] {
  [
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(0.8944271909999159F, 0.4472135954999579F, 0.0F),
    @math.Vec3::new(
      0.2763932022500211F, 0.4472135954999579F, 0.8506508083520399F,
    ),
    @math.Vec3::new(
      -0.7236067977499788F,
      0.4472135954999579F,
      0.5257311121191337F,
    ),
    @math.Vec3::new(
      -0.7236067977499790F,
      0.4472135954999579F,
      -0.5257311121191335F,
    ),
    @math.Vec3::new(
      0.27639320225002084F,
      0.4472135954999579F,
      -0.85065080835204F,
    ),
    @math.Vec3::new(
      0.7236067977499787F,
      -0.4472135954999579F,
      -0.5257311121191339F,
    ),
    @math.Vec3::new(
      0.7236067977499790F,
      -0.4472135954999579F,
      0.5257311121191334F,
    ),
    @math.Vec3::new(
      -0.27639320225002073F,
      -0.4472135954999579F,
      0.85065080835204F,
    ),
    @math.Vec3::new(-0.8944271909999159F, -0.4472135954999579F, 0.0F),
    @math.Vec3::new(
      -0.2763932022500214F,
      -0.4472135954999579F,
      -0.8506508083520398F,
    ),
    @math.Vec3::new(0.0F, -1.0F, 0.0F),
  ]
}

///|
fn ico_base_triangles() -> Array[IcoTriangle] {
  [
    IcoTriangle::new(0, 2, 1, 0, 5, 4),
    IcoTriangle::new(0, 3, 2, 1, 6, 0),
    IcoTriangle::new(0, 4, 3, 2, 7, 1),
    IcoTriangle::new(0, 5, 4, 3, 8, 2),
    IcoTriangle::new(0, 1, 5, 4, 9, 3),
    IcoTriangle::new(5, 1, 6, 9, 10, 15),
    IcoTriangle::new(1, 2, 7, 5, 11, 16),
    IcoTriangle::new(2, 3, 8, 6, 12, 17),
    IcoTriangle::new(3, 4, 9, 7, 13, 18),
    IcoTriangle::new(4, 5, 10, 8, 14, 19),
    IcoTriangle::new(5, 6, 10, 15, 20, 14),
    IcoTriangle::new(1, 7, 6, 16, 21, 10),
    IcoTriangle::new(2, 8, 7, 17, 22, 11),
    IcoTriangle::new(3, 9, 8, 18, 23, 12),
    IcoTriangle::new(4, 10, 9, 19, 24, 13),
    IcoTriangle::new(10, 6, 11, 20, 26, 25),
    IcoTriangle::new(6, 7, 11, 21, 27, 26),
    IcoTriangle::new(7, 8, 11, 22, 28, 27),
    IcoTriangle::new(8, 9, 11, 23, 29, 28),
    IcoTriangle::new(9, 10, 11, 24, 25, 29),
  ]
}

///|
fn ico_slerp(a : @math.Vec3, b : @math.Vec3, percent : Float) -> @math.Vec3 {
  let angle = @math.acos(a.dot(b))
  let sin = 1.0F / @math.sin(angle)
  a
  .mul_scalar(@math.sin((1.0F - percent) * angle) * sin)
  .add(b.mul_scalar(@math.sin(percent * angle) * sin))
}

///|
fn ico_slerp_half(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  a.add(b).mul_scalar(1.0F / @math.sqrt(2.0F * (1.0F + a.dot(b))))
}

///|
fn ico_slerp_multiple(
  a : @math.Vec3,
  b : @math.Vec3,
  indices : IcoSlice,
  points : Array[@math.Vec3],
) -> Unit {
  let denominator = primitive_f32(indices.length + 1)
  for percent_index in 0..<indices.length {
    let percent = primitive_f32(percent_index + 1) / denominator
    let point_index = indices.get(percent_index)
    points[point_index] = ico_slerp(a, b, percent)
  }
}

///|
fn ico_contents_subdivide(
  contents : IcoTriangleContents,
  next_point : Int,
) -> (IcoTriangleContents, Int) {
  match contents {
    IcoNone => (IcoOne(next_point), next_point + 1)
    IcoOne(a) => (IcoThree(a, next_point, next_point + 1), next_point + 2)
    IcoThree(a, b, c) =>
      (
        IcoSix(a, b, c, next_point, next_point + 1, next_point + 2),
        next_point + 3,
      )
    IcoSix(a, b, c, ab, bc, ca) => {
      let sides : Array[Int] = [ab, bc, ca]
      ico_contents_subdivide(IcoMore(a, b, c, sides, 1, IcoNone), next_point)
    }
    IcoMore(a, b, c, sides, side_length, inner) => {
      sides.push(next_point)
      sides.push(next_point + 1)
      sides.push(next_point + 2)
      let result = ico_contents_subdivide(inner, next_point + 3)
      (IcoMore(a, b, c, sides, side_length + 1, result.0), result.1)
    }
  }
}

///|
fn ico_contents_idx_ab(contents : IcoTriangleContents, index : Int) -> Int {
  match contents {
    IcoOne(a) => a
    IcoThree(a, b, _) => if index == 0 { a } else { b }
    IcoSix(a, b, _, ab, _, _) =>
      if index == 0 {
        a
      } else if index == 1 {
        ab
      } else {
        b
      }
    IcoMore(a, b, _, sides, side_length, _) =>
      if index == 0 {
        a
      } else if index == side_length + 1 {
        b
      } else {
        sides[index - 1]
      }
    IcoNone => abort("invalid icosphere triangle contents")
  }
}

///|
fn ico_contents_idx_bc(contents : IcoTriangleContents, index : Int) -> Int {
  match contents {
    IcoOne(a) => a
    IcoThree(_, b, c) => if index == 0 { b } else { c }
    IcoSix(_, b, c, _, bc, _) =>
      if index == 0 {
        b
      } else if index == 1 {
        bc
      } else {
        c
      }
    IcoMore(_, b, c, sides, side_length, _) =>
      if index == 0 {
        b
      } else if index == side_length + 1 {
        c
      } else {
        sides[side_length + index - 1]
      }
    IcoNone => abort("invalid icosphere triangle contents")
  }
}

///|
fn ico_contents_idx_ca(contents : IcoTriangleContents, index : Int) -> Int {
  match contents {
    IcoOne(a) => a
    IcoThree(a, _, c) => if index == 0 { c } else { a }
    IcoSix(a, _, c, _, _, ca) =>
      if index == 0 {
        c
      } else if index == 1 {
        ca
      } else {
        a
      }
    IcoMore(a, _, c, sides, side_length, _) =>
      if index == 0 {
        c
      } else if index == side_length + 1 {
        a
      } else {
        sides[side_length * 2 + index - 1]
      }
    IcoNone => abort("invalid icosphere triangle contents")
  }
}

///|
fn ico_calculate_contents(
  contents : IcoTriangleContents,
  ab : IcoSlice,
  bc : IcoSlice,
  ca : IcoSlice,
  points : Array[@math.Vec3],
) -> Unit {
  match contents {
    IcoNone => ()
    IcoOne(index) => {
      let p1 = points[ab.get(0)]
      let p2 = points[bc.get(1)]
      points[index] = ico_slerp_half(p1, p2)
    }
    IcoThree(a, b, c) => {
      let ab_mid = points[ab.get(1)]
      let bc_mid = points[bc.get(1)]
      let ca_mid = points[ca.get(1)]
      points[a] = ico_slerp_half(ab_mid, ca_mid)
      points[b] = ico_slerp_half(bc_mid, ab_mid)
      points[c] = ico_slerp_half(ca_mid, bc_mid)
    }
    IcoSix(a, b, c, ab_index, bc_index, ca_index) => {
      let aba = points[ab.get(1)]
      let abb = points[ab.get(2)]
      let bcb = points[bc.get(1)]
      let bcc = points[bc.get(2)]
      let cac = points[ca.get(1)]
      let caa = points[ca.get(2)]
      let a_point = ico_slerp_half(aba, caa)
      let b_point = ico_slerp_half(abb, bcb)
      let c_point = ico_slerp_half(bcc, cac)
      points[a] = a_point
      points[b] = b_point
      points[c] = c_point
      points[ab_index] = ico_slerp_half(a_point, b_point)
      points[bc_index] = ico_slerp_half(b_point, c_point)
      points[ca_index] = ico_slerp_half(c_point, a_point)
    }
    IcoMore(a, b, c, sides, side_length, inner) => {
      let outer_len = ab.length
      let aba = points[ab.get(1)]
      let abb = points[ab.get(outer_len - 2)]
      let bcb = points[bc.get(1)]
      let bcc = points[bc.get(outer_len - 2)]
      let cac = points[ca.get(1)]
      let caa = points[ca.get(outer_len - 2)]
      let a_point = ico_slerp_half(aba, caa)
      let b_point = ico_slerp_half(abb, bcb)
      let c_point = ico_slerp_half(bcc, cac)
      points[a] = a_point
      points[b] = b_point
      points[c] = c_point
      let ab_slice = IcoSlice::segment(sides, 0, side_length)
      let bc_slice = IcoSlice::segment(sides, side_length, side_length)
      let ca_slice = IcoSlice::segment(sides, side_length * 2, side_length)
      ico_slerp_multiple(a_point, b_point, ab_slice, points)
      ico_slerp_multiple(b_point, c_point, bc_slice, points)
      ico_slerp_multiple(c_point, a_point, ca_slice, points)
      ico_calculate_contents(inner, ab_slice, bc_slice, ca_slice, points)
    }
  }
}

///|
fn ico_add_indices(buffer : Array[Int], a : Int, b : Int, c : Int) -> Unit {
  buffer.push(a)
  buffer.push(b)
  buffer.push(c)
}

///|
fn ico_add_indices_triangular(
  a : Int,
  b : Int,
  c : Int,
  ab : IcoSlice,
  bc : IcoSlice,
  ca : IcoSlice,
  contents : IcoTriangleContents,
  buffer : Array[Int],
) -> Unit {
  let subdivisions = ab.length
  if subdivisions == 0 {
    ico_add_indices(buffer, a, b, c)
    return
  }
  if subdivisions == 1 {
    ico_add_indices(buffer, a, ab.get(0), ca.get(0))
    ico_add_indices(buffer, b, bc.get(0), ab.get(0))
    ico_add_indices(buffer, c, ca.get(0), bc.get(0))
    ico_add_indices(buffer, ab.get(0), bc.get(0), ca.get(0))
    return
  }
  if subdivisions == 2 {
    let inner = ico_contents_idx_ab(contents, 0)
    ico_add_indices(buffer, a, ab.get(0), ca.get(1))
    ico_add_indices(buffer, b, bc.get(0), ab.get(1))
    ico_add_indices(buffer, c, ca.get(0), bc.get(1))
    ico_add_indices(buffer, ab.get(1), inner, ab.get(0))
    ico_add_indices(buffer, bc.get(1), inner, bc.get(0))
    ico_add_indices(buffer, ca.get(1), inner, ca.get(0))
    ico_add_indices(buffer, ab.get(0), inner, ca.get(1))
    ico_add_indices(buffer, bc.get(0), inner, ab.get(1))
    ico_add_indices(buffer, ca.get(0), inner, bc.get(1))
    return
  }

  let last_idx = subdivisions - 1
  ico_add_indices(buffer, a, ab.get(0), ca.get(last_idx))
  ico_add_indices(buffer, b, bc.get(0), ab.get(last_idx))
  ico_add_indices(buffer, c, ca.get(0), bc.get(last_idx))
  ico_add_indices(
    buffer,
    ab.get(0),
    ico_contents_idx_ab(contents, 0),
    ca.get(last_idx),
  )
  ico_add_indices(
    buffer,
    bc.get(0),
    ico_contents_idx_bc(contents, 0),
    ab.get(last_idx),
  )
  ico_add_indices(
    buffer,
    ca.get(0),
    ico_contents_idx_ca(contents, 0),
    bc.get(last_idx),
  )

  for index in 0..<(last_idx - 1) {
    ico_add_indices(
      buffer,
      ab.get(index),
      ab.get(index + 1),
      ico_contents_idx_ab(contents, index),
    )
    ico_add_indices(
      buffer,
      ab.get(index + 1),
      ico_contents_idx_ab(contents, index + 1),
      ico_contents_idx_ab(contents, index),
    )
    ico_add_indices(
      buffer,
      bc.get(index),
      bc.get(index + 1),
      ico_contents_idx_bc(contents, index),
    )
    ico_add_indices(
      buffer,
      bc.get(index + 1),
      ico_contents_idx_bc(contents, index + 1),
      ico_contents_idx_bc(contents, index),
    )
    ico_add_indices(
      buffer,
      ca.get(index),
      ca.get(index + 1),
      ico_contents_idx_ca(contents, index),
    )
    ico_add_indices(
      buffer,
      ca.get(index + 1),
      ico_contents_idx_ca(contents, index + 1),
      ico_contents_idx_ca(contents, index),
    )
  }

  ico_add_indices(
    buffer,
    ab.get(last_idx),
    ico_contents_idx_ab(contents, last_idx - 1),
    ab.get(last_idx - 1),
  )
  ico_add_indices(
    buffer,
    bc.get(last_idx),
    ico_contents_idx_bc(contents, last_idx - 1),
    bc.get(last_idx - 1),
  )
  ico_add_indices(
    buffer,
    ca.get(last_idx),
    ico_contents_idx_ca(contents, last_idx - 1),
    ca.get(last_idx - 1),
  )
}

///|
fn ico_contents_add_indices(
  contents : IcoTriangleContents,
  buffer : Array[Int],
) -> Unit {
  match contents {
    IcoNone | IcoOne(_) => ()
    IcoThree(a, b, c) => ico_add_indices(buffer, a, b, c)
    IcoSix(a, b, c, ab, bc, ca) => {
      ico_add_indices(buffer, a, ab, ca)
      ico_add_indices(buffer, ab, b, bc)
      ico_add_indices(buffer, bc, c, ca)
      ico_add_indices(buffer, ab, bc, ca)
    }
    IcoMore(a, b, c, sides, side_length, inner) => {
      let ab = IcoSlice::segment(sides, 0, side_length)
      let bc = IcoSlice::segment(sides, side_length, side_length)
      let ca = IcoSlice::segment(sides, side_length * 2, side_length)
      ico_add_indices_triangular(a, b, c, ab, bc, ca, inner, buffer)
      ico_contents_add_indices(inner, buffer)
    }
  }
}

///|
fn ico_calculate_edge(
  p1 : Int,
  p2 : Int,
  edge : IcoEdge,
  points : Array[@math.Vec3],
) -> Bool {
  if !edge.done {
    ico_slerp_multiple(
      points[p1],
      points[p2],
      IcoSlice::full(edge.points, true),
      points,
    )
    edge.done = true
    true
  } else {
    false
  }
}

///|
fn ico_triangle_calculate(
  triangle : IcoTriangle,
  edges : Array[IcoEdge],
  points : Array[@math.Vec3],
) -> Unit {
  let ab_edge = edges[triangle.ab_edge]
  let bc_edge = edges[triangle.bc_edge]
  let ca_edge = edges[triangle.ca_edge]
  triangle.ab_forward = ico_calculate_edge(
    triangle.a,
    triangle.b,
    ab_edge,
    points,
  )
  triangle.bc_forward = ico_calculate_edge(
    triangle.b,
    triangle.c,
    bc_edge,
    points,
  )
  triangle.ca_forward = ico_calculate_edge(
    triangle.c,
    triangle.a,
    ca_edge,
    points,
  )
  if ab_edge.points.length() > 1 {
    ico_calculate_contents(
      triangle.contents,
      IcoSlice::full(ab_edge.points, triangle.ab_forward),
      IcoSlice::full(bc_edge.points, triangle.bc_forward),
      IcoSlice::full(ca_edge.points, triangle.ca_forward),
      points,
    )
  }
}

///|
fn ico_triangle_add_indices(
  triangle : IcoTriangle,
  edges : Array[IcoEdge],
  indices : Array[Int],
) -> Unit {
  let ab_edge = edges[triangle.ab_edge]
  let bc_edge = edges[triangle.bc_edge]
  let ca_edge = edges[triangle.ca_edge]
  ico_add_indices_triangular(
    triangle.a,
    triangle.b,
    triangle.c,
    IcoSlice::full(ab_edge.points, triangle.ab_forward),
    IcoSlice::full(bc_edge.points, triangle.bc_forward),
    IcoSlice::full(ca_edge.points, triangle.ca_forward),
    triangle.contents,
    indices,
  )
  ico_contents_add_indices(triangle.contents, indices)
}

///|
fn ico_uv(unit : @math.Vec3) -> @math.Vec2 {
  let inclination = @math.acos(unit.y)
  let azimuth = @math.atan2(unit.z, unit.x)
  @math.Vec2::new(
    0.5F - azimuth / (2.0F * @math.pi()),
    inclination / @math.pi(),
  )
}

///|
pub fn sphere(radius : Float) -> @math.Sphere {
  @math.Sphere::new(radius)
}

///|
pub enum SphereKind {
  Ico(Int)
  Uv(Int, Int)
} derive(Eq, Debug)

///|
pub(all) suberror IcosphereError {
  TooManyVertices(Int, Int)
}

///|
pub fn SphereKind::default() -> SphereKind {
  Ico(5)
}

///|
pub fn SphereKind::ico(subdivisions : Int) -> SphereKind {
  Ico(subdivisions)
}

///|
pub fn SphereKind::uv(sectors : Int, stacks : Int) -> SphereKind {
  Uv(sectors, stacks)
}

///|
pub(all) struct SphereMeshBuilder {
  sphere : @math.Sphere
  kind : SphereKind
}

///|
pub fn SphereMeshBuilder::SphereMeshBuilder() -> SphereMeshBuilder {
  { sphere: Sphere(), kind: SphereKind::default() }
}

///|
pub fn SphereMeshBuilder::new(
  radius : Float,
  kind : SphereKind,
) -> SphereMeshBuilder {
  { sphere: { radius, }, kind }
}

///|
pub fn SphereMeshBuilder::from_sphere(
  sphere : @math.Sphere,
) -> SphereMeshBuilder {
  { sphere, kind: SphereKind::default() }
}

///|
pub fn SphereMeshBuilder::kind(
  self : SphereMeshBuilder,
  kind : SphereKind,
) -> SphereMeshBuilder {
  { sphere: self.sphere, kind }
}

///|
pub fn SphereMeshBuilder::ico(
  self : SphereMeshBuilder,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry raise IcosphereError {
  if subdivisions >= 80 {
    let temp = subdivisions + 1
    let number_of_resulting_points = temp * temp * 10 + 2
    raise TooManyVertices(subdivisions, number_of_resulting_points)
  } else {
    icosphere_mesh(self.sphere.radius, subdivisions)
  }
}

///|
pub fn SphereMeshBuilder::uv(
  self : SphereMeshBuilder,
  sectors : Int,
  stacks : Int,
) -> @mesh.Mesh3dGeometry {
  uv_sphere_mesh(self.sphere.radius, sectors, stacks)
}

///|
pub fn SphereMeshBuilder::build(
  self : SphereMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  sphere_mesh_with_kind(self.sphere.radius, self.kind)
}

///|
pub impl MeshBuilder for SphereMeshBuilder with fn build(self) {
  sphere_mesh_with_kind(self.sphere.radius, self.kind)
}

///|
pub impl Meshable for @math.Sphere with fn mesh(self) {
  SphereMeshBuilder::from_sphere(self).build()
}

///|
pub fn sphere_mesh(radius : Float, subdivisions : Int) -> @mesh.Mesh3dGeometry {
  icosphere_mesh(radius, subdivisions)
}

///|
pub fn sphere_mesh_with_kind(
  radius : Float,
  kind : SphereKind,
) -> @mesh.Mesh3dGeometry {
  match kind {
    Ico(subdivisions) =>
      SphereMeshBuilder::new(radius, kind).ico(subdivisions) catch {
        TooManyVertices(_, _) =>
          abort("icosphere subdivisions produce too many vertices")
      }
    Uv(sectors, stacks) => uv_sphere_mesh(radius, sectors, stacks)
  }
}

///|
pub fn icosphere_mesh(
  radius : Float,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry {
  if subdivisions >= 80 {
    let temp = subdivisions + 1
    let number_of_resulting_points = temp * temp * 10 + 2
    abort(
      "Cannot create an icosphere of \{subdivisions} subdivisions due to there being too many vertices being generated: \{number_of_resulting_points}.",
    )
  }
  let subdivisions = if subdivisions < 0 { 0 } else { subdivisions }
  let unit_points = ico_initial_points()
  let edges : Array[IcoEdge] = []
  for _ in 0..<30 {
    edges.push(IcoEdge::new())
  }
  let triangles = ico_base_triangles()
  let mut new_points = unit_points.length()
  for edge in edges {
    for _ in 0..<subdivisions {
      edge.points.push(new_points)
      new_points = new_points + 1
    }
    edge.done = false
  }
  for triangle in triangles {
    for level in 0..<subdivisions {
      if level >= 1 {
        let result = ico_contents_subdivide(triangle.contents, new_points)
        triangle.contents = result.0
        new_points = result.1
      }
    }
  }
  while unit_points.length() < new_points {
    unit_points.push(@math.Vec3::new(0.0F, 0.0F, 0.0F))
  }
  for triangle in triangles {
    ico_triangle_calculate(triangle, edges, unit_points)
  }

  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for point in unit_points {
    positions.push(point.mul_scalar(radius))
    normals.push(point)
    uvs.push(ico_uv(point))
  }
  let indices : Array[Int] = []
  for triangle in triangles {
    ico_triangle_add_indices(triangle, edges, indices)
  }
  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn uv_sphere_mesh(
  radius : Float,
  sectors : Int,
  stacks : Int,
) -> @mesh.Mesh3dGeometry {
  let sectors = if sectors < 3 { 3 } else { sectors }
  let stacks = if stacks < 2 { 2 } else { stacks }
  let sectors_f32 = primitive_f32(sectors)
  let stacks_f32 = primitive_f32(stacks)
  let length_inv = 1.0F / radius
  let sector_step = 2.0F * @math.pi() / sectors_f32
  let stack_step = @math.pi() / stacks_f32
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  for i in 0..<=stacks {
    let stack_angle = @math.pi() / 2.0F - primitive_f32(i) * stack_step
    let xy = radius * @math.cos(stack_angle)
    let z = radius * @math.sin(stack_angle)
    for j in 0..<=sectors {
      let sector_angle = primitive_f32(j) * sector_step
      let x = xy * @math.cos(sector_angle)
      let y = xy * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      normals.push(
        @math.Vec3::new(x * length_inv, y * length_inv, z * length_inv),
      )
      uvs.push(
        @math.Vec2::new(
          primitive_f32(j) / sectors_f32,
          primitive_f32(i) / stacks_f32,
        ),
      )
    }
  }

  for i in 0..<stacks {
    let mut k1 = i * (sectors + 1)
    let mut k2 = k1 + sectors + 1
    for _j in 0..<sectors {
      if i != 0 {
        indices.push(k1)
        indices.push(k2)
        indices.push(k1 + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + 1)
        indices.push(k2)
        indices.push(k2 + 1)
      }
      k1 = k1 + 1
      k2 = k2 + 1
    }
  }

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}
