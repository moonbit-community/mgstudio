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
const CLUSTER_LIGHT_PLUGIN_NAME : String = "mgstudio.light.cluster.ClusterLightPlugin"

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
  // Bevy default shape:
  // - total clusters: 4096
  // - z slices: 24
  // - dynamic resizing enabled
  FixedZ(4096, 24, ClusterZConfig::default(), true)
}

///|
fn cluster_config_positive(value : Int, fallback : Int) -> Int {
  if value <= 0 {
    fallback
  } else {
    value
  }
}

///|
fn cluster_config_requested_dimensions_for_screen_size(
  config : ClusterConfig,
  screen_width : Int,
  screen_height : Int,
) -> (Int, Int, Int) {
  match config {
    None => (0, 0, 0)
    Single => (1, 1, 1)
    XYZ(x, y, z, _, _) => (
      cluster_config_positive(x, 1),
      cluster_config_positive(y, 1),
      cluster_config_positive(z, 1),
    )
    // Bevy `FixedZ { total, z_slices, .. }` shape:
    // derive XY from total-per-layer and screen aspect ratio.
    FixedZ(total, z_slices, _, _) => {
      let safe_total = cluster_config_positive(total, 1)
      let safe_z_slices = cluster_config_positive(z_slices, 1)
      let resolved_z_slices = if safe_total < safe_z_slices {
        safe_total
      } else {
        safe_z_slices
      }
      let safe_width = cluster_config_positive(screen_width, 1)
      let safe_height = cluster_config_positive(screen_height, 1)
      let aspect_ratio = Float::from_double(safe_width.to_double()) /
        Float::from_double(safe_height.to_double())
      let per_layer = Float::from_double(safe_total.to_double()) /
        Float::from_double(resolved_z_slices.to_double())
      let y_estimate = @math.sqrt(per_layer / aspect_ratio)
      let mut x = (y_estimate * aspect_ratio).to_int()
      let mut y = y_estimate.to_int()

      if x <= 0 {
        x = 1
        y = cluster_config_positive(per_layer.to_int(), 1)
      }
      if y <= 0 {
        y = 1
        x = cluster_config_positive(per_layer.to_int(), 1)
      }
      (x, y, resolved_z_slices)
    }
  }
}

///|
pub fn cluster_config_first_slice_depth(config : ClusterConfig) -> Float {
  match config {
    None => 0.0F
    Single => 0.0F
    XYZ(_, _, _, z_config, _) => z_config.first_slice_depth
    FixedZ(_, _, z_config, _) => z_config.first_slice_depth
  }
}

///|
pub fn cluster_config_far_z_mode(config : ClusterConfig) -> ClusterFarZMode {
  match config {
    None => ClusterFarZMode::Constant(0.0F)
    Single => ClusterFarZMode::MaxClusterableObjectRange
    XYZ(_, _, _, z_config, _) => z_config.far_z_mode
    FixedZ(_, _, z_config, _) => z_config.far_z_mode
  }
}

///|
pub fn cluster_config_dynamic_resizing(config : ClusterConfig) -> Bool {
  match config {
    None => false
    Single => false
    XYZ(_, _, _, _, dynamic_resizing) => dynamic_resizing
    FixedZ(_, _, _, dynamic_resizing) => dynamic_resizing
  }
}

///|
pub fn cluster_config_dimensions_for_screen_size(
  config : ClusterConfig,
  screen_width : Int,
  screen_height : Int,
) -> (Int, Int, Int) {
  let (requested_x, requested_y, requested_z) =
    cluster_config_requested_dimensions_for_screen_size(
      config,
      screen_width,
      screen_height,
    )
  if requested_x <= 0 || requested_y <= 0 || requested_z <= 0 {
    return (0, 0, 0)
  }
  let safe_width = cluster_config_positive(screen_width, 1)
  let safe_height = cluster_config_positive(screen_height, 1)

  // Align with Bevy's `Clusters::update` behavior:
  // tile size is rounded up, then realized dimensions are rounded down.
  let tile_size_x = cluster_config_positive(
    @math_core.ceil(
      safe_width.to_double() / requested_x.to_double(),
    ).to_int(),
    1,
  )
  let tile_size_y = cluster_config_positive(
    @math_core.ceil(
      safe_height.to_double() / requested_y.to_double(),
    ).to_int(),
    1,
  )
  let dimensions_x = cluster_config_positive(
    (Float::from_double(safe_width.to_double()) /
      Float::from_double(tile_size_x.to_double())).to_int(),
    1,
  )
  let dimensions_y = cluster_config_positive(
    (Float::from_double(safe_height.to_double()) /
      Float::from_double(tile_size_y.to_double())).to_int(),
    1,
  )
  (dimensions_x, dimensions_y, requested_z)
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
  clusterables : Array[@core.Entity]
  mut counts : ClusterableObjectCounts
} derive(Eq, Debug)

///|
pub fn ObjectsInCluster::default() -> ObjectsInCluster {
  ObjectsInCluster::{ clusterables: [], counts: ClusterableObjectCounts::default() }
}

///|
pub fn ObjectsInCluster::clear(self : ObjectsInCluster) -> Unit {
  self.clusterables.clear()
  self.counts = ClusterableObjectCounts::default()
}

///|
pub fn ObjectsInCluster::add_point_light(
  self : ObjectsInCluster,
  entity : @core.Entity,
) -> Unit {
  self.clusterables.push(entity)
  self.counts = ClusterableObjectCounts::{
    ..self.counts,
    point_lights: self.counts.point_lights + 1,
  }
}

///|
pub fn ObjectsInCluster::add_spot_light(
  self : ObjectsInCluster,
  entity : @core.Entity,
) -> Unit {
  self.clusterables.push(entity)
  self.counts = ClusterableObjectCounts::{
    ..self.counts,
    spot_lights: self.counts.spot_lights + 1,
  }
}

///|
pub fn ObjectsInCluster::add_reflection_probe(
  self : ObjectsInCluster,
  entity : @core.Entity,
) -> Unit {
  self.clusterables.push(entity)
  self.counts = ClusterableObjectCounts::{
    ..self.counts,
    reflection_probes: self.counts.reflection_probes + 1,
  }
}

///|
pub fn ObjectsInCluster::add_irradiance_volume(
  self : ObjectsInCluster,
  entity : @core.Entity,
) -> Unit {
  self.clusterables.push(entity)
  self.counts = ClusterableObjectCounts::{
    ..self.counts,
    irradiance_volumes: self.counts.irradiance_volumes + 1,
  }
}

///|
pub fn ObjectsInCluster::add_decal(
  self : ObjectsInCluster,
  entity : @core.Entity,
) -> Unit {
  self.clusterables.push(entity)
  self.counts = ClusterableObjectCounts::{
    ..self.counts,
    decals: self.counts.decals + 1,
  }
}

///|
pub fn ObjectsInCluster::clusterables(
  self : ObjectsInCluster,
) -> Array[@core.Entity] {
  self.clusterables.copy()
}

///|
pub struct Clusters {
  mut tile_size_x : Int
  mut tile_size_y : Int
  mut dimensions_x : Int
  mut dimensions_y : Int
  mut dimensions_z : Int
  mut near : Float
  mut far : Float
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
pub fn Clusters::new(
  tile_size_x : Int,
  tile_size_y : Int,
  dimensions_x : Int,
  dimensions_y : Int,
  dimensions_z : Int,
  near : Float,
  far : Float,
) -> Clusters {
  let safe_dimensions_x = if dimensions_x <= 0 { 0 } else { dimensions_x }
  let safe_dimensions_y = if dimensions_y <= 0 { 0 } else { dimensions_y }
  let safe_dimensions_z = if dimensions_z <= 0 { 0 } else { dimensions_z }
  let cluster_count = safe_dimensions_x * safe_dimensions_y * safe_dimensions_z
  let clusterable_objects : Array[ObjectsInCluster] = []
  for _ in 0..<cluster_count {
    clusterable_objects.push(ObjectsInCluster::default())
  }
  Clusters::{
    tile_size_x: if tile_size_x <= 0 { 0 } else { tile_size_x },
    tile_size_y: if tile_size_y <= 0 { 0 } else { tile_size_y },
    dimensions_x: safe_dimensions_x,
    dimensions_y: safe_dimensions_y,
    dimensions_z: safe_dimensions_z,
    near,
    far,
    clusterable_objects,
  }
}

///|
pub fn Clusters::clear(self : Clusters) -> Unit {
  self.tile_size_x = 1
  self.tile_size_y = 1
  self.dimensions_x = 0
  self.dimensions_y = 0
  self.dimensions_z = 0
  self.near = 0.0F
  self.far = 0.0F
  self.clusterable_objects.clear()
}

///|
pub fn Clusters::update(
  self : Clusters,
  screen_width : Int,
  screen_height : Int,
  requested_dimensions_x : Int,
  requested_dimensions_y : Int,
  requested_dimensions_z : Int,
) -> Unit {
  let safe_screen_width = if screen_width <= 0 { 1 } else { screen_width }
  let safe_screen_height = if screen_height <= 0 { 1 } else { screen_height }
  let safe_requested_x = if requested_dimensions_x <= 0 {
    1
  } else {
    requested_dimensions_x
  }
  let safe_requested_y = if requested_dimensions_y <= 0 {
    1
  } else {
    requested_dimensions_y
  }
  let safe_requested_z = if requested_dimensions_z <= 0 {
    1
  } else {
    requested_dimensions_z
  }
  let tile_size_x = @math_core.ceil(
    safe_screen_width.to_double() / safe_requested_x.to_double(),
  ).to_int()
  let tile_size_y = @math_core.ceil(
    safe_screen_height.to_double() / safe_requested_y.to_double(),
  ).to_int()
  let safe_tile_size_x = if tile_size_x <= 0 { 1 } else { tile_size_x }
  let safe_tile_size_y = if tile_size_y <= 0 { 1 } else { tile_size_y }
  let dimensions_x = @math_core.ceil(
    safe_screen_width.to_double() / safe_tile_size_x.to_double(),
  ).to_int()
  let dimensions_y = @math_core.ceil(
    safe_screen_height.to_double() / safe_tile_size_y.to_double(),
  ).to_int()
  let safe_dimensions_x = if dimensions_x <= 0 { 1 } else { dimensions_x }
  let safe_dimensions_y = if dimensions_y <= 0 { 1 } else { dimensions_y }
  self.tile_size_x = safe_tile_size_x
  self.tile_size_y = safe_tile_size_y
  self.dimensions_x = safe_dimensions_x
  self.dimensions_y = safe_dimensions_y
  self.dimensions_z = safe_requested_z
}

///|
pub struct VisibleClusterableObjects {
  point_and_spot_lights : Array[@core.Entity]
  reflection_probes : Array[@core.Entity]
  irradiance_volumes : Array[@core.Entity]
  decals : Array[@core.Entity]
} derive(Eq, Debug)

///|
pub fn VisibleClusterableObjects::default() -> VisibleClusterableObjects {
  VisibleClusterableObjects::{
    point_and_spot_lights: [],
    reflection_probes: [],
    irradiance_volumes: [],
    decals: [],
  }
}

///|
pub fn VisibleClusterableObjects::new() -> VisibleClusterableObjects {
  VisibleClusterableObjects::default()
}

///|
pub fn VisibleClusterableObjects::from_lists(
  point_and_spot_lights : Array[@core.Entity],
  reflection_probes : Array[@core.Entity],
  irradiance_volumes : Array[@core.Entity],
  decals : Array[@core.Entity],
) -> VisibleClusterableObjects {
  VisibleClusterableObjects::{
    point_and_spot_lights: point_and_spot_lights.copy(),
    reflection_probes: reflection_probes.copy(),
    irradiance_volumes: irradiance_volumes.copy(),
    decals: decals.copy(),
  }
}

///|
pub fn VisibleClusterableObjects::point_and_spot_entities(
  self : VisibleClusterableObjects,
) -> Array[@core.Entity] {
  self.point_and_spot_lights.copy()
}

///|
pub fn VisibleClusterableObjects::reflection_probe_entities(
  self : VisibleClusterableObjects,
) -> Array[@core.Entity] {
  self.reflection_probes.copy()
}

///|
pub fn VisibleClusterableObjects::irradiance_volume_entities(
  self : VisibleClusterableObjects,
) -> Array[@core.Entity] {
  self.irradiance_volumes.copy()
}

///|
pub fn VisibleClusterableObjects::decal_entities(
  self : VisibleClusterableObjects,
) -> Array[@core.Entity] {
  self.decals.copy()
}

///|
pub fn VisibleClusterableObjects::clear(
  self : VisibleClusterableObjects,
) -> Unit {
  self.point_and_spot_lights.clear()
  self.reflection_probes.clear()
  self.irradiance_volumes.clear()
  self.decals.clear()
}

///|
pub fn VisibleClusterableObjects::add(
  self : VisibleClusterableObjects,
  entity : @core.Entity,
  object_type : ClusterableObjectType,
) -> Unit {
  match object_type {
    ClusterableObjectType::PointLight(_, _) =>
      self.point_and_spot_lights.push(entity)
    ClusterableObjectType::SpotLight(_, _, _) =>
      self.point_and_spot_lights.push(entity)
    ClusterableObjectType::ReflectionProbe =>
      self.reflection_probes.push(entity)
    ClusterableObjectType::IrradianceVolume =>
      self.irradiance_volumes.push(entity)
    ClusterableObjectType::Decal => ()
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
pub impl @app.PluginReplacement for ClusterLightPlugin with plugin_name(_self) {
  CLUSTER_LIGHT_PLUGIN_NAME
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
