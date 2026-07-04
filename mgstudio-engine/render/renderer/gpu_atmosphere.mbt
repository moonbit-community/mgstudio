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
fn atmosphere_pack_transform_buffer(
  camera_world_x : Float,
  camera_world_y : Float,
  camera_world_z : Float,
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
  let cam_atmosphere_x = world_to_atmosphere_x_axis_x * camera_world_x +
    world_to_atmosphere_y_axis_x * camera_world_y +
    world_to_atmosphere_z_axis_x * camera_world_z +
    world_to_atmosphere_translation_x
  let cam_atmosphere_y = world_to_atmosphere_x_axis_y * camera_world_x +
    world_to_atmosphere_y_axis_y * camera_world_y +
    world_to_atmosphere_z_axis_y * camera_world_z +
    world_to_atmosphere_translation_y
  let cam_atmosphere_z = world_to_atmosphere_x_axis_z * camera_world_x +
    world_to_atmosphere_y_axis_z * camera_world_y +
    world_to_atmosphere_z_axis_z * camera_world_z +
    world_to_atmosphere_translation_z
  let atmo_y_len_sq = cam_atmosphere_x * cam_atmosphere_x +
    cam_atmosphere_y * cam_atmosphere_y +
    cam_atmosphere_z * cam_atmosphere_z
  let (atmo_y_x, atmo_y_y, atmo_y_z) = if atmo_y_len_sq > 0.0F {
    let inv_len = 1.0F / Float::sqrt(atmo_y_len_sq)
    (
      cam_atmosphere_x * inv_len,
      cam_atmosphere_y * inv_len,
      cam_atmosphere_z * inv_len,
    )
  } else {
    (0.0F, 1.0F, 0.0F)
  }
  let world_ref_x = 0.0F
  let world_ref_y = 0.0F
  let world_ref_z = -1.0F
  let ref_dot = atmo_y_x * world_ref_x +
    atmo_y_y * world_ref_y +
    atmo_y_z * world_ref_z
  let ref_horizontal_x = world_ref_x - atmo_y_x * ref_dot
  let ref_horizontal_y = world_ref_y - atmo_y_y * ref_dot
  let ref_horizontal_z = world_ref_z - atmo_y_z * ref_dot
  let ref_len = Float::sqrt(
    ref_horizontal_x * ref_horizontal_x +
    ref_horizontal_y * ref_horizontal_y +
    ref_horizontal_z * ref_horizontal_z,
  )
  let atmo_z_x = ref_horizontal_x / ref_len
  let atmo_z_y = ref_horizontal_y / ref_len
  let atmo_z_z = ref_horizontal_z / ref_len
  let atmo_x_raw_x = atmo_y_y * atmo_z_z - atmo_y_z * atmo_z_y
  let atmo_x_raw_y = atmo_y_z * atmo_z_x - atmo_y_x * atmo_z_z
  let atmo_x_raw_z = atmo_y_x * atmo_z_y - atmo_y_y * atmo_z_x
  let atmo_x_len = Float::sqrt(
    atmo_x_raw_x * atmo_x_raw_x +
    atmo_x_raw_y * atmo_x_raw_y +
    atmo_x_raw_z * atmo_x_raw_z,
  )
  let atmo_x_x = atmo_x_raw_x / atmo_x_len
  let atmo_x_y = atmo_x_raw_y / atmo_x_len
  let atmo_x_z = atmo_x_raw_z / atmo_x_len
  u32le_pack([
    f32_bits(atmo_x_x),
    f32_bits(atmo_x_y),
    f32_bits(atmo_x_z),
    f32_bits(0.0F),
    f32_bits(atmo_y_x),
    f32_bits(atmo_y_y),
    f32_bits(atmo_y_z),
    f32_bits(0.0F),
    f32_bits(atmo_z_x),
    f32_bits(atmo_z_y),
    f32_bits(atmo_z_z),
    f32_bits(0.0F),
    f32_bits(camera_world_x),
    f32_bits(camera_world_y),
    f32_bits(camera_world_z),
    f32_bits(1.0F),
    f32_bits(atmo_x_x),
    f32_bits(atmo_y_x),
    f32_bits(atmo_z_x),
    f32_bits(camera_world_x),
    f32_bits(atmo_x_y),
    f32_bits(atmo_y_y),
    f32_bits(atmo_z_y),
    f32_bits(camera_world_y),
    f32_bits(atmo_x_z),
    f32_bits(atmo_y_z),
    f32_bits(atmo_z_z),
    f32_bits(camera_world_z),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(0.0F),
    f32_bits(1.0F),
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
fn atmosphere_create_sky_view_lut_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
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
    builder.add_texture(
      9U,
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
    fatal("wgpu: failed to build atmosphere sky-view LUT layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_sky_view_lut_bind_group_layout",
  )
}

///|
fn atmosphere_create_aerial_view_lut_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
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
    builder.add_texture(
      9U,
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
      @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build atmosphere aerial-view LUT layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_aerial_view_lut_bind_group_layout",
  )
}

///|
fn atmosphere_create_environment_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_texture(
      8U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      9U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      10U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      11U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    ) &&
    builder.add_sampler(12U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_storage_texture(
      13U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build atmosphere environment layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_environment_bind_group_layout",
  )
}

///|
fn atmosphere_create_render_sky_bgl(
  backend : GpuBackend,
  multisampled : Bool,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let fragment = ss(@wgpu.SHADER_STAGE_FRAGMENT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
  let ok = builder.add_buffer(0U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(1U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(2U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(3U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(4U, fragment, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_texture(
      5U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      6U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_sampler(7U, fragment, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_texture(
      8U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      9U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      10U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      11U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_3D,
    ) &&
    builder.add_sampler(12U, fragment, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_texture(
      13U,
      fragment,
      @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      multisampled~,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build atmosphere render-sky layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_atmosphere_render_sky_bind_group_layout",
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
fn atmosphere_create_sky_view_lut_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/sky_view_lut.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "main",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build atmosphere sky-view LUT pipeline: \{err.message()}",
      )
  }
  shader.release()
  pipeline.set_label("mgstudio_atmosphere_sky_view_lut_pipeline")
  pipeline
}

///|
fn atmosphere_create_aerial_view_lut_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/aerial_view_lut.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "main",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build atmosphere aerial-view LUT pipeline: \{err.message()}",
      )
  }
  shader.release()
  pipeline.set_label("mgstudio_atmosphere_aerial_view_lut_pipeline")
  pipeline
}

///|
fn atmosphere_create_environment_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/environment.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "main",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build atmosphere environment pipeline: \{err.message()}",
      )
  }
  shader.release()
  pipeline.set_label("mgstudio_atmosphere_environment_pipeline")
  pipeline
}

///|
fn atmosphere_create_render_sky_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  color_format : @wgpu.TextureFormat,
  msaa_sample_count : Int,
) -> @wgpu.RenderPipeline raise GpuBackendError {
  let vertex_source = load_wgsl_preprocessed(
    backend.assets_base,
    "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  )
  let shader_defs = @hashmap.HashMap([])
  if msaa_sample_count > 1 {
    shader_defs.set("MULTISAMPLED", true)
  }
  let fragment_source = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/atmosphere/render_sky.wgsl",
    shader_defs,
    default_wgsl_value_defines(),
  )
  let vertex_sm = create_postprocess_shader_module(
    backend, vertex_source, "mgstudio_atmosphere_render_sky vertex",
  )
  let fragment_sm = create_postprocess_shader_module(
    backend, fragment_source, "mgstudio_atmosphere_render_sky fragment",
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
      fatal("wgpu: failed to build atmosphere render-sky pipeline descriptor")
    }
  }
  try {
    builder.set_entry_points("fullscreen_vertex_shader", "main")
    builder.set_color_target_format(color_format)
    builder.set_blend_components(
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_FACTOR_SRC_ALPHA,
      @wgpu.BLEND_OPERATION_ADD,
      @wgpu.BLEND_FACTOR_ZERO,
      @wgpu.BLEND_FACTOR_ONE,
      @wgpu.BLEND_OPERATION_ADD,
    )
    if msaa_sample_count > 1 {
      builder.set_multisample(msaa_sample_count.reinterpret_as_uint())
    }
  } catch {
    err => {
      err |> ignore
      vertex_sm.release()
      fragment_sm.release()
      fatal("wgpu: failed to configure atmosphere render-sky pipeline")
    }
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = try {
    builder.set_vertex_module(vertex_sm)
    builder.set_fragment_module(fragment_sm)
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
      fatal("wgpu: failed to build atmosphere render-sky pipeline descriptor")
    }
  }
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to create atmosphere render-sky pipeline",
    )
    pipeline.release()
    vertex_sm.release()
    fragment_sm.release()
    fatal(message)
  }
  vertex_sm.release()
  fragment_sm.release()
  pipeline.set_label("mgstudio_atmosphere_render_sky_pipeline")
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
  camera_world_x~ : Float,
  camera_world_y~ : Float,
  camera_world_z~ : Float,
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
    let transform_buffer = self.device.create_buffer(
      size=MESH3D_ATMOSPHERE_TRANSFORM_BUFFER_SIZE,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
    )
    transform_buffer.set_label("mgstudio_atmosphere_transform_buffer")
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
    let sky_view_lut_bgl = atmosphere_create_sky_view_lut_bgl(self)
    let sky_view_lut_pipeline_layout = self.device.create_pipeline_layout_1(
      sky_view_lut_bgl,
    )
    sky_view_lut_pipeline_layout.set_label(
      "mgstudio_atmosphere_sky_view_lut_pipeline_layout",
    )
    let sky_view_lut_pipeline = atmosphere_create_sky_view_lut_pipeline(
      self, sky_view_lut_pipeline_layout,
    )
    let aerial_view_lut_bgl = atmosphere_create_aerial_view_lut_bgl(self)
    let aerial_view_lut_pipeline_layout = self.device.create_pipeline_layout_1(
      aerial_view_lut_bgl,
    )
    aerial_view_lut_pipeline_layout.set_label(
      "mgstudio_atmosphere_aerial_view_lut_pipeline_layout",
    )
    let aerial_view_lut_pipeline = atmosphere_create_aerial_view_lut_pipeline(
      self, aerial_view_lut_pipeline_layout,
    )
    let environment_bgl = atmosphere_create_environment_bgl(self)
    let environment_pipeline_layout = self.device.create_pipeline_layout_1(
      environment_bgl,
    )
    environment_pipeline_layout.set_label(
      "mgstudio_atmosphere_environment_pipeline_layout",
    )
    let environment_pipeline = atmosphere_create_environment_pipeline(
      self, environment_pipeline_layout,
    )
    let render_sky_bgl = atmosphere_create_render_sky_bgl(self, false)
    let render_sky_pipeline_layout = self.device.create_pipeline_layout_1(
      render_sky_bgl,
    )
    render_sky_pipeline_layout.set_label(
      "mgstudio_atmosphere_render_sky_pipeline_layout",
    )
    let render_sky_pipeline = atmosphere_create_render_sky_pipeline(
      self,
      render_sky_pipeline_layout,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      1,
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
      transform_buffer,
      transmittance_lut_bgl,
      transmittance_lut_pipeline_layout,
      transmittance_lut_pipeline,
      multiscattering_lut_bgl,
      multiscattering_lut_pipeline_layout,
      multiscattering_lut_pipeline,
      sky_view_lut_bgl,
      sky_view_lut_pipeline_layout,
      sky_view_lut_pipeline,
      aerial_view_lut_bgl,
      aerial_view_lut_pipeline_layout,
      aerial_view_lut_pipeline,
      environment_bgl,
      environment_pipeline,
      render_sky_bgl,
      render_sky_pipeline_layout,
      render_sky_pipeline,
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
  let transform_bytes = atmosphere_pack_transform_buffer(
    camera_world_x, camera_world_y, camera_world_z, world_to_atmosphere_x_axis_x,
    world_to_atmosphere_x_axis_y, world_to_atmosphere_x_axis_z, world_to_atmosphere_y_axis_x,
    world_to_atmosphere_y_axis_y, world_to_atmosphere_y_axis_z, world_to_atmosphere_z_axis_x,
    world_to_atmosphere_z_axis_y, world_to_atmosphere_z_axis_z, world_to_atmosphere_translation_x,
    world_to_atmosphere_translation_y, world_to_atmosphere_translation_z,
  )
  self.queue.write_buffer(resources.transform_buffer, 0UL, transform_bytes)
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
fn atmosphere_environment_dispatch_group_count_8(value : Int) -> UInt {
  if value <= 0 {
    0U
  } else {
    (value / 8).reinterpret_as_uint()
  }
}

///|
fn GpuBackend::mesh3d_dispatch_atmosphere_luts(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard self.mesh3d_atmosphere_resources is Some(atmosphere) else { return }
  guard self.mesh3d_scattering_medium_resources is Some(medium) else { return }
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
  let sky_view_builder = @wgpu.BindGroupBuilder::new(max_entries=12UL)
  let sky_view_ok = sky_view_builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    sky_view_builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    sky_view_builder.add_buffer(
      2U,
      atmosphere.transform_buffer,
      size=MESH3D_ATMOSPHERE_TRANSFORM_BUFFER_SIZE,
    ) &&
    sky_view_builder.add_buffer(
      3U,
      pass_uniforms.view_buffer,
      size=MESH3D_VIEW_BUFFER_SIZE,
    ) &&
    sky_view_builder.add_buffer(
      4U,
      pass_uniforms.lights_buffer,
      size=MESH3D_LIGHTS_BUFFER_SIZE,
    ) &&
    sky_view_builder.add_texture_view(5U, medium.density_view) &&
    sky_view_builder.add_texture_view(6U, medium.scattering_view) &&
    sky_view_builder.add_sampler(7U, medium.sampler) &&
    sky_view_builder.add_texture_view(8U, atmosphere.transmittance_view) &&
    sky_view_builder.add_texture_view(9U, atmosphere.multiscattering_view) &&
    sky_view_builder.add_sampler(12U, atmosphere.sampler) &&
    sky_view_builder.add_texture_view(13U, atmosphere.sky_view_view)
  if !sky_view_ok {
    transmittance_bind_group.release()
    multiscattering_bind_group.release()
    sky_view_builder.free()
    return
  }
  self.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let sky_view_bind_group = sky_view_builder.finish(
    self.device,
    atmosphere.sky_view_lut_bgl,
    label="mgstudio_atmosphere_sky_view_lut_bind_group",
  )
  let sky_view_result = self.device.pop_error_scope_sync_result(self.instance)
  if sky_view_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      sky_view_result, "wgpu: failed to build atmosphere sky-view LUT bind group",
    )
    transmittance_bind_group.release()
    multiscattering_bind_group.release()
    sky_view_bind_group.release()
    fatal(message)
  }
  let aerial_view_builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let aerial_view_ok = aerial_view_builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    aerial_view_builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    aerial_view_builder.add_buffer(
      3U,
      pass_uniforms.view_buffer,
      size=MESH3D_VIEW_BUFFER_SIZE,
    ) &&
    aerial_view_builder.add_buffer(
      4U,
      pass_uniforms.lights_buffer,
      size=MESH3D_LIGHTS_BUFFER_SIZE,
    ) &&
    aerial_view_builder.add_texture_view(5U, medium.density_view) &&
    aerial_view_builder.add_texture_view(6U, medium.scattering_view) &&
    aerial_view_builder.add_sampler(7U, medium.sampler) &&
    aerial_view_builder.add_texture_view(8U, atmosphere.transmittance_view) &&
    aerial_view_builder.add_texture_view(9U, atmosphere.multiscattering_view) &&
    aerial_view_builder.add_sampler(12U, atmosphere.sampler) &&
    aerial_view_builder.add_texture_view(13U, atmosphere.aerial_view_view)
  if !aerial_view_ok {
    transmittance_bind_group.release()
    multiscattering_bind_group.release()
    sky_view_bind_group.release()
    aerial_view_builder.free()
    return
  }
  self.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let aerial_view_bind_group = aerial_view_builder.finish(
    self.device,
    atmosphere.aerial_view_lut_bgl,
    label="mgstudio_atmosphere_aerial_view_lut_bind_group",
  )
  let aerial_view_result = self.device.pop_error_scope_sync_result(
    self.instance,
  )
  if aerial_view_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      aerial_view_result, "wgpu: failed to build atmosphere aerial-view LUT bind group",
    )
    transmittance_bind_group.release()
    multiscattering_bind_group.release()
    sky_view_bind_group.release()
    aerial_view_bind_group.release()
    fatal(message)
  }
  mesh3d_end_active_pass_preserving_state(self)
  let luts_pass = frame.encoder.begin_compute_pass()
  luts_pass.set_pipeline(atmosphere.transmittance_lut_pipeline)
  luts_pass.set_bind_group(0U, transmittance_bind_group, [])
  luts_pass.dispatch_workgroups(
    atmosphere_dispatch_group_count_16(atmosphere.transmittance_width),
    atmosphere_dispatch_group_count_16(atmosphere.transmittance_height),
    1U,
  )
  luts_pass.set_pipeline(atmosphere.multiscattering_lut_pipeline)
  luts_pass.set_bind_group(0U, multiscattering_bind_group, [])
  luts_pass.dispatch_workgroups(
    atmosphere_safe_extent(atmosphere.multiscattering_width),
    atmosphere_safe_extent(atmosphere.multiscattering_height),
    1U,
  )
  luts_pass.set_pipeline(atmosphere.sky_view_lut_pipeline)
  luts_pass.set_bind_group(0U, sky_view_bind_group, [])
  luts_pass.dispatch_workgroups(
    atmosphere_dispatch_group_count_16(atmosphere.sky_view_width),
    atmosphere_dispatch_group_count_16(atmosphere.sky_view_height),
    1U,
  )
  luts_pass.set_pipeline(atmosphere.aerial_view_lut_pipeline)
  luts_pass.set_bind_group(0U, aerial_view_bind_group, [])
  luts_pass.dispatch_workgroups(
    atmosphere_dispatch_group_count_16(atmosphere.aerial_view_width),
    atmosphere_dispatch_group_count_16(atmosphere.aerial_view_height),
    1U,
  )
  luts_pass.end()
  luts_pass.release()
  transmittance_bind_group.release()
  multiscattering_bind_group.release()
  sky_view_bind_group.release()
  aerial_view_bind_group.release()
  reopen_saved_pass(self, pass_state)
}

///|
fn GpuBackend::mesh3d_dispatch_atmosphere_environment(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
  environment_texture_id : Int,
  environment_width : Int,
  environment_height : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard self.mesh3d_atmosphere_resources is Some(atmosphere) else { return }
  guard find_texture(self, environment_texture_id) is Some(environment_texture) else {
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
  let output_view = environment_texture.texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    texture_view_aspect_for_format(tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)),
    0U,
    6U,
    0U,
    1U,
  )
  output_view.set_label("mgstudio_atmosphere_environment_output_view")
  let builder = @wgpu.BindGroupBuilder::new(max_entries=11UL)
  let ok = builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      2U,
      atmosphere.transform_buffer,
      size=MESH3D_ATMOSPHERE_TRANSFORM_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      3U,
      pass_uniforms.view_buffer,
      size=MESH3D_VIEW_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      4U,
      pass_uniforms.lights_buffer,
      size=MESH3D_LIGHTS_BUFFER_SIZE,
    ) &&
    builder.add_texture_view(8U, atmosphere.transmittance_view) &&
    builder.add_texture_view(9U, atmosphere.multiscattering_view) &&
    builder.add_texture_view(10U, atmosphere.sky_view_view) &&
    builder.add_texture_view(11U, atmosphere.aerial_view_view) &&
    builder.add_sampler(12U, atmosphere.sampler) &&
    builder.add_texture_view(13U, output_view)
  if !ok {
    output_view.release()
    builder.free()
    return
  }
  self.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let bind_group = builder.finish(
    self.device,
    atmosphere.environment_bgl,
    label="mgstudio_atmosphere_environment_bind_group",
  )
  let result = self.device.pop_error_scope_sync_result(self.instance)
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result, "wgpu: failed to build atmosphere environment bind group",
    )
    bind_group.release()
    output_view.release()
    fatal(message)
  }
  mesh3d_end_active_pass_preserving_state(self)
  let pass = frame.encoder.begin_compute_pass()
  pass.set_pipeline(atmosphere.environment_pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.dispatch_workgroups(
    atmosphere_environment_dispatch_group_count_8(environment_width),
    atmosphere_environment_dispatch_group_count_8(environment_height),
    6U,
  )
  pass.end()
  pass.release()
  bind_group.release()
  output_view.release()
  reopen_saved_pass(self, pass_state)
}

///|
fn GpuBackend::mesh3d_draw_atmosphere_sky(
  self : GpuBackend,
  camera_key_hi : Int,
  camera_key_lo : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard self.mesh3d_atmosphere_resources is Some(atmosphere) else { return }
  guard self.mesh3d_scattering_medium_resources is Some(medium) else { return }
  guard target_view(self, pass_state.target_id, pass_state.target_layer)
    is Some(color_view) else {
    return
  }
  guard self.depth_view is Some(depth_view) else { return }
  guard pass_state.msaa_sample_count <= 1 else {
    fatal("wgpu: atmosphere render-sky MSAA pipeline is not implemented")
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
  let builder = @wgpu.BindGroupBuilder::new(max_entries=14UL)
  let ok = builder.add_buffer(
      0U,
      atmosphere.atmosphere_buffer,
      size=MESH3D_ATMOSPHERE_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      1U,
      atmosphere.settings_buffer,
      size=MESH3D_ATMOSPHERE_SETTINGS_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      2U,
      atmosphere.transform_buffer,
      size=MESH3D_ATMOSPHERE_TRANSFORM_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      3U,
      pass_uniforms.view_buffer,
      size=MESH3D_VIEW_BUFFER_SIZE,
    ) &&
    builder.add_buffer(
      4U,
      pass_uniforms.lights_buffer,
      size=MESH3D_LIGHTS_BUFFER_SIZE,
    ) &&
    builder.add_texture_view(5U, medium.density_view) &&
    builder.add_texture_view(6U, medium.scattering_view) &&
    builder.add_sampler(7U, medium.sampler) &&
    builder.add_texture_view(8U, atmosphere.transmittance_view) &&
    builder.add_texture_view(9U, atmosphere.multiscattering_view) &&
    builder.add_texture_view(10U, atmosphere.sky_view_view) &&
    builder.add_texture_view(11U, atmosphere.aerial_view_view) &&
    builder.add_sampler(12U, atmosphere.sampler) &&
    builder.add_texture_view(13U, depth_view)
  if !ok {
    builder.free()
    return
  }
  let bind_group = mesh3d_finish_bind_group_checked(
    self,
    builder,
    atmosphere.render_sky_bgl,
    "mgstudio_atmosphere_render_sky_bind_group",
    "wgpu: failed to build atmosphere render-sky bind group",
  )
  mesh3d_end_active_pass_preserving_state(self)
  let pass = frame.encoder.begin_render_pass_color_load(color_view)
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
  pass.set_pipeline(atmosphere.render_sky_pipeline)
  pass.set_bind_group(0U, bind_group, [])
  pass.draw(3U, 1U, 0U, 0U)
  pass.end()
  pass.release()
  bind_group.release()
  reopen_saved_pass(self, pass_state)
}

///|
pub fn prepare_mesh3d_atmosphere_resources(
  ground_albedo_x~ : Float,
  ground_albedo_y~ : Float,
  ground_albedo_z~ : Float,
  inner_radius~ : Float,
  outer_radius~ : Float,
  camera_world_x~ : Float,
  camera_world_y~ : Float,
  camera_world_z~ : Float,
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
      camera_world_x~,
      camera_world_y~,
      camera_world_z~,
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
pub fn dispatch_mesh3d_atmosphere_luts(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_dispatch_atmosphere_luts(camera_key_hi, camera_key_lo) catch {
      err => debug_runtime_error("dispatch_mesh3d_atmosphere_luts", err)
    }
  }
}

///|
pub fn dispatch_mesh3d_atmosphere_environment(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  environment_texture_id~ : Int,
  environment_width~ : Int,
  environment_height~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_dispatch_atmosphere_environment(
      camera_key_hi, camera_key_lo, environment_texture_id, environment_width, environment_height,
    ) catch {
      err => debug_runtime_error("dispatch_mesh3d_atmosphere_environment", err)
    }
  }
}

///|
pub fn draw_mesh3d_atmosphere_sky(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_draw_atmosphere_sky(camera_key_hi, camera_key_lo) catch {
      err => debug_runtime_error("draw_mesh3d_atmosphere_sky", err)
    }
  }
}
