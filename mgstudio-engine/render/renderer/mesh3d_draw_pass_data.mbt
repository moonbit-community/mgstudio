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
fn mesh3d_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  tonemapping_view_uniform_bytes_full(
    pass_state,
    pass_state.camera_exposure,
    0U,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.25F,
    0.75F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  )
}

///|
fn mesh3d_lights_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(f32_bits(value))
}

///|
fn mesh3d_lights_push_u32(words : Array[UInt], value : UInt) -> Unit {
  words.push(value)
}

///|
fn mesh3d_lights_push_i32(words : Array[UInt], value : Int) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn mesh3d_lights_push_cascade(
  words : Array[UInt],
  cascade_data : Array[Float],
  cascade_index : Int,
) -> Unit {
  let base = cascade_index * 20
  for i in 0..<16 {
    if base + i < cascade_data.length() {
      mesh3d_lights_push_f32(words, cascade_data[base + i])
    } else {
      mesh3d_lights_push_f32(words, 0.0F)
    }
  }
  if base + 16 < cascade_data.length() {
    mesh3d_lights_push_f32(words, cascade_data[base + 16])
  } else {
    mesh3d_lights_push_f32(words, 0.0F)
  }
  if base + 17 < cascade_data.length() {
    mesh3d_lights_push_f32(words, cascade_data[base + 17])
  } else {
    mesh3d_lights_push_f32(words, 0.0F)
  }
  mesh3d_lights_push_f32(words, 0.0F)
  mesh3d_lights_push_f32(words, 0.0F)
}

///|
fn mesh3d_lights_push_directional_light(
  words : Array[UInt],
  pass_state : GpuPassState,
  directional_color_r : Float,
  directional_color_g : Float,
  directional_color_b : Float,
  directional_shadow_textured : Bool,
  light_index : Int,
) -> Unit {
  let is_active = light_index == 0 && pass_state.directional_illuminance > 0.0F
  let cascade_count = if is_active &&
    directional_shadow_textured &&
    pass_state.directional_shadow_enabled > 0.5F {
    if pass_state.directional_shadow_cascade_count < 0 {
      0
    } else if pass_state.directional_shadow_cascade_count > 4 {
      4
    } else {
      pass_state.directional_shadow_cascade_count
    }
  } else {
    0
  }
  for cascade_index in 0..<4 {
    if is_active && cascade_index < cascade_count {
      mesh3d_lights_push_cascade(
        words,
        pass_state.directional_shadow_cascade_data,
        cascade_index,
      )
    } else {
      mesh3d_lights_push_cascade(words, [], 0)
    }
  }
  if is_active {
    mesh3d_lights_push_f32(words, directional_color_r)
    mesh3d_lights_push_f32(words, directional_color_g)
    mesh3d_lights_push_f32(words, directional_color_b)
    mesh3d_lights_push_f32(words, 1.0F)
    mesh3d_lights_push_f32(words, pass_state.directional_dir_x)
    mesh3d_lights_push_f32(words, pass_state.directional_dir_y)
    mesh3d_lights_push_f32(words, pass_state.directional_dir_z)
    let flags = if cascade_count > 0 { 1U } else { 0U }
    mesh3d_lights_push_u32(words, flags)
    mesh3d_lights_push_f32(words, pass_state.directional_shadow_soft_size)
    mesh3d_lights_push_f32(words, pass_state.directional_shadow_depth_bias)
    mesh3d_lights_push_f32(words, pass_state.directional_shadow_normal_bias)
    mesh3d_lights_push_u32(words, cascade_count.reinterpret_as_uint())
    mesh3d_lights_push_f32(words, pass_state.directional_shadow_cascade_overlap)
    mesh3d_lights_push_u32(words, 0U)
    mesh3d_lights_push_i32(words, -1)
    mesh3d_lights_push_f32(words, 0.0F)
    mesh3d_lights_push_f32(words, 0.0F)
    mesh3d_lights_push_f32(words, 0.0F)
    mesh3d_lights_push_f32(words, 0.0F)
    mesh3d_lights_push_f32(words, 0.0F)
  } else {
    for _ in 0..<4 {
      mesh3d_lights_push_f32(words, 0.0F)
    }
    for _ in 0..<3 {
      mesh3d_lights_push_f32(words, 0.0F)
    }
    mesh3d_lights_push_u32(words, 0xFFFFU)
    for _ in 0..<3 {
      mesh3d_lights_push_f32(words, 0.0F)
    }
    mesh3d_lights_push_u32(words, 0U)
    mesh3d_lights_push_f32(words, 0.0F)
    mesh3d_lights_push_u32(words, 0U)
    mesh3d_lights_push_i32(words, -1)
    for _ in 0..<5 {
      mesh3d_lights_push_f32(words, 0.0F)
    }
  }
}

///|
fn mesh3d_lights_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  let transmission_source_enabled = pass_state.transmission_source_texture_id >=
    0
  let transmission_blur_taps = if transmission_source_enabled {
    pass_state.transmission_blur_taps
  } else {
    0.0F
  }
  let transmission_steps = if transmission_source_enabled {
    pass_state.transmission_steps
  } else {
    0.0F
  }
  let point_shadow_textured = pass_state.point_shadow_texture_id >= 0
  let point_shadow_enabled = if point_shadow_textured {
    pass_state.point_shadow_enabled
  } else {
    0.0F
  }
  let point_shadow_depth_bias = if point_shadow_textured {
    pass_state.point_shadow_depth_bias
  } else {
    0.0F
  }
  let point_shadow_near = if point_shadow_enabled > 0.5F {
    pass_state.point_shadow_near
  } else {
    0.1F
  }
  let environment_map_enabled = pass_state.environment_map_intensity > 0.0F &&
    pass_state.environment_diffuse_texture_id >= 0 &&
    pass_state.environment_specular_texture_id >= 0
  let environment_map_rotation_x = if environment_map_enabled {
    pass_state.environment_map_rotation_x
  } else {
    0.0F
  }
  let environment_map_rotation_y = if environment_map_enabled {
    pass_state.environment_map_rotation_y
  } else {
    0.0F
  }
  let environment_map_rotation_z = if environment_map_enabled {
    pass_state.environment_map_rotation_z
  } else {
    0.0F
  }
  let environment_map_rotation_w = if environment_map_enabled {
    pass_state.environment_map_rotation_w
  } else {
    1.0F
  }
  let ambient_brightness = if pass_state.ambient_brightness < 0.0F {
    0.0F
  } else {
    pass_state.ambient_brightness
  }
  let ambient_color_r = pass_state.ambient_r * ambient_brightness
  let ambient_color_g = pass_state.ambient_g * ambient_brightness
  let ambient_color_b = pass_state.ambient_b * ambient_brightness
  let camera_forward = mesh3d_quat_rotate_vec3(
    pass_state.camera_rot_x,
    pass_state.camera_rot_y,
    pass_state.camera_rot_z,
    pass_state.camera_rot_w,
    0.0F,
    0.0F,
    -1.0F,
  )
  let directional_illuminance = if pass_state.directional_illuminance < 0.0F {
    0.0F
  } else {
    pass_state.directional_illuminance
  }
  let directional_color_r = pass_state.directional_color_r *
    directional_illuminance
  let directional_color_g = pass_state.directional_color_g *
    directional_illuminance
  let directional_color_b = pass_state.directional_color_b *
    directional_illuminance
  let point_intensity = if pass_state.point_intensity < 0.0F {
    0.0F
  } else {
    pass_state.point_intensity
  }
  let point_color_r = pass_state.point_color_r * point_intensity
  let point_color_g = pass_state.point_color_g * point_intensity
  let point_color_b = pass_state.point_color_b * point_intensity
  let point_inverse_square_range = mesh3d_inverse_square_range(
    pass_state.point_range,
  )
  let spot_intensity = if pass_state.spot_intensity < 0.0F {
    0.0F
  } else {
    pass_state.spot_intensity
  }
  let spot_color_r = pass_state.spot_color_r * spot_intensity
  let spot_color_g = pass_state.spot_color_g * spot_intensity
  let spot_color_b = pass_state.spot_color_b * spot_intensity
  let spot_inverse_square_range = mesh3d_inverse_square_range(
    pass_state.spot_range,
  )
  let (spot_scale, spot_offset) = mesh3d_spot_scale_offset(
    pass_state.spot_inner_angle,
    pass_state.spot_outer_angle,
  )
  let environment_map_intensity = if environment_map_enabled {
    pass_state.environment_map_intensity
  } else {
    0.0F
  }
  let directional_shadow_textured = pass_state.directional_shadow_texture_id >=
    0
  let words : Array[UInt] = []
  for light_index in 0..<10 {
    mesh3d_lights_push_directional_light(
      words, pass_state, directional_color_r, directional_color_g, directional_color_b,
      directional_shadow_textured, light_index,
    )
  }
  mesh3d_lights_push_f32(words, ambient_color_r)
  mesh3d_lights_push_f32(words, ambient_color_g)
  mesh3d_lights_push_f32(words, ambient_color_b)
  mesh3d_lights_push_f32(words, 1.0F)
  mesh3d_lights_push_u32(words, 16U)
  mesh3d_lights_push_u32(words, 9U)
  mesh3d_lights_push_u32(words, 24U)
  mesh3d_lights_push_u32(words, 3456U)
  for _ in 0..<4 {
    mesh3d_lights_push_f32(words, 0.0F)
  }
  mesh3d_lights_push_u32(
    words,
    (if pass_state.directional_illuminance > 0.0F { 1 } else { 0 }).reinterpret_as_uint(),
  )
  mesh3d_lights_push_i32(words, 0)
  mesh3d_lights_push_u32(words, 0U)
  mesh3d_lights_push_u32(words, 0U)
  let values : Array[Float] = [
    pass_state.point_pos_x,
    pass_state.point_pos_y,
    pass_state.point_pos_z,
    pass_state.point_range,
    point_color_r,
    point_color_g,
    point_color_b,
    point_inverse_square_range,
    point_shadow_enabled,
    point_shadow_depth_bias,
    point_shadow_near,
    environment_map_rotation_w,
    pass_state.spot_pos_x,
    pass_state.spot_pos_y,
    pass_state.spot_pos_z,
    pass_state.spot_range,
    pass_state.spot_dir_x,
    pass_state.spot_dir_y,
    pass_state.spot_dir_z,
    0.0F,
    spot_color_r,
    spot_color_g,
    spot_color_b,
    spot_inverse_square_range,
    spot_scale,
    spot_offset,
    transmission_blur_taps,
    transmission_steps,
    environment_map_intensity,
    0.0F,
    0.0F,
    0.0F,
    environment_map_rotation_x,
    environment_map_rotation_y,
    environment_map_rotation_z,
    environment_map_rotation_w,
  ]
  values.push(
    if directional_shadow_textured {
      pass_state.directional_shadow_enabled
    } else {
      0.0F
    },
  )
  values.push(pass_state.directional_shadow_depth_bias)
  values.push(pass_state.directional_shadow_normal_bias)
  values.push(pass_state.directional_shadow_soft_size)
  values.push(
    Float::from_double(pass_state.directional_shadow_cascade_count.to_double()),
  )
  values.push(pass_state.directional_shadow_cascade_overlap)
  values.push(0.0F)
  values.push(0.0F)
  values.push(camera_forward.0)
  values.push(camera_forward.1)
  values.push(camera_forward.2)
  values.push(0.0F)
  let cascade_data = pass_state.directional_shadow_cascade_data
  for i in 0..<80 {
    if i < cascade_data.length() {
      values.push(cascade_data[i])
    } else {
      values.push(0.0F)
    }
  }
  for value in values {
    mesh3d_lights_push_f32(words, value)
  }
  u32le_pack(words)
}

///|
fn mesh3d_quat_rotate_vec3(
  qx : Float,
  qy : Float,
  qz : Float,
  qw : Float,
  vx : Float,
  vy : Float,
  vz : Float,
) -> (Float, Float, Float) {
  let tx = 2.0F * (qy * vz - qz * vy)
  let ty = 2.0F * (qz * vx - qx * vz)
  let tz = 2.0F * (qx * vy - qy * vx)
  (
    vx + qw * tx + (qy * tz - qz * ty),
    vy + qw * ty + (qz * tx - qx * tz),
    vz + qw * tz + (qx * ty - qy * tx),
  )
}

///|
fn mesh3d_inverse_square_range(range : Float) -> Float {
  let safe_range = if range < 0.0001F { 0.0001F } else { range }
  1.0F / (safe_range * safe_range)
}

///|
fn mesh3d_spot_scale_offset(
  inner_angle : Float,
  outer_angle : Float,
) -> (Float, Float) {
  let safe_inner_angle = if inner_angle < 0.0F { 0.0F } else { inner_angle }
  let safe_outer_angle = if outer_angle < safe_inner_angle + 0.0001F {
    safe_inner_angle + 0.0001F
  } else {
    outer_angle
  }
  let inner_cos = Float::from_double(
    @coremath.cos(safe_inner_angle.to_double()),
  )
  let outer_cos = Float::from_double(
    @coremath.cos(safe_outer_angle.to_double()),
  )
  let denom = if inner_cos - outer_cos < 0.0001F {
    0.0001F
  } else {
    inner_cos - outer_cos
  }
  let scale = 1.0F / denom
  let offset = -outer_cos * scale
  (scale, offset)
}

///|
fn mesh3d_mesh_uniform_words(
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  previous_x : Float,
  previous_y : Float,
  previous_z : Float,
  previous_rotation_x : Float,
  previous_rotation_y : Float,
  previous_rotation_z : Float,
  previous_rotation_w : Float,
  previous_scale_x : Float,
  previous_scale_y : Float,
  previous_scale_z : Float,
  current_skin_index : UInt,
  point_shadow_enabled : Float,
) -> Array[UInt] {
  let determinant = scale_x * scale_y * scale_z
  let mut flags = 0xFFFFU
  if point_shadow_enabled > 0.5F {
    flags = flags | (1U << 29)
  }
  if determinant >= 0.0F {
    flags = flags | (1U << 31)
  }
  let inverse_transpose = mesh3d_inverse_transpose_words(
    rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
  )
  let words : Array[UInt] = []
  for
    word in mesh3d_world_from_local_words(
      x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
      scale_z,
    ) {
    words.push(word)
  }
  for
    word in mesh3d_world_from_local_words(
      previous_x, previous_y, previous_z, previous_rotation_x, previous_rotation_y,
      previous_rotation_z, previous_rotation_w, previous_scale_x, previous_scale_y,
      previous_scale_z,
    ) {
    words.push(word)
  }
  for i in 0..<8 {
    words.push(inverse_transpose[i])
  }
  words.push(inverse_transpose[8])
  words.push(flags)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  words.push(current_skin_index)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  for _ in 0..<3 {
    words.push(0U)
  }
  words
}

///|
fn mesh3d_mesh_uniform_write(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  words : Array[UInt],
) -> Unit {
  let mut cursor = byte_offset
  for word in words {
    u32le_write_into_fixed(bytes, cursor, word)
    cursor += 4
  }
}

///|
fn mesh3d_draw_uniform_bytes(
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  uv_transform_mode : Float,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  current_skin_index : UInt,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
) -> Bytes {
  ignore(color_r)
  ignore(color_g)
  ignore(color_b)
  ignore(color_a)
  ignore(uv_transform_a)
  ignore(uv_transform_b)
  ignore(uv_transform_c)
  ignore(uv_transform_d)
  ignore(uv_transform_tx)
  ignore(uv_transform_ty)
  ignore(uv_transform_mode)
  ignore(emissive_r)
  ignore(emissive_g)
  ignore(emissive_b)
  ignore(metallic)
  ignore(roughness)
  ignore(reflectance)
  ignore(parallax_depth_scale)
  ignore(max_parallax_layer_count)
  ignore(max_relief_mapping_search_steps)
  ignore(anisotropy_strength)
  ignore(anisotropy_rotation)
  ignore(specular_tint_r)
  ignore(specular_tint_g)
  ignore(specular_tint_b)
  ignore(diffuse_transmission)
  ignore(specular_transmission)
  ignore(thickness)
  ignore(ior)
  ignore(alpha_cutoff)
  ignore(material_flags)
  ignore(point_shadow_depth_bias)
  let words = mesh3d_mesh_uniform_words(
    x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
    x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
    current_skin_index, point_shadow_enabled,
  )
  u32le_pack(words)
}

///|
fn mesh3d_standard_material_uniform_bytes(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
) -> Bytes {
  let reflectance_tint_r = reflectance * specular_tint_r
  let reflectance_tint_g = reflectance * specular_tint_g
  let reflectance_tint_b = reflectance * specular_tint_b
  let words : Array[UInt] = [
    f32_bits(color_r),
    f32_bits(color_g),
    f32_bits(color_b),
    f32_bits(color_a),
    f32_bits(emissive_r),
    f32_bits(emissive_g),
    f32_bits(emissive_b),
    f32_bits(0.0F),
    f32_bits(1.0F),
    f32_bits(1.0F),
    f32_bits(1.0F),
    f32_bits(1.0F),
    f32_bits(uv_transform_a),
    f32_bits(uv_transform_b),
    f32_bits(0.0F),
    0U,
    f32_bits(uv_transform_c),
    f32_bits(uv_transform_d),
    f32_bits(0.0F),
    0U,
    f32_bits(uv_transform_tx),
    f32_bits(uv_transform_ty),
    f32_bits(1.0F),
    0U,
    f32_bits(reflectance_tint_r),
    f32_bits(reflectance_tint_g),
    f32_bits(reflectance_tint_b),
    f32_bits(roughness),
    f32_bits(metallic),
    f32_bits(diffuse_transmission),
    f32_bits(specular_transmission),
    f32_bits(thickness),
    f32_bits(ior),
    f32_bits(1.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(anisotropy_strength),
    0U,
    f32_bits(cosf(anisotropy_rotation)),
    f32_bits(sinf(anisotropy_rotation)),
    material_flags,
    f32_bits(alpha_cutoff),
    f32_bits(parallax_depth_scale),
    f32_bits(max_parallax_layer_count),
    f32_bits(1.0F),
    max_relief_mapping_search_steps.to_int().reinterpret_as_uint(),
    1U,
    0U,
  ]
  u32le_pack(words)
}

///|
fn mesh3d_standard_material_default_uniform_bytes() -> Bytes {
  mesh3d_standard_material_uniform_bytes(
    1.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.5F, 0.5F, 0.1F, 16.0F, 5.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F,
    0.0F, 1.5F, 0.5F, 0U,
  )
}

///|
fn mesh3d_draw_uniform_write(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  uv_transform_mode : Float,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  current_skin_index : UInt,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
) -> Unit {
  ignore(color_r)
  ignore(color_g)
  ignore(color_b)
  ignore(color_a)
  ignore(uv_transform_a)
  ignore(uv_transform_b)
  ignore(uv_transform_c)
  ignore(uv_transform_d)
  ignore(uv_transform_tx)
  ignore(uv_transform_ty)
  ignore(uv_transform_mode)
  ignore(emissive_r)
  ignore(emissive_g)
  ignore(emissive_b)
  ignore(metallic)
  ignore(roughness)
  ignore(reflectance)
  ignore(parallax_depth_scale)
  ignore(max_parallax_layer_count)
  ignore(max_relief_mapping_search_steps)
  ignore(anisotropy_strength)
  ignore(anisotropy_rotation)
  ignore(specular_tint_r)
  ignore(specular_tint_g)
  ignore(specular_tint_b)
  ignore(diffuse_transmission)
  ignore(specular_transmission)
  ignore(thickness)
  ignore(ior)
  ignore(alpha_cutoff)
  ignore(material_flags)
  ignore(point_shadow_depth_bias)
  mesh3d_mesh_uniform_write(
    bytes,
    byte_offset,
    mesh3d_mesh_uniform_words(
      x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
      scale_z, x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x,
      scale_y, scale_z, current_skin_index, point_shadow_enabled,
    ),
  )
}

///|
fn mesh3d_normal_map_is_two_component_format(format_raw : UInt) -> Bool {
  format_raw == @wgpu.TEXTURE_FORMAT_RG8_UNORM ||
  format_raw == @wgpu.TEXTURE_FORMAT_BC5_RG_UNORM ||
  format_raw == @wgpu.TEXTURE_FORMAT_EACRG11_UNORM
}

///|
fn mesh3d_runtime_material_flags(
  material_flags : UInt,
  normal_texture_id : Int,
  normal_texture : GpuTextureInfo,
) -> UInt {
  if normal_texture_id < 0 {
    return material_flags
  }
  let mut runtime_flags = material_flags
  if mesh3d_normal_map_is_two_component_format(normal_texture.format_raw) {
    runtime_flags = runtime_flags | (1U << 6)
  }
  runtime_flags
}

///|
fn mesh3d_motion_vector_view_uniform_bytes(pass_state : GpuPassState) -> Bytes {
  tonemapping_view_uniform_bytes_full(
    pass_state, 1.0F, 0U, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F,
  )
}

///|
fn mesh3d_motion_vector_previous_view_uniform_bytes(
  pass_state : GpuPassState,
) -> Bytes {
  let identity = gpu_clip_matrix_identity()
  let words : Array[UInt] = []
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(pass_state.previous_clip_from_world) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  for word in gpu_clip_matrix_words(identity) {
    words.push(word)
  }
  u32le_pack(words)
}

///|
fn mesh3d_motion_vector_globals_uniform_bytes() -> Bytes {
  u32le_pack([0U, 0U, 0U, 0U])
}

///|
fn mesh3d_motion_vector_visibility_ranges_bytes() -> Bytes {
  u32le_pack([0U, 0U, 0U, 0U])
}

///|
fn load_wgsl_required_mesh3d_motion_vector_prepass(
  assets_base : String,
  skinned : Bool,
  has_previous_skin : Bool,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_FRAGMENT", true)
  defines.set("MOTION_VECTOR_PREPASS", true)
  if skinned {
    defines.set("SKINNED", true)
    if has_previous_skin {
      defines.set("HAS_PREVIOUS_SKIN", true)
    }
  }
  let value_defines = default_wgsl_value_defines()
  value_defines.remove("PER_OBJECT_BUFFER_BATCH_SIZE")
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "pbr/prepass/prepass.wgsl", defines, value_defines, visited, modules,
  )
}

///|
fn mesh3d_normalize_quat(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float) {
  let len_sq = x * x + y * y + z * z + w * w
  if len_sq <= 1.0e-8F {
    (0.0F, 0.0F, 0.0F, 1.0F)
  } else {
    let inv_len = 1.0F / Float::sqrt(len_sq)
    (x * inv_len, y * inv_len, z * inv_len, w * inv_len)
  }
}

///|
fn mesh3d_quat_rotation_matrix(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float, Float, Float, Float, Float, Float) {
  let (safe_x, safe_y, safe_z, safe_w) = mesh3d_normalize_quat(x, y, z, w)
  let xx = safe_x * safe_x
  let yy = safe_y * safe_y
  let zz = safe_z * safe_z
  let xy = safe_x * safe_y
  let xz = safe_x * safe_z
  let yz = safe_y * safe_z
  let wx = safe_w * safe_x
  let wy = safe_w * safe_y
  let wz = safe_w * safe_z
  (
    1.0F - 2.0F * (yy + zz),
    2.0F * (xy - wz),
    2.0F * (xz + wy),
    2.0F * (xy + wz),
    1.0F - 2.0F * (xx + zz),
    2.0F * (yz - wx),
    2.0F * (xz - wy),
    2.0F * (yz + wx),
    1.0F - 2.0F * (xx + yy),
  )
}

///|
fn mesh3d_world_from_local_words(
  translation_x : Float,
  translation_y : Float,
  translation_z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> Array[UInt] {
  let (m00, m01, m02, m10, m11, m12, m20, m21, m22) = mesh3d_quat_rotation_matrix(
    rotation_x, rotation_y, rotation_z, rotation_w,
  )
  let world_x_axis_x = m00 * scale_x
  let world_x_axis_y = m10 * scale_x
  let world_x_axis_z = m20 * scale_x
  let world_y_axis_x = m01 * scale_y
  let world_y_axis_y = m11 * scale_y
  let world_y_axis_z = m21 * scale_y
  let world_z_axis_x = m02 * scale_z
  let world_z_axis_y = m12 * scale_z
  let world_z_axis_z = m22 * scale_z
  [
    f32_bits(world_x_axis_x),
    f32_bits(world_y_axis_x),
    f32_bits(world_z_axis_x),
    f32_bits(translation_x),
    f32_bits(world_x_axis_y),
    f32_bits(world_y_axis_y),
    f32_bits(world_z_axis_y),
    f32_bits(translation_y),
    f32_bits(world_x_axis_z),
    f32_bits(world_y_axis_z),
    f32_bits(world_z_axis_z),
    f32_bits(translation_z),
  ]
}

///|
fn mesh3d_inverse_transpose_words(
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> Array[UInt] {
  let safe_scale_x = if scale_x == 0.0F { 1.0F } else { scale_x }
  let safe_scale_y = if scale_y == 0.0F { 1.0F } else { scale_y }
  let safe_scale_z = if scale_z == 0.0F { 1.0F } else { scale_z }
  let (m00, m01, m02, m10, m11, m12, m20, m21, m22) = mesh3d_quat_rotation_matrix(
    rotation_x, rotation_y, rotation_z, rotation_w,
  )
  [
    f32_bits(m00 / safe_scale_x),
    f32_bits(m10 / safe_scale_x),
    f32_bits(m20 / safe_scale_x),
    f32_bits(m01 / safe_scale_y),
    f32_bits(m11 / safe_scale_y),
    f32_bits(m21 / safe_scale_y),
    f32_bits(m02 / safe_scale_z),
    f32_bits(m12 / safe_scale_z),
    f32_bits(m22 / safe_scale_z),
  ]
}

///|
fn mesh3d_motion_vector_mesh_bytes(
  translation_x : Float,
  translation_y : Float,
  translation_z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  previous_translation_x : Float,
  previous_translation_y : Float,
  previous_translation_z : Float,
  previous_rotation_x : Float,
  previous_rotation_y : Float,
  previous_rotation_z : Float,
  previous_rotation_w : Float,
  previous_scale_x : Float,
  previous_scale_y : Float,
  previous_scale_z : Float,
  skinning_key_hi : Int,
) -> Bytes {
  let determinant = scale_x * scale_y * scale_z
  let mut flags = 0xFFFFU
  if determinant >= 0.0F {
    flags = flags | (1U << 31)
  }
  let current_skin_index = if skinning_key_hi >= 0 {
    skinning_key_hi.reinterpret_as_uint()
  } else {
    0xFFFFFFFFU
  }
  let inverse_transpose = mesh3d_inverse_transpose_words(
    rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
  )
  let words : Array[UInt] = []
  for
    word in mesh3d_world_from_local_words(
      translation_x, translation_y, translation_z, rotation_x, rotation_y, rotation_z,
      rotation_w, scale_x, scale_y, scale_z,
    ) {
    words.push(word)
  }
  for
    word in mesh3d_world_from_local_words(
      previous_translation_x, previous_translation_y, previous_translation_z, previous_rotation_x,
      previous_rotation_y, previous_rotation_z, previous_rotation_w, previous_scale_x,
      previous_scale_y, previous_scale_z,
    ) {
    words.push(word)
  }
  for i in 0..<8 {
    words.push(inverse_transpose[i])
  }
  words.push(inverse_transpose[8])
  words.push(flags)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  words.push(current_skin_index)
  words.push(0U)
  words.push(0U)
  words.push(0U)
  for _ in 0..<3 {
    words.push(0U)
  }
  u32le_pack(words)
}

///|
fn mesh3d_motion_vector_skin_buffers(
  backend : GpuBackend,
) -> (@wgpu.Buffer, @wgpu.Buffer)? {
  if !ensure_mesh3d_skin_buffers(backend, MESH3D_SKINNING_STORAGE_STRIDE_BYTES) {
    return None
  }
  guard backend.mesh3d_skin_current_buf is Some(current_skin_buf) else {
    return None
  }
  guard backend.mesh3d_skin_prev_buf is Some(prev_skin_buf) else { return None }
  Some((current_skin_buf, prev_skin_buf))
}

///|
fn create_mesh3d_motion_vector_mesh_bind_group(
  backend : GpuBackend,
  bgl : @wgpu.BindGroupLayout,
  mesh_buf : @wgpu.Buffer,
  mesh_buf_size : UInt64,
  label : String,
) -> @wgpu.BindGroup? {
  guard mesh3d_motion_vector_skin_buffers(backend)
    is Some((current_skin_buf, prev_skin_buf)) else {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=3UL)
  let ok = builder.add_buffer(0U, mesh_buf, size=mesh_buf_size) &&
    builder.add_buffer(1U, current_skin_buf, size=backend.mesh3d_skin_capacity) &&
    builder.add_buffer(6U, prev_skin_buf, size=backend.mesh3d_skin_capacity)
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(backend.device, bgl, label~))
}

///|
fn ensure_mesh3d_motion_vector_mesh_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard backend.mesh3d_motion_vector_bgl_mesh is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_motion_vector_mesh_slots.length() <= slot_index {
    let mesh_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_MESH_BUFFER_SIZE,
      usage~,
    )
    guard create_mesh3d_motion_vector_mesh_bind_group(
        backend,
        bgl,
        mesh_buf,
        MESH3D_PREPASS_MESH_BUFFER_SIZE,
        "mgstudio_motion_vector_mesh_slot_bg",
      )
      is Some(mesh_bg) else {
      return None
    }
    backend.mesh3d_motion_vector_mesh_slots.push(GpuStorageSlot::{
      buffer: mesh_buf,
      bind_group: mesh_bg,
    })
    backend.mesh3d_motion_vector_mesh_slot_skin_revisions.push(
      backend.mesh3d_skin_revision,
    )
  }
  if backend.mesh3d_motion_vector_mesh_slot_skin_revisions[slot_index] !=
    backend.mesh3d_skin_revision {
    let mesh_buf = backend.mesh3d_motion_vector_mesh_slots[slot_index].buffer
    guard create_mesh3d_motion_vector_mesh_bind_group(
        backend,
        bgl,
        mesh_buf,
        MESH3D_PREPASS_MESH_BUFFER_SIZE,
        "mgstudio_motion_vector_mesh_slot_bg",
      )
      is Some(mesh_bg) else {
      return None
    }
    backend.mesh3d_motion_vector_mesh_slots[slot_index] = GpuStorageSlot::{
      buffer: mesh_buf,
      bind_group: mesh_bg,
    }
    backend.mesh3d_motion_vector_mesh_slot_skin_revisions[slot_index] = backend.mesh3d_skin_revision
  }
  Some(backend.mesh3d_motion_vector_mesh_slots[slot_index])
}

///|
fn ensure_mesh3d_motion_vector_instance_mesh_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh3d_motion_vector_bgl_mesh is Some(bgl) else { return None }
  if !ensure_mesh3d_skin_buffers(backend, MESH3D_SKINNING_STORAGE_STRIDE_BYTES) {
    return None
  }
  if backend.mesh3d_motion_vector_instance_mesh_buf is Some(mesh_buf) &&
    backend.mesh3d_motion_vector_instance_mesh_bg is Some(mesh_bg) &&
    backend.mesh3d_motion_vector_instance_mesh_capacity >= required_size &&
    backend.mesh3d_motion_vector_instance_mesh_skin_revision ==
    backend.mesh3d_skin_revision {
    return Some((mesh_buf, mesh_bg))
  }
  let mesh_buf = if backend.mesh3d_motion_vector_instance_mesh_buf
    is Some(mesh_buf) &&
    backend.mesh3d_motion_vector_instance_mesh_capacity >= required_size {
    mesh_buf
  } else {
    let mut next_capacity = if backend.mesh3d_motion_vector_instance_mesh_capacity >
      0UL {
      backend.mesh3d_motion_vector_instance_mesh_capacity
    } else {
      MESH3D_PREPASS_MESH_BUFFER_SIZE * 16384UL
    }
    while next_capacity < required_size {
      next_capacity = next_capacity * 2UL
    }
    backend.mesh3d_motion_vector_instance_mesh_capacity = next_capacity
    let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
    backend.device.create_buffer(size=next_capacity, usage~)
  }
  guard create_mesh3d_motion_vector_mesh_bind_group(
      backend,
      bgl,
      mesh_buf,
      backend.mesh3d_motion_vector_instance_mesh_capacity,
      "mgstudio_motion_vector_instance_mesh_bg",
    )
    is Some(mesh_bg) else {
    return None
  }
  backend.mesh3d_motion_vector_instance_mesh_buf = Some(mesh_buf)
  backend.mesh3d_motion_vector_instance_mesh_bg = Some(mesh_bg)
  backend.mesh3d_motion_vector_instance_mesh_skin_revision = backend.mesh3d_skin_revision
  Some((mesh_buf, mesh_bg))
}

///|
