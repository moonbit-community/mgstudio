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
}

///|
pub fn configure_pbr_render_app_build_flow(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  sub_app
  |> configure_pbr_render_startup_systems
  |> configure_pbr_render_world_resources
  |> configure_pbr_render_extract_systems
}
