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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/mip_generation/mod.rs`.

///|
const MIP_GENERATION_UNIFORM_SIZE : UInt64 = 16UL

///|
const MIP_GENERATION_STORAGE_MIPS_PER_PASS : Int = 6

///|
fn mip_generation_u32le_write_into(
  bytes : Array[Byte],
  byte_offset : Int,
  word : UInt,
) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn mip_generation_u32le_pack(xs : Array[UInt]) -> Bytes {
  let bytes = Array::make(xs.length() * 4, (0).to_byte())
  for i in 0..<xs.length() {
    mip_generation_u32le_write_into(bytes, i * 4, xs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn mip_generation_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
fn mip_generation_downsampling_constants_bytes(
  mips : Int,
  width : Int,
  height : Int,
) -> Bytes {
  let safe_mips = if mips <= 0 { 1 } else { mips }
  let safe_width = if width <= 0 {
    1.0F
  } else {
    Float::from_double(width.to_double())
  }
  let safe_height = if height <= 0 {
    1.0F
  } else {
    Float::from_double(height.to_double())
  }
  // WGSL uniform layout places `inverse_input_size: vec2f` at offset 8.
  mip_generation_u32le_pack([
    safe_mips.reinterpret_as_uint(),
    0U,
    mip_generation_f32_bits(1.0F / safe_width),
    mip_generation_f32_bits(1.0F / safe_height),
  ])
}

///|
fn mip_generation_div_ceil(value : Int, divisor : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    ((value + divisor - 1) / divisor).reinterpret_as_uint()
  }
}

///|
fn mip_generation_texture_view_aspect_for_format(
  format : @wgpu.TextureFormat,
) -> UInt {
  if format.to_u32() == @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT {
    @wgpu.TEXTURE_ASPECT_DEPTH_ONLY
  } else {
    @wgpu.TEXTURE_ASPECT_ALL
  }
}

///|
fn mip_generation_texture_format_identifier(
  format : @wgpu.TextureFormat,
) -> String? {
  match format.to_u32() {
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM => Some("rgba8unorm")
    @wgpu.TEXTURE_FORMAT_RGBA8_SNORM => Some("rgba8snorm")
    @wgpu.TEXTURE_FORMAT_RGBA8_UINT => Some("rgba8uint")
    @wgpu.TEXTURE_FORMAT_RGBA8_SINT => Some("rgba8sint")
    @wgpu.TEXTURE_FORMAT_RGBA16_UNORM => Some("rgba16unorm")
    @wgpu.TEXTURE_FORMAT_RGBA16_SNORM => Some("rgba16snorm")
    @wgpu.TEXTURE_FORMAT_RGBA16_UINT => Some("rgba16uint")
    @wgpu.TEXTURE_FORMAT_RGBA16_SINT => Some("rgba16sint")
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT => Some("rgba16float")
    @wgpu.TEXTURE_FORMAT_RG8_UNORM => Some("rg8unorm")
    @wgpu.TEXTURE_FORMAT_RG8_SNORM => Some("rg8snorm")
    @wgpu.TEXTURE_FORMAT_RG8_UINT => Some("rg8uint")
    @wgpu.TEXTURE_FORMAT_RG8_SINT => Some("rg8sint")
    @wgpu.TEXTURE_FORMAT_RG16_UNORM => Some("rg16unorm")
    @wgpu.TEXTURE_FORMAT_RG16_SNORM => Some("rg16snorm")
    @wgpu.TEXTURE_FORMAT_RG16_UINT => Some("rg16uint")
    @wgpu.TEXTURE_FORMAT_RG16_SINT => Some("rg16sint")
    @wgpu.TEXTURE_FORMAT_RG16_FLOAT => Some("rg16float")
    @wgpu.TEXTURE_FORMAT_R32_UINT => Some("r32uint")
    @wgpu.TEXTURE_FORMAT_R32_SINT => Some("r32sint")
    @wgpu.TEXTURE_FORMAT_R32_FLOAT => Some("r32float")
    @wgpu.TEXTURE_FORMAT_RG32_UINT => Some("rg32uint")
    @wgpu.TEXTURE_FORMAT_RG32_SINT => Some("rg32sint")
    @wgpu.TEXTURE_FORMAT_RG32_FLOAT => Some("rg32float")
    @wgpu.TEXTURE_FORMAT_RGBA32_UINT => Some("rgba32uint")
    @wgpu.TEXTURE_FORMAT_RGBA32_SINT => Some("rgba32sint")
    @wgpu.TEXTURE_FORMAT_RGBA32_FLOAT => Some("rgba32float")
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM => Some("bgra8unorm")
    @wgpu.TEXTURE_FORMAT_R8_UNORM => Some("r8unorm")
    @wgpu.TEXTURE_FORMAT_R8_SNORM => Some("r8snorm")
    @wgpu.TEXTURE_FORMAT_R8_UINT => Some("r8uint")
    @wgpu.TEXTURE_FORMAT_R8_SINT => Some("r8sint")
    @wgpu.TEXTURE_FORMAT_R16_UNORM => Some("r16unorm")
    @wgpu.TEXTURE_FORMAT_R16_SNORM => Some("r16snorm")
    @wgpu.TEXTURE_FORMAT_R16_UINT => Some("r16uint")
    @wgpu.TEXTURE_FORMAT_R16_SINT => Some("r16sint")
    @wgpu.TEXTURE_FORMAT_R16_FLOAT => Some("r16float")
    @wgpu.TEXTURE_FORMAT_RGB10_A2_UNORM => Some("rgb10a2unorm")
    @wgpu.TEXTURE_FORMAT_RGB10_A2_UINT => Some("rgb10a2uint")
    @wgpu.TEXTURE_FORMAT_RG11_B10_UFLOAT => Some("rg11b10ufloat")
    _ => None
  }
}

///|
fn mip_generation_compile_pipeline_source(
  identifier : String,
  shader_def : String,
) -> String? {
  let source = downsample_specialized_wgsl_source(identifier)
  let defines = @hashmap.HashMap([])
  let value_defines = @shader_compile.default_shader_value_defines()
  value_defines.set(shader_def, @wgsl_common.ShaderDefValue::Int(1))
  let compiled = @shader_compile.preprocess_shader_source(
    "", source, defines, value_defines,
  ) catch {
    _ => return None
  }
  Some(compiled)
}

///|
fn mip_generation_create_bind_group_layout(
  render_device : @renderer.RenderDevice,
  format : @wgpu.TextureFormat,
  label : String,
) -> @wgpu.BindGroupLayout? {
  let compute = @wgpu.ShaderStage::from_u64(@wgpu.SHADER_STAGE_COMPUTE)
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
      min_binding_size=MIP_GENERATION_UNIFORM_SIZE,
    ) &&
    builder.add_texture(
      2U,
      compute,
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    )
  for binding_i in 3..<9 {
    ok = ok &&
      builder.add_storage_texture(
        binding_i.reinterpret_as_uint(),
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        format,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      )
  }
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(render_device.wgpu_device(), label~))
}

///|
fn mip_generation_create_pipeline(
  render_device : @renderer.RenderDevice,
  bind_group_layout : @wgpu.BindGroupLayout,
  identifier : String,
  shader_def : String,
  entry_point : String,
  label : String,
) -> (@wgpu.PipelineLayout, @wgpu.ComputePipeline)? {
  let source = match
    mip_generation_compile_pipeline_source(identifier, shader_def) {
    Some(value) => value
    None => return None
  }
  let pipeline_layout = render_device
    .wgpu_device()
    .create_pipeline_layout_1(bind_group_layout)
  pipeline_layout.set_label(label + " layout")
  let shader = render_device.create_shader_module_wgsl(source)
  let pipeline = render_device
    .wgpu_device()
    .create_compute_pipeline_with_layout_entry(
      pipeline_layout, shader, entry_point,
    ) catch {
      _ => {
        shader.release()
        pipeline_layout.release()
        return None
      }
    }
  pipeline.set_label(label)
  shader.release()
  Some((pipeline_layout, pipeline))
}

///|
fn MipGenerationPipelines::get_or_create_texture_format_pipelines(
  self : MipGenerationPipelines,
  render_device : @renderer.RenderDevice,
  format : @wgpu.TextureFormat,
  identifier : String,
) -> MipGenerationTextureFormatPipelines? {
  let format_raw = format.to_u32()
  match self.pipelines.get(format_raw) {
    Some(existing) => Some(existing)
    None => {
      let layout_pass_1 = match
        mip_generation_create_bind_group_layout(
          render_device, format, "mip generation bind group layout, pass 1",
        ) {
        Some(value) => value
        None => return None
      }
      let layout_pass_2 = match
        mip_generation_create_bind_group_layout(
          render_device, format, "mip generation bind group layout, pass 2",
        ) {
        Some(value) => value
        None => {
          layout_pass_1.release()
          return None
        }
      }
      let pair_1 = match
        mip_generation_create_pipeline(
          render_device, layout_pass_1, identifier, "FIRST_PASS", "downsample_first",
          "mip generation pipeline, pass 1",
        ) {
        Some(value) => value
        None => {
          layout_pass_1.release()
          layout_pass_2.release()
          return None
        }
      }
      let pair_2 = match
        mip_generation_create_pipeline(
          render_device, layout_pass_2, identifier, "SECOND_PASS", "downsample_second",
          "mip generation pipeline, pass 2",
        ) {
        Some(value) => value
        None => {
          pair_1.0.release()
          pair_1.1.release()
          layout_pass_1.release()
          layout_pass_2.release()
          return None
        }
      }
      let pipelines = MipGenerationTextureFormatPipelines::{
        format_raw,
        bind_group_layout_pass_1: layout_pass_1,
        bind_group_layout_pass_2: layout_pass_2,
        pipeline_layout_pass_1: pair_1.0,
        pipeline_layout_pass_2: pair_2.0,
        pipeline_pass_1: pair_1.1,
        pipeline_pass_2: pair_2.1,
      }
      self.pipelines.set(format_raw, pipelines)
      Some(pipelines)
    }
  }
}

///|
fn MipGenerationStorageView::release(self : MipGenerationStorageView) -> Unit {
  self.view.release()
  match self.dummy_texture {
    Some(texture) => texture.release()
    None => ()
  }
}

///|
fn MipGenerationJobBindGroups::release(
  self : MipGenerationJobBindGroups,
) -> Unit {
  self.bind_group_pass_1.release()
  self.bind_group_pass_2.release()
  self.constants_buffer.release()
  self.input_view_pass_1.release()
  self.input_view_pass_2.release()
  for view in self.storage_views_pass_1 {
    view.release()
  }
  for view in self.storage_views_pass_2 {
    view.release()
  }
}

///|
fn mip_generation_input_view(
  gpu_image : @render_texture.GpuImage,
  mip_level : Int,
  label : String,
) -> @wgpu.TextureView? {
  guard gpu_image.texture() is Some(texture) else { return None }
  guard gpu_image.format() is Some(format) else { return None }
  let safe_mip = if mip_level < 0 {
    0
  } else if mip_level < gpu_image.mip_level_count() {
    mip_level
  } else {
    gpu_image.mip_level_count() - 1
  }
  let view = texture.create_view_u32(
    format,
    @wgpu.TEXTURE_VIEW_DIMENSION_2D,
    mip_generation_texture_view_aspect_for_format(format),
    0U,
    1U,
    (gpu_image.base_mip_level() + safe_mip).reinterpret_as_uint(),
    1U,
  )
  view.set_label(label)
  Some(view)
}

///|
fn mip_generation_storage_view(
  render_device : @renderer.RenderDevice,
  gpu_image : @render_texture.GpuImage,
  mip_level : Int,
) -> MipGenerationStorageView? {
  guard gpu_image.format() is Some(format) else { return None }
  if mip_level < gpu_image.mip_level_count() {
    guard gpu_image.texture() is Some(texture) else { return None }
    let view = texture.create_view_u32(
      format,
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      mip_generation_texture_view_aspect_for_format(format),
      0U,
      1U,
      (gpu_image.base_mip_level() + mip_level).reinterpret_as_uint(),
      1U,
    )
    view.set_label(
      "mip downsampling storage view \{mip_level}/\{gpu_image.mip_level_count()}",
    )
    Some(MipGenerationStorageView::{ view, dummy_texture: None })
  } else {
    let texture = render_device
      .wgpu_device()
      .create_texture_u32(
        1U,
        1U,
        1U,
        @wgpu.TextureUsage::from_u64(
          @wgpu.TEXTURE_USAGE_STORAGE_BINDING |
          @wgpu.TEXTURE_USAGE_TEXTURE_BINDING,
        ),
        @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
        format,
      )
    texture.set_label(
      "mip downsampling dummy storage texture \{mip_level}/\{gpu_image.mip_level_count()}",
    )
    let view = texture.create_view()
    view.set_label(
      "mip downsampling dummy storage view \{mip_level}/\{gpu_image.mip_level_count()}",
    )
    Some(MipGenerationStorageView::{ view, dummy_texture: Some(texture) })
  }
}

///|
fn mip_generation_storage_views(
  render_device : @renderer.RenderDevice,
  gpu_image : @render_texture.GpuImage,
  first_mip_level : Int,
) -> Array[MipGenerationStorageView]? {
  let views : Array[MipGenerationStorageView] = []
  for offset in 0..<MIP_GENERATION_STORAGE_MIPS_PER_PASS {
    let view = match
      mip_generation_storage_view(
        render_device,
        gpu_image,
        first_mip_level + offset,
      ) {
      Some(value) => value
      None => {
        for item in views {
          item.release()
        }
        return None
      }
    }
    views.push(view)
  }
  Some(views)
}

///|
fn mip_generation_create_bind_group(
  render_device : @renderer.RenderDevice,
  layout : @wgpu.BindGroupLayout,
  sampler : @wgpu.Sampler,
  constants_buffer : @wgpu.Buffer,
  input_view : @wgpu.TextureView,
  storage_views : Array[MipGenerationStorageView],
  label : String,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=9UL)
  let mut ok = builder.add_sampler(0U, sampler) &&
    builder.add_buffer(1U, constants_buffer) &&
    builder.add_texture_view(2U, input_view)
  for i in 0..<storage_views.length() {
    ok = ok &&
      builder.add_texture_view(
        (3 + i).reinterpret_as_uint(),
        storage_views[i].view,
      )
  }
  if !ok {
    builder.free()
    return None
  }
  Some(builder.finish(render_device.wgpu_device(), layout, label~))
}

///|
fn mip_generation_create_job_bind_groups(
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
  resources : MipGenerationResources,
  pipelines : MipGenerationTextureFormatPipelines,
  gpu_image : @render_texture.GpuImage,
) -> MipGenerationJobBindGroups? {
  let sampler = resources.ensure_sampler(render_device)
  let constants_buffer = render_device
    .wgpu_device()
    .create_buffer(
      size=MIP_GENERATION_UNIFORM_SIZE,
      usage=@wgpu.BufferUsage::from_u64(
        @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
      ),
    )
  render_queue
  .wgpu_queue()
  .write_buffer(
    constants_buffer,
    0UL,
    mip_generation_downsampling_constants_bytes(
      gpu_image.mip_level_count(),
      gpu_image.width(),
      gpu_image.height(),
    ),
  )
  let input_view_pass_1 = match
    mip_generation_input_view(
      gpu_image, 0, "mip generation input texture view, pass 1",
    ) {
    Some(value) => value
    None => {
      constants_buffer.release()
      return None
    }
  }
  let pass_2_mip = if gpu_image.mip_level_count() < 6 {
    gpu_image.mip_level_count() - 1
  } else {
    6
  }
  let input_view_pass_2 = match
    mip_generation_input_view(
      gpu_image, pass_2_mip, "mip generation input texture view, pass 2",
    ) {
    Some(value) => value
    None => {
      input_view_pass_1.release()
      constants_buffer.release()
      return None
    }
  }
  let storage_views_pass_1 = match
    mip_generation_storage_views(render_device, gpu_image, 1) {
    Some(value) => value
    None => {
      input_view_pass_1.release()
      input_view_pass_2.release()
      constants_buffer.release()
      return None
    }
  }
  let storage_views_pass_2 = match
    mip_generation_storage_views(render_device, gpu_image, 7) {
    Some(value) => value
    None => {
      input_view_pass_1.release()
      input_view_pass_2.release()
      constants_buffer.release()
      for view in storage_views_pass_1 {
        view.release()
      }
      return None
    }
  }
  let bind_group_pass_1 = match
    mip_generation_create_bind_group(
      render_device,
      pipelines.bind_group_layout_pass_1,
      sampler,
      constants_buffer,
      input_view_pass_1,
      storage_views_pass_1,
      "mip generation bind group, pass 1",
    ) {
    Some(value) => value
    None => {
      input_view_pass_1.release()
      input_view_pass_2.release()
      constants_buffer.release()
      for view in storage_views_pass_1 {
        view.release()
      }
      for view in storage_views_pass_2 {
        view.release()
      }
      return None
    }
  }
  let bind_group_pass_2 = match
    mip_generation_create_bind_group(
      render_device,
      pipelines.bind_group_layout_pass_2,
      sampler,
      constants_buffer,
      input_view_pass_2,
      storage_views_pass_2,
      "mip generation bind group, pass 2",
    ) {
    Some(value) => value
    None => {
      bind_group_pass_1.release()
      input_view_pass_1.release()
      input_view_pass_2.release()
      constants_buffer.release()
      for view in storage_views_pass_1 {
        view.release()
      }
      for view in storage_views_pass_2 {
        view.release()
      }
      return None
    }
  }
  Some(MipGenerationJobBindGroups::{
    bind_group_pass_1,
    bind_group_pass_2,
    constants_buffer,
    input_view_pass_1,
    input_view_pass_2,
    storage_views_pass_1,
    storage_views_pass_2,
  })
}

///|
fn mip_generation_int_array_contains(values : Array[Int], needle : Int) -> Bool {
  for value in values {
    if value == needle {
      return true
    }
  }
  false
}

///|
fn MipGenerationPipelines::expire_bind_groups_except(
  self : MipGenerationPipelines,
  active_ids : Array[Int],
) -> Unit {
  for entry in self.bind_groups.to_array() {
    let asset_id = entry.0
    let bind_groups = entry.1
    if !mip_generation_int_array_contains(active_ids, asset_id) {
      bind_groups.release()
      self.bind_groups.remove(asset_id) |> ignore
    }
  }
}

///|
fn prepare_mip_generator_pipelines(world : @ecs.World) -> Unit {
  let jobs = match world.get_resource(ecs_key_mip_generation_jobs) {
    Some(value) => value
    None => return
  }
  let render_device = match
    world.get_resource(@render.render_device_resource_key) {
    Some(value) => value
    None => return
  }
  let render_queue = match
    world.get_resource(@render.render_queue_resource_key) {
    Some(value) => value
    None => return
  }
  for _, phase in jobs.phases {
    for image_asset_id in phase.image_asset_ids {
      @render.prepare_gpu_image_render_asset(world, image_asset_id)
    }
  }
  let gpu_images_key : @ecs.ResourceKey[
    @render.RenderAssets[@render_texture.GpuImage],
  ] = @render.RenderAssets::resource()
  let gpu_images = match world.get_resource(gpu_images_key) {
    Some(value) => value
    None => return
  }
  let resources = match world.get_resource(ecs_key_mip_generation_resources) {
    Some(value) => value
    None => return
  }
  guard world.get_resource_mut(ecs_key_mip_generation_pipelines)
    is Some(pipelines_mut) else {
    return
  }
  pipelines_mut.modify(fn(pipelines) {
    let active_ids : Array[Int] = []
    for _, phase in jobs.phases {
      for image_asset_id in phase.image_asset_ids {
        let image_id = image_asset_id.index()
        active_ids.push(image_id)
        if pipelines.bind_groups.get(image_id) is Some(_) {
          continue
        }
        guard gpu_images.get(image_id) is Some(gpu_image) else { continue }
        if gpu_image.mip_level_count() <= 1 {
          continue
        }
        guard gpu_image.format() is Some(format) else { continue }
        guard mip_generation_texture_format_identifier(format)
          is Some(identifier) else {
          continue
        }
        guard pipelines.get_or_create_texture_format_pipelines(
            render_device, format, identifier,
          )
          is Some(format_pipelines) else {
          continue
        }
        guard mip_generation_create_job_bind_groups(
            render_device, render_queue, resources, format_pipelines, gpu_image,
          )
          is Some(bind_groups) else {
          continue
        }
        pipelines.bind_groups.set(image_id, bind_groups)
      }
    }
    pipelines.expire_bind_groups_except(active_ids)
  })
}

///|
pub fn generate_mips_for_phase(
  phase_id : MipGenerationPhaseId,
  world : @ecs.World,
) -> Unit {
  let jobs = match world.get_resource(ecs_key_mip_generation_jobs) {
    Some(value) => value
    None => return
  }
  let phase = match jobs.phase(phase_id) {
    Some(value) => value
    None => return
  }
  if phase.is_empty() {
    return
  }
  let render_device = match
    world.get_resource(@render.render_device_resource_key) {
    Some(value) => value
    None => return
  }
  let gpu_images_key : @ecs.ResourceKey[
    @render.RenderAssets[@render_texture.GpuImage],
  ] = @render.RenderAssets::resource()
  let gpu_images = match world.get_resource(gpu_images_key) {
    Some(value) => value
    None => return
  }
  let pipelines = match world.get_resource(ecs_key_mip_generation_pipelines) {
    Some(value) => value
    None => return
  }
  let mut encoder : @wgpu.CommandEncoder? = None
  for image_asset_id in phase.to_array() {
    let image_id = image_asset_id.index()
    guard gpu_images.get(image_id) is Some(gpu_image) else { continue }
    guard gpu_image.format() is Some(format) else { continue }
    guard pipelines.pipelines.get(format.to_u32()) is Some(format_pipelines) else {
      continue
    }
    guard pipelines.bind_groups.get(image_id) is Some(bind_groups) else {
      continue
    }
    let command_encoder = match encoder {
      Some(value) => value
      None => {
        let value = render_device.create_command_encoder()
        encoder = Some(value)
        value
      }
    }
    let compute_pass_1 = command_encoder.begin_compute_pass()
    compute_pass_1.set_pipeline(format_pipelines.pipeline_pass_1)
    compute_pass_1.set_bind_group0(bind_groups.bind_group_pass_1)
    compute_pass_1.dispatch_workgroups(
      mip_generation_div_ceil(gpu_image.width(), 64),
      mip_generation_div_ceil(gpu_image.height(), 64),
      1U,
    )
    compute_pass_1.end()
    compute_pass_1.release()

    let compute_pass_2 = command_encoder.begin_compute_pass()
    compute_pass_2.set_pipeline(format_pipelines.pipeline_pass_2)
    compute_pass_2.set_bind_group0(bind_groups.bind_group_pass_2)
    compute_pass_2.dispatch_workgroups(
      mip_generation_div_ceil(gpu_image.width(), 256),
      mip_generation_div_ceil(gpu_image.height(), 256),
      1U,
    )
    compute_pass_2.end()
    compute_pass_2.release()
  }
  guard encoder is Some(command_encoder) else { return }
  guard world.get_resource_mut(@render.pending_command_buffers_resource_key)
    is Some(pending_mut) else {
    command_encoder.release()
    return
  }
  pending_mut.modify(fn(pending) { pending.push_encoder(command_encoder) })
}
