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
pub struct Mesh3dGeometry {
  positions : Array[@math.Vec3]
  uvs : Array[@math.Vec2]
  colors : Array[@math.Vec4]?
  mut tangents : Array[@math.Vec4]?
  indices : Array[Int]?
  topology : Mesh3dPrimitiveTopology
}

///|
pub(all) enum Mesh3dPrimitiveTopology {
  TriangleList
  LineList
  LineStrip
} derive(Eq, Show)

///|
pub fn Mesh3dPrimitiveTopology::to_int(self : Mesh3dPrimitiveTopology) -> Int {
  match self {
    TriangleList => 0
    LineList => 1
    LineStrip => 2
  }
}

///|
pub(all) enum Mesh3dValidationError {
  EmptyGeometry
  AttributeLengthMismatch(Int, Int)
  ColorLengthMismatch(Int, Int)
  TangentLengthMismatch(Int, Int)
  NonTriangleVertexCount(Int)
  NonTriangleIndexCount(Int)
  NonLineListVertexCount(Int)
  NonLineListIndexCount(Int)
  NonLineStripVertexCount(Int)
  NonLineStripIndexCount(Int)
  IndexOutOfBounds(Int, Int)
} derive(Eq, Show)

///|
pub(all) enum Mesh3dGenerateTangentsError {
  InvalidGeometry(Mesh3dValidationError)
  UnsupportedTopology(Mesh3dPrimitiveTopology)
  DegenerateUvTriangle(Int, Int, Int)
} derive(Eq, Show)

///|
pub fn Mesh3dGeometry::new(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: None,
    tangents: None,
    indices,
    topology: Mesh3dPrimitiveTopology::TriangleList,
  }
}

///|
pub fn Mesh3dGeometry::new_with_colors(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: Some(colors),
    tangents: None,
    indices,
    topology: Mesh3dPrimitiveTopology::TriangleList,
  }
}

///|
pub fn Mesh3dGeometry::new_with_topology(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: None,
    tangents: None,
    indices,
    topology,
  }
}

///|
pub fn Mesh3dGeometry::new_with_colors_and_topology(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: Some(colors),
    tangents: None,
    indices,
    topology,
  }
}

///|
pub fn Mesh3dGeometry::with_topology(
  self : Mesh3dGeometry,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions: self.positions,
    uvs: self.uvs,
    colors: self.colors,
    tangents: None,
    indices: self.indices,
    topology,
  }
}

///|
pub fn Mesh3dGeometry::primitive_topology(
  self : Mesh3dGeometry,
) -> Mesh3dPrimitiveTopology {
  self.topology
}

///|
const MESH3D_PI : Float = 3.141592653589793F

///|
const MESH3D_TANGENT_EPSILON : Float = 1.0e-8F

///|
fn mesh3d_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn mesh3d_absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn mesh3d_icosphere_uv(unit : @math.Vec3) -> @math.Vec2 {
  let azimuth = @math.atan2(unit.z, unit.x)
  let horizontal = @math.sqrt(unit.x * unit.x + unit.z * unit.z)
  let elevation = @math.atan2(unit.y, horizontal)
  let u = 0.5F - azimuth / (2.0F * MESH3D_PI)
  let v = 0.5F - elevation / MESH3D_PI
  @math.Vec2::new(u, v)
}

///|
pub fn Mesh3dGeometry::uv(self : Mesh3dGeometry, index : Int) -> @math.Vec2? {
  if index < 0 || index >= self.uvs.length() {
    None
  } else {
    Some(self.uvs[index])
  }
}

///|
pub fn Mesh3dGeometry::set_uv(
  self : Mesh3dGeometry,
  index : Int,
  uv : @math.Vec2,
) -> Bool {
  if index < 0 || index >= self.uvs.length() {
    return false
  }
  self.uvs[index] = uv
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::replace_uvs(
  self : Mesh3dGeometry,
  uvs : Array[@math.Vec2],
) -> Bool {
  if uvs.length() != self.positions.length() {
    return false
  }
  self.uvs.clear()
  for uv in uvs {
    self.uvs.push(uv)
  }
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::set_position(
  self : Mesh3dGeometry,
  index : Int,
  position : @math.Vec3,
) -> Bool {
  if index < 0 || index >= self.positions.length() {
    return false
  }
  self.positions[index] = position
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::push_vertex(
  self : Mesh3dGeometry,
  position : @math.Vec3,
  uv : @math.Vec2,
) -> Int {
  self.positions.push(position)
  self.uvs.push(uv)
  if self.colors is Some(colors) {
    colors.push(@math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F))
  }
  if self.tangents is Some(tangents) {
    tangents.push(@math.Vec4::new(1.0F, 0.0F, 0.0F, 1.0F))
  }
  self.tangents = None
  self.positions.length() - 1
}

///|
pub fn Mesh3dGeometry::push_vertex_with_color(
  self : Mesh3dGeometry,
  position : @math.Vec3,
  uv : @math.Vec2,
  color : @math.Vec4,
) -> Bool {
  guard self.colors is Some(colors) else { return false }
  self.positions.push(position)
  self.uvs.push(uv)
  colors.push(color)
  if self.tangents is Some(tangents) {
    tangents.push(@math.Vec4::new(1.0F, 0.0F, 0.0F, 1.0F))
  }
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::clear_vertices(self : Mesh3dGeometry) -> Unit {
  self.positions.clear()
  self.uvs.clear()
  if self.colors is Some(colors) {
    colors.clear()
  }
  if self.tangents is Some(tangents) {
    tangents.clear()
  }
  if self.indices is Some(indices) {
    indices.clear()
  }
}

///|
pub fn Mesh3dGeometry::clear_indices(self : Mesh3dGeometry) -> Unit {
  if self.indices is Some(indices) {
    indices.clear()
  }
  self.tangents = None
}

///|
pub fn Mesh3dGeometry::push_index(self : Mesh3dGeometry, index : Int) -> Bool {
  if index < 0 || index >= self.positions.length() {
    return false
  }
  guard self.indices is Some(indices) else { return false }
  indices.push(index)
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::push_triangle_indices(
  self : Mesh3dGeometry,
  a : Int,
  b : Int,
  c : Int,
) -> Bool {
  let vertex_count = self.positions.length()
  if a < 0 ||
    a >= vertex_count ||
    b < 0 ||
    b >= vertex_count ||
    c < 0 ||
    c >= vertex_count {
    return false
  }
  guard self.indices is Some(indices) else { return false }
  indices.push(a)
  indices.push(b)
  indices.push(c)
  self.tangents = None
  true
}

///|
pub fn Mesh3dGeometry::with_indices(
  self : Mesh3dGeometry,
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions: self.positions,
    uvs: self.uvs,
    colors: self.colors,
    tangents: None,
    indices,
    topology: self.topology,
  }
}

///|
pub fn Mesh3dGeometry::with_colors(
  self : Mesh3dGeometry,
  colors : Array[@math.Vec4]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions: self.positions,
    uvs: self.uvs,
    colors,
    tangents: self.tangents,
    indices: self.indices,
    topology: self.topology,
  }
}

///|
pub fn Mesh3dGeometry::has_tangents(self : Mesh3dGeometry) -> Bool {
  self.tangents is Some(_)
}

///|
pub fn Mesh3dGeometry::tangent(
  self : Mesh3dGeometry,
  index : Int,
) -> @math.Vec4? {
  if index < 0 {
    return None
  }
  guard self.tangents is Some(tangents) else { return None }
  if index >= tangents.length() {
    None
  } else {
    Some(tangents[index])
  }
}

///|
pub fn Mesh3dGeometry::replace_tangents(
  self : Mesh3dGeometry,
  tangents : Array[@math.Vec4]?,
) -> Bool {
  match tangents {
    None => {
      self.tangents = None
      true
    }
    Some(values) =>
      if values.length() != self.positions.length() {
        false
      } else {
        self.tangents = Some(values)
        true
      }
  }
}

///|
pub fn Mesh3dGeometry::clear_tangents(self : Mesh3dGeometry) -> Unit {
  self.tangents = None
}

///|
pub fn Mesh3dGeometry::cuboid(cuboid : @math.Cuboid) -> Mesh3dGeometry {
  let size = cuboid.size()
  let hx = size.x * 0.5F
  let hy = size.y * 0.5F
  let hz = size.z * 0.5F
  let p000 = @math.Vec3::new(-hx, -hy, -hz)
  let p100 = @math.Vec3::new(hx, -hy, -hz)
  let p110 = @math.Vec3::new(hx, hy, -hz)
  let p010 = @math.Vec3::new(-hx, hy, -hz)
  let p001 = @math.Vec3::new(-hx, -hy, hz)
  let p101 = @math.Vec3::new(hx, -hy, hz)
  let p111 = @math.Vec3::new(hx, hy, hz)
  let p011 = @math.Vec3::new(-hx, hy, hz)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  // +Z front
  positions.push(p001)
  positions.push(p101)
  positions.push(p111)
  positions.push(p001)
  positions.push(p111)
  positions.push(p011)
  // -Z back
  positions.push(p100)
  positions.push(p000)
  positions.push(p010)
  positions.push(p100)
  positions.push(p010)
  positions.push(p110)
  // +X right
  positions.push(p101)
  positions.push(p100)
  positions.push(p110)
  positions.push(p101)
  positions.push(p110)
  positions.push(p111)
  // -X left
  positions.push(p000)
  positions.push(p001)
  positions.push(p011)
  positions.push(p000)
  positions.push(p011)
  positions.push(p010)
  // +Y top
  positions.push(p011)
  positions.push(p111)
  positions.push(p110)
  positions.push(p011)
  positions.push(p110)
  positions.push(p010)
  // -Y bottom
  positions.push(p000)
  positions.push(p100)
  positions.push(p101)
  positions.push(p000)
  positions.push(p101)
  positions.push(p001)
  for _ in 0..<6 {
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
    uvs.push(@math.Vec2::new(1.0F, 0.0F))
    uvs.push(@math.Vec2::new(1.0F, 1.0F))
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
    uvs.push(@math.Vec2::new(1.0F, 1.0F))
    uvs.push(@math.Vec2::new(0.0F, 1.0F))
  }
  Mesh3dGeometry::new(positions, uvs, None)
}

///|
pub fn Mesh3dGeometry::rectangle(
  width : Float,
  height : Float,
) -> Mesh3dGeometry {
  let safe_width = if width <= 0.0F { 1.0F } else { width }
  let safe_height = if height <= 0.0F { 1.0F } else { height }
  let half_width = safe_width * 0.5F
  let half_height = safe_height * 0.5F
  let positions : Array[@math.Vec3] = [
    @math.Vec3::new(-half_width, -half_height, 0.0F),
    @math.Vec3::new(half_width, -half_height, 0.0F),
    @math.Vec3::new(half_width, half_height, 0.0F),
    @math.Vec3::new(-half_width, -half_height, 0.0F),
    @math.Vec3::new(half_width, half_height, 0.0F),
    @math.Vec3::new(-half_width, half_height, 0.0F),
  ]
  let uvs : Array[@math.Vec2] = [
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  Mesh3dGeometry::new(positions, uvs, None)
}

///|
pub fn Mesh3dGeometry::circle(radius : Float, segments : Int) -> Mesh3dGeometry {
  let safe_radius = if radius <= 0.0F { 1.0F } else { radius }
  let safe_segments = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let inv_diameter = 1.0F / (2.0F * safe_radius)

  positions.push(@math.Vec3::new(0.0F, 0.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  for i in 0..<safe_segments {
    let angle = 2.0F *
      MESH3D_PI *
      mesh3d_float_from_int(i) /
      mesh3d_float_from_int(safe_segments)
    let x = @math.cos(angle) * safe_radius
    let y = @math.sin(angle) * safe_radius
    positions.push(@math.Vec3::new(x, y, 0.0F))
    uvs.push(@math.Vec2::new(x * inv_diameter + 0.5F, y * inv_diameter + 0.5F))
  }
  for i in 0..<safe_segments {
    let current = i + 1
    let next = if i + 1 == safe_segments { 1 } else { i + 2 }
    indices.push(0)
    indices.push(current)
    indices.push(next)
  }
  Mesh3dGeometry::new(positions, uvs, Some(indices))
}

///|
pub fn Mesh3dGeometry::circle_line_strip(
  radius : Float,
  segments : Int,
) -> Mesh3dGeometry {
  let safe_radius = if radius <= 0.0F { 1.0F } else { radius }
  let safe_segments = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for i in 0..<(safe_segments + 1) {
    let angle = 2.0F *
      MESH3D_PI *
      mesh3d_float_from_int(i) /
      mesh3d_float_from_int(safe_segments)
    positions.push(
      @math.Vec3::new(
        @math.cos(angle) * safe_radius,
        @math.sin(angle) * safe_radius,
        0.0F,
      ),
    )
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    None,
    Mesh3dPrimitiveTopology::LineStrip,
  )
}

///|
pub fn Mesh3dGeometry::icosphere(
  radius : Float,
  subdivisions : Int,
) -> Mesh3dGeometry {
  let safe_radius = if radius <= 0.0F { 1.0F } else { radius }
  let safe_subdivisions = if subdivisions < 0 { 0 } else { subdivisions }
  let t = (1.0F + @math.sqrt(5.0F)) / 2.0F
  let base_vertices : Array[@math.Vec3] = [
    @math.Vec3::new(-1.0F, t, 0.0F).normalize_or_zero(),
    @math.Vec3::new(1.0F, t, 0.0F).normalize_or_zero(),
    @math.Vec3::new(-1.0F, -t, 0.0F).normalize_or_zero(),
    @math.Vec3::new(1.0F, -t, 0.0F).normalize_or_zero(),
    @math.Vec3::new(0.0F, -1.0F, t).normalize_or_zero(),
    @math.Vec3::new(0.0F, 1.0F, t).normalize_or_zero(),
    @math.Vec3::new(0.0F, -1.0F, -t).normalize_or_zero(),
    @math.Vec3::new(0.0F, 1.0F, -t).normalize_or_zero(),
    @math.Vec3::new(t, 0.0F, -1.0F).normalize_or_zero(),
    @math.Vec3::new(t, 0.0F, 1.0F).normalize_or_zero(),
    @math.Vec3::new(-t, 0.0F, -1.0F).normalize_or_zero(),
    @math.Vec3::new(-t, 0.0F, 1.0F).normalize_or_zero(),
  ]
  let faces : Array[(Int, Int, Int)] = [
    (0, 11, 5),
    (0, 5, 1),
    (0, 1, 7),
    (0, 7, 10),
    (0, 10, 11),
    (1, 5, 9),
    (5, 11, 4),
    (11, 10, 2),
    (10, 7, 6),
    (7, 1, 8),
    (3, 9, 4),
    (3, 4, 2),
    (3, 2, 6),
    (3, 6, 8),
    (3, 8, 9),
    (4, 9, 5),
    (2, 4, 11),
    (6, 2, 10),
    (8, 6, 7),
    (9, 8, 1),
  ]
  let mut tris : Array[(@math.Vec3, @math.Vec3, @math.Vec3)] = []
  for face in faces {
    tris.push(
      (base_vertices[face.0], base_vertices[face.1], base_vertices[face.2]),
    )
  }

  for _ in 0..<safe_subdivisions {
    let next : Array[(@math.Vec3, @math.Vec3, @math.Vec3)] = []
    for tri in tris {
      let a = tri.0
      let b = tri.1
      let c = tri.2
      let ab = a.add(b).mul_scalar(0.5F).normalize_or_zero()
      let bc = b.add(c).mul_scalar(0.5F).normalize_or_zero()
      let ca = c.add(a).mul_scalar(0.5F).normalize_or_zero()
      next.push((a, ab, ca))
      next.push((b, bc, ab))
      next.push((c, ca, bc))
      next.push((ab, bc, ca))
    }
    tris = next
  }

  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for tri in tris {
    let a_unit = tri.0
    let b_unit = tri.1
    let c_unit = tri.2
    positions.push(a_unit.mul_scalar(safe_radius))
    positions.push(b_unit.mul_scalar(safe_radius))
    positions.push(c_unit.mul_scalar(safe_radius))
    uvs.push(mesh3d_icosphere_uv(a_unit))
    uvs.push(mesh3d_icosphere_uv(b_unit))
    uvs.push(mesh3d_icosphere_uv(c_unit))
  }
  Mesh3dGeometry::new(positions, uvs, None)
}

///|
pub fn Mesh3dGeometry::validate(
  self : Mesh3dGeometry,
) -> Mesh3dValidationError? {
  let vertex_count = self.positions.length()
  if vertex_count == 0 {
    return Some(Mesh3dValidationError::EmptyGeometry)
  }
  let uv_count = self.uvs.length()
  if uv_count != vertex_count {
    return Some(
      Mesh3dValidationError::AttributeLengthMismatch(vertex_count, uv_count),
    )
  }
  if self.colors is Some(colors) {
    let color_count = colors.length()
    if color_count != vertex_count {
      return Some(
        Mesh3dValidationError::ColorLengthMismatch(vertex_count, color_count),
      )
    }
  }
  if self.tangents is Some(tangents) {
    let tangent_count = tangents.length()
    if tangent_count != vertex_count {
      return Some(
        Mesh3dValidationError::TangentLengthMismatch(
          vertex_count, tangent_count,
        ),
      )
    }
  }
  let primitive_count = match self.indices {
    Some(indices) => {
      let index_count = indices.length()
      for i in 0..<index_count {
        let idx = indices[i]
        if idx < 0 || idx >= vertex_count {
          return Some(
            Mesh3dValidationError::IndexOutOfBounds(idx, vertex_count),
          )
        }
      }
      index_count
    }
    None => vertex_count
  }

  match self.topology {
    Mesh3dPrimitiveTopology::TriangleList =>
      if self.indices is Some(_) {
        if primitive_count == 0 || primitive_count % 3 != 0 {
          Some(Mesh3dValidationError::NonTriangleIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count % 3 != 0 {
        Some(Mesh3dValidationError::NonTriangleVertexCount(primitive_count))
      } else {
        None
      }
    Mesh3dPrimitiveTopology::LineList =>
      if self.indices is Some(_) {
        if primitive_count == 0 || primitive_count % 2 != 0 {
          Some(Mesh3dValidationError::NonLineListIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count % 2 != 0 {
        Some(Mesh3dValidationError::NonLineListVertexCount(primitive_count))
      } else {
        None
      }
    Mesh3dPrimitiveTopology::LineStrip =>
      if self.indices is Some(_) {
        if primitive_count < 2 {
          Some(Mesh3dValidationError::NonLineStripIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count < 2 {
        Some(Mesh3dValidationError::NonLineStripVertexCount(primitive_count))
      } else {
        None
      }
  }
}

///|
pub fn Mesh3dGeometry::generate_tangents(
  self : Mesh3dGeometry,
) -> Mesh3dGenerateTangentsError? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return Some(Mesh3dGenerateTangentsError::UnsupportedTopology(self.topology))
  }
  if self.validate() is Some(err) {
    return Some(Mesh3dGenerateTangentsError::InvalidGeometry(err))
  }

  let vertex_count = self.positions.length()
  let tangent_x : Array[Float] = []
  let tangent_y : Array[Float] = []
  let tangent_z : Array[Float] = []
  let bitangent_x : Array[Float] = []
  let bitangent_y : Array[Float] = []
  let bitangent_z : Array[Float] = []
  for _ in 0..<vertex_count {
    tangent_x.push(0.0F)
    tangent_y.push(0.0F)
    tangent_z.push(0.0F)
    bitangent_x.push(0.0F)
    bitangent_y.push(0.0F)
    bitangent_z.push(0.0F)
  }

  let mut accumulate_error : Mesh3dGenerateTangentsError? = None
  let accumulate_triangle = fn(i0 : Int, i1 : Int, i2 : Int) -> Unit {
    if accumulate_error is Some(_) {
      return
    }
    let p0 = self.positions[i0]
    let p1 = self.positions[i1]
    let p2 = self.positions[i2]
    let uv0 = self.uvs[i0]
    let uv1 = self.uvs[i1]
    let uv2 = self.uvs[i2]
    let edge1 = p1.sub(p0)
    let edge2 = p2.sub(p0)
    let du1 = uv1.x - uv0.x
    let dv1 = uv1.y - uv0.y
    let du2 = uv2.x - uv0.x
    let dv2 = uv2.y - uv0.y
    let denominator = du1 * dv2 - du2 * dv1
    if mesh3d_absf(denominator) <= MESH3D_TANGENT_EPSILON {
      accumulate_error = Some(
        Mesh3dGenerateTangentsError::DegenerateUvTriangle(i0, i1, i2),
      )
      return
    }
    let inv_denom = 1.0F / denominator
    let tx = (edge1.x * dv2 - edge2.x * dv1) * inv_denom
    let ty = (edge1.y * dv2 - edge2.y * dv1) * inv_denom
    let tz = (edge1.z * dv2 - edge2.z * dv1) * inv_denom
    let bx = (edge2.x * du1 - edge1.x * du2) * inv_denom
    let by = (edge2.y * du1 - edge1.y * du2) * inv_denom
    let bz = (edge2.z * du1 - edge1.z * du2) * inv_denom

    tangent_x[i0] = tangent_x[i0] + tx
    tangent_y[i0] = tangent_y[i0] + ty
    tangent_z[i0] = tangent_z[i0] + tz
    tangent_x[i1] = tangent_x[i1] + tx
    tangent_y[i1] = tangent_y[i1] + ty
    tangent_z[i1] = tangent_z[i1] + tz
    tangent_x[i2] = tangent_x[i2] + tx
    tangent_y[i2] = tangent_y[i2] + ty
    tangent_z[i2] = tangent_z[i2] + tz

    bitangent_x[i0] = bitangent_x[i0] + bx
    bitangent_y[i0] = bitangent_y[i0] + by
    bitangent_z[i0] = bitangent_z[i0] + bz
    bitangent_x[i1] = bitangent_x[i1] + bx
    bitangent_y[i1] = bitangent_y[i1] + by
    bitangent_z[i1] = bitangent_z[i1] + bz
    bitangent_x[i2] = bitangent_x[i2] + bx
    bitangent_y[i2] = bitangent_y[i2] + by
    bitangent_z[i2] = bitangent_z[i2] + bz
  }

  match self.indices {
    Some(indices) => {
      let triangle_count = indices.length() / 3
      for tri in 0..<triangle_count {
        let i0 = indices[tri * 3]
        let i1 = indices[tri * 3 + 1]
        let i2 = indices[tri * 3 + 2]
        accumulate_triangle(i0, i1, i2)
      }
    }
    None => {
      let triangle_count = vertex_count / 3
      for tri in 0..<triangle_count {
        let i0 = tri * 3
        let i1 = tri * 3 + 1
        let i2 = tri * 3 + 2
        accumulate_triangle(i0, i1, i2)
      }
    }
  }

  if accumulate_error is Some(err) {
    return Some(err)
  }

  let tangents : Array[@math.Vec4] = []
  for i in 0..<vertex_count {
    let tangent = @math.Vec3::new(tangent_x[i], tangent_y[i], tangent_z[i]).normalize_or_zero()
    let bitangent = @math.Vec3::new(
      bitangent_x[i],
      bitangent_y[i],
      bitangent_z[i],
    )
    let normal = tangent.cross(bitangent).normalize_or_zero()
    let handedness = if normal.length_squared() <= MESH3D_TANGENT_EPSILON {
      1.0F
    } else if normal.cross(tangent).dot(bitangent) < 0.0F {
      -1.0F
    } else {
      1.0F
    }
    tangents.push(@math.Vec4::new(tangent.x, tangent.y, tangent.z, handedness))
  }
  self.tangents = Some(tangents)
  None
}

///|
pub fn Mesh3dGeometry::vertex_count(self : Mesh3dGeometry) -> Int {
  self.positions.length()
}

///|
pub fn Mesh3dGeometry::triangle_count(self : Mesh3dGeometry) -> Int? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  match self.validate() {
    Some(_) => None
    None =>
      match self.indices {
        Some(indices) => Some(indices.length() / 3)
        None => Some(self.positions.length() / 3)
      }
  }
}

///|
fn mesh3d_wireframe_push_vertex(
  src_positions : Array[@math.Vec3],
  src_uvs : Array[@math.Vec2],
  src_colors : Array[@math.Vec4]?,
  dst_positions : Array[@math.Vec3],
  dst_uvs : Array[@math.Vec2],
  dst_colors : Array[@math.Vec4]?,
  src_index : Int,
) -> Unit {
  dst_positions.push(src_positions[src_index])
  dst_uvs.push(src_uvs[src_index])
  if src_colors is Some(colors) {
    guard dst_colors is Some(out_colors) else { return }
    out_colors.push(colors[src_index])
  }
}

///|
fn mesh3d_wireframe_append_edge(
  src_positions : Array[@math.Vec3],
  src_uvs : Array[@math.Vec2],
  src_colors : Array[@math.Vec4]?,
  dst_positions : Array[@math.Vec3],
  dst_uvs : Array[@math.Vec2],
  dst_colors : Array[@math.Vec4]?,
  a : Int,
  b : Int,
) -> Unit {
  mesh3d_wireframe_push_vertex(
    src_positions, src_uvs, src_colors, dst_positions, dst_uvs, dst_colors, a,
  )
  mesh3d_wireframe_push_vertex(
    src_positions, src_uvs, src_colors, dst_positions, dst_uvs, dst_colors, b,
  )
}

///|
pub fn Mesh3dGeometry::to_wireframe_line_list(
  self : Mesh3dGeometry,
) -> Mesh3dGeometry? {
  if self.validate() is Some(_) {
    return None
  }
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  let out_positions : Array[@math.Vec3] = []
  let out_uvs : Array[@math.Vec2] = []
  let out_colors : Array[@math.Vec4]? = if self.colors is Some(_) {
    Some([])
  } else {
    None
  }
  match self.indices {
    Some(indices) => {
      let tri_count = indices.length() / 3
      for tri_index in 0..<tri_count {
        let i0 = indices[tri_index * 3]
        let i1 = indices[tri_index * 3 + 1]
        let i2 = indices[tri_index * 3 + 2]
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i0,
          i1,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i1,
          i2,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i2,
          i0,
        )
      }
    }
    None => {
      let tri_count = self.positions.length() / 3
      for tri_index in 0..<tri_count {
        let i0 = tri_index * 3
        let i1 = tri_index * 3 + 1
        let i2 = tri_index * 3 + 2
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i0,
          i1,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i1,
          i2,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i2,
          i0,
        )
      }
    }
  }
  match out_colors {
    Some(colors) =>
      Some(
        Mesh3dGeometry::new_with_colors_and_topology(
          out_positions,
          out_uvs,
          colors,
          None,
          Mesh3dPrimitiveTopology::LineList,
        ),
      )
    None =>
      Some(
        Mesh3dGeometry::new_with_topology(
          out_positions,
          out_uvs,
          None,
          Mesh3dPrimitiveTopology::LineList,
        ),
      )
  }
}

///|
fn mesh3d_vertex_color_or_white(
  colors : Array[@math.Vec4]?,
  index : Int,
) -> @math.Vec4 {
  match colors {
    Some(cs) => cs[index]
    None => @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F)
  }
}

///|
pub fn Mesh3dGeometry::flatten_interleaved_xyz_uv_rgba(
  self : Mesh3dGeometry,
) -> Array[Double]? {
  if self.validate() is Some(_) {
    return None
  }
  let out : Array[Double] = []
  match self.indices {
    None => {
      let n = self.positions.length()
      for i in 0..<n {
        let p = self.positions[i]
        let uv = self.uvs[i]
        let c = mesh3d_vertex_color_or_white(self.colors, i)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(p.z.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(c.x.to_double())
        out.push(c.y.to_double())
        out.push(c.z.to_double())
        out.push(c.w.to_double())
      }
    }
    Some(indices) =>
      for i in 0..<indices.length() {
        let idx = indices[i]
        let p = self.positions[idx]
        let uv = self.uvs[idx]
        let c = mesh3d_vertex_color_or_white(self.colors, idx)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(p.z.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(c.x.to_double())
        out.push(c.y.to_double())
        out.push(c.z.to_double())
        out.push(c.w.to_double())
      }
  }
  Some(out)
}

///|
pub fn Mesh3dGeometry::encode_interleaved_xyz_uv_rgba_csv(
  self : Mesh3dGeometry,
) -> String? {
  match self.flatten_interleaved_xyz_uv_rgba() {
    None => None
    Some(values) => Some(values.map(fn(v) { v.to_string() }).join(","))
  }
}

///|
pub fn Mesh3dGeometry::flatten_triangle_interleaved_xyz_uv_rgba(
  self : Mesh3dGeometry,
) -> Array[Double]? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  self.flatten_interleaved_xyz_uv_rgba()
}

///|
pub fn Mesh3dGeometry::encode_triangle_interleaved_xyz_uv_rgba_csv(
  self : Mesh3dGeometry,
) -> String? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  self.encode_interleaved_xyz_uv_rgba_csv()
}
