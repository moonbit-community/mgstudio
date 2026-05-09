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
pub fn capsule3d(radius : Float, length : Float) -> @math.Capsule3d {
  @math.Capsule3d::new(radius, length)
}

///|
pub fn capsule3d_unit() -> @math.Capsule3d {
  capsule3d(0.5, 1.0)
}

///|
pub fn capsule3d_mesh(shape : @math.Capsule3d) -> @mesh.Mesh3dGeometry {
  capsule3d_mesh_with_options(shape, 0, 32, 16)
}

///|
pub fn capsule3d_mesh_with_options(
  shape : @math.Capsule3d,
  rings : Int,
  longitudes : Int,
  latitudes : Int,
) -> @mesh.Mesh3dGeometry {
  let rings = if rings < 0 { 0 } else { rings }
  let longitudes = if longitudes < 3 { 3 } else { longitudes }
  let latitudes = if latitudes < 4 { 4 } else { latitudes }
  let radius = shape.radius
  let half_length = shape.half_length
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
  let to_theta = 2.0F * @math.pi() / primitive_f32(longitudes)
  let to_phi = @math.pi() / primitive_f32(latitudes)
  let to_tex_horizontal = 1.0F / primitive_f32(longitudes)
  let to_tex_vertical = 1.0F / primitive_f32(half_lats)
  let vt_aspect_ratio = radius / (2.0F * half_length + radius + radius)
  let vt_aspect_north = 1.0F - vt_aspect_ratio
  let vt_aspect_south = vt_aspect_ratio
  let theta_cartesian = Array::make(longitudes, @math.Vec2::new(0.0F, 0.0F))
  let rho_theta_cartesian = Array::make(longitudes, @math.Vec2::new(0.0F, 0.0F))
  let s_texture_cache = Array::make(lonsp1, 0.0F)

  for j in 0..<longitudes {
    let jf = primitive_f32(j)
    let s_texture_polar = 1.0F - (jf + 0.5F) * to_tex_horizontal
    let theta = jf * to_theta
    let tc = @math.Vec2::from_angle(theta)
    theta_cartesian[j] = tc
    rho_theta_cartesian[j] = tc.mul_scalar(radius)
    positions[j] = @math.Vec3::new(0.0F, summit, 0.0F)
    uvs[j] = @math.Vec2::new(s_texture_polar, 1.0F)
    normals[j] = @math.Vec3::new(0.0F, 1.0F, 0.0F)
    let south_index = vert_offset_south_cap + j
    positions[south_index] = @math.Vec3::new(0.0F, -summit, 0.0F)
    uvs[south_index] = @math.Vec2::new(s_texture_polar, 0.0F)
    normals[south_index] = @math.Vec3::new(0.0F, -1.0F, 0.0F)
  }

  for j in 0..<lonsp1 {
    let s_texture = 1.0F - primitive_f32(j) * to_tex_horizontal
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
    let ip1f = primitive_f32(i) + 1.0F
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
    let to_fac = 1.0F / primitive_f32(ringsp1)
    let mut idx_cyl_lat = vert_offset_cylinder
    for h in 1..<ringsp1 {
      let fac = primitive_f32(h) * to_fac
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

  primitive_geometry_with_normals(positions, normals, uvs, Some(indices))
}
