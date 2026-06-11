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
fn atmosphere_safe_extent(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn atmosphere_create_lut_texture_2d(
  backend : GpuBackend,
  width : Int,
  height : Int,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let texture = backend.device.create_texture_u32(
    atmosphere_safe_extent(width),
    atmosphere_safe_extent(height),
    1U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_STORAGE_BINDING | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
  )
  texture.set_label(label)
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  view.set_label("\{label}_view")
  (texture, view)
}

///|
fn atmosphere_create_lut_texture_3d(
  backend : GpuBackend,
  width : Int,
  height : Int,
  depth : Int,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let texture = backend.device.create_texture_u32(
    atmosphere_safe_extent(width),
    atmosphere_safe_extent(height),
    atmosphere_safe_extent(depth),
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_STORAGE_BINDING | @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_3D),
    format,
  )
  texture.set_label(label)
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  view.set_label("\{label}_view")
  (texture, view)
}

///|
fn atmosphere_resource_shape_matches(
  resources : GpuAtmosphereResources,
  transmittance_width : Int,
  transmittance_height : Int,
  multiscattering_width : Int,
  multiscattering_height : Int,
  sky_view_width : Int,
  sky_view_height : Int,
  aerial_view_width : Int,
  aerial_view_height : Int,
  aerial_view_depth : Int,
) -> Bool {
  resources.transmittance_width == transmittance_width &&
  resources.transmittance_height == transmittance_height &&
  resources.multiscattering_width == multiscattering_width &&
  resources.multiscattering_height == multiscattering_height &&
  resources.sky_view_width == sky_view_width &&
  resources.sky_view_height == sky_view_height &&
  resources.aerial_view_width == aerial_view_width &&
  resources.aerial_view_height == aerial_view_height &&
  resources.aerial_view_depth == aerial_view_depth
}

///|
fn atmosphere_pack_storage_buffer(
  ground_albedo_x : Float,
  ground_albedo_y : Float,
  ground_albedo_z : Float,
  inner_radius : Float,
  outer_radius : Float,
  world_to_atmosphere_x_axis_x : Float,
  world_to_atmosphere_x_axis_y : Float,
  world_to_atmosphere_x_axis_z : Float,
  world_to_atmosphere_y_axis_x : Float,
  world_to_atmosphere_y_axis_y : Float,
  world_to_atmosphere_y_axis_z : Float,
  world_to_atmosphere_z_axis_x : Float,
  world_to_atmosphere_z_axis_y : Float,
  world_to_atmosphere_z_axis_z : Float,
  world_to_atmosphere_translation_x : Float,
  world_to_atmosphere_translation_y : Float,
  world_to_atmosphere_translation_z : Float,
) -> Bytes {
  u32le_pack([
    f32_bits(ground_albedo_x),
    f32_bits(ground_albedo_y),
    f32_bits(ground_albedo_z),
    f32_bits(inner_radius),
    f32_bits(outer_radius),
    0U,
    0U,
    0U,
    f32_bits(world_to_atmosphere_x_axis_x),
    f32_bits(world_to_atmosphere_x_axis_y),
    f32_bits(world_to_atmosphere_x_axis_z),
    f32_bits(0.0F),
    f32_bits(world_to_atmosphere_y_axis_x),
    f32_bits(world_to_atmosphere_y_axis_y),
    f32_bits(world_to_atmosphere_y_axis_z),
    f32_bits(0.0F),
    f32_bits(world_to_atmosphere_z_axis_x),
    f32_bits(world_to_atmosphere_z_axis_y),
    f32_bits(world_to_atmosphere_z_axis_z),
    f32_bits(0.0F),
    f32_bits(world_to_atmosphere_translation_x),
    f32_bits(world_to_atmosphere_translation_y),
    f32_bits(world_to_atmosphere_translation_z),
    f32_bits(1.0F),
  ])
}

///|
fn atmosphere_mode_to_u32(rendering_method : Int) -> UInt {
  if rendering_method <= 0 {
    0U
  } else {
    rendering_method.reinterpret_as_uint()
  }
}

///|
fn atmosphere_pack_settings_buffer(
  transmittance_width : Int,
  transmittance_height : Int,
  multiscattering_width : Int,
  multiscattering_height : Int,
  sky_view_width : Int,
  sky_view_height : Int,
  aerial_view_width : Int,
  aerial_view_height : Int,
  aerial_view_depth : Int,
  transmittance_lut_samples : Int,
  multiscattering_lut_dirs : Int,
  multiscattering_lut_samples : Int,
  sky_view_lut_samples : Int,
  aerial_view_lut_samples : Int,
  aerial_view_lut_max_distance : Float,
  sky_max_samples : Int,
  rendering_method : Int,
) -> Bytes {
  u32le_pack([
    transmittance_width.reinterpret_as_uint(),
    transmittance_height.reinterpret_as_uint(),
    multiscattering_width.reinterpret_as_uint(),
    multiscattering_height.reinterpret_as_uint(),
    sky_view_width.reinterpret_as_uint(),
    sky_view_height.reinterpret_as_uint(),
    0U,
    0U,
    aerial_view_width.reinterpret_as_uint(),
    aerial_view_height.reinterpret_as_uint(),
    aerial_view_depth.reinterpret_as_uint(),
    transmittance_lut_samples.reinterpret_as_uint(),
    multiscattering_lut_dirs.reinterpret_as_uint(),
    multiscattering_lut_samples.reinterpret_as_uint(),
    sky_view_lut_samples.reinterpret_as_uint(),
    aerial_view_lut_samples.reinterpret_as_uint(),
    f32_bits(aerial_view_lut_max_distance),
    sky_max_samples.reinterpret_as_uint(),
    atmosphere_mode_to_u32(rendering_method),
    0U,
  ])
}

///|
fn atmosphere_create_transmittance_lut_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_texture(
      5U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      6U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_sampler(7U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_storage_texture(
      13U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build atmosphere transmittance LUT layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_transmittance_lut_bind_group_layout",
  )
}

///|
fn atmosphere_create_multiscattering_lut_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=8UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_texture(
      5U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      6U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_sampler(7U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_texture(
      8U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_sampler(12U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_storage_texture(
      13U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build atmosphere multiscattering LUT layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_multiscattering_lut_bind_group_layout",
  )
}

///|
fn atmosphere_create_transmittance_lut_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/transmittance_lut.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "main",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build atmosphere transmittance LUT pipeline: \{err.message()}",
      )
  }
  shader.release()
  pipeline.set_label("mgstudio_atmosphere_transmittance_lut_pipeline")
  pipeline
}

///|
fn atmosphere_create_multiscattering_lut_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/multiscattering_lut.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "main",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build atmosphere multiscattering LUT pipeline: \{err.message()}",
      )
  }
  shader.release()
  pipeline.set_label("mgstudio_atmosphere_multiscattering_lut_pipeline")
  pipeline
}

///|
fn GpuBackend::mesh3d_prepare_atmosphere_resources(
  self : GpuBackend,
  ground_albedo_x~ : Float,
  ground_albedo_y~ : Float,
  ground_albedo_z~ : Float,
  inner_radius~ : Float,
  outer_radius~ : Float,
  world_to_atmosphere_x_axis_x~ : Float,
  world_to_atmosphere_x_axis_y~ : Float,
  world_to_atmosphere_x_axis_z~ : Float,
  world_to_atmosphere_y_axis_x~ : Float,
  world_to_atmosphere_y_axis_y~ : Float,
  world_to_atmosphere_y_axis_z~ : Float,
  world_to_atmosphere_z_axis_x~ : Float,
  world_to_atmosphere_z_axis_y~ : Float,
  world_to_atmosphere_z_axis_z~ : Float,
  world_to_atmosphere_translation_x~ : Float,
  world_to_atmosphere_translation_y~ : Float,
  world_to_atmosphere_translation_z~ : Float,
  transmittance_width~ : Int,
  transmittance_height~ : Int,
  transmittance_lut_samples~ : Int,
  multiscattering_width~ : Int,
  multiscattering_height~ : Int,
  multiscattering_lut_dirs~ : Int,
  multiscattering_lut_samples~ : Int,
  sky_view_width~ : Int,
  sky_view_height~ : Int,
  sky_view_lut_samples~ : Int,
  aerial_view_width~ : Int,
  aerial_view_height~ : Int,
  aerial_view_depth~ : Int,
  aerial_view_lut_samples~ : Int,
  aerial_view_lut_max_distance~ : Float,
  sky_max_samples~ : Int,
  rendering_method~ : Int,
) -> Unit raise GpuBackendError {
  let safe_transmittance_width = if transmittance_width <= 0 {
    1
  } else {
    transmittance_width
  }
  let safe_transmittance_height = if transmittance_height <= 0 {
    1
  } else {
    transmittance_height
  }
  let safe_multiscattering_width = if multiscattering_width <= 0 {
    1
  } else {
    multiscattering_width
  }
  let safe_multiscattering_height = if multiscattering_height <= 0 {
    1
  } else {
    multiscattering_height
  }
  let safe_sky_view_width = if sky_view_width <= 0 { 1 } else { sky_view_width }
  let safe_sky_view_height = if sky_view_height <= 0 {
    1
  } else {
    sky_view_height
  }
  let safe_aerial_view_width = if aerial_view_width <= 0 {
    1
  } else {
    aerial_view_width
  }
  let safe_aerial_view_height = if aerial_view_height <= 0 {
    1
  } else {
    aerial_view_height
  }
  let safe_aerial_view_depth = if aerial_view_depth <= 0 {
    1
  } else {
    aerial_view_depth
  }
  let needs_recreate = match self.mesh3d_atmosphere_resources {
    Some(resources) =>
      !atmosphere_resource_shape_matches(
        resources, safe_transmittance_width, safe_transmittance_height, safe_multiscattering_width,
        safe_multiscattering_height, safe_sky_view_width, safe_sky_view_height, safe_aerial_view_width,
        safe_aerial_view_height, safe_aerial_view_depth,
      )
    None => true
  }
  if needs_recreate {
    let (transmittance_texture, transmittance_view) = atmosphere_create_lut_texture_2d(
      self, safe_transmittance_width, safe_transmittance_height, "mgstudio_atmosphere_transmittance_lut",
    )
    let (multiscattering_texture, multiscattering_view) = atmosphere_create_lut_texture_2d(
      self, safe_multiscattering_width, safe_multiscattering_height, "mgstudio_atmosphere_multiscattering_lut",
    )
    let (sky_view_texture, sky_view_view) = atmosphere_create_lut_texture_2d(
      self, safe_sky_view_width, safe_sky_view_height, "mgstudio_atmosphere_sky_view_lut",
    )
    let (aerial_view_texture, aerial_view_view) = atmosphere_create_lut_texture_3d(
      self, safe_aerial_view_width, safe_aerial_view_height, safe_aerial_view_depth,
      "mgstudio_atmosphere_aerial_view_lut",
    )
    let sampler = self.device.create_sampler_linear_clamp()
    sampler.set_label("mgstudio_atmosphere_sampler")
    let atmosphere_buffer = self.device.create_buffer(
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
      usage=bu(
        @wgpu.BUFFER_USAGE_UNIFORM |
        @wgpu.BUFFER_USAGE_STORAGE |
        @wgpu.BUFFER_USAGE_COPY_DST,
      ),
    )
    atmosphere_buffer.set_label("mgstudio_atmosphere_buffer")
    let settings_buffer = self.device.create_buffer(
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    settings_buffer.set_label("mgstudio_atmosphere_settings_buffer")
    let transmittance_lut_bgl = atmosphere_create_transmittance_lut_bgl(self)
    let transmittance_lut_pipeline_layout = self.device.create_pipeline_layout_1(
      transmittance_lut_bgl,
    )
    transmittance_lut_pipeline_layout.set_label(
      "mgstudio_atmosphere_transmittance_lut_pipeline_layout",
    )
    let transmittance_lut_pipeline = atmosphere_create_transmittance_lut_pipeline(
      self, transmittance_lut_pipeline_layout,
    )
    let multiscattering_lut_bgl = atmosphere_create_multiscattering_lut_bgl(
      self,
    )
    let multiscattering_lut_pipeline_layout = self.device.create_pipeline_layout_1(
      multiscattering_lut_bgl,
    )
    multiscattering_lut_pipeline_layout.set_label(
      "mgstudio_atmosphere_multiscattering_lut_pipeline_layout",
    )
    let multiscattering_lut_pipeline = atmosphere_create_multiscattering_lut_pipeline(
      self, multiscattering_lut_pipeline_layout,
    )
    self.mesh3d_atmosphere_resource_revision += 1
    self.mesh3d_atmosphere_resources = Some(GpuAtmosphereResources::{
      transmittance_texture,
      transmittance_view,
      multiscattering_texture,
      multiscattering_view,
      sky_view_texture,
      sky_view_view,
      aerial_view_texture,
      aerial_view_view,
      sampler,
      atmosphere_buffer,
      settings_buffer,
      transmittance_lut_bgl,
      transmittance_lut_pipeline_layout,
      transmittance_lut_pipeline,
      multiscattering_lut_bgl,
      multiscattering_lut_pipeline_layout,
      multiscattering_lut_pipeline,
      transmittance_width: safe_transmittance_width,
      transmittance_height: safe_transmittance_height,
      multiscattering_width: safe_multiscattering_width,
      multiscattering_height: safe_multiscattering_height,
      sky_view_width: safe_sky_view_width,
      sky_view_height: safe_sky_view_height,
      aerial_view_width: safe_aerial_view_width,
      aerial_view_height: safe_aerial_view_height,
      aerial_view_depth: safe_aerial_view_depth,
      revision: self.mesh3d_atmosphere_resource_revision,
    })
  }
  guard self.mesh3d_atmosphere_resources is Some(resources) else { return }
  let bytes = atmosphere_pack_storage_buffer(
    ground_albedo_x, ground_albedo_y, ground_albedo_z, inner_radius, outer_radius,
    world_to_atmosphere_x_axis_x, world_to_atmosphere_x_axis_y, world_to_atmosphere_x_axis_z,
    world_to_atmosphere_y_axis_x, world_to_atmosphere_y_axis_y, world_to_atmosphere_y_axis_z,
    world_to_atmosphere_z_axis_x, world_to_atmosphere_z_axis_y, world_to_atmosphere_z_axis_z,
    world_to_atmosphere_translation_x, world_to_atmosphere_translation_y, world_to_atmosphere_translation_z,
  )
  self.queue.write_buffer(resources.atmosphere_buffer, 0UL, bytes)
  let settings_bytes = atmosphere_pack_settings_buffer(
    safe_transmittance_width,
    safe_transmittance_height,
    safe_multiscattering_width,
    safe_multiscattering_height,
    safe_sky_view_width,
    safe_sky_view_height,
    safe_aerial_view_width,
    safe_aerial_view_height,
    safe_aerial_view_depth,
    if transmittance_lut_samples <= 0 {
      1
    } else {
      transmittance_lut_samples
    },
    if multiscattering_lut_dirs <= 0 {
      1
    } else {
      multiscattering_lut_dirs
    },
    if multiscattering_lut_samples <= 0 {
      1
    } else {
      multiscattering_lut_samples
    },
    if sky_view_lut_samples <= 0 {
      1
    } else {
      sky_view_lut_samples
    },
    if aerial_view_lut_samples <= 0 {
      1
    } else {
      aerial_view_lut_samples
    },
    aerial_view_lut_max_distance,
    if sky_max_samples <= 0 {
      1
    } else {
      sky_max_samples
    },
    rendering_method,
  )
  self.queue.write_buffer(resources.settings_buffer, 0UL, settings_bytes)
}

///|
fn atmosphere_dispatch_group_count_16(value : Int) -> UInt {
  let safe = if value <= 0 { 1 } else { value }
  ((safe + 15) / 16).reinterpret_as_uint()
}

///|
fn GpuBackend::mesh3d_dispatch_atmosphere_luts(
  self : GpuBackend,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.mesh3d_atmosphere_resources is Some(atmosphere) else { return }
  guard self.mesh3d_scattering_medium_resources is Some(medium) else { return }
  let transmittance_builder = @wgpu.BindGroupBuilder::new(max_entries=6UL)
  let transmittance_ok = transmittance_builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    transmittance_builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    transmittance_builder.add_texture_view(5U, medium.density_view) &&
    transmittance_builder.add_texture_view(6U, medium.scattering_view) &&
    transmittance_builder.add_sampler(7U, medium.sampler) &&
    transmittance_builder.add_texture_view(13U, atmosphere.transmittance_view)
  if !transmittance_ok {
    transmittance_builder.free()
    return
  }
  self.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let transmittance_bind_group = transmittance_builder.finish(
    self.device,
    atmosphere.transmittance_lut_bgl,
    label="mgstudio_atmosphere_transmittance_lut_bind_group",
  )
  let transmittance_result = self.device.pop_error_scope_sync_result(
    self.instance,
  )
  if transmittance_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      transmittance_result, "wgpu: failed to build atmosphere transmittance LUT bind group",
    )
    transmittance_bind_group.release()
    fatal(message)
  }
  let multiscattering_builder = @wgpu.BindGroupBuilder::new(max_entries=8UL)
  let multiscattering_ok = multiscattering_builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    multiscattering_builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    multiscattering_builder.add_texture_view(5U, medium.density_view) &&
    multiscattering_builder.add_texture_view(6U, medium.scattering_view) &&
    multiscattering_builder.add_sampler(7U, medium.sampler) &&
    multiscattering_builder.add_texture_view(8U, atmosphere.transmittance_view) &&
    multiscattering_builder.add_sampler(12U, atmosphere.sampler) &&
    multiscattering_builder.add_texture_view(
      13U,
      atmosphere.multiscattering_view,
    )
  if !multiscattering_ok {
    transmittance_bind_group.release()
    multiscattering_builder.free()
    return
  }
  self.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let multiscattering_bind_group = multiscattering_builder.finish(
    self.device,
    atmosphere.multiscattering_lut_bgl,
    label="mgstudio_atmosphere_multiscattering_lut_bind_group",
  )
  let multiscattering_result = self.device.pop_error_scope_sync_result(
    self.instance,
  )
  if multiscattering_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      multiscattering_result, "wgpu: failed to build atmosphere multiscattering LUT bind group",
    )
    transmittance_bind_group.release()
    multiscattering_bind_group.release()
    fatal(message)
  }
  let transmittance_pass = frame.encoder.begin_compute_pass()
  transmittance_pass.set_pipeline(atmosphere.transmittance_lut_pipeline)
  transmittance_pass.set_bind_group(0U, transmittance_bind_group, [])
  transmittance_pass.dispatch_workgroups(
    atmosphere_dispatch_group_count_16(atmosphere.transmittance_width),
    atmosphere_dispatch_group_count_16(atmosphere.transmittance_height),
    1U,
  )
  transmittance_pass.end()
  transmittance_pass.release()
  // TODO(ISS-067): dispatch Bevy's multiscattering LUT shader after the
  // current native backend stall is resolved.
  transmittance_bind_group.release()
  multiscattering_bind_group.release()
}

///|
pub fn prepare_mesh3d_atmosphere_resources(
  ground_albedo_x~ : Float,
  ground_albedo_y~ : Float,
  ground_albedo_z~ : Float,
  inner_radius~ : Float,
  outer_radius~ : Float,
  world_to_atmosphere_x_axis_x~ : Float,
  world_to_atmosphere_x_axis_y~ : Float,
  world_to_atmosphere_x_axis_z~ : Float,
  world_to_atmosphere_y_axis_x~ : Float,
  world_to_atmosphere_y_axis_y~ : Float,
  world_to_atmosphere_y_axis_z~ : Float,
  world_to_atmosphere_z_axis_x~ : Float,
  world_to_atmosphere_z_axis_y~ : Float,
  world_to_atmosphere_z_axis_z~ : Float,
  world_to_atmosphere_translation_x~ : Float,
  world_to_atmosphere_translation_y~ : Float,
  world_to_atmosphere_translation_z~ : Float,
  transmittance_width~ : Int,
  transmittance_height~ : Int,
  transmittance_lut_samples~ : Int,
  multiscattering_width~ : Int,
  multiscattering_height~ : Int,
  multiscattering_lut_dirs~ : Int,
  multiscattering_lut_samples~ : Int,
  sky_view_width~ : Int,
  sky_view_height~ : Int,
  sky_view_lut_samples~ : Int,
  aerial_view_width~ : Int,
  aerial_view_height~ : Int,
  aerial_view_depth~ : Int,
  aerial_view_lut_samples~ : Int,
  aerial_view_lut_max_distance~ : Float,
  sky_max_samples~ : Int,
  rendering_method~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_prepare_atmosphere_resources(
      ground_albedo_x~,
      ground_albedo_y~,
      ground_albedo_z~,
      inner_radius~,
      outer_radius~,
      world_to_atmosphere_x_axis_x~,
      world_to_atmosphere_x_axis_y~,
      world_to_atmosphere_x_axis_z~,
      world_to_atmosphere_y_axis_x~,
      world_to_atmosphere_y_axis_y~,
      world_to_atmosphere_y_axis_z~,
      world_to_atmosphere_z_axis_x~,
      world_to_atmosphere_z_axis_y~,
      world_to_atmosphere_z_axis_z~,
      world_to_atmosphere_translation_x~,
      world_to_atmosphere_translation_y~,
      world_to_atmosphere_translation_z~,
      transmittance_width~,
      transmittance_height~,
      transmittance_lut_samples~,
      multiscattering_width~,
      multiscattering_height~,
      multiscattering_lut_dirs~,
      multiscattering_lut_samples~,
      sky_view_width~,
      sky_view_height~,
      sky_view_lut_samples~,
      aerial_view_width~,
      aerial_view_height~,
      aerial_view_depth~,
      aerial_view_lut_samples~,
      aerial_view_lut_max_distance~,
      sky_max_samples~,
      rendering_method~,
    ) catch {
      err => debug_runtime_error("prepare_mesh3d_atmosphere_resources", err)
    }
  }
}

///|
pub fn dispatch_mesh3d_atmosphere_luts() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_dispatch_atmosphere_luts() catch {
      err => debug_runtime_error("dispatch_mesh3d_atmosphere_luts", err)
    }
  }
}
