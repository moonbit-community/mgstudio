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
