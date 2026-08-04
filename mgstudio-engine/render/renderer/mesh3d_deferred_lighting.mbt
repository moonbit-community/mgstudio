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
const MESH3D_DEFERRED_LIGHTING_SHADER_PATH : String = "pbr/deferred/deferred_lighting.wgsl"

///|
const MESH3D_COPY_DEFERRED_LIGHTING_ID_SHADER_PATH : String = "core_pipeline/deferred/copy_deferred_lighting_id.wgsl"

///|
fn mesh3d_deferred_lighting_shadow_filter_define(
  shadow_filter_method : Int,
) -> String {
  match shadow_filter_method {
    0 => "SHADOW_FILTER_METHOD_HARDWARE_2X2"
    2 => "SHADOW_FILTER_METHOD_TEMPORAL"
    _ => "SHADOW_FILTER_METHOD_GAUSSIAN"
  }
}

///|
fn mesh3d_deferred_lighting_shader_defines(
  pass_state : GpuPassState,
  screen_space_ambient_occlusion : Bool,
  screen_space_reflections : Bool,
  distance_fog : Bool,
  atmosphere : Bool,
) -> @hashmap.HashMap[String, Bool] {
  let shadow_filter_method = pass_kind_shadow_filter_method(
    pass_state.pass_kind,
  )
  let defines = mesh3d_forward_shader_defines(
    false,
    pass_state.tonemap_in_shader,
    pass_state.tonemapping_mode,
    pass_state.deband_dither_enabled,
    pass_kind_fog_enabled(pass_state.pass_kind),
    shadow_filter_method,
  )
  defines.set("DEFERRED_LIGHTING_PIPELINE", true)
  defines.set("DEFERRED_PREPASS", true)
  defines.set("STANDARD_MATERIAL_CLEARCOAT", true)
  if pass_state.prepass_normal_texture_id >= 0 {
    defines.set("NORMAL_PREPASS", true)
  }
  if pass_state.prepass_depth_texture_id >= 0 {
    defines.set("DEPTH_PREPASS", true)
  }
  if pass_state.prepass_motion_vector_texture_id >= 0 {
    defines.set("MOTION_VECTOR_PREPASS", true)
  }
  if screen_space_ambient_occlusion {
    defines.set("SCREEN_SPACE_AMBIENT_OCCLUSION", true)
  }
  if screen_space_reflections {
    defines.set("SCREEN_SPACE_REFLECTIONS", true)
  }
  if distance_fog {

  }
  if atmosphere {
    defines.set("ATMOSPHERE", true)
  }
  if pass_state.environment_map_intensity > 0.0F {
    defines.set("ENVIRONMENT_MAP", true)
  }
  if mesh3d_irradiance_volume_texture_ids_have_loaded_texture(
      pass_state.irradiance_volume_texture_ids,
    ) {
    defines.set("IRRADIANCE_VOLUME", true)
  }
  if mesh3d_light_probe_binding_arrays_are_usable() {
    defines.set("MULTIPLE_LIGHT_PROBES_IN_ARRAY", true)
    defines.set("MULTIPLE_LIGHTMAPS_IN_ARRAY", true)
  }
  defines.set(
    mesh3d_deferred_lighting_shadow_filter_define(shadow_filter_method),
    true,
  )
  defines
}

///|
fn mesh3d_deferred_lighting_view_layout_key(
  pass_state : GpuPassState,
  screen_space_ambient_occlusion : Bool,
  screen_space_reflections : Bool,
  distance_fog : Bool,
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
    screen_space_ambient_occlusion~,
    irradiance_volume=mesh3d_irradiance_volume_texture_ids_have_loaded_texture(
      pass_state.irradiance_volume_texture_ids,
    ),
    screen_space_reflections~,
    distance_fog~,
    area_light_luts=mesh3d_area_light_luts_feature_enabled(),
    dfg_lut=mesh3d_dfg_lut_feature_enabled(),
  )
}

///|
fn mesh3d_deferred_lighting_id_depth_texture_get_or_create(
  backend : GpuBackend,
  width : Int,
  height : Int,
) -> GpuDeferredLightingIdDepthTexture {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  match backend.mesh3d_deferred_lighting_id_depth_texture {
    Some(texture) =>
      if texture.width == safe_width && texture.height == safe_height {
        return texture
      } else {
        texture.view.release()
        texture.texture.release()
      }
    None => ()
  }
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let texture = backend.device.create_texture_u32(
    safe_width.reinterpret_as_uint(),
    safe_height.reinterpret_as_uint(),
    1U,
    usage,
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
  )
  texture.set_label("mgstudio_deferred_lighting_id_depth_texture_a")
  let view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY,
    0U,
    1U,
    0U,
    1U,
  )
  let result = GpuDeferredLightingIdDepthTexture::{
    width: safe_width,
    height: safe_height,
    texture,
    view,
  }
  backend.mesh3d_deferred_lighting_id_depth_texture = Some(result)
  result
}

///|
fn mesh3d_copy_deferred_lighting_id_bind_group_layout(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  match backend.mesh3d_copy_deferred_lighting_id_bind_group_layout {
    Some(layout) => layout
    None => {
      let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
      let ok = builder.add_texture(
        0U,
        ss(@wgpu.SHADER_STAGE_FRAGMENT),
        @wgpu.TEXTURE_SAMPLE_TYPE_UINT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
      if !ok {
        builder.free()
        fatal(
          "wgpu: failed to build copy deferred lighting id bind group layout",
        )
      }
      let layout = builder.finish(
        backend.device,
        label="mgstudio_copy_deferred_lighting_id_bind_group_layout",
      )
      backend.mesh3d_copy_deferred_lighting_id_bind_group_layout = Some(layout)
      layout
    }
  }
}

///|
fn mesh3d_copy_deferred_lighting_id_pipeline(
  backend : GpuBackend,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  match backend.mesh3d_copy_deferred_lighting_id_pipeline {
    Some(pipeline) => pipeline
    None => {
      let bgl = mesh3d_copy_deferred_lighting_id_bind_group_layout(backend)
      let layout = backend.device.create_pipeline_layout_1(bgl)
      let vertex_source = load_fullscreen_vertex_wgsl_required(backend)
      let fragment_source = load_wgsl_from_assets_required(
        backend,
        MESH3D_COPY_DEFERRED_LIGHTING_ID_SHADER_PATH,
      )
      let vertex_sm = create_postprocess_shader_module(
        backend, vertex_source, "copy deferred lighting id vertex",
      )
      let fragment_sm = create_postprocess_shader_module(
        backend, fragment_source, "copy deferred lighting id fragment",
      ) catch {
        err => {
          vertex_sm.release()
          raise err
        }
      }
      let builder = @wgpu.RenderPipelineDescBuilder::new(vertex_sm, layout~) catch {
        err => {
          err |> ignore
          vertex_sm.release()
          fragment_sm.release()
          layout.release()
          fatal(
            "wgpu: failed to build copy deferred lighting id pipeline descriptor",
          )
        }
      }
      try {
        builder.set_entry_points("fullscreen_vertex_shader", "fragment")
        builder.set_fragment_module(fragment_sm)
        builder.set_color_target_count(0U)
        builder.set_depth_stencil(
          tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
          depth_write_enabled=true,
          depth_compare_u32=@wgpu.COMPARE_FUNCTION_ALWAYS,
        )
      } catch {
        err => {
          err |> ignore
          builder.free()
          vertex_sm.release()
          fragment_sm.release()
          layout.release()
          fatal(
            "wgpu: failed to configure copy deferred lighting id pipeline descriptor",
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
          layout.release()
          fatal("wgpu: failed to create copy deferred lighting id pipeline")
        }
      }
      let result = backend.device.pop_error_scope_sync_result(backend.instance)
      vertex_sm.release()
      fragment_sm.release()
      if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
        let message = mesh3d_error_scope_message(
          result, "wgpu: failed to create copy deferred lighting id pipeline",
        )
        pipeline.release()
        layout.release()
        fatal(message)
      }
      backend.mesh3d_copy_deferred_lighting_id_pipeline_layout = Some(layout)
      backend.mesh3d_copy_deferred_lighting_id_pipeline = Some(pipeline)
      pipeline
    }
  }
}

///|
fn mesh3d_copy_deferred_lighting_id(
  backend : GpuBackend,
  material_id_texture_view : @wgpu.TextureView,
  depth_view : @wgpu.TextureView,
) -> Unit raise GpuBackendError {
  guard backend.frame is Some(frame) else { return }
  guard backend.pass_state is Some(pass_state) else { return }
  let pipeline = mesh3d_copy_deferred_lighting_id_pipeline(backend)
  let bgl = mesh3d_copy_deferred_lighting_id_bind_group_layout(backend)
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_texture_view(0U, material_id_texture_view)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build copy deferred lighting id bind group")
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    backend, builder, bgl, "mgstudio_copy_deferred_lighting_id_bind_group", "wgpu: failed to build copy deferred lighting id bind group",
  )
  let pass = command_encoder_begin_render_pass_depth_u32(
    frame.encoder,
    depth_view,
    depth_load_op_u32=@wgpu.LOAD_OP_CLEAR,
    depth_store_op_u32=@wgpu.STORE_OP_STORE,
    depth_clear_value_f32=0.0F,
    stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
    stencil_store_op_u32=@wgpu.STORE_OP_STORE,
    stencil_clear_value_u32=0U,
    depth_read_only=false,
    stencil_read_only=true,
  )
  pass.set_viewport(
    Float::from_double(pass_state.viewport_x.to_double()),
    Float::from_double(pass_state.viewport_y.to_double()),
    Float::from_double(pass_state.viewport_w.to_double()),
    Float::from_double(pass_state.viewport_h.to_double()),
    pass_state.viewport_depth_min,
    pass_state.viewport_depth_max,
  )
  let (sx, sy, sw, sh) = clamp_scissor_to_target(
    backend,
    pass_state.target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  bind_group.release()
}

///|
fn mesh3d_deferred_lighting_depth_id_bind_group_layout(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(
    0U,
    ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT),
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    has_dynamic_offset=false,
    min_binding_size=4UL,
  )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build deferred lighting depth id bind group layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_deferred_lighting_layout_group_2",
  )
}

///|
fn mesh3d_deferred_lighting_pipeline_cache_get(
  backend : GpuBackend,
  color_format : UInt,
  view_layout_key_bits : UInt,
  tonemap_in_shader : Bool,
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  shadow_filter_method : Int,
  screen_space_ambient_occlusion : Bool,
  screen_space_reflections : Bool,
  distance_fog : Bool,
  atmosphere : Bool,
) -> GpuDeferredLightingPipelineCacheEntry? {
  for entry in backend.mesh3d_deferred_lighting_pipeline_cache {
    if entry.color_format == color_format &&
      entry.view_layout_key_bits == view_layout_key_bits &&
      entry.tonemap_in_shader == tonemap_in_shader &&
      entry.tonemapping_mode == tonemapping_mode &&
      entry.deband_dither_enabled == deband_dither_enabled &&
      entry.shadow_filter_method == shadow_filter_method &&
      entry.screen_space_ambient_occlusion == screen_space_ambient_occlusion &&
      entry.screen_space_reflections == screen_space_reflections &&
      entry.distance_fog == distance_fog &&
      entry.atmosphere == atmosphere {
      return Some(entry)
    }
  }
  None
}

///|
fn mesh3d_deferred_lighting_pipeline_get_or_create(
  backend : GpuBackend,
  pass_state : GpuPassState,
  color_format : @wgpu.TextureFormat,
  view_layout_key : @mesh_view_layout.MeshPipelineViewLayoutKey,
  screen_space_ambient_occlusion : Bool,
  screen_space_reflections : Bool,
  distance_fog : Bool,
  atmosphere : Bool,
) -> GpuDeferredLightingPipelineCacheEntry raise GpuBackendError {
  let color_format_bits = color_format.to_u32()
  let view_layout_key_bits = view_layout_key.bits()
  let shadow_filter_method = pass_kind_shadow_filter_method(
    pass_state.pass_kind,
  )
  match
    mesh3d_deferred_lighting_pipeline_cache_get(
      backend,
      color_format_bits,
      view_layout_key_bits,
      pass_state.tonemap_in_shader,
      pass_state.tonemapping_mode,
      pass_state.deband_dither_enabled,
      shadow_filter_method,
      screen_space_ambient_occlusion,
      screen_space_reflections,
      distance_fog,
      atmosphere,
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
  let depth_id_layout = mesh3d_deferred_lighting_depth_id_bind_group_layout(
    backend,
  )
  let pipeline_layout = create_pipeline_layout_3(
    backend.device,
    layout_entry.view_bind_group_layout,
    layout_entry.binding_arrays_bind_group_layout,
    depth_id_layout,
  )
  let defines = mesh3d_deferred_lighting_shader_defines(
    pass_state, screen_space_ambient_occlusion, screen_space_reflections, distance_fog,
    atmosphere,
  )
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    MESH3D_DEFERRED_LIGHTING_SHADER_PATH,
    defines,
    mesh3d_forward_value_defines(),
  )
  let shader = create_postprocess_shader_module(
    backend, wgsl, "deferred lighting",
  )
  let builder = @wgpu.RenderPipelineDescBuilder::new(
    shader,
    layout=pipeline_layout,
  ) catch {
    err => {
      err |> ignore
      shader.release()
      pipeline_layout.release()
      depth_id_layout.release()
      fatal("wgpu: failed to build deferred lighting pipeline descriptor")
    }
  }
  try {
    builder.set_entry_points("vertex", "fragment")
    builder.set_color_target_format(color_format)
    builder.set_depth_stencil(
      tf(@wgpu.TEXTURE_FORMAT_DEPTH16_UNORM),
      depth_write_enabled=false,
      depth_compare_u32=@wgpu.COMPARE_FUNCTION_EQUAL,
    )
  } catch {
    err => {
      err |> ignore
      builder.free()
      shader.release()
      pipeline_layout.release()
      depth_id_layout.release()
      fatal("wgpu: failed to configure deferred lighting pipeline descriptor")
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
      shader.release()
      pipeline_layout.release()
      depth_id_layout.release()
      fatal("wgpu: failed to create deferred lighting pipeline")
    }
  }
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  shader.release()
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to create deferred lighting pipeline",
    )
    pipeline.release()
    pipeline_layout.release()
    depth_id_layout.release()
    fatal(message)
  }
  let entry = GpuDeferredLightingPipelineCacheEntry::{
    color_format: color_format_bits,
    view_layout_key_bits,
    tonemap_in_shader: pass_state.tonemap_in_shader,
    tonemapping_mode: pass_state.tonemapping_mode,
    deband_dither_enabled: pass_state.deband_dither_enabled,
    shadow_filter_method,
    screen_space_ambient_occlusion,
    screen_space_reflections,
    distance_fog,
    atmosphere,
    pipeline_layout,
    depth_id_bind_group_layout: depth_id_layout,
    pipeline,
  }
  backend.mesh3d_deferred_lighting_pipeline_cache.push(entry)
  entry
}

///|
fn mesh3d_deferred_lighting_depth_id_bytes(depth_id : UInt) -> Bytes {
  u32le_pack([depth_id])
}

///|
fn mesh3d_deferred_lighting_bind_depth_id(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  depth_id : UInt,
) -> @wgpu.BindGroup raise GpuBackendError {
  let bytes = mesh3d_deferred_lighting_depth_id_bytes(depth_id)
  let buffer = backend.device.create_buffer(
    size=bytes.length().to_uint64(),
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  backend.queue.write_buffer(buffer, 0UL, bytes)
  match backend.frame {
    Some(frame) => frame.transient_buffers.push(buffer)
    None => ()
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=1UL)
  let ok = builder.add_buffer(0U, buffer, size=bytes.length().to_uint64())
  if !ok {
    builder.free()
    fatal("wgpu: failed to build deferred lighting depth id bind group")
  }
  mesh3d_finish_bind_group_checked(
    backend, builder, layout, "mgstudio_deferred_lighting_layout_group_2", "wgpu: failed to build deferred lighting depth id bind group",
  )
}

///|
pub fn GpuBackend::mesh3d_draw_deferred_lighting(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  screen_space_ambient_occlusion : Bool,
  screen_space_reflections : Bool,
  distance_fog : Bool,
  atmosphere : Bool,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard pass_state.prepass_deferred_texture_id >= 0 else { return }
  guard pass_state.prepass_deferred_lighting_pass_id_texture_id >= 0 else {
    return
  }
  guard target_color_attachment(
      self,
      pass_state.target_id,
      pass_state.target_layer,
      pass_state.msaa_sample_count,
    )
    is Some((color_view, color_resolve_view)) else {
    return
  }
  guard current_pass_color_format(self) is Some(color_format) else { return }
  guard mesh3d_prepass_texture_view_for_id(
      self,
      pass_state.prepass_deferred_lighting_pass_id_texture_id,
    )
    is Some(material_id_texture_view) else {
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
  let depth_id_texture = mesh3d_deferred_lighting_id_depth_texture_get_or_create(
    self,
    pass_state.viewport_w.reinterpret_as_int(),
    pass_state.viewport_h.reinterpret_as_int(),
  )
  mesh3d_end_active_pass_preserving_state(self)
  mesh3d_copy_deferred_lighting_id(
    self,
    material_id_texture_view,
    depth_id_texture.view,
  )
  let view_layout_key = mesh3d_deferred_lighting_view_layout_key(
    pass_state, screen_space_ambient_occlusion, screen_space_reflections, distance_fog,
    atmosphere,
  )
  let pipeline_entry = mesh3d_deferred_lighting_pipeline_get_or_create(
    self, pass_state, color_format, view_layout_key, screen_space_ambient_occlusion,
    screen_space_reflections, distance_fog, atmosphere,
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
    reopen_saved_pass(self, pass_state)
    return
  }
  guard resolve_mesh3d_texture(self, point_shadow_texture_id)
    is Some(point_shadow_texture) else {
    reopen_saved_pass(self, pass_state)
    return
  }
  guard resolve_mesh3d_texture(self, directional_shadow_texture_id)
    is Some(directional_shadow_texture) else {
    reopen_saved_pass(self, pass_state)
    return
  }
  guard resolve_mesh3d_texture(self, environment_diffuse_texture_id)
    is Some(environment_diffuse_texture) else {
    reopen_saved_pass(self, pass_state)
    return
  }
  guard resolve_mesh3d_texture(self, environment_specular_texture_id)
    is Some(environment_specular_texture) else {
    reopen_saved_pass(self, pass_state)
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
  let depth_id_bg = mesh3d_deferred_lighting_bind_depth_id(
    self,
    pipeline_entry.depth_id_bind_group_layout,
    1U,
  )
  let builder = @wgpu.RenderPassDescBuilder::new(1U) catch {
    err => {
      err |> ignore
      depth_id_bg.release()
      reopen_saved_pass(self, pass_state)
      fatal("wgpu: failed to build deferred lighting render pass descriptor")
    }
  }
  try {
    builder.set_color_attachment(
      0U,
      color_view,
      load_op_u32=@wgpu.LOAD_OP_LOAD,
      store_op_u32=@wgpu.STORE_OP_STORE,
      clear_r_f32=0.0F,
      clear_g_f32=0.0F,
      clear_b_f32=0.0F,
      clear_a_f32=1.0F,
    )
    match color_resolve_view {
      Some(resolve_view) =>
        builder.set_color_attachment_resolve_target(0U, resolve_view)
      None => ()
    }
    builder.set_depth_stencil_attachment(
      depth_id_texture.view,
      depth_load_op_u32=@wgpu.LOAD_OP_LOAD,
      depth_store_op_u32=@wgpu.STORE_OP_DISCARD,
      depth_clear_value_f32=0.0F,
      stencil_load_op_u32=@wgpu.LOAD_OP_LOAD,
      stencil_store_op_u32=@wgpu.STORE_OP_STORE,
      stencil_clear_value_u32=0U,
      depth_read_only=false,
      stencil_read_only=true,
    )
  } catch {
    err => {
      err |> ignore
      builder.free()
      depth_id_bg.release()
      reopen_saved_pass(self, pass_state)
      fatal(
        "wgpu: failed to configure deferred lighting render pass descriptor",
      )
    }
  }
  let pass = builder.begin(frame.encoder) catch {
    err => {
      err |> ignore
      builder.free()
      depth_id_bg.release()
      reopen_saved_pass(self, pass_state)
      fatal("wgpu: failed to begin deferred lighting render pass")
    }
  }
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
    pass_state.target_id,
    pass_state.viewport_x,
    pass_state.viewport_y,
    pass_state.viewport_w,
    pass_state.viewport_h,
  )
  pass.set_scissor_rect(sx, sy, sw, sh)
  pass.set_pipeline(pipeline_entry.pipeline)
  pass.set_bind_group(0U, view_bg, view_offsets)
  pass.set_bind_group(1U, binding_arrays_bg, [])
  pass.set_bind_group(2U, depth_id_bg, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  depth_id_bg.release()
  reopen_saved_pass(self, pass_state)
}

///|
pub fn draw_mesh3d_deferred_lighting(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  screen_space_ambient_occlusion~ : Bool,
  screen_space_reflections~ : Bool,
  distance_fog~ : Bool,
  atmosphere~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_draw_deferred_lighting(
      camera_key_hi, camera_key_lo, screen_space_ambient_occlusion, screen_space_reflections,
      distance_fog, atmosphere,
    ) catch {
      err => debug_runtime_error("draw_mesh3d_deferred_lighting", err)
    }
  }
}
