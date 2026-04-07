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
fn ensure_mesh3d_draw_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard backend.mesh3d_bgl_draw is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_draw_slots.length() <= slot_index {
    let draw_buf = backend.device.create_buffer(
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
      usage~,
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      draw_buf,
      size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    )
    if !ok {
      builder.free()
      return None
    }
    let draw_bg = builder.finish(
      backend.device,
      bgl,
      label="mgstudio_mesh3d_draw_slot_bg",
    )
    backend.mesh3d_draw_slots.push(GpuStorageSlot::{
      buffer: draw_buf,
      bind_group: draw_bg,
    })
  }
  Some(backend.mesh3d_draw_slots[slot_index])
}

///|
fn ensure_mesh3d_instance_draw_binding(
  backend : GpuBackend,
  required_size : UInt64,
) -> (@wgpu.Buffer, @wgpu.BindGroup)? {
  guard backend.mesh3d_bgl_draw is Some(bgl) else { return None }
  if backend.mesh3d_instance_draw_buf is Some(draw_buf) &&
    backend.mesh3d_instance_draw_bg is Some(draw_bg) &&
    backend.mesh3d_instance_draw_capacity >= required_size {
    return Some((draw_buf, draw_bg))
  }
  let mut next_capacity = if backend.mesh3d_instance_draw_capacity > 0UL {
    backend.mesh3d_instance_draw_capacity
  } else {
    MESH3D_DRAW_STORAGE_STRIDE_BYTES * 16384UL
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let draw_buf = backend.device.create_buffer(size=next_capacity, usage~)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, draw_buf, size=next_capacity)
  if !ok {
    builder.free()
    return None
  }
  let draw_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh3d_instance_draw_bg",
  )
  // Keep old buffer/bind group alive: commands recorded earlier in this frame
  // may still reference them when capacity grows mid-frame.
  backend.mesh3d_instance_draw_buf = Some(draw_buf)
  backend.mesh3d_instance_draw_bg = Some(draw_bg)
  backend.mesh3d_instance_draw_capacity = next_capacity
  Some((draw_buf, draw_bg))
}

///|
fn mesh3d_identity_rows(matrix_count : Int) -> Array[Float] {
  let identity_rows : Array[Float] = []
  for _ in 0..<matrix_count {
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(0.0F)
    identity_rows.push(1.0F)
  }
  identity_rows
}

///|
fn ensure_mesh3d_skin_slot(
  backend : GpuBackend,
  slot_index : Int,
) -> GpuStorageSlot? {
  guard backend.mesh3d_bgl_skin is Some(bgl) else { return None }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  while backend.mesh3d_skin_slots.length() <= slot_index {
    let skin_buf = backend.device.create_buffer(
      size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
      usage~,
    )
    let matrix_count = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 64UL).to_int()
    backend.queue.write_buffer(
      skin_buf,
      0UL,
      f32le_pack(mesh3d_identity_rows(matrix_count)),
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(
      0U,
      skin_buf,
      size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
    )
    if !ok {
      builder.free()
      return None
    }
    let skin_bg = builder.finish(
      backend.device,
      bgl,
      label="mgstudio_mesh3d_skin_slot_bg",
    )
    backend.mesh3d_skin_slots.push(GpuStorageSlot::{
      buffer: skin_buf,
      bind_group: skin_bg,
    })
  }
  Some(backend.mesh3d_skin_slots[slot_index])
}

///|
fn ensure_mesh3d_skin_default_binding(backend : GpuBackend) -> @wgpu.BindGroup? {
  guard backend.mesh3d_bgl_skin is Some(bgl) else { return None }
  if backend.mesh3d_skin_default_bg is Some(bg) {
    return Some(bg)
  }
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST)
  let skin_buf = backend.device.create_buffer(
    size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
    usage~,
  )
  let matrix_count = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 64UL).to_int()
  backend.queue.write_buffer(
    skin_buf,
    0UL,
    f32le_pack(mesh3d_identity_rows(matrix_count)),
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    skin_buf,
    size=MESH3D_SKINNING_STORAGE_STRIDE_BYTES,
  )
  if !ok {
    builder.free()
    return None
  }
  let skin_bg = builder.finish(
    backend.device,
    bgl,
    label="mgstudio_mesh3d_skin_default_bg",
  )
  backend.mesh3d_skin_default_buf = Some(skin_buf)
  backend.mesh3d_skin_default_bg = Some(skin_bg)
  Some(skin_bg)
}

///|
fn mesh3d_skin_slot_cache_key(key_hi : Int, key_lo : Int) -> UInt64 {
  let hi = key_hi.reinterpret_as_uint().to_uint64()
  let lo = key_lo.reinterpret_as_uint().to_uint64() & 0xffffffffUL
  (hi << 32) | lo
}

///|
fn mesh3d_skin_bind_group_for_key(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> @wgpu.BindGroup? {
  let key = mesh3d_skin_slot_cache_key(key_hi, key_lo)
  guard backend.mesh3d_skin_slot_indices_by_key.get(key) is Some(slot_index) else {
    return None
  }
  guard slot_index >= 0 && slot_index < backend.mesh3d_skin_slots.length() else {
    return None
  }
  Some(backend.mesh3d_skin_slots[slot_index].bind_group)
}

///|
fn mesh3d_upload_skinning_matrices(
  backend : GpuBackend,
  target_buffer : @wgpu.Buffer,
  skinning_matrices : Array[Float],
) -> Unit {
  let max_values = (MESH3D_SKINNING_STORAGE_STRIDE_BYTES / 4UL).to_int()
  let upload_len = if skinning_matrices.length() < max_values {
    skinning_matrices.length()
  } else {
    max_values
  }
  if upload_len <= 0 {
    return
  }
  let upload_values = if upload_len == skinning_matrices.length() {
    skinning_matrices
  } else {
    let clipped : Array[Float] = []
    for i in 0..<upload_len {
      clipped.push(skinning_matrices[i])
    }
    clipped
  }
  backend.queue.write_buffer(target_buffer, 0UL, f32le_pack(upload_values))
}

///|
pub fn GpuBackend::prepare_mesh3d_skin_binding(
  self : GpuBackend,
  key_hi : Int,
  key_lo : Int,
  skinning_matrices : Array[Float],
) -> Unit {
  if key_hi < 0 || key_lo < 0 {
    return
  }
  if skinning_matrices.length() < 16 || skinning_matrices.length() % 16 != 0 {
    return
  }
  let key = mesh3d_skin_slot_cache_key(key_hi, key_lo)
  if self.mesh3d_skin_slot_indices_by_key.get(key) is Some(existing_slot_index) {
    if existing_slot_index >= 0 &&
      existing_slot_index < self.mesh3d_skin_slots.length() {
      mesh3d_upload_skinning_matrices(
        self,
        self.mesh3d_skin_slots[existing_slot_index].buffer,
        skinning_matrices,
      )
      return
    }
  }
  let slot_index = self.mesh3d_skin_slot_used
  guard ensure_mesh3d_skin_slot(self, slot_index) is Some(skin_slot) else {
    return
  }
  self.mesh3d_skin_slot_used = slot_index + 1
  mesh3d_upload_skinning_matrices(self, skin_slot.buffer, skinning_matrices)
  self.mesh3d_skin_slot_indices_by_key.set(key, slot_index)
}

///|
fn mesh3d_expand_vertices_with_skinning_defaults(
  vertices : Array[Float],
) -> Array[Float]? {
  if vertices.length() % MESH3D_VERTEX_SKINNED_FLOAT_STRIDE == 0 {
    return Some(vertices)
  }
  if vertices.length() % MESH3D_VERTEX_BASE_FLOAT_STRIDE != 0 {
    return None
  }
  let vertex_count = vertices.length() / MESH3D_VERTEX_BASE_FLOAT_STRIDE
  let expanded : Array[Float] = []
  for vertex_index in 0..<vertex_count {
    let base = vertex_index * MESH3D_VERTEX_BASE_FLOAT_STRIDE
    for i in 0..<MESH3D_VERTEX_BASE_FLOAT_STRIDE {
      expanded.push(vertices[base + i])
    }
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
  }
  Some(expanded)
}

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
  ]
  u32le_pack(words)
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
    assets_base, "shaders/bevy_pbr/prepass/prepass.wgsl", defines, value_defines,
    visited, modules,
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
) -> Bytes {
  let determinant = scale_x * scale_y * scale_z
  let mut flags = 0xFFFFU
  if determinant >= 0.0F {
    flags = flags | (1U << 31)
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
  words.push(0xFFFFFFFFU)
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
const MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 : Int = 2

///|
const MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 : Int = 3

///|
const MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 : Int = 2

///|
const MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES : UInt64 = 20UL

///|
const MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES : UInt64 = 16UL

///|
const MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES : UInt64 = 32UL

///|
const MESH3D_PREPROCESS_WORKGROUP_SIZE : Int = 64

///|
const MESH3D_DRAW_INDIRECT_KIND_NONE : Int = 0

///|
const MESH3D_DRAW_INDIRECT_KIND_INDEXED : Int = 1

///|
const MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED : Int = 2

///|
const MESH3D_PREPROCESS_INPUT_FLAG_SIGN_DETERMINANT_MODEL_3X3 : UInt = 1U << 31

///|
fn mesh3d_preprocess_camera_upload_state_new(
  key_hi : Int,
  key_lo : Int,
) -> GpuMesh3dPreprocessCameraUploadState {
  GpuMesh3dPreprocessCameraUploadState::{
    key_hi,
    key_lo,
    mesh_input_buffer: None,
    mesh_input_capacity: 0UL,
    previous_mesh_input_buffer: None,
    previous_mesh_input_capacity: 0UL,
    output_buffer: None,
    output_capacity: 0UL,
    output_count: 0,
    motion_vector_mesh_bind_group: None,
    preprocess_main_direct_bind_group: None,
    preprocess_main_indexed_bind_group: None,
    preprocess_main_non_indexed_bind_group: None,
    preprocess_early_indexed_bind_group: None,
    preprocess_early_non_indexed_bind_group: None,
    preprocess_late_indexed_bind_group: None,
    preprocess_late_non_indexed_bind_group: None,
    build_indirect_reset_indexed_bind_group: None,
    build_indirect_reset_non_indexed_bind_group: None,
    build_indirect_indexed_bind_group: None,
    build_indirect_non_indexed_bind_group: None,
    preprocess_view_buffer: None,
    preprocess_view_capacity: 0UL,
    previous_view_buffer: None,
    previous_view_capacity: 0UL,
    mesh_culling_data_buffer: None,
    mesh_culling_data_capacity: 0UL,
    direct_work_item_buffer: None,
    direct_work_item_capacity: 0UL,
    direct_work_item_count: 0,
    indexed_work_item_buffer: None,
    indexed_work_item_capacity: 0UL,
    indexed_work_item_count: 0,
    non_indexed_work_item_buffer: None,
    non_indexed_work_item_capacity: 0UL,
    non_indexed_work_item_count: 0,
    late_indexed_work_item_buffer: None,
    late_indexed_work_item_capacity: 0UL,
    late_indexed_work_item_count: 0,
    late_non_indexed_work_item_buffer: None,
    late_non_indexed_work_item_capacity: 0UL,
    late_non_indexed_work_item_count: 0,
    late_indexed_dispatch_indirect_buffer: None,
    late_indexed_dispatch_indirect_capacity: 0UL,
    late_non_indexed_dispatch_indirect_buffer: None,
    late_non_indexed_dispatch_indirect_capacity: 0UL,
    indexed_cpu_metadata_buffer: None,
    indexed_cpu_metadata_capacity: 0UL,
    indexed_gpu_metadata_buffer: None,
    indexed_gpu_metadata_capacity: 0UL,
    indexed_gpu_metadata_count: 0,
    indexed_batch_set_buffer: None,
    indexed_batch_set_capacity: 0UL,
    indexed_batch_set_count: 0,
    indexed_indirect_parameters_buffer: None,
    indexed_indirect_parameters_capacity: 0UL,
    non_indexed_cpu_metadata_buffer: None,
    non_indexed_cpu_metadata_capacity: 0UL,
    non_indexed_gpu_metadata_buffer: None,
    non_indexed_gpu_metadata_capacity: 0UL,
    non_indexed_gpu_metadata_count: 0,
    non_indexed_batch_set_buffer: None,
    non_indexed_batch_set_capacity: 0UL,
    non_indexed_batch_set_count: 0,
    non_indexed_indirect_parameters_buffer: None,
    non_indexed_indirect_parameters_capacity: 0UL,
    dispatch_metadata_buffer: None,
    dispatch_metadata_capacity: 0UL,
    direct_workgroup_count: 0,
    indexed_workgroup_count: 0,
    non_indexed_workgroup_count: 0,
    depth_pyramid_texture: None,
    depth_pyramid_all_mips_view: None,
    depth_pyramid_mips: [],
    depth_pyramid_width: 0,
    depth_pyramid_height: 0,
    depth_pyramid_mip_count: 0,
  }
}

///|
fn mesh3d_preprocess_camera_upload_state_key(
  key_hi : Int,
  key_lo : Int,
) -> UInt64 {
  let hi = key_hi.reinterpret_as_uint().to_uint64()
  let lo = key_lo.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn mesh3d_preprocess_camera_upload_state_index(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> Int? {
  let key = mesh3d_preprocess_camera_upload_state_key(key_hi, key_lo)
  if backend.mesh3d_preprocess_camera_upload_state_indices.get(key)
    is Some(index) &&
    index >= 0 &&
    index < backend.mesh3d_preprocess_camera_upload_states.length() {
    let state = backend.mesh3d_preprocess_camera_upload_states[index]
    if state.key_hi == key_hi && state.key_lo == key_lo {
      return Some(index)
    }
  }
  for i in 0..<backend.mesh3d_preprocess_camera_upload_states.length() {
    let state = backend.mesh3d_preprocess_camera_upload_states[i]
    if state.key_hi == key_hi && state.key_lo == key_lo {
      backend.mesh3d_preprocess_camera_upload_state_indices.set(key, i)
      return Some(i)
    }
  }
  None
}

///|
fn mesh3d_preprocess_camera_upload_state_get_or_create(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> Int {
  if mesh3d_preprocess_camera_upload_state_index(backend, key_hi, key_lo)
    is Some(index) {
    return index
  }
  let key = mesh3d_preprocess_camera_upload_state_key(key_hi, key_lo)
  backend.mesh3d_preprocess_camera_upload_states.push(
    mesh3d_preprocess_camera_upload_state_new(key_hi, key_lo),
  )
  let state_index = backend.mesh3d_preprocess_camera_upload_states.length() - 1
  backend.mesh3d_preprocess_camera_upload_state_indices.set(key, state_index)
  state_index
}

///|
fn mesh3d_preprocess_ensure_storage_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  required_size : UInt64,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  if required_size == 0UL {
    return (existing_buffer, existing_capacity)
  }
  if existing_buffer is Some(buffer) && existing_capacity >= required_size {
    return (Some(buffer), existing_capacity)
  }
  let mut next_capacity = if existing_capacity > 0UL {
    existing_capacity
  } else {
    required_size
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let usage = bu(
    @wgpu.BUFFER_USAGE_STORAGE |
    @wgpu.BUFFER_USAGE_COPY_DST |
    @wgpu.BUFFER_USAGE_INDIRECT,
  )
  let buffer = backend.device.create_buffer(size=next_capacity, usage~)
  buffer.set_label(label)
  (Some(buffer), next_capacity)
}

///|
fn mesh3d_preprocess_ensure_uniform_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  required_size : UInt64,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  if required_size == 0UL {
    return (existing_buffer, existing_capacity)
  }
  if existing_buffer is Some(buffer) && existing_capacity >= required_size {
    return (Some(buffer), existing_capacity)
  }
  let mut next_capacity = if existing_capacity > 0UL {
    existing_capacity
  } else {
    required_size
  }
  while next_capacity < required_size {
    next_capacity = next_capacity * 2UL
  }
  let buffer = backend.device.create_buffer(
    size=next_capacity,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label(label)
  (Some(buffer), next_capacity)
}

///|
fn mesh3d_preprocess_upload_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  let required_size = bytes.length().to_uint64()
  let (buffer_opt, next_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    backend, existing_buffer, existing_capacity, required_size, label,
  )
  if required_size > 0UL && buffer_opt is Some(buffer) {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  (buffer_opt, next_capacity)
}

///|
fn mesh3d_preprocess_upload_uniform_buffer(
  backend : GpuBackend,
  existing_buffer : @wgpu.Buffer?,
  existing_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer?, UInt64) {
  let required_size = bytes.length().to_uint64()
  let (buffer_opt, next_capacity) = mesh3d_preprocess_ensure_uniform_buffer(
    backend, existing_buffer, existing_capacity, required_size, label,
  )
  if required_size > 0UL && buffer_opt is Some(buffer) {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  (buffer_opt, next_capacity)
}

///|
fn mesh3d_preprocess_work_items_bytes(
  items : Array[HostMesh3dPreprocessShaderWorkItem],
) -> Bytes {
  let words : Array[UInt] = []
  for item in items {
    words.push(item.input_index.reinterpret_as_uint())
    words.push(item.output_or_indirect_parameters_index.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_mesh_input_sign_determinant(
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
) -> UInt {
  if scale_x * scale_y * scale_z >= 0.0F {
    MESH3D_PREPROCESS_INPUT_FLAG_SIGN_DETERMINANT_MODEL_3X3
  } else {
    0U
  }
}

///|
fn mesh3d_preprocess_mesh_input_words(
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
  flags : UInt,
  previous_input_index : UInt,
  first_vertex_index : Int,
  first_index_index : Int,
  index_count : Int,
  tag : Int,
  frame_count : UInt,
) -> Array[UInt] {
  let words : Array[UInt] = []
  for
    word in mesh3d_world_from_local_words(
      translation_x, translation_y, translation_z, rotation_x, rotation_y, rotation_z,
      rotation_w, scale_x, scale_y, scale_z,
    ) {
    words.push(word)
  }
  words.push(0U)
  words.push(0U)
  words.push(flags)
  words.push(previous_input_index)
  words.push(first_vertex_index.reinterpret_as_uint())
  words.push(first_index_index.reinterpret_as_uint())
  words.push(index_count.reinterpret_as_uint())
  words.push(0xffffffffU)
  words.push(0U)
  words.push(frame_count)
  words.push(tag.reinterpret_as_uint())
  words.push(0U)
  words
}

///|
fn mesh3d_preprocess_mesh_inputs_bytes(
  frame_count : UInt,
  inputs : Array[HostMesh3dPreprocessMeshInput],
) -> (Bytes, Bytes) {
  let words : Array[UInt] = []
  let previous_words : Array[UInt] = []
  let input_len = inputs.length()
  for input in inputs {
    let runtime_flags = input.flags |
      mesh3d_preprocess_mesh_input_sign_determinant(
        input.scale_x,
        input.scale_y,
        input.scale_z,
      )
    for
      word in mesh3d_preprocess_mesh_input_words(
        input.translation_x,
        input.translation_y,
        input.translation_z,
        input.rotation_x,
        input.rotation_y,
        input.rotation_z,
        input.rotation_w,
        input.scale_x,
        input.scale_y,
        input.scale_z,
        runtime_flags,
        if input_len > 0 {
          (words.length() / 24).reinterpret_as_uint()
        } else {
          0xffffffffU
        },
        input.first_vertex_index,
        input.first_index_index,
        input.index_count,
        input.tag,
        frame_count,
      ) {
      words.push(word)
    }
    let previous_flags = input.flags |
      mesh3d_preprocess_mesh_input_sign_determinant(
        input.previous_scale_x,
        input.previous_scale_y,
        input.previous_scale_z,
      )
    for
      word in mesh3d_preprocess_mesh_input_words(
        input.previous_translation_x,
        input.previous_translation_y,
        input.previous_translation_z,
        input.previous_rotation_x,
        input.previous_rotation_y,
        input.previous_rotation_z,
        input.previous_rotation_w,
        input.previous_scale_x,
        input.previous_scale_y,
        input.previous_scale_z,
        previous_flags,
        0xffffffffU,
        input.first_vertex_index,
        input.first_index_index,
        input.index_count,
        input.tag,
        0U,
      ) {
      previous_words.push(word)
    }
  }
  (u32le_pack(words), u32le_pack(previous_words))
}

///|
fn mesh3d_preprocess_cpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersCpuMetadata],
) -> Bytes {
  let words : Array[UInt] = []
  for entry in metadata {
    words.push(entry.base_output_index.reinterpret_as_uint())
    words.push(entry.batch_set_index.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_gpu_metadata_bytes(
  metadata : Array[HostMesh3dPreprocessIndirectParametersGpuMetadata],
) -> Bytes {
  let words : Array[UInt] = []
  for entry in metadata {
    words.push(entry.mesh_index.reinterpret_as_uint())
    words.push(entry.early_instance_count.reinterpret_as_uint())
    words.push(entry.late_instance_count.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_batch_set_bytes(
  batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet],
) -> Bytes {
  let words : Array[UInt] = []
  for batch_set in batch_sets {
    words.push(batch_set.indirect_parameters_count.reinterpret_as_uint())
    words.push(batch_set.indirect_parameters_base.reinterpret_as_uint())
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_dispatch_metadata_bytes(
  metadata : HostMesh3dPreprocessDispatchMetadata,
) -> Bytes {
  u32le_pack([
    metadata.direct_workgroup_count.reinterpret_as_uint(),
    metadata.indexed_workgroup_count.reinterpret_as_uint(),
    metadata.non_indexed_workgroup_count.reinterpret_as_uint(),
    metadata.late_indexed_workgroup_count.reinterpret_as_uint(),
    metadata.late_non_indexed_workgroup_count.reinterpret_as_uint(),
  ])
}

///|
fn mesh3d_preprocess_frustum_plane_words(
  plane : HostMesh3dPreprocessFrustumPlane,
) -> Array[UInt] {
  [
    f32_bits(plane.normal_x),
    f32_bits(plane.normal_y),
    f32_bits(plane.normal_z),
    f32_bits(plane.distance),
  ]
}

///|
fn mesh3d_preprocess_mesh_culling_data_bytes(
  culling_data : Array[HostMesh3dPreprocessMeshCullingData],
) -> Bytes {
  let words : Array[UInt] = []
  for entry in culling_data {
    words.push(f32_bits(entry.aabb_center_x))
    words.push(f32_bits(entry.aabb_center_y))
    words.push(f32_bits(entry.aabb_center_z))
    words.push(0U)
    words.push(f32_bits(entry.aabb_half_extents_x))
    words.push(f32_bits(entry.aabb_half_extents_y))
    words.push(f32_bits(entry.aabb_half_extents_z))
    words.push(0U)
  }
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_append_clip_matrix_words(
  words : Array[UInt],
  matrix : GpuClipMatrix,
) -> Unit {
  words.push(f32_bits(matrix.x_axis_x))
  words.push(f32_bits(matrix.x_axis_y))
  words.push(f32_bits(matrix.x_axis_z))
  words.push(f32_bits(matrix.x_axis_w))
  words.push(f32_bits(matrix.y_axis_x))
  words.push(f32_bits(matrix.y_axis_y))
  words.push(f32_bits(matrix.y_axis_z))
  words.push(f32_bits(matrix.y_axis_w))
  words.push(f32_bits(matrix.z_axis_x))
  words.push(f32_bits(matrix.z_axis_y))
  words.push(f32_bits(matrix.z_axis_z))
  words.push(f32_bits(matrix.z_axis_w))
  words.push(f32_bits(matrix.w_axis_x))
  words.push(f32_bits(matrix.w_axis_y))
  words.push(f32_bits(matrix.w_axis_z))
  words.push(f32_bits(matrix.w_axis_w))
}

///|
fn mesh3d_preprocess_view_uniform_bytes(
  view : HostMesh3dPreprocessView,
  frame_count : UInt,
) -> Bytes {
  let words : Array[UInt] = []
  mesh3d_preprocess_append_clip_matrix_words(words, view.clip_from_world)
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    view.unjittered_clip_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(words, view.world_from_clip)
  mesh3d_preprocess_append_clip_matrix_words(words, view.world_from_view)
  mesh3d_preprocess_append_clip_matrix_words(words, view.view_from_world)
  mesh3d_preprocess_append_clip_matrix_words(words, view.clip_from_view)
  mesh3d_preprocess_append_clip_matrix_words(words, view.view_from_clip)
  words.push(f32_bits(view.world_position_x))
  words.push(f32_bits(view.world_position_y))
  words.push(f32_bits(view.world_position_z))
  words.push(f32_bits(view.exposure))
  words.push(f32_bits(view.viewport_x))
  words.push(f32_bits(view.viewport_y))
  words.push(f32_bits(view.viewport_width))
  words.push(f32_bits(view.viewport_height))
  words.push(f32_bits(view.main_pass_viewport_x))
  words.push(f32_bits(view.main_pass_viewport_y))
  words.push(f32_bits(view.main_pass_viewport_width))
  words.push(f32_bits(view.main_pass_viewport_height))
  for i in 0..<6 {
    let plane = if i < view.frustum_planes.length() {
      view.frustum_planes[i]
    } else {
      HostMesh3dPreprocessFrustumPlane::{
        normal_x: 0.0F,
        normal_y: 0.0F,
        normal_z: 0.0F,
        distance: 0.0F,
      }
    }
    for word in mesh3d_preprocess_frustum_plane_words(plane) {
      words.push(word)
    }
  }
  for _ in 0..<40 {
    words.push(0U)
  }
  words.push(f32_bits(view.mip_bias))
  words.push(frame_count)
  words.push(0U)
  words.push(0U)
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_previous_view_uniform_bytes(
  previous_view : HostMesh3dPreprocessPreviousView,
) -> Bytes {
  let words : Array[UInt] = []
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.view_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.clip_from_world,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.clip_from_view,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.world_from_clip,
  )
  mesh3d_preprocess_append_clip_matrix_words(
    words,
    previous_view.view_from_clip,
  )
  u32le_pack(words)
}

///|
fn mesh3d_preprocess_late_dispatch_parameters_default_bytes() -> Bytes {
  u32le_pack([0U, 1U, 1U, 0U, 0U, 0U, 0U, 0U])
}

///|
fn mesh3d_preprocess_previous_power_of_two(value : Int) -> Int {
  let safe_value = if value <= 1 { 1 } else { value }
  let mut power = 1
  while power * 2 > 0 && power * 2 <= safe_value {
    power = power * 2
  }
  power
}

///|
fn mesh3d_preprocess_next_power_of_two(value : Int) -> Int {
  let safe_value = if value <= 1 { 1 } else { value }
  let mut power = 1
  while power < safe_value {
    power = power * 2
  }
  power
}

///|
fn mesh3d_preprocess_depth_pyramid_mip_count(width : Int, height : Int) -> Int {
  let mut max_dim = if width > height { width } else { height }
  if max_dim <= 0 {
    return 1
  }
  let mut mip_count = 0
  while max_dim > 0 && mip_count < 12 {
    mip_count = mip_count + 1
    max_dim = max_dim / 2
  }
  if mip_count <= 0 {
    1
  } else {
    mip_count
  }
}

///|
fn mesh3d_preprocess_depth_pyramid_dispatch_size(size : Int) -> UInt {
  mesh3d_preprocess_next_power_of_two(size + 1).reinterpret_as_uint()
}

///|
fn mesh3d_preprocess_replace_string(
  source : String,
  needle : String,
  replacement : String,
) -> String {
  source.replace_all(old=needle, new=replacement)
}

///|
fn mesh3d_preprocess_specialize_late_phase_immediate(source : String) -> String {
  mesh3d_preprocess_replace_string(
    source, "var<immediate> immediates: Immediates;", "const LATE_PREPROCESS_WORK_ITEM_INDIRECT_OFFSET: u32 = 0u;",
  ).replace_all(
    old="immediates.late_preprocess_work_item_indirect_offset",
    new="LATE_PREPROCESS_WORK_ITEM_INDIRECT_OFFSET",
  )
}

///|
fn mesh3d_preprocess_specialize_downsample_depth(
  source : String,
  max_mip_level : Int,
) -> String {
  mesh3d_preprocess_replace_string(
    source,
    "struct Constants { max_mip_level: u32 }\nvar<immediate> constants: Constants;",
    "const MAX_MIP_LEVEL: u32 = " + max_mip_level.to_string() + "u;",
  ).replace_all(old="constants.max_mip_level", new="MAX_MIP_LEVEL")
}

///|
fn load_wgsl_required_mesh3d_preprocess_direct(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/mesh_preprocess.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/mesh_preprocess.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect_early_occlusion(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  let source = load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/mesh_preprocess.wgsl", defines, value_defines,
    visited, modules,
  )
  mesh3d_preprocess_specialize_late_phase_immediate(source)
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect_late_occlusion(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("LATE_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  let source = load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/mesh_preprocess.wgsl", defines, value_defines,
    visited, modules,
  )
  mesh3d_preprocess_specialize_late_phase_immediate(source)
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("INDEXED", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/build_indirect_params.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params_early(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("INDEXED", true)
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/build_indirect_params.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/build_indirect_params.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params_early(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, "shaders/bevy_pbr/render/build_indirect_params.wgsl", defines, value_defines,
    visited, modules,
  )
}

///|
fn load_wgsl_required_mesh3d_downsample_depth(
  assets_base : String,
  max_mip_level : Int,
) -> String raise GpuBackendError {
  let source = load_wgsl_from_assets_base_required(
    assets_base, "shaders/bevy_core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
  )
  mesh3d_preprocess_specialize_downsample_depth(source, max_mip_level)
}

///|
fn ensure_mesh3d_preprocess_indirect_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  if backend.mesh3d_preprocess_direct_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build mesh3d preprocess direct bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_direct_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label("mgstudio_mesh3d_preprocess_direct_pipeline_layout")
    backend.mesh3d_preprocess_direct_bgl = Some(bgl)
    backend.mesh3d_preprocess_direct_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=8UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label("mgstudio_mesh3d_preprocess_indirect_pipeline_layout")
    backend.mesh3d_preprocess_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_indirect_early_occlusion_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_texture(
        10U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect early occlusion bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_early_occlusion_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_indirect_early_occlusion_pipeline_layout",
    )
    backend.mesh3d_preprocess_indirect_early_occlusion_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_early_occlusion_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_indirect_late_occlusion_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=11UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_texture(
        10U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_buffer(
        12U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect late occlusion bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_late_occlusion_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_indirect_late_occlusion_pipeline_layout",
    )
    backend.mesh3d_preprocess_indirect_late_occlusion_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_late_occlusion_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_reset_batch_sets_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess reset batch sets bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_reset_batch_sets_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_reset_batch_sets_pipeline_layout",
    )
    backend.mesh3d_preprocess_reset_batch_sets_bgl = Some(bgl)
    backend.mesh3d_preprocess_reset_batch_sets_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        1U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indexed indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_build_indexed_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_build_indexed_indirect_pipeline_layout",
    )
    backend.mesh3d_preprocess_build_indexed_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        1U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess non-indexed indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_build_non_indexed_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_downsample_depth_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
    let ok = builder.add_texture(
        0U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        1U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        2U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        3U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        4U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        5U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        6U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_READ_WRITE,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        7U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        8U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        9U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        10U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        11U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        12U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(
        13U,
        compute,
        @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess downsample depth bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_downsample_depth_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_pipeline_layout",
    )
    backend.mesh3d_preprocess_downsample_depth_bgl = Some(bgl)
    backend.mesh3d_preprocess_downsample_depth_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_depth_pyramid_dummy_texture is None {
    let usage = @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
    )
    let texture = backend.device.create_texture_u32(
      1U,
      1U,
      1U,
      usage,
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    )
    let view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      1U,
    )
    backend.mesh3d_preprocess_depth_pyramid_dummy_texture = Some(texture)
    backend.mesh3d_preprocess_depth_pyramid_dummy_view = Some(view)
  }
  if backend.mesh3d_preprocess_depth_pyramid_sampler is None {
    backend.mesh3d_preprocess_depth_pyramid_sampler = Some(
      backend.device.create_sampler_nearest_clamp(),
    )
  }
  if backend.mesh3d_preprocess_reset_batch_sets_pipeline is None {
    guard backend.mesh3d_preprocess_reset_batch_sets_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_from_assets_required(
      backend, "shaders/bevy_pbr/render/reset_indirect_batch_sets.wgsl",
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess reset batch sets pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_reset_batch_sets")
    backend.mesh3d_preprocess_reset_batch_sets_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_direct_pipeline is None {
    guard backend.mesh3d_preprocess_direct_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_direct(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess direct pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_direct")
    backend.mesh3d_preprocess_direct_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect")
    backend.mesh3d_preprocess_indirect_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_early_occlusion_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_early_occlusion_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect_early_occlusion(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect early occlusion pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect_early_occlusion")
    backend.mesh3d_preprocess_indirect_early_occlusion_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_late_occlusion_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_late_occlusion_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect_late_occlusion(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect late occlusion pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect_late_occlusion")
    backend.mesh3d_preprocess_indirect_late_occlusion_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_indexed_indirect")
    backend.mesh3d_preprocess_build_indexed_indirect_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_early_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params_early(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect early pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_indexed_indirect_early",
    )
    backend.mesh3d_preprocess_build_indexed_indirect_early_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_non_indexed_indirect")
    backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params_early(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect early pipeline: " +
          err.message(),
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_early",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_downsample_depth_first_pipeline is None {
    guard backend.mesh3d_preprocess_downsample_depth_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_downsample_depth(
      backend.assets_base,
      12,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let first_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "downsample_depth_first",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess downsample depth first pipeline: " +
          err.message(),
        )
    }
    let second_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "downsample_depth_second",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess downsample depth second pipeline: " +
          err.message(),
        )
    }
    first_pipeline.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_first",
    )
    second_pipeline.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_second",
    )
    backend.mesh3d_preprocess_downsample_depth_first_pipeline = Some(
      first_pipeline,
    )
    backend.mesh3d_preprocess_downsample_depth_second_pipeline = Some(
      second_pipeline,
    )
    shader.release()
  }
}

///|
fn mesh3d_pipeline_get_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent
    } else {
      backend.mesh3d_pipeline_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent
  } else {
    backend.mesh3d_pipeline
  }
}

///|
fn mesh3d_pipeline_set_rgba8(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_transparent = pipeline
  } else {
    backend.mesh3d_pipeline = pipeline
  }
}

///|
fn mesh3d_rgba8_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline = None
  backend.mesh3d_pipeline_transparent = None
  backend.mesh3d_pipeline_line_list = None
  backend.mesh3d_pipeline_line_list_transparent = None
  backend.mesh3d_pipeline_line_strip = None
  backend.mesh3d_pipeline_line_strip_transparent = None
  backend.mesh3d_pipeline_rgba8_cull_mode = -1
}

///|
fn mesh3d_pipeline_get_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
) -> @wgpu.RenderPipeline? {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_list
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent
    } else {
      backend.mesh3d_pipeline_surface_line_strip
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent
  } else {
    backend.mesh3d_pipeline_surface
  }
}

///|
fn mesh3d_pipeline_set_surface(
  backend : GpuBackend,
  topology : UInt,
  transparent : Bool,
  pipeline : @wgpu.RenderPipeline?,
) -> Unit {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    if transparent {
      backend.mesh3d_pipeline_surface_line_list_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_list = pipeline
    }
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    if transparent {
      backend.mesh3d_pipeline_surface_line_strip_transparent = pipeline
    } else {
      backend.mesh3d_pipeline_surface_line_strip = pipeline
    }
  } else if transparent {
    backend.mesh3d_pipeline_surface_transparent = pipeline
  } else {
    backend.mesh3d_pipeline_surface = pipeline
  }
}

///|
fn mesh3d_surface_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  if backend.mesh3d_pipeline_surface is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_list_transparent is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip is Some(old) {
    old.release()
  }
  if backend.mesh3d_pipeline_surface_line_strip_transparent is Some(old) {
    old.release()
  }
  backend.mesh3d_pipeline_surface = None
  backend.mesh3d_pipeline_surface_transparent = None
  backend.mesh3d_pipeline_surface_line_list = None
  backend.mesh3d_pipeline_surface_line_list_transparent = None
  backend.mesh3d_pipeline_surface_line_strip = None
  backend.mesh3d_pipeline_surface_line_strip_transparent = None
  backend.mesh3d_pipeline_surface_cull_mode = -1
}

///|
fn mesh3d_custom_pipeline_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_custom_pipeline_cache {
    entry.pipeline.release()
  }
  backend.mesh3d_custom_pipeline_cache.clear()
}

///|
fn mesh3d_shader_path_or_default(shader_path : String?) -> String {
  match shader_path {
    Some(path) => if path == "" { MESH3D_FORWARD_SHADER_PATH } else { path }
    None => MESH3D_FORWARD_SHADER_PATH
  }
}

///|
fn mesh3d_custom_pipeline_cache_get(
  backend : GpuBackend,
  shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  forward_decal : Bool,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? {
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  for entry in backend.mesh3d_custom_pipeline_cache {
    if entry.shader_path != shader_path {
      continue
    }
    if entry.topology != topology ||
      entry.transparent != transparent ||
      entry.forward_decal != forward_decal ||
      entry.cull_mode != safe_cull_mode {
      continue
    }
    if entry.surface_format == surface_format {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn load_wgsl_required_mesh3d_forward_decal_pipeline(
  assets_base : String,
  shader_path : String,
  forward_decal : Bool,
) -> String raise GpuBackendError {
  if !forward_decal {
    return load_wgsl_from_assets_base_required(assets_base, shader_path)
  }
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("FORWARD_DECAL", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths(assets_base)
  load_wgsl_preprocessed(
    assets_base, shader_path, defines, value_defines, visited, modules,
  )
}

///|
fn mesh3d_custom_pipeline_get_or_create(
  backend : GpuBackend,
  shader_path : String,
  surface_format : @wgpu.TextureFormat?,
  topology : UInt,
  transparent : Bool,
  forward_decal : Bool,
  cull_mode : Int,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_shader_path = mesh3d_shader_path_or_default(Some(shader_path))
  if resolved_shader_path == MESH3D_FORWARD_SHADER_PATH && !forward_decal {
    return None
  }
  if mesh3d_custom_pipeline_cache_get(
      backend, resolved_shader_path, surface_format, topology, transparent, forward_decal,
      cull_mode,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return None }
  let shader_source = load_wgsl_required_mesh3d_forward_decal_pipeline(
    backend.assets_base,
    resolved_shader_path,
    forward_decal,
  )
  let shader_module = backend.device.create_shader_module_wgsl(shader_source)
  let color_format = match surface_format {
    Some(format) => format.to_u32()
    None => @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
  }
  let descriptor = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    shader_module,
    color_format,
    with_depth=true,
    depth_write_enabled=!transparent,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
    depth_compare_u32=if forward_decal {
      @wgpu.COMPARE_FUNCTION_ALWAYS
    } else {
      @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
    },
  )
  let pipeline = backend.device.create_render_pipeline_ptr(descriptor)
  @wgpu_c.render_pipeline_descriptor_free(descriptor)
  let label_prefix = if surface_format is Some(_) {
    "mgstudio_mesh3d_custom_surface_"
  } else {
    "mgstudio_mesh3d_custom_rgba8_"
  }
  let transparent_suffix = if transparent { "1" } else { "0" }
  let forward_decal_suffix = if forward_decal { "1" } else { "0" }
  pipeline.set_label(
    label_prefix +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode) +
    "_transparent_" +
    transparent_suffix +
    "_forward_decal_" +
    forward_decal_suffix +
    "_shader_" +
    resolved_shader_path,
  )
  backend.mesh3d_custom_pipeline_cache.push(Mesh3dCustomPipelineCacheEntry::{
    shader_path: resolved_shader_path,
    surface_format,
    topology,
    transparent,
    forward_decal,
    cull_mode: safe_cull_mode,
    pipeline,
  })
  shader_module.release()
  Some(pipeline)
}

///|
fn ensure_mesh3d_pipeline_rgba8(
  backend : GpuBackend,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  ensure_sprite_resources(backend)
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_rgba8_cull_mode != safe_cull_mode {
    mesh3d_rgba8_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_rgba8_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=9UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_texture(
        1U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        2U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      view_builder.add_texture(
        3U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_CUBE,
      ) &&
      view_builder.add_sampler(
        4U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_COMPARISON,
      ) &&
      view_builder.add_texture(
        5U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        6U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      view_builder.add_texture(
        7U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      view_builder.add_sampler(
        8U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_view_bgl",
    )
    let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
    let material_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=16UL)
    let material_ok = material_builder.add_texture(
        1U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        2U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        3U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        4U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        5U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        6U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        7U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        8U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        9U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        10U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        11U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        12U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        13U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        14U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      ) &&
      material_builder.add_texture(
        29U,
        frag,
        @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      material_builder.add_sampler(
        30U,
        frag,
        @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
      )
    if !material_ok {
      material_builder.free()
      fatal("wgpu: failed to build mesh3d material bind group layout")
    }
    let material_bgl = material_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_material_bgl",
    )
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      view_stage,
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      min_binding_size=MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d draw bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_draw_bgl",
    )
    let skin_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let skin_ok = skin_builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX),
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      min_binding_size=64UL,
    )
    if !skin_ok {
      skin_builder.free()
      fatal("wgpu: failed to build mesh3d skin bind group layout")
    }
    let skin_bgl = skin_builder.finish(
      backend.device,
      label="mgstudio_mesh3d_skin_bgl",
    )
    let pl = create_pipeline_layout_4(
      backend.device,
      view_bgl,
      material_bgl,
      mesh_bgl,
      skin_bgl,
    )
    backend.mesh3d_bgl_view = Some(view_bgl)
    backend.mesh3d_bgl_draw = Some(mesh_bgl)
    backend.mesh3d_bgl_material = Some(material_bgl)
    backend.mesh3d_bgl_skin = Some(skin_bgl)
    backend.mesh3d_pipeline_layout = Some(pl)
    if backend.mesh3d_view_buf is None {
      backend.mesh3d_view_buf = Some(
        backend.device.create_buffer(
          size=MESH3D_VIEW_BUFFER_SIZE,
          usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
        ),
      )
    }
    mesh3d_material_cache_clear(backend)
    mesh3d_custom_pipeline_cache_clear(backend)
    ensure_mesh3d_skin_default_binding(backend) |> ignore
  }
  if backend.mesh3d_view_buf is None {
    backend.mesh3d_view_buf = Some(
      backend.device.create_buffer(
        size=MESH3D_VIEW_BUFFER_SIZE,
        usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
      ),
    )
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_rgba8(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_rgba8_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_rgba8_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_rgba8(backend, topology, true, Some(pipeline_transparent))
  sm.release()
}

///|
fn ensure_mesh3d_pipeline_surface(
  backend : GpuBackend,
  format : @wgpu.TextureFormat,
  topology : UInt,
  cull_mode : Int,
) -> Unit raise GpuBackendError {
  // Ensure shared mesh3d pipeline resources/layout exist before creating
  // surface-format specializations.
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  ensure_sprite_resources(backend)
  if format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) {
    return
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) && prev != format {
    mesh3d_surface_pipeline_cache_clear(backend)
  }
  let safe_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  if backend.mesh3d_pipeline_surface_cull_mode != safe_cull_mode {
    mesh3d_surface_pipeline_cache_clear(backend)
    backend.mesh3d_pipeline_surface_cull_mode = safe_cull_mode
  }
  if backend.mesh3d_pipeline_surface_format is Some(prev) &&
    prev == format &&
    mesh3d_pipeline_get_surface(backend, topology, false) is Some(_) &&
    mesh3d_pipeline_get_surface(backend, topology, true) is Some(_) {
    return
  }
  if mesh3d_pipeline_get_surface(backend, topology, false) is Some(old) {
    old.release()
  }
  if mesh3d_pipeline_get_surface(backend, topology, true) is Some(old) {
    old.release()
  }
  let cull_mode_wgpu = mesh3d_cull_mode_wgpu(safe_cull_mode)
  guard backend.mesh3d_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_from_assets_required(backend, MESH3D_FORWARD_SHADER_PATH)
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let desc_opaque = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=true,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_opaque = backend.device.create_render_pipeline_ptr(desc_opaque)
  @wgpu_c.render_pipeline_descriptor_free(desc_opaque)
  pipeline_opaque.set_label(
    "mgstudio_mesh3d_surface_opaque_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(backend, topology, false, Some(pipeline_opaque))
  let desc_transparent = mesh_pipeline_desc_pos2_uv2_color4_alpha_blend(
    pl,
    sm,
    format.to_u32(),
    with_depth=true,
    depth_write_enabled=false,
    position3d=true,
    topology~,
    cull_mode=cull_mode_wgpu,
  )
  let pipeline_transparent = backend.device.create_render_pipeline_ptr(
    desc_transparent,
  )
  @wgpu_c.render_pipeline_descriptor_free(desc_transparent)
  pipeline_transparent.set_label(
    "mgstudio_mesh3d_surface_transparent_" +
    mesh3d_topology_suffix(topology) +
    "_cull_" +
    mesh3d_cull_mode_suffix(safe_cull_mode),
  )
  mesh3d_pipeline_set_surface(
    backend,
    topology,
    true,
    Some(pipeline_transparent),
  )
  backend.mesh3d_pipeline_surface_format = Some(format)
  sm.release()
}

///|
fn mesh3d_pipeline_for_current_pass(
  backend : GpuBackend,
  transparent : Bool,
  forward_decal : Bool,
  topology : UInt,
  cull_mode : Int,
  shader_path : String?,
) -> @wgpu.RenderPipeline? raise GpuBackendError {
  let resolved_shader_path = mesh3d_shader_path_or_default(shader_path)
  if resolved_shader_path != MESH3D_FORWARD_SHADER_PATH || forward_decal {
    let custom_surface_format = match current_pass_color_format(backend) {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) =>
        Some(format)
      _ => None
    }
    return mesh3d_custom_pipeline_get_or_create(
      backend, resolved_shader_path, custom_surface_format, topology, transparent,
      forward_decal, cull_mode,
    )
  }
  match current_pass_color_format(backend) {
    Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
      ensure_mesh3d_pipeline_surface(backend, format, topology, cull_mode)
      return mesh3d_pipeline_get_surface(backend, topology, transparent)
    }
    _ => ()
  }
  ensure_mesh3d_pipeline_rgba8(backend, topology, cull_mode)
  mesh3d_pipeline_get_rgba8(backend, topology, transparent)
}

///|
fn ensure_mesh3d_motion_vector_pipeline(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  if backend.mesh3d_motion_vector_pipeline_layout is None {
    let view_stage = ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
    let view_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=4UL)
    let view_ok = view_builder.add_buffer(
        0U,
        view_stage,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      ) &&
      view_builder.add_buffer(1U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(2U, view_stage, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
      view_builder.add_buffer(
        14U,
        ss(@wgpu.SHADER_STAGE_VERTEX),
        @wgpu.BUFFER_BINDING_TYPE_STORAGE,
      )
    if !view_ok {
      view_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector view bind group layout")
    }
    let view_bgl = view_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_view_bgl",
    )
    let empty_bgl = backend.device.create_bind_group_layout_uniform_buffer()
    let mesh_builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let mesh_ok = mesh_builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_VERTEX),
      @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      min_binding_size=MESH3D_PREPASS_MESH_BUFFER_SIZE,
    )
    if !mesh_ok {
      mesh_builder.free()
      fatal("wgpu: failed to build mesh3d motion vector mesh bind group layout")
    }
    let mesh_bgl = mesh_builder.finish(
      backend.device,
      label="mgstudio_motion_vector_mesh_bgl",
    )
    let pl = create_pipeline_layout_3(
      backend.device,
      view_bgl,
      empty_bgl,
      mesh_bgl,
    )
    backend.mesh3d_motion_vector_bgl_view = Some(view_bgl)
    backend.mesh3d_motion_vector_bgl_empty = Some(empty_bgl)
    backend.mesh3d_motion_vector_bgl_mesh = Some(mesh_bgl)
    backend.mesh3d_motion_vector_pipeline_layout = Some(pl)
  }
  if backend.mesh3d_motion_vector_view_buf is None ||
    backend.mesh3d_motion_vector_globals_buf is None ||
    backend.mesh3d_motion_vector_previous_view_buf is None ||
    backend.mesh3d_motion_vector_visibility_ranges_buf is None ||
    backend.mesh3d_motion_vector_view_bg is None ||
    backend.mesh3d_motion_vector_empty_bg is None {
    guard backend.mesh3d_motion_vector_bgl_view is Some(view_bgl) else {
      return
    }
    guard backend.mesh3d_motion_vector_bgl_empty is Some(empty_bgl) else {
      return
    }
    let uniform_usage = bu(
      @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let storage_usage = bu(
      @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST,
    )
    let view_buf = backend.device.create_buffer(
      size=MESH2D_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let globals_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let previous_view_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      usage=uniform_usage,
    )
    let visibility_ranges_buf = backend.device.create_buffer(
      size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      usage=storage_usage,
    )
    backend.queue.write_buffer(
      globals_buf,
      0UL,
      mesh3d_motion_vector_globals_uniform_bytes(),
    )
    backend.queue.write_buffer(
      visibility_ranges_buf,
      0UL,
      mesh3d_motion_vector_visibility_ranges_bytes(),
    )
    let builder = @wgpu.BindGroupBuilder::new(max_entries=4UL)
    let ok = builder.add_buffer(0U, view_buf, size=MESH2D_VIEW_BUFFER_SIZE) &&
      builder.add_buffer(
        1U,
        globals_buf,
        size=MESH3D_PREPASS_GLOBALS_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        previous_view_buf,
        size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        14U,
        visibility_ranges_buf,
        size=MESH3D_PREPASS_VISIBILITY_RANGES_BUFFER_SIZE,
      )
    if !ok {
      builder.free()
      return
    }
    let view_bg = builder.finish(
      backend.device,
      view_bgl,
      label="mgstudio_motion_vector_view_bg",
    )
    let empty_bg = backend.device.create_bind_group_uniform_buffer(
      empty_bgl, globals_buf,
    )
    backend.mesh3d_motion_vector_view_buf = Some(view_buf)
    backend.mesh3d_motion_vector_globals_buf = Some(globals_buf)
    backend.mesh3d_motion_vector_previous_view_buf = Some(previous_view_buf)
    backend.mesh3d_motion_vector_visibility_ranges_buf = Some(
      visibility_ranges_buf,
    )
    backend.mesh3d_motion_vector_view_bg = Some(view_bg)
    backend.mesh3d_motion_vector_empty_bg = Some(empty_bg)
  }
  if backend.mesh3d_motion_vector_pipeline is Some(_) {
    return
  }
  guard backend.mesh3d_motion_vector_pipeline_layout is Some(pl) else { return }
  let wgsl = load_wgsl_required_mesh3d_motion_vector_prepass(
    backend.assets_base,
  )
  let sm = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(sm, layout=pl)
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_count(2U)
    builder.set_color_target_format_at(
      0U,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    )
    builder.set_color_target_format_at(1U, tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT))
    builder.set_color_target_write_mask_at(0U, @wgpu.COLOR_WRITE_MASK_NONE)
    builder.set_color_target_write_mask_at(1U, @wgpu.COLOR_WRITE_MASK_ALL)
    builder.disable_blend()
    builder.set_vertex_buffer_layout(
      MESH3D_VERTEX_STRIDE_BYTES,
      @wgpu.VERTEX_STEP_MODE_VERTEX,
    )
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 0UL, 0U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X3, 12UL, 1U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X2, 24UL, 2U)
    builder.add_vertex_attribute(@wgpu.VERTEX_FORMAT_FLOAT32X4, 32UL, 3U)
    builder.set_topology_u32(@wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT),
      depth_write_enabled=true,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    )
    builder.create_pipeline(backend.device)
  } catch {
    err => {
      err |> ignore
      sm.release()
      fatal(
        "wgpu: failed to build canonical mesh3d motion vector prepass pipeline",
      )
    }
  }
  pipeline.set_label("mgstudio_motion_vector_prepass")
  backend.mesh3d_motion_vector_pipeline = Some(pipeline)
  sm.release()
}

///|
fn mesh3d_material_cache_clear(backend : GpuBackend) -> Unit {
  for entry in backend.mesh3d_material_bg_cache {
    entry.bind_group.release()
  }
  backend.mesh3d_material_bg_cache.clear()
}

///|
fn ensure_mesh3d_point_shadow_compare_sampler(
  backend : GpuBackend,
) -> @wgpu.Sampler {
  match backend.mesh3d_point_shadow_compare_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_u32(
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.FILTER_MODE_LINEAR,
        @wgpu.MIPMAP_FILTER_MODE_NEAREST,
        compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      )
      backend.mesh3d_point_shadow_compare_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_view_bg_cache_get_or_create(
  backend : GpuBackend,
  transmission_source_texture : GpuTextureInfo,
  point_shadow_texture : GpuTextureInfo,
  environment_diffuse_texture : GpuTextureInfo,
  environment_specular_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  let layout = match backend.mesh3d_bgl_view {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d view bind group layout")
  }
  let view_buf = match backend.mesh3d_view_buf {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d view uniform buffer")
  }
  let point_shadow_sample_view = match point_shadow_texture.sample_view {
    Some(view) => view
    None => point_shadow_texture.view
  }
  let point_shadow_compare_sampler = ensure_mesh3d_point_shadow_compare_sampler(
    backend,
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
  let ok = builder.add_buffer(0U, view_buf, size=MESH3D_VIEW_BUFFER_SIZE) &&
    builder.add_texture_view(1U, transmission_source_texture.view) &&
    builder.add_sampler(2U, transmission_source_texture.sampler) &&
    builder.add_texture_view(3U, point_shadow_sample_view) &&
    builder.add_sampler(4U, point_shadow_compare_sampler) &&
    builder.add_texture_view(5U, environment_diffuse_texture.view) &&
    builder.add_sampler(6U, environment_diffuse_texture.sampler) &&
    builder.add_texture_view(7U, environment_specular_texture.view) &&
    builder.add_sampler(8U, environment_specular_texture.sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d view bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_view_bg",
  )
  bind_group
}

///|
fn mesh3d_material_cache_get_or_create(
  backend : GpuBackend,
  base_texture : GpuTextureInfo,
  normal_texture : GpuTextureInfo,
  emissive_texture : GpuTextureInfo,
  metallic_roughness_texture : GpuTextureInfo,
  occlusion_texture : GpuTextureInfo,
  depth_texture : GpuTextureInfo,
  anisotropy_texture : GpuTextureInfo,
  specular_tint_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  for entry in backend.mesh3d_material_bg_cache {
    if entry.base_texture_id == base_texture.id &&
      entry.normal_texture_id == normal_texture.id &&
      entry.emissive_texture_id == emissive_texture.id &&
      entry.metallic_roughness_texture_id == metallic_roughness_texture.id &&
      entry.occlusion_texture_id == occlusion_texture.id &&
      entry.depth_texture_id == depth_texture.id &&
      entry.anisotropy_texture_id == anisotropy_texture.id &&
      entry.specular_tint_texture_id == specular_tint_texture.id {
      return entry.bind_group
    }
  }
  let layout = match backend.mesh3d_bgl_material {
    Some(v) => v
    None => fatal("wgpu: missing mesh3d material bind group layout")
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=16UL)
  let ok = builder.add_texture_view(1U, base_texture.view) &&
    builder.add_sampler(2U, base_texture.sampler) &&
    builder.add_texture_view(3U, emissive_texture.view) &&
    builder.add_sampler(4U, emissive_texture.sampler) &&
    builder.add_texture_view(5U, metallic_roughness_texture.view) &&
    builder.add_sampler(6U, metallic_roughness_texture.sampler) &&
    builder.add_texture_view(7U, occlusion_texture.view) &&
    builder.add_sampler(8U, occlusion_texture.sampler) &&
    builder.add_texture_view(9U, normal_texture.view) &&
    builder.add_sampler(10U, normal_texture.sampler) &&
    builder.add_texture_view(11U, depth_texture.view) &&
    builder.add_sampler(12U, depth_texture.sampler) &&
    builder.add_texture_view(13U, anisotropy_texture.view) &&
    builder.add_sampler(14U, anisotropy_texture.sampler) &&
    builder.add_texture_view(29U, specular_tint_texture.view) &&
    builder.add_sampler(30U, specular_tint_texture.sampler)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build mesh3d material bind group")
  }
  let bind_group = builder.finish(
    backend.device,
    layout,
    label="mgstudio_mesh3d_material_bg",
  )
  backend.mesh3d_material_bg_cache.push(Mesh3dMaterialBindGroupCacheEntry::{
    base_texture_id: base_texture.id,
    normal_texture_id: normal_texture.id,
    emissive_texture_id: emissive_texture.id,
    metallic_roughness_texture_id: metallic_roughness_texture.id,
    occlusion_texture_id: occlusion_texture.id,
    depth_texture_id: depth_texture.id,
    anisotropy_texture_id: anisotropy_texture.id,
    specular_tint_texture_id: specular_tint_texture.id,
    bind_group,
  })
  bind_group
}

///|
fn resolve_mesh3d_texture(
  backend : GpuBackend,
  id : Int,
) -> GpuTextureInfo? raise GpuBackendError {
  if id < 0 {
    return Some(ensure_default_texture(backend))
  }
  match find_texture(backend, id) {
    Some(texture) => Some(texture)
    None => Some(ensure_default_texture(backend))
  }
}

///|
fn ensure_point_shadow_fallback_texture(
  backend : GpuBackend,
) -> GpuTextureInfo raise GpuBackendError {
  if backend.point_shadow_fallback_texture_id >= 0 {
    if find_texture(backend, backend.point_shadow_fallback_texture_id)
      is Some(texture) {
      return texture
    }
  }
  let created_id = backend.create_point_light_shadow_target(1)
  backend.point_shadow_fallback_texture_id = created_id
  guard find_texture(backend, created_id) is Some(texture) else {
    fatal("wgpu: failed to initialize point shadow fallback texture")
  }
  texture
}

///|
pub fn GpuBackend::create_mesh3d_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Int {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return 0
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return 0
  }
  let uses_u32_indices = usable_vcount > 65535
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = if uses_u32_indices {
    let indices_u32 : Array[UInt] = []
    for i in 0..<usable_vcount {
      indices_u32.push(i.reinterpret_as_uint())
    }
    self.device.create_buffer_init(usage=ib_usage, u32le_pack(indices_u32))
  } else {
    let indices_u16 : Array[Int] = []
    for i in 0..<usable_vcount {
      indices_u16.push(i)
    }
    self.device.create_buffer_init(usage=ib_usage, u16le_pack(indices_u16))
  }
  let info = GpuMeshInfo::{
    id,
    index_count: usable_vcount.reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology,
    vertex_stride_bytes: MESH3D_VERTEX_STRIDE_BYTES,
    index_stride_bytes: if uses_u32_indices {
      4UL
    } else {
      2UL
    },
    uses_u32_indices,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  self.create_mesh3d_xyznuvrgba(vertices, 0)
}

///|
pub fn GpuBackend::update_mesh3d_xyznuvrgba(
  self : GpuBackend,
  mesh_id : Int,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Bool {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return false
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return false
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return false
  }
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES ||
    mesh.primitive_topology != primitive_topology ||
    mesh.vertex_count.reinterpret_as_int() != usable_vcount {
    return false
  }
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  self.queue.write_buffer(mesh.vertex_buf, 0UL, f32le_pack(trimmed_vertices))
  true
}

///|
pub fn GpuBackend::upload_mesh3d_preprocess_camera_payload(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  payload : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  let state_index = mesh3d_preprocess_camera_upload_state_get_or_create(
    self, camera_key_hi, camera_key_lo,
  )
  let old_preprocess_view_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let old_previous_view_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let old_mesh_input_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let old_previous_mesh_input_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let old_output_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let old_mesh_culling_data_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let old_direct_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  let old_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let old_non_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let old_late_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  let old_late_non_indexed_work_item_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  let old_late_indexed_dispatch_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity
  let old_late_non_indexed_dispatch_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity
  let old_indexed_cpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let old_indexed_gpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let old_indexed_batch_set_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  let old_indexed_indirect_parameters_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  let old_non_indexed_cpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let old_non_indexed_gpu_metadata_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let old_non_indexed_batch_set_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  let old_non_indexed_indirect_parameters_capacity = self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  let (mesh_input_bytes, previous_mesh_input_bytes) = mesh3d_preprocess_mesh_inputs_bytes(
    self.frame_count,
    payload.mesh_inputs,
  )
  let preprocess_view_bytes = mesh3d_preprocess_view_uniform_bytes(
    payload.view,
    self.frame_count,
  )
  let previous_view_bytes = mesh3d_preprocess_previous_view_uniform_bytes(
    payload.previous_view,
  )
  let mesh_culling_data_bytes = mesh3d_preprocess_mesh_culling_data_bytes(
    payload.mesh_culling_data,
  )
  let late_dispatch_default_bytes = mesh3d_preprocess_late_dispatch_parameters_default_bytes()
  let (mesh_input_buffer, mesh_input_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity,
    mesh_input_bytes,
    "mgstudio_mesh3d_preprocess_mesh_inputs",
  )
  let (previous_mesh_input_buffer, previous_mesh_input_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity,
    previous_mesh_input_bytes,
    "mgstudio_mesh3d_preprocess_previous_mesh_inputs",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer = mesh_input_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity = mesh_input_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
  = previous_mesh_input_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  = previous_mesh_input_capacity
  let output_required_size = payload.mesh_inputs.length().to_uint64() *
    MESH3D_PREPASS_MESH_BUFFER_SIZE
  let (output_buffer, output_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].output_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity,
    output_required_size,
    "mgstudio_mesh3d_preprocess_output",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].output_buffer = output_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].output_capacity = output_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].output_count = payload.mesh_inputs.length()
  let (preprocess_view_buffer, preprocess_view_capacity) = mesh3d_preprocess_upload_uniform_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity,
    preprocess_view_bytes,
    "mgstudio_mesh3d_preprocess_view",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
  = preprocess_view_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  = preprocess_view_capacity
  let (previous_view_buffer, previous_view_capacity) = mesh3d_preprocess_upload_uniform_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity,
    previous_view_bytes,
    "mgstudio_mesh3d_preprocess_previous_view",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
  = previous_view_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  = previous_view_capacity
  let (mesh_culling_data_buffer, mesh_culling_data_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity,
    mesh_culling_data_bytes,
    "mgstudio_mesh3d_preprocess_mesh_culling_data",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
  = mesh_culling_data_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  = mesh_culling_data_capacity
  let direct_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.direct_work_items,
  )
  let (direct_work_item_buffer, direct_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity,
    direct_work_item_bytes,
    "mgstudio_mesh3d_preprocess_direct_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer
  = direct_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  = direct_work_item_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_count
  = payload.direct_work_items.length()
  let indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.indexed_work_items,
  )
  let (indexed_work_item_buffer, indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity,
    indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
  = indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  = indexed_work_item_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_count
  = payload.indexed_work_items.length()
  let non_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.non_indexed_work_items,
  )
  let (non_indexed_work_item_buffer, non_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity,
    non_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
  = non_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  = non_indexed_work_item_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_count
  = payload.non_indexed_work_items.length()
  let late_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.late_indexed_work_items,
  )
  let (late_indexed_work_item_buffer, late_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity,
    late_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_late_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
  = late_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  = late_indexed_work_item_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_count
  = payload.late_indexed_work_items.length()
  if self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is None {
    let (buffer, capacity) = mesh3d_preprocess_ensure_storage_buffer(
      self,
      None,
      0UL,
      8UL,
      "mgstudio_mesh3d_preprocess_late_indexed_work_items",
    )
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    = buffer
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
    = capacity
  }
  let late_non_indexed_work_item_bytes = mesh3d_preprocess_work_items_bytes(
    payload.late_non_indexed_work_items,
  )
  let (late_non_indexed_work_item_buffer, late_non_indexed_work_item_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity,
    late_non_indexed_work_item_bytes,
    "mgstudio_mesh3d_preprocess_late_non_indexed_work_items",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
  = late_non_indexed_work_item_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  = late_non_indexed_work_item_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_count
  = payload.late_non_indexed_work_items.length()
  if self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is None {
    let (buffer, capacity) = mesh3d_preprocess_ensure_storage_buffer(
      self,
      None,
      0UL,
      8UL,
      "mgstudio_mesh3d_preprocess_late_non_indexed_work_items",
    )
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    = buffer
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
    = capacity
  }
  let (
    late_indexed_dispatch_indirect_buffer,
    late_indexed_dispatch_indirect_capacity,
  ) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity,
    late_dispatch_default_bytes,
    "mgstudio_mesh3d_preprocess_late_indexed_dispatch_indirect",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
  = late_indexed_dispatch_indirect_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_capacity
  = late_indexed_dispatch_indirect_capacity
  let (
    late_non_indexed_dispatch_indirect_buffer,
    late_non_indexed_dispatch_indirect_capacity,
  ) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity,
    late_dispatch_default_bytes,
    "mgstudio_mesh3d_preprocess_late_non_indexed_dispatch_indirect",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
  = late_non_indexed_dispatch_indirect_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_capacity
  = late_non_indexed_dispatch_indirect_capacity

  let indexed_cpu_metadata_bytes = mesh3d_preprocess_cpu_metadata_bytes(
    payload.indexed_cpu_metadata,
  )
  let indexed_cpu_metadata_bytes_len_u32 = indexed_cpu_metadata_bytes.length() /
    4
  if indexed_cpu_metadata_bytes_len_u32 !=
    payload.indexed_cpu_metadata.length() *
    MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 {
    return
  }
  let (indexed_cpu_metadata_buffer, indexed_cpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity,
    indexed_cpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_indexed_cpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
  = indexed_cpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  = indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_bytes = mesh3d_preprocess_gpu_metadata_bytes(
    payload.indexed_gpu_metadata,
  )
  let indexed_gpu_metadata_bytes_len_u32 = indexed_gpu_metadata_bytes.length() /
    4
  if indexed_gpu_metadata_bytes_len_u32 !=
    payload.indexed_gpu_metadata.length() *
    MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 {
    return
  }
  let (indexed_gpu_metadata_buffer, indexed_gpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity,
    indexed_gpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_indexed_gpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
  = indexed_gpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  = indexed_gpu_metadata_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_count
  = payload.indexed_gpu_metadata.length()
  let indexed_batch_set_bytes = mesh3d_preprocess_batch_set_bytes(
    payload.indexed_batch_sets,
  )
  let indexed_batch_set_bytes_len_u32 = indexed_batch_set_bytes.length() / 4
  if indexed_batch_set_bytes_len_u32 !=
    payload.indexed_batch_sets.length() * MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 {
    return
  }
  let (indexed_batch_set_buffer, indexed_batch_set_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity,
    indexed_batch_set_bytes,
    "mgstudio_mesh3d_preprocess_indexed_batch_sets",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
  = indexed_batch_set_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  = indexed_batch_set_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_count
  = payload.indexed_batch_sets.length()
  let indexed_indirect_parameters_required_size = payload.indexed_gpu_metadata
    .length()
    .to_uint64() *
    MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
  let (indexed_indirect_parameters_buffer, indexed_indirect_parameters_capacity) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity,
    indexed_indirect_parameters_required_size,
    "mgstudio_mesh3d_preprocess_indexed_indirect_parameters",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer
  = indexed_indirect_parameters_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  = indexed_indirect_parameters_capacity

  let non_indexed_cpu_metadata_bytes = mesh3d_preprocess_cpu_metadata_bytes(
    payload.non_indexed_cpu_metadata,
  )
  let non_indexed_cpu_metadata_bytes_len_u32 = non_indexed_cpu_metadata_bytes.length() /
    4
  if non_indexed_cpu_metadata_bytes_len_u32 !=
    payload.non_indexed_cpu_metadata.length() *
    MESH3D_PREPROCESS_CPU_METADATA_STRIDE_U32 {
    return
  }
  let (non_indexed_cpu_metadata_buffer, non_indexed_cpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity,
    non_indexed_cpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_cpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
  = non_indexed_cpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  = non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_bytes = mesh3d_preprocess_gpu_metadata_bytes(
    payload.non_indexed_gpu_metadata,
  )
  let non_indexed_gpu_metadata_bytes_len_u32 = non_indexed_gpu_metadata_bytes.length() /
    4
  if non_indexed_gpu_metadata_bytes_len_u32 !=
    payload.non_indexed_gpu_metadata.length() *
    MESH3D_PREPROCESS_GPU_METADATA_STRIDE_U32 {
    return
  }
  let (non_indexed_gpu_metadata_buffer, non_indexed_gpu_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity,
    non_indexed_gpu_metadata_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_gpu_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
  = non_indexed_gpu_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  = non_indexed_gpu_metadata_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_count
  = payload.non_indexed_gpu_metadata.length()
  let non_indexed_batch_set_bytes = mesh3d_preprocess_batch_set_bytes(
    payload.non_indexed_batch_sets,
  )
  let non_indexed_batch_set_bytes_len_u32 = non_indexed_batch_set_bytes.length() /
    4
  if non_indexed_batch_set_bytes_len_u32 !=
    payload.non_indexed_batch_sets.length() *
    MESH3D_PREPROCESS_BATCH_SET_STRIDE_U32 {
    return
  }
  let (non_indexed_batch_set_buffer, non_indexed_batch_set_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity,
    non_indexed_batch_set_bytes,
    "mgstudio_mesh3d_preprocess_non_indexed_batch_sets",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
  = non_indexed_batch_set_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  = non_indexed_batch_set_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_count
  = payload.non_indexed_batch_sets.length()
  let non_indexed_indirect_parameters_required_size = payload.non_indexed_gpu_metadata
    .length()
    .to_uint64() *
    MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
  let (
    non_indexed_indirect_parameters_buffer,
    non_indexed_indirect_parameters_capacity,
  ) = mesh3d_preprocess_ensure_storage_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity,
    non_indexed_indirect_parameters_required_size,
    "mgstudio_mesh3d_preprocess_non_indexed_indirect_parameters",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer
  = non_indexed_indirect_parameters_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  = non_indexed_indirect_parameters_capacity

  let dispatch_metadata_bytes = mesh3d_preprocess_dispatch_metadata_bytes(
    payload.dispatch_metadata,
  )
  let (dispatch_metadata_buffer, dispatch_metadata_capacity) = mesh3d_preprocess_upload_buffer(
    self,
    self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_buffer,
    self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_capacity,
    dispatch_metadata_bytes,
    "mgstudio_mesh3d_preprocess_dispatch_metadata",
  )
  self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_buffer
  = dispatch_metadata_buffer
  self.mesh3d_preprocess_camera_upload_states[state_index].dispatch_metadata_capacity
  = dispatch_metadata_capacity
  self.mesh3d_preprocess_camera_upload_states[state_index].direct_workgroup_count
  = payload.dispatch_metadata.direct_workgroup_count
  self.mesh3d_preprocess_camera_upload_states[state_index].indexed_workgroup_count
  = payload.dispatch_metadata.indexed_workgroup_count
  self.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_workgroup_count
  = payload.dispatch_metadata.non_indexed_workgroup_count
  let requested_depth_pyramid_width = mesh3d_preprocess_previous_power_of_two(
    if payload.view.main_pass_viewport_width <= 1.0F {
      1
    } else {
      payload.view.main_pass_viewport_width.to_int()
    },
  )
  let requested_depth_pyramid_height = mesh3d_preprocess_previous_power_of_two(
    if payload.view.main_pass_viewport_height <= 1.0F {
      1
    } else {
      payload.view.main_pass_viewport_height.to_int()
    },
  )
  let requested_depth_pyramid_mip_count = mesh3d_preprocess_depth_pyramid_mip_count(
    requested_depth_pyramid_width, requested_depth_pyramid_height,
  )
  let current_state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let depth_pyramid_needs_resize = current_state.depth_pyramid_texture is None ||
    current_state.depth_pyramid_width != requested_depth_pyramid_width ||
    current_state.depth_pyramid_height != requested_depth_pyramid_height ||
    current_state.depth_pyramid_mip_count != requested_depth_pyramid_mip_count
  if depth_pyramid_needs_resize {
    for view in current_state.depth_pyramid_mips {
      view.release()
    }
    current_state.depth_pyramid_mips.clear()
    if current_state.depth_pyramid_all_mips_view is Some(view) {
      view.release()
    }
    if current_state.depth_pyramid_texture is Some(texture) {
      texture.release()
    }
    let usage = @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
    )
    let texture = self.device.create_texture_u32(
      requested_depth_pyramid_width.reinterpret_as_uint(),
      requested_depth_pyramid_height.reinterpret_as_uint(),
      1U,
      usage,
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      mip_level_count=requested_depth_pyramid_mip_count.reinterpret_as_uint(),
    )
    let all_mips_view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      requested_depth_pyramid_mip_count.reinterpret_as_uint(),
    )
    let mip_views : Array[@wgpu.TextureView] = []
    for mip_level in 0..<requested_depth_pyramid_mip_count {
      mip_views.push(
        texture.create_view_u32(
          tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
          @wgpu.TEXTURE_VIEW_DIMENSION_2D,
          @wgpu.TEXTURE_ASPECT_ALL,
          0U,
          1U,
          mip_level.reinterpret_as_uint(),
          1U,
        ),
      )
    }
    current_state.depth_pyramid_texture = Some(texture)
    current_state.depth_pyramid_all_mips_view = Some(all_mips_view)
    current_state.depth_pyramid_mips = mip_views
    current_state.depth_pyramid_width = requested_depth_pyramid_width
    current_state.depth_pyramid_height = requested_depth_pyramid_height
    current_state.depth_pyramid_mip_count = requested_depth_pyramid_mip_count
  }
  let direct_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_direct_work_item_capacity != direct_work_item_capacity ||
    old_output_capacity != output_capacity
  if direct_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
    = None
  }
  let indexed_main_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_indexed_work_item_capacity != indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity
  if indexed_main_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
    = None
  }
  let non_indexed_main_bind_group_dirty = old_preprocess_view_capacity !=
    preprocess_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_non_indexed_work_item_capacity != non_indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity
  if non_indexed_main_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
    = None
  }
  let indexed_early_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_indexed_work_item_capacity != indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_indexed_work_item_capacity != late_indexed_work_item_capacity ||
    old_late_indexed_dispatch_capacity !=
    late_indexed_dispatch_indirect_capacity
  if indexed_early_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
    = None
  }
  let indexed_late_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_output_capacity != output_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_indexed_work_item_capacity != late_indexed_work_item_capacity ||
    old_late_indexed_dispatch_capacity !=
    late_indexed_dispatch_indirect_capacity
  if indexed_late_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
    = None
  }
  let non_indexed_early_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_non_indexed_work_item_capacity != non_indexed_work_item_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_non_indexed_work_item_capacity !=
    late_non_indexed_work_item_capacity ||
    old_late_non_indexed_dispatch_capacity !=
    late_non_indexed_dispatch_indirect_capacity
  if non_indexed_early_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
    = None
  }
  let non_indexed_late_bind_group_dirty = depth_pyramid_needs_resize ||
    old_preprocess_view_capacity != preprocess_view_capacity ||
    old_previous_view_capacity != previous_view_capacity ||
    old_mesh_input_capacity != mesh_input_capacity ||
    old_previous_mesh_input_capacity != previous_mesh_input_capacity ||
    old_output_capacity != output_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_mesh_culling_data_capacity != mesh_culling_data_capacity ||
    old_late_non_indexed_work_item_capacity !=
    late_non_indexed_work_item_capacity ||
    old_late_non_indexed_dispatch_capacity !=
    late_non_indexed_dispatch_indirect_capacity
  if non_indexed_late_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
    = None
  }
  let indexed_reset_bind_group_dirty = old_indexed_batch_set_capacity !=
    indexed_batch_set_capacity
  if indexed_reset_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
    = None
  }
  let non_indexed_reset_bind_group_dirty = old_non_indexed_batch_set_capacity !=
    non_indexed_batch_set_capacity
  if non_indexed_reset_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
    = None
  }
  let indexed_build_bind_group_dirty = old_mesh_input_capacity !=
    mesh_input_capacity ||
    old_indexed_cpu_metadata_capacity != indexed_cpu_metadata_capacity ||
    old_indexed_gpu_metadata_capacity != indexed_gpu_metadata_capacity ||
    old_indexed_batch_set_capacity != indexed_batch_set_capacity ||
    old_indexed_indirect_parameters_capacity !=
    indexed_indirect_parameters_capacity
  if indexed_build_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    = None
  }
  let non_indexed_build_bind_group_dirty = old_mesh_input_capacity !=
    mesh_input_capacity ||
    old_non_indexed_cpu_metadata_capacity != non_indexed_cpu_metadata_capacity ||
    old_non_indexed_gpu_metadata_capacity != non_indexed_gpu_metadata_capacity ||
    old_non_indexed_batch_set_capacity != non_indexed_batch_set_capacity ||
    old_non_indexed_indirect_parameters_capacity !=
    non_indexed_indirect_parameters_capacity
  if non_indexed_build_bind_group_dirty {
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    = None
  }
  mesh3d_preprocess_main_direct_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_main_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_main_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_early_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_early_non_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_preprocess_late_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_preprocess_late_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_build_indirect_reset_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_build_indirect_reset_non_indexed_bind_group_get_or_create(
    self, state_index,
  )
  |> ignore
  mesh3d_build_indirect_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
  mesh3d_build_indirect_non_indexed_bind_group_get_or_create(self, state_index)
  |> ignore
}

///|
pub fn GpuBackend::preprocess_mesh3d(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  phase_kind : Int,
) -> Unit raise GpuBackendError {
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard self.frame is Some(frame) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let compute_pass = frame.encoder.begin_compute_pass()
  if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN {
    if state.direct_workgroup_count > 0 &&
      state.direct_work_item_count > 0 &&
      self.mesh3d_preprocess_direct_pipeline is Some(preprocess_direct_pipeline) &&
      state.preprocess_main_direct_bind_group is Some(bind_group) {
      compute_pass.set_pipeline(preprocess_direct_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.direct_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    }
  }
  let indexed_work_item_buffer = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_indexed_work_item_buffer
  } else {
    state.indexed_work_item_buffer
  }
  let indexed_work_item_count = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_indexed_work_item_count
  } else {
    state.indexed_work_item_count
  }
  let non_indexed_work_item_buffer = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_non_indexed_work_item_buffer
  } else {
    state.non_indexed_work_item_buffer
  }
  let non_indexed_work_item_count = if phase_kind ==
    MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION {
    state.late_non_indexed_work_item_count
  } else {
    state.non_indexed_work_item_count
  }
  if indexed_work_item_count > 0 && indexed_work_item_buffer is Some(_) {
    if phase_kind == MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
      is Some(bind_group) &&
      self.mesh3d_preprocess_indirect_early_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.indexed_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
      is Some(bind_group) &&
      state.late_indexed_dispatch_indirect_buffer is Some(late_dispatch_buffer) &&
      self.mesh3d_preprocess_indirect_late_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups_indirect(late_dispatch_buffer, 0UL)
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN &&
      self.mesh3d_preprocess_indirect_pipeline is Some(preprocess_pipeline) {
      if self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
        is Some(bind_group) {
        compute_pass.set_pipeline(preprocess_pipeline)
        compute_pass.set_bind_group(0U, bind_group, [])
        compute_pass.dispatch_workgroups(
          state.indexed_workgroup_count.reinterpret_as_uint(),
          1U,
          1U,
        )
      }
    }
  }
  if non_indexed_work_item_count > 0 && non_indexed_work_item_buffer is Some(_) {
    if phase_kind == MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
      is Some(bind_group) &&
      self.mesh3d_preprocess_indirect_early_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups(
        state.non_indexed_workgroup_count.reinterpret_as_uint(),
        1U,
        1U,
      )
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION &&
      self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
      is Some(bind_group) &&
      state.late_non_indexed_dispatch_indirect_buffer
      is Some(late_dispatch_buffer) &&
      self.mesh3d_preprocess_indirect_late_occlusion_pipeline
      is Some(preprocess_pipeline) {
      compute_pass.set_pipeline(preprocess_pipeline)
      compute_pass.set_bind_group(0U, bind_group, [])
      compute_pass.dispatch_workgroups_indirect(late_dispatch_buffer, 0UL)
    } else if phase_kind == MESH3D_PREPROCESS_PHASE_MAIN &&
      self.mesh3d_preprocess_indirect_pipeline is Some(preprocess_pipeline) {
      if self.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
        is Some(bind_group) {
        compute_pass.set_pipeline(preprocess_pipeline)
        compute_pass.set_bind_group(0U, bind_group, [])
        compute_pass.dispatch_workgroups(
          state.non_indexed_workgroup_count.reinterpret_as_uint(),
          1U,
          1U,
        )
      }
    }
  }
  compute_pass.end()
  compute_pass.release()
}

///|
pub fn GpuBackend::build_mesh3d_indirect_parameters(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  phase_kind : Int,
) -> Unit raise GpuBackendError {
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard self.frame is Some(frame) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  let compute_pass = frame.encoder.begin_compute_pass()
  if state.indexed_batch_set_count > 0 &&
    self.mesh3d_preprocess_reset_batch_sets_pipeline is Some(reset_pipeline) {
    if self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
      is Some(bind_group) {
      compute_pass.set_pipeline(reset_pipeline)
      compute_pass.set_bind_group0(bind_group)
      let workgroup_count = ((
        state.indexed_batch_set_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
      ) /
      MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
      compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
    }
  }
  if state.indexed_gpu_metadata_count > 0 &&
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    is Some(bind_group) {
    let indexed_pipeline = if phase_kind == MESH3D_BUILD_INDIRECT_PHASE_EARLY {
      self.mesh3d_preprocess_build_indexed_indirect_early_pipeline
    } else {
      self.mesh3d_preprocess_build_indexed_indirect_pipeline
    }
    guard indexed_pipeline is Some(indexed_pipeline) else {
      compute_pass.end()
      compute_pass.release()
      return
    }
    compute_pass.set_pipeline(indexed_pipeline)
    compute_pass.set_bind_group0(bind_group)
    let workgroup_count = ((
      state.indexed_gpu_metadata_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
    ) /
    MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
    compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
  }
  if state.non_indexed_batch_set_count > 0 &&
    self.mesh3d_preprocess_reset_batch_sets_pipeline is Some(reset_pipeline) {
    if self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
      is Some(bind_group) {
      compute_pass.set_pipeline(reset_pipeline)
      compute_pass.set_bind_group0(bind_group)
      let workgroup_count = ((
        state.non_indexed_batch_set_count + MESH3D_PREPROCESS_WORKGROUP_SIZE - 1
      ) /
      MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
      compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
    }
  }
  if state.non_indexed_gpu_metadata_count > 0 &&
    self.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    is Some(bind_group) {
    let non_indexed_pipeline = if phase_kind ==
      MESH3D_BUILD_INDIRECT_PHASE_EARLY {
      self.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline
    } else {
      self.mesh3d_preprocess_build_non_indexed_indirect_pipeline
    }
    guard non_indexed_pipeline is Some(non_indexed_pipeline) else {
      compute_pass.end()
      compute_pass.release()
      return
    }
    compute_pass.set_pipeline(non_indexed_pipeline)
    compute_pass.set_bind_group0(bind_group)
    let workgroup_count = ((
      state.non_indexed_gpu_metadata_count +
      MESH3D_PREPROCESS_WORKGROUP_SIZE -
      1
    ) /
    MESH3D_PREPROCESS_WORKGROUP_SIZE).reinterpret_as_uint()
    compute_pass.dispatch_workgroups(workgroup_count, 1U, 1U)
  }
  compute_pass.end()
  compute_pass.release()
}

///|
pub fn GpuBackend::downsample_mesh3d_depth_pyramid(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.depth_view is Some(depth_view) else { return }
  guard mesh3d_preprocess_camera_upload_state_index(
      self, camera_key_hi, camera_key_lo,
    )
    is Some(state_index) else {
    return
  }
  ensure_mesh3d_preprocess_indirect_resources(self)
  let state = self.mesh3d_preprocess_camera_upload_states[state_index]
  guard state.depth_pyramid_mip_count > 1 else { return }
  guard self.mesh3d_preprocess_depth_pyramid_dummy_view is Some(dummy_view) else {
    return
  }
  guard self.mesh3d_preprocess_depth_pyramid_sampler is Some(sampler) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_bgl is Some(downsample_bgl) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_first_pipeline
    is Some(first_pipeline) else {
    return
  }
  guard self.mesh3d_preprocess_downsample_depth_second_pipeline
    is Some(second_pipeline) else {
    return
  }
  let mip_views = state.depth_pyramid_mips
  let mip_or_dummy = fn(index : Int) -> @wgpu.TextureView {
    if index >= 0 && index < mip_views.length() {
      mip_views[index]
    } else {
      dummy_view
    }
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let ok = builder.add_texture_view(0U, depth_view) &&
    builder.add_texture_view(1U, mip_or_dummy(1)) &&
    builder.add_texture_view(2U, mip_or_dummy(2)) &&
    builder.add_texture_view(3U, mip_or_dummy(3)) &&
    builder.add_texture_view(4U, mip_or_dummy(4)) &&
    builder.add_texture_view(5U, mip_or_dummy(5)) &&
    builder.add_texture_view(6U, mip_or_dummy(6)) &&
    builder.add_texture_view(7U, mip_or_dummy(7)) &&
    builder.add_texture_view(8U, mip_or_dummy(8)) &&
    builder.add_texture_view(9U, mip_or_dummy(9)) &&
    builder.add_texture_view(10U, mip_or_dummy(10)) &&
    builder.add_texture_view(11U, mip_or_dummy(11)) &&
    builder.add_texture_view(12U, mip_or_dummy(12)) &&
    builder.add_sampler(13U, sampler)
  if !ok {
    builder.free()
    return
  }
  let bind_group = builder.finish(
    self.device,
    downsample_bgl,
    label="mgstudio_mesh3d_preprocess_downsample_depth_bg",
  )
  let dispatch_x = (
      mesh3d_preprocess_depth_pyramid_dispatch_size(state.depth_pyramid_width) +
      63U
    ) /
    64U
  let dispatch_y = (
      mesh3d_preprocess_depth_pyramid_dispatch_size(state.depth_pyramid_height) +
      63U
    ) /
    64U
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_bind_group0(bind_group)
  compute_pass.set_pipeline(first_pipeline)
  compute_pass.dispatch_workgroups(dispatch_x, dispatch_y, 1U)
  if state.depth_pyramid_mip_count >= 7 {
    compute_pass.set_pipeline(second_pipeline)
    compute_pass.dispatch_workgroups(1U, 1U, 1U)
  }
  compute_pass.end()
  compute_pass.release()
  bind_group.release()
}

///|
fn mesh3d_preprocess_camera_upload_state(
  backend : GpuBackend,
  key_hi : Int,
  key_lo : Int,
) -> GpuMesh3dPreprocessCameraUploadState? {
  guard mesh3d_preprocess_camera_upload_state_index(backend, key_hi, key_lo)
    is Some(state_index) else {
    return None
  }
  Some(backend.mesh3d_preprocess_camera_upload_states[state_index])
}

///|
fn mesh3d_preprocess_motion_vector_mesh_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].motion_vector_mesh_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_motion_vector_bgl_mesh is Some(mesh_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  let output_count = backend.mesh3d_preprocess_camera_upload_states[state_index].output_count
  if output_count <= 0 {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      output_buffer,
      size=output_count.to_uint64() * MESH3D_PREPASS_MESH_BUFFER_SIZE,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    mesh_bgl,
    label="mgstudio_motion_vector_preprocess_mesh_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].motion_vector_mesh_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_direct_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_direct_bgl is Some(preprocess_direct_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_buffer
    is Some(direct_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let direct_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].direct_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    direct_work_item_capacity == 0UL ||
    output_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      direct_work_item_buffer,
      size=direct_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity)
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_direct_bgl,
    label="mgstudio_mesh3d_preprocess_direct_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_direct_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_bgl is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
    is Some(indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      indexed_work_item_buffer,
      size=indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_main_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_bgl is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
    is Some(non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      non_indexed_work_item_buffer,
      size=non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_main_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_early_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_early_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_buffer
    is Some(indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is Some(late_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
    is Some(late_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let late_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL ||
    late_indexed_work_item_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      indexed_work_item_buffer,
      size=indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      11U,
      late_indexed_work_item_buffer,
      size=late_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(
      12U,
      late_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_early_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_late_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_late_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_buffer
    is Some(late_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_dispatch_indirect_buffer
    is Some(late_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let late_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    late_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      late_indexed_work_item_buffer,
      size=late_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      12U,
      late_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_indexed_late_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_early_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_early_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_buffer
    is Some(non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is Some(late_non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
    is Some(late_non_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  let late_non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL ||
    late_non_indexed_work_item_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      non_indexed_work_item_buffer,
      size=non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      11U,
      late_non_indexed_work_item_buffer,
      size=late_non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(
      12U,
      late_non_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_early_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_early_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_preprocess_late_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_indirect_late_occlusion_bgl
    is Some(preprocess_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_buffer
    is Some(preprocess_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_buffer
    is Some(previous_view_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_buffer
    is Some(previous_mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_buffer
    is Some(late_non_indexed_work_item_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].output_buffer
    is Some(output_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_buffer
    is Some(mesh_culling_data_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].depth_pyramid_all_mips_view
    is Some(depth_pyramid_all_mips_view) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_dispatch_indirect_buffer
    is Some(late_non_indexed_dispatch_buffer) else {
    return None
  }
  let preprocess_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_view_capacity
  let previous_view_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_view_capacity
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let previous_mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].previous_mesh_input_capacity
  let late_non_indexed_work_item_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].late_non_indexed_work_item_capacity
  let output_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].output_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let mesh_culling_data_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_culling_data_capacity
  if preprocess_view_capacity == 0UL ||
    previous_view_capacity == 0UL ||
    mesh_input_capacity == 0UL ||
    previous_mesh_input_capacity == 0UL ||
    late_non_indexed_work_item_capacity == 0UL ||
    output_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    mesh_culling_data_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(
      0U,
      preprocess_view_buffer,
      size=preprocess_view_capacity,
    ) &&
    builder.add_buffer(2U, previous_view_buffer, size=previous_view_capacity) &&
    builder.add_buffer(3U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      4U,
      previous_mesh_input_buffer,
      size=previous_mesh_input_capacity,
    ) &&
    builder.add_buffer(
      5U,
      late_non_indexed_work_item_buffer,
      size=late_non_indexed_work_item_capacity,
    ) &&
    builder.add_buffer(6U, output_buffer, size=output_capacity) &&
    builder.add_buffer(
      7U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      8U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      9U,
      mesh_culling_data_buffer,
      size=mesh_culling_data_capacity,
    ) &&
    builder.add_texture_view(10U, depth_pyramid_all_mips_view) &&
    builder.add_buffer(
      12U,
      late_non_indexed_dispatch_buffer,
      size=MESH3D_PREPROCESS_LATE_DISPATCH_PARAMETERS_STRIDE_BYTES,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    preprocess_bgl,
    label="mgstudio_mesh3d_preprocess_non_indexed_late_occlusion_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].preprocess_late_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_reset_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_reset_batch_sets_bgl is Some(reset_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
    is Some(indexed_batch_set_buffer) else {
    return None
  }
  let indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  if indexed_batch_set_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      indexed_batch_set_buffer,
      size=indexed_batch_set_capacity,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    reset_bgl,
    label="mgstudio_mesh3d_preprocess_reset_indexed_batch_sets_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_reset_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_reset_batch_sets_bgl is Some(reset_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
    is Some(non_indexed_batch_set_buffer) else {
    return None
  }
  let non_indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  if non_indexed_batch_set_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  if !builder.add_buffer(
      0U,
      non_indexed_batch_set_buffer,
      size=non_indexed_batch_set_capacity,
    ) {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    reset_bgl,
    label="mgstudio_mesh3d_preprocess_reset_non_indexed_batch_sets_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_reset_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_build_indexed_indirect_bgl
    is Some(indexed_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_buffer
    is Some(indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_buffer
    is Some(indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_buffer
    is Some(indexed_batch_set_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_buffer
    is Some(indexed_indirect_parameters_buffer) else {
    return None
  }
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_cpu_metadata_capacity
  let indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_gpu_metadata_capacity
  let indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_batch_set_capacity
  let indexed_indirect_parameters_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].indexed_indirect_parameters_capacity
  if mesh_input_capacity == 0UL ||
    indexed_cpu_metadata_capacity == 0UL ||
    indexed_gpu_metadata_capacity == 0UL ||
    indexed_batch_set_capacity == 0UL ||
    indexed_indirect_parameters_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(0U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      1U,
      indexed_cpu_metadata_buffer,
      size=indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      2U,
      indexed_gpu_metadata_buffer,
      size=indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      3U,
      indexed_batch_set_buffer,
      size=indexed_batch_set_capacity,
    ) &&
    builder.add_buffer(
      4U,
      indexed_indirect_parameters_buffer,
      size=indexed_indirect_parameters_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    indexed_bgl,
    label="mgstudio_mesh3d_preprocess_build_indexed_indirect_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_build_indirect_non_indexed_bind_group_get_or_create(
  backend : GpuBackend,
  state_index : Int,
) -> @wgpu.BindGroup? {
  if backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
    is Some(bind_group) {
    return Some(bind_group)
  }
  guard backend.mesh3d_preprocess_build_non_indexed_indirect_bgl
    is Some(non_indexed_bgl) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_buffer
    is Some(mesh_input_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_buffer
    is Some(non_indexed_cpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_buffer
    is Some(non_indexed_gpu_metadata_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_buffer
    is Some(non_indexed_batch_set_buffer) else {
    return None
  }
  guard backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_buffer
    is Some(non_indexed_indirect_parameters_buffer) else {
    return None
  }
  let mesh_input_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].mesh_input_capacity
  let non_indexed_cpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_cpu_metadata_capacity
  let non_indexed_gpu_metadata_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_gpu_metadata_capacity
  let non_indexed_batch_set_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_batch_set_capacity
  let non_indexed_indirect_parameters_capacity = backend.mesh3d_preprocess_camera_upload_states[state_index].non_indexed_indirect_parameters_capacity
  if mesh_input_capacity == 0UL ||
    non_indexed_cpu_metadata_capacity == 0UL ||
    non_indexed_gpu_metadata_capacity == 0UL ||
    non_indexed_batch_set_capacity == 0UL ||
    non_indexed_indirect_parameters_capacity == 0UL {
    return None
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_buffer(0U, mesh_input_buffer, size=mesh_input_capacity) &&
    builder.add_buffer(
      1U,
      non_indexed_cpu_metadata_buffer,
      size=non_indexed_cpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      2U,
      non_indexed_gpu_metadata_buffer,
      size=non_indexed_gpu_metadata_capacity,
    ) &&
    builder.add_buffer(
      3U,
      non_indexed_batch_set_buffer,
      size=non_indexed_batch_set_capacity,
    ) &&
    builder.add_buffer(
      4U,
      non_indexed_indirect_parameters_buffer,
      size=non_indexed_indirect_parameters_capacity,
    )
  if !ok {
    builder.free()
    return None
  }
  let bind_group = builder.finish(
    backend.device,
    non_indexed_bgl,
    label="mgstudio_mesh3d_preprocess_build_non_indexed_indirect_bg",
  )
  backend.mesh3d_preprocess_camera_upload_states[state_index].build_indirect_non_indexed_bind_group
  = Some(bind_group)
  Some(bind_group)
}

///|
fn mesh3d_indexed_indirect_offset(indirect_parameters_index : Int) -> UInt64 {
  indirect_parameters_index.to_uint64() *
  MESH3D_PREPROCESS_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
}

///|
fn mesh3d_non_indexed_indirect_offset(
  indirect_parameters_index : Int,
) -> UInt64 {
  indirect_parameters_index.to_uint64() *
  MESH3D_PREPROCESS_NON_INDEXED_INDIRECT_PARAMETERS_STRIDE_BYTES
}

///|
pub fn GpuBackend::draw_mesh3d(
  self : GpuBackend,
  mesh_id : Int,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
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
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_transform_a : Float,
  uv_transform_b : Float,
  uv_transform_c : Float,
  uv_transform_d : Float,
  uv_transform_tx : Float,
  uv_transform_ty : Float,
  uv_transform_mode : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
  parallax_depth_scale : Float,
  max_parallax_layer_count : Float,
  max_relief_mapping_search_steps : Float,
  anisotropy_texture_id : Int,
  anisotropy_strength : Float,
  anisotropy_rotation : Float,
  specular_tint_texture_id : Int,
  specular_tint_r : Float,
  specular_tint_g : Float,
  specular_tint_b : Float,
  diffuse_transmission : Float,
  specular_transmission : Float,
  thickness : Float,
  ior : Float,
  alpha_cutoff : Float,
  material_flags : UInt,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_diffuse_texture_id : Int,
  environment_specular_texture_id : Int,
  environment_map_intensity : Float,
  environment_map_rotation_x : Float,
  environment_map_rotation_y : Float,
  environment_map_rotation_z : Float,
  environment_map_rotation_w : Float,
  cull_mode : Int,
  shader_path : String?,
  skinning_key_hi : Int,
  skinning_key_lo : Int,
  skinning_matrices? : Array[Float]? = None,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard frame.pass is Some(pass) else { return }
  guard self.pass_state is Some(ps) else { return }
  transmission_source_texture_id |> ignore
  transmission_blur_taps |> ignore
  transmission_steps |> ignore
  point_shadow_texture_id |> ignore
  environment_diffuse_texture_id |> ignore
  environment_specular_texture_id |> ignore
  environment_map_intensity |> ignore
  environment_map_rotation_x |> ignore
  environment_map_rotation_y |> ignore
  environment_map_rotation_z |> ignore
  environment_map_rotation_w |> ignore
  skinning_matrices |> ignore
  if !ps.is_3d {
    return
  }
  flush_mesh2d_batches(self)
  flush_ui_shadow_batches(self)
  flush_ui_slice_batches(self)
  flush_ui_batches(self)
  flush_sprite_batches(self)
  guard find_mesh(self, mesh_id) is Some(mesh) else { return }
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES {
    return
  }
  let transparent = color_a < 0.999F
  let pass_kind_raw = ps.pass_kind
  if !pass_kind_decal_enabled(pass_kind_raw) && mesh3d_draw_is_decal(cull_mode) {
    return
  }
  if !pass_kind_fog_enabled(pass_kind_raw) && mesh3d_draw_is_fog(cull_mode) {
    return
  }
  if !pass_kind_postprocess_enabled(pass_kind_raw) &&
    mesh3d_draw_is_postprocess_proxy(cull_mode) {
    return
  }
  let pass_kind = pass_kind_base_kind(pass_kind_raw)
  if pass_kind == PASS_KIND_BASE_MOTION_VECTOR {
    if mesh.primitive_topology != MESH3D_TOPOLOGY_TRIANGLE_LIST {
      return
    }
    if transparent {
      return
    }
    ensure_mesh3d_motion_vector_pipeline(self)
    guard self.mesh3d_motion_vector_pipeline is Some(pipeline) else { return }
    guard self.mesh3d_motion_vector_view_buf is Some(view_buf) else { return }
    guard self.mesh3d_motion_vector_previous_view_buf is Some(previous_view_buf) else {
      return
    }
    guard self.mesh3d_motion_vector_view_bg is Some(view_bg) else { return }
    guard self.mesh3d_motion_vector_empty_bg is Some(empty_bg) else { return }
    let preprocess_state_index = mesh3d_preprocess_camera_upload_state_index(
      self, preprocess_camera_key_hi, preprocess_camera_key_lo,
    )
    let preprocess_state = if preprocess_state_index is Some(state_index) {
      Some(self.mesh3d_preprocess_camera_upload_states[state_index])
    } else {
      None
    }
    let indirect_first_instance_supported = self.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
    )
    let use_indirect = indirect_first_instance_supported &&
      indirect_parameters_index >= 0 &&
      indirect_kind != MESH3D_DRAW_INDIRECT_KIND_NONE
    let mut mesh_buffer : @wgpu.Buffer? = None
    let mut mesh_bind_group : @wgpu.BindGroup? = None
    let mut mesh_write_offset = 0UL
    let mut mesh_index = 0U
    let mut writes_motion_vector_mesh = true
    if preprocess_state_index is Some(state_index) &&
      (use_indirect || draw_storage_index >= 0) &&
      mesh3d_preprocess_motion_vector_mesh_bind_group_get_or_create(
        self, state_index,
      )
      is Some(preprocess_mesh_bg) {
      mesh_bind_group = Some(preprocess_mesh_bg)
      mesh_index = if use_indirect {
        0U
      } else {
        draw_storage_index.reinterpret_as_uint()
      }
      writes_motion_vector_mesh = false
    } else if self.mesh3d_gpu_instance_builder_enabled || use_indirect {
      let desired_mesh_index = if draw_storage_index >= 0 {
        draw_storage_index
      } else {
        self.mesh3d_motion_vector_instance_mesh_used /
        MESH3D_PREPASS_MESH_BUFFER_SIZE.to_int()
      }
      let next_used_int = (desired_mesh_index + 1) *
        MESH3D_PREPASS_MESH_BUFFER_SIZE.to_int()
      if next_used_int < 0 {
        return
      }
      let required_size = next_used_int.to_uint64()
      guard ensure_mesh3d_motion_vector_instance_mesh_binding(
          self, required_size,
        )
        is Some((instance_mesh_buf, instance_mesh_bg)) else {
        return
      }
      mesh_index = desired_mesh_index.reinterpret_as_uint()
      mesh_buffer = Some(instance_mesh_buf)
      mesh_bind_group = Some(instance_mesh_bg)
      mesh_write_offset = desired_mesh_index.to_uint64() *
        MESH3D_PREPASS_MESH_BUFFER_SIZE
      if self.mesh3d_motion_vector_instance_mesh_used < next_used_int {
        self.mesh3d_motion_vector_instance_mesh_used = next_used_int
      }
    } else {
      let mesh_slot_index = self.mesh3d_motion_vector_mesh_slot_used
      guard ensure_mesh3d_motion_vector_mesh_slot(self, mesh_slot_index)
        is Some(mesh_slot) else {
        return
      }
      self.mesh3d_motion_vector_mesh_slot_used = mesh_slot_index + 1
      mesh_buffer = Some(mesh_slot.buffer)
      mesh_bind_group = Some(mesh_slot.bind_group)
      mesh_write_offset = 0UL
      mesh_index = 0U
    }
    guard mesh_bind_group is Some(active_mesh_bg) else { return }
    let motion_view_bytes = mesh3d_motion_vector_view_uniform_bytes(ps)
    let motion_view_needs_upload = match
      self.mesh3d_motion_vector_pass_view_uniform_bytes {
      Some(cached) => cached != motion_view_bytes
      None => true
    }
    if motion_view_needs_upload {
      self.queue.write_buffer(view_buf, 0UL, motion_view_bytes)
      self.mesh3d_motion_vector_pass_view_uniform_bytes = Some(
        motion_view_bytes,
      )
    }
    let motion_previous_view_bytes = mesh3d_motion_vector_previous_view_uniform_bytes(
      ps,
    )
    let motion_previous_view_needs_upload = match
      self.mesh3d_motion_vector_pass_previous_view_uniform_bytes {
      Some(cached) => cached != motion_previous_view_bytes
      None => true
    }
    if motion_previous_view_needs_upload {
      self.queue.write_buffer(
        previous_view_buf, 0UL, motion_previous_view_bytes,
      )
      self.mesh3d_motion_vector_pass_previous_view_uniform_bytes = Some(
        motion_previous_view_bytes,
      )
    }
    if writes_motion_vector_mesh {
      guard mesh_buffer is Some(active_mesh_buffer) else { return }
      self.queue.write_buffer(
        active_mesh_buffer,
        mesh_write_offset,
        mesh3d_motion_vector_mesh_bytes(
          x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
          scale_z, previous_x, previous_y, previous_z, previous_rotation_x, previous_rotation_y,
          previous_rotation_z, previous_rotation_w, previous_scale_x, previous_scale_y,
          previous_scale_z,
        ),
      )
    }
    pass.set_pipeline(pipeline)
    pass.set_bind_group(0U, view_bg, [])
    pass.set_bind_group(1U, empty_bg, [])
    pass.set_bind_group(2U, active_mesh_bg, [])
    let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
      mesh.vertex_stride_bytes
    pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
    if use_indirect && preprocess_state is Some(preprocess_state) {
      if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_INDEXED &&
        preprocess_state.indexed_indirect_parameters_buffer
        is Some(indexed_indirect_parameters_buffer) {
        gpu_mesh_bind_index_buffer(pass, mesh)
        pass.draw_indexed_indirect(
          indexed_indirect_parameters_buffer,
          mesh3d_indexed_indirect_offset(indirect_parameters_index),
        )
      } else if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED &&
        preprocess_state.non_indexed_indirect_parameters_buffer
        is Some(non_indexed_indirect_parameters_buffer) {
        pass.draw_indirect(
          non_indexed_indirect_parameters_buffer,
          mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
        )
      } else {
        gpu_mesh_bind_index_buffer(pass, mesh)
        pass.draw_indexed(mesh.index_count, 1U, 0U, 0, mesh_index)
      }
    } else {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed(mesh.index_count, 1U, 0U, 0, mesh_index)
    }
    return
  }
  let draw_shader_path = if pass_kind == 0 { shader_path } else { None }
  let forward_decal = (material_flags & (1U << 20)) != 0U
  guard mesh3d_pipeline_for_current_pass(
      self,
      transparent,
      forward_decal,
      mesh.primitive_topology,
      cull_mode,
      draw_shader_path,
    )
    is Some(pipeline) else {
    return
  }
  let indirect_first_instance_supported = self.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  let use_indirect = indirect_first_instance_supported &&
    indirect_parameters_index >= 0 &&
    indirect_kind != MESH3D_DRAW_INDIRECT_KIND_NONE
  let mut draw_buffer : @wgpu.Buffer? = None
  let mut draw_bind_group : @wgpu.BindGroup? = None
  let mut draw_write_offset = 0UL
  let mut draw_index = 0U
  if self.mesh3d_gpu_instance_builder_enabled || use_indirect {
    let desired_draw_index = if draw_storage_index >= 0 {
      draw_storage_index
    } else {
      self.mesh3d_instance_draw_used / MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    }
    let next_used_int = (desired_draw_index + 1) *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    if next_used_int < 0 {
      return
    }
    let required_size = next_used_int.to_uint64()
    guard ensure_mesh3d_instance_draw_binding(self, required_size)
      is Some((instance_draw_buf, instance_draw_bg)) else {
      return
    }
    draw_index = desired_draw_index.reinterpret_as_uint()
    draw_buffer = Some(instance_draw_buf)
    draw_bind_group = Some(instance_draw_bg)
    draw_write_offset = desired_draw_index.to_uint64() *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES
    if self.mesh3d_instance_draw_used < next_used_int {
      self.mesh3d_instance_draw_used = next_used_int
    }
  } else {
    let mesh3d_draw_slot_index = self.mesh3d_draw_slot_used
    guard ensure_mesh3d_draw_slot(self, mesh3d_draw_slot_index)
      is Some(draw_slot) else {
      return
    }
    self.mesh3d_draw_slot_used = mesh3d_draw_slot_index + 1
    draw_buffer = Some(draw_slot.buffer)
    draw_bind_group = Some(draw_slot.bind_group)
    draw_write_offset = 0UL
    draw_index = 0U
  }
  let resolved_base_texture_id = if texture_id < 0 { -1 } else { texture_id }
  let resolved_normal_texture_id = if normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
  } else {
    normal_texture_id
  }
  let resolved_emissive_texture_id = if emissive_texture_id < 0 {
    -1
  } else {
    emissive_texture_id
  }
  let resolved_metallic_roughness_texture_id = if metallic_roughness_texture_id <
    0 {
    -1
  } else {
    metallic_roughness_texture_id
  }
  let resolved_occlusion_texture_id = if occlusion_texture_id < 0 {
    -1
  } else {
    occlusion_texture_id
  }
  let resolved_depth_texture_id = if depth_texture_id < 0 {
    -1
  } else {
    depth_texture_id
  }
  let resolved_anisotropy_texture_id = if anisotropy_texture_id < 0 {
    -1
  } else {
    anisotropy_texture_id
  }
  let resolved_specular_tint_texture_id = if specular_tint_texture_id < 0 {
    -1
  } else {
    specular_tint_texture_id
  }
  let resolved_transmission_source_texture_id = if ps.transmission_source_texture_id <
    0 {
    -1
  } else {
    ps.transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if ps.point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    ps.point_shadow_texture_id
  }
  let environment_map_enabled = ps.environment_map_intensity > 0.0F
  let resolved_environment_diffuse_texture_id = if environment_map_enabled {
    if ps.environment_diffuse_texture_id >= 0 {
      ps.environment_diffuse_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  let resolved_environment_specular_texture_id = if environment_map_enabled {
    if ps.environment_specular_texture_id >= 0 {
      ps.environment_specular_texture_id
    } else {
      -1
    }
  } else {
    -1
  }
  guard resolve_mesh3d_texture(self, resolved_base_texture_id)
    is Some(base_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_emissive_texture_id)
    is Some(emissive_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_metallic_roughness_texture_id)
    is Some(metallic_roughness_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_occlusion_texture_id)
    is Some(occlusion_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_depth_texture_id)
    is Some(depth_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_anisotropy_texture_id)
    is Some(anisotropy_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_specular_tint_texture_id)
    is Some(specular_tint_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_environment_specular_texture_id)
    is Some(environment_specular_texture) else {
    return
  }
  let textured = texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let emissive_textured = emissive_texture_id >= 0
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let occlusion_textured = occlusion_texture_id >= 0
  let depth_textured = depth_texture_id >= 0
  let anisotropy_textured = anisotropy_texture_id >= 0
  let specular_tint_textured = specular_tint_texture_id >= 0
  let point_shadow_textured = ps.point_shadow_texture_id >= 0
  let draw_point_shadow_enabled = if point_shadow_textured &&
    point_shadow_enabled > 0.5F {
    1.0F
  } else {
    0.0F
  }
  let draw_point_shadow_depth_bias = if point_shadow_textured {
    point_shadow_depth_bias
  } else {
    0.0F
  }
  let uv_transform_a_value = uv_transform_a
  let uv_transform_b_value = uv_transform_b
  let uv_transform_c_value = uv_transform_c
  let uv_transform_d_value = uv_transform_d
  let uv_transform_tx_value = uv_transform_tx
  let uv_transform_ty_value = uv_transform_ty
  let runtime_material_flags = mesh3d_runtime_material_flags(
    material_flags, normal_texture_id, normal_texture,
  )
  let uv_transform_mode_value = if uv_transform_mode < 0.0F {
    -1.0F
  } else if textured ||
    normal_textured ||
    emissive_textured ||
    metallic_roughness_textured ||
    occlusion_textured ||
    depth_textured ||
    anisotropy_textured ||
    specular_tint_textured {
    1.0F
  } else {
    0.0F
  }
  let view_bytes = mesh3d_view_uniform_bytes(ps)
  let draw_bytes = mesh3d_draw_uniform_bytes(
    x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y, scale_z,
    color_r, color_g, color_b, color_a, uv_transform_a_value, uv_transform_b_value,
    uv_transform_c_value, uv_transform_d_value, uv_transform_tx_value, uv_transform_ty_value,
    uv_transform_mode_value, emissive_r, emissive_g, emissive_b, metallic, roughness,
    reflectance, parallax_depth_scale, max_parallax_layer_count, max_relief_mapping_search_steps,
    anisotropy_strength, anisotropy_rotation, specular_tint_r, specular_tint_g, specular_tint_b,
    diffuse_transmission, specular_transmission, thickness, ior, alpha_cutoff, runtime_material_flags,
    draw_point_shadow_enabled, draw_point_shadow_depth_bias,
  )
  guard self.mesh3d_view_buf is Some(active_view_buffer) else { return }
  guard draw_buffer is Some(active_draw_buffer) else { return }
  guard draw_bind_group is Some(active_draw_bg) else { return }
  // Bevy-aligned path: skin buffers are prepared before draw.
  let resolved_skin_bg = if skinning_key_hi >= 0 && skinning_key_lo >= 0 {
    match
      mesh3d_skin_bind_group_for_key(self, skinning_key_hi, skinning_key_lo) {
      Some(bind_group) => Some(bind_group)
      None => ensure_mesh3d_skin_default_binding(self)
    }
  } else {
    ensure_mesh3d_skin_default_binding(self)
  }
  guard resolved_skin_bg is Some(active_skin_bg) else { return }
  let view_needs_upload = match self.mesh3d_pass_view_uniform_bytes {
    Some(cached) => cached != view_bytes
    None => true
  }
  if view_needs_upload {
    self.queue.write_buffer(active_view_buffer, 0UL, view_bytes)
    self.mesh3d_pass_view_uniform_bytes = Some(view_bytes)
  }
  self.queue.write_buffer(active_draw_buffer, draw_write_offset, draw_bytes)
  let view_bg = mesh3d_view_bg_cache_get_or_create(
    self, transmission_source_texture, point_shadow_texture, environment_diffuse_texture,
    environment_specular_texture,
  )
  let material_bg = mesh3d_material_cache_get_or_create(
    self, base_texture, normal_texture, emissive_texture, metallic_roughness_texture,
    occlusion_texture, depth_texture, anisotropy_texture, specular_tint_texture,
  )
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, view_bg, [])
  pass.set_bind_group(1U, material_bg, [])
  pass.set_bind_group(2U, active_draw_bg, [])
  pass.set_bind_group(3U, active_skin_bg, [])
  let vb_bytes = mesh.vertex_count.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, vb_bytes)
  debug_mesh3d_executed_draw_calls_ref.val = debug_mesh3d_executed_draw_calls_ref.val +
    1
  current_frame_mesh3d_executed_draw_calls_ref.val = current_frame_mesh3d_executed_draw_calls_ref.val +
    1
  if use_indirect &&
    mesh3d_preprocess_camera_upload_state(
      self, preprocess_camera_key_hi, preprocess_camera_key_lo,
    )
    is Some(preprocess_state) {
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED &&
      preprocess_state.non_indexed_indirect_parameters_buffer
      is Some(non_indexed_indirect_parameters_buffer) {
      pass.draw_indirect(
        non_indexed_indirect_parameters_buffer,
        mesh3d_non_indexed_indirect_offset(indirect_parameters_index),
      )
      return
    }
    if indirect_kind == MESH3D_DRAW_INDIRECT_KIND_INDEXED &&
      preprocess_state.indexed_indirect_parameters_buffer
      is Some(indexed_indirect_parameters_buffer) {
      gpu_mesh_bind_index_buffer(pass, mesh)
      pass.draw_indexed_indirect(
        indexed_indirect_parameters_buffer,
        mesh3d_indexed_indirect_offset(indirect_parameters_index),
      )
      return
    }
  }
  if mesh.primitive_topology == MESH3D_TOPOLOGY_LINE_STRIP {
    pass.draw(mesh.vertex_count, 1U, 0U, draw_index)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(mesh.index_count, 1U, 0U, 0, draw_index)
  }
}

///|
