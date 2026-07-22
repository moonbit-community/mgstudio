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
// Bevy source: `bevy/crates/bevy_pbr/src/ssr/mod.rs`.

///|
const MESH3D_SCREEN_SPACE_REFLECTIONS_SHADER_PATH : String = "pbr/ssr/ssr.wgsl"

///|
fn mesh3d_ssr_uniform_bytes(
  min_perceptual_roughness_start : Float,
  min_perceptual_roughness_end : Float,
  max_perceptual_roughness_start : Float,
  max_perceptual_roughness_end : Float,
  edge_fadeout_start : Float,
  edge_fadeout_end : Float,
  thickness : Float,
  linear_steps : Int,
  linear_march_exponent : Float,
  bisection_steps : Int,
  use_secant : Bool,
) -> Bytes {
  u32le_pack([
    f32_bits(min_perceptual_roughness_start),
    f32_bits(min_perceptual_roughness_end),
    f32_bits(max_perceptual_roughness_start),
    f32_bits(max_perceptual_roughness_end),
    f32_bits(edge_fadeout_end),
    f32_bits(edge_fadeout_start),
    f32_bits(thickness),
    linear_steps.reinterpret_as_uint(),
    f32_bits(linear_march_exponent),
    bisection_steps.reinterpret_as_uint(),
    if use_secant {
      1U
    } else {
      0U
    },
  ])
}

///|
pub fn GpuBackend::prepare_mesh3d_screen_space_reflections_settings(
  self : GpuBackend,
  min_perceptual_roughness_start : Float,
  min_perceptual_roughness_end : Float,
  max_perceptual_roughness_start : Float,
  max_perceptual_roughness_end : Float,
  edge_fadeout_start : Float,
  edge_fadeout_end : Float,
  thickness : Float,
  linear_steps : Int,
  linear_march_exponent : Float,
  bisection_steps : Int,
  use_secant : Bool,
) -> Unit raise GpuBackendError {
  ensure_mesh3d_view_binding_buffers(self)
  guard self.mesh3d_ssr_settings_buf is Some(buffer) else {
    fatal("wgpu: missing mesh3d ssr settings buffer")
  }
  self.queue.write_buffer(
    buffer,
    0UL,
    mesh3d_ssr_uniform_bytes(
      min_perceptual_roughness_start, min_perceptual_roughness_end, max_perceptual_roughness_start,
      max_perceptual_roughness_end, edge_fadeout_start, edge_fadeout_end, thickness,
      linear_steps, linear_march_exponent, bisection_steps, use_secant,
    ),
  )
}

///|
fn mesh3d_ssr_bind_group_layout(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  match backend.mesh3d_ssr_bind_group_layout {
    Some(layout) => layout
    None => {
      let frag = ss(@wgpu.SHADER_STAGE_FRAGMENT)
      let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
      let ok = builder.add_texture(
          0U,
          frag,
          @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
          @wgpu.TEXTURE_VIEW_DIMENSION_2D,
        ) &&
        builder.add_sampler(1U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
        builder.add_sampler(2U, frag, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
        builder.add_sampler(3U, frag, @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING) &&
        builder.add_texture(
          4U,
          frag,
          @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
          @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
        )
      if !ok {
        builder.free()
        fatal(
          "wgpu: failed to build screen-space reflections bind group layout",
        )
      }
      let layout = builder.finish(
        backend.device,
        label="mgstudio_screen_space_reflections_bind_group_layout",
      )
      backend.mesh3d_ssr_bind_group_layout = Some(layout)
      layout
    }
  }
}

///|
fn mesh3d_ssr_color_sampler(backend : GpuBackend) -> @wgpu.Sampler {
  match backend.mesh3d_ssr_color_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_linear_clamp()
      backend.mesh3d_ssr_color_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_ssr_depth_linear_sampler(backend : GpuBackend) -> @wgpu.Sampler {
  match backend.mesh3d_ssr_depth_linear_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_linear_clamp()
      backend.mesh3d_ssr_depth_linear_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_ssr_depth_nearest_sampler(backend : GpuBackend) -> @wgpu.Sampler {
  match backend.mesh3d_ssr_depth_nearest_sampler {
    Some(sampler) => sampler
    None => {
      let sampler = backend.device.create_sampler_nearest_clamp()
      backend.mesh3d_ssr_depth_nearest_sampler = Some(sampler)
      sampler
    }
  }
}

///|
fn mesh3d_ssr_shader_defines(
  pass_state : GpuPassState,
  atmosphere : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = HashMap([])
  defines.set("DEPTH_PREPASS", true)
  defines.set("DEFERRED_PREPASS", true)
  defines.set("SCREEN_SPACE_REFLECTIONS", true)
  defines.set("USE_DEPTH_SAMPLERS", true)
  if pass_state.environment_map_intensity > 0.0F {
    defines.set("ENVIRONMENT_MAP", true)
  }
  if mesh3d_light_probe_binding_arrays_are_usable() {
    defines.set("MULTIPLE_LIGHT_PROBES_IN_ARRAY", true)
  }
  if atmosphere {
    defines.set("ATMOSPHERE", true)
  }
  if mesh3d_bluenoise_texture_feature_enabled() {
    defines.set("BLUE_NOISE_TEXTURE", true)
  }
  if mesh3d_dfg_lut_feature_enabled() {
    defines.set("DFG_LUT", true)
  }
  if mesh3d_area_light_luts_feature_enabled() {
    defines.set("AREA_LIGHT_LUTS", true)
  }
  defines
}

///|
fn mesh3d_ssr_view_layout_key(
  pass_state : GpuPassState,
  atmosphere : Bool,
) -> @mesh_view_layout.MeshPipelineViewLayoutKey {
  @mesh_view_layout.mesh_view_layout_key(
    pass_state.msaa_sample_count > 1,
    pass_state.prepass_depth_texture_id >= 0,
    pass_state.prepass_normal_texture_id >= 0,
    pass_state.prepass_motion_vector_texture_id >= 0,
    true,
    false,
    atmosphere,
    mesh3d_bluenoise_texture_feature_enabled(),
    tonemap_in_shader=pass_state.tonemap_in_shader,
    environment_map=pass_state.environment_map_intensity > 0.0F,
    screen_space_ambient_occlusion=false,
    irradiance_volume=mesh3d_irradiance_volume_texture_ids_have_loaded_texture(
      pass_state.irradiance_volume_texture_ids,
    ),
    screen_space_reflections=true,
    distance_fog=false,
    area_light_luts=mesh3d_area_light_luts_feature_enabled(),
    dfg_lut=mesh3d_dfg_lut_feature_enabled(),
  )
}

///|
fn mesh3d_ssr_pipeline_cache_get(
  backend : GpuBackend,
  color_format : UInt,
  view_layout_key_bits : UInt,
  atmosphere : Bool,
) -> GpuScreenSpaceReflectionsPipelineCacheEntry? {
  for entry in backend.mesh3d_ssr_pipeline_cache {
    if entry.color_format == color_format &&
      entry.view_layout_key_bits == view_layout_key_bits &&
      entry.atmosphere == atmosphere {
      return Some(entry)
    }
  }
  None
}

///|
fn mesh3d_ssr_pipeline_get_or_create(
  backend : GpuBackend,
  pass_state : GpuPassState,
  color_format : @wgpu.TextureFormat,
  view_layout_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
  atmosphere : Bool,
) -> GpuScreenSpaceReflectionsPipelineCacheEntry raise GpuBackendError {
  let color_format_bits = color_format.to_u32()
  let view_layout_key_bits = view_layout_key.bits()
  match
    mesh3d_ssr_pipeline_cache_get(
      backend, color_format_bits, view_layout_key_bits, atmosphere,
    ) {
    Some(entry) => return entry
    None => ()
  }
  let layout_entry = mesh3d_material_pipeline_layout_get_or_create(
    backend,
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    None,
    default_view_layout_key=view_layout_key,
  )
  let ssr_layout = mesh3d_ssr_bind_group_layout(backend)
  let pipeline_layout = create_pipeline_layout_3(
    backend.device,
    layout_entry.view_bind_group_layout,
    layout_entry.binding_arrays_bind_group_layout,
    ssr_layout,
  )
  let vertex_source = load_fullscreen_vertex_wgsl_required(backend)
  let fragment_source = load_wgsl_preprocessed(
    backend.assets_base,
    MESH3D_SCREEN_SPACE_REFLECTIONS_SHADER_PATH,
    mesh3d_ssr_shader_defines(pass_state, atmosphere),
    mesh3d_forward_value_defines(),
  )
  let vertex_sm = create_postprocess_shader_module(
    backend, vertex_source, "screen-space reflections vertex",
  )
  let fragment_sm = create_postprocess_shader_module(
    backend, fragment_source, "screen-space reflections fragment",
  ) catch {
    err => {
      vertex_sm.release()
      raise err
    }
  }
  let builder = @wgpu.RenderPipelineDescBuilder::new(
    vertex_sm,
    layout=pipeline_layout,
  ) catch {
    err => {
      err |> ignore
      vertex_sm.release()
      fragment_sm.release()
      pipeline_layout.release()
      fatal(
        "wgpu: failed to build screen-space reflections pipeline descriptor",
      )
    }
  }
  try {
    builder.set_entry_points("fullscreen_vertex_shader", "fragment")
    builder.set_fragment_module(fragment_sm)
    builder.set_color_target_format(color_format)
  } catch {
    err => {
      err |> ignore
      builder.free()
      vertex_sm.release()
      fragment_sm.release()
      pipeline_layout.release()
      fatal(
        "wgpu: failed to configure screen-space reflections pipeline descriptor",
      )
    }
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = try {
    let desc = builder.finish_descriptor_ptr()
    let pipeline = backend.device.create_render_pipeline_ptr(desc)
    @wgpu_c.render_pipeline_descriptor_free(desc)
    builder.free()
    pipeline
  } catch {
    err => {
      err |> ignore
      ignore(backend.device.pop_error_scope_sync_result(backend.instance))
      vertex_sm.release()
      fragment_sm.release()
      pipeline_layout.release()
      fatal("wgpu: failed to create screen-space reflections pipeline")
    }
  }
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  vertex_sm.release()
  fragment_sm.release()
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to create screen-space reflections pipeline",
    )
    pipeline.release()
    pipeline_layout.release()
    fatal(message)
  }
  let entry = GpuScreenSpaceReflectionsPipelineCacheEntry::{
    color_format: color_format_bits,
    view_layout_key_bits,
    atmosphere,
    pipeline_layout,
    bind_group_layout: ssr_layout,
    pipeline,
  }
  backend.mesh3d_ssr_pipeline_cache.push(entry)
  entry
}

///|
fn mesh3d_ssr_stbn_view(texture : GpuTextureInfo) -> (@wgpu.TextureView, Bool) {
  match texture.sample_view {
    Some(view) => (view, false)
    None => {
      let view = texture.texture.create_view_u32(
        texture.format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
        texture_view_aspect_for_format(texture.format),
        0U,
        1U,
        0U,
        texture.mip_level_count.reinterpret_as_uint(),
      )
      view.set_label("mgstudio_screen_space_reflections_stbn_view")
      (view, true)
    }
  }
}

///|
fn mesh3d_ssr_bind_group(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  color_texture : GpuTextureInfo,
  blue_noise_texture : GpuTextureInfo,
) -> @wgpu.BindGroup raise GpuBackendError {
  let (stbn_view, release_stbn_view) = mesh3d_ssr_stbn_view(blue_noise_texture)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_texture_view(0U, color_texture.view) &&
    builder.add_sampler(1U, mesh3d_ssr_color_sampler(backend)) &&
    builder.add_sampler(2U, mesh3d_ssr_depth_linear_sampler(backend)) &&
    builder.add_sampler(3U, mesh3d_ssr_depth_nearest_sampler(backend)) &&
    builder.add_texture_view(4U, stbn_view)
  if !ok {
    if release_stbn_view {
      stbn_view.release()
    }
    builder.free()
    fatal("wgpu: failed to build screen-space reflections bind group")
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_screen_space_reflections_bind_group", "wgpu: failed to build screen-space reflections bind group",
  )
  if release_stbn_view {
    stbn_view.release()
  }
  bind_group
}

///|
pub fn GpuBackend::mesh3d_draw_screen_space_reflections(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  source_texture_id : Int,
  ping_target_id : Int,
  atmosphere : Bool,
) -> Unit raise GpuBackendError {
  let debug_ssr = @sys.get_env_var("MGSTUDIO_ATMOSPHERE_SSR_DEBUG") is Some(_)
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  if debug_ssr {
    println(
      "[atmosphere-ssr] start source=\{source_texture_id} ping=\{ping_target_id} target=\{pass_state.target_id} depth=\{pass_state.prepass_depth_texture_id} deferred=\{pass_state.prepass_deferred_texture_id} blue_noise=\{pass_state.pbr_blue_noise_texture_id} env_intensity=\{pass_state.environment_map_intensity}",
    )
  }
  guard source_texture_id >= 0 && ping_target_id >= 0 else {
    if debug_ssr {
      println("[atmosphere-ssr] skip invalid source/ping")
    }
    return
  }
  guard pass_state.prepass_depth_texture_id >= 0 else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing depth prepass")
    }
    return
  }
  guard pass_state.prepass_deferred_texture_id >= 0 else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing deferred prepass")
    }
    return
  }
  guard pass_state.pbr_blue_noise_texture_id >= 0 else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing blue noise")
    }
    return
  }
  guard find_texture(self, source_texture_id) is Some(source_texture) else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing source texture")
    }
    return
  }
  guard find_texture(self, pass_state.pbr_blue_noise_texture_id)
    is Some(blue_noise_texture) else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing blue noise texture")
    }
    return
  }
  guard target_view(self, ping_target_id, pass_state.target_layer)
    is Some(destination_view) else {
    if debug_ssr {
      println("[atmosphere-ssr] skip missing destination view")
    }
    return
  }
  guard current_pass_color_format(self) is Some(color_format) else { return }
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
  let view_layout_key = mesh3d_ssr_view_layout_key(pass_state, atmosphere)
  let pipeline_entry = mesh3d_ssr_pipeline_get_or_create(
    self, pass_state, color_format, view_layout_key, atmosphere,
  )
  ignore(pipeline_entry.pipeline_layout)
  let transmission_source_texture_id = if pass_state.transmission_source_texture_id <
    0 {
    ensure_transmission_source_fallback_texture(self).id
  } else {
    pass_state.transmission_source_texture_id
  }
  let point_shadow_texture_id = if pass_state.point_shadow_texture_id < 0 {
    ensure_point_shadow_fallback_texture(self).id
  } else {
    pass_state.point_shadow_texture_id
  }
  let directional_shadow_texture_id = if pass_state.directional_shadow_texture_id <
    0 {
    ensure_directional_shadow_fallback_texture(self).id
  } else {
    pass_state.directional_shadow_texture_id
  }
  let environment_diffuse_texture_id = if pass_state.environment_diffuse_texture_id <
    0 {
    ensure_environment_map_fallback_texture(self).id
  } else {
    pass_state.environment_diffuse_texture_id
  }
  let environment_specular_texture_id = if pass_state.environment_specular_texture_id <
    0 {
    ensure_environment_map_fallback_texture(self).id
  } else {
    pass_state.environment_specular_texture_id
  }
  guard resolve_mesh3d_texture(self, transmission_source_texture_id)
    is Some(transmission_source_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    return
  }
  guard resolve_mesh3d_texture(self, environment_specular_texture_id)
    is Some(environment_specular_texture) else {
    return
  }
  let (view_bg, view_offsets, binding_arrays_bg) = mesh3d_frame_view_bg_cache_get_or_create(
    self,
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    None,
    pass_state.tonemap_in_shader,
    pass_uniforms,
    pass_state.light_probes_uniform_offset,
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
    pbr_blue_noise_texture_id=pass_state.pbr_blue_noise_texture_id,
    pbr_area_light_luts_texture_id=pass_state.pbr_area_light_luts_texture_id,
    pbr_dfg_lut_texture_id=pass_state.pbr_dfg_lut_texture_id,
    default_view_layout_key=view_layout_key,
  )
  let ssr_bg = mesh3d_ssr_bind_group(
    self,
    pipeline_entry.bind_group_layout,
    source_texture,
    blue_noise_texture,
  )
  let had_active_pass = frame.pass is Some(_)
  match frame.pass {
    Some(active_pass) => {
      active_pass.end()
      active_pass.release()
      frame.pass = None
    }
    None => ()
  }
  let pass = frame.encoder.begin_render_pass_color_load(destination_view)
  pass.set_viewport(
    Float::from_double(pass_state.viewport_x.to_double()),
    Float::from_double(pass_state.viewport_y.to_double()),
    Float::from_double(pass_state.viewport_w.to_double()),
    Float::from_double(pass_state.viewport_h.to_double()),
    pass_state.viewport_depth_min,
    pass_state.viewport_depth_max,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    self,
    ping_target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  pass.set_pipeline(pipeline_entry.pipeline)
  pass.set_bind_group(0U, view_bg, view_offsets)
  pass.set_bind_group(1U, binding_arrays_bg, [])
  pass.set_bind_group(2U, ssr_bg, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  ssr_bg.release()
  if debug_ssr {
    println(
      "[atmosphere-ssr] copy ping=\{ping_target_id} -> target=\{pass_state.target_id}",
    )
  }
  self.frame_copy_texture_to_texture(pass_state.target_id, 0, 0, ping_target_id)
  if had_active_pass {
    reopen_saved_pass(self, pass_state)
  }
}

///|
pub fn prepare_mesh3d_screen_space_reflections_settings(
  min_perceptual_roughness_start~ : Float,
  min_perceptual_roughness_end~ : Float,
  max_perceptual_roughness_start~ : Float,
  max_perceptual_roughness_end~ : Float,
  edge_fadeout_start~ : Float,
  edge_fadeout_end~ : Float,
  thickness~ : Float,
  linear_steps~ : Int,
  linear_march_exponent~ : Float,
  bisection_steps~ : Int,
  use_secant~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_mesh3d_screen_space_reflections_settings(
      min_perceptual_roughness_start, min_perceptual_roughness_end, max_perceptual_roughness_start,
      max_perceptual_roughness_end, edge_fadeout_start, edge_fadeout_end, thickness,
      linear_steps, linear_march_exponent, bisection_steps, use_secant,
    ) catch {
      err =>
        debug_runtime_error(
          "prepare_mesh3d_screen_space_reflections_settings", err,
        )
    }
  }
}

///|
pub fn draw_mesh3d_screen_space_reflections(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  source_texture_id~ : Int,
  ping_target_id~ : Int,
  atmosphere~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_draw_screen_space_reflections(
      camera_key_hi, camera_key_lo, source_texture_id, ping_target_id, atmosphere,
    ) catch {
      err => debug_runtime_error("draw_mesh3d_screen_space_reflections", err)
    }
  }
}
