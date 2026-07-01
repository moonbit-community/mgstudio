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
pub fn set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_gpu_instance_builder_enabled = enabled
  }
}

///|
pub fn GpuBackend::reserve_mesh3d_draw_storage(
  self : GpuBackend,
  count : Int,
) -> Int {
  if count <= 0 {
    return -1
  }
  let base = self.mesh3d_instance_draw_used /
    MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
  let next_used_int = (base + count) * MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
  if next_used_int < 0 {
    return -1
  }
  guard self.ensure_mesh3d_instance_draw_binding(next_used_int.to_uint64())
    is Some(_) else {
    return -1
  }
  self.mesh3d_instance_draw_used = next_used_int
  base
}

///|
pub fn reserve_mesh3d_draw_storage(count~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.reserve_mesh3d_draw_storage(count)
  } else {
    -1
  }
}

///|
pub fn mesh3d_binding_arrays_are_usable(
  required_storage_textures_per_shader_stage~ : UInt,
  required_binding_array_sampler_elements_per_shader_stage? : UInt = 0U,
) -> Bool {
  if ensure_backend() is Some(backend) {
    let adapter_info = RenderAdapterInfo::from_backend(backend)
    let adreno_model_is_usable = match adapter_info.adreno_model() {
      Some(model) => model > 610
      None => true
    }
    adreno_model_is_usable &&
    backend.device.has_feature_native_texture_binding_array() &&
    backend.device.has_feature_native_sampled_texture_and_storage_buffer_array_non_uniform_indexing() &&
    backend.device.limits_max_storage_textures_per_shader_stage_u32() >=
    required_storage_textures_per_shader_stage &&
    backend.device.limits_max_binding_array_sampler_elements_per_shader_stage_u32() >=
    required_binding_array_sampler_elements_per_shader_stage
  } else {
    false
  }
}

///|
pub fn prepare_mesh3d_skin_bindings(skinning_rows~ : Array[Float]) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_skin_bindings(skinning_rows)
  }
}

///|
pub fn prepare_mesh3d_morph_bindings(morph_weights~ : Array[Float]) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_morph_bindings(morph_weights)
  }
}

///|
pub fn create_mesh3d_morph_target_buffer(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  components~ : Array[Float],
) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh3d_morph_target_buffer(
      width, height, depth, components,
    )
  }
  -1
}

///|
pub fn GpuBackend::prepare_mesh3d_cluster_buffers(
  self : GpuBackend,
  clustered_lights_bytes : Bytes,
  clusterable_object_index_lists_bytes : Bytes,
  cluster_offsets_and_counts_bytes : Bytes,
) -> Unit {
  ensure_mesh3d_view_binding_buffers(self)
  guard self.mesh3d_clustered_lights_buf is Some(clustered_lights_buf) else {
    return
  }
  guard self.mesh3d_clusterable_object_index_lists_buf
    is Some(clusterable_object_index_lists_buf) else {
    return
  }
  guard self.mesh3d_cluster_offsets_and_counts_buf
    is Some(cluster_offsets_and_counts_buf) else {
    return
  }
  self.queue.write_buffer(clustered_lights_buf, 0UL, clustered_lights_bytes)
  self.queue.write_buffer(
    clusterable_object_index_lists_buf, 0UL, clusterable_object_index_lists_bytes,
  )
  self.queue.write_buffer(
    cluster_offsets_and_counts_buf, 0UL, cluster_offsets_and_counts_bytes,
  )
}

///|
pub fn prepare_mesh3d_cluster_buffers(
  clustered_lights_bytes~ : Bytes,
  clusterable_object_index_lists_bytes~ : Bytes,
  cluster_offsets_and_counts_bytes~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_cluster_buffers(
      clustered_lights_bytes, clusterable_object_index_lists_bytes, cluster_offsets_and_counts_bytes,
    )
  }
}

///|
pub struct HostMesh3dMainPassDrawEntry {
  draw_storage_index : Int
  world_from_local : Array[Float]?
  x : Float
  y : Float
  z : Float
  rotation_x : Float
  rotation_y : Float
  rotation_z : Float
  rotation_w : Float
  scale_x : Float
  scale_y : Float
  scale_z : Float
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
  texture_id : Int
  uv_transform_a : Float
  uv_transform_b : Float
  uv_transform_c : Float
  uv_transform_d : Float
  uv_transform_tx : Float
  uv_transform_ty : Float
  uv_transform_mode : Float
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  emissive_r : Float
  emissive_g : Float
  emissive_b : Float
  emissive_exposure_weight : Float
  metallic : Float
  roughness : Float
  reflectance : Float
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  max_relief_mapping_search_steps : Float
  anisotropy_texture_id : Int
  anisotropy_strength : Float
  anisotropy_rotation : Float
  specular_texture_id : Int
  specular_tint_texture_id : Int
  clearcoat_texture_id : Int
  clearcoat_roughness_texture_id : Int
  clearcoat_normal_texture_id : Int
  specular_tint_r : Float
  specular_tint_g : Float
  specular_tint_b : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  attenuation_color_r : Float
  attenuation_color_g : Float
  attenuation_color_b : Float
  attenuation_distance : Float
  clearcoat : Float
  clearcoat_perceptual_roughness : Float
  alpha_cutoff : Float
  material_flags : UInt
  lightmap_exposure : Float
  lightmap_texture_id : Int
  lightmap_slab_index : Int
  lightmap_slot_index : Int
  lightmap_slab_texture_ids : Array[Int]
  lightmap_uv_min_x : Float
  lightmap_uv_min_y : Float
  lightmap_uv_max_x : Float
  lightmap_uv_max_y : Float
  deferred_lighting_pass_id : Int
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  mesh_flags : UInt
  skinning_key_hi : Int
  morph_weights_index : Int
  previous_morph_weights_index : Int
  morph_targets_texture_id : Int
  first_vertex_index : UInt
}

///|
pub fn host_mesh3d_main_pass_draw_entry(
  draw_storage_index~ : Int,
  world_from_local? : Array[Float]? = None,
  x~ : Float,
  y~ : Float,
  z~ : Float,
  rotation_x~ : Float,
  rotation_y~ : Float,
  rotation_z~ : Float,
  rotation_w~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  scale_z~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_transform_a~ : Float,
  uv_transform_b~ : Float,
  uv_transform_c~ : Float,
  uv_transform_d~ : Float,
  uv_transform_tx~ : Float,
  uv_transform_ty~ : Float,
  uv_transform_mode~ : Float,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  emissive_r~ : Float,
  emissive_g~ : Float,
  emissive_b~ : Float,
  emissive_exposure_weight? : Float = 0.0F,
  metallic~ : Float,
  roughness~ : Float,
  reflectance~ : Float,
  parallax_depth_scale~ : Float,
  max_parallax_layer_count~ : Float,
  max_relief_mapping_search_steps~ : Float,
  anisotropy_texture_id~ : Int,
  anisotropy_strength~ : Float,
  anisotropy_rotation~ : Float,
  specular_texture_id? : Int = -1,
  specular_tint_texture_id~ : Int,
  clearcoat_texture_id? : Int = -1,
  clearcoat_roughness_texture_id? : Int = -1,
  clearcoat_normal_texture_id? : Int = -1,
  specular_tint_r~ : Float,
  specular_tint_g~ : Float,
  specular_tint_b~ : Float,
  diffuse_transmission~ : Float,
  specular_transmission~ : Float,
  thickness~ : Float,
  ior~ : Float,
  attenuation_color_r? : Float = 1.0F,
  attenuation_color_g? : Float = 1.0F,
  attenuation_color_b? : Float = 1.0F,
  attenuation_distance? : Float = 1.0F / 0.0F,
  clearcoat? : Float = 0.0F,
  clearcoat_perceptual_roughness? : Float = 0.5F,
  alpha_cutoff~ : Float,
  material_flags~ : UInt,
  lightmap_exposure? : Float = 1.0F,
  lightmap_texture_id? : Int = -1,
  lightmap_slab_index? : Int = -1,
  lightmap_slot_index? : Int = -1,
  lightmap_slab_texture_ids? : Array[Int] = [],
  lightmap_uv_min_x? : Float = 0.0F,
  lightmap_uv_min_y? : Float = 0.0F,
  lightmap_uv_max_x? : Float = 0.0F,
  lightmap_uv_max_y? : Float = 0.0F,
  deferred_lighting_pass_id? : Int = 1,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  mesh_flags~ : UInt,
  skinning_key_hi~ : Int,
  morph_weights_index? : Int = -1,
  previous_morph_weights_index? : Int = -1,
  morph_targets_texture_id? : Int = -1,
  first_vertex_index? : UInt = 0U,
) -> HostMesh3dMainPassDrawEntry {
  HostMesh3dMainPassDrawEntry::{
    draw_storage_index,
    world_from_local,
    x,
    y,
    z,
    rotation_x,
    rotation_y,
    rotation_z,
    rotation_w,
    scale_x,
    scale_y,
    scale_z,
    color_r,
    color_g,
    color_b,
    color_a,
    texture_id,
    uv_transform_a,
    uv_transform_b,
    uv_transform_c,
    uv_transform_d,
    uv_transform_tx,
    uv_transform_ty,
    uv_transform_mode,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    emissive_r,
    emissive_g,
    emissive_b,
    emissive_exposure_weight,
    metallic,
    roughness,
    reflectance,
    parallax_depth_scale,
    max_parallax_layer_count,
    max_relief_mapping_search_steps,
    anisotropy_texture_id,
    anisotropy_strength,
    anisotropy_rotation,
    specular_texture_id,
    specular_tint_texture_id,
    clearcoat_texture_id,
    clearcoat_roughness_texture_id,
    clearcoat_normal_texture_id,
    specular_tint_r,
    specular_tint_g,
    specular_tint_b,
    diffuse_transmission,
    specular_transmission,
    thickness,
    ior,
    attenuation_color_r,
    attenuation_color_g,
    attenuation_color_b,
    attenuation_distance,
    clearcoat,
    clearcoat_perceptual_roughness,
    alpha_cutoff,
    material_flags,
    lightmap_exposure,
    lightmap_texture_id,
    lightmap_slab_index,
    lightmap_slot_index,
    lightmap_slab_texture_ids,
    lightmap_uv_min_x,
    lightmap_uv_min_y,
    lightmap_uv_max_x,
    lightmap_uv_max_y,
    deferred_lighting_pass_id,
    point_shadow_texture_id,
    point_shadow_enabled,
    point_shadow_depth_bias,
    mesh_flags,
    skinning_key_hi,
    morph_weights_index,
    previous_morph_weights_index,
    morph_targets_texture_id,
    first_vertex_index,
  }
}

///|
fn GpuBackend::write_mesh3d_main_pass_draw_entry(
  self : GpuBackend,
  packed_bytes : FixedArray[Byte],
  byte_offset : Int,
  entry : HostMesh3dMainPassDrawEntry,
) -> Bool raise GpuBackendError {
  let resolved_normal_texture_id = if entry.normal_texture_id < 0 {
    ensure_normal_map_fallback_texture(self).id
  } else {
    entry.normal_texture_id
  }
  guard resolve_mesh3d_texture(self, resolved_normal_texture_id)
    is Some(normal_texture) else {
    return false
  }
  let textured = entry.texture_id >= 0
  let normal_textured = entry.normal_texture_id >= 0
  let emissive_textured = entry.emissive_texture_id >= 0
  let metallic_roughness_textured = entry.metallic_roughness_texture_id >= 0
  let occlusion_textured = entry.occlusion_texture_id >= 0
  let depth_textured = entry.depth_texture_id >= 0
  let anisotropy_textured = entry.anisotropy_texture_id >= 0
  let specular_tint_textured = entry.specular_tint_texture_id >= 0
  let runtime_material_flags = mesh3d_runtime_material_flags(
    entry.material_flags,
    entry.normal_texture_id,
    normal_texture,
  )
  let uv_transform_mode = if entry.uv_transform_mode < 0.0F {
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
  let point_shadow_textured = entry.point_shadow_texture_id >= 0
  let draw_point_shadow_depth_bias = if point_shadow_textured {
    entry.point_shadow_depth_bias
  } else {
    0.0F
  }
  if byte_offset < 0 ||
    byte_offset + MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int() >
    packed_bytes.length() {
    return false
  }
  mesh3d_draw_uniform_write(
    packed_bytes,
    byte_offset,
    entry.world_from_local,
    entry.x,
    entry.y,
    entry.z,
    entry.rotation_x,
    entry.rotation_y,
    entry.rotation_z,
    entry.rotation_w,
    entry.scale_x,
    entry.scale_y,
    entry.scale_z,
    entry.color_r,
    entry.color_g,
    entry.color_b,
    entry.color_a,
    entry.uv_transform_a,
    entry.uv_transform_b,
    entry.uv_transform_c,
    entry.uv_transform_d,
    entry.uv_transform_tx,
    entry.uv_transform_ty,
    uv_transform_mode,
    entry.emissive_r,
    entry.emissive_g,
    entry.emissive_b,
    entry.metallic,
    entry.roughness,
    entry.reflectance,
    entry.parallax_depth_scale,
    entry.max_parallax_layer_count,
    entry.max_relief_mapping_search_steps,
    entry.anisotropy_strength,
    entry.anisotropy_rotation,
    entry.specular_tint_r,
    entry.specular_tint_g,
    entry.specular_tint_b,
    entry.diffuse_transmission,
    entry.specular_transmission,
    entry.thickness,
    entry.ior,
    entry.alpha_cutoff,
    runtime_material_flags,
    if entry.skinning_key_hi >= 0 {
      entry.skinning_key_hi.reinterpret_as_uint()
    } else {
      0xFFFFFFFFU
    },
    entry.mesh_flags,
    draw_point_shadow_depth_bias,
    entry.lightmap_texture_id,
    entry.lightmap_slot_index,
    entry.lightmap_uv_min_x,
    entry.lightmap_uv_min_y,
    entry.lightmap_uv_max_x,
    entry.lightmap_uv_max_y,
    entry.first_vertex_index,
    0U,
  )
  true
}

///|
pub fn GpuBackend::prepare_mesh3d_main_pass_draw_batch(
  self : GpuBackend,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  pass_kind : Int,
  entries : Array[HostMesh3dMainPassDrawEntry],
) -> Unit raise GpuBackendError {
  self.mesh3d_prepared_draw_camera_key_hi = -1
  self.mesh3d_prepared_draw_camera_key_lo = -1
  self.mesh3d_prepared_draw_pass_kind = -1
  self.mesh3d_prepared_draw_count = 0
  let mut min_draw_storage_index = -1
  let mut max_draw_storage_index = -1
  for entry in entries {
    if entry.draw_storage_index >= 0 &&
      (
        min_draw_storage_index < 0 ||
        entry.draw_storage_index < min_draw_storage_index
      ) {
      min_draw_storage_index = entry.draw_storage_index
    }
    if entry.draw_storage_index > max_draw_storage_index {
      max_draw_storage_index = entry.draw_storage_index
    }
  }
  if min_draw_storage_index < 0 ||
    max_draw_storage_index < min_draw_storage_index {
    return
  }
  let required_size = (max_draw_storage_index + 1).to_uint64() *
    MESH3D_DRAW_STORAGE_STRIDE_BYTES
  guard self.ensure_mesh3d_instance_draw_binding(required_size)
    is Some((draw_buffer, _draw_bind_group)) else {
    return
  }
  let packed_len = (max_draw_storage_index - min_draw_storage_index + 1) *
    MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
  if packed_len <= 0 {
    return
  }
  let staging_bytes = bytes_fixed_staging_make(packed_len)
  for entry in entries {
    if entry.draw_storage_index < 0 {
      continue
    }
    let base = (entry.draw_storage_index - min_draw_storage_index) *
      MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
    guard self.write_mesh3d_main_pass_draw_entry(staging_bytes, base, entry) else {
      continue
    }
  }
  self.queue.write_buffer(
    draw_buffer,
    min_draw_storage_index.to_uint64() * MESH3D_DRAW_STORAGE_STRIDE_BYTES,
    staging_bytes.unsafe_reinterpret_as_bytes(),
  )
  self.mesh3d_prepared_draw_camera_key_hi = preprocess_camera_key_hi
  self.mesh3d_prepared_draw_camera_key_lo = preprocess_camera_key_lo
  self.mesh3d_prepared_draw_pass_kind = pass_kind
  self.mesh3d_prepared_draw_count = max_draw_storage_index + 1
  let next_used_int = (max_draw_storage_index + 1) *
    MESH3D_DRAW_STORAGE_STRIDE_BYTES.to_int()
  if self.mesh3d_instance_draw_used < next_used_int {
    self.mesh3d_instance_draw_used = next_used_int
  }
}

///|
pub fn prepare_mesh3d_main_pass_draw_batch(
  preprocess_camera_key_hi~ : Int,
  preprocess_camera_key_lo~ : Int,
  pass_kind~ : Int,
  entries~ : Array[HostMesh3dMainPassDrawEntry],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_main_pass_draw_batch(
      preprocess_camera_key_hi, preprocess_camera_key_lo, pass_kind, entries,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_main_pass_draw_batch", err)
    }
  }
}

///|
pub fn mesh3d_indirect_first_instance_supported() -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
    )
  }
  false
}

///|
fn mesh3d_instance_vertex_buffer_size_for_bytes(bytes : Bytes) -> UInt64 {
  let byte_len = bytes.length()
  if byte_len <= 0 {
    4UL
  } else {
    byte_len.to_uint64()
  }
}

///|
fn GpuBackend::mesh3d_instance_vertex_buffer_index(
  self : GpuBackend,
  buffer_id : Int,
) -> Int? {
  for index in 0..<self.mesh3d_instance_vertex_buffers.length() {
    if self.mesh3d_instance_vertex_buffers[index].id == buffer_id {
      return Some(index)
    }
  }
  None
}

///|
fn GpuBackend::prepare_mesh3d_instance_vertex_buffer(
  self : GpuBackend,
  buffer_id : Int,
  bytes : Bytes,
  length : Int,
) -> Unit {
  if buffer_id < 0 || length <= 0 || bytes.length() == 0 {
    return
  }
  let byte_size = mesh3d_instance_vertex_buffer_size_for_bytes(bytes)
  let usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  match self.mesh3d_instance_vertex_buffer_index(buffer_id) {
    Some(index) => {
      let current = self.mesh3d_instance_vertex_buffers[index]
      let buffer = if current.byte_size < byte_size {
        current.buffer.release()
        self.device.create_buffer(size=byte_size, usage~)
      } else {
        current.buffer
      }
      self.queue.write_buffer(buffer, 0UL, bytes)
      self.mesh3d_instance_vertex_buffers[index] = GpuMesh3dInstanceVertexBufferInfo::{
        id: buffer_id,
        buffer,
        byte_size: if current.byte_size < byte_size {
          byte_size
        } else {
          current.byte_size
        },
        length,
      }
    }
    None => {
      let buffer = self.device.create_buffer_init(usage~, bytes)
      self.mesh3d_instance_vertex_buffers.push(GpuMesh3dInstanceVertexBufferInfo::{
        id: buffer_id,
        buffer,
        byte_size,
        length,
      })
    }
  }
}

///|
pub fn prepare_mesh3d_instance_vertex_buffer(
  buffer_id~ : Int,
  bytes~ : Bytes,
  length~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_instance_vertex_buffer(buffer_id, bytes, length)
  }
}

///|
fn GpuBackend::mesh3d_instance_vertex_buffer(
  self : GpuBackend,
  buffer_id : Int,
) -> GpuMesh3dInstanceVertexBufferInfo? {
  match self.mesh3d_instance_vertex_buffer_index(buffer_id) {
    Some(index) => Some(self.mesh3d_instance_vertex_buffers[index])
    None => None
  }
}

///|
pub fn mesh3d_gpu_culling_supported() -> Bool {
  if ensure_backend() is Some(backend) {
    let backend_type = backend.device.info_backend_type_u32()
    if backend_type == @wgpu.BACKEND_TYPE_OPEN_GL ||
      backend_type == @wgpu.BACKEND_TYPE_OPEN_GLES {
      return false
    }
    if backend.device.limits_max_compute_workgroup_size_x_u32() == 0U {
      return false
    }
    if !backend.device.supported_features_contains_u32(
        @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
      ) {
      return false
    }
    if backend.device.limits_max_storage_textures_per_shader_stage_u32() < 12U {
      return false
    }
    if backend.device.limits_max_compute_workgroup_storage_size_u32() == 0U {
      return false
    }
    return true
  }
  false
}

///|
pub fn read_only_binding_type_uniform(required_storage_buffers : Int) -> Bool {
  if required_storage_buffers <= 0 {
    return false
  }
  if ensure_backend() is Some(backend) {
    return backend.device.get_supported_read_only_binding_type_u32(
        required_storage_buffers.reinterpret_as_uint(),
      ) ==
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM
  }
  false
}

///|
pub fn meshlet_required_rust_features_u64() -> UInt64 {
  @wgpu.FEATURES_TEXTURE_INT64_ATOMIC |
  @wgpu.FEATURES_TEXTURE_ATOMIC |
  @wgpu.FEATURES_SHADER_INT64 |
  @wgpu.FEATURES_SUBGROUP |
  @wgpu.FEATURES_DEPTH_CLIP_CONTROL |
  @wgpu.FEATURES_PUSH_CONSTANTS
}

///|
pub fn meshlet_missing_rust_features_u64() -> UInt64 {
  let required = meshlet_required_rust_features_u64()
  if ensure_backend() is Some(backend) {
    return backend.device.missing_rust_features_u64(required)
  }
  required
}

///|
pub fn meshlet_required_features_supported() -> Bool {
  if ensure_backend() is Some(backend) {
    let backend_type = backend.device.info_backend_type_u32()
    if backend_type != @wgpu.BACKEND_TYPE_VULKAN &&
      backend_type != @wgpu.BACKEND_TYPE_METAL {
      return false
    }
    if !backend.device.supports_rust_features_u64(
        meshlet_required_rust_features_u64(),
      ) {
      return false
    }
    if meshlet_missing_native_subgroup_barrier() {
      return false
    }
    if meshlet_missing_native_r64uint_storage_texture_api() {
      return false
    }
    return true
  }
  false
}

///|
pub fn meshlet_missing_native_subgroup_barrier() -> Bool {
  if ensure_backend() is Some(backend) {
    return !backend.device.has_feature_native_subgroup_barrier()
  }
  true
}

///|
pub fn meshlet_missing_native_r64uint_storage_texture_api() -> Bool {
  // Bevy's meshlet visibility buffer is `texture_storage_2d<r64uint, atomic>`.
  // The current wgpu C ABI exposed through wgpu_mbt cannot create that exact
  // texture format/access pair, so the meshlet renderer must stay unavailable
  // instead of running a different visibility-buffer resource shape.
  true
}

///|
pub fn meshlet_missing_native_immediates() -> Bool {
  if ensure_backend() is Some(backend) {
    return !backend.device.has_feature_native_immediates()
  }
  true
}

///|
pub fn meshlet_adapter_supports_mesh_shader() -> Bool {
  // `wgpu_mbt` does not expose mesh-shader feature constants yet.
  // Keep this value conservative until upstream exposes the capability surface.
  false
}

///|
pub fn delete_old_mesh3d_preprocess_work_item_buffers(
  retained_camera_keys~ : Array[UInt64],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.delete_old_mesh3d_preprocess_work_item_buffers(retained_camera_keys)
  }
}

///|
pub fn upload_mesh3d_preprocess_camera_payload(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  payload~ : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.upload_mesh3d_preprocess_camera_payload(
      camera_key_hi, camera_key_lo, payload,
    )
  }
}

///|
pub fn build_mesh3d_indirect_parameters(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_BUILD_INDIRECT_PHASE_MAIN,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.build_mesh3d_indirect_parameters(
      camera_key_hi, camera_key_lo, phase_kind,
    ) catch {
      ShaderNotReady(_) => ()
      Fatal(message) =>
        debug("[renderer] build_mesh3d_indirect_parameters: Fatal(\{message})")
    }
  }
}

///|
pub fn preprocess_mesh3d(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_PREPROCESS_PHASE_MAIN,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.preprocess_mesh3d(camera_key_hi, camera_key_lo, phase_kind) catch {
      ShaderNotReady(_) => ()
      Fatal(message) => debug("[renderer] preprocess_mesh3d: Fatal(\{message})")
    }
  }
}

///|
pub fn downsample_mesh3d_depth_pyramid(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.downsample_mesh3d_depth_pyramid(camera_key_hi, camera_key_lo) catch {
      ShaderNotReady(_) => ()
      Fatal(message) =>
        debug("[renderer] downsample_mesh3d_depth_pyramid: Fatal(\{message})")
    }
  }
}

///|
pub fn prewarm_mesh3d_pipeline_variants(
  mesh_topology_kind~ : Int,
  cull_mode~ : Int,
  vertex_shader_path~ : String?,
  fragment_shader_path~ : String?,
) -> Unit {
  if ensure_backend() is Some(backend) {
    let topology = mesh3d_topology_from_kind(mesh_topology_kind)
    let opaque_blend_kind = MESH3D_PIPELINE_BLEND_OPAQUE
    let transparent_flags = MESH3D_SHADOW_ALPHA_MODE_BLEND
    let transparent_blend_kind = mesh3d_blend_kind_from_material_flags(
      transparent_flags, true,
    )
    ignore(
      mesh3d_pipeline_for_current_pass(
        backend,
        false,
        0U,
        MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
        false,
        topology,
        cull_mode,
        vertex_shader_path,
        fragment_shader_path,
        false,
        false,
        0,
        false,
        1,
      ),
    ) catch {
      ShaderNotReady(_) => ()
      Fatal(message) =>
        debug(
          "[renderer] prewarm_mesh3d_pipeline_variants(opaque): Fatal(\{message})",
        )
    }
    ignore(
      mesh3d_pipeline_for_current_pass(
        backend,
        true,
        MESH3D_SHADOW_ALPHA_MODE_BLEND,
        MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
        false,
        topology,
        cull_mode,
        vertex_shader_path,
        fragment_shader_path,
        false,
        false,
        0,
        false,
        1,
      ),
    ) catch {
      ShaderNotReady(_) => ()
      Fatal(message) =>
        debug(
          "[renderer] prewarm_mesh3d_pipeline_variants(transparent): Fatal(\{message})",
        )
    }
    match backend.surface_format {
      Some(format) if format != tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) => {
        let resolved_vertex_shader_path = mesh3d_vertex_shader_path_or_default(
          vertex_shader_path,
        )
        let resolved_fragment_shader_path = mesh3d_fragment_shader_path_or_default(
          fragment_shader_path,
        )
        if resolved_vertex_shader_path != MESH3D_FORWARD_VERTEX_SHADER_PATH ||
          resolved_fragment_shader_path != MESH3D_FORWARD_SHADER_PATH {
          ignore(
            mesh3d_custom_pipeline_get_or_create(
              backend,
              MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
              None,
              resolved_vertex_shader_path,
              resolved_fragment_shader_path,
              Some(format),
              1,
              topology,
              false,
              opaque_blend_kind,
              false,
              cull_mode,
              false,
              false,
              0,
              false,
              1,
            ),
          ) catch {
            ShaderNotReady(_) => ()
            Fatal(message) =>
              debug(
                "[renderer] prewarm_mesh3d_pipeline_variants(surface opaque): Fatal(\{message})",
              )
          }
          ignore(
            mesh3d_custom_pipeline_get_or_create(
              backend,
              MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
              None,
              resolved_vertex_shader_path,
              resolved_fragment_shader_path,
              Some(format),
              1,
              topology,
              true,
              transparent_blend_kind,
              false,
              cull_mode,
              false,
              false,
              0,
              false,
              1,
            ),
          ) catch {
            ShaderNotReady(_) => ()
            Fatal(message) =>
              debug(
                "[renderer] prewarm_mesh3d_pipeline_variants(surface transparent): Fatal(\{message})",
              )
          }
        } else {
          ensure_mesh3d_pipeline_surface(
            backend,
            format,
            1,
            topology,
            MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
            None,
            cull_mode,
            opaque_blend_kind,
            false,
            false,
            false,
            0,
            false,
            1,
          ) catch {
            ShaderNotReady(_) => ()
            Fatal(message) =>
              debug(
                "[renderer] prewarm_mesh3d_pipeline_variants(surface opaque): Fatal(\{message})",
              )
          }
          ensure_mesh3d_pipeline_surface(
            backend,
            format,
            1,
            topology,
            MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
            None,
            cull_mode,
            transparent_blend_kind,
            false,
            false,
            false,
            0,
            false,
            1,
          ) catch {
            ShaderNotReady(_) => ()
            Fatal(message) =>
              debug(
                "[renderer] prewarm_mesh3d_pipeline_variants(surface transparent): Fatal(\{message})",
              )
          }
        }
      }
      _ => ()
    }
  }
}

///|
pub fn prepare_mesh3d_material_bind_group(
  texture_id~ : Int,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  anisotropy_texture_id~ : Int,
  specular_texture_id? : Int = -1,
  specular_tint_texture_id~ : Int,
  clearcoat_texture_id? : Int = -1,
  clearcoat_roughness_texture_id? : Int = -1,
  clearcoat_normal_texture_id? : Int = -1,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_material_bind_group(
      texture_id, normal_texture_id, emissive_texture_id, metallic_roughness_texture_id,
      occlusion_texture_id, depth_texture_id, anisotropy_texture_id, specular_texture_id,
      specular_tint_texture_id, clearcoat_texture_id, clearcoat_roughness_texture_id,
      clearcoat_normal_texture_id,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_material_bind_group", err)
    }
  }
}

///|
pub fn frame_count() -> UInt {
  match ensure_backend() {
    Some(backend) => backend.frame_count
    None => 0U
  }
}

///|
pub fn prepare_mesh3d_clustered_decals(
  decal_words~ : Array[UInt],
  texture_ids~ : Array[Int],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_clustered_decals(decal_words, texture_ids)
  }
}

///|
pub fn prepare_mesh3d_light_probes(
  light_probes_uniform_bytes~ : Bytes,
  uniform_offset~ : UInt,
  diffuse_texture_ids~ : Array[Int],
  specular_texture_ids~ : Array[Int],
  irradiance_volume_texture_ids~ : Array[Int],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_light_probes(
      light_probes_uniform_bytes, uniform_offset, diffuse_texture_ids, specular_texture_ids,
      irradiance_volume_texture_ids,
    )
  }
}

///|
pub fn prepare_mesh3d_volumetric_fog_uniforms(
  volumetric_fog_uniform_bytes~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_volumetric_fog_uniforms(volumetric_fog_uniform_bytes) catch {
      err => debug_runtime_error("prepare_mesh3d_volumetric_fog_uniforms", err)
    }
  }
}

///|
pub fn prepare_mesh3d_volumetric_fog_pipeline(
  target_id~ : Int,
  msaa_sample_count~ : Int,
  has_density_texture~ : Bool,
  atmosphere~ : Bool,
  hull_mesh_id~ : Int,
) -> Int? {
  if ensure_backend() is Some(backend) {
    return backend.prepare_mesh3d_volumetric_fog_pipeline(
      target_id, msaa_sample_count, has_density_texture, atmosphere, hull_mesh_id,
    ) catch {
      err => {
        debug_runtime_error("prepare_mesh3d_volumetric_fog_pipeline", err)
        None
      }
    }
  }
  None
}

///|
pub fn prepare_mesh3d_view_bind_group(
  transmission_source_texture_id~ : Int,
  point_shadow_texture_id~ : Int,
  directional_shadow_texture_id? : Int = -1,
  environment_diffuse_texture_id~ : Int,
  environment_specular_texture_id~ : Int,
  prepass_depth_texture_id? : Int = -1,
  prepass_normal_texture_id? : Int = -1,
  prepass_motion_vector_texture_id? : Int = -1,
  prepass_deferred_texture_id? : Int = -1,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_view_bind_group(
      transmission_source_texture_id, point_shadow_texture_id, directional_shadow_texture_id,
      environment_diffuse_texture_id, environment_specular_texture_id, prepass_depth_texture_id,
      prepass_normal_texture_id, prepass_motion_vector_texture_id, prepass_deferred_texture_id,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_view_bind_group", err)
    }
  }
}

///|
pub fn prepare_mesh3d_ssao_resources(
  width~ : Int,
  height~ : Int,
  constant_object_thickness~ : Float,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_ssao_resources(
      width, height, constant_object_thickness,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_ssao_resources", err)
    }
  }
}

///|
pub fn prepare_mesh3d_ssao_pipeline(
  quality_level~ : Int,
  custom_slice_count~ : Int,
  custom_samples_per_slice_side~ : Int,
  temporal_jitter~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_ssao_pipeline(
      quality_level, custom_slice_count, custom_samples_per_slice_side, temporal_jitter,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_ssao_pipeline", err)
    }
  }
}

///|
pub fn draw_mesh3d(
  mesh_id~ : Int,
  preprocess_camera_key_hi? : Int = 0,
  preprocess_camera_key_lo? : Int = 0,
  draw_storage_index? : Int = -1,
  indirect_kind? : Int = 0,
  indirect_parameters_index? : Int = -1,
  indirect_draw_count? : Int = 1,
  instance_vertex_buffer_id? : Int = -1,
  x~ : Float,
  y~ : Float,
  z~ : Float,
  rotation_x~ : Float,
  rotation_y~ : Float,
  rotation_z~ : Float,
  rotation_w~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  scale_z~ : Float,
  previous_x~ : Float,
  previous_y~ : Float,
  previous_z~ : Float,
  previous_rotation_x~ : Float,
  previous_rotation_y~ : Float,
  previous_rotation_z~ : Float,
  previous_rotation_w~ : Float,
  previous_scale_x~ : Float,
  previous_scale_y~ : Float,
  previous_scale_z~ : Float,
  world_from_local? : Array[Float]? = None,
  previous_world_from_local? : Array[Float]? = None,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_transform_a~ : Float,
  uv_transform_b~ : Float,
  uv_transform_c~ : Float,
  uv_transform_d~ : Float,
  uv_transform_tx~ : Float,
  uv_transform_ty~ : Float,
  uv_transform_mode~ : Float,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  emissive_r~ : Float,
  emissive_g~ : Float,
  emissive_b~ : Float,
  emissive_exposure_weight? : Float = 0.0F,
  metallic~ : Float,
  roughness~ : Float,
  reflectance~ : Float,
  parallax_depth_scale~ : Float,
  max_parallax_layer_count~ : Float,
  max_relief_mapping_search_steps~ : Float,
  anisotropy_texture_id~ : Int,
  anisotropy_strength~ : Float,
  anisotropy_rotation~ : Float,
  specular_texture_id? : Int = -1,
  specular_tint_texture_id~ : Int,
  clearcoat_texture_id? : Int = -1,
  clearcoat_roughness_texture_id? : Int = -1,
  clearcoat_normal_texture_id? : Int = -1,
  specular_tint_r~ : Float,
  specular_tint_g~ : Float,
  specular_tint_b~ : Float,
  diffuse_transmission~ : Float,
  specular_transmission~ : Float,
  thickness~ : Float,
  ior~ : Float,
  attenuation_color_r? : Float = 1.0F,
  attenuation_color_g? : Float = 1.0F,
  attenuation_color_b? : Float = 1.0F,
  attenuation_distance? : Float = 1.0F / 0.0F,
  clearcoat? : Float = 0.0F,
  clearcoat_perceptual_roughness? : Float = 0.5F,
  alpha_cutoff~ : Float,
  material_flags~ : UInt,
  forward_decal_inv_depth_fade_factor? : Float = 1.0F / 8.0F,
  material_pipeline_id? : UInt64 = MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
  lightmap_exposure? : Float = 1.0F,
  lightmap_texture_id? : Int = -1,
  lightmap_slab_index? : Int = -1,
  lightmap_slot_index? : Int = -1,
  lightmap_slab_texture_ids? : Array[Int] = [],
  lightmap_uv_min_x? : Float = 0.0F,
  lightmap_uv_min_y? : Float = 0.0F,
  lightmap_uv_max_x? : Float = 0.0F,
  lightmap_uv_max_y? : Float = 0.0F,
  deferred_lighting_pass_id? : Int = 1,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  mesh_flags~ : UInt,
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation_x? : Float = 0.0F,
  environment_map_rotation_y? : Float = 0.0F,
  environment_map_rotation_z? : Float = 0.0F,
  environment_map_rotation_w? : Float = 1.0F,
  cull_mode~ : Int,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
  material_extension_bind_group_data? : @render_resource.MaterialBindGroupResolvedData = @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
  skinning_key_hi? : Int = -1,
  skinning_key_lo? : Int = -1,
  morph_weights_index? : Int = -1,
  previous_morph_weights_index? : Int = -1,
  morph_targets_texture_id? : Int = -1,
  skinning_matrices? : Array[Float]? = None,
) -> Unit {
  render_diagnostics_record_mesh3d_draw(mesh_id)
  if ensure_backend() is Some(backend) {
    backend.draw_mesh3d(
      mesh_id,
      preprocess_camera_key_hi,
      preprocess_camera_key_lo,
      draw_storage_index,
      indirect_kind,
      indirect_parameters_index,
      indirect_draw_count,
      instance_vertex_buffer_id,
      x,
      y,
      z,
      rotation_x,
      rotation_y,
      rotation_z,
      rotation_w,
      scale_x,
      scale_y,
      scale_z,
      previous_x,
      previous_y,
      previous_z,
      previous_rotation_x,
      previous_rotation_y,
      previous_rotation_z,
      previous_rotation_w,
      previous_scale_x,
      previous_scale_y,
      previous_scale_z,
      world_from_local,
      previous_world_from_local,
      color_r,
      color_g,
      color_b,
      color_a,
      texture_id,
      uv_transform_a,
      uv_transform_b,
      uv_transform_c,
      uv_transform_d,
      uv_transform_tx,
      uv_transform_ty,
      uv_transform_mode,
      normal_texture_id,
      emissive_texture_id,
      metallic_roughness_texture_id,
      occlusion_texture_id,
      depth_texture_id,
      emissive_r,
      emissive_g,
      emissive_b,
      emissive_exposure_weight,
      metallic,
      roughness,
      reflectance,
      parallax_depth_scale,
      max_parallax_layer_count,
      max_relief_mapping_search_steps,
      anisotropy_texture_id,
      anisotropy_strength,
      anisotropy_rotation,
      specular_texture_id,
      specular_tint_texture_id,
      clearcoat_texture_id,
      clearcoat_roughness_texture_id,
      clearcoat_normal_texture_id,
      specular_tint_r,
      specular_tint_g,
      specular_tint_b,
      diffuse_transmission,
      specular_transmission,
      thickness,
      ior,
      attenuation_color_r,
      attenuation_color_g,
      attenuation_color_b,
      attenuation_distance,
      clearcoat,
      clearcoat_perceptual_roughness,
      alpha_cutoff,
      material_flags,
      forward_decal_inv_depth_fade_factor,
      material_pipeline_id,
      lightmap_exposure,
      lightmap_texture_id,
      lightmap_slab_index,
      lightmap_slot_index,
      lightmap_slab_texture_ids,
      lightmap_uv_min_x,
      lightmap_uv_min_y,
      lightmap_uv_max_x,
      lightmap_uv_max_y,
      deferred_lighting_pass_id,
      transmission_source_texture_id,
      transmission_blur_taps,
      transmission_steps,
      point_shadow_texture_id,
      point_shadow_enabled,
      point_shadow_depth_bias,
      mesh_flags,
      environment_diffuse_texture_id,
      environment_specular_texture_id,
      environment_map_intensity,
      environment_map_rotation_x,
      environment_map_rotation_y,
      environment_map_rotation_z,
      environment_map_rotation_w,
      cull_mode,
      vertex_shader_path,
      fragment_shader_path,
      material_extension_bind_group_data,
      skinning_key_hi,
      skinning_key_lo,
      morph_weights_index~,
      previous_morph_weights_index~,
      morph_targets_texture_id~,
      skinning_matrices~,
    ) catch {
      err => debug_runtime_error("draw_mesh3d", err)
    }
  }
}
