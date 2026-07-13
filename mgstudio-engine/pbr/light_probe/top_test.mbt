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
  let first_diffuse : @asset.Handle[@asset.Image] = @asset.Handle::new(11)
  let first_specular : @asset.Handle[@asset.Image] = @asset.Handle::new(12)
  let second_diffuse : @asset.Handle[@asset.Image] = @asset.Handle::new(23)
  let second_specular : @asset.Handle[@asset.Image] = @asset.Handle::new(24)
  let first = LightProbeTextureId::environment_map(
    first_diffuse, first_specular,
  )
  let second = LightProbeTextureId::environment_map(
    second_diffuse, second_specular,
  )
  inspect(probes.get_or_insert_texture(first), content="0")
  inspect(probes.get_or_insert_texture(first), content="0")
  inspect(probes.get_or_insert_texture(second), content="1")
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
test "pbr light probe: light probe info skips unloaded or incomplete assets" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  let main_entity = @render.MainEntity::new(entity)
  let light_probe = @light.LightProbe::LightProbe()
  let incomplete_environment = @light.EnvironmentMapLight::new(
    None,
    Some(@asset.Handle::new(701)),
    1.0F,
  )
  inspect(
    LightProbeInfo::from_environment_map_light(
      world, main_entity, light_probe, incomplete_environment,
    )
    is None,
    content="true",
  )
  let unloaded_environment = @light.EnvironmentMapLight::new(
    Some(@asset.Handle::new(702)),
    Some(@asset.Handle::new(703)),
    1.0F,
  )
  inspect(
    LightProbeInfo::from_environment_map_light(
      world, main_entity, light_probe, unloaded_environment,
    )
    is None,
    content="true",
  )
  let unloaded_volume = @light.IrradianceVolume::new(
    Some(@asset.Handle::new(704)),
    1.0F,
  )
  inspect(
    LightProbeInfo::from_irradiance_volume(
      world, main_entity, light_probe, unloaded_volume,
    )
    is None,
    content="true",
  )
}

///|
test "pbr light probe: light probe infos sort by camera distance" {
  let view_transform = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_translation(@math.Vec3::zero()),
  )
  let near_entity = @render.MainEntity::new(@core.Entity::new(801, 1))
  let middle_entity = @render.MainEntity::new(@core.Entity::new(802, 1))
  let far_entity = @render.MainEntity::new(@core.Entity::new(803, 1))
  let near = LightProbeInfo::new(near_entity, Some(@asset.Handle::new(811))).from_world_from_light(
    @math.Affine3::from_translation(@math.Vec3::new(1.0F, 0.0F, 0.0F)),
  )
  let middle = LightProbeInfo::new(middle_entity, Some(@asset.Handle::new(812))).from_world_from_light(
    @math.Affine3::from_translation(@math.Vec3::new(3.0F, 0.0F, 0.0F)),
  )
  let far = LightProbeInfo::new(far_entity, Some(@asset.Handle::new(813))).from_world_from_light(
    @math.Affine3::from_translation(@math.Vec3::new(5.0F, 0.0F, 0.0F)),
  )
  let sorted = light_probe_infos_sort_by_camera_distance(
    [far, near, middle],
    view_transform,
  )
  let probes = RenderViewLightProbes::RenderViewLightProbes()
  probes.maybe_gather_light_probes(sorted)
  inspect(
    probes.render_light_probe_index(near_entity).unwrap_or(999U),
    content="0",
  )
  inspect(
    probes.render_light_probe_index(middle_entity).unwrap_or(999U),
    content="1",
  )
  inspect(
    probes.render_light_probe_index(far_entity).unwrap_or(999U),
    content="2",
  )
}

///|
test "pbr light probe: gather uses visible clusterable probes and skips unloaded assets" {
  let world = @ecs.World::new()
  defer world.close()
  let view = world.spawn()
  let render_view = world.spawn()
  let reflection_probe = world.spawn()
  let irradiance_volume = world.spawn()
  try! world.set_by_key(
    view,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_view),
  )
  try! world.set_by_key(
    view,
    @camera_components3d.ecs_key_camera3d,
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    view,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists(
      [],
      [reflection_probe],
      [irradiance_volume],
      decals=[],
    ),
  )
  try! world.set_by_key(
    reflection_probe,
    @light.ecs_key_light_probe,
    @light.LightProbe::LightProbe(),
  )
  try! world.set_by_key(
    reflection_probe,
    @light.ecs_key_environment_map_light,
    @light.EnvironmentMapLight::new(
      Some(@asset.Handle::new(910)),
      Some(@asset.Handle::new(911)),
      1.0F,
    ),
  )
  try! world.set_by_key(
    irradiance_volume,
    @light.ecs_key_light_probe,
    @light.LightProbe::LightProbe(),
  )
  try! world.set_by_key(
    irradiance_volume,
    @light.ecs_key_irradiance_volume,
    @light.IrradianceVolume::new(Some(@asset.Handle::new(912)), 1.0F),
  )
  gather_environment_map_light_probes(world)
  gather_irradiance_volume_light_probes(world)
  inspect(
    (try! world.get_by_key(
      render_view,
      RenderViewEnvironmentMapLightProbes::component(),
    ))
    is None,
    content="true",
  )
  inspect(
    (try! world.get_by_key(
      render_view,
      RenderViewIrradianceVolumeLightProbes::component(),
    ))
    is None,
    content="true",
  )
}

///|
test "pbr light probe: view environment map creates Bevy view light probe info" {
  @render_texture.register_asset_texture_backend()
  let diffuse = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    1,
    false,
  )
  let specular = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    5,
    false,
  )
  let environment_map_light = @light.EnvironmentMapLight::new(
    Some(diffuse),
    Some(specular),
    2.5F,
  ).with_affects_lightmapped_mesh_diffuse(false)
  let probes = environment_map_light_create_render_view_light_probes(
    Some(environment_map_light),
  )
  let info = probes
    .view_light_probe_info()
    .unwrap_or(
      EnvironmentMapViewLightProbeInfo::EnvironmentMapViewLightProbeInfo(),
    )
  inspect(probes.is_empty(), content="false")
  inspect(probes.texture_count(), content="1")
  inspect(info.cubemap_index(), content="0")
  inspect(info.smallest_specular_mip_level(), content="4")
  inspect(info.intensity() == 2.5F, content="true")
  inspect(info.affects_lightmapped_mesh_diffuse(), content="false")
}

///|
test "pbr light probe: gather includes view environment maps without visible probes" {
  @render_texture.register_asset_texture_backend()
  let world = @ecs.World::new()
  defer world.close()
  let view = world.spawn()
  let render_view = world.spawn()
  let diffuse = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    1,
    false,
  )
  let specular = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    3,
    false,
  )
  try! world.set_by_key(
    view,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_view),
  )
  try! world.set_by_key(
    view,
    @camera_components3d.ecs_key_camera3d,
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    view,
    @light.ecs_key_environment_map_light,
    @light.EnvironmentMapLight::new(Some(diffuse), Some(specular), 4.0F),
  )
  gather_environment_map_light_probes(world)
  let render_view_light_probes = (try! world.get_by_key(
    render_view,
    RenderViewEnvironmentMapLightProbes::component(),
  )).unwrap_or(
    RenderViewEnvironmentMapLightProbes::new(
      RenderViewLightProbes::RenderViewLightProbes(),
    ),
  )
  let info = render_view_light_probes
    .probes()
    .view_light_probe_info()
    .unwrap_or(
      EnvironmentMapViewLightProbeInfo::EnvironmentMapViewLightProbeInfo(),
    )
  inspect(render_view_light_probes.probe_count(), content="0")
  inspect(render_view_light_probes.probes().texture_count(), content="1")
  inspect(info.cubemap_index(), content="0")
  inspect(info.smallest_specular_mip_level(), content="2")
  inspect(info.intensity() == 4.0F, content="true")
}

///|
test "pbr light probe: gather ignores non-Camera3d source views like Bevy" {
  @render_texture.register_asset_texture_backend()
  let world = @ecs.World::new()
  defer world.close()
  let view = world.spawn()
  let render_view = world.spawn()
  let diffuse = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    1,
    false,
  )
  let specular = @asset.asset_create_dynamic_texture_with_mips(
    @math.UVec2::splat(4),
    3,
    false,
  )
  try! world.set_by_key(
    view,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_view),
  )
  try! world.set_by_key(
    view,
    @light.ecs_key_environment_map_light,
    @light.EnvironmentMapLight::new(Some(diffuse), Some(specular), 4.0F),
  )
  gather_environment_map_light_probes(world)
  inspect(
    (try! world.get_by_key(
      render_view,
      RenderViewEnvironmentMapLightProbes::component(),
    ))
    is None,
    content="true",
  )
}

///|
test "pbr light probe: gather removes stale inactive view components" {
  let world = @ecs.World::new()
  defer world.close()
  let view = world.spawn()
  let render_view = world.spawn()
  try! world.set_by_key(
    view,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_view),
  )
  try! world.set_by_key(
    view,
    @camera_components3d.ecs_key_camera3d,
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    view,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  try! world.set_by_key(
    view,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::new(),
  )
  try! world.set_by_key(
    render_view,
    RenderViewEnvironmentMapLightProbes::component(),
    RenderViewEnvironmentMapLightProbes::new(
      RenderViewLightProbes::RenderViewLightProbes(),
    ),
  )
  try! world.set_by_key(
    render_view,
    RenderViewIrradianceVolumeLightProbes::component(),
    RenderViewIrradianceVolumeLightProbes::new(
      RenderViewLightProbes::RenderViewLightProbes(),
    ),
  )
  gather_environment_map_light_probes(world)
  gather_irradiance_volume_light_probes(world)
  inspect(
    (try! world.get_by_key(
      render_view,
      RenderViewEnvironmentMapLightProbes::component(),
    ))
    is None,
    content="true",
  )
  inspect(
    (try! world.get_by_key(
      render_view,
      RenderViewIrradianceVolumeLightProbes::component(),
    ))
    is None,
    content="true",
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
test "pbr light probe: uniform carries Bevy view environment map fields" {
  let reflection = RenderViewLightProbes::RenderViewLightProbes()
  reflection.set_view_light_probe_info(
    EnvironmentMapViewLightProbeInfo::new(
      3,
      6,
      2.0F,
      false,
      @math.Quat::identity(),
    ),
  )
  let uniform = LightProbesUniform::from_render_view_light_probes(
    Some(RenderViewEnvironmentMapLightProbes::new(reflection)),
    None,
  )
  inspect(uniform.view_cubemap_index, content="3")
  inspect(uniform.smallest_specular_mip_level_for_view, content="6")
  inspect(uniform.intensity_for_view == 2.0F, content="true")
  inspect(
    uniform.view_environment_map_affects_lightmapped_mesh_diffuse,
    content="false",
  )
  let bytes = uniform.to_bytes()
  inspect(light_probe_test_read_u32_le(bytes, 1800), content="3")
  inspect(light_probe_test_read_u32_le(bytes, 1804), content="6")
  inspect(light_probe_test_read_u32_le(bytes, 1824), content="1073741824")
  inspect(light_probe_test_read_u32_le(bytes, 1828), content="0")
}

///|
test "pbr light probe: upload_light_probes writes render-world offsets" {
  let world = @ecs.World::new()
  defer world.close()
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
test "pbr light probe: plugin schedules upload in render prepare resources" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(LightProbePlugin::LightProbePlugin())
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_schedule_stage()))
  let render_dot = render_sub_app.schedule_graph_dot(
    @render.render_schedule_stage(),
    settings=@app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
        name,
      ) {
        name == "mgstudio_pbr::upload_light_probes"
      },
    ),
  )
  inspect(
    render_dot.contains("\"mgstudio_pbr::upload_light_probes\""),
    content="true",
  )

  let render_world = render_sub_app.world()
  let view = render_world.spawn()
  try! render_world.set_by_key(
    view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(@render_view.RetainedViewEntity::new(view)),
  )
  let reflection = RenderViewLightProbes::RenderViewLightProbes()
  reflection.maybe_gather_light_probes([
    LightProbeInfo::new(
      @render.MainEntity::new(@core.Entity::new(501, 1)),
      Some(@asset.Handle::new(61)),
    ),
  ])
  try! render_world.set_by_key(
    view,
    RenderViewEnvironmentMapLightProbes::component(),
    RenderViewEnvironmentMapLightProbes::new(reflection),
  )
  ignore(render_sub_app.update())
  let buffer = render_world
    .get_resource(LightProbesBuffer::resource())
    .unwrap_or(LightProbesBuffer::LightProbesBuffer())
  inspect(buffer.uniform_count(), content="1")
  let offset = (try! render_world.get_by_key(
    view,
    ViewLightProbesUniformOffset::component(),
  )).unwrap_or(ViewLightProbesUniformOffset::new(999U))
  inspect(offset.offset(), content="0")
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
  defer world.close()
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
