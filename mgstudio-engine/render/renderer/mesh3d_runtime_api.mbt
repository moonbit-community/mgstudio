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
pub fn prepare_mesh3d_skin_binding(
  key_hi~ : Int,
  key_lo~ : Int,
  skinning_matrices~ : Array[Float],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_skin_binding(key_hi, key_lo, skinning_matrices)
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
pub fn meshlet_required_rust_features_u64() -> UInt64 {
  @wgpu.FEATURES_TEXTURE_INT64_ATOMIC |
  @wgpu.FEATURES_TEXTURE_ATOMIC |
  @wgpu.FEATURES_SHADER_INT64 |
  @wgpu.FEATURES_SUBGROUP |
  @wgpu.FEATURES_DEPTH_CLIP_CONTROL
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
    if !backend.device.has_feature_native_subgroup_barrier() {
      return false
    }
    if !backend.device.has_feature_native_immediates() {
      return false
    }
    return true
  }
  false
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
      Fatal(message) =>
        debug("[renderer] downsample_mesh3d_depth_pyramid: Fatal(\{message})")
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
  metallic~ : Float,
  roughness~ : Float,
  reflectance~ : Float,
  parallax_depth_scale~ : Float,
  max_parallax_layer_count~ : Float,
  max_relief_mapping_search_steps~ : Float,
  anisotropy_texture_id~ : Int,
  anisotropy_strength~ : Float,
  anisotropy_rotation~ : Float,
  specular_tint_texture_id~ : Int,
  specular_tint_r~ : Float,
  specular_tint_g~ : Float,
  specular_tint_b~ : Float,
  diffuse_transmission~ : Float,
  specular_transmission~ : Float,
  thickness~ : Float,
  ior~ : Float,
  alpha_cutoff~ : Float,
  material_flags~ : UInt,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation_x? : Float = 0.0F,
  environment_map_rotation_y? : Float = 0.0F,
  environment_map_rotation_z? : Float = 0.0F,
  environment_map_rotation_w? : Float = 1.0F,
  cull_mode~ : Int,
  shader_path? : String? = None,
  skinning_key_hi? : Int = -1,
  skinning_key_lo? : Int = -1,
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
      metallic,
      roughness,
      reflectance,
      parallax_depth_scale,
      max_parallax_layer_count,
      max_relief_mapping_search_steps,
      anisotropy_texture_id,
      anisotropy_strength,
      anisotropy_rotation,
      specular_tint_texture_id,
      specular_tint_r,
      specular_tint_g,
      specular_tint_b,
      diffuse_transmission,
      specular_transmission,
      thickness,
      ior,
      alpha_cutoff,
      material_flags,
      transmission_source_texture_id,
      transmission_blur_taps,
      transmission_steps,
      point_shadow_texture_id,
      point_shadow_enabled,
      point_shadow_depth_bias,
      environment_diffuse_texture_id,
      environment_specular_texture_id,
      environment_map_intensity,
      environment_map_rotation_x,
      environment_map_rotation_y,
      environment_map_rotation_z,
      environment_map_rotation_w,
      cull_mode,
      shader_path,
      skinning_key_hi,
      skinning_key_lo,
      skinning_matrices~,
    ) catch {
      err => debug_runtime_error("draw_mesh3d", err)
    }
  }
}
