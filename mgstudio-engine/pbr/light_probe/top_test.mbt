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
test "pbr light probe: view probe container enforces max probe count" {
  let probes = RenderViewLightProbes::RenderViewLightProbes()
  for i in 0..<16 {
    probes.push_probe(RenderLightProbe::RenderLightProbe())
    i |> ignore
  }
  inspect(probes.texture_count(), content="0")
  inspect(probes.probe_count(), content="8")
}

///|
test "pbr light probe: texture bindings are deduplicated like Bevy cubemap bindings" {
  let probes = RenderViewLightProbes::RenderViewLightProbes()
  let first = @asset.Handle::new(11)
  let second = @asset.Handle::new(23)
  inspect(probes.get_or_insert_texture(Some(first)), content="0")
  inspect(probes.get_or_insert_texture(Some(first)), content="0")
  inspect(probes.get_or_insert_texture(Some(second)), content="1")
  inspect(probes.texture_count(), content="2")
}

///|
test "pbr light probe: gather records render probe index by main entity" {
  let probes = RenderViewLightProbes::RenderViewLightProbes()
  let first_entity = @render.MainEntity::new(@core.Entity::new(101, 1))
  let second_entity = @render.MainEntity::new(@core.Entity::new(102, 1))
  let texture = @asset.Handle::new(17)
  probes.maybe_gather_light_probes([
    LightProbeInfo::new(first_entity, Some(texture)),
    LightProbeInfo::new(second_entity, Some(texture)),
  ])
  inspect(probes.texture_count(), content="1")
  inspect(probes.probe_count(), content="2")
  inspect(
    probes.render_light_probe_index(first_entity).unwrap_or(999U),
    content="0",
  )
  inspect(
    probes.render_light_probe_index(second_entity).unwrap_or(999U),
    content="1",
  )
}

///|
test "pbr light probe: add_to_uniform writes Bevy render-probe counts" {
  let probes = RenderViewLightProbes::RenderViewLightProbes()
  probes.maybe_gather_light_probes([
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(201, 1)),
      Some(@asset.Handle::new(31)),
    ),
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(202, 1)),
      Some(@asset.Handle::new(32)),
    ),
  ])
  let uniform = LightProbesUniform::LightProbesUniform()
  probes.add_to_uniform_reflection_probes(uniform)
  inspect(uniform.reflection_probe_count, content="2")
  inspect(uniform.reflection_probes[0].texture_index, content="0")
  inspect(uniform.reflection_probes[1].texture_index, content="1")
}

///|
fn light_probe_test_read_u32_le(bytes : Bytes, offset : Int) -> UInt {
  let b0 = bytes[offset].to_uint()
  let b1 = bytes[offset + 1].to_uint()
  let b2 = bytes[offset + 2].to_uint()
  let b3 = bytes[offset + 3].to_uint()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
test "pbr light probe: uniform bytes preserve Bevy probe counts" {
  let reflection = RenderViewLightProbes::RenderViewLightProbes()
  reflection.maybe_gather_light_probes([
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(301, 1)),
      Some(@asset.Handle::new(41)),
    ),
  ])
  let irradiance = RenderViewLightProbes::RenderViewLightProbes()
  irradiance.maybe_gather_light_probes([
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(302, 1)),
      Some(@asset.Handle::new(42)),
    ),
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(303, 1)),
      Some(@asset.Handle::new(43)),
    ),
  ])
  let uniform = LightProbesUniform::from_render_view_light_probes(
    Some(RenderViewEnvironmentMapLightProbes::new(reflection)),
    Some(RenderViewIrradianceVolumeLightProbes::new(irradiance)),
  )
  let bytes = uniform.to_bytes()
  inspect(bytes.length(), content="2048")
  inspect(light_probe_test_read_u32_le(bytes, 1792), content="1")
  inspect(light_probe_test_read_u32_le(bytes, 1796), content="2")
}

///|
test "pbr light probe: upload_light_probes writes render-world offsets" {
  let world = @ecs.World::new()
  let view = world.spawn()
  try! world.set_by_key(
    view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(@render_view.RetainedViewEntity::new(view)),
  )
  let reflection = RenderViewLightProbes::RenderViewLightProbes()
  reflection.maybe_gather_light_probes([
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(401, 1)),
      Some(@asset.Handle::new(51)),
    ),
  ])
  try! world.set_by_key(
    view,
    RenderViewEnvironmentMapLightProbes::component(),
    RenderViewEnvironmentMapLightProbes::new(reflection),
  )

  upload_light_probes(world)

  let buffer = world
    .get_resource(LightProbesBuffer::resource())
    .unwrap_or(LightProbesBuffer::LightProbesBuffer())
  inspect(buffer.uniform_count(), content="1")
  let offset = (try! world.get_by_key(
    view,
    ViewLightProbesUniformOffset::component(),
  )).unwrap_or(ViewLightProbesUniformOffset::new(999U))
  inspect(offset.offset(), content="0")
  let bytes = buffer.uniform_bytes_at(0).unwrap_or(Bytes::make(0, b'\x00'))
  inspect(light_probe_test_read_u32_le(bytes, 1792), content="1")
}

///|
test "pbr light probe: uniform mirrors Bevy light probe capacities" {
  let uniform = LightProbesUniform::LightProbesUniform()
  inspect(uniform.reflection_probe_capacity(), content="8")
  inspect(uniform.irradiance_volume_capacity(), content="8")
  inspect(uniform.view_cubemap_index(), content="-1")
}

///|
test "pbr light probe: plugin initializes main state and render buffer resource" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(LightProbePlugin::LightProbePlugin())
  inspect(
    app.contains_resource(ecs_key_light_probe_plugin_state),
    content="true",
  )
  inspect(app.contains_resource(ecs_key_light_probes_buffer), content="false")
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  inspect(
    render_world.resource(ecs_key_light_probes_buffer).is_present(),
    content="false",
  )
  ignore(render_sub_app.run_startup())
  inspect(
    render_world.resource(ecs_key_light_probes_buffer).is_present(),
    content="true",
  )
}

///|
test "pbr light probe: resource and component keys round-trip through ecs APIs" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_light_probe_plugin_state,
    LightProbePluginState::LightProbePluginState(),
  )
  let state : LightProbePluginState? = world.get_resource(
    ecs_key_light_probe_plugin_state,
  )
  inspect(state is Some(_), content="true")

  let entity = world.spawn()
  try! (world.set_by_key(
    entity,
    ecs_key_render_view_light_probes,
    RenderViewLightProbes::RenderViewLightProbes(),
  )
  |> ignore)
  let probes = try! world.get_by_key(entity, ecs_key_render_view_light_probes)
  inspect(probes is Some(_), content="true")
}

///|
test "pbr light probe: buffer returns byte offsets for view uniforms" {
  let buffer = LightProbesBuffer::LightProbesBuffer()
  let first = buffer.push_uniform_bytes(
    Bytes::make(LIGHT_PROBES_UNIFORM_SIZE_BYTES, b'\x00'),
  )
  let second = buffer.push_uniform_bytes(
    Bytes::make(LIGHT_PROBES_UNIFORM_SIZE_BYTES, b'\x01'),
  )
  inspect(first, content="0")
  inspect(second, content="2048")
  inspect(buffer.uniform_count(), content="2")
  inspect(buffer.uniform_bytes_at(1) is Some(_), content="true")
}

///|
test "pbr light probe: buffer uploads uniform bytes to gpu binding" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let queue = device.queue()
  let buffer = LightProbesBuffer::LightProbesBuffer()
  buffer.write_buffer(device, queue)
  inspect(buffer.binding() is None, content="true")
  ignore(
    buffer.push_uniform_bytes(
      Bytes::make(LIGHT_PROBES_UNIFORM_SIZE_BYTES, b'\x01'),
    ),
  )
  buffer.write_buffer(device, queue)
  inspect(buffer.binding() is Some(_), content="true")
  inspect(
    buffer.gpu_capacity() >= LIGHT_PROBES_UNIFORM_SIZE_BYTES.to_uint64(),
    content="true",
  )
  device.release()
  adapter.release()
  instance.release()
}
