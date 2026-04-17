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
  let environment_map_intensity = if environment_map_enabled {
    pass_state.environment_map_intensity
  } else {
    0.0F
  }
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
  f32le_pack([
    pass_state.camera_x,
    pass_state.camera_y,
    pass_state.camera_z,
    1.0F,
    pass_state.clip_from_world.x_axis_x,
    pass_state.clip_from_world.x_axis_y,
    pass_state.clip_from_world.x_axis_z,
    pass_state.clip_from_world.x_axis_w,
    pass_state.clip_from_world.y_axis_x,
    pass_state.clip_from_world.y_axis_y,
    pass_state.clip_from_world.y_axis_z,
    pass_state.clip_from_world.y_axis_w,
    pass_state.clip_from_world.z_axis_x,
    pass_state.clip_from_world.z_axis_y,
    pass_state.clip_from_world.z_axis_z,
    pass_state.clip_from_world.z_axis_w,
    pass_state.clip_from_world.w_axis_x,
    pass_state.clip_from_world.w_axis_y,
    pass_state.clip_from_world.w_axis_z,
    pass_state.clip_from_world.w_axis_w,
    pass_state.camera_exposure,
    environment_map_intensity,
    0.0F,
    0.0F,
    ambient_color_r,
    ambient_color_g,
    ambient_color_b,
    environment_map_rotation_x,
    pass_state.directional_dir_x,
    pass_state.directional_dir_y,
    pass_state.directional_dir_z,
    environment_map_rotation_y,
    directional_color_r,
    directional_color_g,
    directional_color_b,
    environment_map_rotation_z,
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
  ])
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
  let reflectance_tint_r = reflectance * specular_tint_r
  let reflectance_tint_g = reflectance * specular_tint_g
  let reflectance_tint_b = reflectance * specular_tint_b
  let words : Array[UInt] = [
    f32_bits(x),
    f32_bits(y),
    f32_bits(z),
    f32_bits(1.0F),
    f32_bits(rotation_x),
    f32_bits(rotation_y),
    f32_bits(rotation_z),
    f32_bits(rotation_w),
    f32_bits(scale_x),
    f32_bits(scale_y),
    f32_bits(scale_z),
    f32_bits(1.0F),
    f32_bits(color_r),
    f32_bits(color_g),
    f32_bits(color_b),
    f32_bits(color_a),
    f32_bits(emissive_r),
    f32_bits(emissive_g),
    f32_bits(emissive_b),
    f32_bits(1.0F),
    f32_bits(uv_transform_a),
    f32_bits(uv_transform_b),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(uv_transform_c),
    f32_bits(uv_transform_d),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(uv_transform_tx),
    f32_bits(uv_transform_ty),
    f32_bits(1.0F),
    f32_bits(0.0F),
    f32_bits(reflectance_tint_r),
    f32_bits(reflectance_tint_g),
    f32_bits(reflectance_tint_b),
    f32_bits(roughness),
    f32_bits(metallic),
    f32_bits(diffuse_transmission),
    f32_bits(specular_transmission),
    f32_bits(thickness),
    f32_bits(ior),
    f32_bits(anisotropy_strength),
    f32_bits(cosf(anisotropy_rotation)),
    f32_bits(sinf(anisotropy_rotation)),
    material_flags,
    f32_bits(alpha_cutoff),
    f32_bits(parallax_depth_scale),
    f32_bits(max_parallax_layer_count),
    max_relief_mapping_search_steps.to_int().reinterpret_as_uint(),
    f32_bits(uv_transform_mode),
    f32_bits(point_shadow_enabled),
    f32_bits(point_shadow_depth_bias),
    current_skin_index,
    0U,
    0U,
    0U,
  ]
  u32le_pack(words)
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
  let reflectance_tint_r = reflectance * specular_tint_r
  let reflectance_tint_g = reflectance * specular_tint_g
  let reflectance_tint_b = reflectance * specular_tint_b
  let cos_anisotropy_rotation = cosf(anisotropy_rotation)
  let sin_anisotropy_rotation = sinf(anisotropy_rotation)
  let mut cursor = byte_offset
  f32le_write_into_fixed(bytes, cursor, x)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, y)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, z)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 1.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, rotation_x)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, rotation_y)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, rotation_z)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, rotation_w)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, scale_x)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, scale_y)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, scale_z)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 1.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, color_r)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, color_g)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, color_b)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, color_a)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, emissive_r)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, emissive_g)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, emissive_b)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 1.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_a)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_b)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 0.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 0.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_c)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_d)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 0.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 0.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_tx)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_ty)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 1.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, 0.0F)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, reflectance_tint_r)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, reflectance_tint_g)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, reflectance_tint_b)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, roughness)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, metallic)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, diffuse_transmission)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, specular_transmission)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, thickness)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, ior)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, anisotropy_strength)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, cos_anisotropy_rotation)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, sin_anisotropy_rotation)
  cursor += 4
  u32le_write_into_fixed(bytes, cursor, material_flags)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, alpha_cutoff)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, parallax_depth_scale)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, max_parallax_layer_count)
  cursor += 4
  u32le_write_into_fixed(
    bytes,
    cursor,
    max_relief_mapping_search_steps.to_int().reinterpret_as_uint(),
  )
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, uv_transform_mode)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, point_shadow_enabled)
  cursor += 4
  f32le_write_into_fixed(bytes, cursor, point_shadow_depth_bias)
  cursor += 4
  u32le_write_into_fixed(bytes, cursor, current_skin_index)
  cursor += 4
  u32le_write_into_fixed(bytes, cursor, 0U)
  cursor += 4
  u32le_write_into_fixed(bytes, cursor, 0U)
  cursor += 4
  u32le_write_into_fixed(bytes, cursor, 0U)
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
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_FRAGMENT", true)
  defines.set("MOTION_VECTOR_PREPASS", true)
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
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      mesh_buf,
      size=MESH3D_PREPASS_MESH_BUFFER_SIZE,
    )
    if !ok {
      builder.free()
      return None
    }
    let mesh_bg = builder.finish(
      backend.device,
      bgl,
      label="mgstudio_motion_vector_mesh_slot_bg",
    )
    backend.mesh3d_motion_vector_mesh_slots.push(GpuStorageSlot::{
      buffer: mesh_buf,
      bind_group: mesh_bg,
    })
  }
  Some(backend.mesh3d_motion_vector_mesh_slots[slot_index])
}

///|
fn ensure_mesh3d_motion_vector_instance_mesh_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh3d_motion_vector_bgl_mesh is Some(bgl) else { return None }
  if backend.mesh3d_motion_vector_instance_mesh_buf is Some(mesh_buf) &&
    backend.mesh3d_motion_vector_instance_mesh_bg is Some(mesh_bg) &&
    backend.mesh3d_motion_vector_instance_mesh_capacity >= required_size {
    return Some((mesh_buf, mesh_bg))
  }
  let mut next_capacity = if backend.mesh3d_motion_vector_instance_mesh_capacity >
    0UL {
    backend.mesh3d_motion_vector_instance_mesh_capacity
  } else {
    MESH3D_PREPASS_MESH_BUFFER_SIZE * 16384UL
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let mesh_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, mesh_buf, size=next_capacity)
  if !ok {
    builder.free()
    return None
  }
  let mesh_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_motion_vector_instance_mesh_bg",
  )
  backend.mesh3d_motion_vector_instance_mesh_buf = Some(mesh_buf)
  backend.mesh3d_motion_vector_instance_mesh_bg = Some(mesh_bg)
  backend.mesh3d_motion_vector_instance_mesh_capacity = next_capacity
  Some((mesh_buf, mesh_bg))
}

///|
