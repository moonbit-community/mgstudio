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
pub struct HostMesh3dVolumetricFogVolume {
  density_texture_id : Int
  uniform_buffer_offset : UInt
  exterior : Bool
}

///|
pub fn HostMesh3dVolumetricFogVolume::HostMesh3dVolumetricFogVolume(
  density_texture_id~ : Int,
  uniform_buffer_offset~ : UInt,
  exterior~ : Bool,
) -> HostMesh3dVolumetricFogVolume {
  HostMesh3dVolumetricFogVolume::{
    density_texture_id,
    uniform_buffer_offset,
    exterior,
  }
}

///|
fn mesh3d_volumetric_fog_depth_view(
  backend : GpuBackend,
  pass_state : GpuPassState,
) -> @wgpu.TextureView? {
  match
    find_prepass_depth_texture(backend, pass_state.prepass_depth_texture_id) {
    Some(texture) => Some(texture.view)
    None => backend.depth_view
  }
}

///|
fn mesh3d_volumetric_fog_resolved_texture(
  backend : GpuBackend,
  texture_id : Int,
) -> GpuTextureInfo? {
  if texture_id < 0 {
    return None
  }
  // Bevy uses `RenderAssets<Image>::get(id)` here: a missing density image
  // means this volume uses the textureless pipeline, not a fallback 2D texture.
  find_texture(backend, texture_id)
}

///|
fn mesh3d_volumetric_fog_bind_group(
  backend : GpuBackend,
  depth_view : @wgpu.TextureView,
  density_texture : GpuTextureInfo?,
  msaa_sample_count : Int,
) -> @wgpu.BindGroup? raise GpuBackendError {
  ensure_mesh3d_volumetric_fog_bind_group_layouts(backend)
  guard backend.mesh3d_volumetric_fog_buf is Some(fog_buffer) else {
    return None
  }
  let has_density_texture = density_texture is Some(_)
  let layout_index = mesh3d_volumetric_fog_bind_group_layout_index(
    msaa_sample_count, has_density_texture,
  )
  guard layout_index >= 0 &&
    layout_index < backend.mesh3d_volumetric_fog_bgls.length() else {
    return None
  }
  let layout = backend.mesh3d_volumetric_fog_bgls[layout_index]
  let max_entries = if has_density_texture { 4UL } else { 2UL }
  let builder = @wgpu.BindGroupBuilder::new(max_entries~)
  let mut ok = builder.add_buffer(
      0U,
      fog_buffer,
      size=MESH3D_VOLUMETRIC_FOG_UNIFORM_SIZE,
    ) &&
    builder.add_texture_view(1U, depth_view)
  match density_texture {
    Some(texture) =>
      ok = ok &&
        builder.add_texture_view(2U, texture.view) &&
        builder.add_sampler(3U, texture.sampler)
    None => ()
  }
  if !ok {
    builder.free()
    return None
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_mesh3d_volumetric_fog_bg", "wgpu: failed to build mesh3d volumetric fog bind group",
  )
  match backend.frame {
    Some(frame) => frame.transient_bind_groups.push(bind_group)
    None => ()
  }
  Some(bind_group)
}

///|
fn mesh3d_end_active_pass_preserving_state(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  if frame.pass is Some(pass) {
    flush_mesh2d_batches(backend)
    flush_ui_shadow_batches(backend)
    flush_ui_slice_batches(backend)
    flush_ui_batches(backend)
    flush_sprite_batches(backend)
    render_pass_timing_end_active_pass()
    pass.end()
    pass.release()
    frame.pass = None
  }
}

///|
fn mesh3d_volumetric_fog_draw_mesh(
  pass : @wgpu.RenderPass,
  mesh : GpuMeshInfo,
) -> Unit {
  pass.set_vertex_buffer(0U, mesh.vertex_buf, 0UL, mesh.vertex_buf.size())
  if mesh.index_count == 0U {
    pass.draw(mesh.vertex_count, 1U, mesh.vertex_start, 0U)
  } else {
    gpu_mesh_bind_index_buffer(pass, mesh)
    pass.draw_indexed(
      mesh.index_count,
      1U,
      mesh.index_start,
      mesh.vertex_start.reinterpret_as_int(),
      0U,
    )
  }
}

///|
pub fn GpuBackend::draw_mesh3d_volumetric_fog(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  plane_mesh_id : Int,
  cube_mesh_id : Int,
  textureless_pipeline_id : Int,
  textured_pipeline_id : Int,
  atmosphere : Bool,
  volumes : Array[HostMesh3dVolumetricFogVolume],
) -> Unit raise GpuBackendError {
  guard volumes.length() > 0 else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard self.frame is Some(frame) else { return }
  guard target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(color_view) else {
    return
  }
  guard mesh3d_volumetric_fog_depth_view(self, pass_state) is Some(depth_view) else {
    return
  }
  let resolved_transmission_source_texture_id = if pass_state.transmission_source_texture_id <
    0 {
    ensure_transmission_source_fallback_texture(self).id
  } else {
    pass_state.transmission_source_texture_id
  }
  let resolved_point_shadow_texture_id = if pass_state.point_shadow_texture_id <
    0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    pass_state.point_shadow_texture_id
  }
  let resolved_directional_shadow_texture_id = if pass_state.directional_shadow_texture_id <
    0 {
    ensure_directional_shadow_fallback_texture(self).id
  } else {
    pass_state.directional_shadow_texture_id
  }
  let environment_map_enabled = pass_state.environment_map_intensity > 0.0F
  let resolved_environment_diffuse_texture_id = if environment_map_enabled &&
    pass_state.environment_diffuse_texture_id >= 0 {
    pass_state.environment_diffuse_texture_id
  } else {
    -1
  }
  let resolved_environment_specular_texture_id = if environment_map_enabled &&
    pass_state.environment_specular_texture_id >= 0 {
    pass_state.environment_specular_texture_id
  } else {
    -1
  }
  guard resolve_mesh3d_texture(self, resolved_transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, resolved_directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
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
  guard mesh3d_pass_uniform_state_get_or_create(
      self,
      pass_state,
      camera_key_hi,
      camera_key_lo,
      pass_state.pass_kind,
    )
    is Some(pass_uniforms) else {
    return
  }
  let (view_bg, _) = mesh3d_frame_view_bg_cache_get_or_create(
    self,
    0UL,
    None,
    pass_state.tonemap_in_shader,
    pass_uniforms,
    transmission_source_texture,
    point_shadow_texture,
    directional_shadow_texture,
    environment_diffuse_texture,
    environment_specular_texture,
    pass_state.prepass_depth_texture_id,
    pass_state.prepass_normal_texture_id,
    pass_state.prepass_motion_vector_texture_id,
    pass_state.prepass_deferred_texture_id,
    pass_state.tonemapping_mode,
    pass_state.tonemapping_agx_lut_texture_id,
    pass_state.tonemapping_tony_lut_texture_id,
    pass_state.tonemapping_blender_lut_texture_id,
    default_view_layout_key=mesh3d_pass_mesh_view_layout_key(
      pass_state,
      atmosphere~,
    ),
  )
  guard mesh3d_volumetric_fog_pipeline_get_by_id(self, textureless_pipeline_id)
    is Some(textureless_pipeline) else {
    return
  }
  guard mesh3d_volumetric_fog_pipeline_get_by_id(self, textured_pipeline_id)
    is Some(textured_pipeline) else {
    return
  }
  guard self.mesh3d_volumetric_fog_buf is Some(_) else { return }
  mesh3d_end_active_pass_preserving_state(self)
  for volume in volumes {
    let mesh_id = if volume.exterior { cube_mesh_id } else { plane_mesh_id }
    guard find_mesh(self, mesh_id) is Some(mesh) else { continue }
    let density_texture = mesh3d_volumetric_fog_resolved_texture(
      self,
      volume.density_texture_id,
    )
    let pipeline = if density_texture is Some(_) {
      textured_pipeline
    } else {
      textureless_pipeline
    }
    guard mesh3d_volumetric_fog_bind_group(
        self,
        depth_view,
        density_texture,
        pass_state.msaa_sample_count,
      )
      is Some(volumetric_view_bind_group) else {
      continue
    }
    let render_pass = frame.encoder.begin_render_pass_color_load(color_view)
    render_pass.set_viewport(
      Float::from_double(pass_state.viewport_x.to_double()),
      Float::from_double(pass_state.viewport_y.to_double()),
      Float::from_double(pass_state.viewport_w.to_double()),
      Float::from_double(pass_state.viewport_h.to_double()),
      pass_state.viewport_depth_min,
      pass_state.viewport_depth_max,
    )
    let (sx, sy, sw, sh) = clamp_scissor_to_target(
      self,
      pass_state.target_id,
      pass_state.viewport_x,
      pass_state.viewport_y,
      pass_state.viewport_w,
      pass_state.viewport_h,
    )
    render_pass.set_scissor_rect(sx, sy, sw, sh)
    render_pass.set_pipeline(pipeline)
    render_pass.set_bind_group(
      0U,
      view_bg,
      mesh3d_descriptor_view_bind_group_dynamic_offsets(
        None,
        0,
        light_probes_uniform_offset=pass_state.light_probes_uniform_offset,
      ),
    )
    render_pass.set_bind_group(1U, volumetric_view_bind_group, [
      volume.uniform_buffer_offset,
    ])
    mesh3d_volumetric_fog_draw_mesh(render_pass, mesh)
    render_pass.end()
    render_pass.release()
  }
}

///|
pub fn draw_mesh3d_volumetric_fog(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  plane_mesh_id~ : Int,
  cube_mesh_id~ : Int,
  textureless_pipeline_id~ : Int,
  textured_pipeline_id~ : Int,
  atmosphere~ : Bool,
  volumes~ : Array[HostMesh3dVolumetricFogVolume],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_mesh3d_volumetric_fog(
      camera_key_hi, camera_key_lo, plane_mesh_id, cube_mesh_id, textureless_pipeline_id,
      textured_pipeline_id, atmosphere, volumes,
    ) catch {
      err => debug_runtime_error("draw_mesh3d_volumetric_fog", err)
    }
  }
}
