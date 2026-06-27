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
test "light plugin: initializes default light resources" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let scattering_medium_assets_key : @ecs.ResourceKey[
    @asset.Assets[ScatteringMedium],
  ] = @asset.assets_resource_key()
  debug_inspect(
    app.contains_resource(ecs_key_global_ambient_light),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_point_light_shadow_map),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_directional_light_shadow_map),
    content="true",
  )
  debug_inspect(
    app.contains_resource(scattering_medium_assets_key),
    content="true",
  )
}

///|
test "light plugin: automatically adds default parallax correction to reflection probes" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@transform.TransformPlugin::TransformPlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
  let world = app.world()

  let auto_probe = world.spawn()
  try! world.set(auto_probe, @light.EnvironmentMapLight::EnvironmentMapLight())
  try! world.set(auto_probe, @light.LightProbe::LightProbe())

  let custom_probe = world.spawn()
  try! world.set(
    custom_probe,
    @light.EnvironmentMapLight::EnvironmentMapLight(),
  )
  try! world.set(custom_probe, @light.LightProbe::LightProbe())
  try! world.set(
    custom_probe,
    ParallaxCorrection::Custom(@math.Vec3::new(0.25, 0.5, 0.75)),
  )

  let non_probe = world.spawn()
  try! world.set(non_probe, @light.LightProbe::LightProbe())

  app = app.update()

  let auto_inserted = match
    (try! app.world().get_by_key(auto_probe, ecs_key_parallax_correction)) {
    Some(ParallaxCorrection::Auto) => true
    _ => false
  }
  debug_inspect(auto_inserted, content="true")

  let custom_preserved = match
    (try! app.world().get_by_key(custom_probe, ecs_key_parallax_correction)) {
    Some(ParallaxCorrection::Custom(_)) => true
    _ => false
  }
  debug_inspect(custom_preserved, content="true")

  debug_inspect(
    try! (app.world().get_by_key(non_probe, ecs_key_parallax_correction) is None),
    content="true",
  )
}

///|
test "light plugin: light probe required components match bevy probe requirements" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let probe = world.spawn()
  try! world.set(probe, @light.LightProbe::LightProbe())
  debug_inspect(
    try! (world.get_by_key(probe, @transform.ecs_key_transform) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(probe, @visibility.ecs_key_visibility) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(probe, @visibility.ecs_key_view_visibility)
    is Some(_)),
    content="true",
  )
  let probe_visibility_class : @visibility.VisibilityClass? = try! world.get_by_key(
    probe, @visibility.ecs_key_visibility_class,
  )
  debug_inspect(probe_visibility_class is Some(_), content="true")
  inspect(
    match probe_visibility_class {
      Some(classes) =>
        classes.iter().contains(@light.cluster_visibility_class_id())
      None => false
    },
    content="true",
  )

  let volume = world.spawn()
  try! world.set(volume, @light.IrradianceVolume::IrradianceVolume())
  debug_inspect(
    try! (world.get_by_key(volume, ecs_key_light_probe) is Some(_)),
    content="true",
  )
}

///|
test "light plugin: point light required components match bevy point requirements" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let entity = world.spawn()
  try! world.set(entity, @light.PointLight::PointLight())
  debug_inspect(
    try! (world.get_by_key(entity, @camera_primitives.ecs_key_cubemap_frusta)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(
      entity, @camera_visibility.ecs_key_cubemap_visible_entities,
    )
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @transform.ecs_key_transform) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @visibility.ecs_key_visibility) is Some(_)),
    content="true",
  )
  let classes : @visibility.VisibilityClass? = try! world.get_by_key(
    entity, @visibility.ecs_key_visibility_class,
  )
  inspect(
    match classes {
      Some(classes) =>
        classes.iter().contains(@light.cluster_visibility_class_id())
      None => false
    },
    content="true",
  )
}

///|
test "light plugin: spot light required components match bevy spot requirements" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let entity = world.spawn()
  try! world.set(entity, @light.SpotLight::SpotLight())
  debug_inspect(
    try! (world.get_by_key(entity, @camera_primitives.ecs_key_frustum)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(
      entity, @camera_visibility.ecs_key_visible_mesh_entities,
    )
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @transform.ecs_key_transform) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @visibility.ecs_key_visibility) is Some(_)),
    content="true",
  )
  let classes : @visibility.VisibilityClass? = try! world.get_by_key(
    entity, @visibility.ecs_key_visibility_class,
  )
  inspect(
    match classes {
      Some(classes) =>
        classes.iter().contains(@light.cluster_visibility_class_id())
      None => false
    },
    content="true",
  )
}

///|
test "light plugin: directional light required components match bevy directional requirements" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let entity = world.spawn()
  try! world.set(entity, @light.DirectionalLight::DirectionalLight())
  debug_inspect(
    try! (world.get_by_key(entity, @light.ecs_key_cascades) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @camera_primitives.ecs_key_cascades_frusta)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @light.ecs_key_cascade_shadow_config)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(
      entity, @camera_visibility.ecs_key_cascades_visible_entities,
    )
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @transform.ecs_key_transform) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(entity, @visibility.ecs_key_visibility) is Some(_)),
    content="true",
  )
  let classes : @visibility.VisibilityClass? = try! world.get_by_key(
    entity, @visibility.ecs_key_visibility_class,
  )
  inspect(
    match classes {
      Some(classes) =>
        classes.iter().contains(@light.cluster_visibility_class_id())
      None => false
    },
    content="true",
  )
}

///|
test "light plugin: light texture and sun disk components require owner lights" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let point = world.spawn()
  try! world.set(point, @light.PointLightTexture::PointLightTexture())
  debug_inspect(
    try! (world.get_by_key(point, @light.ecs_key_point_light) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(point, @camera_primitives.ecs_key_cubemap_frusta)
    is Some(_)),
    content="true",
  )

  let spot = world.spawn()
  try! world.set(spot, @light.SpotLightTexture::SpotLightTexture())
  debug_inspect(
    try! (world.get_by_key(spot, @light.ecs_key_spot_light) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(spot, @camera_primitives.ecs_key_frustum) is Some(_)),
    content="true",
  )

  let directional_texture = world.spawn()
  try! world.set(
    directional_texture,
    @light.DirectionalLightTexture::DirectionalLightTexture(),
  )
  debug_inspect(
    try! (world.get_by_key(
      directional_texture, @light.ecs_key_directional_light,
    )
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(directional_texture, @light.ecs_key_cascades)
    is Some(_)),
    content="true",
  )

  let sun_disk = world.spawn()
  try! world.set(sun_disk, @light.SunDisk::SunDisk())
  debug_inspect(
    try! (world.get_by_key(sun_disk, @light.ecs_key_directional_light)
    is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (world.get_by_key(sun_disk, @light.ecs_key_cascade_shadow_config)
    is Some(_)),
    content="true",
  )
}

///|
test "light plugin: cluster visibility hook preserves existing visibility classes" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_visibility_class,
    @visibility.VisibilityClass::single(123),
  )
  try! world.set(entity, @light.PointLight::PointLight())

  let classes : @visibility.VisibilityClass? = try! world.get_by_key(
    entity, @visibility.ecs_key_visibility_class,
  )
  inspect(
    match classes {
      Some(classes) => classes.iter().contains(123)
      None => false
    },
    content="true",
  )
  inspect(
    match classes {
      Some(classes) =>
        classes.iter().contains(@light.cluster_visibility_class_id())
      None => false
    },
    content="true",
  )
}

///|
test "light plugin: ambient light requires camera component" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @light.LightPlugin::LightPlugin(),
  )
  let world = app.world()

  let entity = world.spawn()
  try! world.set(entity, @light.AmbientLight::AmbientLight())
  debug_inspect(
    try! (world.get_by_key(entity, @camera_camera.ecs_key_camera) is Some(_)),
    content="true",
  )
}

///|
test "light plugin: exposes Bevy simulation light system sets" {
  debug_inspect(
    simulation_light_system_set_name(SimulationLightSystems::UpdateBounds),
    content="\"mgstudio.light.SimulationLightSystems.UpdateBounds\"",
  )
  debug_inspect(
    simulation_light_system_set_name(
      SimulationLightSystems::AssignLightsToClusters,
    ),
    content="\"mgstudio.light.SimulationLightSystems.AssignLightsToClusters\"",
  )
  debug_inspect(
    simulation_light_system_set_name(
      SimulationLightSystems::UpdateDirectionalLightCascades,
    ),
    content="\"mgstudio.light.SimulationLightSystems.UpdateDirectionalLightCascades\"",
  )
  debug_inspect(
    simulation_light_system_set_name(SimulationLightSystems::UpdateLightFrusta),
    content="\"mgstudio.light.SimulationLightSystems.UpdateLightFrusta\"",
  )
  debug_inspect(
    simulation_light_system_set_name(
      SimulationLightSystems::CheckLightVisibility,
    ),
    content="\"mgstudio.light.SimulationLightSystems.CheckLightVisibility\"",
  )
}

///|
test "light plugin: updates point and spot light bounding spheres" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@transform.TransformPlugin::TransformPlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
  let world = app.world()

  let point = world.spawn()
  try! world.set(point, @light.PointLight::PointLight().with_range(7.5F))
  try! world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_translation(@math.Vec3::new(1.0F, 2.0F, 3.0F)),
  )

  let spot = world.spawn()
  try! world.set(
    spot,
    @light.SpotLight::new(
      @color.Color::white(),
      1_000_000.0F,
      4.25F,
      0.0F,
      0.7853981633974483F,
      false,
    ),
  )
  try! world.set_by_key(
    spot,
    @transform.ecs_key_transform,
    @transform.Transform::from_translation(@math.Vec3::new(-2.0F, 0.5F, 9.0F)),
  )

  app = app.update()

  let point_sphere = try! app
    .world()
    .get_by_key(point, @camera_primitives.ecs_key_sphere)
  debug_inspect(point_sphere is Some(_), content="true")
  match point_sphere {
    Some(point_sphere) => {
      debug_inspect(point_sphere.center().x, content="1")
      debug_inspect(point_sphere.center().y, content="2")
      debug_inspect(point_sphere.center().z, content="3")
      debug_inspect(point_sphere.radius(), content="7.5")
    }
    None => ()
  }

  let spot_sphere = try! app
    .world()
    .get_by_key(spot, @camera_primitives.ecs_key_sphere)
  debug_inspect(spot_sphere is Some(_), content="true")
  match spot_sphere {
    Some(spot_sphere) => {
      debug_inspect(spot_sphere.center().x, content="-2")
      debug_inspect(spot_sphere.center().y, content="0.5")
      debug_inspect(spot_sphere.center().z, content="9")
      debug_inspect(spot_sphere.radius(), content="4.25")
    }
    None => ()
  }
}

///|
test "light plugin: updates visible shadow-mapped spot light frusta" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@transform.TransformPlugin::TransformPlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
  let world = app.world()
  let spot = world.spawn()
  let spot_light = @light.SpotLight::new(
    @color.Color::white(),
    1_000_000.0F,
    6.0F,
    0.0F,
    0.7853981633974483F,
    true,
  )
  try! world.set(spot, spot_light)
  try! world.set_by_key(
    spot,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )

  app = app.update()

  let frustum = try! app
    .world()
    .get_by_key(spot, @camera_primitives.ecs_key_frustum)
  debug_inspect(frustum is Some(_), content="true")
  match frustum {
    Some(frustum) => {
      let half_spaces = frustum.view_frustum().half_spaces()
      debug_inspect(half_spaces.length(), content="6")
      let far = half_spaces[@camera_primitives.VIEW_FRUSTUM_FAR_PLANE_IDX]
      let normal = far.normal()
      debug_inspect(normal.x.to_double(), content="0")
      debug_inspect(normal.y.to_double(), content="0")
      debug_inspect(normal.z.to_double(), content="1")
      debug_inspect(far.d().to_double(), content="6")
    }
    None => ()
  }
}

///|
test "light: WithLight matches point, spot, directional, and rect lights" {
  let world = @ecs.World::new()
  let point = world.spawn()
  let spot = world.spawn()
  let directional = world.spawn()
  let rect = world.spawn()
  let mesh = world.spawn()

  try! world.set(point, @light.PointLight::PointLight())
  try! world.set(spot, @light.SpotLight::SpotLight())
  try! world.set(directional, @light.DirectionalLight::DirectionalLight())
  try! world.set(rect, @light.RectLight::RectLight())
  try! world.set(mesh, @visibility.Visibility::Visible)

  let query : @ecs.Query[@core.Entity, WithLight] = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.With::new(@light.ecs_key_point_light),
        @ecs.With::new(@light.ecs_key_spot_light),
        @ecs.With::new(@light.ecs_key_directional_light),
        @ecs.With::new(@light.ecs_key_rect_light),
      ),
    ),
  )
  debug_inspect(query.count(), content="4")
  debug_inspect(try! (query.get(point) is Some(_)), content="true")
  debug_inspect(try! (query.get(spot) is Some(_)), content="true")
  debug_inspect(try! (query.get(directional) is Some(_)), content="true")
  debug_inspect(try! (query.get(rect) is Some(_)), content="true")
  debug_inspect(try! (query.get(mesh) is None), content="true")
}
