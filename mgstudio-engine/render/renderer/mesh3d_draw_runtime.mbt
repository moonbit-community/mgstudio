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
    self.draw_mesh3d_motion_vector_pass(
      pass,
      ps,
      mesh,
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
      transparent,
    )
    return
  }
  self.draw_mesh3d_main_pass(
    pass,
    ps,
    mesh,
    pass_kind,
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
    point_shadow_enabled,
    point_shadow_depth_bias,
    cull_mode,
    shader_path,
    skinning_key_hi,
    skinning_key_lo,
    transparent,
  )
}
