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
fn mixed_lighting_test_app() -> @app.App[@ecs.World] {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[LightingMode],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(
    @pbr.GlobalAmbientLight::new(
      @camera_clear_color.ClearColor::ClearColor().color,
      10000.0F,
    ).with_affects_lightmapped_meshes(true),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_message(lighting_mode_changed_message_key)
  .add_systems_param3(Startup, setup)
  .add_systems(
    Update,
    @app.system_config_param6(update_lightmaps).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems(
    Update,
    @app.system_config_param3(update_directional_light).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param2(Update, make_sphere_nonpickable)
  .add_systems_param3(Update, update_radio_buttons)
  .add_systems_param3(Update, handle_lighting_mode_change)
  .add_systems_param2(Update, handle_widget_interactions)
  .add_systems(
    Update,
    @app.system_config_param3(reset_sphere_position).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param4(Update, move_sphere)
  .add_systems(
    Update,
    @app.system_config_param3(adjust_help_text).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
}

///|
test "mixed_lighting: scene-ready event installs lightmaps and dynamic light state" {
  let mut app = mixed_lighting_test_app()
  for _ in 0..<180 {
    app = app.run_once()
  }
  let mesh_names : Array[String] = []
  let lightmapped_meshes : Array[String] = []
  let visible_lightmapped_meshes : Array[String] = []
  let lightmapped_meshes_with_uv1 : Array[String] = []
  let realtime_directional_lights = Ref(0)
  let ignored_pickable_spheres = Ref(0)
  let world = app.world()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  guard world.get_resource(mesh_assets_key) is Some(mesh_assets) else {
    abort("expected mesh assets")
  }
  world.for_each_component(@gltf.GltfMeshName::component(), fn(entity, name) {
    mesh_names.push(name.as_str())
    if (try! world.contains_by_key(entity, @pbr.ecs_key_lightmap)) {
      lightmapped_meshes.push(name.as_str())
      match (try! world.get_by_key(entity, @mesh.ecs_key_mesh3d)) {
        Some(mesh3d) =>
          match mesh_assets.get(mesh3d.mesh()) {
            Some(mesh_asset) =>
              match mesh_asset.as_3d_geometry() {
                Some(geometry) =>
                  if geometry.has_uv1s() {
                    lightmapped_meshes_with_uv1.push(name.as_str())
                  }
                None => ()
              }
            None => ()
          }
        None => ()
      }
      match
        (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
        Some(visibility) =>
          if visibility.is_visible() {
            visible_lightmapped_meshes.push(name.as_str())
          }
        None => ()
      }
    }
    if name.as_str() == "Sphere" &&
      (try! world.contains_by_key(entity, @picking.Pickable::component())) {
      ignored_pickable_spheres.val = ignored_pickable_spheres.val + 1
    }
  })
  world.for_each_component(@pbr.DirectionalLight::component(), fn(
    _entity,
    light,
  ) {
    if light.affects_lightmapped_mesh_diffuse && light.shadow_maps_enabled {
      realtime_directional_lights.val = realtime_directional_lights.val + 1
    }
  })
  debug_inspect(mesh_names.length(), content="6")
  debug_inspect(lightmapped_meshes.length(), content="5")
  debug_inspect(lightmapped_meshes_with_uv1.length(), content="5")
  debug_inspect(visible_lightmapped_meshes.length(), content="5")
  debug_inspect(realtime_directional_lights.val, content="1")
  debug_inspect(ignored_pickable_spheres.val, content="1")
}
