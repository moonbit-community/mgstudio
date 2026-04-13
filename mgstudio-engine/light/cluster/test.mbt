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
    cluster_config_far_z_mode(none_config) is ClusterFarZMode::Constant(0.0F),
    content="true",
  )
  inspect(!cluster_config_dynamic_resizing(none_config), content="true")

  let single_config = ClusterConfig::Single
  inspect(cluster_config_first_slice_depth(single_config), content="0")
  inspect(
    cluster_config_far_z_mode(single_config) is ClusterFarZMode::MaxClusterableObjectRange,
    content="true",
  )
  inspect(!cluster_config_dynamic_resizing(single_config), content="true")

  let z_config = ClusterZConfig::{
    first_slice_depth: 7.5F,
    far_z_mode: ClusterFarZMode::Constant(33.0F),
  }
  let xyz = ClusterConfig::XYZ(4, 3, 2, z_config, true)
  inspect(cluster_config_first_slice_depth(xyz), content="7.5")
  inspect(
    cluster_config_far_z_mode(xyz) is ClusterFarZMode::Constant(33.0F),
    content="true",
  )
  inspect(cluster_config_dynamic_resizing(xyz), content="true")
}

///|
test "light cluster: assign system populates camera cluster payload with default config" {
  let world = @ecs.World::new()
  let camera_entity = world.spawn()
  try! world.set_by_key(
    camera_entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  |> ignore
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
  inspect(clusters_value.far, content="0")
  inspect(visible_value.point_and_spot_lights.length(), content="0")
}

///|
test "light cluster: assign system uses max light range for default far z mode" {
  let world = @ecs.World::new()
  let camera_entity = world.spawn()
  try! world.set_by_key(
    camera_entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  |> ignore
  let point = world.spawn()
  try! world.set_by_key(
    point,
    @light.ecs_key_point_light,
    @light.PointLight::default().with_range(40.0F),
  )
  |> ignore
  let spot = world.spawn()
  try! world.set_by_key(
    spot,
    @light.ecs_key_spot_light,
    @light.SpotLight::new(
      @sprite.Color::white(),
      1_000_000.0F,
      55.0F,
      0.6F,
      0.8F,
      false,
    ),
  )
  |> ignore

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component()))
    .unwrap()
  let visible = (try! world.get_by_key(
    camera_entity,
    VisibleClusterableObjects::component(),
  )).unwrap()
  inspect(clusters.far, content="55")
  inspect(visible.point_and_spot_lights.length(), content="2")
}

///|
test "light cluster: assign system honors constant far z mode from config" {
  let world = @ecs.World::new()
  let camera_entity = world.spawn()
  try! world.set_by_key(
    camera_entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  |> ignore
  try! world.set_by_key(
    camera_entity,
    ClusterConfig::component(),
    ClusterConfig::FixedZ(
      4096,
      24,
      ClusterZConfig::{
        first_slice_depth: 6.0F,
        far_z_mode: ClusterFarZMode::Constant(123.0F),
      },
      true,
    ),
  )
  |> ignore

  cluster_assign_lights_system(world)
  let clusters = (try! world.get_by_key(camera_entity, Clusters::component()))
    .unwrap()
  inspect(clusters.near, content="6")
  inspect(clusters.far, content="123")
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

  let visible = VisibleClusterableObjects::new()
  let entity0 = @core.Entity::new(1, 1)
  let entity1 = @core.Entity::new(2, 1)
  let entity2 = @core.Entity::new(3, 1)
  let entity3 = @core.Entity::new(4, 1)
  let entity4 = @core.Entity::new(5, 1)
  visible.add(entity0, ClusterableObjectType::PointLight(false, false))
  visible.add(entity1, ClusterableObjectType::SpotLight(false, false, 0.8F))
  visible.add(entity2, ClusterableObjectType::ReflectionProbe)
  visible.add(entity3, ClusterableObjectType::IrradianceVolume)
  visible.add(entity4, ClusterableObjectType::Decal)
  inspect(visible.point_and_spot_lights.length(), content="2")
  inspect(visible.reflection_probes.length(), content="1")
  inspect(visible.irradiance_volumes.length(), content="1")
  inspect(visible.decals.length(), content="0")
  visible.clear()
  inspect(visible.point_and_spot_lights.length(), content="0")
  inspect(visible.reflection_probes.length(), content="0")
  inspect(visible.irradiance_volumes.length(), content="0")
  inspect(visible.decals.length(), content="0")

  let in_cluster = ObjectsInCluster::default()
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
  inspect(in_cluster.clusterables().length(), content="5")
  in_cluster.clear()
  inspect(in_cluster.counts.point_lights, content="0")
  inspect(in_cluster.clusterables().length(), content="0")
}
