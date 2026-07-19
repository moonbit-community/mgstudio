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
pub let pbr_prepare_lights_set : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.prepare_lights",
)

///|
let pbr_cluster_extract_system_set : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.cluster.extract",
)

///|
fn prepare_clustered_decals(world : @ecs.World) -> Unit {
  let render_decals = match
    world.get_resource(@pbr_decal.ecs_key_render_clustered_decals) {
    Some(value) => value
    None => abort("prepare_clustered_decals: missing RenderClusteredDecals")
  }
  let meta_ref = match
    world.get_resource_mut(ecs_key_global_clusterable_object_meta) {
    Some(value) => value
    None =>
      abort("prepare_clustered_decals: missing GlobalClusterableObjectMeta")
  }
  meta_ref.modify(fn(global_clusterable_object_meta) {
    world.for_each_component(@pbr_decal.ecs_key_clustered_decal, fn(
      entity,
      _decal,
    ) {
      match render_decals.get_decal_index(entity) {
        Some(index) =>
          global_clusterable_object_meta.insert_entity_index(entity, index)
        None => ()
      }
    })
  })
}

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
    @app.system(init_mesh_pipeline).named("mgstudio_pbr::init_mesh_pipeline"),
  )
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
  sub_app
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_lights)
    .named("mgstudio_pbr::prepare_lights")
    .after(@core_pipeline.core_pipeline_camera_driver_set)
    .in_set(pbr_prepare_lights_set)
    .in_set(@render.render_system_set_create_views),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(render3d_prepare_shadow_phase_views_system)
    .named("mgstudio_pbr::prepare_shadow_phase_views")
    .after(pbr_prepare_lights_set)
    .in_set(@render.render_system_set_create_views),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_clustered_decals)
    .named("mgstudio_pbr::prepare_clustered_decals")
    .after(pbr_prepare_lights_set)
    .in_set(@render.render_system_set_prepare_views),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_clusters_for_cpu_clustering)
    .named("mgstudio_pbr::prepare_clusters_for_cpu_clustering")
    .in_set(@render.render_system_set_prepare_resources)
    .run_if(cpu_clustering_is_enabled),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(render3d_prepare_shadow_phase_buffers_system)
    .named("mgstudio_pbr::prepare_shadow_phase_buffers")
    .in_set(@render.render_system_set_prepare_resources_batch_phases),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(render3d_collect_shadow_phase_buffers_system)
    .named("mgstudio_pbr::collect_shadow_phase_buffers")
    .in_set(@render.render_system_set_prepare_resources_collect_phase_buffers),
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
  pbr_init_render_resource_if_missing(world, ViewKeyCache::resource(), fn() {
    ViewKeyCache::ViewKeyCache()
  })
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
    ecs_key_render_material_shader_paths,
    fn() { RenderMaterialShaderPaths::RenderMaterialShaderPaths() },
  )
  pbr_init_render_resource_if_missing(
    world,
    @render_view.RenderShadowLodOrigin::resource(),
    fn() { @render_view.RenderShadowLodOrigin::RenderShadowLodOrigin() },
  )
  pbr_init_render_resource_if_missing(
    world,
    Render3dShadowPhaseBatchedInstanceBuffers::resource(),
    fn() {
      Render3dShadowPhaseBatchedInstanceBuffers::Render3dShadowPhaseBatchedInstanceBuffers()
    },
  )
  pbr_init_render_resource_if_missing(
    world,
    Render3dShadowPhaseIndirectParametersBuffers::resource(),
    fn() {
      Render3dShadowPhaseIndirectParametersBuffers::Render3dShadowPhaseIndirectParametersBuffers()
    },
  )
  pbr_init_render_resource_if_missing(
    world,
    (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    fn() { Render3dMainViewDrawItems::Render3dMainViewDrawItems() },
  )
  pbr_init_render_resource_if_missing(
    world,
    (@app.Resource::resource() : @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
    fn() { Render3dOpaqueMainViewPhases::Render3dOpaqueMainViewPhases() },
  )
  pbr_init_render_resource_if_missing(
    world,
    (
      @app.Resource::resource() :
      @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
    fn() { Render3dAlphaMaskMainViewPhases::Render3dAlphaMaskMainViewPhases() },
  )
  pbr_init_render_resource_if_missing(
    world,
    (
      @app.Resource::resource() :
      @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
    fn() {
      Render3dTransmissiveMainViewPhases::Render3dTransmissiveMainViewPhases()
    },
  )
  pbr_init_render_resource_if_missing(
    world,
    (
      @app.Resource::resource() :
      @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
    fn() {
      Render3dTransparentMainViewPhases::Render3dTransparentMainViewPhases()
    },
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
  let extract_stage = @render.render_extract_schedule_stage()
  sub_app
  .configure_sets(
    extract_stage,
    @pbr_light_probe.light_probe_extract_system_set,
    before=[pbr_cluster_extract_system_set],
  )
  .configure_sets(extract_stage, pbr_cluster_extract_system_set)
  .add_systems(
    extract_stage,
    @app.system(extract_clusters_for_cpu_clustering)
    .named("mgstudio_pbr::extract_clusters_for_cpu_clustering")
    .in_set(pbr_cluster_extract_system_set)
    .run_if(cpu_clustering_is_enabled_during_extraction),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_clusters_for_gpu_clustering)
    .named("mgstudio_pbr::extract_clusters_for_gpu_clustering")
    .in_set(pbr_cluster_extract_system_set)
    .run_if(gpu_clustering_is_enabled_during_extraction),
  )
  .add_systems(
    extract_stage,
    @app.system(@pbr_render.extract_ambient_light_resource).named(
      "mgstudio_pbr::extract_ambient_light_resource",
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(@pbr_render.extract_lights).named(
      "mgstudio_pbr::extract_lights",
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(clear_dirty_specializations_system)
    .named("mgstudio_pbr::clear_dirty_specializations")
    .in_set(material_dirty_specializations_clear_set),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_mesh_materials)
    .named("mgstudio_pbr::extract_mesh_materials")
    .in_set(material_extraction_systems),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_entities_needs_specialization)
    .named("mgstudio_pbr::extract_entities_needs_specialization")
    .in_set(material_extraction_systems),
  )
  .add_systems(
    extract_stage,
    @app.system(early_sweep_material_instances)
    .named("mgstudio_pbr::early_sweep_material_instances")
    .in_set(early_sweep_material_instances_set),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_shadow_filtering_method).named(
      "mgstudio_pbr::extract_shadow_filtering_method",
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_ambient_light).named(
      "mgstudio_pbr::extract_ambient_light",
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_shadow_lod_origin).named(
      "mgstudio_pbr::extract_shadow_lod_origin",
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_entities_that_need_specializations_removed)
    .named("mgstudio_pbr::extract_entities_that_need_specializations_removed")
    .in_set(material_dirty_specializations_removed_set),
  )
  .add_systems(
    extract_stage,
    @app.system(late_sweep_material_instances)
    .named("mgstudio_pbr::late_sweep_material_instances")
    .in_set(late_sweep_material_instances_set),
  )
  .configure_set(extract_stage, material_dirty_specializations_clear_set, before=[
    material_extraction_systems,
  ])
  .configure_set(
    extract_stage,
    material_extraction_systems,
    after=[material_dirty_specializations_clear_set],
    before=[early_sweep_material_instances_set],
  )
  .configure_set(
    extract_stage,
    early_sweep_material_instances_set,
    after=[material_extraction_systems],
    before=[material_dirty_specializations_removed_set],
  )
  .configure_set(
    extract_stage,
    material_dirty_specializations_removed_set,
    after=[early_sweep_material_instances_set],
    before=[late_sweep_material_instances_set],
  )
  .configure_set(extract_stage, late_sweep_material_instances_set, after=[
    material_dirty_specializations_removed_set,
  ])
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
