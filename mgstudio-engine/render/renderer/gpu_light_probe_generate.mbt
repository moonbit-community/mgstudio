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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/generate.rs`.

///|
const LIGHT_PROBE_DOWNSAMPLING_CONSTANTS_SIZE : UInt64 = 16UL

///|
const LIGHT_PROBE_FILTERING_CONSTANTS_SIZE : UInt64 = 32UL

///|
struct GpuLightProbeEnvironmentGenerator {
  downsampling_first_bgl : @wgpu.BindGroupLayout
  downsampling_second_bgl : @wgpu.BindGroupLayout
  radiance_bgl : @wgpu.BindGroupLayout
  irradiance_bgl : @wgpu.BindGroupLayout
  copy_bgl : @wgpu.BindGroupLayout
  downsampling_first_pipeline : @wgpu.ComputePipeline
  downsampling_second_pipeline : @wgpu.ComputePipeline
  radiance_pipeline : @wgpu.ComputePipeline
  irradiance_pipeline : @wgpu.ComputePipeline
  copy_pipeline : @wgpu.ComputePipeline
  sampler : @wgpu.Sampler
}

///|
struct GpuLightProbeIntermediateTexture {
  source_texture_id : Int
  base_size : Int
  mip_count : Int
  texture : @wgpu.Texture
  view : @wgpu.TextureView
}

///|
fn GpuLightProbeEnvironmentGenerator::release(
  self : GpuLightProbeEnvironmentGenerator,
) -> Unit {
  self.copy_pipeline.release()
  self.irradiance_pipeline.release()
  self.radiance_pipeline.release()
  self.downsampling_second_pipeline.release()
  self.downsampling_first_pipeline.release()
  self.copy_bgl.release()
  self.irradiance_bgl.release()
  self.radiance_bgl.release()
  self.downsampling_second_bgl.release()
  self.downsampling_first_bgl.release()
  self.sampler.release()
}

///|
fn GpuLightProbeIntermediateTexture::release(
  self : GpuLightProbeIntermediateTexture,
) -> Unit {
  self.view.release()
  self.texture.release()
}

///|
fn light_probe_generate_div_ceil(value : Int, divisor : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    ((value + divisor - 1) / divisor).reinterpret_as_uint()
  }
}

///|
fn light_probe_generate_mip_count(size : Int) -> Int {
  let mut safe_size = if size <= 0 { 1 } else { size }
  let mut count = 1
  while safe_size > 1 {
    safe_size = safe_size / 2
    count = count + 1
  }
  count
}

///|
fn light_probe_generate_downsampling_constants_bytes(
  mip_count : Int,
  base_size : Int,
) -> Bytes {
  let size = if base_size <= 0 {
    1.0F
  } else {
    Float::from_double(base_size.to_double())
  }
  u32le_pack([
    (mip_count - 1).reinterpret_as_uint(),
    0U,
    f32_bits(1.0F / size),
    f32_bits(1.0F / size),
  ])
}

///|
fn light_probe_generate_filtering_constants_bytes(
  mip_level : Int,
  sample_count : Int,
  roughness : Float,
  noise_width : Int,
  noise_height : Int,
) -> Bytes {
  u32le_pack([
    f32_bits(Float::from_double(mip_level.to_double())),
    sample_count.reinterpret_as_uint(),
    f32_bits(roughness),
    0U,
    light_probe_generate_trailing_zero_bits(noise_width),
    light_probe_generate_trailing_zero_bits(noise_height),
    0U,
    0U,
  ])
}

///|
fn light_probe_generate_trailing_zero_bits(value : Int) -> UInt {
  let mut v = if value <= 0 { 1U } else { value.reinterpret_as_uint() }
  let mut count = 0U
  while (v & 1U) == 0U {
    count = count + 1U
    v = v >> 1
  }
  count
}

///|
fn light_probe_generate_create_uniform_buffer(
  backend : GpuBackend,
  bytes : Bytes,
  label : String,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=bytes.length().to_uint64(),
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label(label)
  backend.queue.write_buffer(buffer, 0UL, bytes)
  buffer
}

///|
fn light_probe_generate_storage_view(
  texture : @wgpu.Texture,
  format : @wgpu.TextureFormat,
  mip : Int,
  label : String,
) -> @wgpu.TextureView {
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    texture_view_aspect_for_format(format),
    0U,
    6U,
    mip.reinterpret_as_uint(),
    1U,
  )
  view.set_label(label)
  view
}

///|
fn light_probe_generate_sample_array_view(
  texture : @wgpu.Texture,
  format : @wgpu.TextureFormat,
  mip : Int,
  mip_count : Int,
  label : String,
) -> @wgpu.TextureView {
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    texture_view_aspect_for_format(format),
    0U,
    6U,
    mip.reinterpret_as_uint(),
    mip_count.reinterpret_as_uint(),
  )
  view.set_label(label)
  view
}

///|
fn light_probe_generate_create_bgl_downsampling_first(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=9UL)
  let mut ok = builder.add_sampler(
      0U,
      compute,
      @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
    ) &&
    builder.add_buffer(
      1U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      min_binding_size=LIGHT_PROBE_DOWNSAMPLING_CONSTANTS_SIZE,
    ) &&
    builder.add_texture(
      2U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    )
  for binding in 3..<9 {
    ok = ok &&
      builder.add_storage_texture(
        binding.reinterpret_as_uint(),
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
      )
  }
  if !ok {
    builder.free()
    fatal("wgpu: failed to build light-probe downsampling first layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_light_probe_downsampling_first_bgl",
  )
}

///|
fn light_probe_generate_create_bgl_downsampling_second(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=9UL)
  let mut ok = builder.add_sampler(
      0U,
      compute,
      @wgpu.SAMPLER_BINDING_TYPE_FILTERING,
    ) &&
    builder.add_buffer(
      1U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      min_binding_size=LIGHT_PROBE_DOWNSAMPLING_CONSTANTS_SIZE,
    ) &&
    builder.add_texture(
      2U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    )
  for binding in 3..<9 {
    ok = ok &&
      builder.add_storage_texture(
        binding.reinterpret_as_uint(),
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
      )
  }
  if !ok {
    builder.free()
    fatal("wgpu: failed to build light-probe downsampling second layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_light_probe_downsampling_second_bgl",
  )
}

///|
fn light_probe_generate_create_bgl_filtering(
  backend : GpuBackend,
  label : String,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    ) &&
    builder.add_sampler(1U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_storage_texture(
      2U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    ) &&
    builder.add_buffer(
      3U,
      compute,
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
      min_binding_size=LIGHT_PROBE_FILTERING_CONSTANTS_SIZE,
    ) &&
    builder.add_texture(
      4U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build light-probe \{label} layout")
  }
  builder.finish(backend.device, label="mgstudio_light_probe_\{label}_bgl")
}

///|
fn light_probe_generate_create_bgl_copy(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    ) &&
    builder.add_storage_texture(
      1U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build light-probe copy layout")
  }
  builder.finish(backend.device, label="mgstudio_light_probe_copy_bgl")
}

///|
fn light_probe_generate_downsample_source(
  shader_def : String,
) -> String raise GpuBackendError {
  let value_defines = default_wgsl_value_defines()
  value_defines.set("ARRAY_TEXTURE", @wgsl_common.ShaderDefValue::Bool(true))
  value_defines.set(shader_def, @wgsl_common.ShaderDefValue::Int(1))
  preprocess_wgsl_source(
    "",
    @mip_generation_source.downsample_specialized_wgsl_source("rgba16float"),
    @hashmap.HashMap([]),
    value_defines,
  )
}

///|
fn light_probe_generate_filter_source(
  backend : GpuBackend,
) -> String raise GpuBackendError {
  let value_defines = default_wgsl_value_defines()
  value_defines.set("ARRAY_TEXTURE", @wgsl_common.ShaderDefValue::Bool(true))
  load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/light_probe/environment_filter.wgsl",
    @hashmap.HashMap([]),
    value_defines,
  )
}

///|
fn light_probe_generate_create_compute_pipeline(
  backend : GpuBackend,
  bgl : @wgpu.BindGroupLayout,
  source : String,
  entry : String,
  label : String,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let layout = backend.device.create_pipeline_layout_1(bgl)
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let shader = backend.device.create_shader_module_wgsl(source)
  let shader_result = backend.device.pop_error_scope_sync_result(
    backend.instance,
  )
  if shader_result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      shader_result,
      "wgpu: failed to build \{label} shader module",
    )
    layout.release()
    fatal(message)
  }
  backend.device.push_error_scope(@wgpu.ERROR_FILTER_VALIDATION)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, entry,
  ) catch {
    err => {
      ignore(backend.device.pop_error_scope_sync_result(backend.instance))
      layout.release()
      shader.release()
      fatal("wgpu: failed to build \{label}: \{err.message()}")
    }
  }
  let result = backend.device.pop_error_scope_sync_result(backend.instance)
  if result.error_type != @wgpu.ERROR_TYPE_NO_ERROR {
    let message = mesh3d_error_scope_message(
      result,
      "wgpu: failed to build \{label}",
    )
    pipeline.release()
    layout.release()
    shader.release()
    fatal(message)
  }
  pipeline.set_label(label)
  layout.release()
  shader.release()
  pipeline
}

///|
fn light_probe_generate_create_linear_mipmap_sampler(
  backend : GpuBackend,
) -> @wgpu.Sampler {
  let sampler = backend.device.create_sampler_u32(
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.FILTER_MODE_LINEAR,
    @wgpu.FILTER_MODE_LINEAR,
    @wgpu.MIPMAP_FILTER_MODE_LINEAR,
  )
  sampler.set_label("mgstudio_light_probe_generator_linear_sampler")
  sampler
}

///|
fn ensure_light_probe_environment_generator(
  backend : GpuBackend,
) -> GpuLightProbeEnvironmentGenerator raise GpuBackendError {
  match backend.light_probe_environment_generator {
    Some(generator) => generator
    None => {
      let pending_bgls : Array[@wgpu.BindGroupLayout] = []
      defer (for layout in pending_bgls {
        layout.release()
      })
      let pending_pipelines : Array[@wgpu.ComputePipeline] = []
      defer (for pipeline in pending_pipelines {
        pipeline.release()
      })
      let downsampling_first_bgl = light_probe_generate_create_bgl_downsampling_first(
        backend,
      )
      pending_bgls.push(downsampling_first_bgl)
      let downsampling_second_bgl = light_probe_generate_create_bgl_downsampling_second(
        backend,
      )
      pending_bgls.push(downsampling_second_bgl)
      let radiance_bgl = light_probe_generate_create_bgl_filtering(
        backend, "radiance",
      )
      pending_bgls.push(radiance_bgl)
      let irradiance_bgl = light_probe_generate_create_bgl_filtering(
        backend, "irradiance",
      )
      pending_bgls.push(irradiance_bgl)
      let copy_bgl = light_probe_generate_create_bgl_copy(backend)
      pending_bgls.push(copy_bgl)
      let first_source = light_probe_generate_downsample_source("FIRST_PASS")
      let second_source = light_probe_generate_downsample_source("SECOND_PASS")
      let filter_source = light_probe_generate_filter_source(backend)
      let copy_source = load_wgsl_preprocessed(
        backend.assets_base,
        "pbr/light_probe/copy.wgsl",
        @hashmap.HashMap([]),
        default_wgsl_value_defines(),
      )
      let downsampling_first_pipeline = light_probe_generate_create_compute_pipeline(
        backend, downsampling_first_bgl, first_source, "downsample_first", "mgstudio_light_probe_downsampling_first_pipeline",
      )
      pending_pipelines.push(downsampling_first_pipeline)
      let downsampling_second_pipeline = light_probe_generate_create_compute_pipeline(
        backend, downsampling_second_bgl, second_source, "downsample_second", "mgstudio_light_probe_downsampling_second_pipeline",
      )
      pending_pipelines.push(downsampling_second_pipeline)
      let radiance_pipeline = light_probe_generate_create_compute_pipeline(
        backend, radiance_bgl, filter_source, "generate_radiance_map", "mgstudio_light_probe_radiance_pipeline",
      )
      pending_pipelines.push(radiance_pipeline)
      let irradiance_pipeline = light_probe_generate_create_compute_pipeline(
        backend, irradiance_bgl, filter_source, "generate_irradiance_map", "mgstudio_light_probe_irradiance_pipeline",
      )
      pending_pipelines.push(irradiance_pipeline)
      let copy_pipeline = light_probe_generate_create_compute_pipeline(
        backend, copy_bgl, copy_source, "copy", "mgstudio_light_probe_copy_pipeline",
      )
      pending_pipelines.push(copy_pipeline)
      let sampler = light_probe_generate_create_linear_mipmap_sampler(backend)
      let generator = GpuLightProbeEnvironmentGenerator::{
        downsampling_first_bgl,
        downsampling_second_bgl,
        radiance_bgl,
        irradiance_bgl,
        copy_bgl,
        downsampling_first_pipeline,
        downsampling_second_pipeline,
        radiance_pipeline,
        irradiance_pipeline,
        copy_pipeline,
        sampler,
      }
      backend.light_probe_environment_generator = Some(generator)
      pending_pipelines.clear()
      pending_bgls.clear()
      generator
    }
  }
}

///|
fn ensure_light_probe_intermediate_texture(
  backend : GpuBackend,
  source_texture_id : Int,
  base_size : Int,
  mip_count : Int,
) -> GpuLightProbeIntermediateTexture {
  match backend.light_probe_environment_intermediate {
    Some(texture) =>
      if texture.source_texture_id == source_texture_id &&
        texture.base_size == base_size &&
        texture.mip_count == mip_count {
        texture
      } else {
        light_probe_generate_create_intermediate_texture(
          backend, source_texture_id, base_size, mip_count,
        )
      }
    _ =>
      light_probe_generate_create_intermediate_texture(
        backend, source_texture_id, base_size, mip_count,
      )
  }
}

///|
fn light_probe_generate_create_intermediate_texture(
  backend : GpuBackend,
  source_texture_id : Int,
  base_size : Int,
  mip_count : Int,
) -> GpuLightProbeIntermediateTexture {
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let texture = backend.device.create_texture_u32(
    base_size.reinterpret_as_uint(),
    base_size.reinterpret_as_uint(),
    6U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
      @wgpu.TEXTURE_USAGE_STORAGE_BINDING |
      @wgpu.TEXTURE_USAGE_COPY_DST,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
    mip_level_count=mip_count.reinterpret_as_uint(),
  )
  texture.set_label("mgstudio_light_probe_intermediate_environment_map")
  let view = light_probe_generate_sample_array_view(
    texture, format, 0, mip_count, "mgstudio_light_probe_intermediate_environment_map_view",
  )
  let intermediate = GpuLightProbeIntermediateTexture::{
    source_texture_id,
    base_size,
    mip_count,
    texture,
    view,
  }
  let previous = backend.light_probe_environment_intermediate
  backend.light_probe_environment_intermediate = Some(intermediate)
  if previous is Some(old) {
    old.release()
  }
  intermediate
}

///|
fn light_probe_generate_create_placeholder_storage_view(
  backend : GpuBackend,
  label : String,
) -> @wgpu.TextureView {
  let format = tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  let texture = backend.device.create_texture_u32(
    1U,
    1U,
    6U,
    @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
    ),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    format,
  )
  texture.set_label(label)
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
    texture_view_aspect_for_format(format),
    0U,
    6U,
    0U,
    1U,
  )
  view.set_label("\{label}_view")
  view
}

///|
fn light_probe_generate_mip_storage_or_placeholder(
  backend : GpuBackend,
  texture : @wgpu.Texture,
  mip : Int,
  last_mip : Int,
  label : String,
) -> @wgpu.TextureView {
  if mip <= last_mip {
    light_probe_generate_storage_view(
      texture,
      tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
      mip,
      label,
    )
  } else {
    light_probe_generate_create_placeholder_storage_view(backend, label)
  }
}

///|
fn light_probe_generate_create_bind_group_first(
  backend : GpuBackend,
  generator : GpuLightProbeEnvironmentGenerator,
  source : GpuTextureInfo,
  intermediate : GpuLightProbeIntermediateTexture,
  constants_buffer : @wgpu.Buffer,
) -> (@wgpu.BindGroup, @wgpu.TextureView, Array[@wgpu.TextureView]) raise GpuBackendError {
  let views : Array[@wgpu.TextureView] = []
  let input_view = light_probe_generate_sample_array_view(
    source.texture,
    source.format,
    0,
    1,
    "mgstudio_light_probe_downsample_first_input",
  )
  let last_mip = intermediate.mip_count - 1
  let builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
  let mut ok = builder.add_sampler(0U, generator.sampler) &&
    builder.add_buffer(1U, constants_buffer) &&
    builder.add_texture_view(2U, input_view)
  for mip in 1..<7 {
    let view = light_probe_generate_mip_storage_or_placeholder(
      backend,
      intermediate.texture,
      mip,
      last_mip,
      "mgstudio_light_probe_downsample_first_mip_\{mip}",
    )
    views.push(view)
    ok = ok && builder.add_texture_view((mip + 2).reinterpret_as_uint(), view)
  }
  if !ok {
    input_view.release()
    builder.free()
    fatal("wgpu: failed to build light-probe downsampling first bind group")
  }
  (
    builder.finish(
      backend.device,
      generator.downsampling_first_bgl,
      label="mgstudio_light_probe_downsampling_first_bg",
    ),
    input_view,
    views,
  )
}

///|
fn light_probe_generate_create_bind_group_second(
  backend : GpuBackend,
  generator : GpuLightProbeEnvironmentGenerator,
  intermediate : GpuLightProbeIntermediateTexture,
  constants_buffer : @wgpu.Buffer,
) -> (@wgpu.BindGroup, @wgpu.TextureView, Array[@wgpu.TextureView]) raise GpuBackendError {
  let views : Array[@wgpu.TextureView] = []
  let last_mip = intermediate.mip_count - 1
  let input_mip = if last_mip < 6 { last_mip } else { 6 }
  let input_view = light_probe_generate_sample_array_view(
    intermediate.texture,
    tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    input_mip,
    1,
    "mgstudio_light_probe_downsample_second_input",
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
  let mut ok = builder.add_sampler(0U, generator.sampler) &&
    builder.add_buffer(1U, constants_buffer) &&
    builder.add_texture_view(2U, input_view)
  for mip in 7..<13 {
    let view = light_probe_generate_mip_storage_or_placeholder(
      backend,
      intermediate.texture,
      mip,
      last_mip,
      "mgstudio_light_probe_downsample_second_mip_\{mip}",
    )
    views.push(view)
    ok = ok && builder.add_texture_view((mip - 4).reinterpret_as_uint(), view)
  }
  if !ok {
    input_view.release()
    builder.free()
    fatal("wgpu: failed to build light-probe downsampling second bind group")
  }
  (
    builder.finish(
      backend.device,
      generator.downsampling_second_bgl,
      label="mgstudio_light_probe_downsampling_second_bg",
    ),
    input_view,
    views,
  )
}

///|
fn light_probe_generate_create_copy_bind_group(
  backend : GpuBackend,
  generator : GpuLightProbeEnvironmentGenerator,
  source : GpuTextureInfo,
  intermediate : GpuLightProbeIntermediateTexture,
) -> (@wgpu.BindGroup, @wgpu.TextureView, @wgpu.TextureView) raise GpuBackendError {
  let src_view = light_probe_generate_sample_array_view(
    source.texture,
    source.format,
    0,
    1,
    "mgstudio_light_probe_copy_source",
  )
  let dst_view = light_probe_generate_storage_view(
    intermediate.texture,
    tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    0,
    "mgstudio_light_probe_copy_destination",
  )
  let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok = builder.add_texture_view(0U, src_view) &&
    builder.add_texture_view(1U, dst_view)
  if !ok {
    src_view.release()
    dst_view.release()
    builder.free()
    fatal("wgpu: failed to build light-probe copy bind group")
  }
  (
    builder.finish(
      backend.device,
      generator.copy_bgl,
      label="mgstudio_light_probe_copy_bg",
    ),
    src_view,
    dst_view,
  )
}

///|
fn light_probe_generate_create_filter_bind_group(
  backend : GpuBackend,
  layout : @wgpu.BindGroupLayout,
  sampler : @wgpu.Sampler,
  input_view : @wgpu.TextureView,
  output_texture : GpuTextureInfo,
  output_mip : Int,
  constants_buffer : @wgpu.Buffer,
  blue_noise : GpuTextureInfo,
  label : String,
) -> (@wgpu.BindGroup, @wgpu.TextureView, @wgpu.TextureView, Bool) raise GpuBackendError {
  let output_view = light_probe_generate_storage_view(
    output_texture.texture,
    output_texture.format,
    output_mip,
    "\{label}_output_mip_\{output_mip}",
  )
  let (blue_noise_view, release_blue_noise_view) = match
    blue_noise.sample_view {
    Some(view) => (view, false)
    None => {
      let view = blue_noise.texture.create_view_u32(
        blue_noise.format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY,
        texture_view_aspect_for_format(blue_noise.format),
        0U,
        1U,
        0U,
        blue_noise.mip_level_count.reinterpret_as_uint(),
      )
      view.set_label("\{label}_blue_noise")
      (view, true)
    }
  }
  let builder = @wgpu.BindGroupBuilder::new(max_entries=5UL)
  let ok = builder.add_texture_view(0U, input_view) &&
    builder.add_sampler(1U, sampler) &&
    builder.add_texture_view(2U, output_view) &&
    builder.add_buffer(3U, constants_buffer) &&
    builder.add_texture_view(4U, blue_noise_view)
  if !ok {
    output_view.release()
    if release_blue_noise_view {
      blue_noise_view.release()
    }
    builder.free()
    fatal("wgpu: failed to build light-probe \{label} bind group")
  }
  (
    builder.finish(backend.device, layout, label="\{label}_bg"),
    output_view,
    blue_noise_view,
    release_blue_noise_view,
  )
}

///|
fn GpuBackend::generate_environment_map_light(
  self : GpuBackend,
  source_texture_id : Int,
  diffuse_texture_id : Int,
  specular_texture_id : Int,
  blue_noise_texture_id : Int,
) -> Unit raise GpuBackendError {
  guard self.frame is Some(frame) else { return }
  guard self.pass_state is Some(pass_state) else { return }
  guard find_texture(self, source_texture_id) is Some(source) else { return }
  guard find_texture(self, diffuse_texture_id) is Some(diffuse) else { return }
  guard find_texture(self, specular_texture_id) is Some(specular) else {
    return
  }
  guard find_texture(self, blue_noise_texture_id) is Some(blue_noise) else {
    return
  }
  let generator = ensure_light_probe_environment_generator(self)
  let base_size = source.width
  let mip_count = light_probe_generate_mip_count(base_size)
  let intermediate = ensure_light_probe_intermediate_texture(
    self, source_texture_id, base_size, mip_count,
  )
  let downsampling_constants = light_probe_generate_create_uniform_buffer(
    self,
    light_probe_generate_downsampling_constants_bytes(mip_count, base_size),
    "mgstudio_light_probe_downsampling_constants",
  )
  frame.transient_buffers.push(downsampling_constants)
  let (copy_bg, copy_src_view, copy_dst_view) = light_probe_generate_create_copy_bind_group(
    self, generator, source, intermediate,
  )
  frame.transient_bind_groups.push(copy_bg)
  frame.transient_texture_views.push(copy_src_view)
  frame.transient_texture_views.push(copy_dst_view)
  let (first_bg, first_input_view, first_views) = light_probe_generate_create_bind_group_first(
    self, generator, source, intermediate, downsampling_constants,
  )
  frame.transient_bind_groups.push(first_bg)
  frame.transient_texture_views.push(first_input_view)
  for view in first_views {
    frame.transient_texture_views.push(view)
  }
  let (second_bg, second_input_view, second_views) = light_probe_generate_create_bind_group_second(
    self, generator, intermediate, downsampling_constants,
  )
  frame.transient_bind_groups.push(second_bg)
  frame.transient_texture_views.push(second_input_view)
  for view in second_views {
    frame.transient_texture_views.push(view)
  }
  mesh3d_end_active_pass_preserving_state(self)
  let copy_pass = frame.encoder.begin_compute_pass()
  copy_pass.set_pipeline(generator.copy_pipeline)
  copy_pass.set_bind_group(0U, copy_bg, [])
  copy_pass.dispatch_workgroups(
    light_probe_generate_div_ceil(base_size, 8),
    light_probe_generate_div_ceil(base_size, 8),
    6U,
  )
  copy_pass.end()
  copy_pass.release()
  let first_pass = frame.encoder.begin_compute_pass()
  first_pass.set_pipeline(generator.downsampling_first_pipeline)
  first_pass.set_bind_group(0U, first_bg, [])
  first_pass.dispatch_workgroups(
    light_probe_generate_div_ceil(base_size, 64),
    light_probe_generate_div_ceil(base_size, 64),
    6U,
  )
  first_pass.end()
  first_pass.release()
  let second_pass = frame.encoder.begin_compute_pass()
  second_pass.set_pipeline(generator.downsampling_second_pipeline)
  second_pass.set_bind_group(0U, second_bg, [])
  second_pass.dispatch_workgroups(
    light_probe_generate_div_ceil(base_size, 256),
    light_probe_generate_div_ceil(base_size, 256),
    6U,
  )
  second_pass.end()
  second_pass.release()
  let radiance_pass = frame.encoder.begin_compute_pass()
  radiance_pass.set_pipeline(generator.radiance_pipeline)
  for mip in 0..<mip_count {
    let roughness = Float::from_double(mip.to_double()) /
      Float::from_double((mip_count - 1).to_double())
    let roughness_power = (roughness * 4.0F).to_int()
    let sample_count = 32 << roughness_power
    let constants = light_probe_generate_create_uniform_buffer(
      self,
      light_probe_generate_filtering_constants_bytes(
        mip,
        sample_count,
        roughness,
        blue_noise.width,
        blue_noise.height,
      ),
      "mgstudio_light_probe_radiance_constants_\{mip}",
    )
    frame.transient_buffers.push(constants)
    let (bind_group, output_view, blue_noise_view, release_blue_noise_view) = light_probe_generate_create_filter_bind_group(
      self,
      generator.radiance_bgl,
      generator.sampler,
      intermediate.view,
      specular,
      mip,
      constants,
      blue_noise,
      "mgstudio_light_probe_radiance",
    )
    radiance_pass.set_bind_group(0U, bind_group, [])
    frame.transient_bind_groups.push(bind_group)
    frame.transient_texture_views.push(output_view)
    if release_blue_noise_view {
      frame.transient_texture_views.push(blue_noise_view)
    }
    let mip_size = {
      let value = base_size >> mip
      if value <= 0 {
        1
      } else {
        value
      }
    }
    radiance_pass.dispatch_workgroups(
      light_probe_generate_div_ceil(mip_size, 8),
      light_probe_generate_div_ceil(mip_size, 8),
      6U,
    )
  }
  radiance_pass.end()
  radiance_pass.release()
  let irradiance_constants = light_probe_generate_create_uniform_buffer(
    self,
    light_probe_generate_filtering_constants_bytes(
      0,
      1024,
      1.0F,
      blue_noise.width,
      blue_noise.height,
    ),
    "mgstudio_light_probe_irradiance_constants",
  )
  frame.transient_buffers.push(irradiance_constants)
  let (
    irradiance_bg,
    irradiance_output_view,
    irradiance_blue_noise_view,
    release_irradiance_blue_noise_view,
  ) = light_probe_generate_create_filter_bind_group(
    self,
    generator.irradiance_bgl,
    generator.sampler,
    intermediate.view,
    diffuse,
    0,
    irradiance_constants,
    blue_noise,
    "mgstudio_light_probe_irradiance",
  )
  frame.transient_bind_groups.push(irradiance_bg)
  frame.transient_texture_views.push(irradiance_output_view)
  if release_irradiance_blue_noise_view {
    frame.transient_texture_views.push(irradiance_blue_noise_view)
  }
  let irradiance_pass = frame.encoder.begin_compute_pass()
  irradiance_pass.set_pipeline(generator.irradiance_pipeline)
  irradiance_pass.set_bind_group(0U, irradiance_bg, [])
  irradiance_pass.dispatch_workgroups(4U, 4U, 6U)
  irradiance_pass.end()
  irradiance_pass.release()
  reopen_saved_pass(self, pass_state)
}

///|
pub fn host_gpu_generate_environment_map_light(
  source_texture_id~ : Int,
  diffuse_texture_id~ : Int,
  specular_texture_id~ : Int,
  blue_noise_texture_id~ : Int,
) -> Unit {
  try {
    guard ensure_backend() is Some(backend) else { return }
    backend.generate_environment_map_light(
      source_texture_id, diffuse_texture_id, specular_texture_id, blue_noise_texture_id,
    )
  } catch {
    err => debug_runtime_error("generate_environment_map_light", err)
  }
}
