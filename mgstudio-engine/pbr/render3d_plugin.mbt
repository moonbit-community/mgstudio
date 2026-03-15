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
fn init_render3d_resources(world : @ecs.World) -> Unit {
  let ecs_world = world
  let tick = world.read_change_tick()
  render3d_runtime_initialized_ref.val = true
  let ambient = get_global_ambient_light_resource(ecs_world)
  if !ambient.is_present() {
    ambient.insert(GlobalAmbientLight::default(), tick)
  }
  let point_light_shadow_map = get_point_light_shadow_map_resource(ecs_world)
  if !point_light_shadow_map.is_present() {
    point_light_shadow_map.insert(PointLightShadowMap::default(), tick)
  }
  let default_opaque_renderer_method = get_default_opaque_renderer_method_resource(
    ecs_world,
  )
  if !default_opaque_renderer_method.is_present() {
    default_opaque_renderer_method.insert(
      DefaultOpaqueRendererMethod::forward(),
      tick,
    )
  }
  if (try! world.get_resource(ecs_key_internal_assets)) is None {
    world.insert_resource(
      ecs_key_internal_assets,
      Render3dInternalAssetsState::new(),
    )
  }
  let auto_exposure_curve_assets_key : @ecs.ResourceKey[
    @asset.Assets[AutoExposureCompensationCurve],
  ] = @asset.assets_resource_key()
  if (try! world.get_resource(auto_exposure_curve_assets_key)) is None {
    world.insert_resource(auto_exposure_curve_assets_key, @asset.Assets::new())
  }
  if (try! world.get_resource_ref_mut(auto_exposure_curve_assets_key, tick))
    is Some(curves_ref) {
    let default_curve_handle : @asset.Handle[AutoExposureCompensationCurve] = @asset.Handle::new(
      0,
    )
    if !curves_ref.val.contains(default_curve_handle) {
      curves_ref.val.insert(
        default_curve_handle,
        AutoExposureCompensationCurve::default(),
      )
      |> ignore
    }
  }
}

///|
fn init_wireframe_resources(world : @ecs.World) -> Unit {
  let ecs_world = world
  let tick = world.read_change_tick()
  let wireframe_config = get_wireframe_config_resource(ecs_world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::default(), tick)
  }
}

///|
pub fn wireframe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_startup_system(init_wireframe_resources)
}

///|
pub fn fog_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
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
  runtime_config.prepass_enabled |> ignore
  standard_material_plugin(app)
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
      .add_startup_system(init_render3d_resources)
      .add_post_update_system_config(
        @app.system(render3d_update_frusta_system).in_set(
          render3d_set_update_frusta,
        ),
      )
      .add_post_update_system_config(
        @app.system(render3d_extract_system).in_set(render3d_set_extract),
      )
      .add_post_update_system_config(
        @app.system(render3d_prepare_system).in_set(render3d_set_prepare),
      )
      .add_post_update_system_config(
        @app.system(render3d_queue_system).in_set(render3d_set_queue),
      )
      .add_post_update_system_config(
        @app.system(render3d_execute_system).in_set(render3d_set_render),
      )
      .configure_set(@app.PostUpdate, render3d_set_extract, before=[
        render3d_set_prepare,
      ])
      .configure_set(@app.PostUpdate, render3d_set_update_frusta, before=[
        render3d_set_extract,
      ])
      .configure_set(@app.PostUpdate, render3d_set_prepare, before=[
        render3d_set_queue,
      ])
      .configure_set(@app.PostUpdate, render3d_set_queue, before=[
        render3d_set_render,
      ])
    next = fog_plugin(next)
    next = pbr_plugin_sync_gltf_material_handler_state(next, runtime_config)
    next = pbr_plugin_sync_standard_material_state(next, runtime_config)
    next = pbr_plugin_sync_deferred_lighting_state(next, runtime_config)
  } else {
    next = next.insert_world_resource(
      ecs_key_pbr_plugin_runtime_config, runtime_config,
    )
    next = pbr_plugin_sync_gltf_material_handler_state(next, runtime_config)
    next = pbr_plugin_sync_standard_material_state(next, runtime_config)
    next = pbr_plugin_sync_deferred_lighting_state(next, runtime_config)
  }
  next
}

///|
pub fn render3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  pbr_plugin(app)
}
