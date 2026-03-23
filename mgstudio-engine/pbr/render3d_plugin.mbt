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
pub const PBR_PLUGIN_ID : String = "bevy_pbr::PbrPlugin"

///|
pub const FOG_PLUGIN_ID : String = "bevy_pbr::FogPlugin"

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
let pbr_plugin_runtime_config_ref : Ref[PbrPluginRuntimeConfig] = Ref::new(
  PbrPluginRuntimeConfig::from_plugin(PbrPlugin::default()),
)

///|
pub fn pbr_plugin_runtime_config() -> PbrPluginRuntimeConfig {
  pbr_plugin_runtime_config_ref.val
}

///|
pub fn pbr_prepass_enabled() -> Bool {
  pbr_plugin_runtime_config_ref.val.prepass_enabled
}

///|
pub fn pbr_deferred_lighting_enabled() -> Bool {
  pbr_plugin_runtime_config_ref.val.add_default_deferred_lighting_plugin
}

///|
pub fn pbr_gpu_instance_buffer_builder_enabled() -> Bool {
  pbr_plugin_runtime_config_ref.val.use_gpu_instance_buffer_builder
}

///|
pub fn pbr_gltf_render_enabled() -> Bool {
  pbr_plugin_runtime_config_ref.val.gltf_render_enabled
}

///|
priv struct PbrPluginMarker {}

///|
let ecs_key_pbr_plugin_marker : @ecs.ResourceKey[PbrPluginMarker] = @ecs.register_resource(
  debug_name="bevy_pbr::PbrPluginMarker",
)

///|
pub let ecs_key_pbr_plugin_runtime_config : @ecs.ResourceKey[
  PbrPluginRuntimeConfig,
] = @ecs.register_resource(debug_name="bevy_pbr::PbrPluginRuntimeConfig")

///|
fn init_wireframe_resources(world : @ecs.World) -> Unit {
  let ecs_world = world
  let wireframe_config = get_wireframe_config_resource(ecs_world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::default())
  }
}

///|
pub fn wireframe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_startup_system(init_wireframe_resources)
}

///|
pub struct FogPluginState {}

///|
pub let ecs_key_fog_plugin_state : @ecs.ResourceKey[FogPluginState] = @ecs.register_resource(
  debug_name="bevy_pbr::FogPluginState",
)

///|
pub fn fog_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_fog_plugin_state) {
    app
  } else {
    app.insert_world_resource(ecs_key_fog_plugin_state, FogPluginState::{  })
  }
}

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
fn pbr_plugin_sync_deferred_lighting_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  if runtime_config.add_default_deferred_lighting_plugin {
    app.add_plugin(deferred_pbr_lighting_plugin)
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
fn pbr_plugin_sync_gltf_material_handler_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  @gltf.gltf_set_pbr_material_handler_enabled(
    runtime_config.gltf_render_enabled,
  )
  app
}

///|
pub let render3d_set_extract : @app.SystemSet = @app.system_set(
  "bevy.render3d.extract",
)

///|
pub let render3d_set_update_frusta : @app.SystemSet = @app.system_set(
  "bevy.render3d.update_frusta",
)

///|
pub let render3d_set_prepare : @app.SystemSet = @app.system_set(
  "bevy.render3d.prepare",
)

///|
pub let render3d_set_queue : @app.SystemSet = @app.system_set(
  "bevy.render3d.queue",
)

///|
pub let render3d_set_render : @app.SystemSet = @app.system_set(
  "bevy.render3d.render",
)

///|
/// Legacy alias kept for source compatibility.
pub let render3d_set_execute : @app.SystemSet = render3d_set_render

///|
pub fn pbr_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  pbr_plugin_with(app, PbrPlugin::default())
}

///|
pub impl @app.PluginReplacement for PbrPlugin with replacement_id(_self) {
  PBR_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for PbrPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    pbr_plugin_with(app, self)
  }
}

///|
pub fn pbr_plugin_with(
  app : @app.App[@ecs.World],
  plugin : PbrPlugin,
) -> @app.App[@ecs.World] {
  let runtime_config = PbrPluginRuntimeConfig::from_plugin(plugin)
  pbr_plugin_runtime_config_ref.val = runtime_config
  let mut next = app
  if !next.contains_resource(ecs_key_pbr_plugin_marker) {
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
  next = fog_plugin(next)
  next = pbr_plugin_sync_gltf_material_handler_state(next, runtime_config)
  next = pbr_plugin_sync_deferred_lighting_state(next, runtime_config)
  next
}

///|
pub fn render3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  pbr_plugin(app)
}
