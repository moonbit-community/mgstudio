// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_post_process/src/motion_blur/pipeline.rs`.

///|
pub const MOTION_BLUR_SHADER_PATH : String = "post_process/motion_blur/motion_blur.wgsl"

///|
pub const MOTION_BLUR_PIPELINE_LABEL : String = "motion_blur_pipeline"

///|
const MOTION_BLUR_SETTINGS_UNIFORM_SIZE_BYTES : UInt64 = 16UL

///|
const MOTION_BLUR_GLOBALS_UNIFORM_SIZE_BYTES : UInt64 = 16UL

///|
pub struct MotionBlurPipelineKey {
  target_format_raw : UInt
  samples : Int
} derive(Eq, Debug)

///|
pub fn MotionBlurPipelineKey::new(
  target_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  samples? : Int = 1,
) -> MotionBlurPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  MotionBlurPipelineKey::{ target_format_raw, samples }
}

///|
pub fn MotionBlurPipelineKey::target_format_raw(
  self : MotionBlurPipelineKey,
) -> UInt {
  self.target_format_raw
}

///|
pub fn MotionBlurPipelineKey::samples(self : MotionBlurPipelineKey) -> Int {
  self.samples
}

///|
pub fn MotionBlurPipelineKey::is_multisampled(
  self : MotionBlurPipelineKey,
) -> Bool {
  self.samples > 1
}

///|
pub struct MotionBlurPipelineId {
  pipeline_id : @render_resource.CachedRenderPipelineId
}

///|
pub fn MotionBlurPipelineId::new(
  pipeline_id~ : @render_resource.CachedRenderPipelineId,
) -> MotionBlurPipelineId {
  MotionBlurPipelineId::{ pipeline_id, }
}

///|
pub fn MotionBlurPipelineId::pipeline_id(
  self : MotionBlurPipelineId,
) -> @render_resource.CachedRenderPipelineId {
  self.pipeline_id
}

///|
pub let ecs_key_motion_blur_pipeline_id : @ecs.ComponentKey[
  MotionBlurPipelineId,
] = @ecs.register_component(debug_name="post_process.motion_blur.pipeline_id")

///|
pub impl @ecs.Component for MotionBlurPipelineId with fn component() {
  ecs_key_motion_blur_pipeline_id
}

///|
pub struct MotionBlurPipeline {
  sampler : @render_resource.Sampler
  layout : @render_resource.BindGroupLayoutDescriptor
  layout_msaa : @render_resource.BindGroupLayoutDescriptor
  fullscreen_shader_path : String
  fullscreen_shader_entry_point : String
  fragment_shader_path : String
}

///|
pub fn MotionBlurPipeline::new(
  render_device : @render.RenderDevice,
  fullscreen_shader : @fullscreen_vertex_shader.FullscreenShader,
) -> MotionBlurPipeline {
  MotionBlurPipeline::{
    sampler: render_device.create_sampler_linear_clamp(),
    layout: motion_blur_bind_group_layout_descriptor(multisampled=false),
    layout_msaa: motion_blur_bind_group_layout_descriptor(multisampled=true),
    fullscreen_shader_path: fullscreen_shader.path(),
    fullscreen_shader_entry_point: fullscreen_shader.entry_point(),
    fragment_shader_path: MOTION_BLUR_SHADER_PATH,
  }
}

///|
pub fn MotionBlurPipeline::sampler(
  self : MotionBlurPipeline,
) -> @render_resource.Sampler {
  self.sampler
}

///|
pub fn MotionBlurPipeline::layout(
  self : MotionBlurPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.layout
}

///|
pub fn MotionBlurPipeline::layout_msaa(
  self : MotionBlurPipeline,
) -> @render_resource.BindGroupLayoutDescriptor {
  self.layout_msaa
}

///|
pub fn MotionBlurPipeline::specialize(
  self : MotionBlurPipeline,
  key : MotionBlurPipelineKey,
) -> @render_resource.RenderPipelineDescriptor {
  motion_blur_pipeline_specialize_descriptor(
    self.layout,
    self.layout_msaa,
    self.fullscreen_shader_path,
    self.fullscreen_shader_entry_point,
    self.fragment_shader_path,
    key,
  )
}

///|
fn motion_blur_pipeline_specialize_descriptor(
  layout : @render_resource.BindGroupLayoutDescriptor,
  layout_msaa : @render_resource.BindGroupLayoutDescriptor,
  fullscreen_shader_path : String,
  fullscreen_shader_entry_point : String,
  fragment_shader_path : String,
  key : MotionBlurPipelineKey,
) -> @render_resource.RenderPipelineDescriptor {
  let layout = if key.is_multisampled() { [layout_msaa] } else { [layout] }
  let shader_defs = if key.is_multisampled() {
    [@render_resource.ShaderDefVal::Flag("MULTISAMPLED")]
  } else {
    []
  }
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(Some(MOTION_BLUR_PIPELINE_LABEL))
  .with_layout(layout)
  .with_vertex(
    @render_resource.VertexState::new(
      Some(fullscreen_shader_path),
      [],
      Some(fullscreen_shader_entry_point),
      [],
    ),
  )
  .with_fragment(
    Some(
      @render_resource.FragmentState::new(
        Some(fragment_shader_path),
        shader_defs,
        Some("fragment"),
        [
          Some(
            @render_resource.ColorTargetState::new(
              key.target_format_raw,
              @wgpu.COLOR_WRITE_MASK_ALL,
            ),
          ),
        ],
      ),
    ),
  )
}

///|
pub let ecs_key_motion_blur_pipeline : @ecs.ResourceKey[MotionBlurPipeline] = @ecs.register_resource(
  debug_name="post_process.motion_blur.pipeline",
)

///|
pub impl @app.Resource for MotionBlurPipeline with fn resource() {
  ecs_key_motion_blur_pipeline
}

///|
pub struct SpecializedMotionBlurPipelines {
  entries : Array[
    (MotionBlurPipelineKey, @render_resource.CachedRenderPipelineId),
  ]
}

///|
pub fn SpecializedMotionBlurPipelines::SpecializedMotionBlurPipelines() -> SpecializedMotionBlurPipelines {
  SpecializedMotionBlurPipelines::{ entries: [] }
}

///|
pub fn SpecializedMotionBlurPipelines::len(
  self : SpecializedMotionBlurPipelines,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedMotionBlurPipelines::queue(
  self : SpecializedMotionBlurPipelines,
  pipeline_cache : @render_resource.PipelineCache,
  pipeline : MotionBlurPipeline,
  key : MotionBlurPipelineKey,
) -> @render_resource.CachedRenderPipelineId {
  for entry in self.entries {
    let (entry_key, pipeline_id) = entry
    if entry_key == key {
      return pipeline_id
    }
  }
  let pipeline_id = pipeline_cache.queue_render_pipeline(
    pipeline.specialize(key),
  )
  self.entries.push((key, pipeline_id))
  pipeline_id
}

///|
pub let ecs_key_specialized_motion_blur_pipelines : @ecs.ResourceKey[
  SpecializedMotionBlurPipelines,
] = @ecs.register_resource(
  debug_name="post_process.motion_blur.specialized_pipelines",
)

///|
pub impl @app.Resource for SpecializedMotionBlurPipelines with fn resource() {
  ecs_key_specialized_motion_blur_pipelines
}

///|
pub fn init_motion_blur_pipeline(render_world : @ecs.World) -> Unit {
  guard render_world.get_resource(@render.render_device_resource_key)
    is Some(render_device) else {
    return
  }
  let fullscreen_shader = match
    render_world.get_resource(
      @fullscreen_vertex_shader.FullscreenShader::resource(),
    ) {
    Some(value) => value
    None => @fullscreen_vertex_shader.FullscreenShader::FullscreenShader()
  }
  render_world.insert_resource(
    MotionBlurPipeline::resource(),
    MotionBlurPipeline::new(render_device, fullscreen_shader),
  )
  if !render_world
    .resource(SpecializedMotionBlurPipelines::resource())
    .is_present() {
    render_world.insert_resource(
      SpecializedMotionBlurPipelines::resource(),
      SpecializedMotionBlurPipelines::SpecializedMotionBlurPipelines(),
    )
  }
}

///|
fn motion_blur_pipeline_state_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[SpecializedMotionBlurPipelines] {
  if world.get_resource(SpecializedMotionBlurPipelines::resource()) is None {
    world.insert_resource(
      SpecializedMotionBlurPipelines::resource(),
      SpecializedMotionBlurPipelines::SpecializedMotionBlurPipelines(),
    )
  }
  match world.get_resource_mut(SpecializedMotionBlurPipelines::resource()) {
    Some(value) => value
    None => abort("Missing SpecializedMotionBlurPipelines resource")
  }
}

///|
fn motion_blur_pipeline_resource_or_init(
  world : @ecs.World,
) -> MotionBlurPipeline? {
  match world.get_resource(MotionBlurPipeline::resource()) {
    Some(value) => Some(value)
    None => {
      init_motion_blur_pipeline(world)
      world.get_resource(MotionBlurPipeline::resource())
    }
  }
}

///|
pub fn motion_blur_pipeline_key_for_render_entity(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> MotionBlurPipelineKey? {
  guard (try! world.get_by_key(
      render_entity,
      @render_view.ExtractedView::component(),
    ))
    is Some(view) else {
    return None
  }
  guard (try! world.get_by_key(render_entity, @render_view.Msaa::component()))
    is Some(msaa) else {
    return None
  }
  Some(
    MotionBlurPipelineKey::new(
      target_format_raw=view.target_format_raw(),
      samples=msaa.samples(),
    ),
  )
}

///|
fn remove_stale_motion_blur_pipeline_ids(world : @ecs.World) -> Unit {
  let stale : Array[@core.Entity] = []
  let query : @ecs.Query[
    (@core.Entity, @ecs.Read[MotionBlurPipelineId]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(_query_entity, data) {
    let (entity, _pipeline_id) = data
    if (try! world.get_by_key(entity, ecs_key_motion_blur_uniform)) is None {
      stale.push(entity)
    }
  })
  for entity in stale {
    ignore(try! world.remove_by_key(entity, ecs_key_motion_blur_pipeline_id))
  }
}

///|
pub fn prepare_motion_blur_pipelines(render_world : @ecs.World) -> Unit {
  remove_stale_motion_blur_pipeline_ids(render_world)
  guard render_world.get_resource(@render.pipeline_cache_resource_key)
    is Some(pipeline_cache) else {
    return
  }
  guard motion_blur_pipeline_resource_or_init(render_world) is Some(pipeline) else {
    return
  }
  let query : @ecs.Query[(@core.Entity, @ecs.Read[MotionBlurUniform]), @ecs.All] = @ecs.query(
    render_world,
  )
  let prepared : Array[(@core.Entity, MotionBlurPipelineKey)] = []
  try! query.view(fn(_query_entity, data) {
    let (entity, _uniform) = data
    guard motion_blur_pipeline_key_for_render_entity(render_world, entity)
      is Some(key) else {
      return
    }
    prepared.push((entity, key))
  })
  for item in prepared {
    let (entity, key) = item
    let pipeline_id = motion_blur_pipeline_state_mut_or_init(render_world).modify(fn(
        state,
      ) {
        state.queue(pipeline_cache, pipeline, key)
      },
    )
    try! render_world.set_by_key(
      entity,
      ecs_key_motion_blur_pipeline_id,
      MotionBlurPipelineId::new(pipeline_id~),
    )
  }
}

///|
pub fn motion_blur_bind_group_layout_descriptor(
  multisampled~ : Bool,
) -> @render_resource.BindGroupLayoutDescriptor {
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  let motion_vector_sample_type = if multisampled {
    @render_resource.TextureSampleType::Float(false)
  } else {
    @render_resource.TextureSampleType::Float(true)
  }
  let depth_sample_type = @render_resource.TextureSampleType::Float(false)
  @render_resource.BindGroupLayoutDescriptor::new(
    if multisampled {
      "motion_blur_layout_msaa"
    } else {
      "motion_blur_layout"
    },
    [
      @render_resource.BindGroupLayoutEntry::new(
        0,
        fragment,
        @render_resource.BindingType::TextureBinding(
          @render_resource.TextureSampleType::Float(true),
          @render_resource.TextureViewDimension::D2,
          false,
        ),
      ),
      @render_resource.BindGroupLayoutEntry::new(
        1,
        fragment,
        @render_resource.BindingType::TextureBinding(
          motion_vector_sample_type,
          @render_resource.TextureViewDimension::D2,
          multisampled,
        ),
      ),
      @render_resource.BindGroupLayoutEntry::new(
        2,
        fragment,
        @render_resource.BindingType::TextureBinding(
          depth_sample_type,
          @render_resource.TextureViewDimension::D2,
          multisampled,
        ),
      ),
      @render_resource.BindGroupLayoutEntry::new(
        3,
        fragment,
        @render_resource.BindingType::SamplerBinding(
          @render_resource.SamplerBindingType::Filtering,
        ),
      ),
      @render_resource.BindGroupLayoutEntry::new(
        4,
        fragment,
        @render_resource.BindingType::BufferBinding(
          @render_resource.BufferBindingType::Uniform,
          false,
          MOTION_BLUR_SETTINGS_UNIFORM_SIZE_BYTES,
        ),
      ),
      @render_resource.BindGroupLayoutEntry::new(
        5,
        fragment,
        @render_resource.BindingType::BufferBinding(
          @render_resource.BufferBindingType::Uniform,
          false,
          MOTION_BLUR_GLOBALS_UNIFORM_SIZE_BYTES,
        ),
      ),
    ],
  )
}

///|
pub struct MotionBlurSample {
  offset : Float
  weight : Float
} derive(ToJson, FromJson)

///|
pub fn motion_blur_samples(settings : MotionBlur) -> Array[MotionBlurSample] {
  if settings.samples == 0U || settings.shutter_angle <= 0.0F {
    return []
  }
  if settings.samples == 1U {
    return [MotionBlurSample::{ offset: 0.0F, weight: 1.0F }]
  }
  let samples : Array[MotionBlurSample] = []
  let half_angle = settings.shutter_angle * 0.5F
  let sample_count = settings.samples.reinterpret_as_int()
  let last_index = sample_count - 1
  let last_index_float = Float::from_double(last_index.to_double())
  for index in 0..<sample_count {
    let normalized = Float::from_double(index.to_double()) / last_index_float
    let offset = (normalized - 0.5F) * settings.shutter_angle
    let normalized_distance = if half_angle <= 0.0F {
      0.0F
    } else {
      offset.abs() / half_angle
    }
    samples.push(MotionBlurSample::{
      offset,
      weight: 1.0F - normalized_distance * 0.5F,
    })
  }
  samples
}

///|
test "motion blur: pipeline specialization mirrors Bevy MSAA shader def split" {
  let descriptor = motion_blur_pipeline_specialize_descriptor(
    motion_blur_bind_group_layout_descriptor(multisampled=false),
    motion_blur_bind_group_layout_descriptor(multisampled=true),
    @fullscreen_vertex_shader.FULLSCREEN_SHADER_PATH,
    @fullscreen_vertex_shader.FULLSCREEN_SHADER_ENTRY_POINT,
    MOTION_BLUR_SHADER_PATH,
    MotionBlurPipelineKey::new(
      target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
      samples=1,
    ),
  )
  debug_inspect(descriptor.label(), content="Some(\"motion_blur_pipeline\")")
  debug_inspect(descriptor.layout().length(), content="1")
  debug_inspect(
    descriptor.layout()[0].label(),
    content="\"motion_blur_layout\"",
  )
  debug_inspect(
    descriptor.vertex().shader(),
    content="Some(\"core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl\")",
  )
  debug_inspect(
    descriptor.vertex().entry_point(),
    content="Some(\"fullscreen_vertex_shader\")",
  )
  debug_inspect(descriptor.vertex().buffers().length(), content="0")
  let fragment = descriptor.fragment_or_error()
  debug_inspect(
    fragment.shader(),
    content="Some(\"post_process/motion_blur/motion_blur.wgsl\")",
  )
  debug_inspect(fragment.shader_defs().length(), content="0")
  debug_inspect(fragment.entry_point(), content="Some(\"fragment\")")
  debug_inspect(fragment.targets().length(), content="1")
  guard fragment.targets()[0] is Some(target) else {
    abort("expected color target")
  }
  debug_inspect(
    target.format(),
    content=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT.to_string(),
  )
  debug_inspect(
    target.write_mask(),
    content=@wgpu.COLOR_WRITE_MASK_ALL.to_string(),
  )
  let msaa_descriptor = motion_blur_pipeline_specialize_descriptor(
    motion_blur_bind_group_layout_descriptor(multisampled=false),
    motion_blur_bind_group_layout_descriptor(multisampled=true),
    @fullscreen_vertex_shader.FULLSCREEN_SHADER_PATH,
    @fullscreen_vertex_shader.FULLSCREEN_SHADER_ENTRY_POINT,
    MOTION_BLUR_SHADER_PATH,
    MotionBlurPipelineKey::new(
      target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
      samples=4,
    ),
  )
  debug_inspect(
    msaa_descriptor.layout()[0].label(),
    content="\"motion_blur_layout_msaa\"",
  )
  let msaa_fragment = msaa_descriptor.fragment_or_error()
  debug_inspect(msaa_fragment.shader_defs().length(), content="1")
  guard msaa_fragment.shader_defs()[0]
    is @render_resource.ShaderDefVal::Flag(name) else {
    abort("expected MULTISAMPLED shader def")
  }
  debug_inspect(name, content="\"MULTISAMPLED\"")
}

///|
test "motion blur: pipeline key tracks Bevy target format and MSAA samples" {
  let first = MotionBlurPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    samples=1,
  )
  let second = MotionBlurPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    samples=1,
  )
  let msaa = MotionBlurPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    samples=4,
  )
  inspect(first == second, content="true")
  inspect(first == msaa, content="false")
  inspect(first.is_multisampled(), content="false")
  inspect(msaa.is_multisampled(), content="true")
  inspect(
    first.target_format_raw(),
    content=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT.to_string(),
  )
  inspect(msaa.samples(), content="4")
}
