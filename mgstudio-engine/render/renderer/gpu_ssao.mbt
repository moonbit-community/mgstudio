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
fn ssao_safe_extent(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn ssao_resource_shape_matches(
  resources : GpuSsaoResources,
  width : Int,
  height : Int,
  depth_format : @wgpu.TextureFormat,
  constant_object_thickness : Float,
) -> Bool {
  resources.width == width &&
  resources.height == height &&
  resources.depth_format == depth_format &&
  resources.constant_object_thickness == constant_object_thickness
}

///|
fn ssao_create_texture_2d(
  backend : GpuBackend,
  width : Int,
  height : Int,
  mip_level_count : UInt,
  format : @wgpu.TextureFormat,
  label : String,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let texture = backend.device.create_texture_u32(
    ssao_safe_extent(width),
    ssao_safe_extent(height),
    mip_level_count,
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
fn ssao_create_texture_mip_views(
  texture : @wgpu.Texture,
  format : @wgpu.TextureFormat,
  mip_level_count : Int,
  label : String,
) -> Array[@wgpu.TextureView] {
  let views : Array[@wgpu.TextureView] = []
  for mip_level in 0..<mip_level_count {
    let view = texture.create_view_u32(
      format,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      mip_level.reinterpret_as_uint(),
      1U,
      0U,
      1U,
    )
    view.set_label("\{label}_mip_\{mip_level}_view")
    views.push(view)
  }
  views
}

///|
fn ssao_create_thickness_buffer(
  backend : GpuBackend,
  constant_object_thickness : Float,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=4UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_ssao_thickness_buffer")
  backend.queue.write_buffer(
    buffer,
    0UL,
    f32le_pack([constant_object_thickness]),
  )
  buffer
}

///|
fn ssao_pipelines_keepalive(pipelines : GpuSsaoPipelines) -> Unit {
  ignore(pipelines.common_bind_group_layout)
  ignore(pipelines.preprocess_depth_bind_group_layout)
  ignore(pipelines.ssao_bind_group_layout)
  ignore(pipelines.spatial_denoise_bind_group_layout)
  ignore(pipelines.preprocess_depth_pipeline_layout)
  ignore(pipelines.spatial_denoise_pipeline_layout)
  ignore(pipelines.preprocess_depth_pipeline)
  ignore(pipelines.spatial_denoise_pipeline)
  ignore(pipelines.hilbert_index_lut_texture)
  ignore(pipelines.hilbert_index_lut_view)
  ignore(pipelines.point_clamp_sampler)
  ignore(pipelines.linear_clamp_sampler)
}

///|
const SSAO_HILBERT_WIDTH : Int = 64

///|
fn ssao_hilbert_index(x : Int, y : Int) -> Int {
  let mut x = x
  let mut y = y
  let mut index = 0
  let mut level = SSAO_HILBERT_WIDTH / 2
  while level > 0 {
    let region_x = if (x & level) > 0 { 1 } else { 0 }
    let region_y = if (y & level) > 0 { 1 } else { 0 }
    index = index + level * level * ((3 * region_x) ^ region_y)
    if region_y == 0 {
      if region_x == 1 {
        x = SSAO_HILBERT_WIDTH - 1 - x
        y = SSAO_HILBERT_WIDTH - 1 - y
      }
      let old_x = x
      x = y
      y = old_x
    }
    level = level / 2
  }
  index
}

///|
fn ssao_hilbert_index_lut_bytes() -> Bytes {
  let values : Array[Int] = []
  for x in 0..<SSAO_HILBERT_WIDTH {
    for y in 0..<SSAO_HILBERT_WIDTH {
      values.push(ssao_hilbert_index(x, y))
    }
  }
  u16le_pack(values)
}

///|
fn ssao_create_hilbert_index_lut(
  backend : GpuBackend,
) -> (@wgpu.Texture, @wgpu.TextureView) {
  let texture = backend.device.create_texture_u32(
    SSAO_HILBERT_WIDTH.reinterpret_as_uint(),
    SSAO_HILBERT_WIDTH.reinterpret_as_uint(),
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_TEXTURE_BINDING),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    tf(@wgpu.TEXTURE_FORMAT_R16_UINT),
  )
  texture.set_label("mgstudio_ssao_hilbert_index_lut")
  let upload = ssao_hilbert_index_lut_bytes()
  let tex_info = @wgpu_c.texel_copy_texture_info_new(
    texture.raw_handle(),
    0U,
    0U,
    0U,
    0U,
  )
  let layout = @wgpu_c.texel_copy_buffer_layout_new(
    0UL,
    (SSAO_HILBERT_WIDTH * 2).reinterpret_as_uint(),
    SSAO_HILBERT_WIDTH.reinterpret_as_uint(),
  )
  let extent = @wgpu_c.extent3d_new(
    SSAO_HILBERT_WIDTH.reinterpret_as_uint(),
    SSAO_HILBERT_WIDTH.reinterpret_as_uint(),
    1U,
  )
  backend.queue.write_texture_ptr(
    tex_info,
    upload,
    layout,
    extent,
    data_size=(SSAO_HILBERT_WIDTH * SSAO_HILBERT_WIDTH * 2).to_uint64(),
  )
  @wgpu_c.extent3d_free(extent)
  @wgpu_c.texel_copy_buffer_layout_free(layout)
  @wgpu_c.texel_copy_texture_info_free(tex_info)
  let view = texture.create_view_u32(
    tf(@wgpu.TEXTURE_FORMAT_R16_UINT),
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    @wgpu.TEXTURE_ASPECT_ALL,
    0U,
    1U,
    0U,
    1U,
  )
  view.set_label("mgstudio_ssao_hilbert_index_lut_view")
  (texture, view)
}

///|
fn ssao_bool_defines(use_r16float : Bool) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  if use_r16float {
    defines.set("USE_R16FLOAT", true)
  }
  defines
}

///|
fn ssao_value_defines(
  slice_count : Int,
  samples_per_slice_side : Int,
) -> @hashmap.HashMap[String, @wgsl_common.ShaderDefValue] {
  let value_defines = default_wgsl_value_defines()
  value_defines.set("SLICE_COUNT", wgsl_def_int(slice_count))
  value_defines.set(
    "SAMPLES_PER_SLICE_SIDE",
    wgsl_def_int(samples_per_slice_side),
  )
  value_defines
}

///|
fn ssao_create_common_bind_group_layout(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
  let ok = builder.add_sampler(
      0U,
      compute,
      @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING,
    ) &&
    builder.add_sampler(1U, compute, @wgpu.SAMPLER_BINDING_TYPE_FILTERING) &&
    builder.add_buffer(2U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build ssao common bind group layout")
  }
  builder.finish(backend.device, label="mgstudio_ssao_common_bind_group_layout")
}

///|
fn ssao_create_preprocess_depth_bind_group_layout(
  backend : GpuBackend,
  depth_format : @wgpu.TextureFormat,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=6UL)
  let mut ok = builder.add_texture(
    0U,
    compute,
    @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
  )
  for binding_i in 1..<6 {
    ok = ok &&
      builder.add_storage_texture(
        binding_i.reinterpret_as_uint(),
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        depth_format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
  }
  if !ok {
    builder.free()
    fatal("wgpu: failed to build ssao preprocess depth bind group layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_ssao_preprocess_depth_bind_group_layout",
  )
}

///|
fn ssao_create_ssao_bind_group_layout(
  backend : GpuBackend,
  depth_format : @wgpu.TextureFormat,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=7UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      1U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      2U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UINT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_storage_texture(
      3U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      depth_format,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_storage_texture(
      4U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      tf(@wgpu.TEXTURE_FORMAT_R32_UINT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_buffer(5U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM) &&
    builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_UNIFORM)
  if !ok {
    builder.free()
    fatal("wgpu: failed to build ssao bind group layout")
  }
  builder.finish(backend.device, label="mgstudio_ssao_bind_group_layout")
}

///|
fn ssao_create_spatial_denoise_bind_group_layout(
  backend : GpuBackend,
  depth_format : @wgpu.TextureFormat,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=3UL)
  let ok = builder.add_texture(
      0U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_texture(
      1U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_UINT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    ) &&
    builder.add_storage_texture(
      2U,
      compute,
      @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
      depth_format,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build ssao spatial denoise bind group layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_ssao_spatial_denoise_bind_group_layout",
  )
}

///|
fn ssao_create_compute_pipeline(
  backend : GpuBackend,
  layout : @wgpu.PipelineLayout,
  shader_path : String,
  entry_point : String,
  label : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let source = load_wgsl_preprocessed(
    backend.assets_base,
    shader_path,
    defines,
    value_defines,
  )
  let shader = backend.device.create_shader_module_wgsl(source)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, entry_point,
  ) catch {
    err => {
      shader.release()
      fatal("wgpu: failed to create \{label} pipeline: \{err.message()}")
    }
  }
  pipeline.set_label(label)
  shader.release()
  pipeline
}

///|
fn ssao_depth_format_uses_r16float(depth_format : @wgpu.TextureFormat) -> Bool {
  depth_format == tf(@wgpu.TEXTURE_FORMAT_R16_FLOAT)
}

///|
fn ensure_mesh3d_ssao_pipelines(
  backend : GpuBackend,
  depth_format : @wgpu.TextureFormat,
) -> Unit raise GpuBackendError {
  if backend.mesh3d_ssao_pipelines is Some(pipelines) &&
    pipelines.depth_format == depth_format {
    ssao_pipelines_keepalive(pipelines)
    return
  }
  let common_bgl = ssao_create_common_bind_group_layout(backend)
  let preprocess_depth_bgl = ssao_create_preprocess_depth_bind_group_layout(
    backend, depth_format,
  )
  let ssao_bgl = ssao_create_ssao_bind_group_layout(backend, depth_format)
  let spatial_denoise_bgl = ssao_create_spatial_denoise_bind_group_layout(
    backend, depth_format,
  )
  let preprocess_depth_layout = backend.device.create_pipeline_layout_2(
    preprocess_depth_bgl, common_bgl,
  )
  preprocess_depth_layout.set_label(
    "mgstudio_ssao_preprocess_depth_pipeline_layout",
  )
  let ssao_layout = backend.device.create_pipeline_layout_2(
    ssao_bgl, common_bgl,
  )
  ssao_layout.set_label("mgstudio_ssao_pipeline_layout")
  let spatial_denoise_layout = backend.device.create_pipeline_layout_2(
    spatial_denoise_bgl, common_bgl,
  )
  spatial_denoise_layout.set_label(
    "mgstudio_ssao_spatial_denoise_pipeline_layout",
  )
  let use_r16float = ssao_depth_format_uses_r16float(depth_format)
  let preprocess_pipeline = ssao_create_compute_pipeline(
    backend,
    preprocess_depth_layout,
    "pbr/ssao/preprocess_depth.wgsl",
    "preprocess_depth",
    "mgstudio_ssao_preprocess_depth_pipeline",
    ssao_bool_defines(use_r16float),
    default_wgsl_value_defines(),
  )
  let spatial_denoise_pipeline = ssao_create_compute_pipeline(
    backend,
    spatial_denoise_layout,
    "pbr/ssao/spatial_denoise.wgsl",
    "spatial_denoise",
    "mgstudio_ssao_spatial_denoise_pipeline",
    ssao_bool_defines(use_r16float),
    default_wgsl_value_defines(),
  )
  let (hilbert_texture, hilbert_view) = ssao_create_hilbert_index_lut(backend)
  backend.mesh3d_ssao_pipelines = Some(GpuSsaoPipelines::{
    common_bind_group_layout: common_bgl,
    preprocess_depth_bind_group_layout: preprocess_depth_bgl,
    ssao_bind_group_layout: ssao_bgl,
    spatial_denoise_bind_group_layout: spatial_denoise_bgl,
    preprocess_depth_pipeline_layout: preprocess_depth_layout,
    ssao_pipeline_layout: ssao_layout,
    spatial_denoise_pipeline_layout: spatial_denoise_layout,
    preprocess_depth_pipeline: preprocess_pipeline,
    spatial_denoise_pipeline,
    hilbert_index_lut_texture: hilbert_texture,
    hilbert_index_lut_view: hilbert_view,
    point_clamp_sampler: backend.device.create_sampler_nearest_clamp(),
    linear_clamp_sampler: backend.device.create_sampler_linear_clamp(),
    depth_format,
  })
  backend.mesh3d_ssao_pipeline_cache.clear()
}

///|
fn ssao_sample_counts(
  quality_level : Int,
  custom_slice_count : Int,
  custom_samples_per_slice_side : Int,
) -> (Int, Int) {
  match quality_level {
    0 => (1, 2)
    1 => (2, 2)
    2 => (3, 3)
    3 => (9, 3)
    4 => (custom_slice_count, custom_samples_per_slice_side)
    _ => (3, 3)
  }
}

///|
fn mesh3d_ssao_pipeline_cache_find(
  backend : GpuBackend,
  quality_level : Int,
  slice_count : Int,
  samples_per_slice_side : Int,
  temporal_jitter : Bool,
) -> @wgpu.ComputePipeline? {
  for entry in backend.mesh3d_ssao_pipeline_cache {
    if entry.quality_level == quality_level &&
      entry.slice_count == slice_count &&
      entry.samples_per_slice_side == samples_per_slice_side &&
      entry.temporal_jitter == temporal_jitter {
      return Some(entry.pipeline)
    }
  }
  None
}

///|
fn ensure_mesh3d_ssao_pipeline_for_key(
  backend : GpuBackend,
  quality_level : Int,
  custom_slice_count : Int,
  custom_samples_per_slice_side : Int,
  temporal_jitter : Bool,
) -> @wgpu.ComputePipeline? raise GpuBackendError {
  guard backend.mesh3d_ssao_pipelines is Some(pipelines) else { return None }
  let (slice_count, samples_per_slice_side) = ssao_sample_counts(
    quality_level, custom_slice_count, custom_samples_per_slice_side,
  )
  if mesh3d_ssao_pipeline_cache_find(
      backend, quality_level, slice_count, samples_per_slice_side, temporal_jitter,
    )
    is Some(pipeline) {
    return Some(pipeline)
  }
  let defines = ssao_bool_defines(
    ssao_depth_format_uses_r16float(pipelines.depth_format),
  )
  if temporal_jitter {
    defines.set("TEMPORAL_JITTER", true)
  }
  let pipeline = ssao_create_compute_pipeline(
    backend,
    pipelines.ssao_pipeline_layout,
    "pbr/ssao/ssao.wgsl",
    "ssao",
    "mgstudio_ssao_pipeline",
    defines,
    ssao_value_defines(slice_count, samples_per_slice_side),
  )
  backend.mesh3d_ssao_pipeline_cache.push(GpuSsaoPipelineCacheEntry::{
    quality_level,
    slice_count,
    samples_per_slice_side,
    temporal_jitter,
    pipeline,
  })
  Some(pipeline)
}

///|
pub fn GpuBackend::prepare_mesh3d_ssao_resources(
  self : GpuBackend,
  width : Int,
  height : Int,
  constant_object_thickness : Float,
) -> Unit raise GpuBackendError {
  let depth_format = tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT)
  ensure_mesh3d_ssao_pipelines(self, depth_format)
  if self.mesh3d_ssao_resources is Some(resources) &&
    ssao_resource_shape_matches(
      resources, width, height, depth_format, constant_object_thickness,
    ) {
    return
  }
  let next_revision = self.mesh3d_ssao_resource_revision + 1
  let (preprocessed_depth_texture, preprocessed_depth_view) = ssao_create_texture_2d(
    self, width, height, 5U, depth_format, "mgstudio_ssao_preprocessed_depth_texture",
  )
  let preprocessed_depth_mip_views = ssao_create_texture_mip_views(
    preprocessed_depth_texture, depth_format, 5, "mgstudio_ssao_preprocessed_depth_texture",
  )
  let (ssao_noisy_texture, ssao_noisy_view) = ssao_create_texture_2d(
    self, width, height, 1U, depth_format, "mgstudio_ssao_noisy_texture",
  )
  let (
    screen_space_ambient_occlusion_texture,
    screen_space_ambient_occlusion_view,
  ) = ssao_create_texture_2d(
    self, width, height, 1U, depth_format, "mgstudio_ssao_texture",
  )
  let (depth_differences_texture, depth_differences_view) = ssao_create_texture_2d(
    self,
    width,
    height,
    1U,
    tf(@wgpu.TEXTURE_FORMAT_R32_UINT),
    "mgstudio_ssao_depth_differences_texture",
  )
  let thickness_buffer = ssao_create_thickness_buffer(
    self, constant_object_thickness,
  )
  self.mesh3d_ssao_resources = Some(GpuSsaoResources::{
    width,
    height,
    depth_format,
    preprocessed_depth_texture,
    preprocessed_depth_view,
    preprocessed_depth_mip_views,
    ssao_noisy_texture,
    ssao_noisy_view,
    screen_space_ambient_occlusion_texture,
    screen_space_ambient_occlusion_view,
    depth_differences_texture,
    depth_differences_view,
    thickness_buffer,
    constant_object_thickness,
    revision: next_revision,
  })
  self.mesh3d_ssao_resource_revision = next_revision
  mesh3d_material_cache_clear(self)
}

///|
pub fn GpuBackend::prepare_mesh3d_ssao_pipeline(
  self : GpuBackend,
  quality_level : Int,
  custom_slice_count : Int,
  custom_samples_per_slice_side : Int,
  temporal_jitter : Bool,
) -> Unit raise GpuBackendError {
  let depth_format = tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT)
  ensure_mesh3d_ssao_pipelines(self, depth_format)
  ignore(
    ensure_mesh3d_ssao_pipeline_for_key(
      self, quality_level, custom_slice_count, custom_samples_per_slice_side, temporal_jitter,
    ),
  )
}
