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
// Bevy source: `bevy/crates/bevy_pbr/src/lib.rs::PbrPlugin::build`.

///|
priv struct PbrRenderStartupSystemsInstalled {}

///|
let ecs_key_pbr_render_startup_systems_installed : @ecs.ResourceKey[
  PbrRenderStartupSystemsInstalled,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PbrRenderStartupSystemsInstalled",
)

///|
priv struct PbrRenderExtractSystemsInstalled {}

///|
let ecs_key_pbr_render_extract_systems_installed : @ecs.ResourceKey[
  PbrRenderExtractSystemsInstalled,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PbrRenderExtractSystemsInstalled",
)

///|
priv struct PbrRenderLightViewObserversInstalled {}

///|
let ecs_key_pbr_render_light_view_observers_installed : @ecs.ResourceKey[
  PbrRenderLightViewObserversInstalled,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PbrRenderLightViewObserversInstalled",
)

///|
priv struct PbrRenderPrepareSystemsInstalled {}

///|
let ecs_key_pbr_render_prepare_systems_installed : @ecs.ResourceKey[
  PbrRenderPrepareSystemsInstalled,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PbrRenderPrepareSystemsInstalled",
)

///|
pub fn configure_pbr_render_startup_systems(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  if sub_app
    .world()
    .resource(ecs_key_pbr_render_startup_systems_installed)
    .is_present() {
    return sub_app
  }
  let marker = PbrRenderStartupSystemsInstalled::{  }
  sub_app
  .world()
  .insert_resource(ecs_key_pbr_render_startup_systems_installed, marker)
  sub_app
  .add_systems(
    @render.render_startup_schedule_stage(),
    @app.system(@pbr_render.init_shadow_samplers).named(
      "mgstudio_pbr::init_shadow_samplers",
    ),
  )
  .add_systems(
    @render.render_startup_schedule_stage(),
    @app.system(init_global_clusterable_object_meta).named(
      "mgstudio_pbr::init_global_clusterable_object_meta",
    ),
  )
  .add_systems(
    @render.render_startup_schedule_stage(),
    @app.system(init_fallback_bindless_resources).named(
      "mgstudio_pbr::init_fallback_bindless_resources",
    ),
  )
}

///|
pub fn configure_pbr_render_light_view_observers(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  if sub_app
    .world()
    .resource(ecs_key_pbr_render_light_view_observers_installed)
    .is_present() {
    return sub_app
  }
  sub_app
  .world()
  .insert_resource(ecs_key_pbr_render_light_view_observers_installed, PbrRenderLightViewObserversInstalled::{

  })
  ignore(
    sub_app
    .world()
    .add_add_component_observer(@pbr_render.add_light_view_entities),
  )
  ignore(
    sub_app
    .world()
    .add_remove_component_observer(@pbr_render.remove_light_view_entities),
  )
  ignore(
    sub_app
    .world()
    .add_remove_component_observer(
      @pbr_render.remove_point_and_spot_light_view_entities,
    ),
  )
  sub_app
}

///|
fn configure_pbr_render_prepare_systems(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  if sub_app
    .world()
    .resource(ecs_key_pbr_render_prepare_systems_installed)
    .is_present() {
    return sub_app
  }
  sub_app
  .world()
  .insert_resource(ecs_key_pbr_render_prepare_systems_installed, PbrRenderPrepareSystemsInstalled::{

  })
  sub_app.add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_lights)
    .named("mgstudio_pbr::prepare_lights")
    .after(@core_pipeline.core_pipeline_camera_driver_set)
    .in_set(@render.render_system_set_create_views),
  )
}

///|
fn[T] pbr_init_render_resource_if_missing(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  init : () -> T,
) -> Unit {
  if world.get_resource(key) is None {
    world.insert_resource(key, init())
  }
}

///|
fn configure_pbr_render_world_resources(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  pbr_init_render_resource_if_missing(
    world,
    @pbr_render.LightMeta::resource(),
    fn() { @pbr_render.LightMeta::LightMeta() },
  )
  pbr_init_render_resource_if_missing(
    world,
    RenderMaterialBindings::resource(),
    fn() { RenderMaterialBindings::RenderMaterialBindings() },
  )
  pbr_init_render_resource_if_missing(
    world,
    @render_view.RenderShadowLodOrigin::resource(),
    fn() { @render_view.RenderShadowLodOrigin::RenderShadowLodOrigin() },
  )
  sub_app
}

///|
fn configure_pbr_render_extract_systems(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  if sub_app
    .world()
    .resource(ecs_key_pbr_render_extract_systems_installed)
    .is_present() {
    return sub_app
  }
  let marker = PbrRenderExtractSystemsInstalled::{  }
  sub_app
  .world()
  .insert_resource(ecs_key_pbr_render_extract_systems_installed, marker)
  sub_app
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(@pbr_render.extract_ambient_light_resource)
    .named("mgstudio_pbr::extract_ambient_light_resource")
    .in_set(@render.render_system_set_extract_commands),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(@pbr_render.extract_lights)
    .named("mgstudio_pbr::extract_lights")
    .in_set(@render.render_system_set_extract_commands),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_mesh_materials)
    .named("mgstudio_pbr::extract_mesh_materials")
    .in_set(material_extraction_systems),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(early_sweep_material_instances)
    .named("mgstudio_pbr::early_sweep_material_instances")
    .in_set(early_sweep_material_instances_set),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_shadow_filtering_method)
    .named("mgstudio_pbr::extract_shadow_filtering_method")
    .in_set(@render.render_system_set_extract_commands),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_ambient_light)
    .named("mgstudio_pbr::extract_ambient_light")
    .in_set(@render.render_system_set_extract_commands),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_shadow_lod_origin)
    .named("mgstudio_pbr::extract_shadow_lod_origin")
    .in_set(@render.render_system_set_extract_commands),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(late_sweep_material_instances)
    .named("mgstudio_pbr::late_sweep_material_instances")
    .in_set(late_sweep_material_instances_set),
  )
  .configure_set(
    @render.render_schedule_stage(),
    material_extraction_systems,
    before=[early_sweep_material_instances_set],
    in_sets=[@render.render_system_set_extract_commands],
  )
  .configure_set(
    @render.render_schedule_stage(),
    early_sweep_material_instances_set,
    after=[material_extraction_systems],
    before=[late_sweep_material_instances_set],
    in_sets=[@render.render_system_set_extract_commands],
  )
  .configure_set(
    @render.render_schedule_stage(),
    late_sweep_material_instances_set,
    after=[early_sweep_material_instances_set],
    in_sets=[@render.render_system_set_extract_commands],
  )
}

///|
pub fn configure_pbr_render_app_build_flow(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  sub_app
  |> configure_pbr_render_startup_systems
  |> configure_pbr_render_world_resources
  |> configure_pbr_render_extract_systems
  |> configure_pbr_render_prepare_systems
  |> configure_pbr_render_light_view_observers
}
