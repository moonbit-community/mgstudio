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
// Bevy source: `bevy/crates/bevy_light/src/cascade.rs`.

///|
pub type CascadeConfig = CascadeShadowConfig

///|
pub type CascadeConfigBuilder = CascadeShadowConfigBuilder

///|
pub type DirectionalShadowMapResource = DirectionalLightShadowMap

///|
pub let ecs_key_directional_shadow_map_resource : @ecs.ResourceKey[
  DirectionalShadowMapResource,
] = ecs_key_directional_light_shadow_map

///|
pub fn directional_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalShadowMapResource] {
  get_directional_light_shadow_map_resource(world)
}

///|
type DirectionalLightCascadeView = (
  @core.Entity,
  @camera_projection3d.Projection,
  @math.Mat4,
)

///|
fn collect_directional_light_cascade_views(
  world : @ecs.World,
) -> Array[DirectionalLightCascadeView] {
  let views : Array[DirectionalLightCascadeView] = []
  world.for_each_component(@camera_camera.ecs_key_camera, fn(entity, camera) {
    if !camera.is_active {
      return
    }
    match
      (
        try! world.get_by_key(entity, @camera_projection3d.ecs_key_projection),
        try! world.get_by_key(entity, @transform.ecs_key_global_transform),
      ) {
      (Some(projection), Some(global_transform)) =>
        views.push(
          (
            entity,
            projection,
            @math.Mat4::from_affine3(global_transform.affine()),
          ),
        )
      _ => ()
    }
  })
  views
}

///|
fn build_directional_light_cascades_for_light(
  views : Array[DirectionalLightCascadeView],
  shadow_map_size : Float,
  light_transform : @transform.GlobalTransform,
  config : CascadeShadowConfig,
  cascades : Cascades,
) -> Cascades {
  cascades.clear()
  let (_scale, rotation, _translation) = light_transform.to_scale_rotation_translation()
  let world_from_light = @math.Mat4::from_quat(rotation)
  let light_from_world = world_from_light.transpose()
  for view in views {
    let (view_entity, projection, world_from_view) = view
    let light_from_camera = light_from_world.mul(world_from_view)
    let overlap_factor = 1.0F - config.overlap_proportion
    let view_cascades : Array[Cascade] = []
    let mut near_bound = config.minimum_distance
    for far_bound in config.bounds {
      view_cascades.push(
        calculate_directional_light_cascade(
          projection.get_frustum_corners(-near_bound, -far_bound),
          shadow_map_size,
          world_from_light,
          light_from_camera,
        ),
      )
      near_bound = overlap_factor * far_bound
    }
    cascades.set(view_entity, view_cascades)
  }
  cascades
}

///|
// Bevy source: `bevy/crates/bevy_light/src/cascade.rs::build_directional_light_cascades`.
pub fn build_directional_light_cascades(world : @ecs.World) -> Unit {
  let shadow_map = match
    world.get_resource(ecs_key_directional_light_shadow_map) {
    Some(resource) => resource
    None => return
  }
  let shadow_map_size = Float::from_double(shadow_map.size.to_double())
  let views = collect_directional_light_cascade_views(world)
  world.for_each_component(ecs_key_directional_light, fn(entity, light) {
    if !light.shadow_maps_enabled {
      return
    }
    match
      (
        try! world.get_by_key(entity, @transform.ecs_key_global_transform),
        try! world.get_by_key(entity, ecs_key_cascade_shadow_config),
        try! world.get_by_key(entity, ecs_key_cascades),
      ) {
      (Some(transform), Some(config), Some(cascades)) =>
        try! world.set_by_key(
          entity,
          ecs_key_cascades,
          build_directional_light_cascades_for_light(
            views, shadow_map_size, transform, config, cascades,
          ),
        )
      _ => ()
    }
  })
}
