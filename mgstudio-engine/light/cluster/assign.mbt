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
pub fn cluster_assign_lights(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.add_system(cluster_assign_lights_system)
}

///|
pub fn cluster_assign_lights_system(world : @ecs.World) -> Unit {
  let point_light_count = world.component_count(@light.ecs_key_point_light)
  let spot_light_count = world.component_count(@light.ecs_key_spot_light)
  let total = point_light_count + spot_light_count
  world.for_each_component(VisibleClusterableObjects::component(), fn(
    entity,
    visible,
  ) {
    let next = VisibleClusterableObjects::{
      ..visible,
      point_and_spot_lights: total,
    }
    if next != visible {
      try! world.set_by_key(
        entity,
        VisibleClusterableObjects::component(),
        next,
      )
    }
  })
}
