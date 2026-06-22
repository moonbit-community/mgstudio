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
    ignore(probes.push_texture(None))
    probes.push_probe(RenderLightProbe::RenderLightProbe())
    i |> ignore
  }
  inspect(probes.texture_count(), content="8")
  inspect(probes.probe_count(), content="8")
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
