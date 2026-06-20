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
const PBR_BLUENOISE_PATH : String = "pbr/bluenoise/stbn.ktx2"

///|
const PBR_AREA_LIGHT_LUTS_PATH : String = "pbr/ltc/ltc.ktx2"

///|
const PBR_DFG_LUT_PATH : String = "pbr/environment_map/dfg.ktx2"

///|
pub(all) struct PbrPlugin {
  prepass_enabled : Bool
  add_default_deferred_lighting_plugin : Bool
  use_gpu_instance_buffer_builder : Bool
  debug_flags : @render.RenderDebugFlags
  gltf_render_enabled : Bool
}

///|
pub fn PbrPlugin::PbrPlugin() -> PbrPlugin {
  PbrPlugin::{
    prepass_enabled: true,
    add_default_deferred_lighting_plugin: true,
    use_gpu_instance_buffer_builder: true,
    debug_flags: @render.RenderDebugFlags::RenderDebugFlags(),
    gltf_render_enabled: true,
  }
}

///|
pub struct PbrPluginRuntimeConfig {
  prepass_enabled : Bool
  add_default_deferred_lighting_plugin : Bool
  use_gpu_instance_buffer_builder : Bool
  debug_flags : @render.RenderDebugFlags
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
    debug_flags: plugin.debug_flags,
    gltf_render_enabled: plugin.gltf_render_enabled,
  }
}

///|
fn pbr_default_runtime_config() -> PbrPluginRuntimeConfig {
  PbrPluginRuntimeConfig::from_plugin(PbrPlugin::PbrPlugin())
}

///|
fn pbr_plugin_ensure_mesh_asset_resources(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @mesh.ensure_mesh_required_components(app.world())
  let mesh_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mut next = if app.contains_resource(mesh_key) {
    app
  } else {
    @asset.init_asset(app, fn() {
      @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::new([], [], None))
    })
  }
  let inverse_bindposes_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  if next.contains_resource(inverse_bindposes_key) {
    next
  } else {
    next = @asset.init_asset(next, fn() {
      @mesh.SkinnedMeshInverseBindposes::new([])
    })
    next
  }
}

///|
pub fn pbr_plugin_runtime_config(world : @ecs.World) -> PbrPluginRuntimeConfig {
  match world.get_resource(ecs_key_pbr_plugin_runtime_config) {
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
fn pbr_default_material_handle() -> @asset.Handle[@material.StandardMaterial] {
  @asset.Handle::new(0)
}

///|
fn pbr_default_standard_material() -> @material.StandardMaterial {
  @material.StandardMaterial::StandardMaterial().with_base_color(
    @color.Color::srgb(1.0F, 0.0F, 0.5F),
  )
}

///|
fn pbr_plugin_initialize_default_standard_material(world : @ecs.World) -> Unit {
  let key : @ecs.ResourceKey[@asset.Assets[@material.StandardMaterial]] = @asset.assets_resource_key()
  guard world.get_resource_mut(key) is Some(assets) else { return }
  assets.modify(fn(store) {
    ignore(
      store.insert(
        pbr_default_material_handle(),
        pbr_default_standard_material(),
      ),
    )
  })
}

///|
pub(all) struct Bluenoise {
  texture : @asset.Handle[@asset.Image]
}

///|
pub let ecs_key_bluenoise : @ecs.ResourceKey[Bluenoise] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Bluenoise",
)

///|
pub impl @app.Resource for Bluenoise with fn resource() {
  ecs_key_bluenoise
}

///|
pub(all) struct AreaLightLuts {
  image : @asset.Handle[@asset.Image]
}

///|
pub let ecs_key_area_light_luts : @ecs.ResourceKey[AreaLightLuts] = @ecs.register_resource(
  debug_name="mgstudio_pbr::AreaLightLuts",
)

///|
pub impl @app.Resource for AreaLightLuts with fn resource() {
  ecs_key_area_light_luts
}

///|
pub(all) struct DfgLut {
  texture : @asset.Handle[@asset.Image]
}

///|
pub let ecs_key_dfg_lut : @ecs.ResourceKey[DfgLut] = @ecs.register_resource(
  debug_name="mgstudio_pbr::DfgLut",
)

///|
pub impl @app.Resource for DfgLut with fn resource() {
  ecs_key_dfg_lut
}

///|
fn pbr_plugin_register_internal_image_assets(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let mut next = app
  next = @asset.embedded_asset(next, PBR_BLUENOISE_PATH, PBR_BLUENOISE_PATH)
  next = @asset.embedded_asset(
    next,
    PBR_AREA_LIGHT_LUTS_PATH,
    PBR_AREA_LIGHT_LUTS_PATH,
  )
  next = @asset.embedded_asset(next, PBR_DFG_LUT_PATH, PBR_DFG_LUT_PATH)
  next
}

///|
fn pbr_load_bluenoise(world : @ecs.World) -> @asset.Handle[@asset.Image] {
  @asset.asset_world_load_with_settings(world, PBR_BLUENOISE_PATH, fn(
    settings,
  ) {
    settings.is_srgb = false
    settings.sampler = @asset.ImageSampler::Default
    settings.texture_descriptor_label = Some("bluenoise")
    settings.asset_usage = @asset.RenderAssetUsages::render_world()
  })
}

///|
fn pbr_load_area_light_luts(world : @ecs.World) -> @asset.Handle[@asset.Image] {
  @asset.asset_world_load_with_settings(world, PBR_AREA_LIGHT_LUTS_PATH, fn(
    settings,
  ) {
    settings.is_srgb = false
    settings.sampler = @asset.ImageSampler::linear()
    settings.texture_descriptor_label = Some("area_light_luts")
    settings.asset_usage = @asset.RenderAssetUsages::render_world()
  })
}

///|
fn pbr_load_dfg_lut(world : @ecs.World) -> @asset.Handle[@asset.Image] {
  @asset.asset_world_load_with_settings(world, PBR_DFG_LUT_PATH, fn(settings) {
    settings.is_srgb = false
    settings.sampler = @asset.ImageSampler::linear()
    settings.asset_usage = @asset.RenderAssetUsages::render_world()
  })
}

///|
fn pbr_render_world_needs_internal_luts(
  render_world : @ecs.World,
) -> (Bool, Bool, Bool) {
  (
    render_world.get_resource(ecs_key_bluenoise) is None,
    render_world.get_resource(ecs_key_area_light_luts) is None,
    render_world.get_resource(ecs_key_dfg_lut) is None,
  )
}

///|
pub fn pbr_ensure_render_world_internal_luts(
  render_world : @ecs.World,
  main_world : @ecs.World,
) -> Unit {
  let render_needs = pbr_render_world_needs_internal_luts(render_world)
  let bluenoise = if render_needs.0 {
    Some(pbr_load_bluenoise(main_world))
  } else {
    None
  }
  let area_light_luts = if render_needs.1 {
    Some(pbr_load_area_light_luts(main_world))
  } else {
    None
  }
  let dfg_lut = if render_needs.2 {
    Some(pbr_load_dfg_lut(main_world))
  } else {
    None
  }
  if bluenoise is Some(texture) && texture.id() > 0 {
    render_world.insert_resource(ecs_key_bluenoise, Bluenoise::{ texture, })
  }
  if area_light_luts is Some(image) && image.id() > 0 {
    render_world.insert_resource(ecs_key_area_light_luts, AreaLightLuts::{
      image,
    })
  }
  if dfg_lut is Some(texture) && texture.id() > 0 {
    render_world.insert_resource(ecs_key_dfg_lut, DfgLut::{ texture, })
  }
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
    debug_flags: runtime_config.debug_flags,
  })
}

///|
fn pbr_plugin_sync_materials_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  materials_plugin_with(
    app,
    MaterialsPlugin::MaterialsPlugin().with_debug_flags(
      runtime_config.debug_flags,
    ),
  )
}

///|
fn pbr_plugin_sync_light_probe_state(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app.add_plugins(@pbr_light_probe.LightProbePlugin::LightProbePlugin())
}

///|
fn pbr_plugin_sync_feature_plugins(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app
  .add_plugins(@pbr_atmosphere.AtmospherePlugin::AtmospherePlugin())
  .add_plugins(@lightmap.lightmap_plugin())
  .add_plugins(
    @pbr_ssao.ScreenSpaceAmbientOcclusionPlugin::ScreenSpaceAmbientOcclusionPlugin(),
  )
  .add_plugins(
    @pbr_ssr.ScreenSpaceReflectionsPlugin::ScreenSpaceReflectionsPlugin(),
  )
  .add_plugins(@pbr_volumetric_fog.VolumetricFogPlugin::VolumetricFogPlugin())
  .add_plugins(@pbr_render.GpuMeshPreprocessPlugin::GpuMeshPreprocessPlugin())
  .add_plugins(@pbr_decal.ClusteredDecalPlugin::ClusteredDecalPlugin())
  .add_plugins(ContactShadowsPlugin::ContactShadowsPlugin())
  .add_plugins(@pbr_decal.ForwardDecalPlugin::ForwardDecalPlugin())
}

///|
fn pbr_plugin_sync_deferred_lighting_state(
  app : @app.App[@ecs.World],
  runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  if runtime_config.add_default_deferred_lighting_plugin {
    app.add_plugins(
      @pbr_deferred.DeferredPbrLightingPlugin::DeferredPbrLightingPlugin(),
    )
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
    debug_flags: runtime_config.debug_flags,
  })
}

///|
fn pbr_plugin_sync_fog_state(
  app : @app.App[@ecs.World],
  _runtime_config : PbrPluginRuntimeConfig,
) -> @app.App[@ecs.World] {
  app.add_plugins(@pbr_render.FogPlugin::FogPlugin())
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
pub let render3d_set_render : @app.SystemSet = @render.render_graph_system_set_render

///|
pub fn pbr_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(PbrPlugin::PbrPlugin())
}

///|
pub impl @app.Plugin for PbrPlugin with fn name(_self) {
  PBR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PbrPlugin with fn build(self, app) {
  @pbr_render.register_embedded_wgsl_sources()
  @transmission.register_embedded_wgsl_sources()
  @cas.cas_register_camera_component_key(@camera_camera.ecs_key_camera)
  pbr_plugin_install_with(app, self)
}

///|
pub impl @app.Plugin for PbrPlugin with fn finish(self, app) {
  pbr_plugin_finish_with(app, self)
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
  let mut next = @shader.shader_plugin(app)
  next = pbr_plugin_register_internal_image_assets(next)
  next = pbr_plugin_ensure_mesh_asset_resources(next)
  if !next.contains_resource(ecs_key_pbr_plugin_marker) {
    let distance_fog_extract_plugin : @render.ExtractComponentPlugin[
      DistanceFog,
      Unit,
    ] = @render.ExtractComponentPlugin::ExtractComponentPlugin()
    next = @render.extract_component_plugin_with(
      next, distance_fog_extract_plugin,
    )
    let shadow_filtering_method_sync : @render.SyncComponentPlugin[
      ShadowFilteringMethod,
      PbrPlugin,
    ] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(
      next, shadow_filtering_method_sync,
    )
    let directional_light_sync : @render.SyncComponentPlugin[
      DirectionalLight,
      PbrPlugin,
    ] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(next, directional_light_sync)
    let point_light_sync : @render.SyncComponentPlugin[PointLight, PbrPlugin] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(next, point_light_sync)
    let spot_light_sync : @render.SyncComponentPlugin[SpotLight, PbrPlugin] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(next, spot_light_sync)
    let rect_light_sync : @render.SyncComponentPlugin[
      @light.RectLight,
      PbrPlugin,
    ] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(next, rect_light_sync)
    let ambient_light_sync : @render.SyncComponentPlugin[
      AmbientLight,
      PbrPlugin,
    ] = @render.SyncComponentPlugin::SyncComponentPlugin()
    next = @render.sync_component_plugin_with(next, ambient_light_sync)
    next = next
      .insert_world_resource(ecs_key_pbr_plugin_marker, PbrPluginMarker::{  })
      .insert_world_resource(ecs_key_pbr_plugin_runtime_config, runtime_config)
    next = @asset.init_asset(next, fn() {
      @material.StandardMaterial::StandardMaterial()
    })
    pbr_plugin_initialize_default_standard_material(next.world())
  } else {
    next = next.insert_world_resource(
      ecs_key_pbr_plugin_runtime_config, runtime_config,
    )
  }
  next = @render.try_with_render_app(next, configure_pbr_render_app_build_flow)
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
fn pbr_plugin_finish_with(
  app : @app.App[@ecs.World],
  _plugin : PbrPlugin,
) -> @app.App[@ecs.World] {
  match app.get_sub_app(@app.RenderApp) {
    Some(render_app) =>
      match
        pbr_make_global_cluster_settings_from_render_world(render_app.world()) {
        Some(global_cluster_settings) =>
          app.insert_resource(global_cluster_settings)
        None => app
      }
    None => app
  }
}

///|
pub fn render3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(PbrPlugin::PbrPlugin())
}
