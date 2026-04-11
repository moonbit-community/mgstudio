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
// Bevy source: `bevy/crates/bevy_light/src/cluster/mod.rs`.

///|
pub type ClusterPointLight = @light.PointLight

///|
pub type ClusterDirectionalLight = @light.DirectionalLight

///|
pub type ClusterSpotLight = @light.SpotLight

///|
pub const CLUSTER_LIGHT_PLUGIN_ID : String = "bevy_light::cluster::ClusterLightPlugin"

///|
pub struct ClusterLightPlugin {}

///|
pub fn ClusterLightPlugin::default() -> ClusterLightPlugin {
  ClusterLightPlugin::{  }
}

///|
pub struct GlobalClusterSettings {
  supports_storage_buffers : Bool
  clustered_decals_are_usable : Bool
  max_uniform_buffer_clusterable_objects : Int
  view_cluster_bindings_max_indices : Int
} derive(Eq, Debug)

///|
pub fn GlobalClusterSettings::default() -> GlobalClusterSettings {
  GlobalClusterSettings::{
    supports_storage_buffers: true,
    clustered_decals_are_usable: true,
    max_uniform_buffer_clusterable_objects: 2048,
    view_cluster_bindings_max_indices: 4096,
  }
}

///|
pub(all) enum ClusterFarZMode {
  MaxClusterableObjectRange
  Constant(Float)
} derive(Eq, Debug)

///|
pub fn ClusterFarZMode::default() -> ClusterFarZMode {
  MaxClusterableObjectRange
}

///|
pub struct ClusterZConfig {
  first_slice_depth : Float
  far_z_mode : ClusterFarZMode
} derive(Eq, Debug)

///|
pub fn ClusterZConfig::default() -> ClusterZConfig {
  ClusterZConfig::{
    first_slice_depth: 5.0,
    far_z_mode: ClusterFarZMode::default(),
  }
}

///|
pub(all) enum ClusterConfig {
  None
  Single
  XYZ(Int, Int, Int, ClusterZConfig, Bool)
  FixedZ(Int, Int, ClusterZConfig, Bool)
} derive(Eq, Debug)

///|
pub fn ClusterConfig::default() -> ClusterConfig {
  XYZ(16, 9, 24, ClusterZConfig::default(), true)
}

///|
pub struct ClusterableObjectCounts {
  point_lights : Int
  spot_lights : Int
  reflection_probes : Int
  irradiance_volumes : Int
  decals : Int
} derive(Eq, Debug)

///|
pub fn ClusterableObjectCounts::default() -> ClusterableObjectCounts {
  ClusterableObjectCounts::{
    point_lights: 0,
    spot_lights: 0,
    reflection_probes: 0,
    irradiance_volumes: 0,
    decals: 0,
  }
}

///|
pub struct ObjectsInCluster {
  counts : ClusterableObjectCounts
} derive(Eq, Debug)

///|
pub fn ObjectsInCluster::default() -> ObjectsInCluster {
  ObjectsInCluster::{ counts: ClusterableObjectCounts::default() }
}

///|
pub struct Clusters {
  tile_size_x : Int
  tile_size_y : Int
  dimensions_x : Int
  dimensions_y : Int
  dimensions_z : Int
  near : Float
  far : Float
  clusterable_objects : Array[ObjectsInCluster]
} derive(Eq, Debug)

///|
pub fn Clusters::default() -> Clusters {
  Clusters::{
    tile_size_x: 0,
    tile_size_y: 0,
    dimensions_x: 0,
    dimensions_y: 0,
    dimensions_z: 0,
    near: 0.0,
    far: 0.0,
    clusterable_objects: [],
  }
}

///|
pub struct VisibleClusterableObjects {
  point_and_spot_lights : Int
  reflection_probes : Int
  irradiance_volumes : Int
  decals : Int
} derive(Eq, Debug)

///|
pub fn VisibleClusterableObjects::default() -> VisibleClusterableObjects {
  VisibleClusterableObjects::{
    point_and_spot_lights: 0,
    reflection_probes: 0,
    irradiance_volumes: 0,
    decals: 0,
  }
}

///|
let ecs_key_global_cluster_settings : @ecs.ResourceKey[GlobalClusterSettings] = @ecs.register_resource(
  debug_name="light.cluster.global_settings",
)

///|
let ecs_key_cluster_config : @ecs.ComponentKey[ClusterConfig] = @ecs.register_component(
  debug_name="light.cluster.config",
)

///|
let ecs_key_clusters : @ecs.ComponentKey[Clusters] = @ecs.register_component(
  debug_name="light.cluster.clusters",
)

///|
let ecs_key_visible_clusterable_objects : @ecs.ComponentKey[
  VisibleClusterableObjects,
] = @ecs.register_component(
  debug_name="light.cluster.visible_clusterable_objects",
)

///|
pub impl @app.Resource for GlobalClusterSettings with resource() {
  ecs_key_global_cluster_settings
}

///|
pub impl @ecs.Component for ClusterConfig with component() {
  ecs_key_cluster_config
}

///|
pub impl @ecs.Component for Clusters with component() {
  ecs_key_clusters
}

///|
pub impl @ecs.Component for VisibleClusterableObjects with component() {
  ecs_key_visible_clusterable_objects
}

///|
pub impl @app.PluginReplacement for ClusterLightPlugin with replacement_id(
  _self,
) {
  CLUSTER_LIGHT_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for ClusterLightPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    cluster_light_plugin_with(app, self)
  }
}

///|
pub fn cluster_light_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  cluster_light_plugin_with(app, ClusterLightPlugin::default())
}

///|
pub fn cluster_light_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : ClusterLightPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { GlobalClusterSettings::default() })
  .add_plugin(cluster_assign_lights)
}
