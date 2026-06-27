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
test "motion blur: mod owner exposes Bevy default component and uniform extract" {
  let settings = MotionBlur::MotionBlur()
  inspect(settings.shutter_angle == 0.5F, content="true")
  inspect(settings.samples, content="1")
  let uniform = settings.extract_uniform()
  inspect(uniform.shutter_angle == 0.5F, content="true")
  inspect(uniform.samples, content="1")
  inspect(motion_blur_uniform_is_active(uniform), content="true")
}

///|
test "motion blur: uniform extract clamps invalid local constructor inputs" {
  let settings = MotionBlur::new(-2.0F, -3)
  let uniform = motion_blur_extract_uniform(settings)
  inspect(uniform.shutter_angle == 0.0F, content="true")
  inspect(uniform.samples, content="0")
  inspect(motion_blur_uniform_is_active(uniform), content="false")
}

///|
test "motion blur: sample helper stays tied to component settings" {
  let disabled = motion_blur_generate_samples(MotionBlur::new(0.0F, 8))
  inspect(disabled.length(), content="0")
  let single = motion_blur_generate_samples(MotionBlur::MotionBlur())
  inspect(single.length(), content="1")
  inspect(single[0].offset == 0.0F, content="true")
  inspect(single[0].weight == 1.0F, content="true")
  let multi = motion_blur_generate_samples(MotionBlur::new(1.0F, 3))
  inspect(multi.length(), content="3")
  inspect(multi[0].offset == -0.5F, content="true")
  inspect(multi[1].offset == 0.0F, content="true")
  inspect(multi[2].offset == 0.5F, content="true")
}

///|
test "motion blur: extract only writes uniforms for camera views" {
  let world = @ecs.World::new()
  let camera_entity = world.spawn()
  let render_camera_entity = world.spawn()
  try! world.set_by_key(
    camera_entity,
    @render.RenderEntity::component(),
    @render.RenderEntity::new(render_camera_entity),
  )
  try! world.set_by_key(
    camera_entity,
    @camera_camera.Camera::component(),
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera_entity,
    ecs_key_motion_blur,
    MotionBlur::new(1.25F, 3),
  )
  let non_camera_entity = world.spawn()
  let render_non_camera_entity = world.spawn()
  try! world.set_by_key(
    non_camera_entity,
    @render.RenderEntity::component(),
    @render.RenderEntity::new(render_non_camera_entity),
  )
  try! world.set_by_key(
    non_camera_entity,
    ecs_key_motion_blur,
    MotionBlur::new(0.75F, 2),
  )

  extract_motion_blur_uniforms(world)

  let camera_uniform = try! world.get_by_key(
    render_camera_entity, ecs_key_motion_blur_uniform,
  )
  inspect(camera_uniform is Some(_), content="true")
  guard camera_uniform is Some(uniform) else {
    abort("expected extracted uniform")
  }
  inspect(uniform.shutter_angle == 1.25F, content="true")
  inspect(uniform.samples, content="3")
  let non_camera_uniform = try! world.get_by_key(
    render_non_camera_entity, ecs_key_motion_blur_uniform,
  )
  inspect(non_camera_uniform is None, content="true")
}

///|
test "motion blur: prepare view depth texture usages adds texture binding" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_components3d.Camera3d::component(),
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    entity,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(0.5F, 1),
  )
  prepare_view_depth_texture_usages_for_motion_blur(world)
  guard (try! world.get_by_key(
      entity,
      @camera_components3d.Camera3d::component(),
    ))
    is Some(camera3d) else {
    abort("expected camera3d")
  }
  inspect(camera3d.depth_texture_usages().has_texture_binding(), content="true")
}

///|
test "motion blur: pipeline specialization mirrors Bevy MSAA shader def split" {
  let pipeline = MotionBlurPipeline::MotionBlurPipeline()
  let descriptor = pipeline.specialize(
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

  let msaa_descriptor = pipeline.specialize(
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
test "motion blur: specialized pipeline cache deduplicates keys" {
  let pipeline = MotionBlurPipeline::MotionBlurPipeline()
  let cache = @render_resource.PipelineCache::new()
  let specialized = SpecializedMotionBlurPipelines::SpecializedMotionBlurPipelines()
  let key = MotionBlurPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    samples=1,
  )
  let first = specialized.queue(cache, pipeline, key)
  let second = specialized.queue(cache, pipeline, key)
  inspect(first.id(), content="0")
  inspect(second.id(), content="0")
  inspect(specialized.len(), content="1")
  inspect(cache.queued_pipeline_count(), content="1")
  ignore(
    specialized.queue(
      cache,
      pipeline,
      MotionBlurPipelineKey::new(
        target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
        samples=4,
      ),
    ),
  )
  inspect(specialized.len(), content="2")
  inspect(cache.queued_pipeline_count(), content="2")
}

///|
test "motion blur: prepare pipelines writes Bevy-shaped pipeline id per view" {
  let world = @ecs.World::new()
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )
  init_motion_blur_pipeline(world)
  let source_view = world.spawn()
  let render_view = world.spawn()
  try! world.set_by_key(
    render_view,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(0.5F, 1),
  )
  try! world.set_by_key(
    render_view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(source_view),
      target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    ),
  )
  try! world.set_by_key(
    render_view,
    @render_view.Msaa::component(),
    @render_view.Msaa::Sample4,
  )

  prepare_motion_blur_pipelines(world)

  guard (try! world.get_by_key(render_view, ecs_key_motion_blur_pipeline_id))
    is Some(pipeline_id) else {
    abort("expected prepared pipeline id")
  }
  inspect(pipeline_id.pipeline_id().id(), content="0")
  let cache = world.get_resource(@render.pipeline_cache_resource_key).unwrap()
  inspect(cache.queued_pipeline_count(), content="1")
  let state = world
    .get_resource(SpecializedMotionBlurPipelines::resource())
    .unwrap()
  inspect(state.len(), content="1")
}
