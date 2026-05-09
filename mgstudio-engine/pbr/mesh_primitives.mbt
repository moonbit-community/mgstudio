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
fn mesh3d_f32(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn mesh3d_geometry_with_normals(
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
fn mesh3d_geometry_with_normals_and_topology(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
  topology : @mesh.Mesh3dPrimitiveTopology,
) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new_with_topology(positions, uvs, indices, topology).with_custom_attribute_vec3(
    @mesh.MESH3D_ATTRIBUTE_NORMAL_NAME,
    normals,
  )
}

///|
fn mesh3d_default_uvs(count : Int) -> Array[@math.Vec2] {
  let uvs : Array[@math.Vec2] = []
  for _ in 0..<count {
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  uvs
}

///|
fn mesh3d_push_face_vertex(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  position : @math.Vec3,
  normal : @math.Vec3,
  uv : @math.Vec2,
) -> Unit {
  positions.push(position)
  normals.push(normal)
  uvs.push(uv)
}

///|
fn mesh3d_geometry_primitive_cuboid(
  cuboid : @math.Cuboid,
) -> @mesh.Mesh3dGeometry {
  let x = cuboid.half_size.x
  let y = cuboid.half_size.y
  let z = cuboid.half_size.z
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let left = @math.Vec3::new(-1.0F, 0.0F, 0.0F)
  let right = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let down = @math.Vec3::new(0.0F, -1.0F, 0.0F)
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let back = @math.Vec3::new(0.0F, 0.0F, -1.0F)
  let forward = @math.Vec3::new(0.0F, 0.0F, 1.0F)

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, z),
    forward,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, z),
    forward,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, z),
    forward,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, z),
    forward,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, -z),
    back,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, -z),
    back,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, -z),
    back,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, -z),
    back,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, z),
    up,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, z),
    up,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, -z),
    up,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, -z),
    up,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, -z),
    down,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, -z),
    down,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, z),
    down,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, z),
    down,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, z),
    right,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, -y, -z),
    right,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, -z),
    right,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(x, y, z),
    right,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, -z),
    left,
    @math.Vec2::new(0.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, -y, z),
    left,
    @math.Vec2::new(1.0F, 1.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, z),
    left,
    @math.Vec2::new(1.0F, 0.0F),
  )
  mesh3d_push_face_vertex(
    positions,
    normals,
    uvs,
    @math.Vec3::new(-x, y, -z),
    left,
    @math.Vec2::new(0.0F, 0.0F),
  )

  mesh3d_geometry_with_normals(
    positions,
    normals,
    uvs,
    Some([
      0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 8, 9, 10, 10, 11, 8, 12, 13, 14, 14, 15,
      12, 16, 17, 18, 18, 19, 16, 20, 21, 22, 22, 23, 20,
    ]),
  )
}

///|
pub fn mesh3d_geometry_plane_subdivisions(
  width : Float,
  depth : Float,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry {
  let safe_width = if width <= 0.0F { 1.0F } else { width }
  let safe_depth = if depth <= 0.0F { 1.0F } else { depth }
  let safe_subdivisions = if subdivisions < 0 { 0 } else { subdivisions }
  let z_vertex_count = safe_subdivisions + 2
  let x_vertex_count = safe_subdivisions + 2
  let num_vertices = z_vertex_count * x_vertex_count
  let num_indices = (z_vertex_count - 1) * (x_vertex_count - 1) * 6
  let quad_width = safe_width / mesh3d_f32(x_vertex_count - 1)
  let quad_depth = safe_depth / mesh3d_f32(z_vertex_count - 1)
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for z in 0..<z_vertex_count {
    for x in 0..<x_vertex_count {
      positions.push(
        @math.Vec3::new(
          -safe_width * 0.5F + mesh3d_f32(x) * quad_width,
          0.0F,
          -safe_depth * 0.5F + mesh3d_f32(z) * quad_depth,
        ),
      )
      normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
      uvs.push(
        @math.Vec2::new(
          mesh3d_f32(x) / mesh3d_f32(x_vertex_count - 1),
          mesh3d_f32(z) / mesh3d_f32(z_vertex_count - 1),
        ),
      )
    }
  }
  for z in 0..<(z_vertex_count - 1) {
    for x in 0..<(x_vertex_count - 1) {
      let quad = z * x_vertex_count + x
      indices.push(quad + x_vertex_count + 1)
      indices.push(quad + 1)
      indices.push(quad + x_vertex_count)
      indices.push(quad)
      indices.push(quad + x_vertex_count)
      indices.push(quad + 1)
    }
  }
  let _ = num_vertices
  let _ = num_indices
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn mesh3d_geometry_primitive_uv_sphere(
  radius : Float,
  sectors : Int,
  stacks : Int,
) -> @mesh.Mesh3dGeometry {
  let safe_radius = if radius <= 0.0F { 0.5F } else { radius }
  let safe_sectors = if sectors < 3 { 3 } else { sectors }
  let safe_stacks = if stacks < 2 { 2 } else { stacks }
  let sector_count = mesh3d_f32(safe_sectors)
  let stack_count = mesh3d_f32(safe_stacks)
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let length_inv = 1.0F / safe_radius
  for i in 0..<(safe_stacks + 1) {
    let stack_angle = @math.pi() / 2.0F -
      mesh3d_f32(i) * @math.pi() / stack_count
    let xy = safe_radius * @math.cos(stack_angle)
    let z = safe_radius * @math.sin(stack_angle)
    for j in 0..<(safe_sectors + 1) {
      let sector_angle = mesh3d_f32(j) * 2.0F * @math.pi() / sector_count
      let x = xy * @math.cos(sector_angle)
      let y = xy * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      normals.push(
        @math.Vec3::new(x * length_inv, y * length_inv, z * length_inv),
      )
      uvs.push(
        @math.Vec2::new(
          mesh3d_f32(j) / sector_count,
          mesh3d_f32(i) / stack_count,
        ),
      )
    }
  }
  for i in 0..<safe_stacks {
    let k1 = i * (safe_sectors + 1)
    let k2 = k1 + safe_sectors + 1
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
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn mesh3d_geometry_primitive_icosphere(
  radius : Float,
  subdivisions : Int,
) -> @mesh.Mesh3dGeometry {
  let geometry = @mesh.Mesh3dGeometry::icosphere(radius, subdivisions)
  let normals : Array[@math.Vec3] = []
  for index in 0..<geometry.vertex_count() {
    match geometry.vertex_position(index) {
      Some(position) => normals.push(position.normalize_or_zero())
      None => normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    }
  }
  geometry.with_custom_attribute_vec3(
    @mesh.MESH3D_ATTRIBUTE_NORMAL_NAME,
    normals,
  )
}

///|
fn mesh3d_geometry_primitive_cylinder(
  cylinder : @math.Cylinder,
) -> @mesh.Mesh3dGeometry {
  let radius = if cylinder.radius <= 0.0F { 0.5F } else { cylinder.radius }
  let half_height = if cylinder.half_height <= 0.0F {
    0.5F
  } else {
    cylinder.half_height
  }
  let resolution = 32
  let segments = 1
  let rings = segments + 1
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let rings_f = mesh3d_f32(rings)
  for ring in 0..<(rings + 1) {
    let v = mesh3d_f32(ring) / rings_f
    let y = -half_height + v * half_height * 2.0F
    for i in 0..<(resolution + 1) {
      let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
      let (sin, cos) = (@math.sin(theta), @math.cos(theta))
      positions.push(@math.Vec3::new(radius * cos, y, radius * sin))
      normals.push(@math.Vec3::new(cos, 0.0F, sin))
      uvs.push(
        @math.Vec2::new(
          mesh3d_f32(i) / mesh3d_f32(resolution),
          1.0F - mesh3d_f32(ring) / rings_f,
        ),
      )
    }
  }
  let vertices_around = resolution + 1
  for ring_segment in 0..<segments {
    let ring_start = ring_segment * vertices_around
    let next_ring_start = (ring_segment + 1) * vertices_around
    for i in 0..<resolution {
      indices.push(ring_start + i)
      indices.push(next_ring_start + i)
      indices.push(ring_start + i + 1)
      indices.push(ring_start + i + 1)
      indices.push(next_ring_start + i)
      indices.push(next_ring_start + i + 1)
    }
  }
  let top_center = positions.length()
  positions.push(@math.Vec3::new(0.0F, half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  let top_start = positions.length()
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(@math.Vec3::new(radius * cos, half_height, radius * sin))
    normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    uvs.push(@math.Vec2::new((cos + 1.0F) * 0.5F, (sin + 1.0F) * 0.5F))
  }
  for i in 0..<resolution {
    indices.push(top_center)
    indices.push(top_start + i)
    indices.push(top_start + i + 1)
  }
  let bottom_center = positions.length()
  positions.push(@math.Vec3::new(0.0F, -half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  let bottom_start = positions.length()
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(@math.Vec3::new(radius * cos, -half_height, radius * sin))
    normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
    uvs.push(@math.Vec2::new((cos + 1.0F) * 0.5F, (sin + 1.0F) * 0.5F))
  }
  for i in 0..<resolution {
    indices.push(bottom_center)
    indices.push(bottom_start + i + 1)
    indices.push(bottom_start + i)
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn mesh3d_geometry_primitive_capsule(
  capsule : @math.Capsule3d,
) -> @mesh.Mesh3dGeometry {
  let radius = if capsule.radius <= 0.0F { 0.5F } else { capsule.radius }
  let half_length = if capsule.half_length < 0.0F {
    0.0F
  } else {
    capsule.half_length
  }
  let rings = 0
  let longitudes = 32
  let latitudes = 16
  let calc_middle = rings > 0
  let half_lats = latitudes / 2
  let half_latsn1 = half_lats - 1
  let half_latsn2 = half_lats - 2
  let ringsp1 = rings + 1
  let lonsp1 = longitudes + 1
  let summit = half_length + radius
  let vert_offset_north_hemi = longitudes
  let vert_offset_north_equator = vert_offset_north_hemi + lonsp1 * half_latsn1
  let vert_offset_cylinder = vert_offset_north_equator + lonsp1
  let vert_offset_south_equator = if calc_middle {
    vert_offset_cylinder + lonsp1 * rings
  } else {
    vert_offset_cylinder
  }
  let vert_offset_south_hemi = vert_offset_south_equator + lonsp1
  let vert_offset_south_polar = vert_offset_south_hemi + lonsp1 * half_latsn2
  let vert_offset_south_cap = vert_offset_south_polar + lonsp1
  let vert_len = vert_offset_south_cap + longitudes
  let positions = Array::make(vert_len, @math.Vec3::new(0.0F, 0.0F, 0.0F))
  let uvs = Array::make(vert_len, @math.Vec2::new(0.0F, 0.0F))
  let normals = Array::make(vert_len, @math.Vec3::new(0.0F, 0.0F, 0.0F))
  let to_theta = 2.0F * @math.pi() / mesh3d_f32(longitudes)
  let to_phi = @math.pi() / mesh3d_f32(latitudes)
  let to_tex_horizontal = 1.0F / mesh3d_f32(longitudes)
  let to_tex_vertical = 1.0F / mesh3d_f32(half_lats)
  let vt_aspect_ratio = radius / (2.0F * half_length + radius + radius)
  let vt_aspect_north = 1.0F - vt_aspect_ratio
  let vt_aspect_south = vt_aspect_ratio
  let theta_cartesian = Array::make(longitudes, @math.Vec2::new(0.0F, 0.0F))
  let rho_theta_cartesian = Array::make(longitudes, @math.Vec2::new(0.0F, 0.0F))
  let s_texture_cache = Array::make(lonsp1, 0.0F)

  for j in 0..<longitudes {
    let jf = mesh3d_f32(j)
    let s_texture_polar = 1.0F - (jf + 0.5F) * to_tex_horizontal
    let theta = jf * to_theta
    let tc = @math.Vec2::new(@math.cos(theta), @math.sin(theta))
    theta_cartesian[j] = tc
    rho_theta_cartesian[j] = @math.Vec2::new(radius * tc.x, radius * tc.y)
    positions[j] = @math.Vec3::new(0.0F, summit, 0.0F)
    uvs[j] = @math.Vec2::new(s_texture_polar, 1.0F)
    normals[j] = @math.Vec3::new(0.0F, 1.0F, 0.0F)
    let south_index = vert_offset_south_cap + j
    positions[south_index] = @math.Vec3::new(0.0F, -summit, 0.0F)
    uvs[south_index] = @math.Vec2::new(s_texture_polar, 0.0F)
    normals[south_index] = @math.Vec3::new(0.0F, -1.0F, 0.0F)
  }

  for j in 0..<lonsp1 {
    let s_texture = 1.0F - mesh3d_f32(j) * to_tex_horizontal
    s_texture_cache[j] = s_texture
    let j_mod = j % longitudes
    let tc = theta_cartesian[j_mod]
    let rtc = rho_theta_cartesian[j_mod]
    let north_index = vert_offset_north_equator + j
    positions[north_index] = @math.Vec3::new(rtc.x, half_length, -rtc.y)
    uvs[north_index] = @math.Vec2::new(s_texture, vt_aspect_north)
    normals[north_index] = @math.Vec3::new(tc.x, 0.0F, -tc.y)
    let south_index = vert_offset_south_equator + j
    positions[south_index] = @math.Vec3::new(rtc.x, -half_length, -rtc.y)
    uvs[south_index] = @math.Vec2::new(s_texture, vt_aspect_south)
    normals[south_index] = @math.Vec3::new(tc.x, 0.0F, -tc.y)
  }

  for i in 0..<half_latsn1 {
    let ip1f = mesh3d_f32(i) + 1.0F
    let phi = ip1f * to_phi
    let sin_phi_south = @math.sin(phi)
    let cos_phi_south = @math.cos(phi)
    let cos_phi_north = sin_phi_south
    let sin_phi_north = -cos_phi_south
    let rho_cos_phi_north = radius * cos_phi_north
    let rho_sin_phi_north = radius * sin_phi_north
    let z_offset_north = half_length - rho_sin_phi_north
    let rho_cos_phi_south = radius * cos_phi_south
    let rho_sin_phi_south = radius * sin_phi_south
    let z_offset_south = -half_length - rho_sin_phi_south
    let t_tex_fac = ip1f * to_tex_vertical
    let cmpl_tex_fac = 1.0F - t_tex_fac
    let t_tex_north = cmpl_tex_fac + vt_aspect_north * t_tex_fac
    let t_tex_south = cmpl_tex_fac * vt_aspect_south
    let i_lonsp1 = i * lonsp1
    let vert_curr_lat_north = vert_offset_north_hemi + i_lonsp1
    let vert_curr_lat_south = vert_offset_south_hemi + i_lonsp1
    for j in 0..<lonsp1 {
      let j_mod = j % longitudes
      let tc = theta_cartesian[j_mod]
      let north_index = vert_curr_lat_north + j
      positions[north_index] = @math.Vec3::new(
        rho_cos_phi_north * tc.x,
        z_offset_north,
        -rho_cos_phi_north * tc.y,
      )
      uvs[north_index] = @math.Vec2::new(s_texture_cache[j], t_tex_north)
      normals[north_index] = @math.Vec3::new(
        cos_phi_north * tc.x,
        -sin_phi_north,
        -cos_phi_north * tc.y,
      )
      let south_index = vert_curr_lat_south + j
      positions[south_index] = @math.Vec3::new(
        rho_cos_phi_south * tc.x,
        z_offset_south,
        -rho_cos_phi_south * tc.y,
      )
      uvs[south_index] = @math.Vec2::new(s_texture_cache[j], t_tex_south)
      normals[south_index] = @math.Vec3::new(
        cos_phi_south * tc.x,
        -sin_phi_south,
        -cos_phi_south * tc.y,
      )
    }
  }

  if calc_middle {
    let to_fac = 1.0F / mesh3d_f32(ringsp1)
    let mut idx_cyl_lat = vert_offset_cylinder
    for h in 1..<ringsp1 {
      let fac = mesh3d_f32(h) * to_fac
      let cmpl_fac = 1.0F - fac
      let t_texture = cmpl_fac * vt_aspect_north + fac * vt_aspect_south
      let z = half_length - 2.0F * half_length * fac
      for j in 0..<lonsp1 {
        let j_mod = j % longitudes
        let tc = theta_cartesian[j_mod]
        let rtc = rho_theta_cartesian[j_mod]
        positions[idx_cyl_lat] = @math.Vec3::new(rtc.x, z, -rtc.y)
        uvs[idx_cyl_lat] = @math.Vec2::new(s_texture_cache[j], t_texture)
        normals[idx_cyl_lat] = @math.Vec3::new(tc.x, 0.0F, -tc.y)
        idx_cyl_lat = idx_cyl_lat + 1
      }
    }
  }

  let lons3 = longitudes * 3
  let lons6 = longitudes * 6
  let hemi_lons = half_latsn1 * lons6
  let tri_offset_north_hemi = lons3
  let tri_offset_cylinder = tri_offset_north_hemi + hemi_lons
  let tri_offset_south_hemi = tri_offset_cylinder + ringsp1 * lons6
  let tri_offset_south_cap = tri_offset_south_hemi + hemi_lons
  let indices = Array::make(tri_offset_south_cap + lons3, 0)
  let mut i = 0
  let mut k = 0
  let mut m = tri_offset_south_cap
  while i < longitudes {
    indices[k] = i
    indices[k + 1] = vert_offset_north_hemi + i
    indices[k + 2] = vert_offset_north_hemi + i + 1
    indices[m] = vert_offset_south_cap + i
    indices[m + 1] = vert_offset_south_polar + i + 1
    indices[m + 2] = vert_offset_south_polar + i
    i = i + 1
    k = k + 3
    m = m + 3
  }

  i = 0
  k = tri_offset_north_hemi
  m = tri_offset_south_hemi
  while i < half_latsn1 {
    let i_lonsp1 = i * lonsp1
    let vert_curr_lat_north = vert_offset_north_hemi + i_lonsp1
    let vert_next_lat_north = vert_curr_lat_north + lonsp1
    let vert_curr_lat_south = vert_offset_south_equator + i_lonsp1
    let vert_next_lat_south = vert_curr_lat_south + lonsp1
    let mut j = 0
    while j < longitudes {
      let north00 = vert_curr_lat_north + j
      let north01 = vert_next_lat_north + j
      let north11 = vert_next_lat_north + j + 1
      let north10 = vert_curr_lat_north + j + 1
      indices[k] = north00
      indices[k + 1] = north11
      indices[k + 2] = north10
      indices[k + 3] = north00
      indices[k + 4] = north01
      indices[k + 5] = north11
      let south00 = vert_curr_lat_south + j
      let south01 = vert_next_lat_south + j
      let south11 = vert_next_lat_south + j + 1
      let south10 = vert_curr_lat_south + j + 1
      indices[m] = south00
      indices[m + 1] = south11
      indices[m + 2] = south10
      indices[m + 3] = south00
      indices[m + 4] = south01
      indices[m + 5] = south11
      j = j + 1
      k = k + 6
      m = m + 6
    }
    i = i + 1
  }

  i = 0
  k = tri_offset_cylinder
  while i < ringsp1 {
    let vert_curr_lat = vert_offset_north_equator + i * lonsp1
    let vert_next_lat = vert_curr_lat + lonsp1
    let mut j = 0
    while j < longitudes {
      let cy00 = vert_curr_lat + j
      let cy01 = vert_next_lat + j
      let cy11 = vert_next_lat + j + 1
      let cy10 = vert_curr_lat + j + 1
      indices[k] = cy00
      indices[k + 1] = cy11
      indices[k + 2] = cy10
      indices[k + 3] = cy00
      indices[k + 4] = cy01
      indices[k + 5] = cy11
      j = j + 1
      k = k + 6
    }
    i = i + 1
  }

  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn mesh3d_geometry_cone(cone : @math.Cone) -> @mesh.Mesh3dGeometry {
  let radius = if cone.radius <= 0.0F { 0.5F } else { cone.radius }
  let height = if cone.height <= 0.0F { 1.0F } else { cone.height }
  let half_height = height * 0.5F
  let resolution = 32
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let normal_y = radius / height
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(@math.Vec3::new(0.0F, half_height, 0.0F))
    normals.push(@math.Vec3::new(0.0F, 0.0F, 0.0F))
    uvs.push(@math.Vec2::new(mesh3d_f32(i) / mesh3d_f32(resolution), 0.0F))
    positions.push(@math.Vec3::new(radius * cos, -half_height, radius * sin))
    normals.push(@math.Vec3::new(cos, normal_y, sin).normalize_or_zero())
    uvs.push(@math.Vec2::new(mesh3d_f32(i) / mesh3d_f32(resolution), 1.0F))
  }
  for i in 0..<resolution {
    let top0 = i * 2
    let bottom0 = top0 + 1
    let top1 = top0 + 2
    let bottom1 = top0 + 3
    indices.push(top0)
    indices.push(bottom0)
    indices.push(top1)
    indices.push(top1)
    indices.push(bottom0)
    indices.push(bottom1)
  }
  let center = positions.length()
  positions.push(@math.Vec3::new(0.0F, -half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  let start = positions.length()
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(@math.Vec3::new(radius * cos, -half_height, radius * sin))
    normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
    uvs.push(@math.Vec2::new((cos + 1.0F) * 0.5F, (sin + 1.0F) * 0.5F))
  }
  for i in 0..<resolution {
    indices.push(center)
    indices.push(start + i + 1)
    indices.push(start + i)
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn mesh3d_geometry_conical_frustum(
  frustum : @math.ConicalFrustum,
) -> @mesh.Mesh3dGeometry {
  let radius_top = if frustum.radius_top < 0.0F {
    0.0F
  } else {
    frustum.radius_top
  }
  let radius_bottom = if frustum.radius_bottom < 0.0F {
    0.0F
  } else {
    frustum.radius_bottom
  }
  let height = if frustum.height <= 0.0F { 1.0F } else { frustum.height }
  let half_height = height * 0.5F
  let resolution = 32
  let slope = (radius_bottom - radius_top) / height
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    let normal = @math.Vec3::new(cos, slope, sin).normalize_or_zero()
    positions.push(
      @math.Vec3::new(radius_top * cos, half_height, radius_top * sin),
    )
    normals.push(normal)
    uvs.push(@math.Vec2::new(mesh3d_f32(i) / mesh3d_f32(resolution), 0.0F))
    positions.push(
      @math.Vec3::new(radius_bottom * cos, -half_height, radius_bottom * sin),
    )
    normals.push(normal)
    uvs.push(@math.Vec2::new(mesh3d_f32(i) / mesh3d_f32(resolution), 1.0F))
  }
  for i in 0..<resolution {
    let top0 = i * 2
    let bottom0 = top0 + 1
    let top1 = top0 + 2
    let bottom1 = top0 + 3
    indices.push(top0)
    indices.push(bottom0)
    indices.push(top1)
    indices.push(top1)
    indices.push(bottom0)
    indices.push(bottom1)
  }
  let top_center = positions.length()
  positions.push(@math.Vec3::new(0.0F, half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  let top_start = positions.length()
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(
      @math.Vec3::new(radius_top * cos, half_height, radius_top * sin),
    )
    normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    uvs.push(@math.Vec2::new((cos + 1.0F) * 0.5F, (sin + 1.0F) * 0.5F))
  }
  for i in 0..<resolution {
    indices.push(top_center)
    indices.push(top_start + i)
    indices.push(top_start + i + 1)
  }
  let bottom_center = positions.length()
  positions.push(@math.Vec3::new(0.0F, -half_height, 0.0F))
  normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  let bottom_start = positions.length()
  for i in 0..<(resolution + 1) {
    let theta = 2.0F * @math.pi() * mesh3d_f32(i) / mesh3d_f32(resolution)
    let (sin, cos) = (@math.sin(theta), @math.cos(theta))
    positions.push(
      @math.Vec3::new(radius_bottom * cos, -half_height, radius_bottom * sin),
    )
    normals.push(@math.Vec3::new(0.0F, -1.0F, 0.0F))
    uvs.push(@math.Vec2::new((cos + 1.0F) * 0.5F, (sin + 1.0F) * 0.5F))
  }
  for i in 0..<resolution {
    indices.push(bottom_center)
    indices.push(bottom_start + i + 1)
    indices.push(bottom_start + i)
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn mesh3d_geometry_torus(torus : @math.Torus) -> @mesh.Mesh3dGeometry {
  let major_radius = if torus.major_radius <= 0.0F {
    0.5F
  } else {
    torus.major_radius
  }
  let minor_radius = if torus.minor_radius <= 0.0F {
    0.25F
  } else {
    torus.minor_radius
  }
  let major_segments = 32
  let minor_segments = 24
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for major_index in 0..<(major_segments + 1) {
    let theta = 2.0F *
      @math.pi() *
      mesh3d_f32(major_index) /
      mesh3d_f32(major_segments)
    let center = @math.Vec3::new(
      major_radius * @math.cos(theta),
      0.0F,
      major_radius * @math.sin(theta),
    )
    for minor_index in 0..<(minor_segments + 1) {
      let phi = 2.0F *
        @math.pi() *
        mesh3d_f32(minor_index) /
        mesh3d_f32(minor_segments)
      let radial = major_radius + minor_radius * @math.cos(phi)
      let position = @math.Vec3::new(
        radial * @math.cos(theta),
        minor_radius * @math.sin(phi),
        radial * @math.sin(theta),
      )
      positions.push(position)
      normals.push(
        @math.Vec3::new(
          position.x - center.x,
          position.y - center.y,
          position.z - center.z,
        ).normalize_or_zero(),
      )
      uvs.push(
        @math.Vec2::new(
          mesh3d_f32(major_index) / mesh3d_f32(major_segments),
          mesh3d_f32(minor_index) / mesh3d_f32(minor_segments),
        ),
      )
    }
  }
  let columns = minor_segments + 1
  for major_index in 0..<major_segments {
    for minor_index in 0..<minor_segments {
      let lt = major_index * columns + minor_index
      let rt = (major_index + 1) * columns + minor_index
      let lb = lt + 1
      let rb = rt + 1
      indices.push(lt)
      indices.push(rt)
      indices.push(lb)
      indices.push(rt)
      indices.push(rb)
      indices.push(lb)
    }
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
pub fn mesh3d_geometry_segment3d(
  segment : @math.Segment3d,
) -> @mesh.Mesh3dGeometry {
  let positions = [segment.point1(), segment.point2()]
  mesh3d_geometry_with_normals_and_topology(
    positions,
    [@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F)],
    mesh3d_default_uvs(2),
    Some([0, 1]),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
pub fn mesh3d_geometry_polyline3d(
  polyline : @math.Polyline3d,
) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  for vertex in polyline.vertices {
    positions.push(vertex)
    normals.push(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  let indices : Array[Int] = []
  if positions.length() >= 2 {
    for index in 0..<(positions.length() - 1) {
      indices.push(index)
      indices.push(index + 1)
    }
  }
  mesh3d_geometry_with_normals_and_topology(
    positions,
    normals,
    mesh3d_default_uvs(positions.length()),
    Some(indices),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
fn mesh3d_polygon_normal(points : Array[@math.Vec2]) -> Float {
  let count = points.length()
  let mut area = 0.0F
  if count >= 3 {
    for i in 0..<count {
      let a = points[i]
      let b = points[(i + 1) % count]
      area = area + a.x * b.y - b.x * a.y
    }
  }
  if area >= 0.0F {
    1.0F
  } else {
    -1.0F
  }
}

///|
fn mesh3d_push_extrusion_side(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int],
  a : @math.Vec2,
  b : @math.Vec2,
  half_depth : Float,
  perimeter_start : Float,
  perimeter_end : Float,
) -> Unit {
  let normal = @math.Vec3::new(b.y - a.y, a.x - b.x, 0.0F).normalize_or_zero()
  let base = positions.length()
  positions.push(@math.Vec3::new(a.x, a.y, half_depth))
  positions.push(@math.Vec3::new(b.x, b.y, half_depth))
  positions.push(@math.Vec3::new(a.x, a.y, -half_depth))
  positions.push(@math.Vec3::new(b.x, b.y, -half_depth))
  normals.push(normal)
  normals.push(normal)
  normals.push(normal)
  normals.push(normal)
  uvs.push(@math.Vec2::new(perimeter_start, 0.5F))
  uvs.push(@math.Vec2::new(perimeter_end, 0.5F))
  uvs.push(@math.Vec2::new(perimeter_start, 1.0F))
  uvs.push(@math.Vec2::new(perimeter_end, 1.0F))
  indices.push(base)
  indices.push(base + 2)
  indices.push(base + 1)
  indices.push(base + 1)
  indices.push(base + 2)
  indices.push(base + 3)
}

///|
fn mesh3d_polygon_perimeter(points : Array[@math.Vec2]) -> Float {
  let count = points.length()
  let mut perimeter = 0.0F
  if count >= 2 {
    for i in 0..<count {
      let a = points[i]
      let b = points[(i + 1) % count]
      let dx = b.x - a.x
      let dy = b.y - a.y
      perimeter = perimeter + @math.sqrt(dx * dx + dy * dy)
    }
  }
  if perimeter <= 0.0F {
    1.0F
  } else {
    perimeter
  }
}

///|
fn mesh3d_geometry_extrude_polygon_points(
  points : Array[@math.Vec2],
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let count = points.length()
  if count < 3 {
    return @mesh.Mesh3dGeometry::new([], [], None)
  }
  let half_depth = if depth <= 0.0F { 0.5F } else { depth * 0.5F }
  let winding = mesh3d_polygon_normal(points)
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for point in points {
    positions.push(@math.Vec3::new(point.x, point.y, half_depth))
    normals.push(@math.Vec3::new(0.0F, 0.0F, winding))
    uvs.push(@math.Vec2::new(0.5F + point.x * 0.5F, 0.5F - point.y * 0.5F))
  }
  for i in 1..<(count - 1) {
    if winding > 0.0F {
      indices.push(0)
      indices.push(i)
      indices.push(i + 1)
    } else {
      indices.push(0)
      indices.push(i + 1)
      indices.push(i)
    }
  }
  let back_start = positions.length()
  for point in points {
    positions.push(@math.Vec3::new(point.x, point.y, -half_depth))
    normals.push(@math.Vec3::new(0.0F, 0.0F, -winding))
    uvs.push(@math.Vec2::new(1.0F + point.x * 0.5F, 0.5F - point.y * 0.5F))
  }
  for i in 1..<(count - 1) {
    if winding > 0.0F {
      indices.push(back_start)
      indices.push(back_start + i + 1)
      indices.push(back_start + i)
    } else {
      indices.push(back_start)
      indices.push(back_start + i)
      indices.push(back_start + i + 1)
    }
  }
  let perimeter = mesh3d_polygon_perimeter(points)
  let mut distance = 0.0F
  for i in 0..<count {
    let a = points[i]
    let b = points[(i + 1) % count]
    let dx = b.x - a.x
    let dy = b.y - a.y
    let segment_length = @math.sqrt(dx * dx + dy * dy)
    let next_distance = distance + segment_length
    mesh3d_push_extrusion_side(
      positions,
      normals,
      uvs,
      indices,
      a,
      b,
      half_depth,
      distance / perimeter,
      next_distance / perimeter,
    )
    distance = next_distance
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn mesh3d_geometry_extrude_ring_points(
  outer : Array[@math.Vec2],
  inner : Array[@math.Vec2],
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let count = if outer.length() < inner.length() {
    outer.length()
  } else {
    inner.length()
  }
  if count < 3 {
    return @mesh.Mesh3dGeometry::new([], [], None)
  }
  let half_depth = if depth <= 0.0F { 0.5F } else { depth * 0.5F }
  let positions : Array[@math.Vec3] = []
  let normals : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for i in 0..<count {
    let o = outer[i]
    let p = inner[i]
    positions.push(@math.Vec3::new(o.x, o.y, half_depth))
    positions.push(@math.Vec3::new(p.x, p.y, half_depth))
    normals.push(@math.Vec3::new(0.0F, 0.0F, 1.0F))
    normals.push(@math.Vec3::new(0.0F, 0.0F, 1.0F))
    uvs.push(@math.Vec2::new(0.5F + o.x * 0.5F, 0.5F - o.y * 0.5F))
    uvs.push(@math.Vec2::new(0.5F + p.x * 0.5F, 0.5F - p.y * 0.5F))
  }
  for i in 0..<count {
    let next = (i + 1) % count
    let outer0 = i * 2
    let inner0 = outer0 + 1
    let outer1 = next * 2
    let inner1 = outer1 + 1
    indices.push(outer0)
    indices.push(inner0)
    indices.push(outer1)
    indices.push(outer1)
    indices.push(inner0)
    indices.push(inner1)
  }
  let back_start = positions.length()
  for i in 0..<count {
    let o = outer[i]
    let p = inner[i]
    positions.push(@math.Vec3::new(o.x, o.y, -half_depth))
    positions.push(@math.Vec3::new(p.x, p.y, -half_depth))
    normals.push(@math.Vec3::new(0.0F, 0.0F, -1.0F))
    normals.push(@math.Vec3::new(0.0F, 0.0F, -1.0F))
    uvs.push(@math.Vec2::new(1.0F + o.x * 0.5F, 0.5F - o.y * 0.5F))
    uvs.push(@math.Vec2::new(1.0F + p.x * 0.5F, 0.5F - p.y * 0.5F))
  }
  for i in 0..<count {
    let next = (i + 1) % count
    let outer0 = back_start + i * 2
    let inner0 = outer0 + 1
    let outer1 = back_start + next * 2
    let inner1 = outer1 + 1
    indices.push(outer0)
    indices.push(outer1)
    indices.push(inner0)
    indices.push(outer1)
    indices.push(inner1)
    indices.push(inner0)
  }
  let outer_perimeter = mesh3d_polygon_perimeter(outer)
  let inner_perimeter = mesh3d_polygon_perimeter(inner)
  let mut outer_distance = 0.0F
  let mut inner_distance = 0.0F
  for i in 0..<count {
    let next = (i + 1) % count
    let a = outer[i]
    let b = outer[next]
    let dx = b.x - a.x
    let dy = b.y - a.y
    let next_outer_distance = outer_distance + @math.sqrt(dx * dx + dy * dy)
    mesh3d_push_extrusion_side(
      positions,
      normals,
      uvs,
      indices,
      a,
      b,
      half_depth,
      outer_distance / outer_perimeter,
      next_outer_distance / outer_perimeter,
    )
    outer_distance = next_outer_distance
    let ia = inner[next]
    let ib = inner[i]
    let idx = ib.x - ia.x
    let idy = ib.y - ia.y
    let next_inner_distance = inner_distance + @math.sqrt(idx * idx + idy * idy)
    mesh3d_push_extrusion_side(
      positions,
      normals,
      uvs,
      indices,
      ia,
      ib,
      half_depth,
      inner_distance / inner_perimeter,
      next_inner_distance / inner_perimeter,
    )
    inner_distance = next_inner_distance
  }
  mesh3d_geometry_with_normals(positions, normals, uvs, Some(indices))
}

///|
fn mesh3d_circle_points(radius : Float, resolution : Int) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let safe_resolution = if resolution < 3 { 3 } else { resolution }
  for i in 0..<safe_resolution {
    let angle = @math.pi() / 2.0F -
      mesh3d_f32(i) * 2.0F * @math.pi() / mesh3d_f32(safe_resolution)
    points.push(
      @math.Vec2::new(radius * @math.cos(angle), radius * @math.sin(angle)),
    )
  }
  points
}

///|
fn mesh3d_ellipse_points(
  half_size : @math.Vec2,
  resolution : Int,
) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let safe_resolution = if resolution < 3 { 3 } else { resolution }
  for i in 0..<safe_resolution {
    let angle = @math.pi() / 2.0F -
      mesh3d_f32(i) * 2.0F * @math.pi() / mesh3d_f32(safe_resolution)
    points.push(
      @math.Vec2::new(
        half_size.x * @math.cos(angle),
        half_size.y * @math.sin(angle),
      ),
    )
  }
  points
}

///|
fn mesh3d_rectangle_points(rectangle : @math.Rectangle) -> Array[@math.Vec2] {
  let hx = rectangle.half_size.x
  let hy = rectangle.half_size.y
  [
    @math.Vec2::new(hx, hy),
    @math.Vec2::new(-hx, hy),
    @math.Vec2::new(-hx, -hy),
    @math.Vec2::new(hx, -hy),
  ]
}

///|
fn mesh3d_regular_polygon_points(
  polygon : @math.RegularPolygon,
) -> Array[@math.Vec2] {
  mesh3d_circle_points(polygon.radius, polygon.sides)
}

///|
fn mesh3d_triangle_points(triangle : @math.Triangle2d) -> Array[@math.Vec2] {
  [triangle.a, triangle.b, triangle.c]
}

///|
fn mesh3d_capsule2d_points(capsule : @math.Capsule2d) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let segments = if capsule.segments < 4 { 16 } else { capsule.segments }
  let half = if capsule.half_length < 0.0F { 0.0F } else { capsule.half_length }
  let radius = if capsule.radius <= 0.0F { 0.5F } else { capsule.radius }
  let top_segments = segments / 2
  let bottom_segments = segments - top_segments
  for i in 0..<(top_segments + 1) {
    let angle = mesh3d_f32(i) * @math.pi() / mesh3d_f32(top_segments)
    points.push(
      @math.Vec2::new(
        radius * @math.cos(angle),
        half + radius * @math.sin(angle),
      ),
    )
  }
  for i in 0..<(bottom_segments + 1) {
    let angle = @math.pi() +
      mesh3d_f32(i) * @math.pi() / mesh3d_f32(bottom_segments)
    points.push(
      @math.Vec2::new(
        radius * @math.cos(angle),
        -half + radius * @math.sin(angle),
      ),
    )
  }
  points
}

///|
pub fn mesh3d_geometry_extrusion_rectangle(
  rectangle : @math.Rectangle,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_rectangle_points(rectangle),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_capsule2d(
  capsule : @math.Capsule2d,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_capsule2d_points(capsule),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_circle(
  circle : @math.Circle,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_circle_points(circle.radius, circle.vertices),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_ellipse(
  ellipse : @math.Ellipse,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_ellipse_points(ellipse.half_size, ellipse.vertices),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_regular_polygon(
  polygon : @math.RegularPolygon,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_regular_polygon_points(polygon),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_triangle2d(
  triangle : @math.Triangle2d,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_polygon_points(
    mesh3d_triangle_points(triangle),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_annulus(
  annulus : @math.Annulus,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_ring_points(
    mesh3d_circle_points(annulus.outer_radius, annulus.vertices),
    mesh3d_circle_points(annulus.inner_radius, annulus.vertices),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_ring2d(
  ring : @math.Ring2d,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_ring_points(
    mesh3d_circle_points(ring.outer_radius, 32),
    mesh3d_circle_points(ring.inner_radius, 32),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_rectangle_ring(
  rectangle : @math.Rectangle,
  thickness : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let inner = @math.Rectangle::new(
    if rectangle.half_size.x * 2.0F - thickness * 2.0F <= 0.0F {
      0.000001F
    } else {
      rectangle.half_size.x * 2.0F - thickness * 2.0F
    },
    if rectangle.half_size.y * 2.0F - thickness * 2.0F <= 0.0F {
      0.000001F
    } else {
      rectangle.half_size.y * 2.0F - thickness * 2.0F
    },
  )
  mesh3d_geometry_extrude_ring_points(
    mesh3d_rectangle_points(rectangle),
    mesh3d_rectangle_points(inner),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_capsule2d_ring(
  capsule : @math.Capsule2d,
  thickness : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let inner = @math.Capsule2d::new(
    if capsule.radius - thickness <= 0.0F {
      0.000001F
    } else {
      capsule.radius - thickness
    },
    if capsule.half_length - thickness <= 0.0F {
      0.0F
    } else {
      capsule.half_length - thickness
    },
  )
  mesh3d_geometry_extrude_ring_points(
    mesh3d_capsule2d_points(capsule),
    mesh3d_capsule2d_points(inner),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_circle_ring(
  circle : @math.Circle,
  thickness : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_ring_points(
    mesh3d_circle_points(circle.radius, circle.vertices),
    mesh3d_circle_points(
      if circle.radius - thickness <= 0.0F {
        0.000001F
      } else {
        circle.radius - thickness
      },
      circle.vertices,
    ),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_ellipse_ring(
  ellipse : @math.Ellipse,
  thickness : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let inner_half_size = @math.Vec2::new(
    if ellipse.half_size.x - thickness <= 0.0F {
      0.000001F
    } else {
      ellipse.half_size.x - thickness
    },
    if ellipse.half_size.y - thickness <= 0.0F {
      0.000001F
    } else {
      ellipse.half_size.y - thickness
    },
  )
  mesh3d_geometry_extrude_ring_points(
    mesh3d_ellipse_points(ellipse.half_size, ellipse.vertices),
    mesh3d_ellipse_points(inner_half_size, ellipse.vertices),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_regular_polygon_ring(
  polygon : @math.RegularPolygon,
  thickness : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let inner = @math.RegularPolygon::new(
    if polygon.radius - thickness <= 0.0F {
      0.000001F
    } else {
      polygon.radius - thickness
    },
    polygon.sides,
  )
  mesh3d_geometry_extrude_ring_points(
    mesh3d_regular_polygon_points(polygon),
    mesh3d_regular_polygon_points(inner),
    depth,
  )
}

///|
pub fn mesh3d_geometry_extrusion_triangle2d_ring(
  triangle : @math.Triangle2d,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  mesh3d_geometry_extrude_ring_points(
    mesh3d_triangle_points(triangle),
    [
      @math.Vec2::new(triangle.a.x * 0.75F, triangle.a.y * 0.75F),
      @math.Vec2::new(triangle.b.x * 0.75F, triangle.b.y * 0.75F),
      @math.Vec2::new(triangle.c.x * 0.75F, triangle.c.y * 0.75F),
    ],
    depth,
  )
}
