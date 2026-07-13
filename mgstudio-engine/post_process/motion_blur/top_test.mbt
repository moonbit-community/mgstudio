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
test "motion blur: uniform extract preserves Bevy component values" {
  let settings = MotionBlur::new(-2.0F, 3U)
  let uniform = motion_blur_extract_uniform(settings)
  inspect(uniform.shutter_angle == -2.0F, content="true")
  inspect(uniform.samples, content="3")
  inspect(motion_blur_uniform_is_active(uniform), content="false")
}

///|
test "motion blur: uniform bytes match WGSL layout size" {
  let uniform = MotionBlurUniform::new(0.5F, 3U)
  let bytes = uniform.bytes()
  inspect(bytes.length(), content="16")
  inspect(MOTION_BLUR_UNIFORM_SIZE_BYTES, content="16")
  inspect(bytes[0].to_int() & 0xFF, content="0")
  inspect(bytes[1].to_int() & 0xFF, content="0")
  inspect(bytes[2].to_int() & 0xFF, content="0")
  inspect(bytes[3].to_int() & 0xFF, content="63")
  inspect(bytes[4].to_int() & 0xFF, content="3")
  inspect(bytes[5].to_int() & 0xFF, content="0")
  inspect(bytes[6].to_int() & 0xFF, content="0")
  inspect(bytes[7].to_int() & 0xFF, content="0")
}

///|
test "motion blur: render resources skip inactive uniforms before GPU lookups" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(0.0F, 4U),
  )
  inspect(
    motion_blur_render_resources_for_view(world, entity) is None,
    content="true",
  )
}

///|
test "motion blur: sample helper stays tied to component settings" {
  let disabled = motion_blur_generate_samples(MotionBlur::new(0.0F, 8U))
  inspect(disabled.length(), content="0")
  let single = motion_blur_generate_samples(MotionBlur::MotionBlur())
  inspect(single.length(), content="1")
  inspect(single[0].offset == 0.0F, content="true")
  inspect(single[0].weight == 1.0F, content="true")
  let multi = motion_blur_generate_samples(MotionBlur::new(1.0F, 3U))
  inspect(multi.length(), content="3")
  inspect(multi[0].offset == -0.5F, content="true")
  inspect(multi[1].offset == 0.0F, content="true")
  inspect(multi[2].offset == 0.5F, content="true")
}

///|
test "motion blur: extract only writes uniforms for camera views" {
  let world = @ecs.World::new()
  defer world.close()
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
    MotionBlur::new(1.25F, 3U),
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
    MotionBlur::new(0.75F, 2U),
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
test "motion blur: prepare uniforms writes GPU buffer and per-view offsets" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @render.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(@render.render_device_resource_key, render_device)
  world.insert_resource(@render.render_queue_resource_key, render_queue)
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(
    first,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(0.5F, 1U),
  )
  try! world.set_by_key(
    second,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(1.0F, 2U),
  )

  prepare_motion_blur_uniforms(world)

  let uniforms = world.get_resource(MotionBlurUniforms::resource()).unwrap()
  inspect(uniforms.len(), content="2")
  inspect(uniforms.binding() is Some(_), content="true")
  inspect(
    uniforms.gpu_capacity() >= (MOTION_BLUR_UNIFORM_SIZE_BYTES * 2).to_uint64(),
    content="true",
  )
  let first_offset = try! world.get_by_key(
    first,
    ViewMotionBlurUniformOffset::component(),
  )
  let second_offset = try! world.get_by_key(
    second,
    ViewMotionBlurUniformOffset::component(),
  )
  guard first_offset is Some(first_offset_value) else {
    abort("expected first motion blur uniform offset")
  }
  guard second_offset is Some(second_offset_value) else {
    abort("expected second motion blur uniform offset")
  }
  inspect(first_offset_value.offset(), content="0")
  inspect(
    second_offset_value.offset(),
    content=MOTION_BLUR_UNIFORM_SIZE_BYTES.to_string(),
  )
  device.release()
  adapter.release()
  instance.release()
}

///|
test "motion blur: prepare view depth texture usages adds texture binding" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @camera_components3d.Camera3d::component(),
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    entity,
    ecs_key_motion_blur_uniform,
    MotionBlurUniform::new(0.5F, 1U),
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
