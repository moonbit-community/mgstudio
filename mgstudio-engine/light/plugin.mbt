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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`.

///|
const LIGHT_PLUGIN_NAME : String = "mgstudio.light.LightPlugin"

///|
pub struct LightPlugin {}

///|
pub fn LightPlugin::LightPlugin() -> LightPlugin {
  LightPlugin::{  }
}

///|
// Bevy source: `bevy_camera::visibility::add_visibility_class::<ClusterVisibilityClass>`.
fn add_cluster_visibility_class(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  let entity = context.entity()
  let class_id = cluster_visibility_class_id()
  match
    (world.get_by_key(entity, @visibility.ecs_key_visibility_class) catch {
      _ => None
    }) {
    Some(visibility_class) => {
      visibility_class.add(class_id)
      ignore(
        try! world.replace_by_key(
          entity, @visibility.ecs_key_visibility_class, visibility_class,
        ),
      )
    }
    None =>
      try! world.set_by_key(
        entity,
        @visibility.ecs_key_visibility_class,
        @visibility.VisibilityClass::single(class_id),
      )
  }
}

///|
fn register_light_component_hooks(world : @ecs.World) -> Unit {
  ignore(
    world
    .register_component_hooks_for_key(ecs_key_point_light)
    .on_add(add_cluster_visibility_class) catch {
      _ => abort("failed to register point light visibility class hook")
    },
  )
  ignore(
    world
    .register_component_hooks_for_key(ecs_key_spot_light)
    .on_add(add_cluster_visibility_class) catch {
      _ => abort("failed to register spot light visibility class hook")
    },
  )
  ignore(
    world
    .register_component_hooks_for_key(ecs_key_directional_light)
    .on_add(add_cluster_visibility_class) catch {
      _ => abort("failed to register directional light visibility class hook")
    },
  )
  ignore(
    world
    .register_component_hooks_for_key(ecs_key_light_probe)
    .on_add(add_cluster_visibility_class) catch {
      _ => abort("failed to register light probe visibility class hook")
    },
  )
}

///|
// Bevy source: `bevy/crates/bevy_light/src/{point_light,spot_light,directional_light,rect_light,probe}.rs`.
fn register_light_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_point_light,
    @camera_primitives.ecs_key_cubemap_frusta,
    fn() { @camera_primitives.CubemapFrusta::CubemapFrusta() },
  )
  world.register_required_components_with(
    ecs_key_point_light,
    @camera_visibility.ecs_key_cubemap_visible_entities,
    fn() { @camera_visibility.CubemapVisibleEntities::CubemapVisibleEntities() },
  )
  world.register_required_components_with(
    ecs_key_point_light,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_point_light,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_point_light,
    @visibility.ecs_key_visibility_class,
    fn() { @visibility.VisibilityClass::VisibilityClass() },
  )
  world.register_required_components_with(
    ecs_key_spot_light,
    @camera_primitives.ecs_key_frustum,
    fn() { @camera_primitives.Frustum::Frustum() },
  )
  world.register_required_components_with(
    ecs_key_spot_light,
    @camera_visibility.ecs_key_visible_mesh_entities,
    fn() { @camera_visibility.VisibleMeshEntities::VisibleMeshEntities() },
  )
  world.register_required_components_with(
    ecs_key_spot_light,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_spot_light,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_spot_light,
    @visibility.ecs_key_visibility_class,
    fn() { @visibility.VisibilityClass::VisibilityClass() },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    ecs_key_cascades,
    fn() { Cascades::Cascades() },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    @camera_primitives.ecs_key_cascades_frusta,
    fn() { @camera_primitives.CascadesFrusta::CascadesFrusta() },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    ecs_key_cascade_shadow_config,
    fn() { CascadeShadowConfig::CascadeShadowConfig() },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    @camera_visibility.ecs_key_cascades_visible_entities,
    fn() {
      @camera_visibility.CascadesVisibleEntities::CascadesVisibleEntities()
    },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_directional_light,
    @visibility.ecs_key_visibility_class,
    fn() { @visibility.VisibilityClass::VisibilityClass() },
  )
  world.register_required_components_with(
    ecs_key_point_light_texture,
    ecs_key_point_light,
    fn() { PointLight::PointLight() },
  )
  world.register_required_components_with(
    ecs_key_spot_light_texture,
    ecs_key_spot_light,
    fn() { SpotLight::SpotLight() },
  )
  world.register_required_components_with(
    ecs_key_directional_light_texture,
    ecs_key_directional_light,
    fn() { DirectionalLight::DirectionalLight() },
  )
  world.register_required_components_with(
    ecs_key_sun_disk,
    ecs_key_directional_light,
    fn() { DirectionalLight::DirectionalLight() },
  )
  world.register_required_components_with(
    ecs_key_rect_light,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_rect_light,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_rect_light,
    @visibility.ecs_key_visibility_class,
    fn() { @visibility.VisibilityClass::VisibilityClass() },
  )
  world.register_required_components_with(
    ecs_key_ambient_light,
    @camera_camera.ecs_key_camera,
    fn() { @camera_camera.Camera::Camera() },
  )
  world.register_required_components_with(
    ecs_key_light_probe,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_light_probe,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_light_probe,
    @visibility.ecs_key_view_visibility,
    fn() { @visibility.ViewVisibility::new(true) },
  )
  world.register_required_components_with(
    ecs_key_light_probe,
    @visibility.ecs_key_visibility_class,
    fn() { @visibility.VisibilityClass::VisibilityClass() },
  )
  world.register_required_components_with(
    ecs_key_irradiance_volume,
    ecs_key_light_probe,
    fn() { LightProbe::LightProbe() },
  )
}

///|
pub impl @app.Plugin for LightPlugin with fn name(_self) {
  LIGHT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LightPlugin with fn build(_self, app) {
  light_plugin(app)
}

///|
pub fn light_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  register_light_component_hooks(app.world())
  try! register_light_required_components(app.world())
  let mut next = @asset.init_asset(app, fn() {
    ScatteringMedium::ScatteringMedium()
  })
  if !next.contains_resource(ecs_key_global_ambient_light) {
    next = next.insert_world_resource(
      ecs_key_global_ambient_light,
      GlobalAmbientLight::GlobalAmbientLight(),
    )
  }
  if !next.contains_resource(ecs_key_point_light_shadow_map) {
    next = next.insert_world_resource(
      ecs_key_point_light_shadow_map,
      PointLightShadowMap::PointLightShadowMap(),
    )
  }
  if !next.contains_resource(ecs_key_directional_light_shadow_map) {
    next = next.insert_world_resource(
      ecs_key_directional_light_shadow_map,
      DirectionalLightShadowMap::DirectionalLightShadowMap(),
    )
  }
  next
  .add_systems(
    @app.Update,
    @app.system_config_param2(automatically_add_parallax_correction_components),
  )
  .add_post_update_system_config(
    @app.system(validate_directional_light_shadow_map_size).before(
      simulation_light_set_update_directional_light_cascades,
    ),
  )
  .add_post_update_system_config(
    @app.system(build_directional_light_cascades)
    .after(@transform.transform_set_propagate)
    .in_set(simulation_light_set_update_directional_light_cascades),
  )
  .add_post_update_system_config(
    @app.system(update_point_light_bounding_spheres)
    .after(@transform.transform_set_propagate)
    .in_set(simulation_light_set_update_bounds),
  )
  .add_post_update_system_config(
    @app.system(update_spot_light_bounding_spheres)
    .after(@transform.transform_set_propagate)
    .in_set(simulation_light_set_update_bounds),
  )
  .add_post_update_system_config(
    @app.system(update_directional_light_frusta)
    .after(@transform.transform_set_propagate)
    .after(simulation_light_set_update_directional_light_cascades)
    .in_set(simulation_light_set_update_light_frusta),
  )
  .add_post_update_system_config(
    @app.system(update_point_light_frusta)
    .after(@transform.transform_set_propagate)
    .after(simulation_light_set_assign_lights_to_clusters)
    .in_set(simulation_light_set_update_light_frusta),
  )
  .add_post_update_system_config(
    @app.system(update_spot_light_frusta)
    .after(@transform.transform_set_propagate)
    .after(simulation_light_set_assign_lights_to_clusters)
    .in_set(simulation_light_set_update_light_frusta),
  )
}
