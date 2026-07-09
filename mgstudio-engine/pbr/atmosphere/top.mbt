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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/mod.rs`.

///|
const ATMOSPHERE_PLUGIN_NAME : String = "mgstudio.pbr.AtmospherePlugin"

///|
pub struct AtmospherePlugin {}

///|
pub struct ExtractedAtmosphere {
  inner_radius : Float
  outer_radius : Float
  ground_albedo : @math.Vec3
  medium : @asset.Handle[@light.ScatteringMedium]
  world_to_atmosphere : @math.Affine3
}

///|
pub let ecs_key_extracted_atmosphere : @ecs.ComponentKey[ExtractedAtmosphere] = @ecs.register_component(
  debug_name="mgstudio_pbr::ExtractedAtmosphere",
)

///|
pub impl @ecs.Component for ExtractedAtmosphere with fn component() {
  ecs_key_extracted_atmosphere
}

///|
pub fn ExtractedAtmosphere::ExtractedAtmosphere(
  inner_radius : Float,
  outer_radius : Float,
  ground_albedo : @math.Vec3,
  medium : @asset.Handle[@light.ScatteringMedium],
  world_to_atmosphere : @math.Affine3,
) -> ExtractedAtmosphere {
  ExtractedAtmosphere::{
    inner_radius,
    outer_radius,
    ground_albedo,
    medium,
    world_to_atmosphere,
  }
}

///|
pub fn AtmospherePlugin::AtmospherePlugin() -> AtmospherePlugin {
  AtmospherePlugin::{  }
}

///|
pub impl @app.Plugin for AtmospherePlugin with fn name(_self) {
  ATMOSPHERE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AtmospherePlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  atmosphere_plugin_install_with(app, self)
}

///|
pub fn atmosphere_plugin() -> AtmospherePlugin {
  AtmospherePlugin::AtmospherePlugin()
}

///|
pub fn atmosphere_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  atmosphere_plugin_install_with(app, AtmospherePlugin::AtmospherePlugin())
}

///|
pub fn atmosphere_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : AtmospherePlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let environment_map_extract : @render.ExtractComponentPlugin[
    AtmosphereEnvironmentMap,
    AtmospherePlugin,
  ] = @render.ExtractComponentPlugin::ExtractComponentPlugin()
  let atmosphere_settings_sync : @render.SyncComponentPlugin[
    AtmosphereSettings,
    AtmospherePlugin,
  ] = @render.SyncComponentPlugin::SyncComponentPlugin()
  let next = @render.extract_component_plugin_with(app, environment_map_extract)
  let next = @render.sync_component_plugin_with(next, atmosphere_settings_sync)
  @render.try_with_render_app(
    next.add_systems(
      @app.Update,
      @app.system(prepare_atmosphere_probe_components).named(
        "mgstudio_pbr::atmosphere::prepare_atmosphere_probe_components",
      ),
    ),
    fn(render_app) {
      render_app.add_systems(
        @render.render_extract_schedule_stage(),
        @app.system(extract_atmosphere).named(
          "mgstudio_pbr::atmosphere::extract_atmosphere",
        ),
      )
    },
  )
}

///|
fn atmosphere_global_to_world_to_atmosphere(
  global_transform : @transform.GlobalTransform,
) -> @math.Affine3 {
  global_transform.affine().inverse()
}

///|
fn atmosphere_write_extracted(
  render_world : @ecs.World,
  render_entity : @core.Entity,
  atmosphere : @light.Atmosphere,
  world_to_atmosphere : @math.Affine3,
  settings : AtmosphereSettings,
) -> Unit {
  try! render_world.set_by_key(render_entity, ecs_key_extracted_atmosphere, ExtractedAtmosphere::{
    inner_radius: atmosphere.inner_radius,
    outer_radius: atmosphere.outer_radius,
    ground_albedo: atmosphere.ground_albedo,
    medium: atmosphere.medium,
    world_to_atmosphere,
  })
  try! render_world.set_by_key(
    render_entity,
    GpuAtmosphereSettings::component(),
    pbr_gpu_atmosphere_settings(settings),
  )
}

///|
fn atmosphere_remove_extracted(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_atmosphere) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(
      render_entity,
      GpuAtmosphereSettings::component(),
    ) catch {
      _ => false
    },
  )
}

///|
pub fn extract_atmosphere(render_world : @ecs.World) -> Unit {
  let source_world = @render.extract_component_source_world(render_world)
  extract_atmosphere_from_worlds(source_world, render_world)
}

///|
fn extract_atmosphere_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  let candidates : Array[
    (@core.Entity, @light.Atmosphere, @transform.GlobalTransform),
  ] = []
  source_world.for_each_component(@light.ecs_key_atmosphere, fn(
    entity,
    atmosphere,
  ) {
    guard (try! source_world.get_by_key(
        entity, @transform.ecs_key_global_transform,
      ))
      is Some(global_transform) else {
      return
    }
    candidates.push((entity, atmosphere, global_transform))
  })
  let camera_query : @ecs.Query[
    (
      @ecs.Read[@render.RenderEntity],
      @ecs.Read[AtmosphereSettings],
      @ecs.Read[@transform.GlobalTransform],
      @ecs.Read[@camera_components3d.Camera3d],
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! camera_query.view(fn(_entity, data) {
    let (render_entity, settings, camera_global, _camera3d) = data
    let render_entity_id = render_entity.value().id()
    if candidates.length() == 0 {
      atmosphere_remove_extracted(render_world, render_entity_id)
      return
    }
    let camera_world = camera_global.value().translation()
    let mut selected = candidates[0]
    let mut selected_distance = camera_world.distance(selected.2.translation())
    for index = 1; index < candidates.length(); index = index + 1 {
      let candidate = candidates[index]
      let distance = camera_world.distance(candidate.2.translation())
      let tie_breaks_before = candidate.0.id < selected.0.id ||
        (
          candidate.0.id == selected.0.id &&
          candidate.0.generation < selected.0.generation
        )
      if distance < selected_distance ||
        (distance == selected_distance && tie_breaks_before) {
        selected = candidate
        selected_distance = distance
      }
    }
    atmosphere_write_extracted(
      render_world,
      render_entity_id,
      selected.1,
      atmosphere_global_to_world_to_atmosphere(selected.2),
      settings.value(),
    )
  })
}
