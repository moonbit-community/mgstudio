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
/// Port of `bevy/examples/3d/3d_shapes.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const SHAPES_X_EXTENT : Float = 14.0F

///|
const EXTRUSION_X_EXTENT : Float = 14.0F

///|
const Z_EXTENT : Float = 8.0F

///|
const THICKNESS : Float = 0.1F

///|
const TEXTURE_SIZE : Int = 8

///|
priv enum Row {
  Front
  Middle
  Rear
}

///|
priv struct ShapeEntry {
  entity : @core.Entity
  row : Row
}

///|
priv struct ShapesState {
  mut rotating : Bool
  entries : Array[ShapeEntry]
}

///|
let shapes_state : Ref[ShapesState] = Ref::new({ rotating: true, entries: [] })

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn byte_from_int(value : Int) -> Byte {
  value.to_byte()
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn row_z(row : Row) -> Float {
  match row {
    Front => Z_EXTENT / 2.0F
    Middle => 0.0F
    Rear => -Z_EXTENT / 2.0F
  }
}

///|
fn row_advance(row : Row) -> Row {
  match row {
    Front => Rear
    Middle => Front
    Rear => Middle
  }
}

///|
fn spacing_at(index : Int, count : Int, extent : Float) -> Float {
  if count <= 1 {
    0.0F
  } else {
    -extent / 2.0F + float_from_int(index) / float_from_int(count - 1) * extent
  }
}

///|
fn vec3_add(lhs : @math.Vec3, rhs : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

///|
fn vec3_scale(value : @math.Vec3, s : Float) -> @math.Vec3 {
  @math.Vec3::new(value.x * s, value.y * s, value.z * s)
}

///|
fn vec3_length(value : @math.Vec3) -> Float {
  @math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
}

///|
fn vec3_normalize_or_zero(value : @math.Vec3) -> @math.Vec3 {
  let len = vec3_length(value)
  if len <= 0.000001F {
    @math.Vec3::new(0.0F, 0.0F, 0.0F)
  } else {
    vec3_scale(value, 1.0F / len)
  }
}

///|
fn vec2_distance(a : @math.Vec2, b : @math.Vec2) -> Float {
  let dx = b.x - a.x
  let dy = b.y - a.y
  @math.sqrt(dx * dx + dy * dy)
}

///|
fn uv_debug_texture() -> @asset.Handle[@asset.Image] {
  let mut palette : Array[Byte] = [
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(159),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(159),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
  ]

  let texture_data : Array[Byte] = []
  for _y in 0..<TEXTURE_SIZE {
    for i in 0..<palette.length() {
      texture_data.push(palette[i])
    }
    let rotated : Array[Byte] = []
    for i in 0..<palette.length() {
      let source = if i < 4 { palette.length() - 4 + i } else { i - 4 }
      rotated.push(palette[source])
    }
    palette = rotated
  }

  let size = @math.UVec2::new(TEXTURE_SIZE, TEXTURE_SIZE)
  let texture = @asset.asset_create_dynamic_texture(size, true)
  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(@math.UVec2::new(0, 0), size),
    Bytes::from_array(texture_data),
  )
  texture
}

///|
fn mesh_from_soup(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
) -> @pbr.Mesh3d {
  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, None),
      ),
    ),
  )
}

///|
fn soup_push_triangle(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
  ua : @math.Vec2,
  ub : @math.Vec2,
  uc : @math.Vec2,
) -> Unit {
  positions.push(a)
  positions.push(b)
  positions.push(c)
  uvs.push(ua)
  uvs.push(ub)
  uvs.push(uc)
}

///|
fn soup_push_quad(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
  d : @math.Vec3,
  ua : @math.Vec2,
  ub : @math.Vec2,
  uc : @math.Vec2,
  ud : @math.Vec2,
) -> Unit {
  soup_push_triangle(positions, uvs, a, b, c, ua, ub, uc)
  soup_push_triangle(positions, uvs, a, c, d, ua, uc, ud)
}

///|
fn revolve_mesh(profile : Array[(Float, Float)], segments : Int) -> @pbr.Mesh3d {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let segf = float_from_int(safe_segments)
  let count = profile.length()
  let den = if count > 1 { float_from_int(count - 1) } else { 1.0F }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []

  for i in 0..<count {
    let p = profile[i]
    let y = p.0
    let r = max_float(p.1, 0.0F)
    let v = float_from_int(i) / den
    for s in 0..<(safe_segments + 1) {
      let u = float_from_int(s) / segf
      let angle = 2.0F * PI * u
      positions.push(
        @math.Vec3::new(r * @math.cos(angle), y, r * @math.sin(angle)),
      )
      uvs.push(@math.Vec2::new(u, 1.0F - v))
    }
  }

  let indices : Array[Int] = []
  let row = safe_segments + 1
  for i in 0..<(count - 1) {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<safe_segments {
      indices.push(k1 + j)
      indices.push(k2 + j)
      indices.push(k1 + j + 1)

      indices.push(k1 + j + 1)
      indices.push(k2 + j)
      indices.push(k2 + j + 1)
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn sphere_uv_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let safe_stacks = if stacks < 3 { 3 } else { stacks }
  let safe_sectors = if sectors < 3 { 3 } else { sectors }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(safe_stacks)
  let sectors_f = float_from_int(safe_sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(safe_stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(safe_sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = safe_sectors + 1
  for i in 0..<safe_stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<safe_sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != safe_stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn icosphere_mesh(radius : Float, subdivisions : Int) -> @pbr.Mesh3d {
  let t = (1.0F + @math.sqrt(5.0F)) / 2.0F
  let base_vertices = [
    vec3_normalize_or_zero(@math.Vec3::new(-1.0F, t, 0.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(1.0F, t, 0.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(-1.0F, -t, 0.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(1.0F, -t, 0.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(0.0F, -1.0F, t)),
    vec3_normalize_or_zero(@math.Vec3::new(0.0F, 1.0F, t)),
    vec3_normalize_or_zero(@math.Vec3::new(0.0F, -1.0F, -t)),
    vec3_normalize_or_zero(@math.Vec3::new(0.0F, 1.0F, -t)),
    vec3_normalize_or_zero(@math.Vec3::new(t, 0.0F, -1.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(t, 0.0F, 1.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(-t, 0.0F, -1.0F)),
    vec3_normalize_or_zero(@math.Vec3::new(-t, 0.0F, 1.0F)),
  ]
  let faces = [
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

  let safe_subdivisions = if subdivisions < 0 { 0 } else { subdivisions }
  for _ in 0..<safe_subdivisions {
    let next : Array[(@math.Vec3, @math.Vec3, @math.Vec3)] = []
    for tri in tris {
      let a = tri.0
      let b = tri.1
      let c = tri.2
      let ab = vec3_normalize_or_zero(vec3_scale(vec3_add(a, b), 0.5F))
      let bc = vec3_normalize_or_zero(vec3_scale(vec3_add(b, c), 0.5F))
      let ca = vec3_normalize_or_zero(vec3_scale(vec3_add(c, a), 0.5F))
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
    let a = vec3_scale(tri.0, radius)
    let b = vec3_scale(tri.1, radius)
    let c = vec3_scale(tri.2, radius)
    soup_push_triangle(
      positions,
      uvs,
      a,
      b,
      c,
      @math.Vec2::new((tri.0.x + 1.0F) * 0.5F, (tri.0.z + 1.0F) * 0.5F),
      @math.Vec2::new((tri.1.x + 1.0F) * 0.5F, (tri.1.z + 1.0F) * 0.5F),
      @math.Vec2::new((tri.2.x + 1.0F) * 0.5F, (tri.2.z + 1.0F) * 0.5F),
    )
  }
  mesh_from_soup(positions, uvs)
}

///|
fn torus_mesh(
  major_radius : Float,
  minor_radius : Float,
  major_segments : Int,
  minor_segments : Int,
) -> @pbr.Mesh3d {
  let safe_major = if major_segments < 3 { 3 } else { major_segments }
  let safe_minor = if minor_segments < 3 { 3 } else { minor_segments }
  let major_f = float_from_int(safe_major)
  let minor_f = float_from_int(safe_minor)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  for i in 0..<(safe_major + 1) {
    let u = float_from_int(i) / major_f
    let theta = 2.0F * PI * u
    let ct = @math.cos(theta)
    let st = @math.sin(theta)
    for j in 0..<(safe_minor + 1) {
      let v = float_from_int(j) / minor_f
      let phi = 2.0F * PI * v
      let cp = @math.cos(phi)
      let sp = @math.sin(phi)
      let ring_radius = major_radius + minor_radius * cp
      positions.push(
        @math.Vec3::new(ring_radius * ct, minor_radius * sp, ring_radius * st),
      )
      uvs.push(@math.Vec2::new(u, v))
    }
  }

  let row = safe_minor + 1
  for i in 0..<safe_major {
    let base = i * row
    let next = (i + 1) * row
    for j in 0..<safe_minor {
      indices.push(base + j)
      indices.push(next + j)
      indices.push(base + j + 1)

      indices.push(base + j + 1)
      indices.push(next + j)
      indices.push(next + j + 1)
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn cylinder_mesh(radius : Float, height : Float, segments : Int) -> @pbr.Mesh3d {
  let half = height / 2.0F
  revolve_mesh(
    [(half, 0.0F), (half, radius), (-half, radius), (-half, 0.0F)],
    segments,
  )
}

///|
fn cone_mesh(radius : Float, height : Float, segments : Int) -> @pbr.Mesh3d {
  let half = height / 2.0F
  revolve_mesh([(-half, 0.0F), (-half, radius), (half, 0.0F)], segments)
}

///|
fn frustum_mesh(
  radius_bottom : Float,
  radius_top : Float,
  height : Float,
  segments : Int,
) -> @pbr.Mesh3d {
  let half = height / 2.0F
  revolve_mesh(
    [(-half, 0.0F), (-half, radius_bottom), (half, radius_top), (half, 0.0F)],
    segments,
  )
}

///|
fn capsule_mesh(
  radius : Float,
  half_length : Float,
  lat_segments : Int,
  long_segments : Int,
) -> @pbr.Mesh3d {
  let safe_lat = if lat_segments < 4 { 4 } else { lat_segments }
  let lat_f = float_from_int(safe_lat)
  let profile : Array[(Float, Float)] = []
  profile.push((half_length + radius, 0.0F))
  for i in 1..<(safe_lat + 1) {
    let t = float_from_int(i) / lat_f
    let angle = PI / 2.0F - t * (PI / 2.0F)
    profile.push(
      (half_length + radius * @math.sin(angle), radius * @math.cos(angle)),
    )
  }
  profile.push((-half_length, radius))
  for i in 1..<(safe_lat + 1) {
    let t = float_from_int(i) / lat_f
    let angle = -t * (PI / 2.0F)
    profile.push(
      (-half_length + radius * @math.sin(angle), radius * @math.cos(angle)),
    )
  }
  revolve_mesh(profile, long_segments)
}

///|
fn rectangle_points(
  half_width : Float,
  half_height : Float,
) -> Array[@math.Vec2] {
  [
    @math.Vec2::new(-half_width, -half_height),
    @math.Vec2::new(half_width, -half_height),
    @math.Vec2::new(half_width, half_height),
    @math.Vec2::new(-half_width, half_height),
  ]
}

///|
fn circle_points(radius : Float, segments : Int) -> Array[@math.Vec2] {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let out : Array[@math.Vec2] = []
  let den = float_from_int(safe_segments)
  for i in 0..<safe_segments {
    let angle = 2.0F * PI * float_from_int(i) / den
    out.push(
      @math.Vec2::new(radius * @math.cos(angle), radius * @math.sin(angle)),
    )
  }
  out
}

///|
fn ellipse_points(
  half_x : Float,
  half_y : Float,
  segments : Int,
) -> Array[@math.Vec2] {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let out : Array[@math.Vec2] = []
  let den = float_from_int(safe_segments)
  for i in 0..<safe_segments {
    let angle = 2.0F * PI * float_from_int(i) / den
    out.push(
      @math.Vec2::new(half_x * @math.cos(angle), half_y * @math.sin(angle)),
    )
  }
  out
}

///|
fn regular_polygon_points(radius : Float, sides : Int) -> Array[@math.Vec2] {
  let safe_sides = if sides < 3 { 3 } else { sides }
  let out : Array[@math.Vec2] = []
  let den = float_from_int(safe_sides)
  for i in 0..<safe_sides {
    let angle = 2.0F * PI * float_from_int(i) / den + PI / 2.0F
    out.push(
      @math.Vec2::new(radius * @math.cos(angle), radius * @math.sin(angle)),
    )
  }
  out
}

///|
fn triangle_points() -> Array[@math.Vec2] {
  [
    @math.Vec2::new(-0.5F, -0.35F),
    @math.Vec2::new(0.5F, -0.35F),
    @math.Vec2::new(0.0F, 0.55F),
  ]
}

///|
fn scale_points(
  points : Array[@math.Vec2],
  factor : Float,
) -> Array[@math.Vec2] {
  let out : Array[@math.Vec2] = []
  for point in points {
    out.push(@math.Vec2::new(point.x * factor, point.y * factor))
  }
  out
}

///|
fn capsule_points(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Array[@math.Vec2] {
  let safe_segments = if segments < 4 { 4 } else { segments }
  let den = float_from_int(safe_segments)
  let out : Array[@math.Vec2] = []

  for i in 0..<(safe_segments + 1) {
    let angle = -PI / 2.0F + PI * float_from_int(i) / den
    out.push(
      @math.Vec2::new(
        half_length + radius * @math.cos(angle),
        radius * @math.sin(angle),
      ),
    )
  }

  for i in 1..<safe_segments {
    let angle = PI / 2.0F + PI * float_from_int(i) / den
    out.push(
      @math.Vec2::new(
        -half_length + radius * @math.cos(angle),
        radius * @math.sin(angle),
      ),
    )
  }

  out
}

///|
fn line_strip_mesh(points : Array[@math.Vec3]) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for point in points {
    positions.push(point)
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new_with_topology(
          positions,
          uvs,
          None,
          @mesh.Mesh3dPrimitiveTopology::LineStrip,
        ),
      ),
    ),
  )
}

///|
fn segment_mesh() -> @pbr.Mesh3d {
  line_strip_mesh([
    @math.Vec3::new(-0.5F, 0.0F, 0.0F),
    @math.Vec3::new(0.5F, 0.0F, 0.0F),
  ])
}

///|
fn append_extruded_polygon(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  points : Array[@math.Vec2],
  depth : Float,
) -> Unit {
  let count = points.length()
  if count < 3 {
    return
  }

  let mut min_x = points[0].x
  let mut max_x = points[0].x
  let mut min_y = points[0].y
  let mut max_y = points[0].y
  for point in points {
    min_x = min_float(min_x, point.x)
    max_x = max_float(max_x, point.x)
    min_y = min_float(min_y, point.y)
    max_y = max_float(max_y, point.y)
  }
  let span_x = max_float(max_x - min_x, 0.000001F)
  let span_y = max_float(max_y - min_y, 0.000001F)

  let half = depth / 2.0F
  let p0 = points[0]
  let uv0 = @math.Vec2::new((p0.x - min_x) / span_x, (p0.y - min_y) / span_y)

  for i in 1..<(count - 1) {
    let p1 = points[i]
    let p2 = points[i + 1]
    let uv1 = @math.Vec2::new((p1.x - min_x) / span_x, (p1.y - min_y) / span_y)
    let uv2 = @math.Vec2::new((p2.x - min_x) / span_x, (p2.y - min_y) / span_y)

    soup_push_triangle(
      positions,
      uvs,
      @math.Vec3::new(p0.x, p0.y, half),
      @math.Vec3::new(p1.x, p1.y, half),
      @math.Vec3::new(p2.x, p2.y, half),
      uv0,
      uv1,
      uv2,
    )

    soup_push_triangle(
      positions,
      uvs,
      @math.Vec3::new(p0.x, p0.y, -half),
      @math.Vec3::new(p2.x, p2.y, -half),
      @math.Vec3::new(p1.x, p1.y, -half),
      uv0,
      uv2,
      uv1,
    )
  }

  let mut perimeter = 0.0F
  for i in 0..<count {
    let next = if i + 1 < count { i + 1 } else { 0 }
    perimeter = perimeter + vec2_distance(points[i], points[next])
  }
  if perimeter <= 0.000001F {
    perimeter = 1.0F
  }

  let mut progressed = 0.0F
  for i in 0..<count {
    let next = if i + 1 < count { i + 1 } else { 0 }
    let p1 = points[i]
    let p2 = points[next]
    let edge_len = vec2_distance(p1, p2)
    let u0 = progressed / perimeter
    let u1 = (progressed + edge_len) / perimeter

    soup_push_quad(
      positions,
      uvs,
      @math.Vec3::new(p1.x, p1.y, half),
      @math.Vec3::new(p2.x, p2.y, half),
      @math.Vec3::new(p2.x, p2.y, -half),
      @math.Vec3::new(p1.x, p1.y, -half),
      @math.Vec2::new(u0, 0.0F),
      @math.Vec2::new(u1, 0.0F),
      @math.Vec2::new(u1, 1.0F),
      @math.Vec2::new(u0, 1.0F),
    )

    progressed = progressed + edge_len
  }
}

///|
fn extruded_polygon_mesh(
  points : Array[@math.Vec2],
  depth : Float,
) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  append_extruded_polygon(positions, uvs, points, depth)
  mesh_from_soup(positions, uvs)
}

///|
fn append_extruded_ring(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  outer : Array[@math.Vec2],
  inner : Array[@math.Vec2],
  depth : Float,
) -> Unit {
  let count = outer.length()
  if count < 3 || inner.length() != count {
    return
  }

  let half = depth / 2.0F
  for i in 0..<count {
    let next = if i + 1 < count { i + 1 } else { 0 }
    let o1 = outer[i]
    let o2 = outer[next]
    let i1 = inner[i]
    let i2 = inner[next]

    let u0 = float_from_int(i) / float_from_int(count)
    let u1 = float_from_int(i + 1) / float_from_int(count)

    soup_push_quad(
      positions,
      uvs,
      @math.Vec3::new(o1.x, o1.y, half),
      @math.Vec3::new(o2.x, o2.y, half),
      @math.Vec3::new(i2.x, i2.y, half),
      @math.Vec3::new(i1.x, i1.y, half),
      @math.Vec2::new(u0, 0.0F),
      @math.Vec2::new(u1, 0.0F),
      @math.Vec2::new(u1, 1.0F),
      @math.Vec2::new(u0, 1.0F),
    )

    soup_push_quad(
      positions,
      uvs,
      @math.Vec3::new(o1.x, o1.y, -half),
      @math.Vec3::new(i1.x, i1.y, -half),
      @math.Vec3::new(i2.x, i2.y, -half),
      @math.Vec3::new(o2.x, o2.y, -half),
      @math.Vec2::new(u0, 0.0F),
      @math.Vec2::new(u0, 1.0F),
      @math.Vec2::new(u1, 1.0F),
      @math.Vec2::new(u1, 0.0F),
    )

    soup_push_quad(
      positions,
      uvs,
      @math.Vec3::new(o1.x, o1.y, half),
      @math.Vec3::new(o2.x, o2.y, half),
      @math.Vec3::new(o2.x, o2.y, -half),
      @math.Vec3::new(o1.x, o1.y, -half),
      @math.Vec2::new(u0, 0.0F),
      @math.Vec2::new(u1, 0.0F),
      @math.Vec2::new(u1, 1.0F),
      @math.Vec2::new(u0, 1.0F),
    )

    soup_push_quad(
      positions,
      uvs,
      @math.Vec3::new(i2.x, i2.y, half),
      @math.Vec3::new(i1.x, i1.y, half),
      @math.Vec3::new(i1.x, i1.y, -half),
      @math.Vec3::new(i2.x, i2.y, -half),
      @math.Vec2::new(u0, 0.0F),
      @math.Vec2::new(u1, 0.0F),
      @math.Vec2::new(u1, 1.0F),
      @math.Vec2::new(u0, 1.0F),
    )
  }
}

///|
fn extruded_ring_mesh(
  outer : Array[@math.Vec2],
  inner : Array[@math.Vec2],
  depth : Float,
) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  append_extruded_ring(positions, uvs, outer, inner, depth)
  mesh_from_soup(positions, uvs)
}

///|
fn polyline_mesh() -> @pbr.Mesh3d {
  line_strip_mesh([
    @math.Vec3::new(-0.5F, 0.0F, 0.0F),
    @math.Vec3::new(0.5F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.5F, 0.0F),
  ])
}

///|
fn spawn_shape(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  x : Float,
  row : Row,
) -> Unit {
  let entity = @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(x, 2.0F, row_z(row)).with_rotation(
      @math.Quat::from_rotation_x(-PI / 4.0F),
    ),
  ).spawn(world)
  shapes_state.val.entries.push({ entity, row })
}

///|
fn setup(world : @ecs.World) -> Unit {
  shapes_state.val.entries.clear()
  shapes_state.val.rotating = true

  let debug_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(uv_debug_texture()),
    ),
  )

  let shapes = [
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_tetrahedron(1.0F)),
      ),
    ),
    capsule_mesh(0.5F, 0.5F, 8, 24),
    torus_mesh(0.65F, 0.25F, 36, 20),
    cylinder_mesh(0.5F, 1.0F, 28),
    cone_mesh(0.5F, 1.0F, 28),
    frustum_mesh(0.5F, 0.25F, 1.0F, 28),
    icosphere_mesh(0.5F, 2),
    sphere_uv_mesh(0.5F, 18, 32),
    segment_mesh(),
    polyline_mesh(),
  ]

  let shape_count = shapes.length()
  for i in 0..<shape_count {
    spawn_shape(
      world,
      shapes[i],
      debug_material,
      spacing_at(i, shape_count, SHAPES_X_EXTENT),
      Front,
    )
  }

  let capsule_outer = capsule_points(0.5F, 0.5F, 20)
  let capsule_inner = capsule_points(0.5F - THICKNESS, 0.5F - THICKNESS, 20)
  let circle_outer = circle_points(1.0F, 36)
  let circle_inner = circle_points(0.5F, 36)
  let small_circle_outer = circle_points(0.5F, 36)
  let small_circle_inner = circle_points(0.5F - THICKNESS, 36)
  let ellipse_outer = ellipse_points(0.5F, 0.3F, 36)
  let ellipse_inner = ellipse_points(0.5F - THICKNESS, 0.3F - THICKNESS, 36)
  let polygon_outer = regular_polygon_points(0.5F, 6)
  let polygon_inner = regular_polygon_points(0.5F - THICKNESS, 6)
  let triangle_outer = triangle_points()
  let triangle_inner = scale_points(triangle_outer, 0.75F)

  let extrusions = [
    extruded_polygon_mesh(rectangle_points(0.5F, 0.5F), 1.0F),
    extruded_polygon_mesh(capsule_outer, 1.0F),
    extruded_ring_mesh(circle_outer, circle_inner, 1.0F),
    extruded_polygon_mesh(small_circle_outer, 1.0F),
    extruded_polygon_mesh(ellipse_outer, 1.0F),
    extruded_polygon_mesh(polygon_outer, 1.0F),
    extruded_polygon_mesh(triangle_outer, 1.0F),
  ]

  let extrusion_count = extrusions.length()
  for i in 0..<extrusion_count {
    spawn_shape(
      world,
      extrusions[i],
      debug_material,
      spacing_at(i, extrusion_count, EXTRUSION_X_EXTENT),
      Middle,
    )
  }

  let ring_extrusions = [
    extruded_ring_mesh(
      rectangle_points(0.5F, 0.5F),
      rectangle_points(0.5F - THICKNESS, 0.5F - THICKNESS),
      1.0F,
    ),
    extruded_ring_mesh(capsule_outer, capsule_inner, 1.0F),
    extruded_ring_mesh(circle_outer, circle_inner, 1.0F),
    extruded_ring_mesh(small_circle_outer, small_circle_inner, 1.0F),
    extruded_ring_mesh(ellipse_outer, ellipse_inner, 1.0F),
    extruded_ring_mesh(polygon_outer, polygon_inner, 1.0F),
    extruded_ring_mesh(triangle_outer, triangle_inner, 1.0F),
  ]

  let ring_count = ring_extrusions.length()
  for i in 0..<ring_count {
    spawn_shape(
      world,
      ring_extrusions[i],
      debug_material,
      spacing_at(i, ring_count, EXTRUSION_X_EXTENT),
      Rear,
    )
  }

  let tick = world.read_change_tick()
  let point_light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 10_000_000.0F, 100.0F, true).with_shadow_depth_bias(
      0.2F,
    ),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(point_light, @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F), tick)

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(50.0F, 50.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  @text.Text2dBundle::new(
    @text.Text2d::new(
      "Press 'R' to pause/resume rotation\nPress 'Tab' to cycle through rows\nPress 'Space' to toggle wireframes",
    ),
    @text.TextFont::default().with_font(overlay_font).with_font_size(20.0F),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-390.0F, 300.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@sprite.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(780.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
}

///|
fn toggle_rotation(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    shapes_state.val.rotating = !shapes_state.val.rotating
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in 3d_shapes example")
  }
}

///|
fn rotate(world : @ecs.World) -> Unit {
  if !shapes_state.val.rotating {
    return
  }
  let delta = world_time(world).delta_seconds() / 2.0F
  let spin = @math.Quat::from_rotation_y(delta)
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  for entry in shapes_state.val.entries {
    if transform_store.get(entry.entity) is Some(transform) {
      let next = transform.with_rotation(
        transform.rotation.mul(spin).normalize(),
      )
      transform_store.set(entry.entity, next, tick) |> ignore
    }
  }
}

///|
fn advance_rows(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Tab) {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  let count = shapes_state.val.entries.length()
  for i in 0..<count {
    let entry = shapes_state.val.entries[i]
    let next_row = row_advance(entry.row)
    shapes_state.val.entries[i] = { ..entry, row: next_row }
    if transform_store.get(entry.entity) is Some(transform) {
      let next = transform.with_translation(
        @math.Vec3::new(
          transform.translation.x,
          transform.translation.y,
          row_z(next_row),
        ),
      )
      transform_store.set(entry.entity, next, tick) |> ignore
    }
  }
}

///|
fn toggle_wireframe(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  let config = try world.get_resource(@pbr.ecs_key_wireframe_config) catch {
    _ => @pbr.WireframeConfig::default().with_global(true)
  } noraise {
    Some(value) => value.with_global(!value.global)
    None => @pbr.WireframeConfig::default().with_global(true)
  }
  world.insert_resource(@pbr.ecs_key_wireframe_config, config)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@pbr.wireframe_plugin])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(toggle_rotation))
  .add_systems(@app.Update, @app.system(rotate))
  .add_systems(@app.Update, @app.system(advance_rows))
  .add_systems(@app.Update, @app.system(toggle_wireframe))
  .run()
}
