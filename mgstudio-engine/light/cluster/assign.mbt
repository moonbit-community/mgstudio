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
pub(all) enum ClusterableObjectType {
  PointLight(Bool, Bool)
  SpotLight(Bool, Bool, Float)
  ReflectionProbe
  IrradianceVolume
  Decal
} derive(Eq, Debug)

///|
pub fn ClusterableObjectType::ordering(
  self : ClusterableObjectType,
) -> (Int, Bool, Bool) {
  match self {
    PointLight(shadow_maps_enabled, volumetric) =>
      (0, !shadow_maps_enabled, !volumetric)
    SpotLight(shadow_maps_enabled, volumetric, _outer_angle) =>
      (1, !shadow_maps_enabled, !volumetric)
    ReflectionProbe => (2, false, false)
    IrradianceVolume => (3, false, false)
    Decal => (4, false, false)
  }
}

///|
pub fn calculate_cluster_factors(
  near : Float,
  far : Float,
  z_slices : Float,
  is_orthographic : Bool,
) -> @math.Vec2 {
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let safe_far = if far <= safe_near { safe_near + 0.0001F } else { far }
  let safe_slices = if z_slices <= 1.0F { 1.0F } else { z_slices }
  if is_orthographic {
    let denominator = -safe_far - -safe_near
    let slope = if denominator.abs() <= 1.0e-6F {
      0.0F
    } else {
      safe_slices / denominator
    }
    @math.Vec2::new(-safe_near, slope)
  } else {
    let ln_far_over_near = Float::from_double(
      @math_core.ln((safe_far / safe_near).to_double()),
    )
    if ln_far_over_near.abs() <= 1.0e-6F {
      @math.Vec2::new(0.0F, 0.0F)
    } else {
      let z_slices_of_ln_zfar_over_znear = (safe_slices - 1.0F) /
        ln_far_over_near
      @math.Vec2::new(
        z_slices_of_ln_zfar_over_znear,
        Float::from_double(@math_core.ln(safe_near.to_double())) *
        z_slices_of_ln_zfar_over_znear,
      )
    }
  }
}

///|
pub fn cluster_assign_lights(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.add_system(cluster_assign_lights_system)
}

///|
fn cluster_assign_tile_size(
  screen_size : Int,
  cluster_dimension : Int,
) -> Int {
  if screen_size <= 0 || cluster_dimension <= 0 {
    return 0
  }
  let raw = @math_core.ceil(screen_size.to_double() / cluster_dimension.to_double())
  let as_int = raw.to_int()
  if as_int <= 0 {
    1
  } else {
    as_int
  }
}

///|
fn cluster_assign_viewport_size(camera : @sprite.Camera) -> (Int, Int) {
  match camera.physical_viewport_size() {
    Some(viewport_size) => {
      let width = if viewport_size.x <= 0 { 1 } else { viewport_size.x }
      let height = if viewport_size.y <= 0 { 1 } else { viewport_size.y }
      (width, height)
    }
    None => (1280, 720)
  }
}

///|
fn cluster_assign_max_clusterable_object_range(world : @ecs.World) -> Float {
  let max_range_ref : Ref[Float] = Ref::new(0.0F)
  world.for_each_component(@light.ecs_key_point_light, fn(_entity, light) {
    if light.range > max_range_ref.val {
      max_range_ref.val = light.range
    }
  })
  world.for_each_component(@light.ecs_key_spot_light, fn(_entity, light) {
    if light.range > max_range_ref.val {
      max_range_ref.val = light.range
    }
  })
  max_range_ref.val
}

///|
fn cluster_assign_cluster_far(
  config : ClusterConfig,
  max_clusterable_object_range : Float,
) -> Float {
  match cluster_config_far_z_mode(config) {
    ClusterFarZMode::MaxClusterableObjectRange => max_clusterable_object_range
    ClusterFarZMode::Constant(value) => value
  }
}

///|
fn cluster_assign_cluster_objects(cluster_count : Int) -> Array[ObjectsInCluster] {
  let objects : Array[ObjectsInCluster] = []
  if cluster_count <= 0 {
    return objects
  }
  for _ in 0..<cluster_count {
    objects.push(ObjectsInCluster::default())
  }
  objects
}

///|
pub fn cluster_assign_lights_system(world : @ecs.World) -> Unit {
  let point_light_count = world.component_count(@light.ecs_key_point_light)
  let spot_light_count = world.component_count(@light.ecs_key_spot_light)
  let total = point_light_count + spot_light_count
  let max_clusterable_object_range = cluster_assign_max_clusterable_object_range(
    world,
  )
  let camera_entities = []
  world.for_each_component(@sprite.ecs_key_camera, fn(entity, _camera) {
    camera_entities.push(entity)
  })
  for entity in camera_entities {
    let config = match (try! world.get_by_key(entity, ClusterConfig::component())) {
      Some(cluster_config) => cluster_config
      None => ClusterConfig::default()
    }
    let camera = match (try! world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(camera_component) => camera_component
      None => continue
    }
    let (screen_width, screen_height) = cluster_assign_viewport_size(camera)
    let (dimensions_x, dimensions_y, dimensions_z) =
      cluster_config_dimensions_for_screen_size(config, screen_width, screen_height)
    let tile_size_x = cluster_assign_tile_size(screen_width, dimensions_x)
    let tile_size_y = cluster_assign_tile_size(screen_height, dimensions_y)
    let cluster_count = dimensions_x * dimensions_y * dimensions_z
    let clusters = Clusters::{
      tile_size_x,
      tile_size_y,
      dimensions_x,
      dimensions_y,
      dimensions_z,
      near: cluster_config_first_slice_depth(config),
      far: cluster_assign_cluster_far(config, max_clusterable_object_range),
      clusterable_objects: cluster_assign_cluster_objects(cluster_count),
    }
    let visible = VisibleClusterableObjects::{
      point_and_spot_lights: total,
      reflection_probes: 0,
      irradiance_volumes: 0,
      decals: 0,
    }
    try! world.set_by_key(entity, Clusters::component(), clusters)
    try! world.set_by_key(entity, VisibleClusterableObjects::component(), visible)
  }

  // Keep previously-created non-camera entries in sync for compatibility paths.
  world.for_each_component(VisibleClusterableObjects::component(), fn(entity, existing) {
    if (try! world.contains_by_key(entity, @sprite.ecs_key_camera)) {
      return
    }
    let next = VisibleClusterableObjects::{
      ..existing,
      point_and_spot_lights: total,
    }
    if next != existing {
      try! world.set_by_key(
        entity,
        VisibleClusterableObjects::component(),
        next,
      )
    }
  })
}
