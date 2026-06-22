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
      @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
      10000.0F,
    ).with_affects_lightmapped_meshes(true),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_message(lighting_mode_changed_message_key)
  .add_systems_param3(@app.Startup, setup)
  .add_systems(
    @app.Update,
    @app.system_config_param6(update_lightmaps).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param3(update_directional_light).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param2(@app.Update, make_sphere_nonpickable)
  .add_systems_param3(@app.Update, update_radio_buttons)
  .add_systems_param3(@app.Update, handle_lighting_mode_change)
  .add_systems_param2(@app.Update, handle_widget_interactions)
  .add_systems(
    @app.Update,
    @app.system_config_param3(reset_sphere_position).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param4(@app.Update, move_sphere)
  .add_systems(
    @app.Update,
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
  let realtime_directional_lights = Ref(0)
  let ignored_pickable_spheres = Ref(0)
  let world = app.world()
  world.for_each_component(@gltf.GltfMeshName::component(), fn(entity, name) {
    mesh_names.push(name.as_str())
    if (try! world.contains_by_key(entity, @pbr.ecs_key_lightmap)) {
      lightmapped_meshes.push(name.as_str())
    }
    if name.as_str() == "Sphere" &&
      (try! world.contains_by_key(entity, @picking.Pickable::component())) {
      ignored_pickable_spheres.val = ignored_pickable_spheres.val + 1
    }
  })
  world.for_each_component(@pbr.DirectionalLight::component(), fn(_entity, light) {
    if light.affects_lightmapped_mesh_diffuse && light.shadow_maps_enabled {
      realtime_directional_lights.val = realtime_directional_lights.val + 1
    }
  })
  debug_inspect(mesh_names.length(), content="6")
  debug_inspect(lightmapped_meshes.length(), content="5")
  debug_inspect(realtime_directional_lights.val, content="1")
  debug_inspect(ignored_pickable_spheres.val, content="1")
}
