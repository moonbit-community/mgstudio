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
const PBR_PLUGIN_NAME : String = "mgstudio.pbr.PbrPlugin"

///|
pub(all) struct PbrPlugin {
  prepass_enabled : Bool
  add_default_deferred_lighting_plugin : Bool
  use_gpu_instance_buffer_builder : Bool
  gltf_render_enabled : Bool
}

///|
pub fn PbrPlugin::default() -> PbrPlugin {
  PbrPlugin::{
    prepass_enabled: true,
    add_default_deferred_lighting_plugin: true,
    use_gpu_instance_buffer_builder: true,
    gltf_render_enabled: true,
  }
}

///|
pub struct PbrPluginRuntimeConfig {
  prepass_enabled : Bool
  add_default_deferred_lighting_plugin : Bool
  use_gpu_instance_buffer_builder : Bool
  gltf_render_enabled : Bool
}

///|
pub fn PbrPluginRuntimeConfig::from_plugin(
  plugin : PbrPlugin,
) -> PbrPluginRuntimeConfig {
  PbrPluginRuntimeConfig::{
    prepass_enabled: plugin.prepass_enabled,
    add_default_deferred_lighting_plugin: plugin.add_default_deferred_lighting_plugin,
    use_gpu_instance_buffer_builder: plugin.use_gpu_instance_buffer_builder,
    gltf_render_enabled: plugin.gltf_render_enabled,
  }
}

///|
fn pbr_default_runtime_config() -> PbrPluginRuntimeConfig {
  PbrPluginRuntimeConfig::from_plugin(PbrPlugin::default())
}

///|
pub fn pbr_plugin_runtime_config(world : @ecs.World) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_default_runtime_config()
  }
}

///|
pub fn pbr_prepass_enabled(world : @ecs.World) -> Bool {
  pbr_plugin_runtime_config(world).prepass_enabled
}

///|
pub fn pbr_deferred_lighting_enabled(world : @ecs.World) -> Bool {
  pbr_plugin_runtime_config(world).add_default_deferred_lighting_plugin
}

///|
pub fn pbr_gpu_instance_buffer_builder_enabled(world : @ecs.World) -> Bool {
  pbr_plugin_runtime_config(world).use_gpu_instance_buffer_builder
}

///|
pub fn pbr_gltf_render_enabled(world : @ecs.World) -> Bool {
  pbr_plugin_runtime_config(world).gltf_render_enabled
}

///|
priv struct PbrPluginMarker {}

///|
let ecs_key_pbr_plugin_marker : @ecs.ResourceKey[PbrPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PbrPluginMarker",
)

///|
pub let ecs_key_pbr_plugin_runtime_config : @ecs.ResourceKey[
  PbrPluginRuntimeConfig,
] = @ecs.register_resource(debug_name="mgstudio_pbr::PbrPluginRuntimeConfig")

///|
fn pbr_plugin_sync_mesh_render_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  mesh_render_plugin_with(app, MeshRenderPlugin::{
    use_gpu_instance_buffer_builder: runtime_config.use_gpu_instance_buffer_builder,
  })
}

///|
fn pbr_plugin_sync_materials_state(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  materials_plugin(app)
}

///|
fn pbr_plugin_sync_light_probe_state(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app.add_plugins(@pbr_light_probe.LightProbePlugin::default())
}

///|
fn pbr_plugin_sync_feature_plugins(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app
  .add_plugins(@pbr_atmosphere.AtmospherePlugin::default())
  .add_plugins(@lightmap.lightmap_plugin())
  .add_plugins(@pbr_ssao.ScreenSpaceAmbientOcclusionPlugin::default())
  .add_plugins(@pbr_ssr.ScreenSpaceReflectionsPlugin::default())
  .add_plugins(@pbr_volumetric_fog.VolumetricFogPlugin::default())
  .add_plugins(@pbr_render.GpuMeshPreprocessPlugin::default())
  .add_plugins(@pbr_decal.ClusteredDecalPlugin::default())
  .add_plugins(ContactShadowsPlugin::default())
  .add_plugins(@pbr_decal.ForwardDecalPlugin::default())
}

///|
fn pbr_plugin_sync_deferred_lighting_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  if runtime_config.add_default_deferred_lighting_plugin {
    app.add_plugins(DeferredPbrLightingPlugin::default())
  } else {
    app.insert_world_resource(
      ecs_key_deferred_pbr_lighting_state,
      DeferredPbrLightingState::disabled(),
    )
  }
}

///|
fn pbr_plugin_sync_standard_material_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  standard_material_plugin_with(app, StandardMaterialPlugin::{
    prepass_enabled: runtime_config.prepass_enabled,
  })
}

///|
fn pbr_plugin_sync_fog_state(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app.add_plugins(@pbr_render.FogPlugin::default())
}

///|
fn pbr_plugin_sync_gltf_material_handler_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  @gltf_loader.gltf_set_pbr_material_handler_enabled(
    runtime_config.gltf_render_enabled,
  )
  app
}

///|
pub let render3d_set_extract : @app.SystemSet = @render.render_system_set_extract_commands

///|
pub let render3d_set_prepare_resources_flush : @app.SystemSet = @render.render_system_set_prepare_resources_flush

///|
pub let render3d_set_prepare_resources : @app.SystemSet = @render.render_system_set_prepare_resources

///|
pub let render3d_set_prepare_meshes : @app.SystemSet = @render.render_system_set_prepare_meshes

///|
pub let render3d_set_prepare_bind_groups : @app.SystemSet = @render.render_system_set_prepare_bind_groups

///|
pub let render3d_set_queue_meshes : @app.SystemSet = @render.render_system_set_queue_meshes

///|
pub let render3d_set_queue_sweep : @app.SystemSet = @render.render_system_set_queue_sweep

///|
pub let render3d_set_queue : @app.SystemSet = @render.render_system_set_queue

///|
pub let render3d_set_prepare : @app.SystemSet = @render.render_system_set_prepare

///|
pub let render3d_set_render : @app.SystemSet = @render.render_system_set_render

///|
pub fn pbr_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(PbrPlugin::default())
}

///|
pub impl @app.Plugin for PbrPlugin with name(_self) {
  PBR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PbrPlugin with build(self, app) {
  @pbr_render.register_embedded_wgsl_sources()
  @transmission.register_embedded_wgsl_sources()
  pbr_plugin_install_with(app, self)
}

///|
pub fn pbr_plugin_with(
  app : @app.App[@ecs.World],
  plugin : PbrPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugins(plugin)
}

///|
fn pbr_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : PbrPlugin,
) -> @app.App[@ecs.World] {
  let runtime_config = PbrPluginRuntimeConfig::from_plugin(plugin)
  let mut next = app
  if !next.contains_resource(ecs_key_pbr_plugin_marker) {
    let camera_extract_plugin : @render.ExtractComponentPlugin[Camera3d, Unit] = @render.ExtractComponentPlugin::default()
    next = @render.extract_component_plugin_with(next, camera_extract_plugin)
    next = next
      .insert_world_resource(ecs_key_pbr_plugin_marker, PbrPluginMarker::{  })
      .insert_world_resource(ecs_key_pbr_plugin_runtime_config, runtime_config)
      .init_resource(fn() {
        let assets : @asset.Assets[StandardMaterial] = @asset.Assets::new()
        assets
      })
  } else {
    next = next.insert_world_resource(
      ecs_key_pbr_plugin_runtime_config, runtime_config,
    )
  }
  try! register_render3d_required_components(next.world())
  next = pbr_plugin_sync_mesh_render_state(next, runtime_config)
  next = pbr_plugin_sync_materials_state(next, runtime_config)
  next = pbr_plugin_sync_standard_material_state(next, runtime_config)
  next = pbr_plugin_sync_light_probe_state(next, runtime_config)
  next = pbr_plugin_sync_feature_plugins(next, runtime_config)
  next = pbr_plugin_sync_fog_state(next, runtime_config)
  next = pbr_plugin_sync_gltf_material_handler_state(next, runtime_config)
  next = pbr_plugin_sync_deferred_lighting_state(next, runtime_config)
  next
}

///|
pub fn render3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(PbrPlugin::default())
}
