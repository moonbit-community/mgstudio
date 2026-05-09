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
pub enum PerimeterSegment {
  Smooth(@math.Vec2, @math.Vec2, Array[Int])
  Flat(Array[Int])
}

///|
pub(open) trait Extrudable: MeshBuilder {
  perimeter(Self) -> Array[PerimeterSegment]
}

///|
pub(open) trait Meshable {
  mesh(Self) -> @mesh.Mesh3dGeometry
}

///|
pub(open) trait ExtrudablePrimitive: Meshable {
  mesh_perimeter(Self) -> Array[PerimeterSegment]
}

///|
pub(all) struct ExtrusionBuilder {
  base_mesh : @mesh.Mesh3dGeometry
  perimeter : Array[PerimeterSegment]
  half_depth : Float
  segments : Int
}

///|
pub fn ExtrusionBuilder::new(
  base_mesh : @mesh.Mesh3dGeometry,
  perimeter : Array[PerimeterSegment],
  depth : Float,
) -> ExtrusionBuilder {
  { base_mesh, perimeter, half_depth: depth / 2.0F, segments: 1 }
}

///|
pub fn ExtrusionBuilder::segments(
  self : ExtrusionBuilder,
  segments : Int,
) -> ExtrusionBuilder {
  {
    base_mesh: self.base_mesh,
    perimeter: self.perimeter,
    half_depth: self.half_depth,
    segments,
  }
}

///|
pub fn ExtrusionBuilder::build(self : ExtrusionBuilder) -> @mesh.Mesh3dGeometry {
  extrusion_build(
    self.base_mesh,
    self.perimeter,
    self.half_depth * 2.0F,
    self.segments,
  )
}

///|
pub impl MeshBuilder for ExtrusionBuilder with build(self) {
  extrusion_build(
    self.base_mesh,
    self.perimeter,
    self.half_depth * 2.0F,
    self.segments,
  )
}

///|
pub fn extrusion_wireframe_mesh(
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3dGeometry? {
  geometry.to_wireframe_line_list()
}

///|
pub fn[P : ExtrudablePrimitive] extrusion_mesh(
  extrusion : @math.Extrusion[P],
) -> @mesh.Mesh3dGeometry {
  let shape = extrusion.base_shape
  ExtrusionBuilder::new(
    shape.mesh(),
    shape.mesh_perimeter(),
    extrusion.half_depth * 2.0F,
  ).build()
}

///|
fn extrusion_build(
  base_mesh : @mesh.Mesh3dGeometry,
  perimeter : Array[PerimeterSegment],
  depth : Float,
  segments : Int,
) -> @mesh.Mesh3dGeometry {
  let segments = if segments < 1 { 1 } else { segments }
  let half_depth = depth / 2.0F
  let base_count = base_mesh.vertex_count()
  let base_positions = mesh_positions(base_mesh)
  let base_uvs = mesh_uvs(base_mesh)
  let base_normals = mesh_normals_or_default(base_mesh, 1.0F)
  let base_indices = base_mesh.indices_or_sequential()
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  for i in 0..<base_count {
    let p = base_positions[i]
    let uv = base_uvs[i]
    positions.push(@math.Vec3::new(p.x, p.y, half_depth))
    normals.push(base_normals[i])
    uvs.push(@math.Vec2::new(uv.x * 0.5F, uv.y * 0.5F))
  }
  for index in base_indices {
    indices.push(index)
  }

  let back_offset = positions.length()
  for i in 0..<base_count {
    let p = base_positions[i]
    let uv = base_uvs[i]
    let n = base_normals[i]
    positions.push(@math.Vec3::new(p.x, p.y, -half_depth))
    normals.push(@math.Vec3::new(n.x, n.y, -n.z))
    uvs.push(@math.Vec2::new(uv.x * 0.5F + 0.5F, uv.y * 0.5F))
  }
  let mut tri = 0
  while tri + 2 < base_indices.length() {
    indices.push(back_offset + base_indices[tri + 1])
    indices.push(back_offset + base_indices[tri])
    indices.push(back_offset + base_indices[tri + 2])
    tri = tri + 3
  }

  if half_depth != 0.0F {
    extrusion_append_mantel(
      positions, normals, uvs, indices, base_positions, perimeter, half_depth, segments,
    )
  }

  primitive2d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn extrusion_append_mantel(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int],
  cap_verts : Array[@math.Vec3],
  perimeter : Array[PerimeterSegment],
  half_depth : Float,
  segments : Int,
) -> Unit {
  let layers = segments + 1
  let layer_depth_delta = half_depth * 2.0F / primitive2d_f32(segments)
  let uv_segment_delta = 1.0F / primitive2d_f32(perimeter.length())
  for segment_index in 0..<perimeter.length() {
    let segment = perimeter[segment_index]
    let uv_start = primitive2d_f32(segment_index) * uv_segment_delta
    match segment {
      Flat(segment_indices) =>
        extrusion_append_flat_mantel(
          positions, normals, uvs, indices, cap_verts, segment_indices, layers, segments,
          layer_depth_delta, uv_start, uv_segment_delta,
        )
      Smooth(first_normal, last_normal, segment_indices) =>
        extrusion_append_smooth_mantel(
          positions, normals, uvs, indices, cap_verts, first_normal, last_normal,
          segment_indices, layers, segments, layer_depth_delta, uv_start, uv_segment_delta,
        )
    }
  }
}

///|
fn extrusion_append_flat_mantel(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int],
  cap_verts : Array[@math.Vec3],
  segment_indices : Array[Int],
  layers : Int,
  segments : Int,
  layer_depth_delta : Float,
  uv_start : Float,
  uv_segment_delta : Float,
) -> Unit {
  let uv_delta = uv_segment_delta /
    primitive2d_f32(segment_indices.length() - 1)
  for i in 0..<(segment_indices.length() - 1) {
    let uv_x = uv_start + uv_delta * primitive2d_f32(i)
    let a = cap_verts[segment_indices[i]]
    let b = cap_verts[segment_indices[i + 1]]
    let index = positions.length()
    for layer in 0..<layers {
      let layer_f = primitive2d_f32(layer)
      let z = a.z - layer_depth_delta * layer_f
      positions.push(@math.Vec3::new(a.x, a.y, z))
      positions.push(@math.Vec3::new(b.x, b.y, z))
      let uv_y = 0.5F + 0.5F * layer_f / primitive2d_f32(segments)
      uvs.push(@math.Vec2::new(uv_x, uv_y))
      uvs.push(@math.Vec2::new(uv_x + uv_delta, uv_y))
    }
    let normal = @math.Vec3::new(b.y - a.y, a.x - b.x, 0.0F).normalize_or_zero()
    for _ in 0..<(2 * layers) {
      normals.push(normal)
    }
    for layer in 0..<segments {
      let base_index = index + 2 * layer
      indices.push(base_index)
      indices.push(base_index + 2)
      indices.push(base_index + 1)
      indices.push(base_index + 1)
      indices.push(base_index + 2)
      indices.push(base_index + 3)
    }
  }
}

///|
fn extrusion_append_smooth_mantel(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int],
  cap_verts : Array[@math.Vec3],
  first_normal : @math.Vec2,
  last_normal : @math.Vec2,
  segment_indices : Array[Int],
  layers : Int,
  segments : Int,
  layer_depth_delta : Float,
  uv_start : Float,
  uv_segment_delta : Float,
) -> Unit {
  let uv_delta = uv_segment_delta /
    primitive2d_f32(segment_indices.length() - 1)
  let base_index = positions.length()
  if segment_indices.length() > 0 {
    let p = cap_verts[segment_indices[0]]
    for layer in 0..<layers {
      let layer_f = primitive2d_f32(layer)
      positions.push(
        @math.Vec3::new(p.x, p.y, p.z - layer_depth_delta * layer_f),
      )
      uvs.push(
        @math.Vec2::new(
          uv_start,
          0.5F + 0.5F * layer_f / primitive2d_f32(segments),
        ),
      )
    }
    for _ in 0..<layers {
      normals.push(@math.Vec3::new(first_normal.x, first_normal.y, 0.0F))
    }
  }

  for i in 1..<(segment_indices.length() - 1) {
    let uv_x = uv_start + uv_delta * primitive2d_f32(i)
    let a = cap_verts[segment_indices[i - 1]]
    let b = cap_verts[segment_indices[i]]
    let c = cap_verts[segment_indices[i + 1]]
    for layer in 0..<layers {
      let layer_f = primitive2d_f32(layer)
      positions.push(
        @math.Vec3::new(b.x, b.y, b.z - layer_depth_delta * layer_f),
      )
      uvs.push(
        @math.Vec2::new(uv_x, 0.5F + 0.5F * layer_f / primitive2d_f32(segments)),
      )
    }
    let ab = @math.Vec2::new(b.x - a.x, b.y - a.y).normalize_or_zero()
    let bc = @math.Vec2::new(c.x - b.x, c.y - b.y).normalize_or_zero()
    let n = ab.add(bc)
    let normal = @math.Vec3::new(n.y, -n.x, 0.0F).normalize_or_zero()
    for _ in 0..<layers {
      normals.push(normal)
    }
  }

  if segment_indices.length() > 0 {
    let p = cap_verts[segment_indices[segment_indices.length() - 1]]
    for layer in 0..<layers {
      let layer_f = primitive2d_f32(layer)
      positions.push(
        @math.Vec3::new(p.x, p.y, p.z - layer_depth_delta * layer_f),
      )
      uvs.push(
        @math.Vec2::new(
          uv_start + uv_segment_delta,
          0.5F + 0.5F * layer_f / primitive2d_f32(segments),
        ),
      )
    }
    for _ in 0..<layers {
      normals.push(@math.Vec3::new(last_normal.x, last_normal.y, 0.0F))
    }
  }

  let columns = segment_indices.length()
  for s in 0..<segments {
    for column in 0..<(columns - 1) {
      let index = base_index + s + column * layers
      indices.push(index)
      indices.push(index + 1)
      indices.push(index + layers)
      indices.push(index + layers)
      indices.push(index + 1)
      indices.push(index + layers + 1)
    }
  }
}

///|
fn ring_mesh(
  outer_mesh : @mesh.Mesh3dGeometry,
  inner_mesh : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3dGeometry {
  let points = outer_mesh.vertex_count()
  let outer_positions = mesh_positions(outer_mesh)
  let inner_positions = mesh_positions(inner_mesh)
  let outer_uvs = mesh_uvs(outer_mesh)
  let inner_uvs = mesh_uvs(inner_mesh)
  let outer_normals = mesh_normals_or_default(outer_mesh, 1.0F)
  let inner_normals = mesh_normals_or_default(inner_mesh, 1.0F)
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  for p in outer_positions {
    positions.push(p)
  }
  for p in inner_positions {
    positions.push(p)
  }
  for n in outer_normals {
    normals.push(n)
  }
  for n in inner_normals {
    normals.push(n)
  }
  for uv in outer_uvs {
    uvs.push(uv)
  }
  for i in 0..<points {
    let inner_position = inner_positions[i]
    let outer_position = outer_positions[i]
    let inner_uv = inner_uvs[i]
    let ip_len = @math.Vec2::new(inner_position.x, inner_position.y).length()
    let op_len = @math.Vec2::new(outer_position.x, outer_position.y).length()
    let scale = if op_len <= 0.000001F { 0.0F } else { ip_len / op_len }
    uvs.push(
      @math.Vec2::new(
        (inner_uv.x - 0.5F) * scale + 0.5F,
        (inner_uv.y - 0.5F) * scale + 0.5F,
      ),
    )
  }

  for i in 0..<points {
    let next = (i + 1) % points
    indices.push(i)
    indices.push(next)
    indices.push(points + i)
    indices.push(points + i)
    indices.push(next)
    indices.push(points + next)
  }

  primitive2d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn ring_perimeter(
  outer : Array[PerimeterSegment],
  inner : Array[PerimeterSegment],
  outer_vertex_count : Int,
) -> Array[PerimeterSegment] {
  let result : Array[PerimeterSegment] = []
  for segment in outer {
    result.push(segment)
  }
  for i in 0..<inner.length() {
    let segment = inner[inner.length() - 1 - i]
    match segment {
      Smooth(first_normal, last_normal, indices) =>
        result.push(
          Smooth(
            last_normal.neg(),
            first_normal.neg(),
            reversed_indices_with_offset(indices, outer_vertex_count),
          ),
        )
      Flat(indices) =>
        result.push(
          Flat(reversed_indices_with_offset(indices, outer_vertex_count)),
        )
    }
  }
  result
}

///|
fn capsule2d_perimeter(resolution : Int) -> Array[PerimeterSegment] {
  [
    Smooth(
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(-1.0F, 0.0F),
      range_indices(0, resolution),
    ),
    Flat([resolution - 1, resolution]),
    Smooth(
      @math.Vec2::new(-1.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      range_indices(resolution, resolution * 2),
    ),
    Flat([2 * resolution - 1, 0]),
  ]
}

///|
fn annulus_perimeter(resolution : Int) -> Array[PerimeterSegment] {
  let inner : Array[Int] = []
  let mut i = 0
  while i < resolution * 2 {
    inner.push(i)
    i = i + 2
  }
  inner.push(0)
  let outer : Array[Int] = []
  i = 1
  while i < resolution * 2 {
    outer.push(i)
    i = i + 2
  }
  outer.push(1)
  [
    Smooth(
      @math.Vec2::new(0.0F, -1.0F),
      @math.Vec2::new(0.0F, -1.0F),
      reversed_indices_with_offset(inner, 0),
    ),
    Smooth(@math.Vec2::new(0.0F, 1.0F), @math.Vec2::new(0.0F, 1.0F), outer),
  ]
}

///|
fn circular_arc_perimeter(
  resolution : Int,
  half_angle : Float,
) -> Array[PerimeterSegment] {
  let sin = @math.sin(half_angle)
  let cos = @math.cos(half_angle)
  [
    Flat([resolution, 0, 1]),
    Smooth(
      @math.Vec2::new(sin, cos),
      @math.Vec2::new(-sin, cos),
      range_indices(1, resolution + 1),
    ),
  ]
}

///|
fn mesh_positions(mesh : @mesh.Mesh3dGeometry) -> Array[@math.Vec3] {
  let positions : Array[@math.Vec3] = []
  for i in 0..<mesh.vertex_count() {
    match mesh.vertex_position(i) {
      Some(position) => positions.push(position)
      None => positions.push(@math.Vec3::zero())
    }
  }
  positions
}

///|
fn mesh_uvs(mesh : @mesh.Mesh3dGeometry) -> Array[@math.Vec2] {
  let uvs : Array[@math.Vec2] = []
  for i in 0..<mesh.vertex_count() {
    match mesh.vertex_uv(i) {
      Some(uv) => uvs.push(uv)
      None => uvs.push(@math.Vec2::new(0.0F, 0.0F))
    }
  }
  uvs
}

///|
fn mesh_normals_or_default(
  mesh : @mesh.Mesh3dGeometry,
  z : Float,
) -> Array[@math.Vec3] {
  match mesh.normals() {
    Some(normals) =>
      if normals.length() == mesh.vertex_count() {
        normals
      } else {
        primitive2d_normal_z(mesh.vertex_count(), z)
      }
    None => primitive2d_normal_z(mesh.vertex_count(), z)
  }
}

///|
fn range_indices(start : Int, end : Int) -> Array[Int] {
  let indices : Array[Int] = []
  for i in start..<end {
    indices.push(i)
  }
  indices
}

///|
fn closed_range_indices(start : Int, end : Int, close : Int) -> Array[Int] {
  let indices = range_indices(start, end)
  indices.push(close)
  indices
}

///|
fn reversed_indices_with_offset(
  indices : Array[Int],
  offset : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<indices.length() {
    result.push(indices[indices.length() - 1 - i] + offset)
  }
  result
}
