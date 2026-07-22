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
// Bevy source: `bevy/crates/bevy_light/src/cluster/assign.rs`.

///|
fn cluster_approx_eq(a : Float, b : Float, eps : Float) -> Bool {
  (a - b).abs() <= eps
}

///|
fn cluster_test_camera() -> @camera_camera.Camera {
  cluster_test_camera_with_size(1280, 720)
}

///|
fn cluster_test_camera_with_size(
  width : Int,
  height : Int,
) -> @camera_camera.Camera {
  @camera_camera.Camera::Camera().with_viewport(
    @camera_viewport.Viewport::new(
      @math.IVec2::new(0, 0),
      @math.IVec2::new(width, height),
    ),
  )
}

///|
fn cluster_test_set_camera3d(
  world : @ecs.World,
  entity : @core.Entity,
  camera : @camera_camera.Camera,
) -> Unit {
  try! (world.set_by_key(entity, @camera_camera.ecs_key_camera, camera)
  |> ignore)
  try! (world.set_by_key(
    entity,
    @camera_components3d.ecs_key_camera3d,
    Camera3d(),
  )
  |> ignore)
}

///|
test "light cluster: calculate_cluster_factors matches bevy perspective formula shape" {
  let factors = calculate_cluster_factors(0.1F, 1000.0F, 24.0F, false)
  inspect(cluster_approx_eq(factors.x, 2.4971933F, 1.0e-5F), content="true")
  inspect(cluster_approx_eq(factors.y, -5.75F, 1.0e-5F), content="true")
}

///|
test "light cluster: calculate_cluster_factors matches bevy orthographic formula shape" {
  let factors = calculate_cluster_factors(0.1F, 1000.0F, 24.0F, true)
  inspect(cluster_approx_eq(factors.x, -0.1F, 1.0e-6F), content="true")
  inspect(cluster_approx_eq(factors.y, -0.0240024F, 1.0e-6F), content="true")
}

///|
test "light cluster: default cluster config uses bevy fixed-z shape" {
  let config = ClusterConfig::default()
  let ok = match config {
    FixedZ(total, z_slices, _, dynamic_resizing) =>
      total == 4096 && z_slices == 24 && dynamic_resizing
    _ => false
  }
  inspect(ok, content="true")
}

///|
test "light cluster: dimensions_for_screen_size matches bevy fixed-z rounding shape" {
  let config = ClusterConfig::default()
  let dimensions = cluster_config_dimensions_for_screen_size(config, 1920, 1080)
  inspect(dimensions.0, content="16")
  inspect(dimensions.1, content="9")
  inspect(dimensions.2, content="24")
}

///|
test "light cluster: cluster config helper semantics match bevy shape" {
  let none_config = ClusterConfig::None
  inspect(cluster_config_first_slice_depth(none_config), content="0")
  inspect(
    cluster_config_far_z_mode(none_config) is Constant(0.0F),
    content="true",
  )
  inspect(!cluster_config_dynamic_resizing(none_config), content="true")

  let single_config = ClusterConfig::Single
  inspect(cluster_config_first_slice_depth(single_config), content="0")
  inspect(
    cluster_config_far_z_mode(single_config) is MaxClusterableObjectRange,
    content="true",
  )
  inspect(!cluster_config_dynamic_resizing(single_config), content="true")

  let z_config = ClusterZConfig::{
    first_slice_depth: 7.5F,
    far_z_mode: Constant(33.0F),
  }
  let xyz = ClusterConfig::XYZ(4, 3, 2, z_config, true)
  inspect(cluster_config_first_slice_depth(xyz), content="7.5")
  inspect(cluster_config_far_z_mode(xyz) is Constant(33.0F), content="true")
  inspect(cluster_config_dynamic_resizing(xyz), content="true")
}

///|
test "light cluster: assignment is scheduled after transform camera and visibility like bevy" {
  let camera_update_set = @app.system_set("mgstudio.camera.update")
  let lifecycle_world_123_0 = @ecs.World::new()
  defer lifecycle_world_123_0.close()
  let app = @app.App::new(lifecycle_world_123_0)
    .add_systems(
      PostUpdate,
      @app.system(fn(_world : @ecs.World) { () })
      .named("tests.transform.propagate")
      .in_set(@transform.transform_set_propagate),
    )
    .add_systems(
      PostUpdate,
      @app.system(fn(_world : @ecs.World) { () })
      .named("tests.visibility.check")
      .in_set(@visibility.visibility_set_check_visibility),
    )
    .add_systems(
      PostUpdate,
      @app.system(fn(_world : @ecs.World) { () })
      .named("tests.camera.update")
      .in_set(camera_update_set),
    )
    .add_plugins(ClusterLightPlugin::ClusterLightPlugin())
  let update_dot = app.schedule_graph_dot(Update)
  debug_inspect(
    update_dot.contains("\"mgstudio.light.cluster.assign_objects_to_clusters\""),
    content="false",
  )
  let post_update_dot = app.schedule_graph_dot(PostUpdate)
  debug_inspect(
    post_update_dot.contains(
      "\"mgstudio.light.cluster.assign_objects_to_clusters\"",
    ),
    content="true",
  )
  debug_inspect(
    post_update_dot.contains(
      "\"tests.transform.propagate\" -> \"tests.visibility.check\"",
    ),
    content="true",
  )
  debug_inspect(
    post_update_dot.contains(
      "\"tests.visibility.check\" -> \"tests.camera.update\"",
    ),
    content="true",
  )
  debug_inspect(
    post_update_dot.contains(
      "\"tests.camera.update\" -> \"mgstudio.light.cluster.assign_objects_to_clusters\"",
    ),
    content="true",
  )
}

///|
test "light cluster: assign system populates camera cluster payload with default config" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  cluster_assign_lights_system(world)
  let clusters = try! world.get_by_key(camera_entity, Clusters::component())
  let visible = try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )
  guard clusters is Some(clusters_value) else {
    inspect("missing", content="clusters")
    return
  }
  guard visible is Some(visible_value) else {
    inspect("missing", content="visible")
    return
  }
  inspect(clusters_value.dimensions_x, content="16")
  inspect(clusters_value.dimensions_y, content="9")
  inspect(clusters_value.dimensions_z, content="24")
  inspect(clusters_value.clusterable_objects.length(), content="3456")
  inspect(clusters_value.near, content="5")
  inspect(clusters_value.far, content="1000")
  debug_inspect(clusters_value.last_frame_farthest_z(), content="Some(0)")
  debug_inspect(
    clusters_value.last_frame_total_cluster_index_count(),
    content="Some(0)",
  )
  inspect(visible_value.point_and_spot_lights.length(), content="0")
}

///|
test "light cluster: assign system uses previous frame max range for default far z mode" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(40.0F),
  )
  |> ignore)
  let spot = world.spawn()
  try! (world.set_by_key(
    spot,
    @light.ecs_key_spot_light,
    @light.SpotLight::new(
      @color.Color::white(),
      1_000_000.0F,
      55.0F,
      0.6F,
      0.8F,
      false,
    ),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let first_frame_clusters = (try! world.get_by_key(
    camera_entity,
    Clusters::component(),
  )).unwrap()
  inspect(first_frame_clusters.far, content="1000")
  debug_inspect(
    first_frame_clusters.last_frame_farthest_z(),
    content="Some(55)",
  )

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.far, content="55")
  inspect(visible.point_and_spot_lights.length(), content="2")
}

///|
test "light cluster: assign system uses previous frame index count for dynamic resizing" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  let previous_clusters = Clusters::new(120, 120, 16, 9, 24, 5.0F, 1000.0F)
  previous_clusters.last_frame_total_cluster_index_count = Some(65536)
  try! (world.set_by_key(
    camera_entity,
    Clusters::component(),
    previous_clusters,
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  inspect(clusters.dimensions_x, content="8")
  inspect(clusters.dimensions_y, content="4")
  inspect(clusters.dimensions_z, content="24")
}

///|
test "light cluster: ClusterConfig::None clears clusters and preserves last-frame statistics" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  try! (world.set_by_key(camera_entity, ClusterConfig::component(), None)
  |> ignore)
  let previous_clusters = Clusters::new(120, 120, 16, 9, 24, 5.0F, 1000.0F)
  previous_clusters.last_frame_farthest_z = Some(77.0F)
  previous_clusters.last_frame_total_cluster_index_count = Some(1234)
  try! (world.set_by_key(
    camera_entity,
    Clusters::component(),
    previous_clusters,
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.tile_size_x, content="1")
  inspect(clusters.tile_size_y, content="1")
  inspect(clusters.dimensions_x, content="0")
  inspect(clusters.dimensions_y, content="0")
  inspect(clusters.dimensions_z, content="0")
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(77)")
  debug_inspect(
    clusters.last_frame_total_cluster_index_count(),
    content="Some(1234)",
  )
  inspect(visible.point_and_spot_light_count(), content="0")
}

///|
test "light cluster: camera without physical viewport clears clusters" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, Camera())
  let previous_clusters = Clusters::new(120, 120, 16, 9, 24, 5.0F, 1000.0F)
  previous_clusters.last_frame_farthest_z = Some(88.0F)
  previous_clusters.last_frame_total_cluster_index_count = Some(4321)
  try! (world.set_by_key(
    camera_entity,
    Clusters::component(),
    previous_clusters,
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.tile_size_x, content="1")
  inspect(clusters.tile_size_y, content="1")
  inspect(clusters.dimensions_x, content="0")
  inspect(clusters.dimensions_y, content="0")
  inspect(clusters.dimensions_z, content="0")
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(88)")
  debug_inspect(
    clusters.last_frame_total_cluster_index_count(),
    content="Some(4321)",
  )
  inspect(visible.point_and_spot_light_count(), content="0")
}

///|
test "light cluster: non-3d cameras do not receive 3d clusters" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  try! (world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    cluster_test_camera(),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  inspect(
    (try! world.get_by_key(camera_entity, Clusters::component())) is None,
    content="true",
  )
  inspect(
    (try! world.get_by_key(
      camera_entity,
      VisibleClusterableObjects::component(),
    ))
    is None,
    content="true",
  )
}

///|
test "light cluster: zero-sized camera viewport clears clusters" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(
    world,
    camera_entity,
    cluster_test_camera_with_size(0, 720),
  )
  let previous_clusters = Clusters::new(120, 120, 16, 9, 24, 5.0F, 1000.0F)
  previous_clusters.last_frame_farthest_z = Some(99.0F)
  previous_clusters.last_frame_total_cluster_index_count = Some(7654)
  try! (world.set_by_key(
    camera_entity,
    Clusters::component(),
    previous_clusters,
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.tile_size_x, content="1")
  inspect(clusters.tile_size_y, content="1")
  inspect(clusters.dimensions_x, content="0")
  inspect(clusters.dimensions_y, content="0")
  inspect(clusters.dimensions_z, content="0")
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(99)")
  debug_inspect(
    clusters.last_frame_total_cluster_index_count(),
    content="Some(7654)",
  )
  inspect(visible.point_and_spot_light_count(), content="0")
}

///|
test "light cluster: assign system writes visible point lights into cluster lists" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  try! (world.set_by_key(
    camera_entity,
    @transform.Transform::component(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore)
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(10.0F),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  let mut assigned_count = 0
  for cluster in clusters.clusterable_objects {
    assigned_count += cluster.counts.point_lights
  }
  inspect(visible.point_and_spot_light_count(), content="1")
  inspect(assigned_count > 0, content="true")
}

///|
test "light cluster: spot lights use bevy cone culling inside projected bounds" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  try! (world.set_by_key(
    camera_entity,
    @transform.Transform::component(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore)
  let point = world.spawn()
  try! (world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(10.0F),
  )
  |> ignore)
  let spot = world.spawn()
  try! (world.set_by_key(
    spot,
    @light.ecs_key_spot_light,
    @light.SpotLight::new(
      @color.Color::white(),
      1000.0F,
      10.0F,
      0.1F,
      0.25F,
      false,
    ),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let mut point_count = 0
  let mut spot_count = 0
  for cluster in clusters.clusterable_objects {
    point_count += cluster.counts.point_lights
    spot_count += cluster.counts.spot_lights
  }
  inspect(point_count > 0, content="true")
  inspect(spot_count > 0, content="true")
  inspect(spot_count < point_count, content="true")
}

///|
test "light cluster: assign system honors constant far z mode from config" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  try! (world.set_by_key(
    camera_entity,
    ClusterConfig::component(),
    FixedZ(
      4096,
      24,
      { first_slice_depth: 6.0F, far_z_mode: Constant(123.0F) },
      true,
    ),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  inspect(clusters.near, content="6")
  inspect(clusters.far, content="123")
}

///|
test "light cluster: assign system filters hidden clusterables by view visibility" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())

  let point_visible = world.spawn()
  try! (world.set_by_key(
    point_visible,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(10.0F),
  )
  |> ignore)

  let point_hidden = world.spawn()
  try! (world.set_by_key(
    point_hidden,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(80.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    point_hidden,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)

  let probe_visible = world.spawn()
  try! (world.set_by_key(
    probe_visible,
    @light.ecs_key_environment_map_light,
    EnvironmentMapLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    probe_visible,
    @light.ecs_key_light_probe,
    LightProbe(),
  )
  |> ignore)

  let probe_hidden = world.spawn()
  try! (world.set_by_key(
    probe_hidden,
    @light.ecs_key_environment_map_light,
    EnvironmentMapLight(),
  )
  |> ignore)
  try! (world.set_by_key(probe_hidden, @light.ecs_key_light_probe, LightProbe())
  |> ignore)
  try! (world.set_by_key(
    probe_hidden,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)

  let irradiance_visible = world.spawn()
  try! (world.set_by_key(
    irradiance_visible,
    @light.ecs_key_irradiance_volume,
    IrradianceVolume(),
  )
  |> ignore)
  try! (world.set_by_key(
    irradiance_visible,
    @light.ecs_key_light_probe,
    LightProbe(),
  )
  |> ignore)

  let irradiance_hidden = world.spawn()
  try! (world.set_by_key(
    irradiance_hidden,
    @light.ecs_key_irradiance_volume,
    IrradianceVolume(),
  )
  |> ignore)
  try! (world.set_by_key(
    irradiance_hidden,
    @light.ecs_key_light_probe,
    LightProbe(),
  )
  |> ignore)
  try! (world.set_by_key(
    irradiance_hidden,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.far, content="1000")
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(10)")
  inspect(visible.point_and_spot_light_count(), content="1")
  inspect(visible.reflection_probe_count(), content="1")
  inspect(visible.irradiance_volume_count(), content="1")
}

///|
test "light cluster: assign system filters lights by render layers" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())
  try! (world.set_by_key(
    camera_entity,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(1),
  )
  |> ignore)

  let point_visible = world.spawn()
  try! (world.set_by_key(
    point_visible,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(10.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    point_visible,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(1),
  )
  |> ignore)

  let point_hidden = world.spawn()
  try! (world.set_by_key(
    point_hidden,
    @light.ecs_key_point_light,
    @light.PointLight::PointLight().with_range(80.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    point_hidden,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(2),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(10)")
  inspect(visible.point_and_spot_light_count(), content="1")
}

///|
test "light cluster: light probes require LightProbe and use transform radius" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  cluster_test_set_camera3d(world, camera_entity, cluster_test_camera())

  let bare_environment_map = world.spawn()
  try! (world.set_by_key(
    bare_environment_map,
    @light.ecs_key_environment_map_light,
    EnvironmentMapLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    bare_environment_map,
    @transform.Transform::component(),
    @transform.Transform::identity().with_scale(@math.Vec3::splat(100.0F)),
  )
  |> ignore)

  let reflection_probe = world.spawn()
  try! (world.set_by_key(
    reflection_probe,
    @light.ecs_key_environment_map_light,
    EnvironmentMapLight(),
  )
  |> ignore)
  try! (world.set_by_key(
    reflection_probe,
    @light.ecs_key_light_probe,
    LightProbe(),
  )
  |> ignore)
  try! (world.set_by_key(
    reflection_probe,
    @transform.Transform::component(),
    @transform.Transform::identity().with_scale(
      @math.Vec3::new(3.0F, 4.0F, 12.0F),
    ),
  )
  |> ignore)

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component())).unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.far, content="1000")
  debug_inspect(clusters.last_frame_farthest_z(), content="Some(13)")
  inspect(visible.reflection_probe_count(), content="1")
}

///|
test "light cluster: runtime container helpers follow bevy-style semantics" {
  let clusters = Clusters::new(16, 9, 16, 9, 24, 5.0F, 100.0F)
  clusters.update(1920, 1080, 16, 9, 24)
  inspect(clusters.tile_size_x, content="120")
  inspect(clusters.tile_size_y, content="120")
  inspect(clusters.dimensions_x, content="16")
  inspect(clusters.dimensions_y, content="9")
  inspect(clusters.dimensions_z, content="24")
  clusters.clear()
  inspect(clusters.tile_size_x, content="1")
  inspect(clusters.tile_size_y, content="1")
  inspect(clusters.dimensions_x, content="0")
  inspect(clusters.dimensions_y, content="0")
  inspect(clusters.dimensions_z, content="0")
  debug_inspect(clusters.last_frame_farthest_z(), content="None")
  debug_inspect(clusters.last_frame_total_cluster_index_count(), content="None")

  let visible = VisibleClusterableObjects::new()
  let entity0 = @core.Entity::new(1, 1)
  let entity1 = @core.Entity::new(2, 1)
  let entity2 = @core.Entity::new(3, 1)
  let entity3 = @core.Entity::new(4, 1)
  let entity4 = @core.Entity::new(5, 1)
  visible.add(entity0, PointLight(false, false))
  visible.add(entity1, SpotLight(false, false, 0.8F))
  visible.add(entity2, ReflectionProbe)
  visible.add(entity3, IrradianceVolume)
  visible.add(entity4, Decal)
  inspect(visible.point_and_spot_light_count(), content="2")
  inspect(visible.reflection_probe_count(), content="1")
  inspect(visible.irradiance_volume_count(), content="1")
  inspect(visible.decal_count(), content="1")
  visible.clear()
  inspect(visible.point_and_spot_light_count(), content="0")
  inspect(visible.reflection_probe_count(), content="0")
  inspect(visible.irradiance_volume_count(), content="0")
  inspect(visible.decal_count(), content="0")

  let in_cluster = ObjectsInCluster::ObjectsInCluster()
  in_cluster.add_point_light(entity0)
  in_cluster.add_spot_light(entity1)
  in_cluster.add_reflection_probe(entity2)
  in_cluster.add_irradiance_volume(entity3)
  in_cluster.add_decal(entity4)
  inspect(in_cluster.counts.point_lights, content="1")
  inspect(in_cluster.counts.spot_lights, content="1")
  inspect(in_cluster.counts.reflection_probes, content="1")
  inspect(in_cluster.counts.irradiance_volumes, content="1")
  inspect(in_cluster.counts.decals, content="1")
  inspect(in_cluster.iter().length(), content="5")
  in_cluster.clear()
  inspect(in_cluster.counts.point_lights, content="0")
  inspect(in_cluster.iter().length(), content="0")
}
